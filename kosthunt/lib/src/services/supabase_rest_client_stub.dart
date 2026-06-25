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
    return const SupabaseRestResponse(
      statusCode: 0,
      body: '{"message":"Supabase REST client is not supported here"}',
    );
  }
}
