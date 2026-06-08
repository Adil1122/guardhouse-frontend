import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'constants/typography.dart';
import 'routes/app_routes.dart';
import 'routes/routes.dart';
import 'package:flutter/foundation.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/worker_panel_viewmodel.dart';
import 'viewmodels/worker_viewmodel.dart';
import 'viewmodels/supervisor_viewmodel.dart';
import 'viewmodels/admin_viewmodel.dart';
import 'viewmodels/invoice_viewmodel.dart';
import 'viewmodels/digital_occurrence_log_viewmodel.dart';
import 'viewmodels/pay_group_viewmodel.dart';
import 'viewmodels/service_group_viewmodel.dart';
import 'viewmodels/form_template_viewmodel.dart';
import 'viewmodels/organization_compliance_viewmodel.dart';
import 'viewmodels/company_settings_viewmodel.dart';
import 'viewmodels/worker_geofence_viewmodel.dart';
import 'services/auth_service.dart';
import 'services/admin_api_service.dart';
import 'services/supervisor_api_service.dart';
import 'services/worker_api_service.dart';
import 'services/storage_service.dart';
import 'services/location_service.dart';
import 'services/photo_service.dart';
import 'services/geofence_api_service.dart';

// Development configuration - change this to work on specific screens during hot reload
const String? _kDevInitialRoute = kDebugMode
    ? null // Set to a specific route for development
    : null;
// Examples for easier development workflow:
// const String? _kDevInitialRoute = Routes.adminSiteWizard; // Opens site creation wizard
// const String? _kDevInitialRoute = '/dev/site-wizard/staff-preferences'; // Opens staff preferences step
// const String? _kDevInitialRoute = '/dev/site-wizard/contacts'; // Opens contacts step
// const String? _kDevInitialRoute = '/dev/site-wizard/checkpoints'; // Opens checkpoints step

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<LocationService>(create: (_) => LocationService()),
        Provider<PhotoService>(create: (_) => PhotoService()),
        ProxyProvider<StorageService, AuthService>(
          update: (_, storageService, __) => AuthService(storageService),
        ),
        ProxyProvider<StorageService, AdminApiService>(
          update: (_, storageService, __) => AdminApiService(storageService),
        ),
        ProxyProvider<StorageService, SupervisorApiService>(
          update: (_, storageService, __) =>
              SupervisorApiService(storageService),
        ),
        ProxyProvider<StorageService, WorkerApiService>(
          update: (_, storageService, __) => WorkerApiService(storageService),
        ),
        ProxyProvider<StorageService, GeofenceApiService>(
          update: (_, storageService, __) => GeofenceApiService(storageService),
        ),

        // ViewModels
        ChangeNotifierProxyProvider2<
          AuthService,
          StorageService,
          AuthViewModel
        >(
          create: (_) => AuthViewModel(
            authService: AuthService(StorageService()),
            storageService: StorageService(),
          ),
          update: (_, authService, storageService, previous) =>
              previous ??
              AuthViewModel(
                authService: authService,
                storageService: storageService,
              ),
        ),
        ChangeNotifierProxyProvider<WorkerApiService, WorkerViewModel>(
          create: (_) => WorkerViewModel(WorkerApiService(StorageService())),
          update: (_, workerApiService, previous) =>
              previous ?? WorkerViewModel(workerApiService),
        ),
        ChangeNotifierProvider<WorkerPanelViewModel>(
          create: (_) => WorkerPanelViewModel(),
        ),
        ChangeNotifierProxyProvider<SupervisorApiService, SupervisorViewModel>(
          create: (_) =>
              SupervisorViewModel(SupervisorApiService(StorageService())),
          update: (_, supervisorApiService, previous) =>
              previous ?? SupervisorViewModel(supervisorApiService),
        ),
        ChangeNotifierProxyProvider<AdminApiService, AdminViewModel>(
          create: (_) => AdminViewModel(AdminApiService(StorageService())),
          update: (_, adminApiService, previous) =>
              previous ?? AdminViewModel(adminApiService),
        ),
        ChangeNotifierProxyProvider<AdminApiService, InvoiceViewModel>(
          create: (_) => InvoiceViewModel(AdminApiService(StorageService())),
          update: (_, adminApiService, previous) =>
              previous ?? InvoiceViewModel(adminApiService),
        ),
        ChangeNotifierProxyProvider<
          AdminApiService,
          DigitalOccurrenceLogViewModel
        >(
          create: (_) =>
              DigitalOccurrenceLogViewModel(AdminApiService(StorageService())),
          update: (_, adminApiService, previous) =>
              previous ?? DigitalOccurrenceLogViewModel(adminApiService),
        ),
        ChangeNotifierProxyProvider<AdminApiService, PayGroupViewModel>(
          create: (_) => PayGroupViewModel(AdminApiService(StorageService())),
          update: (_, adminApiService, previous) =>
              previous ?? PayGroupViewModel(adminApiService),
        ),
        ChangeNotifierProxyProvider<AdminApiService, ServiceGroupViewModel>(
          create: (_) =>
              ServiceGroupViewModel(AdminApiService(StorageService())),
          update: (_, adminApiService, previous) =>
              previous ?? ServiceGroupViewModel(adminApiService),
        ),
        ChangeNotifierProxyProvider<AdminApiService, FormTemplateViewModel>(
          create: (_) =>
              FormTemplateViewModel(AdminApiService(StorageService())),
          update: (_, adminApiService, previous) =>
              previous ?? FormTemplateViewModel(adminApiService),
        ),
        ChangeNotifierProxyProvider<
          AdminApiService,
          OrganizationComplianceViewModel
        >(
          create: (_) => OrganizationComplianceViewModel(
            AdminApiService(StorageService()),
          ),
          update: (_, adminApiService, previous) =>
              previous ?? OrganizationComplianceViewModel(adminApiService),
        ),
        ChangeNotifierProxyProvider<AdminApiService, CompanySettingsViewModel>(
          create: (_) =>
              CompanySettingsViewModel(AdminApiService(StorageService())),
          update: (_, adminApiService, previous) =>
              previous ?? CompanySettingsViewModel(adminApiService),
        ),
        
        // Worker Geofence ViewModel
        ChangeNotifierProxyProvider3<
          GeofenceApiService,
          LocationService,
          PhotoService,
          WorkerGeofenceViewModel
        >(
          create: (_) => WorkerGeofenceViewModel(
            GeofenceApiService(StorageService()),
            LocationService(),
            PhotoService(),
          ),
          update: (_, geofenceApiService, locationService, photoService, previous) =>
              previous ?? WorkerGeofenceViewModel(
                geofenceApiService,
                locationService,
                photoService,
          ),
        ),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authViewModel, _) {
          return ScreenUtilInit(
            designSize: const Size(360, 690),
            minTextAdapt: true,
            builder: (context, child) {
              return MaterialApp.router(
                title: 'Security App',
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                  useMaterial3: true,
                  textTheme: AppTypography.textTheme,
                  appBarTheme: const AppBarTheme(
                    centerTitle: true,
                    elevation: 2,
                  ),
                  cardTheme: CardThemeData(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  snackBarTheme: SnackBarThemeData(
                    behavior: SnackBarBehavior.floating,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    insetPadding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 100.h),
                    contentTextStyle: AppTypography.body().copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                routerConfig: createAppRouter(
                  authViewModel,
                  initialLocation: _kDevInitialRoute ?? Routes.login,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
