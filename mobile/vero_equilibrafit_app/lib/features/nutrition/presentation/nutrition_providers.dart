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
    preferences: ref.read(sharedPreferencesProvider),
  ),
);

final mealsProvider = StateNotifierProvider.autoDispose<MealsController, List<MealEntry>>(
  (ref) => MealsController(ref.read(nutritionRepositoryProvider)),
);

final mealPhotoAnalysisRepositoryProvider = Provider.autoDispose<MealPhotoAnalysisRepository>((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) throw StateError('Uma sessão validada é necessária.');
  return MealPhotoAnalysisRepository(session);
});

class MealsController extends StateNotifier<List<MealEntry>> {
  MealsController(this._repository) : super(_repository.entries());
  final NutritionRepository _repository;

  void add({required String name, required String mealType, required String notes}) {
    _repository.add(name: name, mealType: mealType, notes: notes);
    state = _repository.entries();
  }

  void delete(String id) {
    _repository.delete(id);
    state = _repository.entries();
  }
}
