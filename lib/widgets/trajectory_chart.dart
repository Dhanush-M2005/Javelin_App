import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/javelin_throw.dart';

class TrajectoryChart extends StatelessWidget {
  final JavelinThrow throwItem;

  const TrajectoryChart({super.key, required this.throwItem});

  @override
  Widget build(BuildContext context) {
    if (throwItem.trajectoryPoints == null || throwItem.trajectoryPoints!.isEmpty) {
      return const Center(child: Text('No trajectory data available', style: TextStyle(color: Colors.white)));
    }

    // Use stored points (now guaranteed to be clean/parabolic by analyzer)
    final points = throwItem.trajectoryPoints!;
    final maxX = throwItem.distance > 0 ? throwItem.distance : 10.0;
    // Calculate maxY from points
    final maxY = points.map((p) => p.z).reduce(max);
    
    final spots = points.map((p) => FlSpot(p.x, p.z)).toList();
    
    // Safety for axis
    final displayMaxY = maxY > 0 ? maxY : 5.0;

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
                getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                interval: (maxX > 0 ? maxX / 5 : 1.0),
              ),
              axisNameWidget: const Text('Distance (m)', style: TextStyle(color: Colors.white)),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: const TextStyle(color: Colors.grey, fontSize: 10)),
                interval: (displayMaxY > 0 ? displayMaxY / 5 : 1.0),
              ),
              axisNameWidget: const Text('Height (m)', style: TextStyle(color: Colors.white)),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey[800]!)),
          minX: 0,
          maxX: (maxX * 1.1),
          minY: 0,
          maxY: (maxY * 1.2),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: const Color(0xFF0096FF),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF0096FF).withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}