import 'package:flutter_test/flutter_test.dart';

import 'package:peg_solitaire/main.dart';

void main() {
  testWidgets('renders game shell with toss/reset controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PegSolitaireApp());

    expect(find.text('Peg Solitaire'), findsOneWidget);
    expect(find.text('Reset Board'), findsOneWidget);
    expect(find.text('Toss'), findsAtLeastNWidgets(1));
  });
}
