# KostHunt Supabase Database

Database menjadi sumber utama untuk listing kost, booking, chat booking, favorit, dan log notifikasi WhatsApp. WhatsApp/Fonnte hanya dipakai sebagai kanal pengiriman pesan.

## Urutan Setup

Opsi yang disarankan sekarang adalah memakai Supabase CLI untuk project cloud.

1. Link repo ini ke project Supabase:
   `supabase link --project-ref mcigudrnsshfgpaecfeg`
2. Push schema dari migration:
   `supabase db push`
3. Isi data contoh:
   `supabase db push --include-seed`
4. Buat akun email/password di Supabase Authentication.
5. Jalankan `auth_profiles.sql` di SQL Editor setelah akun Auth tersedia.
6. Simpan `Project URL` dan `anon public key` untuk integrasi Flutter berikutnya.

Kalau CLI lokal belum siap, `schema.sql` dan `seed.sql` masih bisa dijalankan
manual di SQL Editor dengan urutan schema lebih dulu, lalu seed.

## Tabel Utama

- `app_users`: profil customer, owner, dan admin.
- `owners`: data pemilik kost.
- `kosts`: data listing kost.
- `bookings`: data pesanan kamar.
- `booking_messages`: percakapan customer, admin, dan owner terkait booking.
- `support_messages`: pesan bantuan umum dari customer sebelum masuk ke thread booking.
- `notification_logs`: riwayat pengiriman WhatsApp.
- `favorite_kosts`: kost favorit customer.

## Catatan Keamanan

Token Fonnte tidak disimpan di database dan tidak dimasukkan ke aplikasi Flutter. Token tetap dibaca oleh backend lokal melalui environment variable `FONNTE_TOKEN`.

Row Level Security sudah diaktifkan. Untuk kebutuhan demo prototype, ada policy
`Demo ...` yang mengizinkan anon key membaca listing/booking dan menulis booking,
chat, support message, serta log notifikasi. Setelah login role selesai dibuat,
policy demo ini sebaiknya dicabut dan diganti policy customer/owner/admin yang
lebih ketat.
