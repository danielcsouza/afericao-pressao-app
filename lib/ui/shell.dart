import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import 'anotar_tab.dart';
import 'mais_tab.dart';
import 'resumo_tab.dart';
import 'theme.dart';

/// Cabeçalho fixo, conteúdo da aba e barra inferior (Adendo B do plano).
class Shell extends ConsumerWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final tab = ref.watch(tabProvider);
    final days = ref.watch(notebookProvider.select((n) => n.config.days));
    final day = ref.watch(selectedDayProvider);
    final percent = ref.watch(rulesProvider).progressPercent();

    final title = tab == 0 ? 'Dia ${day + 1} de $days' : 'Diário da Pressão';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: c.statusBar,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: c.headerColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            _Header(title: title, percent: percent),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: IndexedStack(
                    index: tab,
                    children: const [
                      AnotarTab(),
                      ResumoTab(),
                      MaisTab(),
                    ],
                  ),
                ),
              ),
            ),
            _BottomBar(
              index: tab,
              middleLabel: '$days ${days == 1 ? 'dia' : 'dias'}',
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.percent});
  final String title;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.headerColor,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: .15),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.brandInk,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .2),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$percent%',
                  style: const TextStyle(
                    color: AppColors.brandInk,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.index, required this.middleLabel});
  final int index;
  final String middleLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final items = [('✍️', 'Anotar'), ('📅', middleLabel), ('⚙️', 'Mais')];
    return Material(
      color: c.headerColor,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .15),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => ref.read(tabProvider.notifier).set(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: i == index
                                ? Colors.white.withValues(alpha: .3)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            items[i].$1,
                            style: const TextStyle(fontSize: 22, height: 1.2),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$2,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(
                              alpha: i == index ? 1 : .88,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
