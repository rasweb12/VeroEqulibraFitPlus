from __future__ import annotations

import json

from pydantic import ValidationError

from app.core.config import Settings
from app.providers.ai_provider_router import AiProviderRouter
from app.schemas.exercises import ExerciseCandidate, ExerciseSuggestionRequest


class ExerciseService:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings
        self._provider = AiProviderRouter(settings)

    async def suggest(self, request: ExerciseSuggestionRequest) -> ExerciseCandidate:
        result = await self._provider.complete_json_result(
            feature="exercises",
            system_prompt=(
                "Você gera candidatos estruturados de exercício. Não invente IDs, mídia, cargas pessoais "
                "ou alegações clínicas. Responda JSON válido e exija confirmação do usuário."
            ),
            user_prompt=(
                f"Consulta: {request.query}\n"
                f"Nomes já pesquisados no catálogo: {json.dumps(request.known_catalog_names, ensure_ascii=False)}\n"
                "Se não houver informação suficiente, retorne status needs_clarification."
            ),
        )
        if not isinstance(result.payload, dict):
            return ExerciseCandidate(status="needs_clarification")
        try:
            return ExerciseCandidate.model_validate(result.payload)
        except ValidationError:
            return ExerciseCandidate(status="needs_clarification")
