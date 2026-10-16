class MealEntry {
  const MealEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.recordedAt,
    this.notes = '',
    this.estimatedCalories,
    this.proteinGrams,
    this.carbohydrateGrams,
    this.fatGrams,
  });

  final String id;
  final String name;
  final String mealType;
  final DateTime recordedAt;
  final String notes;
  final double? estimatedCalories;
  final double? proteinGrams;
  final double? carbohydrateGrams;
  final double? fatGrams;
}
