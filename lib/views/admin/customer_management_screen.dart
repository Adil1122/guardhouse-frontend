import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../widgets/ultimate_mobile_widgets.dart';


class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({super.key});

  @override
  State<CustomerManagementScreen> createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _fullName(Map<String, dynamic> customer) {
    final firstName = (customer['first_name'] ?? customer['firstName'] ?? '')
        .toString()
        .trim();
    final lastName =
        (customer['last_name'] ?? customer['lastName'] ?? '').toString().trim();
    final combined = '$firstName $lastName'.trim();
    return combined.isEmpty ? 'Unnamed Customer' : combined;
  }

  bool _hasPrivilege(String action) {
    return context.read<AuthViewModel>().hasPrivilege('customer', action);
  }

  String _email(Map<String, dynamic> customer) {
    final value = (customer['email'] ?? '').toString().trim();
    return value.isEmpty ? 'no-email@company.com' : value;
  }

  String _referenceNumber(Map<String, dynamic> customer) {
    final value =
        (customer['reference_number'] ?? customer['referenceNumber'] ?? '')
            .toString()
            .trim();
    return value.isEmpty ? '--' : value;
  }

  String _address(Map<String, dynamic> customer) {
    final addressData = customer['address'];
    if (addressData is Map<String, dynamic>) {
      final address =
          (addressData['name'] ?? addressData['address'] ?? '').toString();
      final city = (addressData['city'] ?? '').toString();
      if (address.isNotEmpty && city.isNotEmpty) {
        return '$address, $city';
      } else if (address.isNotEmpty) {
        return address;
      } else if (city.isNotEmpty) {
        return city;
      }
    } else if (addressData is String) {
      return addressData;
    }
    return 'No address provided';
  }

  Future<void> _showCustomerSheet({Map<String, dynamic>? customer}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) =>
          _CustomerDetailSheet(isEdit: customer != null, customer: customer),
    );

    if (result == true && mounted) {
      context.read<AdminViewModel>().loadCustomers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            customer == null
                ? 'Customer created successfully'
                : 'Customer updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> customer) async {
    final customerId =
        customer['user_id'] ?? customer['profile_id'] ?? customer['id'];
    if (customerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete ${_fullName(customer)}?',
        ),
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
      final success = await context.read<AdminViewModel>().deleteCustomer(
            customerId.toString(),
          );
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminViewModel>();
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        final allCustomers = viewModel.customers;
        final query = _searchController.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? allCustomers
            : allCustomers.where((customer) {
                return _fullName(customer).toLowerCase().contains(query) ||
                    _email(customer).toLowerCase().contains(query) ||
                    _referenceNumber(customer).toLowerCase().contains(query) ||
                    _address(customer).toLowerCase().contains(query);
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
                                  'Customer Management',
                                  style: AppTypography.title().copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  '${allCustomers.length} total customers',
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
                          children: [
                            Icon(
                              Icons.search,
                              size: 22.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                style: AppTypography.body().copyWith(
                                  fontSize: 15.sp,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search customers...',
                                  hintStyle: AppTypography.body().copyWith(
                                    fontSize: 15.sp,
                                    color: Colors.white.withValues(alpha: 0.75),
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
                  child: viewModel.isLoading && allCustomers.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadCustomers(),
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
                                  onPressed: () => _showCustomerSheet(),
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
                                    'Add Customer',
                                    style: AppTypography.body().copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ),
                              ),
                              if (_hasPrivilege('create')) SizedBox(height: 14.h),
                              if (filtered.isEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(vertical: 40.h),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'No customers found',
                                    style: AppTypography.body().copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                )
                              else
                                ...filtered.map(
                                  (customer) => Padding(
                                    padding: EdgeInsets.only(bottom: 12.h),
                                    child: _CustomerCard(
                                      name: _fullName(customer),
                                      email: _email(customer),
                                      referenceNumber: _referenceNumber(
                                        customer,
                                      ),
                                      address: _address(customer),
                                      onEdit: _hasPrivilege('update')
                                          ? () => _showCustomerSheet(customer: customer)
                                          : null,
                                      onDelete: _hasPrivilege('delete')
                                          ? () => _confirmDelete(customer)
                                          : null,
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

class _CustomerCard extends StatelessWidget {
  final String name;
  final String email;
  final String referenceNumber;
  final String address;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canEdit;
  final bool canDelete;

  const _CustomerCard({
    required this.name,
    required this.email,
    required this.referenceNumber,
    required this.address,
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
                  name,
                  style: AppTypography.body().copyWith(
                    fontSize: 16.sp,
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (referenceNumber != '--')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    referenceNumber,
                    style: AppTypography.body().copyWith(
                      fontSize: 11.sp,
                      color: const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
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
            address,
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: 12.h),
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

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBox({required this.label, required this.value});

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

// ─────────────────────────────────────────────────────────────────────────────
// Customer Detail Sheet — 5-tab bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerDetailSheet extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? customer;

  const _CustomerDetailSheet({required this.isEdit, this.customer});

  @override
  State<_CustomerDetailSheet> createState() => _CustomerDetailSheetState();
}

class _CustomerDetailSheetState extends State<_CustomerDetailSheet> {
  int _currentTabIndex = 0;
  bool _isSubmitting = false;
  String? _customerId;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _referenceNumberController;
  late final TextEditingController _emailController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;
  late final TextEditingController _countryController;

  String? _selectedServiceGroupId;

  @override
  void initState() {
    super.initState();
    debugPrint('CUSTOMER FORM: Initializing form - isEdit: ${widget.isEdit}');
    debugPrint('CUSTOMER FORM: Customer data received: ${widget.customer}');
    
    final c = widget.customer;
    _customerId = (c?['user_id'] ?? c?['profile_id'] ?? c?['id'])?.toString();
    _firstNameController = TextEditingController(
      text: (c?['first_name'] ?? c?['firstName'] ?? '').toString(),
    );
    _lastNameController = TextEditingController(
      text: (c?['last_name'] ?? c?['lastName'] ?? '').toString(),
    );
    _referenceNumberController = TextEditingController(
      text: (c?['reference_number'] ?? c?['referenceNumber'] ?? '').toString(),
    );
    _emailController = TextEditingController(
      text: (c?['email'] ?? '').toString(),
    );
    final address = c?['address'] as Map<String, dynamic>?;
    _addressController = TextEditingController(
      text: (address?['name'] ?? address?['address'] ?? '').toString(),
    );
    _cityController = TextEditingController(
      text: (address?['city'] ?? '').toString(),
    );
    _stateController = TextEditingController(
      text: (address?['state'] ?? '').toString(),
    );
    _zipController = TextEditingController(
      text: (address?['zip'] ?? '').toString(),
    );
    _countryController = TextEditingController(
      text: (address?['country'] ?? '').toString(),
    );

    // Debug logging for controller values
    debugPrint('CUSTOMER FORM: Controller values:');
    debugPrint('  First Name: "${_firstNameController.text}"');
    debugPrint('  Last Name: "${_lastNameController.text}"');
    debugPrint('  Email: "${_emailController.text}"');
    debugPrint('  Reference: "${_referenceNumberController.text}"');
    debugPrint('  Address: "${_addressController.text}"');
    _selectedServiceGroupId =
        (c?['default_service_group_id'] ?? '').toString().isEmpty
            ? null
            : c!['default_service_group_id'].toString();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<AdminViewModel>();
      vm.loadSites();
      if (_customerId != null) {
        vm.loadCustomerContacts(_customerId!);
        vm.loadCustomerInvoiceProfiles(_customerId!);
        vm.loadCustomerInvoices(_customerId!);
      }
      vm.loadServiceGroups();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _referenceNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _submitDetails() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);

    final payload = {
      if (widget.isEdit)
        'id': widget.customer?['user_id'] ??
            widget.customer?['profile_id'] ??
            widget.customer?['id'],
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'reference_number': _referenceNumberController.text.trim(),
      'email': _emailController.text.trim(),
      'address': {
        'name': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'zip': _zipController.text.trim(),
        'country': _countryController.text.trim(),
      },
      'default_service_group_id': _selectedServiceGroupId != null
          ? int.tryParse(_selectedServiceGroupId!)
          : null,
    };

    final vm = context.read<AdminViewModel>();

    if (widget.isEdit) {
      final success = await vm.updateCustomer(payload);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showError(vm.errorMessage);
        }
      }
    } else {
      final data = await vm.createCustomer(payload);
      if (mounted) {
        setState(() => _isSubmitting = false);
        if (data != null) {
          _customerId =
              (data['user_id'] ?? data['profile_id'] ?? data['id'])?.toString();
          setState(() => _currentTabIndex = 1);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer created successfully. Now add contacts.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          _showError(vm.errorMessage);
        }
      }
    }
  }

  void _showError(String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Failed to save customer'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildDetailsContent() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Customer Details'),
          SizedBox(height: 12.h),
          UltimateMobileTextField(
            controller: _firstNameController,
            initialValue: widget.isEdit && widget.customer != null 
                ? (widget.customer!['first_name']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('First Name *'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Required'
                : null,
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _lastNameController,
            initialValue: widget.isEdit && widget.customer != null 
                ? (widget.customer!['last_name']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Last Name *'),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Last name is required'
                : null,
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _referenceNumberController,
            initialValue: widget.isEdit && widget.customer != null 
                ? (widget.customer!['reference_number']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Reference Number (Optional)'),
          ),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _emailController,
            initialValue: widget.isEdit && widget.customer != null 
                ? (widget.customer!['email']?.toString() ?? '')
                : null,
            keyboardType: TextInputType.emailAddress,
            decoration: _inputDecoration('Email *'),
            validator: (v) {
              final input = v?.trim() ?? '';
              if (input.isEmpty) return 'Email is required';
              if (!input.contains('@') || !input.contains('.')) {
                return 'Enter valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 14.h),
          _sectionTitle('Address'),
          SizedBox(height: 10.h),
          UltimateMobileTextField(
            controller: _addressController,
            initialValue: widget.isEdit && widget.customer != null 
                ? ((widget.customer!['address'] as Map<String, dynamic>?)?['name']?.toString() ?? (widget.customer!['address'] as Map<String, dynamic>?)?['address']?.toString() ?? '')
                : null,
            decoration: _inputDecoration('Address *'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Address is required' : null,
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: UltimateMobileTextField(
                  controller: _cityController,
                  initialValue: widget.isEdit && widget.customer != null 
                      ? ((widget.customer!['address'] as Map<String, dynamic>?)?['city']?.toString() ?? '')
                      : null,
                  decoration: _inputDecoration('City *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'City is required'
                      : null,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: UltimateMobileTextField(
                  controller: _stateController,
                  initialValue: widget.isEdit && widget.customer != null 
                      ? ((widget.customer!['address'] as Map<String, dynamic>?)?['state']?.toString() ?? '')
                      : null,
                  decoration: _inputDecoration('County *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'County is required'
                      : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: UltimateMobileTextField(
                  controller: _zipController,
                  initialValue: widget.isEdit && widget.customer != null 
                      ? ((widget.customer!['address'] as Map<String, dynamic>?)?['zip']?.toString() ?? '')
                      : null,
                  decoration: _inputDecoration('Post Code *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Post Code is required'
                      : null,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: UltimateMobileTextField(
                  controller: _countryController,
                  initialValue: widget.isEdit && widget.customer != null 
                      ? ((widget.customer!['address'] as Map<String, dynamic>?)?['country']?.toString() ?? '')
                      : null,
                  decoration: _inputDecoration('Country *'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Country is required'
                      : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Consumer<AdminViewModel>(
            builder: (context, vm, _) {
              final items = vm.serviceGroups;
              return UltimateMobileDropdown<String>(
                value: _selectedServiceGroupId,
                decoration:
                    _inputDecoration('Default Service Group (Optional)'),
                hintText: 'Default Service Group (Optional)',
                items: items
                    .map((g) => DropdownMenuItem(
                          value: g['id'].toString(),
                          child: Text(g['name'] ?? 'Unnamed Group'),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedServiceGroupId = v),
              );
            },
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitDetails,
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
                      widget.isEdit ? 'Update Customer' : 'Create Customer',
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
    );
  }

  Widget _buildTabContent() {
    switch (_currentTabIndex) {
      case 1:
        return _ContactsPanel(customerId: _customerId);
      case 2:
        return _InvoiceProfilesPanel(customerId: _customerId);
      default:
        return _buildDetailsContent();
    }
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.body().copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // Mobile UI fix: Force controller text to display on mobile
    if (widget.isEdit && widget.customer != null) {
      final customer = widget.customer;
      
      // Always update controller text to force mobile UI refresh
      _firstNameController.text = customer?['first_name']?.toString() ?? '';
      _lastNameController.text = customer?['last_name']?.toString() ?? '';
      _emailController.text = customer?['email']?.toString() ?? '';
      _referenceNumberController.text = customer?['reference_number']?.toString() ?? '';
      
      final address = customer?['address'] as Map<String, dynamic>?;
      _addressController.text = address?['name']?.toString() ?? address?['address']?.toString() ?? '';
      _cityController.text = address?['city']?.toString() ?? '';
      _stateController.text = address?['state']?.toString() ?? '';
      _zipController.text = address?['zip']?.toString() ?? '';
      _countryController.text = address?['country']?.toString() ?? '';
      
      debugPrint('CUSTOMER FORM: Force updated controllers in build:');
      debugPrint('  First Name: "${_firstNameController.text}"');
      debugPrint('  Last Name: "${_lastNameController.text}"');
      debugPrint('  Email: "${_emailController.text}"');
      debugPrint('  Reference: "${_referenceNumberController.text}"');
      debugPrint('  Address: "${_addressController.text}"');
    }

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
                  widget.isEdit ? 'Edit Customer' : 'Add Customer',
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
              currentIndex: _currentTabIndex,
              onTap: (index) => setState(() => _currentTabIndex = index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF0E45BA),
              unselectedItemColor: const Color(0xFF9CA3AF),
              selectedFontSize: 10.sp,
              unselectedFontSize: 10.sp,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Details',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.people_outline),
                  label: 'Contacts',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Inv. Profile',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sites Panel — attach / detach sites to the customer
// ─────────────────────────────────────────────────────────────────────────────

class _SitesPanel extends StatefulWidget {
  final String? customerId;

  const _SitesPanel({this.customerId});

  @override
  State<_SitesPanel> createState() => _SitesPanelState();
}

class _SitesPanelState extends State<_SitesPanel> {
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) _loadAttachedSites();
  }

  @override
  void didUpdateWidget(_SitesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customerId != widget.customerId &&
        widget.customerId != null) {
      _loadAttachedSites();
    }
  }

  Future<void> _loadAttachedSites() async {
    if (widget.customerId == null) return;
    setState(() => _loading = true);
    final vm = context.read<AdminViewModel>();

    await vm.loadSites();

    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _detachSite(String siteId) async {
    if (widget.customerId == null) return;
    final vm = context.read<AdminViewModel>();
    final success = await vm.detachSiteFromCustomer(widget.customerId!, siteId);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Site detached'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _confirmDetach(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Detachment'),
        content:
            Text('Are you sure you want to detach "$name" from this customer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Detach', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _detachSite(id);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (widget.customerId == null) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 16.w),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 48.sp,
              color: const Color(0xFF9CA3AF),
            ),
            SizedBox(height: 12.h),
            Text(
              'Save customer details first to manage sites',
              textAlign: TextAlign.center,
              style: AppTypography.body().copyWith(
                color: const Color(0xFF6B7280),
                fontSize: 13.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<AdminViewModel>(
      builder: (ctx, vm, _) {
        if (_loading) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()));
        }
        final allSites = vm.sites;
        final attachedSites = allSites.where((s) {
          final profileId = s['customer_profile_id']?.toString();
          return profileId != null && profileId == widget.customerId;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Manage Sites', attachedSites.length,
                const Color(0xFFEFF6FF), const Color(0xFF1D4ED8)),
            SizedBox(height: 16.h),
            _MultiSelectField(
              label: 'Attach / Detach Sites',
              items: attachedSites,
              onRemove: (id, name) => _confirmDetach(id, name),
              onTap: () async {
                setState(() => _loading = true);
                await vm.loadSites();
                if (mounted) {
                  setState(() => _loading = false);
                  final latestAll = vm.sites;
                  // Get sites already attached to this customer OR sites with no customer attached
                  final filteredOptions = latestAll.where((s) {
                    final pId = s['customer_profile_id']?.toString();
                    return pId == null || pId.isEmpty || pId == "null" || pId == widget.customerId;
                  }).toList();

                  final initiallySelectedIds = attachedSites.map((s) => s['id']?.toString() ?? '').toSet();

                  final resultIds = await showDialog<Set<String>>(
                    context: context,
                    builder: (ctx) => _MultiSelectDialog(
                      title: 'Attach / Detach Sites',
                      options: filteredOptions,
                      initiallySelected: initiallySelectedIds,
                      actionLabel: 'Apply Changes',
                    ),
                  );

                  if (resultIds != null && mounted) {
                    setState(() => _loading = true);
                    
                    // Identify items to attach
                    final toAttach = resultIds.difference(initiallySelectedIds);
                    for (final id in toAttach) {
                      await vm.attachSiteToCustomer(widget.customerId!, id);
                    }

                    // Identify items to detach
                    final potentiallyToDetach = initiallySelectedIds.difference(resultIds);
                    for (final id in potentiallyToDetach) {
                      final siteName = attachedSites.firstWhere((s) => s['id']?.toString() == id)['name'] ?? 'Site';
                      
                      // Show confirmation for each detachment during bulk change if you want, 
                      // but the user specifically asked for confirmation when "cross icon" is pressed on the chip.
                      // For bulk deselect in the dialog, I will just apply them, or should I also confirm?
                      // User said: "User should be able to select from the list to attach and deselect to detach."
                      // And "When user press cross icon then after a confirmation popup site should be detached."
                      // I will follow the cross icon requirement for confirmation. 
                      // For the dialog deselect, I will just detach directly for better UX in multi-select.
                      await vm.detachSiteFromCustomer(widget.customerId!, id);
                    }
                    
                    await vm.loadSites();
                    if (mounted) setState(() => _loading = false);
                  }
                }
              },
            ),
            SizedBox(height: 12.h),
            Text(
              'Click tags to remove, or use dropdown to manage sites',
              style: AppTypography.body().copyWith(
                  fontSize: 11.sp,
                  color: const Color(0xFF9CA3AF),
                  fontStyle: FontStyle.italic),
            ),
          ],
        );
      },
    );
  }

  Widget _sectionHeader(
      String title, int count, Color badgeBg, Color badgeText) {
    return Row(
      children: [
        Text(title,
            style: AppTypography.body().copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827))),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
              color: badgeBg, borderRadius: BorderRadius.circular(10.r)),
          child: Text('$count',
              style: AppTypography.body().copyWith(
                  fontSize: 11.sp,
                  color: badgeText,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

class _MultiSelectField extends StatelessWidget {
  final String label;
  final List<Map<String, dynamic>> items;
  final Function(String id, String name)? onRemove;
  final VoidCallback onTap;

  const _MultiSelectField(
      {required this.label,
      required this.items,
      this.onRemove,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.body().copyWith(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280))),
        SizedBox(height: 6.h),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(minHeight: 48.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: const Color(0xFFD1D5DB))),
            child: Row(
              children: [
                Expanded(
                  child: items.isEmpty
                      ? Text('Select $label',
                          style: AppTypography.body().copyWith(
                              fontSize: 14.sp, color: const Color(0xFF9CA3AF)))
                      : Wrap(
                          spacing: 8.w,
                          runSpacing: 8.h,
                          children: items.map((site) {
                            final name = site['name']?.toString() ?? 'Unnamed';
                            final id = site['id']?.toString() ?? '';
                            return Container(
                              padding: EdgeInsets.fromLTRB(10.w, 6.h,
                                  onRemove != null ? 6.w : 10.w, 6.h),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8.r),
                                border:
                                    Border.all(color: const Color(0xFFD1D5DB)),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(name,
                                      style: AppTypography.body().copyWith(
                                          fontSize: 12.sp,
                                          color: const Color(0xFF374151),
                                          fontWeight: FontWeight.w500)),
                                  if (onRemove != null) ...[
                                    SizedBox(width: 6.w),
                                    GestureDetector(
                                      onTap: () => onRemove!(id, name),
                                      child: Icon(Icons.cancel_rounded,
                                          size: 16.sp,
                                          color: const Color(0xFF9CA3AF)),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                SizedBox(width: 8.w),
                Icon(Icons.unfold_more_rounded,
                    color: const Color(0xFF6B7280), size: 20.sp),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MultiSelectDialog extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> options;
  final Set<String> initiallySelected;
  final String actionLabel;

  const _MultiSelectDialog(
      {required this.title,
      required this.options,
      required this.initiallySelected,
      required this.actionLabel});

  @override
  State<_MultiSelectDialog> createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<_MultiSelectDialog> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      title: Text(widget.title,
          style: AppTypography.title().copyWith(fontSize: 18.sp)),
      content: SizedBox(
        width: double.maxFinite,
        child: widget.options.isEmpty
            ? Padding(
                padding: EdgeInsets.symmetric(vertical: 20.h),
                child: Text('No options available',
                    textAlign: TextAlign.center,
                    style: AppTypography.body().copyWith(color: Colors.grey)),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: widget.options.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final option = widget.options[index];
                  final id = option['id'].toString();
                  final isSelected = _selectedIds.contains(id);
                  return CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedIds.add(id);
                        } else {
                          _selectedIds.remove(id);
                        }
                      });
                    },
                    title: Text(option['name'] ?? 'Unnamed Site',
                        style: AppTypography.body().copyWith(
                            fontSize: 14.sp,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal)),
                    subtitle: option['address'] != null
                        ? Text(
                            _formatAddress(option['address']),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.body()
                                .copyWith(fontSize: 12.sp, color: Colors.grey),
                          )
                        : null,
                    activeColor: const Color(0xFF0E45BA),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: AppTypography.body().copyWith(color: Colors.grey[600]))),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedIds),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0E45BA),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r))),
          child: Text(widget.actionLabel,
              style: AppTypography.body()
                  .copyWith(color: Colors.white, fontSize: 13.sp)),
        ),
      ],
    );
  }

  String _formatAddress(dynamic address) {
    if (address == null) return '';
    if (address is String) return address;
    if (address is Map) {
      final name = address['name'] ?? address['address'] ?? '';
      final city = address['city'] ?? '';
      if (name.isNotEmpty && city.isNotEmpty) return '$name, $city';
      return name.isNotEmpty ? name.toString() : city.toString();
    }
    return address.toString();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contacts Panel
// ─────────────────────────────────────────────────────────────────────────────

class _ContactsPanel extends StatefulWidget {
  final String? customerId;
  const _ContactsPanel({this.customerId});

  @override
  State<_ContactsPanel> createState() => _ContactsPanelState();
}

class _ContactsPanelState extends State<_ContactsPanel> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.customerId != null) {
        context.read<AdminViewModel>().loadCustomerContacts(widget.customerId!);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fullName(Map<String, dynamic> c) {
    final first = (c['first_name'] ?? c['firstName'] ?? '').toString().trim();
    final last = (c['last_name'] ?? c['lastName'] ?? '').toString().trim();
    final combined = '$first $last'.trim();
    return combined.isEmpty ? 'Unnamed Contact' : combined;
  }

  String _email(Map<String, dynamic> c) {
    final v = (c['email'] ?? '').toString().trim();
    return v.isEmpty ? 'no-email@company.com' : v;
  }

  String _phone(Map<String, dynamic> c) {
    final v =
        (c['contact_number'] ?? c['mobileNumber'] ?? '').toString().trim();
    return v.isEmpty ? '--' : v;
  }

  String _position(Map<String, dynamic> c) {
    final v = (c['position'] ?? '').toString().trim();
    return v.isEmpty ? '--' : v;
  }

  String _notes(Map<String, dynamic> c) {
    return (c['notes'] ?? '').toString().trim();
  }

  Future<void> _showContactDialog({Map<String, dynamic>? contact}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ContactFormDialog(
          isEdit: contact != null,
          contact: contact,
          customerId: widget.customerId),
    );
    if (result == true && mounted && widget.customerId != null) {
      await context
          .read<AdminViewModel>()
          .loadCustomerContacts(widget.customerId!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            contact == null
                ? 'Contact created successfully'
                : 'Contact updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> contact) async {
    final contactId = contact['id'];
    if (contactId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Delete ${_fullName(contact)}?'),
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
    if (confirmed == true && mounted && widget.customerId != null) {
      final success = await context
          .read<AdminViewModel>()
          .deleteCustomerContact(widget.customerId!, contactId.toString());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (ctx, vm, _) {
        final all = vm.customerContacts;
        final q = _searchCtrl.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? all
            : all
                .where(
                  (c) =>
                      _fullName(c).toLowerCase().contains(q) ||
                      _email(c).toLowerCase().contains(q) ||
                      _phone(c).toLowerCase().contains(q) ||
                      _position(c).toLowerCase().contains(q),
                )
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchField(
              controller: _searchCtrl,
              hint: 'Search contacts...',
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed: () => _showContactDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B122),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: Icon(Icons.add, size: 22.sp),
                label: Text(
                  'Add Contact',
                  style: AppTypography.body().copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            if (vm.isLoading && all.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (filtered.isEmpty)
              Container(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                alignment: Alignment.center,
                child: Text(
                  'No contacts found',
                  style: AppTypography.body().copyWith(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 13.sp,
                  ),
                ),
              )
            else
              ...filtered.map(
                (c) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _ContactCard(
                    name: _fullName(c),
                    email: _email(c),
                    phone: _phone(c),
                    position: _position(c),
                    notes: _notes(c),
                    onEdit: () => _showContactDialog(contact: c),
                    onDelete: () => _confirmDelete(c),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice Profiles Panel
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceProfilesPanel extends StatefulWidget {
  final String? customerId;
  const _InvoiceProfilesPanel({this.customerId});

  @override
  State<_InvoiceProfilesPanel> createState() => _InvoiceProfilesPanelState();
}

class _InvoiceProfilesPanelState extends State<_InvoiceProfilesPanel> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.customerId != null) {
        context
            .read<AdminViewModel>()
            .loadCustomerInvoiceProfiles(widget.customerId!);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fullName(Map<String, dynamic> p) {
    final first = (p['contact_first_name'] ?? p['firstName'] ?? '').toString().trim();
    final last = (p['contact_last_name'] ?? p['lastName'] ?? '').toString().trim();
    final combined = '$first $last'.trim();
    return combined.isEmpty ? 'Unnamed Profile' : combined;
  }

  String _email(Map<String, dynamic> p) {
    final v = (p['email'] ?? '').toString().trim();
    return v.isEmpty ? 'no-email@company.com' : v;
  }

  String _company(Map<String, dynamic> p) {
    final v = (p['company_name'] ?? p['companyName'] ?? '').toString().trim();
    return v.isEmpty ? '--' : v;
  }

  String _phone(Map<String, dynamic> p) {
    final v = (p['contact_number'] ?? p['contactNumber'] ?? '').toString().trim();
    return v.isEmpty ? '--' : v;
  }

  String _terms(Map<String, dynamic> p) => (p['terms'] ?? '').toString().trim();

  Future<void> _showProfileDialog({Map<String, dynamic>? profile}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InvoiceProfileFormDialog(
          isEdit: profile != null,
          profile: profile,
          customerId: widget.customerId),
    );
    if (result == true && mounted && widget.customerId != null) {
      await context
          .read<AdminViewModel>()
          .loadCustomerInvoiceProfiles(widget.customerId!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            profile == null
                ? 'Invoice profile created'
                : 'Invoice profile updated',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> profile) async {
    final profileId = profile['id'];
    if (profileId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice Profile'),
        content: Text('Delete ${_fullName(profile)}?'),
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
    if (confirmed == true && mounted && widget.customerId != null) {
      final success = await context
          .read<AdminViewModel>()
          .deleteCustomerInvoiceProfile(
              widget.customerId!, profileId.toString());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice profile deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (ctx, vm, _) {
        final all = vm.customerInvoiceProfiles;
        final q = _searchCtrl.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? all
            : all
                .where(
                  (p) =>
                      _fullName(p).toLowerCase().contains(q) ||
                      _email(p).toLowerCase().contains(q) ||
                      _company(p).toLowerCase().contains(q) ||
                      _phone(p).toLowerCase().contains(q),
                )
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchField(
              controller: _searchCtrl,
              hint: 'Search invoice profiles...',
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed: () => _showProfileDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B122),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: Icon(Icons.add, size: 22.sp),
                label: Text(
                  'Add Invoice Profile',
                  style: AppTypography.body().copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            if (vm.isLoading && all.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (filtered.isEmpty)
              Container(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                alignment: Alignment.center,
                child: Text(
                  'No invoice profiles found',
                  style: AppTypography.body().copyWith(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 13.sp,
                  ),
                ),
              )
            else
              ...filtered.map(
                (p) => Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _InvoiceProfileCard(
                    name: _fullName(p),
                    email: _email(p),
                    position: _company(p),
                    phone: _phone(p),
                    notes: _terms(p),
                    onEdit: () => _showProfileDialog(profile: p),
                    onDelete: () => _confirmDelete(p),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoices Panel
// ─────────────────────────────────────────────────────────────────────────────

class _InvoicesPanel extends StatefulWidget {
  final String? customerId;
  const _InvoicesPanel({this.customerId});

  @override
  State<_InvoicesPanel> createState() => _InvoicesPanelState();
}

class _InvoicesPanelState extends State<_InvoicesPanel> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _customerName(Map<String, dynamic> inv) {
    final v = (inv['customerName'] ?? '').toString().trim();
    return v.isEmpty ? 'Unknown Customer' : v;
  }

  String _invoiceNumber(Map<String, dynamic> inv) {
    final v = (inv['invoiceNumber'] ?? '').toString().trim();
    return v.isEmpty ? 'N/A' : v;
  }

  String _amount(Map<String, dynamic> inv) {
    final v = inv['amount'];
    if (v == null) return '£0.00';
    final numVal = double.tryParse(v.toString()) ?? 0.0;
    return '£${numVal.toStringAsFixed(2)}';
  }

  String _dueDate(Map<String, dynamic> inv) {
    final v = (inv['dueDate'] ?? '').toString().trim();
    return v.isEmpty ? '--' : v;
  }

  String _status(Map<String, dynamic> inv) {
    final v = (inv['status'] ?? '').toString().trim();
    return v.isEmpty ? 'Draft' : v;
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF10B981);
      case 'overdue':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFFECFDF5);
      case 'overdue':
        return const Color(0xFFFEE2E2);
      case 'pending':
        return const Color(0xFFFFFBEB);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Future<void> _showInvoiceDialog({Map<String, dynamic>? invoice}) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _InvoiceFormDialog(
          isEdit: invoice != null,
          invoice: invoice,
          customerId: widget.customerId!),
    );
    if (result == true && mounted && widget.customerId != null) {
      await context
          .read<AdminViewModel>()
          .loadCustomerInvoices(widget.customerId!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            invoice == null
                ? 'Invoice created successfully'
                : 'Invoice updated successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> invoice) async {
    final invoiceId = invoice['id'];
    if (invoiceId == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Delete invoice ${_invoiceNumber(invoice)}?'),
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
    if (confirmed == true && mounted && widget.customerId != null) {
      final success = await context
          .read<AdminViewModel>()
          .deleteCustomerInvoice(widget.customerId!, invoiceId.toString());
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice deleted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (ctx, vm, _) {
        final all = vm.customerInvoices;
        final q = _searchCtrl.text.trim().toLowerCase();
        final filtered = q.isEmpty
            ? all
            : all
                .where(
                  (inv) =>
                      _customerName(inv).toLowerCase().contains(q) ||
                      _invoiceNumber(inv).toLowerCase().contains(q) ||
                      _amount(inv).toLowerCase().contains(q) ||
                      _status(inv).toLowerCase().contains(q),
                )
                .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SearchField(
              controller: _searchCtrl,
              hint: 'Search invoices...',
              onChanged: (_) => setState(() {}),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed: () => _showInvoiceDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00B122),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: Icon(Icons.add, size: 22.sp),
                label: Text(
                  'Add Invoice',
                  style: AppTypography.body().copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 14.h),
            if (vm.isLoading && all.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (filtered.isEmpty)
              Container(
                padding: EdgeInsets.symmetric(vertical: 32.h),
                alignment: Alignment.center,
                child: Text(
                  'No invoices found',
                  style: AppTypography.body().copyWith(
                    color: const Color(0xFF9CA3AF),
                    fontSize: 13.sp,
                  ),
                ),
              )
            else
              ...filtered.map((inv) {
                final status = _status(inv);
                return Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: _InvoiceCard(
                    invoiceNumber: _invoiceNumber(inv),
                    customerName: _customerName(inv),
                    amount: _amount(inv),
                    dueDate: _dueDate(inv),
                    status: status,
                    statusColor: _statusColor(status),
                    statusBgColor: _statusBgColor(status),
                    onEdit: () => _showInvoiceDialog(invoice: inv),
                    onDelete: () => _confirmDelete(inv),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Form Dialogs (popup forms)
// ─────────────────────────────────────────────────────────────────────────────

class _ContactFormDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? contact;
  final String? customerId;

  const _ContactFormDialog(
      {required this.isEdit, this.contact, this.customerId});

  @override
  State<_ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<_ContactFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _notesCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _firstNameCtrl = TextEditingController(
      text: (c?['first_name'] ?? c?['firstName'] ?? '').toString(),
    );
    _lastNameCtrl = TextEditingController(
      text: (c?['last_name'] ?? c?['lastName'] ?? '').toString(),
    );
    _positionCtrl = TextEditingController(
      text: (c?['position'] ?? '').toString(),
    );
    _emailCtrl = TextEditingController(text: (c?['email'] ?? '').toString());
    _mobileCtrl = TextEditingController(
      text: (c?['contact_number'] ?? c?['mobileNumber'] ?? '').toString(),
    );
    _notesCtrl = TextEditingController(text: (c?['notes'] ?? '').toString());
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _positionCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _isSubmitting ||
        widget.customerId == null) return;
    setState(() => _isSubmitting = true);
    final payload = {
      if (widget.isEdit) 'id': widget.contact?['id'],
      'first_name': _firstNameCtrl.text.trim(),
      'last_name': _lastNameCtrl.text.trim(),
      'position': _positionCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'contact_number': _mobileCtrl.text.trim(),
      'notes': _notesCtrl.text.trim(),
    };
    final vm = context.read<AdminViewModel>();
    final success = widget.isEdit
        ? await vm.updateCustomerContact(widget.customerId!, payload)
        : await vm.createCustomerContact(widget.customerId!, payload);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? 'Failed to save contact'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contact;
    if (c != null && _firstNameCtrl.text.isEmpty && _lastNameCtrl.text.isEmpty) {
      _firstNameCtrl.text = (c['first_name'] ?? c['firstName'] ?? '').toString();
      _lastNameCtrl.text = (c['last_name'] ?? c['lastName'] ?? '').toString();
      _positionCtrl.text = (c['position'] ?? '').toString();
      _emailCtrl.text = (c['email'] ?? '').toString();
      _mobileCtrl.text = (c['contact_number'] ?? c['mobileNumber'] ?? '').toString();
      _notesCtrl.text = (c['notes'] ?? '').toString();
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEdit ? 'Edit Contact' : 'Add Contact',
                style: AppTypography.title().copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              SizedBox(height: 16.h),
              UltimateMobileTextField(
                controller: _firstNameCtrl,
                decoration: _dlgInput('First Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),
              UltimateMobileTextField(
                controller: _lastNameCtrl,
                decoration: _dlgInput('Last Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),
              UltimateMobileTextField(
                controller: _positionCtrl,
                decoration: _dlgInput('Position *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),
              UltimateMobileTextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _dlgInput('Email *'),
                validator: (v) {
                  final input = v?.trim() ?? '';
                  if (input.isEmpty) return 'Required';
                  if (!input.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              SizedBox(height: 10.h),
              UltimateMobileTextField(
                controller: _mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: _dlgInput('Mobile Number *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),
              UltimateMobileTextField(
                controller: _notesCtrl,
                decoration: _dlgInput('Notes (Optional)'),
                maxLines: 2,
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        minimumSize: Size.fromHeight(44.h),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTypography.body().copyWith(
                          color: const Color(0xFF374151),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E45BA),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        minimumSize: Size.fromHeight(44.h),
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
                              widget.isEdit
                                  ? 'Update Contact'
                                  : 'Create Contact',
                              style: AppTypography.body().copyWith(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dlgInput(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTypography.body().copyWith(
          fontSize: 12.sp,
          color: const Color(0xFF6B7280),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF0E45BA), width: 1.1),
        ),
      );
}

// Invoice Profile Form Dialog
class _InvoiceProfileFormDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? profile;
  final String? customerId;

  const _InvoiceProfileFormDialog(
      {required this.isEdit, this.profile, this.customerId});

  @override
  State<_InvoiceProfileFormDialog> createState() =>
      _InvoiceProfileFormDialogState();
}

class _InvoiceProfileFormDialogState extends State<_InvoiceProfileFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _companyNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _contactNumberCtrl;
  late final TextEditingController _poPrefixCtrl;
  late final TextEditingController _taxRateCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _stateCtrl;
  late final TextEditingController _zipCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _termsCtrl;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _firstNameCtrl = TextEditingController(
      text: (p?['contact_first_name'] ?? p?['firstName'] ?? '').toString(),
    );
    _lastNameCtrl = TextEditingController(
      text: (p?['contact_last_name'] ?? p?['lastName'] ?? '').toString(),
    );
    _companyNameCtrl = TextEditingController(
      text: (p?['company_name'] ?? p?['companyName'] ?? '').toString(),
    );
    _emailCtrl = TextEditingController(text: (p?['email'] ?? '').toString());
    _contactNumberCtrl = TextEditingController(
      text: (p?['contact_number'] ?? p?['contactNumber'] ?? '').toString(),
    );
    _poPrefixCtrl = TextEditingController(
      text: (p?['po_number_prefix'] ?? p?['poNumberPrefix'] ?? '').toString(),
    );
    _taxRateCtrl = TextEditingController(
      text: (p?['tax_rate'] ?? p?['taxRate'] ?? '').toString(),
    );
    _termsCtrl = TextEditingController(
      text: (p?['terms'] ?? '').toString(),
    );
    final addr = p?['address'] as Map<String, dynamic>?;
    _addressCtrl = TextEditingController(
      text: (addr?['name'] ?? addr?['address'] ?? '').toString(),
    );
    _cityCtrl = TextEditingController(text: (addr?['city'] ?? '').toString());
    _stateCtrl = TextEditingController(text: (addr?['state'] ?? '').toString());
    _zipCtrl = TextEditingController(text: (addr?['zip'] ?? '').toString());
    _countryCtrl = TextEditingController(
      text: (addr?['country'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _companyNameCtrl.dispose();
    _emailCtrl.dispose();
    _contactNumberCtrl.dispose();
    _poPrefixCtrl.dispose();
    _taxRateCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _countryCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() ||
        _isSubmitting ||
        widget.customerId == null) return;
    setState(() => _isSubmitting = true);
    final payload = {
      if (widget.isEdit) 'id': widget.profile?['id'],
      'company_name': _companyNameCtrl.text.trim(),
      'contact_first_name': _firstNameCtrl.text.trim(),
      'contact_last_name': _lastNameCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'contact_number': _contactNumberCtrl.text.trim(),
      'po_number_prefix': _poPrefixCtrl.text.trim(),
      'tax_rate': double.tryParse(_taxRateCtrl.text.trim()) ?? 0,
      'address': {
        'name': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'zip': _zipCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
      },
      'terms': _termsCtrl.text.trim(),
    };
    final vm = context.read<AdminViewModel>();
    final success = widget.isEdit
        ? await vm.updateCustomerInvoiceProfile(widget.customerId!, payload)
        : await vm.createCustomerInvoiceProfile(widget.customerId!, payload);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? 'Failed to save invoice profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;
    if (p != null && _firstNameCtrl.text.isEmpty && _lastNameCtrl.text.isEmpty) {
      _firstNameCtrl.text = (p['contact_first_name'] ?? p['firstName'] ?? '').toString();
      _lastNameCtrl.text = (p['contact_last_name'] ?? p['lastName'] ?? '').toString();
      _companyNameCtrl.text = (p['company_name'] ?? p['companyName'] ?? '').toString();
      _emailCtrl.text = (p['email'] ?? '').toString();
      _contactNumberCtrl.text = (p['contact_number'] ?? p['contactNumber'] ?? '').toString();
      _poPrefixCtrl.text = (p['po_number_prefix'] ?? p['poNumberPrefix'] ?? '').toString();
      _taxRateCtrl.text = (p['tax_rate'] ?? p['taxRate'] ?? '').toString();
      _termsCtrl.text = (p['terms'] ?? '').toString();
      final addr = p['address'] as Map<String, dynamic>?;
      _addressCtrl.text = (addr?['name'] ?? addr?['address'] ?? '').toString();
      _cityCtrl.text = (addr?['city'] ?? '').toString();
      _stateCtrl.text = (addr?['state'] ?? '').toString();
      _zipCtrl.text = (addr?['zip'] ?? '').toString();
      _countryCtrl.text = (addr?['country'] ?? '').toString();
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEdit ? 'Edit Invoice Profile' : 'Add Invoice Profile',
                style: AppTypography.title().copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              SizedBox(height: 16.h),

              // Contact First Name
              UltimateMobileTextField(
                controller: _firstNameCtrl,
                decoration: _dlgInput('Contact First Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),

              // Contact Last Name
              UltimateMobileTextField(
                controller: _lastNameCtrl,
                decoration: _dlgInput('Contact Last Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),

              // Company Name
              UltimateMobileTextField(
                controller: _companyNameCtrl,
                decoration: _dlgInput('Company Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),

              // Email
              UltimateMobileTextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: _dlgInput('Email *'),
                validator: (v) {
                  final input = v?.trim() ?? '';
                  if (input.isEmpty) return 'Required';
                  if (!input.contains('@') || !input.contains('.')) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10.h),

              // Contact Number
              UltimateMobileTextField(
                controller: _contactNumberCtrl,
                keyboardType: TextInputType.phone,
                decoration: _dlgInput('Contact Number *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),

              // PO Number Prefix (Optional)
              UltimateMobileTextField(
                controller: _poPrefixCtrl,
                decoration: _dlgInput('PO Number Prefix (Optional)'),
              ),
              SizedBox(height: 10.h),

              // Tax Rate (Optional)
              UltimateMobileTextField(
                controller: _taxRateCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _dlgInput('Tax Rate % (Optional)'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v.trim()) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 10.h),

              // Terms
              UltimateMobileTextField(
                controller: _termsCtrl,
                maxLines: 2,
                decoration: _dlgInput('Invoice Terms *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 14.h),

              // Address Group
              Text(
                'Address',
                style: AppTypography.body().copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              SizedBox(height: 8.h),
              UltimateMobileTextField(
                controller: _addressCtrl,
                decoration: _dlgInput('Address *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: UltimateMobileTextField(
                      controller: _cityCtrl,
                      decoration: _dlgInput('City *'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: UltimateMobileTextField(
                      controller: _stateCtrl,
                      decoration: _dlgInput('County *'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: UltimateMobileTextField(
                      controller: _zipCtrl,
                      decoration: _dlgInput('Post Code *'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: UltimateMobileTextField(
                      controller: _countryCtrl,
                      decoration: _dlgInput('Country *'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),

              SizedBox(height: 16.h),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        minimumSize: Size.fromHeight(44.h),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTypography.body().copyWith(
                          color: const Color(0xFF374151),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E45BA),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        minimumSize: Size.fromHeight(44.h),
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
                              widget.isEdit
                                  ? 'Update Profile'
                                  : 'Create Profile',
                              style: AppTypography.body().copyWith(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dlgInput(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTypography.body().copyWith(
          fontSize: 12.sp,
          color: const Color(0xFF6B7280),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF0E45BA), width: 1.1),
        ),
      );
}

// Invoice Form Dialog
class _InvoiceFormDialog extends StatefulWidget {
  final bool isEdit;
  final Map<String, dynamic>? invoice;
  final String customerId;

  const _InvoiceFormDialog(
      {required this.isEdit, this.invoice, required this.customerId});

  @override
  State<_InvoiceFormDialog> createState() => _InvoiceFormDialogState();
}

class _InvoiceFormDialogState extends State<_InvoiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _invoiceNumberCtrl;
  late final TextEditingController _customerNameCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _dueDateCtrl;
  bool _isSubmitting = false;
  String? _selectedStatus;
  final List<String> _statusOptions = ['Draft', 'Pending', 'Paid', 'Overdue'];

  @override
  void initState() {
    super.initState();
    final inv = widget.invoice;
    _invoiceNumberCtrl = TextEditingController(
      text: (inv?['invoiceNumber'] ?? '').toString(),
    );
    _customerNameCtrl = TextEditingController(
      text: (inv?['customerName'] ?? '').toString(),
    );
    _amountCtrl = TextEditingController(
      text: (inv?['amount'] ?? '').toString(),
    );
    _dueDateCtrl = TextEditingController(
      text: (inv?['dueDate'] ?? '').toString(),
    );
    _selectedStatus = (inv?['status'] ?? '').toString().isEmpty
        ? null
        : inv!['status'].toString();
  }

  @override
  void dispose() {
    _invoiceNumberCtrl.dispose();
    _customerNameCtrl.dispose();
    _amountCtrl.dispose();
    _dueDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    setState(() => _isSubmitting = true);
    final payload = {
      if (widget.isEdit) 'id': widget.invoice?['id'],
      'invoiceNumber': _invoiceNumberCtrl.text.trim(),
      'customerName': _customerNameCtrl.text.trim(),
      'amount': double.tryParse(_amountCtrl.text.trim()) ?? 0.0,
      'dueDate': _dueDateCtrl.text.trim(),
      'status': _selectedStatus ?? 'Draft',
    };
    final vm = context.read<AdminViewModel>();
    final success = widget.isEdit
        ? await vm.updateCustomerInvoice(widget.customerId, payload)
        : await vm.createCustomerInvoice(widget.customerId, payload);
    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage ?? 'Failed to save invoice'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEdit ? 'Edit Invoice' : 'Add Invoice',
                style: AppTypography.title().copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                ),
              ),
              SizedBox(height: 16.h),
              TextFormField(
                controller: _invoiceNumberCtrl,
                decoration: _dlgInput('Invoice Number *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: _customerNameCtrl,
                decoration: _dlgInput('Customer Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: _dlgInput('Amount *'),
                validator: (v) {
                  final input = v?.trim() ?? '';
                  if (input.isEmpty) return 'Required';
                  if (double.tryParse(input) == null) return 'Invalid amount';
                  return null;
                },
              ),
              SizedBox(height: 10.h),
              TextFormField(
                controller: _dueDateCtrl,
                decoration: _dlgInput('Due Date *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              SizedBox(height: 10.h),
              UltimateMobileDropdown<String>(
                value: _selectedStatus,
                decoration: _dlgInput('Status *'),
                hintText: 'Status *',
                items: _statusOptions
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedStatus = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        minimumSize: Size.fromHeight(44.h),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTypography.body().copyWith(
                          color: const Color(0xFF374151),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0E45BA),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        minimumSize: Size.fromHeight(44.h),
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
                              widget.isEdit
                                  ? 'Update Invoice'
                                  : 'Create Invoice',
                              style: AppTypography.body().copyWith(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _dlgInput(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTypography.body().copyWith(
          fontSize: 12.sp,
          color: const Color(0xFF6B7280),
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: Color(0xFF0E45BA), width: 1.1),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Helper Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: AppTypography.body().copyWith(
          fontSize: 13.sp,
          color: const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTypography.body().copyWith(
            fontSize: 13.sp,
            color: const Color(0xFF9CA3AF),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18.sp,
            color: const Color(0xFF9CA3AF),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12.h),
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;
  final String position;
  final String notes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.position,
    required this.notes,
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
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.body().copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              if (position != '--')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    position,
                    style: AppTypography.body().copyWith(
                      fontSize: 11.sp,
                      color: const Color(0xFF1D4ED8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            email,
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          if (phone != '--') ...[
            SizedBox(height: 2.h),
            Text(
              phone,
              style: AppTypography.body().copyWith(
                fontSize: 12.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
          if (notes.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              notes,
              style: AppTypography.body().copyWith(
                fontSize: 11.sp,
                color: const Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 10.h),
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
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7CDD1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
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
  }
}

class _InvoiceProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String position;
  final String phone;
  final String notes;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InvoiceProfileCard({
    required this.name,
    required this.email,
    required this.position,
    required this.phone,
    required this.notes,
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
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.body().copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              if (position != '--')
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    position,
                    style: AppTypography.body().copyWith(
                      fontSize: 11.sp,
                      color: const Color(0xFF0369A1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            email,
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          if (phone != '--') ...[
            SizedBox(height: 2.h),
            Text(
              phone,
              style: AppTypography.body().copyWith(
                fontSize: 12.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
          if (notes.isNotEmpty) ...[
            SizedBox(height: 2.h),
            Text(
              notes,
              style: AppTypography.body().copyWith(
                fontSize: 11.sp,
                color: const Color(0xFF9CA3AF),
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 10.h),
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
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7CDD1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
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
  }
}

class _InvoiceCard extends StatelessWidget {
  final String invoiceNumber;
  final String customerName;
  final String amount;
  final String dueDate;
  final String status;
  final Color statusColor;
  final Color statusBgColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InvoiceCard({
    required this.invoiceNumber,
    required this.customerName,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.statusColor,
    required this.statusBgColor,
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
              Expanded(
                child: Text(
                  invoiceNumber,
                  style: AppTypography.body().copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  status,
                  style: AppTypography.body().copyWith(
                    fontSize: 11.sp,
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            customerName,
            style: AppTypography.body().copyWith(
              fontSize: 13.sp,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _InfoBox(label: 'Amount', value: amount),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _InfoBox(label: 'Due Date', value: dueDate),
              ),
            ],
          ),
          SizedBox(height: 10.h),
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
                  onPressed: onDelete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF7CDD1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6.r),
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
  }
}
