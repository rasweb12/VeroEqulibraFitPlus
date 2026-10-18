import 'package:isar/isar.dart';
import 'pending_operation.dart';
import 'sync_operation_queue.dart';

class OfflineOperationQueue implements SyncOperationQueue {
  const OfflineOperationQueue(this._isar);
  final Isar _isar;

  @override
  Future<void> enqueue({
    required String ownerId,
    required String idempotencyKey,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payloadJson,
    required String clientVersion,
  }) async {
    final existing = await _isar.pendingOperations
        .filter()
        .ownerIdEqualTo(ownerId)
        .and()
        .idempotencyKeyEqualTo(idempotencyKey)
        .findFirst();
    if (existing != null) return;
    final now = DateTime.now().toUtc();
    await _isar.writeTxn(
      () => _isar.pendingOperations.put(
        PendingOperation()
          ..ownerId = ownerId
          ..idempotencyKey = idempotencyKey
          ..entityType = entityType
          ..entityId = entityId
          ..operationType = operationType
          ..payloadJson = payloadJson
          ..clientVersion = clientVersion
          ..status = OfflineOperationStatus.pending.name
          ..createdAt = now
          ..updatedAt = now,
      ),
    );
  }

  @override
  Future<void> replacePayload({
    required String idempotencyKey,
    required String payloadJson,
  }) async {
    await _isar.writeTxn(() async {
      final operation = await _isar.pendingOperations
          .filter()
          .idempotencyKeyEqualTo(idempotencyKey)
          .findFirst();
      if (operation == null ||
          operation.status != OfflineOperationStatus.pending.name) {
        return;
      }
      operation.payloadJson = payloadJson;
      operation.updatedAt = DateTime.now().toUtc();
      operation.nextRetryAt = null;
      operation.lastErrorCode = null;
      await _isar.pendingOperations.put(operation);
    });
  }

  @override
  Future<List<PendingOperation>> due({
    required String ownerId,
    int limit = 50,
  }) async {
    final now = DateTime.now().toUtc();
    final operations = await _isar.pendingOperations
        .filter()
        .ownerIdEqualTo(ownerId)
        .and()
        .statusEqualTo(OfflineOperationStatus.pending.name)
        .sortByCreatedAt()
        .findAll();
    return operations
        .where(
          (operation) =>
              operation.nextRetryAt == null ||
              !operation.nextRetryAt!.isAfter(now),
        )
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<List<PendingOperation>> conflicts({required String ownerId}) => _isar
      .pendingOperations
      .filter()
      .ownerIdEqualTo(ownerId)
      .and()
      .statusEqualTo(OfflineOperationStatus.conflict.name)
      .sortByUpdatedAtDesc()
      .findAll();

  @override
  Future<void> markProcessing(int id) =>
      _change(id, OfflineOperationStatus.processing);

  @override
  Future<void> markCompleted(int id) async {
    await _isar.writeTxn(() async {
      final operation = await _isar.pendingOperations.get(id);
      if (operation == null) return;
      final now = DateTime.now().toUtc();
      operation.status = OfflineOperationStatus.synchronized.name;
      operation.completedAt = now;
      operation.updatedAt = now;
      operation.lastErrorCode = null;
      await _isar.pendingOperations.put(operation);
    });
  }

  @override
  Future<void> markConflict(int id) =>
      _change(id, OfflineOperationStatus.conflict);

  @override
  Future<void> retry(int id, {required String errorCode}) async {
    await _isar.writeTxn(() async {
      final operation = await _isar.pendingOperations.get(id);
      if (operation == null) return;
      operation.attemptCount += 1;
      operation.status = OfflineOperationStatus.pending.name;
      operation.lastErrorCode = errorCode;
      operation.updatedAt = DateTime.now().toUtc();
      // Exponential backoff with bounded deterministic jitter, capped at 15 min.
      final exponent = operation.attemptCount.clamp(0, 9);
      final seconds = (1 << exponent) + (id % 17);
      operation.nextRetryAt = operation.updatedAt.add(
        Duration(seconds: seconds.clamp(2, 900)),
      );
      await _isar.pendingOperations.put(operation);
    });
  }

  Future<void> _change(int id, OfflineOperationStatus status) async {
    await _isar.writeTxn(() async {
      final operation = await _isar.pendingOperations.get(id);
      if (operation == null) return;
      operation.status = status.name;
      operation.updatedAt = DateTime.now().toUtc();
      await _isar.pendingOperations.put(operation);
    });
  }
}
