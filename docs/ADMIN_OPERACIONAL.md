# Painel administrativo operacional

## Implementado localmente

O painel Blazor possui uma tela de entrada e mantém a sessão somente no circuito servidor do Blazor. Ele envia as credenciais exclusivamente à API .NET em `POST /api/v1/auth/login` e consulta `GET /api/v1/admin/overview` com o JWT recebido.

O endpoint exige a política `admin` no servidor. Uma conta sem o papel `Administrator` não recebe indicadores. O painel não armazena senha, token em navegador, nem informações individuais de usuários.

## Configuração

Defina `Api__BaseUrl` no serviço Blazor com a URL HTTPS pública da API. Para atribuição inicial, use o processo seguro já suportado pela API: habilite temporariamente `AdminBootstrap__Enabled=true` e configure `AdminBootstrap__Email` para uma conta existente. Depois da atribuição, desabilite o bootstrap e faça novo deploy.

## Limitações pendentes

- A sessão ainda não possui renovação por refresh token ou persistência após reinício do circuito.
- Catálogo, mídias, auditoria, quotas de Gemini e gestão de usuários precisam de endpoints administrativos específicos antes de terem páginas operacionais.
- A homologação requer teste com uma conta administrativa e uma conta comum no ambiente isolado.

## Concessão administrativa — 18/10/2026

O papel `Administrator` foi atribuído à conta existente indicada pelo responsável durante o deploy Render `dep-dbairhqjnfac73fso0vg`. Em seguida, `AdminBootstrap__Enabled` foi definido como `false` e o deploy `dep-dbais6u7bikc73eq54a0` ficou ativo. O endereço da conta não é repetido neste documento para reduzir exposição de dados pessoais.

**Estado:** PRONTO PARA HOMOLOGAÇÃO. O login no Blazor ainda requer teste manual da conta administrativa e o teste negativo de uma conta comum.
