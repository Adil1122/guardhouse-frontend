import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';

class WorkerCheckCallScreen extends StatefulWidget {
  const WorkerCheckCallScreen({super.key});

  @override
  State<WorkerCheckCallScreen> createState() => _WorkerCheckCallScreenState();
}

class _WorkerCheckCallScreenState extends State<WorkerCheckCallScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerViewModel>().loadCheckCalls();
    });
  }

  void _confirmOk(WorkerViewModel vm) {
    final id = vm.pendingCheckCallId;
    if (id == null) return;
    vm.respondToCheckCall(id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Check call confirmed – you are marked safe'),
        backgroundColor: AppColors.successText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerViewModel>();
    final hasPending = vm.hasPendingCheckCall;
    final history = vm.checkCalls
        .where((c) => (c['status'] ?? '') != 'pending')
        .toList();

    return WorkerPanelScaffold(
      title: 'Check Call',
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => vm.loadCheckCalls(),
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
                            decoration: BoxDecoration(
                              color: AppColors.infoBackground,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.health_and_safety_outlined,
                              size: 30.sp,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            hasPending ? 'Welfare Check Pending' : 'All Clear',
                            style: AppTypography.title().copyWith(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            hasPending
                                ? 'Your supervisor has requested a welfare check.\nPlease confirm you are safe and well.'
                                : 'No pending welfare checks. You are marked as safe.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body().copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 16.h),
                          if (hasPending)
                            SizedBox(
                              width: double.infinity,
                              child: WorkerActionButton(
                                label: "I'm OK – Confirm Check Call",
                                icon: Icons.check_circle_outline,
                                onTap: () => _confirmOk(vm),
                              ),
                            )
                          else
                            WorkerStatusBanner(
                              title: 'No pending checks',
                              subtitle:
                                  'You will be notified when a check is required.',
                              icon: Icons.notifications_none_outlined,
                              variant: WorkerStatusVariant.info,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Check Call History',
                      style: AppTypography.title().copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    if (history.isEmpty)
                      const WorkerStatusBanner(
                        title: 'No History',
                        subtitle: 'No check calls have been recorded yet.',
                        icon: Icons.history_outlined,
                        variant: WorkerStatusVariant.info,
                      )
                    else
                      WorkerPanelCard(
                        child: Column(
                          children: [
                            for (int i = 0; i < history.length; i++) ...[
                              _CheckHistoryRow(entry: history[i]),
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

class _CheckHistoryRow extends StatelessWidget {
  const _CheckHistoryRow({required this.entry});

  final Map<String, dynamic> entry;

  WorkerStatusVariant get _variant {
    switch ((entry['status'] ?? '').toString().toLowerCase()) {
      case 'responded':
        return WorkerStatusVariant.success;
      case 'missed':
        return WorkerStatusVariant.danger;
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
            decoration: BoxDecoration(
              color: AppColors.infoBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.health_and_safety_outlined,
                size: 18.sp, color: AppColors.primary),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welfare Check',
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
