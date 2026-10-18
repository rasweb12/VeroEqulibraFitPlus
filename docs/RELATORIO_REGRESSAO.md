# Relatório de regressão

A regressão de rotas privadas e dados por conta permanece pendente de testes automatizados e de integração. Não há aprovação de MVP.

## Correções locais — 17/10/2026

- **REG-EXERCISE-001 (P1):** a abertura imediata do diálogo de configuração após fechar a folha de demonstração podia desmontar dependências herdadas durante a transição. A rota agora aguarda a desmontagem da folha antes de abrir o diálogo. Estado: corrigido localmente; requer reteste no emulador.
- **REG-NUTRITION-001 (P1):** o gerador de planos descartava a resposta HTTP específica e podia deixar uma proposta anterior visível junto de uma mensagem genérica de falha. A tela passou a validar JSON antes de expor a proposta e exibe a mensagem de erro do servidor quando disponível. Estado: corrigido localmente.
- **REG-NUTRITION-002 (P1):** o registro manual não solicitava estimativa nutricional. Foi adicionado o caminho autenticado Flutter → API .NET → FastAPI → Gemini para estimar texto, com campos editáveis de calorias e macros antes da gravação local. Estado: compilado localmente; depende de deploy e validação integrada.
- **REG-VIDEO-001 (P1):** os cinco assets associados existem no projeto e o arquivo de supino inclinado está presente. A reprodução falhou no emulador informado. Codec/duração/resolução ainda não foram identificados porque `ffprobe`/`ffmpeg` não estão disponíveis neste ambiente. Estado: pendente de diagnóstico de codec ou transcodificação autorizada; não aprovado.
- **REG-ADMIN-001 (P1):** o painel Blazor atual continua um shell sem autenticação administrativa nem operações. Estado: parcial/reprovado; não foi declarado concluído.
- **REG-SMTP-001 (P0):** confirmação e recuperação dependem da entrega do SMTP/Resend. Há configuração e código, mas não existe evidência de recebimento, consumo do link e login com a nova senha. Estado: bloqueado para homologação ponta a ponta.

Evidência executada: `dotnet build backend/VeroEqulibraFit.Api/VeroEqulibraFit.Api.csproj --no-restore -m:1 -v:minimal` passou com 0 avisos/0 erros; análise Dart direcionada passou sem problemas; 8 testes Flutter locais passaram. Nenhuma dessas evidências substitui a homologação com Render/Gemini/SMTP.

APK debug recompilado em 17/10/2026 às 17:51 BRT com SHA-256 `77C1C3D3F627304FC8129D8E65EF016FCED60D2B3E7CE636EF18C6DB3B57A816` e instalado com êxito em `emulator-5554`. A inspeção do APK confirmou que os vídeos são empacotados sob `assets/flutter_assets/assets/videos/`; a reprodução no emulador ainda requer reteste após a instalação e diagnóstico de codec se falhar novamente.

## Regressão local — 18/10/2026

| Verificação | Resultado | Evidência |
| --- | --- | --- |
| Blazor Admin | APROVADO localmente | `dotnet build admin/VeroEqulibraFit.Admin/VeroEqulibraFit.Admin.csproj --no-restore -m:1 -v:minimal`: 0 avisos e 0 erros. |
| API .NET | APROVADO localmente | `dotnet test tests/VeroEqulibraFit.Api.Tests/VeroEqulibraFit.Api.Tests.csproj --no-restore -m:1 -v:minimal`: 9/9 testes aprovados. |
| Flutter | APROVADO localmente | `flutter test`: 16/16 testes aprovados. Inclui isolamento por conta, outbox cifrada, tombstones, refeição e scanner. |
| FastAPI/Gemini | APROVADO localmente | Ambiente virtual recriado a partir de `pyproject.toml`; `pytest -q`: 9/9 aprovados; `ruff check .`: sem achados. Há um aviso externo de depreciação do Starlette/AnyIO. |
| Login administrativo integrado | NÃO TESTADO | Requer uma conta com papel `Administrator` no ambiente isolado e teste contra a API publicada. |
| Dois dispositivos independentes | NÃO TESTADO | Roteiro em `docs/TESTE_DOIS_DISPOSITIVOS.md`; não foi executado nesta estação. |
| Fotos de evolução | REPROVADO | Não há armazenamento de imagem com consentimento, retenção, exclusão e criptografia adequados. Não foi implementado um atalho inseguro. |

O ambiente Python anterior apresentava binário incompatível do `pydantic_core`; foi preservado como ambiente local ignorado e substituído por `.venv` recriado. Isso não alterou código nem serviços remotos.
