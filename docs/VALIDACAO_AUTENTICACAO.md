# Validação de autenticação

Não homologada. A validação real exige API e PostgreSQL isolados configurados, além de serviço de e-mail transacional ou coletor local. Não houve envio de e-mail nem migration remota nesta auditoria.

Em 2026-10-15 foram incluídos endpoints de solicitação e redefinição de senha. A solicitação retorna 202 sem revelar a existência da conta; a redefinição usa token do ASP.NET Identity e revoga refresh tokens ativos. O envio só funciona quando SMTP/coletor local estiver configurado; esse fluxo ainda não foi homologado.

## Isolamento local reavaliado em 2026-10-15
Treino, refeições, medidas e hábitos deixaram de usar chaves globais. Cada entrada é namespaceada pelo `userId` da sessão validada; dados legados sem proprietário não são atribuídos à próxima conta do aparelho. Os testes locais A/B passaram. Isto não substitui cifra do banco local, sincronização ou homologação em aparelho compartilhado.

## Confirmação de e-mail — implementação local em 2026-10-15
O backend agora cria contas pendentes de confirmação, bloqueia login enquanto `EmailConfirmed` for falso e oferece confirmação e reenvio com token ASP.NET Identity. Todas as rotas de autenticação têm rate limit de 10 requisições/minuto por instância. Compilação da solução aprovada sem erros. A validação real de e-mail continua **BLOQUEADA** por SMTP/coletor e PostgreSQL isolados, e a tela/deep link Flutter de confirmação ainda é pendente.

## Atualização de confirmação de e-mail — 2026-10-15
O app trata registro como pendente de confirmação, mostra instrução de confirmação e permite reenvio sem expor se o e-mail existe. Ainda falta tratar a abertura do link de confirmação no Flutter e executar o fluxo ponta a ponta com SMTP/coletor e API/Neon isolados; portanto o item permanece **PARCIAL**.

Validações desta alteração: `dotnet build VeroEqulibraFit.slnx --no-restore -v minimal` aprovado com 0 erros/0 avisos. `flutter analyze` não apresentou erros, mas conserva 12 avisos de estilo preexistentes.
