import 'package:flutter/foundation.dart';

import '../data/kost_seed.dart';
import '../models/booking_request.dart';
import '../models/kost.dart';
import '../models/support_message.dart';
import 'notification_service.dart';

class KostHuntStore extends ChangeNotifier {
  KostHuntStore._()
      : _availability = <String, bool>{
          for (final Kost kost in kostSeed) kost.id: kost.isAvailable,
        },
        _verified = <String, bool>{
          for (final Kost kost in kostSeed) kost.id: kost.isVerified,
        },
        _bookings = <BookingRequest>[
          BookingRequest(
            id: 'BK-1002',
            kost: kostSeed[1],
            customerName: 'Nadia Putri',
            customerPhone: '628121110002',
            scheduleLabel: 'Masuk 15 Jun 2026',
            status: 'Diterima',
            notificationStatus: 'Terkirim ke WhatsApp customer',
            notificationReference: 'WA-BK-1002',
            notificationMessage:
                'Update booking Cendana Eksklusif: status kamu sekarang Diterima.',
          ),
          BookingRequest(
            id: 'BK-1001',
            kost: kostSeed[0],
            customerName: 'Raka Pratama',
            customerPhone: '628121110001',
            scheduleLabel: 'Survey 08 Jun 2026',
            status: 'Pending',
            notificationStatus: 'Terkirim ke WhatsApp admin',
            notificationReference: 'WA-BK-1001',
            notificationMessage:
                'Ada booking baru untuk Kost Melati Residence dari Raka Pratama.',
          ),
        ],
        _supportMessages = <SupportMessage>[
          const SupportMessage(
            id: 'MSG-1000',
            text:
                'Halo, saya Admin KostHunt. Silakan tulis kebutuhan kost atau kendala booking kamu di sini.',
            timeLabel: 'Admin',
            sentByCustomer: false,
            deliveryStatus: 'Siap membantu',
            reference: '-',
          ),
        ];

  static final KostHuntStore instance = KostHuntStore._();

  final NotificationService _notification = const NotificationService();
  final Set<String> _favorites = <String>{};
  final Map<String, bool> _availability;
  final Map<String, bool> _verified;
  final List<BookingRequest> _bookings;
  final List<SupportMessage> _supportMessages;
  int _bookingCounter = 1003;
  int _messageCounter = 1001;

  List<BookingRequest> get bookings =>
      List<BookingRequest>.unmodifiable(_bookings);

  List<SupportMessage> get supportMessages =>
      List<SupportMessage>.unmodifiable(_supportMessages);

  List<Kost> get favorites {
    return kostSeed.where((Kost kost) => _favorites.contains(kost.id)).toList();
  }

  bool isFavorite(Kost kost) {
    return _favorites.contains(kost.id);
  }

  bool isAvailable(Kost kost) {
    return _availability[kost.id] ?? kost.isAvailable;
  }

  bool isVerified(Kost kost) {
    return _verified[kost.id] ?? kost.isVerified;
  }

  void toggleFavorite(Kost kost) {
    if (!_favorites.add(kost.id)) {
      _favorites.remove(kost.id);
    }
    notifyListeners();
  }

  void toggleAvailability(Kost kost) {
    _availability[kost.id] = !isAvailable(kost);
    notifyListeners();
  }

  void toggleVerified(Kost kost) {
    _verified[kost.id] = !isVerified(kost);
    notifyListeners();
  }

  Future<BookingRequest> createBooking(Kost kost) async {
    final BookingRequest draft = BookingRequest(
      id: 'BK-${_bookingCounter++}',
      kost: kost,
      customerName: 'Calon Penghuni',
      customerPhone: '628129990001',
      scheduleLabel: 'Survey terdekat',
      status: 'Pending',
      notificationStatus: 'Mengirim ke WhatsApp admin',
      notificationReference: '-',
      notificationMessage:
          'Permintaan booking sedang disiapkan untuk notifikasi admin.',
    );
    _bookings.insert(0, draft);
    notifyListeners();

    final NotificationResult result =
        await _notification.sendBookingCreatedToAdmin(
      booking: draft,
      kost: kost,
    );
    final BookingRequest sent = draft.copyWith(
      notificationStatus:
          result.success ? 'Terkirim ke WhatsApp admin' : 'Gagal terkirim',
      notificationReference: result.reference,
      notificationMessage: result.message,
    );
    _replaceBooking(sent);
    return sent;
  }

  Future<void> updateBookingStatus(
      BookingRequest booking, String status) async {
    final BookingRequest updating = booking.copyWith(
      status: status,
      notificationStatus: 'Mengirim update ke WhatsApp customer',
    );
    _replaceBooking(updating);
    final NotificationResult result =
        await _notification.sendBookingStatusToCustomer(
      booking: updating,
      status: status,
    );
    _replaceBooking(
      updating.copyWith(
        notificationStatus:
            result.success ? 'Update terkirim' : 'Update gagal',
        notificationReference: result.reference,
        notificationMessage: result.message,
      ),
    );
  }

  Future<SupportMessage> sendSupportMessage(String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Pesan tidak boleh kosong.');
    }

    final SupportMessage draft = SupportMessage(
      id: 'MSG-${_messageCounter++}',
      text: trimmed,
      timeLabel: _clockLabel(DateTime.now()),
      sentByCustomer: true,
      deliveryStatus: 'Mengirim ke WhatsApp admin',
      reference: '-',
    );
    _supportMessages.add(draft);
    notifyListeners();

    final NotificationResult result =
        await _notification.sendCustomerSupportToAdmin(
      message: trimmed,
      customerName: 'Calon Penghuni',
      customerPhone: '628129990001',
      messageId: draft.id,
    );
    final SupportMessage sent = draft.copyWith(
      deliveryStatus: result.success
          ? 'Terkirim ke WhatsApp admin'
          : 'Gagal terkirim ke admin',
      reference: result.reference,
    );
    _replaceSupportMessage(sent);
    return sent;
  }

  void _replaceBooking(BookingRequest booking) {
    final int index = _bookings.indexWhere(
      (BookingRequest item) => item.id == booking.id,
    );
    if (index == -1) {
      return;
    }
    _bookings[index] = booking;
    notifyListeners();
  }

  void _replaceSupportMessage(SupportMessage message) {
    final int index = _supportMessages.indexWhere(
      (SupportMessage item) => item.id == message.id,
    );
    if (index == -1) {
      return;
    }
    _supportMessages[index] = message;
    notifyListeners();
  }

  String _clockLabel(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
