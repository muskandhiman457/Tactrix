import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('App compiles and loads login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SportsHubApp());

    // Verify that login screen widgets are present.
    expect(find.text('SIGN IN'), findsOneWidget);
  });
}
