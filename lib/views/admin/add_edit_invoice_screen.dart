import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../viewmodels/invoice_viewmodel.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../services/admin_api_service.dart';
import '../../models/invoice_model.dart';
import '../../models/timesheet_model.dart';

// Ultimate Mobile TextField Solution - Bypass Android rendering issues
class UltimateMobileTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? initialValue;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final InputDecoration? decoration;
  final bool obscureText;
  final void Function(String?)? onSaved;

  const UltimateMobileTextField({
    super.key,
    required this.controller,
    this.initialValue,
    this.validator,
    this.keyboardType,
    this.decoration,
    this.obscureText = false,
    this.onSaved,
  });

  @override
  State<UltimateMobileTextField> createState() => _UltimateMobileTextFieldState();
}

class _UltimateMobileTextFieldState extends State<UltimateMobileTextField> {
  String _displayText = '';
  final FocusNode _focusNode = FocusNode();
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();
    _initializeText();
  }

  void _initializeText() {
    final initialText = widget.initialValue ?? widget.controller.text;
    _displayText = initialText;
    _internalController.text = initialText;
    widget.controller.text = initialText;
    
    debugPrint('ULTIMATE MOBILE TEXTFIELD: Initialized with text: "$initialText"');
    
    // Force immediate update
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always sync text on build
    final currentText = widget.controller.text;
    if (currentText.isNotEmpty && _displayText != currentText) {
      _displayText = currentText;
      _internalController.text = currentText;
      debugPrint('ULTIMATE MOBILE TEXTFIELD: Synced text: "$_displayText"');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Debug display - show current value
        if (_displayText.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              'Current: "$_displayText"',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        
        // Custom input field that bypasses TextFormField
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[400]!),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: TextField(
            controller: _internalController,
            focusNode: _focusNode,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            decoration: widget.decoration?.copyWith(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.black87,
            ),
            onChanged: (value) {
              _displayText = value;
              widget.controller.text = value;
              debugPrint('ULTIMATE MOBILE TEXTFIELD: Changed to: "$value"');
            },
            onTap: () {
              // Force focus and text display
              _focusNode.requestFocus();
              _internalController.selection = TextSelection.fromPosition(
                TextPosition(offset: _internalController.text.length),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _internalController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class AddEditInvoiceScreen extends StatefulWidget {
  final Invoice? invoice;

  const AddEditInvoiceScreen({super.key, this.invoice});

  @override
  State<AddEditInvoiceScreen> createState() => _AddEditInvoiceScreenState();
}

class _AddEditInvoiceScreenState extends State<AddEditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _selectedTimesheetIds = [];
  DateTime? _dueDate;
  final List<ManualBillableItem> _manualItems = [];
  final TextEditingController _notesController = TextEditingController();
  List<Timesheet> _approvedTimesheets = [];
  bool _isLoadingTimesheets = true;
  String? _selectedCustomerProfileId;
  List<Map<String, dynamic>> _customerInvoiceProfiles = [];
  bool _isLoadingProfiles = false;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    debugPrint('INVOICE FORM: Initializing form - isEdit: $_isEditMode');
    debugPrint('INVOICE FORM: Invoice data received: ${widget.invoice}');
    
    if (_isEditMode) {
      // For edit mode, load existing data
      _dueDate = widget.invoice!.dueDate;
      _notesController.text = widget.invoice!.notes ?? '';
      debugPrint('INVOICE FORM: Loaded edit data - Due Date: $_dueDate, Notes: "${_notesController.text}"');
      
      // Load existing items from the invoice
      if (widget.invoice!.items != null) {
        for (final item in widget.invoice!.items!) {
          if (item.referenceType == 'timesheet' && item.reference != null) {
            final ref = item.reference;
            if (ref is Map && ref['id'] != null) {
              _selectedTimesheetIds.add(ref['id'].toString());
            }
          }
        }
      }
      
      // Set existing customer invoice profile
      if (widget.invoice!.customerInvoiceProfile != null) {
        _selectedCustomerProfileId = widget.invoice!.customerInvoiceProfile!['id']?.toString();
      }
    } else {
      // Prefill due date with +5 days
      _dueDate = DateTime.now().add(const Duration(days: 5));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadApprovedTimesheets();
      _loadCustomerInvoiceProfiles();
    });
  }

  Future<void> _loadApprovedTimesheets() async {
    setState(() => _isLoadingTimesheets = true);
    try {
      final apiService = context.read<AdminApiService>();
      final data = await apiService.getTimesheetsByStatus('billable');
      final timesheets = data.map((json) => Timesheet.fromJson(json)).toList();
      setState(() {
        _approvedTimesheets = timesheets;
        _isLoadingTimesheets = false;
      });
    } catch (e) {
      setState(() => _isLoadingTimesheets = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading timesheets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadCustomerInvoiceProfiles() async {
    setState(() => _isLoadingProfiles = true);
    try {
      final apiService = context.read<AdminApiService>();
      final profiles = await apiService.getAllCustomerInvoiceProfiles();
      setState(() {
        _customerInvoiceProfiles = profiles;
        _isLoadingProfiles = false;
        
        // Auto-select first profile if none selected
        if (_selectedCustomerProfileId == null && profiles.isNotEmpty) {
          _selectedCustomerProfileId = profiles.first['id']?.toString();
        }
      });
    } catch (e) {
      setState(() => _isLoadingProfiles = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading customer profiles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mobile UI fix: Force controller text to display on mobile
    if (_isEditMode && widget.invoice != null) {
      final invoice = widget.invoice;
      
      // Always update controller text to force mobile UI refresh
      _notesController.text = invoice?.notes?.toString() ?? '';
      
      debugPrint('INVOICE FORM: Force updated controllers in build:');
      debugPrint('  Notes: "${_notesController.text}"');
      debugPrint('  Due Date: $_dueDate');
      debugPrint('  Selected Timesheet IDs: $_selectedTimesheetIds');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Invoice' : 'Create Invoice'),
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isEditMode ? 'Edit Invoice' : 'Add Invoice',
          style: AppTypography.title().copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF111827),
            size: 20.sp,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Customer Invoice Profile
                    _buildCustomerProfileSection(),
                    SizedBox(height: 24.h),

                    // 2. Choose Timesheets to Invoice
                    _buildTimesheetsSection(),
                    SizedBox(height: 24.h),

                    // 3. Due Date
                    _buildDueDateSection(),
                    SizedBox(height: 24.h),

                    // 4. Manual Billable Items
                    _buildManualItemsSection(),
                    SizedBox(height: 24.h),

                    // Notes
                    _buildNotesSection(),
                    SizedBox(height: 24.h),

                    // Summary
                    _buildSummarySection(),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.title().copyWith(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (action != null) action,
            ],
          ),
          SizedBox(height: 16.h),
          child,
        ],
      ),
    );
  }

  Widget _buildCustomerProfileSection() {
    return _buildSectionCard(
      title: 'Customer Invoice Profile',
      icon: Icons.business,
      child: _isLoadingProfiles
          ? const Center(child: CircularProgressIndicator())
          : _customerInvoiceProfiles.isEmpty
              ? Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'No customer invoice profiles available',
                          style: AppTypography.body().copyWith(
                            color: Colors.orange.shade700,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedCustomerProfileId,
                  decoration: InputDecoration(
                    labelText: 'Select Customer',
                    labelStyle: AppTypography.body().copyWith(
                      fontSize: 13.sp,
                      color: const Color(0xFF6B7280),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
                  ),
                  isExpanded: true,
                  items: _customerInvoiceProfiles.map((profile) {
                    final companyName = profile['company_name']?.toString() ?? 'Unknown';
                    final customerName = profile['customer']?['first_name'] != null
                        ? '${profile['customer']['first_name']} ${profile['customer']['last_name'] ?? ''}'.trim()
                        : companyName;
                    return DropdownMenuItem<String>(
                      value: profile['id']?.toString(),
                      child: Text(
                        customerName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCustomerProfileId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a customer';
                    }
                    return null;
                  },
                ),
    );
  }

  Widget _buildTimesheetsSection() {
    return _buildSectionCard(
      title: 'Choose Timesheets to Invoice',
      icon: Icons.playlist_add_check,
      child: _isLoadingTimesheets
          ? const Center(child: CircularProgressIndicator())
          : _approvedTimesheets.isEmpty
              ? Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'No timesheets available for invoicing',
                          style: AppTypography.body().copyWith(
                            color: Colors.orange.shade700,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: _approvedTimesheets.map((timesheet) {
                    final isSelected = _selectedTimesheetIds.contains(timesheet.id);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedTimesheetIds.remove(timesheet.id);
                          } else {
                            _selectedTimesheetIds.add(timesheet.id);
                          }
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        padding: EdgeInsets.all(14.w),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.05)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFD1D5DB),
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 16.sp,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${timesheet.staffName} - ${timesheet.customerName}',
                                    style: AppTypography.body().copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 12.sp,
                                        color: const Color(0xFF6B7280),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        timesheet.siteName,
                                        style: AppTypography.body().copyWith(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Icon(
                                        Icons.calendar_today,
                                        size: 12.sp,
                                        color: const Color(0xFF6B7280),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        DateFormat('MMM d, y').format(timesheet.date),
                                        style: AppTypography.body().copyWith(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildDueDateSection() {
    return _buildSectionCard(
      title: 'Due Date (Optional)',
      icon: Icons.calendar_month,
      child: InkWell(
        onTap: _selectDueDate,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              Icon(Icons.event, color: AppColors.primary, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  _dueDate != null
                      ? DateFormat('MMMM d, yyyy').format(_dueDate!)
                      : 'Select due date (prefilled with +5 days)',
                  style: AppTypography.body().copyWith(
                    fontSize: 14.sp,
                    color: _dueDate != null
                        ? const Color(0xFF111827)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
              if (_dueDate != null)
                GestureDetector(
                  onTap: () => setState(() => _dueDate = null),
                  child: Icon(
                    Icons.clear,
                    size: 18.sp,
                    color: const Color(0xFF6B7280),
                  ),
                )
              else
                Icon(
                  Icons.chevron_right,
                  size: 20.sp,
                  color: const Color(0xFF6B7280),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManualItemsSection() {
    return _buildSectionCard(
      title: 'Manual Billable Items',
      icon: Icons.receipt_long,
      action: ElevatedButton.icon(
        onPressed: _addManualItem,
        icon: Icon(Icons.add, size: 16.sp),
        label: const Text('Add'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      ),
      child: _manualItems.isEmpty
          ? Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 18.sp,
                    color: const Color(0xFF6B7280),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'No manual items added yet',
                    style: AppTypography.body().copyWith(
                      color: const Color(0xFF6B7280),
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: _manualItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return _buildManualItemCard(item, index);
              }).toList(),
            ),
    );
  }

  Widget _buildManualItemCard(ManualBillableItem item, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: AppTypography.body().copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18.sp),
                color: AppColors.primary,
                onPressed: () => _editManualItem(index),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 18.sp),
                color: Colors.red,
                onPressed: () => _deleteManualItem(index),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(minWidth: 32.w, minHeight: 32.h),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              _buildItemDetail('Rate', '\$${item.rate.toStringAsFixed(2)}'),
              SizedBox(width: 16.w),
              _buildItemDetail('Units', item.units.toStringAsFixed(2)),
              SizedBox(width: 16.w),
              _buildItemDetail(
                'Total',
                '\$${item.totalAmount.toStringAsFixed(2)}',
                highlight: true,
              ),
            ],
          ),
          if (item.note.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.note_outlined,
                    size: 14.sp,
                    color: const Color(0xFF6B7280),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      item.note,
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemDetail(
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.body().copyWith(
            fontSize: 11.sp,
            color: const Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: AppTypography.body().copyWith(
            fontSize: 14.sp,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            color: highlight ? AppColors.primary : const Color(0xFF111827),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _buildSectionCard(
      title: 'Notes (Optional)',
      icon: Icons.note_alt_outlined,
      child: UltimateMobileTextField(
        controller: _notesController,
        initialValue: _isEditMode && widget.invoice != null 
            ? (widget.invoice!.notes?.toString() ?? '')
            : null,
        decoration: InputDecoration(
          labelText: 'Notes (Optional)',
          labelStyle: AppTypography.body().copyWith(
            fontSize: 13.sp,
            color: const Color(0xFF6B7280),
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
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
        ),
      ),
      contentPadding: EdgeInsets.all(14.w),
      style: AppTypography.body().copyWith(fontSize: 14.sp),
    );
  }

  Widget _buildSummarySection() {
    return Consumer<AdminViewModel>(
      builder: (context, adminViewModel, child) {
        final selectedTimesheets = adminViewModel.timesheets
            .where((t) => _selectedTimesheetIds.contains(t.id))
            .toList();

        final timesheetTotal = context
            .read<InvoiceViewModel>()
            .calculateTimesheetTotal(selectedTimesheets);
        final manualTotal = context
            .read<InvoiceViewModel>()
            .calculateManualItemsTotal(_manualItems);
        final subtotal = timesheetTotal + manualTotal;
        final taxAmount = subtotal * 0.1;
        final total = subtotal + taxAmount;

        return Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.calculate,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'Invoice Summary',
                    style: AppTypography.title().copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              _buildSummaryRow('Timesheet Total', timesheetTotal),
              SizedBox(height: 10.h),
              _buildSummaryRow('Manual Items', manualTotal),
              SizedBox(height: 10.h),
              const Divider(),
              SizedBox(height: 10.h),
              _buildSummaryRow('Subtotal', subtotal),
              SizedBox(height: 10.h),
              _buildSummaryRow('Tax (10%)', taxAmount),
              SizedBox(height: 10.h),
              Divider(color: AppColors.primary.withOpacity(0.3), thickness: 2),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Text(
                    'Total Amount',
                    style: AppTypography.title().copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '\$${total.toStringAsFixed(2)}',
                    style: AppTypography.title().copyWith(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      children: [
        Text(
          label,
          style: AppTypography.body().copyWith(
            fontSize: 14.sp,
            color: const Color(0xFF6B7280),
          ),
        ),
        const Spacer(),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: AppTypography.body().copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTypography.body().copyWith(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _saveInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: _isSubmitting
                  ? SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _isEditMode ? 'Update Invoice' : 'Create Invoice',
                      style: AppTypography.body().copyWith(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDueDate() async {
    final picked = await UltimateMobileDatePicker.show(
      context,
      initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 5)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _addManualItem() {
    _showManualItemDialog();
  }

  void _editManualItem(int index) {
    _showManualItemDialog(item: _manualItems[index], index: index);
  }

  void _deleteManualItem(int index) {
    setState(() => _manualItems.removeAt(index));
  }

  void _showManualItemDialog({ManualBillableItem? item, int? index}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final rateController = TextEditingController(
      text: item?.rate.toString() ?? '',
    );
    final unitsController = TextEditingController(
      text: item?.units.toString() ?? '',
    );
    final noteController = TextEditingController(text: item?.note ?? '');

    void disposeDialogControllers() {
      nameController.dispose();
      rateController.dispose();
      unitsController.dispose();
      noteController.dispose();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          item == null ? 'Add Manual Item' : 'Edit Manual Item',
          style: AppTypography.title().copyWith(fontSize: 18.sp),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UltimateMobileTextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g., Equipment Rental',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: UltimateMobileTextField(
                      controller: rateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Rate *',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: UltimateMobileTextField(
                      controller: unitsController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Units *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: noteController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Add additional details...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final rate = double.tryParse(rateController.text) ?? 0;
              final units = double.tryParse(unitsController.text) ?? 0;
              final note = noteController.text.trim();

              if (name.isEmpty || rate <= 0 || units <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Please fill all required fields'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                );
                return;
              }

              final newItem = ManualBillableItem(
                id:
                    item?.id ??
                    DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                rate: rate,
                units: units,
                note: note,
              );

              setState(() {
                if (index != null) {
                  _manualItems[index] = newItem;
                } else {
                  _manualItems.add(newItem);
                }
              });

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ).whenComplete(disposeDialogControllers);
  }

  void _saveInvoice() async {
    if (_selectedCustomerProfileId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a customer invoice profile'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
      return;
    }

    if (_selectedTimesheetIds.isEmpty && _manualItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select timesheets or add manual items'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      final apiService = context.read<AdminApiService>();

      final invoiceItems = <Map<String, dynamic>>[];

      // Add timesheet items
      for (final timesheetId in _selectedTimesheetIds) {
        invoiceItems.add({
          'reference_type': 'timesheet',
          'reference_id': int.tryParse(timesheetId) ?? 0,
        });
      }

      // Add manual billable items
      for (final item in _manualItems) {
        invoiceItems.add({
          'reference_type': 'manual-billable',
          'name': item.name,
          'rate': item.rate,
          'units': item.units,
          'total_amount': item.totalAmount,
          'date': item.date?.toIso8601String().split('T')[0] ?? DateTime.now().toIso8601String().split('T')[0],
          'note': item.note,
        });
      }

      final payload = {
        'reference_number': widget.invoice?.invoiceNumber ??
            'INV-${DateTime.now().year}-${(DateTime.now().millisecondsSinceEpoch % 1000000).toString().padLeft(6, '0')}',
        'customer_invoice_profile_id': int.tryParse(_selectedCustomerProfileId!) ?? 1,
        'due_date': _dueDate?.toIso8601String().split('T')[0] ??
            DateTime.now().add(const Duration(days: 5)).toIso8601String().split('T')[0],
        'invoice_items': invoiceItems,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      if (_isEditMode) {
        await apiService.updateInvoice(widget.invoice!.id, payload);
      } else {
        await apiService.createInvoice(payload);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Invoice updated successfully'
                  : 'Invoice created successfully',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
      );
    }
  }
}
