# Matriz de aceite funcional

| Requisito | Estado | Evidência |
|---|---|---|
| AuthGate | PARCIAL | Rotas privadas redirecionam durante boot e sem sessão. |
| Login/cadastro | PARCIAL | API e tela existem; falta homologação isolada. |
| Recuperação/confirmação | REPROVADO | Não há provedor de e-mail configurado. |
| Isolamento local | PARCIAL | Treinos, refeições, hábitos e medidas usam armazenamento seguro do SO com namespace por conta; dados legados não são migrados sem proprietário. Falta teste em aparelho compartilhado e sincronização remota. |
| Foto de refeições | PARCIAL | Fluxo Flutter e endpoint .NET existem; falta chamada Gemini real, persistência e revisão ponta a ponta. |
| Coach ponta a ponta | PARCIAL | Camadas existem; falta sessão e ambiente integrado. |
| Persistência Neon | PARCIAL | Quatro migrations aplicadas ao Neon isolado em 2026-10-16; Flutter ainda não sincroniza dados locais pela API. |
| Administração Blazor | REPROVADO | As páginas de exemplo Counter/Weather foram removidas, mas ainda faltam autenticação administrativa e operações do produto. |
| Vídeos licenciados | BLOQUEADO | Inventário existe; licenças e mapeamento incompletos. |
