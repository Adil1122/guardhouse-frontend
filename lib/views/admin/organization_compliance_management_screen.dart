import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../models/organization_compliance_model.dart';
import '../../viewmodels/organization_compliance_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'package:security_app/widgets/ultimate_mobile_widgets.dart';

class OrganizationComplianceManagementScreen extends StatefulWidget {
  const OrganizationComplianceManagementScreen({super.key});

  @override
  State<OrganizationComplianceManagementScreen> createState() =>
      _OrganizationComplianceManagementScreenState();
}

class _OrganizationComplianceManagementScreenState
    extends State<OrganizationComplianceManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrganizationComplianceViewModel>().loadCompliances();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrganizationCompliance> _filtered(List<OrganizationCompliance> items) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((c) => c.name.toLowerCase().contains(q)).toList();
  }

  bool _hasPrivilege(String action) {
    return context.read<AuthViewModel>().hasPrivilege('organization_compliance', action);
  }

  Future<void> _showComplianceSheet({OrganizationCompliance? compliance}) async {
    final viewModel = context.read<OrganizationComplianceViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _ComplianceFormSheet(
        viewModel: viewModel,
        compliance: compliance,
      ),
    );
  }

  Future<void> _confirmDelete(OrganizationCompliance compliance) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Compliance'),
        content: Text('Are you sure you want to delete "${compliance.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      context.read<OrganizationComplianceViewModel>().deleteCompliance(compliance.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OrganizationComplianceViewModel>(
      builder: (context, viewModel, child) {
        final all = viewModel.compliances;
        final filtered = _filtered(all);

        return Scaffold(
          backgroundColor: const Color(0xFFE5E7EB),
          body: SafeArea(
            child: Column(
              children: [
                // Blue header
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
                                  'Organization Compliance',
                                  style: AppTypography.title().copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${all.length} total compliance${all.length == 1 ? "" : "s"}',
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
                        padding: EdgeInsets.symmetric(horizontal: 14.w),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 22.sp, color: Colors.white),
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
                                  hintText: 'Search compliances...',
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
                // Body
                Expanded(
                  child: viewModel.isLoading && all.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: viewModel.loadCompliances,
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                            children: [
                              if (_hasPrivilege('create'))
                              SizedBox(
                                width: double.infinity,
                                height: 52.h,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showComplianceSheet(),
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
                                    'Add Compliance',
                                    style: AppTypography.body().copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                              if (_hasPrivilege('create')) SizedBox(height: 12.h),
                              if (filtered.isEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 48.h),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No compliances found',
                                    style: AppTypography.body().copyWith(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                )
                              else
                                ...filtered.map(
                                  (c) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: _ComplianceCard(
                                      compliance: c,
                                      onEdit: _hasPrivilege('update') ? () => _showComplianceSheet(compliance: c) : null,
                                      onDelete: _hasPrivilege('delete') ? () => _confirmDelete(c) : null,
                                      canEdit: _hasPrivilege('update'),
                                      canDelete: _hasPrivilege('delete'),
                                    ),
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
}

class _ComplianceCard extends StatelessWidget {
  final OrganizationCompliance compliance;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canEdit;
  final bool canDelete;

  const _ComplianceCard({
    required this.compliance,
    required this.onEdit,
    required this.onDelete,
    this.canEdit = true,
    this.canDelete = true,
  });

  @override
  Widget build(BuildContext context) {
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
                  compliance.name,
                  style: AppTypography.body().copyWith(
                    fontSize: 16.sp,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (compliance.isCritical)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Critical',
                    style: AppTypography.body().copyWith(
                      fontSize: 11.sp,
                      color: const Color(0xFFDC2626),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Customer visible: ${compliance.showToCustomer ? "Yes" : "No"}',
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _ComplianceInfoBox(
                  label: 'Remind in Days',
                  value: '${compliance.remindInDays} days',
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _ComplianceInfoBox(
                  label: 'Status',
                  value: compliance.isCritical ? 'Critical' : 'Normal',
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (canEdit || canDelete)
          Row(
            children: [
              if (canEdit)
              Expanded(
                child: SizedBox(
                  height: 38.h,
                  child: ElevatedButton(
                    onPressed: onEdit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD1D5DB),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
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
              ),
              if (canEdit && canDelete) SizedBox(width: 10.w),
              if (canDelete)
              Expanded(
                child: SizedBox(
                  height: 38.h,
                  child: ElevatedButton(
                    onPressed: onDelete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF7CDD1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6.r),
                      ),
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComplianceInfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _ComplianceInfoBox({required this.label, required this.value});

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

class _ComplianceFormSheet extends StatefulWidget {
  final OrganizationComplianceViewModel viewModel;
  final OrganizationCompliance? compliance;

  const _ComplianceFormSheet({required this.viewModel, this.compliance});

  @override
  State<_ComplianceFormSheet> createState() => _ComplianceFormSheetState();
}

class _ComplianceFormSheetState extends State<_ComplianceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late int _remindInDays;
  late bool _isCritical;
  late bool _showToCustomer;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.compliance?.name ?? '');
    _remindInDays = widget.compliance?.remindInDays ?? 30;
    _isCritical = widget.compliance?.isCritical ?? false;
    _showToCustomer = widget.compliance?.showToCustomer ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final isEdit = widget.compliance != null;
    if (isEdit) {
      await widget.viewModel.updateCompliance(
        widget.compliance!.copyWith(
          name: _nameController.text.trim(),
          remindInDays: _remindInDays,
          isCritical: _isCritical,
          showToCustomer: _showToCustomer,
          updatedAt: DateTime.now(),
        ),
      );
    } else {
      await widget.viewModel.createCompliance(
        OrganizationCompliance(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          remindInDays: _remindInDays,
          isCritical: _isCritical,
          showToCustomer: _showToCustomer,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.compliance != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                Container(
                  width: 42.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  isEdit ? 'Edit Compliance' : 'Add Compliance',
                  style: AppTypography.title().copyWith(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, bottomPadding),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UltimateMobileTextField(
                      controller: _nameController,
                      decoration: _inputDecoration('Compliance Name *'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                    ),
                    SizedBox(height: 12.h),
                    UltimateMobileDropdown<int>(
                      value: _remindInDays,
                      decoration: _inputDecoration('Remind in Days *'),
                      items: [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
                          .map((d) => DropdownMenuItem(value: d, child: Text('$d days')))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _remindInDays = v);
                      },
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18.sp,
                            color: _isCritical
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF9CA3AF),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Is Critical',
                              style: AppTypography.body().copyWith(
                                fontSize: 14.sp,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ),
                          Switch(
                            value: _isCritical,
                            onChanged: (v) => setState(() => _isCritical = v),
                            activeColor: const Color(0xFFDC2626),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 18.sp,
                            color: _showToCustomer
                                ? const Color(0xFF10B981)
                                : const Color(0xFF9CA3AF),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              'Show to Customer',
                              style: AppTypography.body().copyWith(
                                fontSize: 14.sp,
                                color: const Color(0xFF374151),
                              ),
                            ),
                          ),
                          Switch(
                            value: _showToCustomer,
                            onChanged: (v) => setState(() => _showToCustomer = v),
                            activeColor: const Color(0xFF10B981),
                          ),
                        ],
                      ),
                    ),
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdit ? 'Update Compliance' : 'Create Compliance',
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
