# Matriz de aceite funcional

| Requisito | Estado | Evidência |
|---|---|---|
| AuthGate | PARCIAL | Rotas privadas redirecionam durante boot e sem sessão. |
| Login/cadastro | PARCIAL | API e tela existem; falta homologação isolada. |
| Recuperação/confirmação | REPROVADO | Não há provedor de e-mail configurado. |
| Isolamento local | PARCIAL | Chaves locais têm namespace por conta; treino, refeições, hábitos e medidas ainda usam SharedPreferences sem cifra, outbox ou teste em aparelho compartilhado. |
| Foto de refeições | PARCIAL | Fluxo Flutter e endpoint .NET existem; falta chamada Gemini real, persistência e revisão ponta a ponta. |
| Coach ponta a ponta | PARCIAL | Camadas existem; falta sessão e ambiente integrado. |
| Persistência Neon | PARCIAL | Quatro migrations aplicadas ao Neon isolado em 2026-10-16; Flutter ainda não sincroniza dados locais pela API. |
| Administração Blazor | REPROVADO | Projeto ainda é shell sem autenticação administrativa nem operações do produto. |
| Vídeos licenciados | BLOQUEADO | Inventário existe; licenças e mapeamento incompletos. |
