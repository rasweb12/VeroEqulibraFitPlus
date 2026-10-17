# Lote 1 — Sincronização e persistência

Data: 17/10/2026  
Estado: **PARCIAL — NÃO HOMOLOGADO**

## Auditoria inicial

O armazenamento dos dados locais de treino, refeições, hábitos e medidas usa `SecureOwnerStore`, com chaves isoladas por `ownerId`. Não há uso ativo de `SharedPreferences` para esses dados no código atual. A documentação anterior que afirmava o contrário foi corrigida.

A outbox Isar existia, mas não era acionada por nenhum repositório e só possuía marcação de conclusão. O primeiro incremento adiciona tipo e ID da entidade, versão do cliente, estados, tentativas, horário de nova tentativa e categoria de erro sanitizada. A geração Isar foi atualizada.

## Limites atuais

- Os repositórios ainda não registram cada mutação na outbox de forma atômica.
- Não existem endpoints `push`, `pull` ou cursor de sincronização na API.
- Não há versão de registro, tombstone remoto ou resolução de conflito por entidade.
- Não há demonstração em dois dispositivos/emuladores.

Portanto não há sincronização Flutter ↔ Neon implementada e nenhum dado deve ser considerado recuperável em outro dispositivo.

## Política prevista

- Catálogo oficial: servidor autoritativo.
- Fichas e exercícios personalizados: detectar versão divergente; não substituir silenciosamente.
- Sessões e séries executadas: eventos históricos anexáveis, sem perda.
- Refeições e planos alimentares: conflito explícito quando a mesma revisão divergir.
- Exclusões: tombstones com propagação até confirmação do servidor.

## Próximas correções

1. Definir contratos de push/pull e versão de entidade.
2. Gravar mutação local e outbox no mesmo armazenamento transacional.
3. Implementar processamento idempotente no PostgreSQL e cursor de pull.
4. Integrar treino, alimentação, hábitos e medidas progressivamente.
5. Testar contas A/B e dois emuladores com falha/retry/conflito.

## Incremento de identidade estável — 17/10/2026

Fichas novas, cópias de fichas e refeições novas agora recebem UUID v4 no próprio dispositivo. A API aceita opcionalmente esse `clientId` na criação de fichas e refeições: se o mesmo identificador já existir para o mesmo proprietário, ela devolve o registro existente; se pertencer a outra conta, responde conflito. Isso torna reenvios de criação seguros e impede que uma conta escolha o identificador de outra.

O incremento é apenas a base de identidade para a futura outbox. Os repositórios ainda não fazem chamadas remotas e a API não possui `push/pull`, cursor ou atualização versionada. O estado deste lote continua **PARCIAL — NÃO HOMOLOGADO**.

## Push inicial autenticado — 17/10/2026

Foi criado `POST /api/v1/sync/push`. Ele aceita lotes de até 50 operações e suporta, por enquanto, `training-plan.create` e `meal.create`. Cada operação é vinculada ao proprietário obtido exclusivamente do JWT, tem limite de payload, hash SHA-256 e recibo único por proprietário e `operationId`. A gravação da entidade e do recibo ocorre na mesma transação do PostgreSQL; reenvio idêntico retorna `duplicate` e a reutilização da chave com conteúdo diferente retorna conflito.

Este endpoint não é liberado pelo aplicativo ainda: falta o adaptador Flutter que consome a outbox, renova a sessão e interpreta os resultados. Também faltam `pull`, atualização/exclusão, cursor, versionamento e teste em Neon isolado. Assim, esta implementação não é evidência de sincronização entre dispositivos.
