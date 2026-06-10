import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';

class WorkerOpsLiveScreen extends StatefulWidget {
  const WorkerOpsLiveScreen({super.key});

  @override
  State<WorkerOpsLiveScreen> createState() => _WorkerOpsLiveScreenState();
}

class _WorkerOpsLiveScreenState extends State<WorkerOpsLiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerViewModel>().loadLiveOperations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerViewModel>();
    final shifts = vm.liveShifts;
    final alerts = vm.liveAlerts;

    return WorkerPanelScaffold(
      title: 'Ops Live',
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => vm.loadLiveOperations(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(
                        title: 'Active Shifts at This Site',
                        count: shifts.length),
                    SizedBox(height: 10.h),
                    if (shifts.isEmpty)
                      const WorkerStatusBanner(
                        title: 'No Active Shifts',
                        subtitle: 'No officers are currently on duty.',
                        icon: Icons.people_outline,
                        variant: WorkerStatusVariant.info,
                      )
                    else
                      ...shifts.map(
                        (shift) => Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: _ShiftCard(shift: shift),
                        ),
                      ),
                    SizedBox(height: 8.h),
                    _SectionHeader(
                        title: 'Site Alerts', count: alerts.length),
                    SizedBox(height: 10.h),
                    if (alerts.isEmpty)
                      const WorkerStatusBanner(
                        title: 'No Active Alerts',
                        subtitle: 'All operations are running normally.',
                        icon: Icons.check_circle_outline,
                        variant: WorkerStatusVariant.success,
                      )
                    else
                      ...alerts.map(
                        (alert) => Padding(
                          padding: EdgeInsets.only(bottom: 10.h),
                          child: _AlertBanner(alert: alert),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert});

  final Map<String, dynamic> alert;

  @override
  Widget build(BuildContext context) {
    final severity =
        (alert['variant'] ?? alert['severity'] ?? 'warning').toString();
    final isCritical = severity == 'critical' || severity == 'danger';
    return WorkerStatusBanner(
      title: (alert['title'] ?? '').toString(),
      subtitle: (alert['message'] ?? '').toString(),
      icon: isCritical ? Icons.error_outline : Icons.warning_amber_outlined,
      variant: isCritical
          ? WorkerStatusVariant.danger
          : WorkerStatusVariant.warning,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: AppTypography.title().copyWith(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.actionButtonBackground,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            '$count',
            style: AppTypography.body().copyWith(
              fontSize: 11.sp,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift});

  final Map<String, dynamic> shift;

  String get _timeStr {
    if (shift['hours'] != null) return shift['hours'] as String;
    final s = shift['start'] ?? '';
    final e = shift['end'] ?? '';
    return s.isNotEmpty ? '$s – $e' : '';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'clocked-in':
        return AppColors.successText;
      case 'checking-welfare':
        return AppColors.warningText;
      case 'missed-alert':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'clocked-in':
        return AppColors.successBackground;
      case 'checking-welfare':
        return AppColors.warningBackground;
      case 'missed-alert':
        return AppColors.errorBackground;
      default:
        return AppColors.neutralIconBackground;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'clocked-in':
        return 'Clocked In';
      case 'checking-welfare':
        return 'Checking Welfare';
      case 'missed-alert':
        return 'Missed Beep';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (shift['status'] ?? '') as String;
    final role = (shift['role'] ?? '').toString();
    final timeStr = _timeStr;

    return WorkerPanelCard(
      child: Row(
        children: [
          Container(
            width: 40.sp,
            height: 40.sp,
            decoration: BoxDecoration(
              color: AppColors.actionButtonBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.person_outline,
                size: 22.sp, color: AppColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (shift['name'] ?? '').toString(),
                  style: AppTypography.body().copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  timeStr.isNotEmpty ? '$role  •  $timeStr' : role,
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
              color: _statusBg(status),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Text(
              _statusLabel(status),
              style: AppTypography.body().copyWith(
                fontSize: 10.sp,
                color: _statusColor(status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
