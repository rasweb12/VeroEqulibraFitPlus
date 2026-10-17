/// Namespaces local cache entries by the authenticated account.
///
/// Legacy keys are deliberately never read: without a recorded owner they must
/// not be attached to the next person who signs in on a shared device.
String ownerScopedKey(String ownerId, String resource) {
  if (ownerId.trim().isEmpty) {
    throw ArgumentError.value(
      ownerId,
      'ownerId',
      'An authenticated owner is required.',
    );
  }
  return 'owner:$ownerId:$resource';
}

/// All currently persisted private resources. Keeping this list in one place
/// makes account deletion explicit and avoids deleting another account's data
/// from a shared device.
Iterable<String> ownerPrivateKeys(String ownerId) sync* {
  for (final resource in const [
    'training_repository_v2_secure',
    'nutrition_repository_v2_secure',
    'body_measurements_v2_secure',
    'habits_v3_secure',
    'sync_outbox_v1_secure',
  ]) {
    yield ownerScopedKey(ownerId, resource);
  }
}
