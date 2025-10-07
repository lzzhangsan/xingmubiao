import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/checkin.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/screens/user_management_screen.dart';
import 'package:xingmubiao/src/services/checkin_service.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/widgets/child_selector.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  DateTime _selectedDate = DateTime.now();
  List<Goal> _goals = [];
  List<Checkin> _checkins = [];
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
      _loadData();
    }
  }

  Future<void> _loadData({bool showLoader = true}) async {
    final provider = _provider;
    if (provider == null || !provider.isInitialized) return;
    final child = provider.selectedChild;
    if (child == null) {
      setState(() {
        _isLoading = false;
        _goals = [];
        _checkins = [];
      });
      return;
    }

    if (_isFetching) return;
    _isFetching = true;

    if (showLoader) {
      setState(() => _isLoading = true);
    }

    try {
      final goals = await GoalService.getGoalsForChild(child.id);
      final checkins =
          await CheckinService.getCheckinsForChildByDate(child.id, _selectedDate);

      if (!mounted) return;
      setState(() {
        _goals = goals;
        _checkins = checkins;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载打卡数据失败: $e')),
      );
    } finally {
      _isFetching = false;
    }
  }

  void _changeDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _loadData();
  }

  int get _completedCount => _checkins.length;

  int get _totalPoints {
    if (_checkins.isEmpty) return 0;
    final goalMap = {for (final goal in _goals) goal.id: goal};
    int total = 0;
    for (final c in _checkins) {
      final goal = goalMap[c.goalId];
      if (goal != null) {
        total += goal.points;
      }
    }
    return total;
  }

  double get _averageScore {
    if (_checkins.isEmpty) return 0;
    final sum = _checkins.fold<int>(0, (acc, item) => acc + item.score);
    return sum / _checkins.length;
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
            const Text('还没有孩子成员，请先添加'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日打卡'),
        actions: const [ChildSelector()],
      ),
      body: !provider.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : selectedChild == null
              ? _buildNoChildView()
              : _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: () => _loadData(showLoader: false),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            _DateSelector(
                              selectedDate: _selectedDate,
                              onDateChanged: _changeDate,
                            ),
                            _CheckinGoalList(
                              childId: selectedChild.id,
                              goals: _goals,
                              selectedDate: _selectedDate,
                              onSubmitted: () => _loadData(showLoader: false),
                            ),
                            _CheckinStats(
                              completedCount: _completedCount,
                              totalPoints: _totalPoints,
                              averageScore: _averageScore,
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => onDateChanged(selectedDate.subtract(const Duration(days: 1))),
          ),
          Text(
            '${selectedDate.year}年${selectedDate.month}月${selectedDate.day}日',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () => onDateChanged(selectedDate.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }
}

class _CheckinGoalList extends StatelessWidget {
  const _CheckinGoalList({
    required this.childId,
    required this.goals,
    required this.selectedDate,
    required this.onSubmitted,
  });

  final String childId;
  final List<Goal> goals;
  final DateTime selectedDate;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('今天还没有需要打卡的目标'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: goals.length,
      itemBuilder: (context, index) {
        return _CheckinGoalItem(
          key: ValueKey(goals[index].id),
          childId: childId,
          goal: goals[index],
          selectedDate: selectedDate,
          onSubmitted: onSubmitted,
        );
      },
    );
  }
}

class _CheckinGoalItem extends StatefulWidget {
  const _CheckinGoalItem({
    super.key,
    required this.childId,
    required this.goal,
    required this.selectedDate,
    required this.onSubmitted,
  });

  final String childId;
  final Goal goal;
  final DateTime selectedDate;
  final VoidCallback onSubmitted;

  @override
  State<_CheckinGoalItem> createState() => _CheckinGoalItemState();
}

class _CheckinGoalItemState extends State<_CheckinGoalItem> {
  int _selectedScore = 0;
  final TextEditingController _commentController = TextEditingController();
  XFile? _image;
  bool _isSubmitting = false;
  String? _existingCheckinId; // 若已打卡则保存其ID，支持覆盖更新

  @override
  void initState() {
    super.initState();
    _loadExistingIfAny();
  }

  Future<void> _loadExistingIfAny() async {
    try {
      final sameDayCheckins = await CheckinService.getCheckinsForChildByDate(
        widget.childId,
        widget.selectedDate,
      );
      final existing = sameDayCheckins.firstWhere(
        (c) => c.goalId == widget.goal.id,
        orElse: () => Checkin(
          id: '',
          goalId: widget.goal.id,
          userId: widget.childId,
          score: 0,
          comment: null,
          imageUrl: null,
          createdAt: widget.selectedDate,
        ),
      );
      if (existing.id.isNotEmpty) {
        setState(() {
          _existingCheckinId = existing.id;
          _selectedScore = existing.score;
          if (existing.comment != null) {
            _commentController.text = existing.comment!;
          }
          if (existing.imageUrl != null && existing.imageUrl!.isNotEmpty) {
            _image = XFile(existing.imageUrl!);
          }
        });
      }
    } catch (_) {
      // 读取失败不影响打卡流程
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() => _image = image);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  Future<void> _submitCheckin() async {
    if (_selectedScore == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先给完成程度评分')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final newOrUpdated = Checkin(
        id: _existingCheckinId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        goalId: widget.goal.id,
        userId: widget.childId,
        score: _selectedScore,
        comment: _commentController.text.isNotEmpty ? _commentController.text : null,
        imageUrl: _image?.path,
        createdAt: widget.selectedDate,
      );

      if (_existingCheckinId == null) {
        await CheckinService.addCheckin(newOrUpdated);
      } else {
        await CheckinService.updateCheckin(newOrUpdated);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存打卡')),
      );

      setState(() {
        _existingCheckinId = newOrUpdated.id;
        _isSubmitting = false;
      });

      widget.onSubmitted();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打卡失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.goal.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (widget.goal.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.goal.description),
            ],
            const SizedBox(height: 12),
            const Text('完成评分'),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                final score = index + 1;
                return IconButton(
                  icon: Icon(
                    Icons.star,
                    color: score <= _selectedScore ? Colors.amber : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() => _selectedScore = score);
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: '补充评语（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            if (_image != null)
              Column(
                children: [
                  Image.file(
                    File(_image!.path),
                    height: 120,
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
  const _CheckinStats({
    required this.completedCount,
    required this.totalPoints,
    required this.averageScore,
  });

  final int completedCount;
  final int totalPoints;
  final double averageScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '今日统计',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatCard(title: '已完成', value: completedCount.toString()),
              _StatCard(title: '获取积分', value: totalPoints.toString()),
              _StatCard(title: '平均评分', value: averageScore.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 100,
        height: 90,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
