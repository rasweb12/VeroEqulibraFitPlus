# Validação de autenticação

Não homologada. A validação real exige API e PostgreSQL isolados configurados, além de serviço de e-mail transacional ou coletor local. Não houve envio de e-mail nem migration remota nesta auditoria.

Em 2026-10-15 foram incluídos endpoints de solicitação e redefinição de senha. A solicitação retorna 202 sem revelar a existência da conta; a redefinição usa token do ASP.NET Identity e revoga refresh tokens ativos. O envio só funciona quando SMTP/coletor local estiver configurado; esse fluxo ainda não foi homologado.

## Isolamento local reavaliado em 2026-10-15
Treino, refeições, medidas e hábitos deixaram de usar chaves globais. Cada entrada é namespaceada pelo `userId` da sessão validada; dados legados sem proprietário não são atribuídos à próxima conta do aparelho. Os testes locais A/B passaram. Isto não substitui cifra do banco local, sincronização ou homologação em aparelho compartilhado.
