import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/config/api_config.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/routes/routes.dart';
import 'package:security_app/viewmodels/worker_geofence_viewmodel.dart';
import 'package:security_app/viewmodels/worker_panel_viewmodel.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';
import 'package:security_app/services/location_service.dart';
import 'package:security_app/widgets/ultimate_mobile_widgets.dart';

// Google Maps imports (commented for now)
// import 'package:google_maps_flutter/google_maps_flutter.dart';

class EnhancedCheckinScreen extends StatefulWidget {
  const EnhancedCheckinScreen({super.key});

  @override
  State<EnhancedCheckinScreen> createState() => _EnhancedCheckinScreenState();
}

class _EnhancedCheckinScreenState extends State<EnhancedCheckinScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  String _selectedType = 'regular';
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeScreen();
    });
  }

  void _initializeScreen() async {
    final geofenceViewModel = context.read<WorkerGeofenceViewModel>();
    await geofenceViewModel.loadCurrentShift();
    await geofenceViewModel.loadCheckinHistory();
    
    // Set current location as default
    _setCurrentLocation();
  }

  void _setCurrentLocation() {
    final locationService = LocationService();
    final currentPosition = locationService.currentPosition;
    
    if (currentPosition != null) {
      final geofenceStatus = locationService.getGeofenceStatus(
        geofence: context.read<WorkerGeofenceViewModel>().currentShift?['geofence'] ?? {},
      );
      
      _locationController.text = geofenceStatus.insideGeofence 
          ? 'Inside Geofence (${geofenceStatus.distanceFromSite?.toStringAsFixed(1)}m from site)'
          : 'Outside Geofence (${geofenceStatus.distanceFromSite?.toStringAsFixed(1)}m from site)';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Check In',
          style: AppTypography.title().copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        elevation: 0,
      ),
      body: Consumer3<WorkerGeofenceViewModel, WorkerPanelViewModel, WorkerViewModel>(
        builder: (context, geofenceViewModel, panelViewModel, workerViewModel, child) {
          if (geofenceViewModel.isLoading && geofenceViewModel.currentShift == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (geofenceViewModel.currentShift == null && workerViewModel.tasks.isEmpty) {
            return _buildNoActiveShift();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await geofenceViewModel.loadCurrentShift();
              await geofenceViewModel.loadCheckinHistory();
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGeofenceStatus(panelViewModel),
                  SizedBox(height: 16.h),
                  _buildLocationMap(geofenceViewModel),
                  SizedBox(height: 16.h),
                  _buildCheckinForm(geofenceViewModel),
                  SizedBox(height: 16.h),
                  _buildRecentCheckins(geofenceViewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoActiveShift() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_off_outlined,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Active Shift',
              style: AppTypography.title().copyWith(
                fontSize: 24.sp,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please start your shift to check in',
              style: AppTypography.body().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => context.go(Routes.worker),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofenceStatus(WorkerPanelViewModel panelViewModel) {
    final geofenceStatus = panelViewModel.getCurrentGeofenceStatus();
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: geofenceStatus?.insideGeofence == true 
            ? AppColors.successBackground 
            : AppColors.errorBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: geofenceStatus?.insideGeofence == true 
              ? AppColors.successBorder 
              : AppColors.errorBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            geofenceStatus?.insideGeofence == true 
                ? Icons.check_circle 
                : Icons.location_off,
            color: geofenceStatus?.insideGeofence == true 
                ? AppColors.success 
                : AppColors.error,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  geofenceStatus?.insideGeofence == true 
                      ? 'Inside Geofence' 
                      : 'Outside Geofence',
                  style: AppTypography.body().copyWith(
                    fontWeight: FontWeight.w600,
                    color: geofenceStatus?.insideGeofence == true 
                        ? AppColors.success 
                        : AppColors.error,
                  ),
                ),
                Text(
                  geofenceStatus?.insideGeofence == true 
                      ? 'You can check in from here' 
                      : 'Move closer to the site to check in',
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap(WorkerGeofenceViewModel geofenceViewModel) {
    return Container(
      height: 200.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Stack(
        children: [
          // Google Maps widget (commented for now)
          /*
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                geofenceViewModel.currentShift?['geofence']?['lat'] ?? 0.0,
                geofenceViewModel.currentShift?['geofence']?['lon'] ?? 0.0,
              ),
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('site'),
                position: LatLng(
                  geofenceViewModel.currentShift?['geofence']?['lat'] ?? 0.0,
                  geofenceViewModel.currentShift?['geofence']?['lon'] ?? 0.0,
                ),
                infoWindow: InfoWindow(
                  title: geofenceViewModel.currentShift?['site_name'] ?? 'Site',
                ),
              ),
              if (LocationService().currentPosition != null)
                Marker(
                  markerId: const MarkerId('current'),
                  position: LatLng(
                    LocationService().currentPosition!.latitude,
                    LocationService().currentPosition!.longitude,
                  ),
                  infoWindow: const InfoWindow(title: 'Your Location'),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
            },
            circles: {
              Circle(
                circleId: const CircleId('geofence'),
                center: LatLng(
                  geofenceViewModel.currentShift?['geofence']?['lat'] ?? 0.0,
                  geofenceViewModel.currentShift?['geofence']?['lon'] ?? 0.0,
                ),
                radius: (geofenceViewModel.currentShift?['geofence']?['check_in_distance'] ?? 100).toDouble(),
                fillColor: Colors.blue.withOpacity(0.2),
                strokeColor: Colors.blue,
                strokeWidth: 2,
              ),
            },
          ),
          */
          
          // Placeholder map image
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              image: const DecorationImage(
                image: AssetImage('assets/Icons/map_placeholder.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: Colors.black.withOpacity(0.3),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 48.sp,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Map View',
                      style: AppTypography.body().copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Google Maps will be displayed here',
                      style: AppTypography.body().copyWith(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Location info overlay
          Positioned(
            top: 12.h,
            left: 12.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                _locationController.text,
                style: AppTypography.body().copyWith(
                  color: Colors.white,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckinForm(WorkerGeofenceViewModel geofenceViewModel) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Check In Details',
            style: AppTypography.title().copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          
          // Check-in type
          Text(
            'Type',
            style: AppTypography.body().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedType,
                isExpanded: true,
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 14,
                ),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedType = value);
                },
                items: const [
                  DropdownMenuItem(value: 'regular', child: Text('Regular Check-in')),
                  DropdownMenuItem(value: 'incident', child: Text('Incident Report')),
                  DropdownMenuItem(value: 'checkpoint', child: Text('Checkpoint Scan')),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Location description
          Text(
            'Location Description',
            style: AppTypography.body().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          UltimateMobileTextField(
            controller: _locationController,
            decoration: InputDecoration(
              hintText: 'Enter location description',
              filled: true,
              fillColor: Colors.white,
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
                borderSide: const BorderSide(color: Color(0xFF0E45BA), width: 1.5),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Notes
          Text(
            'Notes',
            style: AppTypography.body().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8.h),
          UltimateMobileTextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter additional notes',
              filled: true,
              fillColor: Colors.white,
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
                borderSide: const BorderSide(color: Color(0xFF0E45BA), width: 1.5),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Photo evidence
          _buildPhotoSection(geofenceViewModel),
          SizedBox(height: 20.h),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: geofenceViewModel.isSubmittingCheckin 
                  ? null 
                  : () => _submitCheckin(geofenceViewModel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: geofenceViewModel.isSubmittingCheckin
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Check-in'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(WorkerGeofenceViewModel geofenceViewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photo Evidence',
          style: AppTypography.body().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8.h),
        
        if (geofenceViewModel.pendingPhoto != null)
          _buildPendingPhoto(geofenceViewModel)
        else
          _buildPhotoOptions(geofenceViewModel),
      ],
    );
  }

  Widget _buildPhotoOptions(WorkerGeofenceViewModel geofenceViewModel) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _takePhoto(geofenceViewModel),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Take Photo'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickPhoto(geofenceViewModel),
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingPhoto(WorkerGeofenceViewModel geofenceViewModel) {
    final photo = geofenceViewModel.pendingPhoto!;
    
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          Container(
            height: 150.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.file(
                File(photo.filePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Text(
                'Photo captured: ${photo.formattedFileSize}',
                style: AppTypography.body().copyWith(
                  fontSize: 12.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => geofenceViewModel.clearPendingPhoto(),
                child: const Text('Remove'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentCheckins(WorkerGeofenceViewModel geofenceViewModel) {
    final checkins = geofenceViewModel.checkinHistory;
    
    if (checkins.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Check-ins',
            style: AppTypography.title().copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          ...checkins.map((checkin) => _buildCheckinItem(checkin)).toList(),
        ],
      ),
    );
  }

  Widget _buildCheckinItem(Map<String, dynamic> checkin) {
    final timestamp = DateTime.tryParse(checkin['checked_in_at']);
    final insideGeofence = checkin['inside_geofence'] ?? false;
    final hasPhoto = checkin['photo_path'] != null;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.sp,
                height: 40.sp,
                decoration: BoxDecoration(
                  color: insideGeofence ? AppColors.successBackground : AppColors.errorBackground,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Icon(
                  insideGeofence ? Icons.check_circle : Icons.location_off,
                  color: insideGeofence ? AppColors.success : AppColors.error,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkin['location_description'] ?? 'No location',
                      style: AppTypography.body().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timestamp != null 
                          ? _formatCheckinTime(timestamp)
                          : 'Unknown time',
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPhoto)
                Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _viewCheckin(checkin),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  minimumSize: Size(60.w, 32.h),
                ),
              ),
              SizedBox(width: 4.w),
              TextButton.icon(
                onPressed: () => _editCheckin(checkin),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                  minimumSize: Size(60.w, 32.h),
                ),
              ),
              SizedBox(width: 4.w),
              TextButton.icon(
                onPressed: () => _deleteCheckin(checkin),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                  minimumSize: Size(60.w, 32.h),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _viewCheckin(Map<String, dynamic> checkin) {
    showDialog(
      context: context,
      builder: (context) => _CheckinDetailsDialog(checkin: checkin),
    );
  }

  void _editCheckin(Map<String, dynamic> checkin) {
    showDialog(
      context: context,
      builder: (context) => _EditCheckinDialog(checkin: checkin),
    );
  }

  void _deleteCheckin(Map<String, dynamic> checkin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Check-in'),
        content: const Text('Are you sure you want to delete this check-in?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final geofenceViewModel = context.read<WorkerGeofenceViewModel>();
              final success = await geofenceViewModel.deleteCheckin(checkin['id'].toString());
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Check-in deleted successfully' : 'Failed to delete check-in'),
                    backgroundColor: success ? AppColors.success : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _takePhoto(WorkerGeofenceViewModel geofenceViewModel) async {
    final success = await geofenceViewModel.takePhoto();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(geofenceViewModel.errorMessage ?? 'Failed to take photo'),
        ),
      );
    }
  }

  Future<void> _pickPhoto(WorkerGeofenceViewModel geofenceViewModel) async {
    final success = await geofenceViewModel.pickPhotoFromGallery();
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(geofenceViewModel.errorMessage ?? 'Failed to pick photo'),
        ),
      );
    }
  }

  Future<void> _submitCheckin(WorkerGeofenceViewModel geofenceViewModel) async {
    final success = await geofenceViewModel.submitCheckin(
      locationDescription: _locationController.text.trim(),
      notes: _notesController.text.trim(),
      type: _selectedType,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in submitted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      // Clear form
      _notesController.clear();
      _locationController.clear();
      setState(() {
        _selectedType = 'regular';
      });
      // Go back to dashboard automatically
      context.go(Routes.worker);
    } else {
      final errMsg = geofenceViewModel.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  (errMsg != null && errMsg.isNotEmpty)
                      ? errMsg
                      : 'Failed to submit check-in. Please try again.',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: EdgeInsets.all(16.w),
        ),
      );
    }
  }

  String _formatCheckinTime(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    final dateTime = timestamp is DateTime 
        ? timestamp 
        : DateTime.tryParse(timestamp.toString());
    
    if (dateTime == null) return 'Invalid time';
    
    final h = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final m = dateTime.minute.toString().padLeft(2, '0');
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    
    return '$h:$m $ampm';
  }
}

class _CheckinDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> checkin;

  const _CheckinDetailsDialog({required this.checkin});

  @override
  Widget build(BuildContext context) {
    final timestamp = DateTime.tryParse(checkin['checked_in_at']);
    final hasPhoto = checkin['photo_path'] != null && checkin['photo_path'].toString().isNotEmpty;
    
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Check-in Details',
                    style: AppTypography.title(),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              
              // Photo display if available
              if (hasPhoto) ...[
                Container(
                  width: double.infinity,
                  height: 200.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: AppColors.background,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      'http://0.0.0.0:8000/storage/${checkin['photo_path']}',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.photo_camera_outlined, size: 48),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              
              _buildDetailRow('Type', checkin['type']?.toString().toUpperCase() ?? 'REGULAR'),
              _buildDetailRow('Date Time', timestamp != null ? _formatDateTime(timestamp) : 'Unknown'),
              if (checkin['location_description'] != null)
                _buildDetailRow('Location', checkin['location_description']),
              if (checkin['notes'] != null)
                _buildDetailRow('Notes', checkin['notes']),
              _buildDetailRow('Coordinates', '${checkin['latitude']}, ${checkin['longitude']}'),
              _buildDetailRow('Geofence Status', checkin['inside_geofence'] == true ? 'Inside' : 'Outside'),
              if (checkin['distance_from_site'] != null)
                _buildDetailRow('Distance from Site', '${checkin['distance_from_site']}m'),
              
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              '$label:',
              style: AppTypography.body().copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _EditCheckinDialog extends StatefulWidget {
  final Map<String, dynamic> checkin;

  const _EditCheckinDialog({required this.checkin});

  @override
  State<_EditCheckinDialog> createState() => _EditCheckinDialogState();
}

class _EditCheckinDialogState extends State<_EditCheckinDialog> {
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with proper data casting
    final locationDesc = widget.checkin['location_description']?.toString() ?? '';
    final notes = widget.checkin['notes']?.toString() ?? '';
    final type = widget.checkin['type']?.toString() ?? 'regular';
    
    _locationController = TextEditingController(text: locationDesc);
    _notesController = TextEditingController(text: notes);
    _selectedType = type;
  }

  @override
  void dispose() {
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Check-in',
                    style: AppTypography.title(),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              
              Text(
                'Type',
                style: AppTypography.body().copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Check-in Type',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'regular', child: Text('Regular')),
                  DropdownMenuItem(value: 'incident', child: Text('Incident')),
                  DropdownMenuItem(value: 'checkpoint', child: Text('Checkpoint')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              
              SizedBox(height: 16.h),
              
              // Photo display if available
              if (widget.checkin['photo_path'] != null) ...[
                Text(
                  'Photo Evidence',
                  style: AppTypography.body().copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  height: 150.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: AppColors.background,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.r),
                    child: Image.network(
                      'http://0.0.0.0:8000/storage/${widget.checkin['photo_path']}',
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.photo_camera_outlined, size: 48),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
              ],
              
              Text(
                'Location Description',
                style: AppTypography.body().copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              UltimateMobileTextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location Description',
                  prefixIcon: Icon(Icons.location_on),
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              
              SizedBox(height: 16.h),
              Text(
                'Notes',
                style: AppTypography.body().copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              UltimateMobileTextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      final geofenceViewModel = context.read<WorkerGeofenceViewModel>();
                      final success = await geofenceViewModel.updateCheckin(
                        widget.checkin['id'].toString(),
                        locationDescription: _locationController.text.trim(),
                        notes: _notesController.text.trim(),
                        type: _selectedType,
                      );
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Check-in updated successfully' : 'Failed to update check-in'),
                            backgroundColor: success ? AppColors.success : Colors.red,
                          ),
                        );
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
