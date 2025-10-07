import 'package:xingmubiao/src/models/point.dart';

class PointService {
  // 模拟积分流水，实际项目可替换为数据库或接口
  static final List<Point> _points = [
    Point(
      id: '1',
      userId: 'child1',
      amount: 10,
      reason: '完成阅读 30 分钟',
      type: 'earned',
      relatedId: 'goal1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Point(
      id: '2',
      userId: 'child1',
      amount: 5,
      reason: '整理书桌',
      type: 'earned',
      relatedId: 'goal2',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Point(
      id: '3',
      userId: 'child1',
      amount: 80,
      reason: '兑换喜欢的小零食',
      type: 'spent',
      relatedId: 'reward3',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static Future<List<Point>> getPoints() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List<Point>.from(_points);
  }

  static Future<List<Point>> getPointsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _points.where((p) => p.userId == userId).toList();
  }

  static Future<int> getTotalPoints(String userId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final earned = _points
        .where((p) => p.userId == userId && p.type == 'earned')
        .fold<int>(0, (sum, point) => sum + point.amount);
    final spent = _points
        .where((p) => p.userId == userId && p.type == 'spent')
        .fold<int>(0, (sum, point) => sum + point.amount);
    return earned - spent;
  }

  static Future<Point> addPoint(Point point) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _points.add(point);
    return point;
  }

  static Future<void> updatePoint(Point point) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _points.indexWhere((p) => p.id == point.id);
    if (index != -1) {
      _points[index] = point;
    }
  }

  static Future<void> deletePoint(String pointId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _points.removeWhere((p) => p.id == pointId);
  }
}
