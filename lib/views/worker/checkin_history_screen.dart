import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/config/api_config.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/worker_geofence_viewmodel.dart';

class CheckinHistoryScreen extends StatefulWidget {
  const CheckinHistoryScreen({super.key});

  @override
  State<CheckinHistoryScreen> createState() => _CheckinHistoryScreenState();
}

class _CheckinHistoryScreenState extends State<CheckinHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerGeofenceViewModel>().loadCheckinHistory();
    });
  }

  void _viewCheckin(Map<String, dynamic> checkin) {
    showDialog(
      context: context,
      builder: (context) => _CheckinDetailsDialog(checkin: checkin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerGeofenceViewModel>();
    final checkins = vm.checkinHistory;

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Check-in History'),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async => vm.loadCheckinHistory(),
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : checkins.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: checkins.length,
                    itemBuilder: (context, index) => _CheckinCard(
                      checkin: checkins[index],
                      onTap: () => _viewCheckin(checkins[index]),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64.sp, color: AppColors.textSecondary),
            SizedBox(height: 16.h),
            Text(
              'No Check-in History',
              style: AppTypography.title().copyWith(
                fontSize: 24.sp,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your check-ins will appear here once you start checking in.',
              textAlign: TextAlign.center,
              style: AppTypography.body().copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  final Map<String, dynamic> checkin;
  final VoidCallback onTap;

  const _CheckinCard({required this.checkin, required this.onTap});

  Color _typeColor(String? type) {
    switch (type) {
      case 'incident':   return Colors.red;
      case 'checkpoint': return Colors.blue;
      default:           return Colors.green;
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null) return 'Unknown';
    try {
      final dt = DateTime.parse(value.toString());
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = checkin['photo_path'] != null;
    final insideGeofence = checkin['inside_geofence'] == true;

    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: type badge + timestamp
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: _typeColor(checkin['type']?.toString()).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      checkin['type']?.toString().toUpperCase() ?? 'REGULAR',
                      style: AppTypography.body().copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.sp,
                        color: _typeColor(checkin['type']?.toString()),
                      ),
                    ),
                  ),
                  Text(
                    _formatDateTime(checkin['checked_in_at']),
                    style: AppTypography.body().copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              // Site name
              if (checkin['site_name'] != null)
                Row(
                  children: [
                    Icon(Icons.location_city, size: 14.sp, color: AppColors.primary),
                    SizedBox(width: 4.w),
                    Text(
                      checkin['site_name'],
                      style: AppTypography.body().copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
              if (checkin['site_name'] != null) SizedBox(height: 4.h),
              // Geofence + photo badges
              Row(
                children: [
                  Icon(
                    insideGeofence ? Icons.check_circle : Icons.cancel,
                    size: 14.sp,
                    color: insideGeofence ? Colors.green : Colors.orange,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    insideGeofence ? 'Inside Geofence' : 'Outside Geofence',
                    style: AppTypography.body().copyWith(
                      fontSize: 11.sp,
                      color: insideGeofence ? Colors.green : Colors.orange,
                    ),
                  ),
                  if (hasPhoto) ...[
                    SizedBox(width: 12.w),
                    Icon(Icons.camera_alt_outlined, size: 14.sp, color: AppColors.textSecondary),
                    SizedBox(width: 3.w),
                    Text(
                      'Photo',
                      style: AppTypography.body().copyWith(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 16.sp, color: AppColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckinDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> checkin;

  const _CheckinDetailsDialog({required this.checkin});

  String _formatDateTime(dynamic value) {
    if (value == null) return 'Unknown';
    try {
      final dt = DateTime.parse(value.toString());
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefer backend-supplied full URL; fall back to constructing from path
    final photoPath = checkin['photo_path']?.toString();
    final photoUrl = checkin['photo_url']?.toString()
        ?? (photoPath != null ? '${ApiConfig.storageUrl}$photoPath' : null);

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title bar
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 16.h, 8.w, 0),
            child: Row(
              children: [
                Text('Check-in Details',
                    style: AppTypography.title().copyWith(fontSize: 16.sp)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Type', checkin['type']?.toString().toUpperCase() ?? 'REGULAR'),
                  _row('Date & Time', _formatDateTime(checkin['checked_in_at'])),
                  if (checkin['site_name'] != null)
                    _row('Site', checkin['site_name'].toString()),
                  if (checkin['location_description'] != null)
                    _row('Location', checkin['location_description'].toString()),
                  if (checkin['notes']?.toString().isNotEmpty == true)
                    _row('Notes', checkin['notes'].toString()),
                  _row(
                    'Coordinates',
                    checkin['latitude'] != null
                        ? '${checkin['latitude']}, ${checkin['longitude']}'
                        : 'N/A',
                  ),
                  _row(
                    'Geofence',
                    checkin['inside_geofence'] == true ? 'Inside ✓' : 'Outside',
                  ),
                  if (checkin['distance_from_site'] != null)
                    _row('Distance', '${checkin['distance_from_site']}m'),
                  if (checkin['checkpoint'] != null)
                    _row('Checkpoint', checkin['checkpoint']['name']?.toString() ?? ''),
                  // Photo
                  if (photoUrl != null && photoUrl.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Text('Photo Evidence',
                        style: AppTypography.body()
                            .copyWith(fontWeight: FontWeight.w600, fontSize: 13.sp)),
                    SizedBox(height: 8.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: Image.network(
                        photoUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) => progress == null
                            ? child
                            : SizedBox(
                                height: 160.h,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          height: 80.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image_outlined,
                                  size: 32.sp, color: Colors.grey),
                              SizedBox(height: 4.h),
                              Text('Unable to load photo',
                                  style: TextStyle(
                                      fontSize: 11.sp, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
