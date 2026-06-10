import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/supervisor_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';

class SupervisorAlarmCallScreen extends StatefulWidget {
  const SupervisorAlarmCallScreen({super.key});

  @override
  State<SupervisorAlarmCallScreen> createState() =>
      _SupervisorAlarmCallScreenState();
}

class _SupervisorAlarmCallScreenState
    extends State<SupervisorAlarmCallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupervisorViewModel>().loadAlarmHistory();
    });
  }

  void _raiseAlarm() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetCtx) => WorkerBottomDualAction(
        leftLabel: 'Cancel',
        rightLabel: 'Confirm Alarm',
        rightVariant: WorkerButtonVariant.danger,
        onLeftTap: () => Navigator.of(sheetCtx).pop(),
        onRightTap: () {
          Navigator.of(sheetCtx).pop();
          context.read<SupervisorViewModel>().raiseAlarm();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Alarm raised – admin & operators notified'),
                backgroundColor: Color(0xFFE53E3E),
              ),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SupervisorViewModel>();
    final history = vm.alarmHistory;

    return WorkerPanelScaffold(
      title: 'Alarm Call',
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => vm.loadAlarmHistory(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WorkerPanelCard(
                      child: Column(
                        children: [
                          Container(
                            width: 56.sp,
                            height: 56.sp,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFEE2E2),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.campaign_outlined,
                              size: 30.sp,
                              color: AppColors.error,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Raise Alarm Call',
                            style: AppTypography.title().copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            'Use this only in an emergency situation.\nAdmin and operators will be notified immediately.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body().copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          SizedBox(
                            width: double.infinity,
                            child: WorkerActionButton(
                              label: 'Raise Alarm Call',
                              icon: Icons.campaign_outlined,
                              variant: WorkerButtonVariant.danger,
                              onTap: _raiseAlarm,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Alarm History',
                      style: AppTypography.title().copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    if (history.isEmpty)
                      const WorkerStatusBanner(
                        title: 'No Alarm Records',
                        subtitle: 'You have not raised any alarms.',
                        icon: Icons.check_circle_outline,
                        variant: WorkerStatusVariant.success,
                      )
                    else
                      WorkerPanelCard(
                        child: Column(
                          children: [
                            for (int i = 0; i < history.length; i++) ...[
                              _AlarmHistoryRow(entry: history[i]),
                              if (i < history.length - 1)
                                Divider(
                                    height: 1, color: AppColors.cardBorder),
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
}

class _AlarmHistoryRow extends StatelessWidget {
  const _AlarmHistoryRow({required this.entry});

  final Map<String, dynamic> entry;

  WorkerStatusVariant get _variant {
    switch ((entry['status'] ?? '').toString().toLowerCase()) {
      case 'raised':
        return WorkerStatusVariant.danger;
      case 'acknowledged':
        return WorkerStatusVariant.warning;
      case 'resolved':
        return WorkerStatusVariant.success;
      default:
        return WorkerStatusVariant.info;
    }
  }

  String get _statusLabel {
    final s = (entry['status'] ?? 'unknown').toString();
    if (s.isEmpty) return 'Unknown';
    return s[0].toUpperCase() + s.substring(1);
  }

  Color _variantColor(WorkerStatusVariant v) {
    switch (v) {
      case WorkerStatusVariant.success:
        return AppColors.successText;
      case WorkerStatusVariant.warning:
        return AppColors.warningText;
      case WorkerStatusVariant.danger:
        return AppColors.error;
      case WorkerStatusVariant.info:
        return AppColors.primary;
    }
  }

  Color _variantBg(WorkerStatusVariant v) {
    switch (v) {
      case WorkerStatusVariant.success:
        return AppColors.successBackground;
      case WorkerStatusVariant.warning:
        return AppColors.warningBackground;
      case WorkerStatusVariant.danger:
        return AppColors.errorBackground;
      case WorkerStatusVariant.info:
        return AppColors.infoBackground;
    }
  }

  @override
  Widget build(BuildContext context) {
    final variant = _variant;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        children: [
          Container(
            width: 36.sp,
            height: 36.sp,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.campaign_outlined,
                size: 18.sp, color: AppColors.error),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (entry['type'] ?? 'Alarm').toString(),
                  style: AppTypography.body().copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  (entry['timestamp'] ?? '').toString(),
                  style: AppTypography.body().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: _variantBg(variant),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              _statusLabel,
              style: AppTypography.body().copyWith(
                fontSize: 10.sp,
                color: _variantColor(variant),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
