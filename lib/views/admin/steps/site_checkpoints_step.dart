import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../constants/app_constants.dart';
import '../../../constants/typography.dart';
import '../../../models/site_models.dart';
import '../../../providers/site_creation_provider.dart';
import '../../../widgets/map_picker_widget.dart';
import 'package:latlong2/latlong.dart';
import '../../../widgets/ultimate_mobile_widgets.dart';

class SiteCheckpointsStep extends StatefulWidget {
  const SiteCheckpointsStep({super.key});

  @override
  State<SiteCheckpointsStep> createState() => _SiteCheckpointsStepState();
}

class _SiteCheckpointsStepState extends State<SiteCheckpointsStep> {
  void _showAddEditCheckpointDialog({SiteCheckpoint? checkpoint, int? index}) {
    final provider = context.read<SiteCreationProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _CheckpointFormSheet(
        checkpoint: checkpoint,
        onSave: (newCheckpoint) {
          if (index != null) {
            provider.updateCheckpoint(index, newCheckpoint);
          } else {
            provider.addCheckpoint(newCheckpoint);
          }
        },
      ),
    );
  }

  void _confirmDeleteCheckpoint(int index) {
    final provider = context.read<SiteCreationProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Checkpoint'),
        content: const Text('Are you sure you want to delete this checkpoint?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              provider.removeCheckpoint(index);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckpointCard(SiteCheckpoint checkpoint, int index) {
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
            checkpoint.name,
            style: AppTypography.body().copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF111827),
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            checkpoint.name,
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Lat: ${checkpoint.geofence.lat?.toStringAsFixed(5) ?? "0.0"}  '
            'Lng: ${checkpoint.geofence.lon?.toStringAsFixed(5) ?? "0.0"}  '
            'Radius: ${checkpoint.geofence.checkInDistance}m',
            style: AppTypography.body().copyWith(
              fontSize: 11.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          if (checkpoint.qrCodeToken != null) ...[
            SizedBox(height: 4.h),
            Text(
              'QR Code attached',
              style: AppTypography.body().copyWith(
                fontSize: 11.sp,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showAddEditCheckpointDialog(
                    checkpoint: checkpoint,
                    index: index,
                  ),
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
                  onPressed: () => _confirmDeleteCheckpoint(index),
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
        final checkpoints = provider.checkpoints;

        return SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => _showAddEditCheckpointDialog(),
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
              if (checkpoints.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 40.h),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 48.sp,
                        color: const Color(0xFFD1D5DB),
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'No checkpoints added yet',
                        style: AppTypography.body().copyWith(
                          fontSize: 14.sp,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...checkpoints.asMap().entries.map(
                      (e) => _buildCheckpointCard(e.value, e.key),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _CheckpointFormSheet extends StatefulWidget {
  final SiteCheckpoint? checkpoint;
  final ValueChanged<SiteCheckpoint> onSave;

  const _CheckpointFormSheet({this.checkpoint, required this.onSave});

  @override
  State<_CheckpointFormSheet> createState() => _CheckpointFormSheetState();
}

class _CheckpointFormSheetState extends State<_CheckpointFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _radiusController;

  @override
  void initState() {
    super.initState();
    final checkpoint = widget.checkpoint;

    _nameController = TextEditingController(text: checkpoint?.name ?? '');
    _latitudeController = TextEditingController(
      text: checkpoint?.geofence.lat.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: checkpoint?.geofence.lon.toString() ?? '',
    );
    _radiusController = TextEditingController(
      text: checkpoint?.geofence.checkInDistance.toString() ?? '100',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      final checkpoint = SiteCheckpoint(
        name: _nameController.text.trim(),
        geofence: Geofence(
          placeId: '',
          lat: double.tryParse(_latitudeController.text.trim()) ?? 0.0,
          lon: double.tryParse(_longitudeController.text.trim()) ?? 0.0,
          checkInDistance: int.tryParse(_radiusController.text.trim()) ?? 100,
        ),
      );

      widget.onSave(checkpoint);
      Navigator.pop(context);
    }
  }

  Future<void> _showMapPicker() async {
    final initialLat = double.tryParse(_latitudeController.text.trim()) ?? 51.509364;
    final initialLon = double.tryParse(_longitudeController.text.trim()) ?? -0.128928;
    final result = await MapPickerWidget.show(
      context,
      initialLocation: LatLng(initialLat, initialLon),
    );
    if (result != null) {
      setState(() {
        _latitudeController.text = result.latitude.toStringAsFixed(6);
        _longitudeController.text = result.longitude.toStringAsFixed(6);
      });
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
                  widget.checkpoint != null
                      ? 'Edit Checkpoint'
                      : 'Add Checkpoint',
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
                      decoration: _fieldDecoration(labelText: 'Name *'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a checkpoint name';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Geofence Location',
                      style: AppTypography.body().copyWith(
                        fontSize: 13.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    GestureDetector(
                      onTap: _showMapPicker,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F1F1),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.map_outlined,
                              color: AppColors.primary,
                              size: 18.sp,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Select Location on Map',
                              style: AppTypography.body().copyWith(
                                fontSize: 13.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: UltimateMobileTextField(
                            controller: _latitudeController,
                            readOnly: true,
                            decoration: _fieldDecoration(labelText: 'Latitude'),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: UltimateMobileTextField(
                            controller: _longitudeController,
                            readOnly: true,
                            decoration: _fieldDecoration(
                              labelText: 'Longitude',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    UltimateMobileTextField(
                      controller: _radiusController,
                      decoration: _fieldDecoration(
                        labelText: 'Radius (meters) *',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a radius';
                        }
                        final radius = double.tryParse(value.trim());
                        if (radius == null || radius <= 0) {
                          return 'Please enter a valid radius';
                        }
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
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
                          widget.checkpoint != null
                              ? 'Update Checkpoint'
                              : 'Add Checkpoint',
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
