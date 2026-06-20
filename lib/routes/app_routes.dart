import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:security_app/routes/routes.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../models/auth_state.dart';
import '../providers/site_creation_provider.dart';

// Auth screens
import '../views/auth/login_view.dart';
import '../views/auth/signup_view.dart';
import '../views/auth/forgot_password_view.dart';
import '../views/auth/password_reset_link_sent_view.dart';

// Worker screens
import '../views/worker/worker_dashboard_screen.dart';
import '../views/worker/shift_start_screen.dart';
import '../views/worker/end_shift_screen.dart';
import '../views/worker/checkin_screen.dart';
import '../views/worker/duty_history_screen.dart';
import '../views/worker/shift_details_screen.dart';
import '../views/worker/worker_notifications_screen.dart';
import '../views/worker/enhanced_checkin_screen.dart';
import '../views/worker/enhanced_duty_history_screen.dart';
import '../views/worker/checkin_history_screen.dart';
import '../views/worker/worker_ops_live_screen.dart';
import '../views/supervisor/supervisor_officers_screen.dart';
import '../views/supervisor/supervisor_activity_sheet_screen.dart';
import '../views/supervisor/supervisor_checkin_screen.dart';
import '../views/supervisor/supervisor_qr_scan_screen.dart';
import '../views/supervisor/supervisor_alarm_call_screen.dart';
import '../views/worker/worker_qr_scan_screen.dart';
import '../views/worker/worker_alarm_call_screen.dart';
import '../views/worker/worker_my_shifts_screen.dart';
import '../views/worker/worker_offered_shifts_screen.dart';
import '../views/worker/worker_check_call_screen.dart';
import '../views/worker/worker_checkin_screen.dart';

// Supervisor screens
import '../views/supervisor/supervisor_dashboard_screen.dart';
import '../views/supervisor/site_visit_on_screen.dart';
import '../views/supervisor/site_visit_off_screen.dart';
import '../views/supervisor/site_report_form_screen.dart';
import '../views/supervisor/site_report_confirmation_screen.dart';
import '../views/supervisor/supervisor_notifications_screen.dart';

// Admin screens
import '../views/admin/admin_dashboard_screen.dart';
import '../views/admin/staff_management_screen.dart';
import '../views/admin/customer_management_screen.dart';
import '../views/admin/shift_management_screen.dart';
import '../views/admin/shift_notes_screen.dart';
import '../views/admin/site_management_screen.dart';
import '../views/admin/create_site_screen.dart';
import '../views/admin/site_creation_wizard.dart';
import '../views/admin/timesheet_management_screen.dart';
import '../views/admin/edit_site_screen.dart';
import '../views/admin/reports_analytics_screen.dart';
import '../views/admin/alert_notification_screen.dart';
import '../views/admin/live_operations_screen.dart';
import '../views/admin/admin_alarm_call_screen.dart';
import '../views/shared/team_messages_screen.dart';

GoRouter createAppRouter(
  AuthViewModel authViewModel, {
  String? initialLocation,
}) {
  return GoRouter(
    refreshListenable: authViewModel,
    initialLocation: initialLocation ?? Routes.login,
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.toString()}')),
    ),
    redirect: (context, state) {
      // Normalize accidental 'Home' location (case-insensitive) coming
      // from external links or incorrect navigation calls.
      final loc = state.uri.path.toLowerCase();
      if (loc == 'home' || loc == '/home') return Routes.login;
      // If we haven't determined auth status yet, don't redirect. This
      // prevents transient redirects to `/login` during hot restart while
      // `AuthViewModel` is still checking stored auth state asynchronously.
      if (authViewModel.authState.status == AuthStatus.uninitialized) {
        return null;
      }

      final isAuthenticated = authViewModel.isAuthenticated;
      final isLoginRoute = state.matchedLocation == Routes.login;
      final isSignupRoute = state.matchedLocation == Routes.signup;
      final isForgotPasswordRoute =
          state.matchedLocation == Routes.forgotPassword;
      final isPasswordResetLinkRoute =
          state.matchedLocation == Routes.passwordResetLinkSent;

      final isAuthScreen = isLoginRoute ||
          isSignupRoute ||
          isForgotPasswordRoute ||
          isPasswordResetLinkRoute;

      if (!isAuthenticated && !isAuthScreen) {
        return Routes.login;
      }
      if (isAuthenticated && isAuthScreen) {
        return _getHomeRouteForRole(authViewModel.currentUser?['role']);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: Routes.signup,
        builder: (context, state) => const SignupView(),
      ),
      GoRoute(
        path: Routes.forgotPassword,
        builder: (context, state) => const ForgotPasswordView(),
      ),
      GoRoute(
        path: Routes.passwordResetLinkSent,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return PasswordResetLinkSentView(email: email);
        },
      ),

      // Worker
      GoRoute(
        path: '/worker',
        builder: (context, state) => const WorkerDashboardScreen(),
      ),
      GoRoute(
        path: '/worker/start-shift',
        builder: (context, state) => const ShiftStartScreen(),
      ),
      GoRoute(
        path: '/worker/end-shift',
        builder: (context, state) => const EndShiftScreen(),
      ),
      GoRoute(
        path: '/worker/checkin',
        builder: (context, state) => const WorkerCheckinScreen(),
      ),
      GoRoute(
        path: '/worker/enhanced-checkin',
        builder: (context, state) => const WorkerCheckinScreen(),
      ),
      GoRoute(
        path: '/worker/history',
        builder: (context, state) => const EnhancedDutyHistoryScreen(),
      ),
      GoRoute(
        path: '/worker/enhanced-history',
        builder: (context, state) => const EnhancedDutyHistoryScreen(),
      ),
      GoRoute(
        path: '/worker/checkin-history',
        builder: (context, state) => const CheckinHistoryScreen(),
      ),
      GoRoute(
        path: '/worker/shift-details',
        builder: (context, state) {
          final shiftId = state.extra as String;
          return ShiftDetailsScreen(shiftId: shiftId);
        },
      ),
      GoRoute(
        path: '/worker/shift-details/:shiftId',
        builder: (context, state) {
          final shiftId = state.pathParameters['shiftId']!;
          return ShiftDetailsScreen(shiftId: shiftId);
        },
      ),
      GoRoute(
        path: '/worker/notifications',
        builder: (context, state) => const WorkerNotificationsScreen(),
      ),
      GoRoute(
        path: '/worker/ops-live',
        builder: (context, state) => const WorkerOpsLiveScreen(),
      ),
      GoRoute(
        path: '/worker/qr-scan',
        builder: (context, state) => const WorkerQrScanScreen(),
      ),
      GoRoute(
        path: '/worker/alarm-call',
        builder: (context, state) => const WorkerAlarmCallScreen(),
      ),
      GoRoute(
        path: '/worker/my-shifts',
        builder: (context, state) => const WorkerMyShiftsScreen(),
      ),
      GoRoute(
        path: '/worker/offered-shifts',
        builder: (context, state) => const WorkerOfferedShiftsScreen(),
      ),
      GoRoute(
        path: '/worker/check-call',
        builder: (context, state) => const WorkerCheckCallScreen(),
      ),

      // Supervisor
      GoRoute(
        path: '/supervisor',
        builder: (context, state) => const SupervisorDashboardScreen(),
      ),
      GoRoute(
        path: '/supervisor/site-visit-on',
        builder: (context, state) => const SiteVisitOnScreen(),
      ),
      GoRoute(
        path: '/supervisor/site-visit-off',
        builder: (context, state) => const SiteVisitOffScreen(),
      ),
      GoRoute(
        path: '/supervisor/report-form',
        builder: (context, state) => const SiteReportFormScreen(),
      ),
      GoRoute(
        path: '/supervisor/report-confirmation',
        builder: (context, state) {
          final reportId = state.extra as String;
          return SiteReportConfirmationScreen(reportId: reportId);
        },
      ),
      GoRoute(
        path: '/supervisor/notifications',
        builder: (context, state) => const SupervisorNotificationsScreen(),
      ),
      GoRoute(
        path: '/supervisor/officers',
        builder: (context, state) => const SupervisorOfficersScreen(),
      ),
      GoRoute(
        path: '/supervisor/activity-sheet',
        builder: (context, state) => const SupervisorActivitySheetScreen(),
      ),
      GoRoute(
        path: '/supervisor/checkin',
        builder: (context, state) => const SupervisorCheckinScreen(),
      ),
      GoRoute(
        path: '/supervisor/qr-scan',
        builder: (context, state) => const SupervisorQrScanScreen(),
      ),
      GoRoute(
        path: '/supervisor/alarm-call',
        builder: (context, state) => const SupervisorAlarmCallScreen(),
      ),

      // Admin
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: Routes.adminStaff,
        builder: (context, state) => const StaffManagementScreen(),
      ),
      GoRoute(
        path: Routes.adminCustomers,
        builder: (context, state) => const CustomerManagementScreen(),
      ),
      GoRoute(
        path: Routes.adminShifts,
        builder: (context, state) => const ShiftManagementScreen(),
      ),
      GoRoute(
        path: Routes.adminShiftNotes,
        builder: (context, state) => const ShiftNotesScreen(),
      ),
      GoRoute(
        path: Routes.adminTimesheets,
        builder: (context, state) => const TimesheetManagementScreen(),
      ),
      GoRoute(
        path: '/admin/sites',
        builder: (context, state) => const SiteManagementScreen(),
      ),
      GoRoute(
        path: '/admin/create-site',
        builder: (context, state) => const CreateSiteScreen(),
      ),
      GoRoute(
        path: Routes.adminSiteWizard,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;

          // For development, check for step parameter in query
          final stepParam = state.uri.queryParameters['step'];
          SiteCreationStep? initialStep;

          if (stepParam != null) {
            try {
              final stepIndex = int.parse(stepParam);
              if (stepIndex >= 0 &&
                  stepIndex < SiteCreationStep.values.length) {
                initialStep = SiteCreationStep.values[stepIndex];
              }
            } catch (_) {
              // Try to parse by name
              for (int i = 0; i < SiteCreationStep.values.length; i++) {
                if (SiteCreationStep.values[i].name == stepParam) {
                  initialStep = SiteCreationStep.values[i];
                  break;
                }
              }
            }
          }

          return SiteCreationWizard(
            initialDetails: extra?['site'],
            initialContacts: extra?['contacts'],
            initialCheckpoints: extra?['checkpoints'],
            initialDocuments: extra?['documents'],
            initialPreferences: extra?['preferences'],
            initialStep: initialStep,
          );
        },
      ),
      GoRoute(
        path: '/admin/edit-site',
        builder: (context, state) {
          final site = state.extra as Map<String, dynamic>;
          return EditSiteScreen(site: site);
        },
      ),
      GoRoute(
        path: '/admin/reports',
        builder: (context, state) => const ReportsAnalyticsScreen(),
      ),
      GoRoute(
        path: '/admin/alerts',
        builder: (context, state) => const AlertNotificationScreen(),
      ),
      GoRoute(
        path: Routes.adminLiveOperations,
        builder: (context, state) => const LiveOperationsScreen(),
      ),
      GoRoute(
        path: Routes.adminAlarmCall,
        builder: (context, state) => const AdminAlarmCallScreen(),
      ),
      GoRoute(
        path: Routes.adminTeamMessages,
        builder: (context, state) => const TeamMessagesScreen(role: TeamMessageRole.admin),
      ),
      GoRoute(
        path: Routes.supervisorTeamMessages,
        builder: (context, state) => const TeamMessagesScreen(role: TeamMessageRole.supervisor),
      ),
      GoRoute(
        path: Routes.workerTeamMessages,
        builder: (context, state) => const TeamMessagesScreen(role: TeamMessageRole.worker),
      ),
      // Development-only routes for easier step access during hot reload
      ...(!kDebugMode
          ? []
          : [
              GoRoute(
                path: '/dev/site-wizard/details',
                builder: (context, state) => const SiteCreationWizard(
                  initialStep: SiteCreationStep.details,
                ),
              ),
              GoRoute(
                path: '/dev/site-wizard/contacts',
                builder: (context, state) => const SiteCreationWizard(
                  initialStep: SiteCreationStep.contacts,
                ),
              ),
              GoRoute(
                path: '/dev/site-wizard/staff-preferences',
                builder: (context, state) => const SiteCreationWizard(
                  initialStep: SiteCreationStep.preferences,
                ),
              ),
              GoRoute(
                path: '/dev/site-wizard/checkpoints',
                builder: (context, state) => const SiteCreationWizard(
                  initialStep: SiteCreationStep.checkpoints,
                ),
              ),
              GoRoute(
                path: '/dev/site-wizard/documents',
                builder: (context, state) => const SiteCreationWizard(
                  initialStep: SiteCreationStep.documents,
                ),
              ),
            ]),
    ],
  );
}

String _getHomeRouteForRole(String? role) {
  if (role == null) return '/login';

  final roleStr = role.toLowerCase();
  if (roleStr.contains('admin')) {
    return '/admin';
  } else if (roleStr.contains('supervisor')) {
    return '/supervisor';
  } else if (roleStr.contains('worker') || roleStr.contains('security-officer')) {
    return '/worker';
  }
  return '/login';
}
