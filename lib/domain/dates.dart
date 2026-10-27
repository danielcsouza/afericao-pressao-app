// Datas sempre como AAAA-MM-DD locais; a diferença de dias usa UTC (sem horário de verão).

String isoOf(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime? parseIso(String s) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(s);
  if (m == null) return null;
  return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
}

DateTime? dateOf(String start, int i) {
  final s = parseIso(start);
  if (s == null) return null;
  return DateTime(s.year, s.month, s.day + i);
}

/// Índice do dia de hoje no caderno (pode ser negativo ou ≥ dias), ou null sem data de início.
int? todayIndex(String start, [DateTime? now]) {
  final s = parseIso(start);
  if (s == null) return null;
  final n = now ?? DateTime.now();
  final t0 = DateTime.utc(s.year, s.month, s.day);
  final t1 = DateTime.utc(n.year, n.month, n.day);
  return t1.difference(t0).inDays;
}

/// "08:05": hora e minuto com dois dígitos.
String hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
