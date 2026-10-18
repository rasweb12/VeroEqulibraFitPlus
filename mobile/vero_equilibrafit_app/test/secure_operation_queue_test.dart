import 'package:flutter_test/flutter_test.dart';
import 'package:vero_equilibrafit_app/core/offline/secure_operation_queue.dart';
import 'package:vero_equilibrafit_app/core/persistence/secure_owner_store.dart';
import 'package:vero_equilibrafit_app/features/nutrition/data/nutrition_repository.dart';

void main() {
  test('persists pending operations in the owner encrypted store', () async {
    final store = MemorySecureOwnerStore();
    final queue = SecureOperationQueue(ownerId: 'account-a', store: store);
    await queue.enqueue(
      ownerId: 'account-a',
      idempotencyKey: 'operation-a',
      entityType: 'meal',
      entityId: 'a4f8a0d3-2ddf-4a8e-9a36-0b3d85b6755c',
      operationType: 'meal.create',
      payloadJson: '{"description":"Almoço"}',
      clientVersion: '1',
    );

    final restored = SecureOperationQueue(ownerId: 'account-a', store: store);
    final pending = await restored.due(ownerId: 'account-a');

    expect(pending, hasLength(1));
    expect(pending.single.idempotencyKey, 'operation-a');
    expect(pending.single.payloadJson, '{"description":"Almoço"}');
  });

  test('does not expose an account queue to another account', () async {
    final store = MemorySecureOwnerStore();
    final first = SecureOperationQueue(ownerId: 'account-a', store: store);
    await first.enqueue(
      ownerId: 'account-a',
      idempotencyKey: 'operation-a',
      entityType: 'meal',
      entityId: 'a4f8a0d3-2ddf-4a8e-9a36-0b3d85b6755c',
      operationType: 'meal.create',
      payloadJson: '{}',
      clientVersion: '1',
    );

    final second = SecureOperationQueue(ownerId: 'account-b', store: store);
    expect(await second.due(ownerId: 'account-b'), isEmpty);
    await expectLater(second.due(ownerId: 'account-a'), throwsStateError);
  });

  test('new local meal also creates an encrypted sync operation', () async {
    final store = MemorySecureOwnerStore();
    final queue = SecureOperationQueue(ownerId: 'account-a', store: store);
    final repository = NutritionRepository(
      ownerId: 'account-a',
      store: store,
      outbox: queue,
    );

    repository.add(name: 'Almoço', mealType: 'Almoço', notes: '');
    await Future<void>.delayed(Duration.zero);

    final pending = await queue.due(ownerId: 'account-a');
    expect(pending, hasLength(1));
    expect(pending.single.operationType, 'meal.create');
  });

  test('deleting a new local meal preserves a tombstone operation', () async {
    final store = MemorySecureOwnerStore();
    final queue = SecureOperationQueue(ownerId: 'account-a', store: store);
    final repository = NutritionRepository(
      ownerId: 'account-a',
      store: store,
      outbox: queue,
    );

    repository.add(name: 'Jantar', mealType: 'Jantar', notes: '');
    await Future<void>.delayed(Duration.zero);
    final mealId = repository.entries().single.id;
    repository.delete(mealId);
    await Future<void>.delayed(Duration.zero);

    final pending = await queue.due(ownerId: 'account-a');
    expect(pending.map((item) => item.operationType), contains('meal.delete'));
  });
}
