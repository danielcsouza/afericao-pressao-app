import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'shell.dart';
import 'wizard.dart';

/// Mostra o wizard enquanto o caderno não foi configurado; depois, o [Shell].
class SetupGate extends ConsumerWidget {
  const SetupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configured = ref.watch(notebookProvider.select((n) => n.configured));
    return configured ? const Shell() : const Wizard();
  }
}
