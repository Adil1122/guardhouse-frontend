import 'package:flutter/material.dart';
import '../models/site_models.dart';

enum SiteCreationStep {
  details,
  contacts,
  checkpoints,
  documents,
  preferences,
}

class SiteCreationProvider extends ChangeNotifier {
  late SiteDetails _details;
  List<SiteContact> _contacts = [];
  List<SiteCheckpoint> _checkpoints = [];
  List<SiteDocument> _documents = [];
  List<SitePreference> _preferences = [];
  List<String> _incidentReportFormIds = [];
  List<String> _clockInQuestionnaireFormIds = [];
  List<String> _accessCodeFormIds = [];
  String? _instructions;

  SiteCreationStep _currentStep = SiteCreationStep.details;
  bool isEdit;

  SiteCreationProvider({
    SiteDetails? initialDetails,
    List<SiteContact>? initialContacts,
    List<SiteCheckpoint>? initialCheckpoints,
    List<SiteDocument>? initialDocuments,
    List<SitePreference>? initialPreferences,
    SiteCreationStep? initialStep,
  }) : isEdit = initialDetails != null {
    _details = initialDetails ??
        SiteDetails(
          type: 'static',
          name: '',
          customerId: '',
          address: SiteAddress(
            name: '',
            city: '',
            state: '',
            zip: '',
            country: '',
          ),
          geofence: Geofence(
            placeId: '',
            lat: 0.0,
            lon: 0.0,
            checkInDistance: 100,
          ),
        );
    _contacts = initialContacts ?? [];
    _checkpoints = initialCheckpoints ?? [];
    _documents = initialDocuments ?? [];
    _preferences = initialPreferences ?? [];
    _currentStep = initialStep ?? SiteCreationStep.details;
  }

  // Getters
  SiteDetails get details => _details;
  List<SiteContact> get contacts => _contacts;
  List<SiteCheckpoint> get checkpoints => _checkpoints;
  List<SiteDocument> get documents => _documents;
  List<SitePreference> get preferences => _preferences;
  List<String> get incidentReportFormIds => _incidentReportFormIds;
  List<String> get clockInQuestionnaireFormIds => _clockInQuestionnaireFormIds;
  List<String> get accessCodeFormIds => _accessCodeFormIds;
  String? get instructions => _instructions;

  SiteCreationStep get currentStep => _currentStep;
  int get currentStepIndex => _currentStep.index;
  int get totalSteps => SiteCreationStep.values.length;
  double get progress => (currentStepIndex + 1) / totalSteps;

  bool get canGoNext {
    if (_currentStep == SiteCreationStep.details) {
      return _isDetailsValid();
    }
    return true;
  }

  bool get canGoPrevious => currentStepIndex > 0;

  // Validation helpers
  bool _isDetailsValid() {
    return _details.name.isNotEmpty &&
        (_details.customerId?.isNotEmpty ?? false) &&
        _details.address.name.isNotEmpty &&
        _details.address.city.isNotEmpty;
  }

  // Navigation methods
  void goToStep(SiteCreationStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void goNext() {
    if (canGoNext && currentStepIndex < totalSteps - 1) {
      _currentStep = SiteCreationStep.values[currentStepIndex + 1];
      notifyListeners();
    }
  }

  void goPrevious() {
    if (canGoPrevious) {
      _currentStep = SiteCreationStep.values[currentStepIndex - 1];
      notifyListeners();
    }
  }

  // Update methods for details
  void updateDetails(SiteDetails details) {
    _details = details;
    notifyListeners();
  }

  // Update methods for contacts
  void updateContacts(List<SiteContact> contacts) {
    _contacts = contacts;
    notifyListeners();
  }

  void addContact(SiteContact contact) {
    _contacts.add(contact);
    notifyListeners();
  }

  void updateContact(int index, SiteContact contact) {
    if (index >= 0 && index < _contacts.length) {
      _contacts[index] = contact;
      notifyListeners();
    }
  }

  void removeContact(int index) {
    if (index >= 0 && index < _contacts.length) {
      _contacts.removeAt(index);
      notifyListeners();
    }
  }

  // Update methods for checkpoints
  void updateCheckpoints(List<SiteCheckpoint> checkpoints) {
    _checkpoints = checkpoints;
    notifyListeners();
  }

  void addCheckpoint(SiteCheckpoint checkpoint) {
    _checkpoints.add(checkpoint);
    notifyListeners();
  }

  void updateCheckpoint(int index, SiteCheckpoint checkpoint) {
    if (index >= 0 && index < _checkpoints.length) {
      _checkpoints[index] = checkpoint;
      notifyListeners();
    }
  }

  void removeCheckpoint(int index) {
    if (index >= 0 && index < _checkpoints.length) {
      _checkpoints.removeAt(index);
      notifyListeners();
    }
  }

  // Update methods for documents
  void updateDocuments(List<SiteDocument> documents) {
    _documents = documents;
    notifyListeners();
  }

  void addDocument(SiteDocument document) {
    _documents.add(document);
    notifyListeners();
  }

  void removeDocument(int index) {
    if (index >= 0 && index < _documents.length) {
      _documents.removeAt(index);
      notifyListeners();
    }
  }

  // Update methods for preferences
  void updatePreferences(List<SitePreference> preferences) {
    _preferences = preferences;
    notifyListeners();
  }

  void addPreference(SitePreference preference) {
    _preferences.add(preference);
    notifyListeners();
  }

  void updatePreference(int index, SitePreference preference) {
    if (index >= 0 && index < _preferences.length) {
      _preferences[index] = preference;
      notifyListeners();
    }
  }

  void removePreference(int index) {
    if (index >= 0 && index < _preferences.length) {
      _preferences.removeAt(index);
      notifyListeners();
    }
  }

  // Update methods for incident report forms
  void updateIncidentReportFormIds(List<String> formIds) {
    _incidentReportFormIds = formIds;
    notifyListeners();
  }

  void addIncidentReportFormId(String formId) {
    if (!_incidentReportFormIds.contains(formId)) {
      _incidentReportFormIds.add(formId);
      notifyListeners();
    }
  }

  void removeIncidentReportFormId(String formId) {
    _incidentReportFormIds.remove(formId);
    notifyListeners();
  }

  // Update methods for clock-in questionnaire forms
  void updateClockInQuestionnaireFormIds(List<String> formIds) {
    _clockInQuestionnaireFormIds = formIds;
    notifyListeners();
  }

  void addClockInQuestionnaireFormId(String formId) {
    if (!_clockInQuestionnaireFormIds.contains(formId)) {
      _clockInQuestionnaireFormIds.add(formId);
      notifyListeners();
    }
  }

  void removeClockInQuestionnaireFormId(String formId) {
    _clockInQuestionnaireFormIds.remove(formId);
    notifyListeners();
  }

  // Update methods for access code forms
  void updateAccessCodeFormIds(List<String> formIds) {
    _accessCodeFormIds = formIds;
    notifyListeners();
  }

  void addAccessCodeFormId(String formId) {
    if (!_accessCodeFormIds.contains(formId)) {
      _accessCodeFormIds.add(formId);
      notifyListeners();
    }
  }

  void removeAccessCodeFormId(String formId) {
    _accessCodeFormIds.remove(formId);
    notifyListeners();
  }

  // Update methods for instructions
  void updateInstructions(String? instructions) {
    _instructions = instructions;
    notifyListeners();
  }

  // Reset to initial state
  void reset() {
    _currentStep = SiteCreationStep.details;
    _details = SiteDetails(
      type: 'static',
      name: '',
      customerId: '',
      address: SiteAddress(
        name: '',
        city: '',
        state: '',
        zip: '',
        country: '',
      ),
      geofence: Geofence(
        placeId: '',
        lat: 0.0,
        lon: 0.0,
        checkInDistance: 100,
      ),
    );
    _contacts = [];
    _checkpoints = [];
    _documents = [];
    _preferences = [];
    notifyListeners();
  }
}

String stepTitle(SiteCreationStep step) {
  switch (step) {
    case SiteCreationStep.details:
      return 'Site Details';
    case SiteCreationStep.contacts:
      return 'Contacts';
    case SiteCreationStep.checkpoints:
      return 'Checkpoints';
    case SiteCreationStep.documents:
      return 'Documents';
    case SiteCreationStep.preferences:
      return 'Preferences';
  }
}

String stepDescription(SiteCreationStep step) {
  switch (step) {
    case SiteCreationStep.details:
      return 'Basic site information and location';
    case SiteCreationStep.contacts:
      return 'Site contact information';
    case SiteCreationStep.checkpoints:
      return 'Geofenced locations and checkpoints';
    case SiteCreationStep.documents:
      return 'Site documents and files';
    case SiteCreationStep.preferences:
      return 'Staff preferences for this site';
  }
}
