import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../viewmodels/admin_viewmodel.dart';

class ShiftNotesScreen extends StatefulWidget {
  const ShiftNotesScreen({super.key});

  @override
  State<ShiftNotesScreen> createState() => _ShiftNotesScreenState();
}

class _ShiftNotesScreenState extends State<ShiftNotesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadShiftNotes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _noteType(Map<String, dynamic> note) {
    final value = (note['type'] ?? '').toString().trim();
    return value.isEmpty ? 'internal' : value;
  }

  String _noteText(Map<String, dynamic> note) {
    final value = (note['note'] ?? '').toString().trim();
    return value.isEmpty ? 'No note content' : value;
  }

  String _createdBy(Map<String, dynamic> note) {
    final value = (note['createdBy'] ?? '').toString().trim();
    return value.isEmpty ? 'Unknown User' : value;
  }

  String _createdDate(Map<String, dynamic> note) {
    final value = (note['createdDate'] ?? '').toString().trim();
    return value.isEmpty ? '--' : value;
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case 'short':
        return const Color(0xFF3B82F6); // Blue
      case 'long':
        return const Color(0xFF8B5CF6); // Purple
      case 'customer':
        return const Color(0xFF10B981); // Green
      case 'internal':
        return const Color(0xFF6B7280); // Gray
      case 'invoice':
        return const Color(0xFFF59E0B); // Yellow/Orange
      case 'position':
        return const Color(0xFFEF4444); // Red
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }

  Color _typeBackgroundColor(String type) {
    switch (type.toLowerCase()) {
      case 'short':
        return const Color(0xFFEFF6FF); // Light blue
      case 'long':
        return const Color(0xFFF3E8FF); // Light purple
      case 'customer':
        return const Color(0xFFECFDF5); // Light green
      case 'internal':
        return const Color(0xFFF3F4F6); // Light gray
      case 'invoice':
        return const Color(0xFFFEF3C7); // Light yellow
      case 'position':
        return const Color(0xFFFEE2E2); // Light red
      default:
        return const Color(0xFFF3F4F6); // Light gray
    }
  }

  Future<void> _showNoteSheet({Map<String, dynamic>? note}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => _NoteFormSheet(isEdit: note != null, note: note),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            note == null
                ? 'Note created successfully'
                : 'Note updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> note) async {
    final noteId = note['id'];
    if (noteId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AdminViewModel>().deleteShiftNote(
        noteId.toString(),
      );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        final allNotes = viewModel.shiftNotes;
        final query = _searchController.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? allNotes
            : allNotes.where((note) {
                return _noteType(note).toLowerCase().contains(query) ||
                    _noteText(note).toLowerCase().contains(query) ||
                    _createdBy(note).toLowerCase().contains(query);
              }).toList();

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
                                  'Shift Notes',
                                  style: AppTypography.title().copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${allNotes.length} total notes',
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
                          style: AppTypography.body().copyWith(
                            fontSize: 15.sp,
                            color: Colors.white,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search notes...',
                            hintStyle: AppTypography.body().copyWith(
                              fontSize: 15.sp,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 25.sp,
                              color: Colors.white,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(top: 12.h),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: viewModel.isLoading && allNotes.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadShiftNotes(),
                          child: ListView(
                            padding: EdgeInsets.fromLTRB(
                              16.w,
                              16.h,
                              16.w,
                              24.h,
                            ),
                            children: [
                              SizedBox(
                                width: double.infinity,
                                height: 52.h,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showNoteSheet(),
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
                                    'Add Note',
                                    style: AppTypography.body().copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 14.h),
                              if (filtered.isEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 40.h),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No notes found',
                                    style: AppTypography.body().copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                )
                              else
                                ...filtered.map(
                                  (note) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: _NoteCard(
                                      type: _noteType(note),
                                      noteText: _noteText(note),
                                      createdBy: _createdBy(note),
                                      createdDate: _createdDate(note),
                                      typeColor: _typeColor(_noteType(note)),
                                      typeBackgroundColor: _typeBackgroundColor(
                                        _noteType(note),
                                      ),
                                      onEdit: () => _showNoteSheet(note: note),
                                      onDelete: () => _confirmDelete(note),
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

class _NoteCard extends StatelessWidget {
  final String type;
  final String noteText;
  final String createdBy;
  final String createdDate;
  final Color typeColor;
  final Color typeBackgroundColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.type,
    required this.noteText,
    required this.createdBy,
    required this.createdDate,
    required this.typeColor,
    required this.typeBackgroundColor,
    required this.onEdit,
    required this.onDelete,
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: typeBackgroundColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  type.toUpperCase(),
                  style: AppTypography.body().copyWith(
                    fontSize: 11.sp,
                    color: typeColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                createdDate,
                style: AppTypography.body().copyWith(
                  fontSize: 11.sp,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            noteText,
            style: AppTypography.body().copyWith(
              fontSize: 14.sp,
              color: const Color(0xFF111827),
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          Text(
            'By $createdBy',
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onEdit,
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
                  onPressed: onDelete,
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
    );
  }
}

class _NoteFormSheet extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? note;

  const _NoteFormSheet({required this.isEdit, this.note});

  @override
  State<_NoteFormSheet> createState() => _NoteFormSheetState();
}

class _NoteFormSheetState extends State<_NoteFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _noteController;

  final List<String> _noteTypes = [
    'short',
    'long',
    'customer',
    'internal',
    'invoice',
    'position',
  ];

  bool _isSubmitting = false;
  String? _selectedType;

  @override
  void initState() {
    super.initState();
    final note = widget.note;

    _noteController = TextEditingController(
      text: (note?['note'] ?? '').toString(),
    );

    _selectedType = (note?['type'] ?? '').toString().isEmpty
        ? null
        : note!['type'].toString();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    final notePayload = {
      if (widget.isEdit) 'id': widget.note?['id'],
      'type': _selectedType,
      'note': _noteController.text.trim(),
      'createdBy': 'Admin', // In real app, get from auth
      'createdDate': DateTime.now().toIso8601String().split('T')[0],
    };

    final viewModel = context.read<AdminViewModel>();
    final success = widget.isEdit
        ? await viewModel.updateShiftNote(notePayload)
        : await viewModel.createShiftNote(notePayload);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(viewModel.errorMessage ?? 'Failed to save note'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, bottomPadding + 16.h),
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
              widget.isEdit ? 'Edit Note' : 'Add Note',
              style: AppTypography.title().copyWith(
                fontSize: 19.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF111827),
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: _inputDecoration('Choose Type *'),
                      items: _noteTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedType = value),
                      validator: (value) =>
                          value == null ? 'Type is required' : null,
                    ),
                    SizedBox(height: 12.h),
                    Expanded(
                      child: TextFormField(
                        controller: _noteController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        decoration: _inputDecoration(
                          'Note *',
                        ).copyWith(alignLabelWithHint: true),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                            ? 'Note is required'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),
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
                        widget.isEdit ? 'Update Note' : 'Create Note',
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
    );
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
}
