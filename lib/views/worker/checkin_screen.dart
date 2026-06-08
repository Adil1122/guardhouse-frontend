import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/routes/routes.dart';
import 'package:security_app/viewmodels/worker_panel_viewmodel.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';

class CheckinScreen extends StatelessWidget {
  const CheckinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workerViewModel = context.watch<WorkerViewModel>();

    if (workerViewModel.currentShift == null) {
      return Scaffold(
        backgroundColor: AppColors.dashboardBackground,
        body: Center(
          child: ElevatedButton(
            onPressed: () => context.push(Routes.workerStartShift),
            child: const Text('Start Shift'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: Stack(
        children: [
          _FakeDashboardBackground(),
          Container(color: const Color(0xCC000000)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 18.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Take Check-in Photo',
                    style: AppTypography.title().copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.infoBackground,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.infoBorder,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppColors.infoBorder,
                          size: 24.sp,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Photo evidence required',
                                style: AppTypography.body().copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.sp,
                                ),
                              ),
                              Text(
                                'Please take a photo as proof of presence',
                                style: AppTypography.body().copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 20.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 46.sp,
                          height: 46.sp,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt_outlined, size: 24.sp),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          'Tap to take photo',
                          style: AppTypography.body().copyWith(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Required for check-in',
                          style: AppTypography.body().copyWith(
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Photo will include timestamp and location',
                          style: AppTypography.body().copyWith(
                            fontSize: 11.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => context.pop(),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFFE5E7EB),
                            foregroundColor: AppColors.textSecondary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            minimumSize: Size.fromHeight(42.h),
                          ),
                          child: const Text('Dismiss'),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final ok = await context
                                .read<WorkerViewModel>()
                                .submitCheckin(
                                  location: 'Site Geofence',
                                  notes: 'Photo evidence uploaded',
                                  type: 'regular',
                                );
                            if (!context.mounted) return;
                            if (ok) {
                              context
                                  .read<WorkerPanelViewModel>()
                                  .setGeofenceStatus(true);
                              context.go(Routes.worker);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            minimumSize: Size.fromHeight(42.h),
                          ),
                          child: const Text('Upload'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FakeDashboardBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200.h,
          color: AppColors.primary,
          padding: EdgeInsets.fromLTRB(16.w, 50.h, 16.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: TextStyle(
                  color: AppColors.subTextOnPrimary,
                  fontSize: 12.sp,
                ),
              ),
              Text(
                'John Worker',
                style: TextStyle(color: Colors.white, fontSize: 22.sp),
              ),
              SizedBox(height: 18.h),
              Center(
                child: Text(
                  'Current Time\n6:32:48 PM',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 16.sp),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
