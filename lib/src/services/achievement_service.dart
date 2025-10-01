import 'package:xingmubiao/src/models/achievement.dart';

class AchievementService {
  // 模拟成就数据
  static final List<Achievement> _achievements = [
    Achievement(
      id: '1',
      title: '初出茅庐',
      description: '完成第一个目标',
      icon: 'beginner',
      pointsRequired: 10,
      isUnlocked: true,
      unlockedAt: DateTime.now().subtract(const Duration(days: 5)),
      type: 'special',
    ),
    Achievement(
      id: '2',
      title: '坚持不懈',
      description: '连续打卡7天',
      icon: 'persistent',
      pointsRequired: 50,
      isUnlocked: false,
      type: 'daily',
    ),
    Achievement(
      id: '3',
      title: '学习达人',
      description: '完成10个学习目标',
      icon: 'study',
      pointsRequired: 100,
      isUnlocked: false,
      type: 'special',
    ),
    Achievement(
      id: '4',
      title: '生活能手',
      description: '完成5个生活目标',
      icon: 'life',
      pointsRequired: 75,
      isUnlocked: false,
      type: 'special',
    ),
    Achievement(
      id: '5',
      title: '月度之星',
      description: '一个月内完成20个目标',
      icon: 'monthly_star',
      pointsRequired: 200,
      isUnlocked: false,
      type: 'monthly',
    ),
  ];

  static Future<List<Achievement>> getAchievements() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    return _achievements;
  }

  static Future<List<Achievement>> getUnlockedAchievements() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _achievements.where((a) => a.isUnlocked).toList();
  }

  static Future<List<Achievement>> getLockedAchievements() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _achievements.where((a) => !a.isUnlocked).toList();
  }

  static Future<Achievement> unlockAchievement(String achievementId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index != -1) {
      _achievements[index] = Achievement(
        id: _achievements[index].id,
        title: _achievements[index].title,
        description: _achievements[index].description,
        icon: _achievements[index].icon,
        pointsRequired: _achievements[index].pointsRequired,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
        type: _achievements[index].type,
      );
      return _achievements[index];
    }
    throw Exception('Achievement not found');
  }

  static Future<void> addAchievement(Achievement achievement) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _achievements.add(achievement);
  }

  static Future<void> updateAchievement(Achievement achievement) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _achievements.indexWhere((a) => a.id == achievement.id);
    if (index != -1) {
      _achievements[index] = achievement;
    }
  }

  static Future<void> deleteAchievement(String achievementId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _achievements.removeWhere((a) => a.id == achievementId);
  }
}