import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../viewmodels/admin_viewmodel.dart';

class AlertNotificationScreen extends StatefulWidget {
  const AlertNotificationScreen({super.key});

  @override
  State<AlertNotificationScreen> createState() =>
      _AlertNotificationScreenState();
}

class _AlertNotificationScreenState extends State<AlertNotificationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().loadAlerts();
    });
  }

  _AlertItem _fromMap(Map<String, dynamic> item, int index) {
    final severityRaw = (item['severity'] ?? item['type'] ?? '')
        .toString()
        .toLowerCase();
    final severity =
        (severityRaw.contains('critical') || severityRaw.contains('high'))
        ? 'critical'
        : 'warning';

    return _AlertItem(
      title: (item['title'] ?? 'Alert').toString(),
      message: (item['message'] ?? item['description'] ?? '').toString(),
      worker: (item['worker_name'] ?? item['worker'] ?? 'Unknown').toString(),
      location: (item['location'] ?? item['site_name'] ?? 'Unknown Site')
          .toString(),
      timeAgo: (item['time'] ?? item['time_ago'] ?? '${index + 1} min ago')
          .toString(),
      severity: severity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminViewModel>(
      builder: (context, viewModel, child) {
        final alerts = List.generate(
          viewModel.alerts.length,
          (index) => _fromMap(viewModel.alerts[index], index),
        );

        return Scaffold(
          backgroundColor: const Color(0xFFE5E7EB),
          body: SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 18.h),
                  color: AppColors.primary,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alert & Notifications',
                              style: AppTypography.title().copyWith(
                                color: Colors.white,
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              '${alerts.length} active alerts',
                              style: AppTypography.label().copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: viewModel.isLoading && viewModel.alerts.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => viewModel.loadAlerts(),
                          child: ListView.builder(
                            padding: EdgeInsets.fromLTRB(
                              16.w,
                              16.h,
                              16.w,
                              20.h,
                            ),
                            itemCount: alerts.length,
                            itemBuilder: (context, index) {
                              final alert = alerts[index];
                              return Padding(
                                padding: EdgeInsets.only(bottom: 14.h),
                                child: _AlertCard(item: alert),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  final _AlertItem item;

  const _AlertCard({required this.item});

  bool get isCritical => item.severity == 'critical';

  Color get cardColor =>
      isCritical ? const Color(0xFFF4D9DD) : const Color(0xFFF1E4AE);

  Color get titleColor =>
      isCritical ? const Color(0xFFFF1616) : const Color(0xFFC19A00);

  Color get iconColor =>
      isCritical ? const Color(0xFFFF1616) : const Color(0xFFC19A00);

  IconData get icon {
    if (item.title.toLowerCase().contains('geofence'))
      return Icons.location_on_outlined;
    if (item.title.toLowerCase().contains('inactivity'))
      return Icons.warning_amber_rounded;
    return Icons.access_time;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: iconColor, size: 24.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTypography.title().copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                        color: titleColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      item.message,
                      style: AppTypography.body().copyWith(
                        fontSize: 13.sp,
                        color: const Color(0xFF5B6475),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Padding(
            padding: EdgeInsets.only(left: 52.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Worker: ${item.worker}',
                    style: AppTypography.body().copyWith(
                      fontSize: 11.sp,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
                Text(
                  item.location,
                  style: AppTypography.body().copyWith(
                    fontSize: 11.sp,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 6.h),
          Padding(
            padding: EdgeInsets.only(left: 52.w),
            child: Text(
              item.timeAgo,
              style: AppTypography.body().copyWith(
                fontSize: 11.sp,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertItem {
  final String title;
  final String message;
  final String worker;
  final String location;
  final String timeAgo;
  final String severity;

  const _AlertItem({
    required this.title,
    required this.message,
    required this.worker,
    required this.location,
    required this.timeAgo,
    required this.severity,
  });
}
