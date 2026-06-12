import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:security_app/constants/app_constants.dart';
import 'package:security_app/constants/typography.dart';
import 'package:security_app/routes/routes.dart';
import 'package:security_app/viewmodels/auth_viewmodel.dart';
import 'package:security_app/viewmodels/worker_panel_viewmodel.dart';
import 'package:security_app/viewmodels/worker_viewmodel.dart';
import 'package:security_app/viewmodels/worker_geofence_viewmodel.dart';
import 'package:security_app/widgets/worker_panel_components.dart';
import 'package:security_app/widgets/supervisor_panel_components.dart';
import 'package:security_app/services/storage_service.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize storage service for worker panel view model
      final storageService = context.read<StorageService>();
      context.read<WorkerPanelViewModel>().initialize(storageService);
      
      // Initialize location service
      await context.read<WorkerPanelViewModel>().initializeLocationService();
      
      // Load dashboard data
      final workerViewModel = context.read<WorkerViewModel>();
      await workerViewModel.loadDashboardData();
      
      // Load current shift with geofence data
      final geofenceViewModel = context.read<WorkerGeofenceViewModel>();
      await geofenceViewModel.loadCurrentShift();
      
      if (!mounted) return;
      
      Map<String, dynamic>? shiftToSync = geofenceViewModel.currentShift;
      if (shiftToSync == null && workerViewModel.tasks.isNotEmpty) {
        shiftToSync = workerViewModel.tasks.first;
      }
      
      context.read<WorkerPanelViewModel>().syncGeofenceStatus(shiftToSync);
    });

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final workerViewModel = context.watch<WorkerViewModel>();
    final panelViewModel = context.watch<WorkerPanelViewModel>();
    final geofenceViewModel = context.watch<WorkerGeofenceViewModel>();

    final userName =
        authViewModel.currentUser?['fullName'] ??
        authViewModel.currentUser?['full_name'] ??
        'John Worker';
    Map<String, dynamic>? upcomingShift;
    if (workerViewModel.tasks.isNotEmpty) {
      upcomingShift = workerViewModel.tasks.first;
    }

    final fallbackSite = workerViewModel.availableSites.isNotEmpty 
        ? workerViewModel.availableSites.first 
        : null;

    final upcomingSiteName = upcomingShift?['site_name']?.toString() ?? '';
    final upcomingSiteAddress = upcomingShift?['site_address']?.toString() ?? '';

    final siteName =
        geofenceViewModel.currentShift?['site_name']?.toString() ??
        workerViewModel.currentShift?['siteName']?.toString() ??
        (upcomingSiteName.isNotEmpty ? upcomingSiteName : null) ??
        fallbackSite?['name']?.toString() ??
        'No Site Assigned';
        
    final siteAddress =
        geofenceViewModel.currentShift?['site_address']?.toString() ??
        workerViewModel.currentShift?['siteAddress']?.toString() ??
        (upcomingSiteAddress.isNotEmpty ? upcomingSiteAddress : null) ?? 
        fallbackSite?['address']?.toString() ??
        'Address: N/A';

    final bool onDuty = geofenceViewModel.currentShift != null;
    final bool insideGeofence = panelViewModel.isInsideGeofence;

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await workerViewModel.loadDashboardData();
            await geofenceViewModel.loadCurrentShift();
            if (!mounted) return;
            context.read<WorkerPanelViewModel>().syncGeofenceStatus(
              geofenceViewModel.currentShift,
            );
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(
                  userName: userName,
                  currentTime: _formatClock(_now),
                  notifications: workerViewModel.unreadNotifications,
                  onNotificationTap: () =>
                      context.push(Routes.workerNotifications),
                  onLogoutTap: () => _showLogoutSheet(context, authViewModel),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                  child: Column(
                    children: [
                      WorkerStatusBanner(
                        title: insideGeofence
                            ? 'Inside Geofence'
                            : 'Outside Geofence',
                        subtitle: insideGeofence
                            ? 'Time tracking is active'
                            : 'Move to site to start tracking',
                        iconWidget: SvgPicture.asset(
                          'assets/Icons/Iconerror.svg',
                          width: 30.sp,
                          height: 30.sp,
                          colorFilter: ColorFilter.mode(
                            insideGeofence ? AppColors.primary : Colors.red,
                            BlendMode.srcIn,
                          ),
                        ),
                        variant: insideGeofence
                            ? WorkerStatusVariant.success
                            : WorkerStatusVariant.danger,
                        onTap: () async {
                          if (!insideGeofence) {
                            context
                                .read<WorkerPanelViewModel>()
                                .setGeofenceStatus(true);
                            final workerVm = context.read<WorkerViewModel>();
                            if (workerVm.currentShift == null) {
                              final siteId = (upcomingShift?['site_id']?.toString() ?? '').isNotEmpty 
                                  ? upcomingShift!['site_id'].toString() 
                                  : (workerVm.availableSites.isNotEmpty
                                      ? workerVm.availableSites.first['id']?.toString() ?? ''
                                      : '');
                              
                              if (siteId.isNotEmpty) {
                                await workerVm.startShift(
                                  siteId: siteId,
                                  location: 'Site geofence',
                                  notes: 'Auto started from geofence entry',
                                );
                              }
                            }
                            return;
                          }
                          context.push(Routes.workerStartShift);
                        },
                      ),
                      SizedBox(height: 12.h),
                      if (onDuty || workerViewModel.tasks.isNotEmpty) ...[
                        WorkerPanelCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assigned Site',
                                style: AppTypography.body().copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12.sp,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                siteName,
                                style: AppTypography.title().copyWith(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 15.sp,
                                    color: AppColors.textSecondary,
                                  ),
                                  SizedBox(width: 4.w),
                                  Expanded(
                                    child: Text(
                                      siteAddress,
                                      style: AppTypography.body().copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),
                              SizedBox(
                                width: double.infinity,
                                child: WorkerActionButton(
                                  label: 'View Details',
                                  onTap: () =>
                                      context.push(Routes.workerStartShift),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],
                      if (insideGeofence || onDuty) ...[
                        WorkerPanelCard(
                          backgroundColor: AppColors.primary,
                          borderColor: AppColors.primary,
                          child: Column(
                            children: [
                              Icon(
                                Icons.watch_later_outlined,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                              SizedBox(height: 6.h),
                              Text(
                                'Time on Duty',
                                style: AppTypography.body().copyWith(
                                  color: AppColors.subTextOnPrimary,
                                  fontSize: 11.sp,
                                ),
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                _dutyDuration(
                                  workerViewModel.currentShift != null 
                                      ? workerViewModel.currentShift!['startTime'] ?? workerViewModel.currentShift!['start_time'] 
                                      : null,
                                ),
                                style: AppTypography.display().copyWith(
                                  color: Colors.white,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Divider(
                                color: Colors.white.withOpacity(0.25),
                                height: 1,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'Check-ins today: ${workerViewModel.totalCheckins}',
                                style: AppTypography.body().copyWith(
                                  color: AppColors.subTextOnPrimary,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!onDuty) ...[
                          SizedBox(height: 10.h),
                          SizedBox(
                            width: double.infinity,
                            child: WorkerActionButton(
                              label: 'Check In Now',
                              icon: Icons.check_circle_outline,
                              variant: WorkerButtonVariant.secondary,
                              onTap: () => context.push('/worker/enhanced-checkin'),
                            ),
                          ),
                        ],
                        if (onDuty) ...[
                          SizedBox(height: 8.h),
                          SizedBox(
                            width: double.infinity,
                            child: WorkerActionButton(
                              label: 'End Shift',
                              icon: Icons.stop_circle_outlined,
                              variant: WorkerButtonVariant.danger,
                              onTap: () {
                                final currentShiftId = geofenceViewModel.currentShift?['id']?.toString() ?? workerViewModel.currentShift?['id']?.toString() ?? '';
                                if (currentShiftId.isNotEmpty) {
                                  _showEndShiftDialog(context, workerViewModel, currentShiftId);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active shift to end')));
                                }
                              },
                            ),
                          ),
                          SizedBox(height: 10.h),
                        ],
                      ],
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardMiniAction(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'My Shifts',
                                  onTap: () => context.push(Routes.workerMyShifts),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _DashboardMiniAction(
                                  icon: Icons.work_outline,
                                  label: 'Offered Shifts',
                                  onTap: () => context.push(Routes.workerOfferedShifts),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardMiniAction(
                                  icon: Icons.check_circle_outline,
                                  label: 'Checkin',
                                  onTap: () => context.push('/worker/enhanced-checkin'),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _DashboardMiniAction(
                                  icon: Icons.health_and_safety_outlined,
                                  label: 'Check Call',
                                  onTap: () => context.push(Routes.workerCheckCall),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Expanded(
                                child: _DashboardMiniAction(
                                  icon: Icons.qr_code_scanner,
                                  label: 'Scan QR',
                                  onTap: () => context.push(Routes.workerQrScan),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: _DashboardMiniAction(
                                  icon: Icons.history,
                                  label: 'Duty History',
                                  onTap: () => context.push(Routes.workerHistory),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),
                      const WorkerStatusBanner(
                        title: 'Automatic Time Tracking',
                        subtitle:
                            'Your duty will start automatically when you enter the geofence radius.',
                        icon: Icons.info_outline,
                        variant: WorkerStatusVariant.info,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader({
    required String userName,
    required String currentTime,
    required int notifications,
    required VoidCallback onNotificationTap,
    required VoidCallback onLogoutTap,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.headerBlue, AppColors.headerBlueLight],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back',
                      style: AppTypography.body().copyWith(
                        color: AppColors.subTextOnPrimary,
                        fontSize: 12.sp,
                      ),
                    ),
                    Text(
                      userName,
                      style: AppTypography.title().copyWith(
                        color: Colors.white,
                        fontSize: 22.sp,
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: onNotificationTap,
                    icon: const Icon(
                      Icons.notifications_none,
                      color: Colors.white,
                    ),
                  ),
                  if (notifications > 0)
                    Positioned(
                      right: 2,
                      top: 1,
                      child: Container(
                        width: 15.sp,
                        height: 15.sp,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          notifications > 9 ? '9+' : '$notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                onPressed: onLogoutTap,
                icon: const Icon(Icons.logout, color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Current Time',
            style: AppTypography.body().copyWith(
              color: AppColors.subTextOnPrimary,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            currentTime,
            style: AppTypography.display().copyWith(
              color: Colors.white,
              fontSize: 30.sp,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEndShiftDialog(
    BuildContext context,
    WorkerViewModel workerViewModel,
    String shiftId,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('End Shift'),
          content: const Text('Are you sure you want to end your current shift?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                final ok = await workerViewModel.endShift(
                  shiftId: shiftId,
                  notes: 'Ended from dashboard',
                  hasIncidents: false,
                );
                if (!mounted) return;
                context.read<WorkerPanelViewModel>().syncGeofenceStatus(
                  workerViewModel.currentShift,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Shift ended' : 'Failed to end shift'),
                  ),
                );
              },
              child: const Text('End Shift'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLogoutSheet(
    BuildContext context,
    AuthViewModel authViewModel,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return LogoutDialog(
          onDismiss: () => Navigator.of(dialogContext).pop(),
          onLogout: () {
            Navigator.of(dialogContext).pop();
            authViewModel.logout();
            if (!mounted) return;
            context.go(Routes.login);
          },
        );
      },
    );
  }

  String _formatClock(DateTime dateTime) {
    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : (dateTime.hour == 0 ? 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $amPm';
  }

  String _dutyDuration(dynamic start) {
    final DateTime? startTime = start is DateTime
        ? start
        : DateTime.tryParse(start?.toString() ?? '');
    if (startTime == null) return '00:00:00';
    final diff = _now.difference(startTime);
    final hh = diff.inHours.toString().padLeft(2, '0');
    final mm = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
}

class _DashboardMiniAction extends StatelessWidget {
  const _DashboardMiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WorkerPanelCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  color: AppColors.neutralIconBackground,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, size: 18.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                style: AppTypography.body().copyWith(fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
