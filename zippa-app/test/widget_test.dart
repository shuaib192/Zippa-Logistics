// Basic widget test for Zippa App
import 'package:flutter_test/flutter_test.dart';
import 'package:zippa_app/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ZippaApp());
    // Verify the app renders without crashing
    expect(find.byType(ZippaApp), findsOneWidget);
  });
}
