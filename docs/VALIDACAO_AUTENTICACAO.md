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

## Redefinição de senha na interface — 2026-10-15
A rota pública `/reset-password` foi adicionada. Ela lê `userId` e token do link, exige confirmação da nova senha e chama a API antes de voltar ao login. Não foi possível comprovar recebimento/abertura do link porque SMTP/coletor, URL pública e banco isolado não foram configurados.

Validação local: `flutter test --reporter expanded` aprovado (8 testes).

## Link de confirmação no Flutter — 2026-10-15
Foi adicionada a rota pública `/confirm-email`. O aplicativo lê `userId` e token do link e confirma a conta pela API antes de enviar a pessoa ao login. Como o endereço público, deep link do Android/iOS e SMTP ainda não foram configurados nem testados, a confirmação ponta a ponta segue **BLOQUEADA** e não homologada.

`flutter analyze` foi executado sem erros de compilação; persistem 12 avisos de estilo preexistentes.

## Correção de inicialização JWT e Render — 2026-10-16

**Status: PARCIAL.** A API valida `Jwt__Issuer` e `Jwt__SigningKey` antes de construir o host. Como a assinatura é HS512, a chave precisa ter no mínimo 64 bytes UTF-8; chaves menores agora encerram a inicialização com mensagem explícita, antes de atender requisições. Não há chave padrão e não há geração de chave durante startup.

A configuração inclui rotação de refresh token já existente, chaves de ASP.NET Data Protection persistidas em `data_protection_keys` e uma migration local `AddDataProtectionKeys`, ainda não aplicada a ambiente remoto. O endpoint `/health/live` só confirma processo ativo; `/health/ready` verifica conectividade PostgreSQL. Nenhum desses endpoints é evidência de login, e-mail ou homologação funcional.

Evidências locais em 2026-10-16:

- `dotnet build VeroEqulibraFit.slnx --no-restore -v minimal`: aprovado, 0 erros e 0 avisos.
- `dotnet test tests/VeroEqulibraFit.Api.Tests/VeroEqulibraFit.Api.Tests.csproj --no-restore -v minimal`: aprovado, 7 testes, 0 falhas.
- Os testes cobrem emissor ausente, chave ausente, chave curta, JWT válido, assinatura inválida, expiração e `401` em `/api/v1/auth/session` sem credencial.

Permanecem **BLOQUEADOS** por ambiente isolado ainda não homologado: conexão real ao Neon, migrations autorizadas, SMTP para confirmação/recuperação, URL/deep links públicos e o fluxo Flutter em dispositivo contra a API implantada. Portanto, a Sprint de autenticação permanece reprovada até essas evidências ponta a ponta existirem.

## Armazenamento local por conta — 2026-10-16

Treinos, refeições, medidas e hábitos deixaram de gravar dados privados em `SharedPreferences`. O adaptador `SecureOwnerStore` usa o armazenamento seguro do sistema operacional e cada recurso recebe uma chave derivada do `userId` validado. Dados legados sem proprietário continuam deliberadamente inacessíveis; não há atribuição automática à próxima pessoa que entrar no aparelho.

O logout remove apenas os cinco registros de sessão. Isso impede que o logout de uma conta elimine os registros cifrados de outra conta em aparelho compartilhado. A exclusão de conta chama `DELETE /api/v1/auth/account` e, após sucesso, remove somente as chaves privadas do proprietário atual. A validação em dispositivo físico e contra a API pública permanece pendente, portanto este requisito continua **PARCIAL**, não homologado.
