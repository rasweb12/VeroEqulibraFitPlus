# Sprint 7.7.3F.1 — Evolução Corporal

## Diagnóstico

O repositório confirmava a interface antes da escrita protegida terminar: as
operações eram disparadas sem `await`. A lista era apresentada por
`reversed`, que dependia da ordem de inserção, e não da data medida. Assim,
um cadastro retroativo podia alterar o peso atual, a variação e o histórico.

## Correções

- Criação, edição e exclusão agora retornam `Future`, persistem antes de
  atualizar o estado e mantêm o estado confirmado se a escrita falhar.
- O controlador serializa gravações consecutivas para evitar corrida entre
  operações.
- Registros são ordenados por `recordedAt`, com o ID como desempate estável.
- Seletores compartilhados calculam peso atual e variação somente com pesos
  válidos. Perfil, Dashboard e relatório nutricional usam esses seletores.
- O modal preservado permite selecionar a data da medição; a data atual é o
  padrão, datas anteriores são permitidas e futuras são bloqueadas.
- Peso e perímetros aceitam vírgula ou ponto, rejeitam valores inválidos,
  negativos e zero, e exigem ao menos uma medida ou observação.
- O gráfico é um `CustomPainter`, sem dependência nova. Ele usa apenas pesos
  persistidos, mostra datas reais, lida com nenhum/um/múltiplos pontos e não
  inventa medições intermediárias.

## Compatibilidade e rollback

O formato JSON mantém os mesmos campos (`id`, `recordedAt`, `weightKg`,
`waistCm`, `chestCm`, `hipCm`, `notes`). A data é gravada em UTC e restaurada
em horário local. Nenhum registro foi migrado ou apagado.

Backup anterior às alterações:
`backups/vero_773f1_measurements_20261024_221500`.

Para rollback, restaure os quatro arquivos desse backup e remova o seletor e
os testes adicionados; os dados armazenados permanecem compatíveis.

## Evidências automatizadas

- `flutter analyze`: sem problemas.
- `flutter test`: 36 testes aprovados; 1 teste de integração de renovação de
  autenticação ficou pulado por não receber `API_BASE_URL` de teste.
- Cobertos: ordenação, desempate na mesma data, peso sem medida válida,
  edição com ID/data preservados, restauração, falha de armazenamento e
  cancelamento/salvamento repetido dos modais.

## Pendências de homologação Android

Validar no APK desta sprint: cadastro retroativo, limpeza de campo durante
edição, exclusão, retorno após reinício, gráfico vazio/um ponto/vários pontos
e peso correspondente no Perfil. A persistência é local protegida; esta tela
não apresenta sincronização Neon.
