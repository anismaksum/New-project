import 'dart:convert';

import '../data/booking_seed.dart';
import '../data/kost_seed.dart';
import '../data/support_message_seed.dart';
import '../models/app_user.dart';
import '../models/booking_request.dart';
import '../models/kost.dart';
import '../models/support_message.dart';
import '../services/auth_service.dart';
import '../services/supabase_rest_client.dart';
import 'kosthunt_repository.dart';

class SupabaseKostHuntRepository implements KostHuntRepository {
  SupabaseKostHuntRepository({
    required this.url,
    required this.publishableKey,
    SupabaseRestClient? client,
    AuthService? authService,
  })  : client = client ?? const SupabaseRestClient(),
        authService = authService ?? AuthService.instance;

  final String url;
  final String publishableKey;
  final SupabaseRestClient client;
  final AuthService authService;

  @override
  Future<List<Kost>> loadKosts() async {
    try {
      final String? authToken = _kostReadToken;
      SupabaseRestResponse response = await _request(
        method: 'GET',
        table: 'kosts',
        query: 'select=*&order=created_at.desc',
        authToken: authToken,
      );
      if (!response.isSuccess && authToken != null) {
        response = await _request(
          method: 'GET',
          table: 'kosts',
          query: 'select=*&order=created_at.desc',
        );
      }
      if (!response.isSuccess) {
        return <Kost>[...kostSeed];
      }
      final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;
      return rows
          .cast<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> row) =>
                Kost.fromDatabase(Map<String, Object?>.from(row)),
          )
          .toList();
    } on Object {
      return <Kost>[...kostSeed];
    }
  }

  @override
  Future<Kost> createKost(Kost kost) async {
    final String? accessToken = authService.accessToken;
    final AppUser? user = authService.currentUser;
    if (accessToken == null || user == null || user.role != UserRole.owner) {
      throw StateError(
        'Akun owner harus login ulang sebelum mempublikasikan kost baru.',
      );
    }

    final Map<String, Object?> ownerProfile = await _resolveOwnerProfile(
      accessToken: accessToken,
      user: user,
    );
    final Kost payload = Kost(
      id: kost.id,
      ownerId: ownerProfile['id']?.toString(),
      name: kost.name,
      city: kost.city,
      address: kost.address,
      price: kost.price,
      distanceKm: kost.distanceKm,
      imageUrl: kost.imageUrl,
      facilities: kost.facilities,
      isVerified: kost.isVerified,
      isAvailable: kost.isAvailable,
      category: kost.category,
      ownerName: ownerProfile['display_name']?.toString() ?? user.name,
      ownerPhone: ownerProfile['phone']?.toString() ?? user.phone,
      description: kost.description,
    );

    final SupabaseRestResponse response = await _request(
      method: 'POST',
      table: 'kosts',
      authToken: accessToken,
      prefer: 'return=representation',
      body: payload.toDatabase(),
    );
    if (!response.isSuccess) {
      throw StateError(_errorMessage(
        response.body,
        fallback:
            'Supabase menolak publish kost baru. Cek policy owner pada tabel kosts.',
      ));
    }

    final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;
    if (rows.isEmpty) {
      return payload;
    }
    return Kost.fromDatabase(Map<String, Object?>.from(rows.first as Map));
  }

  @override
  Future<Kost> updateKost(Kost kost) async {
    final String? accessToken = authService.accessToken;
    final AppUser? user = authService.currentUser;
    if (accessToken == null || user == null || user.role != UserRole.owner) {
      throw StateError(
        'Akun owner harus login ulang sebelum mengubah listing kost.',
      );
    }

    final SupabaseRestResponse response = await _request(
      method: 'PATCH',
      table: 'kosts',
      query: 'id=eq.${Uri.encodeQueryComponent(kost.id)}',
      authToken: accessToken,
      prefer: 'return=representation',
      body: kost.toDatabase(),
    );
    if (!response.isSuccess) {
      throw StateError(_errorMessage(
        response.body,
        fallback:
            'Supabase menolak perubahan listing. Cek policy owner pada tabel kosts.',
      ));
    }

    final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;
    if (rows.isEmpty) {
      return kost;
    }
    return Kost.fromDatabase(Map<String, Object?>.from(rows.first as Map));
  }

  @override
  Future<List<BookingRequest>> loadBookings() async {
    try {
      final List<Kost> loadedKosts = await loadKosts();
      final Map<String, Kost> kostById = <String, Kost>{
        for (final Kost kost in loadedKosts) kost.id: kost,
      };
      final SupabaseRestResponse response = await _request(
        method: 'GET',
        table: 'bookings',
        query: 'select=*&order=created_at.desc',
      );
      if (!response.isSuccess) {
        return <BookingRequest>[...bookingSeed];
      }
      final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;
      return rows
          .cast<Map<String, dynamic>>()
          .where(
            (Map<String, dynamic> row) => kostById.containsKey(row['kost_id']),
          )
          .map(
            (Map<String, dynamic> row) => BookingRequest.fromDatabase(
              Map<String, Object?>.from(row),
              kost: kostById[row['kost_id']]!,
            ),
          )
          .toList();
    } on Object {
      return <BookingRequest>[...bookingSeed];
    }
  }

  @override
  Future<List<SupportMessage>> loadSupportMessages() async {
    try {
      final SupabaseRestResponse response = await _request(
        method: 'GET',
        table: 'support_messages',
        query: 'select=*&order=created_at.asc&limit=50',
      );
      if (!response.isSuccess) {
        return <SupportMessage>[...supportMessageSeed];
      }
      final List<dynamic> rows = jsonDecode(response.body) as List<dynamic>;
      if (rows.isEmpty) {
        return <SupportMessage>[...supportMessageSeed];
      }
      return rows
          .cast<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> row) => SupportMessage.fromSupportDatabase(
              Map<String, Object?>.from(row),
            ),
          )
          .toList();
    } on Object {
      return <SupportMessage>[...supportMessageSeed];
    }
  }

  @override
  Future<void> saveKost(Kost kost) async {
    await _request(
      method: 'POST',
      table: 'kosts',
      query: 'on_conflict=id',
      body: kost.toDatabase(),
      prefer: 'resolution=merge-duplicates,return=minimal',
    );
  }

  @override
  Future<void> saveBooking(BookingRequest booking) async {
    await _request(
      method: 'POST',
      table: 'bookings',
      query: 'on_conflict=id',
      body: booking.toDatabase(),
      prefer: 'resolution=merge-duplicates,return=minimal',
    );
  }

  @override
  Future<void> updateBooking(BookingRequest booking) async {
    await _request(
      method: 'PATCH',
      table: 'bookings',
      query: 'id=eq.${Uri.encodeQueryComponent(booking.id)}',
      body: booking.toDatabase(),
    );
  }

  @override
  Future<void> saveSupportMessage(
    SupportMessage message, {
    String? bookingId,
  }) async {
    await _request(
      method: 'POST',
      table: 'support_messages',
      query: 'on_conflict=id',
      body: message.toSupportDatabase(
        customerName: 'Calon Penghuni',
        customerPhone: '628129990001',
      ),
      prefer: 'resolution=merge-duplicates,return=minimal',
    );
  }

  @override
  Future<void> updateSupportMessage(SupportMessage message) async {
    await _request(
      method: 'PATCH',
      table: 'support_messages',
      query: 'id=eq.${Uri.encodeQueryComponent(message.id)}',
      body: <String, Object?>{
        'delivery_status': message.deliveryStatus,
        'notification_reference': message.reference,
      },
    );
  }

  @override
  Future<void> updateKostAvailability(String kostId, bool isAvailable) async {
    final String? authToken = _kostWriteToken;
    SupabaseRestResponse response = await _request(
      method: 'PATCH',
      table: 'kosts',
      query: 'id=eq.${Uri.encodeQueryComponent(kostId)}',
      authToken: authToken,
      body: <String, Object?>{'is_available': isAvailable},
    );
    if (!response.isSuccess && authToken != null) {
      await _request(
        method: 'PATCH',
        table: 'kosts',
        query: 'id=eq.${Uri.encodeQueryComponent(kostId)}',
        body: <String, Object?>{'is_available': isAvailable},
      );
    }
  }

  @override
  Future<void> updateKostVerification(String kostId, bool isVerified) async {
    final String? authToken = _kostWriteToken;
    SupabaseRestResponse response = await _request(
      method: 'PATCH',
      table: 'kosts',
      query: 'id=eq.${Uri.encodeQueryComponent(kostId)}',
      authToken: authToken,
      body: <String, Object?>{'is_verified': isVerified},
    );
    if (!response.isSuccess && authToken != null) {
      await _request(
        method: 'PATCH',
        table: 'kosts',
        query: 'id=eq.${Uri.encodeQueryComponent(kostId)}',
        body: <String, Object?>{'is_verified': isVerified},
      );
    }
  }

  @override
  Future<void> saveNotificationLog({
    required String relatedType,
    required String relatedId,
    required String eventType,
    required String targetPhone,
    required bool success,
    required String reference,
    required String message,
  }) async {
    await _request(
      method: 'POST',
      table: 'notification_logs',
      body: <String, Object?>{
        'related_type': relatedType,
        'related_id': relatedId,
        'event_type': eventType,
        'channel': 'whatsapp',
        'provider': 'fonnte',
        'target_phone': targetPhone,
        'success': success,
        'reference': reference,
        'message': message,
      },
    );
  }

  Future<Map<String, Object?>> _resolveOwnerProfile({
    required String accessToken,
    required AppUser user,
  }) async {
    final SupabaseRestResponse existing = await _request(
      method: 'GET',
      table: 'owners',
      query: 'select=id,display_name,phone,user_id&limit=1',
      authToken: accessToken,
    );
    if (existing.isSuccess) {
      final List<dynamic> rows = jsonDecode(existing.body) as List<dynamic>;
      if (rows.isNotEmpty) {
        return Map<String, Object?>.from(rows.first as Map);
      }
    }

    final String? profileId = user.profileId;
    if (profileId == null || profileId.isEmpty) {
      throw StateError(
        'Profil owner belum siap. Login ulang lalu coba publish lagi.',
      );
    }

    final SupabaseRestResponse created = await _request(
      method: 'POST',
      table: 'owners',
      authToken: accessToken,
      prefer: 'return=representation',
      body: <String, Object?>{
        'user_id': profileId,
        'display_name': user.name,
        'phone': user.phone,
      },
    );
    if (!created.isSuccess) {
      throw StateError(_errorMessage(
        created.body,
        fallback:
            'Profil owner belum bisa dibuat di Supabase. Pastikan migration owner profile sudah terpasang.',
      ));
    }

    final List<dynamic> createdRows = jsonDecode(created.body) as List<dynamic>;
    if (createdRows.isEmpty) {
      throw StateError(
        'Profil owner berhasil diproses, tetapi data owner belum kembali dari Supabase.',
      );
    }
    return Map<String, Object?>.from(createdRows.first as Map);
  }

  Future<SupabaseRestResponse> _request({
    required String method,
    required String table,
    String? query,
    String? authToken,
    Object? body,
    String? prefer,
  }) {
    final String normalizedUrl =
        url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final Uri uri = Uri.parse(
      '$normalizedUrl/rest/v1/$table${query == null ? '' : '?$query'}',
    );
    return client.request(
      method: method,
      uri: uri,
      headers: <String, String>{
        'apikey': publishableKey,
        'Authorization': 'Bearer ${authToken ?? publishableKey}',
        'Content-Type': 'application/json',
        if (prefer != null) 'Prefer': prefer,
      },
      body: body,
    );
  }

  String _errorMessage(String body, {required String fallback}) {
    try {
      final Map<String, Object?> data =
          Map<String, Object?>.from(jsonDecode(body) as Map);
      final Object? message =
          data['message'] ?? data['msg'] ?? data['error_description'];
      if (message != null) {
        return message.toString();
      }
    } on Object {
      // Fall back to a friendlier default message.
    }
    return fallback;
  }

  String? get _kostReadToken {
    final AppUser? user = authService.currentUser;
    if (user == null) {
      return null;
    }
    if (user.role == UserRole.owner || user.role == UserRole.admin) {
      return authService.accessToken;
    }
    return null;
  }

  String? get _kostWriteToken {
    final AppUser? user = authService.currentUser;
    if (user == null) {
      return null;
    }
    if (user.role == UserRole.owner || user.role == UserRole.admin) {
      return authService.accessToken;
    }
    return null;
  }
}
