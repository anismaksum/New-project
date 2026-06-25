import 'dart:async';
import 'dart:convert';
// ignore: deprecated_member_use
import 'dart:html';

class SupabaseRestResponse {
  const SupabaseRestResponse({
    required this.statusCode,
    required this.body,
  });

  final int statusCode;
  final String body;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

class SupabaseRestClient {
  const SupabaseRestClient();

  Future<SupabaseRestResponse> request({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) {
    final Completer<SupabaseRestResponse> completer =
        Completer<SupabaseRestResponse>();
    final HttpRequest request = HttpRequest();

    request
      ..open(method, uri.toString())
      ..timeout = 12000;
    headers.forEach((String name, String value) {
      request.setRequestHeader(name, value);
    });

    request.onLoadEnd.listen((ProgressEvent event) {
      if (completer.isCompleted) {
        return;
      }
      completer.complete(
        SupabaseRestResponse(
          statusCode: request.status ?? 0,
          body: request.responseText ?? '',
        ),
      );
    });
    request.onError.listen((ProgressEvent event) {
      if (completer.isCompleted) {
        return;
      }
      completer.complete(
        const SupabaseRestResponse(
          statusCode: 0,
          body: '{"message":"Supabase request failed"}',
        ),
      );
    });
    request.onTimeout.listen((ProgressEvent event) {
      if (completer.isCompleted) {
        return;
      }
      completer.complete(
        const SupabaseRestResponse(
          statusCode: 408,
          body: '{"message":"Supabase request timeout"}',
        ),
      );
    });

    request.send(body == null ? null : jsonEncode(body));
    return completer.future;
  }
}
