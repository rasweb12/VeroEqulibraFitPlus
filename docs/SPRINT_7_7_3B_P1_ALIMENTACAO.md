# Sprint 7.7.3B — Bloco P1: diário alimentar, foto e sincronização

Data: 24/10/2026  
Status: **PARCIAL — APK instalado; homologação manual de foto e segundo dispositivo pendente.**

## Escopo preservado

O layout homologado de `nutrition_page.dart` foi preservado. Esta entrega não
altera a composição visual do diário, metas, planos ou relatórios.

## Diagnóstico

- O fluxo de foto já existia de ponta a ponta: captura/galeria, prévia com
  consentimento, envio autenticado, análise por IA, revisão manual dos itens e
  confirmação explícita antes de gravar a refeição.
- A requisição de foto não possuía prazo máximo no aplicativo. Uma conexão
  bloqueada poderia manter a tela aguardando indefinidamente.
- Criação, edição e exclusão de refeições iniciavam persistência e fila offline
  sem aguardar confirmação. A tela podia navegar antes da gravação local.
- As operações de refeições entravam na outbox criptografada, mas a tentativa
  de envio era disparada somente em mudança de sessão. Uma refeição criada após
  o login podia permanecer pendente até o próximo evento de autenticação.

## Correções implementadas

- Foto: timeout de 35 segundos para a análise; em falha, mantém-se a mensagem
  de registro manual, sem fabricar resultado de IA.
- Diário: repositório e controlador agora retornam `Future`; a interface só
  retorna à tela de nutrição depois que a gravação local é confirmada. Falhas
  mostram mensagem e não anunciam salvamento.
- Foto revisada: a confirmação aguarda a persistência antes da navegação.
- Sincronização: depois de criar, editar ou excluir uma refeição já persistida,
  o aplicativo solicita envio em segundo plano à outbox autenticada. Falhas de
  rede continuam na fila; a interface não afirma sincronização remota.
- A revisão humana continua obrigatória: a foto não grava itens automaticamente
  e a interface informa que porções e nutrientes são estimativas.

## Evidências técnicas

- `flutter analyze`: sem problemas.
- `flutter test`: 39 testes aprovados; 1 teste de integração de API ignorado
  porque não recebeu `API_BASE_URL` de teste.
- Testes novos cobrem falha de armazenamento local e o disparo de sincronização
  somente após a gravação confirmada.
- APK debug gerado com
  `API_BASE_URL=https://veroequlibrafitplus.onrender.com` em
  `mobile/vero_equilibrafit_app/build/app/outputs/flutter-apk/app-debug.apk`.
- APK instalado no emulador com `adb install -r`, sem limpar dados. O pacote
  `br.com.vero_equilibrafit.vero_equilibrafit_app` registrou atualização em
  24/10/2026 22:47:48.

## Pendências de homologação

1. Escolher uma fotografia real na câmera ou galeria, confirmar o envio e
   revisar manualmente nome, porção e macros antes de salvar.
2. Desligar a rede ao salvar uma refeição, restabelecê-la e confirmar que a
   operação sai da fila e aparece no segundo dispositivo.
3. Repetir criação, edição e exclusão em dois dispositivos autenticados na
   mesma conta para verificar cursor, revisão e conflitos reais no Neon.
4. Validar scanner EAN/UPC e cadastro manual separadamente, respeitando a
   política de catálogo e licenças.

## Rollback

Reverter somente os arquivos desta entrega pelo commit correspondente. Não
limpar armazenamento seguro, outbox, dados nutricionais, vídeos ou backups.
