import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/models/checkin.dart';
import 'package:xingmubiao/src/models/point.dart';
import 'package:xingmubiao/src/models/reward.dart';
import 'package:xingmubiao/src/models/user.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/services/checkin_service.dart';
import 'package:xingmubiao/src/services/point_service.dart';
import 'package:xingmubiao/src/services/reward_service.dart';

class DataRepository {
  // 单例模式
  static final DataRepository _instance = DataRepository._internal();
  factory DataRepository() => _instance;
  DataRepository._internal();

  // 目标相关操作
  Future<List<Goal>> getGoals() async {
    return await GoalService.getGoals();
  }

  Future<Goal> addGoal(Goal goal) async {
    return await GoalService.addGoal(goal);
  }

  Future<void> updateGoal(Goal goal) async {
    await GoalService.updateGoal(goal);
  }

  Future<void> deleteGoal(String goalId) async {
    await GoalService.deleteGoal(goalId);
  }

  // 打卡相关操作
  Future<List<Checkin>> getCheckins() async {
    return await CheckinService.getCheckins();
  }

  Future<List<Checkin>> getCheckinsByGoal(String goalId) async {
    return await CheckinService.getCheckinsByGoal(goalId);
  }

  Future<List<Checkin>> getCheckinsByDate(DateTime date) async {
    return await CheckinService.getCheckinsByDate(date);
  }

  Future<Checkin> addCheckin(Checkin checkin) async {
    return await CheckinService.addCheckin(checkin);
  }

  Future<void> updateCheckin(Checkin checkin) async {
    await CheckinService.updateCheckin(checkin);
  }

  Future<void> deleteCheckin(String checkinId) async {
    await CheckinService.deleteCheckin(checkinId);
  }

  // 积分相关操作
  Future<List<Point>> getPoints() async {
    return await PointService.getPoints();
  }

  Future<List<Point>> getPointsByUser(String userId) async {
    return await PointService.getPointsByUser(userId);
  }

  Future<int> getTotalPoints(String userId) async {
    return await PointService.getTotalPoints(userId);
  }

  Future<Point> addPoint(Point point) async {
    return await PointService.addPoint(point);
  }

  Future<void> updatePoint(Point point) async {
    await PointService.updatePoint(point);
  }

  Future<void> deletePoint(String pointId) async {
    await PointService.deletePoint(pointId);
  }

  // 心愿相关操作
  Future<List<Reward>> getRewards() async {
    return await RewardService.getRewards();
  }

  Future<Reward> addReward(Reward reward) async {
    return await RewardService.addReward(reward);
  }

  Future<void> updateReward(Reward reward) async {
    await RewardService.updateReward(reward);
  }

  Future<void> deleteReward(String rewardId) async {
    await RewardService.deleteReward(rewardId);
  }

  // 用户相关操作
  Future<List<User>> getUsers() async {
    // 这里应该从用户服务获取用户列表
    // 暂时返回模拟数据
    return [
      User(
        id: 'parent1',
        name: '爸爸',
        email: 'parent@example.com',
        role: 'parent',
        avatarUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      User(
        id: 'child1',
        name: '小明',
        email: 'child@example.com',
        role: 'child',
        avatarUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
      ),
    ];
  }

  Future<User> addUser(User user) async {
    // 这里应该调用用户服务添加用户
    // 暂时直接返回用户
    return user;
  }

  Future<void> updateUser(User user) async {
    // 这里应该调用用户服务更新用户
  }

  Future<void> deleteUser(String userId) async {
    // 这里应该调用用户服务删除用户
  }
}