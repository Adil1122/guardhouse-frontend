import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:security_app/routes/routes.dart';
import '../../viewmodels/supervisor_viewmodel.dart';
import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../widgets/supervisor_panel_components.dart';

class SiteVisitOnScreen extends StatefulWidget {
  const SiteVisitOnScreen({super.key});

  @override
  State<SiteVisitOnScreen> createState() => _SiteVisitOnScreenState();
}

class _SiteVisitOnScreenState extends State<SiteVisitOnScreen> {
  bool _isStartingVisit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupervisorViewModel>().loadAssignedSites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final supervisorViewModel = context.watch<SupervisorViewModel>();
    final sites = supervisorViewModel.assignedSites;
    final siteName = sites.isNotEmpty
        ? (sites[0]['name'] ?? 'Downtown Office')
        : 'Downtown Office';
    final siteAddress = sites.isNotEmpty
        ? (sites[0]['address'] ?? '123 Main Street, City')
        : '123 Main Street, City';
    final workersCount = sites.isNotEmpty
        ? (sites[0]['workersCount']?.toString() ?? '5')
        : '5';
    final siteId = sites.isNotEmpty ? (sites[0]['id']?.toString() ?? '1') : '1';

    return SupervisorPanelScaffold(
      title: 'Site Visit',
      subtitle: siteName,
      body: supervisorViewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOffSiteBanner(
                    onTap: () => _startSiteVisit(
                      viewModel: supervisorViewModel,
                      siteId: siteId,
                      siteAddress: sites.isNotEmpty
                          ? siteAddress
                          : '123 Main Street, City Center, NY 10001',
                    ),
                  ),
                  SizedBox(height: 16.h),

                  _buildSiteAndStatsCard(
                    siteName: siteName,
                    siteAddress: sites.isNotEmpty
                        ? siteAddress
                        : '123 Main Street, City Center, NY 10001',
                    workersCount: workersCount,
                  ),
                  SizedBox(height: 16.h),

                  SizedBox(
                    width: double.infinity,
                    height: 54.h,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          context.push(Routes.supervisorReportForm),
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
                        backgroundColor: const Color(0xFF88A8E8),
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
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFF2B6BFF),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2B6BFF),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.priority_high,
                              color: const Color(0xFF2B6BFF),
                              size: 18.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Automatic Time Tracking',
                                style: AppTypography.title().copyWith(
                                  fontSize: 14.sp,
                                  color: AppColors.textprimaryDark,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                'Your visit will start automatically when you enter the geofence radius. No manual action required.',
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
                  ),
                  SizedBox(height: 18.h),

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

  Future<void> _startSiteVisit({
    required SupervisorViewModel viewModel,
    required String siteId,
    required String siteAddress,
  }) async {
    if (_isStartingVisit) return;
    setState(() => _isStartingVisit = true);

    context.go(Routes.supervisorSiteVisitOff);

    await viewModel.startSiteVisit(
      siteId: siteId,
      location: siteAddress,
      purpose: 'Routine inspection',
    );
  }

  Widget _buildOffSiteBanner({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isStartingVisit ? null : onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: const Color(0xFFF5DDE0),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: const Color(0xFFFF2D20)),
          ),
          child: Row(
            children: [
              Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF2D20), width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.priority_high,
                    color: const Color(0xFFFF2D20),
                    size: 18.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Off Site',
                    style: AppTypography.title().copyWith(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _isStartingVisit
                        ? 'Starting visit...'
                        : 'Move to site to start tracking',
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

  Widget _buildSiteAndStatsCard({
    required String siteName,
    required String siteAddress,
    required String workersCount,
  }) {
    return Container(
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
    );
  }

  Widget _buildWorkersList(SupervisorViewModel viewModel) {
    final workers = viewModel.workers;

    // Use mock data if no workers loaded
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
