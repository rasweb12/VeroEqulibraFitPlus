# Alimentação e IA

O domínio local contém registros de refeição e planos alimentares, ambos isolados por usuário e com exclusão lógica. Planos gerados por IA carregam aprovação explícita do usuário; fotos fornecem estimativas, nunca valores exatos. O fluxo exige revisão e não fornece diagnóstico ou tratamento médico. APIs, telas, foto e sincronização permanecem pendentes.

Atualização 2026-10-16: endpoints autenticados de planos alimentares foram adicionados para gerar proposta Gemini, aprovar/persistir após revisão, listar e arquivar por proprietário. `dotnet build backend/VeroEqulibraFit.Api/VeroEqulibraFit.Api.csproj --no-restore -v minimal` aprovado. Não houve execução real Gemini/Neon.
