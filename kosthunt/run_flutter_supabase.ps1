$supabaseUrl = "https://mcigudrnsshfgpaecfeg.supabase.co"
$supabasePublishableKey = "sb_publishable_35haGLCTXwTCQiZeEVqP5g_20S9LiPU"

flutter run -d edge `
  --dart-define=NEXT_PUBLIC_SUPABASE_URL="$supabaseUrl" `
  --dart-define=NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY="$supabasePublishableKey"
