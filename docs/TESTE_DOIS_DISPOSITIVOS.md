# Roteiro de validação em dois dispositivos

1. Instale o mesmo APK configurado com `API_BASE_URL` em dois emuladores ou aparelhos independentes.
2. Entre com a conta A no primeiro e com a conta B no segundo. Confirme que nenhuma ficha, refeição, hábito ou medida aparece cruzada.
3. Entre com a mesma conta A nos dois dispositivos. Crie uma ficha e uma refeição no primeiro, sincronize e recarregue o segundo.
4. Edite o mesmo registro nos dois dispositivos antes de sincronizar. Confirme que o conflito é exibido ou retornado como conflito, sem perda silenciosa.
5. Exclua uma ficha no primeiro, sincronize e confirme que o tombstone é aplicado no segundo sem apagar sessões históricas.
6. Registre hidratação, atividade, nota e missão; estes submódulos só podem ser aprovados quando a sincronização remota deles estiver implementada e demonstrada.

**Estado atual:** NÃO TESTADO. Este roteiro não é evidência de execução.
