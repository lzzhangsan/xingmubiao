import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xingmubiao/src/models/checkin.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/providers/app_provider.dart';
import 'package:xingmubiao/src/screens/user_management_screen.dart';
import 'package:xingmubiao/src/services/checkin_service.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
import 'package:xingmubiao/src/widgets/child_selector.dart';
import 'package:xingmubiao/src/widgets/custom_charts.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Checkin> _checkins = [];
  List<Goal> _goals = [];
  bool _isLoading = true;
  bool _isFetching = false;
  int _timeRange = 7;

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
        _checkins = [];
        _goals = [];
      });
      return;
    }

    if (_isFetching) return;
    _isFetching = true;

    if (showLoader) {
      setState(() => _isLoading = true);
    }

    try {
      final allCheckins = await CheckinService.getCheckinsForChild(child.id);
      final goals = await GoalService.getGoalsForChild(child.id);
      final filtered = _filterCheckins(allCheckins, _timeRange);

      if (!mounted) return;
      setState(() {
        _checkins = filtered;
        _goals = goals;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载统计数据失败: $e')),
      );
    } finally {
      _isFetching = false;
    }
  }

  List<Checkin> _filterCheckins(List<Checkin> checkins, int days) {
    if (checkins.isEmpty) return [];
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    return checkins.where((checkin) {
      final created = DateTime(
        checkin.createdAt.year,
        checkin.createdAt.month,
        checkin.createdAt.day,
      );
      return !created.isBefore(start);
    }).toList();
  }

  List<DateTime> _buildRangeDates() {
    final now = DateTime.now();
    final range = _timeRange.clamp(1, 30);
    return List.generate(range, (index) {
      final delta = range - 1 - index;
      return DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: delta));
    });
  }

  List<FlSpot> _buildLineSpots(List<DateTime> dates) {
    double sum = 0;
    return dates.map((date) {
      final count = _checkins
          .where((checkin) => _isSameDay(checkin.createdAt, date))
          .length
          .toDouble();
      sum += count;
      return FlSpot(dates.indexOf(date).toDouble(), sum);
    }).toList();
  }

  List<BarChartGroupData> _buildBarGroups(List<DateTime> dates) {
    return dates.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;
      final count = _checkins
          .where((checkin) => _isSameDay(checkin.createdAt, date))
          .length
          .toDouble();
      return BarChartGroupData(x: index, barRods: [BarChartRodData(toY: count, color: Colors.blue)]);
    }).toList();
  }

  List<PieChartSectionData> _buildPieSections() {
    if (_goals.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: '暂无目标',
          color: Colors.grey[400],
          radius: 50,
        ),
      ];
    }

    final categoryMap = <String, int>{};
    for (final goal in _goals) {
      categoryMap.update(goal.categoryId, (value) => value + 1, ifAbsent: () => 1);
    }
    final colors = <String, Color>{
      'learning': Colors.blue,
      'life': Colors.green,
      'interest': Colors.orange,
      'challenge': Colors.red,
    };

    return categoryMap.entries.map((entry) {
      final color = colors[entry.key] ?? Colors.purple;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: _categoryName(entry.key),
        color: color,
        radius: 50,
      );
    }).toList();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _categoryName(String id) {
    switch (id) {
      case 'learning':
        return '学习';
      case 'life':
        return '生活';
      case 'interest':
        return '兴趣';
      case 'challenge':
        return '挑战';
      default:
        return id;
    }
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
            const Text('还没有孩子成员，无法查看统计'),
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

    final dates = _buildRangeDates();
    final lineSpots = _buildLineSpots(dates);
    final barGroups = _buildBarGroups(dates);
    final dateLabels = dates.map((d) => DateFormat('MM/dd').format(d)).toList();
    final pieSections = _buildPieSections();

    final completedGoals = _checkins.map((c) => c.goalId).toSet().length;
    final totalGoals = _goals.length;
    final completionRate = totalGoals == 0 ? 0 : completedGoals / totalGoals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
        actions: [
          const ChildSelector(),
          PopupMenuButton<int>(
            initialValue: _timeRange,
            onSelected: (value) {
              setState(() => _timeRange = value);
              _loadData();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 7, child: Text('最近 7 天')),
              PopupMenuItem(value: 14, child: Text('最近 14 天')),
              PopupMenuItem(value: 30, child: Text('最近 30 天')),
            ],
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('统计对象：${selectedChild.name}',
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            const Text(
                              '成长轨迹',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: CustomLineChart(
                                data: lineSpots.isEmpty
                                    ? [const FlSpot(0, 0)]
                                    : lineSpots,
                                titles: dateLabels,
                                color: Colors.indigo,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              '打卡次数',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: CustomBarChart(
                                barGroups: barGroups.isEmpty
                                    ? [
                                        BarChartGroupData(
                                          x: 0,
                                          barRods: [BarChartRodData(toY: 0, color: Colors.blue)],
                                        ),
                                      ]
                                    : barGroups,
                                titles: dateLabels,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              '目标完成情况',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _MetricRow(label: '完成目标数', value: '$completedGoals 项'),
                                    const SizedBox(height: 8),
                                    _MetricRow(label: '总目标数', value: '$totalGoals 项'),
                                    const SizedBox(height: 8),
                                    _MetricRow(
                                      label: '完成率',
                                      value: '${(completionRate * 100).toStringAsFixed(0)}%',
                                    ),
                                    const SizedBox(height: 12),
                                    LinearProgressIndicator(
                                      value: completionRate.clamp(0.0, 1.0).toDouble(),
                                      backgroundColor: Colors.grey[300],
                                      valueColor: const AlwaysStoppedAnimation(Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              '分类统计',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: CustomPieChart(sections: pieSections),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
