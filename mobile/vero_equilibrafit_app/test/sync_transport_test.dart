import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vero_equilibrafit_app/core/offline/secure_operation_queue.dart';
import 'package:vero_equilibrafit_app/core/offline/sync_pull_client.dart';
import 'package:vero_equilibrafit_app/core/offline/sync_push_client.dart';
import 'package:vero_equilibrafit_app/core/persistence/secure_owner_store.dart';
import 'package:vero_equilibrafit_app/features/auth/data/auth_repository.dart';

void main() {
  const session = AuthSession(
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
    email: 'account@example.test',
    userId: 'account-a',
  );

  Future<SecureOperationQueue> queueWithOneOperation() async {
    final queue = SecureOperationQueue(
      ownerId: session.userId,
      store: MemorySecureOwnerStore(),
    );
    await queue.enqueue(
      ownerId: session.userId,
      idempotencyKey: 'meal-create-a',
      entityType: 'meal',
      entityId: 'a4f8a0d3-2ddf-4a8e-9a36-0b3d85b6755c',
      operationType: 'meal.create',
      payloadJson: '{"description":"Almoço"}',
      clientVersion: '1',
    );
    return queue;
  }

  test(
    'acknowledges accepted push operations only after the API response',
    () async {
      final queue = await queueWithOneOperation();
      final client = SyncPushClient(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.headers['authorization'], 'Bearer access-token');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(
            (body['operations'] as List).single['operationId'],
            'meal-create-a',
          );
          return http.Response(
            jsonEncode({
              'operations': [
                {'operationId': 'meal-create-a', 'status': 'accepted'},
              ],
            }),
            200,
          );
        }),
      );

      final result = await client.pushDue(queue: queue, session: session);

      expect(result.completed, 1);
      expect(await queue.due(ownerId: session.userId), isEmpty);
    },
    skip: AuthRepository.apiBaseUrl.isEmpty
        ? 'Exige API_BASE_URL de teste'
        : false,
  );

  test(
    'keeps an operation for retry when the sync endpoint is unavailable',
    () async {
      final queue = await queueWithOneOperation();
      final client = SyncPushClient(
        client: MockClient((_) => throw http.ClientException('offline')),
      );

      final result = await client.pushDue(queue: queue, session: session);

      expect(result.retried, 1);
      expect((await queue.due(ownerId: session.userId)), isEmpty);
    },
    skip: AuthRepository.apiBaseUrl.isEmpty
        ? 'Exige API_BASE_URL de teste'
        : false,
  );

  test(
    'reads authenticated remote changes and preserves the opaque cursor',
    () async {
      final client = SyncPullClient(
        client: MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.headers['authorization'], 'Bearer access-token');
          expect(request.url.queryParameters['cursor'], 'opaque-cursor');
          return http.Response(
            jsonEncode({
              'changes': [
                {
                  'entityType': 'meal',
                  'entityId': 'a4f8a0d3-2ddf-4a8e-9a36-0b3d85b6755c',
                  'action': 'upsert',
                  'revision': 1,
                  'changedAt': '2026-10-25T00:00:00Z',
                  'payload': {'description': 'Almoço'},
                },
              ],
              'nextCursor': 'next-opaque-cursor',
              'hasMore': false,
            }),
            200,
          );
        }),
      );

      final page = await client.pull(session: session, cursor: 'opaque-cursor');

      expect(page.isSuccess, isTrue);
      expect(page.changes, hasLength(1));
      expect(page.nextCursor, 'next-opaque-cursor');
    },
    skip: AuthRepository.apiBaseUrl.isEmpty
        ? 'Exige API_BASE_URL de teste'
        : false,
  );
}
