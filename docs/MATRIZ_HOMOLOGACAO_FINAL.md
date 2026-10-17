# Matriz de homologação final — 17/10/2026

| Requisito | Estado | Evidência atual |
| --- | --- | --- |
| AuthGate e rotas privadas | PARCIAL | Código e testes locais anteriores; falta instalação limpa e deep link contra API atualizada. |
| JWT, refresh e logout | PARCIAL | Implementação revisada; audiência corrigida localmente. Falta deploy e teste real. |
| Confirmação/recuperação SMTP | BLOQUEADO | Implementação existe; não há evidência ponta a ponta de entrega e uso de link. |
| Isolamento local por conta | PARCIAL | Secure storage com namespace por usuário; falta teste físico A/B. |
| Exclusão de conta | PARCIAL | Remoção transacional de dados adicionada localmente; falta teste PostgreSQL. |
| Coach Gemini | NÃO TESTADO | Gateway interno protegido, mas fluxo real não foi executado. |
| Foto de refeições Gemini | PARCIAL | Fluxo e contratos existem; falta teste real e edição individual completa. |
| Plano alimentar | PARCIAL | API possui gerar/aprovar/listar/editar; Flutter e persistência remota ainda não homologados. |
| Fichas e catálogo | PARCIAL | Busca antes da IA e CRUD local existem; falta sincronização real entre dispositivos. |
| Vídeos | BLOQUEADO | Inventário existe; licença e associação não comprovadas. |
| Administração Blazor | REPROVADO | Shell sem autenticação e sem operações previstas. |
| Neon | PARCIAL | Health ready e migrations previamente verificadas; fluxos funcionais ainda não foram testados. |
| APK atualizado/instalado | NÃO TESTADO | Build anterior encontrou cache CMake corrompido e ADB indisponível. |
| MVP | REPROVADO | Há bloqueios P0/P1/P2 acima. |
