import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/training_repository.dart';
import '../domain/exercise.dart';
import '../domain/training_plan.dart';

final trainingRepositoryProvider = Provider<TrainingRepository>(
  (ref) => TrainingRepository(),
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
}

final exerciseSearchProvider = StateProvider<String>((ref) => '');
final exercisesProvider = Provider<List<Exercise>>(
  (ref) => ref
      .read(trainingRepositoryProvider)
      .search(ref.watch(exerciseSearchProvider)),
);
