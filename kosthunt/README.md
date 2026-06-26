# KostHunt

KostHunt adalah aplikasi Flutter marketplace kost. Project ini sedang dipindahkan
dari prototype menjadi fondasi production dengan Supabase, payment Duitku melalui
Edge Functions, realtime chat/support, notification center, dan role customer,
owner, serta admin.

## Status Saat Ini

- UI utama sekarang berjalan sebagai production sandbox lokal: auth role, marketplace,
  booking, payment sandbox, chat, support, notification, payout, refund, report,
  dan audit log bisa dicoba tanpa credential eksternal.
- Marketplace sandbox mendukung filter chip WiFi/AC/Parkir/jarak kampus, tipe
  properti kost/kontrakan, serta premium listing/iklan owner.
- Schema prototype lama masih tersedia di `database/supabase/` sebagai referensi.
- Fondasi production baru memakai Supabase CLI di folder `supabase/`.
- Fonnte/WhatsApp bukan alur utama production. Customer service dan chat sudah
  diarahkan menjadi chat internal aplikasi pada modul sandbox baru.
- Draft policy ada di `docs/legal/README.md`.
- Status implementasi roadmap ada di `ROADMAP_STATUS.md`.

## Dependency Production

Dependency inti sudah disiapkan di `pubspec.yaml`:

- `supabase_flutter` untuk auth, database, storage, dan realtime.
- `flutter_riverpod` untuk state management bertahap menggantikan singleton store.
- `go_router` untuk route guard berbasis auth dan role.
- `firebase_core` dan `firebase_messaging` untuk FCM push notification.
- `image_picker`, `cached_network_image`, `intl`, `url_launcher`, dan `app_links`
  untuk upload foto, gambar listing, format Rupiah/tanggal, payment URL, dan deep link.

Setelah dependency berubah, jalankan:

```powershell
flutter pub get
```

## Supabase CLI

Jalur production memakai migration, bukan copy-paste SQL Editor.

Struktur utama:

```text
supabase/
  config.toml
  migrations/
    20260626000000_init_production_schema.sql
  functions/
    create-duitku-transaction/
    duitku-callback/
    send-push-notification/
  seed.sql
```

Setup awal:

```powershell
supabase login
supabase link --project-ref PROJECT_REF
supabase db push
```

Development lokal:

```powershell
supabase start
supabase db reset
```

Membuat perubahan schema berikutnya:

```powershell
supabase migration new nama_perubahan
supabase db push
```

## Database Production

Migration production mencakup tabel inti berikut:

- Users dan role: `app_users`, `owner_profiles`.
- Listing kost: `kosts`, `kost_photos`, `kost_facilities`, `kost_rules`, `kost_units`, `favorites`.
- Booking dan payment: `bookings`, `payments`, `payment_events`.
- Saldo dan operasional uang: `owner_balances`, `payouts`, `refunds`, `audit_logs`.
- Chat customer-owner: `conversations`, `conversation_participants`, `messages`, `message_reads`.
- Customer service internal: `support_threads`, `support_messages`.
- Notification center dan push: `notifications`, `notification_preferences`, `user_devices`.
- Trust/moderation: `reviews`, `reports`.

RLS diaktifkan untuk semua tabel production. Flutter client hanya boleh membaca atau
menulis data sesuai role. Mutasi sensitif seperti payment, payment event, saldo owner,
refund, payout admin, dan audit log harus lewat Edge Function atau operasi service role.

## Edge Functions

Skeleton fungsi sudah dibuat:

- `create-duitku-transaction`: membuat invoice/transaksi Duitku dari booking.
- `duitku-callback`: menerima callback Duitku, mencatat raw event, memverifikasi signature/amount,
  dan mengubah status payment/booking.
- `send-push-notification`: mengambil notification database dan device token sebagai dasar FCM.

Secret wajib disimpan sebagai Supabase secrets, bukan di Flutter:

```powershell
supabase secrets set DUITKU_MERCHANT_CODE="..."
supabase secrets set DUITKU_API_KEY="..."
supabase secrets set DUITKU_BASE_URL="https://sandbox-url-duitku"
supabase secrets set DUITKU_CALLBACK_URL="https://PROJECT_REF.functions.supabase.co/duitku-callback"
supabase secrets set DUITKU_RETURN_URL="kosthunt://payment"
```

Untuk push notification FCM HTTP v1, tambahkan secret Firebase berikut:

```powershell
supabase secrets set FIREBASE_PROJECT_ID="..."
supabase secrets set FIREBASE_CLIENT_EMAIL="firebase-adminsdk-...@PROJECT.iam.gserviceaccount.com"
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

Deploy function:

```powershell
supabase functions deploy create-duitku-transaction
supabase functions deploy duitku-callback
supabase functions deploy send-push-notification
```

## Menjalankan Flutter

Tanpa konfigurasi Supabase, aplikasi masih memakai data lokal dan akun demo prototype.

```text
customer@kosthunt.test
owner@kosthunt.test
admin@kosthunt.test
```

Password demo lokal:

```text
KostHunt212
```

Untuk menjalankan dengan Supabase project:

```powershell
flutter run -d edge `
  --dart-define=NEXT_PUBLIC_SUPABASE_URL="https://PROJECT_ID.supabase.co" `
  --dart-define=NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY="SUPABASE_PUBLISHABLE_KEY"
```

Script lama `run_flutter_supabase.ps1` masih ada untuk prototype, tetapi production
sebaiknya memakai env/dart-define yang tidak menyimpan secret sensitif.

## Catatan Penting Payment

- Jangan menyimpan Duitku API key, Supabase service role key, atau credential sensitif di Flutter.
- Redirect payment tidak membuktikan pembayaran sukses.
- Status payment valid hanya dari callback/webhook Duitku yang lolos verifikasi signature dan amount.
- Callback harus idempotent supaya saldo owner tidak bertambah dua kali.
- Semua raw callback disimpan di `payment_events` untuk audit dan rekonsiliasi.

## Langkah Berikutnya

1. Jalankan app sandbox lokal dan uji flow customer, owner, dan admin.
2. Link Supabase project production/sandbox dan push migration.
3. Masukkan secrets Supabase Edge Functions untuk Duitku sandbox.
4. Hubungkan UI sandbox lokal ke Supabase repository dan realtime channel.
5. QA Duitku sandbox end-to-end, lalu siapkan Firebase FCM dan Play Store assets.
