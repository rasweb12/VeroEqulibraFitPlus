import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/preferences_provider.dart';
import 'sync_service.dart';

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(store: ref.read(secureOwnerStoreProvider)),
);
