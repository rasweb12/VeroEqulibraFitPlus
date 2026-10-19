import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/persistence/preferences_provider.dart';
import '../../../core/offline/secure_operation_queue.dart';
import '../../auth/presentation/current_owner_provider.dart';
import '../data/training_repository.dart';
import '../domain/exercise.dart';
import '../domain/exercise_catalog_filter.dart';
import '../domain/training_plan.dart';
import '../domain/planned_exercise.dart';

final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => TrainingRepository(
    ownerId: ref.watch(currentOwnerIdProvider),
    store: ref.read(secureOwnerStoreProvider),
    outbox: SecureOperationQueue(
      ownerId: ref.watch(currentOwnerIdProvider),
      store: ref.read(secureOwnerStoreProvider),
    ),
  ),
);
final plansProvider =
    StateNotifierProvider<PlansController, List<TrainingPlan>>(
      (ref) => PlansController(ref.read(trainingRepositoryProvider)),
    );

class PlansController extends StateNotifier<List<TrainingPlan>> {
  PlansController(this._repository) : super(const []) {
    _restore();
  }
  final TrainingRepository _repository;
  Future<void> _restore() async {
    await _repository.load();
    if (mounted) state = _repository.activePlans();
  }

  List<TrainingPlan> get archivedPlans => _repository.archivedPlans();

  void archive(String id) {
    _repository.archive(id);
    state = List<TrainingPlan>.of(_repository.activePlans());
  }

  void unarchive(String id) {
    _repository.unarchive(id);
    state = _repository.activePlans();
  }

  void delete(String id) {
    _repository.softDelete(id);
    state = _repository.activePlans();
  }

  void restore(String id) {
    _repository.restore(id);
    state = _repository.activePlans();
  }

  void duplicate(String id) {
    _repository.duplicate(id);
    state = _repository.activePlans();
  }

  void create({
    required String name,
    required String objective,
    List<int> weekdays = const [],
  }) {
    _repository.createPlan(
      name: name,
      objective: objective,
      weekdays: weekdays,
    );
    state = _repository.activePlans();
  }

  void addExercise(String planId, String exerciseId) {
    _repository.addExerciseToPlan(planId, exerciseId);
    state = _repository.activePlans();
  }

  void removeExercise(String planId, String exerciseId) {
    _repository.removeExerciseFromPlan(planId, exerciseId);
    state = _repository.activePlans();
  }

  void updateExercise(String planId, PlannedExercise exercise) {
    _repository.updatePlannedExercise(planId, exercise);
    state = _repository.activePlans();
  }

  void updatePlanDetails({
    required String id,
    required String name,
    required String objective,
    required List<int> weekdays,
  }) {
    _repository.updatePlanDetails(
      id: id,
      name: name,
      objective: objective,
      weekdays: weekdays,
    );

    state = List<TrainingPlan>.of(_repository.activePlans());
  }
}

final exerciseSearchProvider = StateProvider<String>((ref) => '');
final exerciseMuscleFilterProvider = StateProvider<String>((ref) => '');
final exerciseEquipmentFilterProvider = StateProvider<String>((ref) => '');
final exerciseOriginFilterProvider = StateProvider<String>((ref) => '');
final exerciseSearchResetProvider = StateProvider<int>((ref) => 0);
final catalogRevisionProvider = StateProvider<int>((ref) => 0);
final catalogExercisesProvider = Provider.autoDispose<List<Exercise>>((ref) {
  ref.watch(catalogRevisionProvider);
  return ref.read(trainingRepositoryProvider).search('');
});
final exercisesProvider = Provider.autoDispose<List<Exercise>>(
  (ref) => filterExerciseCatalog(
    ref.watch(catalogExercisesProvider),
    query: ref.watch(exerciseSearchProvider),
    muscle: ref.watch(exerciseMuscleFilterProvider),
    equipment: ref.watch(exerciseEquipmentFilterProvider),
    origin: ref.watch(exerciseOriginFilterProvider),
  ),
);
final archivedPlansProvider = Provider<List<TrainingPlan>>((ref) {
  ref.watch(plansProvider);

  return ref.read(trainingRepositoryProvider).archivedPlans();
});
