# Sprint 7.7.6A — Administração de Usuários

Data: 25/10/2026

## Auditoria inicial

| Área | Estado anterior | Evidência |
|---|---|---|
| Indicadores agregados | EXISTENTE | `GET /api/v1/admin/overview`, protegido pela policy `admin` |
| Autorização administrativa | EXISTENTE | JWT contém papéis; API exige `Administrator` |
| Listagem e busca de usuários | AUSENTE | Não havia rota nem página |
| Detalhes de identidade | AUSENTE | Painel só mostrava contagens |
| Bloqueio/reativação | AUSENTE | Identity possuía campos, sem fluxo administrativo |
| Gestão de papéis | AUSENTE | Bootstrap inicial era o único mecanismo |
| Auditoria de ações | AUSENTE | Nenhuma tabela ou endpoint |
| Catálogo, mídias, conteúdo e operação | BLOQUEADA PARA 7.7.6B/7.7.6C | Sem endpoints administrativos específicos |

## Implementação local

- API protegida em `/api/v1/admin/users` para listagem paginada, pesquisa por nome/e-mail, filtros de status e papel, detalhe mínimo e lista de papéis existentes.
- Ações de bloqueio/reativação e alteração de papéis exigem confirmação e justificativa de 3 a 500 caracteres.
- Operações revogam refresh tokens existentes, impedem alteração do próprio status/papel e preservam o último administrador ativo.
- DTOs administrativos não retornam senha, token, dados de saúde, refeições, planos, mídia ou conversas.
- O Admin Blazor ganhou as rotas `/usuarios` e `/usuarios/{id}` com filtros, paginação, confirmação no fluxo e histórico de ações.
- Migration local `20261025180012_AddAdminUserManagementAudit` cria `admin_audit_events` e adiciona `RegisteredAt` anulável a `users`. Contas históricas permanecem sem data, em vez de receber data inventada. Registros novos recebem UTC na criação.

## Testes executados

- `dotnet build backend\\VeroEqulibraFit.Api\\VeroEqulibraFit.Api.csproj --no-restore -m:1 -v:minimal`: aprovado, zero avisos/erros.
- `dotnet build admin\\VeroEqulibraFit.Admin\\VeroEqulibraFit.Admin.csproj --no-restore -m:1 -v:minimal`: aprovado, zero avisos/erros.
- `dotnet test backend\\VeroEqulibraFit.Api.Tests\\VeroEqulibraFit.Api.Tests.csproj --no-build -m:1 -v:minimal`: aprovado fora do sandbox; 5 aprovados, 0 falhas, em 309 ms.
- `git diff --check`: sem erros de espaço em branco (somente avisos LF/CRLF do Git).

## Limitações e pendências

- O executor VSTest dentro do sandbox local falha ao abrir o canal TCP de loopback entre `vstest.console` e `testhost` (`SocketException 10013`). Fora do sandbox, a mesma suíte foi executada e aprovada; não há falha funcional do teste.
- A promoção para produção continua pendente e não foi iniciada.
- As duas contas descartáveis criadas exclusivamente para a prova de revogação, incluindo sessões, papéis e auditoria associados, foram removidas da branch de homologação após a validação.

## Rollback

1. Não aplicar a migration: basta descartar as mudanças locais desta sprint.
2. Se aplicada em homologação no futuro, executar a migration anterior somente após backup e aprovação: `dotnet ef database update 20261018201300_AddJournalRecordSync`.
3. Reverter o serviço Admin/API para a revisão anterior caso necessário; nenhum deploy foi feito nesta etapa.

## Backup

`backups/sprint_7_7_6a_admin_20261025_145312`


## Homologação publicada

- Branch publicada: `codex/admin-users-homologation` (`f6cb5b7`).
- Migration aplicada somente na branch Neon de homologação: `20261025180012_AddAdminUserManagementAudit`.
- API isolada: `https://vero-equilibrafit-admin-api-homologation.onrender.com`.
- Admin isolado: `https://vero-equilibrafit-admin-homologation.onrender.com`.
- Produção não foi alterada.

### Validação autenticada executada

Com duas contas descartáveis exclusivas do ambiente de homologação:

1. Administrador autenticado acessou indicadores, listagem de usuários e papéis.
2. Usuário comum recebeu HTTP 403 ao requisitar a rota administrativa diretamente.
3. Bloqueio revogou a sessão e impediu novo login (HTTP 401).
4. Reativação restaurou o login.
5. As ações de bloqueio e reativação apareceram no histórico de auditoria.
6. Concessão temporária de `Administrator` permitiu acesso administrativo; a revogação posterior devolveu HTTP 403 e ambas as alterações foram auditadas.
7. A interface Admin publicada respondeu HTTP 200.
8. Uma nova prova de sessão bloqueou uma conta descartável e reutilizou seu refresh token já emitido: `POST /api/v1/auth/refresh` respondeu HTTP 401. Após reativação, um novo login foi aceito.

A conta temporariamente promovida voltou a não ter papel administrativo ao fim do teste. Nenhum dado de saúde, conversa ou credencial foi consultado ou exposto.

### Credencial de homologação

- A senha do papel `neondb_owner` da branch Neon de homologação foi rotacionada. A documentação do Neon confirma que a operação é isolada por branch; a branch padrão de produção não foi alterada.
- Os dois serviços isolados receberam a nova configuração no formato aceito pelo Npgsql e voltaram ao estado `live`.
- Nenhum segredo é registrado neste relatório.

## Promoção controlada

- A migration administrativa foi aplicada na branch Neon de produção após a criação do ponto de restauração `br-dawn-bar-b6cyua6f`.
- A confirmação posterior encontrou a tabela de auditoria, a coluna `RegisteredAt` e o registro da migration no histórico.
- A publicação do código e a validação autenticada em produção são registradas separadamente quando concluídas.
