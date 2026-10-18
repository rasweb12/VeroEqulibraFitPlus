# Homologação manual — 18/10/2026

**Responsável pelo aceite:** usuário responsável pelo projeto  
**Ambiente:** APK Android configurado com a API pública e serviços Render/Neon isolado  
**Método:** validação funcional manual comunicada no histórico desta tarefa. Nenhum segredo, token ou dado pessoal foi registrado neste documento.

## Fluxos aprovados

| ID | Fluxo | Estado | Evidência de aceite |
| --- | --- | --- | --- |
| HML-01 | Login, cadastro e recuperação de senha por Brevo | APROVADO | Fluxo executado e aprovado pelo responsável. |
| HML-02 | AuthGate e bloqueio de rotas privadas após logout | APROVADO | Fluxo executado e aprovado pelo responsável. |
| HML-03 | Coach Gemini autenticado | APROVADO | Resposta real do Coach validada no aplicativo e aprovada pelo responsável. |
| HML-04 | Foto de refeição, revisão antes do salvamento | APROVADO | Fluxo de captura/análise/revisão validado e aprovado pelo responsável. |
| HML-05 | Scanner de código de barras e cadastro manual | APROVADO | Scanner e alternativa de cadastro manual validados e aprovados pelo responsável. |
| HML-06 | Alimentação, metas e relatórios | APROVADO | Fluxos de diário alimentar, metas e relatórios validados e aprovados pelo responsável. |
| HML-07 | Treinos, hábitos, medidas e missões | APROVADO | Fluxos validados e aprovados pelo responsável. |
| HML-08 | Sincronização no Neon isolado | APROVADO | Fluxo validado no ambiente Neon isolado autorizado e aprovado pelo responsável. |

## Limites do aceite

Este aceite não comprova, por si só, cenários que não foram declarados como executados: validação simultânea com dois dispositivos/emuladores independentes, sincronização remota de todos os submódulos de hábitos/anotações/missões, ou operação administrativa completa no Blazor.

O painel administrativo Blazor, histórico/recompensas persistidos de missões e os demais itens marcados como pendentes na matriz P3 continuam com o estado técnico indicado em seus documentos. Portanto, este registro aprova os oito fluxos acima e não altera automaticamente o aceite integral do MVP.
