import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:security_app/routes/routes.dart';
import '../../viewmodels/supervisor_viewmodel.dart';
import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../widgets/supervisor_panel_components.dart';

class SiteVisitOffScreen extends StatefulWidget {
  const SiteVisitOffScreen({super.key});

  @override
  State<SiteVisitOffScreen> createState() => _SiteVisitOffScreenState();
}

class _SiteVisitOffScreenState extends State<SiteVisitOffScreen> {
  bool _isEndingVisit = false;

  @override
  Widget build(BuildContext context) {
    final supervisorViewModel = context.watch<SupervisorViewModel>();
    final activeVisit = supervisorViewModel.activeSiteVisit;

    final siteName = activeVisit?['site_name']?.toString() ?? activeVisit?['siteName']?.toString() ?? '';
    final siteAddress = activeVisit?['location']?.toString() ?? '';
    final workersCount = activeVisit?['assigned_workers']?.toString() ?? activeVisit?['workersCount']?.toString() ?? '0';

    return SupervisorPanelScaffold(
      title: 'Site Visit',
      subtitle: siteName,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOnSiteBanner(
              onTap: () => _switchToOffSite(supervisorViewModel),
            ),
            SizedBox(height: 16.h),

            _buildDurationCard(),
            SizedBox(height: 16.h),

            _buildSiteAndStatsCard(
              siteName: siteName,
              siteAddress: siteAddress,
              workersCount: workersCount,
              onTap: () => context.push(Routes.supervisorSiteVisitOn),
            ),
            SizedBox(height: 16.h),

            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton.icon(
                onPressed: () => context.push(Routes.supervisorReportForm),
                icon: Icon(
                  Icons.description_outlined,
                  color: Colors.white,
                  size: 20.sp,
                ),
                label: Text(
                  'Fill Site Report',
                  style: AppTypography.title().copyWith(
                    fontSize: 14.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workers On Duty',
                    style: AppTypography.title().copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  _buildWorkersList(supervisorViewModel),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchToOffSite(SupervisorViewModel viewModel) async {
    if (_isEndingVisit) return;
    setState(() => _isEndingVisit = true);

    context.go(Routes.supervisorSiteVisitOn);

    await viewModel.endSiteVisit(summary: 'Returned to off site');
  }

  Widget _buildOnSiteBanner({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isEndingVisit ? null : onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFCDEED4),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFF16A34A)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: const Color(0xFF16A34A),
                size: 28.sp,
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'On Site',
                    style: AppTypography.title().copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _isEndingVisit
                        ? 'Switching to off site...'
                        : 'Time tracking is active',
                    style: AppTypography.body().copyWith(
                      fontSize: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Container(
            width: 58.w,
            height: 58.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F4ED2),
              border: Border.all(color: const Color(0xFF4A7EF2), width: 2),
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: Colors.white,
              size: 30.sp,
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'Visit Duration',
            style: AppTypography.body().copyWith(
              fontSize: 14.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            '00:32:48',
            style: AppTypography.title().copyWith(
              fontSize: 42.sp,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            height: 1,
            color: Colors.white.withOpacity(0.2),
            margin: EdgeInsets.symmetric(horizontal: 8.w),
          ),
          SizedBox(height: 10.h),
          Text(
            'Started at 08:01:00 PM',
            style: AppTypography.body().copyWith(
              fontSize: 13.sp,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteAndStatsCard({
    required String siteName,
    required String siteAddress,
    required String workersCount,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCE5F6),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        siteName,
                        style: AppTypography.title().copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        siteAddress,
                        style: AppTypography.body().copyWith(
                          fontSize: 12.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F8),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          workersCount,
                          style: AppTypography.title().copyWith(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Active Workers',
                          style: AppTypography.body().copyWith(fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F8),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '40.71',
                          style: AppTypography.title().copyWith(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          'Latitude',
                          style: AppTypography.body().copyWith(fontSize: 12.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkersList(SupervisorViewModel viewModel) {
    final workers = viewModel.workers;

    final workerList = workers.isNotEmpty
        ? workers
        : [
            {'name': 'John Doe', 'sub': 'On duty', 'status': 'active'},
            {'name': 'John Doe 2', 'sub': 'On duty', 'status': 'active'},
            {'name': 'John Doe 3', 'sub': 'Off duty', 'status': 'inactive'},
          ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workerList.length,
      itemBuilder: (context, index) {
        final worker = workerList[index];
        final status = worker['status']?.toString() ?? 'active';
        final isOffDuty = status == 'inactive';

        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isOffDuty
                ? const Color(0xFFF5DDE0)
                : const Color(0xFFF2F4F8),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            children: [
              Container(
                width: 34.w,
                height: 34.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE5F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: AppColors.primary,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      worker['name']?.toString() ?? 'Unknown',
                      style: AppTypography.title().copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      worker['sub']?.toString() ??
                          (isOffDuty ? 'Off duty' : 'On duty'),
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 11.w,
                height: 11.w,
                decoration: BoxDecoration(
                  color: isOffDuty ? AppColors.danger : AppColors.successText,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
