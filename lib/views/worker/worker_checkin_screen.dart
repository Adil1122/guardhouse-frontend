import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/routes/routes.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';
import 'package:security_app/viewmodels/worker_geofence_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';
import 'package:security_app/services/location_service.dart';

class WorkerCheckinScreen extends StatefulWidget {
  const WorkerCheckinScreen({super.key});

  @override
  State<WorkerCheckinScreen> createState() => _WorkerCheckinScreenState();
}

class _WorkerCheckinScreenState extends State<WorkerCheckinScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _notesController = TextEditingController();

  File? _photo;
  bool _submitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (file != null && mounted) {
        setState(() => _photo = File(file.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (file != null && mounted) {
        setState(() => _photo = File(file.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removePhoto() => setState(() => _photo = null);

  Future<void> _submit() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take or select a photo first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _submitting = true);

    final locationService = LocationService();
    final currentPosition = locationService.currentPosition;
    
    if (currentPosition == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to get current location. Please wait or enable location services.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _submitting = false);
      return;
    }

    final ok = await context.read<WorkerViewModel>().submitCheckin(
          location: 'Site Checkpoint',
          notes: _notesController.text.trim().isEmpty
              ? 'Photo evidence uploaded'
              : _notesController.text.trim(),
          type: 'regular',
          latitude: currentPosition.latitude,
          longitude: currentPosition.longitude,
          photo: _photo,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      // Reload geofence so dashboard shows "on duty" immediately
      await context.read<WorkerGeofenceViewModel>().loadCurrentShift();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Clocked in successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } else {
      final raw = context.read<WorkerViewModel>().errorMessage ?? '';
      final msg = raw.startsWith('Exception: ') ? raw.substring(11) : raw;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.isNotEmpty ? msg : 'Failed to clock in. Please try again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final geofenceViewModel = context.watch<WorkerGeofenceViewModel>();
    final workerViewModel = context.watch<WorkerViewModel>();

    final currentShift = geofenceViewModel.currentShift;
    final assignedSite = workerViewModel.assignedSite;

    final siteName = currentShift?['site_name']?.toString() ??
        assignedSite?['name']?.toString() ??
        '';
    final hasActiveShift = currentShift != null;
    final hasUpcomingShift = assignedSite != null;

    return WorkerPanelScaffold(
      title: 'Check In',
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 32.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (siteName.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: hasActiveShift
                      ? AppColors.successBackground
                      : AppColors.infoBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: hasActiveShift
                        ? AppColors.successBorder
                        : AppColors.infoBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18.sp,
                      color: hasActiveShift
                          ? AppColors.successText
                          : AppColors.primary,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasActiveShift ? 'On Duty At' : 'Upcoming Shift At',
                            style: AppTypography.body().copyWith(
                              fontSize: 11.sp,
                              color: hasActiveShift
                                  ? AppColors.successText
                                  : AppColors.primary,
                            ),
                          ),
                          Text(
                            siteName,
                            style: AppTypography.body().copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: hasActiveShift
                                  ? AppColors.successText
                                  : AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],
            if (!hasActiveShift) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.errorBackground,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.errorBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_clock_outlined,
                            size: 18.sp, color: AppColors.error),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'You are not clocked in',
                            style: AppTypography.body().copyWith(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'You need to start your shift before submitting a check-in.',
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        color: AppColors.error,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    SizedBox(
                      width: double.infinity,
                      child: WorkerActionButton(
                        label: 'Go to Start Shift',
                        icon: Icons.play_circle_outline,
                        onTap: () => context.push(Routes.workerStartShift),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],
            const WorkerStatusBanner(
              title: 'Photo Evidence Required',
              subtitle:
                  'Take a photo at your checkpoint as proof of presence. Photo will be logged with a timestamp.',
              icon: Icons.info_outline,
              variant: WorkerStatusVariant.info,
            ),
            SizedBox(height: 20.h),

            // ── Photo section ──────────────────────────────────────────────
            Text(
              'Photo Evidence',
              style: AppTypography.body().copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10.h),

            if (_photo != null) ...[
              _PhotoPreview(photo: _photo!, onRemove: _removePhoto),
            ] else ...[
              WorkerPanelCard(
                child: Column(
                  children: [
                    Container(
                      width: 56.sp,
                      height: 56.sp,
                      decoration: BoxDecoration(
                        color: AppColors.neutralIconBackground,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.camera_alt_outlined,
                        size: 28.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'No photo selected',
                      style: AppTypography.body().copyWith(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Use the camera or choose from gallery',
                      style: AppTypography.body().copyWith(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Row(
                      children: [
                        Expanded(
                          child: WorkerActionButton(
                            label: 'Take Photo',
                            icon: Icons.camera_alt_outlined,
                            onTap: _takePhoto,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: WorkerActionButton(
                            label: 'Gallery',
                            icon: Icons.photo_library_outlined,
                            variant: WorkerButtonVariant.secondary,
                            onTap: _pickFromGallery,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 20.h),

            // ── Notes ──────────────────────────────────────────────────────
            Text(
              'Notes (optional)',
              style: AppTypography.body().copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10.h),
            WorkerPanelCard(
              child: TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add any notes about this check-in…',
                  hintStyle: AppTypography.body().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
                  ),
                  border: InputBorder.none,
                ),
                style: AppTypography.body().copyWith(fontSize: 13.sp),
              ),
            ),

            SizedBox(height: 28.h),

            // ── Submit ─────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: WorkerActionButton(
                label: _submitting
                    ? 'Submitting…'
                    : hasActiveShift
                        ? 'Submit Check-in'
                        : 'Clock In & Check-in',
                icon: Icons.check_circle_outline,
                onTap: _submitting ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo, required this.onRemove});

  final File photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return WorkerPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: Image.file(
              photo,
              width: double.infinity,
              height: 200.h,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.check_circle,
                  size: 16.sp, color: AppColors.successText),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Photo captured — ready to submit',
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: AppColors.successText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRemove,
                child: Text(
                  'Retake',
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: AppColors.primary,
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
