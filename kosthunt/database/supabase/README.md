# KostHunt Supabase Database

Database menjadi sumber utama untuk listing kost, booking, chat booking, favorit, dan log notifikasi WhatsApp. WhatsApp/Fonnte hanya dipakai sebagai kanal pengiriman pesan.

## Urutan Setup

1. Buat project Supabase.
2. Buka SQL Editor.
3. Jalankan `schema.sql`.
4. Jalankan `seed.sql` bila ingin mengisi listing contoh yang sama dengan prototype Flutter.
5. Simpan `Project URL` dan `anon public key` untuk integrasi Flutter berikutnya.

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
