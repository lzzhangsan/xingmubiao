import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/storage/local_data_store.dart';

class GoalService {
  static const _storageKey = 'goals';
  static List<Goal> _cache = [];
  static bool _loaded = false;

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final data = await LocalDataStore.loadList(_storageKey);
    _cache = data.map(Goal.fromJson).toList();
    _loaded = true;
  }

  static Future<void> _persist() async {
    await LocalDataStore.saveList(
      _storageKey,
      _cache.map((goal) => goal.toJson()).toList(),
    );
  }

  static Future<List<Goal>> getGoals() async {
    await _ensureLoaded();
    return List<Goal>.from(_cache);
  }

  static Future<List<Goal>> getGoalsForChild(String childId) async {
    await _ensureLoaded();
    return _cache
        .where((goal) => goal.assignedTo.contains(childId))
        .toList();
  }

  static Future<Goal> addGoal(Goal goal) async {
    await _ensureLoaded();
    _cache.add(goal);
    await _persist();
    return goal;
  }

  static Future<void> updateGoal(Goal goal) async {
    await _ensureLoaded();
    final index = _cache.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _cache[index] = goal;
      await _persist();
    }
  }

  static Future<void> deleteGoal(String goalId) async {
    await _ensureLoaded();
    _cache.removeWhere((g) => g.id == goalId);
    await _persist();
  }

  static Future<void> clear() async {
    _cache = [];
    _loaded = true;
    await _persist();
  }
}
