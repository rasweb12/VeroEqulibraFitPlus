# Pendências consolidadas

Data: 30/10/2026

## Release e beta Android

- [x] APK novo do catálogo instalado no emulador sem remover dados; homologação móvel registrada abaixo.
- [x] Permissão de internet incluída no manifesto principal para builds de release.
- [x] Configuração de assinatura de release preparada com `android/key.properties` fora do Git.
- [ ] Criar ou recuperar o keystore de publicação e preencher `android/key.properties` localmente.
- [ ] Gerar e testar o AAB assinado com novo `versionCode`; roteiro em `docs/RELEASE_BETA_ANDROID.md`.
- [ ] Validar em Android físico os fluxos de conta, sincronização, foto alimentar, scanner e notificações antes do beta fechado.

## Catálogo e vídeos

- [ ] Validar manualmente os cinco vídeos já associados no Android.
- [ ] Validar associações dos demais 161 arquivos MP4; nenhum foi associado apenas por semelhança de nome.
- [ ] Definir equipamentos, instruções e dicas de segurança quando houver fonte técnica autorizada. Esses campos não foram inventados.

## Administração

- [ ] Publicar a API e a migration do catálogo somente no ambiente isolado de homologação, para habilitar o inventário de mídias no Blazor Admin.
- [ ] Homologar Exercícios e Mídias no Admin com os endpoints publicados no ambiente de homologação.

## Segurança e MVP

- [ ] Rotacionar e revogar a chave interna exposta antes do beta público.
- [ ] Validar foto alimentar, revisão manual da estimativa Gemini e scanner EAN/UPC no Android físico.
- [ ] Concluir a homologação da sincronização Neon entre dois dispositivos, incluindo offline, conflitos e isolamento por usuário.
- [ ] Validar notificações configuráveis de hidratação e treino.
- [ ] Executar testes ponta a ponta, acessibilidade, desempenho e empacotamento antes da liberação do MVP.

## Promoção Neon

- [x] Prévia validada e quatro migrations de sincronização aplicadas em produção. Não inclui a migration administrativa do catálogo.
- [x] Snapshot de rollback criado antes da janela de produção.
- [x] Health checks da API de produção responderam HTTP 200 após a migration.
- [ ] Validar push/pull de sincronização com dois dispositivos na API de produção.
- [ ] Procedimento completo: `docs/NEON_PROMOCAO_PRODUCAO.md`.

## Já validado nesta etapa

- [x] Catálogo versionado com 200 registros e IDs únicos de 1 a 200.
- [x] Compatibilidade de dez IDs legados no repositório de treino.
- [x] lutter analyze sem problemas.
- [x] lutter test --no-pub: 44 aprovados e 4 ignorados por dependência de API de teste.
- [x] 166 vídeos originais preservados.

## Atualização de 30/10/2026 — homologação manual

- [x] APK novo instalado no emulador sem remover dados.
- [x] Catálogo móvel: 200 exercícios, pesquisas e filtros homologados.
- [x] Cinco demonstrações de vídeo homologadas no Android.
- [x] Fichas com exercício oficial, parâmetros, execução, histórico e IDs legados homologadas.
- [x] Cliente Blazor protegido contra resposta HTTP vazia/não JSON ao salvar ou carregar catálogo e mídias.
- [ ] O Admin continua bloqueado até que a API com `AdminCatalogController` e a migration `20261026000407_AddAdminExerciseCatalog` sejam publicadas em homologação e recebam a carga oficial dos 200 registros. A API de produção conectada pelo Admin local ainda não contém esses recursos.
