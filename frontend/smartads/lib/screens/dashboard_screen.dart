import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/stat_card.dart';
import '../services/api_service.dart';

class DashboardScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const DashboardScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final user = ApiService().currentUser;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Banner
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: AppTheme.subtleGradient,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.08),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentPrimary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user?.role ?? 'ADVERTISER',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'SMARTADS PLATFORM 1.0',
                              style: TextStyle(
                                color: AppTheme.accentLight,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome back, ${user?.fullName ?? 'Advertiser'}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Manage your digital billboard advertising campaigns, monitor playback analytics, and optimize performance.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 24),
                    const Icon(
                      Icons.cell_tower_rounded,
                      size: 80,
                      color: AppTheme.accentLight,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Section Header
            const Text(
              'PLATFORM OVERVIEW & METRICS',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),

            // Stat Cards Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                int crossAxisCount = 4;
                if (width < 600) {
                  crossAxisCount = 1;
                } else if (width < 1000) {
                  crossAxisCount = 2;
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: width < 600 ? 2.2 : 1.6,
                  children: const [
                    StatCard(
                      title: 'Active Campaigns',
                      value: '12',
                      subtitle: '+2 starting this week',
                      icon: Icons.campaign_rounded,
                      accentColor: AppTheme.accentPrimary,
                    ),
                    StatCard(
                      title: 'Digital Billboards',
                      value: '28',
                      subtitle: '26 Online / 2 Maintenance',
                      icon: Icons.tv_rounded,
                      accentColor: Colors.cyan,
                    ),
                    StatCard(
                      title: 'Total Playback Logs',
                      value: '148,250',
                      subtitle: 'Verified by Smart AI',
                      icon: Icons.play_circle_fill_rounded,
                      accentColor: Color(0xFF10B981),
                    ),
                    StatCard(
                      title: 'Total Expenditure',
                      value: '1.45M FCFA',
                      subtitle: 'MTN & Orange Payments',
                      icon: Icons.account_balance_wallet_rounded,
                      accentColor: Colors.amber,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 36),

            // Quick Actions Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Action Buttons Row
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildActionButton(
                  icon: Icons.add_box_rounded,
                  label: 'Create New Campaign',
                  color: AppTheme.accentPrimary,
                  onTap: () =>
                      onNavigateTab?.call(2), // Tab index 2 = Campaigns
                ),
                _buildActionButton(
                  icon: Icons.cloud_upload_rounded,
                  label: 'Upload Media Ad',
                  color: Colors.cyan,
                  onTap: () =>
                      onNavigateTab?.call(3), // Tab index 3 = Advertisements
                ),
                _buildActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Explore Billboards & QR',
                  color: Colors.amber,
                  onTap: () =>
                      onNavigateTab?.call(1), // Tab index 1 = Billboards
                ),
                _buildActionButton(
                  icon: Icons.query_stats_rounded,
                  label: 'IoT & Live Monitoring',
                  color: Color(0xFF10B981),
                  onTap: () =>
                      onNavigateTab?.call(5), // Tab index 5 = Analytics/IoT
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textMuted,
              size: 12,
            ),
          ],
        ),
      ),
    );
  }
}
