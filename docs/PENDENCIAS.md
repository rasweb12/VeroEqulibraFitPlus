# Pendências

- Integrar a fila Isar às ações de plano, hábitos, refeições e sessões, com persistência local cifrada e sincronização de conflitos. Fichas, exercícios personalizados, refeições, hidratação e mobilidade já são preservados localmente entre reinícios por `SharedPreferences`; dados de saúde e sincronização continuam pendentes de armazenamento cifrado e isolamento por conta.
- Implementar fotos de evolução com consentimento, armazenamento cifrado e controle de retenção. Medidas corporais locais já estão disponíveis, mas fotografias não devem ser incluídas antes dessas garantias.
- Finalizar login/JWT com provedor isolado, testes REST autenticados, Neon/EF migrations aplicadas somente após autorização e isolamento de contas ponta a ponta.
- Conectar alimentação, hábitos e administração à API autenticada. A API já possui endpoints autenticados para fichas e refeições, isolados pelo `sub`/`NameIdentifier` do JWT; o Flutter ainda precisa trocar o repositório local pelo cliente REST após o login. O Coach já possui fluxo Flutter → API .NET → FastAPI Gemini, mas requer sessão JWT e configurações de ambiente para execução real.
- Completar metadados técnicos de mídia com ffprobe e associar vídeos a exercícios estáveis.
- Configurar credenciais isoladas do novo ambiente para Gemini, Neon e Render. Credenciais existentes nos projetos de origem não foram reutilizadas.
