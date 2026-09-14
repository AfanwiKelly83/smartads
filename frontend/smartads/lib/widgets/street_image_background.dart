import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StreetImageBackground extends StatelessWidget {
  final Widget child;

  const StreetImageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Generated billboard street photo — city night scene with LED screens
        Image.asset(
          'assets/images/billboard_bg.jpg',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              // Fallback: animated dark gradient if image fails
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF050A18), Color(0xFF0D1B2A), Color(0xFF1A0A2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
        ),

        // Dark overlay — deeper at top and bottom for better text contrast
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.bgDark.withValues(alpha: 0.75),
                AppTheme.bgDark.withValues(alpha: 0.82),
                AppTheme.bgDark.withValues(alpha: 0.92),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Left-right vignette to focus the eye on center
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
                Colors.transparent,
                Colors.black.withValues(alpha: 0.4),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.0, 0.2, 0.8, 1.0],
            ),
          ),
        ),

        // Subtle golden inner glow from center (billboard reflection effect)
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0.0, -0.2),
              radius: 1.2,
              colors: [
                AppTheme.accentPrimary.withValues(alpha: 0.04),
                Colors.transparent,
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),

        // Foreground content
        child,
      ],
    );
  }
}
