import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/javelin_throw.dart';
import '../providers/dataset_provider.dart';
import '../widgets/trajectory_chart.dart';

class ProjectileScreen extends StatelessWidget {
  const ProjectileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DatasetProvider>(
      builder: (context, provider, child) {
        // Simple demo: show the first throw available
        final JavelinThrow? selectedThrow = provider.datasets.isNotEmpty && provider.datasets.first.throws.isNotEmpty 
            ? provider.datasets.first.throws.first 
            : null;

        if (selectedThrow == null) {
          return const Center(child: Text('No throws available', style: TextStyle(color: Colors.white)));
        }

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text('3D Trajectory (Top View)', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
                const SizedBox(height: 20),
                Expanded(child: TrajectoryChart(throwItem: selectedThrow)),
              ],
            ),
          ),
        );
      },
    );
  }
}