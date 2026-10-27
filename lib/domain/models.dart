/// Períodos do dia, na ordem em que aparecem.
enum Period {
  m('Manhã', '🌅', '11:50'),
  t('Tarde', '☀️', '18:30'),
  n('Noite', '🌙', '22:50');

  const Period(this.label, this.icon, this.defaultTime);
  final String label;
  final String icon;
  final String defaultTime;
}

enum Arm {
  left('L', 'Esquerdo'),
  right('R', 'Direito');

  const Arm(this.id, this.label);
  final String id;
  final String label;
}

enum ArmsMode { both, left, right }

/// Uma medição de um braço. Valores guardados como texto, como no app web.
class Reading {
  const Reading({this.s = '', this.d = '', this.p = ''});
  final String s;
  final String d;
  final String p;

  bool get isEmpty => s.isEmpty && d.isEmpty && p.isEmpty;
  bool get done => s.isNotEmpty && d.isNotEmpty;

  Reading copyWith({String? s, String? d, String? p}) =>
      Reading(s: s ?? this.s, d: d ?? this.d, p: p ?? this.p);

  Map<String, dynamic> toJson() => {'s': s, 'd': d, 'p': p};

  factory Reading.fromJson(Object? j) {
    if (j is! Map) return const Reading();
    String f(String k) => (j[k] ?? '').toString();
    return Reading(s: f('s'), d: f('d'), p: f('p'));
  }
}

/// Anotação de um período de um dia: hora opcional e uma medição por braço.
class Entry {
  const Entry({
    this.time = '',
    this.left = const Reading(),
    this.right = const Reading(),
  });
  final String time;
  final Reading left;
  final Reading right;

  Reading arm(Arm a) => a == Arm.left ? left : right;

  Entry withArm(Arm a, Reading r) => a == Arm.left
      ? Entry(time: time, left: r, right: right)
      : Entry(time: time, left: left, right: r);

  Entry withTime(String t) => Entry(time: t, left: left, right: right);

  Map<String, dynamic> toJson() => {
    't': time,
    'L': left.toJson(),
    'R': right.toJson(),
  };

  factory Entry.fromJson(Object? j) {
    if (j is! Map) return const Entry();
    return Entry(
      time: (j['t'] ?? '').toString(),
      left: Reading.fromJson(j['L']),
      right: Reading.fromJson(j['R']),
    );
  }
}

class ReminderConfig {
  const ReminderConfig({this.enabled = true, required this.time});
  final bool enabled;
  final String time; // HH:MM

  ReminderConfig copyWith({bool? enabled, String? time}) =>
      ReminderConfig(enabled: enabled ?? this.enabled, time: time ?? this.time);

  Map<String, dynamic> toJson() => {'enabled': enabled, 'time': time};

  factory ReminderConfig.fromJson(Object? j, String fallback) {
    if (j is! Map) return ReminderConfig(time: fallback);
    final t = (j['time'] ?? '').toString();
    return ReminderConfig(
      enabled: j['enabled'] != false,
      time: RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(t) ? t : fallback,
    );
  }
}

/// Como o caderno está configurado (wizard e aba Ajustes).
class Config {
  const Config({
    this.days = 30,
    this.arms = ArmsMode.both,
    this.pulse = true,
    this.periods = const [Period.m, Period.t, Period.n],
    this.remindersOn = false,
    this.reminders = const {},
  });

  static const minDays = 1;
  static const maxDays = 365;

  final int days;
  final ArmsMode arms;
  final bool pulse;
  final List<Period> periods; // ativos, em ordem; pelo menos 1
  final bool remindersOn;
  final Map<Period, ReminderConfig> reminders;

  List<Arm> get activeArms => switch (arms) {
    ArmsMode.both => Arm.values,
    ArmsMode.left => const [Arm.left],
    ArmsMode.right => const [Arm.right],
  };

  /// Medições possíveis por dia (períodos ativos × braços ativos).
  int get perDay => periods.length * activeArms.length;
  int get totalSlots => days * perDay;

  ReminderConfig reminder(Period p) =>
      reminders[p] ?? ReminderConfig(time: p.defaultTime);

  Config copyWith({
    int? days,
    ArmsMode? arms,
    bool? pulse,
    List<Period>? periods,
    bool? remindersOn,
    Map<Period, ReminderConfig>? reminders,
  }) => Config(
    days: (days ?? this.days).clamp(minDays, maxDays),
    arms: arms ?? this.arms,
    pulse: pulse ?? this.pulse,
    periods: periods ?? this.periods,
    remindersOn: remindersOn ?? this.remindersOn,
    reminders: reminders ?? this.reminders,
  );

  Map<String, dynamic> toJson() => {
    'days': days,
    'arms': arms.name,
    'pulse': pulse,
    'periods': periods.map((p) => p.name).toList(),
    'remindersOn': remindersOn,
    'reminders': {
      for (final e in reminders.entries) e.key.name: e.value.toJson(),
    },
  };

  factory Config.fromJson(Object? j) {
    if (j is! Map) return const Config();
    final periods = <Period>[
      for (final p in Period.values)
        if ((j['periods'] is List
                ? (j['periods'] as List)
                : const ['m', 't', 'n'])
            .contains(p.name))
          p,
    ];
    final rem = j['reminders'];
    return Config(
      days: ((j['days'] is int ? j['days'] as int : 30)).clamp(
        minDays,
        maxDays,
      ),
      arms: ArmsMode.values.firstWhere(
        (a) => a.name == j['arms'],
        orElse: () => ArmsMode.both,
      ),
      pulse: j['pulse'] != false,
      periods: periods.isEmpty ? const [Period.m, Period.t, Period.n] : periods,
      remindersOn: j['remindersOn'] == true,
      reminders: {
        for (final p in Period.values)
          if (rem is Map && rem[p.name] != null)
            p: ReminderConfig.fromJson(rem[p.name], p.defaultTime),
      },
    );
  }
}

/// Tudo o que o app guarda: nome, data de início, configuração e anotações.
class Notebook {
  const Notebook({
    this.name = '',
    this.start = '',
    this.configured = false,
    this.config = const Config(),
    this.data = const {},
  });

  final String name;
  final String start; // AAAA-MM-DD ou ''
  final bool configured; // wizard concluído
  final Config config;
  final Map<int, Map<Period, Entry>> data;

  Entry entry(int day, Period p) => data[day]?[p] ?? const Entry();

  Notebook withEntry(int day, Period p, Entry e) {
    final next = {
      for (final k in data.entries) k.key: Map<Period, Entry>.of(k.value),
    };
    (next[day] ??= {})[p] = e;
    return copyWith(data: next);
  }

  Notebook clearPeriod(int day, Period p) {
    final next = {
      for (final k in data.entries) k.key: Map<Period, Entry>.of(k.value),
    };
    next[day]?.remove(p);
    return copyWith(data: next);
  }

  Notebook copyWith({
    String? name,
    String? start,
    bool? configured,
    Config? config,
    Map<int, Map<Period, Entry>>? data,
  }) => Notebook(
    name: name ?? this.name,
    start: start ?? this.start,
    configured: configured ?? this.configured,
    config: config ?? this.config,
    data: data ?? this.data,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'start': start,
    'configured': configured,
    'config': config.toJson(),
    'data': {
      for (final d in data.entries)
        '${d.key}': {
          for (final e in d.value.entries) e.key.name: e.value.toJson(),
        },
    },
  };

  factory Notebook.fromJson(Object? j) {
    if (j is! Map) return const Notebook();
    final data = <int, Map<Period, Entry>>{};
    final raw = j['data'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final day = int.tryParse('$k');
        if (day == null || v is! Map) return;
        final periods = <Period, Entry>{};
        for (final p in Period.values) {
          if (v[p.name] != null) periods[p] = Entry.fromJson(v[p.name]);
        }
        data[day] = periods;
      });
    }
    return Notebook(
      name: (j['name'] ?? '').toString(),
      start: (j['start'] ?? '').toString(),
      configured: j['configured'] == true,
      config: Config.fromJson(j['config']),
      data: data,
    );
  }
}
