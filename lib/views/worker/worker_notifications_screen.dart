import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';

class WorkerNotificationsScreen extends StatefulWidget {
  const WorkerNotificationsScreen({super.key});

  @override
  State<WorkerNotificationsScreen> createState() =>
      _WorkerNotificationsScreenState();
}

class _WorkerNotificationsScreenState
    extends State<WorkerNotificationsScreen> {
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
    final unread = vm.unreadNotifications;

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────────────
            Container(
              width: double.infinity,
              color: AppColors.primary,
              padding: EdgeInsets.fromLTRB(4.w, 8.h, 12.w, 16.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          unread > 0 ? '$unread unread' : 'All caught up',
                          style: TextStyle(
                            color: AppColors.subTextOnPrimary,
                            fontSize: 13.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (unread > 0)
                    TextButton(
                      onPressed: () async {
                        await vm.markAllNotificationsAsRead();
                      },
                      child: Text(
                        'Mark all read',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── List ─────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.loadNotifications,
                child: vm.isLoading && notifications.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : notifications.isEmpty
                        ? ListView(
                            children: [
                              SizedBox(height: 80.h),
                              Icon(
                                Icons.notifications_off_outlined,
                                size: 56.sp,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                'No notifications',
                                textAlign: TextAlign.center,
                                style: AppTypography.body().copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'You are all caught up',
                                textAlign: TextAlign.center,
                                style: AppTypography.body().copyWith(
                                  fontSize: 13.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 16.h),
                            itemCount: notifications.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: 10.h),
                            itemBuilder: (context, i) {
                              final n = notifications[i];
                              return _NotificationTile(
                                notification: n,
                                onTap: () {
                                  if (n['read'] != true) {
                                    vm.markNotificationAsRead(
                                        n['id'].toString());
                                  }
                                },
                                onDismiss: () {
                                  vm.deleteNotification(
                                      n['id'].toString());
                                },
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
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final Map<String, dynamic> notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final type = notification['type']?.toString() ?? 'info';
    final isAlert = type == 'alert';
    final unread = notification['read'] != true;

    final bg = isAlert ? const Color(0xFFFFF8E1) : Colors.white;
    final borderColor = isAlert
        ? const Color(0xFFFFCC02)
        : (unread ? AppColors.primary.withOpacity(0.3) : AppColors.cardBorder);
    final iconColor =
        isAlert ? const Color(0xFFC49A06) : AppColors.primary;
    final iconBg = isAlert
        ? const Color(0xFFF8EDBE)
        : AppColors.infoBackground;

    final title = notification['title']?.toString() ?? 'Notification';
    final message = notification['message']?.toString() ?? '';
    final timestamp =
        notification['created_at'] ?? notification['timestamp'];
    final timeText = _formatTime(timestamp);

    return Dismissible(
      key: ValueKey(notification['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 22.sp),
      ),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(14.sp),
          decoration: BoxDecoration(
            color: unread ? bg : Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36.sp,
                height: 36.sp,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isAlert
                      ? Icons.warning_amber_rounded
                      : Icons.notifications_outlined,
                  color: iconColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTypography.body().copyWith(
                              fontSize: 14.sp,
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (unread)
                          Container(
                            width: 8.sp,
                            height: 8.sp,
                            decoration: BoxDecoration(
                              color: isAlert
                                  ? const Color(0xFFC49A06)
                                  : AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    if (message.isNotEmpty) ...[
                      SizedBox(height: 3.h),
                      Text(
                        message,
                        style: AppTypography.body().copyWith(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (timeText.isNotEmpty) ...[
                      SizedBox(height: 5.h),
                      Text(
                        timeText,
                        style: AppTypography.body().copyWith(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(dynamic value) {
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return '';
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays} days ago';
  }
}
