# Validação Gemini

Não homologada. Não houve chamada Gemini paga nesta auditoria. O fluxo real depende de ambiente isolado e credencial de servidor.

Atualização 2026-10-16: o cliente Flutter do Coach passou a depender da sessão autenticada e usa `API_BASE_URL` centralizado. O token segue apenas para a API .NET. A execução Flutter→.NET→FastAPI→Gemini ainda não foi homologada ponta a ponta; o Neon isolado e os serviços Render passaram a existir, mas a IA precisa ser mantida privada, receber o deploy dos endpoints de health e ser exercitada com uma conta de teste autorizada.
