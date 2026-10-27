import 'package:diario_pressao/app/providers.dart';
import 'package:diario_pressao/data/storage.dart';
import 'package:diario_pressao/domain/reminders.dart';
import 'package:diario_pressao/main.dart';
import 'package:diario_pressao/notifications/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeNotifications implements NotificationService {
  bool allowed = false;
  int permissionRequests = 0;
  int tests = 0;

  @override
  Future<void> init() async {}

  @override
  Future<bool> permissionGranted() async => allowed;

  @override
  Future<bool> requestPermission() async {
    permissionRequests++;
    return allowed;
  }

  @override
  Future<void> sync(List<PlannedReminder> plan) async {}

  @override
  Future<void> sendTest() async => tests++;
}

void main() {
  testWidgets('passo de lembretes: pede permissão e envia o teste', (
    tester,
  ) async {
    final svc = _FakeNotifications();
    SharedPreferences.setMockInitialValues({});
    final storage = Storage(await SharedPreferences.getInstance());
    await tester.binding.setSurfaceSize(const Size(400, 900));
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
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.text('Avançar'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Lembretes'), findsOneWidget);

    // Desligado: o botão de teste some. Ligado: aparece e pede a permissão.
    await tester.tap(find.text('Não avisar'));
    await tester.pumpAndSettle();
    expect(find.text('🔔 Enviar notificação de teste'), findsNothing);
    await tester.tap(find.text('Avisar'));
    await tester.pumpAndSettle();
    expect(svc.permissionRequests, 1);

    // Permissão negada: avisa e não envia nada.
    await tester.tap(find.text('🔔 Enviar notificação de teste'));
    await tester.pumpAndSettle();
    expect(find.text('Notificações bloqueadas'), findsOneWidget);
    expect(svc.tests, 0);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Liberada: envia o teste.
    svc.allowed = true;
    await tester.tap(find.text('🔔 Enviar notificação de teste'));
    await tester.pumpAndSettle();
    expect(find.text('Teste enviado ✓'), findsOneWidget);
    expect(svc.tests, 1);
  });

  testWidgets('"Outro": confirmar pelo teclado aplica o valor', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = Storage(await SharedPreferences.getInstance());
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(storage)],
        child: const DiarioApp(),
      ),
    );

    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '10');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Quantos dias?'), findsNothing);
    expect(find.text('10'), findsOneWidget); // o chip "Outro" passa a mostrar 10
    expect(tester.takeException(), isNull);
  });

  testWidgets('resumo final: uma linha por escolha', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = Storage(await SharedPreferences.getInstance());
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [storageProvider.overrideWithValue(storage)],
        child: const DiarioApp(),
      ),
    );
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('7'));
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Só o esquerdo'));
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não'));
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Não avisar'));
    await tester.tap(find.text('Avançar'));
    await tester.pumpAndSettle();

    expect(find.text('Tudo pronto!'), findsOneWidget);
    expect(find.textContaining('7 dias: '), findsOneWidget);
    expect(find.text('Manhã, tarde e noite'), findsOneWidget);
    expect(find.text('Braço esquerdo'), findsOneWidget);
    expect(find.text('Sem pulso'), findsOneWidget);
    expect(find.text('Sem lembretes'), findsOneWidget);
  });
}
