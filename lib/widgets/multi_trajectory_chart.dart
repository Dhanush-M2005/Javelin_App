import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/javelin_throw.dart';

class MultiTrajectoryChart extends StatelessWidget {
  final List<JavelinThrow> throws;
  final Set<String> hiddenThrowIds;

  const MultiTrajectoryChart({
    super.key, 
    required this.throws,
    this.hiddenThrowIds = const {},
  });

  @override
  Widget build(BuildContext context) {
    if (throws.isEmpty) {
      return const Center(
        child: Text(
          'No throw data available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Automatically generate distinct colors for each throw
    List<Color> generateColors(int count) {
      return List.generate(count, (index) {
        // Use HSL color space to generate evenly distributed vibrant colors
        final hue = (index * 360.0 / count) % 360.0;
        return HSLColor.fromAHSL(1.0, hue, 0.8, 0.6).toColor();
      });
    }

    final colors = generateColors(throws.length);

    // Calculate global min/max for consistent axis
    double maxX = 0;
    double maxY = 0;

    final List<LineChartBarData> lineBarsData = [];

    for (var i = 0; i < throws.length; i++) {
      final throwItem = throws[i];
      
      // Skip if hidden
      if (hiddenThrowIds.contains(throwItem.id)) continue;
      
      // Data is now guaranteed clean by TrajectoryAnalyzer
      if (throwItem.trajectoryPoints == null || throwItem.trajectoryPoints!.isEmpty) continue;

      final points = throwItem.trajectoryPoints!;
      final spots = points.map((p) => FlSpot(p.x, p.z)).toList();
      
      // Update max values
      final throwMaxX = throwItem.distance;
      final throwMaxY = points.map((p) => p.z).reduce(max);
      
      if (throwMaxX > maxX) maxX = throwMaxX;
      if (throwMaxY > maxY) maxY = throwMaxY;

      // Create line for this throw
      lineBarsData.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: colors[i % colors.length],
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.5,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[800], strokeWidth: 1),
            getDrawingVerticalLine: (value) => FlLine(color: Colors.grey[800], strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
                interval: (maxX > 0 ? maxX / 5 : 1.0),
              ),
              axisNameWidget: const Text('Distance (m)', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(1), // Show decimal for small values
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
                interval: (maxY > 0 ? maxY / 5 : 1.0),
              ),
              axisNameWidget: const Text('Height (m)', style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[800]!),
          ),
          minX: 0,
          maxX: (maxX * 1.1),
          minY: 0,
          maxY: (maxY * 1.2),
          lineBarsData: lineBarsData,
        ),
      ),
    );
  }
}
