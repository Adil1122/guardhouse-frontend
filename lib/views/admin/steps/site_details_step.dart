import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_constants.dart';
import '../../../constants/typography.dart';
import '../../../models/site_models.dart';
import '../../../providers/site_creation_provider.dart';
import '../../../viewmodels/admin_viewmodel.dart';
import '../../../widgets/ultimate_mobile_widgets.dart';
import '../../../widgets/map_picker_widget.dart';
import 'package:latlong2/latlong.dart';

class SiteDetailsStep extends StatefulWidget {
  const SiteDetailsStep({super.key});

  @override
  State<SiteDetailsStep> createState() => _SiteDetailsStepState();
}

class _SiteDetailsStepState extends State<SiteDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;
  late final TextEditingController _countryController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;

  String _selectedType = 'static';
  String? _selectedCustomerId;
  String? _selectedServiceGroupId;
  String? _selectedPayGroupId;

  @override
  void initState() {
    super.initState();
    final provider = context.read<SiteCreationProvider>();
    final details = provider.details;

    _nameController = TextEditingController(text: details.name);
    _addressController = TextEditingController(text: details.address.name);
    _cityController = TextEditingController(text: details.address.city);
    _stateController = TextEditingController(text: details.address.state);
    _zipController = TextEditingController(text: details.address.zip);
    _countryController = TextEditingController(text: details.address.country);
    _latitudeController = TextEditingController(
      text: details.geofence.lat.toString(),
    );
    _longitudeController = TextEditingController(
      text: details.geofence.lon.toString(),
    );

    _selectedType = details.type;
    _selectedCustomerId =
        (details.customerId?.isNotEmpty ?? false) ? details.customerId : null;
    _selectedServiceGroupId = details.defaultServiceGroupId;
    _selectedPayGroupId = details.defaultPayGroupId;

    // Load required data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminViewModel = context.read<AdminViewModel>();
      adminViewModel.loadCustomers();
      adminViewModel.loadServiceGroups();
      adminViewModel.loadPayGroups();
    });

    // Add listeners to update the provider when data changes
    _nameController.addListener(_updateDetails);
    _addressController.addListener(_updateDetails);
    _cityController.addListener(_updateDetails);
    _stateController.addListener(_updateDetails);
    _zipController.addListener(_updateDetails);
    _countryController.addListener(_updateDetails);
    _latitudeController.addListener(_updateDetails);
    _longitudeController.addListener(_updateDetails);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _updateDetails() {
    final provider = context.read<SiteCreationProvider>();

    final details = SiteDetails(
      id: provider.details.id,
      type: _selectedType,
      name: _nameController.text,
      customerId: _selectedCustomerId,
      address: SiteAddress(
        name: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        zip: _zipController.text,
        country: _countryController.text,
      ),
      geofence: Geofence(
        placeId: '',
        lat: double.tryParse(_latitudeController.text) ?? 0.0,
        lon: double.tryParse(_longitudeController.text) ?? 0.0,
        checkInDistance: 100,
      ),
      defaultServiceGroupId: _selectedServiceGroupId,
      defaultPayGroupId: _selectedPayGroupId,
    );

    provider.updateDetails(details);
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

  Widget _buildDropdownField<T>({
    required String labelText,
    required T? value,
    required List<T> items,
    required String Function(T) getLabel,
    required String Function(T) getValue,
    required ValueChanged<T?> onChanged,
    String? hintText,
    bool isExpanded = true,
  }) {
    return UltimateMobileDropdown<T>(
      value: value,
      decoration: _fieldDecoration(labelText: labelText, hintText: hintText),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            getLabel(item),
            style: AppTypography.body().copyWith(fontSize: 14.sp),
          ),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Text(
        title,
        style: AppTypography.title().copyWith(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
        ),
      ),
    );
  }

  Future<void> _showMapPicker() async {
    var initialLat = double.tryParse(_latitudeController.text.trim()) ?? 51.509364;
    var initialLon = double.tryParse(_longitudeController.text.trim()) ?? -0.128928;
    if (initialLat == 0.0 && initialLon == 0.0) {
      initialLat = 51.509364;
      initialLon = -0.128928;
    }
    final result = await MapPickerWidget.show(
      context,
      initialLocation: LatLng(initialLat, initialLon),
    );
    if (result != null) {
      setState(() {
        _latitudeController.text = result.latitude.toStringAsFixed(6);
        _longitudeController.text = result.longitude.toStringAsFixed(6);
        _updateDetails();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SiteCreationProvider, AdminViewModel>(
      builder: (context, provider, adminViewModel, child) {
        final customers = adminViewModel.customers;
        final serviceGroups = adminViewModel.serviceGroups;
        final payGroups = adminViewModel.payGroups;

        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Site Type
                _buildSectionTitle('Type'),
                _buildDropdownField<String>(
                  labelText: 'Type',
                  value: _selectedType,
                  items: ['static', 'patrol'],
                  getLabel: (type) => type.capitalize(),
                  getValue: (type) => type,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                      _updateDetails();
                    }
                  },
                  hintText: 'Select site type',
                  isExpanded: true,
                ),
                SizedBox(height: 24.h),

                // Site Name
                _buildSectionTitle('Site Name'),
                UltimateMobileTextField(
                  controller: _nameController,
                  decoration: _fieldDecoration(
                    labelText: 'Name',
                    hintText: 'Enter site name',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a site name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24.h),

                // Customer
                _buildSectionTitle('Customer'),
                UltimateMobileDropdown<String>(
                  value: (customers.any((c) => (c['id'] ?? c['user_id'] ?? c['profile_id'])?.toString() == _selectedCustomerId)) ? _selectedCustomerId : null,
                  decoration: _fieldDecoration(
                    labelText: 'Choose Customer',
                    hintText: 'Select customer',
                  ),
                  items: customers.map((customer) {
                    final firstName =
                        (customer['firstName'] ?? customer['first_name'] ?? '').toString().trim();
                    final lastName =
                        (customer['lastName'] ?? customer['last_name'] ?? '').toString().trim();
                    final name = '$firstName $lastName'.trim();
                    return DropdownMenuItem<String>(
                      value: (customer['id'] ?? customer['user_id'] ?? customer['profile_id'])?.toString(),
                      child: Text(
                        name.isEmpty ? 'Unknown Customer' : name,
                        style: AppTypography.body().copyWith(fontSize: 14.sp),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCustomerId = value);
                    _updateDetails();
                  },
                ),
                SizedBox(height: 24.h),

                // Address Section
                _buildSectionTitle('Address'),
                UltimateMobileTextField(
                  controller: _addressController,
                  decoration: _fieldDecoration(
                    labelText: 'Address',
                    hintText: 'Enter street address',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: UltimateMobileTextField(
                        controller: _cityController,
                        decoration: _fieldDecoration(
                          labelText: 'City',
                          hintText: 'Enter city',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a city';
                          }
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: UltimateMobileTextField(
                        controller: _stateController,
                        decoration: _fieldDecoration(
                          labelText: 'County',
                          hintText: 'Enter county',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: UltimateMobileTextField(
                        controller: _zipController,
                        decoration: _fieldDecoration(
                          labelText: 'Postal Code',
                          hintText: 'Enter postal code',
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: UltimateMobileTextField(
                        controller: _countryController,
                        decoration: _fieldDecoration(
                          labelText: 'Country',
                          hintText: 'Enter country',
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // Geofence Location
                _buildSectionTitle('Geofence Location'),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                        ),
                        title: Text(
                          'Select Location on Map',
                          style: AppTypography.body().copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          'Tap to open map and select location',
                          style: AppTypography.body().copyWith(
                            fontSize: 12.sp,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: _showMapPicker,
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.w),
                        child: Row(
                          children: [
                            Expanded(
                              child: UltimateMobileTextField(
                                controller: _latitudeController,
                                decoration: _fieldDecoration(
                                  labelText: 'Latitude',
                                  hintText: 'Enter latitude',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: UltimateMobileTextField(
                                controller: _longitudeController,
                                decoration: _fieldDecoration(
                                  labelText: 'Longitude',
                                  hintText: 'Enter longitude',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Default Service Group (Optional)
                _buildSectionTitle('Default Service Group (Optional)'),
                UltimateMobileDropdown<String>(
                  value: (serviceGroups.any((sg) => sg['id']?.toString() == _selectedServiceGroupId)) ? _selectedServiceGroupId : null,
                  decoration: _fieldDecoration(
                    labelText: 'Choose Default Service Group',
                    hintText: 'Select service group (optional)',
                  ),
                  items: serviceGroups.map((sg) {
                    return DropdownMenuItem<String>(
                      value: sg['id']?.toString(),
                      child: Text(
                        (sg['name'] ?? 'Unknown Service Group').toString(),
                        style: AppTypography.body().copyWith(fontSize: 14.sp),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedServiceGroupId = value);
                    _updateDetails();
                  },
                ),
                SizedBox(height: 24.h),

                // Default Pay Group (Optional)
                _buildSectionTitle('Default Pay Group (Optional)'),
                UltimateMobileDropdown<String>(
                  value: (payGroups.any((pg) => pg['id']?.toString() == _selectedPayGroupId)) ? _selectedPayGroupId : null,
                  decoration: _fieldDecoration(
                    labelText: 'Choose Default Pay Group',
                    hintText: 'Select pay group (optional)',
                  ),
                  items: payGroups.map((pg) {
                    return DropdownMenuItem<String>(
                      value: pg['id']?.toString(),
                      child: Text(
                        (pg['name'] ?? 'Unknown Pay Group').toString(),
                        style: AppTypography.body().copyWith(fontSize: 14.sp),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedPayGroupId = value);
                    _updateDetails();
                  },
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        );
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
