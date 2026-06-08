class Routes {
  Routes._();

  // Auth
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const passwordResetLinkSent = '/password-reset-link-sent';

  // Worker
  static const worker = '/worker';
  static const workerStartShift = '/worker/start-shift';
  static const workerEndShift = '/worker/end-shift';
  static const workerCheckin = '/worker/checkin';
  static const workerHistory = '/worker/history';
  static const workerShiftDetails = '/worker/shift-details';
  static const workerNotifications = '/worker/notifications';

  // Supervisor
  static const supervisor = '/supervisor';
  static const supervisorSiteVisitOn = '/supervisor/site-visit-on';
  static const supervisorSiteVisitOff = '/supervisor/site-visit-off';
  static const supervisorReportForm = '/supervisor/report-form';
  static const supervisorReportConfirmation = '/supervisor/report-confirmation';
  static const supervisorNotifications = '/supervisor/notifications';

  // Admin
  static const admin = '/admin';
  static const adminStaff = '/admin/staff';
  static const adminCustomers = '/admin/customers';
  static const adminCustomerContacts = '/admin/customer-contacts';
  static const adminCustomerInvoiceProfiles =
      '/admin/customer-invoice-profiles';
  static const adminCustomerInvoices = '/admin/customer-invoices';
  static const adminShifts = '/admin/shifts';
  static const adminShiftNotes = '/admin/shift-notes';
  static const adminTimesheets = '/admin/timesheets';
  static const adminSites = '/admin/sites';
  static const adminCreateSite = '/admin/create-site';
  static const adminSiteWizard = '/admin/site-wizard';
  static const adminEditSite = '/admin/edit-site';
  static const adminReports = '/admin/reports';
  static const adminAlerts = '/admin/alerts';
  static const adminLiveOperations = '/admin/live-operations';
}
