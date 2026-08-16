import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fanta_app/main.dart';

void main() {
  testWidgets('Home screen mostra le voci principali', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantaApp()));
    await tester.pumpAndSettle();

    expect(find.text('Fanta-App'), findsOneWidget);
    expect(find.text('Listone'), findsOneWidget);
    expect(find.text('La mia squadra'), findsOneWidget);
  });
}
