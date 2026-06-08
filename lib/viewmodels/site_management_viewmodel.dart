import 'package:flutter/foundation.dart';
import '../services/admin_api_service.dart';
import '../models/site_models.dart';

class SiteManagementViewModel extends ChangeNotifier {
  final AdminApiService _apiService;

  bool _isLoading = false;
  String? _errorMessage;
  List<Site> _sites = [];
  Map<String, List<SiteContact>> _siteContacts = {};
  Map<String, List<SiteCheckpoint>> _siteCheckpoints = {};
  Map<String, List<SitePreference>> _sitePreferences = {};
  Map<String, List<SiteDocument>> _siteDocuments = {};

  SiteManagementViewModel(this._apiService);

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Site> get sites => _sites;

  Map<String, List<SiteContact>> get siteContacts => _siteContacts;
  Map<String, List<SiteCheckpoint>> get siteCheckpoints => _siteCheckpoints;
  Map<String, List<SitePreference>> get sitePreferences => _sitePreferences;
  Map<String, List<SiteDocument>> get siteDocuments => _siteDocuments;

  List<SiteContact> getContactsForSite(String siteId) =>
      _siteContacts[siteId] ?? [];
  List<SiteCheckpoint> getCheckpointsForSite(String siteId) =>
      _siteCheckpoints[siteId] ?? [];
  List<SitePreference> getPreferencesForSite(String siteId) =>
      _sitePreferences[siteId] ?? [];
  List<SiteDocument> getDocumentsForSite(String siteId) =>
      _siteDocuments[siteId] ?? [];

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Load all sites
  Future<void> loadSites() async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _apiService.getSites();
      _sites = data.map((item) => Site.fromJson(item)).toList();
    } catch (e) {
      _setError('Failed to load sites: $e');
    }
    _setLoading(false);
  }

  // Create Site
  Future<bool> createSite(Map<String, dynamic> siteData) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _apiService.createSite(siteData);
      if (success) {
        await loadSites();
      }
      return success;
    } catch (e) {
      _setError('Failed to create site: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update Site
  Future<bool> updateSite(String siteId, Map<String, dynamic> siteData) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _apiService.updateSite(siteId, siteData);
      if (success) {
        await loadSites();
      }
      return success;
    } catch (e) {
      _setError('Failed to update site: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete Site
  Future<bool> deleteSite(String siteId) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _apiService.deleteSite(siteId);
      if (success) {
        _sites.removeWhere((site) => site.id.toString() == siteId);
        _siteContacts.remove(siteId);
        _siteCheckpoints.remove(siteId);
        _sitePreferences.remove(siteId);
        _siteDocuments.remove(siteId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to delete site: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Site Contacts ===================

  Future<void> loadSiteContacts(String siteId) async {
    _setLoading(true);
    try {
      final data = await _apiService.getSiteContacts(siteId);
      _siteContacts[siteId] =
          data.map((item) => SiteContact.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load contacts: $e');
    }
    _setLoading(false);
  }

  Future<bool> createSiteContact(
      String siteId, Map<String, dynamic> contactData) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _apiService.createSiteContact(siteId, contactData);
      if (success) {
        await loadSiteContacts(siteId);
      }
      return success;
    } catch (e) {
      _setError('Failed to create contact: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateSiteContact(
    String siteId,
    String contactId,
    Map<String, dynamic> contactData,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      final success =
          await _apiService.updateSiteContact(siteId, contactId, contactData);
      if (success) {
        await loadSiteContacts(siteId);
      }
      return success;
    } catch (e) {
      _setError('Failed to update contact: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteSiteContact(String siteId, String contactId) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _apiService.deleteSiteContact(siteId, contactId);
      if (success) {
        _siteContacts[siteId]?.removeWhere((c) => c.id.toString() == contactId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to delete contact: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Site Checkpoints ===================

  Future<void> loadSiteCheckpoints(String siteId) async {
    _setLoading(true);
    try {
      final data = await _apiService.getSiteCheckpoints(siteId);
      _siteCheckpoints[siteId] =
          data.map((item) => SiteCheckpoint.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load checkpoints: $e');
    }
    _setLoading(false);
  }

  Future<bool> createSiteCheckpoint(
      String siteId, Map<String, dynamic> checkpointData) async {
    _setLoading(true);
    _setError(null);
    try {
      final success =
          await _apiService.createSiteCheckpoint(siteId, checkpointData);
      if (success) {
        await loadSiteCheckpoints(siteId);
      }
      return success;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateSiteCheckpoint(
    String siteId,
    String checkpointId,
    Map<String, dynamic> checkpointData,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _apiService.updateSiteCheckpoint(
          siteId, checkpointId, checkpointData);
      if (success) {
        await loadSiteCheckpoints(siteId);
      }
      return success;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteSiteCheckpoint(String siteId, String checkpointId) async {
    _setLoading(true);
    _setError(null);
    try {
      final success =
          await _apiService.deleteSiteCheckpoint(siteId, checkpointId);
      if (success) {
        _siteCheckpoints[siteId]
            ?.removeWhere((cp) => cp.id.toString() == checkpointId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Site Preferences ===================

  Future<void> loadSitePreferences(String siteId) async {
    _setLoading(true);
    try {
      final data = await _apiService.getSitePreferences(siteId);
      _sitePreferences[siteId] =
          data.map((item) => SitePreference.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load preferences: $e');
    }
    _setLoading(false);
  }

  Future<bool> createSitePreference(
      String siteId, Map<String, dynamic> preferenceData) async {
    _setLoading(true);
    _setError(null);
    try {
      final success =
          await _apiService.createSitePreference(siteId, preferenceData);
      if (success) {
        await loadSitePreferences(siteId);
      }
      return success;
    } catch (e) {
      _setError('Failed to create preference: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateSitePreference(
    String siteId,
    String preferenceId,
    Map<String, dynamic> preferenceData,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _apiService.updateSitePreference(
          siteId, preferenceId, preferenceData);
      if (success) {
        await loadSitePreferences(siteId);
      }
      return success;
    } catch (e) {
      _setError('Failed to update preference: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteSitePreference(String siteId, String preferenceId) async {
    _setLoading(true);
    _setError(null);
    try {
      final success =
          await _apiService.deleteSitePreference(siteId, preferenceId);
      if (success) {
        _sitePreferences[siteId]
            ?.removeWhere((sp) => sp.id.toString() == preferenceId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Failed to delete preference: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== Site Documents ===================

  Future<void> loadSiteDocuments(String siteId) async {
    _setLoading(true);
    try {
      final data = await _apiService.getSiteDocuments(siteId);
      _siteDocuments[siteId] =
          data.map((item) => SiteDocument.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load documents: $e');
    }
    _setLoading(false);
  }

  Future<bool> createSiteDocument(
      String siteId, Map<String, dynamic> documentData) async {
    _setLoading(true);
    _setError(null);
    try {
      final success =
          await _apiService.createSiteDocument(siteId, documentData);
      if (success) {
        await loadSiteDocuments(siteId);
      }
      return success;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateSiteDocument(
    String siteId,
    String documentId,
    Map<String, dynamic> documentData,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _apiService.updateSiteDocument(
          siteId, documentId, documentData);
      if (success) {
        await loadSiteDocuments(siteId);
      }
      return success;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteSiteDocument(String siteId, String documentId) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _apiService.deleteSiteDocument(siteId, documentId);
      if (success) {
        _siteDocuments[siteId]
            ?.removeWhere((d) => d.id.toString() == documentId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError(e.toString().replaceFirst('Exception: ', ''));
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
