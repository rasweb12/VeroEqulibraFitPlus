import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/current_owner_provider.dart';
import '../persistence/preferences_provider.dart';
import 'pending_operation.dart';
import 'secure_operation_queue.dart';

final syncConflictsProvider = FutureProvider.autoDispose<List<PendingOperation>>((ref) {
  final ownerId = ref.watch(currentOwnerIdProvider);
  return SecureOperationQueue(ownerId: ownerId, store: ref.read(secureOwnerStoreProvider)).conflicts(ownerId: ownerId);
});
