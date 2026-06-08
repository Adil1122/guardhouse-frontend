import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/admin_api_service.dart';
import '../../services/photo_service.dart';

import '../../widgets/ultimate_mobile_widgets.dart';



class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadStaffMembers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _fullName(Map<String, dynamic> staff) {
    final firstName =
        (staff['first_name'] ?? staff['firstName'] ?? '').toString().trim();
    final lastName =
        (staff['last_name'] ?? staff['lastName'] ?? '').toString().trim();
    final combined = '$firstName $lastName'.trim();
    return combined.isEmpty ? 'Unnamed Staff' : combined;
  }

  String _email(Map<String, dynamic> staff) {
    final value = (staff['email'] ?? '').toString().trim();
    return value.isEmpty ? 'no-email@security.com' : value;
  }

  String _role(Map<String, dynamic> staff) {
    final value = (staff['role'] ?? '').toString().trim();
    return value.isEmpty ? 'Security Officer' : value;
  }

  String _contact(Map<String, dynamic> staff) {
    final value = (staff['contact_number'] ?? staff['contactNumber'] ?? '')
        .toString()
        .trim();
    return value.isEmpty ? '--' : value;
  }

  String _gender(Map<String, dynamic> staff) {
    final value = (staff['gender'] ?? '').toString().trim();
    if (value.isEmpty) return '--';
    final lower = value.toLowerCase();
    if (lower == 'male') return 'Male';
    if (lower == 'female') return 'Female';
    if (lower == 'other') return 'Other';
    return value;
  }

  int _privilegeCount(Map<String, dynamic> staff) {
    final data = staff['privileges'];
    if (data is List) return data.length;
    return 0;
  }

  int _complianceCount(Map<String, dynamic> staff) {
    final data = staff['compliances'];
    if (data is List) return data.length;
    return 0;
  }

  bool _hasPrivilege(String action) {
    final authViewModel = context.read<AuthViewModel>();
    final currentUser = authViewModel.currentUser;
    if (currentUser == null) return false;
    if (currentUser['role'] == 'admin' || currentUser['role'] == 'master-admin') return true;
    
    final privileges = currentUser['privileges'] as Map<String, dynamic>?;
    if (privileges == null) return false;
    
    if (privileges['all'] == 'all') return true;
    if (privileges['all'] is List && (privileges['all'] as List).contains('all')) return true;

    final itemPerms = privileges['staff'];
    if (itemPerms == null) return false;

    if (itemPerms is List) {
      return itemPerms.contains('all') || itemPerms.contains(action);
    }
    return itemPerms == 'all' || itemPerms == action;
  }

  Future<void> _showStaffSheet({Map<String, dynamic>? staff}) async {
    Map<String, dynamic>? fullStaffData = staff;

    // Load full staff details when editing
    if (staff != null) {
      debugPrint('STAFF EDIT: Loading staff details for editing');
      final staffId = staff['user_id']?.toString() ?? staff['id']?.toString();
      debugPrint('STAFF EDIT: Staff ID: $staffId');
      debugPrint('STAFF EDIT: Initial staff data: $staff');
      
      if (staffId != null) {
        final vm = context.read<AdminViewModel>();
        try {
          final details = await vm.fetchStaffDetails(staffId);
          debugPrint('STAFF EDIT: Fetched details: $details');
          if (details != null) {
            // Keep list payload as fallback and prefer fresh detail payload.
            fullStaffData = {...staff, ...details};
            debugPrint('STAFF EDIT: Combined staff data: $fullStaffData');
          } else {
            debugPrint('STAFF EDIT: No details fetched, using original data');
          }
        } catch (e) {
          debugPrint('STAFF EDIT: Error fetching staff details: $e');
          // Use original data if fetch fails
        }
      }
    } else {
      debugPrint('STAFF EDIT: No staff data provided, creating new staff');
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) =>
          _StaffFormSheet(isEdit: staff != null, staff: fullStaffData),
    );

    if (result == true && mounted) {
      await context.read<AdminViewModel>().loadStaffMembers();
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> staff) async {
    final staffId = staff['user_id'] ?? staff['id'];
    if (staffId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Are you sure you want to delete ${_fullName(staff)}?'),
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
      final success = await context.read<AdminViewModel>().deleteStaff(
            staffId.toString(),
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        final allStaff = viewModel.staffMembers;
        final query = _searchController.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? allStaff
            : allStaff.where((staff) {
                return _fullName(staff).toLowerCase().contains(query) ||
                    _email(staff).toLowerCase().contains(query) ||
                    _role(staff).toLowerCase().contains(query) ||
                    _contact(staff).toLowerCase().contains(query) ||
                    _gender(staff).toLowerCase().contains(query);
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
                            onPressed: () => Navigator.pop(context),
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
                                  'Staff Management',
                                  style: AppTypography.title().copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${allStaff.length} total staff',
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
                            hintText: 'Search staff...',
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
                  child: viewModel.isLoading && allStaff.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadStaffMembers(),
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
                                    onPressed: () => _showStaffSheet(),
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
                                    'Add Staff',
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
                                    'No staff found',
                                    style: AppTypography.body().copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                )
                              else
                                ...filtered.map(
                                  (staff) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: _StaffCard(
                                      name: _fullName(staff),
                                      role: _role(staff),
                                      email: _email(staff),
                                      contact: _contact(staff),
                                      gender: _gender(staff),
                                      privilegeCount: _privilegeCount(staff),
                                      complianceCount: _complianceCount(staff),
                                      canEdit: _hasPrivilege('update'),
                                      canDelete: _hasPrivilege('delete'),
                                      onEdit: () =>
                                          _showStaffSheet(staff: staff),
                                      onDelete: () => _confirmDelete(staff),
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

class _StaffCard extends StatelessWidget {
  final String name;
  final String role;
  final String email;
  final String contact;
  final String gender;
  final int privilegeCount;
  final int complianceCount;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.name,
    required this.role,
    required this.email,
    required this.contact,
    required this.gender,
    required this.privilegeCount,
    required this.complianceCount,
    required this.canEdit,
    required this.canDelete,
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
          Text(
            name,
            style: AppTypography.body().copyWith(
              fontSize: 16.sp,
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            '$role • $gender',
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF4B5563),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            email,
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Contact: $contact',
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  label: 'Privileges',
                  value: privilegeCount.toString(),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _StatBox(
                  label: 'Compliances',
                  value: complianceCount.toString(),
                ),
              ),
            ],
          ),
          if (canEdit || canDelete) SizedBox(height: 12.h),
          if (canEdit || canDelete)
            Row(
              children: [
                if (canEdit)
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
                if (canEdit && canDelete) SizedBox(width: 10.w),
                if (canDelete)
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

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

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

class _StaffFormSheet extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? staff;

  const _StaffFormSheet({required this.isEdit, this.staff});

  @override
  State<_StaffFormSheet> createState() => _StaffFormSheetState();
}

class _StaffFormSheetState extends State<_StaffFormSheet> {
  final _detailsFormKey = GlobalKey<FormState>();
  final _salaryFormKey = GlobalKey<FormState>();
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _preferredFirstNameController;
  late final TextEditingController _preferredLastNameController;
  late final TextEditingController _contactNumberController;
  late final TextEditingController _siaBadgeNumberController;
  late final TextEditingController _passwordController;
  late final TextEditingController _emergencyRelationshipController;
  late final TextEditingController _emergencyNameController;
  late final TextEditingController _emergencyContactController;
  late final TextEditingController _taxNumberController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountTitleController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _bankCountryController;

  final List<String> _roles = ['Admin', 'Supervisor', 'Security Officer'];
  final List<String> _genders = ['Male', 'Female', 'Other'];
  final Map<String, String> _privilegeItems = {
    'live_op': 'Live Operations',
    'staff': 'Staff',
    'shift': 'Shifts',
    'pay_group': 'Pay Groups',
    'service_group': 'Service Groups',
    'invoice': 'Invoices',
    'timesheet': 'Timesheets',
    'static_site': 'Static Sites',
    'patrol_site': 'Patrol Sites',
    'customer': 'Customers',
    'digital_occurrence_log': 'Digital Occurrence Logs',
  };

  final List<String> _privilegeLevels = [
    'list',
    'create',
    'update',
    'delete',
    'detail',
    'document',
    'compliance',
    'privilege',
    'salary',
    'notes',
    'complete',
    'contact',
    'preference',
    'checkpoint',
    'access_code'
  ];
  final Map<String, Set<String>> _allowedPrivilegeLevelsByItem = {
    'live_op': {'list'},
    'staff': {
      'list',
      'create',
      'update',
      'delete',
      'detail',
      'document',
      'compliance',
      'privilege',
      'salary'
    },
    'shift': {'list', 'create', 'update', 'delete', 'notes'},
    'pay_group': {'list', 'create', 'update', 'delete'},
    'service_group': {'list', 'create', 'update', 'delete'},
    'invoice': {'list', 'create', 'update', 'delete', 'complete'},
    'timesheet': {'list', 'create', 'update', 'delete'},
    'static_site': {
      'list',
      'create',
      'update',
      'delete',
      'contact',
      'preference',
      'checkpoint',
      'document',
      'access_code'
    },
    'patrol_site': {
      'list',
      'create',
      'update',
      'delete',
      'contact',
      'preference',
      'checkpoint',
      'document',
      'access_code'
    },
    'customer': {'list', 'create', 'update', 'delete', 'detail', 'contact'},
    'digital_occurrence_log': {'list', 'update', 'delete'},
  };

  int _currentTabIndex = 0;
  bool _isSubmitting = false;
  String? _staffId;

  String? _selectedRole;
  String? _selectedGender;
  String? _imagePath;
  Uint8List? _imageBytes;

  // Each entry: {'item': String?, 'levels': Set<String>}
  List<Map<String, dynamic>> _privileges = [
    {'item': null, 'levels': <String>{}},
  ];

  String? _selectedComplianceType;
  String? _complianceRecordId;
  DateTime? _complianceStartDate;
  DateTime? _complianceExpirationDate;
  List<dynamic> _complianceFiles = [];

  String? _selectedPayGroup;

  String _displayFileName(String pathOrName) {
    final normalized = pathOrName.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.isEmpty ? pathOrName : parts.last;
  }

  bool _isExistingServerFile(String file) {
    if (file.isEmpty) return false;
    // Local files from file_picker usually have absolute paths starting with /data/ (Android) or C: (Windows)
    // Server files are usually relative paths or URLs
    final isLocal = file.startsWith('/') || file.contains(':\\') || file.contains(':/');
    return !isLocal;
  }

  bool get _requireComplianceFiles => !widget.isEdit;

  String? _normalizePrivilegeItem(String? item) {
    if (item == null || item.isEmpty) return null;
    if (item == 'digital_occurence_log') return 'digital_occurrence_log';
    return item;
  }

  String _normalizeRole(String? role) {
    if (role == null) return 'Security Officer';
    final lower = role.toLowerCase();
    if (lower == 'admin') return 'Admin';
    if (lower == 'supervisor') return 'Supervisor';
    if (lower == 'security-officer' || lower == 'security officer')
      return 'Security Officer';
    return 'Security Officer';
  }

  String _normalizeGender(String? gender) {
    if (gender == null) return '';
    final lower = gender.toLowerCase();
    if (lower == 'male') return 'Male';
    if (lower == 'female') return 'Female';
    if (lower == 'other') return 'Other';
    return gender;
  }

  String _formatPrivilegeLevel(String level) {
    switch (level) {
      case 'list':
        return 'List';
      case 'create':
        return 'Create';
      case 'update':
        return 'Update';
      case 'delete':
        return 'Delete';
      case 'detail':
        return 'Detail';
      case 'document':
        return 'Document';
      case 'compliance':
        return 'Compliance';
      case 'privilege':
        return 'Privilege';
      case 'salary':
        return 'Salary';
      case 'notes':
        return 'Notes';
      case 'complete':
        return 'Complete';
      case 'contact':
        return 'Contact';
      case 'preference':
        return 'Preference';
      case 'checkpoint':
        return 'Checkpoint';
      case 'access_code':
        return 'Access Code';
      default:
        return level;
    }
  }

  Set<String> _allowedLevelsForItem(String? item) {
    if (item == null || item.isEmpty) return {};
    return _allowedPrivilegeLevelsByItem[item] ?? _privilegeLevels.toSet();
  }

  @override
  void initState() {
    super.initState();
    debugPrint('STAFF FORM: Initializing form - isEdit: ${widget.isEdit}');
    debugPrint('STAFF FORM: Staff data received: ${widget.staff}');
    
    // Load pay groups for the salary tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadPayGroups();
      // Force UI update on mobile after first frame
      if (mounted) {
        setState(() {});
      }
    });

    final staff = widget.staff;

    _firstNameController = TextEditingController(
      text: (staff?['first_name'] ?? staff?['firstName'] ?? '').toString(),
    );
    _lastNameController = TextEditingController(
      text: (staff?['last_name'] ?? staff?['lastName'] ?? '').toString(),
    );
    _passwordController = TextEditingController();
    _emailController = TextEditingController(
      text: (staff?['email'] ?? '').toString(),
    );
    _preferredFirstNameController = TextEditingController(
      text:
          (staff?['preferred_first_name'] ?? staff?['preferredFirstName'] ?? '')
              .toString(),
    );
    _preferredLastNameController = TextEditingController(
      text: (staff?['preferred_last_name'] ?? staff?['preferredLastName'] ?? '')
          .toString(),
    );
    _contactNumberController = TextEditingController(
      text: (staff?['contact_number'] ?? staff?['contactNumber'] ?? '')
          .toString(),
    );
    _siaBadgeNumberController = TextEditingController(
      text: (staff?['sia_badge_number'] ?? staff?['siaBadgeNumber'] ?? '')
          .toString(),
    );

    // Debug logging for controller values
    debugPrint('STAFF FORM: Controller values:');
    debugPrint('  First Name: "${_firstNameController.text}"');
    debugPrint('  Last Name: "${_lastNameController.text}"');
    debugPrint('  Email: "${_emailController.text}"');
    debugPrint('  Contact: "${_contactNumberController.text}"');
    debugPrint('  SIA Badge: "${_siaBadgeNumberController.text}"');

    // Force controller update for mobile UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _firstNameController.notifyListeners();
        _lastNameController.notifyListeners();
        _emailController.notifyListeners();
        _contactNumberController.notifyListeners();
        _siaBadgeNumberController.notifyListeners();
        setState(() {});
      }
    });

    final emergency = (staff?['emergency_contact'] ??
        staff?['emergencyContact']) as Map<String, dynamic>?;
    _emergencyRelationshipController = TextEditingController(
      text: (emergency?['relationship'] ?? '').toString(),
    );
    _emergencyNameController = TextEditingController(
      text: (emergency?['name'] ?? '').toString(),
    );
    _emergencyContactController = TextEditingController(
      text: (emergency?['contactNumber'] ?? emergency?['contact_number'] ?? '')
          .toString(),
    );

    // Salary/bank data is returned directly in staff object from backend
    final bank = (staff?['bank_details'] ?? staff?['bankDetails'])
        as Map<String, dynamic>?;

    _taxNumberController = TextEditingController(
      text: (staff?['tax_number'] ?? staff?['taxNumber'] ?? '').toString(),
    );
    _bankNameController = TextEditingController(
      text: (bank?['bank_name'] ?? bank?['bankName'] ?? '').toString(),
    );
    _accountTitleController = TextEditingController(
      text: (bank?['account_name'] ?? bank?['accountTitle'] ?? '').toString(),
    );
    _accountNumberController = TextEditingController(
      text:
          (bank?['account_number'] ?? bank?['accountNumber'] ?? '').toString(),
    );
    _bankCountryController = TextEditingController(
      text: (bank?['bank_country'] ?? bank?['bankCountry'] ?? '').toString(),
    );

    _selectedRole = _normalizeRole((staff?['role'] ?? '').toString());
    _selectedGender = _normalizeGender((staff?['gender'] ?? '').toString());
    if (_selectedGender?.isEmpty ?? true) _selectedGender = null;
    _imagePath =
        (staff?['imagePath'] ?? staff?['image'] ?? '').toString().isEmpty
            ? null
            : (staff?['imagePath'] ?? staff?['image']).toString();

    final privileges = staff?['privileges'];
    if (privileges is List && privileges.isNotEmpty) {
      _privileges = privileges.whereType<Map>().map((p) {
        final levels = p['levels'];
        final normalizedItem = _normalizePrivilegeItem(p['item']?.toString());
        final allowedLevels = _allowedLevelsForItem(normalizedItem);
        return {
          'item': _privilegeItems.containsKey(normalizedItem)
              ? normalizedItem
              : null,
          'levels': levels is List
              ? levels
                  .map((e) => e.toString())
                  .where((level) => allowedLevels.contains(level))
                  .toSet()
              : <String>{},
        };
      }).toList();
      if (_privileges.isEmpty) {
        _privileges = [
          {'item': null, 'levels': <String>{}},
        ];
      }
    }

    final compliances = staff?['compliances'];
    if (compliances is List && compliances.isNotEmpty) {
      final first = compliances.first;
      if (first is Map) {
        _complianceRecordId = first['id']?.toString();
        final complianceObj = first['compliance'];
        _selectedComplianceType = first['compliance_id']?.toString() ??
            (complianceObj is Map ? complianceObj['id']?.toString() : null) ??
            first['type']?.toString();

        final startDate =
            first['start_date']?.toString() ?? first['startDate']?.toString();
        final expirationDate = first['end_date']?.toString() ??
            first['expirationDate']?.toString();
        _complianceStartDate = startDate == null || startDate.isEmpty
            ? null
            : DateTime.tryParse(startDate);
        _complianceExpirationDate =
            expirationDate == null || expirationDate.isEmpty
                ? null
                : DateTime.tryParse(expirationDate);

        final files = first['files'];
        if (files is List) {
          _complianceFiles = files.map((e) => e.toString()).toList();
        }
      }
    }

    _selectedPayGroup =
        (staff?['default_pay_group_id'] ?? staff?['defaultPayGroup'] ?? '')
                .toString()
                .isEmpty
            ? null
            : (staff?['default_pay_group_id'] ?? staff?['defaultPayGroup'])
                .toString();

    _staffId = (widget.staff?['user_id'] ?? widget.staff?['id'])?.toString();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _preferredFirstNameController.dispose();
    _preferredLastNameController.dispose();
    _contactNumberController.dispose();
    _siaBadgeNumberController.dispose();
    _passwordController.dispose();
    _emergencyRelationshipController.dispose();
    _emergencyNameController.dispose();
    _emergencyContactController.dispose();
    _taxNumberController.dispose();
    _bankNameController.dispose();
    _accountTitleController.dispose();
    _accountNumberController.dispose();
    _bankCountryController.dispose();
    super.dispose();
  }

  bool _isTabValid(int tab) {
    try {
      if (tab == 0) {
        final detailsValid = _detailsFormKey.currentState?.validate() ??
            (_firstNameController.text.trim().isNotEmpty &&
                _lastNameController.text.trim().isNotEmpty &&
                _emailController.text.trim().isNotEmpty &&
                _preferredFirstNameController.text.trim().isNotEmpty &&
                _preferredLastNameController.text.trim().isNotEmpty &&
                _siaBadgeNumberController.text.trim().isNotEmpty &&
                _contactNumberController.text.trim().isNotEmpty);
        return detailsValid && _selectedRole != null && _selectedGender != null;
      }

      if (tab == 1) {
        return _privileges.isNotEmpty &&
            _privileges.every(
              (p) => p['item'] != null && 
                     p['levels'] != null && 
                     (p['levels'] is Set<String>) && 
                     (p['levels'] as Set<String>).isNotEmpty,
            );
      }

      if (tab == 2) {
        return _selectedComplianceType != null &&
            _complianceStartDate != null &&
            _complianceExpirationDate != null &&
            (!_requireComplianceFiles || _complianceFiles.isNotEmpty);
      }

      if (tab == 3) {
        return _salaryFormKey.currentState?.validate() ?? true;
      }
    } catch (e) {
      debugPrint('Validation Error in tab $tab: $e');
      return false;
    }
    return false;
  }

  bool get _isWorker =>
      _selectedRole?.toLowerCase() == 'worker' ||
      _selectedRole?.toLowerCase() == 'security officer' ||
      _selectedRole?.toLowerCase() == 'security-officer';

  bool get _isAdmin => _selectedRole?.toLowerCase() == 'admin';
  bool get _hidePrivilegesTab => _isAdmin || _isWorker;

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: kIsWeb,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      final selectedPath = file.path ?? file.name;
      if (selectedPath.isEmpty) return;
      setState(() {
        _imagePath = selectedPath;
        if (kIsWeb) {
          _imageBytes = file.bytes;
        }
      });
    }
  }

  Future<void> _addComplianceFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        for (final file in result.files) {
          if (kIsWeb) {
            _complianceFiles.add(file);
          } else {
            final selectedPath = file.path;
            if (selectedPath == null || selectedPath.isEmpty) {
              continue;
            }
            if (!_complianceFiles.contains(selectedPath)) {
              _complianceFiles.add(selectedPath);
            }
          }
        }
      });
    }
  }


  String _dateLabel(DateTime? date) {
    if (date == null) return 'Select Date';
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  // ── Optional-tab fill checkers ──────────────────────────────────────────────

  bool _isPrivilegesFilled() {
    return _privileges.any(
      (p) => p['item'] != null && (p['levels'] as Set<String>).isNotEmpty,
    );
  }

  bool _isComplianceFilled() {
    return _selectedComplianceType != null &&
        _complianceStartDate != null &&
        _complianceExpirationDate != null &&
        (!_requireComplianceFiles || _complianceFiles.isNotEmpty);
  }

  bool _isSalaryFilled() {
    return _taxNumberController.text.trim().isNotEmpty ||
        _bankNameController.text.trim().isNotEmpty ||
        _accountTitleController.text.trim().isNotEmpty ||
        _accountNumberController.text.trim().isNotEmpty ||
        _bankCountryController.text.trim().isNotEmpty ||
        _selectedPayGroup != null;
  }

  // ── Proceed / Submit All ─────────────────────────────────────────────────────

  void _onProceed() {
    try {
      if (_currentTabIndex == 0) {
        _detailsFormKey.currentState?.validate();
        if (!_isTabValid(0)) {
          _showFlashMessage('Please complete all required fields to proceed', isError: true);
          return;
        }
      }
      if (_currentTabIndex < 3) {
        // Skip Privileges (1) if worker
        if (_currentTabIndex == 0 && _isWorker) {
          setState(() => _currentTabIndex = 2);
        } else {
          setState(() => _currentTabIndex++);
        }
      } else {
        _submitAll();
      }
    } catch (e) {
      debugPrint('Proceed Button Error: $e');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Stack Trace: ${StackTrace.current}');
      _showFlashMessage('Error: $e', isError: true);
    }
  }

  Future<void> _submitAll() async {
    // Validate mandatory tab (details)
    if (!_isTabValid(0)) {
      _detailsFormKey.currentState?.validate();
      _showFlashMessage('Please complete all required staff details', isError: true);
      setState(() => _currentTabIndex = 0);
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final vm = context.read<AdminViewModel>();
    try {
      // 1. Details — always submit (mandatory)
      // Only include image if it's a local file path, not a server URL
      final bool _hasNewLocalImage = _imagePath != null &&
          _imagePath!.isNotEmpty &&
          !_imagePath!.startsWith('http');
      
      final detailsPayload = <String, dynamic>{};
      if (_staffId != null) {
        detailsPayload['id'] = _staffId;
      }
      if (_selectedRole != null) {
        detailsPayload['role'] = _selectedRole == 'Security Officer'
            ? 'security-officer'
            : _selectedRole!.toLowerCase();
      }
      detailsPayload['first_name'] = _firstNameController.text.trim();
      detailsPayload['last_name'] = _lastNameController.text.trim();
      detailsPayload['email'] = _emailController.text.trim();
      if (_hasNewLocalImage) {
        if (kIsWeb && _imageBytes != null) {
          detailsPayload['image_bytes'] = _imageBytes;
          detailsPayload['image_name'] = _imagePath;
        } else {
          detailsPayload['image'] = _imagePath;
        }
      }
      detailsPayload['password'] = _passwordController.text.trim();
      detailsPayload['preferred_first_name'] = _preferredFirstNameController.text.trim();
      detailsPayload['preferred_last_name'] = _preferredLastNameController.text.trim();
      detailsPayload['contact_number'] = _contactNumberController.text.trim();
      detailsPayload['sia_badge_number'] = _siaBadgeNumberController.text.trim();
      
      if (_emergencyRelationshipController.text.isNotEmpty ||
          _emergencyNameController.text.isNotEmpty ||
          _emergencyContactController.text.isNotEmpty) {
        detailsPayload['emergency_contact'] = {
          'relationship': _emergencyRelationshipController.text.trim(),
          'name': _emergencyNameController.text.trim(),
          'contact_number': _emergencyContactController.text.trim(),
        };
      }
      
      if (_selectedGender != null) {
        detailsPayload['gender'] = _selectedGender!.toLowerCase();
      }

      bool detailsSuccess;
      if (widget.isEdit || _staffId != null) {
        detailsSuccess = await vm.updateStaffDetails(detailsPayload);
      } else {
        final newId = await vm.submitStaffDetails(detailsPayload);
        detailsSuccess = newId != null;
        if (newId != null) _staffId = newId;
      }

      if (!detailsSuccess || _staffId == null) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showFlashMessage(vm.errorMessage ?? 'Failed to save staff details', isError: true);
        }
        return;
      }

      // 2. Privileges — optional: only submit if tab was filled
      if (_isPrivilegesFilled()) {
        final privilegesMap = <String, List<String>>{};
        for (final p in _privileges) {
          if (p['item'] != null && p['levels'] != null && (p['levels'] as Set<String>).isNotEmpty) {
            final item = p['item'] as String;
            final allowedLevels = _allowedLevelsForItem(item);
            final levelsSet = p['levels'] as Set<String>;
            final sanitizedLevels = levelsSet
                .where((level) => allowedLevels.contains(level))
                .toList();
            if (sanitizedLevels.isNotEmpty) {
              privilegesMap[item] = sanitizedLevels;
            }
          }
        }
        if (privilegesMap.isNotEmpty) {
          final privilegeSuccess =
              await vm.submitStaffPrivileges(_staffId!, privilegesMap);
          if (!privilegeSuccess) {
            if (mounted) {
              setState(() => _isSubmitting = false);
              _showFlashMessage(vm.errorMessage ?? 'Failed to save privileges', isError: true);
            }
            return;
          }
        }
      }

      // 3. Compliances — optional: only submit if tab was filled
      if (_isComplianceFilled()) {
        final existingFiles = _complianceFiles
            .where((file) => file is String && _isExistingServerFile(file))
            .toList();
        final uploadableFiles = _complianceFiles
            .where((file) => file is PlatformFile || (file is String && !_isExistingServerFile(file)))
            .toList();
        
        final compliancePayload = <String, dynamic>{};
        if (_complianceRecordId != null) {
          compliancePayload['compliance_record_id'] = _complianceRecordId;
        }
        if (_selectedComplianceType != null) {
          compliancePayload['compliance_id'] = _selectedComplianceType;
        }
        if (_complianceStartDate != null) {
          compliancePayload['start_date'] = _complianceStartDate!.toIso8601String().split('T').first;
        }
        if (_complianceExpirationDate != null) {
          compliancePayload['end_date'] = _complianceExpirationDate!.toIso8601String().split('T').first;
        }
        if (existingFiles.isNotEmpty) {
          compliancePayload['existing_files'] = existingFiles;
        }
        if (uploadableFiles.isNotEmpty) {
          compliancePayload['files'] = uploadableFiles;
        }
        
        final complianceSuccess = await vm.submitStaffCompliances(_staffId!, compliancePayload);
        if (!complianceSuccess) {
          if (mounted) {
            setState(() => _isSubmitting = false);
            _showFlashMessage(vm.errorMessage ?? 'Failed to save compliances', isError: true);
          }
          return;
        }
      }

      // 4. Salary — optional: only submit if tab was filled
      if (_isSalaryFilled()) {
        final salaryPayload = <String, dynamic>{
          'tax_number': _taxNumberController.text.trim(),
          'bank_details': {
            'bank_name': _bankNameController.text.trim(),
            'account_name': _accountTitleController.text.trim(),
            'account_number': _accountNumberController.text.trim(),
            'bank_country': _bankCountryController.text.trim(),
          },
        };
        if (_selectedPayGroup != null) {
          salaryPayload['default_pay_group_id'] = _selectedPayGroup;
        }
        final salarySuccess = await vm.submitStaffSalary(_staffId!, salaryPayload);
        if (!salarySuccess) {
          if (mounted) {
            setState(() => _isSubmitting = false);
            _showFlashMessage(vm.errorMessage ?? 'Failed to save salary details', isError: true);
          }
          return;
        }
      }

      if (mounted) setState(() => _isSubmitting = false);
      _showFlashMessage(
          widget.isEdit ? 'Staff updated successfully' : 'Staff added successfully');
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('Submit All Error: $e');
      debugPrint('Error Type: ${e.runtimeType}');
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showFlashMessage('An error occurred: $e', isError: true);
      }
    }
  }

  void _showFlashMessage(String message, {bool isError = false}) {
    _scaffoldMessengerKey.currentState?.clearSnackBars();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: AppTypography.body().copyWith(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFDC2626) : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // Mobile UI fix: Force controller text to display on mobile
    if (widget.isEdit && widget.staff != null) {
      final staff = widget.staff;
      
      // Always update controller text to force mobile UI refresh
      _firstNameController.text = staff?['first_name']?.toString() ?? '';
      _lastNameController.text = staff?['last_name']?.toString() ?? '';
      _emailController.text = staff?['email']?.toString() ?? '';
      _contactNumberController.text = staff?['contact_number']?.toString() ?? '';
      _siaBadgeNumberController.text = staff?['sia_badge_number']?.toString() ?? '';
      
      debugPrint('STAFF FORM: Force updated controllers in build:');
      debugPrint('  First Name: "${_firstNameController.text}"');
      debugPrint('  Last Name: "${_lastNameController.text}"');
      debugPrint('  Email: "${_emailController.text}"');
      debugPrint('  Contact: "${_contactNumberController.text}"');
      debugPrint('  SIA Badge: "${_siaBadgeNumberController.text}"');
    }

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
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
                  widget.isEdit ? 'Edit Staff' : 'Add Staff',
                  style: AppTypography.title().copyWith(
                    fontSize: 19.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h + bottomPadding),
              child: _buildTabContent(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: const Color(0xFFE5E7EB), width: 1.h),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _hidePrivilegesTab && _currentTabIndex >= 2 ? _currentTabIndex - 1 : _currentTabIndex,
              onTap: (index) {
                if (_hidePrivilegesTab) {
                  if (index == 0) setState(() => _currentTabIndex = 0);
                  if (index == 1) setState(() => _currentTabIndex = 2);
                  if (index == 2) setState(() => _currentTabIndex = 3);
                } else {
                  setState(() => _currentTabIndex = index);
                }
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF0E45BA),
              unselectedItemColor: const Color(0xFF9CA3AF),
              elevation: 0,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Details',
                ),
                if (!_hidePrivilegesTab)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.security),
                  label: 'Privileges',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.verified),
                  label: 'Compliance',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.payments),
                  label: 'Salary',
                ),
              ],
            ),
          ),
        ],
      ),
    )));
  }

  Widget _buildTabContent() {
    if (_currentTabIndex == 0) {
      return _detailsStep();
    }
    if (_currentTabIndex == 1) {
      return _privilegesStep();
    }
    if (_currentTabIndex == 2) {
      return _complianceStep();
    }
    return _salaryStep();
  }

  Widget _detailsStep() {
    return Form(
      key: _detailsFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Details'),
          SizedBox(height: 12.h),
          UltimateMobileDropdown<String>(
            value: _selectedRole,
            decoration: _inputDecoration('Choose Role *'),
            hintText: 'Choose Role *',
            items: _roles
                .map((role) => DropdownMenuItem(
                      value: role,
                      child: Text(role),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _selectedRole = value),
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _firstNameController,
            initialValue: widget.isEdit && widget.staff != null 
                ? (widget.staff!['first_name']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('First Name *'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'First name is required'
                : null,
            onSaved: (value) => _firstNameController.text = value ?? '',
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _lastNameController,
            initialValue: widget.isEdit && widget.staff != null 
                ? (widget.staff!['last_name']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Last Name *'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Last name is required'
                : null,
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _emailController,
            initialValue: widget.isEdit && widget.staff != null 
                ? (widget.staff!['email']?.toString() ?? '')
                : null,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email *'),
            validator: (value) {
              final input = value?.trim() ?? '';
              if (input.isEmpty) return 'Email is required';
              if (!input.contains('@') || !input.contains('.')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _passwordController,
            initialValue: widget.isEdit ? '' : null,
            obscureText: true,
            decoration: _inputDecoration('Password ${widget.isEdit ? '(Optional)' : '*'}'),
            validator: (value) {
              if (widget.isEdit) return null;
              if (value == null || value.trim().isEmpty) {
                return 'Password is required';
              }
              if (value.length < 8) return 'Password must be at least 8 characters';
              return null;
            },
          ),
          SizedBox(height: 10.h),
          SizedBox(height: 10.h),
          _sectionTitle('Staff Image'),
          SizedBox(height: 8.h),
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100.h,
                    height: 100.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD1D5DB), width: 2),
                      image: (_imagePath != null && _imagePath!.isNotEmpty)
                          ? DecorationImage(
                              image: _imagePath!.startsWith('http')
                                  ? NetworkImage(_imagePath!) as ImageProvider
                                  : (kIsWeb && _imageBytes != null)
                                      ? MemoryImage(_imageBytes!) as ImageProvider
                                      : FileImage(File(_imagePath!)) as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (_imagePath == null || _imagePath!.isEmpty)
                        ? Icon(
                            Icons.camera_alt_outlined,
                            size: 32.sp,
                            color: const Color(0xFF9CA3AF),
                          )
                        : null,
                  ),
                ),
                if (_imagePath != null && _imagePath!.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _imagePath = null),
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _preferredFirstNameController,
            initialValue: widget.isEdit && widget.staff != null 
                ? (widget.staff!['preferred_first_name']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Preferred First Name *'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Preferred first name is required'
                : null,
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _preferredLastNameController,
            initialValue: widget.isEdit && widget.staff != null 
                ? (widget.staff!['preferred_last_name']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Preferred Last Name *'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Preferred last name is required'
                : null,
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _contactNumberController,
            initialValue: widget.isEdit && widget.staff != null 
                ? (widget.staff!['contact_number']?.toString() ?? '')
                : null,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('Contact Number *'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Contact number is required'
                : null,
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _siaBadgeNumberController,
            initialValue: widget.isEdit && widget.staff != null 
                ? (widget.staff!['sia_badge_number']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('SIA Badge Number *'),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'SIA badge number is required'
                : null,
          ),
          SizedBox(height: 10.h),
          _sectionTitle('Emergency Contact (Optional)'),
          SizedBox(height: 8.h),
          UltimateMobileTextField(
            controller: _emergencyRelationshipController,
            initialValue: widget.isEdit && widget.staff != null 
                ? ((widget.staff!['emergency_contact'] as Map<String, dynamic>?)?['relationship']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Relationship'),
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _emergencyNameController,
            initialValue: widget.isEdit && widget.staff != null 
                ? ((widget.staff!['emergency_contact'] as Map<String, dynamic>?)?['name']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Name'),
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _emergencyContactController,
            initialValue: widget.isEdit && widget.staff != null 
                ? ((widget.staff!['emergency_contact'] as Map<String, dynamic>?)?['contact_number']?.toString() ?? '')
                : null,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration('Contact Number'),
          ),
          SizedBox(height: 12.h),
          Text(
            'Gender *',
            style: AppTypography.body().copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            children: _genders.map((gender) {
              return ChoiceChip(
                label: Text(gender),
                selected: _selectedGender == gender,
                onSelected: (_) => setState(() => _selectedGender = gender),
                selectedColor: const Color(0xFFDCE8FF),
                labelStyle: AppTypography.body().copyWith(
                  fontSize: 12.sp,
                  color: _selectedGender == gender
                      ? const Color(0xFF0E45BA)
                      : const Color(0xFF4B5563),
                ),
              );
            }).toList(),
          ),
          if (_selectedGender == null)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                'Gender is required',
                style: AppTypography.body().copyWith(
                  fontSize: 11.sp,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          SizedBox(height: 20.h),
          _proceedButton(),
        ],
      ),
    );
  }

  Widget _privilegesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('Privileges')),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _privileges.add({'item': null, 'levels': <String>{}});
                });
              },
              icon: Icon(Icons.add_circle_outline, size: 18.sp),
              label: Text(
                'Add Privilege',
                style: AppTypography.body().copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0E45BA),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ...List.generate(_privileges.length, (index) {
          final entry = _privileges[index];
          final levels = entry['levels'] as Set<String>;
          return Container(
            margin: EdgeInsets.only(bottom: 12.h),
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
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
                        'Privilege ${index + 1}',
                        style: AppTypography.body().copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    if (_privileges.length > 1)
                      GestureDetector(
                        onTap: () {
                          setState(() => _privileges.removeAt(index));
                        },
                        child: Icon(
                          Icons.remove_circle_outline,
                          size: 20.sp,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 10.h),
                UltimateMobileDropdown<String>(
                  value: entry['item'] as String?,
                  decoration: _inputDecoration('Choose Privilege Item *'),
                  items: _privilegeItems.entries
                      .map(
                        (e) => DropdownMenuItem(
                            value: e.key, child: Text(e.value)),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _privileges[index]['item'] = value;
                      final allowed = _allowedLevelsForItem(value);
                      final selected =
                          (_privileges[index]['levels'] as Set<String>);
                      selected.removeWhere((level) => !allowed.contains(level));
                    });
                  },
                ),
                SizedBox(height: 10.h),
                Text(
                  'Choose Privilege Levels *',
                  style: AppTypography.body().copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  children: _privilegeLevels
                      .where((level) =>
                          _allowedLevelsForItem(entry['item'] as String?)
                              .contains(level))
                      .map((level) {
                    return FilterChip(
                      label: Text(_formatPrivilegeLevel(level)),
                      selected: levels.contains(level),
                      onSelected: (checked) {
                        setState(() {
                          if (checked == true) {
                            levels.add(level);
                          } else {
                            levels.remove(level);
                          }
                        });
                      },
                      selectedColor: const Color(0xFFDCE8FF),
                      labelStyle: AppTypography.body().copyWith(
                        fontSize: 11.sp,
                        color: levels.contains(level)
                            ? const Color(0xFF0E45BA)
                            : const Color(0xFF4B5563),
                      ),
                    );
                  }).toList(),
                ),
                if (levels.isEmpty)
                  Text(
                    'Select at least one level',
                    style: AppTypography.body().copyWith(
                      fontSize: 11.sp,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
              ],
            ),
          );
        }),
        SizedBox(height: 8.h),
        _proceedButton(),
      ],
    );
  }

  Widget _complianceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Compliances'),
        SizedBox(height: 12.h),
        Builder(builder: (context) {
          final complianceList =
              context.watch<AdminViewModel>().organizationCompliances;
          final validValues = complianceList
              .map((c) => c['id']?.toString())
              .whereType<String>()
              .toSet();

          // Reset if the selected value is no longer valid
          if (_selectedComplianceType != null &&
              !validValues.contains(_selectedComplianceType)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _selectedComplianceType = null);
            });
          }

          return UltimateMobileDropdown<String>(
            value: validValues.contains(_selectedComplianceType)
                ? _selectedComplianceType
                : null,
            decoration: _inputDecoration('Choose Type *'),
            hintText: complianceList.isEmpty
                ? 'Loading...'
                : 'Select compliance',
            items: complianceList
                .map((item) => DropdownMenuItem(
                      value: item['id']?.toString(),
                      child: Text(item['name']?.toString() ?? ''),
                    ))
                .toList(),
            onChanged: (value) =>
                setState(() => _selectedComplianceType = value),
          );
        }),
        SizedBox(height: 10.h),
        UltimateMobileDatePicker(
          label: 'Start Date *',
          value: _complianceStartDate,
          onDateSelected: (date) {
            setState(() {
              _complianceStartDate = date;
              if (_complianceExpirationDate != null &&
                  date != null &&
                  _complianceExpirationDate!.isBefore(date)) {
                _complianceExpirationDate = null;
              }
            });
          },
        ),
        SizedBox(height: 10.h),
        UltimateMobileDatePicker(
          label: 'Expiration Date *',
          value: _complianceExpirationDate,
          onDateSelected: (date) {
            setState(() {
              _complianceExpirationDate = date;
            });
          },
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(
              child: Text(
                _requireComplianceFiles ? 'Files *' : 'Files (Optional)',
                style: AppTypography.body().copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _addComplianceFiles,
              icon: Icon(Icons.add_circle_outline, size: 18.sp),
              label: Text(
                'Add Files',
                style: AppTypography.body().copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0E45BA),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              ),
            ),
          ],
        ),
        if (_complianceFiles.isEmpty && widget.isEdit)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              'No files attached (optional)',
              style: AppTypography.body().copyWith(
                fontSize: 11.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          )
        else if (_complianceFiles.isEmpty && _requireComplianceFiles)
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              'Please upload at least one file to proceed',
              style: AppTypography.body().copyWith(
                fontSize: 11.sp,
                color: const Color(0xFFDC2626),
              ),
            ),
          )
        else
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: _complianceFiles.asMap().entries.map((entry) {
              final i = entry.key;
              final file = entry.value;
              final name = file is PlatformFile ? file.name : file.toString();
              return Chip(
                onDeleted: () => setState(() => _complianceFiles.removeAt(i)),
                deleteIcon: Icon(Icons.cancel, size: 16.sp, color: Colors.red),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                label: Text(
                  _displayFileName(name),
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: const Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                backgroundColor: const Color(0xFFF3F4F6),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
              );
            }).toList(),
          ),
        SizedBox(height: 20.h),
        _proceedButton(),
      ],
    );
  }

  Widget _salaryStep() {
    return Form(
      key: _salaryFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Salary / Wage'),
          SizedBox(height: 12.h),
          UltimateMobileTextField(
            controller: _taxNumberController,
            initialValue: widget.isEdit && widget.staff != null 
                ? (widget.staff!['tax_number']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Tax Number (Optional)'),
          ),
          SizedBox(height: 10.h),
          _sectionTitle('Bank Details (Optional)'),
          SizedBox(height: 8.h),
          UltimateMobileTextField(
            controller: _bankNameController,
            initialValue: widget.isEdit && widget.staff != null 
                ? ((widget.staff!['bank_details'] as Map<String, dynamic>?)?['bank_name']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Bank Name'),
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _accountTitleController,
            initialValue: widget.isEdit && widget.staff != null 
                ? ((widget.staff!['bank_details'] as Map<String, dynamic>?)?['account_name']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Account Title'),
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _accountNumberController,
            initialValue: widget.isEdit && widget.staff != null 
                ? ((widget.staff!['bank_details'] as Map<String, dynamic>?)?['account_number']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Account Number'),
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _bankCountryController,
            initialValue: widget.isEdit && widget.staff != null 
                ? ((widget.staff!['bank_details'] as Map<String, dynamic>?)?['bank_country']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Bank Country'),
          ),
          SizedBox(height: 10.h),
          Builder(
            builder: (context) {
              final payGroups = context.watch<AdminViewModel>().payGroups;
              // Ensure the stored value exists in the current list; reset if not.
              final validValues = payGroups
                  .map((g) => g['id']?.toString())
                  .whereType<String>()
                  .toSet();
              if (_selectedPayGroup != null &&
                  !validValues.contains(_selectedPayGroup)) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _selectedPayGroup = null);
                });
              }
              return UltimateMobileDropdown<String>(
                value: validValues.contains(_selectedPayGroup)
                    ? _selectedPayGroup
                    : null,
                decoration: _inputDecoration('Default Pay Group (Optional)'),
                hintText: 'Default Pay Group (Optional)',
                items: payGroups
                    .map((g) => DropdownMenuItem(
                          value: g['id']?.toString(),
                          child: Text(g['name'] ?? 'Unnamed Group'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedPayGroup = value),
              );
            },
          ),
          SizedBox(height: 20.h),
          _proceedButton(),
        ],
      ),
    );
  }

  Widget _proceedButton() {
    final isLastTab = _currentTabIndex == 3;
    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _onProceed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0E45BA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          elevation: 0,
        ),
        icon: _isSubmitting
            ? SizedBox(
                width: 16.w,
                height: 16.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(isLastTab ? Icons.check : Icons.arrow_forward, size: 18),
        label: Text(
          isLastTab ? 'Submit All' : 'Proceed',
          style: AppTypography.body().copyWith(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTypography.body().copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF111827),
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

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.body().copyWith(
            fontSize: 13.sp,
            color: const Color(0xFF6B7280),
          ),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 12.h,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.r),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: AppTypography.body().copyWith(
                  fontSize: 13.sp,
                  color: const Color(0xFF374151),
                ),
              ),
            ),
            Icon(
              Icons.calendar_month_outlined,
              size: 18.sp,
              color: const Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}
