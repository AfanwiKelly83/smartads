import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/role_guard.dart';

class AnalyticsIotScreen extends StatelessWidget {
  const AnalyticsIotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 650;
    final isDesktop = size.width >= 960;

    return RoleGuard(
      allowedRoles: RoleAccess.admin,
      child: Scaffold(
        backgroundColor: AppTheme.bgDark,
        appBar: isMobile
            ? AppBar(
                backgroundColor: AppTheme.surfaceDark,
                title: const Text(
                  'IoT Analytics',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                iconTheme: const IconThemeData(color: Colors.white),
              )
            : null,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 14 : 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'IoT Device Monitoring & Analytics',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 20 : 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Real-time billboard display hardware heartbeats, device health, & impression logs.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              SizedBox(height: isMobile ? 20 : 32),

              // Top Stat Cards
              GridView.count(
                crossAxisCount: isDesktop ? 3 : (isMobile ? 1 : 2),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isDesktop ? 2.2 : (isMobile ? 1.6 : 2.0),
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
              SizedBox(height: isMobile ? 24 : 36),

              // IoT Controller Health List Section
              const Text(
                'HARDWARE DEVICE HEARTBEATS',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.25),
                  ),
                ),
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildIotTile(
                      isMobile: isMobile,
                      deviceName: 'Douala Akwa Screen IoT Node-01',
                      ipAddress: '192.168.1.101',
                      temp: '37.2 °C',
                      status: 'ONLINE',
                      lastPing: '2s ago',
                    ),
                    const Divider(color: AppTheme.borderSubtle, height: 1),
                    _buildIotTile(
                      isMobile: isMobile,
                      deviceName: 'Bastoss Yaoundé Controller Node-02',
                      ipAddress: '192.168.1.102',
                      temp: '40.1 °C',
                      status: 'ONLINE',
                      lastPing: '5s ago',
                    ),
                    const Divider(color: AppTheme.borderSubtle, height: 1),
                    _buildIotTile(
                      isMobile: isMobile,
                      deviceName: 'Limbe Seaside Expressway Node-03',
                      ipAddress: '192.168.1.103',
                      temp: '-- °C',
                      status: 'OFFLINE',
                      lastPing: '15m ago',
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
    required bool isMobile,
    required String deviceName,
    required String ipAddress,
    required String temp,
    required String status,
    required String lastPing,
  }) {
    final isOnline = status == 'ONLINE';

    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: isMobile ? 6 : 10,
      ),
      leading: Container(
        padding: EdgeInsets.all(isMobile ? 8 : 10),
        decoration: BoxDecoration(
          color: isOnline
              ? const Color(0xFF10B981).withValues(alpha: 0.15)
              : Colors.red.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isOnline ? Icons.sensors_rounded : Icons.sensors_off_rounded,
          color: isOnline ? const Color(0xFF10B981) : Colors.red,
          size: isMobile ? 18 : 22,
        ),
      ),
      title: Text(
        deviceName,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 13.5 : 15,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          'IP: $ipAddress • Temp: $temp • Ping: $lastPing',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: isMobile ? 11 : 12,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isOnline ? Colors.green.shade900 : Colors.red.shade900,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          status,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 9.5,
          ),
        ),
      ),
    );
  }
}
