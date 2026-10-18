# Pendências

- Completar a sincronização remota para todos os submódulos de hábitos, anotações e missões, inclusive conflitos e tombstones. O aceite de sincronização Neon isolado de 18/10/2026 está registrado em `docs/HOMOLOGACAO_MANUAL_2026-10-18.md`; ele não substitui a evidência específica desses submódulos.
- Implementar fotos de evolução com consentimento, armazenamento cifrado e controle de retenção. Medidas corporais locais já estão disponíveis, mas fotografias não devem ser incluídas antes dessas garantias.
- Completar os cenários de exclusão de conta, exportação e isolamento entre duas contas no mesmo dispositivo com evidência independente. Login, cadastro, recuperação via Brevo, JWT, refresh, logout, sessão e bloqueio de rotas foram homologados manualmente em 18/10/2026.
- Completar o painel Blazor com autenticação administrativa, páginas operacionais, auditoria e autorização de servidor. O Coach, alimentação e foto/revisão Gemini foram homologados manualmente em 18/10/2026.
- Homologar o login do painel Blazor com uma conta `Administrator` e comprovar que uma conta comum recebe bloqueio. A fundação cliente-servidor está em `docs/ADMIN_OPERACIONAL.md`; catálogo, mídias, auditoria e quotas ainda dependem de endpoints administrativos.
- Executar o roteiro de dois dispositivos em `docs/TESTE_DOIS_DISPOSITIVOS.md`. Ele permanece NÃO TESTADO até haver dois aparelhos ou emuladores independentes.
- Completar metadados técnicos de mídia com ffprobe e associar os demais vídeos a exercícios estáveis. As cinco associações verificadas do catálogo inicial (supino inclinado com halteres, agachamento com barra, leg press, puxada frontal e rosca direta) já têm player local no app.
- Manter testes automatizados de regressão para a comunicação API → FastAPI privada → Gemini, sem registrar chaves ou conteúdo pessoal nos logs. A execução funcional foi homologada manualmente em 18/10/2026; credenciais existentes nos projetos de origem não foram reutilizadas.
