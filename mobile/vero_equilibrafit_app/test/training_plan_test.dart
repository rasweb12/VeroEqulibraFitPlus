import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vero_equilibrafit_app/features/auth/presentation/current_owner_provider.dart';
import 'package:vero_equilibrafit_app/features/habits/presentation/habits_page.dart';
import 'package:vero_equilibrafit_app/features/training/data/training_repository.dart';

void main() {
  test('logical deletion hides a plan and keeps it recoverable', () {
    final repository = TrainingRepository(ownerId: 'test-user');
    final id = repository
        .createPlan(name: 'Força A', objective: 'Consistência')
        .id;
    repository.softDelete(id);
    expect(repository.activePlans(), isEmpty);
    repository.restore(id);
    expect(repository.activePlans().single.id, id);
  });

  test('search finds accent-insensitive aliases before any AI request', () {
    expect(TrainingRepository(ownerId: 'test-user').search('agachamento livre').single.id, 'squat');
  });

  test('hydration is only increased by an explicit local registration', () {
    final container = ProviderContainer(
      overrides: [currentOwnerIdProvider.overrideWithValue('test-user')],
    );
    addTearDown(container.dispose);

    expect(container.read(habitsProvider).waterMl, 0);
    container.read(habitsProvider.notifier).addWater();
    expect(container.read(habitsProvider).waterMl, 250);
  });
}
