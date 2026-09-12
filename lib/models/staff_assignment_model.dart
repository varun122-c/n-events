import 'dart:convert';

/// Represents a staff role assignment granted by the admin.
class StaffAssignment {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String userRollNumber;
  final String userDepartment;
  final String subRole; // 'organizer', 'coordinator', 'tech_provider', 'scanner'
  final String assignedDepartment; // Organizer's managed department
  final List<String> assignedEventIds; // Coordinator/Scanner event IDs
  final DateTime grantedAt;
  final String grantedByAdminId;

  StaffAssignment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userRollNumber = '',
    this.userDepartment = '',
    required this.subRole,
    this.assignedDepartment = '',
    this.assignedEventIds = const [],
    DateTime? grantedAt,
    this.grantedByAdminId = '',
  }) : grantedAt = grantedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userRollNumber': userRollNumber,
      'userDepartment': userDepartment,
      'subRole': subRole,
      'assignedDepartment': assignedDepartment,
      'assignedEventIds': assignedEventIds,
      'grantedAt': grantedAt.toIso8601String(),
      'grantedByAdminId': grantedByAdminId,
    };
  }

  factory StaffAssignment.fromMap(Map<String, dynamic> map) {
    final eventIdsRaw = map['assignedEventIds'];
    List<String> eventIds = [];
    if (eventIdsRaw is List) {
      eventIds = List<String>.from(eventIdsRaw);
    }
    return StaffAssignment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userRollNumber: map['userRollNumber'] ?? '',
      userDepartment: map['userDepartment'] ?? '',
      subRole: map['subRole'] ?? '',
      assignedDepartment: map['assignedDepartment'] ?? '',
      assignedEventIds: eventIds,
      grantedAt: map['grantedAt'] != null
          ? DateTime.tryParse(map['grantedAt']) ?? DateTime.now()
          : DateTime.now(),
      grantedByAdminId: map['grantedByAdminId'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());
  factory StaffAssignment.fromJson(String source) =>
      StaffAssignment.fromMap(json.decode(source));

  StaffAssignment copyWith({
    String? subRole,
    String? assignedDepartment,
    List<String>? assignedEventIds,
  }) {
    return StaffAssignment(
      id: id,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userRollNumber: userRollNumber,
      userDepartment: userDepartment,
      subRole: subRole ?? this.subRole,
      assignedDepartment: assignedDepartment ?? this.assignedDepartment,
      assignedEventIds: assignedEventIds ?? this.assignedEventIds,
      grantedAt: grantedAt,
      grantedByAdminId: grantedByAdminId,
    );
  }
}
