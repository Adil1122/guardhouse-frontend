import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';

class WorkerNotificationsScreen extends StatefulWidget {
  const WorkerNotificationsScreen({super.key});

  @override
  State<WorkerNotificationsScreen> createState() =>
      _WorkerNotificationsScreenState();
}

class _WorkerNotificationsScreenState extends State<WorkerNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerViewModel>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerViewModel>();
    final notifications = vm.notifications;

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
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${vm.unreadNotifications} unread',
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
                  Container(
                    width: 44.sp,
                    height: 44.sp,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E4BD8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                      size: 22.sp,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.loadNotifications,
                child: ListView(
                  padding: EdgeInsets.all(16.sp),
                  children: [
                    if (vm.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (notifications.isEmpty)
                      _NotificationCard(
                        title: 'No notifications',
                        subtitle: 'You are all caught up',
                        timeText: '',
                        isAlert: false,
                        unread: false,
                      )
                    else
                      ...notifications.take(2).map((n) {
                        final type = n['type']?.toString() ?? 'shift';
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _NotificationCard(
                            title: n['title']?.toString() ?? 'Shift Reminder',
                            subtitle:
                                n['message']?.toString() ??
                                'Your shift starts in 30 minutes',
                            timeText: _formatDateTime(n['timestamp']),
                            isAlert: type == 'alert',
                            unread: n['read'] != true,
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(dynamic value) {
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '10 min ago';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} day ago';
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.title,
    required this.subtitle,
    required this.timeText,
    required this.isAlert,
    required this.unread,
  });

  final String title;
  final String subtitle;
  final String timeText;
  final bool isAlert;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final bg = isAlert ? const Color(0xFFF8EDBE) : const Color(0xFFDDE7FA);
    final iconColor = isAlert ? const Color(0xFFC49A06) : AppColors.primary;

    return Container(
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30.sp,
            height: 30.sp,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              isAlert
                  ? Icons.warning_amber_rounded
                  : Icons.notification_important_outlined,
              color: iconColor,
              size: 18.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (timeText.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    timeText,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (unread)
            Container(
              width: 8.sp,
              height: 8.sp,
              margin: EdgeInsets.only(top: 2.h),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
