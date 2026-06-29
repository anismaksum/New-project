class AuthSessionData {
  const AuthSessionData({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
}

class AuthSessionStore {
  const AuthSessionStore();

  Future<AuthSessionData?> read() async {
    return null;
  }

  Future<void> write(AuthSessionData data) async {}

  Future<void> clear() async {}
}
