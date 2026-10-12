import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/features/training/data/training_repository.dart';

void main() {
  test('logical deletion hides a plan and keeps it recoverable', () {
    final repository = TrainingRepository();
    final id = repository.activePlans().single.id;
    repository.softDelete(id);
    expect(repository.activePlans(), isEmpty);
    repository.restore(id);
    expect(repository.activePlans().single.id, id);
  });

  test('search finds accent-insensitive aliases before any AI request', () {
    expect(TrainingRepository().search('agachamento livre').single.id, 'squat');
  });
}
