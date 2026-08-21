import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/auth_page.dart';

void main() {
  runApp(const SmartAdsApp());
}

class SmartAdsApp extends StatelessWidget {
  const SmartAdsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartAds Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthPage(),
    );
  }
}

// Alias for backwards compatibility with default tests
typedef MyApp = SmartAdsApp;
