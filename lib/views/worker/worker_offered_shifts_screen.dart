import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';

class WorkerOfferedShiftsScreen extends StatefulWidget {
  const WorkerOfferedShiftsScreen({super.key});

  @override
  State<WorkerOfferedShiftsScreen> createState() =>
      _WorkerOfferedShiftsScreenState();
}

class _WorkerOfferedShiftsScreenState
    extends State<WorkerOfferedShiftsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkerViewModel>().loadOfferedShifts();
    });
  }

  Future<void> _accept(WorkerViewModel vm, String id) async {
    final ok = await vm.acceptShift(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Shift accepted successfully' : 'Failed to accept shift'),
        backgroundColor: ok ? AppColors.successText : AppColors.error,
      ),
    );
    if (ok) {
      await vm.loadOfferedShifts();
      await vm.loadMyShifts();
    }
  }

  Future<void> _decline(WorkerViewModel vm, String id) async {
    final ok = await vm.declineShift(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Shift declined' : 'Failed to decline shift'),
        backgroundColor: ok ? AppColors.textSecondary : AppColors.error,
      ),
    );
    if (ok) {
      await vm.loadOfferedShifts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<WorkerViewModel>();
    final shifts = vm.offeredShifts;

    return WorkerPanelScaffold(
      title: 'Offered Shifts',
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : shifts.isEmpty
              ? const WorkerStatusBanner(
                  title: 'No Offered Shifts',
                  subtitle: 'There are no shifts available for you right now.',
                  icon: Icons.event_busy_outlined,
                  variant: WorkerStatusVariant.info,
                )
              : RefreshIndicator(
                  onRefresh: () => vm.loadOfferedShifts(),
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
                    itemCount: shifts.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, i) {
                      final shift = shifts[i];
                      final id = shift['id']?.toString() ?? '$i';
                      return _OfferedShiftCard(
                        shift: shift,
                        onAccept: () => _accept(vm, id),
                        onDecline: () => _decline(vm, id),
                      );
                    },
                  ),
                ),
    );
  }
}

class _OfferedShiftCard extends StatelessWidget {
  const _OfferedShiftCard({
    required this.shift,
    required this.onAccept,
    required this.onDecline,
  });

  final Map<String, dynamic> shift;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final siteName =
        (shift['siteName'] ?? shift['site_name'] ?? '') as String;
    final date = (shift['date'] ?? '') as String;
    final time = (shift['time'] ?? '') as String;
    final hours = (shift['hours'] ?? '') as String;
    final payNote = (shift['payNote'] ?? shift['pay_note'] ?? '') as String;

    return WorkerPanelCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40.sp,
                height: 40.sp,
                decoration: BoxDecoration(
                  color: AppColors.infoBackground,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.work_outline,
                    size: 20.sp, color: AppColors.primary),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      siteName,
                      style: AppTypography.body().copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      date,
                      style: AppTypography.body().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.infoBackground,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  hours,
                  style: AppTypography.body().copyWith(
                    fontSize: 10.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Divider(height: 1, color: AppColors.cardBorder),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 13.sp, color: AppColors.textSecondary),
              SizedBox(width: 4.w),
              Text(
                time,
                style: AppTypography.body().copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Icon(Icons.monetization_on_outlined,
                  size: 13.sp, color: AppColors.textSecondary),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  payNote,
                  style: AppTypography.body().copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: WorkerActionButton(
                  label: 'Decline',
                  variant: WorkerButtonVariant.secondary,
                  onTap: onDecline,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: WorkerActionButton(
                  label: 'Accept',
                  icon: Icons.check_circle_outline,
                  onTap: onAccept,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
