import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import '../models/sensor_sample.dart';

class SensorDataParser {
  /// Parses CSV data into a list of SensorSample objects
  static List<SensorSample> parseSensorData(String csvString) {
    final List<SensorSample> sensorData = [];
    
    try {
      final csvTable = const CsvToListConverter().convert(csvString, eol: '\n');
      
      // Find header indices
      final headerRow = csvTable[0];
      final timestampIndex = _findColumnIndex(headerRow, ['timestamp', 'time']);
      final accXIndex = _findColumnIndex(headerRow, ['accx', 'acc_x', 'ax']);
      final accYIndex = _findColumnIndex(headerRow, ['accy', 'acc_y', 'ay']);
      final accZIndex = _findColumnIndex(headerRow, ['accz', 'acc_z', 'az']);
      final gyrXIndex = _findColumnIndex(headerRow, ['gyrx', 'gyr_x', 'gx']);
      final gyrYIndex = _findColumnIndex(headerRow, ['gyry', 'gyr_y', 'gy']);
      final gyrZIndex = _findColumnIndex(headerRow, ['gyrz', 'gyr_z', 'gz']);
      final magXIndex = _findColumnIndex(headerRow, ['magx', 'mag_x', 'mx']);
      final magYIndex = _findColumnIndex(headerRow, ['magy', 'mag_y', 'my']);
      final magZIndex = _findColumnIndex(headerRow, ['magz', 'mag_z', 'mz']);
      
      // Process data rows (skip header)
      for (int i = 1; i < csvTable.length; i++) {
        try {
          final row = csvTable[i];
          
          sensorData.add(SensorSample(
            timestampMs: _parseInt(row[timestampIndex]),
            accXFilt: _parseDouble(row[accXIndex]),
            accYFilt: _parseDouble(row[accYIndex]),
            accZFilt: _parseDouble(row[accZIndex]),
            gyrXFilt: _parseDouble(row[gyrXIndex]),
            gyrYFilt: _parseDouble(row[gyrYIndex]),
            gyrZFilt: _parseDouble(row[gyrZIndex]),
            magXFilt: magXIndex != -1 ? _parseDouble(row[magXIndex]) : 0.0,
            magYFilt: magYIndex != -1 ? _parseDouble(row[magYIndex]) : 0.0,
            magZFilt: magZIndex != -1 ? _parseDouble(row[magZIndex]) : 0.0,
          ));
        } catch (e) {
          debugPrint('Error parsing row $i: $e');
          continue;
        }
      }
    } catch (e) {
      debugPrint('Error parsing CSV: $e');
    }
    
    return sensorData;
  }
  
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
  
  static int _findColumnIndex(List<dynamic> headers, List<String> possibleNames) {
    final lowerHeaders = headers.map((h) => h.toString().toLowerCase()).toList();
    for (final name in possibleNames) {
      final index = lowerHeaders.indexOf(name.toLowerCase());
      if (index != -1) return index;
    }
    return -1; // Not found
  }
}
