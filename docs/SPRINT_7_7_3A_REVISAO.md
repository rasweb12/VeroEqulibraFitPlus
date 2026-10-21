# Revisão 7.7.3A — 20/10/2026

Estado: **PARCIAL; não homologado**. HEAD inicial `1cd2f05`; nenhuma alteração preexistente no Git. Não houve deploy ou alteração remota.

## Diagnóstico e alterações

- Medidas, atividades e anotações: os modais existentes foram preservados. Os testes de widget cobrem cancelar, salvar, reabrir e salvar novamente. Não foi reproduzida a asserção `_dependents.isEmpty`; a causa permanece não identificada e não há stack trace do caso original.
- Planos por Gemini: o serviço Python possui uma resposta alternativa por regras quando o provedor falha. A tela agora informa a indisponibilidade em vez de apresentar esse conteúdo como proposta Gemini. Mensagens para 401, 403, 429 e erros 5xx foram esclarecidas. O HTTP 500 original não foi reproduzido; não é possível afirmar a causa nem sua correção.
- Navegação: adicionados botões de retorno em plano, metas e relatórios, com retorno à nutrição quando não houver rota anterior. Teste manual e cobertura das demais subtelas pendentes.
- Vídeos: os 166 arquivos estão presentes. A descoberta não reconhecia `Supino Inclinado com Halteres2.mp4`; agora também reconhece o sufixo numérico, além de ` (n)`. A velocidade selecionada é mantida ao trocar de ângulo. `Uri.encodeFull(path)` permanece. O teste automatizado cobre a descoberta; a execução dos dois ângulos de supino foi verificada no emulador conforme complemento abaixo.

## Verificação

### Complemento no emulador após reinício

- O APK instalado apresentou `ExoPlaybackException` causado por `AssetDataSourceException` e `FileNotFoundException` para os dois arquivos de supino. Inspeção do APK confirmou os 166 vídeos com nomes percent-encoded. No Android, o caminho agora preserva esses caracteres durante a decodificação da URI do ExoPlayer, mantendo `Uri.encodeFull(path)`.
- Novo APK debug compilado e instalado com `adb install -r` sem limpar dados. Os dois ângulos de supino inicializaram; ao reproduzir o segundo, o controle indicou pausa disponível e duas capturas da área do vídeo, separadas por três segundos, continham quadros diferentes. Outros vídeos e aparelhos não foram testados.
- Medidas, atividade e anotação foram abertos e cancelados no emulador sem a asserção visível; não foram salvos registros na conta. Os testes de widget cobrem salvamento, mas o salvamento real no Android ainda não foi verificado.
- O log Android também apresentou erro de descriptografia de `FlutterSecureStorage`; causa, recorrência e impacto não foram comprovados. Não limpar dados como procedimento de diagnóstico.
- HTTP 500 da geração: o contrato Flutter → .NET → FastAPI foi inspecionado, sem evidência suficiente para estabelecer a causa do erro real. Permanece pendente correlação de logs com uma solicitação autorizada e ambiente apropriado.
- Tentativa posterior com objetivo genérico e sem salvar dados retornou HTTP 401, antes de alcançar a geração. A tela de planos usa o token da sessão carregada e não repete a solicitação após renovar um token expirado; a causa específica deste 401 precisa ser confirmada. Renovação deve ser coordenada entre requisições para não reutilizar refresh tokens rotacionados.
- Após autenticação, uma tentativa real de objetivo genérico recebeu 502 no app. Os logs da API em 20/10/2026 23:08 UTC registraram resposta 502 do endereço do serviço de IA; não foi localizado evento correspondente do FastAPI. Outra tentativa recebeu 429 do destino, mas a API publicada converteu para 502. Não se sabe se o limite veio do Render, do serviço ou de outro componente.
- Nova tentativa em 20/10/2026 às 23:13 UTC: após o serviço FastAPI iniciar e seu health check responder 200, a chamada autenticada chegou ao Gemini, que respondeu HTTP 200; o endpoint FastAPI também respondeu 200. O aplicativo, porém, informou que nenhuma proposta Gemini foi gerada. Não foi salvo plano. O serviço retorna um fallback quando não obtém JSON utilizável ou quando a validação do schema falha; os registros disponíveis não permitem distinguir essas causas nem afirmar que explicam esta tentativa. A resposta 200 do provedor não comprova uma proposta válida. O HTTP 500 original continua sem causa comprovada.
- Diagnóstico preparado localmente no FastAPI: registra apenas a categoria de falha do provedor ou a etapa de validação do schema, sem prompt, resposta ou detalhes de validação. Não foi publicado; uma nova chamada após publicação autorizada será necessária para determinar a etapa da falha. Backup do arquivo anterior em `backups/vero_773a_plan_diagnostic_20261020/plan_service.py`.
- Em 21/10/2026 a alteração e seus testes foram preparados na branch remota `codex/diagnostico-plano-773a`, commit `7f3e1620120cab29ce211d2606b313ba718ea2b0`, sem alteração da `main`. O deploy autorizado não foi realizado: o conector Render disponível não seleciona commit e o painel não pôde ser acessado pela automação. A opção de deploy de commit específico no painel desativa o deploy automático do serviço de IA, segundo a documentação do Render; isso precisa ser considerado ao restaurar a configuração após o diagnóstico.
- Complemento 21/10/2026: revisão `cc36c265f3063c4a773155d1ea219acf4f1eb7f9` publicada automaticamente na main contém o diagnóstico anterior. Uma nova solicitação pelo emulador chegou ao Gemini (HTTP 200), mas o diagnóstico registrou `stage=provider category=invalid_response`; o aplicativo informou indisponibilidade e não salvou proposta. Isso identifica que nenhum objeto JSON válido chegou ao serviço de planos, mas não distingue resposta vazia, JSON inválido, truncamento ou outros formatos. Não comprova a causa do HTTP 500 original.
- Novo diagnóstico local no provedor diferencia resposta vazia de JSON inválido ou não objeto e registra somente uma lista limitada de motivos de término, sem conteúdo gerado. `pytest`: 13 aprovados, com um aviso de dependência; `ruff` dos arquivos alterados: aprovado. Backup anterior em `backups/vero_773a_provider_diagnostic_20261021/`. Não publicado, sem comprovação da causa específica ou correção do problema.
- Nova tentativa em 21/10/2026: após uma resposta 429 do destino, o health check respondeu 200 e outra tentativa alcançou o Gemini (HTTP 200). O diagnóstico retornou `invalid_json_or_non_object` e `finish_reason=STOP`, indicando saída não vazia que não foi interpretada como objeto JSON; não comprova truncamento nem distingue JSON malformado de outro tipo. Nenhum plano foi salvo.
- Correção local preparada: solicitar ao Gemini uma saída estruturada com o schema `PlanGenerateResponse`, mantendo a validação do retorno e o fallback sinalizado. O SDK instalado aceita a configuração localmente; 14 testes Python passaram com um aviso de dependência e Ruff passou. Os testes usam simulação e não comprovam aceitação remota do schema nem uma proposta real. Backup em `backups/vero_773a_schema_20261021/`. Correção não publicada nem homologada.
- Python: `pytest -q -p no:cacheprovider` na `.venv312`: 11 testes aprovados, incluindo dois de privacidade do diagnóstico; um aviso de depreciação de dependência. `ruff check` nos dois arquivos modificados: aprovado. Os testes não comprovam a integração real.
- Correção local: o controlador preserva 429 como 429, mantendo outros erros de gateway em 502 sem expor o corpo recebido. `dotnet test tests/VeroEqulibraFit.Api.Tests/VeroEqulibraFit.Api.Tests.csproj --no-restore`: 12 aprovados, incluindo 429, 502 e autenticação interna recusada. Testes com respostas simuladas; não comprovam Gemini operacional. Correção ainda não publicada; deploy exige autorização.
- O projeto não explicita uma política Android de exclusão do armazenamento seguro do backup automático; a documentação da versão instalada do plugin descreve restauração de chaves como uma possível origem de erros. Não há evidência suficiente para concluir que essa seja a causa deste caso ou que dados devam ser removidos.

- `dart format`: executado nos arquivos modificados.
- `flutter test`: 25 testes passaram, incluindo testes novos dos três modais e da descoberta de ângulos. São testes locais de widget/unidade, sem validação de persistência remota.
- Complemento: os três testes de modal também passaram após inclusão do retorno do sistema e conferência de que o cancelamento não grava dados.
- A geração agora distingue falha de rede e timeout; o tempo limite cobre também a leitura da resposta. Não comprova a causa do HTTP 500.
- `flutter analyze`: após correção de avisos, sem problemas.
- APK debug gerado com `API_BASE_URL=https://veroequlibrafitplus.onrender.com`; um build não comprova funcionamento do serviço. Após reinício do emulador, a instalação e o teste limitado do vídeo foram executados conforme complemento acima.
- Integração Gemini para geração de plano: testada com resposta 200 do provedor, mas sem proposta válida confirmada. HTTP 500 original, navegação Android completa, retorno pelo gesto e stack trace do erro original permanecem sem comprovação suficiente.

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
