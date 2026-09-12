class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final String? linkedEventId;
  final int displayOrder;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.linkedEventId,
    required this.displayOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'imageUrl': imageUrl,
      'linkedEventId': linkedEventId,
      'displayOrder': displayOrder,
    };
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      linkedEventId: json['linkedEventId'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  BannerModel copyWith({
    String? id,
    String? title,
    String? imageUrl,
    String? linkedEventId,
    int? displayOrder,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      linkedEventId: linkedEventId ?? this.linkedEventId,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }
}
