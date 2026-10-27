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
