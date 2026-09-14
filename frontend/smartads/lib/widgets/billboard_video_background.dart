import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class BillboardVideoBackground extends StatefulWidget {
  final Widget child;

  const BillboardVideoBackground(
    this.child, {
    super.key,
  });

  @override
  State<BillboardVideoBackground> createState() => _BillboardVideoBackgroundState();
}

class _BillboardVideoBackgroundState extends State<BillboardVideoBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = _controller.value;
        return Stack(
          children: [
            // Dark Base Layer
            Container(color: AppColors.bgDark),

            // Dynamic Ambient Neon Billboard Light Beams
            Positioned(
              top: -100 + math.sin(value * math.pi * 2) * 50,
              left: -100 + math.cos(value * math.pi * 2) * 60,
              child: Container(
                width: 450,
                height: 450,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accentPrimary.withValues(alpha: 0.18),
                      Colors.cyan.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -150 + math.cos(value * math.pi * 2) * 40,
              right: -100 + math.sin(value * math.pi * 2) * 70,
              child: Container(
                width: 550,
                height: 550,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.blueAccent.withValues(alpha: 0.15),
                      AppColors.accentDark.withValues(alpha: 0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Animated Digital LED Scanlines Grid Overlay
            CustomPaint(
              size: Size.infinite,
              painter: _LedGridPainter(animValue: value),
            ),

            // Dark Vignette & Glassmorphism Blur
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.65),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Content Child
            widget.child,
          ],
        );
      },
    );
  }
}

class _LedGridPainter extends CustomPainter {
  final double animValue;

  _LedGridPainter({required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accentPrimary.withValues(alpha: 0.035)
      ..strokeWidth = 1.0;

    const double step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Moving Scanline Light Sweep
    final scanlineY = (animValue * size.height * 1.5) % size.height;
    final scanlinePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.accentPrimary.withValues(alpha: 0.08),
          Colors.cyanAccent.withValues(alpha: 0.12),
          AppColors.accentPrimary.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, scanlineY - 40, size.width, 80));

    canvas.drawRect(Rect.fromLTWH(0, scanlineY - 40, size.width, 80), scanlinePaint);
  }

  @override
  bool shouldRepaint(covariant _LedGridPainter oldDelegate) {
    return oldDelegate.animValue != animValue;
  }
}
