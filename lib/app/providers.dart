import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/storage.dart';
import '../domain/dates.dart';
import '../domain/models.dart';
import '../domain/rules.dart';

/// Sobrescrito em `main` com a instância já carregada.
final storageProvider = Provider<Storage>((ref) => throw UnimplementedError());

class NotebookNotifier extends Notifier<Notebook> {
  @override
  Notebook build() => ref.read(storageProvider).loadNotebook();

  void _set(Notebook nb) {
    state = nb;
    ref.read(storageProvider).saveNotebook(nb);
  }

  void setName(String name) =>
      _set(state.copyWith(name: name.trim().replaceAll(RegExp(r'\s+'), ' ')));

  void setStart(String iso) => _set(state.copyWith(start: iso));

  void setConfig(Config c) => _set(state.copyWith(config: c));

  /// Conclui o wizard (ou "Usar padrão"): grava a data de início se ainda não houver.
  void finishSetup({String? name, String? start, Config? config}) => _set(
    state.copyWith(
      name: name,
      start:
          start ?? (state.start.isEmpty ? isoOf(DateTime.now()) : state.start),
      config: config,
      configured: true,
    ),
  );

  void setEntry(int day, Period p, Entry e) => _set(state.withEntry(day, p, e));

  void clearPeriod(int day, Period p) => _set(state.clearPeriod(day, p));

  /// "Limpar por período": apaga todas as anotações de um período.
  void clearAllOfPeriod(Period p) {
    var nb = state;
    for (final d in state.data.keys) {
      nb = nb.clearPeriod(d, p);
    }
    _set(nb);
  }

  /// "Apagar tudo": mantém o nome e a configuração, como no app web.
  void eraseAll() => _set(state.copyWith(data: const {}));
}

final notebookProvider = NotifierProvider<NotebookNotifier, Notebook>(
  NotebookNotifier.new,
);

final rulesProvider = Provider<Rules>(
  (ref) => Rules(ref.watch(notebookProvider)),
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ref.read(storageProvider).loadTheme();

  void set(ThemeMode m) {
    state = m;
    ref.read(storageProvider).saveTheme(m);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Dia exibido na aba Anotar (índice 0-based).
class SelectedDayNotifier extends Notifier<int> {
  @override
  int build() {
    final nb = ref.read(notebookProvider);
    final t = todayIndex(nb.start);
    return (t ?? 0).clamp(0, nb.config.days - 1);
  }

  void set(int i) => state = i;
}

final selectedDayProvider = NotifierProvider<SelectedDayNotifier, int>(
  SelectedDayNotifier.new,
);

/// Aba atual: 0 Anotar, 1 Resumo, 2 Mais.
class TabNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void set(int i) => state = i;
}

final tabProvider = NotifierProvider<TabNotifier, int>(TabNotifier.new);
