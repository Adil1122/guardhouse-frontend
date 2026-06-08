import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';

class WorkerDashboardHeader extends StatelessWidget {
  const WorkerDashboardHeader({
    super.key,
    required this.userName,
    required this.currentTime,
    required this.notificationCount,
    required this.onNotificationsTap,
    required this.onLogoutTap,
  });

  final String userName;
  final String currentTime;
  final int notificationCount;
  final VoidCallback onNotificationsTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 26.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.headerBlue, AppColors.headerBlueLight],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: AppTypography.body().copyWith(
                        color: AppColors.subTextOnPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      userName,
                      style: AppTypography.title().copyWith(
                        color: AppColors.textOnPrimary,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _IconWithBadge(
                icon: Icons.notifications_none,
                badgeCount: notificationCount,
                onTap: onNotificationsTap,
              ),
              SizedBox(width: 14.w),
              _HeaderIconButton(icon: Icons.logout, onTap: onLogoutTap),
            ],
          ),
          SizedBox(height: 28.h),
          Text(
            'Current Time',
            style: AppTypography.body().copyWith(
              color: AppColors.subTextOnPrimary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            currentTime,
            style: AppTypography.display().copyWith(
              color: AppColors.textOnPrimary,
              fontSize: 34.sp,
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class GeofenceAlertCard extends StatelessWidget {
  const GeofenceAlertCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.geofenceBackground,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.geofenceBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.geofenceIcon, size: 36.sp),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.title().copyWith(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: AppTypography.body().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
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

class AssignedSiteCard extends StatelessWidget {
  const AssignedSiteCard({
    super.key,
    required this.siteName,
    required this.siteAddress,
    required this.onDetailsTap,
  });

  final String siteName;
  final String siteAddress;
  final VoidCallback onDetailsTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(18.sp),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned Site',
            style: AppTypography.body().copyWith(
              color: AppColors.textSecondary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            siteName,
            style: AppTypography.title().copyWith(
              fontSize: 22.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.textSecondary,
                size: 22.sp,
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  siteAddress,
                  style: AppTypography.body().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onDetailsTap,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.actionButtonBackground,
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'View Details',
                style: AppTypography.body().copyWith(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkerActionTile extends StatelessWidget {
  const WorkerActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          height: 126.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48.sp,
                height: 48.sp,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  color: AppColors.neutralIconBackground,
                ),
                child: Icon(
                  icon,
                  size: 25.sp,
                  color: AppColors.textprimaryDark,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                label,
                style: AppTypography.body().copyWith(
                  fontSize: 14.sp,
                  color: AppColors.textprimaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardInfoCard extends StatelessWidget {
  const DashboardInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.infoBorder, size: 34.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.title().copyWith(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: AppTypography.body().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13.sp,
                    height: 1.3,
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

class _IconWithBadge extends StatelessWidget {
  const _IconWithBadge({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });

  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HeaderIconButton(icon: icon, onTap: onTap),
        if (badgeCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 20.sp,
              height: 20.sp,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeCount > 9 ? '9+' : '$badgeCount',
                style: AppTypography.body().copyWith(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.all(2.sp),
          child: Icon(icon, color: Colors.white, size: 25.sp),
        ),
      ),
    );
  }
}
