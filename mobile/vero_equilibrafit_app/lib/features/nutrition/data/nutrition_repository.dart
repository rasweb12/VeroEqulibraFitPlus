import '../domain/meal_entry.dart';

class NutritionRepository {
  final List<MealEntry> _entries = [];

  List<MealEntry> entries() => List.unmodifiable(_entries.reversed);

  void add({
    required String name,
    required String mealType,
    required String notes,
  }) {
    _entries.add(MealEntry(
      id: 'meal-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      mealType: mealType,
      notes: notes.trim(),
      recordedAt: DateTime.now(),
    ));
  }

  void delete(String id) => _entries.removeWhere((entry) => entry.id == id);
}
