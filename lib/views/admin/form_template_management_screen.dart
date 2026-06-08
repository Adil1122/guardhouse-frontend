import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../models/form_template_model.dart';
import '../../viewmodels/form_template_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/ultimate_mobile_widgets.dart';


class _ElementDraft {
  TemplateFieldType fieldType;
  final TextEditingController controller;

  _ElementDraft({required this.fieldType, String title = ''})
      : controller = TextEditingController(text: title);

  factory _ElementDraft.fromElement(FormElement element) =>
      _ElementDraft(fieldType: element.fieldType, title: element.title);

  FormElement toElement() =>
      FormElement(fieldType: fieldType, title: controller.text.trim());

  void dispose() => controller.dispose();
}

class FormTemplateManagementScreen extends StatefulWidget {
  const FormTemplateManagementScreen({super.key});

  @override
  State<FormTemplateManagementScreen> createState() =>
      _FormTemplateManagementScreenState();
}

class _FormTemplateManagementScreenState
    extends State<FormTemplateManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FormTemplateViewModel>().loadTemplates();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FormTemplate> _filtered(List<FormTemplate> items) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              t.type.apiValue.toLowerCase().contains(q) ||
              t.type.displayName.toLowerCase().contains(q),
        )
        .toList();
  }

  bool _hasPrivilege(String action) {
    return context.read<AuthViewModel>().hasPrivilege('form_template', action);
  }

  Future<void> _showTemplateSheet({FormTemplate? template}) async {
    final viewModel = context.read<FormTemplateViewModel>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) =>
          _TemplateFormSheet(viewModel: viewModel, template: template),
    );
  }

  Future<void> _confirmDelete(FormTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"? This action cannot be undone.'),
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
      final viewModel = context.read<FormTemplateViewModel>();
      final success = await viewModel.deleteTemplate(template.id!);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${template.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.error ?? 'Failed to delete template'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FormTemplateViewModel>(
      builder: (context, viewModel, child) {
        final all = viewModel.templates;
        final filtered = _filtered(all);

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
                                  'Form Templates',
                                  style: AppTypography.title().copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${all.length} total template${all.length == 1 ? "" : "s"}',
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
                                  hintText: 'Search templates...',
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
                Expanded(
                  child: viewModel.isLoading && all.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: viewModel.loadTemplates,
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
                                  onPressed: () => _showTemplateSheet(),
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
                                    'Add Template',
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
                                    'No templates found',
                                    style: AppTypography.body().copyWith(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                )
                              else
                                ...filtered.map(
                                  (t) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: _TemplateCard(
                                      template: t,
                                      onEdit: _hasPrivilege('update') ? () => _showTemplateSheet(template: t) : null,
                                      onDelete: _hasPrivilege('delete') ? () => _confirmDelete(t) : null,
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

class _TemplateCard extends StatelessWidget {
  final FormTemplate template;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canEdit;
  final bool canDelete;

  const _TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
    this.canEdit = true,
    this.canDelete = true,
  });

  @override
  Widget build(BuildContext context) {
    final elements = template.elements;

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
                  template.name,
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
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  template.type.displayName,
                  style: AppTypography.body().copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '${elements.length} element${elements.length == 1 ? '' : 's'}',
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 10.h),
          if (elements.isNotEmpty) ...[
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              children: elements.take(4).map((e) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    e.title,
                    style: AppTypography.body().copyWith(
                      fontSize: 10.sp,
                      color: const Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10.h),
          ],
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

class _TemplateFormSheet extends StatefulWidget {
  final FormTemplateViewModel viewModel;
  final FormTemplate? template;

  const _TemplateFormSheet({required this.viewModel, this.template});

  @override
  State<_TemplateFormSheet> createState() => _TemplateFormSheetState();
}

class _TemplateFormSheetState extends State<_TemplateFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late FormTemplateType _selectedType;
  late List<_ElementDraft> _elements;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.template?.name ?? '');
    _selectedType = widget.template?.type ?? FormTemplateType.incidentReport;
    _elements = widget.template != null
        ? widget.template!.elements.map(_ElementDraft.fromElement).toList()
        : [_ElementDraft(fieldType: TemplateFieldType.text)];
  }

  @override
  void dispose() {
    _nameController.dispose();
    for (final e in _elements) {
      e.dispose();
    }
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

  void _addElement() {
    setState(() {
      _elements.add(_ElementDraft(fieldType: TemplateFieldType.text));
    });
  }

  void _removeElement(int index) {
    if (_elements.length <= 1) return;
    setState(() {
      _elements[index].dispose();
      _elements.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final builtElements = _elements.map((e) => e.toElement()).toList();
    final isEdit = widget.template != null;

    try {
      if (isEdit) {
        await widget.viewModel.updateTemplate(
          widget.template!.copyWith(
            name: _nameController.text.trim(),
            type: _selectedType,
            elements: builtElements,
            updatedAt: DateTime.now(),
          ),
        );
      } else {
        await widget.viewModel.createTemplate(
          FormTemplate(
            name: _nameController.text.trim(),
            type: _selectedType,
            elements: builtElements,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        String errorMsg = isEdit
            ? 'Failed to update template.'
            : 'Failed to create template.';
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isEdit = widget.template != null;

    // Force sync element titles each build for mobile reliability
    for (var i = 0; i < _elements.length; i++) {
      final draft = _elements[i];
      // Note: we can't easily check if it's "empty" because they might be creating it,
      // but for Edit mode, we want to ensure it's synced at least once.
      // The current draft already holds the controller.
    }
    
    if (isEdit && _nameController.text.isEmpty && widget.template != null) {
      _nameController.text = widget.template!.name;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                  isEdit ? 'Edit Template' : 'Add Template',
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
                      decoration: _inputDecoration('Template Name *'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Template name is required'
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    UltimateMobileDropdown<FormTemplateType>(
                      value: _selectedType,
                      decoration: _inputDecoration('Template Type *'),
                      items: FormTemplateType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t.displayName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedType = v);
                      },
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Form Elements',
                          style: AppTypography.body().copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _addElement,
                          icon: Icon(Icons.add, size: 18.sp),
                          label: Text(
                            'Add Element',
                            style: AppTypography.body().copyWith(
                              fontSize: 13.sp,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0E45BA),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    ...List.generate(_elements.length, (i) {
                      final draft = _elements[i];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Element ${i + 1}',
                                    style: AppTypography.body().copyWith(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF374151),
                                    ),
                                  ),
                                  if (_elements.length > 1)
                                    GestureDetector(
                                      onTap: () => _removeElement(i),
                                      child: Icon(
                                        Icons.delete_outline_rounded,
                                        size: 20.sp,
                                        color: const Color(0xFFEF4444),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              UltimateMobileDropdown<TemplateFieldType>(
                                value: draft.fieldType,
                                decoration: _inputDecoration('Element Type *'),
                                items: TemplateFieldType.values
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t.name),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => draft.fieldType = v);
                                  }
                                },
                              ),
                              SizedBox(height: 10.h),
                              UltimateMobileTextField(
                                controller: draft.controller,
                                decoration: _inputDecoration('Element Title *'),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Element title is required'
                                        : null,
                              ),
                            ],
                          ),
                        ),
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEdit ? 'Update Form Template' : 'Create Form Template',
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
