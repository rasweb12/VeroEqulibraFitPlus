# P3 — Especificação funcional e reaproveitamento

Esta P3 começa sobre os fluxos P0–P2 existentes. O diário alimentar será construído reutilizando `MealEntry`, `NutritionRepository`, `MealPhotoAnalysisRepository`, `MealsController` e `NutritionPlansController`, sem duplicar autenticação, cliente HTTP ou fila de sincronização.

A implementação será incremental. Catálogo, porções, metas, fibras, scanner, hidratação, atividades, notas, missões, preferências e administração somente serão marcados como aprovados quando tiverem ciclo completo Flutter → API autenticada → banco isolado, com recuperação e teste correspondente.

Consulte `P3_MATRIZ_ACEITE.md` para o estado de cada item.
