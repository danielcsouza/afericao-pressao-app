import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../app/providers.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/rules.dart';
import 'actions.dart';
import 'theme.dart';
import 'widgets.dart';

final _full = DateFormat('dd/MM/yyyy');
final _short = DateFormat('dd/MM');

/// Aba Resumo: início e duração, progresso, grade de dias e médias.
class ResumoTab extends ConsumerWidget {
  const ResumoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: const [
        _StartPanel(),
        _ProgressPanel(),
        _DaysPanel(),
        _AveragesPanel(),
      ],
    );
  }
}

class _StartPanel extends ConsumerWidget {
  const _StartPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final nb = ref.watch(notebookProvider);
    final notifier = ref.read(notebookProvider.notifier);
    final start = parseIso(nb.start);
    final days = nb.config.days;
    final end = dateOf(nb.start, days - 1);

    Future<void> pickDate() async {
      final d = await showDatePicker(
        context: context,
        initialDate: start ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
        locale: const Locale('pt', 'BR'),
      );
      if (d != null) notifier.setStart(isoOf(d));
    }

    return Panel(
      title: '📆 Quando começa?',
      children: [
        Row(
          spacing: 10,
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: c.bg,
                    border: Border.all(color: c.line, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    start == null ? 'Escolher data' : _full.format(start),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            SmallButton(
              'Usar hoje',
              onTap: () => notifier.setStart(isoOf(DateTime.now())),
            ),
          ],
        ),
        PanelText(
          '',
          span: end == null
              ? TextSpan(
                  text:
                      'Escolha a data do primeiro dia. As outras $days datas aparecem sozinhas.',
                )
              : TextSpan(
                  children: [
                    const TextSpan(text: 'Termina em '),
                    TextSpan(
                      text: _full.format(end),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        Text('Duração (dias)', style: TextStyle(fontSize: 14, color: c.muted)),
        const SizedBox(height: 6),
        DaysChips(
          days: days,
          onChanged: (v) => changeDays(context, ref, v),
        ),
      ],
    );
  }
}

class _ProgressPanel extends ConsumerWidget {
  const _ProgressPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final cfg = ref.watch(notebookProvider.select((n) => n.config));
    final rules = ref.watch(rulesProvider);
    final done = rules.totalDone();
    final total = cfg.totalSlots;
    final fraction = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    final names = [for (final p in cfg.periods) p.label.toLowerCase()];
    final periods = names.length == 1
        ? names.first
        : '${names.sublist(0, names.length - 1).join(', ')} e ${names.last}';
    final arms = cfg.activeArms.length;

    return Panel(
      title: 'Progresso',
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: Container(
            height: 12,
            color: c.line,
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: fraction),
              duration: const Duration(milliseconds: 300),
              builder: (_, v, _) => FractionallySizedBox(
                widthFactor: v,
                child: Container(color: c.ok),
              ),
            ),
          ),
        ),
        PanelText(
          '$done de $total medições feitas '
          '(${cfg.periods.length} por dia: $periods × $arms ${arms == 1 ? 'braço' : 'braços'})',
        ),
      ],
    );
  }
}

class _DaysPanel extends ConsumerWidget {
  const _DaysPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final nb = ref.watch(notebookProvider);
    final rules = ref.watch(rulesProvider);
    final selected = ref.watch(selectedDayProvider);
    final today = todayIndex(nb.start);
    final cfg = nb.config;

    Color dot(int day, Period p) => rules.periodComplete(day, p)
        ? c.ok
        : rules.periodDone(day, p) > 0
        ? c.warn
        : c.line;

    final names = cfg.periods.map((p) => p.label.toLowerCase()).join(' · ');
    final legend = cfg.activeArms.length == 2
        ? 'Verde = os dois braços feitos; laranja = só um.'
        : 'Verde = braço feito.';

    return Panel(
      title: 'Os ${cfg.days} dias',
      children: [
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 82,
          ),
          itemCount: cfg.days,
          itemBuilder: (_, i) {
            final dt = dateOf(nb.start, i);
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ref.read(selectedDayProvider.notifier).set(i);
                ref.read(tabProvider.notifier).set(0);
              },
              child: Container(
                padding: const EdgeInsets.fromLTRB(2, 8, 2, 7),
                decoration: BoxDecoration(
                  color: i == selected ? c.brandSoft : c.card,
                  border: Border.all(
                    color: today == i ? c.brand : c.line,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      dt == null ? '' : _short.format(dt),
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 3,
                      children: [
                        for (final p in cfg.periods)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: dot(i, p),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        PanelText('Bolinhas: $names. $legend'),
      ],
    );
  }
}

class _AveragesPanel extends ConsumerWidget {
  const _AveragesPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final cfg = ref.watch(notebookProvider.select((n) => n.config));
    final rules = ref.watch(rulesProvider);
    final av = rules.averages();
    final diff = rules.armDiff();

    TextStyle head() =>
        TextStyle(fontSize: 13, color: c.muted, fontWeight: FontWeight.w400);

    Widget cell(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: child,
    );

    // A linha inferior fica na linha da tabela, para não desalinhar entre colunas.
    final rowLine = BoxDecoration(
      border: Border(bottom: BorderSide(color: c.line)),
    );

    final rows = <TableRow>[
      TableRow(
        decoration: rowLine,
        children: [
          cell(const SizedBox.shrink()),
          cell(Text('Pressão', style: head())),
          if (cfg.pulse) cell(Text('Pulso', style: head())),
          cell(Text('Medições', style: head())),
        ],
      ),
      for (final a in cfg.activeArms)
        TableRow(
          decoration: rowLine,
          children: [
            cell(
              Text(
                '● ${a.label}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: a == Arm.left ? c.left : c.right,
                ),
              ),
            ),
            cell(Text(_pressure(av[a]!), style: const TextStyle(fontSize: 15))),
            if (cfg.pulse)
              cell(
                Text(
                  av[a]!.p?.toString() ?? '–',
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            cell(Text('${av[a]!.sets}', style: const TextStyle(fontSize: 15))),
          ],
        ),
    ];

    return Panel(
      title: 'Médias até agora',
      children: [
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          columnWidths: {
            0: const IntrinsicColumnWidth(),
            1: const FlexColumnWidth(),
            if (cfg.pulse) 2: const IntrinsicColumnWidth(),
            (cfg.pulse ? 3 : 2): const IntrinsicColumnWidth(),
          },
          children: rows,
        ),
        if (diff != null)
          PanelText(
            '',
            span: TextSpan(
              children: [
                const TextSpan(
                  text: 'Diferença média da alta entre os braços: ',
                ),
                TextSpan(
                  text: fmtAvg(diff.avg),
                  style: TextStyle(fontWeight: FontWeight.w700, color: c.ink),
                ),
                TextSpan(text: ' (em ${diff.n} horários com os dois braços).'),
              ],
            ),
          ),
        const PanelText(
          'Leve esses números na consulta. Quem interpreta é o médico.',
        ),
      ],
    );
  }

  static String _pressure(ArmAverage r) =>
      r.s == null ? '–' : '${fmtAvg(r.s)} / ${fmtAvg(r.d)}';
}
