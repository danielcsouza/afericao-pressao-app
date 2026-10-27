import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import 'theme.dart';

const _white = Colors.white;

/// Wizard de primeiro acesso: uma pergunta por vez, fundo brand, campos brancos.
class Wizard extends ConsumerStatefulWidget {
  const Wizard({super.key});

  @override
  ConsumerState<Wizard> createState() => _WizardState();
}

class _WizardState extends ConsumerState<Wizard> {
  static const _steps = 7;
  static const _presets = [7, 15, 30, 60, 90];

  final _nameCtrl = TextEditingController();
  int _step = 0;

  int _days = 30;
  bool _customDays = false;
  DateTime _start = _today();
  ArmsMode _arms = ArmsMode.both;
  bool _pulse = true;
  final Set<Period> _periods = {...Period.values};
  bool _remindersOn = true;
  final Map<Period, String> _times = {
    for (final p in Period.values) p: p.defaultTime,
  };

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Config get _config => Config(
    days: _days,
    arms: _arms,
    pulse: _pulse,
    periods: [
      for (final p in Period.values)
        if (_periods.contains(p)) p,
    ],
    remindersOn: _remindersOn,
    reminders: {
      for (final p in Period.values) p: ReminderConfig(time: _times[p]!),
    },
  );

  void _finish({bool defaults = false}) {
    final n = ref.read(notebookProvider.notifier);
    final name = _nameCtrl.text;
    if (defaults) {
      n.setName(name);
      n.finishSetup(config: const Config(remindersOn: true));
    } else {
      n.setName(name);
      n.finishSetup(start: isoOf(_start), config: _config);
    }
  }

  void _next() => _step == _steps - 1 ? _finish() : setState(() => _step++);
  void _back() => setState(() => _step--);

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('pt', 'BR'),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _pickCustomDays() async {
    final ctrl = TextEditingController(
      text: _presets.contains(_days) ? '' : '$_days',
    );
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quantos dias?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(3),
          ],
          decoration: InputDecoration(
            hintText: '${Config.minDays} a ${Config.maxDays}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (v != null) {
      setState(() {
        _days = v.clamp(Config.minDays, Config.maxDays);
        _customDays = !_presets.contains(_days);
      });
    }
  }

  Future<void> _pickTime(Period p) async {
    final parts = _times[p]!.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t != null) {
      setState(
        () => _times[p] =
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final canNext = _step != 4 || _periods.isNotEmpty;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: c.statusBar,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: c.headerColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: c.headerColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _Dots(count: _steps, index: _step),
                    Expanded(
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 380),
                          child: Center(child: _body(c)),
                        ),
                      ),
                    ),
                    Row(
                      spacing: 12,
                      children: [
                        if (_step > 0)
                          Expanded(
                            child: _WizButton(
                              'Voltar',
                              onTap: _back,
                              filled: false,
                            ),
                          ),
                        Expanded(
                          flex: 2,
                          child: _WizButton(
                            _step == _steps - 1 ? 'Começar' : 'Avançar',
                            onTap: canNext ? _next : null,
                          ),
                        ),
                      ],
                    ),
                    if (_step == 0)
                      TextButton(
                        onPressed: () => _finish(defaults: true),
                        child: const Text(
                          'Usar padrão',
                          style: TextStyle(color: _white, fontSize: 15),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(AppColors c) {
    switch (_step) {
      case 0:
        return _Step(
          emoji: '❤️',
          title: 'Diário da Pressão',
          subtitle: 'Seu caderno para anotar a pressão. Como devo chamar você?',
          child: SizedBox(
            width: 340,
            child: TextField(
              controller: _nameCtrl,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.words,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
              style: const TextStyle(fontSize: 20, color: Color(0xFF2A1F1F)),
              decoration: InputDecoration(
                hintText: 'Seu nome',
                hintStyle: const TextStyle(color: Color(0xFF7A6A6A)),
                filled: true,
                fillColor: _white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        );
      case 1:
        return _Step(
          emoji: '📆',
          title: 'Por quantos dias?',
          subtitle: 'Quanto tempo o médico pediu para acompanhar.',
          child: Column(
            spacing: 18,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in _presets)
                    _Choice(
                      '$d',
                      selected: !_customDays && _days == d,
                      onTap: () => setState(() {
                        _days = d;
                        _customDays = false;
                      }),
                    ),
                  _Choice(
                    _customDays ? '$_days' : 'Outro',
                    selected: _customDays,
                    onTap: _pickCustomDays,
                  ),
                ],
              ),
              const Text(
                'Começa em',
                style: TextStyle(color: _white, fontSize: 15),
              ),
              _Choice(
                DateFormat("dd/MM/yyyy").format(_start),
                selected: true,
                onTap: _pickDate,
              ),
            ],
          ),
        );
      case 2:
        return _Step(
          emoji: '💪',
          title: 'Quais braços?',
          subtitle: 'Em qual braço você mede.',
          child: _Options<ArmsMode>(
            value: _arms,
            onChanged: (v) => setState(() => _arms = v),
            options: const [
              (ArmsMode.both, 'Os dois'),
              (ArmsMode.left, 'Só o esquerdo'),
              (ArmsMode.right, 'Só o direito'),
            ],
          ),
        );
      case 3:
        return _Step(
          emoji: '💓',
          title: 'Anotar o pulso?',
          subtitle: 'Os batimentos por minuto são opcionais.',
          child: _Options<bool>(
            value: _pulse,
            onChanged: (v) => setState(() => _pulse = v),
            options: const [(true, 'Sim'), (false, 'Não')],
          ),
        );
      case 4:
        return _Step(
          emoji: '🕒',
          title: 'Quando medir?',
          subtitle: 'Escolha os períodos do dia (pelo menos um).',
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in Period.values)
                _Choice(
                  '${p.icon} ${p.label}',
                  selected: _periods.contains(p),
                  onTap: () => setState(() {
                    if (!_periods.remove(p)) _periods.add(p);
                  }),
                ),
            ],
          ),
        );
      case 5:
        return _Step(
          emoji: '🔔',
          title: 'Lembretes',
          subtitle: 'Se até o horário ainda não houver anotação no período, o app avisa uma vez.',
          child: Column(
            spacing: 12,
            children: [
              _Options<bool>(
                value: _remindersOn,
                onChanged: (v) => setState(() => _remindersOn = v),
                options: const [(true, 'Avisar'), (false, 'Não avisar')],
              ),
              if (_remindersOn)
                for (final p in Period.values)
                  if (_periods.contains(p))
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 10,
                      children: [
                        Text(
                          '${p.icon} ${p.label} até',
                          style: const TextStyle(color: _white, fontSize: 17),
                        ),
                        _Choice(
                          _times[p]!,
                          selected: true,
                          onTap: () => _pickTime(p),
                        ),
                      ],
                    ),
            ],
          ),
        );
      default:
        return _Step(
          emoji: '✅',
          title: 'Tudo pronto!',
          subtitle: _summary(),
          child: const SizedBox.shrink(),
        );
    }
  }

  String _summary() {
    final periods = [
      for (final p in Period.values)
        if (_periods.contains(p)) p.label.toLowerCase(),
    ];
    final arms = switch (_arms) {
      ArmsMode.both => 'os dois braços',
      ArmsMode.left => 'braço esquerdo',
      ArmsMode.right => 'braço direito',
    };
    return [
      '$_days ${_days == 1 ? 'dia' : 'dias'}, a partir de ${DateFormat('dd/MM/yyyy').format(_start)}',
      periods.join(', '),
      arms,
      _pulse ? 'com pulso' : 'sem pulso',
      _remindersOn ? 'com lembretes' : 'sem lembretes',
    ].join('\n');
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String emoji, title, subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 64)),
      Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _white,
          fontSize: 26,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _white, fontSize: 16, height: 1.4),
      ),
      const SizedBox(height: 4),
      child,
    ],
  );
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count, index;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 8,
    children: [
      for (var i = 0; i < count; i++)
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _white.withValues(alpha: i == index ? 1 : .35),
          ),
        ),
    ],
  );
}

class _Choice extends StatelessWidget {
  const _Choice(this.label, {required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? _white : Colors.transparent,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: selected ? _white : _white.withValues(alpha: .5),
          width: 2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.light.brand : _white,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _Options<T> extends StatelessWidget {
  const _Options({
    required this.value,
    required this.onChanged,
    required this.options,
  });
  final T value;
  final ValueChanged<T> onChanged;
  final List<(T, String)> options;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (v, label) in options)
        _Choice(label, selected: v == value, onTap: () => onChanged(v)),
    ],
  );
}

class _WizButton extends StatelessWidget {
  const _WizButton(this.label, {required this.onTap, this.filled = true});
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: filled
        ? FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: _white,
              foregroundColor: AppColors.light.brand,
              disabledBackgroundColor: _white.withValues(alpha: .4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onTap,
            child: Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          )
        : OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _white,
              side: BorderSide(color: _white.withValues(alpha: .5), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: onTap,
            child: Text(
              label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
  );
}
