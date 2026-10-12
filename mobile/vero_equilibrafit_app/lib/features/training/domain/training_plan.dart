class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.name,
    required this.objective,
    required this.exercises,
    this.deletedAt,
  });
  final String id;
  final String name;
  final String objective;
  final List<String> exercises;
  final DateTime? deletedAt;
  bool get isDeleted => deletedAt != null;
  TrainingPlan copyWith({String? id, String? name, DateTime? deletedAt}) =>
      TrainingPlan(
        id: id ?? this.id,
        name: name ?? this.name,
        objective: objective,
        exercises: exercises,
        deletedAt: deletedAt,
      );
}
