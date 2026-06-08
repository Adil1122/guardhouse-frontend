import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../../constants/typography.dart';
import '../../../models/site_models.dart';
import '../../../providers/site_creation_provider.dart';
import '../../../widgets/ultimate_mobile_widgets.dart';

class SiteDocumentsStep extends StatefulWidget {
  const SiteDocumentsStep({super.key});

  @override
  State<SiteDocumentsStep> createState() => _SiteDocumentsStepState();
}

class _SiteDocumentsStepState extends State<SiteDocumentsStep> {
  void _showAddDocumentDialog() {
    final provider = context.read<SiteCreationProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _DocumentFormSheet(
        onSave: (document) {
          provider.addDocument(document);
        },
      ),
    );
  }

  void _showEditDocumentDialog(SiteDocument document, int index) {
    final provider = context.read<SiteCreationProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _DocumentFormSheet(
        document: document,
        onSave: (updated) {
          final list = List<SiteDocument>.from(provider.documents);
          list[index] = updated;
          provider.updateDocuments(list);
        },
      ),
    );
  }

  void _confirmDeleteDocument(int index) {
    final provider = context.read<SiteCreationProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.removeDocument(index);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(SiteDocument document, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    Icons.description,
                    color: Colors.blue,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.name,
                        style: AppTypography.title().copyWith(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${document.files.length} file(s)',
                        style: AppTypography.body().copyWith(
                          fontSize: 14.sp,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: document.offsiteVisibility
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    document.offsiteVisibility ? 'Offsite' : 'Onsite Only',
                    style: AppTypography.body().copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: document.offsiteVisibility
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showEditDocumentDialog(document, index),
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
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _confirmDeleteDocument(index),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SiteCreationProvider>(
      builder: (context, provider, child) {
        final documents = provider.documents;

        return Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _showAddDocumentDialog,
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
              SizedBox(height: 24.h),
              if (documents.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64.sp,
                          color: const Color(0xFFD1D5DB),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No documents added yet',
                          style: AppTypography.title().copyWith(
                            fontSize: 18.sp,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'Add documents that staff can access\nat this site location.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body().copyWith(
                            fontSize: 14.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      return _buildDocumentCard(documents[index], index);
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

class _DocumentFormSheet extends StatefulWidget {
  final SiteDocument? document;
  final ValueChanged<SiteDocument> onSave;

  const _DocumentFormSheet({this.document, required this.onSave});

  @override
  State<_DocumentFormSheet> createState() => _DocumentFormSheetState();
}

class _DocumentFormSheetState extends State<_DocumentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  bool _offsiteVisibility = false;
  final List<String> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.document?.name ?? '');
    _offsiteVisibility = widget.document?.offsiteVisibility ?? false;
    if (widget.document != null) {
      _selectedFiles.addAll(widget.document!.files);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.paths.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(
            result.paths.where((path) => path != null).map((path) => path!));
      });
    }
  }

  String _getFileName(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      if (_selectedFiles.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one file'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final document = SiteDocument(
        name: _nameController.text.trim(),
        files: _selectedFiles,
        offsiteVisibility: _offsiteVisibility,
      );
      widget.onSave(document);
      Navigator.pop(context);
    }
  }

  InputDecoration _fieldDecoration({String? hintText, String? labelText}) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: AppTypography.body().copyWith(
        fontSize: 13.sp,
        color: const Color(0xFF6B7280),
      ),
      hintStyle: AppTypography.body().copyWith(
        fontSize: 14.sp,
        color: const Color(0xFF9CA3AF),
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

    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
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
                  widget.document != null ? 'Edit Document' : 'Add Document',
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
                    UltimateMobileTextField(
                      controller: _nameController,
                      decoration: _fieldDecoration(labelText: ' Name *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a name';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    GestureDetector(
                      onTap: _pickFiles,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 14.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file,
                              color: Color(0xFF6B7280),
                              size: 20,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Add Files',
                              style: AppTypography.body().copyWith(
                                fontSize: 14.sp,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_selectedFiles.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 10.h),
                        child: Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: _selectedFiles.asMap().entries.map((entry) {
                            final index = entry.key;
                            final file = entry.value;
                            return Chip(
                              label: Text(
                                _getFileName(file),
                                style: AppTypography.body().copyWith(
                                  fontSize: 12.sp,
                                  color: const Color(0xFF111827),
                                ),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _selectedFiles.removeAt(index);
                                });
                              },
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFD1D5DB)),
                            );
                          }).toList(),
                        ),
                      ),
                    SizedBox(height: 10.h),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F1F1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: SwitchListTile(
                        value: _offsiteVisibility,
                        onChanged: (value) =>
                            setState(() => _offsiteVisibility = value),
                        title: Text(
                          'Viewable offsite',
                          style: AppTypography.body().copyWith(
                            fontSize: 14.sp,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        subtitle: Text(
                          'Allow staff to view this document remotely',
                          style: AppTypography.body().copyWith(
                            fontSize: 12.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        activeColor: const Color(0xFF0E45BA),
                      ),
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
                          widget.document != null
                              ? 'Update Document'
                              : 'Add Document',
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
