import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/services/checkin_service.dart';
import 'package:intl/intl.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  List<Goal> _familyGoals = [];
  Map<String, int> _dateCheckins = {};
  Map<String, int> _personalGoalCounts = {};
  int _totalDateCheckins = 0;
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final familyGoals = await GoalService.getFamilyGoals();
    final checkins = await CheckinService.getCheckinsByDate(_selectedDate);
    final Map<String, int> counts = {};
    for (final c in checkins) {
      counts[c.userId] = (counts[c.userId] ?? 0) + 1;
    }

    final provider = context.read<AppProvider>();
    final Map<String, int> personalCounts = {};
    for (final child in provider.children) {
      final personal = await GoalService.getPersonalGoalsForChild(child.id);
      personalCounts[child.id] = personal.length;
    }

    if (mounted) {
      setState(() {
        _familyGoals = familyGoals;
        _dateCheckins = counts;
        _personalGoalCounts = personalCounts;
        _totalDateCheckins = checkins.length;
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loading = true;
      });
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final children = provider.children;
    final dateLabel = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('家庭总览'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDate,
            tooltip: '选择日期查看历史进度',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(isToday ? '今日家庭总览' : '$dateLabel 进度', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(children: [Text('${_familyGoals.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const Text('公共任务')]),
                              Column(children: [Text('$_totalDateCheckins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const Text('打卡次数')]),
                              Column(children: [Text('${children.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const Text('家庭成员')]),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('家庭公共任务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (_familyGoals.isEmpty)
                    const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('暂无家庭公共任务')))
                  else
                    ..._familyGoals.map((g) => Card(
                          child: ListTile(
                            title: Text(g.title),
                            subtitle: Text('积分: ${g.points}'),
                            trailing: const Icon(Icons.group),
                          ),
                        )),
                  const SizedBox(height: 16),
                  Text(isToday ? '今日成员进度' : '$dateLabel 成员进度', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...children.map((child) {
                    final count = _dateCheckins[child.id] ?? 0;
                    final personal = _personalGoalCounts[child.id] ?? 0;
                    final progress = personal > 0 ? (count / personal).clamp(0.0, 1.0) : 0.0;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(child: Text(child.name.isNotEmpty ? child.name[0] : '?')),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('个人任务 $personal 项 · 打卡 $count 次', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                count > 0
                                    ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                    : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 20),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? Colors.green : Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  if (children.isEmpty) const Text('暂无孩子成员'),
                  const SizedBox(height: 24),
                  Center(child: Text('点击右上角日历可查看历史进度', style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
    );
  }
}
