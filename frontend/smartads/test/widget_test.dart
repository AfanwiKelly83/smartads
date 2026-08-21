import 'package:flutter_test/flutter_test.dart';
import 'package:smartads/main.dart';

void main() {
  testWidgets('SmartAds Auth Page loads correctly', (WidgetTester tester) async {
    // Build SmartAds app and trigger a frame.
    await tester.pumpWidget(const SmartAdsApp());

    // Verify that SmartAds branding title and Login form elements appear.
    expect(find.text('SmartAds'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
