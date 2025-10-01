import 'package:xingmubiao/src/models/reward.dart';

class RewardService {
  // 模拟心愿数据
  static final List<Reward> _rewards = [
    Reward(
      id: '1',
      title: '玩具车',
      description: '遥控玩具车一辆',
      pointsRequired: 200,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Reward(
      id: '2',
      title: '绘本',
      description: '精美绘本一本',
      pointsRequired: 150,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Reward(
      id: '3',
      title: '冰淇淋',
      description: '喜欢的口味任选',
      pointsRequired: 50,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static Future<List<Reward>> getRewards() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    return _rewards;
  }

  static Future<Reward> addReward(Reward reward) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _rewards.add(reward);
    return reward;
  }

  static Future<void> updateReward(Reward reward) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _rewards.indexWhere((r) => r.id == reward.id);
    if (index != -1) {
      _rewards[index] = reward;
    }
  }

  static Future<void> deleteReward(String rewardId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _rewards.removeWhere((r) => r.id == rewardId);
  }
}