import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/branding_panel.dart';
import '../widgets/login_form.dart';
import '../widgets/signup_form.dart';
import '../widgets/video_background.dart';

enum AuthMode { login, register }

class AuthPage extends StatefulWidget {
  final AuthMode initialMode;

  const AuthPage({super.key, this.initialMode = AuthMode.login});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late AuthMode _authMode;

  @override
  void initState() {
    super.initState();
    _authMode = widget.initialMode;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: VideoBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1100 : 480),
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
                          Expanded(flex: 6, child: _buildAuthCard()),
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
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.accentPrimary.withValues(alpha: 0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
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
        border: Border.all(color: AppTheme.borderSubtle.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(title: 'Login', mode: AuthMode.login),
          ),
          Expanded(
            child: _buildTabButton(title: 'Register', mode: AuthMode.register),
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
          gradient: isSelected ? AppTheme.subtleGradient : null,
          border: isSelected
              ? Border.all(
                  color: AppTheme.accentPrimary.withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? AppTheme.accentLight : AppTheme.textSecondary,
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
