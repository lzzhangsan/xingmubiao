import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:xingmubiao/src/models/checkin.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/services/checkin_service.dart';
import 'package:xingmubiao/src/services/goal_service.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Goal> _goals = [];
  bool _isLoading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('今日打卡'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 日期选择
                  _DateSelector(
                    selectedDate: _selectedDate,
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = date;
                      });
                    },
                  ),
                  
                  // 打卡目标列表
                  _CheckinGoalList(
                    goals: _goals,
                    selectedDate: _selectedDate,
                  ),
                  
                  // 打卡统计
                  const _CheckinStats(),
                ],
              ),
            ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              onDateChanged(selectedDate.subtract(const Duration(days: 1)));
            },
          ),
          Text(
            '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              onDateChanged(selectedDate.add(const Duration(days: 1)));
            },
          ),
        ],
      ),
    );
  }
}

class _CheckinGoalList extends StatefulWidget {
  final List<Goal> goals;
  final DateTime selectedDate;

  const _CheckinGoalList({
    required this.goals,
    required this.selectedDate,
  });

  @override
  State<_CheckinGoalList> createState() => _CheckinGoalListState();
}

class _CheckinGoalListState extends State<_CheckinGoalList> {
  final Map<String, _CheckinGoalItemState> _itemStates = {};

  @override
  Widget build(BuildContext context) {
    if (widget.goals.isEmpty) {
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
      itemCount: widget.goals.length,
      itemBuilder: (context, index) {
        return _CheckinGoalItem(
          key: ValueKey(widget.goals[index].id),
          goal: widget.goals[index],
          selectedDate: widget.selectedDate,
          onStateCreated: (state) {
            _itemStates[widget.goals[index].id] = state;
          },
        );
      },
    );
  }
}

class _CheckinGoalItem extends StatefulWidget {
  final Goal goal;
  final DateTime selectedDate;
  final Function(_CheckinGoalItemState) onStateCreated;

  const _CheckinGoalItem({
    super.key,
    required this.goal,
    required this.selectedDate,
    required this.onStateCreated,
  });

  @override
  State<_CheckinGoalItem> createState() => _CheckinGoalItemState();
}

class _CheckinGoalItemState extends State<_CheckinGoalItem> {
  int _selectedScore = 0;
  final TextEditingController _commentController = TextEditingController();
  XFile? _image;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    widget.onStateCreated(this);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );
      if (image != null) {
        setState(() {
          _image = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败: $e')),
        );
      }
    }
  }

  Future<void> _submitCheckin() async {
    if (_selectedScore == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先评分')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final checkin = Checkin(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: widget.goal.id,
        userId: 'child1',
        score: _selectedScore,
        comment: _commentController.text.isNotEmpty ? _commentController.text : null,
        imageUrl: _image?.path, // 在实际应用中这里应该是上传后的URL
        createdAt: widget.selectedDate,
      );

      await CheckinService.addCheckin(checkin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('打卡成功')),
        );
        
        // 重置表单
        setState(() {
          _selectedScore = 0;
          _commentController.clear();
          _image = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('打卡失败: $e')),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.goal.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('+${widget.goal.points}积分'),
            const SizedBox(height: 16),
            
            // 评分组件
            const Text('请评分：'),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _selectedScore ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() {
                      _selectedScore = index + 1;
                    });
                  },
                );
              }),
            ),
            
            const SizedBox(height: 16),
            
            // 评论输入
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: '添加评论...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // 图片上传
            if (_image != null)
              Column(
                children: [
                  Image.file(
                    File(_image!.path),
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('拍照'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCheckin,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('提交'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckinStats extends StatelessWidget {
  const _CheckinStats();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日统计',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(title: '已完成', value: '2'),
              _StatCard(title: '总积分', value: '25'),
              _StatCard(title: '平均分', value: '4.5'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
