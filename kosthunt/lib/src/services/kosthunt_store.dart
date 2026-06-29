import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../data/booking_seed.dart';
import '../data/kost_seed.dart';
import '../models/app_user.dart';
import '../data/support_message_seed.dart';
import '../models/booking_request.dart';
import '../models/kost.dart';
import '../models/support_message.dart';
import '../repositories/kosthunt_repository.dart';
import '../repositories/local_kosthunt_repository.dart';
import '../repositories/supabase_kosthunt_repository.dart';
import 'auth_service.dart';
import 'notification_service.dart';

class KostHuntStore extends ChangeNotifier {
  KostHuntStore._({KostHuntRepository? repository})
      : _repository = repository ?? _defaultRepository() {
    AuthService.instance.addListener(_handleAuthChanged);
    _loadInitialData();
    _startLiveSync();
  }

  static final KostHuntStore instance = KostHuntStore._();

  static KostHuntRepository _defaultRepository() {
    if (!AppConfig.hasSupabaseConfig) {
      return LocalKostHuntRepository();
    }
    return SupabaseKostHuntRepository(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
    );
  }

  final KostHuntRepository _repository;
  final NotificationService _notification = const NotificationService();
  final Set<String> _favorites = <String>{};
  final List<Kost> _kosts = <Kost>[...kostSeed];
  final List<BookingRequest> _bookings = <BookingRequest>[...bookingSeed];
  final List<SupportMessage> _supportMessages = <SupportMessage>[
    ...supportMessageSeed,
  ];
  Timer? _refreshTimer;
  bool _refreshInFlight = false;
  int _bookingCounter = 1003;
  int _messageCounter = 1001;
  int _kostCounter = 1;

  List<Kost> get kosts => List<Kost>.unmodifiable(_kosts);

  List<Kost> get marketplaceKosts {
    return _kosts.where((Kost kost) => isAvailable(kost)).toList();
  }

  List<BookingRequest> get bookings =>
      List<BookingRequest>.unmodifiable(_bookings);

  List<SupportMessage> get supportMessages =>
      List<SupportMessage>.unmodifiable(_supportMessages);

  List<Kost> get ownerKosts {
    final AppUser? user = _currentOwnerUser;
    if (user == null) {
      return const <Kost>[];
    }
    return _kosts
        .where((Kost kost) => _matchesCurrentOwner(kost, user))
        .toList()
      ..sort((Kost a, Kost b) => b.id.compareTo(a.id));
  }

  List<BookingRequest> get ownerBookings {
    final AppUser? user = _currentOwnerUser;
    if (user == null) {
      return const <BookingRequest>[];
    }
    return _bookings
        .where((BookingRequest booking) =>
            _matchesCurrentOwner(booking.kost, user))
        .toList();
  }

  List<Kost> get favorites {
    return _kosts.where((Kost kost) => _favorites.contains(kost.id)).toList();
  }

  bool isFavorite(Kost kost) {
    return _favorites.contains(kost.id);
  }

  bool isAvailable(Kost kost) {
    return _kostById(kost.id)?.isAvailable ?? kost.isAvailable;
  }

  bool isVerified(Kost kost) {
    return _kostById(kost.id)?.isVerified ?? kost.isVerified;
  }

  Future<Kost> publishOwnerListing({
    required String name,
    required String city,
    required String address,
    required int price,
    required double distanceKm,
    required String imageUrl,
    required List<String> facilities,
    required String category,
    required String description,
  }) async {
    final AppUser? user = _currentOwnerUser;
    if (user == null) {
      throw StateError('Akun owner tidak aktif. Silakan login ulang.');
    }

    final Kost created = await _repository.createKost(
      Kost(
        id: _createListingId(name),
        name: name,
        city: city,
        address: address,
        price: price,
        distanceKm: distanceKm,
        imageUrl: imageUrl,
        facilities: facilities,
        isVerified: false,
        isAvailable: true,
        category: category,
        ownerName: user.name,
        ownerPhone: user.phone,
        description: description,
      ),
    );
    _upsertKost(created);
    notifyListeners();
    unawaited(refreshRemoteData());
    return created;
  }

  Future<Kost> updateOwnerListing({
    required Kost listing,
    required String name,
    required String city,
    required String address,
    required int price,
    required double distanceKm,
    required String imageUrl,
    required List<String> facilities,
    required String category,
    required String description,
  }) async {
    final AppUser? user = _currentOwnerUser;
    if (user == null) {
      throw StateError('Akun owner tidak aktif. Silakan login ulang.');
    }

    final Kost updated = listing.copyWith(
      name: name,
      city: city,
      address: address,
      price: price,
      distanceKm: distanceKm,
      imageUrl: imageUrl,
      facilities: facilities,
      category: category,
      ownerName: user.name,
      ownerPhone: user.phone,
      description: description,
    );
    final Kost saved = await _repository.updateKost(updated);
    _upsertKost(saved);
    notifyListeners();
    unawaited(refreshRemoteData());
    return saved;
  }

  void toggleFavorite(Kost kost) {
    if (!_favorites.add(kost.id)) {
      _favorites.remove(kost.id);
    }
    notifyListeners();
  }

  Future<Kost> createKostDraft({
    required String name,
    required int price,
    required String address,
    required String category,
  }) async {
    final String city = _cityFromAddress(address);
    final Kost draft = Kost(
      id: 'owner-kost-${_kostCounter++}',
      name: name.trim(),
      city: city,
      address: address.trim(),
      price: price,
      distanceKm: 1.0,
      imageUrl:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
      facilities: const <String>['WiFi', 'Parkir'],
      isVerified: false,
      isAvailable: true,
      category: category,
      ownerName: AuthService.instance.currentUser?.name ?? 'Owner Kost',
      ownerPhone: AuthService.instance.currentUser?.phone ?? '628122220002',
      description:
          'Draft listing baru dari owner. Lengkapi foto, fasilitas, dan detail kamar sebelum diverifikasi admin.',
    );
    _kosts.insert(0, draft);
    notifyListeners();
    await _persist(_repository.saveKost(draft));
    return draft;
  }

  Future<void> toggleAvailability(Kost kost) async {
    final bool next = !isAvailable(kost);
    _replaceKost(kost.copyWith(isAvailable: next));
    notifyListeners();
    await _persist(_repository.updateKostAvailability(kost.id, next));
  }

  Future<void> toggleVerified(Kost kost) async {
    final bool next = !isVerified(kost);
    _replaceKost(kost.copyWith(isVerified: next));
    notifyListeners();
    await _persist(_repository.updateKostVerification(kost.id, next));
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
    await _persist(_repository.saveBooking(draft));

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
    await _persist(_repository.saveNotificationLog(
      relatedType: 'booking',
      relatedId: sent.id,
      eventType: 'booking-created-admin',
      targetPhone: 'admin',
      success: result.success,
      reference: result.reference,
      message: result.message,
    ));
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
        notificationStatus: result.success ? 'Update terkirim' : 'Update gagal',
        notificationReference: result.reference,
        notificationMessage: result.message,
      ),
    );
    await _persist(_repository.saveNotificationLog(
      relatedType: 'booking',
      relatedId: booking.id,
      eventType: 'booking-status-customer',
      targetPhone: booking.customerPhone,
      success: result.success,
      reference: result.reference,
      message: result.message,
    ));
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
    await _persist(_repository.saveSupportMessage(
      draft,
      bookingId: _bookings.isEmpty ? null : _bookings.first.id,
    ));
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
    await _persist(_repository.saveNotificationLog(
      relatedType: 'support_message',
      relatedId: sent.id,
      eventType: 'customer-support-admin',
      targetPhone: 'admin',
      success: result.success,
      reference: result.reference,
      message: sent.deliveryStatus,
    ));
    return sent;
  }

  Future<void> _loadInitialData() async {
    await refreshRemoteData();
  }

  Future<void> refreshRemoteData() async {
    if (_refreshInFlight) {
      return;
    }
    _refreshInFlight = true;
    try {
      final List<Kost> loadedKosts = await _repository.loadKosts();
      final List<BookingRequest> loadedBookings =
          await _repository.loadBookings();
      final List<SupportMessage> loadedMessages =
          await _repository.loadSupportMessages();

      _kosts
        ..clear()
        ..addAll(loadedKosts);
      _bookings
        ..clear()
        ..addAll(loadedBookings);
      _supportMessages
        ..clear()
        ..addAll(loadedMessages);
      _syncCounters();
      notifyListeners();
    } finally {
      _refreshInFlight = false;
    }
  }

  void _replaceBooking(BookingRequest booking) {
    final int index = _bookings.indexWhere(
      (BookingRequest item) => item.id == booking.id,
    );
    if (index == -1) {
      return;
    }
    _bookings[index] = booking;
    unawaited(_persist(_repository.updateBooking(booking)));
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
    unawaited(_persist(_repository.updateSupportMessage(message)));
    notifyListeners();
  }

  Kost? _kostById(String id) {
    for (final Kost kost in _kosts) {
      if (kost.id == id) {
        return kost;
      }
    }
    return null;
  }

  void _replaceKost(Kost updated) {
    final int index = _kosts.indexWhere((Kost item) => item.id == updated.id);
    if (index == -1) {
      return;
    }
    _kosts[index] = updated;
  }

  void _upsertKost(Kost kost) {
    final int index = _kosts.indexWhere((Kost item) => item.id == kost.id);
    if (index == -1) {
      _kosts.insert(0, kost);
      return;
    }
    _kosts[index] = kost;
  }

  void _syncCounters() {
    for (final BookingRequest booking in _bookings) {
      _bookingCounter = _nextCounter(_bookingCounter, booking.id, 'BK-');
    }
    for (final SupportMessage message in _supportMessages) {
      _messageCounter = _nextCounter(_messageCounter, message.id, 'MSG-');
    }
    for (final Kost kost in _kosts) {
      _kostCounter = _nextCounter(_kostCounter, kost.id, 'owner-kost-');
    }
  }

  int _nextCounter(int current, String id, String prefix) {
    if (!id.startsWith(prefix)) {
      return current;
    }
    final int? parsed = int.tryParse(id.substring(prefix.length));
    if (parsed == null) {
      return current;
    }
    return parsed >= current ? parsed + 1 : current;
  }

  Future<void> _persist(Future<void> operation) async {
    try {
      await operation;
    } on Object {
      // Local UI state remains the source of truth when remote persistence fails.
    }
  }

  String _clockLabel(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  AppUser? get _currentOwnerUser {
    final AppUser? user = AuthService.instance.currentUser;
    if (user == null || user.role != UserRole.owner) {
      return null;
    }
    return user;
  }

  bool _matchesCurrentOwner(Kost kost, AppUser user) {
    final String normalizedPhone = user.phone.trim();
    final String normalizedName = user.name.trim().toLowerCase();
    return kost.ownerPhone.trim() == normalizedPhone ||
        kost.ownerName.trim().toLowerCase() == normalizedName;
  }

  String _cityFromAddress(String address) {
    final parts = address.split(',');
    if (parts.length >= 2) {
      return parts[parts.length - 2].trim();
    }
    return address.trim();
  }

  String _createListingId(String name) {
    final String slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${slug.isEmpty ? 'kost-baru' : slug}-$timestamp';
  }

  void _startLiveSync() {
    if (!AppConfig.hasSupabaseConfig) {
      return;
    }
    _refreshTimer ??= Timer.periodic(const Duration(seconds: 12), (_) {
      unawaited(refreshRemoteData());
    });
  }

  @override
  void dispose() {
    AuthService.instance.removeListener(_handleAuthChanged);
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _handleAuthChanged() {
    unawaited(refreshRemoteData());
  }
}
