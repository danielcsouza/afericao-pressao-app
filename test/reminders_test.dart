import 'package:diario_pressao/app/providers.dart';
import 'package:diario_pressao/data/storage.dart';
import 'package:diario_pressao/domain/models.dart';
import 'package:diario_pressao/domain/reminders.dart';
import 'package:diario_pressao/main.dart';
import 'package:diario_pressao/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Notebook _nb({
  Config config = const Config(days: 5, remindersOn: true),
  Map<int, Map<Period, Entry>> data = const {},
}) =>
    Notebook(start: '2026-03-01', configured: true, config: config, data: data);

void main() {
  final now = DateTime(
    2026,
    3,
    1,
    12,
    0,
  ); // dia 1, depois do horário da manhã (11:50)

  group('plannedReminders', () {
    test('agenda só o que ainda está no futuro', () {
      final plan = plannedReminders(_nb(), now);
      // dia 0: tarde e noite; dias 1–4: manhã, tarde e noite
      expect(plan.length, 2 + 4 * 3);
      expect(plan.first.period, Period.t);
      expect(plan.first.at, DateTime(2026, 3, 1, 18, 30));
      expect(plan.every((r) => r.at.isAfter(now)), true);
    });

    test('período já anotado não tem lembrete', () {
      final plan = plannedReminders(
        _nb(
          data: {
            0: {
              Period.t: const Entry(
                left: Reading(s: '12', d: '8'),
              ),
            },
          },
        ),
        now,
      );
      expect(plan.any((r) => r.day == 0 && r.period == Period.t), false);
      expect(plan.any((r) => r.day == 0 && r.period == Period.n), true);
    });

    test('desligado, período inativo ou lembrete do período desligado', () {
      expect(
        plannedReminders(_nb(config: const Config(days: 5)), now),
        isEmpty,
      );
      final onlyMorning = plannedReminders(
        _nb(
          config: const Config(days: 5, remindersOn: true, periods: [Period.m]),
        ),
        now,
      );
      expect(onlyMorning.every((r) => r.period == Period.m), true);

      final noEvening = plannedReminders(
        _nb(
          config: Config(
            days: 5,
            remindersOn: true,
            reminders: {
              Period.n: ReminderConfig(
                enabled: false,
                time: Period.n.defaultTime,
              ),
            },
          ),
        ),
        now,
      );
      expect(noEvening.any((r) => r.period == Period.n), false);
    });

    test('só dentro dos dias do caderno e do horizonte', () {
      final plan = plannedReminders(
        _nb(config: const Config(days: 60, remindersOn: true)),
        now,
        horizonDays: 3,
      );
      expect(
        plan.every(
          (r) => r.at.isBefore(now.add(const Duration(days: 3, minutes: 1))),
        ),
        true,
      );

      // caderno que ainda não começou: agenda a partir do início
      final future = plannedReminders(
        _nb(config: const Config(days: 2, remindersOn: true)),
        DateTime(2026, 2, 27, 9),
      );
      expect(future.map((r) => r.day).toSet(), {0, 1});
      // e nada depois do último dia
      final after = plannedReminders(_nb(), DateTime(2026, 3, 10));
      expect(after, isEmpty);
    });

    test('ids são estáveis e únicos por dia/período', () {
      final plan = plannedReminders(_nb(), now);
      expect(plan.map((r) => r.id).toSet().length, plan.length);
      expect(PlannedReminder(day: 2, period: Period.n, at: now).id, 2 * 3 + 2);
    });

    test('sem configurar ou sem data de início não agenda', () {
      expect(
        plannedReminders(
          const Notebook(config: Config(remindersOn: true)),
          now,
        ),
        isEmpty,
      );
      expect(
        plannedReminders(
          const Notebook(configured: true, config: Config(remindersOn: true)),
          now,
        ),
        isEmpty,
      );
    });
  });

  group('integração com o app', () {
    testWidgets('permissão, teste e agendamento passam pelo serviço', (
      tester,
    ) async {
      final svc = _FakeService();
      SharedPreferences.setMockInitialValues({});
      final storage = Storage(await SharedPreferences.getInstance());
      await tester.binding.setSurfaceSize(const Size(400, 3200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageProvider.overrideWithValue(storage),
            notificationServiceProvider.overrideWithValue(svc),
          ],
          child: const DiarioApp(),
        ),
      );
      final c = ProviderScope.containerOf(
        tester.element(find.byType(DiarioApp)),
      );
      final today = DateTime.now();
      c
          .read(notebookProvider.notifier)
          .finishSetup(
            start:
                '${today.year}-${today.month.toString().padLeft(2, '0')}-'
                '${today.day.toString().padLeft(2, '0')}',
            config: const Config(days: 30, remindersOn: true),
          );
      await tester.pumpAndSettle();
      expect(svc.syncs, isNotEmpty);
      expect(svc.syncs.last, isNotEmpty);

      await tester.tap(find.text('Mais'));
      await tester.pumpAndSettle();

      // permissão negada: aviso de bloqueio, nada enviado
      svc.allowed = false;
      await tester.tap(find.text('🔔 Enviar notificação de teste'));
      await tester.pumpAndSettle();
      expect(svc.permissionRequests, 1);
      expect(find.text('Notificações bloqueadas'), findsOneWidget);
      expect(svc.tests, 0);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      // liberada, mas sem alarme exato: envia e avisa do atraso
      svc.allowed = true;
      svc.exact = false;
      await tester.tap(find.text('🔔 Enviar notificação de teste'));
      await tester.pumpAndSettle();
      expect(svc.tests, 1);
      expect(find.text('Teste enviado ✓'), findsOneWidget);
      expect(find.textContaining('atrasar'), findsOneWidget);
      await tester.tap(find.text('Liberar alarmes'));
      await tester.pumpAndSettle();
      expect(svc.exactRequests, 1);

      // escolher "Avisar" pede a permissão
      await tester.tap(find.text('Não avisar'));
      await tester.pumpAndSettle();
      final before = svc.permissionRequests;
      await tester.tap(find.text('Avisar'));
      await tester.pumpAndSettle();
      expect(svc.permissionRequests, before + 1);
    });

    testWidgets('anotar um período tira o lembrete dele da lista', (
      tester,
    ) async {
      final svc = _FakeService();
      SharedPreferences.setMockInitialValues({});
      final storage = Storage(await SharedPreferences.getInstance());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageProvider.overrideWithValue(storage),
            notificationServiceProvider.overrideWithValue(svc),
          ],
          child: const DiarioApp(),
        ),
      );
      final c = ProviderScope.containerOf(
        tester.element(find.byType(DiarioApp)),
      );
      // início ontem: hoje é o dia 1, e a lista cobre vários dias
      final start = DateTime.now().subtract(const Duration(days: 1));
      c
          .read(notebookProvider.notifier)
          .finishSetup(
            start:
                '${start.year}-${start.month.toString().padLeft(2, '0')}-'
                '${start.day.toString().padLeft(2, '0')}',
            config: const Config(days: 30, remindersOn: true),
          );
      await tester.pumpAndSettle();
      final n = svc.syncs.length;
      final plan = svc.syncs.last;
      expect(plan, isNotEmpty);

      // digitar não muda a lista → não reagenda
      c
          .read(notebookProvider.notifier)
          .setEntry(
            29,
            Period.m,
            const Entry(left: Reading(s: '12')),
          ); // dia fora do que está agendado hoje
      await tester.pump();
      final first = plan.first;
      c
          .read(notebookProvider.notifier)
          .setEntry(
            first.day,
            first.period,
            const Entry(left: Reading(s: '12')),
          );
      await tester.pump();
      expect(svc.syncs.length, greaterThan(n));
      expect(
        svc.syncs.last.any(
          (r) => r.day == first.day && r.period == first.period,
        ),
        false,
      );
    });
  });
}

class _FakeService implements NotificationService {
  bool allowed = true;
  bool exact = true;
  int permissionRequests = 0;
  int exactRequests = 0;
  int tests = 0;
  final syncs = <List<PlannedReminder>>[];

  @override
  Future<void> init() async {}

  @override
  Future<NotificationStatus> status() async =>
      NotificationStatus(notifications: allowed, exactAlarms: exact);

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allowed;
  }

  @override
  Future<void> requestExactAlarms() async => exactRequests++;

  @override
  Future<void> sync(List<PlannedReminder> plan) async => syncs.add(plan);

  @override
  Future<void> sendTest() async => tests++;
}
