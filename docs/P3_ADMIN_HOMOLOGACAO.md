# P3.8 — Administração e homologação

## Estado: PARCIAL

Foi criada a fundação de autorização na API: a política `admin` exige o papel `Administrator`, e `GET /api/v1/admin/overview` devolve somente contagens operacionais agregadas quando o token possuir esse papel. A política é aplicada no servidor; um token de usuário comum recebe `403`.

A concessão inicial não usa conta ou senha padrão. Ela só é aplicada no início da API quando as variáveis de ambiente abaixo estiverem presentes, para uma conta já criada e confirmada:

```text
AdminBootstrap__Enabled=true
AdminBootstrap__Email=administrador@dominio-controlado.example
```

Após a concessão, a variável `AdminBootstrap__Enabled` deve voltar para `false` e a operação deve ser registrada no procedimento de administração. O e-mail não é escrito nos logs da API.

O projeto Blazor ainda é uma interface inicial e não tem login, sessão administrativa, auditoria ou gestão persistida de catálogo, mídias, alimentos, missões e quotas Gemini. Por isso não pode ser usado como painel operacional e não é evidência de administração homologada.

O MVP permanece **REPROVADO — NÃO HOMOLOGADO**. Os bloqueadores anteriores de SMTP ponta a ponta, Gemini Vision real com persistência Neon, sincronização multi-dispositivo e administração autenticada continuam registrados como pendentes.

## Próximo trabalho necessário

1. Implementar login, expiração de sessão e proteção de rotas Blazor.
2. Registrar auditoria no servidor para concessões e operações administrativas.
3. Criar endpoints e páginas para catálogo, mídias com licença comprovada, alimentos e quotas Gemini.
4. Executar testes de autorização e integração em ambiente isolado.
