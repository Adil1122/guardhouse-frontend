# Laravel Backend API Routes

This document outlines the required Laravel API endpoints for the Security App.

## Base URL Configuration

Update `lib/config/api_config.dart`:
```dart
static const String baseUrl = 'http://your-domain.com/api';
// OR for local development:
static const String baseUrl = 'http://192.168.1.100:8000/api';
```

## Required Laravel Routes (api.php)

### Authentication Routes
```php
// Public routes
Route::post('/login', [AuthController::class, 'login']);

// Protected routes (require authentication)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
});
```

### Worker Routes
```php
Route::middleware(['auth:sanctum', 'role:worker'])->prefix('worker')->group(function () {
    Route::get('/tasks', [WorkerController::class, 'getTasks']);
    Route::get('/reports', [WorkerController::class, 'getReports']);
    Route::post('/reports', [WorkerController::class, 'submitReport']);
    Route::put('/tasks/{id}/status', [WorkerController::class, 'updateTaskStatus']);
});
```

### Supervisor Routes
```php
Route::middleware(['auth:sanctum', 'role:supervisor'])->prefix('supervisor')->group(function () {
    Route::get('/workers', [SupervisorController::class, 'getWorkers']);
    Route::get('/reports', [SupervisorController::class, 'getReports']);
    Route::get('/statistics', [SupervisorController::class, 'getStatistics']);
    Route::post('/tasks/assign', [SupervisorController::class, 'assignTask']);
    Route::put('/reports/{id}/review', [SupervisorController::class, 'reviewReport']);
});
```

### Admin Routes
```php
Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->group(function () {
    Route::get('/users', [AdminController::class, 'getAllUsers']);
    Route::post('/users', [AdminController::class, 'createUser']);
    Route::put('/users/{id}', [AdminController::class, 'updateUser']);
    Route::delete('/users/{id}', [AdminController::class, 'deleteUser']);
    Route::put('/users/{id}/toggle-status', [AdminController::class, 'toggleUserStatus']);
    Route::get('/logs', [AdminController::class, 'getSystemLogs']);
    Route::get('/statistics', [AdminController::class, 'getSystemStatistics']);
});
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('worker', 'supervisor', 'admin') NOT NULL,
    full_name VARCHAR(255),
    department VARCHAR(255),
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL
);
```

### Tasks Table
```sql
CREATE TABLE tasks (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    assigned_to BIGINT UNSIGNED,
    assigned_by BIGINT UNSIGNED,
    status ENUM('pending', 'in_progress', 'completed') DEFAULT 'pending',
    priority ENUM('low', 'medium', 'high') DEFAULT 'medium',
    due_date DATETIME,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (assigned_to) REFERENCES users(id),
    FOREIGN KEY (assigned_by) REFERENCES users(id)
);
```

### Reports Table
```sql
CREATE TABLE reports (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT,
    submitted_by BIGINT UNSIGNED,
    reviewed_by BIGINT UNSIGNED NULL,
    status ENUM('submitted', 'pending_review', 'approved', 'rejected') DEFAULT 'submitted',
    review_comments TEXT NULL,
    created_at TIMESTAMP NULL,
    updated_at TIMESTAMP NULL,
    FOREIGN KEY (submitted_by) REFERENCES users(id),
    FOREIGN KEY (reviewed_by) REFERENCES users(id)
);
```

### System Logs Table
```sql
CREATE TABLE system_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT UNSIGNED,
    action VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    created_at TIMESTAMP NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

## Expected API Response Formats

### Login Response
```json
{
    "token": "1|abcdefgh...",
    "user": {
        "id": "1",
        "username": "john.doe",
        "email": "john@example.com",
        "role": "worker",
        "full_name": "John Doe",
        "department": "Security",
        "created_at": "2024-01-01T00:00:00.000000Z"
    }
}
```

### Get User Response (/me)
```json
{
    "user": {
        "id": "1",
        "username": "john.doe",
        "email": "john@example.com",
        "role": "worker",
        "full_name": "John Doe",
        "department": "Security",
        "created_at": "2024-01-01T00:00:00.000000Z"
    }
}
```

### Worker Tasks Response
```json
{
    "tasks": [
        {
            "id": "1",
            "title": "Patrol Area A",
            "description": "Check all entry points",
            "status": "pending",
            "priority": "high",
            "dueDate": "2024-01-15T14:00:00.000000Z"
        }
    ]
}
```

### Supervisor Statistics Response
```json
{
    "statistics": {
        "totalWorkers": 15,
        "activeWorkers": 12,
        "pendingReports": 5,
        "completedTasksToday": 23,
        "incidentsToday": 2
    }
}
```

### Admin Users Response
```json
{
    "users": [
        {
            "id": "1",
            "username": "john.doe",
            "email": "john@example.com",
            "role": "worker",
            "status": "active",
            "createdAt": "2024-01-01T00:00:00.000000Z"
        }
    ]
}
```

## Laravel Sanctum Setup

1. Install Sanctum:
```bash
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

2. Update `app/Http/Kernel.php`:
```php
'api' => [
    \Laravel\Sanctum\Http\Middleware\EnsureFrontendRequestsAreStateful::class,
    'throttle:api',
    \Illuminate\Routing\Middleware\SubstituteBindings::class,
],
```

3. Create Role Middleware (`app/Http/Middleware/CheckRole.php`):
```php
public function handle(Request $request, Closure $next, string $role)
{
    if ($request->user()->role !== $role) {
        return response()->json(['message' => 'Unauthorized'], 403);
    }
    return $next($request);
}
```

4. Register middleware in `app/Http/Kernel.php`:
```php
protected $routeMiddleware = [
    // ... other middleware
    'role' => \App\Http\Middleware\CheckRole::class,
];
```

## CORS Configuration

Update `config/cors.php`:
```php
'paths' => ['api/*'],
'allowed_origins' => ['*'], // In production, specify your app's domain
'allowed_methods' => ['*'],
'allowed_headers' => ['*'],
'supports_credentials' => true,
```

## Testing the API

Use these credentials format for login:
```json
{
    "username": "john.doe",
    "password": "password123"
}
```

## Error Handling

All endpoints should return consistent error responses:
```json
{
    "message": "Error description",
    "errors": {
        "field": ["Validation error message"]
    }
}
```

HTTP Status Codes:
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 403: Forbidden
- 404: Not Found
- 422: Validation Error
- 500: Server Error
