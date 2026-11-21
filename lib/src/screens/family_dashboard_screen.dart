import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/services/goal_service.dart';

class FamilyDashboardScreen extends StatefulWidget {
  const FamilyDashboardScreen({super.key});

  @override
  State<FamilyDashboardScreen> createState() => _FamilyDashboardScreenState();
}

class _FamilyDashboardScreenState extends State<FamilyDashboardScreen> {
  List<Goal> _familyGoals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final goals = await GoalService.getFamilyGoals();
    if (mounted) {
      setState(() {
        _familyGoals = goals;
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
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('家庭公共任务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('共 ${_familyGoals.length} 项'),
                          const SizedBox(height: 12),
                          ..._familyGoals.map((g) => ListTile(
                                title: Text(g.title),
                                subtitle: Text('积分: ${g.points}'),
                                dense: true,
                              )),
                          if (_familyGoals.isEmpty) const Text('暂无家庭公共任务，可在创建目标时选择家庭归属'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('家庭成员', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...children.map((child) => Card(
                        child: ListTile(
                          title: Text(child.name),
                          subtitle: const Text('个人任务进度待完善（下一阶段加入打卡统计）'),
                          trailing: const Icon(Icons.person),
                        ),
                      )),
                  if (children.isEmpty) const Text('暂无孩子成员'),
                ],
              ),
            ),
    );
  }
}
