export 'supabase_rest_client_stub.dart'
    if (dart.library.html) 'supabase_rest_client_web.dart'
    if (dart.library.io) 'supabase_rest_client_io.dart';
