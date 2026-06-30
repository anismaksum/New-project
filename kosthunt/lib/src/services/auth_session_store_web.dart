import 'dart:async';
import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html';

class AuthSessionData {
  const AuthSessionData({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'access_token': accessToken,
      'refresh_token': refreshToken,
    };
  }

  factory AuthSessionData.fromJson(Map<String, Object?> json) {
    return AuthSessionData(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString(),
    );
  }
}

class AuthSessionStore {
  const AuthSessionStore();

  static const String _storageKey = 'kosthunt_auth_session';

  Future<AuthSessionData?> read() async {
    final String? raw = window.localStorage[_storageKey];
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final Map<String, Object?> data =
        Map<String, Object?>.from(jsonDecode(raw) as Map);
    final AuthSessionData session = AuthSessionData.fromJson(data);
    if (session.accessToken.isEmpty) {
      return null;
    }
    return session;
  }

  Future<void> write(AuthSessionData data) async {
    window.localStorage[_storageKey] = jsonEncode(data.toJson());
  }

  Future<void> clear() async {
    window.localStorage.remove(_storageKey);
  }
}
