# Integração Gemini

Somente `google-genai` é dependência de IA. Chave e modelo são variáveis apenas do servidor. O serviço interno exige `VERO_EQUILIBRAFIT_INTERNAL_API_KEY`, valida JSON com Pydantic, limita saída e encerra por timeout; não há fallback OpenAI. O modelo padrão é configurável e não foi validado contra uma conta real.
