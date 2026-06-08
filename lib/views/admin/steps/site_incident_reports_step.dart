import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../constants/typography.dart';
import '../../../providers/site_creation_provider.dart';
import '../../../viewmodels/form_template_viewmodel.dart';
import '../../../models/form_template_model.dart';

class SiteIncidentReportsStep extends StatefulWidget {
  const SiteIncidentReportsStep({super.key});

  @override
  State<SiteIncidentReportsStep> createState() =>
      _SiteIncidentReportsStepState();
}

class _SiteIncidentReportsStepState extends State<SiteIncidentReportsStep> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FormTemplateViewModel>().loadTemplates();
    });
  }

  void _showAddIncidentReportDialog() {
    final siteProvider = context.read<SiteCreationProvider>();
    final templateViewModel = context.read<FormTemplateViewModel>();

    final availableForms = templateViewModel.templates
        .where(
          (form) =>
              form.type == FormTemplateType.incidentReport ||
              form.type == FormTemplateType.securityBreach,
        )
        .map((form) => {'id': form.id, 'name': form.name})
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _IncidentReportFormSheet(
        availableForms: availableForms,
        existingFormIds: siteProvider.incidentReportFormIds,
        onSave: (formId) {
          final updated = List<String>.from(siteProvider.incidentReportFormIds);
          if (!updated.contains(formId)) {
            updated.add(formId);
          }
          siteProvider.updateIncidentReportFormIds(updated);
        },
      ),
    );
  }

  void _showEditIncidentReportDialog(String formId, int index) {
    final siteProvider = context.read<SiteCreationProvider>();
    final templateViewModel = context.read<FormTemplateViewModel>();

    final availableForms = templateViewModel.templates
        .where(
          (form) =>
              form.type == FormTemplateType.incidentReport ||
              form.type == FormTemplateType.securityBreach,
        )
        .map((form) => {'id': form.id, 'name': form.name})
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _IncidentReportFormSheet(
        availableForms: availableForms,
        existingFormIds: siteProvider.incidentReportFormIds,
        editingFormId: formId,
        onSave: (newFormId) {
          final updated = List<String>.from(siteProvider.incidentReportFormIds);
          updated[index] = newFormId;
          siteProvider.updateIncidentReportFormIds(updated);
        },
      ),
    );
  }

  void _removeForm(String formId, SiteCreationProvider provider) {
    final updated = List<String>.from(provider.incidentReportFormIds)
      ..remove(formId);
    provider.updateIncidentReportFormIds(updated);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SiteCreationProvider, FormTemplateViewModel>(
      builder: (context, provider, templateViewModel, child) {
        final availableForms = templateViewModel.templates
            .where(
              (form) =>
                  form.type == FormTemplateType.incidentReport ||
                  form.type == FormTemplateType.securityBreach,
            )
            .map((form) => {'id': form.id, 'name': form.name})
            .toList();

        final selectedFormIds = provider.incidentReportFormIds;

        return Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showAddIncidentReportDialog,
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
              ),
              SizedBox(height: 16.h),
              if (templateViewModel.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (selectedFormIds.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 48.sp,
                          color: const Color(0xFFD1D5DB),
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          'No incident report forms added yet',
                          style: AppTypography.body().copyWith(
                            fontSize: 14.sp,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Tap + to add',
                          style: AppTypography.body().copyWith(
                            fontSize: 12.sp,
                            color: const Color(0xFFD1D5DB),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: selectedFormIds.length,
                    itemBuilder: (context, index) {
                      final formId = selectedFormIds[index];
                      final form = availableForms.firstWhere(
                        (f) => f['id']?.toString() == formId,
                        orElse: () => {'id': formId, 'name': 'Unknown Form'},
                      );
                      final formName =
                          form['name']?.toString() ?? 'Unknown Form';

                      return Container(
                        margin: EdgeInsets.only(bottom: 12.h),
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
                                Container(
                                  padding: EdgeInsets.all(8.w),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Icon(
                                    Icons.description,
                                    color: Colors.orange,
                                    size: 18.sp,
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: Text(
                                    formName,
                                    style: AppTypography.body().copyWith(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF111827),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _showEditIncidentReportDialog(
                                      formId,
                                      index,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFD1D5DB),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
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
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        _removeForm(formId, provider),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF7CDD1),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      minimumSize: Size.fromHeight(38.h),
                                    ),
                                    child: Text(
                                      'Remove',
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
      },
    );
  }
}

class _IncidentReportFormSheet extends StatefulWidget {
  final List<Map<String, dynamic>> availableForms;
  final List<String> existingFormIds;
  final String? editingFormId;
  final ValueChanged<String> onSave;

  const _IncidentReportFormSheet({
    required this.availableForms,
    required this.existingFormIds,
    this.editingFormId,
    required this.onSave,
  });

  @override
  State<_IncidentReportFormSheet> createState() =>
      _IncidentReportFormSheetState();
}

class _IncidentReportFormSheetState extends State<_IncidentReportFormSheet> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedFormId;

  @override
  void initState() {
    super.initState();
    _selectedFormId = widget.editingFormId;
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_selectedFormId!);
      Navigator.pop(context);
    }
  }

  InputDecoration _fieldDecoration({String? labelText}) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: AppTypography.body().copyWith(
        fontSize: 13.sp,
        color: const Color(0xFF6B7280),
      ),
      filled: true,
      fillColor: const Color(0xFFF1F1F1),
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
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.r),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    final unselectedForms = widget.availableForms
        .where(
          (f) =>
              !widget.existingFormIds.contains(f['id']?.toString()) ||
              f['id']?.toString() == widget.editingFormId,
        )
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
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
                  widget.editingFormId != null
                      ? 'Edit Incident Report'
                      : 'Add Incident Report',
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
                  children: [
                    if (unselectedForms.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.h),
                        child: Center(
                          child: Text(
                            'All available forms have already been added.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body().copyWith(
                              fontSize: 14.sp,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        value: _selectedFormId,
                        isExpanded: true,
                        decoration: _fieldDecoration(
                          labelText: 'Incident Report *',
                        ),
                        items: unselectedForms.map((form) {
                          return DropdownMenuItem<String>(
                            value: form['id']?.toString(),
                            child: Text(
                              form['name']?.toString() ?? 'Untitled Form',
                              style: AppTypography.body().copyWith(
                                fontSize: 14.sp,
                                color: const Color(0xFF111827),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedFormId = value),
                        validator: (value) {
                          if (value == null) {
                            return 'Please select an incident report';
                          }
                          return null;
                        },
                        dropdownColor: Colors.white,
                      ),
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: double.infinity,
                        height: 46.h,
                        child: ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0E45BA),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: Text(
                            widget.editingFormId != null
                                ? 'Update Report'
                                : 'Add Report',
                            style: AppTypography.body().copyWith(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
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
