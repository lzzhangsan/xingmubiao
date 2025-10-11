import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/models/point.dart';
import 'package:xingmubiao/src/models/reward.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/screens/add_goal_screen.dart';
import 'package:xingmubiao/src/screens/goal_list_screen.dart';
import 'package:xingmubiao/src/screens/user_management_screen.dart';
import 'package:xingmubiao/src/screens/wishlist_screen.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/services/point_service.dart';
import 'package:xingmubiao/src/services/checkin_service.dart';
import 'package:xingmubiao/src/services/reward_service.dart';
import 'package:xingmubiao/src/widgets/child_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  bool _isFetching = false;
  int _totalPoints = 0;
  int _todayPoints = 0;
  int _weekPoints = 0;
  List<Goal> _todayGoals = [];
  List<bool> _checkedGoals = [];
  List<Reward> _wishlistPreview = [];

  late final AnimationController _pointsController;
  Animation<int>? _pointsAnimation;
  AppProvider? _provider;
  String? _currentChildId;

  @override
  void initState() {
    super.initState();
    _pointsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

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
    _pointsController.dispose();
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

  int _calculateTodayPoints(List<Point> records) {
    // 计算今天的积分
    final earnedRecords = records.where((record) => record.type == 'earned').toList();
    
    if (earnedRecords.isEmpty) return 0;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    int total = 0;
    for (final record in earnedRecords) {
      final created = DateTime(record.createdAt.year, record.createdAt.month,
          record.createdAt.day);
      if (created.compareTo(todayStart) >= 0 && created.compareTo(todayEnd) < 0) {
        total += record.amount;
      }
    }
    return total;
  }

  int _calculateWeekPoints(List<Point> records) {
    // 计算本周的积分（周一到今天）
    final earnedRecords = records.where((record) => record.type == 'earned').toList();
    
    if (earnedRecords.isEmpty) return 0;
    final now = DateTime.now();
    
    // 计算本周一的日期
    final today = DateTime(now.year, now.month, now.day);
    final weekday = today.weekday; // 周一为1，周日为7
    final weekStart = today.subtract(Duration(days: weekday - 1)); // 本周一
    
    int total = 0;
    for (final record in earnedRecords) {
      final created = DateTime(record.createdAt.year, record.createdAt.month,
          record.createdAt.day);
      // 在本周一到今天之间（包含今天）
      if (created.compareTo(weekStart) >= 0 && created.compareTo(today) <= 0) {
        total += record.amount;
      }
    }
    return total;
  }

  Future<void> _loadData({bool showLoader = true}) async {
    final provider = _provider;
    if (provider == null || !provider.isInitialized) return;
    final child = provider.selectedChild;
    if (child == null) {
      setState(() {
        _isLoading = false;
        _totalPoints = 0;
        _todayPoints = 0;
        _weekPoints = 0;
        _todayGoals = [];
        _checkedGoals = [];
        _wishlistPreview = [];
        _pointsAnimation = null;
      });
      return;
    }

    if (_isFetching) return;
    _isFetching = true;

    if (showLoader) {
      setState(() => _isLoading = true);
    }

    try {
      final previousPoints = _totalPoints;
      final totalPointsFuture = PointService.getTotalPoints(child.id);
      final pointRecordsFuture = PointService.getPointsByUser(child.id);
      final goalsFuture = GoalService.getGoalsForChild(child.id);
      final rewardsFuture = RewardService.getRewards();

      final totalPoints = await totalPointsFuture;
      final pointRecords = await pointRecordsFuture;
      final goals = await goalsFuture;
      final rewards = await rewardsFuture;

      final todayPoints = _calculateTodayPoints(pointRecords);
      final weekPoints = _calculateWeekPoints(pointRecords);

      // 根据“今日是否已获得该目标对应的积分”来勾选，确保不会重复加分
      final now = DateTime.now();
      final earnedTodayGoalIds = pointRecords
          .where((p) =>
              p.type == 'earned' &&
              p.createdAt.year == now.year &&
              p.createdAt.month == now.month &&
              p.createdAt.day == now.day)
          .map((p) => p.relatedId)
          .whereType<String>()
          .toSet();

      if (!mounted) return;
      setState(() {
        _totalPoints = totalPoints;
        _todayPoints = todayPoints;
        _weekPoints = weekPoints;
        _todayGoals = goals;
        _checkedGoals = goals
            .map((g) => earnedTodayGoalIds.contains(g.id))
            .toList(growable: false);
        _wishlistPreview = rewards.take(3).toList();
        _isLoading = false;
        _pointsAnimation = IntTween(
          begin: previousPoints,
          end: totalPoints,
        ).animate(_pointsController);
      });
      _pointsController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载首页数据失败: $e')),
      );
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _addPointsForGoal(Goal goal) async {
    final child = _provider?.selectedChild;
    if (child == null) return;

    try {
      final point = Point(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: child.id,
        amount: goal.points,
        reason: '完成目标: ${goal.title}',
        type: 'earned',
        relatedId: goal.id,
        createdAt: DateTime.now(),
      );

      await PointService.addPoint(point);
      await _loadData(showLoader: false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获得 ${goal.points} 积分')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('积分记录失败: $e')),
      );
    }
  }

  Future<void> _openAddGoal() async {
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


  void _openWishlist() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WishlistScreen()),
    );
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
            const Text('还没有孩子成员，请先添加孩子再开始使用'),
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
        title: const Text('每日目标'),
        actions: [
          const ChildSelector(),
          IconButton(
            tooltip: '消息提醒',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('暂时没有新通知')),
              );
            },
          ),
          IconButton(
            tooltip: '设置',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
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
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _StatisticsCard(
                              todayPoints: _todayPoints,
                              weekPoints: _weekPoints,
                              totalPoints: _totalPoints,
                              animation: _pointsAnimation,
                            ),
                            // 快捷操作入口已由底部导航替代，移除冗余按钮
                            _TodayGoalsSection(
                              goals: _todayGoals,
                              checkedGoals: _checkedGoals,
                              onManageGoal: _openGoalList,
                            ),
                            _WishlistPreview(
                              rewards: _wishlistPreview,
                              onViewMore: _openWishlist,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
      // Floating action button for adding a goal removed —
      // goal creation moved to the GoalList/管理目标 page.
    );
  }
}

class _StatisticsCard extends StatelessWidget {
  const _StatisticsCard({
    required this.todayPoints,
    required this.weekPoints,
    required this.totalPoints,
    this.animation,
  });

  final int todayPoints;
  final int weekPoints;
  final int totalPoints;
  final Animation<int>? animation;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(title: '今日积分', value: todayPoints.toString()),
            _StatItem(title: '本周积分', value: weekPoints.toString()),
            _AnimatedStatItem(
              title: '总积分',
              value: totalPoints,
              animation: animation,
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
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
    final style = const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
    return Column(
      children: [
        animation == null
            ? Text(value.toString(), style: style)
            : AnimatedBuilder(
                animation: animation!,
                builder: (context, child) => Text(
                  animation!.value.toString(),
                  style: style,
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

// _QuickActions 已移除

class _TodayGoalsSection extends StatelessWidget {
  const _TodayGoalsSection({
    required this.goals,
    required this.checkedGoals,
    required this.onManageGoal,
  });

  final List<Goal> goals;
  final List<bool> checkedGoals;
  final VoidCallback onManageGoal;

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
              TextButton(onPressed: onManageGoal, child: const Text('管理目标')),
            ],
          ),
          const SizedBox(height: 8),
          if (goals.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('今天还没有待完成的目标'),
                    SizedBox(height: 4),
                    Text('试着添加一个新的任务，让孩子开启有序的一天。',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ...goals.asMap().entries.map(
              (entry) => _GoalItem(
                goal: entry.value,
                isChecked: checkedGoals[entry.key],
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  final Goal goal;
  final bool isChecked;
  const _GoalItem({
    required this.goal,
    required this.isChecked,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = isChecked ? theme.colorScheme.onSurface : Colors.grey;
    final subtitleColor = isChecked ? theme.colorScheme.onSurface.withOpacity(0.8) : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isChecked ? theme.colorScheme.primary : Colors.transparent,
            border: Border.all(color: isChecked ? theme.colorScheme.primary : Colors.grey),
            borderRadius: BorderRadius.circular(6),
          ),
          child: isChecked
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : const SizedBox.shrink(),
        ),
        title: Text(
          goal.title,
          style: TextStyle(color: titleColor),
        ),
        subtitle: goal.description.isNotEmpty
            ? Text(
                goal.description,
                style: TextStyle(color: subtitleColor),
              )
            : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '+${goal.points}分',
            style: TextStyle(
              color: isChecked ? theme.colorScheme.primary : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _WishlistPreview extends StatelessWidget {
  const _WishlistPreview({
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
                  '心愿预览',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(onPressed: onViewMore, child: const Text('查看全部')),
              ],
            ),
            const SizedBox(height: 8),
            if (rewards.isEmpty)
              const Text('还没有心愿奖励，快去添加一个激励孩子吧。')
            else
              ...rewards.map(
                (reward) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(reward.title),
                  subtitle: Text(reward.description),
                  trailing: Text(
                    '${reward.pointsRequired >= 0 ? '+' : ''}${reward.pointsRequired}分',
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

// Growth preview removed per request.
