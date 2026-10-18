import '../../features/auth/data/auth_repository.dart';
import '../persistence/secure_owner_store.dart';
import 'secure_operation_queue.dart';
import 'sync_push_client.dart';

/// Coordinates one push at a time after an authenticated session is restored.
/// Failures are represented in the encrypted queue and never block navigation.
class SyncService {
  SyncService({required this.store, SyncPushClient? client})
    : _client = client ?? SyncPushClient();

  final SecureOwnerStore store;
  final SyncPushClient _client;
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
}
