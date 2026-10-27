import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
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
