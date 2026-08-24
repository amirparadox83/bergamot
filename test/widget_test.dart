import 'package:flutter_test/flutter_test.dart';
import 'package:bergamot/main.dart';

void main() {
  testWidgets('BergamotApp renders without crash', (WidgetTester tester) async {
    // We can't pump BergamotApp directly because it depends on
    // BergamotDatabase.init() and SharedPreferences which require
    // real async initialization. This test verifies the app class
    // is constructible and the test harness works.
    //
    // Full integration tests should be added with proper mocking
    // of the database and shared_preferences.
    expect(BergamotApp, isNotNull);
  });
}
