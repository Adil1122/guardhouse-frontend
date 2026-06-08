enum FormTemplateType {
  incidentReport,
  welfareCheckReport,
  maintenanceReport,
  securityBreach,
  mentalWellnessStaffAudit;

  String get apiValue {
    switch (this) {
      case FormTemplateType.incidentReport:
        return 'incident-report';
      case FormTemplateType.welfareCheckReport:
        return 'welfare-check-report';
      case FormTemplateType.maintenanceReport:
        return 'maintaince-report'; // Backend has typo
      case FormTemplateType.securityBreach:
        return 'security-breach';
      case FormTemplateType.mentalWellnessStaffAudit:
        return 'mental-wellness-staff-audit';
    }
  }

  String get displayName {
    switch (this) {
      case FormTemplateType.incidentReport:
        return 'Incident Report';
      case FormTemplateType.welfareCheckReport:
        return 'Welfare Check Report';
      case FormTemplateType.maintenanceReport:
        return 'Maintenance Report';
      case FormTemplateType.securityBreach:
        return 'Security Breach';
      case FormTemplateType.mentalWellnessStaffAudit:
        return 'Mental Wellness Staff Audit';
    }
  }

  static FormTemplateType fromApiValue(String? value) {
    if (value == null) return FormTemplateType.incidentReport;
    switch (value) {
      case 'incident-report':
        return FormTemplateType.incidentReport;
      case 'welfare-check-report':
        return FormTemplateType.welfareCheckReport;
      case 'maintaince-report':
      case 'maintenance-report':
        return FormTemplateType.maintenanceReport;
      case 'security-breach':
        return FormTemplateType.securityBreach;
      case 'mental-wellness-staff-audit':
        return FormTemplateType.mentalWellnessStaffAudit;
      default:
        return FormTemplateType.incidentReport;
    }
  }
}

enum TemplateFieldType { text, textarea, date, time, file, boolean, signature }

extension TemplateFieldTypeExtension on TemplateFieldType {
  String get apiValue => name;
}

class FormElement {
  final String? id;
  final TemplateFieldType fieldType;
  final String title;

  FormElement({this.id, required this.fieldType, required this.title});

  FormElement copyWith({
    String? id,
    TemplateFieldType? fieldType,
    String? title,
  }) {
    return FormElement(
      id: id ?? this.id,
      fieldType: fieldType ?? this.fieldType,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'type': fieldType.apiValue,
      'title': title,
    };
  }

  factory FormElement.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String?) ?? 'text';
    final fieldType = TemplateFieldType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => TemplateFieldType.text,
    );

    return FormElement(
      id: json['id']?.toString(),
      fieldType: fieldType,
      title: json['title'] as String? ?? '',
    );
  }
}

class FormTemplate {
  final String? id;
  final String name;
  final FormTemplateType type;
  final List<FormElement> elements;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FormTemplate({
    this.id,
    required this.name,
    required this.type,
    this.elements = const [],
    this.createdAt,
    this.updatedAt,
  });

  FormTemplate copyWith({
    String? id,
    String? name,
    FormTemplateType? type,
    List<FormElement>? elements,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FormTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      elements: elements ?? this.elements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.apiValue,
      'elements': elements.map((e) => e.toJson()).toList(),
    };
  }

  factory FormTemplate.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String?) ?? 'incident-report';
    
    final elementsData = json['elements'];
    List<FormElement> elementsList = [];
    if (elementsData is List) {
      elementsList = elementsData
          .map((e) => FormElement.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return FormTemplate(
      id: json['id']?.toString(),
      name: json['name'] as String? ?? '',
      type: FormTemplateType.fromApiValue(typeStr),
      elements: elementsList,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
