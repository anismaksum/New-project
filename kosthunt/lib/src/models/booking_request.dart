import 'kost.dart';

class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.kost,
    required this.customerName,
    required this.customerPhone,
    required this.scheduleLabel,
    required this.status,
    required this.notificationStatus,
    required this.notificationReference,
    required this.notificationMessage,
  });

  final String id;
  final Kost kost;
  final String customerName;
  final String customerPhone;
  final String scheduleLabel;
  final String status;
  final String notificationStatus;
  final String notificationReference;
  final String notificationMessage;

  BookingRequest copyWith({
    String? status,
    String? notificationStatus,
    String? notificationReference,
    String? notificationMessage,
  }) {
    return BookingRequest(
      id: id,
      kost: kost,
      customerName: customerName,
      customerPhone: customerPhone,
      scheduleLabel: scheduleLabel,
      status: status ?? this.status,
      notificationStatus: notificationStatus ?? this.notificationStatus,
      notificationReference:
          notificationReference ?? this.notificationReference,
      notificationMessage: notificationMessage ?? this.notificationMessage,
    );
  }
}
