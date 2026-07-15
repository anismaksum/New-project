# PRODUCT REQUIREMENTS DOCUMENT (PRD)

## 2.1 Latar Belakang

Perkembangan teknologi informasi telah mengubah cara masyarakat memperoleh berbagai layanan, termasuk dalam mencari tempat tinggal sementara seperti rumah kost. Saat ini masih banyak calon penyewa yang mencari informasi kost melalui media sosial, rekomendasi teman, atau mendatangi lokasi secara langsung. Cara tersebut membutuhkan waktu yang cukup lama dan sering kali informasi yang diperoleh tidak lengkap, seperti harga, fasilitas, ketersediaan kamar, maupun lokasi yang akurat.

Selain itu, pemilik kost juga mengalami kesulitan dalam mempromosikan properti kepada calon penyewa yang lebih luas. Informasi yang tersebar di berbagai platform membuat proses komunikasi menjadi kurang efisien dan tidak terpusat.

Berdasarkan permasalahan tersebut, dikembangkan aplikasi **KostHunt**, yaitu aplikasi mobile berbasis Flutter yang bertujuan memudahkan pengguna dalam mencari, melihat informasi, berkomunikasi dengan pemilik, serta melakukan pemesanan tempat kost melalui satu aplikasi yang terintegrasi.

---

# 2.2 Tujuan Produk

Pengembangan aplikasi KostHunt memiliki beberapa tujuan sebagai berikut:

1. Mempermudah masyarakat dalam mencari informasi tempat kost.
2. Menyediakan informasi kost yang lengkap dan mudah dipahami.
3. Mempermudah komunikasi antara calon penyewa dengan pemilik kost.
4. Membantu proses pemesanan kost secara lebih praktis.
5. Memberikan pengalaman pengguna (User Experience) yang sederhana, cepat, dan modern.

---

# 2.3 Target Pengguna

Target pengguna aplikasi KostHunt meliputi:

### 1. Mahasiswa

Mahasiswa yang berasal dari luar daerah dan membutuhkan tempat kost di sekitar kampus.

### 2. Pekerja

Karyawan atau pekerja yang membutuhkan tempat tinggal sementara maupun jangka panjang.

### 3. Pendatang

Masyarakat yang berpindah domisili ke suatu kota dan membutuhkan informasi kost sebelum datang ke lokasi.

### 4. Pemilik Kost

Pemilik atau pengelola kost yang ingin menawarkan properti kepada calon penyewa secara digital.

---

# 2.4 Permasalahan yang Diselesaikan

Aplikasi KostHunt dikembangkan untuk mengatasi beberapa permasalahan berikut.

* Sulit menemukan informasi kost yang lengkap.
* Pengguna harus mendatangi lokasi secara langsung untuk mengetahui kondisi kost.
* Sulit membandingkan harga dan fasilitas antar kost.
* Proses komunikasi dengan pemilik masih dilakukan melalui media yang berbeda.
* Belum adanya aplikasi yang mengintegrasikan pencarian, komunikasi, dan pemesanan kost dalam satu platform.

---

# 2.5 Ruang Lingkup Produk

Aplikasi KostHunt memiliki ruang lingkup sebagai berikut:

* Menampilkan daftar kost.
* Menampilkan detail informasi kost.
* Menampilkan harga dan fasilitas.
* Melakukan pencarian kost.
* Menyediakan fitur chat.
* Menyediakan fitur booking.
* Menampilkan profil pengguna.

---

# 2.6 Fitur Utama

Fitur utama yang terdapat pada aplikasi KostHunt meliputi:

### Login

Pengguna dapat masuk ke dalam aplikasi menggunakan akun yang telah dimiliki.

### Home

Menampilkan daftar kost yang tersedia beserta informasi singkat.

### Search Kost

Pengguna dapat mencari kost berdasarkan kata kunci.

### Detail Kost

Menampilkan informasi lengkap mengenai kost, seperti:

* Nama kost
* Harga
* Alamat
* Deskripsi
* Fasilitas
* Foto kost

### Booking

Memungkinkan pengguna melakukan pemesanan kamar kost.

### Chat

Pengguna dapat menghubungi pemilik kost melalui fitur percakapan.

### Profil

Menampilkan informasi akun pengguna.

---

# 2.7 Kebutuhan Fungsional

Berikut kebutuhan fungsional sistem.

| No   | Kebutuhan                                 |
| ---- | ----------------------------------------- |
| F-01 | Sistem dapat menampilkan halaman login.   |
| F-02 | Sistem dapat menampilkan daftar kost.     |
| F-03 | Sistem dapat melakukan pencarian kost.    |
| F-04 | Sistem dapat menampilkan detail kost.     |
| F-05 | Sistem dapat melakukan booking kost.      |
| F-06 | Sistem dapat menampilkan halaman chat.    |
| F-07 | Sistem dapat menampilkan profil pengguna. |

---

# 2.8 Kebutuhan Non-Fungsional

### Usability

Antarmuka dibuat sederhana sehingga mudah digunakan oleh seluruh pengguna.

### Performance

Aplikasi mampu menampilkan data dengan waktu respons yang cepat.

### Reliability

Aplikasi dapat berjalan secara stabil tanpa mengalami crash.

### Compatibility

Aplikasi dapat dijalankan pada perangkat Android yang mendukung Flutter.

### Security

Data pengguna dan proses autentikasi dijaga menggunakan layanan backend sehingga akses hanya diberikan kepada pengguna yang memiliki hak.

### Maintainability

Kode program dibuat secara modular sehingga mudah dikembangkan di masa mendatang.

---

# 2.9 Arsitektur Sistem

Arsitektur aplikasi KostHunt menggunakan konsep Client–Server.

```text
                USER
                  │
                  ▼
          Aplikasi Flutter
                  │
        HTTP / REST API
                  │
                  ▼
         Backend (Supabase)
                  │
                  ▼
        Database PostgreSQL
```

Penjelasan:

* **Flutter** berfungsi sebagai antarmuka pengguna (client).
* **Supabase** berfungsi sebagai backend yang menyediakan layanan autentikasi dan akses data.
* **PostgreSQL** berfungsi sebagai penyimpanan seluruh data aplikasi.

---

# 2.10 Database Schema

Secara umum database terdiri dari beberapa tabel utama.

### Users

| Field    | Tipe    |
| -------- | ------- |
| id       | UUID    |
| nama     | VARCHAR |
| email    | VARCHAR |
| password | VARCHAR |
| no_hp    | VARCHAR |

---

### Kost

| Field     | Tipe    |
| --------- | ------- |
| id        | UUID    |
| nama_kost | VARCHAR |
| alamat    | TEXT    |
| harga     | INTEGER |
| deskripsi | TEXT    |
| fasilitas | TEXT    |
| foto      | TEXT    |

---

### Booking

| Field           | Tipe    |
| --------------- | ------- |
| id              | UUID    |
| user_id         | UUID    |
| kost_id         | UUID    |
| tanggal_booking | DATE    |
| status          | VARCHAR |

---

### Chat

| Field       | Tipe      |
| ----------- | --------- |
| id          | UUID      |
| pengirim_id | UUID      |
| penerima_id | UUID      |
| pesan       | TEXT      |
| waktu       | TIMESTAMP |

---

### Relasi Database

```text
Users
   │
   ├──────── Booking ──────── Kost
   │
   └──────── Chat
```

---

# 2.11 Alur Sistem

Alur penggunaan aplikasi adalah sebagai berikut.

1. Pengguna membuka aplikasi.
2. Pengguna melakukan login.
3. Sistem menampilkan halaman Home.
4. Pengguna memilih salah satu kost.
5. Sistem menampilkan detail kost.
6. Pengguna dapat melakukan:

   * Booking
   * Chat dengan pemilik
7. Sistem menyimpan data ke database.
8. Pengguna dapat melihat riwayat atau profil.

---

# 2.12 Batasan Produk

Pada versi saat ini, aplikasi memiliki beberapa keterbatasan.

* Belum tersedia sistem ulasan dan rating.
* Belum tersedia integrasi Google Maps secara penuh.
* Belum tersedia verifikasi identitas pemilik kost.

---

# 2.13 Rencana Pengembangan

Pengembangan yang direncanakan pada versi berikutnya meliputi:

* Integrasi Google Maps.
* Sistem rating dan review.
* Notifikasi real-time.
* Dashboard khusus pemilik kost.
* Upload foto kost langsung dari aplikasi.
* Rekomendasi kost menggunakan Artificial Intelligence (AI).

---

# 2.14 Kesimpulan

KostHunt merupakan aplikasi pencarian kost berbasis mobile yang dirancang untuk membantu pengguna memperoleh informasi tempat tinggal secara lebih mudah, cepat, dan efisien. Dengan menyediakan fitur pencarian kost, detail informasi, komunikasi melalui chat, serta booking dalam satu aplikasi, KostHunt diharapkan mampu menjadi solusi digital yang mempermudah proses pencarian tempat tinggal.

Melalui pengembangan lebih lanjut, seperti integrasi penuh dengan backend, sistem pembayaran, dan layanan berbasis lokasi, aplikasi ini memiliki potensi untuk menjadi platform pencarian kost yang lebih lengkap dan bermanfaat bagi masyarakat.
