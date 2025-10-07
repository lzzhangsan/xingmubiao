import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/goal.dart';
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
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _submitGoal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final existing = widget.initialGoal;
      final goal = Goal(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId,
        userId: existing?.userId ?? 'user1',
        assignedTo: existing?.assignedTo ?? const ['child1'],
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
        SnackBar(
          content: Text(widget.isEditing ? '目标更新成功' : '目标添加成功'),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? '编辑目标' : '新增目标';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: '保存',
            icon: const Icon(Icons.save),
            onPressed: _submitGoal,
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
                  hintText: '补充目标的具体要求或备注',
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
                    return '请填写奖励积分';
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return '请输入大于 0 的整数';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _SectionTitle('类别'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((category) {
                  final isSelected = _selectedCategoryId == category['id'];
                  return ChoiceChip(
                    label: Text(category['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategoryId =
                            selected ? category['id']! : _selectedCategoryId;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _SectionTitle('频率'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _frequencies.map((frequency) {
                  final isSelected = _frequency == frequency['value'];
                  return ChoiceChip(
                    label: Text(frequency['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _frequency = selected ? frequency['value']! : _frequency;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              _SectionTitle('类型'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.map((type) {
                  final isSelected = _type == type['value'];
                  return ChoiceChip(
                    label: Text(type['name']!),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _type = selected ? type['value']! : _type;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitGoal,
                  child: Text(widget.isEditing ? '保存目标' : '添加目标'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
