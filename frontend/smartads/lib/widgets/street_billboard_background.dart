import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StreetBillboardBackground extends StatelessWidget {
  final Widget child;

  const StreetBillboardBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Street Digital Billboard Background Image
        Image.network(
          'https://images.unsplash.com/photo-1542751371-adc38448a05e?q=80&w=1600&auto=format&fit=crop',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(color: AppTheme.bgDark),
        ),

        // Dark Electric Blue Overlay Gradient & Vignette
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.bgDark.withValues(alpha: 0.88),
                AppTheme.bgDark.withValues(alpha: 0.78),
                AppTheme.bgDark.withValues(alpha: 0.92),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        // Content
        child,
      ],
    );
  }
}
