import 'package:flutter_test/flutter_test.dart';
import 'package:staynest_mobile/main.dart';

void main() {
  testWidgets('App launches', (tester) async {
    await tester.pumpWidget(const StayNestApp());
    expect(find.text('COMPONENT GALLERY'), findsOneWidget);
  });
}
