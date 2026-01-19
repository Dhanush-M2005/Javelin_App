import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wifi_service_provider.dart';
import 'wifi_scan_dialog.dart';

class EnhancedAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EnhancedAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Consumer<WifiServiceProvider>(
      builder: (context, wifiProvider, child) {
        final isConnected = wifiProvider.connectionStatus == WifiConnectionStatus.connected;
        final isSyncing = wifiProvider.statusMessage.contains('Syncing') || wifiProvider.statusMessage.contains('Downloading');
        
        // Dynamic WiFi icon color based on connection status
        Color wifiIconColor = Colors.white;
        if (isConnected) {
          wifiIconColor = const Color(0xFF0096FF); // Blue when connected
        } else if (wifiProvider.connectionStatus == WifiConnectionStatus.connecting) {
          wifiIconColor = Colors.orangeAccent;
        }

        return AppBar(
          title: Row(
            children: [
              const Text('Javelin Tracker'),
              if (isConnected && wifiProvider.connectedSsid != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0096FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF0096FF), width: 1),
                  ),
                  child: Text(
                    wifiProvider.connectedSsid!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0096FF)),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            // WiFi button with dynamic color and status indicator
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.wifi, color: wifiIconColor),
                  tooltip: isConnected ? 'Connected: ${wifiProvider.connectedSsid}' : 'Connect to WiFi',
                  onPressed: () {
                    showWifiScanDialog(context);
                  },
                ),
                if (isSyncing)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0096FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const SizedBox(
                        width: 8,
                        height: 8,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                if (isConnected && !isSyncing)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0096FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}