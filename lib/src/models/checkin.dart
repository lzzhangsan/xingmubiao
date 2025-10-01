class Checkin {
  final String id;
  final String goalId;
  final String userId; // 打卡的用户ID
  final int score; // 评分（1-5分）
  final String? comment;
  final String? imageUrl; // 打卡图片URL
  final DateTime createdAt;

  Checkin({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.score,
    this.comment,
    this.imageUrl,
    required this.createdAt,
  });

  factory Checkin.fromJson(Map<String, dynamic> json) {
    return Checkin(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      userId: json['userId'] as String,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      imageUrl: json['imageUrl'] as String?,
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
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}