# Rotação da chave interna API → IA

Use este procedimento porque a chave anterior foi exposta fora do repositório.
Ela deve ser tratada como comprometida e não deve ser reutilizada.

## Preparação já incluída no código

O FastAPI aceita, temporariamente, duas chaves:

- `VERO_EQUILIBRAFIT_INTERNAL_API_KEY`: chave nova, obrigatória.
- `VERO_EQUILIBRAFIT_PREVIOUS_INTERNAL_API_KEY`: chave anterior, opcional e
  exclusiva para a janela de transição.

Os valores são comparados com comparação em tempo constante. Ao remover a
variável anterior, apenas a chave atual volta a ser aceita.

## Procedimento no Render

1. Publique a versão que contém a compatibilidade de rotação.
2. Gere uma nova chave aleatória com pelo menos 32 caracteres usando o
   gerador de segredo do Render. Não use uma chave copiada de logs, telas ou
   conversas.
3. No serviço `vero-equilibrafit-ai`, mantenha a chave exposta em
   `VERO_EQUILIBRAFIT_PREVIOUS_INTERNAL_API_KEY` e grave a nova em
   `VERO_EQUILIBRAFIT_INTERNAL_API_KEY`.
4. No serviço `vero-equilibrafit-api`, atualize `AI__InternalApiKey` com a
   mesma chave nova. Se o vínculo `fromService` estiver efetivo, confirme o
   valor sem revelá-lo e acione o redeploy da API para consumir a alteração.
5. Confirme em produção, sem registrar segredos: Coach, reconhecimento de
   foto e geração de plano alimentar devem responder pela API autenticada.
6. Após a confirmação, remova
   `VERO_EQUILIBRAFIT_PREVIOUS_INTERNAL_API_KEY` do serviço de IA e faça novo
   redeploy. A chave exposta ficará revogada.

## Rollback durante a janela

Se a API ainda usar a chave anterior, ela continua válida enquanto a variável
`PREVIOUS` existir. Não reverta para a chave exposta como chave principal.
Corrija a variável da API para a chave nova e então conclua a revogação.
