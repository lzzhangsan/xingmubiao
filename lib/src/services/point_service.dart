import 'package:xingmubiao/src/models/point.dart';

class PointService {
  // 模拟积分数据
  static final List<Point> _points = [
    Point(
      id: '1',
      userId: 'child1',
      amount: 10,
      reason: '完成阅读目标',
      type: 'earned',
      relatedId: '1',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Point(
      id: '2',
      userId: 'child1',
      amount: 5,
      reason: '整理书桌',
      type: 'earned',
      relatedId: '2',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Point(
      id: '3',
      userId: 'child1',
      amount: -100,
      reason: '兑换玩具车',
      type: 'spent',
      relatedId: 'reward1',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  static Future<List<Point>> getPoints() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    return _points;
  }

  static Future<List<Point>> getPointsByUser(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _points.where((p) => p.userId == userId).toList();
  }

  static Future<int> getTotalPoints(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _points
        .where((p) => p.userId == userId && p.type == 'earned')
        .fold(0, (sum, point) => sum + point.amount) -
        _points
            .where((p) => p.userId == userId && p.type == 'spent')
            .fold(0, (sum, point) => sum + point.amount);
  }

  static Future<Point> addPoint(Point point) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _points.add(point);
    return point;
  }

  static Future<void> updatePoint(Point point) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _points.indexWhere((p) => p.id == point.id);
    if (index != -1) {
      _points[index] = point;
    }
  }

  static Future<void> deletePoint(String pointId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _points.removeWhere((p) => p.id == pointId);
  }
}