import 'package:csv/csv.dart';
import '../models/sensor_sample.dart';

class CsvParser {
  static const List<String> requiredColumns = [
    'Timestamp_ms',
    'AccX_Filt', 'AccY_Filt', 'AccZ_Filt',
    'GyrX_Filt', 'GyrY_Filt', 'GyrZ_Filt',
    'MagX_Filt', 'MagY_Filt', 'MagZ_Filt'
  ];

  static List<SensorSample> parseSensorData(String csvString) {
    final List<List<dynamic>> rows = const CsvToListConverter(eol: '\n').convert(csvString);

    if (rows.isEmpty) {
      throw Exception('Empty CSV file');
    }

    final headerRow = rows[0].map((e) => e.toString().trim()).toList();
    final columnIndices = <String, int>{};

    // Map required columns to their indices
    for (final col in requiredColumns) {
      final index = headerRow.indexOf(col);
      if (index == -1) {
        throw Exception('Missing required column: $col');
      }
      columnIndices[col] = index;
    }

    final List<SensorSample> samples = [];

    // Parse data rows
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      // Skip empty rows or rows that are too short for the mapped indices
      // We check if the row has enough columns to cover the max index we found
      // But simpler is to try to access and catch range error, or check length vs max index.
      // However, CSV parser might return different lengths.
      
      try {
        // Helper to safely get double
        double getDouble(String colName) {
          final idx = columnIndices[colName]!;
          if (idx >= row.length) throw Exception('Row too short');
          final val = row[idx];
          if (val is num) return val.toDouble();
          return double.tryParse(val.toString()) ?? 0.0;
        }

        // Helper to safely get int
        int getInt(String colName) {
           final idx = columnIndices[colName]!;
           if (idx >= row.length) throw Exception('Row too short');
           final val = row[idx];
           if (val is num) return val.toInt();
           return int.tryParse(val.toString()) ?? 0;
        }

        samples.add(SensorSample(
          timestampMs: getInt('Timestamp_ms'),
          accXFilt: getDouble('AccX_Filt'),
          accYFilt: getDouble('AccY_Filt'),
          accZFilt: getDouble('AccZ_Filt'),
          gyrXFilt: getDouble('GyrX_Filt'),
          gyrYFilt: getDouble('GyrY_Filt'),
          gyrZFilt: getDouble('GyrZ_Filt'),
          magXFilt: getDouble('MagX_Filt'),
          magYFilt: getDouble('MagY_Filt'),
          magZFilt: getDouble('MagZ_Filt'),
        ));
      } catch (e) {
        // Skip malformed rows
        continue;
      }
    }

    return samples;
  }
}