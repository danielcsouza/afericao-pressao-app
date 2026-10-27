import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/rules.dart';

/// Três versões do mesmo layout (A4 paisagem, até 15 dias por folha).
enum ReportKind {
  /// Para imprimir e escrever à mão: sem valores, com linhas a preencher.
  printBlank,

  /// Para imprimir com o que já foi anotado.
  printFilled,

  /// Para exportar/compartilhar: valores + página de resumo + "Gerado em".
  pdf;

  bool get filled => this != printBlank;
  bool get summary => this == pdf;
}

/// Dias por folha.
const daysPerSheet = 15;

const _mm = PdfPageFormat.mm;
final _red = PdfColor.fromInt(0xffc0392b);
final _gray = PdfColor.fromInt(0xff595959);
final _lightGray = PdfColor.fromInt(0xff808080);
final _line = PdfColor.fromInt(0xff333333);
final _headFill = PdfColor.fromInt(0xffeeeeee);
final _periodFill = PdfColor.fromInt(0xffdddddd);
final _sideFill = PdfColor.fromInt(0xfff6f6f6);

const _thin = 0.6;
const _thick = 1.8;

final _full = DateFormat('dd/MM/yyyy');
final _short = DateFormat('dd/MM');

Future<Uint8List> buildReportPdf(
  Notebook nb,
  ReportKind kind, {
  DateTime? now,
}) async => (await buildReportDocument(nb, kind, now: now)).save();

Future<pw.Document> buildReportDocument(
  Notebook nb,
  ReportKind kind, {
  DateTime? now,
}) async {
  final regular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
  final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));
  final doc = pw.Document(
    title: 'Diário da Pressão',
    theme: pw.ThemeData.withFont(base: regular, bold: bold),
  );
  final format = PdfPageFormat.a4.landscape;
  final margin = kind == ReportKind.pdf
      ? const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 22)
      : const pw.EdgeInsets.all(8 * _mm);
  final generatedAt = now ?? DateTime.now();

  final days = nb.config.days;
  for (var from = 0; from < days; from += daysPerSheet) {
    final to = from + daysPerSheet < days ? from + daysPerSheet : days;
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: margin,
        build: (_) => _sheet(nb, kind, from, to, generatedAt),
      ),
    );
  }
  if (kind.summary) {
    doc.addPage(
      pw.Page(
        pageFormat: format,
        margin: margin,
        build: (_) => _summary(nb, generatedAt),
      ),
    );
  }
  return doc;
}

// ---------------------------------------------------------------- folha

pw.Widget _sheet(Notebook nb, ReportKind kind, int from, int to, DateTime now) {
  final cfg = nb.config;
  final start = parseIso(nb.start);
  final name = nb.name;
  final blank = !kind.filled;

  final title = 'Registro de pressão arterial — dias ${from + 1} a $to';

  final meta = <String>[
    'Nome: ${name.isEmpty ? '______________________________' : name}',
    'Início: ${start != null ? _full.format(start) : '____/____/________'}',
    if (kind != ReportKind.pdf) 'Aparelho: ______________________',
  ];

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        title,
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: _red),
      ),
      pw.SizedBox(height: 4),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [for (final m in meta) pw.Text(m, style: const pw.TextStyle(fontSize: 10))],
      ),
      pw.SizedBox(height: 4),
      pw.Text(_legend(cfg), style: pw.TextStyle(fontSize: 8.5, color: _gray)),
      pw.SizedBox(height: 6),
      _table(nb, kind, from, to, blank),
      pw.Spacer(),
      if (name.isNotEmpty)
        pw.Text(
          'Nome do paciente: $name',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      if (kind == ReportKind.pdf)
        pw.Text(
          'Gerado em ${_full.format(now)} pelo app Diário da Pressão',
          style: pw.TextStyle(fontSize: 7, color: _lightGray),
        ),
    ],
  );
}

/// Legenda que acompanha a configuração (períodos, braços, pulso).
String _legend(Config cfg) {
  final periods = cfg.periods.map((p) => p.label.toLowerCase()).toList();
  final list = periods.length == 1
      ? periods.first
      : '${periods.sublist(0, periods.length - 1).join(', ')} e ${periods.last}';
  final times = periods.length == 1 ? '1 vez' : '${periods.length} vezes';
  final arms = switch (cfg.arms) {
    ArmsMode.both => 'nos dois braços',
    ArmsMode.left => 'no braço esquerdo',
    ArmsMode.right => 'no braço direito',
  };
  return 'Pressão: escreva alta/baixa, como 13/8 (alta = sistólica, baixa = '
      'diastólica). Hora: horário da medição. '
      '${cfg.pulse ? 'Pulso: batimentos por minuto (opcional). ' : ''}'
      'Medir $times ao dia — $list — $arms, com a pessoa sentada e em repouso.';
}

pw.Widget _table(Notebook nb, ReportKind kind, int from, int to, bool blank) {
  final cfg = nb.config;
  final rowH = kind == ReportKind.pdf ? 26.0 : 9.5 * _mm;
  const headH = 14.0;
  const dayW = 8 * _mm;
  const dateW = 14 * _mm;
  const horaW = 13 * _mm;
  const pressW = 22 * _mm;
  const pulseW = 14 * _mm;

  final arms = cfg.activeArms;
  final armW = pressW + (cfg.pulse ? pulseW : 0);
  final blockW = horaW + arms.length * armW;
  final lastBlock = cfg.periods.length - 1;

  pw.Widget cell(
    double w,
    double h,
    String text, {
    bool bold = false,
    double size = 9,
    PdfColor? fill,
    bool thickRight = false,
  }) => pw.Container(
    width: w,
    height: h,
    alignment: pw.Alignment.center,
    decoration: pw.BoxDecoration(
      color: fill,
      border: pw.Border(
        right: pw.BorderSide(width: thickRight ? _thick : _thin, color: _line),
        bottom: pw.BorderSide(width: _thin, color: _line),
      ),
    ),
    child: text.isEmpty
        ? null
        : pw.Text(
            text,
            style: pw.TextStyle(
              fontSize: size,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
  );

  // Cabeçalho em 3 níveis: período → braço → Pressão/Pulso.
  final header = pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      cell(dayW, headH * 3, 'Dia', bold: true, fill: _headFill),
      cell(dateW, headH * 3, 'Data', bold: true, fill: _headFill),
      for (var pi = 0; pi < cfg.periods.length; pi++)
        pw.Column(
          children: [
            cell(
              blockW,
              headH,
              cfg.periods[pi].label,
              bold: true,
              size: 10,
              fill: _periodFill,
              thickRight: pi < lastBlock,
            ),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                cell(horaW, headH * 2, 'Hora', bold: true, size: 8, fill: _headFill),
                for (var ai = 0; ai < arms.length; ai++)
                  pw.Column(
                    children: [
                      cell(
                        armW,
                        headH,
                        'Braço ${arms[ai].label.toLowerCase()}',
                        bold: true,
                        size: cfg.pulse ? 9 : 7,
                        fill: _headFill,
                        thickRight: pi < lastBlock && ai == arms.length - 1,
                      ),
                      pw.Row(
                        children: [
                          cell(pressW, headH, 'Pressão', size: 8, fill: _headFill),
                          if (cfg.pulse)
                            cell(
                              pulseW,
                              headH,
                              'Pulso',
                              size: 8,
                              fill: _headFill,
                              thickRight: pi < lastBlock && ai == arms.length - 1,
                            ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
    ],
  );

  String pressure(Reading r) => (r.s.isNotEmpty || r.d.isNotEmpty) ? '${r.s}/${r.d}' : '';

  final rows = <pw.Widget>[
    for (var day = from; day < to; day++)
      pw.Row(
        children: [
          cell(dayW, rowH, '${day + 1}', bold: true, size: 10, fill: _sideFill),
          cell(
            dateW,
            rowH,
            dateOf(nb.start, day) == null ? '' : _short.format(dateOf(nb.start, day)!),
            fill: _sideFill,
          ),
          for (var pi = 0; pi < cfg.periods.length; pi++) ...[
            cell(horaW, rowH, blank ? '' : nb.entry(day, cfg.periods[pi]).time, size: 10),
            for (var ai = 0; ai < arms.length; ai++) ...[
              () {
                final r = nb.entry(day, cfg.periods[pi]).arm(arms[ai]);
                final endOfBlock = pi < lastBlock && ai == arms.length - 1;
                return pw.Row(
                  children: [
                    cell(
                      pressW,
                      rowH,
                      blank ? '' : pressure(r),
                      bold: true,
                      size: 11,
                      thickRight: endOfBlock && !cfg.pulse,
                    ),
                    if (cfg.pulse)
                      cell(
                        pulseW,
                        rowH,
                        blank ? '' : r.p,
                        size: 11,
                        thickRight: endOfBlock,
                      ),
                  ],
                );
              }(),
            ],
          ],
        ],
      ),
  ];

  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border(
        left: pw.BorderSide(width: _thin, color: _line),
        top: pw.BorderSide(width: _thin, color: _line),
      ),
    ),
    child: pw.Column(children: [header, ...rows]),
  );
}

// ---------------------------------------------------------------- resumo

pw.Widget _summary(Notebook nb, DateTime now) {
  final cfg = nb.config;
  final rules = Rules(nb);
  final av = rules.averages();
  final diff = rules.armDiff();

  pw.Widget cell(String text, {bool bold = false, double size = 11, PdfColor? fill}) => pw.Container(
    color: fill,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
    alignment: pw.Alignment.center,
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );

  String pressure(ArmAverage r) =>
      r.s == null ? '-' : '${fmtAvg(r.s)} / ${fmtAvg(r.d)}  (${r.s!.round()}/${r.d!.round()})';

  final widths = <int, pw.TableColumnWidth>{
    0: const pw.FixedColumnWidth(140),
    1: const pw.FixedColumnWidth(200),
    if (cfg.pulse) 2: const pw.FixedColumnWidth(120),
    (cfg.pulse ? 3 : 2): const pw.FixedColumnWidth(140),
  };

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Resumo das medições',
        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: _red),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Médias de todas as medições completas (alta e baixa preenchidas)',
        style: pw.TextStyle(fontSize: 10, color: _gray),
      ),
      pw.SizedBox(height: 14),
      pw.Table(
        border: pw.TableBorder.all(width: 0.5, color: _gray),
        columnWidths: widths,
        children: [
          pw.TableRow(
            children: [
              cell('Braço', bold: true, size: 10, fill: _headFill),
              cell('Pressão média', bold: true, size: 10, fill: _headFill),
              if (cfg.pulse) cell('Pulso médio', bold: true, size: 10, fill: _headFill),
              cell('Medições', bold: true, size: 10, fill: _headFill),
            ],
          ),
          for (final a in cfg.activeArms)
            pw.TableRow(
              children: [
                cell('Braço ${a.label.toLowerCase()}', bold: true),
                cell(pressure(av[a]!)),
                if (cfg.pulse) cell(av[a]!.p == null ? '-' : '${av[a]!.p}'),
                cell('${av[a]!.sets}'),
              ],
            ),
        ],
      ),
      pw.SizedBox(height: 14),
      if (diff != null) ...[
        pw.Text(
          'Diferença média da alta entre os braços: ${fmtAvg(diff.avg)}  '
          '(em ${diff.n} horários com os dois braços)',
          style: const pw.TextStyle(fontSize: 11),
        ),
        pw.SizedBox(height: 8),
      ],
      pw.Text(
        'Valores curtos valem dez vezes o número: 13/8 equivale a 130/80 mmHg.',
        style: pw.TextStyle(fontSize: 9, color: _gray),
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'Este documento é só um registro. A interpretação dos valores é feita pelo médico.',
        style: pw.TextStyle(fontSize: 9, color: _gray),
      ),
      pw.Spacer(),
      if (nb.name.isNotEmpty)
        pw.Text(
          'Nome do paciente: ${nb.name}',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      pw.Text(
        'Gerado em ${_full.format(now)} pelo app Diário da Pressão',
        style: pw.TextStyle(fontSize: 7, color: _lightGray),
      ),
    ],
  );
}
