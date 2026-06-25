class AppConfig {
  static const String adminWhatsapp = '085701054362';
  static const String _legacySupabaseUrl =
      String.fromEnvironment('SUPABASE_URL');
  static const String _nextPublicSupabaseUrl =
      String.fromEnvironment('NEXT_PUBLIC_SUPABASE_URL');
  static const String _legacySupabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _nextPublicSupabasePublishableKey =
      String.fromEnvironment('NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY');

  static const String supabaseUrl = _nextPublicSupabaseUrl == ''
      ? _legacySupabaseUrl
      : _nextPublicSupabaseUrl;
  static const String supabasePublishableKey =
      _nextPublicSupabasePublishableKey == ''
          ? _legacySupabaseAnonKey
          : _nextPublicSupabasePublishableKey;

  static bool get hasSupabaseConfig =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
