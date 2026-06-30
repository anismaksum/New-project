import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/app_user.dart';
import 'auth_session_store.dart';
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
  final AuthSessionStore _sessionStore = const AuthSessionStore();

  AppUser? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _initialized = false;

  AppUser? get currentUser => _currentUser;

  String? get accessToken => _accessToken;

  bool get isLoggedIn => _currentUser != null;

  UserRole? get currentRole => _currentUser?.role;

  bool get isInitialized => _initialized;

  bool canAccess(UserRole role) {
    return _currentUser?.role == role;
  }

  Future<void> restoreSession() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    try {
      final AuthSessionData? saved = await _sessionStore.read();
      if (saved == null) {
        notifyListeners();
        return;
      }

      _accessToken = saved.accessToken;
      _refreshToken = saved.refreshToken;

      final Map<String, Object?>? authUser = await _loadAuthUser();
      if (authUser == null && _refreshToken != null) {
        final _AuthPayload? refreshed = await _refreshSession(_refreshToken!);
        if (refreshed == null) {
          await _clearSession();
          notifyListeners();
          return;
        }
        await _applyPayload(refreshed);
        notifyListeners();
        return;
      }

      if (authUser == null) {
        await _clearSession();
        notifyListeners();
        return;
      }

      final Map<String, Object?>? profile = await _loadUserProfile(
        authUser['id']?.toString(),
      );
      _currentUser = AppUser.fromSupabaseAuth(
        authUser: authUser,
        profile: profile,
      );
    } on Object {
      await _clearSession();
    }
    notifyListeners();
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
        'Supabase Cloud belum dikonfigurasi. Isi URL dan publishable key saat menjalankan app.',
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
        return AuthResult.failure(
          _authErrorMessage(
            response.body,
            fallback: 'Login gagal. Periksa email dan password.',
          ),
        );
      }

      final _AuthPayload payload = _payloadFrom(response.body);
      await _applyPayload(payload);
      notifyListeners();
      return AuthResult.success(_currentUser!);
    } on Object {
      return const AuthResult.failure(
        'Gagal menghubungi Supabase. Periksa koneksi dan konfigurasi project.',
      );
    }
  }

  Future<AuthResult> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final String normalizedName = name.trim();
    final String normalizedPhone = phone.trim();
    final String normalizedEmail = email.trim().toLowerCase();

    if (normalizedName.isEmpty ||
        normalizedPhone.isEmpty ||
        normalizedEmail.isEmpty ||
        password.isEmpty) {
      return const AuthResult.failure('Semua field wajib diisi.');
    }

    if (!AppConfig.hasSupabaseConfig) {
      return const AuthResult.failure(
        'Supabase Cloud belum dikonfigurasi. Isi URL dan publishable key saat menjalankan app.',
      );
    }

    try {
      final SupabaseRestResponse response = await _client.request(
        method: 'POST',
        uri: _authUri('/signup'),
        headers: _anonHeaders,
        body: <String, Object?>{
          'email': normalizedEmail,
          'password': password,
          'data': <String, Object?>{
            'full_name': normalizedName,
            'name': normalizedName,
            'phone': normalizedPhone,
            'role': _roleValue(role),
          },
        },
      );

      if (!response.isSuccess) {
        return AuthResult.failure(
          _authErrorMessage(
            response.body,
            fallback: 'Registrasi gagal. Periksa data akun yang dimasukkan.',
          ),
        );
      }

      final _AuthPayload payload = _payloadFrom(response.body);
      final String? accessToken = payload.accessToken;
      final Map<String, Object?>? authUser = payload.authUser;
      if (accessToken == null || authUser == null) {
        return const AuthResult.failure(
          'Registrasi berhasil dibuat, tetapi sesi login belum tersedia. '
          'Periksa pengaturan email confirmation di Supabase.',
        );
      }

      final String? authUserId = authUser['id']?.toString();
      _accessToken = accessToken;
      _refreshToken = payload.refreshToken;
      final Map<String, Object?> profile = await _createAppUserProfile(
        authUserId: authUserId,
        name: normalizedName,
        phone: normalizedPhone,
        role: role,
      );
      if (role == UserRole.owner) {
        await _ensureOwnerProfile(
          appUserId: profile['id']?.toString(),
          name: normalizedName,
          phone: normalizedPhone,
        );
      }

      _currentUser = AppUser.fromSupabaseAuth(
        authUser: authUser,
        profile: profile,
      );
      await _saveSession();
      notifyListeners();
      return AuthResult.success(_currentUser!);
    } on _AuthFlowException catch (error) {
      await _clearSession();
      return AuthResult.failure(error.message);
    } on Object {
      await _clearSession();
      return const AuthResult.failure(
        'Registrasi gagal. Periksa koneksi dan pastikan email belum dipakai.',
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

  Future<void> logout() async {
    final String? token = _accessToken;
    if (token != null) {
      try {
        await _client.request(
          method: 'POST',
          uri: _authUri('/logout'),
          headers: <String, String>{
            ..._anonHeaders,
            'Authorization': 'Bearer $token',
          },
        );
      } on Object {
        // Logout should still clear local session even if the network fails.
      }
    }
    await _clearSession();
    notifyListeners();
  }

  Future<Map<String, Object?>?> _loadAuthUser() async {
    final String? token = _accessToken;
    if (token == null || token.isEmpty) {
      return null;
    }

    final SupabaseRestResponse response = await _client.request(
      method: 'GET',
      uri: _authUri('/user'),
      headers: <String, String>{
        ..._anonHeaders,
        'Authorization': 'Bearer $token',
      },
    );
    if (!response.isSuccess) {
      return null;
    }
    return Map<String, Object?>.from(jsonDecode(response.body) as Map);
  }

  Future<_AuthPayload?> _refreshSession(String refreshToken) async {
    final SupabaseRestResponse response = await _client.request(
      method: 'POST',
      uri: _authUri('/token?grant_type=refresh_token'),
      headers: _anonHeaders,
      body: <String, Object?>{'refresh_token': refreshToken},
    );
    if (!response.isSuccess) {
      return null;
    }
    return _payloadFrom(response.body);
  }

  Future<void> _applyPayload(_AuthPayload payload) async {
    _accessToken = payload.accessToken;
    _refreshToken = payload.refreshToken;
    final Map<String, Object?> authUser =
        payload.authUser ?? await _loadAuthUser() ?? <String, Object?>{};
    if (authUser.isEmpty) {
      await _clearSession();
      return;
    }

    final Map<String, Object?>? profile = await _loadUserProfile(
      authUser['id']?.toString(),
    );
    _currentUser = AppUser.fromSupabaseAuth(
      authUser: authUser,
      profile: profile,
    );
    await _saveSession();
  }

  Future<Map<String, Object?>> _createAppUserProfile({
    required String? authUserId,
    required String name,
    required String phone,
    required UserRole role,
  }) async {
    final String? token = _accessToken;
    if (authUserId == null || authUserId.isEmpty || token == null) {
      throw const _AuthFlowException(
        'Akun auth sudah dibuat, tetapi sesi Supabase belum siap untuk menyimpan profil aplikasi.',
      );
    }

    final SupabaseRestResponse response = await _client.request(
      method: 'POST',
      uri: _restUri('app_users', ''),
      headers: <String, String>{
        ..._anonHeaders,
        'Authorization': 'Bearer $token',
        'Prefer': 'return=representation',
      },
      body: <String, Object?>{
        'auth_user_id': authUserId,
        'full_name': name,
        'phone': phone,
        'role': _roleValue(role),
      },
    );
    if (!response.isSuccess) {
      final Map<String, Object?>? existingProfile = await _loadUserProfile(
        authUserId,
      );
      if (existingProfile != null) {
        return existingProfile;
      }
      throw _AuthFlowException(
        _profileErrorMessage(
          response.body,
          fallback:
              'Akun auth berhasil dibuat, tetapi profil aplikasi belum bisa disimpan ke tabel app_users. '
              'Jalankan migration auth profile di Supabase, lalu login kembali tanpa daftar ulang.',
        ),
      );
    }

    final Map<String, Object?>? profile = _singleRowFromBody(response.body);
    if (profile != null) {
      return profile;
    }

    final Map<String, Object?>? reloaded = await _loadUserProfile(authUserId);
    if (reloaded != null) {
      return reloaded;
    }

    throw const _AuthFlowException(
      'Akun auth berhasil dibuat, tetapi profil aplikasi belum muncul di tabel app_users. '
      'Jalankan migration auth profile di Supabase, lalu login kembali.',
    );
  }

  Future<void> _ensureOwnerProfile({
    required String? appUserId,
    required String name,
    required String phone,
  }) async {
    final String? token = _accessToken;
    if (appUserId == null || appUserId.isEmpty || token == null) {
      throw const _AuthFlowException(
        'Profil owner belum bisa dibuat karena profil app_users belum tersedia.',
      );
    }

    final Map<String, Object?>? existingOwner = await _loadOwnerProfile(
      appUserId,
    );
    if (existingOwner != null) {
      return;
    }

    final SupabaseRestResponse response = await _client.request(
      method: 'POST',
      uri: _restUri('owners', ''),
      headers: <String, String>{
        ..._anonHeaders,
        'Authorization': 'Bearer $token',
        'Prefer': 'return=minimal',
      },
      body: <String, Object?>{
        'user_id': appUserId,
        'display_name': name,
        'phone': phone,
      },
    );
    if (response.isSuccess) {
      return;
    }

    final Map<String, Object?>? reloaded = await _loadOwnerProfile(appUserId);
    if (reloaded != null) {
      return;
    }

    throw _AuthFlowException(
      _profileErrorMessage(
        response.body,
        fallback:
            'Akun owner berhasil dibuat, tetapi profil owner belum tersimpan di tabel owners. '
            'Jalankan migration owner profile di Supabase, lalu login kembali.',
      ),
    );
  }

  Future<void> _saveSession() {
    final String? accessToken = _accessToken;
    final String? refreshToken = _refreshToken;
    if (accessToken == null || accessToken.isEmpty) {
      return _sessionStore.clear();
    }
    return _sessionStore.write(
      AuthSessionData(
        accessToken: accessToken,
        refreshToken: refreshToken,
      ),
    );
  }

  Future<void> _clearSession() async {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    await _sessionStore.clear();
  }

  AuthResult _signInLocalDemo(String email, String password) {
    if (password != 'KostHunt212') {
      return const AuthResult.failure('Email atau password tidak sesuai.');
    }

    final Map<String, AppUser> users = <String, AppUser>{
      'customer@kosthunt.test': const AppUser(
        name: 'Nadia Putri',
        email: 'customer@kosthunt.test',
        phone: '628129990001',
        role: UserRole.customer,
      ),
      'owner@kosthunt.test': const AppUser(
        name: 'Ardi Properti',
        email: 'owner@kosthunt.test',
        phone: '628122220002',
        role: UserRole.owner,
      ),
      'admin@kosthunt.test': const AppUser(
        name: 'Admin KostHunt',
        email: 'admin@kosthunt.test',
        phone: '628122220000',
        role: UserRole.admin,
      ),
      'customer@kosthunt.com': const AppUser(
        name: 'Nadia Putri',
        email: 'customer@kosthunt.com',
        phone: '628129990001',
        role: UserRole.customer,
      ),
      'owner@kosthunt.com': const AppUser(
        name: 'Ardi Properti',
        email: 'owner@kosthunt.com',
        phone: '628122220002',
        role: UserRole.owner,
      ),
      'admin@kosthunt.com': const AppUser(
        name: 'Admin KostHunt',
        email: 'admin@kosthunt.com',
        phone: '628122220000',
        role: UserRole.admin,
      ),
    };
    final AppUser? user = users[email];
    if (user == null) {
      return const AuthResult.failure('Email atau password tidak sesuai.');
    }
    _currentUser = user;
    _accessToken = null;
    notifyListeners();
    return AuthResult.success(user);
  }

  Uri _authUri(String path) {
    final String normalizedUrl = AppConfig.supabaseUrl.endsWith('/')
        ? AppConfig.supabaseUrl.substring(0, AppConfig.supabaseUrl.length - 1)
        : AppConfig.supabaseUrl;
    return Uri.parse('$normalizedUrl/auth/v1$path');
  }

  Uri _restUri(String table, [String? query]) {
    final String normalizedUrl = AppConfig.supabaseUrl.endsWith('/')
        ? AppConfig.supabaseUrl.substring(0, AppConfig.supabaseUrl.length - 1)
        : AppConfig.supabaseUrl;
    final String querySuffix = query == null || query.isEmpty ? '' : '?$query';
    return Uri.parse('$normalizedUrl/rest/v1/$table$querySuffix');
  }

  Map<String, String> get _anonHeaders {
    return <String, String>{
      'apikey': AppConfig.supabasePublishableKey,
      'Authorization': 'Bearer ${AppConfig.supabasePublishableKey}',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, Object?>?> _loadOwnerProfile(String appUserId) async {
    final String? token = _accessToken;
    if (appUserId.isEmpty || token == null) {
      return null;
    }
    final SupabaseRestResponse response = await _client.request(
      method: 'GET',
      uri: _restUri(
        'owners',
        'select=*&user_id=eq.${Uri.encodeQueryComponent(appUserId)}&limit=1',
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

  String _authErrorMessage(String body, {required String fallback}) {
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
    return fallback;
  }

  String _profileErrorMessage(String body, {required String fallback}) {
    final String normalized = body.toLowerCase();
    if (normalized.contains('row-level security')) {
      return 'Supabase menolak menyimpan profil akun karena policy RLS untuk app_users/owners belum lengkap. '
          'Jalankan migration auth profile, lalu login kembali tanpa daftar ulang.';
    }
    if (normalized.contains('duplicate key')) {
      return 'Akun ini sudah pernah terdaftar. Coba login memakai email yang sama.';
    }
    return _authErrorMessage(body, fallback: fallback);
  }

  Map<String, Object?>? _singleRowFromBody(String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final Object? decoded = jsonDecode(trimmed);
    if (decoded is List<dynamic> && decoded.isNotEmpty) {
      final Object? first = decoded.first;
      if (first is Map<dynamic, dynamic>) {
        return Map<String, Object?>.from(first);
      }
    }
    if (decoded is Map<dynamic, dynamic>) {
      return Map<String, Object?>.from(decoded);
    }
    return null;
  }

  _AuthPayload _payloadFrom(String body) {
    final Map<String, Object?> payload =
        Map<String, Object?>.from(jsonDecode(body) as Map);
    final Object? rawUser = payload['user'];
    return _AuthPayload(
      accessToken: payload['access_token']?.toString(),
      refreshToken: payload['refresh_token']?.toString(),
      authUser: rawUser is Map<dynamic, dynamic>
          ? Map<String, Object?>.from(rawUser)
          : null,
    );
  }

  String _roleValue(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'customer';
      case UserRole.owner:
        return 'owner';
      case UserRole.admin:
        return 'admin';
    }
  }
}

class _AuthPayload {
  const _AuthPayload({
    required this.accessToken,
    required this.refreshToken,
    required this.authUser,
  });

  final String? accessToken;
  final String? refreshToken;
  final Map<String, Object?>? authUser;
}

class _AuthFlowException implements Exception {
  const _AuthFlowException(this.message);

  final String message;
}
