# Correção 7.7.6A.2 — Sessão do menu administrativo

Data: 28/10/2026

## Causa raiz

O `Routes` já era renderizado como `InteractiveServer`, porém as páginas
também declaravam `@rendermode InteractiveServer`. Cada página recebia um
circuito próprio e, por consequência, outra instância scoped de
`AdminApiSession`. Após o login, o painel usava a instância com token, enquanto
o layout lateral consultava a instância vazia e mantinha o link **Entrar**.

Não havia `AuthenticationStateProvider` ou cookie de autenticação do Blazor:
a autorização continua sendo conferida pela API, com o token recebido apenas
depois de a chamada administrativa `/api/v1/admin/overview` ser aceita.

## Correção local

- As páginas deixaram de criar render modes próprios; o circuito interativo do
  roteador passa a ser compartilhado por página, layout e menu.
- `AdminApiSession` agora publica a mudança de sessão. `NavMenu` e o layout
  reagem imediatamente ao login, logout, expiração ou revogação.
- O token fica somente em `ProtectedSessionStorage`, criptografado pelo
  Data Protection do servidor e associado à sessão do navegador. Não há uso
  de `localStorage`.
- Ao restaurar a sessão, o token é conferido pela API. Uma resposta 401/403
  limpa o token protegido e volta o menu ao estado de visitante.
- O menu inclui um indicador de sessão administrativa quando autenticado.

## Arquivos alterados

- `admin/VeroEqulibraFit.Admin/Components/Pages/Home.razor`
- `admin/VeroEqulibraFit.Admin/Components/Pages/Login.razor`
- `admin/VeroEqulibraFit.Admin/Components/Pages/Users.razor`
- `admin/VeroEqulibraFit.Admin/Components/Pages/UserDetail.razor`
- `admin/VeroEqulibraFit.Admin/Components/Pages/CatalogExercises.razor`
- `admin/VeroEqulibraFit.Admin/Components/Pages/CatalogExerciseDetail.razor`
- `admin/VeroEqulibraFit.Admin/Components/Pages/CatalogMedia.razor`
- `admin/VeroEqulibraFit.Admin/Components/Layout/MainLayout.razor`
- `admin/VeroEqulibraFit.Admin/Components/Layout/NavMenu.razor`
- `admin/VeroEqulibraFit.Admin/Components/Layout/NavMenu.razor.css`
- `admin/VeroEqulibraFit.Admin/Services/AdminApiSession.cs`

## Validação executada

- `dotnet build admin/VeroEqulibraFit.Admin/VeroEqulibraFit.Admin.csproj -c Release --no-restore -m:1 -v:minimal`: aprovado, sem avisos ou erros.
- `dotnet test backend/VeroEqulibraFit.Api.Tests/VeroEqulibraFit.Api.Tests.csproj --no-restore -m:1 -v:minimal`: 5 aprovados.
- O build Debug não pôde sobrescrever o executável em uso pela instância local
  do Admin. Não se trata de erro de código.

## Homologação local pendente

Ainda é necessário reiniciar a instância local que serve `localhost:7197` e
validar visualmente: visitante, login de administrador, menu imediato,
`/usuarios`, detalhes, logout, novo login e atualização de página.

## Backup e rollback

Backup criado em `backups/admin_7_7_6a2_20261028_011031`.

Para rollback local, restaure os arquivos desse diretório e reinicie o Admin.
Nenhum commit, push, deploy, migration ou alteração de produção foi feito
nesta correção.
