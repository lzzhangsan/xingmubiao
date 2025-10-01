class Reward {
  final String id;
  final String title;
  final String description;
  final int pointsRequired;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsRequired,
    this.imageUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      pointsRequired: json['pointsRequired'] as int,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pointsRequired': pointsRequired,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}