# Auditoria P2 — 17/10/2026

## Escopo e evidências

HEAD auditado: `0a2168b86a13de602c980591c072d231529a87b9`, antes das correções locais desta auditoria. Os projetos Vero, EquilibraFit++ e a pasta de vídeos não foram modificados.

Foram verificados o controle de rota Flutter, a configuração de autenticação .NET, o gateway FastAPI, o catálogo, a persistência local, o `render.yaml` e os testes disponíveis. Os health checks públicos já informados pelo responsável confirmam apenas processo e PostgreSQL; não são homologação funcional.

## Achados

| ID | Severidade | Causa | Correção/status |
| --- | --- | --- | --- |
| P2-001 | Alta | JWT emitia e aceitava tokens sem validação de audiência. | Corrigido localmente: `Jwt__Audience` obrigatório, incluído no token e validado pelo bearer handler. Requer deploy com a nova variável. |
| P2-002 | Alta | A API podia iniciar sem URL/chave interna da IA e enviar chave vazia ao FastAPI. | Corrigido localmente: `AI__BaseUrl` e `AI__InternalApiKey` são validados no startup. Requer deploy. |
| P2-003 | Alta | Falha SMTP podia devolver 500 depois de criar conta ou no fluxo de recuperação. | Corrigido localmente: respostas públicas permanecem genéricas para indisponibilidade SMTP. Requer teste real SMTP. |
| P2-004 | Alta | Exclusão de conta não removia explicitamente os registros de domínio do proprietário. | Corrigido localmente com transação e remoção de planos, sessões, refeições, planos alimentares, outbox e refresh tokens. Requer teste em PostgreSQL isolado. |
| P2-005 | Média | Rate limit de autenticação é por instância e não foi comprovado por IP confiável no proxy Render. | PARCIAL. A configuração aceita somente proxy explicitamente confiável; falta valor estável/documentado do Render e teste distribuído. |
| P2-006 | Média | Ambiente Python local contém extensão `pydantic_core` incompatível. | BLOQUEADO no ambiente local; recriar ambiente de dependências antes da suíte Python. |
| P2-007 | Alta | Administração Blazor continua sem autenticação, papéis ou operações de negócio. | REPROVADO. Não deve ser exposto como painel administrativo funcional. |
| P2-008 | Alta | Outbox, conflitos, recuperação em segundo dispositivo e sincronização remota completa não possuem evidência. | REPROVADO. Há tipos de sync no domínio, mas o fluxo ponta a ponta não está implementado/comprovado. |
| P2-009 | Média | Vídeos possuem inventário/hash, mas licença e associação estável para os 166 itens não foram comprovadas. | BLOQUEADO. Não incluir conteúdo sem licença verificável em build distribuível. |

## Conclusão

P2 permanece **REPROVADA**. As correções locais reduzem bloqueadores de configuração e privacidade, mas não substituem o deploy controlado, testes reais de e-mail/Gemini/Neon, testes em dois dispositivos e a implementação da administração e sincronização.

## Reavaliação v4 — 17/10/2026

HEAD de início da reavaliação: `5b6c12e1d751d3d33d9dbd94ea16b06fdd68fd7a` (`main`, sem alterações locais). O commit era exatamente a referência informada. Projetos originais e pasta de vídeos não foram alterados.

### Evidências reexecutadas

- `dart analyze lib/core/offline`: aprovado após a atualização da outbox.
- Testes Flutter direcionados: 9 aprovados (persistência de refeições, edição, isolamento por proprietário e fichas).
- `build_runner build --delete-conflicting-outputs`: concluído para atualizar o schema Isar. Houve aviso de versão do analyzer do gerador; não houve falha de geração.

### Estado corrigido

| ID | Estado | Evidência |
| --- | --- | --- |
| P2-SYNC-001 | PARCIAL | Outbox Isar agora persiste entidade, versão de cliente, estado, tentativas, backoff e erro sanitizado. Commit `29b3a1b`. Ela ainda não é chamada pelos repositórios nem enviada à API. |
| P2-SYNC-002 | REPROVADO | API não possui push/pull, cursor, versão de registro, tombstone remoto ou resolução de conflito. |
| P2-STORE-001 | PARCIAL | Treino, refeições, hábitos e medidas usam SecureOwnerStore por conta no código atual. Falta teste físico A/B e migração/limpeza de armazenamento legado. |
| P2-VISION-001 | PARCIAL | O caminho de foto e o contrato Gemini existem; a revisão ainda é agregada e não persiste alimentos individuais no Neon. |
| P2-AUTH-001 | PARCIAL | AuthGate e sessão existem. Confirmação e recuperação SMTP não têm evidência ponta a ponta. |
| P2-ADMIN-001 | REPROVADO | Blazor continua shell sem autenticação administrativa e operações reais. |

### Lote 2 — revisão alimentar estruturada

Em 17/10/2026, a análise de foto passou a abrir uma rota protegida de revisão (`/nutrition/photo-review`). A tela permite editar cada alimento, porção, unidade e valores estimados, remover/adicionar itens e escolher a data antes de confirmar. Os totais são recalculados no cliente e o salvamento continua condicionado à revisão explícita; a imagem não é persistida pelo fluxo.

`dart analyze` dos arquivos modificados e `flutter test` concluíram sem falhas (9 testes). Isso corrige a revisão agregada, mas não cria persistência individual de alimentos no Neon: **P2-VISION-001 permanece PARCIAL**. A validação real com imagem autorizada, Gemini, API, Neon e recuperação em outro dispositivo permanece pendente.

### Push inicial da sincronização — 17/10/2026

`P2-SYNC-002` evoluiu para **PARCIAL**: a API possui `POST /api/v1/sync/push`, autenticado, idempotente por proprietário e transacional, para criar fichas e refeições com IDs estáveis. O build de `VeroEqulibraFit.Api` foi concluído sem avisos ou erros. O Flutter ainda não envia a outbox, e não existem pull, cursor, tombstones, versões de edição ou demonstração em dois dispositivos; a sincronização ponta a ponta continua **REPROVADA**.

`P2-STORE-002` foi confirmado como bloqueador: Isar `3.1.0+1` não expõe abertura com chave de criptografia. A outbox não foi aberta no aplicativo e não recebeu dados, evitando persistência local desprotegida de dados de saúde. É necessária uma mudança de camada local com migração e testes antes de ativar a sincronização automática.

Atualização posterior do mesmo achado: a outbox deixou de depender de Isar e passou a ter implementação por `SecureOwnerStore`, cifrada pelo keystore/Keychain e isolada por proprietário. Os testes locais de persistência e isolamento foram aprovados. Ainda faltam enfileiramento pelos repositórios, acionamento após login, transação entre dado local e outbox, pull, conflitos e homologação Neon; `P2-STORE-002` fica **PARCIAL**, e a sincronização ponta a ponta segue **REPROVADA**.

Atualização 17/10/2026: criações de fichas/refeições agora entram na fila cifrada e o push é tentado após uma sessão válida, com exclusão mútua em memória. `P2-SYNC-003` é **PARCIAL**: o caminho local até o adaptador existe, mas não há validação contra Neon, pull, tombstones, edição remota ou fluxo em dois dispositivos.

O status do MVP continua **REPROVADO — NÃO HOMOLOGADO**.
