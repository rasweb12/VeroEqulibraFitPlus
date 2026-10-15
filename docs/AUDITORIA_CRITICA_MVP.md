# Auditoria crítica do MVP

Data: 2026-10-15. Status geral: **REPROVADO**.

## P0-001 — acesso privado sem AuthGate
- Severidade: P0
- Evidência anterior: rota `/` apontava diretamente para `DashboardPage`.
- Correção em andamento: `GoRouter` agora inicia em `/splash`, verifica sessão no repositório seguro e redireciona rotas privadas para `/auth`.
- Estado: PARCIAL — proteção de navegação implementada; validação integrada contra API depende de ambiente isolado configurado.

## P0-002 — sessão baseada apenas em token armazenado
- Severidade: P0
- Correção: expiração JWT é verificada; token expirado tenta refresh; token válido é validado em `/api/v1/auth/session`; falhas removem os tokens e bloqueiam acesso.
- Estado: PARCIAL — necessita teste de integração com banco/API isolados.

## P0-003 — armazenamento local global
- Severidade: P0
- Evidência: SharedPreferences globais em treinos, refeições, hábitos e medidas.
- Estado: REPROVADO — correção de isolamento cifrado por conta ainda pendente. A política atual do AuthGate nega acesso offline até ela existir.
