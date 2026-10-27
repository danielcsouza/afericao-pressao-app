import 'package:diario_pressao/app/providers.dart';
import 'package:diario_pressao/data/storage.dart';
import 'package:diario_pressao/domain/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(ProviderContainer, Storage)> _make([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final storage = Storage(await SharedPreferences.getInstance());
  final c = ProviderContainer(overrides: [storageProvider.overrideWithValue(storage)]);
  addTearDown(c.dispose);
  return (c, storage);
}

void main() {
  test('caderno novo vem vazio e não configurado', () async {
    final (c, _) = await _make();
    final nb = c.read(notebookProvider);
    expect(nb.configured, false);
    expect(nb.data, isEmpty);
  });

  test('anotações e config sobrevivem a recarregar', () async {
    final (c, storage) = await _make();
    final n = c.read(notebookProvider.notifier);
    n.finishSetup(name: '  Maria   Silva ', start: '2026-03-01', config: const Config(days: 7, arms: ArmsMode.left));
    n.setEntry(0, Period.m, const Entry(time: '08:00', left: Reading(s: '13', d: '8', p: '70')));

    final reloaded = storage.loadNotebook();
    expect(reloaded.configured, true);
    expect(reloaded.start, '2026-03-01');
    expect(reloaded.config.days, 7);
    expect(reloaded.config.arms, ArmsMode.left);
    expect(reloaded.entry(0, Period.m).left.s, '13');
    expect(reloaded.entry(0, Period.m).time, '08:00');
  });

  test('apagar tudo mantém nome e config', () async {
    final (c, storage) = await _make();
    final n = c.read(notebookProvider.notifier);
    n.finishSetup(name: 'Ana', start: '2026-03-01', config: const Config(days: 10));
    n.setEntry(2, Period.t, const Entry(left: Reading(s: '12', d: '8')));
    n.eraseAll();
    final nb = storage.loadNotebook();
    expect(nb.data, isEmpty);
    expect(nb.name, 'Ana');
    expect(nb.config.days, 10);
  });

  test('limpar por período só afeta aquele período', () async {
    final (c, _) = await _make();
    final n = c.read(notebookProvider.notifier);
    n.setEntry(0, Period.m, const Entry(left: Reading(s: '12', d: '8')));
    n.setEntry(1, Period.m, const Entry(left: Reading(s: '12', d: '8')));
    n.setEntry(0, Period.t, const Entry(left: Reading(s: '12', d: '8')));
    n.clearAllOfPeriod(Period.m);
    final nb = c.read(notebookProvider);
    expect(nb.entry(0, Period.m).isEmptyForTest, true);
    expect(nb.entry(1, Period.m).isEmptyForTest, true);
    expect(nb.entry(0, Period.t).left.done, true);
  });

  test('JSON corrompido volta ao caderno vazio', () async {
    final (c, _) = await _make({Storage.notebookKey: '{nao é json'});
    expect(c.read(notebookProvider).configured, false);
  });

  test('tema persiste', () async {
    final (c, storage) = await _make();
    c.read(themeModeProvider.notifier).set(ThemeMode.dark);
    expect(storage.loadTheme(), ThemeMode.dark);
  });
}

extension on Entry {
  bool get isEmptyForTest => time.isEmpty && left.isEmpty && right.isEmpty;
}
