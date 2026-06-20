import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../models/invoice_model.dart';
import '../../models/timesheet_model.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/invoice_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/ultimate_mobile_widgets.dart';

class InvoiceManagementScreen extends StatefulWidget {
  const InvoiceManagementScreen({super.key});

  @override
  State<InvoiceManagementScreen> createState() =>
      _InvoiceManagementScreenState();
}

class _InvoiceManagementScreenState extends State<InvoiceManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceViewModel>().loadInvoices();
      context.read<AdminViewModel>().loadTimesheets();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Invoice> _filtered(List<Invoice> invoices) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return invoices;
    return invoices
        .where(
          (inv) =>
              inv.invoiceNumber.toLowerCase().contains(q) ||
              inv.customerName.toLowerCase().contains(q) ||
              inv.status.displayName.toLowerCase().contains(q),
        )
        .toList();
  }

  bool _hasPrivilege(String action) {
    return context.read<AuthViewModel>().hasPrivilege('invoice', action);
  }

  Future<void> _showInvoiceSheet(
    InvoiceViewModel vm, {
    Invoice? invoice,
  }) async {
    // Reload timesheets to ensure we have latest approved ones
    await context.read<AdminViewModel>().loadTimesheets();

    final approvedTimesheets = context
        .read<AdminViewModel>()
        .timesheets
        .where((t) =>
            t.status == TimesheetStatus.approved ||
            (invoice != null && invoice.timesheetIds.contains(t.id)))
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _InvoiceFormSheet(
        viewModel: vm,
        invoice: invoice,
        approvedTimesheets: approvedTimesheets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<InvoiceViewModel>(
      builder: (context, viewModel, child) {
        final invoices = _filtered(viewModel.invoices);

        return Scaffold(
          backgroundColor: const Color(0xFFE5E7EB),
          body: SafeArea(
            child: Column(
              children: [
                //  Primary Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 18.h),
                  color: AppColors.primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18.sp,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invoice Management',
                                  style: AppTypography.title().copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${viewModel.invoices.length} total invoice${viewModel.invoices.length == 1 ? "" : "s"}',
                                  style: AppTypography.label().copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      // Search bar
                      Container(
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A43C7),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 22.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                style: AppTypography.body().copyWith(
                                  fontSize: 15.sp,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search invoices...',
                                  hintStyle: AppTypography.body().copyWith(
                                    fontSize: 15.sp,
                                    color: Colors.white.withValues(alpha: 0.95),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                //  Body
                Expanded(
                  child: viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                          child: Column(
                            children: [
                              // Add Invoice button
                              if (_hasPrivilege('create'))
                              SizedBox(
                                width: double.infinity,
                                height: 52.h,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showInvoiceSheet(viewModel),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00B122),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    elevation: 0,
                                  ),
                                  icon: Icon(Icons.add, size: 27.sp),
                                  label: Text(
                                    'Add Invoice',
                                    style: AppTypography.body().copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                              if (_hasPrivilege('create')) SizedBox(height: 14.h),
                              if (invoices.isEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 48.h),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No invoices found',
                                    style: AppTypography.body().copyWith(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                )
                              else
                                ...invoices.map(
                                  (inv) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: _buildInvoiceCard(inv, viewModel),
                                  ),
                                ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  //  Invoice Card
  Widget _buildInvoiceCard(Invoice invoice, InvoiceViewModel viewModel) {
    final dueDateStr = invoice.dueDate != null
        ? DateFormat('MMM dd, yyyy').format(invoice.dueDate!)
        : 'No due date';
    final amountStr = '£${invoice.totalAmount.toStringAsFixed(2)}';
    final timesheetsStr =
        '${invoice.timesheetIds.length} timesheet${invoice.timesheetIds.length == 1 ? "" : "s"}';

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: customer name + approved badge
          Row(
            children: [
              Expanded(
                child: Text(
                  invoice.customerName,
                  style: AppTypography.body().copyWith(
                    fontSize: 16.sp,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _statusBadge(invoice.status),
            ],
          ),
          SizedBox(height: 6.h),
          // Row 2: invoice number
          Row(
            children: [
              if (invoice.isLocked)
                Padding(
                  padding: EdgeInsets.only(right: 4.w),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 13.sp,
                    color: AppColors.primary,
                  ),
                ),
              Expanded(
                child: Text(
                  invoice.invoiceNumber,
                  style: AppTypography.body().copyWith(
                    fontSize: 14.sp,
                    color: const Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Row 3: amount • timesheets
          Text(
            '$amountStr • $timesheetsStr',
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 10.h),
          // InfoBoxes
          Row(
            children: [
              Expanded(
                child: _InvoiceInfoBox(label: 'Due Date', value: dueDateStr),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _InvoiceInfoBox(label: 'Amount', value: amountStr),
              ),
            ],
          ),
          // Manual items preview (if any)
          if (invoice.manualItems.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: invoice.manualItems
                  .map(
                    (item) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 7.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        '${item.name}  ${item.units}',
                        style: AppTypography.body().copyWith(
                          fontSize: 10.sp,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],

          SizedBox(height: 12.h),

          // Action buttons
          if (_hasPrivilege('update') || _hasPrivilege('delete'))
          Row(
            children: [
              if (invoice.status == InvoiceStatus.draft && _hasPrivilege('update')) ...[
                // Approve button (full width minus icons)
                Expanded(
                  child: SizedBox(
                    height: 38.h,
                    child: ElevatedButton(
                      onPressed: () => _approveDialog(invoice, viewModel),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                      child: Text(
                        'Approve',
                        style: AppTypography.body().copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
              ] else
                const Spacer(),

              // Edit icon button
              if (_hasPrivilege('update')) ...[
              SizedBox(
                width: 38.w,
                height: 38.h,
                child: ElevatedButton(
                  onPressed: () =>
                      _showInvoiceSheet(viewModel, invoice: invoice),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD1D5DB),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18.sp,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              ],
              // Delete icon button
              if (_hasPrivilege('delete'))
              SizedBox(
                width: 38.w,
                height: 38.h,
                child: ElevatedButton(
                  onPressed: () => _deleteDialog(invoice, viewModel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7CDD1),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18.sp,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(InvoiceStatus status) {
    final (color, icon) = switch (status) {
      InvoiceStatus.draft => (Colors.grey, Icons.edit_outlined),
      InvoiceStatus.approved => (Colors.green, Icons.check_circle_outline),
      InvoiceStatus.sent => (Colors.orange, Icons.send_outlined),
      InvoiceStatus.paid => (Colors.green.shade800, Icons.payments_outlined),
      InvoiceStatus.overdue => (Colors.red, Icons.warning_outlined),
      InvoiceStatus.cancelled => (Colors.red.shade300, Icons.cancel_outlined),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            status.displayName,
            style: AppTypography.body().copyWith(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  //  Dialogs
  void _approveDialog(Invoice invoice, InvoiceViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: const Color(0xFF10B981),
              size: 26.sp,
            ),
            SizedBox(width: 10.w),
            const Text('Approve Invoice'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Approve ${invoice.invoiceNumber}?'),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_outlined,
                    color: Colors.orange,
                    size: 18.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Once approved, the invoice will be locked and sent to the client for payment.',
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              vm.completeInvoice(invoice.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invoice approved'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
            ),
            child: const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteDialog(Invoice invoice, InvoiceViewModel vm) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red, size: 26.sp),
            SizedBox(width: 10.w),
            const Text('Delete Invoice'),
          ],
        ),
        content: Text('Delete ${invoice.invoiceNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              vm.deleteInvoice(invoice.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _InvoiceInfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InvoiceInfoBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.body().copyWith(
              fontSize: 11.sp,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: AppTypography.body().copyWith(
              fontSize: 13.sp,
              color: const Color(0xFF1F2937),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

//
// Invoice Form Bottom Sheet
//

class _InvoiceFormSheet extends StatefulWidget {
  final InvoiceViewModel viewModel;
  final Invoice? invoice;
  final List<Timesheet> approvedTimesheets;

  const _InvoiceFormSheet({
    required this.viewModel,
    required this.approvedTimesheets,
    this.invoice,
  });

  @override
  State<_InvoiceFormSheet> createState() => _InvoiceFormSheetState();
}

class _InvoiceFormSheetState extends State<_InvoiceFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final List<String> _selectedTimesheetIds;
  late DateTime _dueDate;
  late final List<_BillableItemDraft> _manualItems;
  late final TextEditingController _notesController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedTimesheetIds = List<String>.from(
      widget.invoice?.timesheetIds ?? [],
    );
    _dueDate =
        widget.invoice?.dueDate ?? DateTime.now().add(const Duration(days: 5));
    _manualItems =
        widget.invoice?.manualItems
            .map((item) => _BillableItemDraft.fromItem(item))
            .toList() ??
        [];
    _notesController = TextEditingController(text: widget.invoice?.notes ?? '');
  }

  InputDecoration _inputDeco(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: AppTypography.body().copyWith(
        fontSize: 13.sp,
        color: const Color(0xFF6B7280),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFF0E45BA), width: 1.1),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.1),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final picked = await UltimateMobileDatePicker.show(
      context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _pickTimesheets() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _TimesheetPickerDialog(
        timesheets: widget.approvedTimesheets,
        selected: List.from(_selectedTimesheetIds),
      ),
    );
    if (selected != null) {
      setState(() {
        _selectedTimesheetIds
          ..clear()
          ..addAll(selected);
      });
    }
  }

  double _computeTotal() {
    double total = 0;
    for (final item in _manualItems) {
      final r = double.tryParse(item.rateCtrl.text) ?? 0;
      final u = double.tryParse(item.unitsCtrl.text) ?? 0;
      total += r * u;
    }
    return total;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    // Build manual items
    final manualItems = _manualItems.map((d) {
      final rate = double.tryParse(d.rateCtrl.text.trim()) ?? 0;
      final units = double.tryParse(d.unitsCtrl.text.trim()) ?? 0;
      return ManualBillableItem(
        id: d.id,
        name: d.nameCtrl.text.trim(),
        rate: rate,
        units: units,
        note: d.noteCtrl.text.trim(),
        date: d.date,
      );
    }).toList();

    // Determine customer from selected timesheets
    String customerId = '';
    String customerName = 'Unknown';
    if (_selectedTimesheetIds.isNotEmpty) {
      final ts = widget.approvedTimesheets.firstWhere(
        (t) => t.id == _selectedTimesheetIds.first,
        orElse: () => widget.approvedTimesheets.first,
      );
      customerId = ts.customerId;
      customerName = ts.customerName;
    }

    final now = DateTime.now();
    final subtotal = _computeTotal();

    try {
      final invoiceItems = <Map<String, dynamic>>[];

      for (final timesheetId in _selectedTimesheetIds) {
        invoiceItems.add({
          'reference_type': 'timesheet',
          'reference_id': int.tryParse(timesheetId) ?? 0,
        });
      }

      for (final item in manualItems) {
        invoiceItems.add({
          'reference_type': 'manual-billable',
          'name': item.name,
          'rate': item.rate,
          'units': item.units,
          'total_amount': item.totalAmount,
          'date': item.date?.toIso8601String().split('T')[0] ?? now.toIso8601String().split('T')[0],
          'note': item.note,
        });
      }

      final payload = {
        'reference_number': widget.invoice?.invoiceNumber ??
            'INV-${now.year}-${(widget.viewModel.invoices.length + 1).toString().padLeft(3, '0')}',
        if (widget.invoice == null) 'customer_invoice_profile_id': 4,
        'due_date': _dueDate?.toIso8601String().split('T')[0] ?? now.toIso8601String().split('T')[0],
        'invoice_items': invoiceItems,
        if (_notesController.text.trim().isNotEmpty) 'notes': _notesController.text.trim(),
      };

      if (widget.invoice == null) {
        await widget.viewModel.createInvoice(payload);
      } else {
        await widget.viewModel.updateInvoice(widget.invoice!.id, payload);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save invoice: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final item in _manualItems) {
      item.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.invoice != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Handle + title
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 42.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1D5DB),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  isEdit ? 'Edit Invoice' : 'Add Invoice',
                  style: AppTypography.title().copyWith(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16.w,
                8.h,
                16.w,
                24.h + bottomPadding,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //  Timesheets picker
                    GestureDetector(
                      onTap: widget.approvedTimesheets.isEmpty
                          ? null
                          : _pickTimesheets,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: widget.approvedTimesheets.isEmpty
                            ? Text(
                                'No approved timesheets available',
                                style: AppTypography.body().copyWith(
                                  fontSize: 13.sp,
                                  color: const Color(0xFF9CA3AF),
                                ),
                              )
                            : _selectedTimesheetIds.isEmpty
                            ? Row(
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: 16.sp,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    'Tap to select timesheets...',
                                    style: AppTypography.body().copyWith(
                                      fontSize: 13.sp,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 18.sp,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ],
                              )
                            : Wrap(
                                spacing: 6.w,
                                runSpacing: 4.h,
                                children: [
                                  ..._selectedTimesheetIds.map((id) {
                                    // Try to find in approved list first
                                    var ts = widget.approvedTimesheets
                                        .where((t) => t.id == id)
                                        .firstOrNull;

                                    String displayText = 'Unknown Timesheet';
                                    
                                    if (ts != null) {
                                      displayText = '${ts.staffName} @ ${ts.siteName}';
                                    } else if (widget.invoice != null) {
                                      // Fallback to invoice items
                                      final item = widget.invoice!.items
                                          .where((i) => i.referenceType == 'timesheet' && 
                                                        i.reference != null && 
                                                        i.reference!['id']?.toString() == id)
                                          .firstOrNull;
                                      
                                      if (item != null && item.reference != null) {
                                        final ref = item.reference!;
                                        final staff = ref['employee']?['name'] ?? ref['staff_name'] ?? 'Staff';
                                        final site = ref['site']?['name'] ?? ref['site_name'] ?? 'Site';
                                        displayText = '$staff @ $site';
                                      } else {
                                        displayText = 'TS #$id';
                                      }
                                    }

                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            displayText,
                                            style: AppTypography.body().copyWith(
                                              fontSize: 11.sp,
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(width: 4.w),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _selectedTimesheetIds.remove(id);
                                              });
                                            },
                                            child: Icon(
                                              Icons.close,
                                              size: 14.sp,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  GestureDetector(
                                    onTap: _pickTimesheets,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      child: Text(
                                        'Edit',
                                        style: AppTypography.body().copyWith(
                                          fontSize: 11.sp,
                                          color: const Color(0xFF374151),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    //  Due Date
                    GestureDetector(
                      onTap: _pickDueDate,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 14.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 16.sp,
                              color: const Color(0xFF6B7280),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              DateFormat('dd MMM yyyy').format(_dueDate),
                              style: AppTypography.body().copyWith(
                                fontSize: 13.sp,
                                color: const Color(0xFF111827),
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.edit_calendar_outlined,
                              size: 16.sp,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    //  Manual Billable Items
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Manual Billable Items',
                            style: AppTypography.body().copyWith(
                              fontSize: 13.sp,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _manualItems.add(_BillableItemDraft());
                            });
                          },
                          icon: Icon(Icons.add, size: 16.sp),
                          label: Text(
                            'Add Item',
                            style: AppTypography.body().copyWith(
                              fontSize: 12.sp,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 4.h,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    if (_manualItems.isEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20.h),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          'No billable items yet',
                          style: AppTypography.body().copyWith(
                            fontSize: 13.sp,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ...List.generate(_manualItems.length, (i) {
                      final item = _manualItems[i];
                      return StatefulBuilder(
                        builder: (ctx, setItemState) {
                          final rate = double.tryParse(item.rateCtrl.text) ?? 0;
                          final units =
                              double.tryParse(item.unitsCtrl.text) ?? 0;
                          final total = rate * units;

                          // Force sync controllers each build for dynamic list items on mobile
                          final name = item.nameCtrl.text;
                          final rateText = item.rateCtrl.text;
                          final unitsText = item.unitsCtrl.text;
                          final note = item.noteCtrl.text;

                          return Container(
                            margin: EdgeInsets.only(bottom: 10.h),
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Item ${i + 1}',
                                      style: AppTypography.body().copyWith(
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF374151),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => setState(() {
                                        _manualItems[i].dispose();
                                        _manualItems.removeAt(i);
                                      }),
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 18.sp,
                                        color: Colors.red,
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                // Name
                                UltimateMobileTextField(
                                  controller: item.nameCtrl,
                                  decoration: _inputDeco('Item Name *'),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Name required'
                                      : null,
                                ),
                                SizedBox(height: 8.h),
                                // Date picker
                                UltimateMobileDatePicker(
                                   label: 'Date',
                                   value: item.date,
                                   onDateSelected: (picked) {
                                     if (picked != null) {
                                       setItemState(() => item.date = picked);
                                     }
                                   },
                                 ),
                                SizedBox(height: 8.h),
                                // Rate + Units
                                Row(
                                  children: [
                                    Expanded(
                                      child: UltimateMobileTextField(
                                        controller: item.rateCtrl,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: _inputDeco('Rate (\$) *'),
                                        onChanged: (_) => setItemState(() {}),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Rate required';
                                          }
                                          if (double.tryParse(v.trim()) ==
                                              null) {
                                            return 'Invalid';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Expanded(
                                      child: UltimateMobileTextField(
                                        controller: item.unitsCtrl,
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: _inputDeco('Units *'),
                                        onChanged: (_) => setItemState(() {}),
                                        validator: (v) {
                                          if (v == null || v.trim().isEmpty) {
                                            return 'Units required';
                                          }
                                          if (double.tryParse(v.trim()) ==
                                              null) {
                                            return 'Invalid';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                // Total amount (read-only display)
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12.w,
                                    vertical: 10.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.07,
                                    ),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Total Amount:',
                                        style: AppTypography.body().copyWith(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF374151),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '£${total.toStringAsFixed(2)}',
                                        style: AppTypography.body().copyWith(
                                          fontSize: 13.sp,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                // Note
                                UltimateMobileTextField(
                                  controller: item.noteCtrl,
                                  decoration: _inputDeco('Note (optional)'),
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            child: SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0E45BA),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isEdit ? 'Update Invoice' : 'Create Invoice',
                        style: AppTypography.body().copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//  Timesheet picker dialog

class _TimesheetPickerDialog extends StatefulWidget {
  final List<Timesheet> timesheets;
  final List<String> selected;

  const _TimesheetPickerDialog({
    required this.timesheets,
    required this.selected,
  });

  @override
  State<_TimesheetPickerDialog> createState() => _TimesheetPickerDialogState();
}

class _TimesheetPickerDialogState extends State<_TimesheetPickerDialog> {
  late final List<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: SizedBox(
        width: screenSize.width,
        height: screenSize.height * 0.80,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 16.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Select Approved Timesheets',
                      style: AppTypography.body().copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      '${_selected.length} selected',
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable table (header + rows share one horizontal scroll)
            Expanded(
              child: widget.timesheets.isEmpty
                  ? Center(
                      child: Text(
                        'No approved timesheets available',
                        style: AppTypography.body().copyWith(
                          fontSize: 14.sp,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header row
                            Container(
                              color: const Color(0xFFF8FAFC),
                              child: Row(
                                children: [
                                  _headerCell('', width: 52.w),
                                  _headerCell('DATE', width: 100.w),
                                  _headerCell('CUSTOMER / SITE', width: 200.w),
                                  _headerCell('STAFF', width: 140.w),
                                  _headerCell('CLOCK IN/OUT', width: 160.w),
                                  _headerCell('SERVICE GROUP', width: 140.w),
                                  _headerCell('PAY GROUP', width: 140.w),
                                  _headerCell('BREAK', width: 100.w),
                                  _headerCell('NOTES', width: 180.w),
                                ],
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFE5E7EB)),
                            // Data rows
                            ...widget.timesheets.asMap().entries.map((entry) {
                              final index = entry.key;
                              final ts = entry.value;
                              final isChecked = _selected.contains(ts.id);
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    isChecked
                                        ? _selected.remove(ts.id)
                                        : _selected.add(ts.id);
                                  });
                                },
                                child: Container(
                                  color: isChecked
                                      ? AppColors.primary.withValues(
                                          alpha: 0.07,
                                        )
                                      : index % 2 == 0
                                      ? Colors.white
                                      : const Color(0xFFFAFAFA),
                                  child: Row(
                                    children: [
                                      // Checkbox
                                      SizedBox(
                                        width: 52.w,
                                        child: Checkbox(
                                          value: isChecked,
                                          activeColor: AppColors.primary,
                                          onChanged: (val) {
                                            setState(() {
                                              val == true
                                                  ? _selected.add(ts.id)
                                                  : _selected.remove(ts.id);
                                            });
                                          },
                                        ),
                                      ),
                                      // DATE
                                      _dataCell(
                                        width: 100.w,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              DateFormat(
                                                'MMM d',
                                              ).format(ts.date),
                                              style: AppTypography.body()
                                                  .copyWith(
                                                    fontSize: 13.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(
                                                      0xFF111827,
                                                    ),
                                                  ),
                                            ),
                                            Text(
                                              DateFormat(
                                                'yyyy',
                                              ).format(ts.date),
                                              style: AppTypography.body()
                                                  .copyWith(
                                                    fontSize: 11.sp,
                                                    color: const Color(
                                                      0xFF6B7280,
                                                    ),
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // CUSTOMER / SITE
                                      _dataCell(
                                        width: 200.w,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              ts.customerName,
                                              style: AppTypography.body()
                                                  .copyWith(
                                                    fontSize: 13.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: const Color(
                                                      0xFF111827,
                                                    ),
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              ts.siteName,
                                              style: AppTypography.body()
                                                  .copyWith(
                                                    fontSize: 11.sp,
                                                    color: const Color(
                                                      0xFF6B7280,
                                                    ),
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // STAFF
                                      _dataCell(
                                        width: 140.w,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 30.w,
                                              height: 30.w,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(15.r),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  ts.staffName.isNotEmpty
                                                      ? ts.staffName
                                                            .substring(0, 1)
                                                            .toUpperCase()
                                                      : 'S',
                                                  style: AppTypography.body()
                                                      .copyWith(
                                                        fontSize: 12.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppColors.primary,
                                                      ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8.w),
                                            Expanded(
                                              child: Text(
                                                ts.staffName,
                                                style: AppTypography.body()
                                                    .copyWith(
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: const Color(
                                                        0xFF111827,
                                                      ),
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // CLOCK IN/OUT
                                      _dataCell(
                                        width: 160.w,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _clockChip(
                                              time: ts.clockInTime,
                                              icon: Icons.login,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(height: 4.h),
                                            _clockChip(
                                              time: ts.clockOutTime,
                                              icon: Icons.logout,
                                              color: Colors.orange,
                                            ),
                                          ],
                                        ),
                                      ),
                                      // SERVICE GROUP
                                      _dataCell(
                                        width: 140.w,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 6.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                            border: Border.all(
                                              color: Colors.purple.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.work_outline,
                                                size: 12.sp,
                                                color: Colors.purple.shade700,
                                              ),
                                              SizedBox(width: 4.w),
                                              Expanded(
                                                child: Text(
                                                  ts.serviceGroup,
                                                  style: AppTypography.body()
                                                      .copyWith(
                                                        fontSize: 11.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors
                                                            .purple
                                                            .shade700,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // PAY GROUP
                                      _dataCell(
                                        width: 140.w,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 6.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                            border: Border.all(
                                              color: Colors.teal.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.payments_outlined,
                                                size: 12.sp,
                                                color: Colors.teal.shade700,
                                              ),
                                              SizedBox(width: 4.w),
                                              Expanded(
                                                child: Text(
                                                  ts.payGroup.isEmpty
                                                      ? '—'
                                                      : ts.payGroup,
                                                  style: AppTypography.body()
                                                      .copyWith(
                                                        fontSize: 11.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            ts.payGroup.isEmpty
                                                            ? Colors
                                                                  .teal
                                                                  .shade300
                                                            : Colors
                                                                  .teal
                                                                  .shade700,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // BREAK
                                      _dataCell(
                                        width: 100.w,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 6.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.withValues(
                                              alpha: 0.08,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.coffee_outlined,
                                                size: 12.sp,
                                                color: Colors.green.shade700,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                '${ts.breakMinutes}m',
                                                style: AppTypography.body()
                                                    .copyWith(
                                                      fontSize: 12.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.green.shade700,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // NOTES
                                      _dataCell(
                                        width: 180.w,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 6.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withValues(
                                              alpha: 0.06,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.note_outlined,
                                                size: 12.sp,
                                                color: Colors.grey.shade600,
                                              ),
                                              SizedBox(width: 4.w),
                                              Expanded(
                                                child: Text(
                                                  ts.notes.isEmpty
                                                      ? '—'
                                                      : ts.notes,
                                                  style: AppTypography.body()
                                                      .copyWith(
                                                        fontSize: 11.sp,
                                                        color: ts.notes.isEmpty
                                                            ? Colors
                                                                  .grey
                                                                  .shade400
                                                            : Colors
                                                                  .grey
                                                                  .shade700,
                                                        fontStyle:
                                                            ts.notes.isEmpty
                                                            ? FontStyle.italic
                                                            : FontStyle.normal,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),
            ),

            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Footer actions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTypography.body().copyWith(
                        fontSize: 14.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Confirm (${_selected.length})',
                      style: AppTypography.body().copyWith(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label, {required double width}) {
    return SizedBox(
      width: width,
      height: 40.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: AppTypography.body().copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dataCell({required double width, required Widget child}) {
    return SizedBox(
      width: width,
      height: 68.h,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        child: child,
      ),
    );
  }

  Widget _clockChip({
    required DateTime? time,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color.shade700),
          SizedBox(width: 4.w),
          Text(
            time != null ? DateFormat('HH:mm').format(time) : '--:--',
            style: AppTypography.body().copyWith(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: color.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

//  Draft helper for billable item form state

class _BillableItemDraft {
  final String id;
  final TextEditingController nameCtrl;
  final TextEditingController rateCtrl;
  final TextEditingController unitsCtrl;
  final TextEditingController noteCtrl;
  DateTime? date;

  _BillableItemDraft()
    : id = DateTime.now().millisecondsSinceEpoch.toString(),
      nameCtrl = TextEditingController(),
      rateCtrl = TextEditingController(),
      unitsCtrl = TextEditingController(),
      noteCtrl = TextEditingController(),
      date = null;

  _BillableItemDraft.fromItem(ManualBillableItem item)
    : id = item.id,
      nameCtrl = TextEditingController(text: item.name),
      rateCtrl = TextEditingController(text: item.rate.toStringAsFixed(2)),
      unitsCtrl = TextEditingController(text: item.units.toStringAsFixed(2)),
      noteCtrl = TextEditingController(text: item.note),
      date = item.date;

  void dispose() {
    nameCtrl.dispose();
    rateCtrl.dispose();
    unitsCtrl.dispose();
    noteCtrl.dispose();
  }
}
