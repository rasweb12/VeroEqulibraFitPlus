# P3 — Matriz de aceite inicial

Data: 18/10/2026  
Estado geral: **PARCIAL — MVP permanece REPROVADO / NÃO HOMOLOGADO**

| Módulo | Estado | Evidência atual | Próximo passo |
|---|---|---|---|
| Diário alimentar | PARCIAL | Registros locais cifrados, edição, data, porção e macros; plano remoto recuperável/editável | Agrupar por data/refeição e persistir itens alimentares estruturados |
| Gemini por texto | PARCIAL | Flutter → API autenticada → FastAPI/Gemini implementado; revisão manual antes de salvar | Teste real autorizado e catálogo nutricional como fonte de correspondência |
| Gemini Vision | PARCIAL | Foto/câmera, validação, revisão por item e salvamento local | Teste real autorizado, persistência de itens e recuperação Neon |
| Plano alimentar | PARCIAL | Gerar, aprovar, listar e atualizar por API autenticada | Edição estruturada de refeições e teste Neon real |
| Catálogo de alimentos | AUSENTE | Nenhuma entidade/catálogo nutricional canônico identificada | Modelar catálogo, aliases, nutrientes, porções e fontes licenciadas |
| Código de barras | AUSENTE | Nenhum leitor/contrato identificado | Avaliar pacote e fonte de produtos autorizada |
| Metas, fibras e relatórios | AUSENTE | Macros por refeição existentes | Metas versionadas, cálculo transparente e gráficos de dados persistidos |
| Hidratação, atividades e notas | PARCIAL | Hidratação/mobilidade locais identificadas | Entidades, API, outbox e histórico por data |
| Gamificação | AUSENTE | Nenhum domínio persistente identificado | Missões opt-in e regras não punitivas |
| Perfil/preferências | PARCIAL | Perfil, logout e aviso de saúde existentes | Preferências, privacidade, exportação e configurações funcionais |
| Administração Blazor | REPROVADO | Shell sem autenticação/roles operacionais comprovados | Criar API administrativa protegida e autenticação real |
| SMTP | PARCIAL | Tokens Identity, links de uso único, rate limit e SMTP configurável | Teste ponta a ponta com caixa de e-mail autorizada e domínio/provedor válido |
| Sincronização | PARCIAL | Outbox cifrada para fichas/refeições/exercícios; migrations em Neon isolado | Módulos restantes, conflito manual e API de homologação isolada |

## Regras mantidas

- Google Gemini é o único provedor de IA.
- Nenhuma sugestão de IA é salva sem revisão do usuário.
- Nenhum dado nutricional desconhecido receberá valor inventado.
- A aprovação exige persistência, recuperação, autorização e evidência de teste.
# Atualização de 18/10/2026

| Módulo | Estado | Evidência | Limitação |
|---|---|---|---|
| P3.6 Missões diárias | PARCIAL | `features/habits/presentation/missions_page.dart` | Sem histórico, pontos, medalhas ou sincronização remota. |
| P3.7 Perfil | PARCIAL | `features/profile/presentation/profile_page.dart` | Preferências e ações sensíveis ainda não homologadas. |
| P3.8 Administração | REPROVADO | `admin/.../Components/Pages/Home.razor` | Painel ainda é um shell sem autenticação e operações reais. |
