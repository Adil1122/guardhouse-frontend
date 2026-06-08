import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';

// =====================================
// STAT CARD - Bordered box with number + label
// =====================================
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const StatCard({
    Key? key,
    required this.label,
    required this.value,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: AppTypography.title().copyWith(
                fontSize: 24.sp,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              label,
              style: AppTypography.body().copyWith(
                fontSize: 11.sp,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================
// SITE CARD - Green dot, name, address, workers, Visit Site button
// =====================================
class SiteCard extends StatelessWidget {
  final String siteName;
  final String location;
  final String status;
  final String workersCount;
  final String distance;
  final VoidCallback? onTap;
  final VoidCallback? onVisitTap;

  const SiteCard({
    Key? key,
    required this.siteName,
    required this.location,
    this.status = 'active',
    required this.workersCount,
    this.distance = '',
    this.onTap,
    this.onVisitTap,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.successText;
      case 'warning':
        return AppColors.warningText;
      case 'inactive':
        return AppColors.textSecondary;
      default:
        return AppColors.successText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    siteName,
                    style: AppTypography.title().copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    location,
                    style: AppTypography.body().copyWith(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 14.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 5.w),
                Text(
                  workersCount,
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(width: 12.w),
                Icon(
                  Icons.location_on_outlined,
                  size: 14.sp,
                  color: AppColors.textSecondary,
                ),
                SizedBox(width: 4.w),
                Text(
                  distance,
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            if (onVisitTap != null)
              SizedBox(
                width: double.infinity,
                height: 40.h,
                child: ElevatedButton(
                  onPressed: onVisitTap,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: Text(
                    'Visit Site',
                    style: AppTypography.body().copyWith(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =====================================
// WORKER ON DUTY CARD - Avatar, name, time, colored dot
// =====================================
class WorkerOnDutyCard extends StatelessWidget {
  final String workerName;
  final String checkInTime;
  final String status;
  final VoidCallback? onTap;

  const WorkerOnDutyCard({
    Key? key,
    required this.workerName,
    required this.checkInTime,
    required this.status,
    this.onTap,
  }) : super(key: key);

  Color _getStatusColor() {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.successText;
      case 'break':
        return AppColors.warningText;
      case 'inactive':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20.r,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              child: Text(
                workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workerName,
                    style: AppTypography.title().copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    checkInTime,
                    style: AppTypography.body().copyWith(
                      fontSize: 11.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 12.w,
              height: 12.w,
              decoration: BoxDecoration(
                color: _getStatusColor(),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================
// STATUS BANNER - Red (Off Site) / Green (On Site)
// =====================================
class StatusBanner extends StatelessWidget {
  final bool isOnSite;
  final String? subtitle;

  const StatusBanner({Key? key, required this.isOnSite, this.subtitle})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isOnSite ? AppColors.successBackground : const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isOnSite ? AppColors.successBorder : AppColors.danger,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isOnSite ? Icons.check_circle : Icons.location_off,
            color: isOnSite ? AppColors.successText : AppColors.danger,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOnSite ? 'On Site' : 'Off Site',
                  style: AppTypography.title().copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: isOnSite ? AppColors.successText : AppColors.danger,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
                    style: AppTypography.body().copyWith(
                      fontSize: 11.sp,
                      color: isOnSite
                          ? AppColors.successText
                          : AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================
// SITE INFO CARD - Location icon, name, address
// =====================================
class SiteInfoCard extends StatelessWidget {
  final String siteName;
  final String address;

  const SiteInfoCard({Key? key, required this.siteName, required this.address})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.location_on,
              color: AppColors.primary,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siteName,
                  style: AppTypography.title().copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  address,
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
}

// =====================================
// STAT ROW - Two stat boxes side by side
// =====================================
class StatRow extends StatelessWidget {
  final String value1;
  final String label1;
  final String value2;
  final String label2;

  const StatRow({
    Key? key,
    required this.value1,
    required this.label1,
    required this.value2,
    required this.label2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Text(
                  value1,
                  style: AppTypography.title().copyWith(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  label1,
                  style: AppTypography.body().copyWith(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: [
                Text(
                  value2,
                  style: AppTypography.title().copyWith(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  label2,
                  style: AppTypography.body().copyWith(
                    fontSize: 11.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =====================================
// INFO CARD - e.g. "Automatic Time Tracking"
// =====================================
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;

  const InfoCard({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.infoBorder.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? AppColors.primary, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.title().copyWith(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitle!,
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
    );
  }
}

// =====================================
// NOTIFICATION CARD
// =====================================
class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String timestamp;
  final IconData icon;
  final Color iconBackground;
  final bool isRead;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationCard({
    Key? key,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.iconBackground,
    this.isRead = true,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : AppColors.infoBackground,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isRead ? AppColors.cardBorder : AppColors.infoBorder,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: iconBackground.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconBackground, size: 22.sp),
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
                          style: AppTypography.title().copyWith(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    message,
                    style: AppTypography.body().copyWith(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    timestamp,
                    style: AppTypography.body().copyWith(
                      fontSize: 10.sp,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================
// CONDITION CHIP - For Report Form
// =====================================
class ConditionChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const ConditionChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.body().copyWith(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textprimaryDark,
          ),
        ),
      ),
    );
  }
}

// =====================================
// ATTENDANCE ROW - Worker with Present/Late/Absent buttons
// =====================================
class AttendanceRow extends StatelessWidget {
  final String workerName;
  final String? selectedStatus;
  final Function(String) onStatusChanged;

  const AttendanceRow({
    Key? key,
    required this.workerName,
    required this.selectedStatus,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18.r,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              workerName.isNotEmpty ? workerName[0].toUpperCase() : 'W',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              workerName,
              style: AppTypography.title().copyWith(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildStatusButton('Present', 'present', AppColors.successText),
          SizedBox(width: 6.w),
          _buildStatusButton('Late', 'late', AppColors.warningText),
          SizedBox(width: 6.w),
          _buildStatusButton('Absent', 'absent', AppColors.danger),
        ],
      ),
    );
  }

  Widget _buildStatusButton(String label, String status, Color color) {
    final isActive = selectedStatus == status;
    return GestureDetector(
      onTap: () => onStatusChanged(status),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: isActive ? color : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: AppTypography.body().copyWith(
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// =====================================
// DETAIL ROW - Label + Value for confirmation screen
// =====================================
class DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const DetailRow({Key? key, required this.label, required this.value})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body().copyWith(
              fontSize: 13.sp,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.body().copyWith(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textprimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================
// SUPERVISOR ACTION BUTTON
// =====================================
class SupervisorActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isOutlined;

  const SupervisorActionButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isOutlined = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final txtColor = textColor ?? Colors.white;

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: 48.h,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: bgColor,
            side: BorderSide(color: bgColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            label,
            style: AppTypography.title().copyWith(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: bgColor,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 48.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: txtColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18.sp, color: txtColor),
              SizedBox(width: 8.w),
            ],
            Text(
              label,
              style: AppTypography.title().copyWith(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: txtColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================
// SUPERVISOR PANEL SCAFFOLD
// =====================================
class SupervisorPanelScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget body;
  final Widget? bottomBar;
  final List<Widget>? actions;
  final bool showBack;

  const SupervisorPanelScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.subtitle,
    this.bottomBar,
    this.actions,
    this.showBack = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      bottomNavigationBar: bottomBar,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 14.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.headerBlue, AppColors.headerBlueLight],
                ),
              ),
              child: Row(
                children: [
                  if (showBack)
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    )
                  else
                    SizedBox(width: 8.w),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.title().copyWith(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            subtitle!,
                            style: AppTypography.body().copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12.sp,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  ...(actions ?? []),
                ],
              ),
            ),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

// =====================================
// LOGOUT DIALOG
// =====================================
class LogoutDialog extends StatelessWidget {
  final VoidCallback onDismiss;
  final VoidCallback onLogout;

  const LogoutDialog({
    Key? key,
    required this.onDismiss,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you sure',
              style: AppTypography.title().copyWith(
                fontSize: 17.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40.h,
                    child: ElevatedButton(
                      onPressed: onDismiss,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFF2F4F8),
                        foregroundColor: const Color(0xFF9AA1AF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Dismiss',
                        style: AppTypography.title().copyWith(
                          fontSize: 13.sp,
                          color: const Color(0xFF9AA1AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: SizedBox(
                    height: 40.h,
                    child: ElevatedButton(
                      onPressed: onLogout,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFFF1616),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Logout',
                        style: AppTypography.title().copyWith(
                          fontSize: 13.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
