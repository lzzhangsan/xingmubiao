class Point {
  final String id;
  final String userId;
  final int amount;
  final String reason; // 积分变动原因
  final String type; // 'earned' or 'spent'
  final String? relatedId; // 关联的goalId或rewardId
  final DateTime createdAt;

  Point({
    required this.id,
    required this.userId,
    required this.amount,
    required this.reason,
    required this.type,
    this.relatedId,
    required this.createdAt,
  });

  factory Point.fromJson(Map<String, dynamic> json) {
    return Point(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amount: json['amount'] as int,
      reason: json['reason'] as String,
      type: json['type'] as String,
      relatedId: json['relatedId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'reason': reason,
      'type': type,
      'relatedId': relatedId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}