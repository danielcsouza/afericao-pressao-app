import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'shell.dart';
import 'theme.dart';

/// Mostra o wizard enquanto o caderno não foi configurado; depois, o [Shell].
class SetupGate extends ConsumerWidget {
  const SetupGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configured = ref.watch(notebookProvider.select((n) => n.configured));
    return configured ? const Shell() : const _WizardPlaceholder();
  }
}

// TODO: substituir pelo wizard de 7 passos (próxima etapa).
class _WizardPlaceholder extends ConsumerWidget {
  const _WizardPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.headerColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                const Text('❤️', style: TextStyle(fontSize: 64)),
                const Text(
                  'Diário da Pressão',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: c.headerColor),
                  onPressed: () => ref.read(notebookProvider.notifier).finishSetup(),
                  child: const Text('Usar padrão'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
