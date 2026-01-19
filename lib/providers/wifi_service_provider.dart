import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart';
import '../models/dataset.dart';
import '../services/wifi_download_service.dart';
import '../services/file_service.dart';
import '../services/trajectory_analyzer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'dataset_provider.dart';

enum WifiConnectionStatus { disconnected, connecting, connected, error }

class WifiServiceProvider with ChangeNotifier {
  final WifiDownloadService _downloadService;
  final DatasetProvider _datasetProvider;
  
  WifiConnectionStatus _connectionStatus = WifiConnectionStatus.disconnected;
  String? _connectedSsid;
  String _statusMessage = '';
  List<WiFiAccessPoint> _scannedNetworks = [];
  bool _isScanning = false;
  
  WifiServiceProvider(this._datasetProvider) 
      : _downloadService = WifiDownloadService(FileService(), TrajectoryAnalyzer());

  WifiConnectionStatus get connectionStatus => _connectionStatus;
  String? get connectedSsid => _connectedSsid;
  String get statusMessage => _statusMessage;
  List<WiFiAccessPoint> get scannedNetworks => _scannedNetworks;
  bool get isScanning => _isScanning;

  Future<void> checkCurrentConnection() async {
    try {
      // 1. Check if connected to ANY Wi-Fi
      final isWifiConnected = await _downloadService.isConnectedToWifi();

      if (isWifiConnected) {
        _connectionStatus = WifiConnectionStatus.connected;

        // 2. Try to get SSID
        String? currentSsid;
        try {
          if (Platform.isAndroid) {
            currentSsid = await WiFiForIoTPlugin.getSSID();
          }
        } catch (e) {
          debugPrint('Could not get SSID: $e');
        }

        // Set SSID display
        if (currentSsid == null || currentSsid.isEmpty || currentSsid == "<unknown ssid>") {
          // Only overwrite if we don't already have a valid SSID (e.g. set by connectToDevice)
          // or if the current one is generic.
          if (_connectedSsid == null || _connectedSsid == "Wi-Fi Connected" || _connectedSsid == "Javelin Device") {
             _connectedSsid = "Wi-Fi Connected"; 
             _statusMessage = "Connected to Wi-Fi";
          }
        } else {
          _connectedSsid = currentSsid;
          _statusMessage = "Connected to $_connectedSsid";
        }

        // 3. Check if it's OUR device (ESP32)
        final isDeviceReachable = await _downloadService.isConnectedToEsp32();
        if (isDeviceReachable) {
           debugPrint('ESP32 is reachable!');
           // If we didn't get a good SSID but it IS the device, label it clearly
           if (_connectedSsid == "Wi-Fi Connected" || _connectedSsid == currentSsid) {
              // Only override if generic or if we want to enforce "Javelin Device" label?
              // Actually, if we have the real SSID, we might want to keep it.
              // But if it's generic, we definitely want "Javelin Device".
              if (_connectedSsid == "Wi-Fi Connected") {
                  _connectedSsid = "Javelin Device";
                  _statusMessage = "Connected to Javelin Device";
              }
           }
           // Auto-sync
           syncFiles();
        } else {
           debugPrint('Connected to Wi-Fi but ESP32 not reachable (Normal Internet?)');
        }

      } else {
        // Not connected to Wi-Fi
        if (_connectionStatus == WifiConnectionStatus.connected) {
          _connectionStatus = WifiConnectionStatus.disconnected;
          _connectedSsid = null;
          _statusMessage = "Disconnected";
        }
      }
    } catch (e) {
      debugPrint('Error checking connection: $e');
      _connectionStatus = WifiConnectionStatus.error;
      _statusMessage = "Error checking connection";
    }
    notifyListeners();
  }

  Future<void> startScan() async {
    if (_isScanning) return;
    _isScanning = true;
    _statusMessage = "Scanning...";
    notifyListeners();

    try {
      // 1. Ensure Wi-Fi is enabled (Android only)
      if (Platform.isAndroid) {
        try {
          bool isWifiEnabled = await WiFiForIoTPlugin.isEnabled();
          if (!isWifiEnabled) {
            _statusMessage = "Enabling Wi-Fi...";
            notifyListeners();
            await WiFiForIoTPlugin.setEnabled(true);
            // Wait a bit for it to turn on
            int retries = 0;
            while (!isWifiEnabled && retries < 5) {
              await Future.delayed(const Duration(milliseconds: 500));
              isWifiEnabled = await WiFiForIoTPlugin.isEnabled();
              retries++;
            }
            
            if (!isWifiEnabled) {
               _statusMessage = "Please enable Wi-Fi to scan.";
               _isScanning = false;
               notifyListeners();
               return;
            }
          }
        } catch (e) {
          debugPrint("Error checking/enabling Wi-Fi: $e");
        }
      }

      // 2. Check Permissions and Service via WiFiScan
      final canScan = await WiFiScan.instance.canStartScan();
      
      if (canScan == CanStartScan.yes) {
        await _performScan();
      } else {
        // Handle specific failure cases
        switch (canScan) {
          case CanStartScan.noLocationPermissionRequired:
          case CanStartScan.noLocationPermissionDenied:
            // Request permission
            _statusMessage = "Requesting location permission...";
            notifyListeners();
            final status = await Permission.location.request();
            if (status.isGranted) {
               // Retry scan
               final canScanRetry = await WiFiScan.instance.canStartScan();
               if (canScanRetry == CanStartScan.yes) {
                 await _performScan();
               } else {
                 _statusMessage = "Scan failed: $canScanRetry";
               }
            } else {
               _statusMessage = "Location permission denied.";
               if (status.isPermanentlyDenied) {
                 await AppSettings.openAppSettings(type: AppSettingsType.settings);
               }
            }
            break;
            
          case CanStartScan.noLocationServiceDisabled:
            _statusMessage = "Location disabled. Opening settings...";
            notifyListeners();
            await AppSettings.openAppSettings(type: AppSettingsType.location);
            _statusMessage = "Enable Location and retry scan.";
            break;
            
          default:
             _statusMessage = "Scan not supported: $canScan";
             break;
        }
      }
    } catch (e) {
      _statusMessage = "Scan failed. Please check permissions.";
      debugPrint("Scan failed: $e");
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> _performScan() async {
    await WiFiScan.instance.startScan();
    await Future.delayed(const Duration(seconds: 1)); // Wait for scan
    _scannedNetworks = await WiFiScan.instance.getScannedResults();
    _scannedNetworks.sort((a, b) => b.level.compareTo(a.level));
    
    // Check connection again to see if we are connected to one of these
    await checkCurrentConnection();
  }

  Future<void> disconnect() async {
    _connectionStatus = WifiConnectionStatus.disconnected;
    _connectedSsid = null;
    _statusMessage = "Disconnected";
    notifyListeners();

    try {
      if (Platform.isAndroid) {
        await WiFiForIoTPlugin.disconnect();
      }
    } catch (e) {
      debugPrint("Disconnect failed: $e");
    }
  }

  Future<void> connectToDevice(String ssid, {String? password}) async {
    _connectionStatus = WifiConnectionStatus.connecting;
    _statusMessage = "Connecting to $ssid...";
    notifyListeners();

    try {
      bool connected = false;
      if (Platform.isAndroid) {
        // Try to connect programmatically
        try {
          // Force disconnect first to ensure clean state
          await WiFiForIoTPlugin.disconnect();
          
          // Heuristic: If it looks like our device, assume no internet (ESP32).
          // Otherwise, assume internet (so normal wifi works).
          final isLikelyIotDevice = ssid.toLowerCase().contains('esp32') || ssid.toLowerCase().contains('javelin');
          
          connected = await WiFiForIoTPlugin.connect(ssid,
              password: password, 
              security: password != null && password.isNotEmpty ? NetworkSecurity.WPA : NetworkSecurity.NONE,
              joinOnce: true,
              withInternet: !isLikelyIotDevice // True for normal wifi, False for IoT
          );
        } catch (e) {
          debugPrint("WiFiForIoTPlugin connection failed: $e");
        }
      } 
      
      // If programmatic connection said true, we assume connected immediately
      if (connected) {
         _connectionStatus = WifiConnectionStatus.connected;
         _connectedSsid = ssid;
         _statusMessage = "Connected";
         notifyListeners();
      }
      
      // Give it a moment to establish IP
      await Future.delayed(const Duration(seconds: 4));

      // Verify connection by checking if we can reach the device
      // OR if we are just connected to general WiFi
      await checkCurrentConnection();
      
      // If we are still not connected after check, then show error
      if (_connectionStatus != WifiConnectionStatus.connected) {
         if (Platform.isAndroid && !connected) {
           _connectionStatus = WifiConnectionStatus.error;
           _statusMessage = "Failed to connect. Please use system settings.";
        } else {
           _connectionStatus = WifiConnectionStatus.error;
           _statusMessage = "Device not responding. Check Wi-Fi.";
        }
      }
    } catch (e) {
      _connectionStatus = WifiConnectionStatus.error;
      _statusMessage = "Connection error: $e";
    }
    notifyListeners();
  }

  Future<void> syncFiles() async {
    if (_connectionStatus != WifiConnectionStatus.connected) return;
    
    // CRITICAL: Only sync if we are actually connected to the ESP32
    if (!await _downloadService.isConnectedToEsp32()) {
       debugPrint("Skipping sync - not connected to ESP32");
       return;
    }
    
    _statusMessage = "Syncing files...";
    notifyListeners();

    try {
      final files = await _downloadService.getAvailableFiles();
      if (files.isEmpty) {
        _statusMessage = "No files found on device.";
      } else {
        int newFiles = 0;
        for (final file in files) {
          // Check if we already have this file by filename (not by SSID)
          // This allows data to persist across different devices
          final exists = _datasetProvider.datasets.any((d) => d.filename == file);
          if (!exists) {
            _statusMessage = "Downloading $file...";
            notifyListeners();
            
            final dataset = await _downloadService.downloadAndProcessFile(file, _connectedSsid ?? "Unknown");
            await _datasetProvider.addDataset(dataset);
            newFiles++;
          }
        }
        _statusMessage = "Sync complete. $newFiles new files.";
      }
    } catch (e) {
      // If sync fails, it might just be because we lost connection or it's not the ESP32
      // Don't show a scary error message if we are still connected to wifi
      if (await _downloadService.isConnectedToWifi()) {
         _statusMessage = "Connected";
      } else {
         _statusMessage = "Sync failed: $e";
      }
    }
    notifyListeners();
  }
  
  // Manual override
  Future<void> manualConnect(String ip) async {
     // Just try to sync
     _connectionStatus = WifiConnectionStatus.connecting;
     notifyListeners();
     // We assume connected
     if (await _downloadService.isConnectedToEsp32()) {
        _connectionStatus = WifiConnectionStatus.connected;
        _connectedSsid = "Manual IP";
        await syncFiles();
     } else {
        _connectionStatus = WifiConnectionStatus.error;
        _statusMessage = "Could not reach device at $ip";
     }
     notifyListeners();
  }
}
