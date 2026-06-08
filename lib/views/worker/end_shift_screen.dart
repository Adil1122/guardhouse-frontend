import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:security_app/routes/routes.dart';
import 'package:security_app/viewmodels/worker_panel_viewmodel.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';

class EndShiftScreen extends StatelessWidget {
  const EndShiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workerViewModel = context.watch<WorkerViewModel>();

    if (workerViewModel.currentShift == null) {
      return WorkerPanelScaffold(
        title: 'End Shift',
        subtitle: 'No active duty session',
        body: ListView(
          padding: EdgeInsets.all(16.sp),
          children: const [
            WorkerStatusBanner(
              title: 'No active shift found',
              subtitle: 'You can return to dashboard.',
              variant: WorkerStatusVariant.warning,
              icon: Icons.work_off_outlined,
            ),
          ],
        ),
      );
    }

    final shift = workerViewModel.currentShift!;

    return WorkerPanelScaffold(
      title: 'End Shift',
      subtitle: 'Confirm your action',
      body: ListView(
        padding: EdgeInsets.all(16.sp),
        children: [
          WorkerPanelCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Site: ${shift['siteName'] ?? 'Downtown Office'}'),
                SizedBox(height: 6.h),
                Text('Started: ${_format(shift['startTime'])}'),
                SizedBox(height: 6.h),
                Text('Last Check-in: ${_format(shift['lastCheckin'])}'),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          const WorkerStatusBanner(
            title: 'Are you sure?',
            subtitle: 'Ending shift stops tracking and closes your session.',
            variant: WorkerStatusVariant.warning,
            icon: Icons.help_outline,
          ),
        ],
      ),
      bottomBar: WorkerBottomDualAction(
        leftLabel: 'Dismiss',
        rightLabel: 'End Shift',
        rightVariant: WorkerButtonVariant.danger,
        onLeftTap: () => Navigator.of(context).pop(),
        onRightTap: () async {
          final ok = await context.read<WorkerViewModel>().endShift(
            notes: 'Ended by worker',
            hasIncidents: false,
          );
          if (!context.mounted) return;
          context.read<WorkerPanelViewModel>().syncGeofenceStatus(
            context.read<WorkerViewModel>().currentShift,
          );
          if (ok) {
            context.go(Routes.worker);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok ? 'Shift ended successfully' : 'Failed to end shift',
              ),
            ),
          );
        },
      ),
    );
  }

  String _format(dynamic value) {
    final date = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '');
    if (date == null) return 'N/A';
    final h = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final m = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
}
