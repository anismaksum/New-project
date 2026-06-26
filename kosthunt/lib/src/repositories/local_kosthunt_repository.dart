import '../data/booking_seed.dart';
import '../data/kost_seed.dart';
import '../data/support_message_seed.dart';
import '../models/booking_request.dart';
import '../models/kost.dart';
import '../models/support_message.dart';
import 'kosthunt_repository.dart';

class LocalKostHuntRepository implements KostHuntRepository {
  LocalKostHuntRepository()
      : _kosts = <Kost>[...kostSeed],
        _bookings = <BookingRequest>[...bookingSeed],
        _supportMessages = <SupportMessage>[...supportMessageSeed];

  final List<Kost> _kosts;
  final List<BookingRequest> _bookings;
  final List<SupportMessage> _supportMessages;
  final List<Map<String, Object?>> _notificationLogs = <Map<String, Object?>>[];

  @override
  Future<List<Kost>> loadKosts() async {
    return List<Kost>.unmodifiable(_kosts);
  }

  @override
  Future<List<BookingRequest>> loadBookings() async {
    return List<BookingRequest>.unmodifiable(_bookings);
  }

  @override
  Future<List<SupportMessage>> loadSupportMessages() async {
    return List<SupportMessage>.unmodifiable(_supportMessages);
  }

  @override
  Future<void> saveKost(Kost kost) async {
    final int index = _kosts.indexWhere((Kost item) => item.id == kost.id);
    if (index == -1) {
      _kosts.insert(0, kost);
      return;
    }
    _kosts[index] = kost;
  }

  @override
  Future<void> saveBooking(BookingRequest booking) async {
    _bookings.insert(0, booking);
  }

  @override
  Future<void> updateBooking(BookingRequest booking) async {
    final int index = _bookings.indexWhere(
      (BookingRequest item) => item.id == booking.id,
    );
    if (index == -1) {
      _bookings.insert(0, booking);
      return;
    }
    _bookings[index] = booking;
  }

  @override
  Future<void> saveSupportMessage(
    SupportMessage message, {
    String? bookingId,
  }) async {
    _supportMessages.add(message);
  }

  @override
  Future<void> updateSupportMessage(SupportMessage message) async {
    final int index = _supportMessages.indexWhere(
      (SupportMessage item) => item.id == message.id,
    );
    if (index == -1) {
      _supportMessages.add(message);
      return;
    }
    _supportMessages[index] = message;
  }

  @override
  Future<void> updateKostAvailability(String kostId, bool isAvailable) async {
    final int index = _kosts.indexWhere((Kost kost) => kost.id == kostId);
    if (index == -1) {
      return;
    }
    _kosts[index] = _kosts[index].copyWith(isAvailable: isAvailable);
  }

  @override
  Future<void> updateKostVerification(String kostId, bool isVerified) async {
    final int index = _kosts.indexWhere((Kost kost) => kost.id == kostId);
    if (index == -1) {
      return;
    }
    _kosts[index] = _kosts[index].copyWith(isVerified: isVerified);
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
    _notificationLogs.add(<String, Object?>{
      'related_type': relatedType,
      'related_id': relatedId,
      'event_type': eventType,
      'channel': 'whatsapp',
      'provider': 'fonnte',
      'target_phone': targetPhone,
      'success': success,
      'reference': reference,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
