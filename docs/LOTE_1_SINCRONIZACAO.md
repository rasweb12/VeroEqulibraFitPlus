# Lote 1 — Sincronização e persistência

Data: 17/10/2026  
Estado: **PARCIAL — NÃO HOMOLOGADO**

## Auditoria inicial

O armazenamento dos dados locais de treino, refeições, hábitos e medidas usa `SecureOwnerStore`, com chaves isoladas por `ownerId`. Não há uso ativo de `SharedPreferences` para esses dados no código atual. A documentação anterior que afirmava o contrário foi corrigida.

A outbox Isar existia, mas não era acionada por nenhum repositório e só possuía marcação de conclusão. O primeiro incremento adiciona tipo e ID da entidade, versão do cliente, estados, tentativas, horário de nova tentativa e categoria de erro sanitizada. A geração Isar foi atualizada.

## Limites atuais

- Os repositórios ainda não registram cada mutação na outbox de forma atômica.
- Não há aplicação de alterações remotas no armazenamento Flutter; o cliente ainda só faz `push`.
- Atualizações concorrentes ainda não carregam uma revisão-base e não há tela de resolução de conflito.
- Não há demonstração em dois dispositivos/emuladores.

Portanto não há sincronização Flutter ↔ Neon implementada e nenhum dado deve ser considerado recuperável em outro dispositivo.

## Política prevista

- Catálogo oficial: servidor autoritativo.
- Fichas e exercícios personalizados: detectar versão divergente; não substituir silenciosamente.
- Sessões e séries executadas: eventos históricos anexáveis, sem perda.
- Refeições e planos alimentares: conflito explícito quando a mesma revisão divergir.
- Exclusões: tombstones com propagação até confirmação do servidor.

## Próximas correções

1. Aplicar o `pull` no armazenamento local com deduplicação por revisão.
2. Gravar mutação local e outbox no mesmo armazenamento transacional.
3. Implementar atualização condicionada à revisão e resolução explícita de conflito.
4. Integrar hábitos e medidas progressivamente.
5. Testar contas A/B e dois emuladores com falha/retry/conflito.

## Incremento de identidade estável — 17/10/2026

Fichas novas, cópias de fichas e refeições novas agora recebem UUID v4 no próprio dispositivo. A API aceita opcionalmente esse `clientId` na criação de fichas e refeições: se o mesmo identificador já existir para o mesmo proprietário, ela devolve o registro existente; se pertencer a outra conta, responde conflito. Isso torna reenvios de criação seguros e impede que uma conta escolha o identificador de outra.

O incremento é apenas a base de identidade para a futura outbox. Os repositórios ainda não fazem chamadas remotas e a API não possui `push/pull`, cursor ou atualização versionada. O estado deste lote continua **PARCIAL — NÃO HOMOLOGADO**.

## Push inicial autenticado — 17/10/2026

Foi criado `POST /api/v1/sync/push`. Ele aceita lotes de até 50 operações e suporta, por enquanto, `training-plan.create` e `meal.create`. Cada operação é vinculada ao proprietário obtido exclusivamente do JWT, tem limite de payload, hash SHA-256 e recibo único por proprietário e `operationId`. A gravação da entidade e do recibo ocorre na mesma transação do PostgreSQL; reenvio idêntico retorna `duplicate` e a reutilização da chave com conteúdo diferente retorna conflito.

Este endpoint não é liberado pelo aplicativo ainda: falta o adaptador Flutter que consome a outbox, renova a sessão e interpreta os resultados. Também faltam `pull`, atualização/exclusão, cursor, versionamento e teste em Neon isolado. Assim, esta implementação não é evidência de sincronização entre dispositivos.

## Adaptador Flutter de push — 17/10/2026

`SyncPushClient` consome somente operações pendentes da outbox do proprietário autenticado. Ele valida IDs UUID, envia o token, usa timeout de 30 segundos e só marca a operação como sincronizada quando a API devolve `accepted` ou `duplicate`. Conflitos e rejeições são preservados como conflito local; problemas de rede, autenticação e respostas inválidas voltam para a fila com backoff.

O adaptador ainda não é disparado pelo aplicativo: não há abertura centralizada e cifrada do Isar nem ligação atômica das mutações de treino/refeição à outbox. Essa limitação é deliberada para não simular sincronização automática. `flutter analyze` do adaptador e `flutter test` concluíram sem falhas; a integração real com API/Neon continua pendente.

### Bloqueador de criptografia identificado

A versão instalada do Isar (`3.1.0+1`) foi inspecionada e sua API de abertura não aceita chave de criptografia. Por isso, a outbox não será aberta nem conectada ao aplicativo nessa versão: seu payload pode conter dados de treino e alimentação, que não podem ir para armazenamento local em texto claro. A tentativa de inicialização foi descartada antes de qualquer uso.

Para concluir o fluxo será necessário adotar uma camada local que forneça criptografia de banco verificável, ou atualizar o mecanismo de persistência mediante migração testada. Até essa decisão e seus testes de migração, o estado de sincronização permanece **REPROVADO** para homologação, embora os contratos e o adaptador possam continuar evoluindo isoladamente.

## Substituição da outbox por armazenamento cifrado — 17/10/2026

Foi implementada `SecureOperationQueue`, com o envelope completo de operações persistido pela `SecureOwnerStore`, que usa Android Keystore/iOS Keychain. A chave é isolada por `ownerId`, foi incluída na rotina de exclusão de conta e não permite leitura por outra conta. `SyncPushClient` passou a depender de uma interface de fila, permitindo usar essa implementação cifrada sem abrir o Isar não cifrável.

Evidências: análise estática dos arquivos de outbox sem problemas e 11 testes Flutter aprovados, incluindo persistência após reinstanciar a fila e isolamento entre contas. A fila ainda não é alimentada pelos repositórios nem acionada automaticamente; também não há transação comum entre o registro local e o envelope no keystore. Assim, a sincronização ponta a ponta continua **REPROVADA**, e o próximo incremento deve enfileirar mutações de criação sem bloquear o uso offline.

## Enfileiramento de criações locais — 17/10/2026

Fichas novas, duplicações de fichas e refeições novas agora geram operações de criação na fila cifrada do proprietário. O payload contém o UUID estável e os dados necessários para o `push` inicial. O registro local é salvo primeiro e seu uso não fica bloqueado caso a fila apresente falha; portanto, não há perda intencional de histórico por indisponibilidade de sincronização.

O teste `new local meal also creates an encrypted sync operation` confirmou o enfileiramento de uma refeição, e a suíte Flutter total passou com 12 testes. A operação ainda não é disparada automaticamente após login, e a gravação local/outbox não possui transação comum. Atualizações, exclusões, hábitos, medidas e pull permanecem fora deste incremento.

## Envio após sessão autenticada — 17/10/2026

`SyncService` é acionado quando o `authSessionProvider` obtém uma sessão válida após login ou restauração. Ele cria a fila cifrada da conta e chama o adaptador de push sem bloquear a navegação. Uma trava em memória impede execuções concorrentes; falhas permanecem na fila para tentativa posterior com backoff. Não há tokens, payloads ou respostas de servidor registrados localmente fora do envelope cifrado.

Esta etapa conecta criação local → outbox cifrada → tentativa autenticada de push. A validação real contra Render/Neon, o pull, atualizações, exclusões/tombstones e conflitos entre dispositivos continuam pendentes, portanto o lote ainda é **PARCIAL — NÃO HOMOLOGADO**.

## Tombstones de exclusão — 17/10/2026

Excluir uma ficha com UUID estável ou uma refeição com UUID estável agora gera `training-plan.delete` ou `meal.delete` na fila cifrada. O `push` aplica a exclusão lógica exclusivamente ao registro daquele proprietário; fichas são mantidas no banco com `DeletedAt`, sem apagar sessões de treino. Reenvios recebem o mesmo tratamento idempotente do recibo de operação.

Evidências locais: build da API .NET sem avisos/erros e teste Flutter `deleting a new local meal preserves a tombstone operation` aprovado. Ainda falta pull dos tombstones e a verificação em Neon, portanto exclusão entre dispositivos não está homologada.

## Versionamento e pull remoto — 18/10/2026

Fichas e refeições agora possuem `Revision` e `UpdatedAt`. A migration local `AddSyncRecordVersions` inicializa linhas existentes com revisão `1` e `CURRENT_TIMESTAMP`, evitando que registros já existentes fiquem invisíveis no primeiro `pull`. Ela **não foi aplicada no Neon**.

Foi criado `GET /api/v1/sync/pull`, protegido por JWT e limitado a 50 alterações por página. Ele usa `OwnerId` somente do token, inclui tombstones e devolve cursor opaco composto por instante, tipo e ID da entidade. Esse cursor evita perder alterações com o mesmo instante de atualização; os dados são ordenados de forma determinística. O endpoint devolve apenas fichas e refeições neste incremento.

Evidências locais: `dotnet build backend/VeroEqulibraFit.Api/VeroEqulibraFit.Api.csproj --no-restore -m:1 -v normal` concluído com êxito e sem avisos/erros. A suíte de API identificou um arranjo incorreto no teste de JWT ausente, que foi corrigido para informar issuer e audience antes de verificar a chave.

Permanece **PARCIAL — NÃO HOMOLOGADO**: o Flutter ainda não aplica o pull, atualizações ainda não usam `Revision` como pré-condição, não existe atomicidade entre o dado local e a outbox, e não houve teste contra Neon ou dois dispositivos.

## Cliente Flutter de pull e aplicação idempotente — 18/10/2026

O aplicativo agora chama o `pull` autenticado após o `push` da sessão validada. O cursor opaco fica no armazenamento seguro por conta e cada página é aplicada ao repositório de treino e alimentação. Uma alteração só substitui a cópia local quando a revisão remota for igual ou superior; tombstones de fichas permanecem persistidos para impedir reaparecimento. Refeições removidas deixam de ser apresentadas localmente.

Após uma sincronização, os providers de fichas e refeições são invalidados para recarregar o conteúdo cifrado. A análise estática dos arquivos alterados passou sem erros. Ainda faltam atualização versionada, filas transacionais, hábitos/medidas, testes de API contra Neon e homologação em dois dispositivos. O lote segue **PARCIAL — NÃO HOMOLOGADO**.
