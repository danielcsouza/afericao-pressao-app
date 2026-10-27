import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/providers.dart';
import 'data/storage.dart';
import 'notifications/notification_service.dart';
import 'ui/setup_gate.dart';
import 'ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final prefs = await SharedPreferences.getInstance();

  final NotificationService notifications =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? LocalNotificationService()
      : const NoopNotificationService();
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        storageProvider.overrideWithValue(Storage(prefs)),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const DiarioApp(),
    ),
  );
}

class DiarioApp extends ConsumerWidget {
  const DiarioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Diário da Pressão',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => _ReminderLifecycle(child: child!),
      home: const SetupGate(),
    );
  }
}

/// Mantém os lembretes agendados: ao abrir e ao voltar ao app (a janela de
/// agendamento avança com o tempo).
class _ReminderLifecycle extends ConsumerStatefulWidget {
  const _ReminderLifecycle({required this.child});
  final Widget child;

  @override
  ConsumerState<_ReminderLifecycle> createState() => _ReminderLifecycleState();
}

class _ReminderLifecycleState extends ConsumerState<_ReminderLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(reminderSyncProvider).run();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(reminderSyncProvider); // liga a escuta do caderno
    return widget.child;
  }
}
