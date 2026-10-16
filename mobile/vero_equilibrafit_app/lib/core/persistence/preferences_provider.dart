import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'secure_owner_store.dart';

/// Private health and training data must not use SharedPreferences.
final secureOwnerStoreProvider = Provider<SecureOwnerStore>(
  (ref) => PlatformSecureOwnerStore(),
);
