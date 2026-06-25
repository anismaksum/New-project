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

  Map<String, Object?> toDatabase() {
    return <String, Object?>{
      'id': id,
      'kost_id': kost.id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'schedule_label': scheduleLabel,
      'status': _statusToDatabase(status),
      'notification_status': notificationStatus,
      'notification_reference': notificationReference,
      'notification_message': notificationMessage,
    };
  }

  static BookingRequest fromDatabase(
    Map<String, Object?> data, {
    required Kost kost,
  }) {
    return BookingRequest(
      id: data['id'] as String,
      kost: kost,
      customerName: data['customer_name'] as String,
      customerPhone: data['customer_phone'] as String,
      scheduleLabel: data['schedule_label'] as String,
      status: _statusFromDatabase(data['status'] as String),
      notificationStatus: data['notification_status'] as String,
      notificationReference: data['notification_reference'] as String,
      notificationMessage: data['notification_message'] as String,
    );
  }

  static String _statusToDatabase(String status) {
    switch (status) {
      case 'Diterima':
        return 'accepted';
      case 'Ditolak':
        return 'rejected';
      case 'Dibatalkan':
        return 'cancelled';
      case 'Selesai':
        return 'completed';
      case 'Pending':
      default:
        return 'pending';
    }
  }

  static String _statusFromDatabase(String status) {
    switch (status) {
      case 'accepted':
        return 'Diterima';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      case 'completed':
        return 'Selesai';
      case 'pending':
      default:
        return 'Pending';
    }
  }
}
