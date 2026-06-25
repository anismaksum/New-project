class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.text,
    required this.timeLabel,
    required this.sentByCustomer,
    required this.deliveryStatus,
    required this.reference,
  });

  final String id;
  final String text;
  final String timeLabel;
  final bool sentByCustomer;
  final String deliveryStatus;
  final String reference;

  SupportMessage copyWith({
    String? deliveryStatus,
    String? reference,
  }) {
    return SupportMessage(
      id: id,
      text: text,
      timeLabel: timeLabel,
      sentByCustomer: sentByCustomer,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      reference: reference ?? this.reference,
    );
  }

  Map<String, Object?> toDatabase({required String bookingId}) {
    return <String, Object?>{
      'id': id,
      'booking_id': bookingId,
      'sender_role': sentByCustomer ? 'customer' : 'admin',
      'sender_name': sentByCustomer ? 'Calon Penghuni' : 'Admin KostHunt',
      'body': text,
      'delivery_status': deliveryStatus,
      'notification_reference': reference,
    };
  }

  Map<String, Object?> toSupportDatabase({
    required String customerName,
    required String customerPhone,
  }) {
    return <String, Object?>{
      'id': id,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'body': text,
      'sent_by_customer': sentByCustomer,
      'delivery_status': deliveryStatus,
      'notification_reference': reference,
    };
  }

  static SupportMessage fromDatabase(Map<String, Object?> data) {
    return SupportMessage(
      id: data['id'] as String,
      text: data['body'] as String,
      timeLabel: _timeLabel(data['created_at']?.toString()),
      sentByCustomer: data['sender_role'] == 'customer',
      deliveryStatus: data['delivery_status'] as String,
      reference: data['notification_reference'] as String,
    );
  }

  static SupportMessage fromSupportDatabase(Map<String, Object?> data) {
    return SupportMessage(
      id: data['id'] as String,
      text: data['body'] as String,
      timeLabel: _timeLabel(data['created_at']?.toString()),
      sentByCustomer: data['sent_by_customer'] as bool,
      deliveryStatus: data['delivery_status'] as String,
      reference: data['notification_reference'] as String,
    );
  }

  static String _timeLabel(String? value) {
    if (value == null) {
      return '-';
    }
    final DateTime? parsed = DateTime.tryParse(value);
    if (parsed == null) {
      return '-';
    }
    final String hour = parsed.hour.toString().padLeft(2, '0');
    final String minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
