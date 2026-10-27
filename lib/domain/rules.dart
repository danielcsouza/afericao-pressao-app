import 'models.dart';

/// "13" e "130" valem o mesmo (13/8 = 130/80). Vazio ou inválido → null.
double? norm(String v) {
  final n = double.tryParse(v);
  if (n == null) return null;
  return n <= 30 ? n * 10 : n;
}

/// 128.0 → "12,8" (a média é exibida em cm Hg com vírgula, como no app web).
String fmtAvg(double? n) =>
    n == null ? '–' : (n.round() / 10).toStringAsFixed(1).replaceAll('.', ',');

class ArmAverage {
  const ArmAverage({required this.sets, this.s, this.d, this.p});
  final int sets;
  final double? s;
  final double? d;
  final int? p;
}

class ArmDiff {
  const ArmDiff(this.avg, this.n);
  final double avg;
  final int n;
}

/// Motivo de um período ter sido começado mas estar incompleto.
enum Incomplete {
  /// Tem valores, mas falta a hora (obrigatória).
  missingTime,

  /// Tem alta sem baixa (ou o contrário) em algum braço.
  halfReading,

  /// Tem hora, mas nenhum valor de medição.
  timeWithoutValues,
}

class IncompleteEntry {
  const IncompleteEntry({
    required this.day,
    required this.period,
    required this.reason,
  });
  final int day;
  final Period period;
  final Incomplete reason;
}

/// Todas as regras do caderno, calculadas sobre um [Notebook] e sua [Config].
class Rules {
  const Rules(this.nb);
  final Notebook nb;

  Config get cfg => nb.config;

  /// Medição de um braço feita: alta e baixa preenchidas **e a hora informada**
  /// (a hora é obrigatória: o médico precisa saber quando foi medido).
  bool armDone(int day, Period p, Arm a) {
    final e = nb.entry(day, p);
    return e.time.isNotEmpty && e.arm(a).done;
  }

  /// Há valores anotados no período mas falta a hora.
  bool missingTime(int day, Period p) {
    final e = nb.entry(day, p);
    return e.time.isEmpty && cfg.activeArms.any((a) => !e.arm(a).isEmpty);
  }

  bool periodHasData(int day, Period p) {
    final e = nb.entry(day, p);
    if (e.time.isNotEmpty) return true;
    return Arm.values.any((a) => !e.arm(a).isEmpty);
  }

  /// Por que o período não pode ser deixado como está, ou null se está em
  /// ordem. Período **vazio** é sempre válido (dá para navegar sem digitar
  /// nada); depois de começado, exige a hora e, em cada braço usado, alta e
  /// baixa (o pulso continua opcional).
  Incomplete? incompleteReason(int day, Period p) {
    final e = nb.entry(day, p);
    final touched = cfg.activeArms.where((a) => !e.arm(a).isEmpty).toList();
    if (touched.isEmpty) {
      return e.time.isEmpty ? null : Incomplete.timeWithoutValues;
    }
    if (e.time.isEmpty) return Incomplete.missingTime;
    if (touched.any((a) => !e.arm(a).done)) return Incomplete.halfReading;
    return null;
  }

  /// Períodos incompletos do caderno (todos os dias, ou só [day]), em ordem.
  List<IncompleteEntry> incompleteEntries({int? day}) => [
    for (var d = day ?? 0; d < (day == null ? cfg.days : day + 1); d++)
      for (final p in cfg.periods)
        if (incompleteReason(d, p) case final reason?)
          IncompleteEntry(day: d, period: p, reason: reason),
  ];

  /// Quantos braços ativos já estão completos no período.
  int periodDone(int day, Period p) =>
      cfg.activeArms.where((a) => armDone(day, p, a)).length;

  /// Preenchidos / esperados no período.
  bool periodComplete(int day, Period p) =>
      periodDone(day, p) == cfg.activeArms.length;

  int dayDone(int day) => cfg.periods.fold(0, (n, p) => n + periodDone(day, p));

  int totalDone() {
    var n = 0;
    for (var i = 0; i < cfg.days; i++) {
      n += dayDone(i);
    }
    return n;
  }

  int progressPercent() =>
      cfg.totalSlots == 0 ? 0 : (totalDone() / cfg.totalSlots * 100).round();

  Map<Arm, ArmAverage> averages() {
    final out = <Arm, ArmAverage>{};
    for (final a in cfg.activeArms) {
      var ss = 0.0, dd = 0.0, pp = 0, pc = 0, sets = 0;
      for (var i = 0; i < cfg.days; i++) {
        for (final p in cfg.periods) {
          final r = nb.entry(i, p).arm(a);
          if (r.done) {
            sets++;
            ss += norm(r.s) ?? 0;
            dd += norm(r.d) ?? 0;
          }
          if (cfg.pulse) {
            final pv = int.tryParse(r.p);
            if (pv != null) {
              pp += pv;
              pc++;
            }
          }
        }
      }
      out[a] = ArmAverage(
        sets: sets,
        s: sets > 0 ? ss / sets : null,
        d: sets > 0 ? dd / sets : null,
        p: pc > 0 ? (pp / pc).round() : null,
      );
    }
    return out;
  }

  /// Só faz sentido com os dois braços ativos.
  ArmDiff? armDiff() {
    if (cfg.arms != ArmsMode.both) return null;
    final diffs = <double>[];
    for (var i = 0; i < cfg.days; i++) {
      for (final p in cfg.periods) {
        final e = nb.entry(i, p);
        if (e.left.done && e.right.done) {
          diffs.add(((norm(e.left.s) ?? 0) - (norm(e.right.s) ?? 0)).abs());
        }
      }
    }
    if (diffs.isEmpty) return null;
    return ArmDiff(diffs.reduce((a, b) => a + b) / diffs.length, diffs.length);
  }

  /// Último dia (índice) com alguma anotação, ou -1.
  int lastDayWithData() {
    var last = -1;
    for (final d in nb.data.entries) {
      if (d.value.keys.any((p) => periodHasData(d.key, p)) && d.key > last) {
        last = d.key;
      }
    }
    return last;
  }
}
