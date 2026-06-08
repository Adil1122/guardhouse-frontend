enum StaffStatus { active, inactive, suspended }

class StaffMember {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? role;
  final String? contactNumber;
  final String? gender;
  final List<String> privileges;
  final List<String> compliances;
  final StaffStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.role,
    this.contactNumber,
    this.gender,
    this.privileges = const [],
    this.compliances = const [],
    this.status = StaffStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id'] as String,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String,
      role: json['role'] as String?,
      contactNumber: json['contactNumber'] as String?,
      gender: json['gender'] as String?,
      privileges: List<String>.from(json['privileges'] as List? ?? []),
      compliances: List<String>.from(json['compliances'] as List? ?? []),
      status: StaffStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => StaffStatus.active,
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
      'role': role,
      'contactNumber': contactNumber,
      'gender': gender,
      'privileges': privileges,
      'compliances': compliances,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  StaffMember copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    String? contactNumber,
    String? gender,
    List<String>? privileges,
    List<String>? compliances,
    StaffStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      contactNumber: contactNumber ?? this.contactNumber,
      gender: gender ?? this.gender,
      privileges: privileges ?? this.privileges,
      compliances: compliances ?? this.compliances,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
