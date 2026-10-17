# Relatório de testes P2 — 17/10/2026

| Verificação | Resultado | Evidência/limite |
| --- | --- | --- |
| Build .NET API | APROVADO | `dotnet build backend/VeroEqulibraFit.Api/VeroEqulibraFit.Api.csproj --no-restore -m:1 -v minimal`: 0 erros, 0 avisos. |
| Testes JWT .NET | NÃO CONCLUSIVO | A execução com filtro recompilou o projeto, mas não retornou resumo de testes dentro da janela da ferramenta. Não registrar como aprovado. |
| Testes Python de configuração e contrato de exercícios | APROVADO | 6 testes: `test_configuration.py` e `test_exercise_contract.py`, todos aprovados no ambiente isolado. |
| Testes Python de rotas | APROVADO | 3 testes em `test_contract.py` aprovados após fixar versões compatíveis FastAPI/Starlette. |
| Ruff Python | APROVADO | `ruff check app tests`: sem achados no ambiente isolado. |
| Flutter format | APROVADO | Formatação aplicada a 39 arquivos; 11 foram normalizados. |
| Flutter analyze | NÃO CONCLUSIVO | A análise iniciou e não retornou relatório final dentro da janela disponível. |
| Login/cadastro/recuperação reais | NÃO TESTADO | Exige deploy das correções, SMTP homologado e conta de teste. |
| Deep links Android/iOS | NÃO TESTADO | Requer aparelhos/emuladores com o APK atualizado. |
| Coach Gemini real | APROVADO | Em 17/10/2026, resposta real foi exibida no Flutter autenticado após deploy da API e da IA. |
| Foto/plano Gemini | NÃO TESTADO | Requer chamadas autorizadas separadas e revisão funcional no aplicativo. |
| Sincronização dois dispositivos | REPROVADO | Não há implementação/evidência suficiente de outbox e resolução de conflitos. |

Os resultados acima não inferem aprovação de nenhum fluxo não executado.
