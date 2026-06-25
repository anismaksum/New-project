# KostHunt

KostHunt adalah prototype Flutter untuk pencarian kost/kontrakan, booking kamar,
dashboard owner, admin console, dan notifikasi WhatsApp melalui backend lokal.

## Database

Fondasi database memakai Supabase PostgreSQL. File SQL tersedia di:

```text
database/supabase/schema.sql
database/supabase/seed.sql
database/supabase/auth_profiles.sql
```

Urutan setup:

1. Buat project di Supabase.
2. Jalankan `database/supabase/schema.sql` di SQL Editor.
3. Jalankan `database/supabase/seed.sql` untuk data listing contoh.
4. Buat user email/password di Supabase Authentication.
5. Sesuaikan email di `database/supabase/auth_profiles.sql`, lalu jalankan
   file itu untuk memberi role `customer`, `owner`, dan `admin`.
6. Simpan `Project URL` dan `anon public key`.

Untuk saat ini aplikasi masih memakai `LocalKostHuntRepository`, jadi app tetap
berjalan tanpa kredensial Supabase. Layer repository sudah disiapkan agar tahap
berikutnya bisa mengaktifkan Supabase tanpa membongkar UI.

Untuk menjalankan app dengan Supabase REST langsung:

```powershell
flutter run -d edge `
  --dart-define=NEXT_PUBLIC_SUPABASE_URL="https://PROJECT_ID.supabase.co" `
  --dart-define=NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY="SUPABASE_PUBLISHABLE_KEY"
```

Atau pakai script lokal yang sudah berisi config project Supabase:

```powershell
.\run_flutter_supabase.ps1
```

Kalau nilai di atas tidak diberikan, aplikasi otomatis memakai data lokal.

## WhatsApp Server

Token Fonnte tidak disimpan di Flutter. Jalankan backend lokal:

```powershell
.\server\run_whatsapp_server.ps1 -Token "TOKEN_FONNTE_KAMU"
```

Biarkan terminal server tetap hidup, lalu jalankan Flutter di terminal lain:

```powershell
flutter run -d edge
```

## Sign In Supabase

Halaman login memakai Supabase Auth email/password. Role aplikasi diambil dari
tabel `app_users`, jadi setiap akun Auth perlu satu baris profil dengan
`auth_user_id` yang mengarah ke `auth.users.id`.

File `database/supabase/auth_profiles.sql` sudah menyiapkan profil untuk email:

```text
customer@kosthunt.test
owner@kosthunt.test
admin@kosthunt.test

customer@kosthunt.com
owner@kosthunt.com
admin@kosthunt.com
```

Pakai password yang sama untuk akun uji:

```text
KostHunt212
```

## Struktur Data Utama

- `app_users`: customer, owner, admin.
- `owners`: profil pemilik kost.
- `kosts`: listing kost.
- `bookings`: booking kamar.
- `booking_messages`: chat terkait booking.
- `support_messages`: pesan bantuan umum customer.
- `notification_logs`: riwayat kirim WhatsApp.
- `favorite_kosts`: favorit customer.
