# Validação de foto de refeições

REPROVADO. O FastAPI possui reconhecimento, mas o Flutter ainda não envia imagem pela API .NET autenticada.

## Foto de refeições — implementação local em 2026-10-15
- Backend: `POST /api/v1/meals/analyze-photo` exige JWT, aceita somente JPEG/PNG/WebP, confere assinatura do arquivo e limita o payload decodificado a 5 MB antes de encaminhar o conteúdo ao FastAPI interno com a credencial entre serviços.
- Flutter: câmera/galeria, prévia, revisão explícita e confirmação antes do registro. Nenhuma foto é persistida por este fluxo.
- Limitações: ainda não há teste ponta a ponta com Gemini, API/Neon e uma imagem autorizada. A tentativa de gerar APK debug não concluiu no ambiente de automação após iniciar o daemon Gradle; não há evidência de novo APK.
- Estado: **PARCIAL**. O cadastro local atual não persiste os macronutrientes revisados no Neon e não há upload protegido de mídia privada.
