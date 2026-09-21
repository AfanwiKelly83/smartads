import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class RoleGuard extends StatelessWidget {
  final Set<String> allowedRoles;
  final Widget child;

  const RoleGuard({super.key, required this.allowedRoles, required this.child});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user != null && allowedRoles.contains(user.role)) {
      return child;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                color: AppTheme.accentLight,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Access restricted',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account does not have permission to view this page.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('GO BACK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RoleAccess {
  static const admin = <String>{'ADMIN'};
  static const advertiser = <String>{'ADVERTISER', 'USER'};
  static const billboardOwner = <String>{'BILLBOARD_OWNER', 'OWNER'};
  static const adminAndOwner = <String>{'ADMIN', 'BILLBOARD_OWNER', 'OWNER'};
  static const adminAndAdvertiser = <String>{'ADMIN', 'ADVERTISER', 'USER'};
  static const all = <String>{'ADMIN', 'ADVERTISER', 'USER', 'BILLBOARD_OWNER', 'OWNER'};

  static bool canAccess(User? user, Set<String> roles) {
    return user != null && roles.contains(user.role);
  }
}
