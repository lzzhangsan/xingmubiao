import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/services/goal_service.dart';

class GoalListScreen extends StatefulWidget {
  const GoalListScreen({super.key});

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  int _selectedCategoryIndex = 0;
  List<Goal> _goals = [];
  bool _isLoading = true;

  final List<String> _categories = [
    '全部',
    '学习',
    '生活',
    '兴趣',
    '挑战',
  ];

  final Map<String, String> _categoryMap = {
    '全部': '',
    '学习': 'learning',
    '生活': 'life',
    '兴趣': 'interest',
    '挑战': 'challenge',
  };

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final goals = await GoalService.getGoals();
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载目标失败: $e')),
        );
      }
    }
  }

  void _navigateToAddGoal() {
    Navigator.pushNamed(context, '/add-goal').then((value) {
      if (value == true) {
        _loadGoals(); // 如果添加了新目标，重新加载数据
      }
    });
  }

  void _editGoal(Goal goal) {
    // 这里应该导航到编辑目标页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能待实现')),
    );
  }

  void _deleteGoal(Goal goal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除目标"${goal.title}"吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await GoalService.deleteGoal(goal.id);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('删除成功')),
                    );
                    _loadGoals(); // 重新加载数据
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('删除失败: $e')),
                    );
                  }
                }
              },
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('目标管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddGoal,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 目标分类标签
                  _CategoryTabs(
                    categories: _categories,
                    selectedIndex: _selectedCategoryIndex,
                    onCategorySelected: (index) {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                    },
                  ),
                  
                  // 目标列表
                  _GoalList(
                    goals: _goals,
                    categoryFilter: _categoryMap[_categories[_selectedCategoryIndex]] ?? '',
                    onEdit: _editGoal,
                    onDelete: _deleteGoal,
                  ),
                ],
              ),
            ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  final List<String> categories;
  final int selectedIndex;
  final Function(int) onCategorySelected;

  const _CategoryTabs({
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...categories.asMap().entries.map((entry) => _CategoryTab(
                title: entry.value,
                isSelected: entry.key == selectedIndex,
                onTap: () => onCategorySelected(entry.key),
              )),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Function() onTap;

  const _CategoryTab({
    required this.title,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _GoalList extends StatelessWidget {
  final List<Goal> goals;
  final String categoryFilter;
  final Function(Goal) onEdit;
  final Function(Goal) onDelete;

  const _GoalList({
    required this.goals,
    required this.categoryFilter,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // 过滤目标
    List<Goal> filteredGoals = goals;
    if (categoryFilter.isNotEmpty) {
      filteredGoals = goals.where((goal) => goal.categoryId == categoryFilter).toList();
    }

    if (filteredGoals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('暂无目标'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredGoals.length,
      itemBuilder: (context, index) {
        final goal = filteredGoals[index];
        return _GoalListItem(
          goal: goal,
          onEdit: () => onEdit(goal),
          onDelete: () => onDelete(goal),
        );
      },
    );
  }
}

class _GoalListItem extends StatelessWidget {
  final Goal goal;
  final Function() onEdit;
  final Function() onDelete;

  const _GoalListItem({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, String> categoryNames = {
      'learning': '学习',
      'life': '生活',
      'interest': '兴趣',
      'challenge': '挑战',
    };

    final Map<String, String> frequencyNames = {
      'daily': '每日',
      'weekly': '每周',
      'monthly': '每月',
      'once': '一次',
    };

    final Map<String, String> typeNames = {
      'habit': '习惯',
      'task': '任务',
      'challenge': '挑战',
    };

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(goal.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal.description),
            const SizedBox(height: 4),
            Text(
              '${categoryNames[goal.categoryId] ?? goal.categoryId} · ${frequencyNames[goal.frequency] ?? goal.frequency} · ${typeNames[goal.type] ?? goal.type}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('+${goal.points}积分'),
            PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'edit') {
                  onEdit();
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: Text('编辑'),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}