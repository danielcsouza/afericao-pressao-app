# Ficha da Play Store — Diário da Pressão Arterial

Textos e declarações prontos para colar no Play Console (pt-BR). Os textos são
públicos: falam com quem vai instalar o app. Os limites entre parênteses são os
da Play; as contagens foram conferidas.

**Regra de marca:** o app é um caderno, não mede nem diagnostica. Não usar a
palavra "aferição" em nome/textos de marca e não prometer efeito médico.

## 1. Textos

### Nome do app (máx. 30)
<!--ini:nome-->
Diário da Pressão Arterial
<!--fim:nome-->

### Descrição curta (máx. 80)
<!--ini:curta-->
Caderno digital para anotar a pressão e levar tudo organizado ao médico.
<!--fim:curta-->

### Descrição completa (máx. 4000)
<!--ini:longa-->
Diário da Pressão Arterial é um caderno digital simples para anotar a sua pressão e levar tudo organizado à consulta.

Ele não mede a pressão e não faz diagnóstico: você mede com o seu aparelho e anota aqui. Quem interpreta os valores é o médico.

COMO FUNCIONA
• Na primeira vez, o app pergunta por quantos dias você vai acompanhar (de 1 a 365), a data de início, em qual braço você mede e em quais períodos do dia: manhã, tarde e noite.
• Digite como a gente fala: "13 e 8" vira 130/80. Também aceita o valor do aparelho de uma vez, como 12882, que vira 128/82.
• Anote o pulso, se quiser (é opcional).
• A hora de cada medição é obrigatória e já vem sugerida com a hora atual, para o médico saber exatamente quando foi medido.
• Tudo é salvo automaticamente, a cada toque.

ACOMPANHE SEUS DIAS
• Uma grade com todos os dias do caderno mostra o que já foi anotado em cada período.
• Médias de pressão e de pulso de cada braço e a diferença média entre os braços, calculadas com as medições completas.
• Barra de progresso do acompanhamento.

LEMBRETES QUE NÃO INCOMODAM
• Defina um horário para cada período. Se até lá você ainda não tiver anotado, o app avisa uma única vez. Se já anotou, não avisa.
• Dá para testar o aviso na hora, para ter certeza de que as notificações estão liberadas.

LEVE À CONSULTA
• Imprima uma folha para escrever à mão ou já com os valores anotados (A4, até 15 dias por folha).
• Gere um PDF com as medições e uma página de resumo, ou uma planilha (CSV) que abre no Excel, e compartilhe por WhatsApp ou e-mail.

SEUS DADOS SÃO SEUS
• Tudo fica somente no seu aparelho: sem conta, sem cadastro e sem anúncios.
• O app nem pede acesso à internet, então nenhuma informação sai do seu celular.
• Você apaga tudo quando quiser, dentro do próprio app.

FÁCIL DE USAR
• Campos grandes e fáceis de tocar, teclado só com números e tema claro, escuro ou automático.

AVISO IMPORTANTE
Este aplicativo não é um dispositivo médico e não diagnostica, trata, cura nem previne nenhuma condição médica. É apenas um caderno digital: ele não mede nem interpreta valores de pressão arterial. Consulte sempre um profissional de saúde para orientação, diagnóstico ou tratamento. Em caso de mal-estar ou emergência, procure atendimento médico imediatamente (SAMU: 192).
<!--fim:longa-->

### Novidades desta versão (máx. 500)
<!--ini:novidades-->
Primeira versão do Diário da Pressão Arterial: anote sua pressão por dia e período, receba lembretes, veja as médias e leve tudo ao médico em PDF, planilha ou folha impressa.
<!--fim:novidades-->

> O aviso final da descrição segue a política "Conteúdo e serviços de saúde" da
> Play: apps de saúde que não são dispositivo médico precisam dizer **na
> descrição** que não são dispositivo médico, não diagnosticam/tratam/curam/previnem
> condições e que se deve consultar um profissional de saúde. Não remover.

### Tags (até 5; escolhidas na lista do Console)
Escolher só as que descrevem o app (a Play pede "as mais obviamente relevantes";
tag sem relação pode ser tratada como spam de metadados). Não precisa preencher 5.

- **Saúde e fitness** (principal)
- **Bloco de notas** (é um caderno de anotações)
- Opcional: **Assistente pessoal** (lembretes)

Evitar: **Medicina** (associa o app à categoria Medicina e às exigências de app
médico), **Medição** (sugere ferramenta que mede), **Rastreador de atividades**,
Dieta, Perda de peso, Sono, Meditação, Ioga, Treino (não são o app), e **Agenda**
(é tag de calendário; o app não é agenda de compromissos).

## 2. Dados da ficha

| Campo | Valor |
| --- | --- |
| Tipo | Aplicativo |
| Gratuito / pago | Gratuito |
| Categoria | Saúde e fitness (não escolher "Medicina": atrai exigências de dispositivo médico que o app não tem) |
| Contato (e-mail) | contato@danielsistemas.com.br |
| Política de privacidade | URL pública da página `diario-pressao-app.html` (a que o Daniel publicar) |
| Exclusão de dados | URL pública da página `exclusao-dados-diario-pressao.html` |
| ID do app | `br.com.danielsistemas.diario_pressao` (definitivo) |
| Idioma padrão | Português (Brasil) |

## 3. Declarações do Console (conferir o texto atual de cada formulário)

Base de tudo: o app **não coleta nem compartilha dados**. Tudo fica no aparelho,
sem internet, sem conta, sem SDK de terceiros. Verificado no manifesto de
release: só `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED` e `VIBRATE`; sem
`INTERNET` e sem `AD_ID`.

- **Segurança dos dados:** coleta de dados = **Não**; compartilhamento = **Não**.
  Como nada é transmitido, "criptografia em trânsito" não se aplica. Há
  exclusão de dados dentro do app. A política já cita o backup automático do
  Android (função do sistema, controlada pelo usuário).
- **Anúncios:** o app **não** contém anúncios.
- **ID de publicidade:** **Não** usa.
- **Acesso ao app:** todas as funções estão disponíveis sem login.
- **Público-alvo:** adultos (**18 anos ou mais**). Não é direcionado a crianças.
- **Classificação de conteúdo (questionário IARC):** responder "não" a violência,
  conteúdo sexual, drogas, jogos de azar, interação entre usuários e compartilhamento
  de localização. Espera-se a classificação mais baixa (Livre).
- **Apps de saúde (etapa 1 de 2, "Recursos de saúde no seu app"):** marcar
  **somente "Controle de doenças e condições médicas"** (Medicina). Definição da
  Play: apps para gerenciar condições físicas agudas ou crônicas. É o caso de um
  diário de pressão para quem acompanha hipertensão. **Não** marcar: "Meu app não
  tem recursos de saúde" (o app registra dados de saúde); "Apps para dispositivos
  médicos" (só para apps regulados: diagnóstico, recomendação de tratamento ou
  interface com hardware médico; o app não mede, não interpreta e não se liga a
  aparelhos); "Suporte à decisão clínica" (é para profissionais de saúde);
  "Controle de medicamentos" (os lembretes são de anotar a pressão, não de remédio);
  "Atividade e condicionamento físico" (a pressão aqui é clínica, não esportiva).
  Se a etapa 2 pedir mais informações, descrever como **caderno de anotações de
  medições feitas pelo próprio usuário**, sem medir, diagnosticar ou tratar.
- **Permissões sensíveis / declarações extras:** nenhuma (sem alarme exato,
  sem localização, câmera, microfone, SMS, etc.).
- **App governamental / financeiro / notícias:** não.

## 4. Gráficos (prontos na pasta `store/`)

| Item | Exigência da Play | Arquivo |
| --- | --- | --- |
| Ícone | PNG 512×512, até 1 MB | `store/icone-512.png` (sem cantos transparentes; a Play aplica a máscara) |
| Imagem de destaque | PNG/JPEG 1024×500 | `store/imagem-destaque-1024x500.png` (gerada por `flutter test tool/gen_feature_graphic_test.dart`) |
| Capturas de celular | mínimo 2, até 8; lado maior até 2× o menor | `store/capturas/01…07-*.png`, todas 1080×1920 (proporção 1,78) |

Ordem sugerida das capturas: 01 Anotar (hoje) · 02 Anotar (dia completo) ·
03 Agenda · 04 grade dos dias · 05 médias · 06 Ajustes (lembretes) · 07 Imprimir/Compartilhar · 08 splash (a Play aceita até 8; pode ficar por último).

As capturas usam **dados fictícios** ("Maria", valores curtos como 12/8 e 13/8),
barra de status limpa (modo demo do Android, 10:00) e tela 1080×1920. Para
refazer: instalar o build de depuração, gravar o `FlutterSharedPreferences.xml`
de exemplo com `adb run-as` e capturar com `adb exec-out screencap -p`.

## 5. Antes de enviar

1. Política e página de exclusão publicadas e abrindo no navegador do celular.
2. Criar o app no Console com o nome e o ID acima; preencher ficha, declarações e gráficos.
3. Enviar o `.aab` assinado (`build/app/outputs/bundle/release/app-release.aab`)
   primeiro em **teste interno**, instalar pela Play e passar pelo fluxo.
4. Se a conta de desenvolvedor for pessoal e recente, a Play pode exigir teste
   fechado com testadores por 14 dias antes da produção (conferir no Console).
5. Subir o `versionCode` (número depois do `+` no `pubspec.yaml`) a cada novo envio.

## 6. Atenção: tipo de conta de desenvolvedor (conferir ANTES de publicar)

A Play exige **conta de organização** para quem publica "apps de saúde, como apps
médicos e apps de pesquisa em seres humanos" (ajuda "Escolha um tipo de conta",
item de requisitos). O artigo "Categorias de apps de saúde", que define o que
conta como app médico, **não foi lido** (não abriu na consulta). Não foi possível
confirmar se um diário de pressão declarado como "Controle de doenças e condições
médicas" (que fica na seção Medicina da declaração) entra nessa exigência.

O que fazer:
1. No Console, em Configurações > Detalhes da conta, ver se a conta é **Organização** ou **Pessoal**.
2. Se for **Organização**: sem problema; seguir o fluxo.
3. Se for **Pessoal**: pode haver bloqueio na revisão. Consultar o suporte do
   Console / o artigo "Health app categories" antes de enviar. A conta pode ser
   convertida para organização (pede D-U-N-S e dados da empresa).
4. **Não** trocar a declaração de saúde só para fugir da exigência: declarar o
   que o app é de verdade. Declaração falsa pode suspender o app e a conta.
