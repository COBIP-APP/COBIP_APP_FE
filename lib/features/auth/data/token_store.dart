import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String session);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();
  final FlutterSecureStorage _storage;
  static const _key = 'cobia.auth.session';

  @override
  Future<String?> read() => _storage.read(key: _key);
  @override
  Future<void> write(String session) =>
      _storage.write(key: _key, value: session);
  @override
  Future<void> clear() => _storage.delete(key: _key);
}
