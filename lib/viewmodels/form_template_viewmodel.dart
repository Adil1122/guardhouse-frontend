import 'package:flutter/foundation.dart';

import '../models/form_template_model.dart';
import '../services/admin_api_service.dart';

class FormTemplateViewModel extends ChangeNotifier {
  final AdminApiService _apiService;

  static const bool _mockMode = false;

  List<FormTemplate> _templates = [];
  bool _isLoading = false;
  String? _error;

  List<FormTemplate> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalTemplates => _templates.length;
  int get totalElements =>
      _templates.fold(0, (sum, template) => sum + template.elements.length);

  FormTemplateViewModel(this._apiService);

  Future<void> loadTemplates() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    if (_mockMode) {
      _templates = _fallbackTemplates();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final templatesData = await _apiService.getFormTemplates();
      _templates = templatesData
          .map((data) => FormTemplate.fromJson(data))
          .toList();
      _isLoading = false;
      notifyListeners();
      
      debugPrint('Loaded ${_templates.length} form templates');
      for (final t in _templates) {
        debugPrint('FormTemplate: id=${t.id}, name=${t.name}, type=${t.type.apiValue}, elements=${t.elements.length}');
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _templates = [];
      notifyListeners();
      debugPrint('Error loading form templates: $_error');
    }
  }

  Future<void> createTemplate(FormTemplate template) async {
    if (_mockMode) {
      _templates.insert(0, template);
      notifyListeners();
      return;
    }
    try {
      final result = await _apiService.createFormTemplate(template.toJson());
      final newTemplate = FormTemplate.fromJson(result);
      _templates.insert(0, newTemplate);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTemplate(FormTemplate template) async {
    if (_mockMode) {
      final index = _templates.indexWhere((t) => t.id == template.id);
      if (index != -1) {
        _templates[index] = template.copyWith(updatedAt: DateTime.now());
        notifyListeners();
      }
      return;
    }
    try {
      await _apiService.updateFormTemplate(template.id!, template.toJson());
      final index = _templates.indexWhere((t) => t.id == template.id);
      if (index != -1) {
        _templates[index] = template.copyWith(updatedAt: DateTime.now());
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> deleteTemplate(String id) async {
    if (_mockMode) {
      _templates.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    }
    try {
      await _apiService.deleteFormTemplate(id);
      _templates.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  List<FormTemplate> _fallbackTemplates() {
    return [
      FormTemplate(
        name: 'Main Incident Template',
        type: FormTemplateType.incidentReport,
        elements: [
          FormElement(
            fieldType: TemplateFieldType.text,
            title: 'Incident Short Title',
          ),
          FormElement(
            fieldType: TemplateFieldType.textarea,
            title: 'Incident Description',
          ),
          FormElement(
            fieldType: TemplateFieldType.date,
            title: 'Incident Date',
          ),
          FormElement(
            fieldType: TemplateFieldType.signature,
            title: 'Supervisor Signature',
          ),
        ],
      ),
      FormTemplate(
        name: 'Welfare Check Standard',
        type: FormTemplateType.welfareCheckReport,
        elements: [
          FormElement(
            fieldType: TemplateFieldType.text,
            title: 'Staff Name',
          ),
          FormElement(
            fieldType: TemplateFieldType.boolean,
            title: 'Fitness To Work',
          ),
          FormElement(
            fieldType: TemplateFieldType.textarea,
            title: 'Comments',
          ),
        ],
      ),
    ];
  }
}
