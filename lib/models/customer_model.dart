enum CustomerStatus { active, inactive, suspended }

class CustomerAddress {
  final String address;
  final String city;
  final String state;
  final String zip;
  final String country;

  CustomerAddress({
    required this.address,
    this.city = '',
    this.state = '',
    this.zip = '',
    this.country = '',
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      zip: json['zip'] as String? ?? '',
      country: json['country'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'country': country,
    };
  }
}

class Customer {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? referenceNumber;
  final CustomerAddress address;
  final String? defaultPayGroup;
  final CustomerStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.referenceNumber,
    required this.address,
    this.defaultPayGroup,
    this.status = CustomerStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String,
      referenceNumber: json['referenceNumber'] as String?,
      address: CustomerAddress.fromJson(
        json['address'] as Map<String, dynamic>? ?? {},
      ),
      defaultPayGroup: json['defaultPayGroup'] as String?,
      status: CustomerStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => CustomerStatus.active,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'referenceNumber': referenceNumber,
      'address': address.toJson(),
      'defaultPayGroup': defaultPayGroup,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Customer copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? referenceNumber,
    CustomerAddress? address,
    String? defaultPayGroup,
    CustomerStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      address: address ?? this.address,
      defaultPayGroup: defaultPayGroup ?? this.defaultPayGroup,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
