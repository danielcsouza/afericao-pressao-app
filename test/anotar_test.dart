import 'package:diario_pressao/app/providers.dart';
import 'package:diario_pressao/data/storage.dart';
import 'package:diario_pressao/domain/models.dart';
import 'package:diario_pressao/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  Config config = const Config(),
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = Storage(await SharedPreferences.getInstance());
  await tester.binding.setSurfaceSize(const Size(400, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [storageProvider.overrideWithValue(storage)],
      child: const DiarioApp(),
    ),
  );
  final c = ProviderScope.containerOf(tester.element(find.byType(DiarioApp)));
  c
      .read(notebookProvider.notifier)
      .finishSetup(name: 'Maria Silva', start: '2026-03-01', config: config);
  // Sem isso o app abre no dia de hoje (limitado ao último dia), e os testes dependeriam da data.
  c.read(selectedDayProvider.notifier).set(0);
  await tester.pumpAndSettle();
  return c;
}

/// Campos na ordem da tela: esquerdo (s, d, p), direito (s, d, p), por cartão.
Finder get _fields => find.byType(TextField);

void main() {
  testWidgets('mostra saudação, dia e um cartão por período', (tester) async {
    await _pump(tester);
    expect(find.text('Olá, Maria! 👋'), findsOneWidget);
    expect(find.text('Dia 1 de 30'), findsWidgets);
    expect(find.text('Domingo, 1 de março'), findsOneWidget);
    expect(find.text('🌅 Manhã'), findsOneWidget);
    expect(find.text('☀️ Tarde'), findsOneWidget);
    expect(find.text('🌙 Noite'), findsOneWidget);
    expect(find.text('a fazer'), findsNWidgets(3));
  });

  testWidgets('digitar 13 e 8 grava 13/8, pula o foco e marca o braço', (
    tester,
  ) async {
    final c = await _pump(
      tester,
      config: const Config(periods: [Period.m], arms: ArmsMode.left),
    );
    await tester.enterText(_fields.at(0), '13');
    await tester.pump();
    await tester.enterText(_fields.at(1), '8');
    await tester.pumpAndSettle();

    final r = c.read(notebookProvider).entry(0, Period.m).left;
    expect((r.s, r.d), ('13', '8'));
    expect(find.text('✓ completo'), findsOneWidget);
  });

  testWidgets('formato do aparelho 12882 vira 128/82', (tester) async {
    final c = await _pump(
      tester,
      config: const Config(periods: [Period.m], arms: ArmsMode.left),
    );
    await tester.enterText(_fields.at(0), '12');
    await tester.pump();
    await tester.enterText(_fields.at(1), '882');
    await tester.pumpAndSettle();

    final r = c.read(notebookProvider).entry(0, Period.m).left;
    expect((r.s, r.d), ('128', '82'));
  });

  testWidgets('um braço só: "falta 1 braço" com os dois e braço pela metade', (
    tester,
  ) async {
    await _pump(tester, config: const Config(periods: [Period.m]));
    await tester.enterText(_fields.at(0), '120');
    await tester.enterText(_fields.at(1), '80');
    await tester.pumpAndSettle();
    expect(find.text('falta 1 braço'), findsOneWidget);
  });

  testWidgets('sem pulso não mostra o campo de pulso', (tester) async {
    await _pump(
      tester,
      config: const Config(
        periods: [Period.m],
        arms: ArmsMode.left,
        pulse: false,
      ),
    );
    expect(_fields, findsNWidgets(2));
    expect(find.text('Pulso'), findsNothing);
  });

  testWidgets('limpar registros pede confirmação e zera os campos', (
    tester,
  ) async {
    final c = await _pump(
      tester,
      config: const Config(periods: [Period.m], arms: ArmsMode.left),
    );
    await tester.enterText(_fields.at(0), '120');
    await tester.enterText(_fields.at(1), '80');
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Limpar registros da manhã'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();

    expect(c.read(notebookProvider).entry(0, Period.m).left.isEmpty, true);
    expect(tester.widget<TextField>(_fields.at(0)).controller!.text, '');
    expect(find.textContaining('Limpar registros'), findsNothing);
  });

  testWidgets('navega entre os dias e limites desabilitam os botões', (
    tester,
  ) async {
    await _pump(tester, config: const Config(days: 2));
    expect(find.text('Dia 1 de 2'), findsWidgets);
    await tester.tap(find.text('›'));
    await tester.pumpAndSettle();
    expect(find.text('Dia 2 de 2'), findsWidgets);
    expect(find.text('Segunda-feira, 2 de março'), findsOneWidget);
    await tester.tap(find.text('›')); // já no último: nada acontece
    await tester.pumpAndSettle();
    expect(find.text('Dia 2 de 2'), findsWidgets);
  });
}
