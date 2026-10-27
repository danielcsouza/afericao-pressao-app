import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../domain/rules.dart';
import 'widgets.dart';

/// Muda a duração do caderno. Reduzir abaixo do último dia com anotação pede
/// confirmação; as anotações são preservadas (só deixam de aparecer).
Future<void> changeDays(BuildContext context, WidgetRef ref, int days) async {
  final nb = ref.read(notebookProvider);
  if (days == nb.config.days) return;
  final last = ref.read(rulesProvider).lastDayWithData();
  if (days - 1 < last) {
    final ok = await confirm(
      context,
      title: 'Reduzir para $days dias?',
      message:
          'Há anotações até o dia ${last + 1}. Elas continuam guardadas, '
          'mas não aparecem enquanto o caderno for menor.',
      ok: 'Reduzir',
    );
    if (!ok) return;
  }
  ref.read(notebookProvider.notifier).setConfig(nb.config.copyWith(days: days));
}

/// "Enviar notificação de teste": confere a permissão (pedindo, se faltar),
/// manda um aviso agora e explica o resultado.
Future<void> testNotifications(BuildContext context, WidgetRef ref) async {
  final svc = ref.read(notificationServiceProvider);
  var granted = await svc.permissionGranted();
  if (!granted) {
    granted = await svc.requestPermission();
  }
  if (!context.mounted) return;

  if (!granted) {
    await _info(
      context,
      title: 'Notificações bloqueadas',
      message:
          'O Android não deixou o app avisar. Abra Configurações › Apps › '
          'Diário da Pressão › Notificações e ative, depois teste de novo.',
    );
    return;
  }

  await svc.sendTest();
  if (!context.mounted) return;
  await _info(
    context,
    title: 'Teste enviado ✓',
    message:
        'Se o aviso apareceu na barra de notificações, está tudo certo. Os '
        'lembretes podem chegar com alguns minutos de diferença do horário.',
  );
}

Future<void> _info(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<void>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
    ],
  ),
);

String _reasonText(IncompleteEntry e) {
  final x = e.period.label.toLowerCase();
  return switch (e.reason) {
    Incomplete.missingTime =>
      'Informe a hora da $x. A hora da medição é obrigatória.',
    Incomplete.halfReading =>
      'Falta a alta ou a baixa na $x. Complete os valores de cada braço.',
    Incomplete.timeWithoutValues =>
      'A $x tem hora, mas nenhum valor. Anote os valores ou apague o registro.',
  };
}

/// Pode sair do dia [day]? Bloqueia só se a pessoa editou um período dele nesta
/// visita e o deixou incompleto (hora ou valores faltando). Quem apenas olha
/// um dia, ou navega sem digitar, nunca é barrado. O aviso sempre oferece uma
/// saída: completar ou apagar o registro começado.
Future<bool> canLeaveDay(BuildContext context, WidgetRef ref, int day) async {
  while (true) {
    final edited = ref.read(editedPeriodsProvider);
    final problems = ref
        .read(rulesProvider)
        .incompleteEntries(day: day)
        .where((e) => edited.contains((e.day, e.period)))
        .toList();
    if (problems.isEmpty) return true;

    final p = problems.first;
    final x = p.period.label.toLowerCase();
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registro incompleto'),
        content: Text(_reasonText(p)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Apagar o registro da $x'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Completar'),
          ),
        ],
      ),
    );
    if (!context.mounted || discard != true) return false;
    ref.read(notebookProvider.notifier).clearPeriod(p.day, p.period);
    ref.read(editedPeriodsProvider.notifier).unmark(p.day, p.period);
  }
}

/// Antes de imprimir ou compartilhar: um documento para o médico não pode ter
/// registro sem hora ou com valor pela metade, em nenhum dia.
Future<bool> ensureNothingIncomplete(
  BuildContext context,
  WidgetRef ref,
) async {
  final all = ref.read(rulesProvider).incompleteEntries();
  if (all.isEmpty) return true;

  final first = all.first;
  final more = all.length > 1 ? ' (e mais ${all.length - 1})' : '';
  final goto = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Há registros incompletos'),
      content: Text(
        'Dia ${first.day + 1}, ${first.period.label.toLowerCase()}$more: '
        '${_reasonText(first)}\n\nCorrija antes de gerar o documento.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text('Ir para o dia ${first.day + 1}'),
        ),
      ],
    ),
  );
  if (goto == true) {
    ref.read(selectedDayProvider.notifier).set(first.day);
    ref.read(tabProvider.notifier).set(0);
  }
  return false;
}
