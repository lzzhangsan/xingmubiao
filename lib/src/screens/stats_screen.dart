import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:xingmubiao/src/models/checkin.dart';
import 'package:xingmubiao/src/models/goal.dart';
import 'package:xingmubiao/src/services/checkin_service.dart';
import 'package:xingmubiao/src/services/goal_service.dart';
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
  int _timeRange = 7; // 7天数据

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final checkins = await CheckinService.getCheckins();
      final goals = await GoalService.getGoals();

      setState(() {
        _checkins = checkins;
        _goals = goals;
        _isLoading = false;
      });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
        actions: [
          PopupMenuButton<int>(
            onSelected: (int value) {
              setState(() {
                _timeRange = value;
              });
              _loadData();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<int>>[
              const PopupMenuItem<int>(
                value: 7,
                child: Text('近7天'),
              ),
              const PopupMenuItem<int>(
                value: 30,
                child: Text('近30天'),
              ),
              const PopupMenuItem<int>(
                value: 90,
                child: Text('近90天'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
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
                    SizedBox(
                      height: 200,
                      child: CustomLineChart(
                        data: [
                          const FlSpot(0, 10),
                          const FlSpot(1, 20),
                          const FlSpot(2, 30),
                          const FlSpot(3, 40),
                          const FlSpot(4, 50),
                          const FlSpot(5, 60),
                          const FlSpot(6, 70),
                        ],
                        titles: ['周一', '周二', '周三', '周四', '周五', '周六', '周日'],
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '积分统计',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: CustomBarChart(
                        barGroups: [
                          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 20, color: Colors.blue)]),
                          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 35, color: Colors.blue)]),
                          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 30, color: Colors.blue)]),
                          BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 45, color: Colors.blue)]),
                          BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 50, color: Colors.blue)]),
                        ],
                        titles: ['周一', '周二', '周三', '周四', '周五'],
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '目标完成情况',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('已完成目标'),
                                Text('15个'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('总目标数'),
                                Text('20个'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('完成率'),
                                Text('75%'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: 0.75,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      '分类统计',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: CustomPieChart(
                        sections: [
                          PieChartSectionData(
                            value: 40,
                            title: '学习',
                            color: Colors.blue,
                            radius: 50,
                          ),
                          PieChartSectionData(
                            value: 30,
                            title: '生活',
                            color: Colors.green,
                            radius: 50,
                          ),
                          PieChartSectionData(
                            value: 20,
                            title: '兴趣',
                            color: Colors.orange,
                            radius: 50,
                          ),
                          PieChartSectionData(
                            value: 10,
                            title: '挑战',
                            color: Colors.red,
                            radius: 50,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}