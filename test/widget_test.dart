import 'package:flutter_test/flutter_test.dart';
import 'package:wholesale_desk/main.dart';

void main() {
  testWidgets('WholesaleDesk smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WholesaleDeskApp());
    expect(find.byType(WholesaleDeskApp), findsOneWidget);
  });
}
