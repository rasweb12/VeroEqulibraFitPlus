import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_providers.dart';

/// Private feature state can only be created after AuthGate has verified a
/// session. Depending on this provider also disposes account-specific state
/// when the session changes.
final currentOwnerIdProvider = Provider<String>((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null || session.userId.trim().isEmpty) {
    throw StateError('A verified authenticated session is required.');
  }
  return session.userId;
});
