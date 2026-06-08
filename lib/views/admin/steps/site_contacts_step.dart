import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_constants.dart';
import '../../../constants/typography.dart';
import '../../../models/site_models.dart';
import '../../../providers/site_creation_provider.dart';
import '../../../widgets/ultimate_mobile_widgets.dart';

class SiteContactsStep extends StatefulWidget {
  const SiteContactsStep({super.key});

  @override
  State<SiteContactsStep> createState() => _SiteContactsStepState();
}

class _SiteContactsStepState extends State<SiteContactsStep> {
  void _showAddEditContactDialog({SiteContact? contact, int? index}) {
    final provider = context.read<SiteCreationProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _ContactFormSheet(
        contact: contact,
        onSave: (newContact) {
          if (index != null) {
            provider.updateContact(index, newContact);
          } else {
            provider.addContact(newContact);
          }
        },
      ),
    );
  }

  void _confirmDeleteContact(int index) {
    final provider = context.read<SiteCreationProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.removeContact(index);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(SiteContact contact, int index) {
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
          Text(
            '${contact.firstName} ${contact.lastName}',
            style: AppTypography.body().copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            contact.position,
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          if (contact.email.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(
                contact.email,
                style: AppTypography.body().copyWith(
                  fontSize: 12.sp,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          if (contact.contactNumber.isNotEmpty)
            Text(
              contact.contactNumber,
              style: AppTypography.body().copyWith(
                fontSize: 12.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _showAddEditContactDialog(contact: contact, index: index),
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
                  onPressed: () => _confirmDeleteContact(index),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<SiteCreationProvider>(
      builder: (context, provider, child) {
        final contacts = provider.contacts;

        return SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _showAddEditContactDialog(),
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
              if (contacts.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.contacts,
                        size: 48.sp,
                        color: const Color(0xFFD1D5DB),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'No contacts added yet',
                        style: AppTypography.body().copyWith(
                          fontSize: 14.sp,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...contacts.asMap().entries.map(
                      (e) => _buildContactCard(e.value, e.key),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _ContactFormSheet extends StatefulWidget {
  final SiteContact? contact;
  final ValueChanged<SiteContact> onSave;

  const _ContactFormSheet({this.contact, required this.onSave});

  @override
  State<_ContactFormSheet> createState() => _ContactFormSheetState();
}

class _ContactFormSheetState extends State<_ContactFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _positionController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;

    _firstNameController = TextEditingController(
      text: contact?.firstName ?? '',
    );
    _lastNameController = TextEditingController(text: contact?.lastName ?? '');
    _positionController = TextEditingController(text: contact?.position ?? '');
    _emailController = TextEditingController(text: contact?.email ?? '');
    _mobileController = TextEditingController(
      text: contact?.contactNumber ?? '',
    );
    _notesController = TextEditingController(text: contact?.notes ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final contact = SiteContact(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        position: _positionController.text.trim(),
        email: _emailController.text.trim(),
        contactNumber: _mobileController.text.trim(),
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      widget.onSave(contact);
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
                  widget.contact != null ? 'Edit Contact' : 'Add Contact',
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
                    Row(
                      children: [
                        Expanded(
                          child: UltimateMobileTextField(
                            controller: _firstNameController,
                            decoration: _fieldDecoration(
                              labelText: 'First Name *',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: UltimateMobileTextField(
                            controller: _lastNameController,
                            decoration: _fieldDecoration(
                              labelText: 'Last Name *',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    UltimateMobileTextField(
                      controller: _positionController,
                      decoration: _fieldDecoration(labelText: 'Position *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a position';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    UltimateMobileTextField(
                      controller: _emailController,
                      decoration: _fieldDecoration(
                        labelText: 'Email (Optional)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            !RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value.trim())) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    UltimateMobileTextField(
                      controller: _mobileController,
                      decoration: _fieldDecoration(
                        labelText: 'Mobile Number *',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a mobile number';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 10.h),
                    UltimateMobileTextField(
                      controller: _notesController,
                      decoration: _fieldDecoration(
                        labelText: 'Notes (Optional)',
                      ),
                      maxLines: 3,
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
                          widget.contact != null
                              ? 'Update Contact'
                              : 'Add Contact',
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
