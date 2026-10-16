# Resend SMTP e links de conta

## Homologação sem domínio próprio

Use a URL pública da API como base dos links:

```text
PublicApp__BaseUrl=https://veroequlibrafitplus.onrender.com
```

Os caminhos públicos `/confirm-email` e `/reset-password` redirecionam para o esquema do aplicativo `veroequilibrafit://account/...`. Android e iOS registram esse esquema. Isso permite testar a abertura do aplicativo sem comprar domínio. O link ainda deve ser testado em aparelho físico antes de homologar o fluxo.

Para o SMTP do Resend no Render, cadastre na API:

| Variável | Valor |
| --- | --- |
| `Email__SmtpHost` | `smtp.resend.com` |
| `Email__SmtpPort` | `587` |
| `Email__UseSsl` | `true` |
| `Email__Username` | `resend` |
| `Email__Password` | API key do Resend, como segredo |
| `Email__From` | remetente autorizado pelo Resend |

Com `System.Net.Mail.SmtpClient`, a porta `587` com STARTTLS é a configuração adequada. Não coloque a chave no APK, Git, `.env.example` ou documentação.

Para testes restritos, o remetente fornecido pelo Resend pode ser usado conforme as limitações da conta. Para enviar mensagens a usuários do produto, compre ou obtenha um domínio sobre o qual você tenha controle de DNS, adicione-o no Resend e publique todos os registros SPF e DKIM que ele indicar. Depois, habilite DMARC gradualmente. Subdomínios gratuitos e serviços de redirecionamento de e-mail não dão controle confiável dos registros necessários e não são recomendados para autenticação de conta.

## Verificação mínima

1. Crie uma API key SMTP no Resend e cadastre-a somente em `Email__Password`.
2. Configure as variáveis acima e `PublicApp__BaseUrl` no serviço API do Render.
3. Faça deploy da API que contém os redirecionamentos públicos.
4. Instale um APK com `--dart-define=API_BASE_URL=https://veroequlibrafitplus.onrender.com`.
5. Cadastre uma conta de teste, abra o e-mail no aparelho, confirme a conta, entre e repita o processo de redefinição de senha.

Nenhum passo acima autoriza envio em massa ou transforma testes em homologação de produção.
