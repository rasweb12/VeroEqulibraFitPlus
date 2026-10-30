# Validação do catálogo

## Dados de origem

- Registros de origem: 200
- Registros versionados: 200
- IDs legados: 1 a 200, únicos
- Schema: 1.0.0
- Vídeos vinculados: 5, todos provenientes de mapeamentos legados já existentes
- Arquivos MP4 preservados: 166

## Compatibilidade

- IDs antigos em fichas já salvas são resolvidos pelo mapeamento legado em TrainingRepository.exerciseById.
- O ID persistido no histórico não é regravado; não há migração destrutiva.
- Novas seleções usam o ID canônico do catálogo oficial.
- O catálogo é carregado por ootBundle.loadString e valida versão, total, campos obrigatórios e unicidade.
- Falha de asset ou JSON mantém o catálogo legado de contingência e expõe diagnóstico no repositório.
- Exercícios personalizados continuam separados por proprietário autenticado.

## Verificações executadas

- Validação estrutural PowerShell: **PASSOU** — 200/200, IDs únicos de 1 a 200 e 5 vídeos validados.
- dart analyze: **No issues found**. O processo depois reportou falha de permissão ao atualizar telemetria em C:\Users\RASS\AppData\Roaming\.dart-tool; não é erro do projeto.
- lutter test: **PENDENTE/BLOQUEADO no ambiente atual**. O processo é encerrado pela camada de terminal antes de produzir saída; nenhum resultado de teste é declarado como aprovado.
- `flutter build apk --debug`: **PENDENTE/BLOQUEADO** — o executor local interrompe a tarefa Gradle sem retornar um código de saída; nenhum APK novo foi instalado.

## Pendências manuais

Os demais 161 arquivos de vídeo não foram vinculados por semelhança nominal. Eles precisam de validação explícita antes de aparecerem como demonstração de um exercício.

