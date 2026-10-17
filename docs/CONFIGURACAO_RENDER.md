# Configuração de homologação no Render

Este guia descreve uma configuração isolada. Não reutilize banco, SMTP, chaves ou serviços dos projetos Vero e EquilibraFit++.

## 1. Publicar o código correto

O erro `open Dockerfile: no such file or directory` acontece quando o Render recebe um commit que ainda não contém o `render.yaml` e os Dockerfiles. Envie primeiro os commits locais `075057f`, `71ca428` e os commits posteriores desta correção ao repositório remoto. No Render, confirme que o commit exibido é o mesmo que contém `render.yaml` antes de criar um deploy.

## 2. Criar a IA privada

No Render, crie o serviço privado `vero-equilibrafit-ai` com:

- Runtime: Docker.
- Dockerfile: `./ai/vero_equilibrafit_ai/Dockerfile`.
- Docker context: `./ai/vero_equilibrafit_ai`.
- Porta: `8001`.
- Health check: `/health`.

Cadastre estas variáveis:

| Nome | Valor |
| --- | --- |
| `PORT` | `8001` |
| `VERO_EQUILIBRAFIT_ENVIRONMENT` | `production` |
| `VERO_EQUILIBRAFIT_INTERNAL_API_KEY` | segredo aleatório persistente |
| `VERO_EQUILIBRAFIT_GEMINI_API_KEY` | chave Gemini, somente neste serviço |
| `VERO_EQUILIBRAFIT_GEMINI_MODEL` | modelo Gemini aprovado |

A IA não deve ser pública. Em produção ela recusa iniciar se a chave interna ou a chave Gemini estiverem ausentes. O nome `production` em minúsculas é válido.

## 3. Criar a API pública

Crie `vero-equilibrafit-api` com:

- Runtime: Docker.
- Dockerfile: `./backend/VeroEqulibraFit.Api/Dockerfile`.
- Docker context: `.`.
- Porta: `8080`.
- Health check: `/health/live`.

Cadastre:

| Nome | Valor |
| --- | --- |
| `ASPNETCORE_ENVIRONMENT` | `Production` |
| `PORT` | `8080` |
| `Database__ConnectionString` | string do Neon isolado |
| `Jwt__Issuer` | `vero-equilibrafit-api` |
| `Jwt__Audience` | `vero-equilibrafit-mobile` |
| `Jwt__SigningKey` | segredo persistente de ao menos 64 bytes UTF-8 |
| `AI__BaseUrl` | host privado da IA; no blueprint é preenchido por `fromService` |
| `AI__InternalApiKey` | exatamente o mesmo valor de `VERO_EQUILIBRAFIT_INTERNAL_API_KEY` |

Para criar a chave JWT, execute localmente e cole apenas o resultado no campo secreto do Render:

```powershell
$bytes = New-Object byte[] 64
[Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
[Convert]::ToBase64String($bytes)
```

Não altere essa chave em cada deploy. A API precisa dela para validar tokens existentes. `Jwt__Audience` precisa corresponder ao valor configurado no `render.yaml`; a API recusa iniciar sem ela. `Database__ConnectionString` é o nome canônico; não cadastre também `ConnectionStrings__Postgres`.

Mantenha `ReverseProxy__KnownProxy` vazio enquanto não houver um IP estável e documentado do proxy confiável. A API ignora cabeçalhos encaminhados nesse caso, o que evita falsificação de `X-Forwarded-*`.

## 4. Configurar e-mail antes de testar cadastro

Só depois de definir o endereço público que abrirá links de conta, cadastre na API:

| Nome | Valor |
| --- | --- |
| `Email__SmtpHost` | host SMTP de homologação ou transacional |
| `Email__SmtpPort` | porta do provedor, normalmente `587` |
| `Email__UseSsl` | `true` ou conforme o provedor |
| `Email__From` | remetente validado |
| `Email__Username` | usuário SMTP, se necessário |
| `Email__Password` | segredo SMTP, se necessário |

Enquanto não houver domínio próprio, use `https://veroequlibrafitplus.onrender.com` em `PublicApp__BaseUrl`. A API redireciona `/confirm-email` e `/reset-password` para o deep link `veroequilibrafit://account/...` registrado no aplicativo. Consulte [RESEND_SMTP.md](RESEND_SMTP.md) para as variáveis do Resend e o roteiro de validação.

## 5. Banco Neon e migrations

Use somente um banco Neon de homologação do VeroEqulibraFit+. A configuração da connection string não aplica schema automaticamente. Revise as migrations, incluindo `AddDataProtectionKeys`, e execute-as apenas depois de autorizar explicitamente essa alteração no ambiente isolado.

## 6. Aplicativo Flutter

`API_BASE_URL` não é variável do Render. Ela é incorporada no APK no build. Depois de a API ter URL pública HTTPS, gere o APK assim:

```powershell
C:\develop\flutter\bin\flutter.bat build apk --debug --dart-define=API_BASE_URL=https://SUA-API.onrender.com
```

Não use barra no final da URL. Nunca inclua JWT, Gemini, banco ou SMTP em `--dart-define`.

## 7. Verificação técnica

Após cada serviço subir, abra:

- `https://SUA-API.onrender.com/health/live` — processo .NET ativo.
- `https://SUA-API.onrender.com/health/ready` — processo e PostgreSQL alcançável.
- o health check interno `/health` da IA pelo painel privado.

Esses checks não comprovam cadastro, SMTP, Gemini ou login. Execute então os fluxos reais de cadastro, confirmação de e-mail, login, refresh, logout, recuperação de senha, Coach e análise de foto com contas e imagens de homologação.
