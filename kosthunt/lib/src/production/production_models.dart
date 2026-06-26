enum KhRole { customer, owner, admin }

enum PropertyType { kost, kontrakan }

enum ListingStatus { published, paused, suspended, deleted }

enum UnitStatus { available, occupied, maintenance, inactive }

enum BookingStatus {
  draft,
  pendingPayment,
  paid,
  confirmed,
  checkedIn,
  completed,
  cancelled,
  refunded,
  disputed,
}

enum PaymentStatus {
  pending,
  waitingPayment,
  paid,
  failed,
  expired,
  cancelled,
  refunded,
  partiallyRefunded,
}

enum PayoutStatus { requested, approved, paid, rejected, cancelled }

enum RefundStatus { requested, approved, processed, rejected, cancelled }

enum SupportStatus { open, pending, resolved, closed }

enum ReportStatus { open, reviewing, resolved, rejected }

class KhUser {
  const KhUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.status = 'active',
    this.trustLevel = 0,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final KhRole role;
  final String status;
  final int trustLevel;

  String get roleLabel {
    switch (role) {
      case KhRole.customer:
        return 'Customer';
      case KhRole.owner:
        return 'Owner';
      case KhRole.admin:
        return 'Admin';
    }
  }

  KhUser copyWith({
    String? name,
    String? phone,
    String? status,
    int? trustLevel,
  }) {
    return KhUser(
      id: id,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      status: status ?? this.status,
      trustLevel: trustLevel ?? this.trustLevel,
    );
  }
}

class OwnerProfile {
  const OwnerProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.phone,
    required this.bankName,
    required this.bankAccountNumber,
    required this.bankAccountHolder,
    required this.isVerifiedOwner,
  });

  final String id;
  final String userId;
  final String displayName;
  final String phone;
  final String bankName;
  final String bankAccountNumber;
  final String bankAccountHolder;
  final bool isVerifiedOwner;
}

class KostListing {
  const KostListing({
    required this.id,
    required this.ownerUserId,
    required this.title,
    required this.description,
    required this.address,
    required this.city,
    required this.area,
    required this.propertyType,
    required this.campusDistanceKm,
    required this.genderPolicy,
    required this.status,
    required this.minPrice,
    required this.photos,
    required this.facilities,
    required this.rules,
    required this.isPremium,
    required this.adCredits,
    required this.createdAt,
    this.premiumUntil,
  });

  final String id;
  final String ownerUserId;
  final String title;
  final String description;
  final String address;
  final String city;
  final String area;
  final PropertyType propertyType;
  final double campusDistanceKm;
  final String genderPolicy;
  final ListingStatus status;
  final int minPrice;
  final List<String> photos;
  final List<String> facilities;
  final List<String> rules;
  final bool isPremium;
  final int adCredits;
  final DateTime createdAt;
  final DateTime? premiumUntil;

  bool get isPublished => status == ListingStatus.published;

  bool get isPremiumActive {
    return isPremium && (premiumUntil == null || premiumUntil!.isAfter(DateTime.now()));
  }

  String get typeLabel {
    switch (propertyType) {
      case PropertyType.kost:
        return 'Kost';
      case PropertyType.kontrakan:
        return 'Kontrakan';
    }
  }

  KostListing copyWith({
    String? title,
    String? description,
    String? address,
    String? city,
    String? area,
    PropertyType? propertyType,
    double? campusDistanceKm,
    String? genderPolicy,
    ListingStatus? status,
    int? minPrice,
    List<String>? photos,
    List<String>? facilities,
    List<String>? rules,
    bool? isPremium,
    int? adCredits,
    DateTime? premiumUntil,
  }) {
    return KostListing(
      id: id,
      ownerUserId: ownerUserId,
      title: title ?? this.title,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      area: area ?? this.area,
      propertyType: propertyType ?? this.propertyType,
      campusDistanceKm: campusDistanceKm ?? this.campusDistanceKm,
      genderPolicy: genderPolicy ?? this.genderPolicy,
      status: status ?? this.status,
      minPrice: minPrice ?? this.minPrice,
      photos: photos ?? this.photos,
      facilities: facilities ?? this.facilities,
      rules: rules ?? this.rules,
      isPremium: isPremium ?? this.isPremium,
      adCredits: adCredits ?? this.adCredits,
      createdAt: createdAt,
      premiumUntil: premiumUntil ?? this.premiumUntil,
    );
  }
}

class KostUnit {
  const KostUnit({
    required this.id,
    required this.kostId,
    required this.name,
    required this.monthlyPrice,
    required this.depositAmount,
    required this.status,
  });

  final String id;
  final String kostId;
  final String name;
  final int monthlyPrice;
  final int depositAmount;
  final UnitStatus status;

  KostUnit copyWith({UnitStatus? status}) {
    return KostUnit(
      id: id,
      kostId: kostId,
      name: name,
      monthlyPrice: monthlyPrice,
      depositAmount: depositAmount,
      status: status ?? this.status,
    );
  }
}

class FavoriteEntry {
  const FavoriteEntry({required this.userId, required this.kostId});

  final String userId;
  final String kostId;
}

class Booking {
  const Booking({
    required this.id,
    required this.customerUserId,
    required this.ownerUserId,
    required this.kostId,
    required this.unitId,
    required this.startDate,
    required this.durationMonths,
    required this.rentAmount,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String customerUserId;
  final String ownerUserId;
  final String kostId;
  final String unitId;
  final DateTime startDate;
  final int durationMonths;
  final int rentAmount;
  final BookingStatus status;
  final DateTime createdAt;

  Booking copyWith({BookingStatus? status}) {
    return Booking(
      id: id,
      customerUserId: customerUserId,
      ownerUserId: ownerUserId,
      kostId: kostId,
      unitId: unitId,
      startDate: startDate,
      durationMonths: durationMonths,
      rentAmount: rentAmount,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.ownerUserId,
    required this.kostId,
    required this.amount,
    required this.platformFee,
    required this.ownerAmount,
    required this.merchantOrderId,
    required this.duitkuReference,
    required this.paymentMethod,
    required this.status,
    required this.paymentUrl,
    required this.expiredAt,
    this.paidAt,
  });

  final String id;
  final String bookingId;
  final String customerUserId;
  final String ownerUserId;
  final String kostId;
  final int amount;
  final int platformFee;
  final int ownerAmount;
  final String merchantOrderId;
  final String duitkuReference;
  final String paymentMethod;
  final PaymentStatus status;
  final String paymentUrl;
  final DateTime expiredAt;
  final DateTime? paidAt;

  Payment copyWith({
    PaymentStatus? status,
    String? duitkuReference,
    DateTime? paidAt,
  }) {
    return Payment(
      id: id,
      bookingId: bookingId,
      customerUserId: customerUserId,
      ownerUserId: ownerUserId,
      kostId: kostId,
      amount: amount,
      platformFee: platformFee,
      ownerAmount: ownerAmount,
      merchantOrderId: merchantOrderId,
      duitkuReference: duitkuReference ?? this.duitkuReference,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      paymentUrl: paymentUrl,
      expiredAt: expiredAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}

class PaymentEvent {
  const PaymentEvent({
    required this.id,
    required this.paymentId,
    required this.merchantOrderId,
    required this.eventType,
    required this.signatureValid,
    required this.amountMatch,
    required this.createdAt,
  });

  final String id;
  final String paymentId;
  final String merchantOrderId;
  final String eventType;
  final bool signatureValid;
  final bool amountMatch;
  final DateTime createdAt;
}

class OwnerBalance {
  const OwnerBalance({
    required this.ownerUserId,
    required this.pendingAmount,
    required this.availableAmount,
    required this.paidOutAmount,
  });

  final String ownerUserId;
  final int pendingAmount;
  final int availableAmount;
  final int paidOutAmount;

  OwnerBalance copyWith({
    int? pendingAmount,
    int? availableAmount,
    int? paidOutAmount,
  }) {
    return OwnerBalance(
      ownerUserId: ownerUserId,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      availableAmount: availableAmount ?? this.availableAmount,
      paidOutAmount: paidOutAmount ?? this.paidOutAmount,
    );
  }
}

class Payout {
  const Payout({
    required this.id,
    required this.ownerUserId,
    required this.amount,
    required this.status,
    required this.bankSnapshot,
    required this.createdAt,
    this.paidAt,
  });

  final String id;
  final String ownerUserId;
  final int amount;
  final PayoutStatus status;
  final String bankSnapshot;
  final DateTime createdAt;
  final DateTime? paidAt;

  Payout copyWith({PayoutStatus? status, DateTime? paidAt}) {
    return Payout(
      id: id,
      ownerUserId: ownerUserId,
      amount: amount,
      status: status ?? this.status,
      bankSnapshot: bankSnapshot,
      createdAt: createdAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}

class RefundRequest {
  const RefundRequest({
    required this.id,
    required this.bookingId,
    required this.paymentId,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String paymentId;
  final int amount;
  final String reason;
  final RefundStatus status;
  final DateTime createdAt;

  RefundRequest copyWith({RefundStatus? status}) {
    return RefundRequest(
      id: id,
      bookingId: bookingId,
      paymentId: paymentId,
      amount: amount,
      reason: reason,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.kostId,
    required this.participantUserIds,
    required this.createdAt,
  });

  final String id;
  final String kostId;
  final List<String> participantUserIds;
  final DateTime createdAt;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    required this.body,
    required this.createdAt,
    this.readAtBy = const <String, DateTime>{},
  });

  final String id;
  final String conversationId;
  final String senderUserId;
  final String body;
  final DateTime createdAt;
  final Map<String, DateTime> readAtBy;
}

class SupportThread {
  const SupportThread({
    required this.id,
    required this.customerUserId,
    required this.subject,
    required this.status,
    required this.createdAt,
    this.bookingId,
    this.paymentId,
  });

  final String id;
  final String customerUserId;
  final String subject;
  final SupportStatus status;
  final DateTime createdAt;
  final String? bookingId;
  final String? paymentId;

  SupportThread copyWith({SupportStatus? status}) {
    return SupportThread(
      id: id,
      customerUserId: customerUserId,
      subject: subject,
      status: status ?? this.status,
      createdAt: createdAt,
      bookingId: bookingId,
      paymentId: paymentId,
    );
  }
}

class SupportNote {
  const SupportNote({
    required this.id,
    required this.threadId,
    required this.senderUserId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String threadId;
  final String senderUserId;
  final String body;
  final DateTime createdAt;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.recipientUserId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.actorUserId,
    this.readAt,
  });

  final String id;
  final String recipientUserId;
  final String? actorUserId;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  AppNotification copyWith({DateTime? readAt}) {
    return AppNotification(
      id: id,
      recipientUserId: recipientUserId,
      actorUserId: actorUserId,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.customerUserId,
    required this.kostId,
    required this.rating,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String customerUserId;
  final String kostId;
  final int rating;
  final String body;
  final DateTime createdAt;
}

class ReportItem {
  const ReportItem({
    required this.id,
    required this.reporterUserId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reporterUserId;
  final String targetType;
  final String targetId;
  final String reason;
  final ReportStatus status;
  final DateTime createdAt;

  ReportItem copyWith({ReportStatus? status}) {
    return ReportItem(
      id: id,
      reporterUserId: reporterUserId,
      targetType: targetType,
      targetId: targetId,
      reason: reason,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}

class AuditLog {
  const AuditLog({
    required this.id,
    required this.actorUserId,
    required this.action,
    required this.targetType,
    required this.targetId,
    required this.metadata,
    required this.createdAt,
  });

  final String id;
  final String actorUserId;
  final String action;
  final String targetType;
  final String targetId;
  final String metadata;
  final DateTime createdAt;
}

String rolePath(KhRole role) {
  switch (role) {
    case KhRole.customer:
      return '/customer';
    case KhRole.owner:
      return '/owner';
    case KhRole.admin:
      return '/admin';
  }
}

String formatRupiah(int value) {
  final String raw = value.toString();
  final StringBuffer buffer = StringBuffer();
  for (var i = 0; i < raw.length; i += 1) {
    final int reverseIndex = raw.length - i;
    buffer.write(raw[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp$buffer';
}

String shortDate(DateTime value) {
  final String day = value.day.toString().padLeft(2, '0');
  final String month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String clock(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
