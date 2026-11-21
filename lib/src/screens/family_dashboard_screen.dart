import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/services/checkin_service.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  List<Goal> _familyGoals = [];
  Map<String, int> _todayCheckins = {};
  int _totalTodayCheckins = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goals = await GoalService.getFamilyGoals();
    final today = DateTime.now();
    final checkins = await CheckinService.getCheckinsByDate(today);
    final Map<String, int> counts = {};
    for (final c in checkins) {
      counts[c.userId] = (counts[c.userId] ?? 0) + 1;
    }
    if (mounted) {
      setState(() {
        _familyGoals = goals;
        _todayCheckins = counts;
        _totalTodayCheckins = checkins.length;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final children = provider.children;

    return Scaffold(
      appBar: AppBar(title: const Text('家庭总览')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Family summary card
                  Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text('今日家庭总览', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(children: [Text('${_familyGoals.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const Text('公共任务')]),
                              Column(children: [Text('$_totalTodayCheckins', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const Text('今日打卡')]),
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
                    const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('暂无家庭公共任务，可在创建目标时选择家庭归属')))
                  else
                    ..._familyGoals.map((g) => Card(
                          child: ListTile(
                            title: Text(g.title),
                            subtitle: Text('积分: ${g.points} · ${g.frequency == "daily" ? "每天" : g.frequency}'),
                            trailing: const Icon(Icons.group),
                          ),
                        )),
                  const SizedBox(height: 16),
                  const Text('今日成员进度', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...children.map((child) {
                    final count = _todayCheckins[child.id] ?? 0;
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(child: Text(child.name.isNotEmpty ? child.name[0] : '?')),
                        title: Text(child.name),
                        subtitle: Text('今日已打卡 $count 次'),
                        trailing: count > 0
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                      ),
                    );
                  }),
                  if (children.isEmpty) const Text('暂无孩子成员'),
                  const SizedBox(height: 24),
                  const Center(child: Text('下拉刷新获取最新进度', style: TextStyle(color: Colors.grey))),
                ],
              ),
            ),
    );
  }
}
