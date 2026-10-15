/// Namespaces local cache entries by the authenticated account.
///
/// Legacy keys are deliberately never read: without a recorded owner they must
/// not be attached to the next person who signs in on a shared device.
String ownerScopedKey(String ownerId, String resource) {
  if (ownerId.trim().isEmpty) {
    throw ArgumentError.value(ownerId, 'ownerId', 'An authenticated owner is required.');
  }
  return 'owner:$ownerId:$resource';
}
