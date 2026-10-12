import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/features/training/data/training_repository.dart';

void main() {
  test('adiciona e remove exercício sem apagar a ficha', () {
    final repository = TrainingRepository();
    final plan = repository.createPlan(name: 'Treino A', objective: 'Força');

    repository.addExerciseToPlan(plan.id, 'squat');
    expect(repository.planById(plan.id)?.exercises, ['squat']);

    repository.removeExerciseFromPlan(plan.id, 'squat');
    expect(repository.planById(plan.id)?.exercises, isEmpty);
  });

  test('não duplica exercício adicionado duas vezes', () {
    final repository = TrainingRepository();
    final plan = repository.createPlan(name: 'Treino A', objective: 'Força');

    repository.addExerciseToPlan(plan.id, 'squat');
    repository.addExerciseToPlan(plan.id, 'squat');

    expect(repository.planById(plan.id)?.exercises, ['squat']);
  });
}
