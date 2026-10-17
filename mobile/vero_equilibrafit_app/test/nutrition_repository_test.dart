import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/core/persistence/secure_owner_store.dart';
import 'package:vero_equilibrafit_app/features/nutrition/data/nutrition_repository.dart';

void main() {
  test('registra e exclui uma refeição', () {
    final repository = NutritionRepository(
      ownerId: 'test-user',
      store: MemorySecureOwnerStore(),
    );
    repository.add(name: 'Arroz e feijão', mealType: 'Almoço', notes: '');

    final entry = repository.entries().single;
    expect(entry.name, 'Arroz e feijão');
    expect(entry.mealType, 'Almoço');

    repository.delete(entry.id);
    expect(repository.entries(), isEmpty);
  });

  test('edita uma refeição sem alterar sua identidade', () {
    final repository = NutritionRepository(
      ownerId: 'test-user',
      store: MemorySecureOwnerStore(),
    );
    repository.add(name: 'Arroz', mealType: 'Almoço', notes: 'Porção: 100 g');
    final original = repository.entries().single;

    repository.update(original.copyWith(
      notes: 'Porção: 150 g',
      estimatedCalories: 195,
      proteinGrams: 3.8,
    ));

    final updated = repository.entries().single;
    expect(updated.id, original.id);
    expect(updated.notes, 'Porção: 150 g');
    expect(updated.estimatedCalories, 195);
    expect(updated.proteinGrams, 3.8);
  });
}
