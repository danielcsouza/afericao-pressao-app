import 'package:diario_pressao/app/providers.dart';
import 'package:diario_pressao/data/storage.dart';
import 'package:diario_pressao/domain/models.dart';
import 'package:diario_pressao/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(WidgetTester tester) async {
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
  return ProviderScope.containerOf(tester.element(find.byType(DiarioApp)));
}

void main() {
  testWidgets('"Usar padrão" leva ao app com as abas', (tester) async {
    await _pump(tester);
    await tester.tap(find.text('Usar padrão'));
    await tester.pumpAndSettle();

    expect(find.text('Dia 1 de 30'), findsWidgets); // cabeçalho e aba Anotar
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.text('Diário da Pressão'), findsOneWidget);
  });

  testWidgets('wizard completo grava a configuração escolhida', (tester) async {
    final c = await _pump(tester);

    await tester.enterText(find.byType(TextField), '  Maria   Silva ');
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('7')); // duração
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Só o direito'));
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Não')); // pulso
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('${Period.t.icon} Tarde')); // desliga a tarde
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Não avisar'));
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Começar'));
    await tester.pumpAndSettle();

    final nb = c.read(notebookProvider);
    expect(nb.configured, true);
    expect(nb.name, 'Maria Silva');
    expect(nb.start, isNotEmpty);
    expect(nb.config.days, 7);
    expect(nb.config.arms, ArmsMode.right);
    expect(nb.config.pulse, false);
    expect(nb.config.periods, [Period.m, Period.n]);
    expect(nb.config.remindersOn, false);
    expect(find.text('Dia 1 de 7'), findsWidgets);
  });

  testWidgets('não deixa avançar sem nenhum período', (tester) async {
    await _pump(tester);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
    }
    for (final p in Period.values) {
      await tester.tap(find.text('${p.icon} ${p.label}'));
    }
    await tester.pump();
    final btn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Avançar'),
    );
    expect(btn.onPressed, isNull);
  });
}
