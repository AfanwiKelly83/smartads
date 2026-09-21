import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/branding_panel.dart';
import '../widgets/video_background.dart';
import 'auth_page.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: VideoBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Expanded(
                            flex: 5,
                            child: DesktopBrandingPanel(),
                          ),
                          const SizedBox(width: 48),
                          Expanded(flex: 4, child: _buildWelcomePanel(context)),
                        ],
                      )
                    : Column(
                        children: [
                          const BrandingHeader(),
                          const SizedBox(height: 32),
                          _buildWelcomePanel(context),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentPrimary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'SMARTADS',
            style: TextStyle(
              color: AppTheme.accentPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Smart Advertising.\nSmarter Billboards.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Find. Book. Pay. Advertise.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AuthPage(initialMode: AuthMode.register),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Text('Get Started', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthPage(initialMode: AuthMode.login)),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textWhite,
              side: const BorderSide(color: AppTheme.accentPrimary),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('I Already Have an Account', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
