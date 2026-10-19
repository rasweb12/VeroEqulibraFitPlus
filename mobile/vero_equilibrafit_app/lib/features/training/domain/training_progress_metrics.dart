import '../domain/workout_session.dart';

class ExerciseProgress {
  const ExerciseProgress({
    required this.id,
    required this.name,
    required this.sessions,
    required this.maxKg,
    required this.volumeKg,
    required this.maxRepetitions,
  });
  final String id;
  final String name;
  final int sessions;
  final double? maxKg;
  final double volumeKg;
  final int maxRepetitions;
}

class ProgressPoint {
  const ProgressPoint(this.date, this.volumeKg);
  final DateTime date;
  final double volumeKg;
}

class TrainingProgressMetrics {
  TrainingProgressMetrics._({
    required this.sessions,
    required this.completedSets,
    required this.totalSets,
    required this.volumeKg,
    required this.exercises,
    required this.points,
  });

  final int sessions;
  final int completedSets;
  final int totalSets;
  final double volumeKg;
  final List<ExerciseProgress> exercises;
  final List<ProgressPoint> points;
  double get completionRate => totalSets == 0 ? 0 : completedSets / totalSets;

  static TrainingProgressMetrics calculate(
    Iterable<WorkoutSession> source, {
    int days = 0,
    DateTime? now,
  }) {
    final today = (now ?? DateTime.now()).toLocal();
    final sessions = source.where((s) {
      if (s.status != WorkoutSessionStatus.completed) {
        return false;
      }
      if (days == 0) {
        return true;
      }
      final age = today.difference(s.startedAt.toLocal());
      return !age.isNegative && age < Duration(days: days);
    }).toList()..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    var completed = 0;
    var total = 0;
    var volume = 0.0;
    final byExercise = <String, _Accum>{};
    final volumesByDate = <DateTime, double>{};
    for (final session in sessions) {
      final date = session.startedAt.toLocal();
      final keyDate = DateTime(date.year, date.month, date.day);
      var sessionVolume = 0.0;
      completed += session.completedSets;
      total += session.totalSets;
      for (final exercise in session.exercises) {
        final key = exercise.exerciseId;
        final acc = byExercise.putIfAbsent(
          key,
          () => _Accum(exercise.exerciseName),
        );
        acc.sessions.add(session.id);
        for (final set in exercise.sets) {
          if (!set.completed || set.repetitions <= 0) {
            continue;
          }
          if (set.repetitions > acc.maxRepetitions) {
            acc.maxRepetitions = set.repetitions;
          }
          final kg = set.loadKg;
          if (kg == null || !kg.isFinite || kg < 0) {
            continue;
          }
          if (acc.maxKg == null || kg > acc.maxKg!) {
            acc.maxKg = kg;
          }
          final setVolume = kg * set.repetitions;
          acc.volumeKg += setVolume;
          sessionVolume += setVolume;
        }
      }
      volume += sessionVolume;
      volumesByDate.update(
        keyDate,
        (old) => old + sessionVolume,
        ifAbsent: () => sessionVolume,
      );
    }
    final exerciseResults =
        byExercise.entries
            .map(
              (entry) => ExerciseProgress(
                id: entry.key,
                name: entry.value.name,
                sessions: entry.value.sessions.length,
                maxKg: entry.value.maxKg,
                volumeKg: entry.value.volumeKg,
                maxRepetitions: entry.value.maxRepetitions,
              ),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    final points =
        volumesByDate.entries.map((e) => ProgressPoint(e.key, e.value)).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return TrainingProgressMetrics._(
      sessions: sessions.length,
      completedSets: completed,
      totalSets: total,
      volumeKg: volume,
      exercises: exerciseResults,
      points: points,
    );
  }
}

class _Accum {
  _Accum(this.name);
  final String name;
  final Set<String> sessions = {};
  double? maxKg;
  double volumeKg = 0;
  int maxRepetitions = 0;
}
