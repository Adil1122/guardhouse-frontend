import 'package:flutter/foundation.dart';
// Note: inline ignores remain where specific collection-if cases need them.
import '../services/admin_api_service.dart';
import '../models/site_models.dart';
import '../models/timesheet_model.dart';
import '../config/api_config.dart';

class AdminViewModel extends ChangeNotifier {
  final AdminApiService _apiService;

  // Set true to use mock/fallback data while API is unavailable.
  static const bool _mockMode = false;

  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _sites = [];
  List<Map<String, dynamic>> _reports = [];
  List<Map<String, dynamic>> _alerts = [];
  List<Map<String, dynamic>> _staffMembers = [];
  List<Map<String, dynamic>> _customers = [];
  List<Map<String, dynamic>> _customerContacts = [];
  List<Map<String, dynamic>> _customerInvoiceProfiles = [];
  List<Map<String, dynamic>> _customerInvoices = [];
  List<Map<String, dynamic>> _shifts = [];
  List<Map<String, dynamic>> _liveShifts = [];
  List<Map<String, dynamic>> _liveAlerts = [];
  List<Map<String, dynamic>> _liveCheckins = [];
  Map<String, dynamic> _liveSummary = {};
  List<Map<String, dynamic>> _shiftNotes = [];
  List<Map<String, dynamic>> _securityOfficers = [];
  List<Map<String, dynamic>> _serviceGroups = [];
  List<Map<String, dynamic>> _payGroups = [];
  List<Map<String, dynamic>> _organizationCompliances = [];
  List<Map<String, dynamic>> _clockInQuestionnaires = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _systemLogs = [];
  List<Timesheet> _timesheets = [];
  Map<String, dynamic>? _systemStatistics;

  AdminViewModel(this._apiService);

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Map<String, dynamic>> get sites => _sites;
  List<Map<String, dynamic>> get reports => _reports;
  List<Map<String, dynamic>> get alerts => _alerts;
  List<Map<String, dynamic>> get staffMembers => _staffMembers;
  List<Map<String, dynamic>> get customers => _customers;
  List<Map<String, dynamic>> get customerContacts => _customerContacts;
  List<Map<String, dynamic>> get customerInvoiceProfiles =>
      _customerInvoiceProfiles;
  List<Map<String, dynamic>> get customerInvoices => _customerInvoices;
  List<Map<String, dynamic>> get shifts => _shifts;
  List<Map<String, dynamic>> get liveShifts => _liveShifts;
  List<Map<String, dynamic>> get liveAlerts => _liveAlerts;
  List<Map<String, dynamic>> get liveCheckins => _liveCheckins;
  Map<String, dynamic> get liveSummary => _liveSummary;
  List<Map<String, dynamic>> get shiftNotes => _shiftNotes;
  List<Map<String, dynamic>> get securityOfficers => _securityOfficers;
  List<Map<String, dynamic>> get serviceGroups => _serviceGroups;
  List<Map<String, dynamic>> get payGroups => _payGroups;
  List<Map<String, dynamic>> get organizationCompliances =>
      _organizationCompliances;
  List<Map<String, dynamic>> get clockInQuestionnaires =>
      _clockInQuestionnaires;
  List<Map<String, dynamic>> get activities => _activities;
  List<Map<String, dynamic>> get systemLogs => _systemLogs;
  List<Timesheet> get timesheets => _timesheets;
  Map<String, dynamic>? get systemStatistics => _systemStatistics;
  String get baseUrl => ApiConfig.baseUrl;

  // Initialize admin data
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await Future.wait([
        loadStaffMembers(),
        loadCustomers(),
        loadShifts(),
        loadShiftNotes(),
        loadSecurityOfficers(),
        loadServiceGroups(),
        loadPayGroups(),
        loadOrganizationCompliances(),
        loadClockInQuestionnaires(),
        loadSites(),
        loadReports(),
        loadAlerts(),
        _loadActivities(),
        _loadSystemLogs(),
        _loadSystemStatistics(),
      ]);
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
    notifyListeners();
  }

  // Load sites
  Future<void> loadSites() async {
    if (_mockMode) {
      _sites = _fallbackSites();
      notifyListeners();
      return;
    }
    try {
      _sites = await _apiService.getSites();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_sites.isEmpty) _sites = _fallbackSites();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fallbackSites() {
    return [
      {
        'id': 301,
        'name': 'Main Office Building',
        'address': '123 Business Street, London, SW1A 1AA',
        'contact': '+44 7000 111000',
        'description': 'Primary corporate headquarters',
        'status': 'Active',
        'customerId': 201,
        'customerName': 'John Corporation',
      },
      {
        'id': 302,
        'name': 'Market Place',
        'address': '45 Market Street, Manchester, M1 1PT',
        'contact': '+44 7000 222000',
        'description': 'Retail security site',
        'status': 'Active',
        'customerId': 201,
        'customerName': 'John Corporation',
      },
      {
        'id': 303,
        'name': 'Tech Park East',
        'address': '99 Innovation Drive, Birmingham, B1 1BT',
        'contact': '+44 7000 333000',
        'description': 'Data centre and tech campus',
        'status': 'Active',
        'customerId': 202,
        'customerName': 'Tech Solutions Ltd',
      },
    ];
  }

  // Load staff
  Future<void> loadStaffMembers() async {
    if (_mockMode) {
      _staffMembers = _fallbackStaffMembers();
      notifyListeners();
      return;
    }
    try {
      _staffMembers = await _apiService.getStaffMembers();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_staffMembers.isEmpty) _staffMembers = _fallbackStaffMembers();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fallbackStaffMembers() {
    return [
      {
        'id': 101,
        'role': 'Supervisor',
        'firstName': 'Emma',
        'lastName': 'Stone',
        'email': 'emma.supervisor@security.com',
        'preferredFirstName': 'Em',
        'preferredLastName': '',
        'contactNumber': '+44 7000 111111',
        'siaBadgeNumber': 'SIA-112233',
        'gender': 'Female',
        'imagePath': '',
        'emergencyContact': {
          'relationship': 'Sister',
          'name': 'Mia Stone',
          'contactNumber': '+44 7000 999999',
        },
        'privileges': [
          {
            'item': 'staff_detail',
            'levels': ['view-only', 'edit'],
          },
        ],
        'compliances': [
          {
            'type': 'driver-license',
            'startDate': '2026-01-01',
            'expirationDate': '2029-01-01',
            'files': ['dl_front.pdf', 'dl_back.pdf'],
          },
        ],
        'salaryWage': {
          'taxNumber': 'TAX-987651',
          'bankDetails': {
            'bankName': 'City Bank',
            'accountTitle': 'Emma Stone',
            'accountNumber': '99887766',
            'bankCountry': 'UK',
          },
          'defaultPayGroup': 'Monthly',
        },
      },
    ];
  }

  // Load customers
  Future<void> loadCustomers() async {
    if (_mockMode) {
      _customers = _fallbackCustomers();
      notifyListeners();
      return;
    }
    try {
      _customers = await _apiService.getCustomers();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_customers.isEmpty) _customers = _fallbackCustomers();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fallbackCustomers() {
    return [
      {
        'id': 201,
        'firstName': 'John',
        'lastName': 'Corporation',
        'referenceNumber': 'REF-001',
        'email': 'contact@johncorp.com',
        'address': {
          'address': '123 Business Street',
          'city': 'London',
          'state': 'England',
          'zip': 'SW1A 1AA',
          'country': 'UK',
        },
        'defaultPayGroup': 'Monthly',
      },
    ];
  }

  // Load customer contacts
  Future<void> loadCustomerContacts(String customerId) async {
    if (_mockMode) {
      _customerContacts = _fallbackCustomerContacts();
      notifyListeners();
      return;
    }
    try {
      _customerContacts = await _apiService.getCustomerContacts(customerId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_customerContacts.isEmpty) _customerContacts = _fallbackCustomerContacts();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fallbackCustomerContacts() {
    return [
      {
        'id': 301,
        'firstName': 'Sarah',
        'lastName': 'Johnson',
        'position': 'Manager',
        'email': 'sarah@johncorp.com',
        'mobileNumber': '+44 7000 123456',
        'notes': 'Primary contact for security services',
      },
    ];
  }

  // Load customer invoice profiles
  Future<void> loadCustomerInvoiceProfiles(String customerId) async {
    if (_mockMode) {
      _customerInvoiceProfiles = _fallbackCustomerInvoiceProfiles();
      notifyListeners();
      return;
    }
    try {
      _customerInvoiceProfiles =
          await _apiService.getCustomerInvoiceProfiles(customerId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_customerInvoiceProfiles.isEmpty) _customerInvoiceProfiles = _fallbackCustomerInvoiceProfiles();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fallbackCustomerInvoiceProfiles() {
    return [
      {
        'id': 401,
        'firstName': 'Michael',
        'lastName': 'Smith',
        'position': 'Finance Director',
        'email': 'finance@johncorp.com',
        'mobileNumber': '+44 7000 654321',
        'notes': 'Handles all invoice approvals',
      },
    ];
  }

  // Load customer invoices
  Future<void> loadCustomerInvoices(String customerId) async {
    if (_mockMode) {
      _customerInvoices = _fallbackCustomerInvoices();
      notifyListeners();
      return;
    }
    try {
      _customerInvoices = await _apiService.getCustomerInvoices(customerId);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_customerInvoices.isEmpty) _customerInvoices = _fallbackCustomerInvoices();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fallbackCustomerInvoices() {
    return [
      {
        'id': 501,
        'invoiceNumber': 'INV-2026-001',
        'customerId': 201,
        'customerName': 'John Corporation',
        'amount': 2500.00,
        'dueDate': '2026-04-01',
        'status': 'Pending',
        'createdDate': '2026-03-01',
      },
      {
        'id': 502,
        'invoiceNumber': 'INV-2026-002',
        'customerId': 201,
        'customerName': 'John Corporation',
        'amount': 1800.00,
        'dueDate': '2026-03-15',
        'status': 'Paid',
        'createdDate': '2026-02-15',
      },
    ];
  }

  // Create customer
  Future<Map<String, dynamic>?> createCustomer(
      Map<String, dynamic> customerData) async {
    _setLoading(true);
    if (_mockMode) {
      final newId = (_customers.isNotEmpty
          ? (_customers.last['id'] as int? ?? 200) + 1
          : 201);
      final newCustomer = {...customerData, 'id': newId};
      _customers.add(newCustomer);
      _setLoading(false);
      notifyListeners();
      return newCustomer;
    }
    try {
      final result = await _apiService.createCustomer(customerData);
      if (result != null) {
        await loadCustomers();
      }
      _setLoading(false);
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  // Update customer
  Future<bool> updateCustomer(Map<String, dynamic> customerData) async {
    _setLoading(true);
    if (_mockMode) {
      final idx = _customers.indexWhere(
        (c) => c['id'].toString() == customerData['id']?.toString(),
      );
      if (idx != -1) _customers[idx] = customerData;
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final customerId = customerData['id']?.toString();
      if (customerId == null || customerId.isEmpty) {
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final success = await _apiService.updateCustomer(
        customerId,
        customerData,
      );
      if (success) {
        await loadCustomers();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete customer
  Future<bool> deleteCustomer(String customerId) async {
    _setLoading(true);
    if (_mockMode) {
      _customers.removeWhere((c) => c['id'].toString() == customerId);
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.deleteCustomer(customerId);
      if (success) {
        await loadCustomers();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Create customer contact
  Future<bool> createCustomerContact(
      String customerId, Map<String, dynamic> contactData) async {
    _setLoading(true);
    if (_mockMode) {
      final newId = (_customerContacts.isNotEmpty
          ? (_customerContacts.last['id'] as int? ?? 300) + 1
          : 301);
      _customerContacts.add({...contactData, 'id': newId});
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success =
          await _apiService.createCustomerContact(customerId, contactData);
      if (success) {
        await loadCustomerContacts(customerId);
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update customer contact
  Future<bool> updateCustomerContact(
      String customerId, Map<String, dynamic> contactData) async {
    _setLoading(true);
    if (_mockMode) {
      final idx = _customerContacts.indexWhere(
        (c) => c['id'].toString() == contactData['id']?.toString(),
      );
      if (idx != -1) _customerContacts[idx] = contactData;
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final contactId = contactData['id']?.toString();
      if (contactId == null || contactId.isEmpty) {
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final success = await _apiService.updateCustomerContact(
        customerId,
        contactId,
        contactData,
      );
      if (success) {
        await loadCustomerContacts(customerId);
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete customer contact
  Future<bool> deleteCustomerContact(
      String customerId, String contactId) async {
    _setLoading(true);
    if (_mockMode) {
      _customerContacts.removeWhere((c) => c['id'].toString() == contactId);
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success =
          await _apiService.deleteCustomerContact(customerId, contactId);
      if (success) {
        await loadCustomerContacts(customerId);
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Create customer invoice profile
  Future<bool> createCustomerInvoiceProfile(
    String customerId,
    Map<String, dynamic> profileData,
  ) async {
    _setLoading(true);
    if (_mockMode) {
      final newId = (_customerInvoiceProfiles.isNotEmpty
          ? (_customerInvoiceProfiles.last['id'] as int? ?? 400) + 1
          : 401);
      _customerInvoiceProfiles.add({...profileData, 'id': newId});
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.createCustomerInvoiceProfile(
        customerId,
        profileData,
      );
      if (success) {
        await loadCustomerInvoiceProfiles(customerId);
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update customer invoice profile
  Future<bool> updateCustomerInvoiceProfile(
    String customerId,
    Map<String, dynamic> profileData,
  ) async {
    _setLoading(true);
    if (_mockMode) {
      final idx = _customerInvoiceProfiles.indexWhere(
        (p) => p['id'].toString() == profileData['id']?.toString(),
      );
      if (idx != -1) _customerInvoiceProfiles[idx] = profileData;
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final profileId = profileData['id']?.toString();
      if (profileId == null || profileId.isEmpty) {
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final success = await _apiService.updateCustomerInvoiceProfile(
        customerId,
        profileId,
        profileData,
      );
      if (success) {
        await loadCustomerInvoiceProfiles(customerId);
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete customer invoice profile
  Future<bool> deleteCustomerInvoiceProfile(
      String customerId, String profileId) async {
    _setLoading(true);
    if (_mockMode) {
      _customerInvoiceProfiles.removeWhere(
        (p) => p['id'].toString() == profileId,
      );
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success =
          await _apiService.deleteCustomerInvoiceProfile(customerId, profileId);
      if (success) {
        await loadCustomerInvoiceProfiles(customerId);
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Create customer invoice
  Future<bool> createCustomerInvoice(
      String customerId, Map<String, dynamic> invoiceData) async {
    _setLoading(true);
    if (_mockMode) {
      final newId = (_customerInvoices.isNotEmpty
          ? (_customerInvoices.last['id'] as int? ?? 500) + 1
          : 501);
      _customerInvoices.add({...invoiceData, 'id': newId});
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success =
          await _apiService.createCustomerInvoice(customerId, invoiceData);
      if (success) {
        await loadCustomerInvoices(customerId);
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update customer invoice
  Future<bool> updateCustomerInvoice(
      String customerId, Map<String, dynamic> invoiceData) async {
    _setLoading(true);
    if (_mockMode) {
      final idx = _customerInvoices.indexWhere(
        (i) => i['id'].toString() == invoiceData['id']?.toString(),
      );
      if (idx != -1) _customerInvoices[idx] = invoiceData;
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final invoiceId = invoiceData['id']?.toString();
      if (invoiceId == null || invoiceId.isEmpty) {
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final success = await _apiService.updateCustomerInvoice(
        customerId,
        invoiceId,
        invoiceData,
      );
      if (success) {
        await loadCustomerInvoices(customerId);
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete customer invoice
  Future<bool> deleteCustomerInvoice(
      String customerId, String invoiceId) async {
    _setLoading(true);
    if (_mockMode) {
      _customerInvoices.removeWhere((i) => i['id'].toString() == invoiceId);
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success =
          await _apiService.deleteCustomerInvoice(customerId, invoiceId);
      if (success) {
        await loadCustomerInvoices(customerId);
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Load reports
  Future<void> loadReports() async {
    if (_mockMode) {
      _reports = _fallbackReports();
      return;
    }
    try {
      _reports = await _apiService.getReports();
    } catch (e) {
      _errorMessage = e.toString();
      if (_reports.isEmpty) _reports = _fallbackReports();
    }
  }

  List<Map<String, dynamic>> _fallbackReports() {
    return [
      {
        'id': 'R001',
        'title': 'Night Patrol Summary',
        'type': 'Patrol',
        'site': 'Main Office Building',
        'createdBy': 'Emma Stone',
        'date': '2026-03-10',
        'status': 'Reviewed',
      },
      {
        'id': 'R002',
        'title': 'Access Control Incident',
        'type': 'Incident',
        'site': 'Market Place',
        'createdBy': 'John Smith',
        'date': '2026-03-11',
        'status': 'Pending',
      },
    ];
  }

  // Load alerts
  Future<void> loadAlerts() async {
    if (_mockMode) {
      _alerts = _fallbackAlerts();
      return;
    }
    try {
      _alerts = await _apiService.getAlerts();
    } catch (e) {
      _errorMessage = e.toString();
      if (_alerts.isEmpty) _alerts = _fallbackAlerts();
    }
  }

  List<Map<String, dynamic>> _fallbackAlerts() {
    return [
      {
        'id': 'A001',
        'title': 'Unauthorized Access Detected',
        'message': 'Gate 3 breach at 02:14 AM',
        'type': 'security',
        'site': 'Main Office Building',
        'is_read': false,
        'created_at': '2026-03-12T02:14:00Z',
      },
      {
        'id': 'A002',
        'title': 'SIA Badge Expiry',
        'message': 'Emma Stone SIA badge expires in 30 days',
        'type': 'compliance',
        'site': '',
        'is_read': false,
        'created_at': '2026-03-11T09:00:00Z',
      },
      {
        'id': 'A003',
        'title': 'Shift Not Started',
        'message': 'Mark Williams has not clocked in for PM shift',
        'type': 'operational',
        'site': 'Tech Park East',
        'is_read': true,
        'created_at': '2026-03-10T14:05:00Z',
      },
    ];
  }

  // Load activities
  Future<void> _loadActivities() async {
    if (_mockMode) {
      _activities = [
        {
          'type': 'login',
          'description': 'Admin logged in',
          'timestamp': '2026-03-12T08:00:00Z',
        },
        {
          'type': 'shift_created',
          'description': 'New shift created for Main Office',
          'timestamp': '2026-03-12T08:15:00Z',
        },
        {
          'type': 'staff_added',
          'description': 'New staff member onboarded',
          'timestamp': '2026-03-11T16:00:00Z',
        },
      ];
      return;
    }
    try {
      _activities = await _apiService.getActivities();
    } catch (e) {
      _errorMessage = e.toString();
      _activities = [];
    }
  }

  // Load system logs
  Future<void> _loadSystemLogs() async {
    if (_mockMode) {
      _systemLogs = [
        {
          'level': 'info',
          'message': 'Application started',
          'timestamp': '2026-03-12T07:00:00Z',
        },
        {
          'level': 'warning',
          'message': 'API timeout (demo mode)',
          'timestamp': '2026-03-12T07:01:00Z',
        },
      ];
      return;
    }
    try {
      _systemLogs = await _apiService.getSystemLogs();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Load system statistics
  Future<void> _loadSystemStatistics() async {
    if (_mockMode) {
      _systemStatistics = {
        'totalUsers': 12,
        'totalSites': 3,
        'activeShifts': 4,
        'pendingReports': 2,
        'openAlerts': 2,
        'staffOnDuty': 6,
      };
      return;
    }
    try {
      _systemStatistics = await _apiService.getSystemStatistics();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Create site
  Future<bool> createSite({
    required String name,
    required String address,
    String? contact,
    String? description,
    required String status,
  }) async {
    _setLoading(true);
    if (_mockMode) {
      final newId =
          (_sites.isNotEmpty ? (_sites.last['id'] as int? ?? 300) + 1 : 301);
      _sites.add({
        'id': newId,
        'name': name,
        'address': address,
        'contact': contact ?? '',
        'description': description ?? '',
        'status': status,
      });
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final siteData = {
        'name': name,
        'address': address,
        ...?(contact != null ? {'contact': contact} : null),
        ...?(description != null ? {'description': description} : null),
        'status': status,
      };
      final success = await _apiService.createSite(siteData);
      if (success) {
        await loadSites();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update site
  Future<bool> updateSite(Map<String, dynamic> siteData) async {
    _setLoading(true);
    if (_mockMode) {
      final idx = _sites.indexWhere(
        (s) => s['id'].toString() == siteData['id']?.toString(),
      );
      if (idx != -1) _sites[idx] = siteData;
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final siteId = siteData['id'].toString();
      final success = await _apiService.updateSite(siteId, siteData);
      if (success) {
        await loadSites();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Create complete site with all details
  Future<bool> createSiteFromDetails(SiteDetails details) async {
    _setLoading(true);
    if (_mockMode) {
      final map = details.toJson();
      final newId =
          (_sites.isNotEmpty ? (_sites.last['id'] as int? ?? 300) + 1 : 301);
      _sites.add({...map, 'id': newId.toString()});
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final siteData = details.toJson();
      final success = await _apiService.createSite(siteData);
      if (success) {
        await loadSites();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Save Full Site including entities
  Future<bool> saveFullSite({
    required SiteDetails details,
    required List<SiteContact> contacts,
    required List<SiteCheckpoint> checkpoints,
    required List<SiteDocument> documents,
    required List<SitePreference> preferences,
    required bool isEdit,
    Function(String)? onSiteCreated,
  }) async {
    _setLoading(true);
    if (_mockMode) {
      _setLoading(false);
      notifyListeners();
      return true;
    }
    
    try {
      String? siteId;
      if (isEdit) {
        siteId = details.id;
        if (siteId == null) {
          _errorMessage = 'Site ID is required for updates';
          _setLoading(false);
          notifyListeners();
          return false;
        }
        final success = await _apiService.updateSite(siteId, details.toJson());
        if (!success) throw Exception('Failed to update site details');
      } else {
        siteId = await _apiService.createSiteAndGetId(details.toJson());
        if (siteId == null) throw Exception('Failed to create site');
        if (onSiteCreated != null) {
          onSiteCreated(siteId);
        }
      }

      // Sync Contacts
      final existingContacts = await _apiService.getSiteContacts(siteId);
      final newContactIds = contacts.map((c) => c.id).where((id) => id != null).toSet();
      for (final ec in existingContacts) {
        final ecId = int.tryParse(ec['id']?.toString() ?? '');
        if (ecId != null && !newContactIds.contains(ecId)) {
          await _apiService.deleteSiteContact(siteId, ecId.toString());
        }
      }
      for (final c in contacts) {
        if (c.id == null) {
          await _apiService.createSiteContact(siteId, c.toJson());
        } else {
          await _apiService.updateSiteContact(siteId, c.id.toString(), c.toJson());
        }
      }

      // Sync Checkpoints
      final existingCheckpoints = await _apiService.getSiteCheckpoints(siteId);
      final newCheckpointIds = checkpoints.map((c) => c.id).where((id) => id != null).toSet();
      for (final ec in existingCheckpoints) {
        final ecId = int.tryParse(ec['id']?.toString() ?? '');
        if (ecId != null && !newCheckpointIds.contains(ecId)) {
          await _apiService.deleteSiteCheckpoint(siteId, ecId.toString());
        }
      }
      for (final c in checkpoints) {
        if (c.id == null) {
          await _apiService.createSiteCheckpoint(siteId, c.toJson());
        } else {
          await _apiService.updateSiteCheckpoint(siteId, c.id.toString(), c.toJson());
        }
      }

      // Sync Documents
      final existingDocuments = await _apiService.getSiteDocuments(siteId);
      final newDocIds = documents.map((d) => d.id).where((id) => id != null).toSet();
      for (final ed in existingDocuments) {
        final edId = int.tryParse(ed['id']?.toString() ?? '');
        if (edId != null && !newDocIds.contains(edId)) {
          await _apiService.deleteSiteDocument(siteId, edId.toString());
        }
      }
      for (final d in documents) {
        if (d.id == null) {
          await _apiService.createSiteDocument(siteId, d.toJson());
        } else {
          await _apiService.updateSiteDocument(siteId, d.id.toString(), d.toJson());
        }
      }

      // Sync Preferences
      final existingPrefs = await _apiService.getSitePreferences(siteId);
      final newPrefIds = preferences.map((p) => p.id).where((id) => id != null).toSet();
      for (final ep in existingPrefs) {
        final epId = int.tryParse(ep['id']?.toString() ?? '');
        if (epId != null && !newPrefIds.contains(epId)) {
          await _apiService.deleteSitePreference(siteId, epId.toString());
        }
      }
      for (final p in preferences) {
        if (p.id == null) {
          await _apiService.createSitePreference(siteId, p.toJson());
        } else {
          await _apiService.updateSitePreference(siteId, p.id.toString(), p.toJson());
        }
      }

      await loadSites();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update complete site with all details
  Future<bool> updateSiteFromDetails(SiteDetails details) async {
    _setLoading(true);
    if (_mockMode) {
      if (details.id == null) {
        _setLoading(false);
        notifyListeners();
        return false;
      }
      final idx = _sites.indexWhere((s) => s['id'].toString() == details.id);
      if (idx != -1) _sites[idx] = {...details.toJson(), 'id': details.id};
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      if (details.id == null) {
        _errorMessage = 'Site ID is required for updates';
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final siteData = details.toJson();
      final success = await _apiService.updateSite(details.id!, siteData);
      if (success) {
        await loadSites();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete site
  Future<bool> deleteSite(String siteId) async {
    _setLoading(true);
    if (_mockMode) {
      _sites.removeWhere((s) => s['id'].toString() == siteId);
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.deleteSite(siteId);
      if (success) {
        await loadSites();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Site Contacts
  Future<List<Map<String, dynamic>>> getSiteContacts(String siteId) async {
    if (_mockMode) return [];
    try {
      return await _apiService.getSiteContacts(siteId);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  // Site Checkpoints
  Future<List<Map<String, dynamic>>> getSiteCheckpoints(String siteId) async {
    if (_mockMode) return [];
    try {
      return await _apiService.getSiteCheckpoints(siteId);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  // Site Documents
  Future<List<Map<String, dynamic>>> getSiteDocuments(String siteId) async {
    if (_mockMode) return [];
    try {
      return await _apiService.getSiteDocuments(siteId);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  // Site Preferences
  Future<List<Map<String, dynamic>>> getSitePreferences(String siteId) async {
    if (_mockMode) return [];
    try {
      return await _apiService.getSitePreferences(siteId);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  // Create staff
  Future<bool> createStaff(Map<String, dynamic> staffData) async {
    _setLoading(true);
    if (_mockMode) {
      final newId = (_staffMembers.isNotEmpty
          ? (_staffMembers.last['id'] as int? ?? 100) + 1
          : 101);
      _staffMembers.add({...staffData, 'id': newId});
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.createStaff(staffData);
      if (success) {
        await loadStaffMembers();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Update staff
  Future<bool> updateStaff(Map<String, dynamic> staffData) async {
    _setLoading(true);
    if (_mockMode) {
      final idx = _staffMembers.indexWhere(
        (s) => s['id'].toString() == staffData['id']?.toString(),
      );
      if (idx != -1) _staffMembers[idx] = staffData;
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final staffId = staffData['id']?.toString();
      if (staffId == null || staffId.isEmpty) {
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final success = await _apiService.updateStaff(staffId, staffData);
      if (success) {
        await loadStaffMembers();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Delete staff
  Future<bool> deleteStaff(String staffId) async {
    _setLoading(true);
    if (_mockMode) {
      _staffMembers.removeWhere((s) => s['id'].toString() == staffId);
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.deleteStaff(staffId);
      if (success) {
        await loadStaffMembers();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Submit staff details (create)
  Future<String?> submitStaffDetails(Map<String, dynamic> staffData) async {
    _setLoading(true);
    if (_mockMode) {
      final newId = (_staffMembers.isNotEmpty
              ? (_staffMembers.last['id'] as int? ?? 100) + 1
              : 101)
          .toString();
      _staffMembers.add({...staffData, 'id': newId});
      _setLoading(false);
      notifyListeners();
      return newId;
    }
    try {
      final staffId = await _apiService.createStaffDetails(staffData);
      if (staffId != null) await loadStaffMembers();
      _setLoading(false);
      notifyListeners();
      return staffId;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  // Update staff details
  Future<bool> updateStaffDetails(Map<String, dynamic> staffData) async {
    _setLoading(true);
    if (_mockMode) {
      final idx = _staffMembers.indexWhere(
        (s) => s['id'].toString() == staffData['id']?.toString(),
      );
      if (idx != -1) {
        _staffMembers[idx] = {..._staffMembers[idx], ...staffData};
      }
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final staffId = staffData['id']?.toString();
      if (staffId == null) return false;
      final success = await _apiService.updateStaffDetails(staffId, staffData);
      if (success) await loadStaffMembers();
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchStaffDetails(String staffId) async {
    _setLoading(true);
    try {
      final details = await _apiService.getStaffDetails(staffId);
      _setLoading(false);
      notifyListeners();
      return details;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return null;
    }
  }

  Future<Map<String, dynamic>?> fetchStaffPrivileges(String staffId) async {
    try {
      return await _apiService.getStaffPrivileges(staffId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchStaffCompliances(
      String staffId) async {
    try {
      return await _apiService.getStaffCompliances(staffId);
    } catch (e) {
      return [];
    }
  }

  // Submit staff privileges
  Future<bool> submitStaffPrivileges(
    String staffId,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    if (_mockMode) {
      final idx = _staffMembers.indexWhere(
        (s) => s['id'].toString() == staffId,
      );
      if (idx != -1) _staffMembers[idx]['privileges'] = data['privileges'];
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.submitStaffPrivileges(staffId, data);
      if (success) await loadStaffMembers();
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Submit staff compliances
  Future<bool> submitStaffCompliances(
    String staffId,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    if (_mockMode) {
      final idx = _staffMembers.indexWhere(
        (s) => s['id'].toString() == staffId,
      );
      if (idx != -1) _staffMembers[idx]['compliances'] = data['compliances'];
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.submitStaffCompliances(staffId, data);
      if (success) await loadStaffMembers();
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Submit staff salary
  Future<bool> submitStaffSalary(
    String staffId,
    Map<String, dynamic> data,
  ) async {
    _setLoading(true);
    if (_mockMode) {
      final idx = _staffMembers.indexWhere(
        (s) => s['id'].toString() == staffId,
      );
      if (idx != -1) _staffMembers[idx]['salaryWage'] = data['salaryWage'];
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.submitStaffSalary(staffId, data);
      if (success) await loadStaffMembers();
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Mark alert as read/unread
  Future<void> markAlertAsRead(String alertId, bool isRead) async {
    if (_mockMode) {
      final index = _alerts.indexWhere((a) => a['id'].toString() == alertId);
      if (index != -1) _alerts[index]['is_read'] = isRead;
      notifyListeners();
      return;
    }
    try {
      await _apiService.markAlertAsRead(alertId);
      final index = _alerts.indexWhere((a) => a['id'].toString() == alertId);
      if (index != -1) {
        _alerts[index]['is_read'] = isRead;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Delete alert
  Future<bool> deleteAlert(String alertId) async {
    if (_mockMode) {
      _alerts.removeWhere((a) => a['id'].toString() == alertId);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.deleteAlert(alertId);
      if (success) {
        _alerts.removeWhere((a) => a['id'].toString() == alertId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Mark all alerts as read
  Future<void> markAllAlertsAsRead() async {
    if (_mockMode) {
      for (var alert in _alerts) {
        alert['is_read'] = true;
      }
      notifyListeners();
      return;
    }
    try {
      await _apiService.markAllAlertsAsRead();
      for (var alert in _alerts) {
        alert['is_read'] = true;
      }
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
    }
  }

  // Shift Management Methods
  Future<void> loadShifts() async {
    if (_mockMode) {
      if (_shifts.isEmpty) {
        _shifts = _fallbackShifts();
      }
      notifyListeners();
      return;
    }
    try {
      _shifts = await _apiService.getShifts();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_shifts.isEmpty) _shifts = _fallbackShifts();
      notifyListeners();
    }
  }

  Future<void> loadLiveOperations() async {
    _setLoading(true);
    try {
      final response = await _apiService.getLiveOperations();
      _liveShifts = List<Map<String, dynamic>>.from(response['active_shifts'] ?? []);
      _liveAlerts = List<Map<String, dynamic>>.from(response['recent_alerts'] ?? []);
      _liveCheckins = List<Map<String, dynamic>>.from(response['recent_checkins'] ?? []);
      _liveSummary = Map<String, dynamic>.from(response['summary'] ?? {});
    } catch (e) {
      _errorMessage = e.toString();
      _liveShifts = [];
      _liveAlerts = [];
      _liveCheckins = [];
      _liveSummary = {};
    }
    _setLoading(false);
    notifyListeners();
  }

  List<Map<String, dynamic>> _fallbackShifts() {
    return [
      {
        'id': 1001,
        'customerId': 201,
        'customerName': 'John Corporation',
        'siteId': 301,
        'siteName': 'Main Office Building',
        'serviceType': 'Guard',
        'securityOfficerId': 101,
        'securityOfficerName': 'Emma Stone',
        'date': '2026-03-05',
        'startTime': '08:00',
        'endTime': '20:00',
        'mealBreakDuration': 60,
        'serviceGroup': 'Day Shift Security',
        'payGroup': 'Standard Rate',
        'customerPO': 'PO-2026-001',
        'clockInQuestionnaire': 'Site Specific',
        'status': 'Scheduled',
        'createdDate': '2026-03-01',
      },
    ];
  }

  Future<bool> createShift(Map<String, dynamic> shiftData) async {
    _setLoading(true);
    if (_mockMode) {
      final newId = (_shifts.isNotEmpty
          ? (_shifts.last['id'] as int? ?? 1000) + 1
          : 1001);
      _shifts.add({...shiftData, 'id': newId});
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.createShift(shiftData);
      if (success) {
        await loadShifts();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateShift(Map<String, dynamic> shiftData) async {
    _setLoading(true);
    if (_mockMode) {
      final shiftId = shiftData['id']?.toString();
      if (shiftId == null || shiftId.isEmpty) {
        _setLoading(false);
        notifyListeners();
        return false;
      }
      final idx = _shifts.indexWhere((s) => s['id'].toString() == shiftId);
      if (idx != -1) _shifts[idx] = shiftData;
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final shiftId = shiftData['id']?.toString();
      if (shiftId == null || shiftId.isEmpty) {
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final success = await _apiService.updateShift(shiftId, shiftData);
      if (success) {
        await loadShifts();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteShift(String shiftId) async {
    _setLoading(true);
    if (_mockMode) {
      _shifts.removeWhere((s) => s['id'].toString() == shiftId);
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.deleteShift(shiftId);
      if (success) {
        await loadShifts();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Shift Notes Management
  Future<void> loadShiftNotes() async {
    if (_mockMode) {
      _shiftNotes = _fallbackShiftNotes();
      notifyListeners();
      return;
    }
    try {
      _shiftNotes = await _apiService.getShiftNotes();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_shiftNotes.isEmpty) _shiftNotes = _fallbackShiftNotes();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fallbackShiftNotes() {
    return [
      {
        'id': 2001,
        'type': 'internal',
        'note':
            'Security officer performed excellent during night shift. All protocols followed.',
        'shiftId': 1001,
        'createdBy': 'Admin',
        'createdDate': '2026-03-02',
      },
    ];
  }

  Future<bool> createShiftNote(Map<String, dynamic> noteData) async {
    _setLoading(true);
    if (_mockMode) {
      final newId = (_shiftNotes.isNotEmpty
          ? (_shiftNotes.last['id'] as int? ?? 2000) + 1
          : 2001);
      _shiftNotes.add({...noteData, 'id': newId});
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.createShiftNote(noteData);
      if (success) {
        await loadShiftNotes();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateShiftNote(Map<String, dynamic> noteData) async {
    _setLoading(true);
    if (_mockMode) {
      final noteId = noteData['id']?.toString();
      if (noteId == null || noteId.isEmpty) {
        _setLoading(false);
        notifyListeners();
        return false;
      }
      final idx = _shiftNotes.indexWhere((n) => n['id'].toString() == noteId);
      if (idx != -1) _shiftNotes[idx] = noteData;
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final noteId = noteData['id']?.toString();
      if (noteId == null || noteId.isEmpty) {
        _setLoading(false);
        notifyListeners();
        return false;
      }

      final success = await _apiService.updateShiftNote(noteId, noteData);
      if (success) {
        await loadShiftNotes();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteShiftNote(String noteId) async {
    _setLoading(true);
    if (_mockMode) {
      _shiftNotes.removeWhere((n) => n['id'].toString() == noteId);
      _setLoading(false);
      notifyListeners();
      return true;
    }
    try {
      final success = await _apiService.deleteShiftNote(noteId);
      if (success) {
        await loadShiftNotes();
      }
      _setLoading(false);
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  // Helper Methods for Dropdowns
  Future<void> loadSecurityOfficers() async {
    if (_mockMode) {
      _securityOfficers = _fallbackSecurityOfficers();
      notifyListeners();
      return;
    }
    try {
      _securityOfficers = await _apiService.getSecurityOfficers();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_securityOfficers.isEmpty) _securityOfficers = _fallbackSecurityOfficers();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fallbackSecurityOfficers() {
    return [
      {
        'id': 101,
        'name': 'Emma Stone',
        'role': 'Security Guard',
        'isOffered': true,
      },
      {
        'id': 102,
        'name': 'John Smith',
        'role': 'Security Guard',
        'isOffered': true,
      },
    ];
  }

  Future<List<Map<String, dynamic>>> getCustomerSites(String customerId) async {
    if (_mockMode) {
      return _sites
              .where((s) => s['customerId']?.toString() == customerId)
              .toList()
              .isNotEmpty
          ? _sites
              .where((s) => s['customerId']?.toString() == customerId)
              .toList()
          : [
              {
                'id': 301,
                'name': 'Main Office Building',
                'address': '123 Business Street, London',
              },
            ];
    }
    try {
      return await _apiService.getCustomerSites(customerId);
    } catch (e) {
      _errorMessage = e.toString();
      return [];
    }
  }

  Future<bool> attachSiteToCustomer(String customerId, String siteId) async {
    if (_mockMode) {
      notifyListeners();
      return true;
    }
    try {
      final success =
          await _apiService.attachSiteToCustomer(customerId, siteId);
      if (success) {
        await loadSites();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<bool> detachSiteFromCustomer(String customerId, String siteId) async {
    if (_mockMode) {
      notifyListeners();
      return true;
    }
    try {
      final success =
          await _apiService.detachSiteFromCustomer(customerId, siteId);
      if (success) {
        await loadSites();
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  Future<void> loadServiceGroups() async {
    if (_mockMode) {
      _serviceGroups = _fallbackServiceGroups();
      notifyListeners();
      return;
    }
    try {
      _serviceGroups = await _apiService.getServiceGroups();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_serviceGroups.isEmpty) _serviceGroups = _fallbackServiceGroups();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fallbackServiceGroups() {
    return [
      {'id': 1, 'name': 'Day Shift Security'},
      {'id': 2, 'name': 'Night Shift Security'},
      {'id': 3, 'name': 'Event Security'},
      {'id': 4, 'name': 'Mobile Patrol'},
    ];
  }

  Future<void> loadPayGroups() async {
    if (_mockMode) {
      _payGroups = _fallbackPayGroups();
      notifyListeners();
      return;
    }
    try {
      _payGroups = await _apiService.getPayGroups();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_payGroups.isEmpty) _payGroups = _fallbackPayGroups();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fallbackPayGroups() {
    return [
      {
        'id': 100,
        'name': 'Standard Rate',
        'type': 'hourly',
        'pay_rate': 25.0,
      },
    ];
  }

  Future<void> loadOrganizationCompliances() async {
    if (_mockMode) {
      _organizationCompliances = [
        {'id': 1, 'name': 'SIA License'},
        {'id': 2, 'name': 'Right To Work'},
      ];
      notifyListeners();
      return;
    }
    try {
      _organizationCompliances = await _apiService.getOrganizationCompliances();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_organizationCompliances.isEmpty) {
        _organizationCompliances = [
          {'id': 1, 'name': 'SIA License'},
          {'id': 2, 'name': 'Right To Work'},
        ];
      }
      notifyListeners();
    }
  }

  Future<void> loadClockInQuestionnaires() async {
    if (_mockMode) {
      _clockInQuestionnaires = _fallbackClockInQuestionnaires();
      notifyListeners();
      return;
    }
    try {
      _clockInQuestionnaires = await _apiService.getClockInQuestionnaires();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      if (_clockInQuestionnaires.isEmpty) _clockInQuestionnaires = _fallbackClockInQuestionnaires();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> _fallbackClockInQuestionnaires() {
    return [
      {'id': 1, 'name': 'Global', 'type': 'global'},
      {'id': 2, 'name': 'Site Specific', 'type': 'site'},
    ];
  }

  List<Timesheet> _fallbackTimesheets() {
    final now = DateTime.now();
    return [
      Timesheet(
        id: 'TS001',
        shiftId: 'SH001',
        entryType: 'work',
        siteId: '301',
        siteName: 'Main Office Building',
        customerId: '201',
        customerName: 'John Corporation',
        staffId: '101',
        staffName: 'Emma Stone',
        serviceGroup: 'Day Shift Security',
        serviceGroupId: 'SG001',
        payGroup: 'Standard Rate',
        payGroupId: 'PG001',
        clockInTime: now.subtract(const Duration(days: 1, hours: 8)),
        clockOutTime: now.subtract(const Duration(days: 1)),
        breakMinutes: 60,
        status: TimesheetStatus.drafted,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      Timesheet(
        id: 'TS002',
        shiftId: 'SH002',
        entryType: 'work',
        siteId: '302',
        siteName: 'Market Place',
        customerId: '201',
        customerName: 'John Corporation',
        staffId: '102',
        staffName: 'John Smith',
        serviceGroup: 'Night Shift Security',
        serviceGroupId: 'SG002',
        payGroup: 'Night Rate',
        payGroupId: 'PG002',
        clockInTime: now.subtract(const Duration(days: 2, hours: 12)),
        clockOutTime: now.subtract(const Duration(days: 2)),
        breakMinutes: 30,
        status: TimesheetStatus.approved,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      Timesheet(
        id: 'TS003',
        shiftId: 'SH003',
        entryType: 'work',
        siteId: '303',
        siteName: 'Tech Park East',
        customerId: '202',
        customerName: 'Tech Solutions Ltd',
        staffId: '101',
        staffName: 'Emma Stone',
        serviceGroup: 'Day Shift Security',
        serviceGroupId: 'SG001',
        payGroup: 'Standard Rate',
        payGroupId: 'PG001',
        clockInTime: now.subtract(const Duration(days: 3, hours: 10)),
        clockOutTime: now.subtract(const Duration(days: 3, hours: 2)),
        breakMinutes: 45,
        status: TimesheetStatus.drafted,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  // Timesheet Management
  Future<void> loadTimesheets() async {
    if (_mockMode) {
      _timesheets = _fallbackTimesheets();
      notifyListeners();
      return;
    }
    try {
      final timesheetsData = await _apiService.getTimesheets();
      _timesheets =
          timesheetsData.map((data) => Timesheet.fromJson(data)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _timesheets = _fallbackTimesheets();
      notifyListeners();
    }
  }

  Future<bool> updateTimesheet(Timesheet timesheet) async {
    if (_mockMode) {
      final index = _timesheets.indexWhere((t) => t.id == timesheet.id);
      if (index != -1) {
        _timesheets[index] = timesheet;
        notifyListeners();
      }
      return true;
    }
    try {
      await _apiService.updateTimesheet(timesheet.id, timesheet.toJson());

      // Update local list
      final index = _timesheets.indexWhere((t) => t.id == timesheet.id);
      if (index != -1) {
        _timesheets[index] = timesheet;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> approveTimesheet(String timesheetId) async {
    if (_mockMode) {
      final index = _timesheets.indexWhere((t) => t.id == timesheetId);
      if (index != -1) {
        _timesheets[index] = _timesheets[index].copyWith(
          status: TimesheetStatus.approved,
        );
        notifyListeners();
      }
      return true;
    }
    try {
      await _apiService.approveTimesheet(timesheetId);

      // Update local status
      final index = _timesheets.indexWhere((t) => t.id == timesheetId);
      if (index != -1) {
        _timesheets[index] = _timesheets[index].copyWith(
          status: TimesheetStatus.approved,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectTimesheet(String timesheetId, String reason) async {
    if (_mockMode) {
      final index = _timesheets.indexWhere((t) => t.id == timesheetId);
      if (index != -1) {
        _timesheets[index] = _timesheets[index].copyWith(
          status: TimesheetStatus.rejected,
        );
        notifyListeners();
      }
      return true;
    }
    try {
      await _apiService.rejectTimesheet(timesheetId, reason);

      // Update local status
      final index = _timesheets.indexWhere((t) => t.id == timesheetId);
      if (index != -1) {
        _timesheets[index] = _timesheets[index].copyWith(
          status: TimesheetStatus.rejected,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Refresh data
  Future<void> refresh() async {
    await initialize();
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
