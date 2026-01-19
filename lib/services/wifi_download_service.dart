import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/dataset.dart';
import '../utils/csv_parser.dart';
import 'file_service.dart';
import 'trajectory_analyzer.dart';

class WifiDownloadService {
  static const String targetSsid = "ESP32-FileServer";
  static const String esp32Url = "http://192.168.4.1";
  static const String filesUrl = "$esp32Url/files";
  
  final FileService _fileService;
  final TrajectoryAnalyzer _analyzer;
  
  WifiDownloadService(this._fileService, this._analyzer);

  Future<bool> isConnectedToEsp32() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) return false;
      if (connectivityResult != ConnectivityResult.wifi) return false;
      
      // Ping
      final response = await http.get(Uri.parse(esp32Url)).timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isConnectedToWifi() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult == ConnectivityResult.wifi;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getAvailableFiles() async {
    try {
      final response = await http.get(Uri.parse(esp32Url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        final files = <String>[];
        
        // Match Python script logic: find buttons with onclick="downloadFile('...')"
        final buttons = document.querySelectorAll('button[onclick]');
        for (var button in buttons) {
          final onclick = button.attributes['onclick'];
          if (onclick != null && onclick.contains('downloadFile')) {
            final regex = RegExp(r"downloadFile\('([^']+)'\)");
            final match = regex.firstMatch(onclick);
            if (match != null) {
              files.add(match.group(1)!);
            }
          }
        }
        return files;
      }
    } catch (e) {
      debugPrint('Error getting files: $e');
    }
    return [];
  }

  Future<Dataset> downloadAndProcessFile(String filename, String deviceSsid) async {
    final downloadUrl = '$esp32Url/download?file=$filename';
    final id = const Uuid().v4();
    final now = DateTime.now();

    try {
      final response = await http.get(Uri.parse(downloadUrl)).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) throw Exception('Download failed: ${response.statusCode}');
      
      var csvContent = response.body;
      
      // Fix header if needed (match Python script logic)
      if (!csvContent.trim().toLowerCase().startsWith('timestamp_ms')) {
        const correctHeader = "Timestamp_ms,AccX_Filt,AccY_Filt,AccZ_Filt,GyrX_Filt,GyrY_Filt,GyrZ_Filt,MagX_Filt,MagY_Filt,MagZ_Filt\n";
        csvContent = correctHeader + csvContent;
      }
      
      // Validate
      try {
        final samples = CsvParser.parseSensorData(csvContent);
        
        // Save
        final savedFile = await _fileService.saveCsv('$id.csv', csvContent);
        
        // Analyze
        final throws = _analyzer.detectThrows(samples, id, now);
        
        DatasetStatus status = DatasetStatus.downloaded;
        if (throws.isEmpty) status = DatasetStatus.noThrows;
        
        return Dataset(
          id: id,
          deviceSsid: deviceSsid,
          filename: savedFile.path.split('/').last,
          downloadedAt: now,
          status: status,
          throws: throws,
        );
      } catch (e) {
        // Validation failed
        return Dataset(
          id: id,
          deviceSsid: deviceSsid,
          filename: filename,
          downloadedAt: now,
          status: DatasetStatus.skipped,
          skipReason: e.toString(),
        );
      }
    } catch (e) {
      return Dataset(
        id: id,
        deviceSsid: deviceSsid,
        filename: filename,
        downloadedAt: now,
        status: DatasetStatus.error,
        skipReason: 'Download error: $e',
      );
    }
  }
}