import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
  }) async {
    final HttpClient client = HttpClient();
    try {
      final HttpClientRequest request = await client
          .openUrl(method, uri)
          .timeout(const Duration(seconds: 8));
      headers.forEach((String name, String value) {
        request.headers.set(name, value);
      });
      if (body != null) {
        request.write(jsonEncode(body));
      }

      final HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 12));
      final String responseBody = await response.transform(utf8.decoder).join();
      return SupabaseRestResponse(
        statusCode: response.statusCode,
        body: responseBody,
      );
    } on TimeoutException {
      return const SupabaseRestResponse(
        statusCode: 408,
        body: '{"message":"Supabase request timeout"}',
      );
    } finally {
      client.close(force: true);
    }
  }
}
