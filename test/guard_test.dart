import 'dart:typed_data';

import 'package:diario_pressao/app/providers.dart';
import 'package:diario_pressao/data/storage.dart';
import 'package:diario_pressao/domain/models.dart';
import 'package:diario_pressao/domain/rules.dart';
import 'package:diario_pressao/export/export_service.dart';
import 'package:diario_pressao/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _one = Config(days: 3, periods: [Period.m], arms: ArmsMode.left);

class _FakeExport implements ExportService {
  int calls = 0;

  @override
  Future<void> printPdf(Uint8List pdf, String name) async => calls++;

  @override
  Future<void> shareFile(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async => calls++;
}

Future<(ProviderContainer, _FakeExport)> _pump(
  WidgetTester tester, {
  Config config = _one,
}) async {
  final export = _FakeExport();
  SharedPreferences.setMockInitialValues({});
  final storage = Storage(await SharedPreferences.getInstance());
  await tester.binding.setSurfaceSize(const Size(400, 3200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(storage),
        exportServiceProvider.overrideWithValue(export),
        // "Hoje" é o dia 1 do caderno, 09:30.
        clockProvider.overrideWithValue(() => DateTime(2026, 3, 1, 9, 30)),
      ],
      child: const DiarioApp(),
    ),
  );
  final c = ProviderScope.containerOf(tester.element(find.byType(DiarioApp)));
  c
      .read(notebookProvider.notifier)
      .finishSetup(name: 'Ana', start: '2026-03-01', config: config);
  c.read(selectedDayProvider.notifier).set(0);
  await tester.pumpAndSettle();
  return (c, export);
}

Finder get _fields => find.byType(TextField);

Future<void> _type(WidgetTester tester, int field, String text) async {
  await tester.enterText(_fields.at(field), text);
  await tester.pump();
}

void main() {
  group('regra de domínio', () {
    Notebook nb(Entry? e, {Config config = _one}) => Notebook(
      start: '2026-03-01',
      config: config,
      data: {
        if (e != null) 0: {Period.m: e},
      },
    );

    test('período vazio é sempre válido', () {
      expect(Rules(nb(null)).incompleteReason(0, Period.m), isNull);
      expect(Rules(nb(const Entry())).incompleteReason(0, Period.m), isNull);
      expect(Rules(nb(null)).incompleteEntries(), isEmpty);
    });

    test('começado: exige hora e, em cada braço usado, alta e baixa', () {
      const full = Reading(s: '13', d: '8');
      Incomplete? r(Entry e, {Config config = _one}) =>
          Rules(nb(e, config: config)).incompleteReason(0, Period.m);

      expect(r(const Entry(time: '08:00', left: full)), isNull);
      expect(r(const Entry(left: full)), Incomplete.missingTime);
      expect(
        r(
          const Entry(
            time: '08:00',
            left: Reading(s: '13'),
          ),
        ),
        Incomplete.halfReading,
      );
      expect(r(const Entry(time: '08:00')), Incomplete.timeWithoutValues);
      // pulso sozinho conta como valor começado e não basta
      expect(
        r(
          const Entry(
            time: '08:00',
            left: Reading(p: '70'),
          ),
        ),
        Incomplete.halfReading,
      );
      // dois braços: um completo e o outro pela metade ainda é incompleto
      expect(
        r(
          const Entry(
            time: '08:00',
            left: full,
            right: Reading(s: '12'),
          ),
          config: const Config(days: 3, periods: [Period.m]),
        ),
        Incomplete.halfReading,
      );
      // um braço completo basta; o outro vazio é permitido
      expect(
        r(
          const Entry(time: '08:00', left: full),
          config: const Config(days: 3, periods: [Period.m]),
        ),
        isNull,
      );
      // dado de braço desativado não conta
      expect(
        r(
          const Entry(
            time: '08:00',
            left: full,
            right: Reading(s: '12'),
          ),
        ),
        isNull,
      );
    });
  });

  group('navegação', () {
    testWidgets('navegar entre os dias sem digitar nada é livre', (
      tester,
    ) async {
      final (c, _) = await _pump(tester);
      await tester.tap(find.text('›'));
      await tester.pumpAndSettle();
      expect(c.read(selectedDayProvider), 1);
      await tester.tap(find.text('›'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('‹'));
      await tester.pumpAndSettle();
      expect(c.read(selectedDayProvider), 1);
      expect(find.text('Registro incompleto'), findsNothing);
      await tester.tap(find.text('Agenda'));
      await tester.pumpAndSettle();
      expect(c.read(tabProvider), 1);
    });

    testWidgets('só olhar: registro antigo incompleto não prende ninguém', (
      tester,
    ) async {
      final (c, _) = await _pump(tester);
      // veio de antes (não foi editado nesta visita) e está sem hora
      c
          .read(notebookProvider.notifier)
          .setEntry(
            0,
            Period.m,
            const Entry(
              left: Reading(s: '13', d: '8'),
            ),
          );
      await tester.pumpAndSettle();
      await tester.tap(find.text('›'));
      await tester.pumpAndSettle();
      expect(c.read(selectedDayProvider), 1);
      expect(find.text('Registro incompleto'), findsNothing);
    });

    testWidgets('hoje: a hora é sugerida, então 13 e 8 deixam sair', (
      tester,
    ) async {
      final (c, _) = await _pump(tester);
      await _type(tester, 0, '13');
      await _type(tester, 1, '8');
      await tester.tap(find.text('›'));
      await tester.pumpAndSettle();
      expect(find.text('Registro incompleto'), findsNothing);
      expect(c.read(selectedDayProvider), 1);
    });

    testWidgets('digitou e ficou sem hora: não deixa sair do dia', (
      tester,
    ) async {
      final (c, _) = await _pump(tester);
      await tester.tap(find.text('›')); // dia 2: não é hoje, sem hora sugerida
      await tester.pumpAndSettle();
      await _type(tester, 0, '13');
      await _type(tester, 1, '8');

      await tester.tap(find.text('›'));
      await tester.pumpAndSettle();
      expect(find.text('Registro incompleto'), findsOneWidget);
      expect(find.textContaining('hora da manhã'), findsOneWidget);
      expect(c.read(selectedDayProvider), 1); // continua no mesmo dia

      // "Completar" volta para o dia, sem apagar nada
      await tester.tap(find.text('Completar'));
      await tester.pumpAndSettle();
      expect(c.read(selectedDayProvider), 1);
      expect(c.read(notebookProvider).entry(1, Period.m).left.s, '13');

      // aba também é barrada
      await tester.tap(find.text('Agenda'));
      await tester.pumpAndSettle();
      expect(find.text('Registro incompleto'), findsOneWidget);
      expect(c.read(tabProvider), 0);
      await tester.tap(find.text('Completar'));
      await tester.pumpAndSettle();

      // informando a hora, passa
      c
          .read(notebookProvider.notifier)
          .setEntry(
            1,
            Period.m,
            c.read(notebookProvider).entry(1, Period.m).withTime('08:10'),
          );
      await tester.pumpAndSettle();
      await tester.tap(find.text('›'));
      await tester.pumpAndSettle();
      expect(c.read(selectedDayProvider), 2);
    });

    testWidgets('alta sem baixa também barra, e dá para apagar o registro', (
      tester,
    ) async {
      final (c, _) = await _pump(tester);
      await _type(tester, 0, '13'); // hoje: hora sugerida; falta a baixa
      await tester.tap(find.text('›'));
      await tester.pumpAndSettle();
      expect(find.text('Registro incompleto'), findsOneWidget);
      expect(find.textContaining('alta ou a baixa'), findsOneWidget);
      expect(c.read(selectedDayProvider), 0);

      await tester.tap(find.text('Apagar o registro da manhã'));
      await tester.pumpAndSettle();
      expect(c.read(notebookProvider).entry(0, Period.m).left.isEmpty, isTrue);
      expect(c.read(notebookProvider).entry(0, Period.m).time, '');
    });

    testWidgets('o botão voltar também pede para completar', (tester) async {
      final (c, _) = await _pump(tester);
      await _type(tester, 0, '13');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Registro incompleto'), findsOneWidget);
      await tester.tap(find.text('Completar'));
      await tester.pumpAndSettle();
      expect(c.read(notebookProvider).entry(0, Period.m).left.s, '13');
    });
  });

  group('compartilhar e imprimir', () {
    Future<void> openAjustes(WidgetTester tester) async {
      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
    }

    testWidgets('registro incompleto em qualquer dia bloqueia o documento', (
      tester,
    ) async {
      final (c, export) = await _pump(tester);
      c
          .read(notebookProvider.notifier)
          .setEntry(
            2,
            Period.m,
            const Entry(
              left: Reading(s: '13', d: '8'),
            ), // dia 3, sem hora
          );
      await openAjustes(tester);

      await tester.tap(find.text('PDF com as medições'));
      await tester.pumpAndSettle();
      expect(find.text('Há registros incompletos'), findsOneWidget);
      expect(find.textContaining('Dia 3, manhã'), findsOneWidget);
      expect(export.calls, 0);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Planilha (CSV, abre no Excel)'));
      await tester.pumpAndSettle();
      expect(find.text('Há registros incompletos'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Folha com os valores já anotados'));
      await tester.pumpAndSettle();
      expect(find.text('Há registros incompletos'), findsOneWidget);
      expect(export.calls, 0);

      // "Ir para o dia" leva direto ao registro a corrigir
      await tester.tap(find.text('Ir para o dia 3'));
      await tester.pumpAndSettle();
      expect(c.read(selectedDayProvider), 2);
      expect(c.read(tabProvider), 0);
    });

    testWidgets('a folha em branco sai mesmo com registro incompleto', (
      tester,
    ) async {
      final (c, export) = await _pump(tester);
      c
          .read(notebookProvider.notifier)
          .setEntry(
            2,
            Period.m,
            const Entry(
              left: Reading(s: '13', d: '8'),
            ),
          );
      await openAjustes(tester);
      await tester.runAsync(() async {
        await tester.tap(find.text('Folha em branco, para escrever à mão'));
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      expect(find.text('Há registros incompletos'), findsNothing);
      expect(export.calls, 1);
    });
  });
}
