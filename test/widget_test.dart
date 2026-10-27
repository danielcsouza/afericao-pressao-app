import 'package:diario_pressao/app/providers.dart';
import 'package:diario_pressao/data/storage.dart';
import 'package:diario_pressao/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('primeiro acesso → "Usar padrão" → abas na barra inferior', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = Storage(await SharedPreferences.getInstance());
    await tester.pumpWidget(ProviderScope(
      overrides: [storageProvider.overrideWithValue(storage)],
      child: const DiarioApp(),
    ));

    expect(find.text('Usar padrão'), findsOneWidget);
    await tester.tap(find.text('Usar padrão'));
    await tester.pumpAndSettle();

    expect(find.text('Dia 1 de 30'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
    expect(find.text('30 dias'), findsOneWidget);

    await tester.tap(find.text('Mais'));
    await tester.pumpAndSettle();
    expect(find.text('Diário da Pressão'), findsOneWidget);
  });
}
