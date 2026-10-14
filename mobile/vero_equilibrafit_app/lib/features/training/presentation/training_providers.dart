import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/persistence/preferences_provider.dart';
import '../data/training_repository.dart';
import '../domain/exercise.dart';
import '../domain/training_plan.dart';

final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => TrainingRepository(preferences: ref.read(sharedPreferencesProvider)),
);
final plansProvider =
    StateNotifierProvider<PlansController, List<TrainingPlan>>(
      (ref) => PlansController(ref.read(trainingRepositoryProvider)),
    );

class PlansController extends StateNotifier<List<TrainingPlan>> {
  PlansController(this._repository) : super(_repository.activePlans());
  final TrainingRepository _repository;
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

  void create({required String name, required String objective}) {
    _repository.createPlan(name: name, objective: objective);
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
}

final exerciseSearchProvider = StateProvider<String>((ref) => '');
final catalogRevisionProvider = StateProvider<int>((ref) => 0);
final exercisesProvider = Provider<List<Exercise>>((ref) {
  ref.watch(catalogRevisionProvider);
  return ref
      .read(trainingRepositoryProvider)
      .search(ref.watch(exerciseSearchProvider));
});
