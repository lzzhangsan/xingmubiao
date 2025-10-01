class Goal {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final String userId; // 创建目标的用户ID
  final List<String> assignedTo; // 分配给哪些用户（孩子）
  final int points;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final String frequency; // 'daily', 'weekly', 'monthly', 'once'
  final String type; // 'habit', 'task', 'challenge'

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.userId,
    required this.assignedTo,
    required this.points,
    required this.createdAt,
    this.startDate,
    this.endDate,
    this.isActive = true,
    this.frequency = 'daily',
    this.type = 'habit',
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      categoryId: json['categoryId'] as String,
      userId: json['userId'] as String,
      assignedTo: List<String>.from(json['assignedTo'] as List),
      points: json['points'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate'] as String) : null,
      isActive: json['isActive'] as bool,
      frequency: json['frequency'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'categoryId': categoryId,
      'userId': userId,
      'assignedTo': assignedTo,
      'points': points,
      'createdAt': createdAt.toIso8601String(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'frequency': frequency,
      'type': type,
    };
  }
}