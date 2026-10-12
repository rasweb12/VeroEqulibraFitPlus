# Sprints 4 a 6 — registro de entrega

## Sprint 4 — Gemini e cadastro inteligente

Objetivo: atender sugestões estruturadas sem OpenAI e sem salvar respostas automaticamente.

Entregas: FastAPI interno com autenticação por chave de serviço, `ExerciseCandidate` Pydantic com os três status oficiais, timeout, limite de saída, validação de JSON e rejeição de IDs de catálogo inventados. A API continua consultando o catálogo antes da IA. Arquivos principais: `ai/vero_equilibrafit_ai/app/main.py` e testes de contrato em `tests/test_exercise_contract.py`.

Limites: não houve chamada Gemini real nem Pytest/Ruff por bloqueio local durante a instalação do ambiente Python. A sintaxe foi verificada com `compileall`; nenhuma chave foi usada.

## Sprint 5 — mídia

Objetivo: inventariar mídias sem redistribuí-las.

Entregas: `docs/inventario_videos.csv` com 166 linhas, nome, caminho de origem, tamanho, SHA-256, possível exercício e status de autorização. `scripts/New-VideoInventory.ps1` permite regenerar o arquivo sem escrever na origem.

Limites: `ffprobe` não está instalado, portanto duração, resolução e codec não foram extraídos. Termos de redistribuição permanecem não comprovados; todo conteúdo fica excluído de builds distribuíveis.

## Sprint 6 — alimentação

Objetivo: criar a base de dados do módulo alimentar com revisão humana.

Entregas: entidades `MealEntry` e `NutritionPlan`, isolamento por `OwnerId`, exclusão lógica, revisão obrigatória de estimativas e aprovação explícita de planos gerados por IA. Migration local `AddNutritionFoundation` gerada sem aplicação remota.

Limites: telas, APIs autenticadas, reconhecimento de foto, plano semanal, sincronização e avaliação nutricional ainda não foram implementados. Nenhuma estimativa nutricional ou orientação clínica foi apresentada ao usuário.

## Evidências e integridade

`dotnet build VeroEqulibraFit.slnx --no-restore` foi aprovado. O `flutter analyze` estava limpo e os testes Flutter passaram antes destas entregas; a repetição final não alterou o código Flutter. Os projetos de origem foram somente lidos. Nenhum banco, serviço Render, Supabase, Neon ou Gemini foi alterado.
