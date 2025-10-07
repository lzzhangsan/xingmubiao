import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/models/user.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/screens/user_management_screen.dart';
import 'package:xingmubiao/src/services/goal_service.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key, this.initialGoal});

  final Goal? initialGoal;

  bool get isEditing => initialGoal != null;

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pointsController;

  final List<Map<String, String>> _categories = const [
    {'id': 'learning', 'name': '学习'},
    {'id': 'life', 'name': '生活'},
    {'id': 'interest', 'name': '兴趣'},
    {'id': 'challenge', 'name': '挑战'},
  ];

  final List<Map<String, String>> _frequencies = const [
    {'value': 'daily', 'name': '每天'},
    {'value': 'weekly', 'name': '每周'},
    {'value': 'monthly', 'name': '每月'},
    {'value': 'once', 'name': '一次性'},
  ];

  final List<Map<String, String>> _types = const [
    {'value': 'habit', 'name': '习惯'},
    {'value': 'task', 'name': '任务'},
    {'value': 'challenge', 'name': '挑战'},
  ];

  late String _selectedCategoryId;
  late String _frequency;
  late String _type;
  Set<String> _assignedChildIds = {};
  bool _assignedInitialized = false;

  @override
  void initState() {
    super.initState();
    final goal = widget.initialGoal;
    _titleController = TextEditingController(text: goal?.title ?? '');
    _descriptionController = TextEditingController(text: goal?.description ?? '');
    _pointsController =
        TextEditingController(text: goal != null ? goal.points.toString() : '');
    _selectedCategoryId = goal?.categoryId ?? 'learning';
    _frequency = goal?.frequency ?? 'daily';
    _type = goal?.type ?? 'habit';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_assignedInitialized) return;
    final provider = context.read<AppProvider>();
    final Goal? goal = widget.initialGoal;

    if (goal != null && goal.assignedTo.isNotEmpty) {
      _assignedChildIds = goal.assignedTo.toSet();
    } else {
      final selected = provider.selectedChild;
      if (selected != null) {
        _assignedChildIds = {selected.id};
      }
    }

    if (_assignedChildIds.isEmpty && provider.children.isNotEmpty) {
      _assignedChildIds = {provider.children.first.id};
    }

    _assignedInitialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _submitGoal() async {
    if (!_formKey.currentState!.validate()) return;

    if (_assignedChildIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个孩子')),
      );
      return;
    }

    try {
      final existing = widget.initialGoal;
      final goal = Goal(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        userId: existing?.userId ?? 'parent',
        assignedTo: _assignedChildIds.toList(),
        points: int.parse(_pointsController.text),
        createdAt: existing?.createdAt ?? DateTime.now(),
        startDate: existing?.startDate,
        endDate: existing?.endDate,
        isActive: existing?.isActive ?? true,
        frequency: _frequency,
        type: _type,
      );

      if (widget.isEditing) {
        await GoalService.updateGoal(goal);
      } else {
        await GoalService.addGoal(goal);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? '目标已更新' : '目标已创建')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final List<User> children = provider.children;
    final hasChildren = children.isNotEmpty;
    final title = widget.isEditing ? '编辑目标' : '新增目标';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: '保存',
            icon: const Icon(Icons.save),
            onPressed: hasChildren ? _submitGoal : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '目标名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入目标名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '目标说明',
                  hintText: '可选，填写目标要求或注意事项',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: '奖励积分',
                  border: OutlineInputBorder(),
                  suffixText: '分',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入积分';
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null) {
                    return '请输入整数';
                  }
                  // 移除正数限制，允许任何整数（正负都可以）
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildChoiceSection(
                title: '类别',
                options: _categories,
                selectedId: _selectedCategoryId,
                onSelected: (id) => setState(() => _selectedCategoryId = id),
              ),
              const SizedBox(height: 24),
              _buildChoiceSection(
                title: '频率',
                options: _frequencies,
                selectedId: _frequency,
                onSelected: (value) => setState(() => _frequency = value),
              ),
              const SizedBox(height: 24),
              _buildChoiceSection(
                title: '类型',
                options: _types,
                selectedId: _type,
                onSelected: (value) => setState(() => _type = value),
              ),
              const SizedBox(height: 24),
              Text(
                '适用孩子',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (!hasChildren)
                Card(
                  color: Colors.orange[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('当前还没有孩子成员，请先添加'),
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
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: children.map((child) {
                    final selected = _assignedChildIds.contains(child.id);
                    return FilterChip(
                      label: Text(child.name),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            _assignedChildIds.add(child.id);
                          } else {
                            _assignedChildIds.remove(child.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: hasChildren ? _submitGoal : null,
                  child: Text(widget.isEditing ? '保存目标' : '添加目标'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceSection({
    required String title,
    required List<Map<String, String>> options,
    required String selectedId,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final value = option['id'] ?? option['value']!;
            final selected = selectedId == value;
            return ChoiceChip(
              label: Text(option['name']!),
              selected: selected,
              onSelected: (isSelected) {
                if (isSelected) {
                  onSelected(value);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

