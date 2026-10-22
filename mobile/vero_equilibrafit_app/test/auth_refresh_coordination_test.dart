import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vero_equilibrafit_app/features/auth/data/auth_repository.dart';
import 'package:vero_equilibrafit_app/features/auth/presentation/auth_providers.dart';

AuthSession session(String owner, String token) => AuthSession(
  accessToken: token,
  refreshToken: 'refresh-$token',
  email: '$owner@example.test',
  userId: owner,
);

class FakeAuthRepository extends AuthRepository {
  AuthSession? stored = session('a', 'old');
  final refreshStarted = Completer<void>();
  final refreshResult = Completer<AuthSession>();
  int refreshCalls = 0;

  @override
  Future<AuthSession?> restore() async => stored;

  @override
  Future<AuthSession> refresh() async {
    refreshCalls++;
    if (!refreshStarted.isCompleted) refreshStarted.complete();
    final result = await refreshResult.future;
    stored = result;
    return result;
  }

  @override
  Future<void> logout() async {
    stored = null;
  }

  @override
  Future<AuthSession> login(String email, String password) async {
    stored = session('b', 'new-b');
    return stored!;
  }
}

void main() {
  test('renova uma vez quando duas chamadas rejeitam o mesmo token', () async {
    final repo = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    final controller = container.read(authSessionProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final old = container.read(authSessionProvider).valueOrNull!;
    final first = controller.refreshAfterUnauthorized(old);
    final second = controller.refreshAfterUnauthorized(old);
    await repo.refreshStarted.future;
    repo.refreshResult.complete(session('a', 'new'));
    expect((await first)?.accessToken, 'new');
    expect((await second)?.accessToken, 'new');
    expect(repo.refreshCalls, 1);
    container.dispose();
  });

  test('logout durante renovação não restaura sessão anterior', () async {
    final repo = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    final controller = container.read(authSessionProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final refresh = controller.refreshAfterUnauthorized(
      container.read(authSessionProvider).valueOrNull!,
    );
    await repo.refreshStarted.future;
    final logout = controller.logout();
    repo.refreshResult.complete(session('a', 'new'));
    expect(await refresh, isNull);
    await logout;
    expect(container.read(authSessionProvider).valueOrNull, isNull);
    expect(repo.stored, isNull);
    container.dispose();
  });

  test(
    'troca de conta aguarda renovação sem restaurar usuário anterior',
    () async {
      final repo = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repo)],
      );
      final controller = container.read(authSessionProvider.notifier);
      await Future<void>.delayed(Duration.zero);
      final refresh = controller.refreshAfterUnauthorized(
        container.read(authSessionProvider).valueOrNull!,
      );
      await repo.refreshStarted.future;
      final login = controller.login('b@example.test', 'test');
      repo.refreshResult.complete(session('a', 'new'));
      expect(await refresh, isNull);
      await login;
      expect(container.read(authSessionProvider).valueOrNull?.userId, 'b');
      expect(repo.stored?.userId, 'b');
      container.dispose();
    },
  );

  test('falha de renovação preserva a conta ativa', () async {
    final repo = FakeAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    final controller = container.read(authSessionProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    final refresh = controller.refreshAfterUnauthorized(
      container.read(authSessionProvider).valueOrNull!,
    );
    await repo.refreshStarted.future;
    repo.refreshResult.completeError(const AuthException('indisponível'));
    await expectLater(refresh, throwsA(isA<AuthException>()));
    expect(container.read(authSessionProvider).valueOrNull?.userId, 'a');
    expect(repo.stored?.accessToken, 'old');
    container.dispose();
  });
}
