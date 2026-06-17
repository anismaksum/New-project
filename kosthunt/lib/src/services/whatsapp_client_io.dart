import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest request = await client
          .postUrl(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 5));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode(<String, String>{
          'target': target,
          'message': message,
          'referenceId': referenceId,
          'type': type,
        }),
      );

      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 8));
      final String body = await response.transform(utf8.decoder).join();
      return _parseResponse(response.statusCode, body);
    } on TimeoutException {
      return const WhatsAppClientResponse(
        success: false,
        reference: 'WA-TIMEOUT',
        message:
            'Backend WhatsApp belum merespons. Jalankan server lokal lalu coba lagi.',
      );
    } on Object catch (error) {
      return WhatsAppClientResponse(
        success: false,
        reference: 'WA-BACKEND-OFFLINE',
        message: 'Backend WhatsApp belum aktif: $error',
      );
    } finally {
      client.close(force: true);
    }
  }

  WhatsAppClientResponse _parseResponse(int statusCode, String body) {
    try {
      final Map<String, dynamic> data =
          jsonDecode(body) as Map<String, dynamic>;
      return WhatsAppClientResponse(
        success: data['status'] == true,
        reference: _referenceFrom(data),
        message: _messageFrom(data, statusCode),
      );
    } on Object {
      return WhatsAppClientResponse(
        success: false,
        reference: 'WA-INVALID-RESPONSE',
        message: body.isEmpty ? 'Response backend kosong.' : body,
      );
    }
  }

  String _referenceFrom(Map<String, dynamic> data) {
    final Object? reference = data['reference'] ?? data['requestid'];
    if (reference != null) {
      return reference.toString();
    }
    final Object? ids = data['id'];
    if (ids is List<dynamic> && ids.isNotEmpty) {
      return ids.join(',');
    }
    return 'WA-NO-REFERENCE';
  }

  String _messageFrom(Map<String, dynamic> data, int statusCode) {
    final Object? message = data['message'] ?? data['detail'] ?? data['reason'];
    if (message != null) {
      return message.toString();
    }
    return 'Backend WhatsApp merespons HTTP $statusCode.';
  }
}
