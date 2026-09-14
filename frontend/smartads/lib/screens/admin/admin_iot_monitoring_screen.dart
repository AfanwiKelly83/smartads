import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_colors.dart';
import 'dart:async';

class AdminIotMonitoringScreen extends StatefulWidget {
  const AdminIotMonitoringScreen({super.key});

  @override
  State<AdminIotMonitoringScreen> createState() => _AdminIotMonitoringScreenState();
}

class _AdminIotMonitoringScreenState extends State<AdminIotMonitoringScreen> {
  Timer? _timer;
  final List<Map<String, dynamic>> _esp32Devices = [
    {'id': 'ESP32-NODE-A1', 'location': 'Downtown Plaza', 'status': 'ONLINE', 'ping': 42, 'uptime': '14d 2h'},
    {'id': 'ESP32-NODE-B2', 'location': 'Highway 42', 'status': 'ONLINE', 'ping': 18, 'uptime': '5d 6h'},
    {'id': 'ESP32-NODE-C3', 'location': 'Mall Entrance', 'status': 'OFFLINE', 'ping': 0, 'uptime': '0m'},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          // Mock some heartbeat updates
          _esp32Devices[0]['ping'] = 40 + (DateTime.now().second % 10);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('IoT Monitoring Panel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ESP32 / RASPBERRY PI DEVICE STATUS',
              style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _esp32Devices.length,
                itemBuilder: (context, index) {
                  final device = _esp32Devices[index];
                  final isOnline = device['status'] == 'ONLINE';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isOnline ? AppColors.statusOnline : AppColors.statusOffline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isOnline ? Icons.router_rounded : Icons.portable_wifi_off_rounded,
                          color: isOnline ? AppColors.statusOnline : AppColors.statusOffline,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(device['id'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(device['location'], style: const TextStyle(color: AppTheme.textSecondary)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(device['status'], style: TextStyle(color: isOnline ? AppColors.statusOnline : AppColors.statusOffline, fontWeight: FontWeight.bold)),
                            Text('Ping: \ms', style: const TextStyle(color: AppTheme.textSecondary)),
                            Text('Uptime: \', style: const TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
