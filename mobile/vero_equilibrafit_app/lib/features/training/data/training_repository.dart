import '../domain/exercise.dart';
import '../domain/training_plan.dart';

/// Local-first repository boundary; the Isar adapter will queue synced work.
class TrainingRepository {
  TrainingRepository()
    : _plans = [
        const TrainingPlan(
          id: 'plan-strength-a',
          name: 'Força A',
          objective: 'Força e consistência',
          exercises: ['Agachamento com barra', 'Supino inclinado com halteres'],
        ),
      ];
  final List<TrainingPlan> _plans;
  final List<Exercise> _customExercises = [];
  static const catalog = <Exercise>[
    Exercise(
      id: 'incline-dumbbell',
      name: 'Supino inclinado com halteres',
      primaryMuscle: 'Peito',
      equipment: 'Halteres',
    ),
    Exercise(
      id: 'squat',
      name: 'Agachamento com barra',
      primaryMuscle: 'Pernas',
      equipment: 'Barra',
      aliases: ['Agachamento livre'],
    ),
    Exercise(
      id: 'leg-press',
      name: 'Leg press',
      primaryMuscle: 'Pernas',
      equipment: 'Máquina',
    ),
    Exercise(
      id: 'lat-pulldown',
      name: 'Puxada frontal',
      primaryMuscle: 'Costas',
      equipment: 'Máquina',
    ),
    Exercise(
      id: 'biceps-curl',
      name: 'Rosca direta',
      primaryMuscle: 'Bíceps',
      equipment: 'Barra',
    ),
  ];
  List<TrainingPlan> activePlans() =>
      _plans.where((plan) => !plan.isDeleted).toList(growable: false);
  List<Exercise> search(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return [...catalog, ..._customExercises];
    return [...catalog, ..._customExercises]
        .where(
          (exercise) =>
              _normalize(exercise.name).contains(normalized) ||
              exercise.aliases.any(
                (alias) => _normalize(alias).contains(normalized),
              ),
        )
        .toList(growable: false);
  }

  void softDelete(String id) {
    final index = _plans.indexWhere((plan) => plan.id == id);
    if (index < 0 || _plans[index].isDeleted) return;
    _plans[index] = _plans[index].copyWith(deletedAt: DateTime.now().toUtc());
  }

  void restore(String id) {
    final index = _plans.indexWhere((plan) => plan.id == id);
    if (index < 0) return;
    final plan = _plans[index];
    _plans[index] = TrainingPlan(
      id: plan.id,
      name: plan.name,
      objective: plan.objective,
      exercises: plan.exercises,
    );
  }

  TrainingPlan duplicate(String id) {
    final source = _plans.firstWhere(
      (plan) => plan.id == id && !plan.isDeleted,
    );
    final copy = source.copyWith(
      id: '${source.id}-${DateTime.now().microsecondsSinceEpoch}',
      name: '${source.name} (cópia)',
    );
    _plans.add(copy);
    return copy;
  }

  Exercise createCustom({
    required String name,
    required String primaryMuscle,
    required String equipment,
  }) {
    final exercise = Exercise(
      id: 'custom-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      primaryMuscle: primaryMuscle,
      equipment: equipment,
      isCustom: true,
    );
    _customExercises.add(exercise);
    return exercise;
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éêë]'), 'e')
      .replaceAll(RegExp('[íîï]'), 'i')
      .replaceAll(RegExp('[óôõö]'), 'o')
      .replaceAll(RegExp('[úûü]'), 'u')
      .replaceAll('ç', 'c')
      .trim();
}
