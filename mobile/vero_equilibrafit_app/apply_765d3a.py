from pathlib import Path
from datetime import datetime
import argparse
import shutil
import sys

p = Path('lib/features/training/presentation/workout_session_page.dart')
parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
a = parser.parse_args()
if not p.is_file():
    sys.exit('ERRO: execute na raiz Flutter (pubspec.yaml).')
s = p.read_text(encoding='utf-8')
mark = '// Vero 7.6.5D.3A - recuperacao de abertura'
if mark in s:
    print('Ja aplicado. Nenhuma alteracao.'); sys.exit(0)
old1 = '''  Future<void> _initialize() async {
    try {
      final training = ref.read(trainingRepositoryProvider);'''
new1 = '''  // Vero 7.6.5D.3A - recuperacao de abertura
  Future<void> _retryOpen() async {
    if (_session != null || _busy) return;
    // A tentativa anterior pode ter deixado um Future de load com erro
    // em cache. Recrear os repositories somente antes de abrir a sessao.
    ref.invalidate(trainingRepositoryProvider);
    ref.invalidate(workoutSessionRepositoryProvider);
    await _initialize();
  }

  Future<void> _initialize() async {
    if (!mounted || _session != null || _busy) return;
    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final training = ref.read(trainingRepositoryProvider);'''
old2 = '''    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  void _initializeDrafts'''
new2 = '''    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _initializeDrafts'''
old3 = '''        body: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )'''
new3 = '''        body: _error != null
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 42),
                      const SizedBox(height: 12),
                      Text(
                        'Nao foi possivel abrir o treino',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _busy ? null : _retryOpen,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tentar novamente'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _busy ? null : () => context.go('/training'),
                        child: const Text('Voltar aos treinos'),
                      ),
                    ],
                  ),
                ),
              )'''
for old in [old1,old2,old3]:
    if s.count(old)!=1:
        sys.exit('CHECK FALHOU: estrutura local difere do codigo esperado. Nenhum arquivo alterado. Trecho: '+old[:45])
if a.check:
    print('CHECK OK: tres pontos encontrados. Nenhum arquivo alterado.');sys.exit(0)
s2=s.replace(old1,new1).replace(old2,new2).replace(old3,new3)
root=Path.cwd()
if not (root/'pubspec.yaml').exists():
    sys.exit('ERRO: nao esta na raiz do Flutter. Nenhum arquivo alterado.')
backup=root.parents[1]/'backups'/('backup_765d3a_'+datetime.now().strftime('%Y%m%d_%H%M%S'))
backup.mkdir(parents=True,exist_ok=False)
shutil.copy2(p,backup/p.name)
p.write_text(s2,encoding='utf-8')
print('APLICADO: '+str(p))
print('Backup: '+str(backup/p.name))
