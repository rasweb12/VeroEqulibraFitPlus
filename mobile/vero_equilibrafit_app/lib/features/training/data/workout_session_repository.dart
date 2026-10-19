import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import '../../../core/persistence/owner_scope.dart';
import '../../../core/persistence/secure_owner_store.dart';
import '../../../core/persistence/stable_id.dart';

import '../domain/training_plan.dart';
import '../domain/workout_session.dart';
import '../domain/workout_exercise_result.dart';
import '../domain/workout_set_result.dart';

class WorkoutSessionRepository {
  WorkoutSessionRepository({required this.ownerId, required this.store})
    : _storageKey = ownerScopedKey(ownerId, 'workout_sessions_v1_secure');

  final String ownerId;
  final SecureOwnerStore store;
  final String _storageKey;

  final List<WorkoutSession> _sessions = [];

  Future<void>? _loadFuture;
  Future<void> _pendingSave = Future<void>.value();

  // Uma falha transitoria permite nova leitura sem apagar as sessoes.
  Future<void> load() => _loadFuture ??= _loadRecoverable();

  Future<void> _loadRecoverable() async {
    try {
      await _loadFromStore();
    } catch (_) {
      _loadFuture = null;
      rethrow;
    }
  }

  Future<void> _loadFromStore() async {
    final encoded = await store.read(_storageKey);
    if (encoded == null || encoded.isEmpty) return;

    final data = jsonDecode(encoded) as List<dynamic>;
    final loaded = data
        .map(
          (item) =>
              WorkoutSession.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();

    _sessions
      ..clear()
      ..addAll(loaded);
  }

  List<WorkoutSession> allSessions() =>
      List<WorkoutSession>.unmodifiable(_sessions);

  List<WorkoutSession> history() => _sessions
      .where((session) => session.status == WorkoutSessionStatus.completed)
      .toList(growable: false);

  WorkoutSession? byId(String id) {
    for (final session in _sessions) {
      if (session.id == id) return session;
    }
    return null;
  }

  Future<WorkoutSession> start({
    required TrainingPlan plan,
    required String Function(String exerciseId) exerciseName,
  }) async {
    await load();

    if (plan.isDeleted || plan.isArchived) {
      throw StateError('A ficha não está ativa.');
    }

    final existing = _sessions.where(
      (session) => session.planId == plan.id && !session.isFinished,
    );

    if (existing.isNotEmpty) return existing.first;

    final session = WorkoutSession(
      id: newStableId(),
      planId: plan.id,
      planName: plan.name,
      startedAt: DateTime.now().toUtc(),
      exercises: [
        for (final planned in plan.exercises)
          WorkoutExerciseResult(
            exerciseId: planned.exerciseId,
            exerciseName: exerciseName(planned.exerciseId),
            notes: planned.notes,
            sets: [
              for (var i = 1; i <= planned.sets; i++)
                WorkoutSetResult(setNumber: i, loadKg: planned.targetLoadKg),
            ],
          ),
      ],
    );

    _sessions.add(session);
    await _save();

    return session;
  }

  Future<void> update(WorkoutSession session) async {
    await load();

    final index = _sessions.indexWhere((item) => item.id == session.id);
    if (index < 0) throw StateError('Sessão não encontrada.');

    if (_sessions[index].isFinished) {
      throw StateError('Esta sessão já foi encerrada.');
    }

    if (session.id != _sessions[index].id ||
        session.planId != _sessions[index].planId) {
      throw StateError('Identificação da sessão inválida.');
    }

    _sessions[index] = session;
    await _save();
  }

  Future<void> finish(String id, {String notes = ''}) async {
    await load();

    final index = _sessions.indexWhere((item) => item.id == id);

    if (index < 0) throw StateError('Sessão não encontrada.');

    final current = _sessions[index];
    if (current.isFinished) return;

    _sessions[index] = current.copyWith(
      status: WorkoutSessionStatus.completed,
      finishedAt: DateTime.now().toUtc(),
      notes: notes,
    );

    await _save();
  }

  Future<void> _save() {
    final snapshot = jsonEncode(
      _sessions.map((session) => session.toJson()).toList(),
    );

    final operation = _pendingSave.then(
      (_) => store.write(_storageKey, snapshot),
    );

    _pendingSave = operation.catchError((Object error, StackTrace stack) {
      developer.log(
        'Erro ao persistir sessão',
        name: 'WorkoutSessionRepository',
        error: error,
        stackTrace: stack,
      );
    });

    return operation;
  }
}
