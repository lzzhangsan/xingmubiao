import 'package:xingmubiao/src/models/reward.dart';
import 'package:xingmubiao/src/storage/local_data_store.dart';

class RewardService {
  static const _storageKey = 'rewards';
  static List<Reward> _cache = [];
  static bool _loaded = false;

  static Future<void> _ensureLoaded() async {
    if (_loaded) return;
    final data = await LocalDataStore.loadList(_storageKey);
    _cache = data.map(Reward.fromJson).toList();
    _loaded = true;
  }

  static Future<void> _persist() async {
    await LocalDataStore.saveList(
      _storageKey,
      _cache.map((reward) => reward.toJson()).toList(),
    );
  }

  static Future<List<Reward>> getRewards() async {
    await _ensureLoaded();
    return List<Reward>.from(_cache);
  }

  static Future<Reward> addReward(Reward reward) async {
    await _ensureLoaded();
    _cache.add(reward);
    await _persist();
    return reward;
  }

  static Future<void> updateReward(Reward reward) async {
    await _ensureLoaded();
    final index = _cache.indexWhere((r) => r.id == reward.id);
    if (index != -1) {
      _cache[index] = reward;
      await _persist();
    }
  }

  static Future<void> deleteReward(String rewardId) async {
    await _ensureLoaded();
    _cache.removeWhere((reward) => reward.id == rewardId);
    await _persist();
  }

  static Future<void> clear() async {
    _cache = [];
    _loaded = true;
    await _persist();
  }
}
