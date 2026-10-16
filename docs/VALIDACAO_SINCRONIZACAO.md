# Validação de sincronização

REPROVADO. O Neon isolado foi criado e recebeu as migrations versionadas em 2026-10-16, mas o Flutter ainda não sincroniza fichas, refeições, hábitos e medidas com a API. Os dados locais continuam sem cifra em `SharedPreferences` e não existe outbox, retry com backoff, resolução de conflitos entre dispositivos ou teste de troca de aparelho.
