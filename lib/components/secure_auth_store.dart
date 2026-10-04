import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredAuthSession {
  final String accessToken;
  final String idToken;
  final String refreshToken;
  final String email;
  final DateTime? expiresAt;

  const StoredAuthSession({
    required this.accessToken,
    required this.idToken,
    required this.refreshToken,
    required this.email,
    required this.expiresAt,
  });

  bool get isExpiringSoon {
    if (expiresAt == null) return false;
    return DateTime.now().toUtc().add(const Duration(seconds: 60)).isAfter(expiresAt!);
  }
}

class SecureAuthStore {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'confygre.auth.access_token';
  static const _idTokenKey = 'confygre.auth.id_token';
  static const _refreshTokenKey = 'confygre.auth.refresh_token';
  static const _emailKey = 'confygre.auth.email';
  static const _expiresAtKey = 'confygre.auth.expires_at';

  static Future<void> saveSession({
    required String accessToken,
    String idToken = '',
    String refreshToken = '',
    String email = '',
    DateTime? expiresAt,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _idTokenKey, value: idToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
      _storage.write(key: _emailKey, value: email),
      _storage.write(
        key: _expiresAtKey,
        value: expiresAt?.toUtc().millisecondsSinceEpoch.toString() ?? '',
      ),
    ]);
  }

  static Future<StoredAuthSession?> readSession() async {
    final values = await Future.wait([
      _storage.read(key: _accessTokenKey),
      _storage.read(key: _idTokenKey),
      _storage.read(key: _refreshTokenKey),
      _storage.read(key: _emailKey),
      _storage.read(key: _expiresAtKey),
    ]);

    final accessToken = values[0] ?? '';
    final refreshToken = values[2] ?? '';
    if (accessToken.isEmpty && refreshToken.isEmpty) return null;

    DateTime? expiresAt;
    final expiresRaw = values[4] ?? '';
    final expiresMs = int.tryParse(expiresRaw);
    if (expiresMs != null && expiresMs > 0) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresMs, isUtc: true);
    }

    return StoredAuthSession(
      accessToken: accessToken,
      idToken: values[1] ?? '',
      refreshToken: refreshToken,
      email: values[3] ?? '',
      expiresAt: expiresAt,
    );
  }

  static Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _idTokenKey),
      _storage.delete(key: _refreshTokenKey),
      _storage.delete(key: _emailKey),
      _storage.delete(key: _expiresAtKey),
    ]);
  }
}
