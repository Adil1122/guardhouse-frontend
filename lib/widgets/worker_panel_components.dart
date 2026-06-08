import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';

enum WorkerButtonVariant { primary, secondary, danger, neutral }

enum WorkerStatusVariant { info, success, warning, danger }

class WorkerPanelScaffold extends StatelessWidget {
  const WorkerPanelScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.showBack = true,
    this.actions = const [],
    this.bottomBar,
  });

  final String title;
  final String? subtitle;
  final bool showBack;
  final List<Widget> actions;
  final Widget body;
  final Widget? bottomBar;

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
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                      ),
                    )
                  else
                    SizedBox(width: 8.w),
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
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppTypography.body().copyWith(
                              color: AppColors.subTextOnPrimary,
                              fontSize: 12.sp,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ...actions,
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

class WorkerPanelCard extends StatelessWidget {
  const WorkerPanelCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderColor,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(14.sp),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor ?? AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

class WorkerActionButton extends StatelessWidget {
  const WorkerActionButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.iconWidget,
    this.variant = WorkerButtonVariant.primary,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Widget? iconWidget;
  final WorkerButtonVariant variant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final _WorkerButtonStyle style = _resolveStyle(variant);
    return SizedBox(
      height: compact ? 36.h : 44.h,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: style.background,
          foregroundColor: style.foreground,
          disabledBackgroundColor: style.background.withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
            side: BorderSide(color: style.border),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (iconWidget != null || icon != null) ...[
              iconWidget ?? Icon(icon, size: 16.sp),
              SizedBox(width: 6.w),
            ],
            Text(
              label,
              style: AppTypography.body().copyWith(
                fontSize: compact ? 12.sp : 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  _WorkerButtonStyle _resolveStyle(WorkerButtonVariant variant) {
    switch (variant) {
      case WorkerButtonVariant.secondary:
        return const _WorkerButtonStyle(
          background: AppColors.primary,
          foreground: Colors.white,
          border: AppColors.primary,
        );
      case WorkerButtonVariant.danger:
        return const _WorkerButtonStyle(
          background: AppColors.danger,
          foreground: Colors.white,
          border: AppColors.danger,
        );
      case WorkerButtonVariant.neutral:
        return const _WorkerButtonStyle(
          background: AppColors.background,
          foreground: AppColors.textSecondary,
          border: AppColors.cardBorder,
        );
      case WorkerButtonVariant.primary:
        return const _WorkerButtonStyle(
          background: AppColors.actionButtonBackground,
          foreground: AppColors.primary,
          border: AppColors.actionButtonBackground,
        );
    }
  }
}

class WorkerStatusBanner extends StatelessWidget {
  const WorkerStatusBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.info_outline,
    this.iconWidget,
    this.variant = WorkerStatusVariant.info,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? iconWidget;
  final WorkerStatusVariant variant;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = _palette(variant);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: WorkerPanelCard(
          backgroundColor: palette.background,
          borderColor: palette.border,
          child: Row(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  iconWidget ?? Icon(icon, color: palette.icon, size: 30.sp),
                ],
              ),
              SizedBox(width: 10.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.body().copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[SizedBox(width: 8.w), trailing!],
            ],
          ),
        ),
      ),
    );
  }

  _StatusPalette _palette(WorkerStatusVariant variant) {
    switch (variant) {
      case WorkerStatusVariant.success:
        return const _StatusPalette(
          background: AppColors.successBackground,
          border: AppColors.successBorder,
          icon: AppColors.successText,
        );
      case WorkerStatusVariant.warning:
        return const _StatusPalette(
          background: AppColors.warningBackground,
          border: AppColors.warningBorder,
          icon: AppColors.warningText,
        );
      case WorkerStatusVariant.danger:
        return const _StatusPalette(
          background: AppColors.geofenceBackground,
          border: AppColors.geofenceBorder,
          icon: AppColors.geofenceIcon,
        );
      case WorkerStatusVariant.info:
        return const _StatusPalette(
          background: AppColors.infoBackground,
          border: AppColors.infoBorder,
          icon: AppColors.infoBorder,
        );
    }
  }
}

class WorkerBottomDualAction extends StatelessWidget {
  const WorkerBottomDualAction({
    super.key,
    required this.leftLabel,
    required this.rightLabel,
    required this.onLeftTap,
    required this.onRightTap,
    this.rightVariant = WorkerButtonVariant.primary,
  });

  final String leftLabel;
  final String rightLabel;
  final VoidCallback onLeftTap;
  final VoidCallback onRightTap;
  final WorkerButtonVariant rightVariant;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      child: Row(
        children: [
          Expanded(
            child: WorkerActionButton(
              label: leftLabel,
              onTap: onLeftTap,
              variant: WorkerButtonVariant.neutral,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: WorkerActionButton(
              label: rightLabel,
              onTap: onRightTap,
              variant: rightVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class WorkerMiniStat extends StatelessWidget {
  const WorkerMiniStat({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTypography.title().copyWith(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: AppTypography.body().copyWith(
            color: AppColors.subTextOnPrimary,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }
}

class WorkerTimelineRow extends StatelessWidget {
  const WorkerTimelineRow({
    super.key,
    required this.time,
    required this.title,
    required this.subtitle,
    required this.variant,
  });

  final String time;
  final String title;
  final String subtitle;
  final WorkerStatusVariant variant;

  @override
  Widget build(BuildContext context) {
    final color = switch (variant) {
      WorkerStatusVariant.success => AppColors.successText,
      WorkerStatusVariant.warning => AppColors.warningText,
      WorkerStatusVariant.danger => AppColors.geofenceIcon,
      WorkerStatusVariant.info => AppColors.infoBorder,
    };

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 58.w,
            child: Text(
              time,
              style: AppTypography.body().copyWith(
                color: AppColors.textSecondary,
                fontSize: 11.sp,
              ),
            ),
          ),
          Container(
            width: 8.sp,
            height: 8.sp,
            margin: EdgeInsets.only(top: 4.h),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body().copyWith(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: AppTypography.body().copyWith(
                    fontSize: 11.sp,
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

class _WorkerButtonStyle {
  const _WorkerButtonStyle({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;
}

class _StatusPalette {
  const _StatusPalette({
    required this.background,
    required this.border,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color icon;
}
