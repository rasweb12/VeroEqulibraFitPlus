# Testes e validação

Executados com êxito: `flutter analyze`, dois testes Flutter para exclusão lógica/recuperação e busca por alias sem acento, `py -3.9 -m compileall -q app` e `dotnet build VeroEqulibraFit.slnx` sem avisos. A tentativa de `flutter build apk --debug` não produziu artefato dentro da janela disponível do Gradle e permanece pendente. Pytest/Ruff estão bloqueados por arquivo em uso no ambiente virtual local; testes REST autenticados, banco Neon e integração real ainda não foram executados.
