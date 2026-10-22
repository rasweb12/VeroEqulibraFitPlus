import 'dart:async';

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
  Future<void> _tail = Future.value();
  int _epoch = 0;

  Future<T> _serialize<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _tail = _tail.then((_) async {
      try {
        result.complete(await action());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  Future<void> _restore() async {
    final epoch = _epoch;
    await _serialize(() async {
      final session = await _repository.restore();
      if (mounted && epoch == _epoch) state = AsyncValue.data(session);
    });
  }

  /// Renova uma vez por token rejeitado e não reaproveita outra conta.
  Future<AuthSession?> refreshAfterUnauthorized(AuthSession rejected) {
    final epoch = _epoch;
    return _serialize(() async {
      if (!mounted || epoch != _epoch) return null;
      final current = state.valueOrNull;
      if (current?.userId != rejected.userId) {
        return null;
      }
      if (current!.accessToken != rejected.accessToken) return current;
      final refreshed = await _repository.refresh();
      if (!mounted || epoch != _epoch || refreshed.userId != rejected.userId) {
        return null;
      }
      state = AsyncValue.data(refreshed);
      return refreshed;
    });
  }

  Future<void> login(String email, String password) =>
      _perform(() => _repository.login(email, password));
  Future<void> register(
    String email,
    String password,
    String? displayName,
  ) async {
    final epoch = ++_epoch;
    state = const AsyncValue.loading();
    return _serialize(() async {
      try {
        await _repository.register(email, password, displayName);
        if (mounted && epoch == _epoch) state = const AsyncValue.data(null);
      } on Object catch (error, stackTrace) {
        if (mounted && epoch == _epoch) {
          state = AsyncValue.error(error, stackTrace);
        }
        rethrow;
      }
    });
  }

  Future<void> logout() async {
    final epoch = ++_epoch;
    state = const AsyncValue.loading();
    await _serialize(() async {
      try {
        await _repository.logout();
        if (mounted && epoch == _epoch) state = const AsyncValue.data(null);
      } on Object catch (error, stackTrace) {
        if (mounted && epoch == _epoch) {
          state = AsyncValue.error(error, stackTrace);
        }
        rethrow;
      }
    });
  }

  Future<void> deleteAccount() async {
    final epoch = ++_epoch;
    state = const AsyncValue.loading();
    return _serialize(() async {
      try {
        await _repository.deleteAccount();
        if (mounted && epoch == _epoch) state = const AsyncValue.data(null);
      } on Object catch (error, stackTrace) {
        if (mounted && epoch == _epoch) {
          state = AsyncValue.error(error, stackTrace);
        }
        rethrow;
      }
    });
  }

  Future<void> _perform(Future<AuthSession> Function() action) async {
    final epoch = ++_epoch;
    state = const AsyncValue.loading();
    await _serialize(() async {
      try {
        final session = await action();
        if (mounted && epoch == _epoch) state = AsyncValue.data(session);
      } on Object catch (error, stackTrace) {
        if (mounted && epoch == _epoch) {
          state = AsyncValue.error(error, stackTrace);
        }
      }
    });
  }
}
