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

  MealEntry copyWith({
    String? name,
    String? mealType,
    DateTime? recordedAt,
    String? notes,
    double? estimatedCalories,
    double? proteinGrams,
    double? carbohydrateGrams,
    double? fatGrams,
  }) => MealEntry(
    id: id,
    name: name ?? this.name,
    mealType: mealType ?? this.mealType,
    recordedAt: recordedAt ?? this.recordedAt,
    notes: notes ?? this.notes,
    estimatedCalories: estimatedCalories ?? this.estimatedCalories,
    proteinGrams: proteinGrams ?? this.proteinGrams,
    carbohydrateGrams: carbohydrateGrams ?? this.carbohydrateGrams,
    fatGrams: fatGrams ?? this.fatGrams,
  );
}
