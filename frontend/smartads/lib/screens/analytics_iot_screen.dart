import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/role_guard.dart';

class AnalyticsIotScreen extends StatelessWidget {
  const AnalyticsIotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: RoleAccess.admin,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'IoT Device Monitoring & Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Real-time billboard display hardware heartbeats, device health, & impression logs.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Top Stat Cards
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 1,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 2.2,
                children: const [
                  StatCard(
                    title: 'Connected IoT Hardware',
                    value: '28 Controllers',
                    subtitle: '26 Online | 2 Standby',
                    icon: Icons.developer_board_rounded,
                    accentColor: Color(0xFF10B981),
                  ),
                  StatCard(
                    title: 'Avg Hardware Temp',
                    value: '38.5 °C',
                    subtitle: 'Optimal Operating Temp',
                    icon: Icons.thermostat_rounded,
                    accentColor: Colors.amber,
                  ),
                  StatCard(
                    title: 'Daily Verified Playbacks',
                    value: '14,890 Times',
                    subtitle: '100% Uptime Guarantee',
                    icon: Icons.sync_rounded,
                    accentColor: AppTheme.accentPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // IoT Controller Health List Section
              const Text(
                'HARDWARE DEVICE HEARTBEATS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 16),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.25),
                  ),
                ),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildIotTile(
                      deviceName: 'Douala Akwa Screen IoT Node-01',
                      ipAddress: '192.168.1.101',
                      temp: '37.2 °C',
                      status: 'ONLINE',
                      lastPing: '2 seconds ago',
                    ),
                    const Divider(color: AppTheme.borderSubtle),
                    _buildIotTile(
                      deviceName: 'Bastoss Yaoundé Controller Node-02',
                      ipAddress: '192.168.1.102',
                      temp: '40.1 °C',
                      status: 'ONLINE',
                      lastPing: '5 seconds ago',
                    ),
                    const Divider(color: AppTheme.borderSubtle),
                    _buildIotTile(
                      deviceName: 'Limbe Seaside Expressway Node-03',
                      ipAddress: '192.168.1.103',
                      temp: '-- °C',
                      status: 'OFFLINE',
                      lastPing: '15 minutes ago',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIotTile({
    required String deviceName,
    required String ipAddress,
    required String temp,
    required String status,
    required String lastPing,
  }) {
    final isOnline = status == 'ONLINE';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isOnline
              ? const Color(0xFF10B981).withValues(alpha: 0.15)
              : Colors.red.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded,
          color: isOnline ? const Color(0xFF10B981) : Colors.red,
        ),
      ),
      title: Text(
        deviceName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'IP: $ipAddress | Temp: $temp | Ping: $lastPing',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green.shade900 : Colors.red.shade900,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
