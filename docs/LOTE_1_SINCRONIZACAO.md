# Lote 1 — Sincronização e persistência

Data: 17/10/2026  
Estado: **PARCIAL — NÃO HOMOLOGADO**

## Auditoria inicial

O armazenamento dos dados locais de treino, refeições, hábitos e medidas usa `SecureOwnerStore`, com chaves isoladas por `ownerId`. Não há uso ativo de `SharedPreferences` para esses dados no código atual. A documentação anterior que afirmava o contrário foi corrigida.

A outbox Isar existia, mas não era acionada por nenhum repositório e só possuía marcação de conclusão. O primeiro incremento adiciona tipo e ID da entidade, versão do cliente, estados, tentativas, horário de nova tentativa e categoria de erro sanitizada. A geração Isar foi atualizada.

## Limites atuais

- Os repositórios ainda não registram cada mutação na outbox de forma atômica.
- Não existem endpoints `push`, `pull` ou cursor de sincronização na API.
- Não há versão de registro, tombstone remoto ou resolução de conflito por entidade.
- Não há demonstração em dois dispositivos/emuladores.

Portanto não há sincronização Flutter ↔ Neon implementada e nenhum dado deve ser considerado recuperável em outro dispositivo.

## Política prevista

- Catálogo oficial: servidor autoritativo.
- Fichas e exercícios personalizados: detectar versão divergente; não substituir silenciosamente.
- Sessões e séries executadas: eventos históricos anexáveis, sem perda.
- Refeições e planos alimentares: conflito explícito quando a mesma revisão divergir.
- Exclusões: tombstones com propagação até confirmação do servidor.

## Próximas correções

1. Definir contratos de push/pull e versão de entidade.
2. Gravar mutação local e outbox no mesmo armazenamento transacional.
3. Implementar processamento idempotente no PostgreSQL e cursor de pull.
4. Integrar treino, alimentação, hábitos e medidas progressivamente.
5. Testar contas A/B e dois emuladores com falha/retry/conflito.