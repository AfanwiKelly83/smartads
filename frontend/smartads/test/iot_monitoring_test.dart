import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartads/models/user.dart';
import 'package:smartads/screens/admin/admin_iot_monitoring_screen.dart';
import 'package:smartads/screens/analytics_iot_screen.dart';
import 'package:smartads/services/auth_service.dart';

void main() {
  setUp(() {
    AuthService().currentUser = User(
      userId: 1,
      fullName: 'Admin Tester',
      email: 'admin@smartads.com',
      role: 'ADMIN',
    );
  });

  group('IoT Monitoring & Analytics Flutter Tests', () {
    testWidgets('AdminIotMonitoringScreen renders ESP32 devices and telemetry stats', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AdminIotMonitoringScreen(enablePeriodicUpdates: false),
        ),
      );

      // Verify Screen Title and Header
      expect(find.text('IoT Monitoring Panel'), findsOneWidget);
      expect(find.text('ESP32 / RASPBERRY PI DEVICE STATUS'), findsOneWidget);

      // Verify Device IDs
      expect(find.text('ESP32-NODE-A1'), findsOneWidget);
      expect(find.text('ESP32-NODE-B2'), findsOneWidget);
      expect(find.text('ESP32-NODE-C3'), findsOneWidget);

      // Verify Locations & Status Badges
      expect(find.text('Downtown Plaza'), findsOneWidget);
      expect(find.text('Highway 42'), findsOneWidget);
      expect(find.text('Mall Entrance'), findsOneWidget);
      expect(find.text('ONLINE'), findsNWidgets(2));
      expect(find.text('OFFLINE'), findsOneWidget);

      // Cleanly unmount to dispose periodic timer
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('AnalyticsIotScreen renders hardware stat cards and telemetry overview', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AnalyticsIotScreen(),
        ),
      );

      await tester.pump();

      // Verify Header & Subtitles
      expect(find.text('IoT Device Monitoring & Analytics'), findsOneWidget);
      expect(
        find.textContaining('Real-time billboard display hardware heartbeats'),
        findsOneWidget,
      );

      // Verify Telemetry Stat Cards
      expect(find.text('CONNECTED IOT HARDWARE'), findsOneWidget);
      expect(find.text('AVG HARDWARE TEMP'), findsOneWidget);
      expect(find.text('DAILY VERIFIED PLAYBACKS'), findsOneWidget);
    });

    testWidgets('AnalyticsIotScreen restricts access for non-admin roles', (
      WidgetTester tester,
    ) async {
      // Set unprivileged role
      AuthService().currentUser = User(
        userId: 2,
        fullName: 'Advertiser Tester',
        email: 'advertiser@smartads.com',
        role: 'ADVERTISER',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AnalyticsIotScreen(),
        ),
      );

      await tester.pump();

      // Verify Access Restricted message is displayed
      expect(find.text('Access restricted'), findsOneWidget);
      expect(
        find.text('Your account does not have permission to view this page.'),
        findsOneWidget,
      );
    });
  });
}
