class WhatsAppClientResponse {
  const WhatsAppClientResponse({
    required this.success,
    required this.reference,
    required this.message,
  });

  final bool success;
  final String reference;
  final String message;
}

class WhatsAppClient {
  const WhatsAppClient({
    this.endpoint = 'http://127.0.0.1:8787/api/whatsapp/send',
  });

  final String endpoint;

  Future<WhatsAppClientResponse> send({
    required String target,
    required String message,
    required String referenceId,
    required String type,
  }) async {
    return const WhatsAppClientResponse(
      success: false,
      reference: 'WA-UNSUPPORTED',
      message: 'Platform ini belum mendukung client WhatsApp.',
    );
  }
}
