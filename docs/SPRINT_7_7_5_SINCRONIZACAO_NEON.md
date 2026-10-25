# Sprint 7.7.5 — Auditoria de sincronização Neon

Data: 25/10/2026

## Escopo

Esta etapa auditou a persistência local, a outbox Flutter, os endpoints de
sincronização, o contrato de conflitos e o esquema da branch de produção do
Neon. Não foram executadas migrações, deploys, escritas remotas ou testes que
criassem dados em produção.

## Evidências verificadas

### Flutter

- As filas pendentes são gravadas por proprietário em `FlutterSecureStorage`,
  sob uma chave derivada do identificador autenticado.
- Nutrição enfileira operações `meal.create`, `meal.update` e `meal.delete` e
  solicita envio após uma gravação local confirmada.
- Treinos enfileiram fichas e exercícios personalizados, mas não disparam o
  envio após cada alteração; hoje a tentativa garantida ocorre quando a sessão
  é restaurada.
- Hábitos, hidratação, mobilidade, atividades, anotações e medidas corporais
  usam armazenamento seguro local e **não** são serializados na outbox.
- A restauração de sessão valida o token no servidor. Sem conectividade, a
  autenticação offline é recusada deliberadamente; portanto, não há suporte
  atual a abrir uma nova sessão sem rede.

### API

- `POST /api/v1/sync/push` aceita operações de treino, refeição, exercício
  personalizado e diário.
- A identidade do proprietário é derivada do JWT e todas as consultas de
  alteração e leitura são filtradas por `OwnerId`.
- A tabela `sync_operations` contém índice único para
  `(OwnerId, IdempotencyKey)`. A repetição com o mesmo payload retorna
  `duplicate`; reutilização da mesma chave com outro payload retorna conflito.
- Atualizações e exclusões de treino, refeição, exercício personalizado e
  diário usam revisão base e retornam `revision_conflict` quando aplicável.
- `GET /api/v1/sync/pull` usa cursor opaco, ordenação estável por data, tipo e
  identificador e paginação limitada a 50 alterações.

### Neon de produção

A branch padrão contém somente estas migrações:

1. `20261012051421_InitialTrainingFoundation`
2. `20261012052813_AddNutritionFoundation`
3. `20261014233907_AddIsolatedIdentityAuth`
4. `20261016204756_AddDataProtectionKeys`

As migrações locais abaixo ainda não estão aplicadas:

1. `20261018030504_AddSyncRecordVersions`
2. `20261018033335_AddCustomExerciseSync`
3. `20261018145415_AddFoodProductCatalog`
4. `20261018201300_AddJournalRecordSync`

Há uma branch Neon existente de homologação (`homologation-sync-20261018`)
com as três primeiras dessas migrações. Ela ainda não contém
`AddJournalRecordSync` e nenhum serviço foi redirecionado para ela; por isso,
é candidata a validação isolada de treino, refeição, exercício personalizado e
catálogo, mas não de Hábitos.

Consequências confirmadas pelo esquema remoto:

- `training_plans` e `meal_entries` não têm `Revision` nem `UpdatedAt`, que o
  endpoint de sincronização exige.
- Não existem `custom_exercises`, `journal_records` ou `food_products`.
- A validação entre aparelhos para treinos e refeições é bloqueada pelo
  esquema, assim como a sincronização de exercícios personalizados e diário.
- Scanner com catálogo remoto também permanece bloqueado; leitura e cadastro
  local devem continuar independentes desta tabela.

As contagens agregadas lidas no Neon para `sync_operations`, `training_plans`
e `meal_entries` eram zero. Nenhum conteúdo pessoal foi consultado.

## Correção local aplicada

`SecureOperationQueue.due` agora recupera uma operação que ficou no estado
`processing` por interrupção do processo. Ela volta para `pending`, marcada
com `interrupted`, e será reenviada na próxima oportunidade. O reenvio é
seguro porque a API aplica idempotência por proprietário e chave da operação.

## Testes executados

```text
flutter analyze
No issues found.

flutter test --dart-define=API_BASE_URL=https://veroequlibrafitplus.onrender.com
44 testes aprovados.
```

Foram acrescentados testes para:

- recuperação de uma operação marcada como `processing` após reinício;
- confirmação somente após resposta `accepted` da API;
- manutenção da operação para nova tentativa em falha de rede;
- leitura autenticada de alterações remotas e cursor opaco.

## Situação de homologação

| Área | Situação | Evidência / bloqueio |
| --- | --- | --- |
| Isolamento local por conta | TESTADO | Testes de outbox, treino e nutrição por proprietário. |
| Persistência local após reinício | TESTADO | Fila criptografada e teste de recuperação da operação interrompida. |
| Idempotência e conflito na API | AUDITADO | Implementação e índice único revisados; ainda falta execução contra ambiente compatível. |
| Treino e refeição entre dispositivos | BLOQUEADO | Colunas de versão ausentes no Neon de produção. |
| Exercício personalizado entre dispositivos | BLOQUEADO | Tabela ausente no Neon de produção. |
| Hábitos, notas, atividade e medidas entre dispositivos | PENDENTE | Aplicativo ainda não enfileira estes registros; `journal_records` também não existe em produção. |
| Scanner com catálogo remoto | BLOQUEADO | `food_products` ausente e integração externa continua restrita por licença. |
| Conflito real entre dois dispositivos | NÃO EXECUTADO | Depende de esquema remoto compatível e duas sessões de teste. |
| Encerrar sessão e entrar novamente | PARCIAL | A sessão é validada online; resta validar dados remotos após migração. |

## Ambiente isolado de homologação

Com autorização do proprietário, a migração
`20261018201300_AddJournalRecordSync` foi aplicada **somente** na branch Neon
`homologation-sync-20261018`. A verificação posterior confirmou a tabela
`journal_records`, as duas chaves de índice e o registro correspondente no
histórico de migrações. A branch padrão de produção continua sem essa tabela.

Foi criada a API isolada de homologação:

- URL: `https://vero-equilibrafit-sync-homologation.onrender.com`
- serviço Render: `vero-equilibrafit-sync-homologation`
- deploy: `dep-dbeo7g5g1s2s7387hcg0` (ativo)
- `/health/live`: HTTP 200
- `/health/ready`: HTTP 200

O serviço usa chaves JWT e chave interna exclusivas de homologação, com
deploy automático desativado. Ele aponta somente para a branch Neon de
homologação. IA e e-mail não são incluídos no escopo desse ambiente.

APK de homologação criado, ainda não instalado:

`D:\Curso\APP\VeroEqulibraFitPlus\artifacts\vero_equilibrafit_sync_homologation_debug.apk`

O artefato foi compilado com `API_BASE_URL` direcionada à API isolada. O ADB
local não tinha um emulador acessível no momento da compilação, portanto não
houve instalação nem substituição do aplicativo atual.

## Roteiro de validação entre dois dispositivos

1. Instalar o APK de homologação nos dois dispositivos de teste.
2. Entrar com a mesma conta de homologação nos dois aparelhos.
3. No dispositivo A, criar uma ficha e uma refeição; confirmar que aparecem
   no dispositivo B após reabrir o aplicativo.
4. Editar o mesmo item nos dois aparelhos antes de sincronizar e confirmar que
   o conflito é preservado na fila, sem substituição silenciosa.
5. Criar uma atividade e uma anotação; confirmar que permanecem locais até
   que o aplicativo passe a enfileirá-las em uma entrega posterior.
6. Desligar a rede no dispositivo A, criar uma refeição, reativar a rede e
   confirmar um único registro no dispositivo B.
7. Repetir o envio depois de interromper o aplicativo durante a sincronização
   e confirmar que a chave de idempotência não duplica o registro.
8. Encerrar e iniciar sessão novamente em cada dispositivo; confirmar que os
   dados remotos continuam isolados da conta de outro usuário.

## Próximo pacote seguro

1. Criar uma branch Neon de homologação a partir da produção.
2. Aplicar e testar as quatro migrações pendentes somente nessa branch.
3. Executar testes integrados com duas contas e dois dispositivos/emuladores:
   criação, atualização concorrente, exclusão, repetição de envio, falta de
   rede, retorno da rede e isolamento entre contas.
4. Revisar o envio imediato de Treinos e definir o contrato de sincronização
   de Hábitos e Medidas antes de incluí-los na outbox.
5. Somente após a homologação da branch, preparar um plano reversível de
   aplicação das migrações na produção.

## Backup e rollback

Backup local criado em:

`D:\Curso\APP\VeroEqulibraFitPlus\backups\sprint_7_7_5_sync_20261025_010302`

Para rollback local, restaurar os três arquivos preservados nesse diretório ou
reverter as alterações em `secure_operation_queue.dart` e nos testes desta
sprint. Nenhuma alteração remota requer rollback.
