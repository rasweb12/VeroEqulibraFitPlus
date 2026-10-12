# Pendências

- Integrar a fila Isar às ações de plano, hábitos, refeições e sessões, com persistência local cifrada e sincronização de conflitos.
- Finalizar login/JWT com provedor isolado, testes REST autenticados, Neon/EF migrations aplicadas somente após autorização e isolamento de contas ponta a ponta.
- Conectar alimentação, hábitos e administração à API autenticada. O Coach já possui fluxo Flutter → API .NET → FastAPI Gemini, mas requer sessão JWT e configurações de ambiente para execução real.
- Completar metadados técnicos de mídia com ffprobe e associar vídeos a exercícios estáveis.
- Configurar credenciais isoladas do novo ambiente para Gemini, Neon e Render. Credenciais existentes nos projetos de origem não foram reutilizadas.
