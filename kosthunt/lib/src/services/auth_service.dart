import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/app_user.dart';
import 'supabase_rest_client.dart';

class AuthResult {
  const AuthResult.success(this.user) : message = null;

  const AuthResult.failure(this.message) : user = null;

  final AppUser? user;
  final String? message;

  bool get success => user != null;
}

class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  final SupabaseRestClient _client = const SupabaseRestClient();

  AppUser? _currentUser;
  String? _accessToken;

  AppUser? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  UserRole? get currentRole => _currentUser?.role;

  bool canAccess(UserRole role) {
    return _currentUser?.role == role;
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final String normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return const AuthResult.failure('Email dan password wajib diisi.');
    }

    if (!AppConfig.hasSupabaseConfig) {
      return const AuthResult.failure(
        'Supabase belum dikonfigurasi. Jalankan lewat run_flutter_supabase.ps1.',
      );
    }

    try {
      final SupabaseRestResponse response = await _client.request(
        method: 'POST',
        uri: _authUri('/token?grant_type=password'),
        headers: _anonHeaders,
        body: <String, String>{
          'email': normalizedEmail,
          'password': password,
        },
      );
      if (!response.isSuccess) {
        return AuthResult.failure(_authErrorMessage(response.body));
      }

      final Map<String, Object?> payload =
          Map<String, Object?>.from(jsonDecode(response.body) as Map);
      final Map<String, Object?> authUser =
          Map<String, Object?>.from(payload['user'] as Map);
      _accessToken = payload['access_token']?.toString();

      final Map<String, Object?>? profile = await _loadUserProfile(
        authUser['id']?.toString(),
      );
      final AppUser user = AppUser.fromSupabaseAuth(
        authUser: authUser,
        profile: profile,
      );
      _currentUser = user;
      notifyListeners();
      return AuthResult.success(user);
    } on Object {
      return const AuthResult.failure(
        'Gagal menghubungi Supabase. Periksa koneksi dan konfigurasi project.',
      );
    }
  }

  Future<Map<String, Object?>?> _loadUserProfile(String? authUserId) async {
    final String? token = _accessToken;
    if (authUserId == null || authUserId.isEmpty || token == null) {
      return null;
    }
    final SupabaseRestResponse response = await _client.request(
      method: 'GET',
      uri: _restUri(
        'app_users',
        'select=*&auth_user_id=eq.${Uri.encodeQueryComponent(authUserId)}'
        '&limit=1',
      ),
      headers: <String, String>{
        ..._anonHeaders,
        'Authorization': 'Bearer $token',
      },
    );
    if (!response.isSuccess) {
      return null;
    }
    final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;
    if (rows.isEmpty) {
      return null;
    }
    return Map<String, Object?>.from(rows.first as Map);
  }

  void logout() {
    _currentUser = null;
    _accessToken = null;
    notifyListeners();
  }

  Uri _authUri(String path) {
    final String normalizedUrl = AppConfig.supabaseUrl.endsWith('/')
        ? AppConfig.supabaseUrl.substring(0, AppConfig.supabaseUrl.length - 1)
        : AppConfig.supabaseUrl;
    return Uri.parse('$normalizedUrl/auth/v1$path');
  }

  Uri _restUri(String table, String query) {
    final String normalizedUrl = AppConfig.supabaseUrl.endsWith('/')
        ? AppConfig.supabaseUrl.substring(0, AppConfig.supabaseUrl.length - 1)
        : AppConfig.supabaseUrl;
    return Uri.parse('$normalizedUrl/rest/v1/$table?$query');
  }

  Map<String, String> get _anonHeaders {
    return <String, String>{
      'apikey': AppConfig.supabasePublishableKey,
      'Authorization': 'Bearer ${AppConfig.supabasePublishableKey}',
      'Content-Type': 'application/json',
    };
  }

  String _authErrorMessage(String body) {
    try {
      final Map<String, Object?> data =
          Map<String, Object?>.from(jsonDecode(body) as Map);
      final Object? message =
          data['msg'] ?? data['message'] ?? data['error_description'];
      if (message != null) {
        final String text = message.toString();
        if (text.toLowerCase().contains('invalid login')) {
          return 'Email atau password tidak sesuai.';
        }
        return text;
      }
    } on Object {
      // Fall through to a user-friendly message.
    }
    return 'Login gagal. Periksa email dan password.';
  }
}
