class ChatMessageModel {
  final String id;
  final String eventId;
  final String studentRoll;
  final String studentName;
  final String senderRole; // 'student' or 'coordinator'
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final String status; // 'sent', 'delivered', 'seen'

  ChatMessageModel({
    required this.id,
    required this.eventId,
    required this.studentRoll,
    required this.studentName,
    required this.senderRole,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.status = 'seen',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'studentRoll': studentRoll,
      'studentName': studentName,
      'senderRole': senderRole,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'status': status,
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      studentRoll: json['studentRoll'] as String,
      studentName: json['studentName'] as String,
      senderRole: json['senderRole'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? true,
      status: json['status'] as String? ?? 'seen',
    );
  }

  ChatMessageModel copyWith({
    String? id,
    String? eventId,
    String? studentRoll,
    String? studentName,
    String? senderRole,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    String? status,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      studentRoll: studentRoll ?? this.studentRoll,
      studentName: studentName ?? this.studentName,
      senderRole: senderRole ?? this.senderRole,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
    );
  }
}
