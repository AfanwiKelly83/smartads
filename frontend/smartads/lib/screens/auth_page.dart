import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/branding_panel.dart';
import '../widgets/login_form.dart';
import '../widgets/signup_form.dart';

enum AuthMode { login, register }

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  AuthMode _authMode = AuthMode.login;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Background ambient golden glow effects
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.goldPrimary.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.goldLight.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Main Responsive Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1100 : 480,
                  ),
                  child: isDesktop
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left Column: Desktop Branding Showcase Panel
                            const Expanded(
                              flex: 5,
                              child: DesktopBrandingPanel(),
                            ),
                            const SizedBox(width: 48),

                            // Right Column: Auth Card
                            Expanded(
                              flex: 6,
                              child: _buildAuthCard(),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            // Mobile Top Header
                            const BrandingHeader(isCompact: true),
                            const SizedBox(height: 32),

                            // Auth Card
                            _buildAuthCard(),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.goldPrimary.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 40,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: AppTheme.goldPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Segmented Tab Switcher (Login vs Register)
          _buildSegmentedTabSwitcher(),
          const SizedBox(height: 28),

          // Form Switcher Transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.05, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: _authMode == AuthMode.login
                ? LoginForm(
                    key: const ValueKey('login_form'),
                    onSwitchToRegister: () {
                      setState(() => _authMode = AuthMode.register);
                    },
                  )
                : SignUpForm(
                    key: const ValueKey('signup_form'),
                    onSwitchToLogin: () {
                      setState(() => _authMode = AuthMode.login);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.inputBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderGold.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              title: 'Login',
              mode: AuthMode.login,
            ),
          ),
          Expanded(
            child: _buildTabButton(
              title: 'Register',
              mode: AuthMode.register,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({required String title, required AuthMode mode}) {
    final bool isSelected = _authMode == mode;

    return GestureDetector(
      onTap: () {
        setState(() => _authMode = mode);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.cardDark : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          gradient: isSelected ? AppTheme.goldSubtleGradient : null,
          border: isSelected
              ? Border.all(
                  color: AppTheme.goldPrimary.withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppTheme.goldLight : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
