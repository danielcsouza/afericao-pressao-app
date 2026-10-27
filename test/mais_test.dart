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
  Config config = const Config(days: 7),
}) async {
  SharedPreferences.setMockInitialValues({});
  final storage = Storage(await SharedPreferences.getInstance());
  await tester.binding.setSurfaceSize(const Size(400, 3200));
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
      .finishSetup(name: 'Ana', start: '2026-03-01', config: config);
  c.read(selectedDayProvider.notifier).set(0);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ajustes'));
  await tester.pumpAndSettle();
  return c;
}

void main() {
  testWidgets('editar o nome grava normalizado', (tester) async {
    final c = await _pump(tester);
    await tester.enterText(find.byType(TextField), '  Maria   Silva ');
    await tester.pump();
    expect(c.read(notebookProvider).name, 'Maria Silva');
  });

  testWidgets('tema persiste e muda o themeMode', (tester) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();
    expect(c.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('lembretes: desligar esconde os horários', (tester) async {
    final c = await _pump(
      tester,
      config: const Config(days: 7, remindersOn: true),
    );
    expect(find.text('🌅 Manhã até'), findsOneWidget);
    await tester.tap(find.text('Não avisar'));
    await tester.pumpAndSettle();
    expect(c.read(notebookProvider).config.remindersOn, false);
    expect(find.text('🌅 Manhã até'), findsNothing);
  });

  testWidgets('ajustar caderno: braços, pulso e períodos (mín. 1)', (
    tester,
  ) async {
    final c = await _pump(tester);
    await tester.tap(find.text('Esquerdo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não anotar'));
    await tester.pumpAndSettle();
    var cfg = c.read(notebookProvider).config;
    expect(cfg.arms, ArmsMode.left);
    expect(cfg.pulse, false);

    // desliga tarde e noite; a manhã (último período) não desliga
    await tester.tap(find.text('☀️ Tarde'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌙 Noite'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🌅 Manhã'));
    await tester.pumpAndSettle();
    cfg = c.read(notebookProvider).config;
    expect(cfg.periods, [Period.m]);
  });

  testWidgets('mudar o caderno não apaga anotações', (tester) async {
    final c = await _pump(tester);
    c
        .read(notebookProvider.notifier)
        .setEntry(
          0,
          Period.t,
          const Entry(
            left: Reading(s: '12', d: '8'),
          ),
        );
    await tester.tap(find.text('☀️ Tarde')); // desliga a tarde
    await tester.pumpAndSettle();
    expect(c.read(notebookProvider).entry(0, Period.t).left.s, '12');
  });

  testWidgets('limpar período e apagar tudo pedem confirmação', (tester) async {
    final c = await _pump(tester);
    final n = c.read(notebookProvider.notifier);
    const e = Entry(
      left: Reading(s: '12', d: '8'),
    );
    n.setEntry(0, Period.m, e);
    n.setEntry(1, Period.t, e);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Limpar todos os registros da manhã'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(c.read(notebookProvider).entry(0, Period.m).left.done, true);

    await tester.tap(find.text('Limpar todos os registros da manhã'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpar'));
    await tester.pumpAndSettle();
    expect(c.read(notebookProvider).entry(0, Period.m).left.isEmpty, true);
    expect(c.read(notebookProvider).entry(1, Period.t).left.done, true);

    await tester.tap(find.text('Apagar tudo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apagar'));
    await tester.pumpAndSettle();
    final nb = c.read(notebookProvider);
    expect(nb.data, isEmpty);
    expect(nb.name, 'Ana');
    expect(nb.config.days, 7);
  });
}
