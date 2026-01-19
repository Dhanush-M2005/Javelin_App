import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/javelin_throw.dart';
import '../providers/throw_selection_provider.dart';
import '../providers/dataset_provider.dart';
import '../widgets/multi_trajectory_chart.dart';

class CompareScreen extends StatefulWidget {
  final List<JavelinThrow>? selectedThrows;

  const CompareScreen({Key? key, this.selectedThrows}) : super(key: key);

  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  final Set<String> _hiddenThrowIds = {};

  void _toggleThrowVisibility(String id) {
    setState(() {
      if (_hiddenThrowIds.contains(id)) {
        _hiddenThrowIds.remove(id);
      } else {
        _hiddenThrowIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine which throws to compare
    final throws = widget.selectedThrows ??
        context
            .watch<ThrowSelectionProvider>()
            .getSelectedThrows(context.read<DatasetProvider>().allThrows);

    if (throws.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No throws selected for comparison',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparing ${throws.length} Throw${throws.length > 1 ? 's' : ''}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 20),
            // Trajectory graph
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
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  MultiTrajectoryChart(
                    throws: throws,
                    hiddenThrowIds: _hiddenThrowIds,
                  ),
                  const SizedBox(height: 16),
                  _buildLegend(throws),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // Metrics table
            const Text(
              'Performance Metrics',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildComparisonTable(throws),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(List<JavelinThrow> throws) {
    List<Color> generateColors(int count) {
      return List.generate(count, (index) {
        final hue = (index * 360.0 / count) % 360.0;
        return HSLColor.fromAHSL(1.0, hue, 0.8, 0.6).toColor();
      });
    }

    final colors = generateColors(throws.length);

    return Column(
      children: throws.asMap().entries.map((entry) {
        final idx = entry.key;
        final th = entry.value;
        final isHidden = _hiddenThrowIds.contains(th.id);
        final color = colors[idx % colors.length];
        final dateStr = th.date.isNotEmpty
            ? DateFormat('dd.MM.yyyy')
                .format(DateFormat('yyyy-MM-dd').parse(th.date))
            : 'Unknown';
            
        return InkWell(
          onTap: () => _toggleThrowVisibility(th.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Checkbox(
                  value: !isHidden,
                  activeColor: color,
                  checkColor: Colors.black,
                  side: BorderSide(color: isHidden ? Colors.grey : color, width: 2),
                  onChanged: (_) => _toggleThrowVisibility(th.id),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Throw ${idx + 1} - $dateStr (${th.distance}m)',
                    style: TextStyle(
                        color: isHidden ? Colors.grey : Colors.white, 
                        fontSize: 14, 
                        fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildComparisonTable(List<JavelinThrow> throws) {
    return Card(
      color: const Color(0xFF1E1E1E),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Table(
          border: TableBorder.all(color: Colors.grey[800]!),
          columnWidths: const {0: FlexColumnWidth(1.2)},
          children: [
            // Header row
            TableRow(
              decoration:
                  BoxDecoration(color: const Color(0xFF0096FF).withValues(alpha: 0.2)),
              children: [
                const TableCell(
                    child: Padding(
                        padding: EdgeInsets.all(8),
                        child: Text('Metric',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))),
                ...List.generate(
                    throws.length,
                    (i) => TableCell(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text('Throw ${i + 1}',
                                style: const TextStyle(
                                    color: Color(0xFF0096FF),
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center),
                          ),
                        ))
              ],
            ),
            // Metric rows
            _buildMetricRow(
                'Distance', throws.map((t) => '${t.distance} m').toList()),
            _buildMetricRow(
                'Release Speed',
                throws
                    .map((t) => '${t.releaseSpeed.toStringAsFixed(1)} m/s')
                    .toList()),
            _buildMetricRow(
                'Release Angle',
                throws
                    .map((t) => '${t.angle.toStringAsFixed(1)}°')
                    .toList()),
            _buildMetricRow(
                'Flight Time',
                throws
                    .map((t) => '${t.flightTime.toStringAsFixed(2)} s')
                    .toList()),
            if (throws.any((t) => t.throwStatistics?.peakHeight != null))
              _buildMetricRow(
                  'Peak Height',
                  throws
                      .map((t) => t.throwStatistics?.peakHeight != null
                          ? '${t.throwStatistics!.peakHeight.toStringAsFixed(1)} m'
                          : '-')
                      .toList()),
          ],
        ),
      ),
    );
  }

  TableRow _buildMetricRow(String metricName, List<String> values) {
    return TableRow(children: [
          TableCell(
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(metricName,
                      style: const TextStyle(color: Colors.white)))),
          ...values.map((v) => TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(v,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center),
                ),
              ))
        ]);
  }
}