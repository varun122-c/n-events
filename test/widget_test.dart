import 'package:flutter_test/flutter_test.dart';
import 'package:n_vents/main.dart';

void main() {
  testWidgets('App initialization test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    
    // Verify that the splash screen is built and contains the app title
    expect(find.text('N EVENTS'), findsOneWidget);
    
    // Pump and settle to let the splash timer complete
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
