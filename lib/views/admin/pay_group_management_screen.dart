import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../viewmodels/pay_group_viewmodel.dart';
import '../../models/pay_group_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/ultimate_mobile_widgets.dart';


class PayGroupManagementScreen extends StatefulWidget {
  const PayGroupManagementScreen({super.key});

  @override
  State<PayGroupManagementScreen> createState() =>
      _PayGroupManagementScreenState();
}

class _PayGroupManagementScreenState extends State<PayGroupManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PayGroupViewModel>().loadPayGroups();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PayGroup> _getFilteredPayGroups(List<PayGroup> groups) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return groups;
    return groups.where((g) {
      return g.name.toLowerCase().contains(query) ||
          g.type.displayName.toLowerCase().contains(query);
    }).toList();
  }

  bool _hasPrivilege(String action) {
    return context.read<AuthViewModel>().hasPrivilege('pay_group', action);
  }

  Future<void> _confirmDelete(PayGroupViewModel viewModel, PayGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Pay Group'),
        content: Text('Are you sure you want to delete "${group.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await viewModel.deletePayGroup(group.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${group.name} deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(viewModel.error ?? 'Failed to delete pay group'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PayGroupViewModel>(
      builder: (context, viewModel, child) {
        final allGroups = viewModel.payGroups;
        final filteredGroups = _getFilteredPayGroups(allGroups);

        return Scaffold(
          backgroundColor: const Color(0xFFE5E7EB),
          body: SafeArea(
            child: Column(
              children: [
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
                                  'Pay Groups Management',
                                  style: AppTypography.title().copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${allGroups.length} total groups',
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
                      Container(
                        height: 52.h,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A43C7),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          textAlignVertical: TextAlignVertical.center,
                          style: AppTypography.body().copyWith(
                            fontSize: 15.sp,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search pay groups...',
                            hintStyle: AppTypography.body().copyWith(
                              fontSize: 15.sp,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 12.w, right: 8.w),
                              child: Icon(
                                Icons.search,
                                size: 22.sp,
                                color: Colors.white,
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(),
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 16.h,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: viewModel.isLoading && allGroups.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadPayGroups(),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              16.w,
                              16.h,
                              16.w,
                              24.h,
                            ),
                            children: [
                              if (_hasPrivilege('create'))
                              SizedBox(
                                width: double.infinity,
                                height: 52.h,
                                child: ElevatedButton.icon(
                                  onPressed: () =>
                                      _showPayGroupSheet(viewModel),
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
                                    'Add Pay Group',
                                    style: AppTypography.body().copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                              if (_hasPrivilege('create')) SizedBox(height: 14.h),
                              if (filteredGroups.isEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 40.h),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No pay groups found',
                                    style: AppTypography.body().copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                )
                              else
                                ...filteredGroups.asMap().entries.map(
                                  (entry) => Padding(
                                    key: ValueKey(entry.value.id),
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: _buildPayGroupCard(entry.value, viewModel),
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

  Widget _buildPayGroupCard(PayGroup group, PayGroupViewModel viewModel) {
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
          Row(
            children: [
              Expanded(
                child: Text(
                  group.name,
                  style: AppTypography.body().copyWith(
                    fontSize: 16.sp,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: group.type == PayType.hourly
                      ? const Color(0xFFDEF7EC)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  group.type.displayName,
                  style: AppTypography.body().copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: group.type == PayType.hourly
                        ? const Color(0xFF065F46)
                        : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            'Base Rate: £${group.baseRate.toStringAsFixed(2)}',
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF4B5563),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${group.rates.length} rate${group.rates.length == 1 ? '' : 's'} configured',
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 10.h),
          if (_hasPrivilege('update') || _hasPrivilege('delete'))
          Row(
            children: [
              if (_hasPrivilege('update'))
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showPayGroupSheet(viewModel, group: group),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD1D5DB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    minimumSize: Size.fromHeight(38.h),
                  ),
                  child: Text(
                    'Edit',
                    style: AppTypography.body().copyWith(
                      color: const Color(0xFF111827),
                      fontWeight: FontWeight.w500,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
              if (_hasPrivilege('update') && _hasPrivilege('delete')) SizedBox(width: 10.w),
              if (_hasPrivilege('delete'))
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmDelete(viewModel, group),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7CDD1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    minimumSize: Size.fromHeight(38.h),
                  ),
                  child: Text(
                    'Delete',
                    style: AppTypography.body().copyWith(
                      color: const Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
              if (_hasPrivilege('update') || _hasPrivilege('delete')) SizedBox(width: 10.w),
              SizedBox(
                height: 38.h,
                width: 38.h,
                child: ElevatedButton(
                  onPressed: () =>
                      _showPayRatesSheet(viewModel, groupId: group.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
              ),
            ],
          ) else
            Row(
              children: [
                const Spacer(),
                SizedBox(
                  height: 38.h,
                  width: 38.h,
                  child: ElevatedButton(
                    onPressed: () =>
                        _showPayRatesSheet(viewModel, groupId: group.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _showPayGroupSheet(
    PayGroupViewModel viewModel, {
    PayGroup? group,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _PayGroupFormSheet(viewModel: viewModel, group: group),
    );
  }

  Future<void> _showPayRatesSheet(
    PayGroupViewModel viewModel, {
    required String groupId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _PayRatesSheet(viewModel: viewModel, groupId: groupId),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pay Group Form Sheet — bottom sheet popup
// ─────────────────────────────────────────────────────────────────────────────

class _PayGroupFormSheet extends StatefulWidget {
  final PayGroupViewModel viewModel;
  final PayGroup? group;

  const _PayGroupFormSheet({required this.viewModel, this.group});

  @override
  State<_PayGroupFormSheet> createState() => _PayGroupFormSheetState();
}

class _PayGroupFormSheetState extends State<_PayGroupFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _baseRateController;
  late PayType _selectedType;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _baseRateController = TextEditingController(
      text: widget.group != null
          ? widget.group!.baseRate.toStringAsFixed(2)
          : '',
    );
    _selectedType = widget.group?.type ?? PayType.hourly;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseRateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    debugPrint('Submitting pay group...');

    final baseRateText = _baseRateController.text.trim();
    if (baseRateText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a base rate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final baseRate = double.tryParse(baseRateText);
    if (baseRate == null || baseRate <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid base rate'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      if (widget.group == null) {
        debugPrint('Creating new pay group...');
        await widget.viewModel.createPayGroup(
          PayGroup(
            name: _nameController.text.trim(),
            type: _selectedType,
            baseRate: baseRate,
            rates: [
              PayRate(
                selectedDays: ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'],
                payRate: baseRate,
                fromTime: const TimeOfDay(hour: 0, minute: 0),
                toTime: const TimeOfDay(hour: 23, minute: 59),
              ),
            ],
          ),
        );
        debugPrint('Create completed');
      } else {
        debugPrint('Updating pay group ${widget.group!.id}...');
        await widget.viewModel.updatePayGroup(
          widget.group!.copyWith(
            name: _nameController.text.trim(),
            type: _selectedType,
            baseRate: baseRate,
            rates: widget.group!.rates,
          ),
        );
        debugPrint('Update completed');
      }

      debugPrint('Closing dialog...');
      if (mounted) {
        Navigator.pop(context);
        debugPrint('Dialog should be closed');
      }
    } catch (e) {
      debugPrint('Error caught in submit: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        String errorMsg = widget.group == null
            ? 'Failed to create pay group.'
            : 'Failed to update pay group.';
        if (e.toString().contains('Exception:')) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.group != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
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
                  isEdit ? 'Edit Pay Group' : 'Add Pay Group',
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
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16.w,
                8.h,
                16.w,
                16.h + bottomPadding,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Group Details',
                      style: AppTypography.body().copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    UltimateMobileTextField(
                      controller: _nameController,
                      decoration: _inputDecoration('Group Name *'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Group name is required'
                          : null,
                    ),
                    SizedBox(height: 10.h),
                    UltimateMobileDropdown<PayType>(
                      value: _selectedType,
                      decoration: _inputDecoration('Pay Type *'),
                      items: PayType.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedType = v);
                      },
                    ),
                    SizedBox(height: 10.h),
                    UltimateMobileTextField(
                      controller: _baseRateController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: _inputDecoration('Base Rate *'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Base rate is required';
                        }
                        if (double.tryParse(v.trim()) == null) {
                          return 'Enter valid number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20.h),
                    SizedBox(
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
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isEdit
                                    ? 'Update Pay Group'
                                    : 'Create Pay Group',
                                style: AppTypography.body().copyWith(
                                  color: Colors.white,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pay Rates Sheet — 90% bottom sheet with rates list + add button
// ─────────────────────────────────────────────────────────────────────────────

class _PayRatesSheet extends StatefulWidget {
  final PayGroupViewModel viewModel;
  final String groupId;

  const _PayRatesSheet({required this.viewModel, required this.groupId});

  @override
  State<_PayRatesSheet> createState() => _PayRatesSheetState();
}

class _PayRatesSheetState extends State<_PayRatesSheet> {
  PayGroup? get _group => widget.viewModel.payGroups
      .where((g) => g.id == widget.groupId)
      .firstOrNull;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  void _onViewModelChanged() {
    if (mounted) setState(() {});
  }

  bool _hasPrivilege(String action) {
    return context.read<AuthViewModel>().hasPrivilege('pay_group', action);
  }

  Future<void> _openRateForm({PayRate? rate}) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _PayRateFormDialog(
        viewModel: widget.viewModel,
        groupId: widget.groupId,
        rate: rate,
        onSaved: () => setState(() {}),
      ),
    );
  }

  Future<void> _deleteRate(String rateId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Rate'),
        content: const Text('Remove this pay rate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && mounted) {
      final success = await widget.viewModel.deleteRateFromGroup(widget.groupId, rateId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rate deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {});
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.viewModel.error ?? 'Failed to delete rate'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = _group;
    final rates = group?.rates ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Column(
        children: [
          // Header
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pay Rates',
                      style: AppTypography.title().copyWith(
                        fontSize: 19.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF111827),
                      ),
                    ),
                    if (_hasPrivilege('create'))
                    GestureDetector(
                      onTap: () => _openRateForm(),
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E45BA),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Divider(height: 1.h, color: const Color(0xFFE5E7EB)),
              ],
            ),
          ),
          // Rates list
          Expanded(
            child: rates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48.sp,
                          color: const Color(0xFFD1D5DB),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No pay rates yet',
                          style: AppTypography.body().copyWith(
                            fontSize: 14.sp,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Tap + to add the first rate',
                          style: AppTypography.body().copyWith(
                            fontSize: 12.sp,
                            color: const Color(0xFFD1D5DB),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 24.h),
                    itemCount: rates.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (_, i) {
                      final rate = rates[i];
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
                            // Days
                            Wrap(
                              spacing: 6.w,
                              runSpacing: 4.h,
                              children: rate.selectedDays.map((day) {
                                return Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Text(
                                    day,
                                    style: AppTypography.body().copyWith(
                                      fontSize: 11.sp,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Text(
                                  '£',
                                  style: AppTypography.body().copyWith(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF6B7280),
                                  ),
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  rate.payRate.toStringAsFixed(2),
                                  style: AppTypography.body().copyWith(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Icon(
                                  Icons.access_time,
                                  size: 14.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${rate.fromTime.format(context)} – ${rate.toTime.format(context)}',
                                  style: AppTypography.body().copyWith(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                            if (_hasPrivilege('update') || _hasPrivilege('delete')) SizedBox(height: 10.h),
                            if (_hasPrivilege('update') || _hasPrivilege('delete'))
                            Row(
                              children: [
                                if (_hasPrivilege('update'))
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _openRateForm(rate: rate),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD1D5DB),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      minimumSize: Size.fromHeight(36.h),
                                    ),
                                    child: Text(
                                      'Edit',
                                      style: AppTypography.body().copyWith(
                                        color: const Color(0xFF111827),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_hasPrivilege('update') && _hasPrivilege('delete')) SizedBox(width: 10.w),
                                if (_hasPrivilege('delete'))
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _deleteRate(rate.id),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF7CDD1),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      minimumSize: Size.fromHeight(36.h),
                                    ),
                                    child: Text(
                                      'Delete',
                                      style: AppTypography.body().copyWith(
                                        color: const Color(0xFFEF4444),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pay Rate Form Dialog — add / edit a single pay rate
// ─────────────────────────────────────────────────────────────────────────────

class _PayRateFormDialog extends StatefulWidget {
  final PayGroupViewModel viewModel;
  final String groupId;
  final PayRate? rate;
  final VoidCallback onSaved;

  const _PayRateFormDialog({
    required this.viewModel,
    required this.groupId,
    this.rate,
    required this.onSaved,
  });

  @override
  State<_PayRateFormDialog> createState() => _PayRateFormDialogState();
}

class _PayRateFormDialogState extends State<_PayRateFormDialog> {
  static const _allDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _payRateController;
  late Set<String> _selectedDays;
  late TimeOfDay _fromTime;
  late TimeOfDay _toTime;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _payRateController = TextEditingController(
      text: widget.rate != null ? widget.rate!.payRate.toStringAsFixed(2) : '',
    );
    _selectedDays = {...?widget.rate?.selectedDays};
    _fromTime = widget.rate?.fromTime ?? const TimeOfDay(hour: 8, minute: 0);
    _toTime = widget.rate?.toTime ?? const TimeOfDay(hour: 17, minute: 0);
  }

  @override
  void dispose() {
    _payRateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one day')),
      );
      return;
    }
    setState(() => _isSubmitting = true);

    final payRate = double.tryParse(_payRateController.text.trim()) ?? 0;

    try {
      bool success;
      if (widget.rate == null) {
        success = await widget.viewModel.addRateToGroup(
          widget.groupId,
          PayRate(
            selectedDays: _selectedDays.toList(),
            payRate: payRate,
            fromTime: _fromTime,
            toTime: _toTime,
          ),
        );
      } else {
        success = await widget.viewModel.updateRateInGroup(
          widget.groupId,
          widget.rate!.copyWith(
            selectedDays: _selectedDays.toList(),
            payRate: payRate,
            fromTime: _fromTime,
            toTime: _toTime,
          ),
        );
      }
      
      if (mounted) {
        if (success) {
          widget.onSaved();
          Navigator.pop(context);
        } else {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.viewModel.error ?? 'Failed to save pay rate'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.viewModel.error ?? 'Failed to save pay rate'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.rate != null;

    // Force sync controller on mobile each build
    if (isEdit && _payRateController.text.isEmpty && widget.rate != null) {
      _payRateController.text = widget.rate!.payRate.toStringAsFixed(2);
    }

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Pay Rate' : 'Add Pay Rate',
                    style: AppTypography.title().copyWith(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close,
                      size: 20.sp,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 18.h),

              // Choose Days
              Text(
                'Choose Days',
                style: AppTypography.body().copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              SizedBox(height: 8.h),
              ..._allDays.map((day) {
                final selected = _selectedDays.contains(day);
                return InkWell(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedDays.remove(day);
                    } else {
                      _selectedDays.add(day);
                    }
                  }),
                  borderRadius: BorderRadius.circular(8.r),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 6.h,
                      horizontal: 4.w,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20.w,
                          height: 20.w,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            border: Border.all(
                              color: selected
                                  ? AppColors.primary
                                  : const Color(0xFFD1D5DB),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: selected
                              ? Icon(
                                  Icons.check,
                                  size: 13.sp,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        SizedBox(width: 10.w),
                        Text(
                          day,
                          style: AppTypography.body().copyWith(
                            fontSize: 13.sp,
                            color: selected
                                ? const Color(0xFF111827)
                                : const Color(0xFF4B5563),
                            fontWeight: selected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              SizedBox(height: 16.h),

              // Pay Rate
              UltimateMobileTextField(
                controller: _payRateController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration('Pay Rate (£) *'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Pay rate is required';
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 12.h),

              // From / To Time
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From Time',
                          style: AppTypography.body().copyWith(
                            fontSize: 13.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _fromTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (t != null) setState(() => _fromTime = t);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  _fromTime.format(context),
                                  style: AppTypography.body().copyWith(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'To Time',
                          style: AppTypography.body().copyWith(
                            fontSize: 13.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        GestureDetector(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _toTime,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: AppColors.primary,
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (t != null) setState(() => _toTime = t);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 12.h,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              border: Border.all(
                                color: const Color(0xFFD1D5DB),
                              ),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 16.sp,
                                  color: const Color(0xFF6B7280),
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  _toTime.format(context),
                                  style: AppTypography.body().copyWith(
                                    fontSize: 13.sp,
                                    color: const Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // Submit button
              SizedBox(
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
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEdit ? 'Update Rate' : 'Add Rate',
                          style: AppTypography.body().copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
