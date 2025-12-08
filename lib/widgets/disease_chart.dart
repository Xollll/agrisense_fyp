// lib/widgets/disease_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/statistics_service.dart';

/// Pie chart showing disease distribution
class DiseaseFrequencyChart extends StatelessWidget {
  final List<DiseaseStats> diseaseStats;

  const DiseaseFrequencyChart({
    Key? key,
    required this.diseaseStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (diseaseStats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No disease data available',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return PieChart(
      PieChartData(
        sections: diseaseStats
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final stat = entry.value;
              final colors = [
                Colors.red[400]!,
                Colors.orange[400]!,
                Colors.yellow[600]!,
                Colors.green[400]!,
                Colors.blue[400]!,
                Colors.purple[400]!,
                Colors.pink[400]!,
                Colors.teal[400]!,
              ];

              return PieChartSectionData(
                color: colors[index % colors.length],
                value: stat.percentage,
                title: '${stat.percentage.toStringAsFixed(1)}%',
                radius: 80,
                titleStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            })
            .toList(),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
}

/// Timeline chart showing detections over time
class DetectionTimelineChart extends StatelessWidget {
  final List<TimelineData> timelineData;

  const DetectionTimelineChart({
    Key? key,
    required this.timelineData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (timelineData.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No timeline data available',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    // Calculate max Y value for scaling
    final maxCount =
        timelineData.isEmpty ? 1 : timelineData.fold<int>(0, (max, d) => d.count > max ? d.count : max);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: (timelineData.length / 5).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < timelineData.length) {
                  final date = timelineData[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      '${date.month}/${date.day}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: ((maxCount + 1) / 4).ceil().toDouble(),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
              reservedSize: 32,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        minX: 0,
        maxX: (timelineData.length - 1).toDouble(),
        minY: 0,
        maxY: (maxCount + 1).toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: timelineData
                .asMap()
                .entries
                .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
                .toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [Colors.green[400]!, Colors.green[800]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.green[700]!,
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.green[400]!.withAlpha(100),
                  Colors.green[800]!.withAlpha(30),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final index = spot.x.toInt();
                if (index >= 0 && index < timelineData.length) {
                  final date = timelineData[index].date;
                  return LineTooltipItem(
                    '${date.month}/${date.day}: ${spot.y.toInt()} detections',
                    const TextStyle(color: Colors.white),
                  );
                }
                return null;
              }).whereType<LineTooltipItem>().toList();
            },
          ),
        ),
      ),
    );
  }
}

/// Disease ranking table widget
class DiseaseRankingTable extends StatelessWidget {
  final List<DiseaseStats> diseaseStats;

  const DiseaseRankingTable({
    Key? key,
    required this.diseaseStats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (diseaseStats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No disease rankings available',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Rank')),
          DataColumn(label: Text('Disease')),
          DataColumn(label: Text('Count')),
          DataColumn(label: Text('Percentage')),
        ],
        rows: diseaseStats
            .asMap()
            .entries
            .map((entry) {
              final rank = entry.key + 1;
              final stat = entry.value;
              return DataRow(
                cells: [
                  DataCell(Text('$rank')),
                  DataCell(Text(stat.disease)),
                  DataCell(Text('${stat.count}')),
                  DataCell(Text('${stat.percentage.toStringAsFixed(1)}%')),
                ],
              );
            })
            .toList(),
      ),
    );
  }
}

/// Health meter widget
class HealthMeter extends StatelessWidget {
  final double healthyPercentage;

  const HealthMeter({
    Key? key,
    required this.healthyPercentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine color based on health percentage
    final color = healthyPercentage >= 70
        ? Colors.green
        : healthyPercentage >= 40
            ? Colors.orange
            : Colors.red;

    return Column(
      children: [
        Text(
          'Field Health Status',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: CircularProgressIndicator(
                value: healthyPercentage / 100,
                strokeWidth: 12,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${healthyPercentage.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Healthy',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          healthyPercentage >= 70
              ? '✅ Field is in excellent condition'
              : healthyPercentage >= 40
                  ? '⚠️ Field requires attention'
                  : '❌ Field needs immediate care',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
