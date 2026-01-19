import 'package:flutter/material.dart';
import '../models/dataset.dart';
import '../models/javelin_throw.dart';

class DatasetCard extends StatelessWidget {
  final Dataset dataset;
  final Function(JavelinThrow) onThrowTap;
  final VoidCallback onDelete;

  const DatasetCard({
    super.key,
    required this.dataset,
    required this.onThrowTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          dataset.filename,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${dataset.deviceSsid} • ${dataset.downloadedAt.toString().split('.')[0]}',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
        trailing: _buildStatusIcon(dataset.status),
        children: [
          if (dataset.status == DatasetStatus.downloaded)
            ...dataset.throws.map((t) => ListTile(
              title: Text('Throw ${t.id.split('_').last}', style: const TextStyle(color: Colors.white)),
              subtitle: Text('${t.distance} m', style: const TextStyle(color: Color(0xFF0096FF))),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => onThrowTap(t),
            )).toList()
          else if (dataset.status == DatasetStatus.skipped)
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Text('Skipped: ${dataset.skipReason}', style: const TextStyle(color: Colors.red)),
             )
          else if (dataset.status == DatasetStatus.noThrows)
             const Padding(
               padding: EdgeInsets.all(16.0),
               child: Text('No throws detected.', style: TextStyle(color: Colors.orange)),
             ),
          
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Delete Dataset', style: TextStyle(color: Colors.red)),
                  onPressed: onDelete,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusIcon(DatasetStatus status) {
    switch (status) {
      case DatasetStatus.downloaded:
        return const Icon(Icons.check_circle, color: Colors.green);
      case DatasetStatus.skipped:
        return const Icon(Icons.warning, color: Colors.orange);
      case DatasetStatus.error:
        return const Icon(Icons.error, color: Colors.red);
      case DatasetStatus.noThrows:
        return const Icon(Icons.do_not_disturb, color: Colors.grey);
    }
  }
}
