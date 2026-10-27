import 'package:diario_pressao/app/providers.dart';
import 'package:diario_pressao/data/storage.dart';
import 'package:diario_pressao/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('"Outro": confirmar pelo teclado aplica o valor', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = Storage(await SharedPreferences.getInstance());
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(storage)],
        child: const DiarioApp(),
      ),
    );

    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '10');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Quantos dias?'), findsNothing);
    expect(find.text('10'), findsOneWidget); // o chip "Outro" passa a mostrar 10
    expect(tester.takeException(), isNull);
  });
}
