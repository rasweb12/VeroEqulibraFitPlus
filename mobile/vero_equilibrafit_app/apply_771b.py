from pathlib import Path
import sys, shutil, datetime
root=Path.cwd()
a=root/'lib/app.dart'; p=root/'lib/features/training/presentation/training_providers.dart'
f=root/'lib/features/training/domain/exercise_catalog_filter.dart';t=root/'test/exercise_catalog_filter_test.dart'
if not (root/'pubspec.yaml').exists() or not a.exists() or not p.exists():sys.exit('ERRO: execute na raiz Flutter.')
if f.exists() or t.exists():sys.exit('ERRO: esta etapa ja parece instalada. Nenhuma mudanca.')
app=a.read_text(encoding='utf-8');prov=p.read_text(encoding='utf-8')
anchor='''    final exercises = ref.watch(exercisesProvider);
    return Scaffold('''
replace='''    final exercises = ref.watch(exercisesProvider);
    final catalog = ref.watch(catalogExercisesProvider);
    final muscle = ref.watch(exerciseMuscleFilterProvider);
    final equipment = ref.watch(exerciseEquipmentFilterProvider);
    final origin = ref.watch(exerciseOriginFilterProvider);
    final muscles = catalog.map((e) => e.primaryMuscle).toSet().toList()..sort();
    final equipments = catalog.map((e) => e.equipment).toSet().toList()..sort();
    void clearFilters() {
      ref.read(exerciseSearchProvider.notifier).state = '';
      ref.read(exerciseMuscleFilterProvider.notifier).state = '';
      ref.read(exerciseEquipmentFilterProvider.notifier).state = '';
      ref.read(exerciseOriginFilterProvider.notifier).state = '';
      ref.read(exerciseSearchResetProvider.notifier).state++;
    }
    return Scaffold('''
# Restrict replacements to library class, not other widgets.
start=app.index('class ExerciseLibraryPage extends ConsumerWidget')
head,body=app[:start],app[start:]
old='''          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,'''
new='''          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value: muscle,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Todos os músculos')),
                    for (final value in muscles) DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) => ref.read(exerciseMuscleFilterProvider.notifier).state = value ?? '',
                ),
                DropdownButton<String>(
                  value: equipment,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Todos os equipamentos')),
                    for (final value in equipments) DropdownMenuItem(value: value, child: Text(value)),
                  ],
                  onChanged: (value) => ref.read(exerciseEquipmentFilterProvider.notifier).state = value ?? '',
                ),
                DropdownButton<String>(
                  value: origin,
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todas as origens')),
                    DropdownMenuItem(value: 'catalog', child: Text('Catálogo')),
                    DropdownMenuItem(value: 'custom', child: Text('Personalizados')),
                  ],
                  onChanged: (value) => ref.read(exerciseOriginFilterProvider.notifier).state = value ?? '',
                ),
                TextButton.icon(onPressed: clearFilters, icon: const Icon(Icons.filter_alt_off), label: const Text('Limpar filtros')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Text('${exercises.length} exercícios encontrados'),
          ),
          if (exercises.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off, size: 42),
                    const SizedBox(height: 10),
                    const Text('Nenhum exercício encontrado.'),
                    OutlinedButton(onPressed: clearFilters, child: const Text('Limpar filtros')),
                  ],
                ),
              ),
            )
          else
          Expanded(
            child: ListView.builder(
              itemCount: exercises.length,'''
oldp='''final exerciseSearchProvider = StateProvider<String>((ref) => '');
final catalogRevisionProvider = StateProvider<int>((ref) => 0);
final exercisesProvider = Provider.autoDispose<List<Exercise>>((ref) {
  ref.watch(catalogRevisionProvider);
  return ref
      .read(trainingRepositoryProvider)
      .search(ref.watch(exerciseSearchProvider));
});'''
newp='''final exerciseSearchProvider = StateProvider<String>((ref) => '');
final exerciseMuscleFilterProvider = StateProvider<String>((ref) => '');
final exerciseEquipmentFilterProvider = StateProvider<String>((ref) => '');
final exerciseOriginFilterProvider = StateProvider<String>((ref) => '');
final exerciseSearchResetProvider = StateProvider<int>((ref) => 0);
final catalogRevisionProvider = StateProvider<int>((ref) => 0);
final catalogExercisesProvider = Provider.autoDispose<List<Exercise>>((ref) {
  ref.watch(catalogRevisionProvider);
  return ref.read(trainingRepositoryProvider).search('');
});
final exercisesProvider = Provider.autoDispose<List<Exercise>>((ref) => filterExerciseCatalog(
  ref.watch(catalogExercisesProvider),
  query: ref.watch(exerciseSearchProvider),
  muscle: ref.watch(exerciseMuscleFilterProvider),
  equipment: ref.watch(exerciseEquipmentFilterProvider),
  origin: ref.watch(exerciseOriginFilterProvider),
));'''
if body.count(anchor)!=1 or body.count(old)!=1 or prov.count(oldp)!=1:sys.exit('CHECK FALHOU: trechos locais divergentes. Nada alterado.')
app=head+body.replace(anchor,replace,1).replace(old,new,1)
app=app.replace("            child: TextField(\n              onChanged: (value) =>\n                  ref.read(exerciseSearchProvider.notifier).state = value,","            child: TextField(\n              key: ValueKey(ref.watch(exerciseSearchResetProvider)),\n              onChanged: (value) =>\n                  ref.read(exerciseSearchProvider.notifier).state = value,",1)
prov=prov.replace("import '../domain/exercise.dart';","import '../domain/exercise.dart';\nimport '../domain/exercise_catalog_filter.dart';",1).replace(oldp,newp,1)
filter_src='''import 'exercise.dart';

List<Exercise> filterExerciseCatalog(List<Exercise> items, {String query = '', String muscle = '', String equipment = '', String origin = ''}) {
  final text = query.trim().toLowerCase();
  return items.where((e) =>
    (text.isEmpty || e.name.toLowerCase().contains(text) || e.aliases.any((a) => a.toLowerCase().contains(text))) &&
    (muscle.isEmpty || e.primaryMuscle == muscle) &&
    (equipment.isEmpty || e.equipment == equipment) &&
    (origin.isEmpty || (origin == 'custom' && e.isCustom) || (origin == 'catalog' && !e.isCustom))
  ).toList(growable: false);
}
'''
test_src='''import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/features/training/domain/exercise.dart';
import 'package:vero_equilibrafit_app/features/training/domain/exercise_catalog_filter.dart';
void main() {
  const items = <Exercise>[
    Exercise(id: '1', name: 'Supino inclinado', primaryMuscle: 'Peito', equipment: 'Halteres', aliases: ['Inclinado']),
    Exercise(id: '2', name: 'Remada baixa', primaryMuscle: 'Costas', equipment: 'Cabo'),
    Exercise(id: '3', name: 'Supino personalizado', primaryMuscle: 'Peito', equipment: 'Halteres', isCustom: true),
  ];
  test('combina filtros', () => expect(filterExerciseCatalog(items, query: 'supino', muscle: 'Peito', equipment: 'Halteres', origin: 'catalog').single.id, '1'));
  test('apelidos', () => expect(filterExerciseCatalog(items, query: 'inclinado').single.id, '1'));
  test('sem filtros', () => expect(filterExerciseCatalog(items).length, 3));
  test('personalizados', () => expect(filterExerciseCatalog(items, origin: 'custom').single.id, '3'));
  test('sem resultado', () => expect(filterExerciseCatalog(items, query: 'naoexiste'), isEmpty));
}
'''
print('CHECK OK: estrutura compativel')
if '--check' in sys.argv:sys.exit(0)
backup=root.parents[1]/'backups'/('vero_771b_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S'))
backup.mkdir(parents=True,exist_ok=False)
for file in [a,p]:
  dst=backup/file.relative_to(root);dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,dst)
a.write_text(app,encoding='utf-8');p.write_text(prov,encoding='utf-8');f.write_text(filter_src,encoding='utf-8');t.write_text(test_src,encoding='utf-8')
print('INSTALADO; backup:',backup)
