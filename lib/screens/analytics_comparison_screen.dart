import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/javelin_throw.dart';
import '../widgets/multi_trajectory_chart.dart';

class AnalyticsComparisonScreen extends StatelessWidget {
  final List<JavelinThrow> throws;

  const AnalyticsComparisonScreen({super.key, required this.throws});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparing ${throws.length} Throws',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            
            // Overlaid Trajectory Comparison Graph
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trajectory Comparison',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  MultiTrajectoryChart(throws: throws),
                  const SizedBox(height: 16),
                  _buildLegend(),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Metrics Comparison Table
            const Text(
              'Metrics Comparison',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildComparisonTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    // Auto-generate colors matching the chart
    List<Color> generateColors(int count) {
      return List.generate(count, (index) {
        final hue = (index * 360.0 / count) % 360.0;
        return HSLColor.fromAHSL(1.0, hue, 0.8, 0.6).toColor();
      });
    }

    final colors = generateColors(throws.length);

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: throws.asMap().entries.map((entry) {
        final index = entry.key;
        final throwItem = entry.value;
        final color = colors[index % colors.length];
        final throwDate = DateFormat('dd.MM.yyyy').format(DateFormat('yyyy-MM-dd').parse(throwItem.date));

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Throw ${index + 1} - $throwDate (${throwItem.distance}m)',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildComparisonTable() {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Table(
          border: TableBorder.all(color: Colors.grey[800]!),
          columnWidths: const {
            0: FlexColumnWidth(2),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: const Color(0xFF0096FF).withValues(alpha: 0.2)),
              children: [
                const TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text('Metric', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                ...List.generate(throws.length, (i) => TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('Throw ${i + 1}', style: const TextStyle(color: Color(0xFF0096FF), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                )),
              ],
            ),
            // Distance Row
            _buildMetricRow('Distance', throws.map((t) => '${t.distance} m').toList()),
            // Speed Row
            _buildMetricRow('Release Speed', throws.map((t) => '${t.releaseSpeed.toStringAsFixed(1)} m/s').toList()),
            // Angle Row
            _buildMetricRow('Release Angle', throws.map((t) => '${t.angle.toStringAsFixed(1)}°').toList()),
            // Flight Time Row
            _buildMetricRow('Flight Time', throws.map((t) => '${t.flightTime.toStringAsFixed(2)} s').toList()),
            // Peak Height Row (if available)
            if (throws.any((t) => t.throwStatistics?.peakHeight != null))
              _buildMetricRow('Peak Height', throws.map((t) => t.throwStatistics?.peakHeight != null ? '${t.throwStatistics!.peakHeight.toStringAsFixed(1)} m' : '-').toList()),
          ],
        ),
      ),
    );
  }

  TableRow _buildMetricRow(String metricName, List<String> values) {
    return TableRow(
      children: [
        TableCell(child: Padding(padding: const EdgeInsets.all(8), child: Text(metricName, style: const TextStyle(color: Colors.white)))),
        ...values.map((value) => TableCell(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(value, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
          ),
        )),
      ],
    );
  }
}
