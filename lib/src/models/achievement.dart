class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int pointsRequired;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final String type; // 'daily', 'weekly', 'monthly', 'special'

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.pointsRequired,
    required this.isUnlocked,
    this.unlockedAt,
    required this.type,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      pointsRequired: json['pointsRequired'] as int,
      isUnlocked: json['isUnlocked'] as bool,
      unlockedAt: json['unlockedAt'] != null ? DateTime.parse(json['unlockedAt'] as String) : null,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'pointsRequired': pointsRequired,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'type': type,
    };
  }
}