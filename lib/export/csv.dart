import 'package:intl/intl.dart';

import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/rules.dart';

final _full = DateFormat('dd/MM/yyyy');

/// "130" em vez de "130.0" (valores curtos como 13 viram 130 mmHg).
String _mmHg(String v) {
  final n = norm(v);
  if (n == null) return '';
  return n == n.roundToDouble() ? '${n.toInt()}' : '$n';
}

/// CSV com `;` e quebras `\r\n`, sem o BOM (quem grava o arquivo acrescenta).
/// As colunas Braço e Pulso só existem se há dois braços / pulso ligado.
String buildCsv(Notebook nb) {
  final cfg = nb.config;
  final twoArms = cfg.activeArms.length == 2;

  final header = [
    'Dia',
    'Data',
    'Período',
    'Hora',
    if (twoArms) 'Braço',
    'Alta',
    'Baixa',
    if (cfg.pulse) 'Pulso',
    'Alta (mmHg)',
    'Baixa (mmHg)',
  ];
  final rows = <List<String>>[header];

  for (var day = 0; day < cfg.days; day++) {
    final date = dateOf(nb.start, day);
    for (final p in cfg.periods) {
      for (final a in cfg.activeArms) {
        final e = nb.entry(day, p);
        final r = e.arm(a);
        if (r.s.isEmpty && r.d.isEmpty && (!cfg.pulse || r.p.isEmpty)) continue;
        rows.add([
          '${day + 1}',
          date == null ? '' : _full.format(date),
          p.label,
          e.time,
          if (twoArms) a.label,
          r.s,
          r.d,
          if (cfg.pulse) r.p,
          _mmHg(r.s),
          _mmHg(r.d),
        ]);
      }
    }
  }
  return rows.map((r) => r.join(';')).join('\r\n');
}
