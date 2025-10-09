import 'package:xingmubiao/src/models/point.dart';
import 'package:xingmubiao/src/storage/local_data_store.dart';

class PointService {
  static const _storageKey = 'points';
  static List<Point> _cache = [];
  static bool _loaded = false;

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final data = await LocalDataStore.loadList(_storageKey);
    _cache = data.map(Point.fromJson).toList();
    _loaded = true;
  }

  static Future<void> _persist() async {
    await LocalDataStore.saveList(
      _storageKey,
      _cache.map((point) => point.toJson()).toList(),
    );
  }

  static Future<List<Point>> getPoints() async {
    await _ensureLoaded();
    return List<Point>.from(_cache);
  }

  static Future<List<Point>> getPointsByUser(String userId) async {
    await _ensureLoaded();
    return _cache.where((point) => point.userId == userId).toList();
  }

  // 历史累计获得的总积分（不扣除已兑换/支出）
  static Future<int> getTotalPoints(String userId) async {
    await _ensureLoaded();
    final earned = _cache
        .where((point) => point.userId == userId && point.type == 'earned')
        .fold<int>(0, (sum, point) => sum + point.amount);
    return earned;
  }

  // 当前可用积分（历史获得 - 历史支出），用于兑换/消费判断
  static Future<int> getAvailablePoints(String userId) async {
    await _ensureLoaded();
    final earned = _cache
        .where((point) => point.userId == userId && point.type == 'earned')
        .fold<int>(0, (sum, point) => sum + point.amount);
    final spent = _cache
        .where((point) => point.userId == userId && point.type == 'spent')
        .fold<int>(0, (sum, point) => sum + point.amount);
    return earned - spent;
  }

  static Future<Point> addPoint(Point point) async {
    await _ensureLoaded();
    _cache.add(point);
    await _persist();
    return point;
  }

  static Future<void> updatePoint(Point point) async {
    await _ensureLoaded();
    final index = _cache.indexWhere((p) => p.id == point.id);
    if (index != -1) {
      _cache[index] = point;
      await _persist();
    }
  }

  static Future<void> deletePoint(String pointId) async {
    await _ensureLoaded();
    _cache.removeWhere((point) => point.id == pointId);
    await _persist();
  }

  static Future<void> clear() async {
    _cache = [];
    _loaded = true;
    await _persist();
  }
}
