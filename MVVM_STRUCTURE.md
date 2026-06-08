# MVVM Structure Documentation

## Overview
This security app is built using the **MVVM (Model-View-ViewModel)** architecture pattern with **Provider** for state management. The app connects to a **Laravel backend** with **MySQL database** and includes 4 different panels based on user roles.

## Folder Structure

```
lib/
├── config/                # Configuration files
│   └── api_config.dart    # API endpoints and base URL
│
├── models/                 # Data models
│   ├── user_model.dart    # User entity with roles
│   └── auth_state.dart    # Authentication state
│
├── viewmodels/            # Business logic layer
│   ├── auth_viewmodel.dart       # Authentication logic
│   ├── worker_viewmodel.dart     # Worker panel logic
│   ├── supervisor_viewmodel.dart # Supervisor panel logic
│   └── admin_viewmodel.dart      # Admin panel logic
│
├── views/                 # UI layer
│   ├── login_view.dart    # Login screen
│   ├── worker_view.dart   # Worker dashboard
│   ├── supervisor_view.dart # Supervisor dashboard
│   └── admin_view.dart    # Admin dashboard
│
├── services/              # External services
│   ├── auth_service.dart  # Authentication API calls
│   ├── api_service.dart   # HTTP API client
│   └── storage_service.dart # Token storage
│
└── main.dart             # App entry point with providers
```

## User Roles

The app supports **4 user roles**, each with a dedicated panel:

1. **Worker Panel** - For security workers
   - View assigned tasks
   - Submit reports
   - Update task status

2. **Supervisor Panel** - For team supervisors
   - Manage workers
   - Review and approve reports
   - Assign tasks to workers
   - View team statistics

3. **Admin Panel** - For system administrators
   - User management (CRUD operations)
   - System-wide statistics
   - View system logs
   - Manage all roles

4. **Login Panel** - Authentication entry point
   - Role-based authentication
   - Auto-redirect based on user role

## State Management

### Provider Setup
The app uses **MultiProvider** at the root level to provide:

```dart
MultiProvider(
  providers: [
    // Services (Singletons)
    Provider<StorageService>
    ProxyProvider<StorageService, AuthService>
    ProxyProvider<StorageService, ApiService>
    
    // ViewModels (with ChangeNotifier)
    ChangeNotifierProxyProvider<AuthService, StorageService, AuthViewModel>
    ChangeNotifierProxyProvider<ApiService, WorkerViewModel>
    ChangeNotifierProxyProvider<ApiService, SupervisorViewModel>
    ChangeNotifierProxyProvider<ApiService, AdminViewModel>
  ],
  child: MyApp()
)
```

### Services
- **AuthService**: Handles authentication with Laravel backend
- **ApiService**: Makes HTTP requests to Laravel API using Dio
- **StorageService**: Stores authentication tokens locally

### ViewModels
Each ViewModel extends `ChangeNotifier` and handles:
- Business logic
- API calls
- State updates
- Error handling

## Navigation

Uses **GoRouter** for declarative routing with authentication guards:

```dart
Routes:
- /login       → LoginView
- /worker      → WorkerView      (requires authentication)
- /supervisor  → SupervisorView  (requires authentication)
- /admin       → AdminView       (requires authentication)
```

**Auto-redirect**: After login, users are automatically redirected to their role-specific panel.

## How to Use

### 1. Setup Backend
- Setup Laravel backend following **LARAVEL_API_GUIDE.md**
- Configure database and run migrations
- Update API URL in `lib/config/api_config.dart`

### 2. Login
Use credentials from your Laravel database:
- Login with username and password
- App automatically redirects based on user role

### 3. Each Panel Features

**Worker Panel:**
- View and update assigned tasks
- Submit new reports
- Track report status

**Supervisor Panel:**
- Monitor team members
- Review pending reports
- Assign tasks to workers
- View team statistics

**Admin Panel:**
- Create/Edit/Delete users
- Toggle user status
- View system logs
- Monitor system-wide statistics

## Dependencies

```yaml
dependencies:
  provider: ^6.1.2          # State management
  go_router: ^14.5.1        # Navigation
  dio: ^5.7.0               # HTTP client for API calls
  shared_preferences: ^2.3.4 # Token storage
```

## Backend Setup

### 1. Configure API URL
Update `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://your-laravel-backend.com/api';
// For local development:
static const String baseUrl = 'http://192.168.1.100:8000/api';
```

### 2. Laravel Backend Required
- See **LARAVEL_API_GUIDE.md** for complete Laravel setup
- Requires Laravel Sanctum for authentication
- MySQL database for data storage
- All API routes and database schema documented

## Running the App

```bash
# Get dependencies
flutter pub get

# Run the app
flutter run

# Build for production
flutter build apk    # Android
flutter build ios    # iOS
flutter build web    # Web
```

## API Integration

The app uses **Dio** HTTP client to communicate with Laravel:

1. **Authentication Flow**:
   - User logs in → Token received from Laravel
   - Token stored in SharedPreferences
   - Token sent with every API request in Authorization header

2. **Error Handling**:
   - 401 errors automatically clear tokens and redirect to login
   - Network errors displayed to users
   - Validation errors from Laravel shown in UI

3. **Request Interceptors**:
   - Automatically add auth tokens to requests
   - Handle unauthorized responses
   - Log API calls for debugging

## MVVM Benefits in This Project

1. **Separation of Concerns**: UI, business logic, and data are separated
2. **Testability**: ViewModels can be tested independently
3. **Reusability**: ViewModels can be reused across different views
4. **Maintainability**: Easy to locate and fix issues
5. **Scalability**: Easy to add new features and panels

## Next Steps

To complete the integration:
1. **Setup Laravel backend** using LARAVEL_API_GUIDE.md
2. **Configure database** with required tables
3. **Update API URL** in api_config.dart
4. **Test API endpoints** with Postman
5. **Handle edge cases** like network timeouts
6. **Add refresh token** mechanism if needed
7. **Implement proper error messages** from backend
8. **Add data caching** for offline support (optional)

## File Responsibilities

### Models
- Define data structure
- JSON serialization
- Data validation

### ViewModels
- Business logic
- State management
- API communication
- User actions handling

### Views
- UI rendering
- User input collection
- Display data from ViewModels
- Navigate between screens

### Services
- External API calls
- Local storage operations
- Third-party integrations
