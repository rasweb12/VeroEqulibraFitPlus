import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/core/persistence/secure_owner_store.dart';
import 'package:vero_equilibrafit_app/features/nutrition/data/nutrition_repository.dart';
import 'package:vero_equilibrafit_app/features/nutrition/presentation/nutrition_providers.dart';

void main() {
  test('registra e exclui uma refeição', () async {
    final repository = NutritionRepository(
      ownerId: 'test-user',
      store: MemorySecureOwnerStore(),
    );
    await repository.add(name: 'Arroz e feijão', mealType: 'Almoço', notes: '');

    final entry = repository.entries().single;
    expect(entry.name, 'Arroz e feijão');
    expect(entry.mealType, 'Almoço');

    await repository.delete(entry.id);
    expect(repository.entries(), isEmpty);
  });

  test('edita uma refeição sem alterar sua identidade', () async {
    final repository = NutritionRepository(
      ownerId: 'test-user',
      store: MemorySecureOwnerStore(),
    );
    await repository.add(
      name: 'Arroz',
      mealType: 'Almoço',
      notes: 'Porção: 100 g',
    );
    final original = repository.entries().single;

    await repository.update(
      original.copyWith(
        notes: 'Porção: 150 g',
        estimatedCalories: 195,
        proteinGrams: 3.8,
      ),
    );

    final updated = repository.entries().single;
    expect(updated.id, original.id);
    expect(updated.notes, 'Porção: 150 g');
    expect(updated.estimatedCalories, 195);
    expect(updated.proteinGrams, 3.8);
  });

  test('não confirma uma refeição quando a persistência local falha', () async {
    final repository = NutritionRepository(
      ownerId: 'test-user',
      store: _FailingStore(),
    );

    await expectLater(
      repository.add(name: 'Almoço', mealType: 'Almoço', notes: ''),
      throwsA(isA<StateError>()),
    );
    expect(repository.entries(), isEmpty);
  });

  test(
    'notifica sincronização somente depois de persistir a refeição',
    () async {
      final repository = NutritionRepository(
        ownerId: 'test-user',
        store: MemorySecureOwnerStore(),
      );
      var notifications = 0;
      final controller = MealsController(
        repository,
        onPersistedMutation: () => notifications++,
      );

      await controller.add(name: 'Almoço', mealType: 'Almoço', notes: '');

      expect(notifications, 1);
      controller.dispose();
    },
  );
}

class _FailingStore implements SecureOwnerStore {
  @override
  Future<void> delete(String key) async {}

  @override
  Future<String?> read(String key) async => null;

  @override
  Future<void> write(String key, String value) =>
      Future<void>.error(StateError('storage unavailable'));
}
