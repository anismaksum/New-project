import '../models/booking_request.dart';
import '../models/kost.dart';
import '../models/support_message.dart';

abstract class KostHuntRepository {
  Future<List<Kost>> loadKosts();

  Future<Kost> createKost(Kost kost);

  Future<Kost> updateKost(Kost kost);

  Future<List<BookingRequest>> loadBookings();

  Future<List<SupportMessage>> loadSupportMessages();

  Future<void> saveKost(Kost kost);

  Future<void> saveBooking(BookingRequest booking);

  Future<void> updateBooking(BookingRequest booking);

  Future<void> saveSupportMessage(SupportMessage message, {String? bookingId});

  Future<void> updateSupportMessage(SupportMessage message);

  Future<void> updateKostAvailability(String kostId, bool isAvailable);

  Future<void> updateKostVerification(String kostId, bool isVerified);

  Future<void> saveNotificationLog({
    required String relatedType,
    required String relatedId,
    required String eventType,
    required String targetPhone,
    required bool success,
    required String reference,
    required String message,
  });
}
