import 'dart:convert';

import '../data/booking_seed.dart';
import '../data/kost_seed.dart';
import '../data/support_message_seed.dart';
import '../models/booking_request.dart';
import '../models/kost.dart';
import '../models/support_message.dart';
import '../services/supabase_rest_client.dart';
import 'kosthunt_repository.dart';

class SupabaseKostHuntRepository implements KostHuntRepository {
  const SupabaseKostHuntRepository({
    required this.url,
    required this.publishableKey,
    this.client = const SupabaseRestClient(),
  });

  final String url;
  final String publishableKey;
  final SupabaseRestClient client;

  @override
  Future<List<Kost>> loadKosts() async {
    try {
      final SupabaseRestResponse response = await _request(
        method: 'GET',
        table: 'kosts',
        query: 'select=*&order=created_at.asc',
      );
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
            (Map<String, dynamic> row) =>
                SupportMessage.fromSupportDatabase(
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
    await _request(
      method: 'PATCH',
      table: 'kosts',
      query: 'id=eq.${Uri.encodeQueryComponent(kostId)}',
      body: <String, Object?>{'is_available': isAvailable},
    );
  }

  @override
  Future<void> updateKostVerification(String kostId, bool isVerified) async {
    await _request(
      method: 'PATCH',
      table: 'kosts',
      query: 'id=eq.${Uri.encodeQueryComponent(kostId)}',
      body: <String, Object?>{'is_verified': isVerified},
    );
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

  Future<SupabaseRestResponse> _request({
    required String method,
    required String table,
    String? query,
    Object? body,
    String? prefer,
  }) {
    final String normalizedUrl = url.endsWith('/')
        ? url.substring(0, url.length - 1)
        : url;
    final Uri uri = Uri.parse(
      '$normalizedUrl/rest/v1/$table${query == null ? '' : '?$query'}',
    );
    return client.request(
      method: method,
      uri: uri,
      headers: <String, String>{
        'apikey': publishableKey,
        'Authorization': 'Bearer $publishableKey',
        'Content-Type': 'application/json',
        if (prefer != null) 'Prefer': prefer,
      },
      body: body,
    );
  }
}
