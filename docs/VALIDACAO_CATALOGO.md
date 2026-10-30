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
- O catálogo é carregado por rootBundle.loadString e valida versão, total, campos obrigatórios e unicidade.
- Falha de asset ou JSON mantém o catálogo legado de contingência e expõe diagnóstico no repositório.
- Exercícios personalizados continuam separados por proprietário autenticado.

## Verificações executadas

- Validação estrutural PowerShell: **PASSOU** — 200/200, IDs únicos de 1 a 200 e 5 vídeos validados.
- dart analyze: **No issues found**. O processo depois reportou falha de permissão ao atualizar telemetria em C:\Users\RASS\AppData\Roaming\.dart-tool; não é erro do projeto.
- lutter test: **PENDENTE/BLOQUEADO no ambiente atual**. O processo é encerrado pela camada de terminal antes de produzir saída; nenhum resultado de teste é declarado como aprovado.
- `flutter build apk --debug`: **GERADO** em 30/10/2026 às 07:44. Instalação no emulador pendente por falha interna do Package Manager, sem remoção de dados.

## Pendências manuais

Os demais 161 arquivos de vídeo não foram vinculados por semelhança nominal. Eles precisam de validação explícita antes de aparecerem como demonstração de um exercício.

## Homologação manual Android — 30/10/2026

- **APROVADO pelo responsável:** os 200 exercícios oficiais aparecem em `Treinos > Biblioteca de exercícios`.
- **APROVADO pelo responsável:** pesquisa por Supino inclinado com halteres, agachamento, rosca martelo, leg press e panturrilha, inclusive sem acentuação exata.
- **APROVADO pelo responsável:** filtros de grupo muscular, objetivo, com e sem vídeo; cinco itens no filtro com vídeo.
- **APROVADO pelo responsável:** demonstrações de Supino inclinado com halteres, Agachamento livre com barra, Leg Press 45° tradicional, Puxada alta frontal e Rosca direta; reprodução, pausa, reinício e retorno à biblioteca.
- **APROVADO pelo responsável:** criação, reabertura e execução de ficha; parâmetros e IDs legados preservados.
- APK instalado com sucesso no emulador em 30/10/2026. Artefato: `mobile/vero_equilibrafit_app/build/app/outputs/flutter-apk/app-debug.apk`.

## Administração Blazor — bloqueio separado

- O Admin local aponta para `https://veroequlibrafitplus.onrender.com/`.
- Essa API ainda não disponibiliza as rotas `api/v1/admin/catalog/*` nem recebeu a migration/tabelas do catálogo. Por isso o catálogo e o inventário de mídias não podem listar os 200 registros nesse ambiente.
- O cliente Admin passou a tratar respostas vazias ou não JSON sem lançar `JsonException`; ele informa o recurso administrativo indisponível no ambiente conectado.
- Nenhuma migration, deploy ou alteração de produção foi executada nesta correção.
