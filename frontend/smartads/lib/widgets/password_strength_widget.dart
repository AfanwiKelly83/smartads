import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PasswordStrengthWidget extends StatelessWidget {
  final String password;

  const PasswordStrengthWidget({
    super.key,
    required this.password,
  });

  double _calculateStrength(String value) {
    if (value.isEmpty) return 0.0;
    double score = 0.0;

    if (value.length >= 8) score += 0.3;
    if (value.contains(RegExp(r'[A-Z]'))) score += 0.2;
    if (value.contains(RegExp(r'[0-9]'))) score += 0.25;
    if (value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 0.25;

    return score.clamp(0.0, 1.0);
  }

  String _getStrengthText(double strength) {
    if (strength == 0.0) return '';
    if (strength <= 0.3) return 'Weak Password';
    if (strength <= 0.7) return 'Medium Strength';
    return 'Strong Password';
  }

  Color _getStrengthColor(double strength) {
    if (strength <= 0.3) return const Color(0xFFFF5252);
    if (strength <= 0.7) return const Color(0xFFFFB74D);
    return AppTheme.accentLight;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);
    if (password.isEmpty) return const SizedBox.shrink();

    final color = _getStrengthColor(strength);
    final text = _getStrengthText(strength);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${(strength * 100).toInt()}%',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: List.generate(4, (index) {
            final threshold = (index + 1) * 0.25;
            final isFilled = strength >= threshold;

            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: isFilled ? color : AppTheme.inputBg,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: isFilled && strength > 0.7
                      ? [
                          BoxShadow(
                            color: AppTheme.accentPrimary.withValues(alpha: 0.4),
                            blurRadius: 4,
                          ),
                        ]
                      : [],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
