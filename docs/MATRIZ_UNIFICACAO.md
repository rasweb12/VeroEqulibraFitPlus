# Matriz de unificação

| Módulo | Origem | Decisão | Risco | Prioridade | Aceite |
|---|---|---|---|---|---|
| Design e treino | Vero | Adaptar visual e domínio | mudanças locais no original | Alta | análise/testes Flutter |
| Catálogo | Vero `catalog.json` | IDs preservados como semente | catálogo pequeno | Alta | busca antes da IA |
| Planos/alimentação | EquilibraFit++ | Adaptar contratos e domínio | dependia Supabase | Alta | API isolada Neon |
| Gemini/FastAPI | EquilibraFit++ | Recriar somente Gemini | modelo/chave externos | Alta | mocks/contrato |
| Mídias | Vídeos locais | Inventariar, não distribuir | licença indefinida | Alta | autorização documentada |
| Admin | EquilibraFit++ | Planejado | requer API/Auth | Alta | RBAC testado |
