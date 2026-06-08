import 'package:uuid/uuid.dart';

class SiteAddress {
  final String name; // name field as per API
  final String city;
  final String state;
  final String zip;
  final String country;

  SiteAddress({
    required this.name,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'city': city,
        'state': state,
        'zip': zip,
        'country': country,
      };

  factory SiteAddress.fromJson(Map<String, dynamic> json) => SiteAddress(
        name: json['name'] ?? '',
        city: json['city'] ?? '',
        state: json['state'] ?? '',
        zip: json['zip'] ?? '',
        country: json['country'] ?? '',
      );

  SiteAddress copyWith({
    String? name,
    String? city,
    String? state,
    String? zip,
    String? country,
  }) =>
      SiteAddress(
        name: name ?? this.name,
        city: city ?? this.city,
        state: state ?? this.state,
        zip: zip ?? this.zip,
        country: country ?? this.country,
      );
}

class Geofence {
  final String? placeId;
  final double? lat;
  final double? lon;
  final int? checkInDistance; // in meters

  Geofence({
    this.placeId,
    this.lat,
    this.lon,
    this.checkInDistance,
  });

  Map<String, dynamic> toJson() => {
        'place_id': placeId ?? '',
        'lat': lat ?? 0.0,
        'lon': lon ?? 0.0,
        'check_in_distance': checkInDistance ?? 100,
      };

  factory Geofence.fromJson(Map<String, dynamic> json) => Geofence(
        placeId: json['place_id'] ?? json['placeId'],
        lat: (json['lat'] ?? json['latitude']).toDouble(),
        lon: (json['lon'] ?? json['longitude']).toDouble(),
        checkInDistance: json['check_in_distance'] ?? json['checkInDistance'],
      );

  Geofence copyWith({
    String? placeId,
    double? lat,
    double? lon,
    int? checkInDistance,
  }) =>
      Geofence(
        placeId: placeId ?? this.placeId,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        checkInDistance: checkInDistance ?? this.checkInDistance,
      );
}

class SiteDetails {
  final String type; // static or mobile-patrol
  final String name;
  final String? customerId;
  final SiteAddress address;
  final Geofence geofence;
  final String? defaultServiceGroupId;
  final String? defaultPayGroupId;
  final List<String>? customClockInQuestionnaire;
  final String? instructions;
  final String? id;

  SiteDetails({
    required this.type,
    required this.name,
    this.customerId,
    required this.address,
    required this.geofence,
    this.defaultServiceGroupId,
    this.defaultPayGroupId,
    this.customClockInQuestionnaire,
    this.instructions,
    this.id,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        if (customerId != null && customerId!.isNotEmpty) 'customer_profile_id': customerId,
        'address': address.name,
        'city': address.city,
        'state': address.state,
        'zip': address.zip,
        'country': address.country,
        'geofence': geofence.toJson(),
        if (defaultServiceGroupId != null && defaultServiceGroupId!.isNotEmpty)
          'default_service_group_id': defaultServiceGroupId,
        if (defaultPayGroupId != null && defaultPayGroupId!.isNotEmpty)
          'default_pay_group_id': defaultPayGroupId,
        if (customClockInQuestionnaire != null)
          'custom_clockin_questionnaire': customClockInQuestionnaire,
        if (instructions != null) 'instructions': instructions,
      };

  factory SiteDetails.fromJson(Map<String, dynamic> json) => SiteDetails(
        id: json['id']?.toString(),
        type: json['type'] ?? 'static',
        name: json['name'] ?? '',
        customerId:
            json['customer_profile_id']?.toString() ?? json['customer_id']?.toString() ?? json['customerId'],
        address: SiteAddress(
          name: json['address']?.toString() ?? '',
          city: json['city']?.toString() ?? '',
          state: json['state']?.toString() ?? '',
          zip: json['zip']?.toString() ?? '',
          country: json['country']?.toString() ?? '',
        ),
        geofence: Geofence.fromJson(json['geofence'] ?? {}),
        defaultServiceGroupId: json['default_service_group_id']?.toString() ??
            json['defaultServiceGroupId'],
        defaultPayGroupId: json['default_pay_group_id']?.toString() ??
            json['defaultPayGroupId'],
        customClockInQuestionnaire:
            List<String>.from(json['custom_clockin_questionnaire'] ?? []),
        instructions: json['instructions'],
      );

  SiteDetails copyWith({
    String? type,
    String? name,
    String? customerId,
    SiteAddress? address,
    Geofence? geofence,
    String? defaultServiceGroupId,
    String? defaultPayGroupId,
    List<String>? customClockInQuestionnaire,
    String? instructions,
    String? id,
  }) =>
      SiteDetails(
        type: type ?? this.type,
        name: name ?? this.name,
        customerId: customerId ?? this.customerId,
        address: address ?? this.address,
        geofence: geofence ?? this.geofence,
        defaultServiceGroupId:
            defaultServiceGroupId ?? this.defaultServiceGroupId,
        defaultPayGroupId: defaultPayGroupId ?? this.defaultPayGroupId,
        customClockInQuestionnaire:
            customClockInQuestionnaire ?? this.customClockInQuestionnaire,
        instructions: instructions ?? this.instructions,
        id: id ?? this.id,
      );
}

class SiteContact {
  final int? id;
  final String firstName;
  final String lastName;
  final String position;
  final String email;
  final String contactNumber;
  final String? notes;
  final int? siteId;

  SiteContact({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.position,
    required this.email,
    required this.contactNumber,
    this.notes,
    this.siteId,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'position': position,
        'email': email,
        'contact_number': contactNumber,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
      };

  factory SiteContact.fromJson(Map<String, dynamic> json) => SiteContact(
        id: json['id'],
        firstName: json['first_name'] ?? json['firstName'] ?? '',
        lastName: json['last_name'] ?? json['lastName'] ?? '',
        position: json['position'] ?? '',
        email: json['email'] ?? '',
        contactNumber: json['contact_number'] ??
            json['contactNumber'] ??
            json['mobileNumber'] ??
            '',
        notes: json['notes'],
        siteId: json['site_id'],
      );

  SiteContact copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? position,
    String? email,
    String? contactNumber,
    String? notes,
    int? siteId,
  }) =>
      SiteContact(
        id: id ?? this.id,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        position: position ?? this.position,
        email: email ?? this.email,
        contactNumber: contactNumber ?? this.contactNumber,
        notes: notes ?? this.notes,
        siteId: siteId ?? this.siteId,
      );
}

class SiteCheckpoint {
  final int? id;
  final String name;
  final Geofence geofence;
  final String? qrCodeToken;
  final int? siteId;

  SiteCheckpoint({
    this.id,
    required this.name,
    required this.geofence,
    this.qrCodeToken,
    this.siteId,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'geofence': geofence.toJson(),
        'qr_code_token': (qrCodeToken != null && qrCodeToken!.isNotEmpty)
            ? qrCodeToken
            : const Uuid().v4(),
      };

  factory SiteCheckpoint.fromJson(Map<String, dynamic> json) => SiteCheckpoint(
        id: json['id'],
        name: json['name'] ?? '',
        geofence: Geofence.fromJson(json['geofence'] ?? {}),
        qrCodeToken: json['qr_code_token'],
        siteId: json['site_id'],
      );

  SiteCheckpoint copyWith({
    int? id,
    String? name,
    Geofence? geofence,
    String? qrCodeToken,
    int? siteId,
  }) =>
      SiteCheckpoint(
        id: id ?? this.id,
        name: name ?? this.name,
        geofence: geofence ?? this.geofence,
        qrCodeToken: qrCodeToken ?? this.qrCodeToken,
        siteId: siteId ?? this.siteId,
      );
}

class SitePreference {
  final int? id;
  final int? siteId;
  final int? referenceId;
  final String? mode; // staff-setting or form-setting
  final String? setting; // preferred, blacklisted, enabled

  SitePreference({
    this.id,
    this.siteId,
    this.referenceId,
    this.mode,
    this.setting,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (siteId != null) 'site_id': siteId,
        if (referenceId != null) 'reference_id': referenceId,
        if (mode != null) 'mode': mode,
        if (setting != null) 'setting': setting,
      };

  factory SitePreference.fromJson(Map<String, dynamic> json) => SitePreference(
        id: json['id'],
        siteId: json['site_id'],
        referenceId: json['reference_id'],
        mode: json['mode'],
        setting: json['setting'],
      );

  SitePreference copyWith({
    int? id,
    int? siteId,
    int? referenceId,
    String? mode,
    String? setting,
  }) =>
      SitePreference(
        id: id ?? this.id,
        siteId: siteId ?? this.siteId,
        referenceId: referenceId ?? this.referenceId,
        mode: mode ?? this.mode,
        setting: setting ?? this.setting,
      );
}

class SiteDocument {
  final int? id;
  final String name;
  final List<String> files;
  final bool offsiteVisibility;
  final int? siteId;

  SiteDocument({
    this.id,
    required this.name,
    required this.files,
    required this.offsiteVisibility,
    this.siteId,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'files': files,
        'offsite_visibility': offsiteVisibility,
      };

  factory SiteDocument.fromJson(Map<String, dynamic> json) => SiteDocument(
        id: json['id'],
        name: json['name'] ?? '',
        files: List<String>.from(json['files'] ?? json['filePaths'] ?? []),
        offsiteVisibility:
            json['offsite_visibility'] ?? json['isViewableOffsite'] ?? false,
        siteId: json['site_id'],
      );

  SiteDocument copyWith({
    int? id,
    String? name,
    List<String>? files,
    bool? offsiteVisibility,
    int? siteId,
  }) =>
      SiteDocument(
        id: id ?? this.id,
        name: name ?? this.name,
        files: files ?? this.files,
        offsiteVisibility: offsiteVisibility ?? this.offsiteVisibility,
        siteId: siteId ?? this.siteId,
      );
}

class Site {
  final int id;
  final String type;
  final int? customerProfileId;
  final String name;
  final Map<String, dynamic> geofence;
  final Map<String, dynamic> address;
  final int? defaultPayGroupId;
  final int? defaultServiceGroupId;
  final List<String>? customClockInQuestionnaire;
  final String? instructions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Site({
    required this.id,
    required this.type,
    this.customerProfileId,
    required this.name,
    required this.geofence,
    required this.address,
    this.defaultPayGroupId,
    this.defaultServiceGroupId,
    this.customClockInQuestionnaire,
    this.instructions,
    this.createdAt,
    this.updatedAt,
  });

  factory Site.fromJson(Map<String, dynamic> json) => Site(
        id: json['id'] ?? 0,
        type: json['type'] ?? '',
        customerProfileId: json['customer_profile_id'],
        name: json['name'] ?? '',
        geofence: Map<String, dynamic>.from(json['geofence'] ?? {}),
        address: Map<String, dynamic>.from(json['address'] ?? {}),
        defaultPayGroupId: json['default_pay_group_id'],
        defaultServiceGroupId: json['default_service_group_id'],
        customClockInQuestionnaire:
            List<String>.from(json['custom_clockin_questionnaire'] ?? []),
        instructions: json['instructions'],
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        if (customerProfileId != null) 'customer_profile_id': customerProfileId,
        'name': name,
        'geofence': geofence,
        'address': address,
        if (defaultPayGroupId != null)
          'default_pay_group_id': defaultPayGroupId,
        if (defaultServiceGroupId != null)
          'default_service_group_id': defaultServiceGroupId,
        if (customClockInQuestionnaire != null)
          'custom_clockin_questionnaire': customClockInQuestionnaire,
        if (instructions != null) 'instructions': instructions,
      };
}
