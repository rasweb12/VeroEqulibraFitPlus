import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/features/training/domain/exercise.dart';
import 'package:vero_equilibrafit_app/features/training/domain/exercise_catalog_filter.dart';

void main() {
  const items = <Exercise>[
    Exercise(
      id: '1',
      name: 'Supino inclinado',
      primaryMuscle: 'Peito',
      equipment: 'Halteres',
      aliases: ['Inclinado'],
    ),
    Exercise(
      id: '2',
      name: 'Remada baixa',
      primaryMuscle: 'Costas',
      equipment: 'Cabo',
    ),
    Exercise(
      id: '3',
      name: 'Supino personalizado',
      primaryMuscle: 'Peito',
      equipment: 'Halteres',
      isCustom: true,
    ),
  ];
  test(
    'combina filtros',
    () => expect(
      filterExerciseCatalog(
        items,
        query: 'supino',
        muscle: 'Peito',
        equipment: 'Halteres',
        origin: 'catalog',
      ).single.id,
      '1',
    ),
  );
  test(
    'apelidos',
    () =>
        expect(filterExerciseCatalog(items, query: 'inclinado').single.id, '1'),
  );
  test('sem filtros', () => expect(filterExerciseCatalog(items).length, 3));
  test(
    'personalizados',
    () => expect(filterExerciseCatalog(items, origin: 'custom').single.id, '3'),
  );
  test(
    'sem resultado',
    () => expect(filterExerciseCatalog(items, query: 'naoexiste'), isEmpty),
  );
}
