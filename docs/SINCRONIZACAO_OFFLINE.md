# Sincronização offline

Isar guarda a coleção `PendingOperation`, isolada por `ownerId` e chave de idempotência, para representar operações pendentes. O servidor possui a tabela correspondente. Falta ligar a fila às ações da UI, cifrar o banco local, executar conflitos por versão e sincronizar contra a API autenticada.
