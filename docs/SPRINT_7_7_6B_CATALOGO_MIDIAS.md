# Sprint 7.7.6B — Catálogo de Exercícios e Mídias

Data: 28/10/2026

## Auditoria

| Área | Estado encontrado |
|---|---|
| Vídeos originais | 166 assets preservados no Flutter |
| Player Flutter | aprovado; não foi alterado |
| Catálogo global no servidor | ausente |
| Exercícios privados | existentes em `custom_exercises`; permanecem isolados |
| Administração de mídia | ausente |

## Implementação concluída localmente

- Entidades globais `exercise_catalog_items` e `exercise_catalog_media`, separadas de exercícios privados.
- API administrativa protegida em `/api/v1/admin/catalog` para pesquisa, filtros, publicação, edição e associação de mídia.
- Inventário de 166 caminhos de vídeo gerado a partir dos assets existentes. O inventário não cria associação automática.
- A API recusa associação cujo caminho não pertença ao inventário, evitando mapeamentos por semelhança de nome.
- Migration `AddAdminExerciseCatalog` gerada somente nesta branch.
- Administração Blazor: listagem paginada, busca, filtro de publicação, criação, edição, publicação e despublicação de exercícios globais.
- Administração Blazor: inventário de mídias, identificação de vídeos sem associação e associação manual de vídeo principal ou ângulo alternativo, com confirmação e justificativa.
- O menu administrativo passa a compartilhar o mesmo circuito autenticado do painel; a navegação não depende mais de uma instância vazia da sessão.

## Validação executada

- `dotnet build backend\\VeroEqulibraFit.Api\\VeroEqulibraFit.Api.csproj --no-restore -m:1 -v:minimal`: aprovado, sem avisos ou erros.
- `dotnet build admin\\VeroEqulibraFit.Admin\\VeroEqulibraFit.Admin.csproj -c Release --no-restore -m:1 -v:minimal`: aprovado, sem avisos ou erros.

## Pendências para homologação remota

- Aplicação da migration e testes autenticados no ambiente de homologação.
- Validação manual de criação, edição, publicação e associação de mídia com uma conta administrativa.
- Os cinco mapeamentos já aprovados no Flutter continuam preservados no aplicativo. Nenhum vídeo foi associado automaticamente no catálogo administrativo, para não transformar inferência de nome em dado editorial.
- Nenhum deploy ou alteração de produção nesta sprint.
