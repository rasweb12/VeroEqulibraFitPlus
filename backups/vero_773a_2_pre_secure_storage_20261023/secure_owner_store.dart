import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Cifred per-account persistence backed by Android Keystore / iOS Keychain.
///
/// Callers must already have a verified owner ID. Legacy SharedPreferences
/// values are intentionally never read because they have no trustworthy owner.
abstract interface class SecureOwnerStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class PlatformSecureOwnerStore implements SecureOwnerStore {
  PlatformSecureOwnerStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Test-only compatible implementation; never register it in production.
class MemorySecureOwnerStore implements SecureOwnerStore {
  final Map<String, String> _values = {};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
