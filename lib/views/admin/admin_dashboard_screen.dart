import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:security_app/routes/routes.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../widgets/supervisor_panel_components.dart';
import '../../viewmodels/admin_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'invoice_management_screen.dart';
import 'digital_occurrence_log_management_screen.dart';
import 'pay_group_management_screen.dart';
import 'service_group_management_screen.dart';
import 'form_template_management_screen.dart';
import 'organization_compliance_management_screen.dart';
import 'company_settings_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminViewModel>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final adminViewModel = context.watch<AdminViewModel>();

    final userName =
        authViewModel.currentUser?['fullName'] ??
        authViewModel.currentUser?['full_name'] ??
        'Admin User';
    final totalUsers = adminViewModel.systemStatistics?['totalUsers']?.toString() ??
        adminViewModel.staffMembers.length.toString();
    final activeSites = adminViewModel.systemStatistics?['totalSites']?.toString() ??
        adminViewModel.sites.length.toString();
    final onDutyNow = adminViewModel.systemStatistics?['staffOnDuty']?.toString() ??
        adminViewModel.systemStatistics?['onDutyNow']?.toString() ??
        '0';
    final activeAlerts = adminViewModel.systemStatistics?['openAlerts']?.toString() ??
        adminViewModel.alerts.length.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: SafeArea(
        child: adminViewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => adminViewModel.refresh(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(userName, authViewModel),
                      SizedBox(height: 18.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: _buildStatGrid(
                          totalUsers: totalUsers,
                          activeSites: activeSites,
                          onDutyNow: onDutyNow,
                          activeAlerts: activeAlerts,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'My Sites',
                          style: AppTypography.title().copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textprimaryDark,
                          ),
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Column(
                          children: [
                            _buildAdminActionCard(
                              icon: Icons.badge_outlined,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Staff Management',
                              subtitle:
                                  'Manage staff details, privileges & wages',
                              onTap: () => context.push(Routes.adminStaff),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.business,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Customer Management',
                              subtitle:
                                  'Manage customers, contacts & invoicing',
                              onTap: () => context.push(Routes.adminCustomers),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.location_on_outlined,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Site Management',
                              subtitle:
                                  'Create site, defines redius & assign workers',
                              onTap: () => context.push(Routes.adminSites),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.access_time,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Timesheet Management',
                              subtitle: 'Review & approve staff timesheets',
                              onTap: () => context.push(Routes.adminTimesheets),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.schedule,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Shift Management',
                              subtitle:
                                  'Schedule shifts, assign officers & notes',
                              onTap: () => context.push(Routes.adminShifts),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.live_tv,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Live Operations',
                              subtitle:
                                  'Monitor real-time shift status & operations',
                              onTap: () =>
                                  context.push(Routes.adminLiveOperations),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.campaign_outlined,
                              iconBg: const Color(0xFFDC2626),
                              title: 'Alarm Call',
                              subtitle:
                                  'Raise an emergency alarm – supervisors & operators notified',
                              onTap: () =>
                                  context.push(Routes.adminAlarmCall),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.message_outlined,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Team Messages',
                              subtitle:
                                  'Send announcements to all workers & supervisors',
                              onTap: () =>
                                  context.push(Routes.adminTeamMessages),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.receipt_long,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Invoice Management',
                              subtitle: 'Create & manage customer invoices',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const InvoiceManagementScreen(),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.assignment_outlined,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Digital Occurrence Logs',
                              subtitle: 'Track & manage facility incidents',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const DigitalOccurrenceLogManagementScreen(),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.attach_money_outlined,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Pay Groups Management',
                              subtitle:
                                  'Manage pay groups & rates configuration',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PayGroupManagementScreen(),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.miscellaneous_services_outlined,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Service Groups Management',
                              subtitle:
                                  'Manage service groups & rates configuration',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ServiceGroupManagementScreen(),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.dynamic_form_outlined,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Form Templates',
                              subtitle:
                                  'Create templates with dynamic custom fields',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const FormTemplateManagementScreen(),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.verified_user_outlined,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Organization Compliances',
                              subtitle:
                                  'Manage compliance requirements & reminders',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OrganizationComplianceManagementScreen(),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            _buildAdminActionCard(
                              icon: Icons.settings_outlined,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Company Settings',
                              subtitle:
                                  'Configure logs, auth, sorting, defaults & alerts',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CompanySettingsScreen(),
                                ),
                              ),
                            ),
                            // SizedBox(height: 8.h),
                            // _buildAdminActionCard(
                            //   icon: Icons.description_outlined,
                            //   iconBg: const Color(0xFF0E45BA),
                            //   title: 'Reports & Analytics',
                            //   subtitle: 'View hours, compliance & audit logs',
                            //   onTap: () => context.push(Routes.adminReports),
                            // ),
                            // SizedBox(height: 8.h),
                            // _buildAdminActionCard(
                            //   icon: Icons.notifications_none,
                            //   iconBg: const Color(0xFF0E45BA),
                            //   title: 'Alert & Notifications',
                            //   subtitle: 'Monitor violations & missed check-ins',
                            //   onTap: () => context.push(Routes.adminAlerts),
                            // ),
                            SizedBox(height: 16.h),
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

  Widget _buildHeader(String userName, AuthViewModel authViewModel) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 18.h, 16.w, 28.h),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.headerBlue, AppColors.headerBlueLight],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Administrator',
                      style: AppTypography.body().copyWith(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.85),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      userName,
                      style: AppTypography.title().copyWith(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push(Routes.adminAlerts),
                child: Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 14.w),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => LogoutDialog(
                      onDismiss: () => Navigator.of(context).pop(),
                      onLogout: () {
                        Navigator.of(context).pop();
                        authViewModel.logout();
                        if (!mounted) return;
                        context.go(Routes.login);
                      },
                    ),
                  );
                },
                child: Icon(Icons.logout, color: Colors.white, size: 22.sp),
              ),
            ],
          ),
          SizedBox(height: 26.h),
          Center(
            child: Text(
              'System Status',
              style: AppTypography.body().copyWith(
                fontSize: 13.sp,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'All Systems Operational',
                style: AppTypography.title().copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid({
    required String totalUsers,
    required String activeSites,
    required String onDutyNow,
    required String activeAlerts,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 0.95,
      children: [
        _buildStatCard(
          icon: Icons.group_outlined,
          iconColor: const Color(0xFF111111),
          iconBg: const Color(0xFFE9ECF1),
          value: totalUsers,
          label: 'Total Users',
        ),
        _buildStatCard(
          icon: Icons.location_on_outlined,
          iconColor: AppColors.primary,
          iconBg: const Color(0xFFE3ECFA),
          value: activeSites,
          label: 'Active Sites',
        ),
        _buildStatCard(
          icon: Icons.access_time,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFD8F1E0),
          value: onDutyNow,
          label: 'On Duty Now',
        ),
        _buildStatCard(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFBE9800),
          iconBg: const Color(0xFFF7E8B2),
          value: activeAlerts,
          label: 'Active Alerts',
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: iconColor, size: 22.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: AppTypography.title().copyWith(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textprimaryDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: AppTypography.body().copyWith(
              fontSize: 13.sp,
              color: AppColors.textprimaryDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: Colors.white, size: 24.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.title().copyWith(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTypography.body().copyWith(
                      fontSize: 12.sp,
                      color: Colors.white.withOpacity(0.92),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
