import 'planned_exercise.dart';

class TrainingPlan {
  const TrainingPlan({
    required this.id,
    required this.name,
    required this.objective,
    required this.exercises,
    this.weekdays = const [],
    this.deletedAt,
    this.archivedAt,
    this.revision = 0,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String objective;
  final List<PlannedExercise> exercises;
  final List<int> weekdays;
  final DateTime? deletedAt;
  final DateTime? archivedAt;
  final int revision;
  final DateTime? updatedAt;

  bool get isDeleted => deletedAt != null;
  bool get isArchived => archivedAt != null;

  static const _unchanged = Object();

  TrainingPlan copyWith({
    String? id,
    String? name,
    String? objective,
    List<PlannedExercise>? exercises,
    List<int>? weekdays,
    Object? deletedAt = _unchanged,
    Object? archivedAt = _unchanged,
    int? revision,
    DateTime? updatedAt,
  }) {
    return TrainingPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      objective: objective ?? this.objective,
      exercises: exercises ?? this.exercises,
      weekdays: weekdays ?? this.weekdays,
      deletedAt: identical(deletedAt, _unchanged)
          ? this.deletedAt
          : deletedAt as DateTime?,
      archivedAt: identical(archivedAt, _unchanged)
          ? this.archivedAt
          : archivedAt as DateTime?,
      revision: revision ?? this.revision,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
