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

## Reavaliação P0-003 — 2026-10-15
- Correção: treino, refeições, medidas e hábitos agora usam chaves namespaceadas pelo `userId` autenticado. Chaves legadas sem proprietário não são lidas nem migradas automaticamente.
- Contenção em memória: os providers privados dependem da sessão e usam `autoDispose`, descartando estado quando a conta muda ou sai da área privada.
- Testes: `test/owner_isolation_test.dart` confirmou que treino e refeição da conta A não aparecem para a conta B; `flutter test` aprovou 8 testes.
- Estado: **PARCIAL**. O armazenamento ainda é SharedPreferences sem cifra, e faltam outbox/sincronização Neon e ensaio em dispositivo real compartilhado.

## Reavaliação P0-002/P0-004 — 2026-10-15
- Registro cria uma conta com e-mail ainda não confirmado e envia link de confirmação único usando o provedor de token do ASP.NET Identity.
- Login rejeita conta ainda não confirmada. Foram adicionados os endpoints `confirm-email` e `resend-confirmation`; o reenvio sempre responde `202` para não enumerar endereços.
- As rotas de autenticação recebem limite fixo de 10 solicitações por minuto por instância de API. A senha redefinida revoga refresh tokens ativos.
- Evidência local: `dotnet build VeroEqulibraFit.slnx --no-restore -v minimal` aprovado (0 erros, 0 avisos). Não há projeto de testes .NET descoberto na solução, portanto não houve teste HTTP/SMTP/Neon.
- Estado: **PARCIAL**. O aplicativo Flutter ainda precisa concluir a tela de confirmação/reenvio e a abertura de link; a prova completa exige coletor SMTP e PostgreSQL isolados.
