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
- `dotnet test backend\\VeroEqulibraFit.Api\\VeroEqulibraFit.Api.csproj --no-build -m:1 -v:minimal`: concluído; A suíte local de política de segurança foi criada, mas o adaptador de execução não retornou resultado nesta máquina e o processo foi interrompido sem teste aprovado.
- `git diff --check`: sem erros de espaço em branco (somente avisos LF/CRLF do Git).

## Não executado

- Migration não foi aplicada a Neon, Render ou produção.
- Não houve deploy, commit ou push.
- Não foi possível testar HTTP remoto de sincronização nesta sessão: a aprovação automática da chamada HTTPS atingiu o limite de uso e a chamada não foi executada.
- Ainda faltam testes de integração autenticados para 401, 403, paginação, alteração de status, papéis e auditoria; a execução do adaptador xUnit local também precisa ser estabilizada. A fase não está homologada até esses testes e a aplicação da migration em ambiente de homologação.

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

A conta temporariamente promovida voltou a não ter papel administrativo ao fim do teste. Nenhum dado de saúde, conversa ou credencial foi consultado ou exposto.

### Pendência de qualidade

O adaptador xUnit desta máquina ainda trava antes de emitir resultado, embora a suíte compile. A validação autenticada publicada acima foi executada com sucesso; estabilizar o executor de testes continua pendente antes da homologação final da sprint.
