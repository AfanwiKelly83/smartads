import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import 'admin/admin_dashboard.dart';
import 'owner/owner_dashboard.dart';
import 'advertiser/advertiser_dashboard.dart';
import 'user_dashboard.dart';
import 'billboard_screen.dart';
import 'campaign_screen.dart';
import 'profile_screen.dart';
import 'analytics_iot_screen.dart';
import 'auth_page.dart';
import '../widgets/street_image_background.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialTabIndex;
  final bool isNewRegistration;

  const MainNavigationScreen({
    super.key,
    this.initialTabIndex = 0,
    this.isNewRegistration = false,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  bool get _isAdmin => AuthService().currentUser?.isAdmin == true;
  bool get _isAdvertiser {
    final user = AuthService().currentUser;
    return user?.isAdvertiser == true || user?.role == 'USER';
  }

  List<_NavigationItem> get _navigationItems {
    if (_isAdmin) {
      return const [
        _NavigationItem('Dashboard', Icons.dashboard_rounded),
        _NavigationItem('Billboards', Icons.tv_rounded),
        _NavigationItem('Manage Profile', Icons.account_circle_rounded),
        _NavigationItem('IoT & Analytics', Icons.insights_rounded),
      ];
    }

    if (_isAdvertiser) {
      return const [
        _NavigationItem('Home', Icons.home_rounded),
        _NavigationItem('Search Billboards', Icons.travel_explore_rounded),
        _NavigationItem('Campaigns', Icons.campaign_rounded),
        _NavigationItem('My Bookings', Icons.playlist_play_rounded),
        _NavigationItem('Manage Profile', Icons.account_circle_rounded),
      ];
    }

    return const [_NavigationItem('Dashboard', Icons.dashboard_rounded)];
  }

  List<Widget> get _navigationPages {
    if (_isAdmin) {
      return [
        _buildRoleDashboard(),
        const BillboardScreen(),
        const ProfileScreen(),
        const AnalyticsIotScreen(),
      ];
    }

    if (_isAdvertiser) {
      return [
        _buildRoleDashboard(),
        const BillboardScreen(),
        const CampaignScreen(),
        _buildRoleDashboard(),
        const ProfileScreen(),
      ];
    }

    return [_buildRoleDashboard()];
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  void _handleLogout() {
    AuthService().logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthPage()),
    );
  }

  Widget _buildRoleDashboard() {
    final user = AuthService().currentUser;
    if (user != null && user.isAdmin) {
      return const AdminDashboard();
    } else if (user != null && user.isOwner) {
      return OwnerDashboard(onNavigateTab: _onTabSelected);
    } else if (user != null && !user.isAdvertiser) {
      return UserDashboard(onNavigateTab: _onTabSelected);
    } else {
      return AdvertiserDashboard(
        onNavigateTab: _onTabSelected,
        isNewRegistration: widget.isNewRegistration,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;
    final isCompact = size.width < 600;
    final user = AuthService().currentUser;

    final navigationItems = _navigationItems;
    final pages = _navigationPages;
    if (_currentIndex >= pages.length) _currentIndex = 0;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: StreetImageBackground(
        child: Column(
          children: [
            // Global Top Header Bar
            Container(
              height: 72,
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.accentPrimary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Logo & Brand Name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.hub_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      if (!isCompact) ...[
                        const SizedBox(width: 12),
                        const Text(
                          'SMARTADS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),

                  // Right Profile & Logout Action items
                  Row(
                    children: [
                      if (!isCompact) ...[
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppTheme.accentLight,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No new notifications'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                      ],

                      // User Profile Chip (Navigates to Profile tab)
                      InkWell(
                        onTap: () => _onTabSelected(
                          _navigationItems.indexWhere(
                            (item) => item.label == 'Manage Profile',
                          ),
                        ),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.accentPrimary.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppTheme.accentPrimary
                                    .withValues(alpha: 0.2),
                                child: const Icon(
                                  Icons.person,
                                  size: 16,
                                  color: AppTheme.accentLight,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (!isCompact)
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 140,
                                  ),
                                  child: Text(
                                    user?.fullName ?? 'User',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!isCompact) const SizedBox(width: 12),

                      // Logout Button
                      IconButton(
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.redAccent,
                        ),
                        tooltip: 'Logout',
                        onPressed: _handleLogout,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main View Body (Sidebar for Desktop, Bottom Nav for Mobile)
            Expanded(
              child: Row(
                children: [
                  if (isDesktop)
                    Container(
                      width: 240,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceDark,
                        border: Border(
                          right: BorderSide(
                            color: AppTheme.accentPrimary.withValues(alpha: 0.15),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          for (
                            var index = 0;
                            index < navigationItems.length;
                            index++
                          )
                            _buildSidebarItem(
                              index,
                              navigationItems[index].label,
                              navigationItems[index].icon,
                            ),
                        ],
                      ),
                    ),

                  // Active Page Content
                  Expanded(
                    child: IndexedStack(index: _currentIndex, children: pages),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Mobile Bottom Navigation Bar
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
              backgroundColor: AppTheme.surfaceDark,
              selectedItemColor: AppTheme.accentLight,
              unselectedItemColor: AppTheme.textSecondary,
              type: BottomNavigationBarType.fixed,
              items: [
                for (final item in navigationItems)
                  BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
              ],
            ),
    );
  }

  Widget _buildSidebarItem(int index, String title, IconData icon) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.cardDark : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            gradient: isSelected ? AppTheme.subtleGradient : null,
            border: isSelected
                ? Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.4))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.accentLight : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 14),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationItem {
  final String label;
  final IconData icon;

  const _NavigationItem(this.label, this.icon);
}
