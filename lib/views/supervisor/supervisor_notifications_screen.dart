import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/supervisor_viewmodel.dart';
import '../../constants/app_constants.dart';
import '../../widgets/supervisor_panel_components.dart';

class SupervisorNotificationsScreen extends StatefulWidget {
  const SupervisorNotificationsScreen({super.key});

  @override
  State<SupervisorNotificationsScreen> createState() =>
      _SupervisorNotificationsScreenState();
}

class _SupervisorNotificationsScreenState
    extends State<SupervisorNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupervisorViewModel>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final supervisorViewModel = context.watch<SupervisorViewModel>();

    return SupervisorPanelScaffold(
      title: 'Notifications',
      subtitle: '${supervisorViewModel.unreadNotifications} unread',
      actions: [
        Icon(Icons.notifications_outlined, color: Colors.white, size: 24.sp),
      ],
      body: supervisorViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => supervisorViewModel.loadNotifications(),
              child: _buildNotificationsList(supervisorViewModel),
            ),
    );
  }

  Widget _buildNotificationsList(SupervisorViewModel viewModel) {
    final notifications = viewModel.notifications;

    // Use mock data if empty
    if (notifications.isEmpty) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            NotificationCard(
              title: 'Shift Reminder',
              message: 'Your shift starts in 30 minutes',
              timestamp: '15 min ago',
              icon: Icons.warning_amber_rounded,
              iconBackground: AppColors.warningText,
              isRead: false,
              onTap: () {},
            ),
            NotificationCard(
              title: 'Check-in Required',
              message: 'Time for your hourly check-in',
              timestamp: '30 min ago',
              icon: Icons.warning_amber_rounded,
              iconBackground: AppColors.danger,
              isRead: false,
              onTap: () {},
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        final isUnread = notification['read'] != true;

        return NotificationCard(
          title: notification['title'] ?? 'Notification',
          message: notification['message'] ?? '',
          timestamp: _formatDateTime(notification['timestamp']),
          icon: _getNotificationIcon(notification['type']),
          iconBackground: _getNotificationColor(notification['type']),
          isRead: !isUnread,
          onTap: () {
            if (isUnread) {
              viewModel.markNotificationAsRead(notification['id']);
            }
          },
        );
      },
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'alert':
        return Icons.warning_amber_rounded;
      case 'report':
        return Icons.assignment;
      case 'worker':
        return Icons.people;
      case 'reminder':
        return Icons.warning_amber_rounded;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'alert':
        return AppColors.danger;
      case 'report':
        return AppColors.primary;
      case 'worker':
        return AppColors.successText;
      case 'reminder':
        return AppColors.warningText;
      default:
        return AppColors.warningText;
    }
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return '';
    if (dateTime is DateTime) {
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    }
    return dateTime.toString();
  }
}
