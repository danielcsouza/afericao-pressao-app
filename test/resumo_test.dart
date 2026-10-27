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
  await tester.binding.setSurfaceSize(const Size(400, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [storageProvider.overrideWithValue(storage)],
      child: const DiarioApp(),
    ),
  );
  final c = ProviderScope.containerOf(tester.element(find.byType(DiarioApp)));
  final n = c.read(notebookProvider.notifier);
  n.finishSetup(name: 'Ana', start: '2026-03-01', config: config);
  c.read(selectedDayProvider.notifier).set(0);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Agenda'));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('início, término e progresso do caderno vazio', (tester) async {
    await _pump(tester, config: const Config(days: 7));
    expect(find.text('01/03/2026'), findsWidgets);
    expect(
      find.textContaining('Termina em 07/03/2026.'),
      findsOneWidget,
    ); // fim = início + 6
    expect(
      find.text(
        '0 de 42 medições feitas (3 por dia: manhã, tarde e noite × 2 braços)',
      ),
      findsOneWidget,
    );
    expect(find.text('Os 7 dias'), findsOneWidget);
    expect(find.text('Médias até agora'), findsOneWidget);
  });

  testWidgets('texto do progresso reflete a configuração', (tester) async {
    await _pump(
      tester,
      config: const Config(
        days: 7,
        periods: [Period.m, Period.t],
        arms: ArmsMode.left,
      ),
    );
    expect(
      find.text('0 de 14 medições feitas (2 por dia: manhã e tarde × 1 braço)'),
      findsOneWidget,
    );
  });

  testWidgets('médias e diferença entre braços com dados', (tester) async {
    final c = await _pump(tester, config: const Config(days: 7));
    final n = c.read(notebookProvider.notifier);
    n.setEntry(
      0,
      Period.m,
      const Entry(
        left: Reading(s: '13', d: '8', p: '70'),
        right: Reading(s: '12', d: '8', p: '72'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('13,0 / 8,0'), findsOneWidget);
    expect(find.text('12,0 / 8,0'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    expect(
      find.textContaining('em 1 horários com os dois braços'),
      findsOneWidget,
    );
    expect(find.text('2 de 42 medições feitas'), findsNothing);
    expect(find.textContaining('2 de 42'), findsOneWidget);
  });

  testWidgets('sem pulso some a coluna e um braço some a diferença', (
    tester,
  ) async {
    await _pump(
      tester,
      config: const Config(days: 7, pulse: false, arms: ArmsMode.right),
    );
    expect(find.text('Pulso'), findsNothing);
    expect(find.textContaining('Diferença média'), findsNothing);
    expect(find.text('● Esquerdo'), findsNothing);
    expect(find.text('● Direito'), findsOneWidget);
  });

  testWidgets('tocar num dia abre o dia na aba Anotar', (tester) async {
    final c = await _pump(tester, config: const Config(days: 7));
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    expect(c.read(selectedDayProvider), 2);
    expect(c.read(tabProvider), 0);
  });

  testWidgets('reduzir abaixo do último dia com dado pede confirmação', (
    tester,
  ) async {
    final c = await _pump(tester, config: const Config(days: 30));
    c
        .read(notebookProvider.notifier)
        .setEntry(
          19,
          Period.m,
          const Entry(
            left: Reading(s: '12', d: '8'),
          ),
        );
    await tester.pumpAndSettle();

    await tester.tap(find.text('7').first);
    await tester.pumpAndSettle();
    expect(find.text('Reduzir para 7 dias?'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(c.read(notebookProvider).config.days, 30);

    await tester.tap(find.text('7').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reduzir'));
    await tester.pumpAndSettle();
    final nb = c.read(notebookProvider);
    expect(nb.config.days, 7);
    expect(nb.entry(19, Period.m).left.s, '12'); // dados preservados
  });
}
