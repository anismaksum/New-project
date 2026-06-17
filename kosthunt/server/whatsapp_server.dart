import 'dart:convert';
import 'dart:io';

import '../lib/src/config/app_config.dart';

const String _defaultAdminTarget = AppConfig.adminWhatsapp;

Future<void> main(List<String> args) async {
  final int port =
      int.tryParse(Platform.environment['WHATSAPP_PORT'] ?? '') ?? 8787;
  final HttpServer server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    port,
  );

  stdout.writeln('KostHunt WhatsApp server running at http://127.0.0.1:$port');
  stdout.writeln('Health check: http://127.0.0.1:$port/health');
  stdout.writeln(
    _token.isEmpty
        ? 'FONNTE_TOKEN belum diset. Request WhatsApp akan ditolak.'
        : 'FONNTE_TOKEN terdeteksi. Server siap mengirim WhatsApp.',
  );

  await for (final HttpRequest request in server) {
    await _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  _setCorsHeaders(request.response);

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  if (request.method == 'GET' && request.uri.path == '/health') {
    await _sendJson(request.response, <String, Object>{
      'status': true,
      'service': 'kosthunt-whatsapp-server',
      'provider': 'fonnte',
      'tokenConfigured': _token.isNotEmpty,
      'defaultAdminTarget': _normalizePhone(_defaultAdminTarget),
    });
    return;
  }

  if (request.method == 'POST' &&
      (request.uri.path == '/api/whatsapp/send' ||
          request.uri.path == '/api/send-whatsapp')) {
    await _sendWhatsapp(request);
    return;
  }

  request.response.statusCode = HttpStatus.notFound;
  await _sendJson(request.response, <String, Object>{
    'status': false,
    'reason': 'route not found',
  });
}

Future<void> _sendWhatsapp(HttpRequest request) async {
  final String body = await utf8.decoder.bind(request).join();
  final Map<String, dynamic> payload = _decodeBody(body);

  if (_token.isEmpty) {
    await _sendJson(request.response, <String, Object>{
      'status': false,
      'reference': 'WA-TOKEN-MISSING',
      'reason': 'FONNTE_TOKEN belum diset di terminal server.',
    });
    return;
  }

  final String target = _normalizePhone(
    (payload['target'] as String?)?.trim().isNotEmpty == true
        ? payload['target'] as String
        : _defaultAdminTarget,
  );
  final String message = (payload['message'] as String?)?.trim() ?? '';
  final String referenceId =
      (payload['referenceId'] as String?)?.trim() ?? '-';
  final String type = (payload['type'] as String?)?.trim() ?? 'whatsapp';

  if (message.isEmpty) {
    await _sendJson(request.response, <String, Object>{
      'status': false,
      'reference': 'WA-MESSAGE-EMPTY',
      'reason': 'message wajib diisi.',
    });
    return;
  }

  try {
    final Map<String, dynamic> provider = await _postToWhatsAppProvider(
      target: target,
      message: message,
    );
    final bool success = provider['status'] == true;
    await _sendJson(request.response, <String, Object?>{
      'status': success,
      'reference': provider['requestid']?.toString() ??
          provider['id']?.toString() ??
          'WA-$referenceId',
      'message': success
          ? 'WhatsApp $type $referenceId terkirim ke $target.'
          : (provider['reason'] ?? 'Provider WhatsApp menolak request.')
              .toString(),
      'detail': provider['detail'],
      'reason': provider['reason'],
      'target': target,
    });
  } on Object catch (error) {
    request.response.statusCode = HttpStatus.badGateway;
    await _sendJson(request.response, <String, Object>{
      'status': false,
      'reference': 'WA-UPSTREAM-ERROR',
      'reason': 'Gagal menghubungi provider WhatsApp: $error',
    });
  }
}

Future<Map<String, dynamic>> _postToWhatsAppProvider({
  required String target,
  required String message,
}) async {
  final HttpClient client = HttpClient();
  try {
    final HttpClientRequest request = await client.postUrl(
      Uri.parse('https://api.fonnte.com/send'),
    );
    request.headers.set('Authorization', _token);
    request.headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
      charset: 'utf-8',
    );
    request.write(
      Uri(
        queryParameters: <String, String>{
          'target': target,
          'message': message,
          'countryCode': '62',
          'typing': 'true',
          'delay': '1',
        },
      ).query,
    );

    final HttpClientResponse response = await request.close();
    final String responseBody = await response.transform(utf8.decoder).join();
    final Object? decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{
      'status': false,
      'reason': 'Response provider WhatsApp bukan JSON object.',
      'body': responseBody,
    };
  } finally {
    client.close(force: true);
  }
}

Map<String, dynamic> _decodeBody(String body) {
  if (body.trim().isEmpty) {
    return <String, dynamic>{};
  }
  final Object? decoded = jsonDecode(body);
  if (decoded is Map<String, dynamic>) {
    return decoded;
  }
  return <String, dynamic>{};
}

String get _token => Platform.environment['FONNTE_TOKEN']?.trim() ?? '';

String _normalizePhone(String value) {
  final String digits = value.replaceAll(RegExp('[^0-9]'), '');
  if (digits.startsWith('0')) {
    return '62${digits.substring(1)}';
  }
  if (digits.startsWith('62')) {
    return digits;
  }
  return '62$digits';
}

void _setCorsHeaders(HttpResponse response) {
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type')
    ..set('Access-Control-Max-Age', '86400');
}

Future<void> _sendJson(
  HttpResponse response,
  Map<String, Object?> data,
) async {
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(data));
  await response.close();
}
