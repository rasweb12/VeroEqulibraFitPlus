import 'dart:convert';

import '../../../core/persistence/owner_scope.dart';
import '../../../core/persistence/secure_owner_store.dart';

/// Rest timing is independent of workout results and scoped to one session.
class WorkoutRestState {
  const WorkoutRestState({
    required this.sessionId,
    required this.exerciseName,
    required this.durationSeconds,
    required this.remainingSeconds,
    required this.paused,
    this.deadline,
  });

  final String sessionId;
  final String exerciseName;
  final int durationSeconds;
  final int remainingSeconds;
  final bool paused;
  final DateTime? deadline;

  int remainingAt(DateTime now) {
    if (paused || deadline == null) return remainingSeconds;
    final milliseconds = deadline!.difference(now).inMilliseconds;
    if (milliseconds <= 0) return 0;
    return (milliseconds / 1000).ceil();
  }

  WorkoutRestState pause(DateTime now) => WorkoutRestState(
    sessionId: sessionId,
    exerciseName: exerciseName,
    durationSeconds: durationSeconds,
    remainingSeconds: remainingAt(now),
    paused: true,
  );

  WorkoutRestState resume(DateTime now) => WorkoutRestState(
    sessionId: sessionId,
    exerciseName: exerciseName,
    durationSeconds: durationSeconds,
    remainingSeconds: remainingSeconds,
    paused: false,
    deadline: now.add(Duration(seconds: remainingSeconds)),
  );

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'exerciseName': exerciseName,
    'durationSeconds': durationSeconds,
    'remainingSeconds': remainingSeconds,
    'paused': paused,
    'deadline': deadline?.toIso8601String(),
  };

  factory WorkoutRestState.fromJson(Map<String, dynamic> json) =>
      WorkoutRestState(
        sessionId: json['sessionId'] as String,
        exerciseName: json['exerciseName'] as String? ?? '',
        durationSeconds: (json['durationSeconds'] as num).toInt(),
        remainingSeconds: (json['remainingSeconds'] as num).toInt(),
        paused: json['paused'] as bool? ?? false,
        deadline: DateTime.tryParse(json['deadline'] as String? ?? ''),
      );
}

class WorkoutRestStore {
  WorkoutRestStore({required String ownerId, required this.store})
    : _prefix = ownerScopedKey(ownerId, 'workout_rest_v1');

  final SecureOwnerStore store;
  final String _prefix;

  String _key(String sessionId) => '$_prefix:$sessionId';

  Future<WorkoutRestState?> read(String sessionId) async {
    final encoded = await store.read(_key(sessionId));
    if (encoded == null) return null;
    final state = WorkoutRestState.fromJson(
      Map<String, dynamic>.from(jsonDecode(encoded) as Map),
    );
    return state.sessionId == sessionId ? state : null;
  }

  Future<void> write(WorkoutRestState state) =>
      store.write(_key(state.sessionId), jsonEncode(state.toJson()));

  Future<void> clear(String sessionId) => store.delete(_key(sessionId));
}
