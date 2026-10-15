import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/features/nutrition/data/nutrition_repository.dart';

void main() {
  test('registra e exclui uma refeição', () {
    final repository = NutritionRepository(ownerId: 'test-user');
    repository.add(name: 'Arroz e feijão', mealType: 'Almoço', notes: '');

    final entry = repository.entries().single;
    expect(entry.name, 'Arroz e feijão');
    expect(entry.mealType, 'Almoço');

    repository.delete(entry.id);
    expect(repository.entries(), isEmpty);
  });
}
