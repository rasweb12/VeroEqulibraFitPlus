import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vero_equilibrafit_app/features/nutrition/data/nutrition_repository.dart';
import 'package:vero_equilibrafit_app/features/training/data/training_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('does not expose a training plan to a different account', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final first = TrainingRepository(ownerId: 'account-a', preferences: preferences);
    first.createPlan(name: 'Força', objective: 'Constância');

    final second = TrainingRepository(ownerId: 'account-b', preferences: preferences);
    expect(second.activePlans(), isEmpty);
  });

  test('does not expose a meal entry to a different account', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final first = NutritionRepository(ownerId: 'account-a', preferences: preferences);
    first.add(name: 'Almoço', mealType: 'Almoço', notes: 'teste');

    final second = NutritionRepository(ownerId: 'account-b', preferences: preferences);
    expect(second.entries(), isEmpty);
  });
}
