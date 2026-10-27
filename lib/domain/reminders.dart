import 'dates.dart';
import 'models.dart';
import 'rules.dart';

/// Um lembrete a agendar: uma notificação, no horário do período, num dia.
class PlannedReminder {
  const PlannedReminder({
    required this.day,
    required this.period,
    required this.at,
  });

  final int day; // índice do dia no caderno
  final Period period;
  final DateTime at;

  /// Estável por dia/período, para o mesmo lembrete manter o mesmo id.
  int get id => day * Period.values.length + period.index;

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.day == day &&
      other.period == period &&
      other.at == at;

  @override
  int get hashCode => Object.hash(day, period, at);
}

/// Lembretes que devem estar agendados agora: dentro de [horizonDays] a partir
/// de [now], só em dias do caderno, só em períodos ativos com lembrete ligado,
/// só no futuro e só se o período ainda não tem nenhuma anotação.
List<PlannedReminder> plannedReminders(
  Notebook nb,
  DateTime now, {
  int horizonDays = 14,
}) {
  final cfg = nb.config;
  if (!nb.configured || !cfg.remindersOn || parseIso(nb.start) == null) {
    return const [];
  }

  final rules = Rules(nb);
  final limit = now.add(Duration(days: horizonDays));
  final out = <PlannedReminder>[];
  for (var day = 0; day < cfg.days; day++) {
    final date = dateOf(nb.start, day)!;
    if (date.isAfter(limit)) break;
    for (final p in cfg.periods) {
      final r = cfg.reminder(p);
      if (!r.enabled) continue;
      final hm = r.time.split(':');
      final at = DateTime(
        date.year,
        date.month,
        date.day,
        int.parse(hm[0]),
        int.parse(hm[1]),
      );
      if (!at.isAfter(now) || at.isAfter(limit)) continue;
      if (rules.periodHasData(day, p)) continue;
      out.add(PlannedReminder(day: day, period: p, at: at));
    }
  }
  return out;
}
