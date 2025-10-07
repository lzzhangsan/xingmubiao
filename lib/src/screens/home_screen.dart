import 'package:flutter/material.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/models/point.dart';
import 'package:xingmubiao/src/models/reward.dart';
import 'package:xingmubiao/src/screens/add_goal_screen.dart';
import 'package:xingmubiao/src/screens/checkin_screen.dart';
import 'package:xingmubiao/src/screens/goal_list_screen.dart';
import 'package:xingmubiao/src/screens/wishlist_screen.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/services/point_service.dart';
import 'package:xingmubiao/src/services/reward_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _totalPoints = 0;
  List<Goal> _todayGoals = [];
  List<bool> _checkedGoals = [];
  List<Reward> _wishlistPreview = [];
  bool _isLoading = true;

  late final AnimationController _pointsController;
  Animation<int>? _pointsAnimation;

  @override
  void initState() {
    super.initState();
    _pointsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _loadData();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool showLoader = true}) async {
    try {
      if (showLoader) {
        setState(() => _isLoading = true);
      }

      final previousPoints = _totalPoints;
      final pointsFuture = PointService.getTotalPoints('child1');
      final goalsFuture = GoalService.getGoals();
      final rewardsFuture = RewardService.getRewards();

      final points = await pointsFuture;
      final goals = await goalsFuture;
      final rewards = await rewardsFuture;

      if (!mounted) return;

      setState(() {
        _totalPoints = points;
        _todayGoals = goals;
        _checkedGoals = List<bool>.filled(goals.length, false);
        _wishlistPreview = rewards.take(3).toList();
        _isLoading = false;
        _pointsAnimation = IntTween(
          begin: previousPoints,
          end: points,
        ).animate(_pointsController);
      });

      _pointsController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载数据失败：$e')),
      );
    }
  }

  void _toggleGoal(int index) {
    setState(() {
      _checkedGoals[index] = !_checkedGoals[index];
    });

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
        reason: '完成目标：${goal.title}',
        type: 'earned',
        relatedId: goal.id,
        createdAt: DateTime.now(),
      );

      await PointService.addPoint(point);
      final points = await PointService.getTotalPoints('child1');
      if (!mounted) return;

      final previousPoints = _totalPoints;
      setState(() {
        _totalPoints = points;
        _pointsAnimation = IntTween(
          begin: previousPoints,
          end: points,
        ).animate(_pointsController);
      });
      _pointsController.forward(from: 0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('获得 ${goal.points} 积分！'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('积分添加失败：$e')),
      );
    }
  }

  Future<void> _navigateToAddGoal() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddGoalScreen()),
    );
    if (result == true) {
      await _loadData(showLoader: false);
    }
  }

  void _openGoalList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GoalListScreen()),
    );
  }

  void _openCheckin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckinScreen()),
    );
  }

  void _openWishlist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WishlistScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('星目标'),
        actions: [
          IconButton(
            tooltip: '消息中心',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('暂无新通知')),
              );
            },
          ),
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _loadData(showLoader: false),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _UserGuideCard(
                      onAddGoal: _navigateToAddGoal,
                      onCheckIn: _openCheckin,
                      onViewGoals: _openGoalList,
                      onViewRewards: _openWishlist,
                    ),
                    _StatisticsCard(
                      totalPoints: _totalPoints,
                      pointsAnimation: _pointsAnimation,
                    ),
                    _TodayGoalsSection(
                      goals: _todayGoals,
                      checkedGoals: _checkedGoals,
                      onToggleGoal: _toggleGoal,
                      onManageGoals: _openGoalList,
                    ),
                    _WishlistPreviewCard(
                      rewards: _wishlistPreview,
                      onViewMore: _openWishlist,
                    ),
                    const _GrowthChartPreview(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddGoal,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _UserGuideCard extends StatelessWidget {
  const _UserGuideCard({
    required this.onAddGoal,
    required this.onCheckIn,
    required this.onViewGoals,
    required this.onViewRewards,
  });

  final VoidCallback onAddGoal;
  final VoidCallback onCheckIn;
  final VoidCallback onViewGoals;
  final VoidCallback onViewRewards;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '使用指南',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const _GuideStep(
              icon: Icons.flag,
              text: '制定每日/每周目标，明确孩子需要完成的任务。',
            ),
            const SizedBox(height: 8),
            const _GuideStep(
              icon: Icons.check_circle_outline,
              text: '使用打卡记录孩子完成情况，系统自动累计积分。',
            ),
            const SizedBox(height: 8),
            const _GuideStep(
              icon: Icons.card_giftcard,
              text: '积分可兑换心愿奖励，帮助孩子保持长期动力。',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: onAddGoal,
                  child: const Text('添加目标'),
                ),
                FilledButton.tonal(
                  onPressed: onCheckIn,
                  child: const Text('去打卡'),
                ),
                FilledButton.tonal(
                  onPressed: onViewGoals,
                  child: const Text('管理目标'),
                ),
                FilledButton.tonal(
                  onPressed: onViewRewards,
                  child: const Text('心愿与奖励'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({
    required this.totalPoints,
    this.pointsAnimation,
  });

  final int totalPoints;
  final Animation<int>? pointsAnimation;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const _StatItem(title: '今日积分', value: '20'),
            const _StatItem(title: '本周积分', value: '120'),
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
  const _StatItem({required this.title, required this.value});

  final String title;
  final String value;

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
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}

class _AnimatedStatItem extends StatelessWidget {
  const _AnimatedStatItem({
    required this.title,
    required this.value,
    this.animation,
  });

  final String title;
  final int value;
  final Animation<int>? animation;

  @override
  Widget build(BuildContext context) {
    final textStyle = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );

    return Column(
      children: [
        animation != null
            ? AnimatedBuilder(
                animation: animation!,
                builder: (context, child) => Text(
                  animation!.value.toString(),
                  style: textStyle,
                ),
              )
            : Text(value.toString(), style: textStyle),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}

class _TodayGoalsSection extends StatelessWidget {
  const _TodayGoalsSection({
    required this.goals,
    required this.checkedGoals,
    required this.onToggleGoal,
    required this.onManageGoals,
  });

  final List<Goal> goals;
  final List<bool> checkedGoals;
  final ValueChanged<int> onToggleGoal;
  final VoidCallback onManageGoals;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '今日目标',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: onManageGoals,
                child: const Text('管理目标'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (goals.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('今天还没有待完成的目标，赶紧添加一个吧！'),
              ),
            )
          else
            ...goals.asMap().entries.map(
              (entry) => _GoalItem(
                goal: entry.value,
                isChecked: checkedGoals[entry.key],
                onChanged: () => onToggleGoal(entry.key),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  const _GoalItem({
    required this.goal,
    required this.isChecked,
    required this.onChanged,
  });

  final Goal goal;
  final bool isChecked;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: CheckboxListTile(
        value: isChecked,
        onChanged: (_) => onChanged(),
        title: Text(goal.title),
        subtitle: Text(goal.description),
        secondary: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '+${goal.points} 分',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _WishlistPreviewCard extends StatelessWidget {
  const _WishlistPreviewCard({
    required this.rewards,
    required this.onViewMore,
  });

  final List<Reward> rewards;
  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '心愿库',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: onViewMore,
                  child: const Text('查看更多'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (rewards.isEmpty)
              const Text('暂无心愿，添加一些孩子期待的奖励，更有动力哦！')
            else
              ...rewards.map(
                (reward) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(reward.title),
                  subtitle: Text(reward.description),
                  trailing: Text(
                    '${reward.pointsRequired} 分',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GrowthChartPreview extends StatelessWidget {
  const _GrowthChartPreview();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '成长轨迹',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('数据统计图表即将上线'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
