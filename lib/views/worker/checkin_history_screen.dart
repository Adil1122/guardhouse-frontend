import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
        onRefresh: () async {
          await vm.loadCheckinHistory();
        },
        child: vm.isLoading
            ? const Center(child: CircularProgressIndicator())
            : checkins.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: checkins.length,
                    itemBuilder: (context, index) {
                      final checkin = checkins[index];
                      return _CheckinCard(
                        checkin: checkin,
                        onView: () => _viewCheckin(checkin),
                        onEdit: () => _editCheckin(checkin),
                        onDelete: () => _deleteCheckin(checkin),
                      );
                    },
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
            Icon(
              Icons.history,
              size: 64.sp,
              color: AppColors.textSecondary,
            ),
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
              style: AppTypography.body().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
    // TODO: Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
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
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement delete functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete functionality coming soon')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  final Map<String, dynamic> checkin;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CheckinCard({
    required this.checkin,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  checkin['type']?.toString().toUpperCase() ?? 'REGULAR',
                  style: AppTypography.body().copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(checkin['type']),
                  ),
                ),
                Text(
                  _formatDateTime(checkin['checked_in_at']),
                  style: AppTypography.body().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            if (checkin['location_description'] != null) ...[
              Text(
                checkin['location_description'],
                style: AppTypography.body(),
              ),
              SizedBox(height: 4.h),
            ],
            if (checkin['notes'] != null) ...[
              Text(
                checkin['notes'],
                style: AppTypography.body().copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 4.h),
            ],
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 4.w),
                Text(
                  '${checkin['latitude']}, ${checkin['longitude']}',
                  style: AppTypography.body().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
                if (checkin['inside_geofence'] == true) ...[
                  SizedBox(width: 8.w),
                  Icon(
                    Icons.check_circle,
                    size: 16.sp,
                    color: Colors.green,
                  ),
                  SizedBox(width: 4.w),
                  Text(
                    'Inside Geofence',
                    style: AppTypography.body().copyWith(
                      color: Colors.green,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'incident':
        return Colors.red;
      case 'checkpoint':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Unknown';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }
}

class _CheckinDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> checkin;

  const _CheckinDetailsDialog({required this.checkin});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: EdgeInsets.all(24.w),
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
            _buildDetailRow('Type', checkin['type']?.toString().toUpperCase() ?? 'REGULAR'),
            _buildDetailRow('Date Time', _formatDateTime(checkin['checked_in_at'])),
            if (checkin['location_description'] != null)
              _buildDetailRow('Location', checkin['location_description']),
            if (checkin['notes'] != null)
              _buildDetailRow('Notes', checkin['notes']),
            _buildDetailRow('Coordinates', '${checkin['latitude']}, ${checkin['longitude']}'),
            _buildDetailRow('Geofence Status', checkin['inside_geofence'] == true ? 'Inside' : 'Outside'),
            if (checkin['distance_from_site'] != null)
              _buildDetailRow('Distance from Site', '${checkin['distance_from_site']}m'),
            if (checkin['photo_path'] != null)
              _buildDetailRow('Photo', 'Photo uploaded'),
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

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Unknown';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }
}
