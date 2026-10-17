# Validação Gemini

## Coach — homologado em 17/10/2026

Foi comprovada uma resposta real do Coach no aplicativo autenticado. A cadeia verificada foi Flutter → API .NET pública → FastAPI Render → Google Gemini → Flutter. A resposta exibiu o modelo Gemini configurado e não foi uma resposta estática local.

Os health checks da IA respondem `200` em `/health/live`. A comunicação entre API e IA usa uma chave interna compartilhada; a chave Gemini permanece apenas no serviço IA.

## Itens ainda não homologados

- Reconhecimento de foto de refeição com Gemini.
- Geração e persistência de plano alimentar com Gemini.
- Cadastro assistido de exercícios com Gemini.
- Quotas, timeouts, respostas inválidas e indisponibilidade em ambiente real.

O Coach aprovado não torna os demais fluxos Gemini aprovados.
