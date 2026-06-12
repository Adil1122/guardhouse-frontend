import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/routes/routes.dart';
import 'package:security_app/viewmodels/worker_panel_viewmodel.dart';
import 'package:security_app/viewmodels/worker_geofence_viewmodel.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';

class ShiftStartScreen extends StatefulWidget {
  const ShiftStartScreen({super.key});

  @override
  State<ShiftStartScreen> createState() => _ShiftStartScreenState();
}

class _ShiftStartScreenState extends State<ShiftStartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final workerViewModel = context.read<WorkerViewModel>();
      if (workerViewModel.tasks.isEmpty) {
        await workerViewModel.loadDashboardData();
      }
      if (workerViewModel.tasks.isNotEmpty) {
        final shift = workerViewModel.tasks.first;
        if (shift['geofence'] != null) {
          context.read<WorkerPanelViewModel>().syncGeofenceStatus(shift);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final workerViewModel = context.watch<WorkerViewModel>();
    final panelViewModel = context.watch<WorkerPanelViewModel>();
    final geofenceViewModel = context.watch<WorkerGeofenceViewModel>();

    Map<String, dynamic>? upcomingShift;
    if (workerViewModel.tasks.isNotEmpty) {
      upcomingShift = workerViewModel.tasks.first;
    }
    
    final fallbackSite = workerViewModel.availableSites.isNotEmpty 
        ? workerViewModel.availableSites.first 
        : null;

    final upcomingSiteName = upcomingShift?['site_name']?.toString() ?? '';
    final upcomingSiteAddress = upcomingShift?['site_address']?.toString() ?? '';

    final siteName = upcomingSiteName.isNotEmpty ? upcomingSiteName : (fallbackSite?['name']?.toString() ?? 'No Site Assigned');
    final siteAddress = upcomingSiteAddress.isNotEmpty ? upcomingSiteAddress : (fallbackSite?['address']?.toString() ?? 'Address: N/A');
    
    // Extract geofence data from the shift, or fallback to the site's geofence if available
    final geofenceData = (upcomingShift?['geofence'] ?? fallbackSite?['geofence']) as Map<String, dynamic>?;
    final geofenceRadius = geofenceData != null ? geofenceData['check_in_distance']?.toString() ?? '100' : '100';
    final geofenceLat = geofenceData?['lat']?.toString() ?? '0.0';
    final geofenceLon = geofenceData?['lon']?.toString() ?? '0.0';
    final isInsideGeofence = panelViewModel.isInsideGeofence;

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: 'Assigned Site',
              subtitle: 'Details & location',
              onBack: () => context.pop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.sp),
                child: Column(
                  children: [
                    _StatusCard(isInside: panelViewModel.isInsideGeofence),
                    SizedBox(height: 12.h),
                    _SiteInfoCard(
                      siteName: siteName, 
                      siteAddress: siteAddress,
                      geofenceRadius: geofenceRadius,
                      geofenceLat: geofenceLat,
                      geofenceLon: geofenceLon,
                    ),
                    SizedBox(height: 12.h),
                    _MapCard(isInside: panelViewModel.isInsideGeofence),
                    SizedBox(height: 16.h),
                    if (isInsideGeofence && geofenceViewModel.currentShift == null)
                      SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.push(Routes.workerCheckin),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          minimumSize: Size.fromHeight(44.h),
                        ),
                        child: Text(
                          'Check In Now',
                          style: AppTypography.body().copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14.sp,
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
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12.w, 14.h, 12.w, 16.h),
      color: AppColors.primary,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          SizedBox(width: 4.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.title().copyWith(
                  color: Colors.white,
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.body().copyWith(
                  color: AppColors.subTextOnPrimary,
                  fontSize: 18.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.isInside});

  final bool isInside;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F3DF),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFF16A34A)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.pin_drop_outlined,
            color: const Color(0xFF16A34A),
            size: 26.sp,
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isInside ? 'Inside Geofence' : 'Outside Geofence',
                style: AppTypography.body().copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              Text(
                isInside
                    ? 'Time tracking is active'
                    : 'Move to site to start tracking',
                style: AppTypography.body().copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SiteInfoCard extends StatelessWidget {
  const _SiteInfoCard({
    required this.siteName, 
    required this.siteAddress,
    required this.geofenceRadius,
    required this.geofenceLat,
    required this.geofenceLon,
  });

  final String siteName;
  final String siteAddress;
  final String geofenceRadius;
  final String geofenceLat;
  final String geofenceLon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.sp),
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
                width: 42.sp,
                height: 42.sp,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F0FF),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primary,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      siteName,
                      style: AppTypography.body().copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                    Text(
                      siteAddress,
                      style: AppTypography.body().copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          _MetricRow(label: 'Notes', value: 'Assigned Site Location'),
          SizedBox(height: 8.h),
          _MetricRow(label: 'Geofence Radius', value: '${geofenceRadius}m'),
          SizedBox(height: 8.h),
          _MetricRow(label: 'Geofence Coordinates', value: '$geofenceLat, $geofenceLon'),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body().copyWith(fontSize: 11.sp),
            ),
          ),
          if (value.isNotEmpty)
            Text(value, style: AppTypography.body().copyWith(fontSize: 11.sp)),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  const _MapCard({required this.isInside});

  final bool isInside;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Site location & Geofence',
            style: AppTypography.body().copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 2.h),
          RichText(
            text: TextSpan(
              style: AppTypography.body().copyWith(fontSize: 11.sp),
              children: [
                const TextSpan(
                  text: 'Your Status: ',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                TextSpan(
                  text: isInside ? 'Inside' : 'Outside',
                  style: TextStyle(
                    color: isInside
                        ? const Color(0xFF16A34A)
                        : AppColors.danger,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            height: 220.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              color: const Color(0xFFE9ECEF),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _MapPatternPainter()),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 34.sp,
                    height: 34.sp,
                    decoration: const BoxDecoration(
                      color: Colors.pink,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'Note: Time tracking works only when you are inside the geofence radius',
            style: AppTypography.body().copyWith(
              color: AppColors.textSecondary,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()..color = const Color(0xFFD8DEE8);
    final line = Paint()
      ..color = const Color(0xFFBFC7D2)
      ..strokeWidth = 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), road);
    canvas.drawLine(
      Offset(0, size.height * 0.35),
      Offset(size.width, size.height * 0.35),
      line,
    );
    canvas.drawLine(
      Offset(size.width * 0.15, 0),
      Offset(size.width * 0.35, size.height),
      line,
    );
    canvas.drawLine(
      Offset(size.width * 0.7, 0),
      Offset(size.width * 0.95, size.height),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
