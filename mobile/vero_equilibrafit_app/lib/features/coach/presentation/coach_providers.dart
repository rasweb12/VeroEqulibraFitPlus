import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_providers.dart';
import '../data/coach_repository.dart';

final coachRepositoryProvider = Provider.autoDispose<CoachRepository>((ref) {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) throw StateError('Uma sessão validada é necessária.');
  return CoachRepository(accessToken: session.accessToken);
});
