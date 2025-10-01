import 'package:xingmubiao/src/models/checkin.dart';

class CheckinService {
  // 模拟打卡数据
  static final List<Checkin> _checkins = [
    Checkin(
      id: '1',
      goalId: '1',
      userId: 'child1',
      score: 5,
      comment: '今天读了一本有趣的书',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Checkin(
      id: '2',
      goalId: '2',
      userId: 'child1',
      score: 4,
      comment: '书桌整理得还不错',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static Future<List<Checkin>> getCheckins() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    return _checkins;
  }

  static Future<List<Checkin>> getCheckinsByGoal(String goalId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _checkins.where((c) => c.goalId == goalId).toList();
  }

  static Future<List<Checkin>> getCheckinsByDate(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _checkins
        .where((c) =>
            c.createdAt.year == date.year &&
            c.createdAt.month == date.month &&
            c.createdAt.day == date.day)
        .toList();
  }

  static Future<Checkin> addCheckin(Checkin checkin) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _checkins.add(checkin);
    return checkin;
  }

  static Future<void> updateCheckin(Checkin checkin) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _checkins.indexWhere((c) => c.id == checkin.id);
    if (index != -1) {
      _checkins[index] = checkin;
    }
  }

  static Future<void> deleteCheckin(String checkinId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _checkins.removeWhere((c) => c.id == checkinId);
  }
}