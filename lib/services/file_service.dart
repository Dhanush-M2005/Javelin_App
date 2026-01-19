import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/dataset.dart';

class FileService {
  static const String _csvDirName = 'javelin_csvs';
  static const String _indexFileName = 'index.json';

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(path.join(directory.path, _csvDirName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  Future<List<Dataset>> loadIndex() async {
    try {
      final p = await _localPath;
      final file = File(path.join(p, _indexFileName));
      if (!await file.exists()) return [];
      
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((e) => Dataset.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading index: $e');
      return [];
    }
  }

  Future<void> saveIndex(List<Dataset> datasets) async {
    final p = await _localPath;
    final file = File(path.join(p, _indexFileName));
    final jsonList = datasets.map((e) => e.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }

  Future<File> saveCsv(String filename, String content) async {
    final p = await _localPath;
    final tempFile = File(path.join(p, '$filename.tmp'));
    await tempFile.writeAsString(content);
    
    final finalFile = File(path.join(p, filename));
    if (await finalFile.exists()) {
      await finalFile.delete();
    }
    return await tempFile.rename(finalFile.path);
  }

  Future<void> deleteDataset(Dataset dataset) async {
    final p = await _localPath;
    final csvFile = File(path.join(p, dataset.filename));
    if (await csvFile.exists()) {
      await csvFile.delete();
    }
    
    // Also delete trajectory file if exists
    final trajFile = File(path.join(p, '${dataset.id}-trajectory.json'));
    if (await trajFile.exists()) {
      await trajFile.delete();
    }
  }

  Future<String?> readCsv(String filename) async {
    try {
      final p = await _localPath;
      final file = File(path.join(p, filename));
      if (await file.exists()) {
        return await file.readAsString();
      }
    } catch (e) {
      debugPrint('Error reading CSV: $e');
    }
    return null;
  }
  Future<void> clearAllData() async {
    try {
      final p = await _localPath;
      final dir = Directory(p);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        debugPrint('All internal data cleared successfully.');
      }
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }
}
