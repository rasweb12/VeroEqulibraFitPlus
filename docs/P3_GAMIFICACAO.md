# P3.6 — Missões e consistência

## Estado: PARCIAL

As missões diárias são calculadas a partir de dados reais, locais e associados à conta autenticada: uma refeição registrada no dia, o progresso de hidratação e a marcação de mobilidade. Elas não geram punições, não prescrevem treino ou alimentação e ficam em `Missões de hoje`.

O progresso é recalculado a cada atualização dos repositórios de refeições e hábitos. Nenhuma pontuação, medalha, sequência histórica ou recompensa é apresentada como concluída, porque esses recursos ainda não possuem modelo remoto, regras de retenção ou sincronização homologada.

## Evidência local

- `mobile/vero_equilibrafit_app/lib/features/habits/presentation/missions_page.dart`
- rota protegida `/missions` em `mobile/vero_equilibrafit_app/lib/app.dart`
- atalho no dashboard.

## Pendente

- Persistir histórico e preferências de missões no backend/Neon.
- Sincronizar entre dispositivos.
- Implementar sequências, pontos e medalhas com regras revisáveis.
- Testar em Android e em dois dispositivos.
