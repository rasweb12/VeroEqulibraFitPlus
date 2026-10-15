import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    required this.userId,
    this.displayName,
  });
  final String accessToken;
  final String refreshToken;
  final String email;
  final String userId;
  final String? displayName;
}

/// Keeps credentials in the operating system's encrypted keystore, never in
/// SharedPreferences. The API endpoint is supplied at build time.
class AuthRepository {
  AuthRepository({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _emailKey = 'auth_email';
  static const _userIdKey = 'auth_user_id';
  static const _displayNameKey = 'auth_display_name';
  static const _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<AuthSession?> restore() async {
    final access = await _storage.read(key: _accessKey);
    final refresh = await _storage.read(key: _refreshKey);
    final email = await _storage.read(key: _emailKey);
    final userId = await _storage.read(key: _userIdKey);
    if (access == null ||
        refresh == null ||
        email == null ||
        userId == null ||
        access.isEmpty ||
        refresh.isEmpty ||
        email.isEmpty ||
        userId.isEmpty) {
      return null;
    }
    final session = AuthSession(
      accessToken: access,
      refreshToken: refresh,
      email: email,
      userId: userId,
      displayName: await _storage.read(key: _displayNameKey),
    );
    if (_isExpired(session.accessToken)) {
      try {
        return await refresh();
      } on AuthException {
        await _storage.deleteAll();
        return null;
      }
    }
    // A stored token never grants access by itself: validate it against the API.
    if (_baseUrl.isEmpty) return null;
    try {
      final response = await _client.get(
        _uri('/api/v1/auth/session'),
        headers: _headers(session.accessToken),
      );
      if (response.statusCode == 200) return session;
      if (response.statusCode == 401 || response.statusCode == 403) {
        final refreshed = await refresh();
        final retry = await _client.get(
          _uri('/api/v1/auth/session'),
          headers: _headers(refreshed.accessToken),
        );
        if (retry.statusCode == 200) return refreshed;
      }
    } catch (_) {
      // No encrypted, owner-scoped offline store exists yet; deny offline access.
    }
    await _storage.deleteAll();
    return null;
  }

  Future<AuthSession> login(String email, String password) => _authenticate(
    '/api/v1/auth/login',
    {'email': email, 'password': password},
  );
  Future<AuthSession> register(
    String email,
    String password,
    String? displayName,
  ) => _authenticate('/api/v1/auth/register', {
    'email': email,
    'password': password,
    'displayName': displayName,
  });

  Future<AuthSession> refresh() async {
    final refresh = await _storage.read(key: _refreshKey);
    if (refresh == null) {
      throw const AuthException('A sessão não está disponível.');
    }
    return _authenticate('/api/v1/auth/refresh', {'refreshToken': refresh});
  }

  Future<void> logout() async {
    final session = await restore();
    if (session != null && _baseUrl.isNotEmpty) {
      await _client.post(
        _uri('/api/v1/auth/logout'),
        headers: _headers(session.accessToken),
        body: jsonEncode({'refreshToken': session.refreshToken}),
      );
    }
    await _storage.deleteAll();
  }

  Future<AuthSession> _authenticate(
    String path,
    Map<String, Object?> body,
  ) async {
    if (_baseUrl.isEmpty) {
      throw const AuthException(
        'Defina API_BASE_URL para conectar sua conta ao ambiente isolado.',
      );
    }
    final response = await _client.post(
      _uri(path),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_message(response));
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final session = AuthSession(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      email: data['email'] as String,
      userId: data['userId'] as String,
      displayName: data['displayName'] as String?,
    );
    await _store(session);
    return session;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');
  Map<String, String> _headers([String? accessToken]) => {
    'Content-Type': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };
  String _message(http.Response response) {
    try {
      return (jsonDecode(response.body) as Map<String, dynamic>)['title']
              as String? ??
          'Não foi possível concluir a autenticação.';
    } catch (_) {
      return 'Não foi possível concluir a autenticação.';
    }
  }

  Future<void> _store(AuthSession session) async {
    await _storage.write(key: _accessKey, value: session.accessToken);
    await _storage.write(key: _refreshKey, value: session.refreshToken);
    await _storage.write(key: _emailKey, value: session.email);
    await _storage.write(key: _userIdKey, value: session.userId);
    await _storage.write(key: _displayNameKey, value: session.displayName);
  }

  bool _isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
              )
              as Map<String, dynamic>;
      final exp = payload['exp'] as num?;
      return exp == null ||
          DateTime.fromMillisecondsSinceEpoch(
            exp.toInt() * 1000,
            isUtc: true,
          ).isBefore(DateTime.now().toUtc().add(const Duration(seconds: 30)));
    } catch (_) {
      return true;
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
