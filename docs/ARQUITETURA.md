# Arquitetura

`Flutter -> API .NET 10 -> FastAPI interna -> Google Gemini`. O Flutter não recebe chaves Gemini nem conexão privilegiada. Neon PostgreSQL será o banco principal; Isar será a persistência local e fila de sincronização. A API será a única fronteira pública de negócio, autenticação, autorização, idempotência e auditoria. A FastAPI aceita apenas autenticação interna e produz DTOs validados; respostas Gemini nunca persistem sem revisão do usuário.
