import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/screens/add_goal_screen.dart';
import 'package:xingmubiao/src/screens/user_management_screen.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/widgets/child_selector.dart';

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
  bool _isFetching = false;
  AppProvider? _provider;
  String? _currentChildId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<AppProvider>(context);
    if (_provider != provider) {
      _provider?.removeListener(_handleProviderChanged);
      _provider = provider;
      provider.addListener(_handleProviderChanged);
      _handleProviderChanged();
    }
  }

  @override
  void dispose() {
    _provider?.removeListener(_handleProviderChanged);
    super.dispose();
  }

  void _handleProviderChanged() {
    final provider = _provider;
    if (provider == null || !provider.isInitialized) return;
    final newChildId = provider.selectedChild?.id;
    if (newChildId != _currentChildId) {
      _currentChildId = newChildId;
      _loadGoals();
    }
  }

  Future<void> _loadGoals() async {
    final provider = _provider;
    if (provider == null || !provider.isInitialized) return;
    final child = provider.selectedChild;
    if (child == null) {
      setState(() {
        _isLoading = false;
        _goals = [];
      });
      return;
    }

    if (_isFetching) return;
    _isFetching = true;

    setState(() => _isLoading = true);

    try {
      final goals = await GoalService.getGoalsForChild(child.id);
      if (!mounted) return;
      setState(() {
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载目标失败: $e')),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _openGoalEditor({Goal? goal}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddGoalScreen(initialGoal: goal)),
    );
    if (result == true) {
      await _loadGoals();
    }
  }

  void _deleteGoal(Goal goal) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除目标'),
          content: Text('确定要删除“${goal.title}”吗？'),
          actions: [
            TextButton(
              onPressed: () => navigator.pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                navigator.pop();
                try {
                  await GoalService.deleteGoal(goal.id);
                  if (!mounted) return;
                  messenger.showSnackBar(const SnackBar(content: Text('删除成功')));
                  await _loadGoals();
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('删除失败: $e')),
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

  Widget _buildNoChildView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.child_care_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('还没有孩子成员，无法管理目标'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const UserManagementScreen(),
                  ),
                );
              },
              child: const Text('前往成员管理'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final selectedChild = provider.selectedChild;

    final filteredGoals = _selectedCategoryId == 'all'
        ? _goals
        : _goals.where((goal) => goal.categoryId == _selectedCategoryId).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('目标管理'),
        actions: [
          const ChildSelector(),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加目标',
            onPressed: selectedChild == null ? null : () => _openGoalEditor(),
          ),
        ],
      ),
      body: !provider.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : selectedChild == null
              ? _buildNoChildView()
              : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadGoals,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            '${selectedChild.name} 当前共有 ${filteredGoals.length} 项目标',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((category) {
                              final selected = _selectedCategoryId == category['id'];
                              return ChoiceChip(
                                label: Text(category['name']!),
                                selected: selected,
                                onSelected: (value) {
                                  setState(() {
                                    _selectedCategoryId =
                                        value ? category['id']! : 'all';
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          if (filteredGoals.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: Text('暂无目标，点击右上角添加。')),
                            )
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
                      if (goal.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(goal.description),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '+${goal.points} 分',
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
                _InfoTag(icon: Icons.folder_outlined, label: category),
                _InfoTag(icon: Icons.calendar_today_outlined, label: frequency),
                _InfoTag(icon: Icons.bolt_outlined, label: type),
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
  const _InfoTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
