# Pendências consolidadas

Data: 30/10/2026

## Bloqueio imediato

- [ ] **APK do catálogo:** a compilação Android não concluiu neste executor. O APK disponível em uild/app/outputs/flutter-apk/app-debug.apk é de 28/10/2026 e não foi instalado como versão nova.
- [ ] **Homologação Android do catálogo:** executar os 12 cenários de HOMOLOGACAO_CATALOGO_200_EXERCICIOS.md após gerar o APK novo.

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

## Já validado nesta etapa

- [x] Catálogo versionado com 200 registros e IDs únicos de 1 a 200.
- [x] Compatibilidade de dez IDs legados no repositório de treino.
- [x] lutter analyze sem problemas.
- [x] lutter test --no-pub: 44 aprovados e 4 ignorados por dependência de API de teste.
- [x] 166 vídeos originais preservados.
