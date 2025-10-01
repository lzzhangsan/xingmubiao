import 'package:xingmubiao/src/models/goal.dart';

class GoalService {
  // 模拟数据
  static final List<Goal> _goals = [
    Goal(
      id: '1',
      title: '阅读30分钟',
      description: '每天阅读30分钟，培养阅读习惯',
      categoryId: 'learning',
      userId: 'user1',
      assignedTo: ['child1'],
      points: 10,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      frequency: 'daily',
      type: 'habit',
    ),
    Goal(
      id: '2',
      title: '整理书桌',
      description: '保持书桌整洁有序',
      categoryId: 'life',
      userId: 'user1',
      assignedTo: ['child1'],
      points: 5,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      frequency: 'daily',
      type: 'habit',
    ),
    Goal(
      id: '3',
      title: '完成数学作业',
      description: '按时完成每天的数学作业',
      categoryId: 'learning',
      userId: 'user1',
      assignedTo: ['child1'],
      points: 15,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      frequency: 'daily',
      type: 'task',
    ),
  ];

  static Future<List<Goal>> getGoals() async {
    // 模拟网络延迟
    await Future.delayed(const Duration(milliseconds: 500));
    return _goals;
  }

  static Future<Goal> addGoal(Goal goal) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _goals.add(goal);
    return goal;
  }

  static Future<void> updateGoal(Goal goal) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _goals.indexWhere((g) => g.id == goal.id);
    if (index != -1) {
      _goals[index] = goal;
    }
  }

  static Future<void> deleteGoal(String goalId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _goals.removeWhere((g) => g.id == goalId);
  }
}