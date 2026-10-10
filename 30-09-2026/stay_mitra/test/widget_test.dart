import 'package:flutter_test/flutter_test.dart';

import 'package:stay_mitra/main.dart';

void main() {
  testWidgets('Stay Mitra app loads successfully', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const StayMitraApp());

    // Verify that the Stay Mitra dashboard is displayed.
    expect(find.text('Stay Mitra Dashboard'), findsOneWidget);
    expect(find.text('Property Overview'), findsOneWidget);
    expect(find.text('Quick Actions'), findsOneWidget);
  });
}