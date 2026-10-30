# Google Play — beta fechado

## Metadados preparados

| Item | Conteúdo/estado |
| --- | --- |
| Nome do app | `VeroEqulibraFit+` |
| Application ID | `br.com.vero_equilibrafit.vero_equilibrafit_app` |
| Canal inicial | Teste fechado, somente usuários autorizados |
| Artefato | AAB assinado, com `versionCode` maior que o último enviado |
| Ícone Android | Presente em `android/app/src/main/res/mipmap-*`; revisão visual do ativo definitivo pendente |
| API de produção | `https://veroequlibrafitplus.onrender.com` por `API_BASE_URL` no comando de build |
| Privacidade no app | Perfil possui exportação local e fluxo protegido de exclusão de conta |

## Texto base da loja

### Descrição curta

Organize treinos, alimentação, hidratação e evolução corporal no seu ritmo.

### Descrição completa

O VeroEqulibraFit+ reúne sua rotina de treinos, alimentação, hidratação e registros de evolução corporal em um só lugar. Crie fichas, acompanhe exercícios, registre refeições e hábitos e consulte sua evolução ao longo do tempo.

Alguns recursos utilizam inteligência artificial para sugerir organização de treinos e alimentação. As estimativas exigem sua revisão e não substituem orientação médica, nutricional ou profissional.

Use o Perfil para exportar dados locais e solicitar a exclusão da conta pelo fluxo protegido.

## Materiais ainda necessários antes do envio

- [ ] URL pública da política de privacidade, com contato do controlador, dados tratados, finalidade, retenção e processo de exclusão.
- [ ] E-mail ou página pública de suporte.
- [ ] Screenshots reais da build de release: entrada, dashboard, treinos, alimentação, evolução, perfil e um vídeo em reprodução.
- [ ] Revisão visual do ícone definitivo em todos os tamanhos Play Store.
- [ ] Preenchimento da declaração de segurança de dados com base no comportamento real do APK e dos serviços.
- [ ] Classificação indicativa e declaração de permissões: câmera para foto alimentar e scanner; internet para API; sem permissão de galeria declarada.
- [ ] Grupo fechado de testadores e canal para receber falhas.
- [ ] Monitoramento de falhas via Play Console/Android Vitals durante o beta.

## Não declarar no Play Console sem evidência

- Sincronização entre dispositivos, enquanto os testes de push/pull em dois aparelhos não estiverem concluídos.
- Administração Blazor como parte do aplicativo móvel.
- Diagnóstico, tratamento ou aconselhamento clínico.
