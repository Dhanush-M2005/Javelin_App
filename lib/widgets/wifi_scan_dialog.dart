import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import '../providers/wifi_service_provider.dart';

class WifiManagementDialog extends StatefulWidget {
  const WifiManagementDialog({super.key});

  @override
  State<WifiManagementDialog> createState() => _WifiManagementDialogState();
}

class _WifiManagementDialogState extends State<WifiManagementDialog> {
  String? _expandedSsid;
  final TextEditingController _passwordController = TextEditingController();
  bool _isConnecting = false;
  Timer? _connectionCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<WifiServiceProvider>();
      // Check current connection first
      provider.checkCurrentConnection().then((_) {
        // Then scan for networks
        provider.startScan();
      });
      
      // Set up periodic connection check every 3 seconds
      _connectionCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        if (mounted) {
          provider.checkCurrentConnection();
        }
      });
    });
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[800]!),
        ),
        child: Consumer<WifiServiceProvider>(
          builder: (context, provider, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(context),
                if (provider.statusMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      provider.statusMessage,
                      style: const TextStyle(color: Colors.orange, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(child: _buildNetworksList(provider)),
                _buildFooter(provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Wi-Fi Connection',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworksList(WifiServiceProvider provider) {
    if (provider.isScanning) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF0096FF)),
            SizedBox(height: 16),
            Text('Scanning for networks...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (provider.scannedNetworks.isEmpty) {
      // If connected but scan failed (e.g. no permission), show the connected network manually
      if (provider.connectionStatus == WifiConnectionStatus.connected) {
         return ListView(
           padding: const EdgeInsets.all(16),
           children: [
             _buildConnectedCard(provider, provider.connectedSsid ?? "Javelin Device"),
             const SizedBox(height: 20),
             const Center(child: Text('No other networks found (Location permission might be disabled)', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)),
           ],
         );
      }
      return const Center(child: Text('No networks found. Check Location permissions.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.scannedNetworks.length + (provider.connectionStatus == WifiConnectionStatus.connected ? 1 : 0),
      itemBuilder: (context, index) {
        // If connected, show the connected card first
        if (provider.connectionStatus == WifiConnectionStatus.connected && index == 0) {
           return _buildConnectedCard(provider, provider.connectedSsid ?? "Javelin Device");
        }
        
        final listIndex = provider.connectionStatus == WifiConnectionStatus.connected ? index - 1 : index;
        final network = provider.scannedNetworks[listIndex];
        
        // Skip if this is the connected network we already showed
        if (provider.connectionStatus == WifiConnectionStatus.connected && network.ssid == provider.connectedSsid) {
           return const SizedBox.shrink(); 
        }

        final isConnected = provider.connectionStatus == WifiConnectionStatus.connected && 
                           provider.connectedSsid == network.ssid;
        final isExpanded = _expandedSsid == network.ssid;

        return Card(
          color: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isConnected ? const Color(0xFF0096FF) : Colors.grey[800]!,
              width: isConnected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Icon(
                  isConnected ? Icons.wifi : Icons.wifi_lock,
                  color: isConnected ? const Color(0xFF0096FF) : Colors.white,
                ),
                title: Text(
                  network.ssid,
                  style: TextStyle(
                    color: isConnected ? const Color(0xFF0096FF) : Colors.white,
                    fontWeight: isConnected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(
                  "${network.level} dBm",
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: isConnected
                    ? const Icon(Icons.check_circle, color: Color(0xFF0096FF))
                    : const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  if (!isConnected && !_isConnecting) {
                    setState(() {
                      _expandedSsid = _expandedSsid == network.ssid ? null : network.ssid;
                      _passwordController.clear();
                    });
                  }
                },
              ),
              if (isConnected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Text(
                          'Successfully connected to ${network.ssid}',
                          style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await provider.connectToDevice("");
                            setState(() {
                              _expandedSsid = null;
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Disconnect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                )
              else if (isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect to ${network.ssid}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        enabled: !_isConnecting,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Password',
                          hintStyle: TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Color(0xFF2C2C2C),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isConnecting ? null : () {
                                setState(() {
                                  _expandedSsid = null;
                                  _passwordController.clear();
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.grey),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isConnecting
                                  ? null
                                  : () async {
                                      setState(() => _isConnecting = true);
                                      await provider.connectToDevice(
                                        network.ssid,
                                        password: _passwordController.text,
                                      );
                                      setState(() {
                                        _isConnecting = false;
                                        _passwordController.clear();
                                        // Keep expanded only if connection succeeded
                                        if (provider.connectionStatus != WifiConnectionStatus.connected) {
                                          _expandedSsid = null;
                                        }
                                      });
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0096FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                _isConnecting ? 'Connecting...' : 'Connect',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConnectedCard(WifiServiceProvider provider, String ssid) {
      return Card(
          color: Colors.transparent,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(
              color: Color(0xFF0096FF),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.wifi,
                  color: Color(0xFF0096FF),
                ),
                title: Text(
                  ssid,
                  style: const TextStyle(
                    color: Color(0xFF0096FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  "Connected",
                  style: TextStyle(color: Colors.green),
                ),
                trailing: const Icon(Icons.check_circle, color: Color(0xFF0096FF)),
              ),
              Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Text(
                          'Connected',
                          style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                             await provider.disconnect();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Disconnect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                )
            ],
          ),
        );
  }

  Widget _buildFooter(WifiServiceProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[800]!)),
      ),
      child: Column(
        children: [
          const Text(
            'Select a network to connect.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => AppSettings.openAppSettings(type: AppSettingsType.wifi),
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Wi-Fi Settings'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF0096FF)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.startScan,
                  icon: const Icon(Icons.refresh, size: 18, color: Colors.white),
                  label: const Text(
                    'Re-scan',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0096FF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> showWifiScanDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (BuildContext context) => const WifiManagementDialog(),
  );
}