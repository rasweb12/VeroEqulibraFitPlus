import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(),
);
final authSessionProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>(
      (ref) => AuthController(ref.read(authRepositoryProvider)),
    );

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._repository) : super(const AsyncValue.loading()) {
    _restore();
  }
  final AuthRepository _repository;
  Future<void> _restore() async {
    state = AsyncValue.data(await _repository.restore());
  }

  Future<void> login(String email, String password) =>
      _perform(() => _repository.login(email, password));
  Future<void> register(String email, String password, String? displayName) =>
      _perform(() => _repository.register(email, password, displayName));
  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> _perform(Future<AuthSession> Function() action) async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await action());
    } on Object catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
