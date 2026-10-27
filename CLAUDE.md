# Diário da Pressão (Flutter, Android)

Porte do PWA "Pressão Arterial" (referência em `reference/index.html`, somente leitura) para Flutter, com extras. O app é um **caderno para anotar**, não mede nem diagnostica: evitar a palavra "aferição" no nome/textos de marca.

- Plano completo, decisões e especificação visual: `docs/plano-portabilidade.md` (leia antes de implementar telas; o Adendo B tem tokens de cor, medidas e layouts de PDF/impressão).
- ID do app: `br.com.danielsistemas.diario_pressao` (definitivo, não mudar). Pacote Dart: `diario_pressao`. Rótulo: "Diário da Pressão". Só Android.
- Idioma da UI e dos comentários: pt-BR.
- Não adicionar linhas Co-Authored-By nem "Generated with Claude Code" em commits.

## Decisões fechadas
Duração 1–365 dias; até 3 períodos (manhã/tarde/noite), cada um opcional (mín. 1); braços: ambos/esquerdo/direito; pulso opcional; lembrete = uma notificação local no horário do período se ainda não há nenhuma anotação nele (sem repetição, sem servidor); sem importar dados do PWA; publicação na Play Store; visual o mais próximo possível do PWA; PDF/impressão/CSV mantidos e dinâmicos.

## Estado
Feito: projeto criado, dependências, `lib/domain/` (models, rules, dates, input) com testes em `test/domain_test.dart` (18 passando); armazenamento (`lib/data/storage.dart`), providers Riverpod (`lib/app/providers.dart`), tema com tokens do PWA (`lib/ui/theme.dart`), `Shell` com cabeçalho + barra inferior e abas ainda vazias (`lib/ui/shell.dart`); `SetupGate` mostra o wizard de 7 passos (`lib/ui/wizard.dart`) até o caderno ser configurado; o pedido de permissão de notificação fica para a etapa de notificações. Aba Anotar pronta (`lib/ui/anotar_tab.dart`: navegação por dia, cartões por período, campos com a digitação "como falamos", limpar período). Aba Resumo pronta (`lib/ui/resumo_tab.dart`; painéis e chips de duração em `lib/ui/widgets.dart`, reaproveitáveis em Mais). Aba Mais pronta, sem imprimir/exportar (`lib/ui/mais_tab.dart`; regra de mudar duração em `lib/ui/actions.dart`). 46 testes passando; app roda no emulador (build exige core library desugaring, já configurado). Nos testes de widget, fixe o dia com `selectedDayProvider.set(0)`: o app abre no dia de hoje.
Notificações locais prontas: planejamento puro em `lib/domain/reminders.dart` (14 dias à frente, só períodos sem anotação), serviço em `lib/notifications/notification_service.dart` (nos testes entra o `NoopNotificationService`), reagendamento automático ao mudar o caderno e ao voltar ao app, botão "Enviar notificação de teste" em Mais (pede a permissão e avisa se alarmes exatos não estão liberados). Manifesto com `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` e receptores do plugin. Validado no emulador (Android 16). A aba do meio se chama "Agenda". 54 testes passando.
Próximos passos (ordem do plano): PDF/CSV/impressão (inclui os painéis 🖨️ Imprimir e 📤 Exportar em Mais) → **ícone do app e splash** (reaproveitar `reference/icons/`; ícone adaptativo, splash `#c0392b`, e ícone pequeno próprio para as notificações, hoje usa o do launcher) → build `.aab` → ficha da Play Store. A declaração de `SCHEDULE_EXACT_ALARM` precisa de justificativa na Play Console.

## Comandos
`flutter test` · `flutter analyze` · `flutter run`
