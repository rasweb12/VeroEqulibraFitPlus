# Validação de foto de refeições

REPROVADO. O FastAPI possui reconhecimento, mas o Flutter ainda não envia imagem pela API .NET autenticada.

## Foto de refeições — implementação local em 2026-10-15
- Backend: `POST /api/v1/meals/analyze-photo` exige JWT, aceita somente JPEG/PNG/WebP, confere assinatura do arquivo e limita o payload decodificado a 5 MB antes de encaminhar o conteúdo ao FastAPI interno com a credencial entre serviços.
- Flutter: câmera/galeria, prévia, revisão explícita e confirmação antes do registro. Nenhuma foto é persistida por este fluxo.
- Limitações: ainda não há teste ponta a ponta com Gemini, API/Neon e uma imagem autorizada. A tentativa de gerar APK debug não concluiu no ambiente de automação após iniciar o daemon Gradle; não há evidência de novo APK.
- Estado: **PARCIAL**. O cadastro local atual não persiste os macronutrientes revisados no Neon e não há upload protegido de mídia privada.

Atualização 2026-10-16: depois da confirmação explícita, calorias e macros estimados passam a acompanhar o registro local e aparecem no histórico como aproximações. Ainda não há sincronização Neon nem homologação com Gemini real.

## Revisão individual — 17/10/2026

- A resposta de `analyze-photo` agora abre uma página própria antes do salvamento. Cada alimento pode ter nome, porção, unidade e macronutrientes estimados corrigidos, pode ser removido e novos alimentos podem ser adicionados.
- A tela recalcula os totais a partir dos campos revisados e permite definir a data do registro. A foto continua efêmera: ela é exibida apenas durante a revisão e não é mantida pelo aplicativo nesse fluxo.
- Evidências locais: `dart analyze lib/features/nutrition/presentation/nutrition_page.dart lib/app.dart` e `flutter test` concluídos em 17/10/2026 (9 testes aprovados).
- Limite atual: o `MealEntry` local persiste o resumo revisado e seus totais; ainda não possui uma coleção remota de alimentos individuais, nem sincronização Neon. Portanto, o fluxo ponta a ponta Foto → Gemini → revisão → Neon → segundo dispositivo continua **PARCIAL** e não é evidência de homologação real.
