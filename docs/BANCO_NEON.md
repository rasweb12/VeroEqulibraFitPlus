# Banco Neon

O Lakebase Postgres (Neon) está isolado no projeto `VeroEqulibraFitPlus`, branch `production`, banco `neondb`. A connection string permanece somente no Render; não foi salva neste repositório.

## Migração aplicada em 2026-10-16

Com autorização explícita, as migrations EF foram primeiro executadas e verificadas em uma branch temporária do Neon e depois promovidas para `production`. A branch temporária foi removida pelo processo de promoção.

- `20261012051421_InitialTrainingFoundation`
- `20261012052813_AddNutritionFoundation`
- `20261014233907_AddIsolatedIdentityAuth`
- `20261016204756_AddDataProtectionKeys`

Validação posterior na branch `production`: quatro registros em `__EFMigrationsHistory` e dez tabelas principais presentes, incluindo `users`, `refresh_tokens`, `training_plans`, `meal_entries`, `nutrition_plans` e `data_protection_keys`.

O app deve usar conexão agrupada para tráfego normal. Migrations futuras devem usar conexão direta, ser testadas primeiro em branch temporária e nunca ser aplicadas aos bancos dos projetos originais.
