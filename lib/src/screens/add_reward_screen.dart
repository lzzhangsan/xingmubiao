import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/reward.dart';
import 'package:xingmubiao/src/services/reward_service.dart';

class AddRewardScreen extends StatefulWidget {
  const AddRewardScreen({super.key, this.initialReward});

  final Reward? initialReward;

  bool get isEditing => initialReward != null;

  @override
  State<AddRewardScreen> createState() => _AddRewardScreenState();
}

class _AddRewardScreenState extends State<AddRewardScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _pointsController;

  @override
  void initState() {
    super.initState();
    final reward = widget.initialReward;
    _titleController = TextEditingController(text: reward?.title ?? '');
    _descriptionController = TextEditingController(text: reward?.description ?? '');
    _pointsController =
        TextEditingController(text: reward != null ? reward.pointsRequired.toString() : '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _submitReward() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final existing = widget.initialReward;
      final reward = Reward(
        id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        pointsRequired: int.parse(_pointsController.text),
        imageUrl: existing?.imageUrl,
        isActive: existing?.isActive ?? true,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );

      if (widget.isEditing) {
        await RewardService.updateReward(reward);
      } else {
        await RewardService.addReward(reward);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? '奖励更新成功' : '奖励添加成功'),
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
    final title = widget.isEditing ? '编辑奖励' : '新增奖励';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: '保存',
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
                  labelText: '奖励名称',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入奖励名称';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '奖励说明',
                  hintText: '描述奖励内容、使用规则或注意事项',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入奖励说明';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pointsController,
                decoration: const InputDecoration(
                  labelText: '兑换所需积分',
                  border: OutlineInputBorder(),
                  suffixText: '分',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请填写积分';
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null) {
                    return '请输入整数';
                  }
                  // 移除正数限制，允许任何整数（正负都可以）
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitReward,
                  child: Text(widget.isEditing ? '保存奖励' : '添加奖励'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
