import 'package:flutter/foundation.dart';
import '../models/auth_state.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  AuthState _authState = AuthState.uninitialized();
  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel({
    required AuthService authService,
    required StorageService storageService,
  }) : _authService = authService,
       _storageService = storageService {
    _checkAuthStatus();
  }

  // Getters
  AuthState get authState => _authState;
  Map<String, dynamic>? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _authState.status == AuthStatus.authenticated;

  bool hasPrivilege(String item, String action) {
    final currentUser = this.currentUser;
    if (currentUser == null) return false;
    if (currentUser['role'] == 'admin' || currentUser['role'] == 'master-admin') return true;
    
    final privileges = currentUser['privileges'] as Map<String, dynamic>?;
    if (privileges == null) return false;
    
    if (privileges['all'] == 'all') return true;
    if (privileges['all'] is List && (privileges['all'] as List).contains('all')) return true;

    final itemPerms = privileges[item];
    if (itemPerms == null) return false;

    if (itemPerms is List) {
      return itemPerms.contains('all') || itemPerms.contains(action);
    }
    return itemPerms == 'all' || itemPerms == action;
  }

  // Check if user is already logged in
  Future<void> _checkAuthStatus() async {
    try {
      final userJson = await _storageService.getCurrentUserJson();
      if (userJson != null) {
        _currentUser = userJson;
        _authState = AuthState.authenticated();
      } else {
        _authState = AuthState.unauthenticated();
      }
    } catch (e) {
      _authState = AuthState.unauthenticated();
    }
    notifyListeners();
  }

  // Login method
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    _authState = AuthState.authenticating();
    notifyListeners();

    try {
      final userJson = await _authService.loginAsJson(email, password);
      if (userJson != null) {
        await _storageService.saveUserJson(userJson);
        _currentUser = userJson;
        _authState = AuthState.authenticated();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Invalid credentials';
        _authState = AuthState.unauthenticated();
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _authState = AuthState.unauthenticated();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Logout method
  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authService.logout();
      _currentUser = null;
      _authState = AuthState.unauthenticated();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  // Register method
  Future<bool> register({
    required String first_name,
    required String last_name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final userJson = await _authService.registerAsJson(
        first_name: first_name,
        last_name: last_name,
        email: email,
        password: password,
      );

      if (userJson != null) {
        await _storageService.saveUserJson(userJson);
        _currentUser = userJson;
        _authState = AuthState.authenticated();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Registration failed';
        _setLoading(false);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Forgot password method
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.forgotPassword(email);
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Reset password method
  Future<bool> resetPassword({
    required String email,
    required String token,
    required String password,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _authService.resetPassword(
        email: email,
        token: token,
        password: password,
      );
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Temporary development helper to bypass auth and open admin flows.
  Future<void> enableMockAdminSession() async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    final mockAdmin = {
      'id': 'mock_admin',
      'username': 'admin',
      'email': 'admin@mock.local',
      'role': 'admin',
      'fullName': 'Mock Admin',
      'department': 'Administration',
    };

    _currentUser = mockAdmin;
    await _storageService.saveUserJson(mockAdmin);
    _authState = AuthState.authenticated();
    _setLoading(false);
    notifyListeners();
  }

  Future<void> enableMockWorkerSession() async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    _currentUser = {
      'id': 'mock_worker',
      'username': 'worker',
      'email': 'worker@mock.local',
      'role': 'worker',
      'fullName': 'Mock Worker',
    };
    await _storageService.saveUserJson(_currentUser!);
    _authState = AuthState.authenticated();
    _setLoading(false);
    notifyListeners();
  }

  Future<void> enableMockSupervisorSession() async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    _currentUser = {
      'id': 'mock_supervisor',
      'username': 'supervisor',
      'email': 'supervisor@mock.local',
      'role': 'supervisor',
      'fullName': 'Mock Supervisor',
    };
    await _storageService.saveUserJson(_currentUser!);
    _authState = AuthState.authenticated();
    _setLoading(false);
    notifyListeners();
  }

  // Helper to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
