import 'review_model.dart';

class SubEvent {
  final String id;
  final String title;
  final String imageUrl;
  final String category; // 'Technical' or 'Non-Technical'
  final double price; // 0.0 for Free, or custom price in INR
  final String details; // Description / Rules / Other Details
  final String venue;
  final String time;

  SubEvent({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    this.price = 0.0,
    required this.details,
    this.venue = '',
    this.time = '',
  });

  bool get isFree => price <= 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'category': category,
      'price': price,
      'details': details,
      'venue': venue,
      'time': time,
    };
  }

  factory SubEvent.fromJson(Map<String, dynamic> json) {
    return SubEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      category: json['category'] as String? ?? 'Technical',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      details: json['details'] as String? ?? '',
      venue: json['venue'] as String? ?? '',
      time: json['time'] as String? ?? '',
    );
  }

  SubEvent copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? category,
    double? price,
    String? details,
    String? venue,
    String? time,
  }) {
    return SubEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      price: price ?? this.price,
      details: details ?? this.details,
      venue: venue ?? this.venue,
      time: time ?? this.time,
    );
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final String bannerUrl;
  final DateTime dateTime;
  final String venue;
  final String category;
  final String coordinatorName;
  final String coordinatorPhone;
  final int maxSeats;
  final double price;
  final List<SubEvent> subEvents;
  final List<Review> reviews;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.bannerUrl,
    required this.dateTime,
    required this.venue,
    required this.category,
    required this.coordinatorName,
    required this.coordinatorPhone,
    this.maxSeats = 100,
    this.price = 0.0,
    this.subEvents = const [],
    this.reviews = const [],
  });

  bool get isFree => price <= 0;

  String get eventCode {
    if (id.isEmpty) return 'EVT-001';
    final clean = id.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (clean.startsWith('EVT')) return clean;
    return 'EVT-$clean';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'bannerUrl': bannerUrl,
      'dateTime': dateTime.toIso8601String(),
      'venue': venue,
      'category': category,
      'coordinatorName': coordinatorName,
      'coordinatorPhone': coordinatorPhone,
      'maxSeats': maxSeats,
      'price': price,
      'subEvents': subEvents.map((s) => s.toJson()).toList(),
      'reviews': reviews.map((r) => r.toJson()).toList(),
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    var reviewsJson = json['reviews'] as List<dynamic>?;
    List<Review> reviewsList = reviewsJson != null
        ? reviewsJson.map((item) => Review.fromJson(item as Map<String, dynamic>)).toList()
        : [];

    var subEventsJson = json['subEvents'] as List<dynamic>?;
    List<SubEvent> subEventsList = subEventsJson != null
        ? subEventsJson.map((item) => SubEvent.fromJson(item as Map<String, dynamic>)).toList()
        : [];

    return Event(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      bannerUrl: json['bannerUrl'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      venue: json['venue'] as String,
      category: json['category'] as String,
      coordinatorName: json['coordinatorName'] as String,
      coordinatorPhone: json['coordinatorPhone'] as String,
      maxSeats: json['maxSeats'] as int? ?? 100,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      subEvents: subEventsList,
      reviews: reviewsList,
    );
  }

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? bannerUrl,
    DateTime? dateTime,
    String? venue,
    String? category,
    String? coordinatorName,
    String? coordinatorPhone,
    int? maxSeats,
    double? price,
    List<SubEvent>? subEvents,
    List<Review>? reviews,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      dateTime: dateTime ?? this.dateTime,
      venue: venue ?? this.venue,
      category: category ?? this.category,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      coordinatorPhone: coordinatorPhone ?? this.coordinatorPhone,
      maxSeats: maxSeats ?? this.maxSeats,
      price: price ?? this.price,
      subEvents: subEvents ?? this.subEvents,
      reviews: reviews ?? this.reviews,
    );
  }
}
