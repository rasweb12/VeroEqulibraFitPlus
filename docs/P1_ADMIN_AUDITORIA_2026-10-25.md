# P1 — Auditoria do Blazor Admin

Data: 25/10/2026  
Estado: **PARCIAL — publicado; autenticação positiva e negativa completa ainda não homologada.**

## Implementado e verificado localmente

- O painel Blazor usa uma sessão por circuito no servidor; credenciais e JWT
  não são persistidos no navegador.
- O login solicita token à API e consulta somente
  `GET /api/v1/admin/overview`.
- O endpoint exige a política `admin`, associada ao papel `Administrator` na
  API. Contas não autenticadas recebem `401`; contas autenticadas sem o papel
  recebem `403`.
- O resumo expõe apenas contagens agregadas de usuários, fichas, refeições,
  planos nutricionais e exercícios personalizados.
- A compilação local do Blazor foi concluída sem avisos ou erros. Os testes da
  API passaram, incluindo os cenários `401` e `403` do resumo administrativo.

## Configuração preparada

O `render.yaml` passou a declarar `Api__BaseUrl` para o serviço
`vero-equilibrafit-admin`. Essa variável não é segredo e aponta para a API
HTTPS já publicada.

## Evidência de publicação

- Serviço gratuito `vero-equilibrafit-admin` criado no workspace Render em
  Oregon, com auto deploy desligado.
- Primeiro deploy manual da revisão `dfedfc7` ficou `live` em
  25/10/2026 00:14 UTC.
- A página pública respondeu HTTP 200 e apresentou a identidade do painel.
- A API pública respondeu HTTP 401 a uma solicitação anônima para
  `/api/v1/admin/overview`.

## Limites reais

- O painel atual não tem ações de catálogo, mídias, usuários, auditoria ou
  quotas Gemini. Esses recursos não devem ser apresentados como operacionais.
- A sessão do painel não sobrevive ao reinício do circuito e não faz refresh
  token. O usuário deve entrar novamente após expiração ou reconexão.
- Falta homologar, em ambiente publicado, uma conta `Administrator` e uma
  conta comum, sem revelar credenciais no chat.

## Próximo bloco seguro

Executar o roteiro de login positivo com a conta que já possui
`Administrator` e o roteiro negativo com uma conta comum. Não envie as
credenciais pelo chat; o resultado pode ser informado como aprovado ou
reprovado.
