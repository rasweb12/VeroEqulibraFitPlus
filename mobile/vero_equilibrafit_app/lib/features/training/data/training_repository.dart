import 'dart:async';
import 'dart:convert';

import '../../../core/persistence/owner_scope.dart';
import '../../../core/persistence/secure_owner_store.dart';
import '../../../core/persistence/stable_id.dart';
import '../../../core/offline/sync_operation_queue.dart';

import '../domain/exercise.dart';
import '../domain/planned_exercise.dart';
import '../domain/training_plan.dart';

/// Local-first repository. Sync adapters can later enqueue the stable IDs.
class TrainingRepository {
  TrainingRepository({required this.ownerId, required this.store, this.outbox})
    : _storageKey = ownerScopedKey(ownerId, 'training_repository_v2_secure');
  final String ownerId;
  final String _storageKey;
  final SecureOwnerStore store;
  final SyncOperationQueue? outbox;
  final List<TrainingPlan> _plans = [];
  final List<Exercise> _customExercises = [];
  final Map<String, int> _customRevisions = {};
  static const catalog = <Exercise>[
    Exercise(
      id: 'incline-dumbbell',
      name: 'Supino inclinado com halteres',
      primaryMuscle: 'Peito',
      equipment: 'Halteres',
      demoVideoAsset: 'assets/videos/Supino Inclinado com Halteres.mp4',
      instructions: [
        'Ajuste o banco inclinado.',
        'Desça os halteres com controle.',
        'Empurre mantendo os pés apoiados.',
      ],
      safetyTips: ['Use uma carga que permita movimento estável.'],
    ),
    Exercise(
      id: 'squat',
      name: 'Agachamento com barra',
      primaryMuscle: 'Pernas',
      equipment: 'Barra',
      aliases: ['Agachamento livre'],
      demoVideoAsset: 'assets/videos/Agachamento com barra.mp4',
      instructions: [
        'Posicione a barra com conforto.',
        'Desça mantendo o tronco organizado.',
        'Suba distribuindo a força pelos pés.',
      ],
      safetyTips: ['Use travas e apoio quando necessário.'],
    ),
    Exercise(
      id: 'leg-press',
      name: 'Leg press',
      primaryMuscle: 'Pernas',
      equipment: 'Máquina',
      demoVideoAsset: 'assets/videos/Leg press na máquina.mp4',
      instructions: [
        'Ajuste o banco.',
        'Desça de forma controlada.',
        'Empurre sem travar os joelhos.',
      ],
    ),
    Exercise(
      id: 'lat-pulldown',
      name: 'Puxada frontal',
      primaryMuscle: 'Costas',
      equipment: 'Máquina',
      demoVideoAsset: 'assets/videos/Puxada com cabo.mp4',
      instructions: [
        'Mantenha o peito confortável.',
        'Puxe em direção à parte alta do peito.',
        'Retorne com controle.',
      ],
    ),
    Exercise(
      id: 'biceps-curl',
      name: 'Rosca direta',
      primaryMuscle: 'Bíceps',
      equipment: 'Barra',
      demoVideoAsset: 'assets/videos/Rosca Direta.mp4',
      instructions: [
        'Mantenha os cotovelos próximos ao corpo.',
        'Eleve sem balanço.',
        'Desça devagar.',
      ],
    ),
    Exercise(
      id: 'deadlift',
      name: 'Levantamento terra',
      primaryMuscle: 'Posterior de coxa',
      equipment: 'Barra',
      aliases: ['Terra'],
      instructions: [
        'Aproxime a barra do corpo.',
        'Mantenha a coluna estável.',
        'Suba com controle.',
      ],
    ),
    Exercise(
      id: 'shoulder-press',
      name: 'Desenvolvimento com halteres',
      primaryMuscle: 'Ombros',
      equipment: 'Halteres',
      aliases: ['Shoulder press'],
    ),
    Exercise(
      id: 'triceps-pushdown',
      name: 'Tríceps na polia',
      primaryMuscle: 'Tríceps',
      equipment: 'Cabo',
      aliases: ['Triceps pulley'],
    ),
    Exercise(
      id: 'seated-row',
      name: 'Remada baixa',
      primaryMuscle: 'Costas',
      equipment: 'Cabo',
      aliases: ['Remada sentada'],
    ),
    Exercise(
      id: 'calf-raise',
      name: 'Elevação de panturrilha',
      primaryMuscle: 'Panturrilhas',
      equipment: 'Máquina',
      aliases: ['Panturrilha em pé'],
    ),
  ];
  List<TrainingPlan> activePlans() => _plans
      .where((plan) => !plan.isDeleted && !plan.isArchived)
      .toList(growable: false);

  List<TrainingPlan> archivedPlans() => _plans
      .where((plan) => !plan.isDeleted && plan.isArchived)
      .toList(growable: false);

  void archive(String id) {
    final index = _plans.indexWhere((plan) => plan.id == id && !plan.isDeleted);

    if (index < 0) return;

    _plans[index] = _plans[index].copyWith(archivedAt: DateTime.now().toUtc());

    unawaited(_save());
  }

  void unarchive(String id) {
    final index = _plans.indexWhere((plan) => plan.id == id && !plan.isDeleted);

    if (index < 0) return;

    _plans[index] = _plans[index].copyWith(archivedAt: null);

    unawaited(_save());
  }

  List<Exercise> search(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return [...catalog, ..._customExercises];
    return [...catalog, ..._customExercises]
        .where(
          (exercise) =>
              _normalize(exercise.name).contains(normalized) ||
              exercise.aliases.any(
                (alias) => _normalize(alias).contains(normalized),
              ),
        )
        .toList(growable: false);
  }

  void softDelete(String id) {
    final index = _plans.indexWhere((plan) => plan.id == id);
    if (index < 0 || _plans[index].isDeleted) return;
    _plans[index] = _plans[index].copyWith(deletedAt: DateTime.now().toUtc());
    unawaited(_save());
    unawaited(_enqueueDelete(_plans[index].id));
  }

  void restore(String id) {
    final index = _plans.indexWhere((plan) => plan.id == id);

    if (index < 0 || !_plans[index].isDeleted) return;

    _plans[index] = _plans[index].copyWith(deletedAt: null);

    unawaited(_save());
  }

  TrainingPlan duplicate(String id) {
    final source = _plans.firstWhere(
      (plan) => plan.id == id && !plan.isDeleted,
    );

    final copy = TrainingPlan(
      id: newStableId(),
      name: '${source.name} (cópia)',
      objective: source.objective,
      exercises: List<PlannedExercise>.from(source.exercises),
      weekdays: List<int>.from(source.weekdays),
    );

    _plans.add(copy);
    unawaited(_save());
    unawaited(_enqueuePlan(copy));

    return copy;
  }

  TrainingPlan createPlan({
    required String name,
    required String objective,
    List<int> weekdays = const [],
  }) {
    final plan = TrainingPlan(
      id: newStableId(),
      name: name.trim(),
      objective: objective.trim(),
      exercises: const [],
      weekdays: weekdays,
    );
    _plans.add(plan);
    unawaited(_save());
    unawaited(_enqueuePlan(plan));
    return plan;
  }

  TrainingPlan? planById(String id) {
    for (final plan in _plans) {
      if (plan.id == id && !plan.isDeleted) return plan;
    }
    return null;
  }

  void addExerciseToPlan(String planId, String exerciseId) {
    final index = _plans.indexWhere(
      (plan) => plan.id == planId && !plan.isDeleted,
    );
    if (index < 0 ||
        _plans[index].exercises.any(
          (exercise) => exercise.exerciseId == exerciseId,
        )) {
      return;
    }
    final plan = _plans[index];
    _plans[index] = plan.copyWith(
      exercises: [
        ...plan.exercises,
        PlannedExercise(exerciseId: exerciseId),
      ],
    );
    unawaited(_save());
    unawaited(_enqueueUpdate(_plans[index]));
  }

  void removeExerciseFromPlan(String planId, String exerciseId) {
    final index = _plans.indexWhere(
      (plan) => plan.id == planId && !plan.isDeleted,
    );
    if (index < 0) return;
    final plan = _plans[index];
    _plans[index] = plan.copyWith(
      exercises: plan.exercises
          .where((exercise) => exercise.exerciseId != exerciseId)
          .toList(growable: false),
    );
    unawaited(_save());
    unawaited(_enqueueUpdate(_plans[index]));
  }

  void updatePlannedExercise(String planId, PlannedExercise updated) {
    final index = _plans.indexWhere(
      (plan) => plan.id == planId && !plan.isDeleted,
    );
    if (index < 0) return;
    final plan = _plans[index];
    _plans[index] = plan.copyWith(
      exercises: plan.exercises
          .map(
            (exercise) =>
                exercise.exerciseId == updated.exerciseId ? updated : exercise,
          )
          .toList(growable: false),
    );
    unawaited(_save());
    unawaited(_enqueueUpdate(_plans[index]));
  }

  Exercise? exerciseById(String id) {
    for (final exercise in [...catalog, ..._customExercises]) {
      if (exercise.id == id) return exercise;
    }
    return null;
  }

  Exercise createCustom({
    required String name,
    required String primaryMuscle,
    required String equipment,
  }) {
    final exercise = Exercise(
      id: newStableId(),
      name: name.trim(),
      primaryMuscle: primaryMuscle,
      equipment: equipment,
      isCustom: true,
    );
    _customExercises.add(exercise);
    unawaited(_save());
    unawaited(_enqueueCustomExercise(exercise));
    return exercise;
  }

  void deleteCustom(String id) {
    final index = _customExercises.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _customExercises.removeAt(index);
    unawaited(_save());
    unawaited(_enqueueCustomDelete(id));
  }

  void updateCustom({
    required String id,
    required String name,
    required String primaryMuscle,
    required String equipment,
  }) {
    final index = _customExercises.indexWhere((item) => item.id == id);
    if (index < 0) return;
    final updated = Exercise(
      id: id,
      name: name.trim(),
      primaryMuscle: primaryMuscle.trim(),
      equipment: equipment.trim(),
      isCustom: true,
    );
    _customExercises[index] = updated;
    unawaited(_save());
    final revision = _customRevisions[id] ?? 0;
    unawaited(_enqueueCustomUpdate(updated, revision));
  }

  Future<void> applyRemoteCustomExercise(Map<String, dynamic> change) async {
    if (change['entityType'] != 'custom-exercise') return;
    final id = change['entityId'] as String?;
    if (id == null) return;
    _customExercises.removeWhere((item) => item.id == id);
    if (change['action'] == 'upsert') {
      final payload = change['payload'];
      if (payload is Map<String, dynamic>) {
        _customExercises.add(
          Exercise(
            id: id,
            name: payload['name'] as String? ?? '',
            primaryMuscle: payload['primaryMuscle'] as String? ?? '',
            equipment: payload['equipment'] as String? ?? '',
            isCustom: true,
          ),
        );
        _customRevisions[id] = change['revision'] as int? ?? 0;
      }
    }
    await _save();
  }

  Future<void> load() async {
    final encoded = await store.read(_storageKey);
    if (encoded == null || encoded.isEmpty) return;
    try {
      final data = jsonDecode(encoded) as Map<String, dynamic>;
      for (final item in (data['plans'] as List<dynamic>? ?? const [])) {
        final plan = item as Map<String, dynamic>;
        _plans.add(
          TrainingPlan(
            id: plan['id'] as String,
            name: plan['name'] as String,
            objective: plan['objective'] as String,
            exercises: (plan['exercises'] as List<dynamic>? ?? const [])
                .map((raw) {
                  if (raw is String) return PlannedExercise(exerciseId: raw);
                  final exercise = raw as Map<String, dynamic>;
                  return PlannedExercise(
                    exerciseId: exercise['exerciseId'] as String,
                    sets: exercise['sets'] as int? ?? 3,
                    repetitions: exercise['repetitions'] as String? ?? '10',
                    targetLoadKg: (exercise['targetLoadKg'] as num?)
                        ?.toDouble(),
                    restSeconds: exercise['restSeconds'] as int? ?? 60,
                    notes: exercise['notes'] as String? ?? '',
                  );
                })
                .toList(growable: false),
            weekdays: List<int>.from(
              plan['weekdays'] as List<dynamic>? ?? const [],
            ),
            archivedAt: plan['archivedAt'] == null
                ? null
                : DateTime.tryParse(plan['archivedAt'] as String),
            deletedAt: plan['deletedAt'] == null
                ? null
                : DateTime.tryParse(plan['deletedAt'] as String),
            revision: plan['revision'] as int? ?? 0,
            updatedAt: plan['updatedAt'] == null
                ? null
                : DateTime.tryParse(plan['updatedAt'] as String),
          ),
        );
      }
      for (final item
          in (data['customExercises'] as List<dynamic>? ?? const [])) {
        final exercise = item as Map<String, dynamic>;
        _customExercises.add(
          Exercise(
            id: exercise['id'] as String,
            name: exercise['name'] as String,
            primaryMuscle: exercise['primaryMuscle'] as String,
            equipment: exercise['equipment'] as String,
            aliases: List<String>.from(
              exercise['aliases'] as List<dynamic>? ?? const [],
            ),
            isCustom: true,
          ),
        );
        _customRevisions[exercise['id'] as String] =
            exercise['revision'] as int? ?? 0;
      }
    } on FormatException {
      // A corrupt cache is ignored; no remote or historical data is removed.
    }
  }

  /// Applies a server change only when it is newer than the encrypted local
  /// copy. A tombstone is retained so a deleted plan cannot reappear.
  Future<void> applyRemote(Map<String, dynamic> change) async {
    if (change['entityType'] != 'training-plan') return;
    final id = change['entityId'] as String?;
    final revision = change['revision'] as int?;
    final changedAt = DateTime.tryParse(change['changedAt'] as String? ?? '');
    if (id == null || revision == null || changedAt == null) return;
    final index = _plans.indexWhere((plan) => plan.id == id);
    if (index >= 0 && _plans[index].revision > revision) return;
    if (index >= 0 && _plans[index].isDeleted && change['action'] != 'delete') {
      return;
    }
    if (change['action'] == 'delete') {
      final existing = index < 0
          ? TrainingPlan(id: id, name: '', objective: '', exercises: const [])
          : _plans[index];
      final deleted = existing.copyWith(
        deletedAt: changedAt.toUtc(),
        revision: revision,
        updatedAt: changedAt.toUtc(),
      );
      if (index < 0) {
        _plans.add(deleted);
      } else {
        _plans[index] = deleted;
      }
      await _save();
      return;
    }
    final payload = change['payload'];
    if (payload is! Map<String, dynamic>) return;
    final exercises = (payload['exercises'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => PlannedExercise(
            exerciseId: item['exerciseId'] as String? ?? '',
            sets: item['sets'] as int? ?? 3,
            repetitions: item['repetitions'] as String? ?? '10',
            targetLoadKg: (item['targetLoadKg'] as num?)?.toDouble(),
            restSeconds: item['restSeconds'] as int? ?? 60,
            notes: item['notes'] as String? ?? '',
          ),
        )
        .where((item) => item.exerciseId.isNotEmpty)
        .toList(growable: false);
    final remote = TrainingPlan(
      id: id,
      name: payload['name'] as String? ?? '',
      objective: payload['objective'] as String? ?? '',
      exercises: exercises,
      weekdays: index >= 0 ? _plans[index].weekdays : const [],
      archivedAt: index >= 0 ? _plans[index].archivedAt : null,
      revision: revision,
      updatedAt: changedAt.toUtc(),
    );
    if (index < 0) {
      _plans.add(remote);
    } else {
      _plans[index] = remote;
    }
    await _save();
  }

  Future<void> _save() async {
    final payload = {
      'plans': _plans
          .map(
            (plan) => {
              'id': plan.id,
              'name': plan.name,
              'objective': plan.objective,
              'weekdays': plan.weekdays,
              'exercises': plan.exercises
                  .map(
                    (exercise) => {
                      'exerciseId': exercise.exerciseId,
                      'sets': exercise.sets,
                      'repetitions': exercise.repetitions,
                      'targetLoadKg': exercise.targetLoadKg,
                      'restSeconds': exercise.restSeconds,
                      'notes': exercise.notes,
                    },
                  )
                  .toList(growable: false),
              'deletedAt': plan.deletedAt?.toIso8601String(),
              'archivedAt': plan.archivedAt?.toIso8601String(),
              'revision': plan.revision,
              'updatedAt': plan.updatedAt?.toIso8601String(),
            },
          )
          .toList(growable: false),
      'customExercises': _customExercises
          .map(
            (exercise) => {
              'id': exercise.id,
              'name': exercise.name,
              'primaryMuscle': exercise.primaryMuscle,
              'equipment': exercise.equipment,
              'aliases': exercise.aliases,
              'revision': _customRevisions[exercise.id] ?? 0,
            },
          )
          .toList(growable: false),
    };
    await store.write(_storageKey, jsonEncode(payload));
  }

  Future<void> _enqueuePlan(TrainingPlan plan) async {
    final queue = outbox;
    if (queue == null) return;
    await queue.enqueue(
      ownerId: ownerId,
      idempotencyKey: 'training-plan-create:${plan.id}',
      entityType: 'training-plan',
      entityId: plan.id,
      operationType: 'training-plan.create',
      clientVersion: '1.0.0',
      payloadJson: jsonEncode({
        'name': plan.name,
        'objective': plan.objective,
        'clientId': plan.id,
        'exercises': plan.exercises
            .asMap()
            .entries
            .map(
              (entry) => {
                'exerciseId': entry.value.exerciseId,
                'position': entry.key,
                'sets': entry.value.sets,
                'repetitions': entry.value.repetitions,
                'targetLoadKg': entry.value.targetLoadKg,
                'restSeconds': entry.value.restSeconds,
                'notes': entry.value.notes,
              },
            )
            .toList(growable: false),
      }),
    );
  }

  Future<void> _enqueueDelete(String id) async {
    final queue = outbox;
    if (queue == null || !_isUuid(id)) return;
    await queue.enqueue(
      ownerId: ownerId,
      idempotencyKey: 'training-plan-delete:$id',
      entityType: 'training-plan',
      entityId: id,
      operationType: 'training-plan.delete',
      clientVersion: '1.0.0',
      payloadJson: '{}',
    );
  }

  Future<void> _enqueueUpdate(TrainingPlan plan) async {
    final queue = outbox;
    if (queue == null || !_isUuid(plan.id) || plan.revision < 1) return;
    await queue.enqueue(
      ownerId: ownerId,
      idempotencyKey: 'training-plan-update:${plan.id}:${plan.revision}',
      entityType: 'training-plan',
      entityId: plan.id,
      operationType: 'training-plan.update',
      clientVersion: '1.0.0',
      payloadJson: jsonEncode({
        'baseRevision': plan.revision,
        'name': plan.name,
        'objective': plan.objective,
        'exercises': plan.exercises
            .asMap()
            .entries
            .map(
              (entry) => {
                'exerciseId': entry.value.exerciseId,
                'position': entry.key,
                'sets': entry.value.sets,
                'repetitions': entry.value.repetitions,
                'targetLoadKg': entry.value.targetLoadKg,
                'restSeconds': entry.value.restSeconds,
                'notes': entry.value.notes,
              },
            )
            .toList(growable: false),
      }),
    );
  }

  Future<void> _enqueueCustomExercise(Exercise exercise) async {
    final queue = outbox;
    if (queue == null || !_isUuid(exercise.id)) return;
    await queue.enqueue(
      ownerId: ownerId,
      idempotencyKey: 'custom-exercise-create:${exercise.id}',
      entityType: 'custom-exercise',
      entityId: exercise.id,
      operationType: 'custom-exercise.create',
      clientVersion: '1.0.0',
      payloadJson: jsonEncode({
        'name': exercise.name,
        'primaryMuscle': exercise.primaryMuscle,
        'equipment': exercise.equipment,
      }),
    );
  }

  Future<void> _enqueueCustomDelete(String id) async {
    final queue = outbox;
    if (queue == null || !_isUuid(id)) return;
    await queue.enqueue(
      ownerId: ownerId,
      idempotencyKey: 'custom-exercise-delete:$id',
      entityType: 'custom-exercise',
      entityId: id,
      operationType: 'custom-exercise.delete',
      clientVersion: '1.0.0',
      payloadJson: '{}',
    );
  }

  Future<void> _enqueueCustomUpdate(Exercise exercise, int revision) async {
    final queue = outbox;
    if (queue == null || !_isUuid(exercise.id)) return;
    final payload = jsonEncode({
      'name': exercise.name,
      'primaryMuscle': exercise.primaryMuscle,
      'equipment': exercise.equipment,
      'baseRevision': revision,
    });
    if (revision < 1) {
      await queue.replacePayload(
        idempotencyKey: 'custom-exercise-create:${exercise.id}',
        payloadJson: payload,
      );
      return;
    }
    await queue.enqueue(
      ownerId: ownerId,
      idempotencyKey: 'custom-exercise-update:${exercise.id}:$revision',
      entityType: 'custom-exercise',
      entityId: exercise.id,
      operationType: 'custom-exercise.update',
      clientVersion: '1.0.0',
      payloadJson: payload,
    );
  }

  bool _isUuid(String value) => RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value);

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp('[áàâãä]'), 'a')
      .replaceAll(RegExp('[éêë]'), 'e')
      .replaceAll(RegExp('[íîï]'), 'i')
      .replaceAll(RegExp('[óôõö]'), 'o')
      .replaceAll(RegExp('[úûü]'), 'u')
      .replaceAll('ç', 'c')
      .trim();
}
