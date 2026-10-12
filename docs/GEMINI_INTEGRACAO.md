# Integração Gemini

Somente `google-genai` é dependência de IA. O gateway FastAPI foi adaptado dos módulos maduros do EquilibraFit++ e disponibiliza Coach, geração de treino, planos alimentares, estimativa de refeições, leitura de rótulos e cadastro assistido de exercício. Chave e modelo são variáveis apenas do servidor. O serviço interno exige `VERO_EQUILIBRAFIT_INTERNAL_API_KEY`, valida JSON com Pydantic, limita saída e encerra por timeout; não há fallback OpenAI. A API .NET chama o gateway via `AI__BaseUrl` e `AI__InternalApiKey`; o Flutter chama somente a API .NET autenticada.

O cadastro assistido faz a busca no catálogo .NET antes da chamada Gemini. Um resultado Gemini não pode carregar ID de catálogo e exige confirmação do usuário. As credenciais do EquilibraFit++ não foram lidas nem copiadas; configure uma chave própria no ambiente do novo serviço para habilitar chamadas reais.
