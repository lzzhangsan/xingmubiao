import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/services/checkin_service.dart';
import 'package:xingmubiao/src/services/point_service.dart';
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
  Map<String, int> _totalPoints = {};
  Map<String, int> _todayPoints = {};
  Map<String, int> _remainingPoints = {};
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

    // 加载每个成员的积分
    final Map<String, int> totalPts = {};
    final Map<String, int> todayPts = {};
    final Map<String, int> remainPts = {};
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    for (final child in provider.children) {
      final pts = await PointService.getPointsByUser(child.id);
      final earned = pts.where((p) => p.type == 'earned').toList();
      final spent = pts.where((p) => p.type == 'spent').fold(0, (s, p) => s + p.amount);
      totalPts[child.id] = earned.fold<int>(0, (s, p) => s + p.amount);
      todayPts[child.id] = earned.where((p) => p.createdAt.isAfter(todayStart)).fold(0, (s, p) => s + p.amount);
      remainPts[child.id] = totalPts[child.id]! - spent;
    }

    if (mounted) {
      setState(() {
        _familyGoals = familyGoals;
        _dateCheckins = counts;
        _personalGoalCounts = personalCounts;
        _totalPoints = totalPts;
        _todayPoints = todayPts;
        _remainingPoints = remainPts;
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
                  ...(() {
                    final sorted = [...children]..sort((a, b) => (_todayPoints[b.id] ?? 0).compareTo(_todayPoints[a.id] ?? 0));
                    return sorted.map((child) {
                    final count = _dateCheckins[child.id] ?? 0;
                    final personal = _personalGoalCounts[child.id] ?? 0;
                    final family = _familyGoals.length;
                    final totalTasks = personal + family;
                    final progress = totalTasks > 0 ? (count / totalTasks).clamp(0.0, 1.0) : 0.0;
                    final rank = sorted.indexOf(child) + 1;
                    return Card(
                      child: Stack(
                        children: [
                          Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: child.avatarUrl.isNotEmpty ? FileImage(File(child.avatarUrl)) : null,
                                  child: child.avatarUrl.isEmpty ? Text(child.name.isNotEmpty ? child.name[child.name.length - 1] : '?') : null,
                                ),
                                const SizedBox(width: 8),
                                
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('历史总分：${_totalPoints[child.id] ?? 0}'),
                                      Text('今日得分：${_todayPoints[child.id] ?? 0}'),
                                      Text('剩余积分：${_remainingPoints[child.id] ?? 0}'),
                                      const SizedBox(height: 4),
                                      Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text('总任务 $totalTasks 项 · 打卡 $count 次', style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: count > 0
                                  ? const Icon(Icons.check_circle, color: Colors.green, size: 18)
                                  : const Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 18),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? Colors.green : Colors.blue),
                            ),
                          ],
                        ),
                          ),
                          if (rank <= 3)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: _CombinedRankBadge(rank: rank),
                            ),
                        ],
                      ),
                    );
                  }).toList();
                  })(),
                  if (children.isEmpty) const Text('暂无孩子成员'),
                  const SizedBox(height: 24),
                  Center(child: Text('点击右上角日历可查看历史进度', style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
    );
  }
}


class _RankMedal extends StatefulWidget {
  const _RankMedal({required this.rank});
  final int rank;

  @override
  State<_RankMedal> createState() => _RankMedalState();
}

class _RankMedalState extends State<_RankMedal> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rank > 3) {
      return Text('${widget.rank}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey));
    }
    final colors = [Colors.amber, Colors.grey.shade400, Colors.orange.shade700];
    return ScaleTransition(
      scale: Tween<double>(begin: 0.9, end: 1.15).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [colors[widget.rank - 1].withOpacity(0.9), colors[widget.rank - 1].withOpacity(0.3)]),
          boxShadow: [BoxShadow(color: colors[widget.rank - 1].withOpacity(0.6), blurRadius: 8, spreadRadius: 1)],
        ),
        child: const Icon(Icons.workspace_premium, color: Colors.white, size: 22),
      ),
    );
  }
}


class _AnimatedRankLabel extends StatefulWidget {
  const _AnimatedRankLabel({required this.rank});
  final int rank;

  @override
  State<_AnimatedRankLabel> createState() => _AnimatedRankLabelState();
}

class _AnimatedRankLabelState extends State<_AnimatedRankLabel> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = ['第1名', '第2名', '第3名'];
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.12).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.6), blurRadius: 6, spreadRadius: 1)],
        ),
        child: Text(
          labels[widget.rank - 1],
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }
}


class _CombinedRankBadge extends StatefulWidget {
  const _CombinedRankBadge({required this.rank});
  final int rank;

  @override
  State<_CombinedRankBadge> createState() => _CombinedRankBadgeState();
}

class _CombinedRankBadgeState extends State<_CombinedRankBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rank > 3) return const SizedBox.shrink();
    final medalColors = [
      [const Color(0xFFFFD700), const Color(0xFFFFA500), const Color(0xFFB8860B)], // gold
      [const Color(0xFFE8E8E8), const Color(0xFFC0C0C0), const Color(0xFF808080)], // silver
      [const Color(0xFFCD7F32), const Color(0xFFB87333), const Color(0xFF8B4513)], // bronze
    ];
    final ribbonColors = [
      [const Color(0xFFD32F2F), const Color(0xFF1976D2)], // gold ribbon red/blue
      [const Color(0xFF1976D2), const Color(0xFF0D47A1)], // silver ribbon blue
      [const Color(0xFF388E3C), const Color(0xFF1B5E20)], // bronze ribbon green
    ];
    final colors = medalColors[widget.rank - 1];
    final ribbons = ribbonColors[widget.rank - 1];
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 1.1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ribbon
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 8, height: 18, color: ribbons[0]),
              Container(width: 8, height: 18, color: ribbons[1]),
            ],
          ),
          // Medal
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [colors[0], colors[1], colors[2], colors[0]],
                stops: const [0.0, 0.35, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(color: colors[0].withOpacity(0.5), blurRadius: 8, spreadRadius: 1),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.9), width: 3),
            ),
            child: Container(
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [colors[0].withOpacity(0.95), colors[1]],
                  center: const Alignment(-0.3, -0.3),
                ),
                border: Border.all(color: colors[2].withOpacity(0.6), width: 1),
              ),
              child: Center(
                child: Text(
                  '${widget.rank}',
                  style: TextStyle(
                    color: widget.rank == 2 ? Colors.black87 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    shadows: const [Shadow(color: Colors.black38, blurRadius: 2, offset: Offset(0.5, 0.5))],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
