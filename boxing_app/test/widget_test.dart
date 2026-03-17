import 'package:flutter_test/flutter_test.dart';
import 'package:boxing_app/main.dart';

void main() {
  testWidgets('App loads with HOME screen', (WidgetTester tester) async {
    await tester.pumpWidget(const BoxingApp());
    expect(find.text('HOME'), findsWidgets);
  });
}
