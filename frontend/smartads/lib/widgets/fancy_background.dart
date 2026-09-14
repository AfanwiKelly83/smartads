import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FancyBackground extends StatefulWidget {
  final Widget child;

  const FancyBackground({super.key, required this.child});

  @override
  State<FancyBackground> createState() => _FancyBackgroundState();
}

class _FancyBackgroundState extends State<FancyBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Subtle dark gradient base
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppTheme.bgDark, AppTheme.surfaceDark],
            ),
          ),
        ),

        // Animated moving gradient overlay
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final t = _ctrl.value;
            return ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  begin: Alignment(-1 + 2 * t, -1),
                  end: Alignment(1 - 2 * t, 1),
                  colors: [
                    AppTheme.accentPrimary.withValues(alpha: 0.06),
                    Colors.transparent,
                    AppTheme.accentLight.withValues(alpha: 0.06),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.overlay,
              child: Container(color: Colors.white.withValues(alpha: 0.0)),
            );
          },
        ),

        // Floating soft circles (street light / bokeh)
        ...List.generate(5, (i) {
          return AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              final phase = (_ctrl.value + i * 0.18) % 1.0;
              final x = (0.1 + 0.8 * ((sin(phase * 2 * pi) + 1) / 2));
              final y = (0.05 + 0.9 * ((cos(phase * 2 * pi) + 1) / 2));
              final size = 80.0 + 120.0 * (i / 5); // varied sizes

              return Positioned(
                left: MediaQuery.of(context).size.width * x - size / 2,
                top: MediaQuery.of(context).size.height * y - size / 2,
                child: Opacity(
                  opacity: 0.06 + 0.06 * (1 - (i / 6)),
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.accentLight.withValues(alpha: 0.28 - i * 0.04),
                          AppTheme.accentPrimary.withValues(alpha: 0.06 - i * 0.008),
                        ],
                      ),
                      // soft blur via boxShadow
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentPrimary.withValues(alpha: 0.08),
                          blurRadius: 40 + i * 6,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }),

        // Subtle animated horizontal light streak
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final w = MediaQuery.of(context).size.width;
            final h = MediaQuery.of(context).size.height;
            final x = (w * (_ctrl.value * 1.5 % 1.0)) - w * 0.25;
            return Positioned(
              left: x,
              top: h * 0.25,
              child: Transform.rotate(
                angle: -0.18,
                child: Container(
                  width: w * 0.6,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentPrimary.withValues(alpha: 0.06),
                        AppTheme.accentLight.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(80),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentPrimary.withValues(alpha: 0.06),
                        blurRadius: 40,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Vignette
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.2),
              radius: 1.0,
              colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
              stops: const [0.6, 1.0],
            ),
          ),
        ),

        // Foreground content
        widget.child,
      ],
    );
  }
}
