# Matriz de adaptação Stitch

| Módulo | Referência | Arquivo Flutter | Estado inicial | Direção |
| --- | --- | --- | --- | --- |
| Dashboard | Código anexado + tokens | `features/dashboard/.../dashboard_page.dart` | PARCIAL | Shell e dados reais aplicados; falta captura comparativa Android. |
| Treinos | `veroequilibrafit_treinos_da_semana` | `app.dart` e `features/training/presentation` | PARCIAL | Lista de fichas usa tema/navegação; detalhes e biblioteca ainda precisam composição própria. |
| Nutrição | `veroequilibrafit_alimenta_o` | `features/nutrition/presentation` | PARCIAL | Diário, relatório, plano e scanner receberam tokens; falta revisão visual dos formulários e foto. |
| Hábitos | `veroequilibrafit_h_bitos_e_hidrata_o` | `features/habits/presentation` | PARCIAL | Cartão de hidratação, missões e ações reais adaptados; falta histórico visual. |
| Evolução | `veroequilibrafit_evolu_o_corporal` | `features/measurements/presentation` | PARCIAL | Tema/navegação aplicados; gráficos, fotos e edição ainda precisam composição própria. |
| Coach | `veroequilibrafit_coach_gemini` | `features/coach/presentation` | PARCIAL | Shell e resposta real adaptados; falta histórico de conversa em formato de chat. |
| Perfil | `veroequilibrafit_perfil` | `features/profile/presentation` | PARCIAL | Conta autenticada, metas, privacidade e logout adaptados; falta captura em Android. |

Não há referência para autenticação, recuperação de senha, scanner, planos alimentares e telas de detalhes. Esses fluxos mantêm Material 3 e passam a usar tokens compartilhados quando forem revisados.
