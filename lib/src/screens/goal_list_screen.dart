import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/screens/add_goal_screen.dart';
import 'package:xingmubiao/src/services/goal_service.dart';

class GoalListScreen extends StatefulWidget {
  const GoalListScreen({super.key});

  @override
  State<GoalListScreen> createState() => _GoalListScreenState();
}

class _GoalListScreenState extends State<GoalListScreen> {
  final List<Map<String, String>> _categories = const [
    {'id': 'all', 'name': '全部'},
    {'id': 'learning', 'name': '学习'},
    {'id': 'life', 'name': '生活'},
    {'id': 'interest', 'name': '兴趣'},
    {'id': 'challenge', 'name': '挑战'},
  ];

  String _selectedCategoryId = 'all';
  List<Goal> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    try {
      setState(() => _isLoading = true);
      final goals = await GoalService.getGoals();
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载目标失败：$e')),
      );
    }
  }

  Future<void> _openGoalEditor({Goal? goal}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddGoalScreen(initialGoal: goal),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      await _loadGoals();
    }
  }

  void _deleteGoal(Goal goal) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: Text('确定要删除目标“${goal.title}”吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await GoalService.deleteGoal(goal.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('删除成功')),
                  );
                  await _loadGoals();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('删除失败：$e')),
                  );
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
    final filteredGoals = _selectedCategoryId == 'all'
        ? _goals
        : _goals.where((goal) => goal.categoryId == _selectedCategoryId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('目标管理'),
        actions: [
          IconButton(
            tooltip: '添加目标',
            icon: const Icon(Icons.add),
            onPressed: () => _openGoalEditor(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGoals,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '为孩子安排学习与生活任务，使用积分激励持续成长。',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildCategorySelector(),
                  const SizedBox(height: 16),
                  if (filteredGoals.isEmpty)
                    _EmptyGoalPlaceholder(onAddGoal: () => _openGoalEditor())
                  else
                    ...filteredGoals.map(
                      (goal) => _GoalListItem(
                        goal: goal,
                        onEdit: () => _openGoalEditor(goal: goal),
                        onDelete: () => _deleteGoal(goal),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isSelected = _selectedCategoryId == category['id'];
        return ChoiceChip(
          label: Text(category['name']!),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCategoryId = selected ? category['id']! : 'all';
            });
          },
        );
      }).toList(),
    );
  }
}

class _GoalListItem extends StatelessWidget {
  const _GoalListItem({
    required this.goal,
    required this.onEdit,
    required this.onDelete,
  });

  final Goal goal;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const Map<String, String> _categoryNames = {
    'learning': '学习',
    'life': '生活',
    'interest': '兴趣',
    'challenge': '挑战',
  };

  static const Map<String, String> _frequencyNames = {
    'daily': '每天',
    'weekly': '每周',
    'monthly': '每月',
    'once': '一次性',
  };

  static const Map<String, String> _typeNames = {
    'habit': '习惯',
    'task': '任务',
    'challenge': '挑战',
  };

  @override
  Widget build(BuildContext context) {
    final category = _categoryNames[goal.categoryId] ?? goal.categoryId;
    final frequency = _frequencyNames[goal.frequency] ?? goal.frequency;
    final type = _typeNames[goal.type] ?? goal.type;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        goal.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '+${goal.points}积分',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoTag(label: category, icon: Icons.folder),
                _InfoTag(label: frequency, icon: Icons.calendar_today),
                _InfoTag(label: type, icon: Icons.bolt),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('编辑'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('删除'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyGoalPlaceholder extends StatelessWidget {
  const _EmptyGoalPlaceholder({required this.onAddGoal});

  final VoidCallback onAddGoal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.sticky_note_2_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              '还没有设置目标',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '制定学习与生活计划，让孩子每天都有清晰的努力方向。',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAddGoal,
              child: const Text('立即添加目标'),
            ),
          ],
        ),
      ),
    );
  }
}
