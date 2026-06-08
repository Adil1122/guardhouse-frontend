import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:security_app/routes/routes.dart';
import 'package:security_app/widgets/supervisor_panel_components.dart';
import '../../viewmodels/supervisor_viewmodel.dart';
import '../../constants/app_constants.dart';
import '../../constants/typography.dart';

class SiteReportConfirmationScreen extends StatefulWidget {
  final String reportId;

  const SiteReportConfirmationScreen({super.key, required this.reportId});

  @override
  State<SiteReportConfirmationScreen> createState() =>
      _SiteReportConfirmationScreenState();
}

class _SiteReportConfirmationScreenState
    extends State<SiteReportConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupervisorViewModel>().loadReportDetails(widget.reportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final supervisorViewModel = context.watch<SupervisorViewModel>();
    final report = supervisorViewModel.selectedReport;

    if (supervisorViewModel.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.dashboardBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: Stack(
        children: [
          SupervisorPanelScaffold(
            title: 'Site Report Form',
            subtitle: 'Dynamic submission',
            body: Container(),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.55)),
          ),
          Center(
            child: Container(
              width: 0.9.sw,
              padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42.w,
                    height: 42.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF12B339),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.check,
                      color: const Color(0xFF12B339),
                      size: 28.sp,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Report Submitted!',
                    style: AppTypography.title().copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Your site report has been successfully\nsubmitted and recorded in the system.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body().copyWith(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F8),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildModalRow(
                          'Submitted at:',
                          report != null
                              ? _formatTime(report['submittedAt'])
                              : _formatTime(DateTime.now()),
                        ),
                        SizedBox(height: 6.h),
                        _buildModalRow(
                          'Report ID:',
                          report?['id']?.toString() ?? widget.reportId,
                        ),
                        SizedBox(height: 6.h),
                        _buildModalRow('Status:', 'Confirmed'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    height: 46.h,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.go(Routes.supervisorSiteVisitOff),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      child: Text(
                        'Back to Active Site',
                        style: AppTypography.title().copyWith(
                          fontSize: 16.sp,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.body().copyWith(
              fontSize: 12.sp,
              color: AppColors.textprimaryDark,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.body().copyWith(
            fontSize: 12.sp,
            color: AppColors.textprimaryDark,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatTime(dynamic dateTime) {
    if (dateTime == null) return 'Just now';
    if (dateTime is DateTime) {
      final h = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
      final m = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '${h.toString().padLeft(2, '0')}:$m $period';
    }
    return dateTime.toString();
  }
}
