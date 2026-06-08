import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../models/company_settings_model.dart';
import '../../viewmodels/company_settings_viewmodel.dart';
import '../../viewmodels/pay_group_viewmodel.dart';
import '../../viewmodels/service_group_viewmodel.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  bool _initializedFromVm = false;

  bool _enableDigitalOccurrenceLogs = true;
  bool _enableTwoFactorAuthentication = false;
  String _liveOperationsListSorting = 'time-asc';
  String? _defaultPayGroupId;
  String? _defaultServiceGroupId;

  final TextEditingController _geofenceDistanceController =
      TextEditingController();
  final TextEditingController _shiftAlertResponseController =
      TextEditingController();
  final List<TextEditingController> _questionControllers = List.generate(
    5,
    (_) => TextEditingController(),
  );

  static const List<String> _sortingOptions = [
    'time-asc',
    'time-desc',
    'duration-asc',
    'duration-desc',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanySettingsViewModel>().loadSettings();
      context.read<PayGroupViewModel>().loadPayGroups();
      context.read<ServiceGroupViewModel>().loadGroups();
    });
  }

  @override
  void dispose() {
    _geofenceDistanceController.dispose();
    _shiftAlertResponseController.dispose();
    for (final controller in _questionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeFromSettings(CompanySettings settings) {
    _enableDigitalOccurrenceLogs = settings.enableDigitalOccurrenceLogs;
    _enableTwoFactorAuthentication = settings.enableTwoFactorAuthentication;
    _liveOperationsListSorting = settings.liveOperationsListSorting;
    _defaultPayGroupId = settings.defaultPayGroupId;
    _defaultServiceGroupId = settings.defaultServiceGroupId;
    _geofenceDistanceController.text = settings.geofenceCheckInDistance
        .toStringAsFixed(0);
    _shiftAlertResponseController.text = settings.shiftAlertResponseTime
        .toString();

    for (int index = 0; index < 5; index++) {
      _questionControllers[index].text = settings.customClockInQuestionnaire
          .elementAt(index);
    }

    _initializedFromVm = true;
  }

  Future<void> _saveSettings(
    CompanySettingsViewModel companySettingsViewModel,
  ) async {
    final geofenceDistance = double.tryParse(_geofenceDistanceController.text);
    final shiftAlertResponse = int.tryParse(_shiftAlertResponseController.text);

    if (geofenceDistance == null || geofenceDistance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid geofence distance')),
      );
      return;
    }

    if (shiftAlertResponse == null || shiftAlertResponse <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid shift alert response time'),
        ),
      );
      return;
    }

    final updatedSettings = companySettingsViewModel.settings.copyWith(
      enableDigitalOccurrenceLogs: _enableDigitalOccurrenceLogs,
      enableTwoFactorAuthentication: _enableTwoFactorAuthentication,
      liveOperationsListSorting: _liveOperationsListSorting,
      customClockInQuestionnaire: _questionControllers
          .map((controller) => controller.text.trim())
          .toList(),
      defaultPayGroupId: _defaultPayGroupId,
      defaultServiceGroupId: _defaultServiceGroupId,
      geofenceCheckInDistance: geofenceDistance,
      shiftAlertResponseTime: shiftAlertResponse,
    );

    await companySettingsViewModel.updateSettings(updatedSettings);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company settings saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Company Settings',
          style: AppTypography.title().copyWith(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111827),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios,
            color: const Color(0xFF111827),
            size: 20.sp,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body:
          Consumer3<
            CompanySettingsViewModel,
            PayGroupViewModel,
            ServiceGroupViewModel
          >(
            builder:
                (
                  context,
                  companySettingsViewModel,
                  payGroupViewModel,
                  serviceGroupViewModel,
                  _,
                ) {
                  if (companySettingsViewModel.isLoading &&
                      !_initializedFromVm) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (companySettingsViewModel.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48.sp,
                            color: Colors.red,
                          ),
                          SizedBox(height: 12.h),
                          Text('Error: ${companySettingsViewModel.error}'),
                          SizedBox(height: 12.h),
                          ElevatedButton(
                            onPressed: companySettingsViewModel.loadSettings,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!_initializedFromVm) {
                    _initializeFromSettings(companySettingsViewModel.settings);
                  }

                  final payGroups = payGroupViewModel.payGroups;
                  final serviceGroups = serviceGroupViewModel.groups;

                  if (_defaultPayGroupId != null &&
                      payGroups.every(
                        (group) => group.id != _defaultPayGroupId,
                      )) {
                    _defaultPayGroupId = null;
                  }

                  if (_defaultServiceGroupId != null &&
                      serviceGroups.every(
                        (group) => group.id != _defaultServiceGroupId,
                      )) {
                    _defaultServiceGroupId = null;
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      children: [
                        _buildToggleCard(
                          title: 'Enable Digital Occurrence Logs',
                          value: _enableDigitalOccurrenceLogs,
                          onChanged: (value) {
                            setState(() {
                              _enableDigitalOccurrenceLogs = value;
                            });
                          },
                        ),
                        SizedBox(height: 12.h),
                        _buildToggleCard(
                          title: 'Enable Two Factor Authentication',
                          value: _enableTwoFactorAuthentication,
                          onChanged: (value) {
                            setState(() {
                              _enableTwoFactorAuthentication = value;
                            });
                          },
                        ),
                        SizedBox(height: 12.h),
                        _buildDropdownCard(
                          title: 'Live Operations List Sorting',
                          child: DropdownButtonFormField<String>(
                            value: _liveOperationsListSorting,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            items: _sortingOptions
                                .map(
                                  (option) => DropdownMenuItem(
                                    value: option,
                                    child: Text(option),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() {
                                _liveOperationsListSorting = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildQuestionnaireCard(),
                        SizedBox(height: 12.h),
                        _buildDropdownCard(
                          title: 'Default Pay Group ID',
                          child: DropdownButtonFormField<String>(
                            value: _defaultPayGroupId,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select pay group',
                            ),
                            items: payGroups
                                .map(
                                  (group) => DropdownMenuItem(
                                    value: group.id,
                                    child: Text(group.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _defaultPayGroupId = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildDropdownCard(
                          title: 'Default Service Group ID',
                          child: DropdownButtonFormField<String>(
                            value: _defaultServiceGroupId,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select service group',
                            ),
                            items: serviceGroups
                                .map(
                                  (group) => DropdownMenuItem(
                                    value: group.id,
                                    child: Text(group.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _defaultServiceGroupId = value;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildInputCard(
                          title: 'Geofence Check-in Distance in Meters',
                          child: TextField(
                            controller: _geofenceDistanceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _buildInputCard(
                          title: 'Shift Alert Response Time in Minutes',
                          note:
                              'Maximum time in minutes until then a staff member can respond to an alert',
                          child: TextField(
                            controller: _shiftAlertResponseController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: companySettingsViewModel.isLoading
                                ? null
                                : () => _saveSettings(companySettingsViewModel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                            ),
                            child: Text(
                              'Save Settings',
                              style: AppTypography.body().copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
          ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.body().copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }

  Widget _buildDropdownCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body().copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }

  Widget _buildInputCard({
    required String title,
    required Widget child,
    String? note,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body().copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (note != null) ...[
            SizedBox(height: 6.h),
            Text(
              note,
              style: AppTypography.body().copyWith(
                fontSize: 12.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }

  Widget _buildQuestionnaireCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Custom Clock-in Questionnaire',
            style: AppTypography.body().copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10.h),
          ...List.generate(5, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: index == 4 ? 0 : 10.h),
              child: TextField(
                controller: _questionControllers[index],
                decoration: InputDecoration(
                  labelText: 'Question ${index + 1} ',
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
