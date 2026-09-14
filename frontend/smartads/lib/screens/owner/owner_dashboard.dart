import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../widgets/stat_card.dart';
import '../../services/auth_service.dart';

class OwnerDashboard extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const OwnerDashboard({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Owner Banner Header
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.accentPrimary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade900,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'BILLBOARD OWNER PORTAL',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome, ${user?.fullName ?? 'Billboard Owner'}!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Register new digital billboards, generate location QR codes, track bookings, & monitor IoT hardware.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop)
                    const Icon(
                      Icons.storefront_rounded,
                      size: 70,
                      color: AppColors.accentLight,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            const Text(
              'MY BILLBOARDS & EARNINGS OVERVIEW',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),

            // Stat Cards Grid
            GridView.count(
              crossAxisCount: isDesktop ? 4 : (size.width > 600 ? 2 : 1),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: isDesktop ? 1.6 : 2.2,
              children: const [
                StatCard(
                  title: 'My Billboards',
                  value: '4 Displays',
                  subtitle: '3 Online | 1 Standby',
                  icon: Icons.tv_rounded,
                  accentColor: AppColors.accentPrimary,
                ),
                StatCard(
                  title: 'Active Bookings',
                  value: '8 Slots',
                  subtitle: '100% Slot Occupancy',
                  icon: Icons.calendar_month_rounded,
                  accentColor: Colors.cyan,
                ),
                StatCard(
                  title: 'Monthly Earnings',
                  value: '890,000 FCFA',
                  subtitle: 'Payout via MoMo/Orange',
                  icon: Icons.account_balance_wallet_rounded,
                  accentColor: Color(0xFF10B981),
                ),
                StatCard(
                  title: 'IoT Device Status',
                  value: 'Healthy (38.5°C)',
                  subtitle: 'Heartbeat Signal 100%',
                  icon: Icons.developer_board_rounded,
                  accentColor: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 36),

            // Quick Actions Header
            const Text(
              'QUICK MANAGEMENT ACTIONS',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                ElevatedButton.icon(
                  onPressed: () => onNavigateTab?.call(1), // Nav to Billboards
                  icon: const Icon(
                    Icons.add_location_alt_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'REGISTER NEW BILLBOARD & QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => onNavigateTab?.call(5), // Nav to IoT
                  icon: const Icon(
                    Icons.developer_board_rounded,
                    color: AppColors.accentLight,
                  ),
                  label: const Text(
                    'MONITOR IOT HARDWARE',
                    style: TextStyle(
                      color: AppColors.accentLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.borderSubtle),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
