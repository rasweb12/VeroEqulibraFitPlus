from pathlib import Path
import argparse, datetime, shutil, sys
p=Path('lib/features/training/presentation/workout_history_page.dart')
repo_file=Path('lib/features/training/data/workout_session_repository.dart')
parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
if not p.exists() or not repo_file.exists():sys.exit('ERRO: Execute na raiz Flutter (pubspec.yaml).')
r=repo_file.read_text(encoding='utf-8')
repo_old='  Future<void> load() => _loadFuture ??= _loadFromStore();'
repo_new='''  // Uma falha transitoria permite nova leitura sem apagar as sessoes.
  Future<void> load() => _loadFuture ??= _loadRecoverable();

  Future<void> _loadRecoverable() async {
    try {
      await _loadFromStore();
    } catch (_) {
      _loadFuture = null;
      rethrow;
    }
  }'''
s=p.read_text(encoding='utf-8')
marker='// VERO_765D3B_RECOVERY'
if marker in s:sys.exit('Ja aplicado; nenhuma alteracao.')
old='''  String _date(BuildContext context, DateTime value) {'''
new='''  // VERO_765D3B_RECOVERY — estado de leitura e recuperação.
  void _retryLoad() {
    setState(() {
      _load = ref.read(workoutSessionRepositoryProvider).load();
    });
  }

  String _date(BuildContext context, DateTime value) {'''
old2='''          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar o histórico: ${snapshot.error}',
                ),
              ),
            );
          }'''
new2='''          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 44),
                    const SizedBox(height: 12),
                    Text(
                      'Não foi possível carregar o histórico.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Seus registros não foram alterados. Tente novamente.',
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
          }'''
old3='''              if (filtered.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Column(
                      children: [
                        Icon(Icons.event_note_outlined, size: 42),
                        SizedBox(height: 12),
                        Text(
                          'Nenhum treino finalizado neste período.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),'''
new3='''              if (filtered.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 32,
                      horizontal: 20,
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.event_note_outlined, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          sessions.isEmpty
                              ? 'Você ainda não finalizou nenhum treino.'
                              : 'Nenhum treino encontrado neste período.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sessions.isEmpty
                              ? 'Comece uma ficha e finalize uma sessão para acompanhar seus resultados.'
                              : 'Altere o período para consultar suas sessões anteriores.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        if (sessions.isEmpty)
                          FilledButton.icon(
                            onPressed: () => context.go('/training'),
                            icon: const Icon(Icons.fitness_center),
                            label: const Text('Ver meus treinos'),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _periodDays = 0),
                            icon: const Icon(Icons.filter_alt_off_outlined),
                            label: const Text('Ver todo o histórico'),
                          ),
                      ],
                    ),
                  ),
                ),'''
if r.count(repo_old) != 1:
 sys.exit('CHECK FAILED: repositorio alterado; nenhuma mudanca foi feita.')
r=r.replace(repo_old,repo_new)
for a,b in [(old,new),(old2,new2),(old3,new3)]:
 n=s.count(a)
 if n!=1:sys.exit(f'CHECK FAILED: trecho esperado encontrado {n} vez(es); nada foi modificado.')
 s=s.replace(a,b)
if args.check:sys.exit('CHECK OK: atualizacao compativel (nenhum arquivo alterado).')
repo=Path.cwd()
for parent in [repo,*repo.parents]:
 if parent.name.lower()=='veroequlibrafitplus':break
else:sys.exit('ERRO: pasta do repositorio nao identificada; nada alterado.')
backup=parent/'backups'/('backup_765d3b_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
backup.mkdir(parents=True,exist_ok=False)
shutil.copy2(p,backup/p.name)
shutil.copy2(repo_file,backup/repo_file.name)
p.write_text(s,encoding='utf-8')
repo_file.write_text(r,encoding='utf-8')
print(f'Atualizados: {p} e {repo_file}\nBackup: {backup}')
