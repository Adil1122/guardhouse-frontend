import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/supervisor_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';

class SupervisorActivitySheetScreen extends StatelessWidget {
  const SupervisorActivitySheetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<SupervisorViewModel>().recentReports;

    return WorkerPanelScaffold(
      title: 'Activity Sheet',
      body: reports.isEmpty
          ? Center(
              child: Text(
                'No recent activities',
                style: AppTypography.body().copyWith(
                  fontSize: 14.sp,
                  color: AppColors.textSecondary,
                ),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
              itemCount: reports.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (_, i) => _ActivityCard(report: reports[i]),
            ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.report});

  final Map<String, dynamic> report;

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Incident':
        return Icons.warning_amber_outlined;
      case 'Patrol':
        return Icons.security_outlined;
      case 'Welfare':
        return Icons.health_and_safety_outlined;
      default:
        return Icons.assignment_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = report['title']?.toString() ?? 'Activity';
    final type = report['type']?.toString() ?? '';
    final priority = report['priority']?.toString() ?? 'Normal';
    final status = report['status']?.toString() ?? '';
    final createdAt =
        DateTime.tryParse(report['createdAt']?.toString() ?? '');

    final priorityColor = priority == 'High'
        ? AppColors.error
        : priority == 'Low'
            ? AppColors.successText
            : AppColors.warningText;
    final priorityBg = priority == 'High'
        ? AppColors.errorBackground
        : priority == 'Low'
            ? AppColors.successBackground
            : AppColors.warningBackground;

    final statusColor =
        (status == 'Reviewed' || status == 'Approved')
            ? AppColors.successText
            : status == 'Pending'
                ? AppColors.warningText
                : AppColors.textSecondary;
    final statusBg =
        (status == 'Reviewed' || status == 'Approved')
            ? AppColors.successBackground
            : status == 'Pending'
                ? AppColors.warningBackground
                : AppColors.neutralIconBackground;

    String timeLabel = '';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inMinutes < 60) {
        timeLabel = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeLabel = '${diff.inHours}h ago';
      } else {
        timeLabel = '${diff.inDays}d ago';
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40.sp,
            height: 40.sp,
            decoration: BoxDecoration(
              color: AppColors.actionButtonBackground,
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: Icon(
              _typeIcon(type),
              size: 20.sp,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body().copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textprimaryDark,
                  ),
                ),
                SizedBox(height: 3.h),
                Row(
                  children: [
                    if (type.isNotEmpty) ...[
                      Text(
                        type,
                        style: AppTypography.body().copyWith(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Container(
                        width: 3.w,
                        height: 3.w,
                        decoration: const BoxDecoration(
                          color: AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 5.w),
                    ],
                    if (timeLabel.isNotEmpty)
                      Text(
                        timeLabel,
                        style: AppTypography.body().copyWith(
                          fontSize: 11.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: priorityBg,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        priority,
                        style: AppTypography.body().copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        status,
                        style: AppTypography.body().copyWith(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
