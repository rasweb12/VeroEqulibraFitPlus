# Deploy no Render

Nenhum serviço, segredo, migration ou deploy foi criado por este repositório. O arquivo `render.yaml` prepara três serviços com `autoDeployTrigger: off`: API .NET pública, FastAPI privada e painel administrativo. Antes de aplicar o blueprint, envie ao GitHub os commits que contêm esse arquivo; um checkout antigo não terá os Dockerfiles indicados e falhará com `open Dockerfile: no such file or directory`.

## API .NET pública

Configure o Dockerfile como `./backend/VeroEqulibraFit.Api/Dockerfile`, o contexto como `.` e a porta como `8080`. Use `/health/live` como health check do Render.

| Variável | Valor ou origem | Obrigatória |
| --- | --- | --- |
| `ASPNETCORE_ENVIRONMENT` | `Production` | Sim |
| `PORT` | `8080` | Sim |
| `Database__ConnectionString` | string de conexão do Neon isolado | Sim |
| `Jwt__Issuer` | `vero-equilibrafit-api` | Sim |
| `Jwt__SigningKey` | segredo aleatório persistente com ao menos 64 bytes UTF-8 | Sim |
| `AI__BaseUrl` | host privado da FastAPI, com `http://` quando configurado manualmente | Sim para IA |
| `AI__InternalApiKey` | mesmo segredo interno da FastAPI | Sim para IA |
| `PublicApp__BaseUrl` | URL/deep link público usado nos e-mails | Sim para links de conta |
| `Email__SmtpHost` | host SMTP transacional ou coletor de homologação | Sim para e-mail |
| `Email__SmtpPort` | normalmente `587` | Sim para e-mail |
| `Email__UseSsl` | `true` ou `false` conforme o provedor | Sim para e-mail |
| `Email__From` | remetente verificado | Sim para e-mail |
| `Email__Username` | credencial SMTP | Quando exigido |
| `Email__Password` | segredo SMTP | Quando exigido |
| `ReverseProxy__KnownProxy` | IP específico do proxy confiável, se houver | Opcional |

`ConnectionStrings__Postgres` continua aceito somente por compatibilidade; configure **uma** das duas variáveis de conexão. Nunca coloque a connection string, chaves JWT, Gemini ou SMTP em `appsettings`, `.env.example`, GitHub Actions ou logs.

O segredo JWT não pode ser substituído a cada restart: a troca invalida todos os access tokens e pode interromper sessões. Para HS512, use pelo menos 64 bytes. Exemplo local para gerar um valor sem salvá-lo no repositório:

```powershell
$bytes = New-Object byte[] 64
[Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
[Convert]::ToBase64String($bytes)
```

O Render termina TLS. A API só processa cabeçalhos `X-Forwarded-*` quando `ReverseProxy__KnownProxy` contém um IP explicitamente confiável; deixe vazio se o endereço não for conhecido. A aplicação não redireciona HTTP internamente, evitando loops atrás do proxy.

## FastAPI privada

Use `./ai/vero_equilibrafit_ai/Dockerfile`, contexto `./ai/vero_equilibrafit_ai`, porta `8001` e mantenha o serviço privado.

| Variável | Valor ou origem |
| --- | --- |
| `PORT` | `8001` |
| `VERO_EQUILIBRAFIT_ENVIRONMENT` | `production` |
| `VERO_EQUILIBRAFIT_INTERNAL_API_KEY` | segredo compartilhado com `AI__InternalApiKey` |
| `VERO_EQUILIBRAFIT_GEMINI_API_KEY` | chave Gemini somente no servidor |
| `VERO_EQUILIBRAFIT_GEMINI_MODEL` | modelo Gemini aprovado |

## Banco e health checks

`/health/live` responde apenas pela disponibilidade do processo. `/health/ready` confirma alcance do PostgreSQL, sem executar migrations e sem verificar o fluxo de login. Ambos são checks técnicos, não evidência de homologação funcional.

Existe a migration local `AddDataProtectionKeys`, que persiste chaves do ASP.NET Data Protection no banco isolado. Revise-a e aplique-a somente no ambiente de homologação autorizado, junto com as migrations anteriores. Esta documentação não autoriza migrations remotas.

## Painel administrativo

Use `./admin/VeroEqulibraFit.Admin/Dockerfile`, contexto `.` e porta `8080`. A configuração de autenticação administrativa ainda exige homologação independente; não exponha segredo administrativo no navegador.
