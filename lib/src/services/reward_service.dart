import 'package:xingmubiao/src/models/reward.dart';

class RewardService {
  // 模拟的心愿奖励数据
  static final List<Reward> _rewards = [
    Reward(
      id: '1',
      title: '周末亲子出游',
      description: '一起去动物园或博物馆度过愉快的半天。',
      pointsRequired: 200,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    Reward(
      id: '2',
      title: '额外平板使用时间',
      description: '可额外使用 30 分钟的平板娱乐时间。',
      pointsRequired: 150,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    Reward(
      id: '3',
      title: '喜欢的小零食',
      description: '兑换一份孩子最喜欢的健康小零食。',
      pointsRequired: 80,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static Future<List<Reward>> getRewards() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List<Reward>.from(_rewards);
  }

  static Future<Reward> addReward(Reward reward) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _rewards.add(reward);
    return reward;
  }

  static Future<void> updateReward(Reward reward) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _rewards.indexWhere((r) => r.id == reward.id);
    if (index != -1) {
      _rewards[index] = reward;
    }
  }

  static Future<void> deleteReward(String rewardId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _rewards.removeWhere((r) => r.id == rewardId);
  }
}
