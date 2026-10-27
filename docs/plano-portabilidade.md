# Plano: portar "Pressão Arterial" (PWA) para Flutter

> Plano autocontido, feito para ser levado a um **novo repositório/diretório**. O app de origem fica em `c:\dev\js\pressao-arterial-app` (somente leitura durante o port; usar como referência de comportamento). Funções extras "simples" serão passadas pelo usuário depois.

## Contexto
O app atual é um caderno de pressão arterial de 30 dias (3 períodos/dia × 2 braços, pulso e hora opcionais), PWA de arquivo único (`index.html`, ~830 linhas de JS) + service worker + 2 Netlify Functions para push. Objetivo: app Flutter nativo com paridade total de funcionalidades, mais as extras a definir. Dados continuam 100% locais.

## Regras de negócio a portar literalmente (de `index.html`)
- **Modelo**: `{ name, start:"AAAA-MM-DD", data:{ [diaIdx 0..29]:{ [m|t|n]:{ t:"HH:MM", L:{s,d,p}, R:{s,d,p} } } } }`; valores como string. Tema e lembretes em chaves separadas.
- `norm(v)`: vazio→NaN; `n <= 30 ? n*10 : n` (13/8 = 130/80).
- `armDone` = s e d preenchidos; `periodDone` 0..2; `dayDone` 0..6; `totalDone` 0..180. Status do dia: verde = dois braços, laranja = um.
- `periodHasData`: tem `t` ou qualquer s/d/p em algum braço.
- `averages()`: por braço, média de s e d (via `norm`) só dos conjuntos completos; pulso = média arredondada de todos os pulsos informados. `armDiff()`: média de |sL−sR| nos períodos com os dois braços completos. `fmtAvg`: `round(n)/10` com vírgula decimal.
- Digitação: aceitar `13`→130; pular foco da alta para a baixa; aceitar formato do aparelho `12882`→`128/82`. Salva automaticamente. "Limpar registros da manhã/tarde/noite" por cartão; "Limpar por período" e "Apagar tudo" na aba Mais.
- Datas: sempre strings ISO locais + `DateTime(y,m,d)`; `todayIndex = dias entre start e hoje` (usar UTC só para a diferença, como no original, para evitar bug de horário de verão).
- Nome pedido na 1ª abertura (máx. 60 chars, espaços normalizados); saudação usa primeiro nome; vai no PDF/impressão.
- Lembretes padrão: manhã 11:50, tarde 18:30, noite 22:50; só dentro dos 30 dias; só se o período ainda não tem nenhuma anotação; uma vez por período/dia.

## Arquitetura Flutter proposta
- Pacotes: `flutter_riverpod` (ou provider), `shared_preferences` (mesmo JSON do original, facilita import/export), `intl` (pt_BR), `pdf` + `printing`, `share_plus`, `path_provider`, `flutter_local_notifications` + `timezone` + `flutter_timezone`, `package_info_plus` (opcional).
- Estrutura: `lib/domain` (modelo + regras puras: norm, médias, status — 100% testáveis), `lib/data` (repositório de armazenamento, export CSV/PDF), `lib/ui` (telas Anotar / 30 dias / Mais + onboarding de nome), `lib/notifications`.
- Tema: `ThemeMode` auto/claro/escuro com a paleta do original (primária `#c0392b`; escura `#7a2018` na barra). Material 3, `NavigationBar` com 3 destinos.
- Exportação: PDF via pacote `pdf` (substitui o gerador manual de ~100 linhas), A4 paisagem, 2 folhas de 15 dias, em branco ou preenchido; CSV com `;` e BOM UTF-8; compartilhar com `share_plus`.
- **Lembretes: notificações locais agendadas** (sem servidor, sem VAPID, sem Netlify). A cada gravação, cancelar a notificação do período se já houver dado; reagendar os próximos 7–10 dias (limite de 64 pendentes no iOS). Permissões: Android 13+ `POST_NOTIFICATIONS` e alarme exato; iOS pede permissão no uso. As Netlify Functions deixam de ser usadas pelo app novo.

## Etapas
1. Criar repo + `flutter create`, definir pacote/app id, CI básico (`flutter analyze`, `flutter test`).
2. Camada de domínio + testes unitários (portando os casos de `norm`, médias, status; gerar fixtures comparando com o JS atual).
3. Armazenamento + tema + navegação + onboarding de nome.
4. Aba Anotar (navegação por dia, 3 cartões, campos com formatter/foco).
5. Aba 30 dias (data de início, progresso, grade, médias e diferença).
6. Aba Mais (tema, lembretes, limpar período, apagar tudo, exportar).
7. PDF / CSV / imprimir / compartilhar.
8. Notificações locais + permissões.
9. Ícone/splash (reaproveitar `icons/icon-512.png`, `maskable-512.png`), build Android assinado; iOS se houver Mac/conta Apple.
10. Funções extras (a definir pelo usuário).
11. Publicação na Play Store (aab assinado, ficha, política de privacidade, teste fechado se exigido).

## Esforço
~11–17 dias úteis para paridade (Android), +1–2 dias iOS; cada função extra simples +0,5–1 dia. Maior parte: UI e input inteligente (4–6 d), lembretes locais (2–3 d), testes em aparelho (2–3 d).

## Verificação
- `flutter test`: regras de domínio idênticas ao JS (mesmos números para um conjunto de entradas).
- Rodar em emulador/aparelho Android: fluxo completo (nome → data de início → anotar → médias → exportar PDF/CSV → lembrete de teste).
- Comparar PDF/CSV gerados com os do app web para os mesmos dados.
- Conferir notificação chegando no horário e sendo cancelada após anotar o período.

---

# Adendo: funcionalidades extras (definidas pelo usuário)

## 1. Configuração flexível do caderno (`Config`)
Hoje tudo é fixo (`DAYS = 30`, braços `L`/`R`, pulso sempre visível, 3 períodos). Passa a ser um objeto `Config` salvo junto dos dados:
- `days` (int): duração do acompanhamento. Atalhos 7 / 15 / 30 / 60 / 90 + valor livre (1–365). Opção "sem fim" fica como decisão futura (grade, progresso e PDF assumem tamanho finito).
- `arms`: `both` | `left` | `right`. Com um braço só, some o cartão do outro, a "diferença entre braços" e a coluna do PDF/CSV.
- `pulse` (bool): mostra/oculta o campo de pulso (cartões, médias, PDF, CSV).
- `periods`: quais dos 3 períodos (manhã/tarde/noite) usar; mantém os 3 como padrão. (Suposição: o usuário pode desligar períodos, não criar novos.)
- `reminders`: por período `{ enabled, time }`, mais **limite máximo** (ver item 3).
- Tudo editável depois na aba **Mais** (a mesma tela do wizard, reaproveitada). Mudar `days`/`arms` depois **não apaga** dados já lançados; só oculta/estende. Reduzir `days` abaixo do último dia com dado pede confirmação.

Impacto no código portado: toda regra que usava `DAYS`, `ARMS` e `PERIODS` como constante passa a receber `Config` (`totalDone`, `dayDone`, `averages`, `armDiff`, grade de dias, impressão, PDF, CSV). `totalDone` máximo = `days × períodos ativos × braços`. A grade de dias deve quebrar linha de forma adaptativa (7 colunas) para qualquer `days`; a impressão A4 paginar por N dias (hoje 2 folhas × 15).

## 2. Wizard de primeiro acesso
Fluxo de telas, uma pergunta por vez, com Voltar/Avançar e barra de passos; mesmo visual do app atual (cartões arredondados, vermelho `#c0392b`):
1. Boas-vindas + **nome**.
2. **Duração** (chips 7/15/30/60/90/outro) + **data de início** (padrão hoje).
3. **Braços**: os dois / só esquerdo / só direito.
4. **Pulso**: sim / não.
5. **Períodos** do dia a medir (manhã/tarde/noite).
6. **Lembretes**: ativar? horário de cada período (o horário em que avisa se ainda não houver lançamento); pede permissão de notificação aqui.
7. Resumo + "Começar" → cai na aba Anotar.
Pode ser pulado com "Usar padrão" (30 dias, dois braços, com pulso, 3 períodos, lembretes padrão). O wizard roda uma vez; a mesma tela de configuração fica em Mais → "Ajustar caderno".

## 3. Lembretes por período (igual ao que existe hoje, só que local)
Não há regra nova: o "horário" de cada período já **é** o horário limite. Ex.: manhã 12:00 → se até as 12:00 não houver nenhum lançamento da manhã naquele dia, o app dispara **uma** notificação de lembrete. Só isso.
- Por período: **ativo/inativo** e **horário** (padrões atuais 11:50 / 18:30 / 22:50), editáveis no wizard e em Mais.
- Uma notificação por período e por dia; sem repetição. Se o período já tem qualquer anotação, a notificação daquele dia é cancelada/não dispara.
- Só dentro do intervalo `start..start+days` e só para períodos ativos.
- (A janela de 90 min do servidor atual é só tolerância para falha do cron; no app local não existe.)
- Implementação: notificações locais agendadas para os próximos 7–10 dias (limite de 64 no iOS), reagendadas ao abrir o app, gravar dado ou mudar a config; ao lançar dado de um período, cancela a notificação de hoje daquele período.

## 4. Visual fiel ao atual
- Extrair do `index.html` (bloco `<style>`, ~linhas 1–230) os tokens: cores claro/escuro, raios, sombras, tipografia, espaçamentos; mapear para `ThemeData` + `ThemeExtension` (cores de status verde/laranja, etc.). O app original é a referência: comparar capturas lado a lado em cada tela.
- Reproduzir: cabeçalho com saudação, barra de progresso, cartões de período com status, grade de dias com cores, aba inferior com 3 abas, convite/feedbacks.
- Em vez de uma `NavigationBar` Material padrão, estilizar para parecer com a barra atual.

## 5. Exportação e impressão (mantidas, agora dinâmicas)
- **PDF** (pacote `pdf`) e **impressão** (`printing`, A4 paisagem): tabela gerada a partir da `Config` (nº de dias, braços, pulso, períodos). Paginação automática (≈15 dias por folha), em branco ou preenchida, com nome e datas no cabeçalho.
- **CSV** (`;`, BOM UTF-8): colunas geradas conforme braços/pulso/períodos ativos.
- Compartilhar com `share_plus` (WhatsApp, e-mail).
- Teste de regressão: com a config padrão, o PDF/CSV deve ter o mesmo conteúdo do app web.

## Ajustes no cronograma
| Item | Dias adicionais |
| --- | --- |
| `Config` + adaptar todas as regras e telas (dias/braços/pulso/períodos variáveis) | +1,5–2 |
| Wizard de 7 passos + tela de ajustes reaproveitada | +1,5–2 |
| Lembretes locais configuráveis por período | +1 |
| PDF/impressão paginado dinâmico (em vez de 2×15 fixo) | +1 |
| Testes extras (combinações de config) | +1 |

**Novo total estimado: ~17–24 dias úteis (≈ 4–5 semanas) para Android; iOS +1–2.**

## Decisões fechadas
1. Duração: finita, de 1 a 365 dias (sem "sem fim").
2. Períodos: no máximo 3 por dia (manhã, tarde, noite), cada um opcional (só manhã, só tarde, manhã+tarde etc., conforme orientação médica). Mínimo 1 período ativo. Sem horários/quantidade livres.
3. Lembrete: uma notificação no horário do período, sem repetição.
4. Sem importação de dados do PWA (remover etapa 11 e o risco de migração).
5. Publicação: Google Play, na conta de desenvolvedor existente do usuário (junto dos outros apps). iOS/App Store fora do escopo por ora.

## Impacto das decisões na publicação (Play Store)
- Gerar **app bundle (.aab)** assinado com Play App Signing; criar keystore de upload e guardá-lo fora do repositório.
- `applicationId` novo e definitivo (ex.: `br.com.<dominio>.pressaoarterial`), `targetSdk` exigido pela Play na época do envio.
- Ficha da loja: ícone 512, imagem de destaque 1024×500, screenshots de celular, descrição em pt-BR.
- Política de privacidade (URL pública): app de saúde, dados só no aparelho, sem coleta/servidor; preencher "Segurança dos dados" e declaração de apps de saúde. Aviso de que não é dispositivo médico/diagnóstico.
- Permissões: `POST_NOTIFICATIONS`, e alarme exato (`SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM`) com justificativa de lembretes; atenção à política de alarmes exatos da Play. Receptor de boot (`RECEIVE_BOOT_COMPLETED`) para reagendar lembretes após reiniciar.
- Se a conta for pessoal criada recentemente: pode exigir teste fechado (12 testadores por 14 dias) antes da produção.
- Sem iOS: dispensa Mac/conta Apple; notificações locais do iOS (limite 64) deixam de ser restrição.

## Cronograma final (Android)
~16–22 dias úteis (sem import, sem iOS) incluindo ficha da loja e teste fechado em paralelo.


---

# Adendo B: especificação visual (para reproduzir no Flutter)

> Extraída de `index.html` (bloco `<style>` e funções `renderDay/renderSum/renderMore/buildPrint/buildPdf`). **Recomendado:** copiar para o novo repo uma pasta `reference/` com `index.html` e `icons/` (somente leitura) para comparar lado a lado. Fonte do app: `system-ui` (no Flutter: fonte padrão do sistema/Roboto), base 17px, line-height 1.4.

## Tokens de cor
| Token | Claro | Escuro |
| --- | --- | --- |
| bg | `#fbf7f6` | `#171212` |
| card | `#ffffff` | `#241c1c` |
| ink (texto) | `#2a1f1f` | `#f5eceb` |
| muted | `#7a6a6a` | `#b4a3a1` |
| line (bordas) | `#eadcd9` | `#3a2d2d` |
| brand | `#c0392b` | `#e5594a` |
| brand-ink | `#ffffff` | `#ffffff` |
| brand-soft | `#fbe6e3` | `#3a1f1c` |
| ok (verde) / ok-soft | `#2e8b57` / `#e3f4ea` | `#4cc380` / `#163223` |
| warn (laranja) / warn-soft | `#d98200` / `#fff2db` | `#f0a63a` / `#3a2a10` |
| left (braço esq.) | `#2c6fbb` | `#6fa8ee` |
| right (braço dir.) | `#8a4fb8` | `#c39af0` |
| danger / danger-line | `#b3261e` / `#e8b8b4` | `#ff8a80` / `#7a3a36` |
- Cabeçalho e barra inferior usam `brand` em ambos os temas; a barra de status do sistema: `#c0392b` (claro) / `#7a2018` (escuro). Sombras: cabeçalho `0 2px 10px rgba(0,0,0,.15)`, barra inferior `0 -2px 10px rgba(0,0,0,.15)`.
- Raio padrão dos cartões/painéis: **18**. Escolha de tema: Automático / Claro / Escuro (Automático segue o sistema).

## Estrutura de tela (todas as telas)
- **Cabeçalho fixo** (`header.app`): fundo brand, texto branco, padding 12/16, título 19px bold (`Dia X de N` na aba Anotar; `Pressão Arterial` nas outras) + **pílula** à direita com a % total de progresso (fundo branco 20% opaco, raio 99, 14px semibold, padding 4×12).
- **Conteúdo**: largura máx. 640, centralizado, padding 14 horizontal / 14 topo; espaço inferior ≈84 (altura da barra).
- **Barra inferior** (`nav.tabs`): fixa, fundo brand, 3 itens iguais (Anotar ✍️ / "N dias" 📅 / Mais ⚙️), rótulo 13px semibold branco 88%; ícone 22px dentro de "pílula" (padding 3×18, raio 99); o item ativo tem a pílula em branco 30% e o texto 100% branco. (No novo app o rótulo do meio vira "Resumo" ou "N dias", conforme a duração configurada.)

## Aba Anotar
- Saudação centralizada: `Olá, {primeiro nome}! 👋`, 19px bold.
- **Navegação de dias**: botão redondo **56×56** de cada lado (fundo brand, ícone ‹ › 34px bold branco, sombra `0 2px 6px rgba(0,0,0,.25)`, ao tocar escala .94; desabilitado: fundo `line`, texto muted, sem sombra, opacidade .7). Centro: `Dia X de N` 21px bold e abaixo a data longa pt-BR ("terça-feira, 5 de março") 15px muted capitalizada.
- Chip "Ir para hoje (dia X)" centralizado quando o dia exibido ≠ hoje: borda `line`, fundo card, raio 99, padding 6×14, 14px semibold muted.
- **Cartão de período** (um por período ativo): fundo card, **borda 2px**, raio 18, padding 14, margem inferior 14. Borda `line` (a fazer) / `ok` (completo) / `warn` (falta 1 braço).
  - Cabeçalho: `🌅 Manhã` / `☀️ Tarde` / `🌙 Noite` (19px bold, expande) + campo **Hora** (rótulo muted 14px + input de hora 100px, borda 1px `line`, raio 10, fundo bg) + **selo de status** (13px bold, raio 99, padding 3×10): "a fazer" (brand-soft/brand), "✓ completo" (ok-soft/ok), "falta 1 braço" (warn-soft/warn). Com 1 braço só configurado: "✓ completo" quando preenchido.
  - Grade 2 colunas (gap 6×12): **faixa colorida do braço** (texto branco bold 14, raio 10, `left` azul / `right` roxo, "Braço esquerdo"/"Braço direito"), depois por braço: legenda "Alta (sistólica) / Baixa (diastólica)" (13px bold, subtítulo 10px muted) e um par de campos numéricos separados por "/" (26px muted).
  - Campo numérico: altura **58**, texto 25px bold centralizado, borda 2px `line`, raio 14, fundo bg; em foco: borda brand e fundo card; placeholder "–" cor `line`. Teclado numérico (decimal).
  - Linha de **Pulso** (só se `pulse` ativo): legenda "Pulso / opcional" e campo único por braço (mesmo estilo).
  - Com **1 braço**: grade vira 1 coluna (faixa + campos ocupam a largura do cartão, mantendo as mesmas alturas).
  - Botão "🗑️ Limpar registros da {manhã|tarde|noite}": alinhado à direita, só aparece se há dado no período; borda 1px `line`, transparente, raio 99, 13px semibold muted, padding 7×14. Pede confirmação.
- Nota final centralizada 13px muted: "Digite como falamos: 13 e 8. Salva automaticamente neste aparelho."

## Aba Resumo ("N dias")
Painéis (`panel`): fundo card, borda 1px `line`, raio 18, padding 16, margem inferior 14; título 18px bold com emoji; texto 15px muted.
1. **📆 Quando começa?**: seletor de data (borda 2px `line`, raio 12, padding 10×12) + botão "Usar hoje" (pequeno, brand). Texto: "Termina em **dd/mm/aaaa**." (ou orientação se não definido). Novo: seletor de **duração** (chips 7/15/30/60/90/outro, 1–365) neste painel e no wizard.
2. **Progresso**: barra de 12px (fundo `line`, preenchimento `ok`, raio 99, animação .3s) + "X de Y medições feitas (…)"; o texto passa a refletir a config (ex.: "2 por dia: manhã e tarde × 1 braço").
3. **Os N dias**: grade de **5 colunas** (gap 8) de botões por dia: borda 2px `line`, fundo card, raio 14, padding 8×2×7; número do dia 18px bold, data curta `dd/mm` 11px muted, e **bolinhas** 9×9 (uma por período ativo): cinza `line` (nada), `ok` (completo), `warn` (meio). Hoje: borda brand; selecionado: fundo brand-soft. Tocar abre o dia na aba Anotar. Legenda: "Bolinhas: manhã · tarde · noite. Verde = os dois braços feitos; laranja = só um." (ajustar à config).
4. **Médias até agora**: tabela (linhas por braço: "● Esquerdo" azul / "● Direito" roxo, colunas Pressão `120,5 / 80,3`, Pulso, Medições); cabeçalho 13px muted, células 15px, linha inferior 1px `line`. Parágrafo da diferença média entre braços (só com os dois braços ativos e dados) e "Leve esses números na consulta. Quem interpreta é o médico." Coluna Pulso some se o pulso estiver desligado.

## Aba Mais (nesta ordem)
👤 Paciente (campo de nome, borda 2px, raio 12) · 🎨 Tema (3 botões segmentados: borda 2px `line`, raio 12; ativo: borda brand + fundo brand-soft + texto brand) · 🔔 Lembretes (linhas "🌅 Manhã até [hora]" + botões) · **(novo)** ⚙️ Ajustar caderno (duração, data de início, braços, pulso, períodos; mesma UI do wizard) · 🖨️ Imprimir (botão cheio "Folha em branco, para escrever à mão" + ghost "Folha com os valores já anotados") · 📤 Exportar (cheio "PDF com as medições" + ghost "Planilha (CSV, abre no Excel)") · 🧹 Recomeçar (botão `danger` "Apagar tudo"; nome permanece) · nota final: "Este app é só um caderno digital. Não faz diagnóstico nem substitui o médico." O painel "Instalar no celular" **não existe** no app nativo.
- **Botões**: `btn` = largura total, raio 14, padding 14×16, bold 16, brand/branco, margem superior 10; `ghost` = fundo card, borda 2px `line`; `danger` = fundo card, texto danger, borda 2px danger-line; `small` = inline, padding 11×16.

## Boas-vindas e wizard
- Tela cheia fundo **brand**, conteúdo centralizado (gap 12, padding 24): logo ❤️ 64px, título "Pressão Arterial" 26px bold, subtítulo, campo branco (max 340, raio 14, texto 20px centralizado) e botão **branco com texto brand**. O wizard mantém esse visual (fundo brand, campos/botões brancos, texto branco): um passo por tela, com indicador de passos (pontos) e botão voltar; opções como chips/segmentados brancos (selecionado: fundo branco, texto brand, borda branca; não selecionado: borda branca 50%).

## Impressão e PDF (layout a reproduzir)
- **Folha A4 paisagem**, margem 8 mm (impressão) / 28 pt (PDF, 842×595). Uma folha por **15 dias** (para N dias: ⌈N/15⌉ folhas) + **página de resumo** no PDF.
- Título "Registro de pressão arterial — dias a a b" (15 pt / PDF 16 pt bold vermelho `#c0392b`), linha meta: `Nome`, `Início`, `Aparelho: ______` (impressão em branco usa linhas para preencher), legenda explicativa (8,5 pt cinza): "Pressão: escreva alta/baixa, como 13/8 (alta = sistólica, baixa = diastólica). Hora: horário da medição. Pulso: batimentos por minuto (opcional). Medir 3 vezes ao dia — manhã, tarde e noite — nos dois braços, sentada e em repouso." (o trecho final deve refletir a config).
- Tabela: colunas `Dia` (8 mm) e `Data` (14 mm), depois por período um bloco: `Hora` (13 mm) + por braço `Pressão` (22 mm) e `Pulso` (14 mm). Cabeçalho em 3 níveis (período → braço → Pressão/Pulso), fundos cinza `#eee/#ddd`, células de dia/data `#f6f6f6`, bordas 0,4 mm `#333`, borda grossa (0,9 mm) separando blocos de período, linhas de 9,5 mm, valores 11 pt bold. Sem pulso: remove as colunas Pulso; um braço: remove o outro bloco; períodos desativados somem.
- Rodapé: "Nome do paciente: {nome}"; PDF: "Gerado em {data} pelo app Pressão Arterial" (7 pt cinza, canto).
- **Página de resumo (PDF)**: título "Resumo das medições", subtítulo cinza, tabela `Braço | Pressão média | Pulso médio | Medições` (mostra `120,5 / 80,3 (121/80)`), diferença entre braços, notas cinza ("Valores curtos valem dez vezes o número: 13/8 equivale a 130/80 mmHg." e "Este documento é só um registro. A interpretação dos valores é feita pelo médico.").
- CSV: cabeçalho `Dia;Data;Período;Hora;Braço;Alta;Baixa;Pulso;Alta (mmHg);Baixa (mmHg)`, uma linha por braço/período com algum valor; as colunas `Braço`/`Pulso` somem se desativados; `Alta (mmHg)` = `norm()`.

## Ícones e marca
- Reutilizar `icons/icon-512.png`, `icon-192.png`, `maskable-512.png` (ícone adaptativo Android) e `favicon.png` do repo original; emoji ❤️ como logo na tela de boas-vindas. Cor de marca para splash: `#c0392b`.

## Microinterações
Botão redondo: escala .94 ao tocar; barra de progresso anima largura .3s; foco do campo numérico troca borda/fundo; salva automaticamente a cada edição; pular foco Alta→Baixa ao completar a sistólica.
