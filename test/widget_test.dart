import 'package:flutter_test/flutter_test.dart';
import 'package:cam/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Ensure UI renders correctly
    expect(find.text("Getting location..."), findsOneWidget);

    // Simulate waiting for location update
    await tester.pump();
  });
}
