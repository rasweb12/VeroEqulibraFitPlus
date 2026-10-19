class WorkoutSetResult {
  const WorkoutSetResult({
    required this.setNumber,
    this.repetitions = 0,
    this.loadKg,
    this.completed = false,
    this.completedAt,
  });

  final int setNumber;
  final int repetitions;
  final double? loadKg;
  final bool completed;
  final DateTime? completedAt;

  static const _unchanged = Object();

  WorkoutSetResult copyWith({
    int? repetitions,
    Object? loadKg = _unchanged,
    bool? completed,
    Object? completedAt = _unchanged,
  }) {
    return WorkoutSetResult(
      setNumber: setNumber,
      repetitions: repetitions ?? this.repetitions,
      loadKg: identical(loadKg, _unchanged) ? this.loadKg : loadKg as double?,
      completed: completed ?? this.completed,
      completedAt: identical(completedAt, _unchanged)
          ? this.completedAt
          : completedAt as DateTime?,
    );
  }

  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'repetitions': repetitions,
    'loadKg': loadKg,
    'completed': completed,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory WorkoutSetResult.fromJson(Map<String, dynamic> json) {
    return WorkoutSetResult(
      setNumber: (json['setNumber'] as num).toInt(),
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      loadKg: (json['loadKg'] as num?)?.toDouble(),
      completed: json['completed'] as bool? ?? false,
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
    );
  }
}
