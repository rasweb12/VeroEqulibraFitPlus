import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/persistence/preferences_provider.dart';
import '../../auth/presentation/current_owner_provider.dart';
import '../data/workout_session_repository.dart';

final workoutSessionRepositoryProvider = Provider<WorkoutSessionRepository>((
  ref,
) {
  return WorkoutSessionRepository(
    ownerId: ref.watch(currentOwnerIdProvider),
    store: ref.read(secureOwnerStoreProvider),
  );
});
