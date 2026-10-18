# Matriz de homologação final — 17/10/2026

| Requisito | Estado | Evidência atual |
| --- | --- | --- |
| AuthGate e rotas privadas | PARCIAL | Código e testes locais anteriores; falta instalação limpa e deep link contra API atualizada. |
| JWT, refresh e logout | PARCIAL | Implementação revisada; audiência corrigida localmente. Falta deploy e teste real. |
| Confirmação/recuperação SMTP | BLOQUEADO | Implementação existe; não há evidência ponta a ponta de entrega e uso de link. |
| Isolamento local por conta | PARCIAL | Secure storage com namespace por usuário; falta teste físico A/B. |
| Exclusão de conta | PARCIAL | Remoção transacional de dados adicionada localmente; falta teste PostgreSQL. |
| Coach Gemini | APROVADO | Em 17/10/2026, uma pergunta no Flutter autenticado recebeu resposta real pelo fluxo API → IA → Gemini. |
| Foto de refeições Gemini | PARCIAL | Fluxo e contratos existem; falta revisão individual, persistência de itens e teste real. |
| Plano alimentar | PARCIAL | API possui gerar/aprovar/listar/editar; Flutter e persistência remota ainda não homologados. |
| Fichas e catálogo | PARCIAL | Busca antes da IA e CRUD local existem; falta sincronização real entre dispositivos. |
| Vídeos | BLOQUEADO | Inventário existe; licença e associação não comprovadas. |
| Administração Blazor | REPROVADO | Shell sem autenticação e sem operações previstas. |
| Neon | PARCIAL | Health/migrations relatados; a API não possui sincronização push/pull e os fluxos funcionais não foram testados. |
| APK atualizado/instalado | PARCIAL | APK debug atualizado foi compilado e instalado no emulador em 17/10/2026. Falta roteiro funcional completo no dispositivo. |
| MVP | REPROVADO | Há pendências de Blazor operacional completo, fotos de evolução e validação em dois dispositivos. |

## Atualização de aceite manual — 18/10/2026

O responsável aprovou HML-01 a HML-08: autenticação/Brevo, AuthGate, Coach Gemini, foto de refeição com revisão, scanner e cadastro manual, alimentação/metas/relatórios, treinos/hábitos/medidas/missões e sincronização Neon isolado. A evidência e os limites estão em [HOMOLOGACAO_MANUAL_2026-10-18.md](HOMOLOGACAO_MANUAL_2026-10-18.md).

Este registro substitui os estados anteriores desses fluxos, que passam a **APROVADO** por homologação manual. Os demais itens da matriz permanecem com seu estado próprio; em especial, a administração Blazor ainda está reprovada e a validação em dois dispositivos não foi incluída no aceite informado.

