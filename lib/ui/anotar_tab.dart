import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/input.dart';
import '../domain/models.dart';
import 'theme.dart';

/// Aba Anotar: navegação por dia e um cartão por período ativo.
class AnotarTab extends ConsumerWidget {
  const AnotarTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final nb = ref.watch(notebookProvider);
    final days = nb.config.days;
    final day = ref.watch(selectedDayProvider).clamp(0, days - 1);
    final today = todayIndex(nb.start);
    final first = nb.name.split(' ').first;
    final date = dateOf(nb.start, day);

    void go(int i) =>
        ref.read(selectedDayProvider.notifier).set(i.clamp(0, days - 1));

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        if (first.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Olá, $first! 👋',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ),
        Row(
          children: [
            _RoundButton('‹', onTap: day > 0 ? () => go(day - 1) : null),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Dia ${day + 1} de $days',
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (date != null)
                    Text(
                      _longDate(date),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: c.muted),
                    ),
                ],
              ),
            ),
            _RoundButton('›', onTap: day < days - 1 ? () => go(day + 1) : null),
          ],
        ),
        if (today != null && today >= 0 && today < days && today != day)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: () => go(today),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: c.card,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Ir para hoje (dia ${today + 1})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 14),
        for (final p in nb.config.periods)
          _PeriodCard(key: ValueKey('$day-${p.name}'), day: day, period: p),
        Text(
          'Digite como falamos: 13 e 8. Salva automaticamente neste aparelho.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: c.muted),
        ),
      ],
    );
  }

  static String _longDate(DateTime d) {
    final s = DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(d);
    return s[0].toUpperCase() + s.substring(1);
  }
}

class _RoundButton extends StatefulWidget {
  const _RoundButton(this.label, {required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  State<_RoundButton> createState() => _RoundButtonState();
}

class _RoundButtonState extends State<_RoundButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? .94 : 1,
        duration: const Duration(milliseconds: 100),
        child: Opacity(
          opacity: enabled ? 1 : .7,
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? c.headerColor : c.line,
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 34,
                height: 1,
                fontWeight: FontWeight.w700,
                color: enabled ? AppColors.brandInk : c.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeriodCard extends ConsumerStatefulWidget {
  const _PeriodCard({super.key, required this.day, required this.period});
  final int day;
  final Period period;

  @override
  ConsumerState<_PeriodCard> createState() => _PeriodCardState();
}

class _PeriodCardState extends ConsumerState<_PeriodCard> {
  static const _fields = ['s', 'd', 'p'];

  final _ctrl = <String, TextEditingController>{};
  final _focus = <String, FocusNode>{};
  final _last = <String, String>{};

  String _key(Arm a, String f) => '${a.id}$f';

  @override
  void initState() {
    super.initState();
    for (final a in Arm.values) {
      for (final f in _fields) {
        _ctrl[_key(a, f)] = TextEditingController();
        _focus[_key(a, f)] = FocusNode();
      }
    }
    _sync(ref.read(notebookProvider).entry(widget.day, widget.period));
    // Mantém os campos em dia quando o cartão é limpo ou o valor muda por fora.
    ref.listenManual(
      notebookProvider.select((n) => n.entry(widget.day, widget.period)),
      (_, e) => _sync(e),
    );
  }

  @override
  void dispose() {
    for (final c in _ctrl.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _sync(Entry e) {
    for (final a in Arm.values) {
      final r = e.arm(a);
      _setText(_key(a, 's'), r.s);
      _setText(_key(a, 'd'), r.d);
      _setText(_key(a, 'p'), r.p);
    }
  }

  void _setText(String key, String v) {
    _last[key] = v;
    final c = _ctrl[key]!;
    if (c.text != v) {
      c.value = TextEditingValue(
        text: v,
        selection: TextSelection.collapsed(offset: v.length),
      );
    }
  }

  Entry get _entry =>
      ref.read(notebookProvider).entry(widget.day, widget.period);

  void _onChanged(Arm arm, String f, String raw) {
    final key = _key(arm, f);
    final r = _entry.arm(arm);
    final ch = applyInput(
      field: f,
      raw: raw,
      currentSystolic: r.s,
      inserting: raw.length >= (_last[key] ?? '').length,
      diastolicEmpty: r.d.isEmpty,
    );
    _setText(key, ch.value);
    if (ch.systolic != null) _setText(_key(arm, 's'), ch.systolic!);
    final next = switch (f) {
      's' => r.copyWith(s: ch.value),
      'd' => r.copyWith(d: ch.value, s: ch.systolic ?? r.s),
      _ => r.copyWith(p: ch.value),
    };
    ref
        .read(notebookProvider.notifier)
        .setEntry(widget.day, widget.period, _entry.withArm(arm, next));
    if (ch.jumpToDiastolic) _focus[_key(arm, 'd')]!.requestFocus();
  }

  Future<void> _pickTime() async {
    final cur = _entry.time.split(':');
    final initial = cur.length == 2
        ? TimeOfDay(
            hour: int.tryParse(cur[0]) ?? 8,
            minute: int.tryParse(cur[1]) ?? 0,
          )
        : TimeOfDay.now();
    final t = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (t == null) return;
    final s =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    ref
        .read(notebookProvider.notifier)
        .setEntry(widget.day, widget.period, _entry.withTime(s));
  }

  Future<void> _confirmClear() async {
    final label = widget.period.label.toLowerCase();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Limpar registros da $label?'),
        content: const Text(
          'Os valores deste período, neste dia, serão apagados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref
          .read(notebookProvider.notifier)
          .clearPeriod(widget.day, widget.period);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final nb = ref.watch(notebookProvider);
    final rules = ref.watch(rulesProvider);
    final cfg = nb.config;
    final e = nb.entry(widget.day, widget.period);
    final done = rules.periodDone(widget.day, widget.period);
    final complete = rules.periodComplete(widget.day, widget.period);

    final (badge, badgeFg, badgeBg, border) = complete
        ? ('✓ completo', c.ok, c.okSoft, c.ok)
        : done > 0
        ? ('falta 1 braço', c.warn, c.warnSoft, c.warn)
        : ('a fazer', c.brand, c.brandSoft, c.line);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: border, width: 2),
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${widget.period.icon} ${widget.period.label}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text('Hora', style: TextStyle(fontSize: 14, color: c.muted)),
              const SizedBox(width: 4),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _pickTime,
                child: Container(
                  width: 64,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.bg,
                    border: Border.all(color: c.line),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    e.time.isEmpty ? '--:--' : e.time,
                    style: TextStyle(
                      fontSize: 16,
                      color: e.time.isEmpty ? c.muted : c.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: badgeFg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              for (final a in cfg.activeArms)
                Expanded(child: _armColumn(c, a, cfg.pulse)),
            ],
          ),
          if (rules.periodHasData(widget.day, widget.period))
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: _confirmClear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: c.line),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '🗑️ Limpar registros da ${widget.period.label.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: c.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _armColumn(AppColors c, Arm a, bool pulse) {
    final color = a == Arm.left ? c.left : c.right;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            'Braço ${a.label.toLowerCase()}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _legend(c, 'Alta', '(sistólica)')),
            const SizedBox(width: 14),
            Expanded(child: _legend(c, 'Baixa', '(diastólica)')),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(child: _numField(c, a, 's')),
            SizedBox(
              width: 14,
              child: Text(
                '/',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, color: c.muted),
              ),
            ),
            Expanded(child: _numField(c, a, 'd')),
          ],
        ),
        if (pulse) ...[
          const SizedBox(height: 10),
          _legend(c, 'Pulso', 'opcional'),
          const SizedBox(height: 4),
          _numField(c, a, 'p'),
        ],
      ],
    );
  }

  Widget _legend(AppColors c, String title, String sub) => Column(
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      Text(sub, style: TextStyle(fontSize: 10, color: c.muted)),
    ],
  );

  Widget _numField(AppColors c, Arm a, String f) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: 2),
    );
    return SizedBox(
      height: 58,
      child: TextField(
        controller: _ctrl[_key(a, f)],
        focusNode: _focus[_key(a, f)],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
        onChanged: (v) => _onChanged(a, f, v),
        decoration: InputDecoration(
          hintText: '–',
          hintStyle: TextStyle(color: c.line, fontWeight: FontWeight.w700),
          filled: true,
          fillColor: WidgetStateColor.resolveWith(
            (s) => s.contains(WidgetState.focused) ? c.card : c.bg,
          ),
          contentPadding: EdgeInsets.zero,
          enabledBorder: border(c.line),
          focusedBorder: border(c.headerColor),
        ),
      ),
    );
  }
}
