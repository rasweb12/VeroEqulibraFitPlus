from pathlib import Path
import shutil, sys, datetime

root = Path.cwd()
path = root / 'lib/features/training/presentation/training_progress_page.dart'
if not (root/'pubspec.yaml').exists() or not path.exists():
    sys.exit('ERRO: execute na raiz Flutter, ao lado de pubspec.yaml.')
s = path.read_text(encoding='utf-8')
if 'VERO_765D3C_RECOVERY' in s:
    print('Already patched; no changes made.')
    sys.exit(0)
repls = [
('  late final Future<void> _load;', '  Future<void>? _load;'),
('    _load = ref.read(workoutSessionRepositoryProvider).load();\n  }\n\n  String _number', '''    _load = ref.read(workoutSessionRepositoryProvider).load();
  }

  // VERO_765D3C_RECOVERY: tenta novamente, sem alterar sessoes existentes.
  void _retryLoad() {
    setState(() {
      _load = ref.read(workoutSessionRepositoryProvider).load();
    });
  }

  String _number'''),
('''          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar a evolução: ${snapshot.error}',
                ),
              ),
            );
          }''', '''          if (snapshot.hasError) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 44),
                    const SizedBox(height: 12),
                    Text('Não foi possível carregar a evolução',
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text(
                      'Os dados não foram apagados. Tente novamente para recuperar seus indicadores.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _retryLoad,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/training'),
                      child: const Text('Voltar aos treinos'),
                    ),
                  ],
                ),
              ),
            );
          }'''),
('''              if (data.sessions == 0)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.show_chart_outlined, size: 40),
                        SizedBox(height: 12),
                        Text(
                          'Nenhum treino concluído neste período. Finalize uma sessão para acompanhar sua evolução.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )''', '''              if (data.sessions == 0)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const Icon(Icons.show_chart_outlined, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          sessions.isEmpty
                              ? 'Você ainda não concluiu nenhum treino. Finalize uma sessão para acompanhar sua evolução.'
                              : 'Não existem treinos concluídos no período selecionado.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        if (sessions.isEmpty)
                          FilledButton.icon(
                            onPressed: () => context.go('/training'),
                            icon: const Icon(Icons.fitness_center),
                            label: const Text('Ver meus treinos'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => setState(() {
                              _days = 0;
                              _exerciseId = null;
                            }),
                            icon: const Icon(Icons.filter_alt_off_outlined),
                            label: const Text('Ver todo o período'),
                          ),
                      ],
                    ),
                  ),
                )''')
]
new=s
for old,replacement in repls:
    if new.count(old)!=1:
        sys.exit('INCOMPATIVEL: trecho nao encontrado exatamente uma vez:\n'+old[:160]+'\nNenhuma alteracao realizada.')
    new=new.replace(old,replacement,1)
if '--check' in sys.argv:
    print('CHECK OK: arquivo compatível; nenhuma alteração realizada.')
    sys.exit(0)
# ascend mobile/vero... to project root, with backup outside Flutter
repo_root = root.parent.parent
backup=repo_root/'backups'/('backup_765d3c_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
backup.mkdir(parents=True,exist_ok=False)
shutil.copy2(path,backup/path.name)
path.write_text(new,encoding='utf-8')
print('PATCH OK:',path)
print('BACKUP:',backup/path.name)
