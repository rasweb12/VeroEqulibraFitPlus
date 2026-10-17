import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/preferences_provider.dart';
import '../../auth/presentation/current_owner_provider.dart';
import '../../auth/presentation/auth_providers.dart';
import '../data/meal_photo_analysis_repository.dart';
import '../data/nutrition_repository.dart';
import '../domain/meal_entry.dart';

final nutritionRepositoryProvider = Provider.autoDispose<NutritionRepository>(
  (ref) => NutritionRepository(
    ownerId: ref.watch(currentOwnerIdProvider),
    store: ref.read(secureOwnerStoreProvider),
  ),
);

final mealsProvider =
    StateNotifierProvider.autoDispose<MealsController, List<MealEntry>>(
      (ref) => MealsController(ref.read(nutritionRepositoryProvider)),
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
  MealsController(this._repository) : super(const []) {
    _restore();
  }
  final NutritionRepository _repository;
  Future<void> _restore() async {
    await _repository.load();
    if (mounted) state = _repository.entries();
  }

  void add({
    required String name,
    required String mealType,
    required String notes,
    double? estimatedCalories,
    double? proteinGrams,
    double? carbohydrateGrams,
    double? fatGrams,
    DateTime? recordedAt,
  }) {
    _repository.add(
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
  }

  void delete(String id) {
    _repository.delete(id);
    state = _repository.entries();
  }

  void update(MealEntry entry) {
    _repository.update(entry);
    state = _repository.entries();
  }
}
