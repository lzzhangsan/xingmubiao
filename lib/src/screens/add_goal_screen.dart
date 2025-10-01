import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/services/goal_service.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  String _selectedCategory = '学习';
  String _frequency = 'daily';
  String _type = 'habit';

  final List<Map<String, String>> _categories = [
    {'id': 'learning', 'name': '学习'},
    {'id': 'life', 'name': '生活'},
    {'id': 'interest', 'name': '兴趣'},
    {'id': 'challenge', 'name': '挑战'},
  ];

  final List<Map<String, String>> _frequencies = [
    {'value': 'daily', 'name': '每日'},
    {'value': 'weekly', 'name': '每周'},
    {'value': 'monthly', 'name': '每月'},
    {'value': 'once', 'name': '一次'},
  ];

  final List<Map<String, String>> _types = [
    {'value': 'habit', 'name': '习惯'},
    {'value': 'task', 'name': '任务'},
    {'value': 'challenge', 'name': '挑战'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _submitGoal() async {
    if (_formKey.currentState!.validate()) {
      try {
        final goal = Goal(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          categoryId: _categories
              .firstWhere((category) => category['name'] == _selectedCategory)['id']!,
          userId: 'user1',
          assignedTo: ['child1'],
          points: int.parse(_pointsController.text),
          createdAt: DateTime.now(),
          frequency: _frequency,
          type: _type,
        );

        await GoalService.addGoal(goal);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('目标添加成功')),
          );
          Navigator.pop(context, true); // 返回并传递成功标志
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('添加失败: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加目标'),
        actions: [
          IconButton(
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
                  if (value == null || value.isEmpty) {
                    return '请输入目标名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '目标描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: '积分奖励',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入积分奖励';
                  }
                  if (int.tryParse(value) == null) {
                    return '请输入有效的数字';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('分类'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((category) {
                  return ChoiceChip(
                    label: Text(category['name']!),
                    selected: _selectedCategory == category['name'],
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category['name']! : '';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('频率'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _frequencies.map((frequency) {
                  return ChoiceChip(
                    label: Text(frequency['name']!),
                    selected: _frequency == frequency['value'],
                    onSelected: (selected) {
                      setState(() {
                        _frequency = selected ? frequency['value']! : 'daily';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('类型'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _types.map((type) {
                  return ChoiceChip(
                    label: Text(type['name']!),
                    selected: _type == type['value'],
                    onSelected: (selected) {
                      setState(() {
                        _type = selected ? type['value']! : 'habit';
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitGoal,
                  child: const Text('添加目标'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}