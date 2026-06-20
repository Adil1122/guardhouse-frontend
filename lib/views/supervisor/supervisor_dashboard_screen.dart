import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:security_app/routes/routes.dart';

import '../../constants/app_constants.dart';
import '../../constants/typography.dart';
import '../../widgets/supervisor_panel_components.dart';
import '../../viewmodels/supervisor_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';

// Import admin screens for routing
import '../admin/invoice_management_screen.dart';
import '../admin/digital_occurrence_log_management_screen.dart';
import '../admin/pay_group_management_screen.dart';
import '../admin/service_group_management_screen.dart';
import '../admin/form_template_management_screen.dart';
import '../admin/organization_compliance_management_screen.dart';
import '../admin/company_settings_screen.dart';

class SupervisorDashboardScreen extends StatefulWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  State<SupervisorDashboardScreen> createState() =>
      _SupervisorDashboardScreenState();
}

class _SupervisorDashboardScreenState extends State<SupervisorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupervisorViewModel>().loadDashboardData();
    });
  }

  bool _hasPrivilege(Map<String, dynamic>? privileges, String itemId, String requiredPrivilege) {
    if (privileges == null) return false;
    
    // Global all
    if (privileges['all'] == 'all') return true;
    if (privileges['all'] is List && (privileges['all'] as List).contains('all')) return true;

    final itemPerms = privileges[itemId];
    if (itemPerms == null) return false;

    if (itemPerms is List) {
      return itemPerms.contains('all') || itemPerms.contains(requiredPrivilege);
    }
    
    return itemPerms == 'all' || itemPerms == requiredPrivilege;
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final supervisorViewModel = context.watch<SupervisorViewModel>();

    final user = authViewModel.currentUser;
    final userName = user?['fullName'] ?? user?['full_name'] ?? 'Supervisor User';
    
    // Assume privileges are returned in the user object from the backend
    final privileges = user?['privileges'] as Map<String, dynamic>?;

    final totalUsers = supervisorViewModel.totalWorkers > 0
        ? supervisorViewModel.totalWorkers.toString().padLeft(2, '0')
        : '0';
    final activeSites = supervisorViewModel.activeSites > 0
        ? supervisorViewModel.activeSites.toString().padLeft(2, '0')
        : '0';
    final reportsToday = supervisorViewModel.reportsToday > 0
        ? supervisorViewModel.reportsToday.toString().padLeft(2, '0')
        : '0';
    final unreadNotifications = supervisorViewModel.unreadNotifications.toString().padLeft(2, '0');

    return Scaffold(
      backgroundColor: AppColors.dashboardBackground,
      body: SafeArea(
        child: supervisorViewModel.isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => supervisorViewModel.refresh(),
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
                          onDutyNow: reportsToday, // Replacing with reports for supervisor or leave as onDuty
                          activeAlerts: unreadNotifications,
                        ),
                      ),
                      SizedBox(height: 14.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'My Dashboard',
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
                            _buildActionCard(
                              icon: Icons.login,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Clock In',
                              subtitle: 'Check in to your current site as supervisor',
                              onTap: () => context.push(Routes.supervisorCheckin),
                            ),
                            _buildActionCard(
                              icon: Icons.live_tv,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Ops Live',
                              subtitle: 'Monitor real-time shift status & operations',
                              onTap: () => context.push(Routes.adminLiveOperations),
                            ),
                            _buildActionCard(
                              icon: Icons.qr_code_scanner,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Scan QR',
                              subtitle: 'Scan site checkpoint QR code to log presence',
                              onTap: () => context.push(Routes.supervisorQrScan),
                            ),
                            _buildActionCard(
                              icon: Icons.people_outline,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Officers Details',
                              subtitle: 'View all assigned officers & their duty status',
                              onTap: () => context.push(Routes.supervisorOfficers),
                            ),
                            _buildActionCard(
                              icon: Icons.message_outlined,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Team Messages',
                              subtitle: 'View announcements from admin',
                              onTap: () => context.push(Routes.supervisorTeamMessages),
                            ),
                            _buildActionCard(
                              icon: Icons.event_note_outlined,
                              iconBg: const Color(0xFF0E45BA),
                              title: 'Activity Sheet',
                              subtitle: 'Browse patrol reports & recent site activities',
                              onTap: () => context.push(Routes.supervisorActivitySheet),
                            ),
                            if (_hasPrivilege(privileges, 'staff', 'list'))
                              _buildActionCard(
                                icon: Icons.badge_outlined,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Staff Management',
                                subtitle: 'Manage staff details, privileges & wages',
                                onTap: () => context.push(Routes.adminStaff),
                              ),
                            if (_hasPrivilege(privileges, 'customer', 'list'))
                              _buildActionCard(
                                icon: Icons.business,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Customer Management',
                                subtitle: 'Manage customers, contacts & invoicing',
                                onTap: () => context.push(Routes.adminCustomers),
                              ),
                            if (_hasPrivilege(privileges, 'static_site', 'list'))
                              _buildActionCard(
                                icon: Icons.location_on_outlined,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Site Management',
                                subtitle: 'Create site, defines redius & assign workers',
                                onTap: () => context.push(Routes.adminSites),
                              ),
                            if (_hasPrivilege(privileges, 'timesheet', 'list'))
                              _buildActionCard(
                                icon: Icons.access_time,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Timesheet Management',
                                subtitle: 'Review & approve staff timesheets',
                                onTap: () => context.push(Routes.adminTimesheets),
                              ),
                            if (_hasPrivilege(privileges, 'shift', 'list'))
                              _buildActionCard(
                                icon: Icons.schedule,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Shift Management',
                                subtitle: 'Schedule shifts, assign officers & notes',
                                onTap: () => context.push(Routes.adminShifts),
                              ),
                            if (_hasPrivilege(privileges, 'live_operation', 'list') || _hasPrivilege(privileges, 'live_operations', 'list'))
                              _buildActionCard(
                                icon: Icons.live_tv,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Live Operations',
                                subtitle: 'Monitor real-time shift status & operations',
                                onTap: () => context.push(Routes.adminLiveOperations),
                              ),
                            if (_hasPrivilege(privileges, 'invoice', 'list'))
                              _buildActionCard(
                                icon: Icons.receipt_long,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Invoice Management',
                                subtitle: 'Create & manage customer invoices',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const InvoiceManagementScreen(),
                                  ),
                                ),
                              ),
                            if (_hasPrivilege(privileges, 'digital_occurence_log', 'list'))
                              _buildActionCard(
                                icon: Icons.assignment_outlined,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Digital Occurrence Logs',
                                subtitle: 'Track & manage facility incidents',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const DigitalOccurrenceLogManagementScreen(),
                                  ),
                                ),
                              ),
                            if (_hasPrivilege(privileges, 'pay_group', 'list'))
                              _buildActionCard(
                                icon: Icons.attach_money_outlined,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Pay Groups Management',
                                subtitle: 'Manage pay groups & rates configuration',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const PayGroupManagementScreen(),
                                  ),
                                ),
                              ),
                            if (_hasPrivilege(privileges, 'service_group', 'list'))
                              _buildActionCard(
                                icon: Icons.miscellaneous_services_outlined,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Service Groups Management',
                                subtitle: 'Manage service groups & rates configuration',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ServiceGroupManagementScreen(),
                                  ),
                                ),
                              ),
                            if (_hasPrivilege(privileges, 'form', 'list'))
                              _buildActionCard(
                                icon: Icons.dynamic_form_outlined,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Form Templates',
                                subtitle: 'Create templates with dynamic custom fields',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const FormTemplateManagementScreen(),
                                  ),
                                ),
                              ),
                            if (_hasPrivilege(privileges, 'organization_compliance', 'list'))
                              _buildActionCard(
                                icon: Icons.verified_user_outlined,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Organization Compliances',
                                subtitle: 'Manage compliance requirements & reminders',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const OrganizationComplianceManagementScreen(),
                                  ),
                                ),
                              ),
                            if (_hasPrivilege(privileges, 'organization', 'settings'))
                              _buildActionCard(
                                icon: Icons.settings_outlined,
                                iconBg: const Color(0xFF0E45BA),
                                title: 'Company Settings',
                                subtitle: 'Configure logs, auth, sorting, defaults & alerts',
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CompanySettingsScreen(),
                                  ),
                                ),
                              ),
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
                      'Supervisor',
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
                onTap: () => context.push(Routes.supervisorNotifications),
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
          label: 'Total Workers',
        ),
        _buildStatCard(
          icon: Icons.location_on_outlined,
          iconColor: AppColors.primary,
          iconBg: const Color(0xFFE3ECFA),
          value: activeSites,
          label: 'Active Sites',
        ),
        _buildStatCard(
          icon: Icons.assignment_outlined,
          iconColor: const Color(0xFF16A34A),
          iconBg: const Color(0xFFD8F1E0),
          value: onDutyNow,
          label: 'Reports Today',
        ),
        _buildStatCard(
          icon: Icons.notifications_none,
          iconColor: const Color(0xFFBE9800),
          iconBg: const Color(0xFFF7E8B2),
          value: activeAlerts,
          label: 'Unread Notifications',
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

  Widget _buildActionCard({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
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
        ),
        SizedBox(height: 8.h),
      ],
    );
  }
}
