import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/core/persistence/secure_owner_store.dart';
import 'package:vero_equilibrafit_app/features/nutrition/data/nutrition_repository.dart';
import 'package:vero_equilibrafit_app/features/training/data/training_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('does not expose a training plan to a different account', () async {
    final store = MemorySecureOwnerStore();
    final first = TrainingRepository(ownerId: 'account-a', store: store);
    first.createPlan(name: 'Força', objective: 'Constância');
    await Future<void>.delayed(Duration.zero);

    final second = TrainingRepository(ownerId: 'account-b', store: store);
    await second.load();
    expect(second.activePlans(), isEmpty);
  });

  test('does not expose a meal entry to a different account', () async {
    final store = MemorySecureOwnerStore();
    final first = NutritionRepository(ownerId: 'account-a', store: store);
    first.add(name: 'Almoço', mealType: 'Almoço', notes: 'teste');
    await Future<void>.delayed(Duration.zero);

    final second = NutritionRepository(ownerId: 'account-b', store: store);
    await second.load();
    expect(second.entries(), isEmpty);
  });
}
