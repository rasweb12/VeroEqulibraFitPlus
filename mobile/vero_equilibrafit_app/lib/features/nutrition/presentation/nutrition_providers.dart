import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/offline/sync_providers.dart';
import '../../../core/persistence/preferences_provider.dart';
import '../../../core/offline/secure_operation_queue.dart';
import '../../auth/presentation/current_owner_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/meal_photo_analysis_repository.dart';
import '../data/nutrition_repository.dart';
import '../domain/meal_entry.dart';

final nutritionRepositoryProvider = Provider.autoDispose<NutritionRepository>(
  (ref) => NutritionRepository(
    ownerId: ref.watch(currentOwnerIdProvider),
    store: ref.read(secureOwnerStoreProvider),
    outbox: SecureOperationQueue(
      ownerId: ref.watch(currentOwnerIdProvider),
      store: ref.read(secureOwnerStoreProvider),
    ),
  ),
);

final mealsProvider =
    StateNotifierProvider.autoDispose<MealsController, List<MealEntry>>(
      (ref) => MealsController(
        ref.read(nutritionRepositoryProvider),
        onPersistedMutation: () {
          final session = ref.read(authSessionProvider).valueOrNull;
          if (session == null) return;
          unawaited(ref.read(syncServiceProvider).pushPending(session));
        },
      ),
    );

/// Dia exibido no diário. O registro continua usando seu horário original.
final nutritionDiaryDateProvider = StateProvider<DateTime>(
  (_) => DateTime.now(),
);

final mealPhotoAnalysisRepositoryProvider =
    Provider.autoDispose<MealPhotoAnalysisRepository>((ref) {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('Uma sessão validada é necessária.');
      }
      return MealPhotoAnalysisRepository(session);
    });

class MealsController extends StateNotifier<List<MealEntry>> {
  MealsController(this._repository, {this.onPersistedMutation})
    : super(const []) {
    _restore();
  }
  final NutritionRepository _repository;
  final void Function()? onPersistedMutation;
  Future<void> _restore() async {
    await _repository.load();
    if (mounted) state = _repository.entries();
  }

  Future<void> add({
    required String name,
    required String mealType,
    required String notes,
    double? estimatedCalories,
    double? proteinGrams,
    double? carbohydrateGrams,
    double? fatGrams,
    DateTime? recordedAt,
  }) async {
    await _repository.add(
      name: name,
      mealType: mealType,
      notes: notes,
      estimatedCalories: estimatedCalories,
      proteinGrams: proteinGrams,
      carbohydrateGrams: carbohydrateGrams,
      fatGrams: fatGrams,
      recordedAt: recordedAt,
    );
    state = _repository.entries();
    onPersistedMutation?.call();
  }

  Future<void> delete(String id) async {
    await _repository.delete(id);
    state = _repository.entries();
    onPersistedMutation?.call();
  }

  Future<void> update(MealEntry entry) async {
    await _repository.update(entry);
    state = _repository.entries();
    onPersistedMutation?.call();
  }
}
