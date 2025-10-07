import 'package:xingmubiao/src/models/goal.dart';

class GoalService {
  // 模拟数据，真实项目中可替换为接口或本地数据库
  static final List<Goal> _goals = [
    Goal(
      id: '1',
      title: '阅读 30 分钟',
      description: '每天坚持阅读半小时，培养持续专注力。',
      categoryId: 'learning',
      userId: 'user1',
      assignedTo: const ['child1'],
      points: 10,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      frequency: 'daily',
      type: 'habit',
    ),
    Goal(
      id: '2',
      title: '整理书桌',
      description: '学习结束后整理书桌，让学习环境更舒适。',
      categoryId: 'life',
      userId: 'user1',
      assignedTo: const ['child1'],
      points: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      frequency: 'daily',
      type: 'habit',
    ),
    Goal(
      id: '3',
      title: '完成数学作业',
      description: '按时完成当天布置的所有数学练习题。',
      categoryId: 'learning',
      userId: 'user1',
      assignedTo: const ['child1'],
      points: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      frequency: 'daily',
      type: 'task',
    ),
  ];

  static Future<List<Goal>> getGoals() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List<Goal>.from(_goals);
  }

  static Future<Goal> addGoal(Goal goal) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _goals.add(goal);
    return goal;
  }

  static Future<void> updateGoal(Goal goal) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
    }
  }

  static Future<void> deleteGoal(String goalId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _goals.removeWhere((g) => g.id == goalId);
  }
}
