import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_repository.dart';
import 'offline_operation_queue.dart';
import 'pending_operation.dart';

/// Sends only persisted outbox entries. It never considers a network response
/// successful until the server returns `accepted` or the same idempotency key
/// is acknowledged as `duplicate`.
class SyncPushClient {
  SyncPushClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<SyncPushResult> pushDue({
    required OfflineOperationQueue queue,
    required AuthSession session,
    int limit = 50,
  }) async {
    if (AuthRepository.apiBaseUrl.isEmpty) {
      return const SyncPushResult.skipped('api_not_configured');
    }
    final due = await queue.due(ownerId: session.userId, limit: limit);
    if (due.isEmpty) return const SyncPushResult.empty();

    final sendable = <_QueuedOperation>[];
    for (final operation in due) {
      if (!_isUuid(operation.entityId)) {
        await queue.markConflict(operation.id);
        continue;
      }
      try {
        final payload = jsonDecode(operation.payloadJson);
        if (payload is! Map<String, dynamic>) {
          await queue.markConflict(operation.id);
          continue;
        }
        await queue.markProcessing(operation.id);
        sendable.add(_QueuedOperation(operation, payload));
      } on FormatException {
        await queue.markConflict(operation.id);
      }
    }
    if (sendable.isEmpty) {
      return SyncPushResult(processed: due.length, conflicted: due.length);
    }

    try {
      final response = await _client
          .post(
            Uri.parse('${AuthRepository.apiBaseUrl}/api/v1/sync/push'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session.accessToken}',
            },
            body: jsonEncode({
              'operations': sendable
                  .map(
                    (entry) => {
                      'operationId': entry.operation.idempotencyKey,
                      'entityType': entry.operation.entityType,
                      'entityId': entry.operation.entityId,
                      'operationType': entry.operation.operationType,
                      'payload': entry.payload,
                      'clientVersion': entry.operation.clientVersion,
                    },
                  )
                  .toList(growable: false),
            }),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        final code = response.statusCode == 401 || response.statusCode == 403
            ? 'auth_required'
            : 'server_${response.statusCode}';
        for (final entry in sendable) {
          await queue.retry(entry.operation.id, errorCode: code);
        }
        return SyncPushResult(processed: due.length, retried: sendable.length);
      }
      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final results = <String, Map<String, dynamic>>{};
      for (final result
          in responseBody['operations'] as List<dynamic>? ?? const []) {
        if (result is! Map<String, dynamic>) continue;
        final operationId = result['operationId'];
        if (operationId is String && operationId.isNotEmpty) {
          results[operationId] = result;
        }
      }
      var completed = 0;
      var conflicted = 0;
      var retried = 0;
      for (final entry in sendable) {
        final status =
            results[entry.operation.idempotencyKey]?['status'] as String?;
        if (status == 'accepted' || status == 'duplicate') {
          await queue.markCompleted(entry.operation.id);
          completed++;
        } else if (status == 'conflict' || status == 'rejected') {
          await queue.markConflict(entry.operation.id);
          conflicted++;
        } else {
          await queue.retry(
            entry.operation.id,
            errorCode: 'invalid_sync_response',
          );
          retried++;
        }
      }
      return SyncPushResult(
        processed: due.length,
        completed: completed,
        conflicted: conflicted,
        retried: retried,
      );
    } on Object {
      for (final entry in sendable) {
        await queue.retry(entry.operation.id, errorCode: 'network_unavailable');
      }
      return SyncPushResult(processed: due.length, retried: sendable.length);
    }
  }

  bool _isUuid(String value) => RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value);
}

class _QueuedOperation {
  const _QueuedOperation(this.operation, this.payload);
  final PendingOperation operation;
  final Map<String, dynamic> payload;
}

class SyncPushResult {
  const SyncPushResult({
    this.processed = 0,
    this.completed = 0,
    this.conflicted = 0,
    this.retried = 0,
    this.reason,
  });
  const SyncPushResult.empty() : this();
  const SyncPushResult.skipped(String reason) : this(reason: reason);

  final int processed;
  final int completed;
  final int conflicted;
  final int retried;
  final String? reason;
}
