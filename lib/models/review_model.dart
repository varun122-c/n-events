class Review {
  final String id;
  final String eventId;
  final String studentName;
  final double rating;
  final String comment;
  final DateTime date;

  Review({
    required this.id,
    required this.eventId,
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.date,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'studentName': studentName,
      'rating': rating,
      'comment': comment,
      'date': date.toIso8601String(),
    };
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      studentName: json['studentName'] as String,
      rating: (json['rating'] as num).toDouble(),
      comment: json['comment'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }
}
