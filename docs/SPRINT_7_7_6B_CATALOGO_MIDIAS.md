# Sprint 7.7.6B — Catálogo de Exercícios e Mídias

Data: 25/10/2026

## Auditoria

| Área | Estado encontrado |
|---|---|
| Vídeos originais | 166 assets preservados no Flutter |
| Player Flutter | aprovado; não foi alterado |
| Catálogo global no servidor | ausente |
| Exercícios privados | existentes em `custom_exercises`; permanecem isolados |
| Administração de mídia | ausente |

## Implementação local em andamento

- Entidades globais `exercise_catalog_items` e `exercise_catalog_media`, separadas de exercícios privados.
- API administrativa protegida em `/api/v1/admin/catalog` para pesquisa, filtros, publicação, edição e associação de mídia.
- Inventário de 166 caminhos de vídeo gerado a partir dos assets existentes. O inventário não cria associação automática.
- A API recusa associação cujo caminho não pertença ao inventário, evitando mapeamentos por semelhança de nome.
- Migration `AddAdminExerciseCatalog` gerada somente nesta branch.

## Validação executada

- `dotnet build backend\\VeroEqulibraFit.Api\\VeroEqulibraFit.Api.csproj --no-restore -m:1 -v:minimal`: aprovado, sem avisos ou erros.

## Pendências antes da homologação

- Tela Blazor para listar, editar e revisar mídias.
- Seed explícito dos cinco mapeamentos de vídeo já verificados, sem inferir os demais.
- Testes de autorização, catálogo e mídia.
- Aplicação da migration e testes autenticados somente em homologação.
- Nenhum deploy ou alteração de produção nesta sprint.
