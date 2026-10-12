# Testes e validação

Validação final aprovada em 12/10/2026: `flutter analyze` sem problemas; `flutter test` com 3 testes aprovados (exclusão lógica/recuperação, busca por alias sem acento e hidratação explícita); `dotnet build VeroEqulibraFit.slnx --no-restore` sem avisos; e `py -3.9 -m compileall -q app` aprovado. `dotnet test` foi executado sem erro, mas a solução ainda não contém projeto de testes .NET descoberto pelo runner.

O APK Debug foi gerado em `mobile/vero_equilibrafit_app/build/app/outputs/flutter-apk/app-debug.apk` (293.544.809 bytes), instalado com sucesso e iniciado no emulador `emulator-5554`, pacote `br.com.vero_equilibrafit.vero_equilibrafit_app`. O tamanho inclui 166 vídeos autorizados. A primeira falha de build identificou incompatibilidade do `isar_flutter_libs` com AGP 9; a cópia vendorizada em `third_party/isar_flutter_libs` recebeu somente `namespace` e `compileSdk 36`, sem alterar o cache global.

Pytest/Ruff locais continuam bloqueados por arquivo em uso no ambiente virtual; a GitHub Actions executará ambos em ambiente limpo. Testes REST autenticados, banco Neon, Render e integração Gemini real não foram executados porque não há credenciais/ambientes isolados autorizados.
