import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/models/point.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/services/point_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _totalPoints = 0;
  List<Goal> _todayGoals = [];
  List<bool> _checkedGoals = [];
  bool _isLoading = true;
  late AnimationController _pointsController;
  late Animation<int> _pointsAnimation;

  @override
  void initState() {
    super.initState();
    _pointsController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // 加载积分数据
      final points = await PointService.getTotalPoints('child1');
      
      // 加载今日目标
      final goals = await GoalService.getGoals();
      
      setState(() {
        _totalPoints = points;
        _todayGoals = goals;
        _checkedGoals = List.generate(goals.length, (index) => false);
        _isLoading = false;
      });
      
      // 设置积分动画
      _pointsAnimation = IntTween(
        begin: _pointsAnimation?.value ?? 0,
        end: points,
      ).animate(_pointsController);
      _pointsController.forward(from: 0.0);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    }
  }

  void _toggleGoal(int index) {
    setState(() {
      _checkedGoals[index] = !_checkedGoals[index];
    });
    
    // 这里应该添加积分逻辑
    if (_checkedGoals[index]) {
      _addPointsForGoal(_todayGoals[index]);
    }
  }

  Future<void> _addPointsForGoal(Goal goal) async {
    try {
      final point = Point(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: 'child1',
        amount: goal.points,
        reason: '完成目标: ${goal.title}',
        type: 'earned',
        relatedId: goal.id,
        createdAt: DateTime.now(),
      );
      
      await PointService.addPoint(point);
      
      // 更新总积分显示
      final points = await PointService.getTotalPoints('child1');
      setState(() {
        _totalPoints = points;
      });
      
      // 设置积分动画
      _pointsAnimation = IntTween(
        begin: _pointsAnimation.value,
        end: points,
      ).animate(_pointsController);
      _pointsController.forward(from: 0.0);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('获得${goal.points}积分！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('积分添加失败: $e')),
        );
      }
    }
  }

  void _navigateToAddGoal() {
    // 导航到添加目标页面
    Navigator.pushNamed(context, '/add-goal').then((value) {
      if (value == true) {
        _loadData(); // 如果添加了新目标，重新加载数据
      }
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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 导航到设置页面
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // 顶部统计卡片
                  _StatisticsCard(
                    totalPoints: _totalPoints,
                    pointsAnimation: _pointsAnimation,
                  ),
                  
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
        onPressed: _navigateToAddGoal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  final int totalPoints;
  final Animation<int>? pointsAnimation;

  const _StatisticsCard({
    required this.totalPoints,
    this.pointsAnimation,
  });

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
            _AnimatedStatItem(
              title: '总积分',
              value: totalPoints,
              animation: pointsAnimation,
            ),
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

class _AnimatedStatItem extends StatelessWidget {
  final String title;
  final int value;
  final Animation<int>? animation;

  const _AnimatedStatItem({
    required this.title,
    required this.value,
    this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        animation != null
            ? AnimatedBuilder(
                animation: animation!,
                builder: (context, child) {
                  return Text(
                    animation!.value.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              )
            : Text(
                value.toString(),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '今日目标',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  // 跳转到目标管理页面
                  Navigator.pushNamed(context, '/goals');
                },
                child: const Text('管理目标'),
              ),
            ],
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

class _GoalItem extends StatefulWidget {
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
  State<_GoalItem> createState() => _GoalItemState();
}

class _GoalItemState extends State<_GoalItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (widget.isChecked) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant _GoalItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isChecked != widget.isChecked) {
      if (widget.isChecked) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Card(
        child: ListTile(
          leading: Checkbox(
            value: widget.isChecked,
            onChanged: widget.onChanged,
          ),
          title: Text(widget.title),
          trailing: Text('+${widget.points}积分'),
        ),
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