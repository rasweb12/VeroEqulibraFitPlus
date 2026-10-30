# Promoção Neon: homologação para produção

Data da auditoria: 30/10/2026.

## Ambientes encontrados

- Projeto: `VeroEqulibraFitPlus` em `aws-sa-east-1`.
- Produção: branch `production` (`br-fancy-sea-b6gchiq4`).
- Homologação de sincronização: `homologation-sync-20261018` (`br-shiny-cell-b6l5vebk`).
- Banco: `neondb`.

## Diferença confirmada

A produção contém cinco migrations. A homologação contém, além delas, estas quatro migrations pendentes em produção:

1. `20261018030504_AddSyncRecordVersions` — adiciona `Revision` e `UpdatedAt` a planos e refeições, com índices de sincronização.
2. `20261018033335_AddCustomExerciseSync` — cria `custom_exercises`.
3. `20261018145415_AddFoodProductCatalog` — cria `food_products`.
4. `20261018201300_AddJournalRecordSync` — cria `journal_records`.

A migration `20261026000407_AddAdminExerciseCatalog` não está aplicada em produção nem em homologação; ela não integra esta promoção de sincronização.

## Plano de aplicação

1. Criar snapshot ou branch de rollback da produção imediatamente antes da janela.
2. Gerar e revisar a prévia da migration contra a branch de produção, usando conexão direta para migration.
3. Confirmar que o binário de API que entende essas tabelas está pronto para publicação.
4. Aplicar exclusivamente as quatro migrations listadas.
5. Publicar a API correspondente e verificar `/health/ready`.
6. Validar login, push/pull de sincronização em dois dispositivos, isolamento entre usuários, modo offline e reenvio.
7. Se falhar, direcionar a API de volta ao build anterior e restaurar a branch/snapshot conforme a prévia aprovada.

## Prévia executada

- Branch temporária criada a partir de produção: `br-summer-credit-b65jo07y`.
- A prévia aplicou as quatro migrations sem erro.
- Consulta de validação na branch temporária: 3 novas tabelas, 4 colunas de sincronização e 4 registros novos em `__EFMigrationsHistory`.
- Snapshot de rollback criado antes da promoção: `pre-sync-production-20261030` (`snap-polished-dew-b68esjkf`), com expiração em 13/11/2026 às 23:59:59 UTC.

## Aplicação em produção — 30/10/2026

- **APLICADA:** as quatro migrations de sincronização foram promovidas para `production` após a aprovação explícita do responsável.
- **VALIDADA:** a produção apresenta 3 tabelas novas, 4 colunas de sincronização e 4 migrations adicionais no histórico EF Core.
- **VALIDADA:** o diff de schema entre `production` e `homologation-sync-20261018` está vazio.
- **VALIDADA:** `GET /health/live` e `GET /health/ready` da API de produção responderam HTTP 200 após a aplicação.
- A branch temporária de prévia foi removida pelo Neon após a promoção. O snapshot de rollback permanece disponível até sua expiração.

## Limites e aprovação

Nenhuma migration ou deploy de produção foi executado por esta preparação. A aplicação muda o schema de produção e precisa da sua aprovação explícita depois da prévia e do snapshot de rollback.
