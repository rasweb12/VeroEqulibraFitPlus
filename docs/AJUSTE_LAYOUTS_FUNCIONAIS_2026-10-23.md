# Ajuste de funcionalidades — layouts importados (23/10/2026)

Estado: **PARCIAL — pronto para homologação manual visual.**

Os layouts importados para Coach, Perfil, Hábitos e Evolução corporal foram preservados em `backups/imported_layouts_20261023/`. Eles continham dados fixos e callbacks vazios e não podiam operar com as rotas atuais. Foram restaurados os controladores, repositórios e rotas funcionais das cópias de segurança, mantendo a paleta e os componentes Vero já existentes.

- Coach: consulta real à API autenticada Gemini, estados de envio e erro, contador de caracteres e sugestões rápidas que preenchem o campo; sem telemetria ou insight fictício.
- Perfil: sessão autenticada, peso, meta nutricional e hidratação reais; metas, privacidade, exportação local, exclusão de conta e logout preservados.
- Hábitos: hidratação persistida, meta, mobilidade, atividade, anotação e missões preservadas.
- Evolução: cadastro, edição, exclusão e histórico de medidas preservados.

`flutter analyze --no-pub`: aprovado. `flutter test --no-pub --dart-define=API_BASE_URL=https://example.test`: 33 testes aprovados. Os testes não comprovam integração externa Gemini, persistência remota ou fidelidade visual em Android.
