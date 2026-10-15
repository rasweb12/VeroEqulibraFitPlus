class PlannedExercise {
  const PlannedExercise({
    required this.exerciseId,
    this.sets = 3,
    this.repetitions = '10',
    this.targetLoadKg,
    this.restSeconds = 60,
    this.notes = '',
  });

  final String exerciseId;
  final int sets;
  final String repetitions;
  final double? targetLoadKg;
  final int restSeconds;
  final String notes;

  PlannedExercise copyWith({
    int? sets,
    String? repetitions,
    double? targetLoadKg,
    int? restSeconds,
    String? notes,
  }) => PlannedExercise(
    exerciseId: exerciseId,
    sets: sets ?? this.sets,
    repetitions: repetitions ?? this.repetitions,
    targetLoadKg: targetLoadKg ?? this.targetLoadKg,
    restSeconds: restSeconds ?? this.restSeconds,
    notes: notes ?? this.notes,
  );
}
