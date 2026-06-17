# KostHunt WhatsApp Server

Server lokal ini menyimpan token provider WhatsApp di environment, lalu Flutter
KostHunt memanggil endpoint lokal untuk mengirim notifikasi booking dan chat
customer.

Untuk saat ini provider yang dipakai adalah Fonnte. Token tetap berada di server
lokal, bukan di source Flutter, karena APK/web app bisa dibongkar.

Jalankan dari folder project:

```powershell
cd "C:\Users\ASUS\OneDrive\Documents\New project\kosthunt"
$env:FONNTE_TOKEN="TOKEN_FONNTE_KAMU"
dart run server\whatsapp_server.dart
```

Atau pakai script:

```powershell
cd "C:\Users\ASUS\OneDrive\Documents\New project\kosthunt"
.\server\run_whatsapp_server.ps1 -Token "TOKEN_FONNTE_KAMU"
```

Biarkan terminal server tetap hidup, lalu jalankan Flutter:

```powershell
flutter run -d edge
```

Nomor admin default yang dipakai server:

```text
085701054362 -> 6285701054362
```
