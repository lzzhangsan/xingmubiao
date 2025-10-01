import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CustomLineChart extends StatelessWidget {
  final List<FlSpot> data;
  final List<String> titles;
  final Color color;

  const CustomLineChart({
    super.key,
    required this.data,
    required this.titles,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: data,
            isCurved: true,
            color: color,
            barWidth: 4,
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.3),
            ),
            dotData: FlDotData(show: true),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < titles.length) {
                  return Text(titles[value.toInt()]);
                }
                return const Text('');
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
      ),
    );
  }
}

class CustomBarChart extends StatelessWidget {
  final List<BarChartGroupData> barGroups;
  final List<String> titles;
  final Color color;

  const CustomBarChart({
    super.key,
    required this.barGroups,
    required this.titles,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < titles.length) {
                  return Text(titles[value.toInt()]);
                }
                return const Text('');
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
      ),
    );
  }
}

class CustomPieChart extends StatelessWidget {
  final List<PieChartSectionData> sections;

  const CustomPieChart({
    super.key,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
}