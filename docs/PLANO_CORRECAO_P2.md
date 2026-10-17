# Plano de correção P2

## Próxima entrega controlada

1. Cadastrar `Jwt__Audience=vero-equilibrafit-mobile` no serviço API do Render e fazer deploy do commit que contém a validação.
2. Confirmar que a API sobe somente com `Jwt__Issuer`, `Jwt__Audience`, `Jwt__SigningKey`, `Database__ConnectionString`, `AI__BaseUrl` e `AI__InternalApiKey` válidos.
3. Executar, em dados de homologação, cadastro, e-mail de confirmação, login, refresh, logout, recuperação e exclusão de conta.
4. Recriar o ambiente Python a partir de `pyproject.toml`, executar `pytest` e `ruff`, e registrar os resultados sem chaves.

## Trabalho ainda necessário

- Implementar outbox persistente, sincronização autenticada, tombstones, versão de registro e conflitos por proprietário.
- Completar edição/revisão individual de itens reconhecidos por foto e persistência/recuperação de plano alimentar no Flutter.
- Implementar administração com autenticação, autorização por papel e endpoints administrativos protegidos.
- Associar mídias somente depois de comprovação de licença, origem e exercício estável.
- Executar os fluxos offline/online para duas contas em dois dispositivos e o fluxo real Gemini com imagens autorizadas.

Nenhum item desta lista é considerado concluído antes de evidência funcional reproduzível.
