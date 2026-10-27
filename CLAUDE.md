# Diário da Pressão (Flutter, Android)

Porte do PWA "Pressão Arterial" (referência em `reference/index.html`, somente leitura) para Flutter, com extras. O app é um **caderno para anotar**, não mede nem diagnostica: evitar a palavra "aferição" no nome/textos de marca.

- Plano completo, decisões e especificação visual: `docs/plano-portabilidade.md` (leia antes de implementar telas; o Adendo B tem tokens de cor, medidas e layouts de PDF/impressão).
- ID do app: `br.com.danielsistemas.diario_pressao` (definitivo, não mudar). Pacote Dart: `diario_pressao`. Rótulo: "Diário da Pressão". Só Android.
- Idioma da UI e dos comentários: pt-BR.
- Não adicionar linhas Co-Authored-By nem "Generated with Claude Code" em commits.

## Decisões fechadas
Duração 1–365 dias; até 3 períodos (manhã/tarde/noite), cada um opcional (mín. 1); braços: ambos/esquerdo/direito; pulso opcional; lembrete = uma notificação local no horário do período se ainda não há nenhuma anotação nele (sem repetição, sem servidor); sem importar dados do PWA; publicação na Play Store; visual o mais próximo possível do PWA; PDF/impressão/CSV mantidos e dinâmicos.

## Estado
Feito: projeto criado, dependências, `lib/domain/` (models, rules, dates, input) com testes em `test/domain_test.dart` (18 passando); armazenamento (`lib/data/storage.dart`), providers Riverpod (`lib/app/providers.dart`), tema com tokens do PWA (`lib/ui/theme.dart`), `Shell` com cabeçalho + barra inferior e abas ainda vazias (`lib/ui/shell.dart`); `SetupGate` mostra um wizard provisório (só "Usar padrão"). 25 testes passando.
Próximos passos (ordem do plano): wizard de primeiro acesso (substituir `_WizardPlaceholder` em `lib/ui/setup_gate.dart`) → abas Anotar / Resumo / Mais → PDF/CSV/impressão → notificações locais → ícone/splash/build `.aab` → ficha da Play Store.

## Comandos
`flutter test` · `flutter analyze` · `flutter run`
