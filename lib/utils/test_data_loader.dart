import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/dataset.dart';
import '../services/file_service.dart';
import '../services/trajectory_analyzer.dart';
import '../utils/csv_parser.dart';
import 'package:uuid/uuid.dart';

/// Utility class to load test CSV data from assets into the app
class TestDataLoader {
  final FileService _fileService;
  final TrajectoryAnalyzer _analyzer;

  TestDataLoader(this._fileService, this._analyzer);

  /// List of test CSV files bundled in assets
  static const List<String> testFiles = [
    // Original test files
    'sensor_data_20250922_173511S.csv',
    'sensor_data_20250922_173631R.csv',
    'sensor_data_20250918_220224.csv',
    'sensor_data_20250918_161859.csv',
    'sensor_data_20250917_172244 L.csv',
    // New varied distance files (35m - 62m)
    'sensor_data_beginner_35m.csv',     // Beginner level
    'sensor_data_average_42m.csv',      // Average performance
    'sensor_data_good_48m.csv',         // Good technique
    'sensor_data_excellent_52m.csv',    // Excellent throw
    'sensor_data_verygood_55m.csv',     // Very good
    'sensor_data_excellent_58m.csv',    // Excellent
    'sensor_data_pro_62m.csv',          // Professional level
  ];

  /// Load all test CSV files from assets to the app's CSV directory
  /// This makes them appear in the app as if they were downloaded via WiFi
  Future<List<Dataset>> loadTestData() async {
    final List<Dataset> loadedDatasets = [];
    
    for (final filename in testFiles) {
      try {
        debugPrint('Loading test file: $filename');
        final dataset = await _loadSingleTestFile(filename);
        loadedDatasets.add(dataset);
        debugPrint('Successfully loaded: $filename');
      } catch (e) {
        debugPrint('Failed to load $filename: $e');
      }
    }
    
    debugPrint('Loaded ${loadedDatasets.length} test datasets');
    return loadedDatasets;
  }

  /// Load a single test CSV file from assets
  Future<Dataset> _loadSingleTestFile(String filename) async {
    // Read CSV content from assets
    final csvContent = await rootBundle.loadString('assets/test_data/$filename');
    
    // Parse the CSV data
    final samples = CsvParser.parseSensorData(csvContent);
    
    // Generate a unique ID for this dataset
    final id = const Uuid().v4();
    final now = DateTime.now();
    
    // Save the CSV file to the app's CSV directory (same as WiFi downloads)
    await _fileService.saveCsv('$id.csv', csvContent);
    
    // Analyze the data to detect throws
    final throws = _analyzer.detectThrows(samples, id);
    
    // Determine status
    DatasetStatus status = DatasetStatus.downloaded;
    if (throws.isEmpty) {
      status = DatasetStatus.noThrows;
    }
    
    // Create a dataset object
    return Dataset(
      id: id,
      deviceSsid: 'Test Data',
      filename: '$id.csv',
      downloadedAt: now,
      status: status,
      throws: throws,
    );
  }

  /// Check if test data has already been loaded
  Future<bool> hasTestData() async {
    final directory = await getApplicationDocumentsDirectory();
    final csvDir = Directory(path.join(directory.path, 'javelin_csvs'));
    
    if (!await csvDir.exists()) {
      return false;
    }
    
    // Check if any CSV files exist
    final files = await csvDir.list().toList();
    return files.any((file) => file.path.endsWith('.csv'));
  }
}
