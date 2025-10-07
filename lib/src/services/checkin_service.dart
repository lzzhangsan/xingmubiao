import 'package:xingmubiao/src/models/checkin.dart';
import 'package:xingmubiao/src/storage/local_data_store.dart';

class CheckinService {
  static const _storageKey = 'checkins';
  static List<Checkin> _cache = [];
  static bool _loaded = false;

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final data = await LocalDataStore.loadList(_storageKey);
    _cache = data.map(Checkin.fromJson).toList();
    _loaded = true;
  }

  static Future<void> _persist() async {
    await LocalDataStore.saveList(
      _storageKey,
      _cache.map((checkin) => checkin.toJson()).toList(),
    );
  }

  static Future<List<Checkin>> getCheckins() async {
    await _ensureLoaded();
    return List<Checkin>.from(_cache);
  }

  static Future<List<Checkin>> getCheckinsForChild(String childId) async {
    await _ensureLoaded();
    return _cache.where((checkin) => checkin.userId == childId).toList();
  }

  static Future<List<Checkin>> getCheckinsForChildByDate(
    String childId,
    DateTime date,
  ) async {
    await _ensureLoaded();
    return _cache.where((checkin) {
      if (checkin.userId != childId) return false;
      final created = checkin.createdAt;
      return created.year == date.year &&
          created.month == date.month &&
          created.day == date.day;
    }).toList();
  }

  static Future<List<Checkin>> getCheckinsByGoal(String goalId) async {
    await _ensureLoaded();
    return _cache.where((checkin) => checkin.goalId == goalId).toList();
  }

  static Future<List<Checkin>> getCheckinsByDate(DateTime date) async {
    await _ensureLoaded();
    return _cache.where((checkin) {
      final created = checkin.createdAt;
      return created.year == date.year &&
          created.month == date.month &&
          created.day == date.day;
    }).toList();
  }

  static Future<Checkin> addCheckin(Checkin checkin) async {
    await _ensureLoaded();
    _cache.add(checkin);
    await _persist();
    return checkin;
  }

  static Future<void> updateCheckin(Checkin checkin) async {
    await _ensureLoaded();
    final index = _cache.indexWhere((c) => c.id == checkin.id);
    if (index != -1) {
      _cache[index] = checkin;
      await _persist();
    }
  }

  static Future<void> deleteCheckin(String checkinId) async {
    await _ensureLoaded();
    _cache.removeWhere((checkin) => checkin.id == checkinId);
    await _persist();
  }

  static Future<void> clear() async {
    _cache = [];
    _loaded = true;
    await _persist();
  }
}