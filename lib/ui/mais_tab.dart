import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/models.dart';
import 'actions.dart';
import 'theme.dart';
import 'widgets.dart';

/// Aba Mais: paciente, tema, lembretes, ajustes do caderno e recomeçar.
/// (Imprimir e exportar entram com o PDF/CSV.)
class MaisTab extends StatelessWidget {
  const MaisTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        const _PatientPanel(),
        const _ThemePanel(),
        const _RemindersPanel(),
        const _SetupPanel(),
        const _ResetPanel(),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'Este app é só um caderno digital. Não faz diagnóstico nem '
            'substitui o médico.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.colors.muted),
          ),
        ),
      ],
    );
  }
}

class _PatientPanel extends ConsumerStatefulWidget {
  const _PatientPanel();

  @override
  ConsumerState<_PatientPanel> createState() => _PatientPanelState();
}

class _PatientPanelState extends ConsumerState<_PatientPanel> {
  late final _ctrl = TextEditingController(
    text: ref.read(notebookProvider).name,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: 2),
    );
    return Panel(
      title: '👤 Paciente',
      children: [
        TextField(
          controller: _ctrl,
          textCapitalization: TextCapitalization.words,
          inputFormatters: [LengthLimitingTextInputFormatter(60)],
          // O nome é normalizado ao gravar; o campo mantém o que foi digitado.
          onChanged: (v) => ref.read(notebookProvider.notifier).setName(v),
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Nome do paciente',
            filled: true,
            fillColor: c.bg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: border(c.line),
            focusedBorder: border(c.headerColor),
          ),
        ),
        const PanelText('Aparece na saudação e nos documentos exportados.'),
      ],
    );
  }
}

class _ThemePanel extends ConsumerWidget {
  const _ThemePanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Panel(
      title: '🎨 Tema',
      children: [
        SegButtons<ThemeMode>(
          value: ref.watch(themeModeProvider),
          onChanged: ref.read(themeModeProvider.notifier).set,
          options: const [
            (ThemeMode.system, 'Automático'),
            (ThemeMode.light, 'Claro'),
            (ThemeMode.dark, 'Escuro'),
          ],
        ),
      ],
    );
  }
}

class _RemindersPanel extends ConsumerWidget {
  const _RemindersPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final cfg = ref.watch(notebookProvider.select((n) => n.config));
    final notifier = ref.read(notebookProvider.notifier);

    void update(Config next) => notifier.setConfig(next);

    void setReminder(Period p, ReminderConfig r) =>
        update(cfg.copyWith(reminders: {...cfg.reminders, p: r}));

    Future<void> pickTime(Period p) async {
      final parts = cfg.reminder(p).time.split(':');
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
      if (t == null) return;
      final s =
          '${t.hour.toString().padLeft(2, '0')}:'
          '${t.minute.toString().padLeft(2, '0')}';
      setReminder(p, cfg.reminder(p).copyWith(time: s));
    }

    return Panel(
      title: '🔔 Lembretes',
      children: [
        SegButtons<bool>(
          value: cfg.remindersOn,
          onChanged: (v) {
            update(cfg.copyWith(remindersOn: v));
            if (v) ref.read(notificationServiceProvider).requestPermission();
          },
          options: const [(true, 'Avisar'), (false, 'Não avisar')],
        ),
        PanelText(
          'Se até o horário ainda não houver anotação no período, o app '
          'avisa uma vez.',
        ),
        AppButton(
          '🔔 Enviar notificação de teste',
          kind: AppButtonKind.ghost,
          onTap: () => testNotifications(context, ref),
        ),
        if (cfg.remindersOn)
          for (final p in cfg.periods)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${p.icon} ${p.label} até',
                      style: TextStyle(
                        fontSize: 16,
                        color: cfg.reminder(p).enabled ? c.ink : c.muted,
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => pickTime(p),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: c.bg,
                        border: Border.all(color: c.line, width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        cfg.reminder(p).time,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  Switch(
                    value: cfg.reminder(p).enabled,
                    onChanged: (v) =>
                        setReminder(p, cfg.reminder(p).copyWith(enabled: v)),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}

class _SetupPanel extends ConsumerWidget {
  const _SetupPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final cfg = ref.watch(notebookProvider.select((n) => n.config));
    final notifier = ref.read(notebookProvider.notifier);

    void togglePeriod(Period p) {
      final on = cfg.periods.contains(p);
      if (on && cfg.periods.length == 1) return; // pelo menos um período
      notifier.setConfig(
        cfg.copyWith(
          periods: [
            for (final q in Period.values)
              if (q == p ? !on : cfg.periods.contains(q)) q,
          ],
        ),
      );
    }

    Widget label(String t) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(t, style: TextStyle(fontSize: 14, color: c.muted)),
    );

    return Panel(
      title: '⚙️ Ajustar caderno',
      children: [
        label('Duração (dias)'),
        DaysChips(
          days: cfg.days,
          onChanged: (v) => changeDays(context, ref, v),
        ),
        label('Braços'),
        SegButtons<ArmsMode>(
          value: cfg.arms,
          onChanged: (v) => notifier.setConfig(cfg.copyWith(arms: v)),
          options: const [
            (ArmsMode.both, 'Os dois'),
            (ArmsMode.left, 'Esquerdo'),
            (ArmsMode.right, 'Direito'),
          ],
        ),
        label('Pulso'),
        SegButtons<bool>(
          value: cfg.pulse,
          onChanged: (v) => notifier.setConfig(cfg.copyWith(pulse: v)),
          options: const [(true, 'Anotar'), (false, 'Não anotar')],
        ),
        label('Períodos do dia'),
        Row(
          spacing: 8,
          children: [
            for (final p in Period.values)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => togglePeriod(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cfg.periods.contains(p)
                          ? c.brandSoft
                          : Colors.transparent,
                      border: Border.all(
                        color: cfg.periods.contains(p) ? c.brand : c.line,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${p.icon} ${p.label}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: cfg.periods.contains(p) ? c.brand : c.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const PanelText(
          'Mudar isso não apaga nada do que já foi anotado: só mostra ou '
          'esconde.',
        ),
      ],
    );
  }
}

class _ResetPanel extends ConsumerWidget {
  const _ResetPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cfg = ref.watch(notebookProvider.select((n) => n.config));
    final notifier = ref.read(notebookProvider.notifier);

    return Panel(
      title: '🧹 Recomeçar',
      children: [
        for (final p in cfg.periods)
          AppButton(
            'Limpar todos os registros da ${p.label.toLowerCase()}',
            kind: AppButtonKind.ghost,
            onTap: () async {
              final ok = await confirm(
                context,
                title: 'Limpar a ${p.label.toLowerCase()}?',
                message:
                    'Os registros da ${p.label.toLowerCase()} de todos os '
                    'dias serão apagados.',
                ok: 'Limpar',
              );
              if (ok) notifier.clearAllOfPeriod(p);
            },
          ),
        AppButton(
          'Apagar tudo',
          kind: AppButtonKind.danger,
          onTap: () async {
            final ok = await confirm(
              context,
              title: 'Apagar tudo?',
              message:
                  'Todas as anotações serão apagadas. O nome e os ajustes '
                  'do caderno ficam.',
              ok: 'Apagar',
            );
            if (ok) notifier.eraseAll();
          },
        ),
      ],
    );
  }
}
