import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

  File get _file => File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}kosthunt_auth_session.json',
      );

  Future<AuthSessionData?> read() async {
    if (!await _file.exists()) {
      return null;
    }
    final String raw = await _file.readAsString();
    if (raw.trim().isEmpty) {
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
    await _file.writeAsString(jsonEncode(data.toJson()), flush: true);
  }

  Future<void> clear() async {
    if (await _file.exists()) {
      await _file.delete();
    }
  }
}
