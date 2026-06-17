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
}
