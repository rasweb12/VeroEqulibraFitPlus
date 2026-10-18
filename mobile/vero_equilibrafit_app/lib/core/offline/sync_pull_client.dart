import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../features/auth/data/auth_repository.dart';

/// Reads owner-scoped remote changes. The cursor is opaque and is persisted by
/// [SyncService]; neither it nor responses are logged because they may contain
/// health and training data.
class SyncPullClient {
  SyncPullClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<SyncPullPage> pull({
    required AuthSession session,
    String? cursor,
  }) async {
    if (AuthRepository.apiBaseUrl.isEmpty) {
      return const SyncPullPage.skipped('api_not_configured');
    }
    final uri = Uri.parse('${AuthRepository.apiBaseUrl}/api/v1/sync/pull')
        .replace(queryParameters: {
      'limit': '50',
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    });
    try {
      final response = await _client.get(
        uri,
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        return SyncPullPage.failed('server_${response.statusCode}');
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return const SyncPullPage.failed('invalid_sync_response');
      }
      final rawChanges = body['changes'];
      if (rawChanges is! List<dynamic>) {
        return const SyncPullPage.failed('invalid_sync_response');
      }
      return SyncPullPage(
        changes: rawChanges.whereType<Map<String, dynamic>>().toList(),
        nextCursor: body['nextCursor'] as String?,
        hasMore: body['hasMore'] as bool? ?? false,
      );
    } on Object {
      return const SyncPullPage.failed('network_unavailable');
    }
  }
}

class SyncPullPage {
  const SyncPullPage({this.changes = const [], this.nextCursor, this.hasMore = false, this.reason});
  const SyncPullPage.skipped(String reason) : this(reason: reason);
  const SyncPullPage.failed(String reason) : this(reason: reason);

  final List<Map<String, dynamic>> changes;
  final String? nextCursor;
  final bool hasMore;
  final String? reason;
  bool get isSuccess => reason == null;
}
