import 'dart:convert';

/// Sub-roles that the admin can assign to a registered student/user.
/// Empty string means no staff sub-role (regular student or admin).
class SubRoles {
  static const String none = '';
  static const String organizer = 'organizer';
  static const String coordinator = 'coordinator';
  static const String techProvider = 'tech_provider';
  static const String scanner = 'scanner';

  static const List<String> all = [organizer, coordinator, techProvider, scanner];

  static String label(String subRole) {
    switch (subRole) {
      case organizer:
        return 'Organizer';
      case coordinator:
        return 'Coordinator';
      case techProvider:
        return 'Tech Provider';
      case scanner:
        return 'QR Scanner';
      default:
        return 'Student';
    }
  }
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role; // 'student', 'admin'
  final String subRole; // '', 'organizer', 'coordinator', 'tech_provider', 'scanner'
  final String rollNumber;
  final String department;
  final String college;
  final String year;
  final String phone;
  final String dob; // Date of birth (YYYY-MM-DD)
  final String gender; // 'Male', 'Female', 'Other'
  final int avatarIndex;
  final String customAvatarUrl; // Custom image URL or path
  final String participantCode; // Permanent 10-digit code
  final DateTime createdAt;

  // Staff-role specific fields
  final String assignedDepartment; // For organizer — which department they manage
  final List<String> assignedEventIds; // Events a coordinator/scanner is assigned to

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.subRole = '',
    this.rollNumber = '',
    this.department = 'Computer Science and Engineering (CSE)',
    this.college = 'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)',
    this.year = '1st Year',
    this.phone = '',
    this.dob = '',
    this.gender = 'Male',
    this.avatarIndex = 0,
    this.customAvatarUrl = '',
    String? participantCode,
    DateTime? createdAt,
    this.assignedDepartment = '',
    this.assignedEventIds = const [],
  })  : participantCode = (participantCode != null && participantCode.length == 10)
            ? participantCode
            : generate10DigitParticipantCode(id),
        createdAt = createdAt ?? DateTime.now();

  static String generate10DigitParticipantCode(String userId) {
    if (userId.isEmpty) return '9876543210';
    int hash = 0;
    for (int i = 0; i < userId.length; i++) {
      hash = (hash * 31 + userId.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    int tenDigit = 1000000000 + (hash.abs() % 9000000000);
    return tenDigit.toString();
  }

  String get displayParticipantCode =>
      participantCode.isNotEmpty ? participantCode : generate10DigitParticipantCode(id);

  /// True if this user has any staff sub-role assigned
  bool get isStaff => subRole.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'subRole': subRole,
      'rollNumber': rollNumber,
      'department': department,
      'college': college,
      'year': year,
      'phone': phone,
      'dob': dob,
      'gender': gender,
      'avatarIndex': avatarIndex,
      'customAvatarUrl': customAvatarUrl,
      'participantCode': displayParticipantCode,
      'createdAt': createdAt.toIso8601String(),
      'assignedDepartment': assignedDepartment,
      'assignedEventIds': assignedEventIds,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    final idVal = map['id'] ?? '';
    final eventIdsRaw = map['assignedEventIds'];
    List<String> eventIds = [];
    if (eventIdsRaw is List) {
      eventIds = List<String>.from(eventIdsRaw);
    }
    return UserModel(
      id: idVal,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      role: map['role'] ?? 'student',
      subRole: map['subRole'] ?? '',
      rollNumber: map['rollNumber'] ?? '',
      department: map['department'] ?? 'Computer Science and Engineering (CSE)',
      college: map['college'] ??
          'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)',
      year: map['year'] ?? '1st Year',
      phone: map['phone'] ?? '',
      dob: map['dob'] ?? '',
      gender: map['gender'] ?? 'Male',
      avatarIndex: map['avatarIndex'] ?? 0,
      customAvatarUrl: map['customAvatarUrl'] ?? '',
      participantCode:
          map['participantCode'] ?? generate10DigitParticipantCode(idVal),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      assignedDepartment: map['assignedDepartment'] ?? '',
      assignedEventIds: eventIds,
    );
  }

  String toJson() => json.encode(toMap());

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? password,
    String? role,
    String? subRole,
    String? rollNumber,
    String? department,
    String? college,
    String? year,
    String? phone,
    String? dob,
    String? gender,
    int? avatarIndex,
    String? customAvatarUrl,
    String? participantCode,
    DateTime? createdAt,
    String? assignedDepartment,
    List<String>? assignedEventIds,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      subRole: subRole ?? this.subRole,
      rollNumber: rollNumber ?? this.rollNumber,
      department: department ?? this.department,
      college: college ?? this.college,
      year: year ?? this.year,
      phone: phone ?? this.phone,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      customAvatarUrl: customAvatarUrl ?? this.customAvatarUrl,
      participantCode: participantCode ?? this.participantCode,
      createdAt: createdAt ?? this.createdAt,
      assignedDepartment: assignedDepartment ?? this.assignedDepartment,
      assignedEventIds: assignedEventIds ?? this.assignedEventIds,
    );
  }
}
