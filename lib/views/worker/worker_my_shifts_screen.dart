import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';

class WorkerMyShiftsScreen extends StatefulWidget {
  const WorkerMyShiftsScreen({super.key});

  @override
  State<WorkerMyShiftsScreen> createState() => _WorkerMyShiftsScreenState();
}

class _WorkerMyShiftsScreenState extends State<WorkerMyShiftsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerViewModel>().loadDutyHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerViewModel>();
    final shifts = vm.shiftHistory;

    return WorkerPanelScaffold(
      title: 'My Shifts',
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shifts.isEmpty
              ? const WorkerStatusBanner(
                  title: 'No Shifts Found',
                  subtitle: 'You have no shift records yet.',
                  icon: Icons.event_busy_outlined,
                  variant: WorkerStatusVariant.info,
                )
              : RefreshIndicator(
                  onRefresh: () => vm.loadDutyHistory(),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    itemCount: shifts.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, i) => _ShiftCard(shift: shifts[i]),
                  ),
                ),
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift});

  final Map<String, dynamic> shift;

  String get _siteName =>
      (shift['siteName'] ?? shift['site_name'] ?? 'Unknown Site') as String;

  String get _dateStr {
    final d = shift['date'];
    if (d == null) return '';
    if (d is DateTime) return '${_monthName(d.month)} ${d.day}';
    try {
      final dt = DateTime.parse(d.toString());
      return '${_monthName(dt.month)} ${dt.day}';
    } catch (_) {
      return d.toString();
    }
  }

  String get _timeStr {
    final start = shift['startTime'] ?? shift['start_time'];
    final end = shift['endTime'] ?? shift['end_time'];
    if (start == null) return (shift['time'] ?? '').toString();
    return '${_fmtTime(start)} – ${_fmtTime(end)}';
  }

  String _fmtTime(dynamic t) {
    if (t is DateTime) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return t.toString();
  }

  static String _monthName(int m) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return m >= 1 && m <= 12 ? names[m - 1] : '';
  }

  String get _statusLabel {
    final s = (shift['status'] ?? 'unknown').toString();
    if (s.isEmpty) return 'Unknown';
    return s[0].toUpperCase() + s.substring(1);
  }

  WorkerStatusVariant get _statusVariant {
    switch ((shift['status'] ?? '').toString().toLowerCase()) {
      case 'active':
        return WorkerStatusVariant.success;
      case 'upcoming':
        return WorkerStatusVariant.info;
      case 'completed':
        return WorkerStatusVariant.warning;
      default:
        return WorkerStatusVariant.info;
    }
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
    final variant = _statusVariant;
    return WorkerPanelCard(
      child: Row(
        children: [
          Container(
            width: 42.sp,
            height: 42.sp,
            decoration: BoxDecoration(
              color: AppColors.neutralIconBackground,
              borderRadius: BorderRadius.circular(10.r),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.calendar_today_outlined,
                size: 20.sp, color: AppColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _siteName,
                  style: AppTypography.body().copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _dateStr,
                  style: AppTypography.body().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 12.sp, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text(
                      _timeStr,
                      style: AppTypography.body().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
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
