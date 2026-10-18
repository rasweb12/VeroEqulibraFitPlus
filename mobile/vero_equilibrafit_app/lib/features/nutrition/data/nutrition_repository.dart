import 'dart:async';
import 'dart:convert';

import '../../../core/persistence/owner_scope.dart';
import '../../../core/persistence/secure_owner_store.dart';
import '../../../core/persistence/stable_id.dart';
import '../../../core/offline/sync_operation_queue.dart';

import '../domain/meal_entry.dart';

class NutritionRepository {
  NutritionRepository({
    required this.ownerId,
    required this._store,
    this.outbox,
  }) : _storageKey = ownerScopedKey(ownerId, 'nutrition_repository_v2_secure');
  final String ownerId;
  final String _storageKey;
  final SecureOwnerStore _store;
  final SyncOperationQueue? outbox;
  final List<MealEntry> _entries = [];

  List<MealEntry> entries() => List.unmodifiable(_entries.reversed);

  void add({
    required String name,
    required String mealType,
    required String notes,
    double? estimatedCalories,
    double? proteinGrams,
    double? carbohydrateGrams,
    double? fatGrams,
    DateTime? recordedAt,
  }) {
    final entry = MealEntry(
      id: newStableId(),
      name: name.trim(),
      mealType: mealType,
      notes: notes.trim(),
      recordedAt: recordedAt ?? DateTime.now(),
      estimatedCalories: estimatedCalories,
      proteinGrams: proteinGrams,
      carbohydrateGrams: carbohydrateGrams,
      fatGrams: fatGrams,
    );
    _entries.add(entry);
    unawaited(_save());
    unawaited(_enqueueMeal(entry));
  }

  void delete(String id) {
    final existing = _entries.where((entry) => entry.id == id).firstOrNull;
    _entries.removeWhere((entry) => entry.id == id);
    unawaited(_save());
    if (existing != null) unawaited(_enqueueDelete(existing.id));
  }

  void update(MealEntry entry) {
    final index = _entries.indexWhere((item) => item.id == entry.id);
    if (index < 0) return;
    _entries[index] = entry;
    unawaited(_save());
    unawaited(_enqueueUpdate(entry));
  }

  Future<void> load() async {
    final encoded = await _store.read(_storageKey);
    if (encoded == null || encoded.isEmpty) return;
    try {
      final entries = jsonDecode(encoded) as List<dynamic>;
      for (final item in entries) {
        final entry = item as Map<String, dynamic>;
        final recordedAt = DateTime.tryParse(entry['recordedAt'] as String);
        if (recordedAt == null) continue;
        _entries.add(
          MealEntry(
            id: entry['id'] as String,
            name: entry['name'] as String,
            mealType: entry['mealType'] as String,
            notes: entry['notes'] as String? ?? '',
            recordedAt: recordedAt,
            estimatedCalories: (entry['estimatedCalories'] as num?)?.toDouble(),
            proteinGrams: (entry['proteinGrams'] as num?)?.toDouble(),
            carbohydrateGrams: (entry['carbohydrateGrams'] as num?)?.toDouble(),
            fatGrams: (entry['fatGrams'] as num?)?.toDouble(),
            revision: entry['revision'] as int? ?? 0,
            updatedAt: entry['updatedAt'] == null
                ? null
                : DateTime.tryParse(entry['updatedAt'] as String),
          ),
        );
      }
    } on FormatException {
      // Ignore only the local cache if it cannot be decoded.
    }
  }

  /// Keeps the newest server revision and never exposes another owner's data.
  Future<void> applyRemote(Map<String, dynamic> change) async {
    if (change['entityType'] != 'meal') return;
    final id = change['entityId'] as String?;
    final revision = change['revision'] as int?;
    final changedAt = DateTime.tryParse(change['changedAt'] as String? ?? '');
    if (id == null || revision == null || changedAt == null) return;
    final index = _entries.indexWhere((entry) => entry.id == id);
    if (index >= 0 && _entries[index].revision > revision) return;
    if (change['action'] == 'delete') {
      if (index >= 0) {
        _entries.removeAt(index);
      }
      await _save();
      return;
    }
    final payload = change['payload'];
    if (payload is! Map<String, dynamic>) return;
    final consumedAt = DateTime.tryParse(payload['consumedAt'] as String? ?? '');
    if (consumedAt == null) return;
    final existing = index < 0 ? null : _entries[index];
    final remote = MealEntry(
      id: id,
      name: payload['description'] as String? ?? '',
      mealType: existing?.mealType ?? 'Refeição',
      notes: existing?.notes ?? '',
      recordedAt: consumedAt.toLocal(),
      estimatedCalories: (payload['estimatedCalories'] as num?)?.toDouble(),
      proteinGrams: (payload['proteinGrams'] as num?)?.toDouble(),
      carbohydrateGrams: (payload['carbohydrateGrams'] as num?)?.toDouble(),
      fatGrams: (payload['fatGrams'] as num?)?.toDouble(),
      revision: revision,
      updatedAt: changedAt.toUtc(),
    );
    if (index < 0) {
      _entries.add(remote);
    } else {
      _entries[index] = remote;
    }
    await _save();
  }

  Future<void> _save() => _store.write(
    _storageKey,
    jsonEncode(
      _entries
          .map(
            (entry) => {
              'id': entry.id,
              'name': entry.name,
              'mealType': entry.mealType,
              'notes': entry.notes,
              'recordedAt': entry.recordedAt.toIso8601String(),
              'estimatedCalories': entry.estimatedCalories,
              'proteinGrams': entry.proteinGrams,
              'carbohydrateGrams': entry.carbohydrateGrams,
              'fatGrams': entry.fatGrams,
              'revision': entry.revision,
              'updatedAt': entry.updatedAt?.toIso8601String(),
            },
          )
          .toList(growable: false),
    ),
  );

  Future<void> _enqueueMeal(MealEntry entry) async {
    final queue = outbox;
    if (queue == null) return;
    await queue.enqueue(
      ownerId: ownerId,
      idempotencyKey: 'meal-create:${entry.id}',
      entityType: 'meal',
      entityId: entry.id,
      operationType: 'meal.create',
      clientVersion: '1.0.0',
      payloadJson: jsonEncode({
        'description': entry.name,
        'consumedAt': entry.recordedAt.toUtc().toIso8601String(),
        'estimatedCalories': entry.estimatedCalories,
        'proteinGrams': entry.proteinGrams,
        'carbohydrateGrams': entry.carbohydrateGrams,
        'fatGrams': entry.fatGrams,
        'clientId': entry.id,
      }),
    );
  }

  Future<void> _enqueueDelete(String id) async {
    final queue = outbox;
    if (queue == null || !_isUuid(id)) return;
    await queue.enqueue(
      ownerId: ownerId,
      idempotencyKey: 'meal-delete:$id',
      entityType: 'meal',
      entityId: id,
      operationType: 'meal.delete',
      clientVersion: '1.0.0',
      payloadJson: '{}',
    );
  }

  Future<void> _enqueueUpdate(MealEntry entry) async {
    final queue = outbox;
    if (queue == null || !_isUuid(entry.id) || entry.revision < 1) return;
    await queue.enqueue(
      ownerId: ownerId,
      idempotencyKey: 'meal-update:${entry.id}:${entry.revision}',
      entityType: 'meal', entityId: entry.id, operationType: 'meal.update',
      clientVersion: '1.0.0',
      payloadJson: jsonEncode({
        'baseRevision': entry.revision, 'description': entry.name,
        'consumedAt': entry.recordedAt.toUtc().toIso8601String(),
        'estimatedCalories': entry.estimatedCalories, 'proteinGrams': entry.proteinGrams,
        'carbohydrateGrams': entry.carbohydrateGrams, 'fatGrams': entry.fatGrams,
      }),
    );
  }

  bool _isUuid(String value) => RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value);
}
