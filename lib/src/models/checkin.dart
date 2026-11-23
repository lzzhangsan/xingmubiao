class ScoreChange {
  final int fromScore;
  final int toScore;
  final DateTime changedAt;
  final String? note;

  ScoreChange({
    required this.fromScore,
    required this.toScore,
    required this.changedAt,
    this.note,
  });

  factory ScoreChange.fromJson(Map<String, dynamic> json) {
    return ScoreChange(
      fromScore: json['fromScore'] as int,
      toScore: json['toScore'] as int,
      changedAt: DateTime.parse(json['changedAt'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'fromScore': fromScore,
    'toScore': toScore,
    'changedAt': changedAt.toIso8601String(),
    'note': note,
  };
}

class Checkin {
  final String id;
  final String goalId;
  final String userId;
  final int score;
  final String? comment;
  final String? imageUrl;
  final List<String> imageUrls;
  final DateTime createdAt;
  final List<ScoreChange> history; // 分数变更记录

  Checkin({
    required this.id,
    required this.goalId,
    required this.userId,
    required this.score,
    this.comment,
    this.imageUrl,
    List<String>? imageUrls,
    required this.createdAt,
    List<ScoreChange>? history,
  })  : imageUrls = imageUrls ?? (imageUrl != null ? [imageUrl] : []),
        history = history ?? [];

  bool get hasBeenModified => history.isNotEmpty;

  factory Checkin.fromJson(Map<String, dynamic> json) {
    final single = json['imageUrl'] as String?;
    final list = (json['imageUrls'] as List?)?.cast<String>() ?? (single != null ? [single] : <String>[]);
    final hist = (json['history'] as List?)?.map((e) => ScoreChange.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    return Checkin(
      id: json['id'] as String,
      goalId: json['goalId'] as String,
      userId: json['userId'] as String,
      score: json['score'] as int,
      comment: json['comment'] as String?,
      imageUrl: single ?? (list.isNotEmpty ? list.first : null),
      imageUrls: list,
      createdAt: DateTime.parse(json['createdAt'] as String),
      history: hist,
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
      'history': history.map((h) => h.toJson()).toList(),
    };
  }
}
