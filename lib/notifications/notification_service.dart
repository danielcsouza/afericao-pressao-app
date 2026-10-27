import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../domain/reminders.dart';

/// Situação das permissões que os lembretes precisam.
class NotificationStatus {
  const NotificationStatus({
    required this.notifications,
    required this.exactAlarms,
  });

  /// Notificações liberadas para o app (Android 13+ pede ao usuário).
  final bool notifications;

  /// Alarmes exatos liberados; sem isso o aviso pode atrasar alguns minutos.
  final bool exactAlarms;
}

abstract class NotificationService {
  Future<void> init();
  Future<NotificationStatus> status();

  /// Pede a permissão de notificação. Devolve se ficou liberada.
  Future<bool> requestPermission();

  /// Abre a tela do sistema para liberar alarmes exatos.
  Future<void> requestExactAlarms();

  /// Troca os lembretes agendados por [plan].
  Future<void> sync(List<PlannedReminder> plan);

  /// Mostra uma notificação agora, para conferir se tudo está liberado.
  Future<void> sendTest();
}

/// Usada nos testes e fora do Android: não faz nada e diz que está tudo liberado.
class NoopNotificationService implements NotificationService {
  const NoopNotificationService();

  @override
  Future<void> init() async {}

  @override
  Future<NotificationStatus> status() async =>
      const NotificationStatus(notifications: true, exactAlarms: true);

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> requestExactAlarms() async {}

  @override
  Future<void> sync(List<PlannedReminder> plan) async {}

  @override
  Future<void> sendTest() async {}
}

class LocalNotificationService implements NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();

  static const _testId = 1000000;
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'lembretes',
      'Lembretes',
      channelDescription: 'Avisa quando falta anotar a pressão de um período',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  // Uma sincronização por vez, para não misturar cancelamento e agendamento.
  Future<void> _queue = Future.value();

  @override
  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('Fuso horário não identificado, usando o padrão: $e');
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
  }

  @override
  Future<NotificationStatus> status() async {
    final a = _android;
    return NotificationStatus(
      notifications: await a?.areNotificationsEnabled() ?? false,
      exactAlarms: await a?.canScheduleExactNotifications() ?? false,
    );
  }

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<void> requestExactAlarms() async {
    await _android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> sync(List<PlannedReminder> plan) {
    return _queue = _queue.then((_) => _sync(plan)).catchError((Object e) {
      debugPrint('Falha ao agendar lembretes: $e');
    });
  }

  Future<void> _sync(List<PlannedReminder> plan) async {
    await _plugin.cancelAllPendingNotifications();
    if (plan.isEmpty) return;
    final exact = await _android?.canScheduleExactNotifications() ?? false;
    for (final r in plan) {
      final p = r.period;
      await _plugin.zonedSchedule(
        id: r.id,
        title: '${p.icon} Hora de anotar a pressão',
        body: 'Ainda não há anotação da ${p.label.toLowerCase()} de hoje.',
        scheduledDate: tz.TZDateTime.from(r.at, tz.local),
        notificationDetails: _details,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> sendTest() => _plugin.show(
    id: _testId,
    title: '✅ Lembretes funcionando',
    body: 'Este é um aviso de teste do Diário da Pressão.',
    notificationDetails: _details,
  );
}
