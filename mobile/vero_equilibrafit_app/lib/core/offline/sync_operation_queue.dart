import 'pending_operation.dart';

abstract interface class SyncOperationQueue {
  Future<void> enqueue({
    required String ownerId,
    required String idempotencyKey,
    required String entityType,
    required String entityId,
    required String operationType,
    required String payloadJson,
    required String clientVersion,
  });
  Future<List<PendingOperation>> due({required String ownerId, int limit = 50});
  Future<void> markProcessing(int id);
  Future<void> markCompleted(int id);
  Future<void> markConflict(int id);
  Future<void> retry(int id, {required String errorCode});
}

enum OfflineOperationStatus {
  pending,
  processing,
  synchronized,
  conflict,
  failed,
}
