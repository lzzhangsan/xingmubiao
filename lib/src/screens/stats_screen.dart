import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('统计分析'),
      ),
      body: SingleChildScrollView(
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
                child: LineChart(
                  _sampleData(),
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
                child: BarChart(
                  _barData(),
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
            ],
          ),
        ),
      ),
    );
  }

  LineChartData _sampleData() {
    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: [
            const FlSpot(0, 10),
            const FlSpot(1, 20),
            const FlSpot(2, 30),
            const FlSpot(3, 40),
            const FlSpot(4, 50),
            const FlSpot(5, 60),
            const FlSpot(6, 70),
          ],
          isCurved: true,
          color: Colors.blue,
          barWidth: 4,
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.3),
          ),
        ),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              const weeks = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
              return Text(weeks[value.toInt()]);
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true),
    );
  }

  BarChartData _barData() {
    return BarChartData(
      barGroups: [
        BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 20, color: Colors.blue)]),
        BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 35, color: Colors.blue)]),
        BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 30, color: Colors.blue)]),
        BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 45, color: Colors.blue)]),
        BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 50, color: Colors.blue)]),
      ],
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              const weeks = ['周一', '周二', '周三', '周四', '周五'];
              return Text(weeks[value.toInt()]);
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      gridData: FlGridData(show: true),
      borderData: FlBorderData(show: true),
    );
  }
}