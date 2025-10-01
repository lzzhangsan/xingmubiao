import 'package:flutter/material.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/services/point_service.dart';
import 'package:xingmubiao/src/models/goal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _totalPoints = 0;
  List<Goal> _todayGoals = [];
  List<bool> _checkedGoals = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // 加载积分数据
    final points = await PointService.getTotalPoints('child1');
    
    // 加载今日目标
    final goals = await GoalService.getGoals();
    
    setState(() {
      _totalPoints = points;
      _todayGoals = goals;
      _checkedGoals = List.generate(goals.length, (index) => false);
    });
  }

  void _toggleGoal(int index) {
    setState(() {
      _checkedGoals[index] = !_checkedGoals[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('星目标'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // 处理通知点击
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('暂无新通知')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 顶部统计卡片
            _StatisticsCard(totalPoints: _totalPoints),
            
            // 今日目标列表
            _TodayGoalsSection(
              goals: _todayGoals,
              checkedGoals: _checkedGoals,
              onToggleGoal: _toggleGoal,
            ),
            
            // 心愿库预览
            const _WishlistPreview(),
            
            // 成长轨迹预览
            const _GrowthChartPreview(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 添加新目标
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('添加新目标功能待实现')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final int totalPoints;

  const _StatisticsCard({required this.totalPoints});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(title: '今日积分', value: '20'),
            _StatItem(title: '本周积分', value: '120'),
            _StatItem(title: '总积分', value: totalPoints.toString()),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String title;
  final String value;

  const _StatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _TodayGoalsSection extends StatelessWidget {
  final List<Goal> goals;
  final List<bool> checkedGoals;
  final Function(int) onToggleGoal;

  const _TodayGoalsSection({
    required this.goals,
    required this.checkedGoals,
    required this.onToggleGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '今日目标',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // 这里会显示今日需要打卡的目标列表
        if (goals.isEmpty)
          const Center(child: Text('暂无目标'))
        else
          ...goals.asMap().entries.map((entry) => _GoalItem(
                title: entry.value.title,
                points: entry.value.points,
                isChecked: checkedGoals[entry.key],
                onChanged: (value) => onToggleGoal(entry.key),
              )),
      ],
    ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  final String title;
  final int points;
  final bool isChecked;
  final Function(bool?) onChanged;

  const _GoalItem({
    required this.title,
    required this.points,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: isChecked,
          onChanged: onChanged,
        ),
        title: Text(title),
        trailing: Text('+${points}积分'),
      ),
    );
  }
}

class _WishlistPreview extends StatelessWidget {
  const _WishlistPreview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '心愿库',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // 跳转到心愿库页面
                  Navigator.pushNamed(context, '/wishlist');
                },
                child: const Text('查看更多'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 心愿预览列表
          Card(
            child: ListTile(
              title: const Text('玩具车'),
              subtitle: const Text('需要200积分'),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('积分不足，无法兑换')),
                  );
                },
                child: const Text('兑换'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GrowthChartPreview extends StatelessWidget {
  const _GrowthChartPreview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '成长轨迹',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // 简单的图表预览
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text('成长轨迹图表'),
            ),
          ),
        ],
      ),
    );
  }
}