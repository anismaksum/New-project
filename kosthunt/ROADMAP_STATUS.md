# KostHunt Production Roadmap Status

Status ini mengikuti catatan roadmap awal dan kondisi project saat ini.

## Sudah Ada Di App Sandbox Lokal

- Auth demo role customer, owner, dan admin.
- Register customer dan register owner.
- Marketplace listing published.
- Search listing berdasarkan nama, kota, area, dan fasilitas.
- Filter chip WiFi, AC, Parkir, jarak <=1 km kampus, Kost, Kontrakan, dan Premium.
- Tipe properti `kost` dan `kontrakan` di model, seed, form owner, kartu listing,
  dan detail listing.
- Premium listing/iklan owner sandbox dengan ad credits, badge premium, dan sorting
  listing premium di atas listing reguler.
- Detail kost dengan unit tersedia.
- Favorite listing.
- Booking unit dan status `pending_payment`.
- Payment sandbox Duitku: create payment, simulate paid callback, payment event,
  booking paid, dan owner pending balance.
- Chat customer-owner dari detail kost.
- Customer service internal customer-admin.
- Notification center berbasis database lokal.
- Owner dashboard, listing direct publish, pause/publish listing.
- Owner booking confirmation dan booking completion.
- Owner balance, available balance, dan payout request manual.
- Admin dashboard.
- Admin listing moderation suspend/restore.
- Admin user/owner view.
- Admin payment, refund, payout view dan manual processing.
- Admin support reply dan resolve.
- Report listing dan admin report resolve.
- Review setelah booking completed.
- Audit log untuk aksi penting.
- Account deletion request dari profil.

## Sudah Ada Di Supabase Folder

- Supabase CLI structure di `supabase/`.
- Production migration dengan tabel inti marketplace, booking, payment, balance,
  payout, refund, chat, support, notification, review, report, dan audit.
- Production migration mendukung tipe properti `kost/kontrakan`, jarak kampus,
  premium listing, ad credits, dan tabel `listing_promotions`.
- RLS dasar production untuk public listing, customer/owner/admin data access,
  chat participant, support, notifications, favorites, report, dan storage.
- Storage bucket `kost-photos` public-read dan `owner-documents` private.
- Edge Function `create-duitku-transaction`.
- Edge Function `duitku-callback` dengan raw event, signature check, amount check,
  conditional update, dan idempotent balance increment.
- Edge Function `send-push-notification` untuk FCM HTTP v1.
- Legal policy draft di `docs/legal/README.md`.

## Sudah Ada Untuk Play Store Preparation

- Android package name diganti ke `com.kosthunt.app`.
- App label Android `KostHunt`.
- Deep link scheme `kosthunt://payment`.
- Permission minimal: internet dan post notifications.
- Release signing config membaca `android/key.properties` jika tersedia.
- `android/key.properties.example` disediakan dan secret signing di-ignore.

## Masih Butuh Credential Atau Akun Eksternal

- Supabase Cloud project dan `supabase link --project-ref`.
- Duitku sandbox/production merchant credential.
- URL callback public untuk Duitku.
- Firebase project dan service account untuk FCM.
- Google Play Console account.
- Domain/halaman publik untuk privacy policy, terms, refund policy, owner
  agreement, payment/payout policy, account deletion, dan moderation policy.
- Keystore release asli untuk Android App Bundle.

## Masih Perlu QA Dengan Service Asli

- `supabase db push` ke project sandbox.
- Deploy semua Edge Functions.
- Duitku sandbox create transaction dan callback asli.
- Callback Duitku dobel/concurrent.
- FCM device token registration dan push notification ke device asli.
- RLS negative tests: owner akses listing owner lain, customer akses booking orang
  lain, chat non-participant, support non-owner.
- Build release AAB dan test di Android device asli.
