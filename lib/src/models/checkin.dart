class Checkin {
  final String id;
  final String goalId;
  final String userId;
  final int score;
  final String? comment;
  final String? imageUrl; // 兼容旧字段（单图）
  final List<String> imageUrls; // 最多 3 张
  final DateTime createdAt;

  Checkin({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.score,
    this.comment,
    this.imageUrl,
    List<String>? imageUrls,
    required this.createdAt,
  }) : imageUrls = imageUrls ?? (imageUrl != null ? [imageUrl] : []);

  factory Checkin.fromJson(Map<String, dynamic> json) {
    final single = json['imageUrl'] as String?;
    final list = (json['imageUrls'] as List?)?.cast<String>() ?? (single != null ? [single] : <String>[]);
    return Checkin(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      userId: json['userId'] as String,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      imageUrl: single ?? (list.isNotEmpty ? list.first : null),
      imageUrls: list,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'goalId': goalId,
      'userId': userId,
      'score': score,
      'comment': comment,
      'imageUrl': imageUrl ?? (imageUrls.isNotEmpty ? imageUrls.first : null),
      'imageUrls': imageUrls,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
