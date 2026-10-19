import 'workout_set_result.dart';

class WorkoutExerciseResult {
  const WorkoutExerciseResult({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    this.notes = '',
  });

  final String exerciseId;
  final String exerciseName;
  final List<WorkoutSetResult> sets;
  final String notes;

  WorkoutExerciseResult copyWith({
    List<WorkoutSetResult>? sets,
    String? notes,
  }) {
    return WorkoutExerciseResult(
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets ?? this.sets,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
    'exerciseId': exerciseId,
    'exerciseName': exerciseName,
    'notes': notes,
    'sets': sets.map((set) => set.toJson()).toList(),
  };

  factory WorkoutExerciseResult.fromJson(Map<String, dynamic> json) {
    return WorkoutExerciseResult(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      sets: (json['sets'] as List<dynamic>? ?? [])
          .map(
            (item) => WorkoutSetResult.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
    );
  }
}
