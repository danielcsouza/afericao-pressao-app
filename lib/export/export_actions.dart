import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../ui/actions.dart';
import 'csv.dart';
import 'pdf_report.dart';

const _pdfName = 'diario-da-pressao.pdf';
const _csvName = 'diario-da-pressao.csv';

/// Imprimir a folha em branco ou com os valores já anotados. A folha com
/// valores só sai se nenhum registro estiver incompleto (a em branco, sempre).
Future<void> printSheet(
  BuildContext context,
  WidgetRef ref, {
  required bool filled,
}) async {
  if (filled && !await ensureNothingIncomplete(context, ref)) return;
  if (!context.mounted) return;
  await _run(context, () async {
    final nb = ref.read(notebookProvider);
    final pdf = await buildReportPdf(
      nb,
      filled ? ReportKind.printFilled : ReportKind.printBlank,
    );
    await ref.read(exportServiceProvider).printPdf(pdf, 'Diário da Pressão');
  });
}

/// PDF com as medições e a página de resumo, para compartilhar.
Future<void> exportPdf(BuildContext context, WidgetRef ref) async {
  if (!await ensureNothingIncomplete(context, ref)) return;
  if (!context.mounted) return;
  await _run(context, () async {
    final pdf = await buildReportPdf(
      ref.read(notebookProvider),
      ReportKind.pdf,
    );
    await ref
        .read(exportServiceProvider)
        .shareFile(pdf, filename: _pdfName, mimeType: 'application/pdf');
  });
}

/// Planilha CSV (`;`, UTF-8 com BOM para o Excel abrir com acentos).
Future<void> exportCsv(BuildContext context, WidgetRef ref) async {
  if (!await ensureNothingIncomplete(context, ref)) return;
  if (!context.mounted) return;
  await _run(context, () async {
    final csv = buildCsv(ref.read(notebookProvider));
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
    await ref
        .read(exportServiceProvider)
        .shareFile(bytes, filename: _csvName, mimeType: 'text/csv');
  });
}

Future<void> _run(BuildContext context, Future<void> Function() job) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await job();
  } catch (e) {
    debugPrint('Falha ao gerar o documento: $e');
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Não consegui gerar o arquivo. Tente de novo.'),
      ),
    );
  }
}
