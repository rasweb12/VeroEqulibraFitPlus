# Testes do redesign Stitch

Data: 18/10/2026.

| Verificação | Estado | Evidência |
|---|---|---|
| Inventário do Stitch em somente leitura | APROVADO | `STITCH_INVENTARIO.md` |
| ThemeData e componentes compartilhados | APROVADO em análise estática | `lib/shared/presentation/vero_design.dart` |
| Dashboard com providers existentes | APROVADO em análise estática | `dashboard_page.dart` |
| Navegação inferior por GoRouter | APROVADO em análise estática | `VeroBottomNavigation` usa `context.go` |
| Dados de protótipo não transportados | APROVADO por revisão de código | nenhum nome, métrica ou imagem de exemplo foi adicionada |
| Teste de widget e regressão funcional | APROVADO | `flutter test --reporter compact`: 16 testes aprovados em 18/10/2026. |
| APK Android Debug | APROVADO | APK atualizado com `API_BASE_URL` e instalado no AVD Pixel 7 API 36. |
| AuthGate Android em instalação sem sessão | APROVADO | Splash → Login; evidência `evidence/android-authgate-ready.png`. Nenhuma rota privada foi exposta. |
| Capturas privadas e comparação lado a lado | BLOQUEADO | o AVD não contém conta de teste autenticada; não foi criado atalho de autenticação. |
| Login em modo escuro, fonte 130% e viewport 720×1600 | PARCIAL | Validado no AVD Pixel 7 API 36 sem overflow. A captura não foi retida porque o preenchimento automático do emulador inseriu um e-mail previamente usado. Ainda faltam telas autenticadas, teclado e fontes ampliadas nas telas privadas. |

O status visual do redesign é **PARCIAL**. Há evidência Android para Splash/AuthGate/Login, mas faltam capturas autenticadas e comparação lado a lado das telas privadas.
