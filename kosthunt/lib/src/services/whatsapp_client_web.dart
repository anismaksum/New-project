import 'dart:async';
import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html';

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
  }) {
    final Completer<WhatsAppClientResponse> completer =
        Completer<WhatsAppClientResponse>();
    final HttpRequest request = HttpRequest();

    request
      ..open('POST', endpoint)
      ..timeout = 8000
      ..setRequestHeader('Content-Type', 'application/json');

    request.onLoadEnd.listen((ProgressEvent event) {
      if (completer.isCompleted) {
        return;
      }
      completer
          .complete(_parseResponse(request.status ?? 0, request.responseText));
    });
    request.onError.listen((ProgressEvent event) {
      if (completer.isCompleted) {
        return;
      }
      completer.complete(
        const WhatsAppClientResponse(
          success: false,
          reference: 'WA-BACKEND-OFFLINE',
          message:
              'Backend WhatsApp belum aktif atau CORS belum terbuka. Jalankan server lokal.',
        ),
      );
    });
    request.onTimeout.listen((ProgressEvent event) {
      if (completer.isCompleted) {
        return;
      }
      completer.complete(
        const WhatsAppClientResponse(
          success: false,
          reference: 'WA-TIMEOUT',
          message: 'Backend WhatsApp timeout. Coba jalankan ulang server lokal.',
        ),
      );
    });

    request.send(
      jsonEncode(<String, String>{
        'target': target,
        'message': message,
        'referenceId': referenceId,
        'type': type,
      }),
    );

    return completer.future;
  }

  WhatsAppClientResponse _parseResponse(int statusCode, String? body) {
    final String raw = body ?? '';
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      return WhatsAppClientResponse(
        success: data['status'] == true,
        reference: _referenceFrom(data),
        message: _messageFrom(data, statusCode),
      );
    } on Object {
      return WhatsAppClientResponse(
        success: false,
        reference: 'WA-INVALID-RESPONSE',
        message: raw.isEmpty ? 'Response backend kosong.' : raw,
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
