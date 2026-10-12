# Relatório das Sprints 7 a 9

Data de validação: 12/10/2026.

## Sprint 7 — Coach, dashboard e hábitos

- Adicionado dashboard 360º com estados vazios reais para treinos, alimentação e evolução.
- Adicionadas navegação e telas para Coach, alimentação, hábitos e hidratação.
- Implementado registro local explícito de 250 ml de água e prática de mobilidade com Riverpod.
- O Coach declara a dependência da API interna Gemini e não simula recomendações.

Aceite parcial: a experiência local é navegável e não mostra números fictícios. Persistência Isar, sincronização e consultas autenticadas à API ainda são pendências.

## Sprint 8 — Administração e monetização

- Adaptado o início do painel Blazor para a identidade VeroEqulibraFit+.
- Adicionado health check administrativo em `/health`.
- A tela administrativa deixa explícito que dados operacionais só serão apresentados após a API autenticada estar conectada.

Aceite parcial: o shell administrativo e health check compilam. Papéis, permissões, catálogo, moderação, assinaturas e auditoria ainda precisam da camada de autenticação e endpoints administrativos.

## Sprint 9 — Infraestrutura, homologação e APK

- Mantidos Dockerfiles e `render.yaml` com `autoDeployTrigger: off`; nenhum recurso Neon ou Render foi criado.
- Adicionada CI GitHub Actions para build/testes .NET, Flutter e FastAPI em ambiente limpo.
- Copiados os 166 vídeos autorizados pelo titular para os assets do aplicativo. A origem foi preservada; nomes e três hashes amostrais foram conferidos contra a origem.
- Corrigida a compatibilidade Android do Isar no projeto novo por cópia vendorizada com `namespace` e `compileSdk 36`.
- Gerado e instalado o APK Debug no emulador Android.

## Resultado dos testes

| Verificação | Resultado |
|---|---|
| Flutter analyze | Aprovado, sem problemas |
| Flutter test | Aprovado, 3 testes |
| .NET build | Aprovado, 0 avisos e 0 erros |
| .NET test | Executado sem erro; sem projeto de teste descoberto |
| FastAPI compileall | Aprovado |
| APK Debug | Aprovado, 293.544.809 bytes |
| Instalação Android | Aprovada em `emulator-5554` |
| Pytest/Ruff local | Não executado: arquivo em uso no ambiente virtual |
| Neon/Render/Gemini real | Não executado: credenciais e ambiente isolado ausentes |

## Integridade das origens

Foram feitas somente leituras nos projetos originais e na pasta de vídeos. O Vero mantém as alterações locais já registradas na auditoria e o HEAD `f19e9301aae63da4eb8230531b0da9b73fa8a6ec`. O EquilibraFit++ permanece limpo no HEAD `cc700e969de1bfec84d0dabb338fc94f78cb641b`. Nenhum arquivo de origem foi editado por esta entrega.
