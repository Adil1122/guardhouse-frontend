import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/site_models.dart';
import 'custom_text_field.dart';

class SiteFormValidator {
  static String? validateSiteName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Site name is required';
    }
    if (value.length > 100) {
      return 'Site name must not exceed 100 characters';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    return null;
  }

  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    return null;
  }

  static String? validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'State is required';
    }
    return null;
  }

  static String? validateZip(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Zip code is required';
    }
    return null;
  }

  static String? validateCountry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Country is required';
    }
    return null;
  }

  static String? validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Latitude is required';
    }
    final lat = double.tryParse(value);
    if (lat == null || lat < -90 || lat > 90) {
      return 'Invalid latitude (must be between -90 and 90)';
    }
    return null;
  }

  static String? validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Longitude is required';
    }
    final lon = double.tryParse(value);
    if (lon == null || lon < -180 || lon > 180) {
      return 'Invalid longitude (must be between -180 and 180)';
    }
    return null;
  }

  static String? validateDistance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Check-in distance is required';
    }
    final distance = int.tryParse(value);
    if (distance == null || distance <= 0) {
      return 'Check-in distance must be a positive number';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex =
          RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Enter a valid email address';
      }
    }
    return null;
  }

  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (value.length < 7) {
      return 'Phone number must be at least 7 digits';
    }
    return null;
  }

  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'First name is required';
    }
    if (value.length > 50) {
      return 'First name must not exceed 50 characters';
    }
    return null;
  }

  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Last name is required';
    }
    if (value.length > 50) {
      return 'Last name must not exceed 50 characters';
    }
    return null;
  }

  static String? validatePosition(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Position is required';
    }
    if (value.length > 50) {
      return 'Position must not exceed 50 characters';
    }
    return null;
  }

  static String? validateCheckpointName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Checkpoint name is required';
    }
    if (value.length > 50) {
      return 'Checkpoint name must not exceed 50 characters';
    }
    return null;
  }

  static String? validateDocumentName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Document name is required';
    }
    if (value.length > 50) {
      return 'Document name must not exceed 50 characters';
    }
    return null;
  }
}

class SiteDetailsForm extends StatefulWidget {
  final SiteDetails? initialDetails;
  final Function(SiteDetails) onSave;
  final List<Map<String, dynamic>> serviceGroups;
  final List<Map<String, dynamic>> payGroups;
  final List<Map<String, dynamic>> customers;

  const SiteDetailsForm({
    Key? key,
    this.initialDetails,
    required this.onSave,
    required this.serviceGroups,
    required this.payGroups,
    required this.customers,
  }) : super(key: key);

  @override
  State<SiteDetailsForm> createState() => _SiteDetailsFormState();
}

class _SiteDetailsFormState extends State<SiteDetailsForm> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _countryController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _distanceController;
  late TextEditingController _placeIdController;
  late TextEditingController _instructionsController;

  String? _selectedType;
  String? _selectedCustomer;
  String? _selectedServiceGroup;
  String? _selectedPayGroup;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final details = widget.initialDetails;

    _nameController = TextEditingController(text: details?.name ?? '');
    _addressController =
        TextEditingController(text: details?.address.name ?? '');
    _cityController = TextEditingController(text: details?.address.city ?? '');
    _stateController =
        TextEditingController(text: details?.address.state ?? '');
    _zipController = TextEditingController(text: details?.address.zip ?? '');
    _countryController =
        TextEditingController(text: details?.address.country ?? '');
    _latController =
        TextEditingController(text: details?.geofence.lat?.toString() ?? '');
    _lonController =
        TextEditingController(text: details?.geofence.lon?.toString() ?? '');
    _distanceController = TextEditingController(
        text: details?.geofence.checkInDistance?.toString() ?? '50');
    _placeIdController =
        TextEditingController(text: details?.geofence.placeId ?? '');
    _instructionsController =
        TextEditingController(text: details?.instructions ?? '');

    _selectedType = details?.type ?? 'static';
    _selectedCustomer = details?.customerId;
    _selectedServiceGroup = details?.defaultServiceGroupId;
    _selectedPayGroup = details?.defaultPayGroupId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _countryController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _distanceController.dispose();
    _placeIdController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _validateAndSave() {
    if (_formKey.currentState!.validate()) {
      final details = SiteDetails(
        type: _selectedType ?? 'static',
        name: _nameController.text.trim(),
        customerId: _selectedCustomer,
        address: SiteAddress(
          name: _addressController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          zip: _zipController.text.trim(),
          country: _countryController.text.trim(),
        ),
        geofence: Geofence(
          placeId: _placeIdController.text.trim().isEmpty
              ? null
              : _placeIdController.text.trim(),
          lat: double.tryParse(_latController.text),
          lon: double.tryParse(_lonController.text),
          checkInDistance: int.tryParse(_distanceController.text) ?? 50,
        ),
        defaultServiceGroupId: _selectedServiceGroup,
        defaultPayGroupId: _selectedPayGroup,
        instructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
      );
      widget.onSave(details);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type Selection
            Text('Site Type*', style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 8.h),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              ),
              items: const [
                DropdownMenuItem(value: 'static', child: Text('Static Site')),
                DropdownMenuItem(
                    value: 'mobile-patrol', child: Text('Mobile Patrol')),
              ],
              onChanged: (value) => setState(() => _selectedType = value),
              validator: (value) => value == null ? 'Select a site type' : null,
            ),
            SizedBox(height: 16.h),

            // Customer Selection
            Text('Customer', style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 8.h),
            DropdownButtonFormField<String>(
              value: _selectedCustomer,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                hintText: 'Select customer (optional)',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...widget.customers.map((customer) => DropdownMenuItem(
                      value: customer['id']?.toString(),
                      child: Text(customer['name'] ?? 'Unknown'),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedCustomer = value),
            ),
            SizedBox(height: 16.h),

            // Site Name
            Text('Site Name*', style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: 'Enter site name'),
              maxLength: 100,
              validator: SiteFormValidator.validateSiteName,
            ),
            SizedBox(height: 16.h),

            // Address Section
            Text('Address Information*',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 12.h),

            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(hintText: 'Street Address'),
              validator: SiteFormValidator.validateAddress,
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('City*',
                          style: Theme.of(context).textTheme.labelMedium),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(hintText: 'City'),
                        validator: SiteFormValidator.validateCity,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('State*',
                          style: Theme.of(context).textTheme.labelMedium),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _stateController,
                        decoration: const InputDecoration(hintText: 'State'),
                        validator: SiteFormValidator.validateState,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Zip Code*',
                          style: Theme.of(context).textTheme.labelMedium),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _zipController,
                        decoration: const InputDecoration(hintText: 'Zip Code'),
                        validator: SiteFormValidator.validateZip,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Country*',
                          style: Theme.of(context).textTheme.labelMedium),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(hintText: 'Country'),
                        validator: SiteFormValidator.validateCountry,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Geofence Section
            Text('Geofence Information*',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 12.h),

            TextFormField(
              controller: _placeIdController,
              decoration: const InputDecoration(hintText: 'Place ID (optional)'),
            ),
            SizedBox(height: 12.h),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Latitude*',
                          style: Theme.of(context).textTheme.labelMedium),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _latController,
                        decoration: const InputDecoration(hintText: 'Latitude'),
                        keyboardType: TextInputType.number,
                        validator: SiteFormValidator.validateLatitude,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Longitude*',
                          style: Theme.of(context).textTheme.labelMedium),
                      SizedBox(height: 4.h),
                      TextFormField(
                        controller: _lonController,
                        decoration: const InputDecoration(hintText: 'Longitude'),
                        keyboardType: TextInputType.number,
                        validator: SiteFormValidator.validateLongitude,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            Text('Check-In Distance (meters)*',
                style: Theme.of(context).textTheme.labelMedium),
            SizedBox(height: 4.h),
            TextFormField(
              controller: _distanceController,
              decoration: const InputDecoration(hintText: 'Distance in meters (e.g., 50)'),
              keyboardType: TextInputType.number,
              validator: SiteFormValidator.validateDistance,
            ),
            SizedBox(height: 16.h),

            // Service and Pay Groups
            Text('Default Groups (Optional)',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 12.h),

            Text('Service Group',
                style: Theme.of(context).textTheme.labelMedium),
            SizedBox(height: 4.h),
            DropdownButtonFormField<String>(
              value: _selectedServiceGroup,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                hintText: 'Select service group',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...widget.serviceGroups.map((group) => DropdownMenuItem(
                      value: group['id']?.toString(),
                      child: Text(group['name'] ?? 'Unknown'),
                    )),
              ],
              onChanged: (value) =>
                  setState(() => _selectedServiceGroup = value),
            ),
            SizedBox(height: 12.h),

            Text('Pay Group', style: Theme.of(context).textTheme.labelMedium),
            SizedBox(height: 4.h),
            DropdownButtonFormField<String>(
              value: _selectedPayGroup,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                hintText: 'Select pay group',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...widget.payGroups.map((group) => DropdownMenuItem(
                      value: group['id']?.toString(),
                      child: Text(group['name'] ?? 'Unknown'),
                    )),
              ],
              onChanged: (value) => setState(() => _selectedPayGroup = value),
            ),
            SizedBox(height: 16.h),

            // Instructions
            Text('Instructions', style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: 8.h),
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(hintText: 'Site instructions (optional)'),
              maxLines: 4,
              maxLength: 500,
            ),
            SizedBox(height: 24.h),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndSave,
                child: const Text('Save Site Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
