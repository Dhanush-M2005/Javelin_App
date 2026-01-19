import 'package:flutter/material.dart';
import '../models/javelin_throw.dart';
import '../widgets/trajectory_chart.dart';

class GraphScreen extends StatelessWidget {
  final JavelinThrow throwItem;

  const GraphScreen({super.key, required this.throwItem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Throw Analysis'),
        backgroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distance vs Height',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: TrajectoryChart(throwItem: throwItem),
            ),
            const SizedBox(height: 24),
            Text(
              'Metrics',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildMetricsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildMetricCard(context, 'Distance', '${throwItem.distance} m', Icons.straighten),
        _buildMetricCard(context, 'Release Speed', '${throwItem.releaseSpeed.toStringAsFixed(1)} m/s', Icons.speed),
        _buildMetricCard(context, 'Release Angle', '${throwItem.angle.toStringAsFixed(1)}°', Icons.rotate_right),
        _buildMetricCard(context, 'Flight Time', '${throwItem.flightTime.toStringAsFixed(2)} s', Icons.timer),
        if (throwItem.throwStatistics != null) ...[
           _buildMetricCard(context, 'Peak Height', '${throwItem.throwStatistics!.peakHeight.toStringAsFixed(1)} m', Icons.height),
           _buildMetricCard(context, 'Release Height', '${throwItem.throwStatistics!.releaseHeight.toStringAsFixed(1)} m', Icons.upload),
        ]
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF0096FF)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}
