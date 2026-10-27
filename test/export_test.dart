import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:diario_pressao/app/providers.dart';
import 'package:diario_pressao/data/storage.dart';
import 'package:diario_pressao/domain/models.dart';
import 'package:diario_pressao/export/csv.dart';
import 'package:diario_pressao/export/export_service.dart';
import 'package:diario_pressao/export/pdf_report.dart';
import 'package:diario_pressao/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Notebook _nb({Config config = const Config(), String name = 'Maria Silva'}) {
  return Notebook(
    name: name,
    start: '2026-03-01',
    configured: true,
    config: config,
    data: {
      0: {
        Period.m: const Entry(
          time: '08:00',
          left: Reading(s: '13', d: '8', p: '70'),
          right: Reading(s: '12', d: '8'),
        ),
      },
      2: {Period.n: const Entry(left: Reading(s: '128', d: '82', p: '64'))},
    },
  );
}

int _pages(dynamic doc) => doc.document.pdfPageList.pages.length as int;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CSV', () {
    test('configuração padrão: mesmas colunas e valores do app web', () {
      expect(
        buildCsv(_nb()),
        [
          'Dia;Data;Período;Hora;Braço;Alta;Baixa;Pulso;Alta (mmHg);Baixa (mmHg)',
          '1;01/03/2026;Manhã;08:00;Esquerdo;13;8;70;130;80',
          '1;01/03/2026;Manhã;08:00;Direito;12;8;;120;80',
          '3;03/03/2026;Noite;;Esquerdo;128;82;64;128;82',
        ].join('\r\n'),
      );
    });

    test('um braço e sem pulso: somem as colunas Braço e Pulso', () {
      final csv = buildCsv(
        _nb(config: const Config(arms: ArmsMode.left, pulse: false)),
      );
      expect(
        csv.split('\r\n'),
        [
          'Dia;Data;Período;Hora;Alta;Baixa;Alta (mmHg);Baixa (mmHg)',
          '1;01/03/2026;Manhã;08:00;13;8;130;80',
          '3;03/03/2026;Noite;;128;82;128;82',
        ],
      );
    });

    test('período desativado e caderno vazio', () {
      final csv = buildCsv(_nb(config: const Config(periods: [Period.t])));
      expect(csv.split('\r\n').length, 1); // só o cabeçalho
    });

    test('só pulso preenchido conta como linha (com pulso ligado)', () {
      final nb = Notebook(
        start: '2026-03-01',
        data: {
          0: {Period.m: const Entry(left: Reading(p: '70'))},
        },
      );
      expect(buildCsv(nb).split('\r\n').length, 2);
      final off = nb.copyWith(config: const Config(pulse: false));
      expect(buildCsv(off).split('\r\n').length, 1);
    });
  });

  group('PDF', () {
    test('15 dias por folha; só o PDF tem página de resumo', () async {
      Future<int> pages(int days, ReportKind k) async => _pages(
        await buildReportDocument(_nb(config: Config(days: days)), k),
      );
      expect(await pages(30, ReportKind.pdf), 3);
      expect(await pages(30, ReportKind.printBlank), 2);
      expect(await pages(30, ReportKind.printFilled), 2);
      expect(await pages(7, ReportKind.pdf), 2);
      expect(await pages(15, ReportKind.printBlank), 1);
      expect(await pages(16, ReportKind.printBlank), 2);
      expect(await pages(365, ReportKind.pdf), 25 + 1);
    });

    test('gera arquivo PDF válido em todas as combinações', () async {
      for (final arms in ArmsMode.values) {
        for (final pulse in [true, false]) {
          for (final periods in [
            Period.values,
            [Period.t],
            [Period.m, Period.n],
          ]) {
            for (final kind in ReportKind.values) {
              final bytes = await buildReportPdf(
                _nb(
                  config: Config(
                    days: 20,
                    arms: arms,
                    pulse: pulse,
                    periods: periods,
                  ),
                ),
                kind,
                now: DateTime(2026, 3, 10),
              );
              expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
              expect(bytes.length, greaterThan(2000));
            }
          }
        }
      }
    });

    test('sem nome nem data de início também gera', () async {
      final bytes = await buildReportPdf(const Notebook(), ReportKind.printBlank);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('amostra para conferência visual', () async {
      final dir = Directory(
        Platform.environment['PDF_SAMPLE_DIR'] ?? '',
      );
      if (dir.path.isEmpty) return;
      for (final k in ReportKind.values) {
        final bytes = await buildReportPdf(
          _nb(config: const Config(days: 30)),
          k,
          now: DateTime(2026, 3, 10),
        );
        await File('${dir.path}/${k.name}.pdf').writeAsBytes(bytes);
      }
    });
  });

  group('botões em Mais', () {
    testWidgets('imprimir e exportar chamam o serviço com o arquivo certo', (
      tester,
    ) async {
      final svc = _FakeExport();
      SharedPreferences.setMockInitialValues({});
      final storage = Storage(await SharedPreferences.getInstance());
      await tester.binding.setSurfaceSize(const Size(400, 4200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageProvider.overrideWithValue(storage),
            exportServiceProvider.overrideWithValue(svc),
          ],
          child: const DiarioApp(),
        ),
      );
      final c = ProviderScope.containerOf(
        tester.element(find.byType(DiarioApp)),
      );
      c.read(notebookProvider.notifier).finishSetup(
        name: 'Ana',
        start: '2026-03-01',
        config: const Config(days: 7),
      );
      c.read(notebookProvider.notifier).setEntry(
        0,
        Period.m,
        const Entry(left: Reading(s: '13', d: '8')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(find.text('Folha em branco, para escrever à mão'));
        await Future<void>.delayed(const Duration(seconds: 2));
      });
      expect(svc.printed.length, 1);

      await tester.runAsync(() async {
        await tester.tap(find.text('Folha com os valores já anotados'));
        await Future<void>.delayed(const Duration(seconds: 2));
        await tester.tap(find.text('PDF com as medições'));
        await Future<void>.delayed(const Duration(seconds: 2));
        await tester.tap(find.text('Planilha (CSV, abre no Excel)'));
        await Future<void>.delayed(const Duration(seconds: 1));
      });
      expect(svc.printed.length, 2);
      expect(svc.shared.map((s) => s.$1), ['diario-da-pressao.pdf', 'diario-da-pressao.csv']);
      expect(svc.shared[0].$2, 'application/pdf');

      final csv = svc.shared[1].$3;
      expect(csv.take(3), [0xEF, 0xBB, 0xBF]); // BOM UTF-8
      final text = utf8.decode(csv.skip(3).toList());
      expect(text, contains('Dia;Data;Período'));
      expect(text, contains('1;01/03/2026;Manhã'));
    });
  });
}

class _FakeExport implements ExportService {
  final printed = <Uint8List>[];
  final shared = <(String, String, Uint8List)>[];

  @override
  Future<void> printPdf(Uint8List pdf, String name) async => printed.add(pdf);

  @override
  Future<void> shareFile(
    Uint8List bytes, {
    required String filename,
    required String mimeType,
  }) async => shared.add((filename, mimeType, bytes));
}
