# Matriz de adaptação Stitch

| Módulo | Referência | Arquivo Flutter | Estado inicial | Direção |
| --- | --- | --- | --- | --- |
| Dashboard | Código anexado + tokens | `features/dashboard/.../dashboard_page.dart` | REPROVADO visualmente | Portar primeiro com dados Riverpod reais |
| Treinos | `veroequilibrafit_treinos_da_semana` | `features/training/presentation` | EM REAVALIAÇÃO | Cabeçalho, filtros e cartões sem imagens remotas |
| Nutrição | `veroequilibrafit_alimenta_o` | `features/nutrition/presentation` | EM REAVALIAÇÃO | Diário e ações existentes preservados |
| Hábitos | `veroequilibrafit_h_bitos_e_hidrata_o` | `features/habits/presentation` | EM REAVALIAÇÃO | Registros reais e controles rápidos |
| Evolução | `veroequilibrafit_evolu_o_corporal` | `features/measurements/presentation` | EM REAVALIAÇÃO | Histórico real, sem métricas fixas |
| Coach | `veroequilibrafit_coach_gemini` | `features/coach/presentation` | EM REAVALIAÇÃO | Chat autenticado, sem telemetria fictícia |
| Perfil | `veroequilibrafit_perfil` | `features/profile/presentation` | EM REAVALIAÇÃO | Dados de sessão e ações reais |

Não há referência para autenticação, recuperação de senha, scanner, planos alimentares e telas de detalhes. Esses fluxos mantêm Material 3 e passam a usar tokens compartilhados quando forem revisados.
