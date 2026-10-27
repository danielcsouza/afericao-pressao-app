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
Este aplicativo é apenas um caderno digital. Não é um dispositivo médico, não mede nem interpreta valores de pressão arterial e não substitui a orientação de um profissional de saúde. Em caso de mal-estar ou emergência, procure atendimento médico imediatamente (SAMU: 192).
<!--fim:longa-->

### Novidades desta versão (máx. 500)
<!--ini:novidades-->
Primeira versão do Diário da Pressão Arterial: anote sua pressão por dia e período, receba lembretes, veja as médias e leve tudo ao médico em PDF, planilha ou folha impressa.
<!--fim:novidades-->

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

## 4. Gráficos

| Item | Exigência da Play | Situação |
| --- | --- | --- |
| Ícone | PNG 512×512, até 1 MB | Pronto: `reference/icons/maskable-512.png` (sem cantos transparentes; a Play aplica a máscara) |
| Imagem de destaque | PNG/JPEG 1024×500 | A criar |
| Capturas de tela (celular) | mínimo 2, até 8; cada lado entre 320 e 3840 px; **o lado maior não pode passar de 2× o menor** | A criar. A tela do emulador (1080×2400) passa de 2:1 e seria recusada: capturar em 1080×1920 |

Sugestão de capturas (ordem): 1) Anotar com valores preenchidos e selo
"✓ completo"; 2) Agenda (progresso e grade dos dias); 3) médias e diferença entre
braços; 4) lembretes em Ajustes; 5) folha impressa / PDF; 6) wizard (resumo).
Usar dados de exemplo fictícios (não usar nome ou valores de pessoa real).

## 5. Antes de enviar

1. Política e página de exclusão publicadas e abrindo no navegador do celular.
2. Criar o app no Console com o nome e o ID acima; preencher ficha, declarações e gráficos.
3. Enviar o `.aab` assinado (`build/app/outputs/bundle/release/app-release.aab`)
   primeiro em **teste interno**, instalar pela Play e passar pelo fluxo.
4. Se a conta de desenvolvedor for pessoal e recente, a Play pode exigir teste
   fechado com testadores por 14 dias antes da produção (conferir no Console).
5. Subir o `versionCode` (número depois do `+` no `pubspec.yaml`) a cada novo envio.
