class MealEntry {
  const MealEntry({
    required this.id,
    required this.name,
    required this.mealType,
    required this.recordedAt,
    this.notes = '',
  });

  final String id;
  final String name;
  final String mealType;
  final DateTime recordedAt;
  final String notes;
}
