# VeroEqulibraFit+ 7.7.1C - instalador transacional
from pathlib import Path
from datetime import datetime
import sys, shutil, re
root=Path.cwd()
app=root/'lib/app.dart'
repo=root/'lib/features/training/data/training_repository.dart'
if not (root/'pubspec.yaml').exists() or not app.is_file() or not repo.is_file():
    sys.exit('ERRO: execute na raiz Flutter, com pubspec.yaml. Nada alterado.')
a=app.read_text(encoding='utf-8'); b=repo.read_text(encoding='utf-8')
def sub(text, old, new, label):
    n=text.count(old)
    if n!=1: raise ValueError(f'{label}: esperado 1 bloco, encontrado {n}. Nenhuma alteracao aplicada.')
    return text.replace(old,new,1)
try:
    b=sub(b, '''  void deleteCustom(String id) {
    final index = _customExercises.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _customExercises.removeAt(index);
    unawaited(_save());
    unawaited(_enqueueCustomDelete(id));
  }
''', '''  bool isCustomExerciseInUse(String id) => _plans.any(
    (plan) => !plan.isDeleted &&
        plan.exercises.any((entry) => entry.exerciseId == id),
  );

  bool deleteCustom(String id) {
    final index = _customExercises.indexWhere((item) => item.id == id);
    if (index < 0 || isCustomExerciseInUse(id)) return false;
    _customExercises.removeAt(index);
    unawaited(_save());
    unawaited(_enqueueCustomDelete(id));
    return true;
  }
''','protecao de exclusao')
    a=sub(a, '''                              onPressed: () {
                                ref
                                    .read(trainingRepositoryProvider)
                                    .deleteCustom(exercise.id);
                                ref
                                    .read(catalogRevisionProvider.notifier)
                                    .state++;
                              },''', '''                              onPressed: () async {
                                final repository = ref.read(trainingRepositoryProvider);
                                if (repository.isCustomExerciseInUse(exercise.id)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Este exercício está em uma ficha. Remova-o da ficha antes de excluir.')),
                                  );
                                  return;
                                }
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Excluir exercício?'),
                                    content: Text('Excluir "${exercise.name}"? Esta ação não pode ser desfeita.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
                                      FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Excluir')),
                                    ],
                                  ),
                                );
                                if (confirmed != true || !context.mounted) return;
                                final removed = repository.deleteCustom(exercise.id);
                                if (removed) {
                                  ref.read(catalogRevisionProvider.notifier).state++;
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Não foi possível excluir: exercício utilizado ou indisponível.')),
                                  );
                                }
                              },''','confirmacao de exclusao')
    a=sub(a,'''      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: TextField(
              key: ValueKey(ref.watch(exerciseSearchResetProvider)),''','''      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.fitness_center_rounded, color: Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Explore exercícios', style: Theme.of(context).textTheme.titleMedium),
                        const Text('Encontre movimentos e monte sua ficha.'),
                      ],
                    )),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              key: ValueKey(ref.watch(exerciseSearchResetProvider)),''','cabecalho visual')
    a=sub(a,'''                  return Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: ListTile(''','''                  return Card(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: ListTile(''','cards modernos')
    # Localiza o bloco do subtitulo independentemente de formatacao/indentacao.
    header=a.find('class ExerciseLibraryPage')
    item=a.find('itemBuilder: (_, index)', header)
    if header < 0 or item < 0:
        raise ValueError('biblioteca nao localizada; nenhum arquivo alterado')
    import re
    segment=a[item:a.find('onTap:',item)]
    match=re.search(r'(?m)^(\s*)subtitle:\s*Padding\(.*?(?=^\s*trailing:\s*Row\()',segment,re.S|re.M)
    if not match:
        raise ValueError('bloco da legenda do card nao localizado')
    old=match.group(0)
    if 'exercise.primaryMuscle' not in old or 'exercise.equipment' not in old:
        raise ValueError('estrutura da legenda nao reconhecida')
    pad=match.group(1)
    new="""subtitle: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${exercise.primaryMuscle} · ${exercise.equipment}'),
          if (exercise.isCustom || exercise.demoVideoAsset != null)
            Text(
              exercise.isCustom ? 'Personalizado' : 'Demonstração disponível',
              style: Theme.of(context).textTheme.labelSmall,
            ),
        ],
      ),
    ),
"""
    new='\n'.join(pad+line if line else line for line in new.split('\n'))
    a=a[:item]+segment[:match.start()]+new+segment[match.end():]+a[item+len(segment):]
    a=sub(a,'''              floatingActionButton: FloatingActionButton.extended(''','''              floatingActionButton: FloatingActionButton.extended(''','marcador neutro') if False else a
except ValueError as e:
    sys.exit('CHECK FALHOU: '+str(e))
print('CHECK OK: alteracoes localizadas e seguras; 2 arquivos Dart.')
if '--check' in sys.argv: sys.exit(0)
# Caminho de backups na raiz do repositorio: mobile/vero_app -> ../../backups
backup=root.parent.parent/'backups'/('vero_771c_'+datetime.now().strftime('%Y%m%d_%H%M%S'))
backup.mkdir(parents=True,exist_ok=False)
for p in (app,repo):
    dest=backup/p.relative_to(root)
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(p,dest)
try:
    app.write_text(a,encoding='utf-8')
    repo.write_text(b,encoding='utf-8')
except Exception:
    for p in (app,repo):
        copy=backup/p.relative_to(root)
        if copy.exists(): shutil.copy2(copy,p)
    raise
print('APLICADO. Backup externo:',backup)
print('Execute dart format lib/app.dart lib/features/training/data/training_repository.dart')
