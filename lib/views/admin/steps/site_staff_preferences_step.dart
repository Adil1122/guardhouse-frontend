import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../constants/typography.dart';
import '../../../models/site_models.dart';
import '../../../providers/site_creation_provider.dart';
import '../../../viewmodels/admin_viewmodel.dart';

class SiteStaffPreferencesStep extends StatefulWidget {
  const SiteStaffPreferencesStep({super.key});

  @override
  State<SiteStaffPreferencesStep> createState() =>
      _SiteStaffPreferencesStepState();
}

class _SiteStaffPreferencesStepState extends State<SiteStaffPreferencesStep>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadStaffMembers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddStaffPreferenceDialog(String mode) {
    final siteProvider = context.read<SiteCreationProvider>();
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _StaffPreferenceFormSheet(
        mode: mode,
        onSave: (preference) {
          siteProvider.addPreference(preference);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text(
                mode == 'preferred' ? 'Preference added' : 'Preference added',
              ),
              backgroundColor: Colors.green,
            ),
          );
        },
        existingReferenceIds: siteProvider.preferences
            .map((sp) => sp.referenceId?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList(),
      ),
    );
  }

  void _showEditStaffPreferenceDialog(SitePreference preference, int index) {
    final siteProvider = context.read<SiteCreationProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _StaffPreferenceFormSheet(
        mode: preference.setting ?? 'preferred',
        initialReferenceId: preference.referenceId?.toString(),
        onSave: (updated) {
          siteProvider.updatePreference(index, updated);
        },
        existingReferenceIds: siteProvider.preferences
            .where((sp) => sp.referenceId != preference.referenceId)
            .map((sp) => sp.referenceId?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList(),
      ),
    );
  }

  void _confirmDeleteStaffPreference(int index) {
    // Capture the provider reference before showing the dialog
    final siteProvider = context.read<SiteCreationProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Preference'),
        content: const Text(
          'Are you sure you want to remove this staff preference?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              siteProvider.removePreference(index);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffPreferenceCard(
    SitePreference preference,
    int index,
    List<Map<String, dynamic>> staff,
  ) {
    final staffMember = staff.firstWhere(
      (s) => (s['profile_id'] ?? s['id']).toString() == preference.referenceId?.toString(),
      orElse: () => {'name': 'Unknown Staff', 'email': ''},
    );

    final firstName = (staffMember['firstName'] ?? staffMember['first_name'] ?? '').toString().trim();
    final lastName = (staffMember['lastName'] ?? staffMember['last_name'] ?? '').toString().trim();
    final name = '$firstName $lastName'.trim();

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
            name.isNotEmpty ? name : 'Unknown Staff',
            style: AppTypography.body().copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF111827),
            ),
          ),
          if (staffMember['email'] != null &&
              staffMember['email'].toString().isNotEmpty) ...[
            SizedBox(height: 3.h),
            Text(
              staffMember['email'],
              style: AppTypography.body().copyWith(
                fontSize: 12.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _showEditStaffPreferenceDialog(preference, index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD1D5DB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
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
              SizedBox(width: 10.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _confirmDeleteStaffPreference(index),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7CDD1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    minimumSize: Size.fromHeight(36.h),
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
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SiteCreationProvider, AdminViewModel>(
      builder: (context, provider, adminViewModel, child) {
        final staffPreferences = provider.preferences;
        final staff = adminViewModel.staffMembers;

        final preferred =
            staffPreferences.where((sp) => sp.setting == 'preferred' && sp.mode == 'staff-setting').toList();
        final blacklisted =
            staffPreferences.where((sp) => sp.setting == 'blacklisted' && sp.mode == 'staff-setting').toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    final mode =
                        _tabController.index == 0 ? 'preferred' : 'blacklisted';
                    _showAddStaffPreferenceDialog(mode);
                  },
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
            ),
            SizedBox(height: 12.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF0E45BA),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF0E45BA),
                indicatorWeight: 2,
                labelStyle: AppTypography.body().copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTypography.body().copyWith(
                  fontSize: 13.sp,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.thumb_up_outlined, size: 15),
                        SizedBox(width: 6.w),
                        Text('Preferred (${preferred.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.block_outlined, size: 15),
                        SizedBox(width: 6.w),
                        Text('Blacklist (${blacklisted.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTabContent(
                    preferred,
                    staffPreferences,
                    staff,
                    'preferred',
                  ),
                  _buildTabContent(
                    blacklisted,
                    staffPreferences,
                    staff,
                    'blacklisted',
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTabContent(
    List<SitePreference> filtered,
    List<SitePreference> allPreferences,
    List<Map<String, dynamic>> staff,
    String mode,
  ) {
    if (staff.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt, size: 48.sp, color: const Color(0xFFD1D5DB)),
            SizedBox(height: 12.h),
            Text(
              'No staff available',
              style: AppTypography.body().copyWith(
                fontSize: 14.sp,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode == 'preferred'
                  ? Icons.thumb_up_outlined
                  : Icons.block_outlined,
              size: 48.sp,
              color: const Color(0xFFD1D5DB),
            ),
            SizedBox(height: 12.h),
            Text(
              mode == 'preferred'
                  ? 'No preferred staff yet'
                  : 'No blacklisted staff yet',
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
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final pref = filtered[index];
        final fullIndex = allPreferences.indexWhere(
          (sp) => sp.referenceId == pref.referenceId && sp.setting == pref.setting && sp.mode == pref.mode,
        );
        return _buildStaffPreferenceCard(pref, fullIndex, staff);
      },
    );
  }
}

class _StaffPreferenceFormSheet extends StatefulWidget {
  final String mode;
  final String? initialReferenceId;
  final ValueChanged<SitePreference> onSave;
  final List<String> existingReferenceIds;

  const _StaffPreferenceFormSheet({
    required this.mode,
    this.initialReferenceId,
    required this.onSave,
    required this.existingReferenceIds,
  });

  @override
  State<_StaffPreferenceFormSheet> createState() =>
      _StaffPreferenceFormSheetState();
}

class _StaffPreferenceFormSheetState extends State<_StaffPreferenceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late String? _selectedReferenceId;

  @override
  void initState() {
    super.initState();
    _selectedReferenceId = widget.initialReferenceId;
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(
        SitePreference(
          referenceId: int.tryParse(_selectedReferenceId ?? ''),
          mode: 'staff-setting',
          setting: widget.mode,
        ),
      );
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
    final isPreferred = widget.mode == 'preferred';

    return Consumer<AdminViewModel>(
      builder: (context, adminViewModel, child) {
        final uniqueStaff = <String, Map<String, dynamic>>{};
        for (final s in adminViewModel.staffMembers) {
          final id = (s['profile_id'] ?? s['id'])?.toString() ?? '';
          if (id.isNotEmpty && !widget.existingReferenceIds.contains(id)) {
            uniqueStaff[id] = s;
          }
        }
        final availableStaff = uniqueStaff.values.toList();

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
                      isPreferred ? 'Add Preferred Staff' : 'Add to Blacklist',
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
                        if (availableStaff.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 32.h),
                            child: Center(
                              child: Text(
                                'All staff members have already been added.',
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
                            value: _selectedReferenceId,
                            isExpanded: true,
                            decoration: _fieldDecoration(
                              labelText: 'Choose Staff Member *',
                            ),
                            items: availableStaff.map((staff) {
                              final firstName = (staff['firstName'] ?? staff['first_name'] ?? '').toString().trim();
                              final lastName = (staff['lastName'] ?? staff['last_name'] ?? '').toString().trim();
                              final name = '$firstName $lastName'.trim();
                              return DropdownMenuItem<String>(
                                value: (staff['profile_id'] ?? staff['id']).toString(),
                                child: Text(
                                  name.isNotEmpty ? name : 'Unknown',
                                  style: AppTypography.body().copyWith(
                                    fontSize: 14.sp,
                                    color: const Color(0xFF111827),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedReferenceId = value);
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a staff member';
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
                                isPreferred
                                    ? 'Add to Preferred'
                                    : 'Add to Blacklist',
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
      },
    );
  }
}
