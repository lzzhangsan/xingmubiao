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
import 'package:xingmubiao/src/widgets/cool_background.dart';
import 'dart:math' as math;
import 'dart:ui';

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
  List<_WeeklyPointSummary> _weeklySummaries = const [];
  _WeeklyPointSummary? _weeklyMaxHistory;
  _WeeklyPointSummary? _weeklyMinHistory;

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
      _provider?.addListener(_handleProviderChanged);
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

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = _normalizeDate(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  List<_WeeklyPointSummary> _buildWeeklySummaries(List<Point> records, {int weeks = 55}) {
    final weeklyTotals = <DateTime, int>{};
    for (final record in records) {
      if (record.type != 'earned') continue;
      final recordDate = _normalizeDate(record.createdAt);
      final weekStart = _startOfWeek(recordDate);
      weeklyTotals[weekStart] = (weeklyTotals[weekStart] ?? 0) + record.amount;
    }

    final currentWeekStart = _startOfWeek(_normalizeDate(DateTime.now()));
    return List<_WeeklyPointSummary>.generate(weeks, (index) {
      final weekStart = currentWeekStart.subtract(Duration(days: 7 * index));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final total = weeklyTotals[weekStart] ?? 0;
      return _WeeklyPointSummary(
        weekStart: weekStart,
        weekEnd: weekEnd,
        total: total,
      );
    });
  }

  _WeeklyPointSummary? _findWeeklyExtreme(
    List<_WeeklyPointSummary> summaries, {
    required bool max,
  }) {
    if (summaries.length <= 1) return null;
    final history = summaries.skip(1).toList();
    if (history.isEmpty) return null;
    _WeeklyPointSummary result = history.first;
    for (final item in history.skip(1)) {
      if (max) {
        if (item.total > result.total) {
          result = item;
        }
      } else {
        if (item.total < result.total) {
          result = item;
        }
      }
    }
    return result;
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatWeekRange(_WeeklyPointSummary summary) {
    return '${_formatDate(summary.weekStart)} ~ ${_formatDate(summary.weekEnd)}';
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
        _weeklySummaries = const [];
        _weeklyMaxHistory = null;
        _weeklyMinHistory = null;
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
      final weeklySummaries = _buildWeeklySummaries(pointRecords);
      final weeklyMaxHistory = _findWeeklyExtreme(weeklySummaries, max: true);
      final weeklyMinHistory = _findWeeklyExtreme(weeklySummaries, max: false);

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
        _weeklySummaries = weeklySummaries;
        _weeklyMaxHistory = weeklyMaxHistory;
        _weeklyMinHistory = weeklyMinHistory;
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

  void _showWeeklyPointsDetails() {
    if (_weeklySummaries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无周积分记录')),
      );
      return;
    }

    final highest = _weeklyMaxHistory;
    final lowest = _weeklyMinHistory;
    final summaries = _weeklySummaries;
    final hasHistory = highest != null || lowest != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '周积分详情',
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      IconButton(
                        tooltip: '关闭',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (hasHistory) ...[
                    if (highest != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.trending_up, color: Colors.green),
                        title: const Text('历史最高'),
                        subtitle: Text(_formatWeekRange(highest)),
                        trailing: Text(
                          '${highest.total} 分',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    if (lowest != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.trending_down, color: Colors.redAccent),
                        title: const Text('历史最低'),
                        subtitle: Text(_formatWeekRange(lowest)),
                        trailing: Text(
                          '${lowest.total} 分',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                  ] else
                    const ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('暂无历史周积分记录'),
                    ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.separated(
                      itemCount: summaries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final summary = summaries[index];
                        final isCurrentWeek = index == 0;
                        final isHighest =
                            highest != null && summary.weekStart == highest.weekStart;
                        final isLowest =
                            lowest != null && summary.weekStart == lowest.weekStart;
                        final baseColor = theme.textTheme.bodyLarge?.color;
                        final trailingStyle = TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isHighest
                              ? Colors.green
                              : isLowest
                                  ? Colors.redAccent
                                  : baseColor,
                        );
                        return ListTile(
                          dense: true,
                          leading: Text(
                            (index + 1).toString().padLeft(2, '0'),
                            style: theme.textTheme.bodySmall,
                          ),
                          title: Text(_formatWeekRange(summary)),
                          subtitle: isCurrentWeek
                              ? const Text('本周')
                              : isHighest
                                  ? const Text('历史最高')
                                  : isLowest
                                      ? const Text('历史最低')
                                      : null,
                          trailing: Text('${summary.total} 分', style: trailingStyle),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      appBar: provider.themeStyle == ThemeStyle.cool
          ? GradientAppBar(
              title: const Text('每日目标'),
              actions: [
                const ChildSelector(),
                IconButton(
                  tooltip: '设置',
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.pushNamed(context, '/settings'),
                ),
              ],
            )
          : AppBar(
              title: const Text('每日目标'),
              actions: [
                const ChildSelector(),
                // 通知按钮已移除（无实际功能），保留设置按钮
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
                      child: provider.themeStyle == ThemeStyle.cool
                          ? AnimatedCoolBackground(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _StatisticsCard(
                                      todayPoints: _todayPoints,
                                      weekPoints: _weekPoints,
                                      totalPoints: _totalPoints,
                                      onWeekTap: _showWeeklyPointsDetails,
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
                            )
                          : SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _StatisticsCard(
                                    todayPoints: _todayPoints,
                                    weekPoints: _weekPoints,
                                    totalPoints: _totalPoints,
                                    onWeekTap: _showWeeklyPointsDetails,
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
    this.onWeekTap,
  });

  final int todayPoints;
  final int weekPoints;
  final int totalPoints;
  final Animation<int>? animation;
  final VoidCallback? onWeekTap;

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
            _StatItem(
              title: '本周积分',
              value: weekPoints.toString(),
              onTap: onWeekTap,
            ),
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
  const _StatItem({required this.title, required this.value, this.onTap});

  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
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

    final paddedContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: content,
    );

    if (onTap == null) {
      return paddedContent;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: paddedContent,
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

class _WeeklyPointSummary {
  _WeeklyPointSummary({
    required this.weekStart,
    required this.weekEnd,
    required this.total,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int total;
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

// Use shared GradientAppBar and AnimatedCoolBackground from widgets/cool_background.dart
