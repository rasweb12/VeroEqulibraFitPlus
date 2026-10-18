import '../../features/auth/data/auth_repository.dart';
import '../persistence/secure_owner_store.dart';
import '../../features/training/data/training_repository.dart';
import '../../features/nutrition/data/nutrition_repository.dart';
import 'secure_operation_queue.dart';
import 'sync_push_client.dart';
import 'sync_pull_client.dart';

/// Coordinates one push at a time after an authenticated session is restored.
/// Failures are represented in the encrypted queue and never block navigation.
class SyncService {
  SyncService({required this.store, SyncPushClient? client, SyncPullClient? pullClient})
    : _client = client ?? SyncPushClient(), _pullClient = pullClient ?? SyncPullClient();

  final SecureOwnerStore store;
  final SyncPushClient _client;
  final SyncPullClient _pullClient;
  Future<SyncPushResult>? _inFlight;

  Future<SyncPushResult> pushPending(AuthSession session) {
    final current = _inFlight;
    if (current != null) return current;
    final operation = _push(session);
    _inFlight = operation;
    operation.whenComplete(() {
      if (identical(_inFlight, operation)) _inFlight = null;
    });
    return operation;
  }

  Future<SyncPushResult> _push(AuthSession session) => _client.pushDue(
    queue: SecureOperationQueue(ownerId: session.userId, store: store),
    session: session,
  );

  Future<SyncPullResult> pullRemote(AuthSession session) async {
    final training = TrainingRepository(ownerId: session.userId, store: store);
    final nutrition = NutritionRepository(ownerId: session.userId, store: store);
    await training.load();
    await nutrition.load();
    final cursorKey = 'sync_pull_cursor_v1:${session.userId}';
    var cursor = await store.read(cursorKey);
    var applied = 0;
    for (var pageNumber = 0; pageNumber < 20; pageNumber++) {
      final page = await _pullClient.pull(session: session, cursor: cursor);
      if (!page.isSuccess) return SyncPullResult(applied: applied, reason: page.reason);
      for (final change in page.changes) {
        await training.applyRemote(change);
        await training.applyRemoteCustomExercise(change);
        await nutrition.applyRemote(change);
        applied++;
      }
      final next = page.nextCursor;
      if (next != null && next.isNotEmpty) {
        cursor = next;
        await store.write(cursorKey, next);
      }
      if (!page.hasMore) return SyncPullResult(applied: applied);
      if (next == null || next.isEmpty) return SyncPullResult(applied: applied, reason: 'invalid_sync_response');
    }
    return SyncPullResult(applied: applied, reason: 'pagination_limit');
  }
}

class SyncPullResult {
  const SyncPullResult({this.applied = 0, this.reason});
  final int applied;
  final String? reason;
}
