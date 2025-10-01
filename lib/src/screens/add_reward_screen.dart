import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/reward.dart';
import 'package:xingmubiao/src/services/reward_service.dart';

class AddRewardScreen extends StatefulWidget {
  const AddRewardScreen({super.key});

  @override
  State<AddRewardScreen> createState() => _AddRewardScreenState();
}

class _AddRewardScreenState extends State<AddRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _submitReward() async {
    if (_formKey.currentState!.validate()) {
      try {
        final reward = Reward(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          pointsRequired: int.parse(_pointsController.text),
          createdAt: DateTime.now(),
        );

        await RewardService.addReward(reward);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('心愿添加成功')),
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
        title: const Text('添加心愿'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _submitReward,
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
                  labelText: '心愿名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入心愿名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '心愿描述',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入心愿描述';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: '所需积分',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入所需积分';
                  }
                  if (int.tryParse(value) == null) {
                    return '请输入有效的数字';
                  }
                  if (int.parse(value) <= 0) {
                    return '积分必须大于0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitReward,
                  child: const Text('添加心愿'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}