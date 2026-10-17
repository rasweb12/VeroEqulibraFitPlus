import 'dart:convert';

import '../persistence/owner_scope.dart';
import '../persistence/secure_owner_store.dart';
import 'pending_operation.dart';
import 'sync_operation_queue.dart';

/// Cifred outbox backed by the OS keystore. It avoids placing health payloads
/// in the installed Isar version, which lacks encrypted database support.
class SecureOperationQueue implements SyncOperationQueue {
  SecureOperationQueue({required this.ownerId, required this.store})
    : _key = ownerScopedKey(ownerId, 'sync_outbox_v1_secure');

  final String ownerId;
  final SecureOwnerStore store;
  final String _key;
  final List<PendingOperation> _operations = [];
  bool _loaded = false;

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
    _verifyOwner(ownerId);
    await _load();
    if (_operations.any((item) => item.idempotencyKey == idempotencyKey)) {
      return;
    }
    final now = DateTime.now().toUtc();
    _operations.add(
      PendingOperation()
        ..id = now.microsecondsSinceEpoch
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
    );
    await _save();
  }

  @override
  Future<List<PendingOperation>> due({
    required String ownerId,
    int limit = 50,
  }) async {
    _verifyOwner(ownerId);
    await _load();
    final now = DateTime.now().toUtc();
    return _operations
        .where(
          (item) =>
              item.status == OfflineOperationStatus.pending.name &&
              (item.nextRetryAt == null || !item.nextRetryAt!.isAfter(now)),
        )
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<void> markProcessing(int id) =>
      _change(id, OfflineOperationStatus.processing);

  @override
  Future<void> markCompleted(int id) async {
    await _load();
    final item = _find(id);
    if (item == null) return;
    final now = DateTime.now().toUtc();
    item.status = OfflineOperationStatus.synchronized.name;
    item.completedAt = now;
    item.updatedAt = now;
    item.lastErrorCode = null;
    await _save();
  }

  @override
  Future<void> markConflict(int id) =>
      _change(id, OfflineOperationStatus.conflict);

  @override
  Future<void> retry(int id, {required String errorCode}) async {
    await _load();
    final item = _find(id);
    if (item == null) return;
    item.attemptCount += 1;
    item.status = OfflineOperationStatus.pending.name;
    item.lastErrorCode = errorCode;
    item.updatedAt = DateTime.now().toUtc();
    final seconds = (1 << item.attemptCount.clamp(0, 9)) + (id % 17);
    item.nextRetryAt = item.updatedAt.add(
      Duration(seconds: seconds.clamp(2, 900)),
    );
    await _save();
  }

  Future<void> _change(int id, OfflineOperationStatus status) async {
    await _load();
    final item = _find(id);
    if (item == null) return;
    item.status = status.name;
    item.updatedAt = DateTime.now().toUtc();
    await _save();
  }

  PendingOperation? _find(int id) {
    for (final item in _operations) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _load() async {
    if (_loaded) return;
    _loaded = true;
    final raw = await store.read(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      for (final value in jsonDecode(raw) as List<dynamic>) {
        final item = value as Map<String, dynamic>;
        final createdAt = DateTime.tryParse(item['createdAt'] as String? ?? '');
        final updatedAt = DateTime.tryParse(item['updatedAt'] as String? ?? '');
        if (createdAt == null || updatedAt == null) {
          continue;
        }
        _operations.add(
          PendingOperation()
            ..id = item['id'] as int
            ..ownerId = ownerId
            ..idempotencyKey = item['idempotencyKey'] as String
            ..entityType = item['entityType'] as String
            ..entityId = item['entityId'] as String
            ..operationType = item['operationType'] as String
            ..payloadJson = item['payloadJson'] as String
            ..clientVersion = item['clientVersion'] as String
            ..status = item['status'] as String
            ..createdAt = createdAt
            ..updatedAt = updatedAt
            ..attemptCount = item['attemptCount'] as int? ?? 0
            ..nextRetryAt = DateTime.tryParse(
              item['nextRetryAt'] as String? ?? '',
            )
            ..lastErrorCode = item['lastErrorCode'] as String?
            ..completedAt = DateTime.tryParse(
              item['completedAt'] as String? ?? '',
            ),
        );
      }
    } on FormatException {
      // A corrupt encrypted cache is ignored; no account data is reassigned.
    }
  }

  Future<void> _save() => store.write(
    _key,
    jsonEncode(
      _operations
          .map(
            (item) => {
              'id': item.id,
              'idempotencyKey': item.idempotencyKey,
              'entityType': item.entityType,
              'entityId': item.entityId,
              'operationType': item.operationType,
              'payloadJson': item.payloadJson,
              'clientVersion': item.clientVersion,
              'status': item.status,
              'createdAt': item.createdAt.toIso8601String(),
              'updatedAt': item.updatedAt.toIso8601String(),
              'attemptCount': item.attemptCount,
              'nextRetryAt': item.nextRetryAt?.toIso8601String(),
              'lastErrorCode': item.lastErrorCode,
              'completedAt': item.completedAt?.toIso8601String(),
            },
          )
          .toList(growable: false),
    ),
  );

  void _verifyOwner(String requestedOwnerId) {
    if (requestedOwnerId != ownerId) {
      throw StateError('Acesso à outbox de outra conta foi negado.');
    }
  }
}
