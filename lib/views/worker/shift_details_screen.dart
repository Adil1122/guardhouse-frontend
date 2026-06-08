import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/worker_geofence_viewmodel.dart';

class ShiftDetailsScreen extends StatefulWidget {
  const ShiftDetailsScreen({super.key, required this.shiftId});

  final String shiftId;

  @override
  State<ShiftDetailsScreen> createState() => _ShiftDetailsScreenState();
}

class _ShiftDetailsScreenState extends State<ShiftDetailsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerGeofenceViewModel>().loadShiftDetails(widget.shiftId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerGeofenceViewModel>();
    final shift = vm.shiftDetails;

    if (vm.isLoading && shift == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (shift == null) {
      return const Scaffold(
        body: Center(child: Text('Shift details not found')),
      );
    }

    final checkins =
        (shift['checkins'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: SafeArea(
        child: Column(
          children: [
            _TopBlueSummary(
              start: _formatTime(shift['start_time']),
              end: _formatTime(shift['end_time']),
              total: '${shift['duration_hours'] ?? 9}h',
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16.sp),
                children: [
                  _LocationCard(
                    dateText: _formatDate(shift['date']),
                    siteName:
                        shift['site_name']?.toString() ?? 'Downtown Office',
                    address:
                        shift['site_address']?.toString() ??
                        '123 Main Street, City Center, NY',
                  ),
                  SizedBox(height: 12.h),
                  _StatsCard(
                    checkinsCount: shift['checkins_count'] ?? 0,
                    photosCount: shift['photos_count'] ?? 0,
                    status: shift['status'] ?? 'completed',
                  ),
                  SizedBox(height: 12.h),
                  _TimelineCard(checkins: checkins),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic value) {
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'Dec 30, 2025';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatTime(dynamic value) {
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '08:00 AM';
    final h = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final m = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$h:${m} $ampm';
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.checkinsCount,
    required this.photosCount,
    required this.status,
  });

  final int checkinsCount;
  final int photosCount;
  final String status;

  @override
  Widget build(BuildContext context) {
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
            'Shift Statistics',
            style: AppTypography.title().copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.check_circle_outline,
                  label: 'Check-ins',
                  value: '$checkinsCount',
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _StatItem(
                  icon: Icons.camera_alt_outlined,
                  label: 'Photos',
                  value: '$photosCount',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Status: ${_getStatusText(status)}',
                  style: AppTypography.body().copyWith(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'clocked-out-offsite':
        return AppColors.warning;
      case 'missed-clock-in':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'clocked-out-offsite':
        return Icons.location_off;
      case 'missed-clock-in':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'clocked-out-offsite':
        return 'Ended Off-site';
      case 'missed-clock-in':
        return 'Missed Clock-in';
      default:
        return 'Unknown';
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48.sp,
          height: 48.sp,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          value,
          style: AppTypography.body().copyWith(
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: AppTypography.body().copyWith(
            fontSize: 12.sp,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TopBlueSummary extends StatelessWidget {
  const _TopBlueSummary({
    required this.start,
    required this.end,
    required this.total,
  });

  final String start;
  final String end;
  final String total;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 18.h),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shift Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'All your shifts',
                    style: TextStyle(
                      color: AppColors.subTextOnPrimary,
                      fontSize: 18.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _SmallTop(label: 'Start Time', value: start),
              ),
              Expanded(
                child: _SmallTop(label: 'End Time', value: end),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Divider(color: Colors.white30, height: 1),
          SizedBox(height: 8.h),
          Text(
            'Total Hours',
            style: TextStyle(
              color: AppColors.subTextOnPrimary,
              fontSize: 16.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            total,
            style: TextStyle(
              color: Colors.white,
              fontSize: 40.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallTop extends StatelessWidget {
  const _SmallTop({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.subTextOnPrimary,
              fontSize: 12.sp,
            ),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 15.sp),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.dateText,
    required this.siteName,
    required this.address,
  });

  final String dateText;
  final String siteName;
  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32.sp,
                height: 32.sp,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(Icons.location_on_outlined, size: 18.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                dateText,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _GrayInfoBlock(label: 'Site Name', value: siteName),
          SizedBox(height: 8.h),
          _GrayInfoBlock(label: 'Address', value: address),
        ],
      ),
    );
  }
}

class _GrayInfoBlock extends StatelessWidget {
  const _GrayInfoBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.checkins});

  final List<Map<String, dynamic>> checkins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.watch_later_outlined, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'Check-in Timelines (${checkins.length})',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          ...checkins.map((item) {
            final isIssue = (item['type']?.toString() ?? '') == 'incident';
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28.sp,
                      height: 28.sp,
                      decoration: BoxDecoration(
                        color: isIssue
                            ? const Color(0xFFFAD9D9)
                            : const Color(0xFFD8F3DF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.watch_later_outlined,
                        size: 16.sp,
                        color: isIssue ? Colors.red : const Color(0xFF16A34A),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _time(item['timestamp']),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                isIssue ? 'Unconfirmed' : 'Confirmed',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: isIssue
                                      ? Colors.red
                                      : const Color(0xFF16A34A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 14.sp,
                                color: isIssue
                                    ? Colors.red
                                    : AppColors.textSecondary,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                isIssue ? 'Photo missing' : 'Photo attached',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: isIssue
                                      ? Colors.red
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _time(dynamic v) {
    final date = v is DateTime ? v : DateTime.tryParse(v?.toString() ?? '');
    if (date == null) return '08:00 AM';
    final h = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final m = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$h:${m} $ampm';
  }
}
