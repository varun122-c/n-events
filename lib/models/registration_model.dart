class Registration {
  final String id;
  final String eventId;
  final String? userId;
  final String fullName;
  final String rollNumber;
  final String department;
  final String college;
  final String yearOfStudy;
  final String phoneNumber;
  final DateTime registrationDate;
  final String status; // 'Registered', 'Checked In', 'Attended', 'Cancelled'
  final String? verifiedBy; // Name of coordinator who verified entry
  final DateTime? verifiedAt; // Timestamp when verified
  final bool isCertificatePublished; // True if admin published digital certificate
  final bool isPaid; // True if payment has been confirmed by admin
  final String paymentNote; // Optional note about payment (e.g. transaction ID)

  Registration({
    required this.id,
    required this.eventId,
    this.userId,
    required this.fullName,
    required this.rollNumber,
    required this.department,
    this.college = 'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)',
    required this.yearOfStudy,
    required this.phoneNumber,
    required this.registrationDate,
    this.status = 'Registered',
    this.verifiedBy,
    this.verifiedAt,
    this.isCertificatePublished = false,
    this.isPaid = false,
    this.paymentNote = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'userId': userId,
      'fullName': fullName,
      'rollNumber': rollNumber,
      'department': department,
      'college': college,
      'yearOfStudy': yearOfStudy,
      'phoneNumber': phoneNumber,
      'registrationDate': registrationDate.toIso8601String(),
      'status': status,
      'verifiedBy': verifiedBy,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'isCertificatePublished': isCertificatePublished,
      'isPaid': isPaid,
      'paymentNote': paymentNote,
    };
  }

  factory Registration.fromJson(Map<String, dynamic> json) {
    return Registration(
      id: json['id'] as String? ?? '',
      eventId: json['eventId'] as String? ?? '',
      userId: json['userId'] as String?,
      fullName: json['fullName'] as String? ?? '',
      rollNumber: json['rollNumber'] as String? ?? '',
      department: json['department'] as String? ?? 'Computer Science and Engineering (CSE)',
      college: json['college'] as String? ?? 'Annamacharya Institute of Technology and Sciences, Tirupati (AITS TPT)',
      yearOfStudy: json['yearOfStudy'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      registrationDate: DateTime.tryParse(json['registrationDate']?.toString() ?? '') ?? DateTime.now(),
      status: json['status'] as String? ?? 'Registered',
      verifiedBy: json['verifiedBy'] as String?,
      verifiedAt: json['verifiedAt'] != null ? DateTime.tryParse(json['verifiedAt']?.toString() ?? '') : null,
      isCertificatePublished: json['isCertificatePublished'] as bool? ?? false,
      isPaid: json['isPaid'] as bool? ?? false,
      paymentNote: json['paymentNote'] as String? ?? '',
    );
  }

  Registration copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? fullName,
    String? rollNumber,
    String? department,
    String? college,
    String? yearOfStudy,
    String? phoneNumber,
    DateTime? registrationDate,
    String? status,
    String? verifiedBy,
    DateTime? verifiedAt,
    bool? isCertificatePublished,
    bool? isPaid,
    String? paymentNote,
  }) {
    return Registration(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      rollNumber: rollNumber ?? this.rollNumber,
      department: department ?? this.department,
      college: college ?? this.college,
      yearOfStudy: yearOfStudy ?? this.yearOfStudy,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      registrationDate: registrationDate ?? this.registrationDate,
      status: status ?? this.status,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      isCertificatePublished: isCertificatePublished ?? this.isCertificatePublished,
      isPaid: isPaid ?? this.isPaid,
      paymentNote: paymentNote ?? this.paymentNote,
    );
  }
}
