import 'workout_exercise_result.dart';

enum WorkoutSessionStatus { inProgress, paused, completed, canceled }

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.planId,
    required this.planName,
    required this.startedAt,
    required this.exercises,
    this.status = WorkoutSessionStatus.inProgress,
    this.finishedAt,
    this.notes = '',
  });

  final String id;
  final String planId;
  final String planName;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final WorkoutSessionStatus status;
  final List<WorkoutExerciseResult> exercises;
  final String notes;

  bool get isFinished =>
      status == WorkoutSessionStatus.completed ||
      status == WorkoutSessionStatus.canceled;

  int get completedSets => exercises.fold(
    0,
    (total, exercise) =>
        total + exercise.sets.where((set) => set.completed).length,
  );

  int get totalSets =>
      exercises.fold(0, (total, exercise) => total + exercise.sets.length);

  static const _unchanged = Object();

  WorkoutSession copyWith({
    WorkoutSessionStatus? status,
    Object? finishedAt = _unchanged,
    List<WorkoutExerciseResult>? exercises,
    String? notes,
  }) {
    return WorkoutSession(
      id: id,
      planId: planId,
      planName: planName,
      startedAt: startedAt,
      finishedAt: identical(finishedAt, _unchanged)
          ? this.finishedAt
          : finishedAt as DateTime?,
      status: status ?? this.status,
      exercises: exercises ?? this.exercises,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'planName': planName,
    'startedAt': startedAt.toIso8601String(),
    'finishedAt': finishedAt?.toIso8601String(),
    'status': status.name,
    'notes': notes,
    'exercises': exercises.map((e) => e.toJson()).toList(),
  };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String? ?? 'inProgress';

    return WorkoutSession(
      id: json['id'] as String,
      planId: json['planId'] as String,
      planName: json['planName'] as String? ?? '',
      startedAt: DateTime.parse(json['startedAt'] as String),
      finishedAt: DateTime.tryParse(json['finishedAt'] as String? ?? ''),
      status: WorkoutSessionStatus.values.firstWhere(
        (value) => value.name == statusName,
        orElse: () => WorkoutSessionStatus.inProgress,
      ),
      notes: json['notes'] as String? ?? '',
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .map(
            (item) => WorkoutExerciseResult.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
