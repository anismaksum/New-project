# Catatan Rombak Production KostHunt

Dokumen ini adalah catatan konsultasi dan roadmap teknis untuk merombak KostHunt dari prototype menjadi aplikasi marketplace kost production.

## 1. Keputusan Produk Yang Sudah Disepakati

1. Payment dipakai untuk pembayaran biaya sewa kost penuh.
2. Payment gateway utama memakai Duitku.
3. Dana pembayaran masuk ke platform terlebih dahulu.
4. Owner bisa langsung publish listing tanpa menunggu approval admin.
5. Chat customer dan owner bebas dimulai dari halaman detail kost.
6. Database dan perubahan schema dikelola dengan Supabase CLI.
7. Fonnte dihapus dari alur utama.
8. Customer service dibuat sebagai chat langsung antara customer dan admin.
9. Aplikasi harus realtime.
10. Aplikasi ditargetkan rilis ke Google Play Store.
11. Semua halaman setelah login untuk customer, owner, dan admin harus berfungsi penuh sesuai role masing-masing.

## 2. Prinsip Utama Sebelum Mulai Implementasi

1. Jangan menaruh secret key Duitku, service role key Supabase, atau credential sensitif lain di Flutter app.
2. Semua operasi payment harus lewat backend, idealnya Supabase Edge Functions.
3. Status pembayaran hanya dianggap valid dari callback/webhook Duitku, bukan dari redirect halaman payment.
4. Semua data production wajib diamankan dengan Row Level Security Supabase.
5. Semua perubahan database wajib masuk migration file agar bisa dilacak, diulang, dan dipush ke cloud.
6. Karena uang sewa penuh masuk ke platform, perlu alur owner balance, payout, refund, dan audit log.
7. Owner boleh publish langsung, tetapi tetap perlu guardrail: validasi data wajib, report, suspend, dan takedown dari admin.
8. Realtime jangan hanya chat. Booking, payment, notification, support, dan status listing juga perlu realtime.
9. Tidak boleh ada fitur utama yang hanya berupa tampilan dummy. Setiap tombol dan halaman penting harus punya alur data, validasi, loading state, error state, dan hasil aksi yang jelas.
10. Setiap fitur customer, owner, dan admin harus diuji sesuai role agar tidak ada akses silang atau fitur yang terlihat tetapi tidak berfungsi.

## 3. Tahap 0 - Persiapan Akun Dan Dokumen

Siapkan akun dan kebutuhan eksternal sebelum coding besar dimulai.

### Akun wajib

1. Supabase Cloud project production.
2. Supabase CLI di laptop development.
3. Duitku merchant account.
4. Duitku sandbox credential.
5. Duitku production credential.
6. Firebase project untuk FCM push notification.
7. Google Play Console developer account.
8. Email support resmi aplikasi.
9. Domain atau halaman publik untuk privacy policy, terms, dan account deletion.

### Cara menyiapkan akun wajib

1. Supabase Cloud
   1. Buat organisasi dan project baru.
   2. Simpan `Project URL`, `anon public key`, dan nanti `service role key` untuk backend.
   3. Aktifkan database dan auth.
   4. Ini yang paling dulu dipakai karena seluruh data app akan masuk ke sini.
2. Supabase CLI
   1. Install Supabase CLI di laptop development.
   2. Login dengan `supabase login`.
   3. Link project cloud dengan `supabase link --project-ref <project-ref>`.
   4. Nanti semua schema dan fungsi akan dijalankan sebagai migration.
3. Duitku merchant account
   1. Daftar merchant.
   2. Aktifkan sandbox dulu.
   3. Simpan credential sandbox.
   4. Setelah alur payment valid, baru aktifkan credential production.
   5. Siapkan callback URL dan return URL untuk Flutter dan backend.
4. Firebase project
   1. Buat project Firebase.
   2. Tambahkan app Android.
   3. Unduh konfigurasi `google-services.json`.
   4. Aktifkan Cloud Messaging untuk push notification.
5. Google Play Console
   1. Buat developer account.
   2. Siapkan identity dan email support.
   3. Ini dipakai nanti saat build release dan upload AAB.
6. Domain atau halaman publik
   1. Buat halaman privacy policy, terms, dan account deletion.
   2. Kalau belum punya domain, bisa mulai dari halaman statis dulu.
7. Email support resmi
   1. Pakai email yang konsisten untuk review Play Store dan support user.
   2. Jangan pakai email pribadi acak kalau mau terlihat production-ready.

### Dokumen wajib

1. Privacy Policy.
2. Terms and Conditions.
3. Refund Policy.
4. Owner Agreement.
5. Payment and Payout Policy.
6. Account Deletion Policy.
7. Moderation Policy untuk listing, chat, dan report.

### Catatan penting

Karena pembayaran adalah sewa penuh, platform akan menyimpan uang customer sebelum diteruskan ke owner. Ini membuat aplikasi lebih serius secara bisnis, karena perlu aturan jelas tentang:

1. kapan uang dianggap sah masuk;
2. kapan owner boleh menerima payout;
3. apa yang terjadi jika customer membatalkan;
4. siapa yang menanggung biaya admin gateway;
5. bagaimana refund diproses;
6. bagaimana sengketa customer dan owner diselesaikan.

### Cara menjalankan tahap 0

Ikuti urutan ini untuk mulai dari kondisi repo sekarang:

1. Jalankan `flutter doctor` dan pastikan Flutter sudah sehat.
2. Buat project Supabase Cloud.
3. Jalankan SQL berikut di Supabase SQL Editor sesuai urutan:
   1. `database/supabase/schema.sql`
   2. `database/supabase/seed.sql`
   3. `database/supabase/auth_profiles.sql`
4. Siapkan akun uji di Supabase Auth jika belum ada.
5. Cek file [run_flutter_supabase.ps1](<C:\Users\ASUS\OneDrive\Documents\New project\kosthunt\run_flutter_supabase.ps1>) karena file ini masih memakai URL dan publishable key yang sudah diisi.
6. Jika ingin menjalankan app dengan config itu, jalankan:

```powershell
.\run_flutter_supabase.ps1
```

7. Jika ingin run lokal tanpa Supabase, jalankan:

```powershell
flutter run -d edge
```

8. Jika ingin melihat flow prototype lama yang masih memakai server WhatsApp lokal, jalankan [server/run_whatsapp_server.ps1](<C:\Users\ASUS\OneDrive\Documents\New project\kosthunt\server\run_whatsapp_server.ps1>) dulu, lalu run Flutter.
9. Login pakai akun contoh dari [README.md](<C:\Users\ASUS\OneDrive\Documents\New project\kosthunt\README.md>) untuk memastikan role customer, owner, dan admin bisa masuk.
10. Pastikan tiap role bisa membuka halaman yang sesuai sebelum lanjut ke tahap 1.

## 4. Tahap 1 - Arsitektur Flutter

Project sekarang masih prototype sederhana. Untuk production, struktur perlu dibuat lebih rapi.

### Rekomendasi struktur

Gunakan struktur feature-based:

```text
lib/
  main.dart
  src/
    app/
      app.dart
      router.dart
    core/
      config/
      errors/
      theme/
      utils/
      widgets/
    features/
      auth/
      marketplace/
      listing/
      booking/
      payment/
      chat/
      support/
      notification/
      owner/
      admin/
      profile/
    shared/
      models/
      services/
```

### Dependency yang disarankan

1. `supabase_flutter` untuk auth, database, storage, dan realtime.
2. `flutter_riverpod` untuk state management.
3. `go_router` untuk routing dan guard berdasarkan role.
4. `firebase_core` dan `firebase_messaging` untuk push notification.
5. `image_picker` atau package sejenis untuk upload foto kost.
6. `cached_network_image` untuk gambar listing.
7. `intl` untuk format Rupiah dan tanggal.
8. `url_launcher` untuk membuka payment URL Duitku.
9. `app_links` atau package deep link sejenis untuk kembali dari payment ke aplikasi.

### Rekomendasi saya

Pindahkan state global dari singleton `ChangeNotifier` menuju Riverpod. Untuk data realtime seperti chat dan notifications, gunakan `StreamProvider`. Untuk aksi seperti create booking, create payment, send message, gunakan service/repository yang dipanggil dari notifier.

## 5. Tahap 2 - Supabase CLI Dan Database Migration

Karena database akan memakai Supabase CLI, semua schema harus dikelola lewat migration.

### Setup awal Supabase CLI

Urutan umum:

```bash
supabase login
supabase init
supabase link --project-ref <project-ref>
supabase migration new init_production_schema
supabase db push
```

Untuk development lokal:

```bash
supabase start
supabase db reset
```

Untuk membuat perubahan schema berikutnya:

```bash
supabase migration new nama_perubahan
supabase db push
```

### Struktur folder yang disarankan

```text
supabase/
  migrations/
  functions/
    create-duitku-transaction/
    duitku-callback/
    send-push-notification/
  seed.sql
  config.toml
```

### Tabel inti yang perlu dibuat

1. `app_users`
2. `owner_profiles`
3. `kosts`
4. `kost_photos`
5. `kost_facilities`
6. `kost_rules`
7. `kost_units`
8. `favorites`
9. `bookings`
10. `payments`
11. `payment_events`
12. `owner_balances`
13. `payouts`
14. `refunds`
15. `conversations`
16. `conversation_participants`
17. `messages`
18. `message_reads`
19. `support_threads`
20. `support_messages`
21. `notifications`
22. `notification_preferences`
23. `reviews`
24. `reports`
25. `audit_logs`

### Catatan schema penting

1. `kosts` sebaiknya punya status: `published`, `paused`, `suspended`, `deleted`.
2. Karena owner boleh langsung publish, default listing bisa `published`, tetapi admin tetap bisa mengubah ke `suspended`.
3. `kost_units` penting jika satu kost punya beberapa kamar/unit. Ini mencegah double booking.
4. `payments` harus menyimpan `merchant_order_id`, `duitku_reference`, `amount`, `status`, dan `raw_callback`.
5. `payment_events` menyimpan semua callback mentah untuk audit.
6. `owner_balances` menyimpan saldo owner yang belum dan sudah bisa ditarik.
7. `payouts` menyimpan transfer dari platform ke owner.
8. `audit_logs` wajib untuk aksi admin, payment, payout, suspend listing, dan refund.

### RLS production

Hapus policy demo `anon` yang memberi akses baca/tulis terlalu luas.

RLS minimum:

1. Public hanya bisa membaca listing yang `published`.
2. Customer hanya bisa membaca booking dan payment miliknya.
3. Owner hanya bisa membaca chat, booking, dan listing miliknya.
4. Owner bisa membuat dan mengedit listing miliknya.
5. Admin bisa membaca dan mengelola semua data.
6. Insert payment hanya boleh lewat Edge Function atau role yang aman.
7. Notification hanya bisa dibaca oleh penerima.
8. Support thread hanya bisa dibaca customer terkait dan admin.

## 6. Tahap 3 - Auth, Register, Dan Role

### Halaman auth yang perlu ada

1. Login.
2. Register customer.
3. Register owner.
4. Forgot password.
5. Profile completion.
6. Account deletion request.

### Alur register customer

1. Customer isi nama, email, password, nomor HP.
2. Supabase Auth membuat user.
3. App membuat row di `app_users` dengan role `customer`.
4. Customer masuk ke halaman marketplace.

### Alur register owner

1. Owner isi nama, email, password, nomor HP.
2. Owner melengkapi profil pemilik kost.
3. Owner bisa langsung membuat listing.
4. Listing langsung published setelah data wajib valid.
5. Admin tetap menerima notifikasi bahwa owner baru/listing baru masuk.

### Rekomendasi saya

Walaupun owner boleh langsung publish, beri label internal seperti `trust_level` atau `is_verified_owner`. Listing tetap tampil, tetapi admin punya kemampuan suspend cepat jika ada laporan.

## 7. Tahap 4 - Semua Fitur Per Role Harus Berfungsi

Bagian ini menjadi aturan production: setiap halaman yang bisa diakses setelah auth harus tersambung ke fitur nyata.

### Customer wajib berfungsi

1. Register dan login.
2. Edit profil.
3. Lihat marketplace kost.
4. Search dan filter kost.
5. Lihat detail kost.
6. Simpan favorit.
7. Chat owner dari detail kost.
8. Membuat booking/sewa.
9. Membayar sewa penuh lewat Duitku.
10. Melihat status payment.
11. Melihat status booking.
12. Menerima notifikasi.
13. Membuka notification center.
14. Chat customer service dengan admin.
15. Melihat riwayat chat owner.
16. Melihat riwayat support.
17. Mengajukan refund atau komplain jika fitur ini sudah dibuka.
18. Logout.
19. Request hapus akun.

### Owner wajib berfungsi

1. Register dan login sebagai owner.
2. Melengkapi profil owner.
3. Membuat listing kost.
4. Upload dan mengelola foto kost.
5. Mengedit harga, fasilitas, aturan, dan ketersediaan.
6. Publish listing langsung setelah data wajib valid.
7. Pause atau unpublish listing.
8. Melihat chat dari customer.
9. Membalas chat customer.
10. Melihat booking masuk.
11. Melihat status payment dari booking terkait.
12. Melihat saldo owner.
13. Melihat riwayat payout.
14. Mengajukan payout jika sudah tersedia.
15. Menerima notifikasi.
16. Membuka notification center.
17. Logout.

### Admin wajib berfungsi

1. Login sebagai admin.
2. Melihat dashboard ringkasan.
3. Melihat semua customer.
4. Melihat semua owner.
5. Melihat semua listing.
6. Suspend atau restore listing.
7. Melihat semua booking.
8. Melihat semua payment.
9. Melihat callback/payment events.
10. Mengelola payout.
11. Mengelola refund.
12. Membalas customer service.
13. Melihat report.
14. Menindaklanjuti report.
15. Melihat audit logs.
16. Mengirim atau menerima notifikasi admin.
17. Logout.

### Standar fitur dianggap selesai

Satu fitur dianggap selesai jika sudah memenuhi syarat berikut:

1. UI tersedia.
2. Data tersimpan di Supabase.
3. RLS sesuai role.
4. Loading state tersedia.
5. Empty state tersedia.
6. Error state tersedia.
7. Success feedback tersedia.
8. Realtime berjalan jika fitur membutuhkan realtime.
9. Notification dibuat jika fitur membutuhkan notifikasi.
10. Test minimal tersedia untuk alur penting.

## 8. Tahap 5 - Marketplace Listing Kost

### Fitur customer

1. Lihat daftar kost.
2. Search berdasarkan kota, area, kampus, nama kost.
3. Filter harga, fasilitas, tipe kost, ketersediaan, jarak.
4. Lihat detail kost.
5. Simpan favorit.
6. Chat owner dari halaman detail.
7. Booking/sewa.
8. Bayar sewa penuh.
9. Lihat status booking dan payment.
10. Beri review setelah transaksi selesai.

### Fitur owner

1. Register sebagai owner.
2. Kelola profil owner.
3. Tambah listing kost.
4. Upload foto kost.
5. Tambah fasilitas dan aturan.
6. Kelola harga.
7. Kelola jumlah kamar/unit.
8. Pause listing.
9. Lihat chat masuk.
10. Lihat booking masuk.
11. Lihat status payment.
12. Lihat saldo owner.
13. Ajukan payout.

### Fitur admin

1. Monitor listing baru.
2. Suspend listing bermasalah.
3. Kelola owner.
4. Kelola customer.
5. Kelola booking.
6. Kelola payment.
7. Kelola payout.
8. Kelola refund.
9. Balas customer service.
10. Lihat report dan audit log.

### Rekomendasi saya

Untuk awal, jangan terlalu banyak tipe properti. Fokus ke kost dulu. Kontrakan bisa menyusul setelah alur payment, chat, booking, dan payout stabil.

## 9. Tahap 6 - Booking Dan Payment Duitku

Karena payment untuk sewa penuh dan uang masuk ke platform, flow harus dibuat rapi.

### Flow utama customer

1. Customer login.
2. Customer buka detail kost.
3. Customer memilih unit/kamar dan durasi sewa.
4. App membuat booking dengan status `pending_payment`.
5. App memanggil Edge Function `create-duitku-transaction`.
6. Edge Function membuat transaksi ke Duitku memakai credential server.
7. Duitku mengembalikan payment URL atau payment instruction.
8. Flutter membuka halaman pembayaran.
9. Customer membayar.
10. Duitku mengirim callback ke Edge Function `duitku-callback`.
11. Edge Function memverifikasi signature dan amount.
12. Payment diupdate menjadi `paid`, `failed`, atau `expired`.
13. Booking berubah menjadi `paid` jika pembayaran sukses.
14. Notification dikirim ke customer, owner, dan admin.
15. Saldo owner masuk sebagai `pending_balance`.
16. Admin atau sistem memproses payout sesuai aturan bisnis.

### Status payment yang disarankan

1. `pending`
2. `waiting_payment`
3. `paid`
4. `failed`
5. `expired`
6. `cancelled`
7. `refunded`
8. `partially_refunded`

### Status booking yang disarankan

1. `draft`
2. `pending_payment`
3. `paid`
4. `confirmed`
5. `checked_in`
6. `completed`
7. `cancelled`
8. `refunded`
9. `disputed`

### Tabel `payments` minimum

Kolom yang disarankan:

1. `id`
2. `booking_id`
3. `customer_user_id`
4. `owner_user_id`
5. `kost_id`
6. `amount`
7. `platform_fee`
8. `owner_amount`
9. `currency`
10. `gateway`
11. `merchant_order_id`
12. `duitku_reference`
13. `payment_method`
14. `status`
15. `payment_url`
16. `expired_at`
17. `paid_at`
18. `created_at`
19. `updated_at`

### Tabel `payment_events`

Simpan semua callback Duitku, termasuk callback yang gagal validasi. Ini penting untuk audit dan troubleshooting.

Kolom minimum:

1. `id`
2. `payment_id`
3. `merchant_order_id`
4. `duitku_reference`
5. `event_type`
6. `signature_valid`
7. `amount_match`
8. `raw_payload`
9. `created_at`

### Aturan keamanan payment

1. Jangan percaya status dari frontend.
2. Jangan percaya redirect URL sebagai bukti payment sukses.
3. Callback harus idempotent, artinya callback yang sama tidak boleh membuat saldo ganda.
4. Verifikasi signature Duitku.
5. Verifikasi amount.
6. Verifikasi merchant order ID.
7. Booking yang sudah paid tidak boleh dibayar dua kali.
8. Gunakan unique constraint untuk `merchant_order_id`.
9. Simpan raw callback untuk audit.
10. Gunakan environment secret di Supabase Edge Functions.

### Rekomendasi payout

Karena dana masuk ke platform dulu, buat sistem saldo owner:

1. Setelah payment sukses, uang masuk ke `owner_balances.pending_amount`.
2. Setelah masa aman selesai, pindahkan ke `available_amount`.
3. Owner mengajukan withdraw/payout.
4. Admin memproses payout.
5. Setelah transfer selesai, payout berubah menjadi `paid`.

Untuk MVP, payout boleh manual oleh admin. Otomasi payout bisa ditambahkan setelah payment dan refund stabil.

## 10. Tahap 7 - Realtime Chat Customer-Owner

Chat bebas dimulai dari halaman detail kost.

### Flow chat

1. Customer buka detail kost.
2. Customer tekan tombol chat.
3. App membuat atau membuka conversation antara customer dan owner.
4. Customer mengirim pesan.
5. Owner menerima realtime message.
6. Notification masuk ke owner.
7. Owner membalas dari halaman pesan.
8. Customer menerima realtime message dan push notification jika app sedang tidak aktif.

### Tabel chat minimum

1. `conversations`
2. `conversation_participants`
3. `messages`
4. `message_reads`

### Guardrail chat

1. Customer harus login sebelum chat owner.
2. Owner tidak boleh melihat conversation listing owner lain.
3. Customer tidak boleh melihat conversation customer lain.
4. Admin bisa membaca chat hanya untuk kebutuhan report/moderation, atau dibuat terbatas sesuai policy.
5. Tambahkan report chat.
6. Tambahkan block user jika diperlukan.
7. Rate limit pesan untuk mencegah spam.

### Rekomendasi saya

Chat sebaiknya tidak memakai WhatsApp. Simpan semua chat di database agar bisa realtime, diaudit, dan dipakai untuk dispute jika ada masalah payment/sewa.

## 11. Tahap 8 - Customer Service Admin

Fonnte dihapus. Customer service menjadi chat internal customer-admin.

### Flow CS

1. Customer buka halaman Customer Service.
2. App membuat support thread.
3. Customer mengirim pesan.
4. Admin menerima realtime message.
5. Admin membalas dari admin console.
6. Customer menerima realtime reply dan push notification.
7. Thread bisa ditandai `open`, `pending`, `resolved`, atau `closed`.

### Tabel CS minimum

1. `support_threads`
2. `support_messages`
3. `support_assignments` jika nanti admin lebih dari satu.

### Rekomendasi saya

Hubungkan support thread dengan booking/payment jika customer menghubungi CS dari halaman booking. Ini akan mempercepat admin melihat konteks masalah.

## 12. Tahap 9 - Notification System

Notifikasi jangan hanya snackbar. Buat notification center di aplikasi.

### Tabel `notifications`

Kolom minimum:

1. `id`
2. `recipient_user_id`
3. `actor_user_id`
4. `type`
5. `title`
6. `body`
7. `data`
8. `read_at`
9. `created_at`

### Event yang wajib membuat notifikasi

1. Register customer berhasil.
2. Register owner berhasil.
3. Owner membuat listing baru.
4. Admin suspend listing.
5. Customer mulai chat.
6. Owner membalas chat.
7. Customer membuat booking.
8. Payment dibuat.
9. Payment sukses.
10. Payment gagal.
11. Payment expired.
12. Booking confirmed.
13. Booking cancelled.
14. Refund dibuat.
15. Refund selesai.
16. Payout dibuat.
17. Payout selesai.
18. Customer membuat support ticket.
19. Admin membalas support ticket.
20. Report dibuat.

### Push notification

Gunakan FCM untuk push notification. Simpan device token di table seperti `user_devices`.

Kolom minimum `user_devices`:

1. `id`
2. `user_id`
3. `fcm_token`
4. `platform`
5. `last_seen_at`
6. `created_at`

### Rekomendasi saya

Semua notifikasi masuk dulu ke table `notifications`. Push notification adalah tambahan. Dengan begitu, jika push gagal, user tetap bisa melihat riwayat notifikasi di aplikasi.

## 13. Tahap 10 - Admin Console

Admin console penting karena platform menerima uang customer.

### Modul admin wajib

1. Dashboard ringkasan.
2. Users.
3. Owners.
4. Listings.
5. Bookings.
6. Payments.
7. Payouts.
8. Refunds.
9. Customer Service.
10. Reports.
11. Audit Logs.
12. App Settings.

### Rekomendasi saya

Untuk MVP, admin console bisa tetap di Flutter app dengan role admin. Setelah bisnis bertumbuh, pisahkan menjadi web admin khusus agar operasional lebih nyaman.

## 14. Tahap 11 - Security, Privacy, Dan Compliance

### Security checklist

1. Semua table aktif RLS.
2. Tidak ada policy demo `anon` untuk insert/update/delete.
3. Service role key hanya di backend.
4. Duitku secret hanya di Edge Function secret.
5. Storage bucket foto kost public-read, owner-write.
6. Storage bucket dokumen owner private.
7. Chat hanya terbaca oleh participant.
8. Payment hanya terbaca customer, owner terkait, dan admin.
9. Admin action masuk audit log.
10. Rate limit untuk chat, support, register, dan create payment.

### Privacy checklist

1. Privacy policy menjelaskan data yang dikumpulkan.
2. Terms menjelaskan peran platform sebagai perantara.
3. Refund policy jelas.
4. Account deletion tersedia.
5. Data Safety Google Play diisi sesuai fitur nyata.
6. Permission Android hanya yang benar-benar dipakai.

### Rekomendasi saya

Jangan minta permission yang belum perlu. Untuk awal, cukup internet, notifikasi, dan media/image picker sesuai kebutuhan upload foto. Permission lokasi hanya ditambahkan jika fitur lokasi benar-benar dipakai.

## 15. Tahap 12 - Play Store Preparation

### Checklist teknis

1. Ganti package name dari default `com.example.kosthunt` ke package resmi.
2. Update app name.
3. Siapkan app icon production.
4. Siapkan splash screen.
5. Siapkan Android App Bundle.
6. Setup signing.
7. Update target SDK sesuai requirement Google Play saat rilis.
8. Build release.
9. Test release APK/AAB di device asli.

### Checklist store listing

1. Nama aplikasi.
2. Short description.
3. Full description.
4. Screenshot phone.
5. Feature graphic.
6. Category.
7. Contact email.
8. Privacy policy URL.
9. Data Safety form.
10. Content rating.
11. App access instruction untuk reviewer.
12. Test account customer, owner, dan admin.

### Catatan Google Play

Jika akun developer termasuk personal account baru, Google Play dapat meminta closed testing dengan 12 tester selama 14 hari sebelum production access. Siapkan tester sejak awal agar rilis tidak tertahan.

## 16. Tahap 13 - Testing

### Unit test

1. Auth validation.
2. Booking status transition.
3. Payment amount calculation.
4. Platform fee calculation.
5. Notification event mapping.

### Widget test

1. Login.
2. Register.
3. Listing list.
4. Detail kost.
5. Chat screen.
6. Payment status screen.
7. Notification center.

### Integration test

1. Register customer sampai login.
2. Register owner sampai publish listing.
3. Customer chat owner.
4. Customer booking kost.
5. Customer membuat payment Duitku sandbox.
6. Callback payment mengubah status booking.
7. Notification realtime masuk.
8. CS customer-admin berjalan.

### Manual QA

1. Android low-end device.
2. Android mid-range device.
3. Koneksi lambat.
4. App background saat chat masuk.
5. App background saat payment sukses.
6. Payment gagal.
7. Payment expired.
8. Callback Duitku dobel.
9. Owner mencoba akses listing owner lain.
10. Customer mencoba akses booking customer lain.

## 17. Tahap 14 - Monitoring Dan Operasional

### Monitoring yang disarankan

1. Firebase Crashlytics atau Sentry.
2. Supabase logs.
3. Edge Function logs.
4. Duitku payment report.
5. Daily payment reconciliation.
6. Admin audit logs.

### Reconciliation payment harian

Setiap hari admin atau sistem mengecek:

1. payment paid di app sama dengan report Duitku;
2. payment pending yang sudah expired;
3. callback gagal validasi;
4. booking paid tanpa payment paid;
5. saldo owner sesuai dengan payment sukses;
6. payout sesuai dengan saldo owner.

## 18. Urutan Implementasi Yang Disarankan

Urutan ini dibuat agar pekerjaan tidak saling menabrak.

1. Rapikan struktur project Flutter.
2. Tambahkan dependency inti.
3. Setup Supabase CLI.
4. Buat migration production schema.
5. Buat RLS production.
6. Migrasi auth ke `supabase_flutter`.
7. Buat login dan register.
8. Buat role customer, owner, admin.
9. Buat owner onboarding.
10. Buat CRUD listing owner.
11. Buat marketplace listing customer.
12. Buat detail kost.
13. Buat chat customer-owner realtime.
14. Buat customer service customer-admin realtime.
15. Buat notification table.
16. Integrasi FCM.
17. Buat booking.
18. Buat Edge Function create Duitku transaction.
19. Buat Edge Function Duitku callback.
20. Buat payment status screen.
21. Buat owner balance.
22. Buat payout manual admin.
23. Buat admin console payment, payout, support, report.
24. Tambahkan audit logs.
25. Tambahkan tests.
26. QA sandbox payment end-to-end.
27. Hardening security RLS.
28. Siapkan Play Store assets.
29. Build release AAB.
30. Closed/internal testing.
31. Submit Play Store.
32. Monitor crash, payment, dan feedback user.

## 19. Rekomendasi Teknis Utama

1. Gunakan Supabase CLI dan migrations dari awal.
2. Gunakan `supabase_flutter`, bukan REST manual.
3. Gunakan Supabase Edge Functions untuk Duitku.
4. Gunakan Riverpod untuk state management.
5. Gunakan GoRouter untuk route guard berbasis auth dan role.
6. Gunakan FCM untuk push notification.
7. Simpan semua notifikasi di database sebelum push.
8. Simpan semua callback payment ke `payment_events`.
9. Buat owner balance dan payout manual untuk MVP.
10. Buat room/unit system agar tidak terjadi double booking.
11. Owner boleh publish langsung, tetapi admin harus bisa suspend.
12. Chat dan CS jangan lewat WhatsApp. Simpan di database.
13. Jangan rilis Play Store sebelum RLS, payment callback, dan refund flow diuji.

## 20. Risiko Yang Harus Diperhatikan

1. Payment full rent berarti risiko refund dan dispute lebih besar.
2. Owner direct publish bisa membuat listing palsu muncul jika tidak ada moderation.
3. Chat bebas bisa menimbulkan spam jika tidak ada rate limit/report.
4. RLS yang salah bisa membocorkan data booking, payment, atau chat.
5. Callback payment yang tidak idempotent bisa membuat saldo owner dobel.
6. Data Safety Play Store harus sesuai fitur nyata, terutama payment, chat, dan data pribadi.
7. Jika account deletion tidak tersedia, review Play Store bisa bermasalah.
8. Jika hanya mengandalkan redirect payment, status payment bisa tidak akurat.

## 21. Link Rujukan Resmi

1. Supabase Flutter: https://supabase.com/docs/guides/getting-started/tutorials/with-flutter
2. Supabase CLI local development: https://supabase.com/docs/guides/local-development/cli/getting-started
3. Supabase Realtime database changes: https://supabase.com/docs/guides/realtime/subscribing-to-database-changes
4. Supabase Edge Functions: https://supabase.com/docs/guides/functions
5. Duitku API documentation: https://docs.duitku.com/api/en/
6. Firebase Cloud Messaging Flutter: https://firebase.google.com/docs/cloud-messaging/flutter/client
7. Google Play production access testing: https://support.google.com/googleplay/android-developer/answer/14151465
8. Google Play Data Safety: https://support.google.com/googleplay/android-developer/answer/10787469
