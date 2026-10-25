# P1 — Auditoria do Blazor Admin

Data: 25/10/2026  
Estado: **PARCIAL — não homologado em produção.**

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

## Limites reais

- Não existe serviço Blazor Admin no workspace Render atual; somente API e IA
  estão publicados. Portanto não há URL administrativa disponível para teste.
- O painel atual não tem ações de catálogo, mídias, usuários, auditoria ou
  quotas Gemini. Esses recursos não devem ser apresentados como operacionais.
- A sessão do painel não sobrevive ao reinício do circuito e não faz refresh
  token. O usuário deve entrar novamente após expiração ou reconexão.
- Falta homologar, em ambiente publicado, uma conta `Administrator` e uma
  conta comum, sem revelar credenciais no chat.

## Próximo bloco seguro

Criar o serviço gratuito `vero-equilibrafit-admin` a partir do Blueprint,
aguardar o health check e realizar o roteiro de login positivo/negativo. A
criação do serviço é uma alteração remota e será feita apenas dentro da
autorização explícita de publicação do P1.
