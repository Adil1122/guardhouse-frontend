import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/routes/app_routes.dart';
import 'package:security_app/viewmodels/worker_geofence_viewmodel.dart';

class EnhancedDutyHistoryScreen extends StatefulWidget {
  const EnhancedDutyHistoryScreen({super.key});

  @override
  State<EnhancedDutyHistoryScreen> createState() => _EnhancedDutyHistoryScreenState();
}

class _EnhancedDutyHistoryScreenState extends State<EnhancedDutyHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerGeofenceViewModel>().loadDutyHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerGeofenceViewModel>();
    final shifts = vm.dutyHistory;
    
    debugPrint('Duty History Build - Loading: ${vm.isLoading}, Shifts Count: ${shifts.length}');
    if (shifts.isNotEmpty) {
      debugPrint('First shift data: ${shifts.first}');
    }

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 18.h),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => GoRouter.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duty History',
                            style: AppTypography.title().copyWith(
                              color: Colors.white,
                              fontSize: 32.sp,
                            ),
                          ),
                          Text(
                            'All your shift records',
                            style: AppTypography.body().copyWith(
                              color: AppColors.subTextOnPrimary,
                              fontSize: 18.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _TopStat(value: '${shifts.length}', label: 'Shifts'),
                      _TopStat(
                        value: '${_calculateTotalHours(shifts).toStringAsFixed(1)}h',
                        label: 'Total Hours',
                      ),
                      _TopStat(
                        value: '${_calculateTotalCheckins(shifts)}',
                        label: 'Check-ins',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => vm.loadDutyHistory(),
                child: vm.isLoading && shifts.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : shifts.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.all(16.sp),
                            itemCount: shifts.length,
                            itemBuilder: (context, index) {
                              final shift = shifts[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 12.h),
                                child: _HistoryCard(
                                  dateText: _formatDate(shift['date']),
                                  timeText:
                                      '${_formatTime(shift['start_time'])} - ${_formatTime(shift['end_time'])}',
                                  siteText:
                                      shift['site_name']?.toString() ?? 'Unknown Site',
                                  hoursText: '${(shift['duration_hours'] as num? ?? 0).toStringAsFixed(1)}h',
                                  checkins: '${shift['checkins_count'] ?? 0}',
                                  photos: '${shift['photos_count'] ?? 0}',
                                  onTap: () {
                                    final id = shift['id']?.toString();
                                    if (id != null) {
                                      context.push('/worker/shift-details', extra: id);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
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
              'No Duty History',
              style: AppTypography.title().copyWith(
                fontSize: 24.sp,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Your completed shifts will appear here',
              style: AppTypography.body().copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).push('/worker'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  double _calculateTotalHours(List<Map<String, dynamic>> shifts) {
    return shifts.fold(
      0.0,
      (sum, shift) => sum + ((shift['duration_hours'] as num?)?.toDouble() ?? 0),
    );
  }

  int _calculateTotalCheckins(List<Map<String, dynamic>> shifts) {
    return shifts.fold(
      0,
      (sum, shift) => sum + ((shift['checkins_count'] as int?) ?? 0),
    );
  }

  String _formatDate(dynamic value) {
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '–';
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
    if (value == null) return '–';
    final date = value is DateTime ? value : DateTime.tryParse(value.toString());
    if (date != null) {
      final h = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final m = date.minute.toString().padLeft(2, '0');
      final ampm = date.hour >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }
    // Handle H:i:s or H:i time-only strings (e.g. "08:00:00")
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value.toString());
    if (match != null) {
      final h24 = int.parse(match.group(1)!);
      final m = match.group(2)!;
      final h = h24 > 12 ? h24 - 12 : (h24 == 0 ? 12 : h24);
      final ampm = h24 >= 12 ? 'PM' : 'AM';
      return '$h:$m $ampm';
    }
    return '–';
  }
}

class _TopStat extends StatelessWidget {
  const _TopStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: AppColors.subTextOnPrimary, fontSize: 14.sp),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.dateText,
    required this.timeText,
    required this.siteText,
    required this.hoursText,
    required this.checkins,
    required this.photos,
    required this.onTap,
  });

  final String dateText;
  final String timeText;
  final String siteText;
  final String hoursText;
  final String checkins;
  final String photos;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          padding: EdgeInsets.all(12.sp),
          decoration: BoxDecoration(
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
                    child: Icon(Icons.calendar_today_outlined, size: 16.sp),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    hoursText,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Text(
                      siteText,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8F3DF),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      'Completed',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Divider(height: 1, color: AppColors.cardBorder),
              SizedBox(height: 8.h),
              Row(
                children: [
                  _SmallMetric(
                    icon: Icons.watch_later_outlined,
                    label: 'Check-ins',
                    value: checkins,
                  ),
                  SizedBox(width: 24.w),
                  _SmallMetric(
                    icon: Icons.camera_alt_outlined,
                    label: 'Photos',
                    value: photos,
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

class _SmallMetric extends StatelessWidget {
  const _SmallMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28.sp,
          height: 28.sp,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(icon, size: 14.sp),
        ),
        SizedBox(width: 8.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
            ),
            Text(
              value,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }
}
