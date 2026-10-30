# Sprint 7.8.0 — Release Android, beta e Neon produção

Data: 30/10/2026.

## Neon

**CORRIGIDO/VALIDADO**

- Produção foi comparada com a branch `homologation-sync-20261018`.
- As quatro migrations de sincronização ausentes foram aplicadas de forma incremental após prévia em branch temporária e aprovação explícita.
- A prévia e a produção confirmaram 3 tabelas novas, 4 colunas novas e 4 registros de migration.
- O schema de produção e de homologação ficou sem diferença.
- A API de produção respondeu HTTP 200 em `/health/live` e `/health/ready`.
- Snapshot de rollback: `pre-sync-production-20261030` (`snap-polished-dew-b68esjkf`), válido até 13/11/2026 às 23:59:59 UTC.

**NÃO INCLUÍDO**

- `20261026000407_AddAdminExerciseCatalog` não foi aplicada. O catálogo do Blazor Admin continua fora desta promoção.
- Não houve deploy de serviços Render nesta sprint.

## Android

**CORRIGIDO**

- `android.permission.INTERNET` foi transferida para o manifesto principal; a release terá acesso à API.
- A variante `release` deixou de aceitar a chave de debug e exige `android/key.properties` com uma assinatura própria.
- Keystore, `key.properties` e extensões usuais de chave foram excluídos do Git.
- `applicationId`: `br.com.vero_equilibrafit.vero_equilibrafit_app`.
- `compileSdk` e `targetSdk`: 36, conforme Flutter SDK instalado; atende à política Google Play vigente para novos envios em agosto de 2026.
- Não foram localizadas chaves de backend no código Flutter rastreado. A URL da API é fornecida em build por `API_BASE_URL`.

**PENDENTE/BLOQUEADO**

- Não há `key.properties` nem keystore de publicação local. Por isso não foi gerado APK release nem AAB assinado.
- A verificação de tarefas Gradle não concluiu por contenção de dois daemons locais. Nenhum processo foi encerrado automaticamente.
- O teste em dispositivo físico da release, o beta fechado e o envio ao Google Play aguardam artefato assinado.
- Política de privacidade pública, suporte público, screenshots reais e declaração de segurança de dados ainda precisam ser fornecidos/preenchidos.
- A rotação da chave interna continua requisito para beta público.
- Push/pull de sincronização em dois dispositivos contra a produção ainda precisa de homologação manual.

## Artefatos e documentação

- [Release Android](RELEASE_BETA_ANDROID.md)
- [Checklist Google Play](GOOGLE_PLAY_BETA_CHECKLIST.md)
- [Promoção Neon](NEON_PROMOCAO_PRODUCAO.md)
- Backup local: `backups/release_beta_preparation_20261030_125942`.

## Rollback

- Neon: restaurar a partir do snapshot registrado somente se uma falha comprovada exigir reversão do schema/dados.
- Android: interromper o canal beta e gerar uma nova versão com `versionCode` superior após corrigir a causa; não reutilizar código de versão.
