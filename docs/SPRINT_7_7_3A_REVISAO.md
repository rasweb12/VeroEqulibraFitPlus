# Revisão 7.7.3A — 20/10/2026

Estado: **PARCIAL; não homologado**. HEAD inicial `1cd2f05`; nenhuma alteração preexistente no Git. Não houve deploy ou alteração remota.

## Diagnóstico e alterações

- Medidas, atividades e anotações: os modais existentes foram preservados. Os testes de widget cobrem cancelar, salvar, reabrir e salvar novamente. Não foi reproduzida a asserção `_dependents.isEmpty`; a causa permanece não identificada e não há stack trace do caso original.
- Planos por Gemini: o serviço Python possui uma resposta alternativa por regras quando o provedor falha. A tela agora informa a indisponibilidade em vez de apresentar esse conteúdo como proposta Gemini. Mensagens para 401, 403, 429 e erros 5xx foram esclarecidas. O HTTP 500 original não foi reproduzido; não é possível afirmar a causa nem sua correção.
- Navegação: adicionados botões de retorno em plano, metas e relatórios, com retorno à nutrição quando não houver rota anterior. Teste manual e cobertura das demais subtelas pendentes.
- Vídeos: os 166 arquivos estão presentes. A descoberta não reconhecia `Supino Inclinado com Halteres2.mp4`; agora também reconhece o sufixo numérico, além de ` (n)`. A velocidade selecionada é mantida ao trocar de ângulo. `Uri.encodeFull(path)` permanece. O teste automatizado cobre a descoberta; reprodução no Android continua não testada.

## Verificação

- `dart format`: executado nos arquivos modificados.
- `flutter test`: 25 testes passaram, incluindo testes novos dos três modais e da descoberta de ângulos. São testes locais de widget/unidade, sem validação de persistência remota.
- Complemento: os três testes de modal também passaram após inclusão do retorno do sistema e conferência de que o cancelamento não grava dados.
- A geração agora distingue falha de rede e timeout; o tempo limite cobre também a leitura da resposta. Não comprova a causa do HTTP 500.
- `flutter analyze`: após correção de avisos, sem problemas.
- APK debug gerado com `API_BASE_URL=https://veroequlibrafitplus.onrender.com`; um build não comprova funcionamento do serviço. ADB detectou `emulator-5554`, mas `adb shell` não respondeu; instalação e reprodução do vídeo permanecem sem confirmação, assim como a sessão autenticada.
- Integração Gemini, HTTP 500, navegação Android, retorno pelo gesto e stack trace do erro original: não testados.

## Rollback

Os arquivos previamente existentes alterados podem ser restaurados a partir do backup `backups/vero_773a_20261020_193136` quando nele presentes; para metas e relatórios, consultar o commit inicial `1cd2f05` e preservar quaisquer alterações posteriores. Remover apenas os novos arquivos desta entrega se for desejado desfazê-la. Não restaurar o repositório inteiro nem apagar vídeos ou dados do usuário.

## Roteiro para homologação posterior

1. Abrir medida, preencher e cancelar; confirmar que nada foi gravado.
2. Salvar medida, reabrir e registrar outra.
3. Fechar medida pelo voltar e gesto; reabrir.
4. Repetir os três cenários para atividade.
5. Repetir os três cenários para anotação.
6. Confirmar que os dados reaparecem após reiniciar.
7. Abrir planos, metas e relatórios diretamente e retornar à nutrição.
8. Gerar uma proposta autenticada em ambiente autorizado; em falha, correlacionar logs sem dados sensíveis.
9. Reproduzir o vídeo principal, pausar e trocar os ângulos, incluindo o arquivo com sufixo `2`.
10. Verificar velocidade, retorno e estados de erro no emulador e em aparelho compatível.

Antes de iniciar 7.7.3B, resolver os problemas críticos pendentes e solicitar a homologação do proprietário. MVP não homologado.
