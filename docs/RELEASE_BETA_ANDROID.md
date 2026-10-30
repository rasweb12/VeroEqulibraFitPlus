# Release Android Beta

## Estado preparado

- O manifesto principal declara `android.permission.INTERNET`; a permissão agora existe também no APK/AAB de release, necessário para autenticação, sincronização, Coach e alimentação.
- Uma build de release exige assinatura própria. O Gradle não usa mais a chave de debug para `release`.
- `android/key.properties` e arquivos `.jks`/`.keystore` são ignorados pelo Git.
- `android/key.properties.example` é somente um modelo e não pode receber credenciais reais.
- O projeto usa `compileSdk` e `targetSdk` 36 pelo Flutter SDK atual. Em 30/10/2026, esse nível atende ao requisito de API 36 para novos envios e atualizações ao Google Play em agosto de 2026.

## Preparar a assinatura local

1. Gere ou recupere o keystore de publicação sob controle do proprietário. Guarde a cópia fora do repositório e em cofre apropriado.
2. Copie `mobile/vero_equilibrafit_app/android/key.properties.example` para `mobile/vero_equilibrafit_app/android/key.properties`.
3. Preencha o caminho relativo ao diretório `android` e as credenciais reais. Não envie esse arquivo ou o keystore ao Git.

## Gerar o AAB de beta

No diretório `mobile/vero_equilibrafit_app`, depois de configurar a assinatura e a URL de API aprovada:

```powershell
flutter analyze
flutter test --no-pub
flutter build appbundle --release --build-name=1.0.0 --build-number=2 --dart-define="API_BASE_URL=https://veroequlibrafitplus.onrender.com"
```

O artefato esperado é `build/app/outputs/bundle/release/app-release.aab`.

## Antes de enviar ao beta fechado

- Confirmar que `build-number` é maior que o publicado anteriormente.
- Executar o APK/AAB assinado em Android físico sem limpar os dados.
- Validar login, recuperação de senha, sincronização, Coach, proposta alimentar, foto alimentar, scanner e notificações.
- Confirmar a chave interna rotacionada e revogada antes de abrir o beta público.
- Confirmar os testes de sincronização com a API de produção após a promoção Neon registrada em `docs/NEON_PROMOCAO_PRODUCAO.md`.

## Rollback Android

- Não publique uma substituição com `versionCode` repetido.
- Se houver falha no beta fechado, interrompa a distribuição na Play Console e publique um novo build com `versionCode` superior depois da correção.
