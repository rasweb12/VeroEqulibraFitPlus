# Autenticação

O novo produto usa ASP.NET Core Identity no PostgreSQL isolado do VeroEqulibraFit+. Nenhuma conta, chave ou configuração do Vero ou EquilibraFit++ é reutilizada.

## Fluxos disponíveis

- `POST /api/v1/auth/register`: cria uma conta com senha validada pelo Identity.
- `POST /api/v1/auth/login`: autentica e emite access token JWT de 15 minutos.
- `POST /api/v1/auth/refresh`: faz rotação atômica do refresh token de 30 dias; o token usado é revogado.
- `POST /api/v1/auth/logout`: revoga o refresh token da sessão autenticada.
- `GET /api/v1/auth/session`: retorna somente a identidade derivada do JWT.
- `DELETE /api/v1/auth/account`: exclui a conta e seus refresh tokens.

Os refresh tokens são persistidos somente como SHA-256. O Flutter usa o armazenamento protegido do sistema operacional por `flutter_secure_storage`, nunca `SharedPreferences`. A URL da API é fornecida em build por `--dart-define=API_BASE_URL=https://...`.

## Configuração de ambiente

```text
ConnectionStrings__Postgres=<conexão Neon isolada>
Jwt__Issuer=vero-equilibrafit-api
Jwt__SigningKey=<segredo único de no mínimo 64 bytes>
```

Há uma migration local versionada, `AddIsolatedIdentityAuth`. Ela **não foi aplicada** a Neon, Render ou a qualquer ambiente externo.

## Itens que dependem de ambiente externo

Confirmação de e-mail e recuperação de senha exigem a configuração de um provedor transacional isolado e domínio remetente. Não há credenciais no novo repositório; portanto esses envios não foram simulados nem foram encaminhados por serviços dos projetos de origem. Antes de produção, habilitar confirmação obrigatória, fluxo de recuperação, rate limiting distribuído, auditoria de login e testes REST contra uma instância Neon de homologação.

## Render — JWT e health check

Variáveis obrigatórias da API em produção: `Database__ConnectionString` (ou `ConnectionStrings__Postgres` por compatibilidade), `Jwt__Issuer`, `Jwt__SigningKey` (mínimo 64 bytes para HS512), `AI__BaseUrl` e `AI__InternalApiKey`. O processo falha antes de abrir rotas se emissor ou chave JWT estiverem ausentes/inválidos.

`/health/live` é apenas liveness técnico para o Render. `/health/ready` verifica somente se o PostgreSQL aceita conexão. Nenhum deles comprova migrations, e-mail, Gemini, login ou homologação funcional. A API não confia em `X-Forwarded-*` sem um `ReverseProxy__KnownProxy` IP explícito. O TLS termina no Render; links públicos devem usar `PublicApp__BaseUrl`.

As chaves do ASP.NET Data Protection são persistidas na tabela `data_protection_keys` do PostgreSQL isolado. A migration `AddDataProtectionKeys` foi apenas gerada localmente e não foi aplicada remotamente. O usuário do banco deve ter acesso exclusivo ao banco/namespace do produto; a chave JWT e os segredos SMTP não são registrados em logs.
