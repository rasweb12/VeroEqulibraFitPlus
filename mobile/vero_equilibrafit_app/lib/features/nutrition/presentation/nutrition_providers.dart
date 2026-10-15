import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/preferences_provider.dart';
import '../../auth/presentation/current_owner_provider.dart';
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
