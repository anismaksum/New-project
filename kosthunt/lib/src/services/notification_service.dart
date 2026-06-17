import '../config/app_config.dart';
import '../models/booking_request.dart';
import '../models/kost.dart';
import 'whatsapp_client.dart';

class NotificationResult {
  const NotificationResult({
    required this.success,
    required this.reference,
    required this.message,
  });

  final bool success;
  final String reference;
  final String message;
}

class NotificationService {
  const NotificationService({this.client = const WhatsAppClient()});

  final WhatsAppClient client;

  Future<NotificationResult> sendBookingCreatedToAdmin({
    required BookingRequest booking,
    required Kost kost,
  }) async {
    final WhatsAppClientResponse response = await client.send(
      target: AppConfig.adminWhatsapp,
      message: _bookingCreatedMessage(booking: booking, kost: kost),
      referenceId: booking.id,
      type: 'booking-created-admin',
    );
    return _resultFrom(response);
  }

  Future<NotificationResult> sendBookingStatusToCustomer({
    required BookingRequest booking,
    required String status,
  }) async {
    final WhatsAppClientResponse response = await client.send(
      target: booking.customerPhone,
      message: _bookingStatusMessage(booking: booking, status: status),
      referenceId: booking.id,
      type: 'booking-status-customer',
    );
    return _resultFrom(response);
  }

  Future<NotificationResult> sendCustomerSupportToAdmin({
    required String message,
    required String customerName,
    required String customerPhone,
    required String messageId,
  }) async {
    final WhatsAppClientResponse response = await client.send(
      target: AppConfig.adminWhatsapp,
      message: _supportMessage(
        message: message,
        customerName: customerName,
        customerPhone: customerPhone,
        messageId: messageId,
      ),
      referenceId: messageId,
      type: 'customer-support-admin',
    );
    return _resultFrom(response);
  }

  NotificationResult _resultFrom(WhatsAppClientResponse response) {
    return NotificationResult(
      success: response.success,
      reference: response.reference,
      message: response.message,
    );
  }

  String _bookingCreatedMessage({
    required BookingRequest booking,
    required Kost kost,
  }) {
    return 'Halo Admin KostHunt, ada booking kamar baru.\n\n'
        'Listing: ${kost.name}\n'
        'Owner: ${kost.ownerName}\n'
        'Nomor owner: ${kost.ownerPhone}\n'
        'Customer: ${booking.customerName}\n'
        'Nomor customer: ${booking.customerPhone}\n'
        'Jadwal: ${booking.scheduleLabel}\n'
        'Kode booking: ${booking.id}\n\n'
        'Pesanan sudah masuk ke aplikasi admin dan menunggu konfirmasi.';
  }

  String _bookingStatusMessage({
    required BookingRequest booking,
    required String status,
  }) {
    return 'Halo ${booking.customerName}, status booking KostHunt kamu diperbarui.\n\n'
        'Listing: ${booking.kost.name}\n'
        'Status: $status\n'
        'Kode booking: ${booking.id}\n\n'
        'Terima kasih sudah memakai KostHunt.';
  }

  String _supportMessage({
    required String message,
    required String customerName,
    required String customerPhone,
    required String messageId,
  }) {
    return 'Halo Admin KostHunt, ada pesan customer dari aplikasi.\n\n'
        'Customer: $customerName\n'
        'Nomor customer: $customerPhone\n'
        'Kode pesan: $messageId\n\n'
        '$message';
  }
}
