import 'planned_exercise.dart';

class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.name,
    required this.objective,
    required this.exercises,
    this.weekdays = const [],
    this.deletedAt,
    this.revision = 0,
    this.updatedAt,
  });
  final String id;
  final String name;
  final String objective;
  final List<PlannedExercise> exercises;
  final List<int> weekdays;
  final DateTime? deletedAt;
  final int revision;
  final DateTime? updatedAt;
  bool get isDeleted => deletedAt != null;
  TrainingPlan copyWith({
    String? id,
    String? name,
    String? objective,
    List<PlannedExercise>? exercises,
    List<int>? weekdays,
    DateTime? deletedAt,
    int? revision,
    DateTime? updatedAt,
  }) => TrainingPlan(
    id: id ?? this.id,
    name: name ?? this.name,
    objective: objective ?? this.objective,
    exercises: exercises ?? this.exercises,
    weekdays: weekdays ?? this.weekdays,
    deletedAt: deletedAt,
    revision: revision ?? this.revision,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
