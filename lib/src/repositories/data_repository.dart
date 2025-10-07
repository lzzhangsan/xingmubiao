import 'package:xingmubiao/src/models/checkin.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/models/point.dart';
import 'package:xingmubiao/src/models/reward.dart';
import 'package:xingmubiao/src/models/user.dart';
import 'package:xingmubiao/src/services/checkin_service.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/services/point_service.dart';
import 'package:xingmubiao/src/services/reward_service.dart';
import 'package:xingmubiao/src/services/user_service.dart';

class DataRepository {
  DataRepository._internal();

  static final DataRepository _instance = DataRepository._internal();

  factory DataRepository() => _instance;

  Future<List<Goal>> getGoals() => GoalService.getGoals();

  Future<List<Goal>> getGoalsForChild(String childId) =>
      GoalService.getGoalsForChild(childId);

  Future<Goal> addGoal(Goal goal) => GoalService.addGoal(goal);

  Future<void> updateGoal(Goal goal) => GoalService.updateGoal(goal);

  Future<void> deleteGoal(String goalId) => GoalService.deleteGoal(goalId);

  Future<List<Checkin>> getCheckins() => CheckinService.getCheckins();

  Future<List<Checkin>> getCheckinsForChild(String childId) =>
      CheckinService.getCheckinsForChild(childId);

  Future<List<Checkin>> getCheckinsForChildByDate(
    String childId,
    DateTime date,
  ) =>
      CheckinService.getCheckinsForChildByDate(childId, date);

  Future<Checkin> addCheckin(Checkin checkin) =>
      CheckinService.addCheckin(checkin);

  Future<void> updateCheckin(Checkin checkin) =>
      CheckinService.updateCheckin(checkin);

  Future<void> deleteCheckin(String checkinId) =>
      CheckinService.deleteCheckin(checkinId);

  Future<List<Point>> getPoints() => PointService.getPoints();

  Future<List<Point>> getPointsByUser(String userId) =>
      PointService.getPointsByUser(userId);

  Future<int> getTotalPoints(String userId) =>
      PointService.getTotalPoints(userId);

  Future<Point> addPoint(Point point) => PointService.addPoint(point);

  Future<void> updatePoint(Point point) => PointService.updatePoint(point);

  Future<void> deletePoint(String pointId) =>
      PointService.deletePoint(pointId);

  Future<List<Reward>> getRewards() => RewardService.getRewards();

  Future<Reward> addReward(Reward reward) => RewardService.addReward(reward);

  Future<void> updateReward(Reward reward) =>
      RewardService.updateReward(reward);

  Future<void> deleteReward(String rewardId) =>
      RewardService.deleteReward(rewardId);

  Future<List<User>> getUsers() async {
    await UserService.ensureDefaultUsers();
    return UserService.getUsers();
  }

  Future<User> addUser(User user) async {
    await UserService.addUser(user);
    return user;
  }

  Future<void> updateUser(User user) => UserService.updateUser(user);

  Future<void> deleteUser(String userId) => UserService.deleteUser(userId);
}
