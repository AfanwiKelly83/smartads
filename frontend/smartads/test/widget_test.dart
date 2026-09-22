import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smartads/screens/auth_page.dart';
import 'package:smartads/screens/landing_screen.dart';
import 'package:smartads/widgets/time_slot_picker.dart';

void main() {
  testWidgets('SmartAds landing page opens login and registration', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: LandingScreen()));

    expect(find.text('SMARTADS'), findsWidgets);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('I Already Have an Account'), findsOneWidget);

    await tester.tap(find.text('I Already Have an Account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);

    Navigator.of(tester.element(find.byType(AuthPage))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get Started'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(find.byType(AuthPage), findsOneWidget);
    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
  });

  testWidgets('time slot picker selects an available slot', (
    WidgetTester tester,
  ) async {
    String? selectedSlot;

    await tester.pumpWidget(
      MaterialApp(
        home: TimeSlotPickerModal(
          billboardName: 'Test Billboard',
          hourlyRate: 1000,
          onSlotSelected: (slot, duration, price) => selectedSlot = slot,
        ),
      ),
    );

    expect(find.text('08:00 AM - 10:00 AM'), findsOneWidget);
    await tester.ensureVisible(find.text('08:00 AM - 10:00 AM'));
    await tester.tap(find.text('08:00 AM - 10:00 AM'));
    await tester.pump();
    await tester.ensureVisible(find.text('CONFIRM TIME SLOT'));
    await tester.tap(find.text('CONFIRM TIME SLOT'));
    await tester.pump();

    expect(selectedSlot, '08:00 AM - 10:00 AM');
  });

  testWidgets('time slot picker handles no available slots', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TimeSlotPickerModal(
          billboardName: 'Empty Billboard',
          hourlyRate: 1000,
          availableTimeSlots: const [],
          onSlotSelected: (slot, duration, price) {},
        ),
      ),
    );

    expect(find.text('No available time slots.'), findsOneWidget);
    expect(find.text('CONFIRM TIME SLOT'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton).last).onPressed,
      isNull,
    );
  });

  testWidgets('time slot picker handles all slots occupied', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: TimeSlotPickerModal(
          billboardName: 'Occupied Billboard',
          hourlyRate: 1000,
          availableTimeSlots: const [
            {
              'time': '08:00 AM - 10:00 AM',
              'isFree': false,
              'occupant': 'Reserved',
            },
          ],
          onSlotSelected: (slot, duration, price) {},
        ),
      ),
    );

    expect(find.text('No available time slots.'), findsOneWidget);
  });
}
