import 'package:isar/isar.dart';
import 'pending_operation.dart';

class OfflineOperationQueue {
  const OfflineOperationQueue(this._isar);
  final Isar _isar;

  Future<void> enqueue({required String ownerId, required String idempotencyKey, required String operationType, required String payloadJson}) async {
    final existing = await _isar.pendingOperations.filter().ownerIdEqualTo(ownerId).and().idempotencyKeyEqualTo(idempotencyKey).findFirst();
    if (existing != null) return;
    await _isar.writeTxn(() => _isar.pendingOperations.put(PendingOperation()..ownerId = ownerId..idempotencyKey = idempotencyKey..operationType = operationType..payloadJson = payloadJson..createdAt = DateTime.now().toUtc()));
  }

  Future<void> markCompleted(int id) async {
    await _isar.writeTxn(() async { final operation = await _isar.pendingOperations.get(id); if (operation != null) { operation.completedAt = DateTime.now().toUtc(); await _isar.pendingOperations.put(operation); } });
  }
}
