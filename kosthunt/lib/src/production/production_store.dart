import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'production_models.dart';

final productionStoreProvider = ChangeNotifierProvider<ProductionStore>(
  (Ref ref) => ProductionStore.seeded(),
);

class ProductionStore extends ChangeNotifier {
  ProductionStore.seeded() {
    _seed();
  }

  final List<KhUser> users = <KhUser>[];
  final List<OwnerProfile> ownerProfiles = <OwnerProfile>[];
  final List<KostListing> listings = <KostListing>[];
  final List<KostUnit> units = <KostUnit>[];
  final List<FavoriteEntry> favorites = <FavoriteEntry>[];
  final List<Booking> bookings = <Booking>[];
  final List<Payment> payments = <Payment>[];
  final List<PaymentEvent> paymentEvents = <PaymentEvent>[];
  final List<OwnerBalance> balances = <OwnerBalance>[];
  final List<Payout> payouts = <Payout>[];
  final List<RefundRequest> refunds = <RefundRequest>[];
  final List<Conversation> conversations = <Conversation>[];
  final List<ChatMessage> messages = <ChatMessage>[];
  final List<SupportThread> supportThreads = <SupportThread>[];
  final List<SupportNote> supportMessages = <SupportNote>[];
  final List<AppNotification> notifications = <AppNotification>[];
  final List<Review> reviews = <Review>[];
  final List<ReportItem> reports = <ReportItem>[];
  final List<AuditLog> auditLogs = <AuditLog>[];
  final List<String> deletionRequests = <String>[];

  KhUser? currentUser;
  int _sequence = 1000;

  bool get isLoggedIn => currentUser != null;

  List<KostListing> get publishedListings {
    final List<KostListing> result = listings
        .where((KostListing item) => item.status == ListingStatus.published)
        .toList();
    result.sort((KostListing a, KostListing b) {
      if (a.isPremiumActive != b.isPremiumActive) {
        return a.isPremiumActive ? -1 : 1;
      }
      return a.campusDistanceKm.compareTo(b.campusDistanceKm);
    });
    return result;
  }

  List<KostListing> listingsForOwner(String ownerUserId) {
    return listings
        .where((KostListing item) => item.ownerUserId == ownerUserId)
        .toList();
  }

  List<Booking> bookingsForUser(String userId) {
    return bookings
        .where(
          (Booking item) =>
              item.customerUserId == userId || item.ownerUserId == userId,
        )
        .toList()
      ..sort((Booking a, Booking b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Payment> paymentsForUser(String userId) {
    return payments
        .where(
          (Payment item) =>
              item.customerUserId == userId || item.ownerUserId == userId,
        )
        .toList();
  }

  List<Conversation> conversationsForUser(String userId) {
    return conversations
        .where((Conversation item) => item.participantUserIds.contains(userId))
        .toList();
  }

  List<SupportThread> supportThreadsForUser(String userId) {
    if (userById(userId)?.role == KhRole.admin) {
      return List<SupportThread>.from(supportThreads);
    }
    return supportThreads
        .where((SupportThread item) => item.customerUserId == userId)
        .toList();
  }

  List<AppNotification> notificationsForUser(String userId) {
    return notifications
        .where((AppNotification item) => item.recipientUserId == userId)
        .toList()
      ..sort(
        (AppNotification a, AppNotification b) =>
            b.createdAt.compareTo(a.createdAt),
      );
  }

  int unreadCount(String userId) {
    return notifications
        .where(
          (AppNotification item) =>
              item.recipientUserId == userId && item.readAt == null,
        )
        .length;
  }

  KhUser? userById(String id) {
    for (final KhUser user in users) {
      if (user.id == id) {
        return user;
      }
    }
    return null;
  }

  KhUser? userByEmail(String email) {
    final String normalized = email.trim().toLowerCase();
    for (final KhUser user in users) {
      if (user.email.toLowerCase() == normalized) {
        return user;
      }
    }
    return null;
  }

  KostListing listingById(String id) {
    return listings.firstWhere((KostListing item) => item.id == id);
  }

  KostUnit unitById(String id) {
    return units.firstWhere((KostUnit item) => item.id == id);
  }

  List<KostUnit> unitsForListing(String kostId) {
    return units.where((KostUnit item) => item.kostId == kostId).toList();
  }

  OwnerProfile? ownerProfile(String userId) {
    for (final OwnerProfile profile in ownerProfiles) {
      if (profile.userId == userId) {
        return profile;
      }
    }
    return null;
  }

  OwnerBalance balanceForOwner(String ownerUserId) {
    for (final OwnerBalance balance in balances) {
      if (balance.ownerUserId == ownerUserId) {
        return balance;
      }
    }
    final OwnerBalance created = OwnerBalance(
      ownerUserId: ownerUserId,
      pendingAmount: 0,
      availableAmount: 0,
      paidOutAmount: 0,
    );
    balances.add(created);
    return created;
  }

  bool isFavorite(String userId, String kostId) {
    return favorites.any(
      (FavoriteEntry item) => item.userId == userId && item.kostId == kostId,
    );
  }

  void signIn(String email) {
    final KhUser? user = userByEmail(email);
    if (user == null || user.status != 'active') {
      throw ArgumentError('Akun tidak ditemukan atau sedang tidak aktif.');
    }
    currentUser = user;
    _audit(user.id, 'auth.sign_in', 'app_user', user.id, user.email);
    notifyListeners();
  }

  KhUser registerCustomer({
    required String name,
    required String email,
    required String phone,
  }) {
    final KhUser user = KhUser(
      id: _id('usr'),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      role: KhRole.customer,
    );
    users.add(user);
    currentUser = user;
    _notify(user.id, 'register_customer', 'Akun customer aktif',
        'Selamat datang di KostHunt.');
    _notifyAdmins('register_customer', 'Customer baru', '${user.name} mendaftar.');
    _audit(user.id, 'auth.register_customer', 'app_user', user.id, user.email);
    notifyListeners();
    return user;
  }

  KhUser registerOwner({
    required String name,
    required String email,
    required String phone,
  }) {
    final KhUser user = KhUser(
      id: _id('usr'),
      name: name.trim(),
      email: email.trim().toLowerCase(),
      phone: phone.trim(),
      role: KhRole.owner,
      trustLevel: 1,
    );
    users.add(user);
    ownerProfiles.add(
      OwnerProfile(
        id: _id('own'),
        userId: user.id,
        displayName: name.trim(),
        phone: phone.trim(),
        bankName: 'BCA',
        bankAccountNumber: '0000000000',
        bankAccountHolder: name.trim(),
        isVerifiedOwner: false,
      ),
    );
    balances.add(OwnerBalance(
      ownerUserId: user.id,
      pendingAmount: 0,
      availableAmount: 0,
      paidOutAmount: 0,
    ));
    currentUser = user;
    _notify(user.id, 'register_owner', 'Akun owner aktif',
        'Kamu bisa langsung membuat listing.');
    _notifyAdmins('register_owner', 'Owner baru', '${user.name} mendaftar.');
    _audit(user.id, 'auth.register_owner', 'app_user', user.id, user.email);
    notifyListeners();
    return user;
  }

  void logout() {
    final String? actorId = currentUser?.id;
    if (actorId != null) {
      _audit(actorId, 'auth.logout', 'app_user', actorId, 'logout');
    }
    currentUser = null;
    notifyListeners();
  }

  void requestAccountDeletion(String userId) {
    if (!deletionRequests.contains(userId)) {
      deletionRequests.add(userId);
    }
    _notifyAdmins(
      'account_deletion',
      'Permintaan hapus akun',
      '${userById(userId)?.name ?? userId} meminta penghapusan akun.',
    );
    _audit(userId, 'privacy.request_account_deletion', 'app_user', userId, '');
    notifyListeners();
  }

  KostListing createListing({
    required String ownerUserId,
    required String title,
    required String city,
    required String area,
    required String address,
    required int monthlyPrice,
    PropertyType propertyType = PropertyType.kost,
    double campusDistanceKm = 1.0,
  }) {
    if (title.trim().isEmpty || address.trim().isEmpty || monthlyPrice <= 0) {
      throw ArgumentError('Nama, alamat, dan harga wajib valid.');
    }
    final String listingId = _id('kos');
    final KostListing listing = KostListing(
      id: listingId,
      ownerUserId: ownerUserId,
      title: title.trim(),
      description:
          'Listing dipublish langsung oleh owner. Admin tetap bisa suspend bila ada laporan.',
      address: address.trim(),
      city: city.trim().isEmpty ? 'Kota belum diisi' : city.trim(),
      area: area.trim().isEmpty ? 'Area umum' : area.trim(),
      propertyType: propertyType,
      campusDistanceKm: campusDistanceKm < 0 ? 0 : campusDistanceKm,
      genderPolicy: 'mixed',
      status: ListingStatus.published,
      minPrice: monthlyPrice,
      photos: const <String>[
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&w=1200&q=80',
      ],
      facilities: const <String>['WiFi', 'Parkir', 'Kamar mandi dalam'],
      rules: const <String>['Jaga kebersihan', 'Tidak membuat keributan'],
      isPremium: false,
      adCredits: 0,
      createdAt: DateTime.now(),
    );
    listings.insert(0, listing);
    units.add(
      KostUnit(
        id: _id('unt'),
        kostId: listingId,
        name: propertyType == PropertyType.kontrakan ? 'Unit Kontrakan' : 'Kamar Regular',
        monthlyPrice: monthlyPrice,
        depositAmount: 0,
        status: UnitStatus.available,
      ),
    );
    _notifyAdmins('listing_created', 'Listing baru published',
        '${listing.title} langsung tampil di marketplace.');
    _audit(ownerUserId, 'listing.create_publish', 'kost', listing.id, listing.title);
    notifyListeners();
    return listing;
  }

  void promoteListing(String actorUserId, String listingId) {
    final int index = listings.indexWhere((KostListing item) => item.id == listingId);
    if (index == -1) {
      return;
    }
    final KostListing listing = listings[index];
    if (listing.ownerUserId != actorUserId) {
      throw ArgumentError('Owner hanya bisa mempromosikan listing miliknya.');
    }
    listings[index] = listing.copyWith(
      isPremium: true,
      premiumUntil: DateTime.now().add(const Duration(days: 30)),
      adCredits: listing.adCredits + 1000,
    );
    _notify(actorUserId, 'premium_listing', 'Premium listing aktif',
        '${listing.title} diprioritaskan selama 30 hari.');
    _notifyAdmins('premium_listing', 'Premium listing dibeli', listing.title);
    _audit(actorUserId, 'listing.promote_premium', 'kost', listingId, 'Rp99.000 sandbox');
    notifyListeners();
  }

  void updateListingStatus(String actorUserId, String listingId, ListingStatus status) {
    final int index = listings.indexWhere((KostListing item) => item.id == listingId);
    if (index == -1) {
      return;
    }
    listings[index] = listings[index].copyWith(status: status);
    final KostListing listing = listings[index];
    _notify(listing.ownerUserId, 'listing_status', 'Status listing berubah',
        '${listing.title}: ${status.name}.');
    if (status == ListingStatus.suspended) {
      _notifyAdmins('listing_suspended', 'Listing disuspend', listing.title);
    }
    _audit(actorUserId, 'listing.status.${status.name}', 'kost', listingId, listing.title);
    notifyListeners();
  }

  void toggleFavorite(String userId, String kostId) {
    final int index = favorites.indexWhere(
      (FavoriteEntry item) => item.userId == userId && item.kostId == kostId,
    );
    if (index == -1) {
      favorites.add(FavoriteEntry(userId: userId, kostId: kostId));
    } else {
      favorites.removeAt(index);
    }
    notifyListeners();
  }

  Booking createBooking({
    required String customerUserId,
    required String listingId,
    required String unitId,
    required int durationMonths,
  }) {
    final KostListing listing = listingById(listingId);
    final KostUnit unit = unitById(unitId);
    if (!listing.isPublished || unit.status != UnitStatus.available) {
      throw ArgumentError('Unit tidak tersedia untuk booking.');
    }
    final Booking booking = Booking(
      id: _id('bok'),
      customerUserId: customerUserId,
      ownerUserId: listing.ownerUserId,
      kostId: listing.id,
      unitId: unit.id,
      startDate: DateTime.now().add(const Duration(days: 7)),
      durationMonths: durationMonths,
      rentAmount: unit.monthlyPrice * durationMonths + unit.depositAmount,
      status: BookingStatus.pendingPayment,
      createdAt: DateTime.now(),
    );
    bookings.insert(0, booking);
    _notify(customerUserId, 'booking_created', 'Booking dibuat',
        'Lanjutkan pembayaran penuh untuk ${listing.title}.');
    _notify(listing.ownerUserId, 'booking_created', 'Booking masuk',
        '${userById(customerUserId)?.name ?? 'Customer'} booking ${listing.title}.');
    _notifyAdmins('booking_created', 'Booking baru', '${booking.id} menunggu payment.');
    _audit(customerUserId, 'booking.create', 'booking', booking.id, listing.title);
    notifyListeners();
    return booking;
  }

  Payment createPayment(String actorUserId, String bookingId) {
    final Booking booking = bookings.firstWhere((Booking item) => item.id == bookingId);
    final Payment? existing = _paymentForBooking(bookingId);
    if (existing != null) {
      return existing;
    }
    if (booking.status != BookingStatus.pendingPayment) {
      throw ArgumentError('Booking tidak berada di status pending payment.');
    }
    final int platformFee = (booking.rentAmount * 3 / 100).round();
    final Payment payment = Payment(
      id: _id('pay'),
      bookingId: booking.id,
      customerUserId: booking.customerUserId,
      ownerUserId: booking.ownerUserId,
      kostId: booking.kostId,
      amount: booking.rentAmount,
      platformFee: platformFee,
      ownerAmount: booking.rentAmount - platformFee,
      merchantOrderId: 'KH-${booking.id}',
      duitkuReference: '-',
      paymentMethod: 'Duitku Sandbox',
      status: PaymentStatus.waitingPayment,
      paymentUrl: 'https://sandbox.duitku.com/payment/${booking.id}',
      expiredAt: DateTime.now().add(const Duration(hours: 24)),
    );
    payments.insert(0, payment);
    _notify(booking.customerUserId, 'payment_created', 'Payment dibuat',
        'Total ${formatRupiah(payment.amount)} menunggu pembayaran.');
    _notifyAdmins('payment_created', 'Payment dibuat', payment.merchantOrderId);
    _audit(actorUserId, 'payment.create_duitku', 'payment', payment.id, payment.merchantOrderId);
    notifyListeners();
    return payment;
  }

  void simulateDuitkuPaid(String actorUserId, String paymentId) {
    final int index = payments.indexWhere((Payment item) => item.id == paymentId);
    if (index == -1) {
      return;
    }
    final Payment payment = payments[index];
    if (payment.status == PaymentStatus.paid) {
      return;
    }
    payments[index] = payment.copyWith(
      status: PaymentStatus.paid,
      duitkuReference: 'DUITKU-${_sequence + 1}',
      paidAt: DateTime.now(),
    );
    paymentEvents.insert(
      0,
      PaymentEvent(
        id: _id('evt'),
        paymentId: payment.id,
        merchantOrderId: payment.merchantOrderId,
        eventType: 'callback_paid',
        signatureValid: true,
        amountMatch: true,
        createdAt: DateTime.now(),
      ),
    );
    _updateBookingStatus(payment.bookingId, BookingStatus.paid);
    _addPendingBalance(payment.ownerUserId, payment.ownerAmount);
    _notify(payment.customerUserId, 'payment_paid', 'Payment sukses',
        '${formatRupiah(payment.amount)} sudah diterima platform.');
    _notify(payment.ownerUserId, 'payment_paid', 'Booking sudah dibayar',
        'Saldo pending bertambah ${formatRupiah(payment.ownerAmount)}.');
    _notifyAdmins('payment_paid', 'Payment paid', payment.merchantOrderId);
    _audit(actorUserId, 'payment.callback_paid', 'payment', payment.id, payment.merchantOrderId);
    notifyListeners();
  }

  void confirmBooking(String actorUserId, String bookingId) {
    _updateBookingStatus(bookingId, BookingStatus.confirmed);
    final Booking booking = bookings.firstWhere((Booking item) => item.id == bookingId);
    _notify(booking.customerUserId, 'booking_confirmed', 'Booking confirmed',
        'Owner sudah mengkonfirmasi booking kamu.');
    _audit(actorUserId, 'booking.confirm', 'booking', bookingId, '');
    notifyListeners();
  }

  void completeBooking(String actorUserId, String bookingId) {
    _updateBookingStatus(bookingId, BookingStatus.completed);
    final Booking booking = bookings.firstWhere((Booking item) => item.id == bookingId);
    _releaseOwnerBalance(booking.ownerUserId);
    _notify(booking.customerUserId, 'booking_completed', 'Sewa selesai',
        'Kamu sekarang bisa memberi review.');
    _audit(actorUserId, 'booking.complete', 'booking', bookingId, '');
    notifyListeners();
  }

  RefundRequest requestRefund(String actorUserId, String paymentId, String reason) {
    final Payment payment = payments.firstWhere((Payment item) => item.id == paymentId);
    final RefundRequest refund = RefundRequest(
      id: _id('ref'),
      bookingId: payment.bookingId,
      paymentId: payment.id,
      amount: payment.amount,
      reason: reason.trim().isEmpty ? 'Permintaan refund customer' : reason.trim(),
      status: RefundStatus.requested,
      createdAt: DateTime.now(),
    );
    refunds.insert(0, refund);
    _updateBookingStatus(payment.bookingId, BookingStatus.disputed);
    _notifyAdmins('refund_requested', 'Refund diminta', refund.reason);
    _audit(actorUserId, 'refund.request', 'refund', refund.id, refund.reason);
    notifyListeners();
    return refund;
  }

  void processRefund(String actorUserId, String refundId) {
    final int index = refunds.indexWhere((RefundRequest item) => item.id == refundId);
    if (index == -1) {
      return;
    }
    refunds[index] = refunds[index].copyWith(status: RefundStatus.processed);
    final RefundRequest refund = refunds[index];
    final int paymentIndex = payments.indexWhere((Payment item) => item.id == refund.paymentId);
    if (paymentIndex != -1) {
      payments[paymentIndex] = payments[paymentIndex].copyWith(status: PaymentStatus.refunded);
      _updateBookingStatus(payments[paymentIndex].bookingId, BookingStatus.refunded);
      _notify(payments[paymentIndex].customerUserId, 'refund_processed',
          'Refund diproses', 'Refund ${formatRupiah(refund.amount)} selesai dicatat.');
    }
    _audit(actorUserId, 'refund.process', 'refund', refundId, '');
    notifyListeners();
  }

  Conversation openConversation({
    required String customerUserId,
    required String listingId,
  }) {
    final KostListing listing = listingById(listingId);
    for (final Conversation conversation in conversations) {
      if (conversation.kostId == listingId &&
          conversation.participantUserIds.contains(customerUserId) &&
          conversation.participantUserIds.contains(listing.ownerUserId)) {
        return conversation;
      }
    }
    final Conversation conversation = Conversation(
      id: _id('cnv'),
      kostId: listingId,
      participantUserIds: <String>[customerUserId, listing.ownerUserId],
      createdAt: DateTime.now(),
    );
    conversations.insert(0, conversation);
    _notify(listing.ownerUserId, 'chat_started', 'Chat baru',
        '${userById(customerUserId)?.name ?? 'Customer'} membuka chat ${listing.title}.');
    _audit(customerUserId, 'chat.open', 'conversation', conversation.id, listing.title);
    notifyListeners();
    return conversation;
  }

  void sendChatMessage(String senderUserId, String conversationId, String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Pesan tidak boleh kosong.');
    }
    final Conversation conversation = conversations.firstWhere(
      (Conversation item) => item.id == conversationId,
    );
    if (!conversation.participantUserIds.contains(senderUserId)) {
      throw ArgumentError('User bukan participant conversation.');
    }
    messages.add(
      ChatMessage(
        id: _id('msg'),
        conversationId: conversationId,
        senderUserId: senderUserId,
        body: trimmed,
        createdAt: DateTime.now(),
      ),
    );
    for (final String participant in conversation.participantUserIds) {
      if (participant != senderUserId) {
        _notify(participant, 'chat_message', 'Pesan baru', trimmed);
      }
    }
    _audit(senderUserId, 'chat.message', 'conversation', conversationId, '');
    notifyListeners();
  }

  List<ChatMessage> messagesForConversation(String conversationId) {
    return messages
        .where((ChatMessage item) => item.conversationId == conversationId)
        .toList()
      ..sort((ChatMessage a, ChatMessage b) => a.createdAt.compareTo(b.createdAt));
  }

  SupportThread openSupportThread({
    required String customerUserId,
    required String subject,
    String? bookingId,
    String? paymentId,
  }) {
    final SupportThread thread = SupportThread(
      id: _id('sup'),
      customerUserId: customerUserId,
      subject: subject.trim().isEmpty ? 'Customer Service' : subject.trim(),
      status: SupportStatus.open,
      bookingId: bookingId,
      paymentId: paymentId,
      createdAt: DateTime.now(),
    );
    supportThreads.insert(0, thread);
    _notifyAdmins('support_created', 'Support ticket baru', thread.subject);
    _audit(customerUserId, 'support.open', 'support_thread', thread.id, thread.subject);
    notifyListeners();
    return thread;
  }

  void sendSupportMessage(String senderUserId, String threadId, String body) {
    final String trimmed = body.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Pesan tidak boleh kosong.');
    }
    supportMessages.add(
      SupportNote(
        id: _id('spm'),
        threadId: threadId,
        senderUserId: senderUserId,
        body: trimmed,
        createdAt: DateTime.now(),
      ),
    );
    final SupportThread thread = supportThreads.firstWhere(
      (SupportThread item) => item.id == threadId,
    );
    final KhUser? sender = userById(senderUserId);
    if (sender?.role == KhRole.admin) {
      _notify(thread.customerUserId, 'support_reply', 'Admin membalas', trimmed);
    } else {
      _notifyAdmins('support_reply', 'Customer membalas support', trimmed);
    }
    _audit(senderUserId, 'support.message', 'support_thread', threadId, '');
    notifyListeners();
  }

  void updateSupportStatus(String actorUserId, String threadId, SupportStatus status) {
    final int index = supportThreads.indexWhere((SupportThread item) => item.id == threadId);
    if (index == -1) {
      return;
    }
    supportThreads[index] = supportThreads[index].copyWith(status: status);
    _audit(actorUserId, 'support.status.${status.name}', 'support_thread', threadId, '');
    notifyListeners();
  }

  List<SupportNote> messagesForSupportThread(String threadId) {
    return supportMessages
        .where((SupportNote item) => item.threadId == threadId)
        .toList()
      ..sort((SupportNote a, SupportNote b) => a.createdAt.compareTo(b.createdAt));
  }

  Payout requestPayout(String ownerUserId, int amount) {
    final OwnerBalance balance = balanceForOwner(ownerUserId);
    if (amount <= 0 || amount > balance.availableAmount) {
      throw ArgumentError('Nominal payout melebihi saldo available.');
    }
    final OwnerProfile? profile = ownerProfile(ownerUserId);
    final Payout payout = Payout(
      id: _id('pot'),
      ownerUserId: ownerUserId,
      amount: amount,
      status: PayoutStatus.requested,
      bankSnapshot:
          '${profile?.bankName ?? '-'} ${profile?.bankAccountNumber ?? '-'} a.n. ${profile?.bankAccountHolder ?? '-'}',
      createdAt: DateTime.now(),
    );
    payouts.insert(0, payout);
    _setBalance(
      balance.copyWith(availableAmount: balance.availableAmount - amount),
    );
    _notifyAdmins('payout_requested', 'Payout diminta',
        '${userById(ownerUserId)?.name ?? ownerUserId}: ${formatRupiah(amount)}');
    _audit(ownerUserId, 'payout.request', 'payout', payout.id, formatRupiah(amount));
    notifyListeners();
    return payout;
  }

  void processPayout(String actorUserId, String payoutId, PayoutStatus status) {
    final int index = payouts.indexWhere((Payout item) => item.id == payoutId);
    if (index == -1) {
      return;
    }
    final Payout payout = payouts[index];
    payouts[index] = payout.copyWith(
      status: status,
      paidAt: status == PayoutStatus.paid ? DateTime.now() : null,
    );
    if (status == PayoutStatus.paid) {
      final OwnerBalance balance = balanceForOwner(payout.ownerUserId);
      _setBalance(
        balance.copyWith(paidOutAmount: balance.paidOutAmount + payout.amount),
      );
      _notify(payout.ownerUserId, 'payout_paid', 'Payout selesai',
          '${formatRupiah(payout.amount)} sudah ditandai paid.');
    }
    _audit(actorUserId, 'payout.status.${status.name}', 'payout', payoutId, '');
    notifyListeners();
  }

  Review addReview({
    required String customerUserId,
    required String bookingId,
    required int rating,
    required String body,
  }) {
    final Booking booking = bookings.firstWhere((Booking item) => item.id == bookingId);
    if (booking.customerUserId != customerUserId || booking.status != BookingStatus.completed) {
      throw ArgumentError('Review hanya bisa dibuat setelah transaksi selesai.');
    }
    final Review review = Review(
      id: _id('rev'),
      bookingId: bookingId,
      customerUserId: customerUserId,
      kostId: booking.kostId,
      rating: rating.clamp(1, 5).toInt(),
      body: body.trim(),
      createdAt: DateTime.now(),
    );
    reviews.insert(0, review);
    _notify(booking.ownerUserId, 'review_created', 'Review baru',
        '${review.rating}/5 untuk ${listingById(booking.kostId).title}.');
    _audit(customerUserId, 'review.create', 'review', review.id, '');
    notifyListeners();
    return review;
  }

  ReportItem createReport({
    required String reporterUserId,
    required String targetType,
    required String targetId,
    required String reason,
  }) {
    final ReportItem report = ReportItem(
      id: _id('rpt'),
      reporterUserId: reporterUserId,
      targetType: targetType,
      targetId: targetId,
      reason: reason.trim().isEmpty ? 'Laporan user' : reason.trim(),
      status: ReportStatus.open,
      createdAt: DateTime.now(),
    );
    reports.insert(0, report);
    _notifyAdmins('report_created', 'Report baru', report.reason);
    _audit(reporterUserId, 'report.create', 'report', report.id, report.targetType);
    notifyListeners();
    return report;
  }

  void resolveReport(String actorUserId, String reportId, ReportStatus status) {
    final int index = reports.indexWhere((ReportItem item) => item.id == reportId);
    if (index == -1) {
      return;
    }
    reports[index] = reports[index].copyWith(status: status);
    _audit(actorUserId, 'report.status.${status.name}', 'report', reportId, '');
    notifyListeners();
  }

  void markNotificationRead(String notificationId) {
    final int index = notifications.indexWhere(
      (AppNotification item) => item.id == notificationId,
    );
    if (index == -1) {
      return;
    }
    notifications[index] = notifications[index].copyWith(readAt: DateTime.now());
    notifyListeners();
  }

  Payment? _paymentForBooking(String bookingId) {
    for (final Payment payment in payments) {
      if (payment.bookingId == bookingId) {
        return payment;
      }
    }
    return null;
  }

  void _updateBookingStatus(String bookingId, BookingStatus status) {
    final int index = bookings.indexWhere((Booking item) => item.id == bookingId);
    if (index != -1) {
      bookings[index] = bookings[index].copyWith(status: status);
    }
  }

  void _addPendingBalance(String ownerUserId, int amount) {
    final OwnerBalance balance = balanceForOwner(ownerUserId);
    _setBalance(balance.copyWith(pendingAmount: balance.pendingAmount + amount));
  }

  void _releaseOwnerBalance(String ownerUserId) {
    final OwnerBalance balance = balanceForOwner(ownerUserId);
    _setBalance(
      balance.copyWith(
        pendingAmount: 0,
        availableAmount: balance.availableAmount + balance.pendingAmount,
      ),
    );
  }

  void _setBalance(OwnerBalance updated) {
    final int index = balances.indexWhere(
      (OwnerBalance item) => item.ownerUserId == updated.ownerUserId,
    );
    if (index == -1) {
      balances.add(updated);
    } else {
      balances[index] = updated;
    }
  }

  void _notifyAdmins(String type, String title, String body) {
    for (final KhUser admin in users.where((KhUser user) => user.role == KhRole.admin)) {
      _notify(admin.id, type, title, body);
    }
  }

  void _notify(String recipientUserId, String type, String title, String body) {
    notifications.insert(
      0,
      AppNotification(
        id: _id('ntf'),
        recipientUserId: recipientUserId,
        actorUserId: currentUser?.id,
        type: type,
        title: title,
        body: body,
        createdAt: DateTime.now(),
      ),
    );
  }

  void _audit(
    String actorUserId,
    String action,
    String targetType,
    String targetId,
    String metadata,
  ) {
    auditLogs.insert(
      0,
      AuditLog(
        id: _id('aud'),
        actorUserId: actorUserId,
        action: action,
        targetType: targetType,
        targetId: targetId,
        metadata: metadata,
        createdAt: DateTime.now(),
      ),
    );
  }

  String _id(String prefix) {
    _sequence += 1;
    return '$prefix-${_sequence.toString().padLeft(4, '0')}';
  }

  void _seed() {
    final KhUser customer = KhUser(
      id: 'usr-customer',
      name: 'Nadia Putri',
      email: 'customer@kosthunt.test',
      phone: '628129990001',
      role: KhRole.customer,
    );
    final KhUser owner = KhUser(
      id: 'usr-owner',
      name: 'Ardi Properti',
      email: 'owner@kosthunt.test',
      phone: '628122220002',
      role: KhRole.owner,
      trustLevel: 1,
    );
    final KhUser admin = KhUser(
      id: 'usr-admin',
      name: 'Admin KostHunt',
      email: 'admin@kosthunt.test',
      phone: '628122220000',
      role: KhRole.admin,
      trustLevel: 99,
    );
    users.addAll(<KhUser>[customer, owner, admin]);
    ownerProfiles.add(
      const OwnerProfile(
        id: 'own-0001',
        userId: 'usr-owner',
        displayName: 'Ardi Properti',
        phone: '628122220002',
        bankName: 'BCA',
        bankAccountNumber: '1234567890',
        bankAccountHolder: 'Ardi Properti',
        isVerifiedOwner: false,
      ),
    );
    balances.add(
      const OwnerBalance(
        ownerUserId: 'usr-owner',
        pendingAmount: 0,
        availableAmount: 0,
        paidOutAmount: 0,
      ),
    );

    _seedListing(
      id: 'kos-0001',
      title: 'Kost Aurora Seturan',
      city: 'Yogyakarta',
      area: 'Seturan',
      price: 1650000,
      propertyType: PropertyType.kost,
      campusDistanceKm: 0.8,
      isPremium: true,
      image:
          'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?auto=format&fit=crop&w=1200&q=80',
      facilities: const <String>['WiFi', 'AC', 'Parkir', 'Laundry'],
    );
    _seedListing(
      id: 'kos-0002',
      title: 'Kost Sagara Pasteur',
      city: 'Bandung',
      area: 'Pasteur',
      price: 1850000,
      propertyType: PropertyType.kost,
      campusDistanceKm: 1.4,
      image:
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=1200&q=80',
      facilities: const <String>['WiFi', 'Kamar mandi dalam', 'Dapur bersama'],
    );
    _seedListing(
      id: 'kos-0003',
      title: 'Kost Nusa Tebet',
      city: 'Jakarta Selatan',
      area: 'Tebet',
      price: 2400000,
      propertyType: PropertyType.kost,
      campusDistanceKm: 2.3,
      image:
          'https://images.unsplash.com/photo-1493809842364-78817add7ffb?auto=format&fit=crop&w=1200&q=80',
      facilities: const <String>['WiFi', 'AC', 'CCTV', 'Cleaning service'],
    );
    _seedListing(
      id: 'kon-0001',
      title: 'Kontrakan Cendana Gejayan',
      city: 'Yogyakarta',
      area: 'Gejayan',
      price: 3200000,
      propertyType: PropertyType.kontrakan,
      campusDistanceKm: 1.0,
      image:
          'https://images.unsplash.com/photo-1570129477492-45c003edd2be?auto=format&fit=crop&w=1200&q=80',
      facilities: const <String>['WiFi', 'Parkir', 'Dapur pribadi', 'Ruang tamu'],
    );

    _notify(customer.id, 'welcome', 'Selamat datang', 'Marketplace siap dipakai.');
    _notify(owner.id, 'welcome', 'Dashboard owner siap', 'Listing bisa langsung publish.');
    _notify(admin.id, 'welcome', 'Admin console aktif', 'Pantau payment, payout, report, dan support.');
  }

  void _seedListing({
    required String id,
    required String title,
    required String city,
    required String area,
    required int price,
    required PropertyType propertyType,
    required double campusDistanceKm,
    required String image,
    required List<String> facilities,
    bool isPremium = false,
  }) {
    listings.add(
      KostListing(
        id: id,
        ownerUserId: 'usr-owner',
        title: title,
        description:
            'Kost siap huni dengan fasilitas lengkap, cocok untuk mahasiswa dan pekerja.',
        address: '$area, $city',
        city: city,
        area: area,
        propertyType: propertyType,
        campusDistanceKm: campusDistanceKm,
        genderPolicy: 'mixed',
        status: ListingStatus.published,
        minPrice: price,
        photos: <String>[image],
        facilities: facilities,
        rules: const <String>['Tidak merokok di kamar', 'Tamu wajib lapor', 'Jam tenang mulai 22.00'],
        isPremium: isPremium,
        adCredits: isPremium ? 850 : 0,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        premiumUntil: isPremium ? DateTime.now().add(const Duration(days: 21)) : null,
      ),
    );
    units.addAll(<KostUnit>[
      KostUnit(
        id: 'unt-$id-a',
        kostId: id,
        name: propertyType == PropertyType.kontrakan ? 'Unit Kontrakan' : 'Kamar Regular',
        monthlyPrice: price,
        depositAmount: 0,
        status: UnitStatus.available,
      ),
      KostUnit(
        id: 'unt-$id-b',
        kostId: id,
        name: propertyType == PropertyType.kontrakan ? 'Unit Furnished' : 'Kamar Premium',
        monthlyPrice: price + 350000,
        depositAmount: 0,
        status: UnitStatus.available,
      ),
    ]);
  }
}
