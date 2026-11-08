#  Pastel.Shop — Aplikasi Katalog Produk

Aplikasi katalog produk berbasis **Flutter** dengan desain antarmuka bernuansa pastel. Aplikasi ini menggunakan API dari DummyJSON untuk menampilkan data produk dan menyediakan fitur pencarian serta pengelolaan informasi produk.

##  Tentang Aplikasi

Pastel.Shop merupakan aplikasi katalog produk yang dirancang untuk perangkat Android. Aplikasi ini menampilkan berbagai produk beserta gambar, nama, harga, merek, dan kategori. Pengguna dapat mencari produk, menyaring berdasarkan kategori, mengurutkan daftar produk, serta melihat detail setiap produk.

##  Fitur Utama

- **Daftar Produk** — Menampilkan produk dari API DummyJSON.
- **Detail Produk** — Menampilkan informasi produk secara lebih lengkap.
- **Pencarian Produk** — Mencari produk berdasarkan kata kunci.
- **Filter Kategori** — Menampilkan produk berdasarkan kategori.
- **Pengurutan Produk** — Mengurutkan produk berdasarkan harga, nama, atau rating.
- **Paginasi** — Menjelajahi daftar produk melalui beberapa halaman.
- **Mode Ringkas** — Menampilkan informasi produk yang lebih sederhana.
- **Tambah Produk** — Mengirim data produk baru menggunakan metode POST.
- **Edit Produk** — Memperbarui data produk menggunakan metode PUT atau PATCH.
- **Hapus Produk** — Menghapus produk menggunakan metode DELETE.

##  Desain Antarmuka

Aplikasi menggunakan skema warna pastel untuk menghasilkan tampilan yang lembut, menarik, dan nyaman dilihat pada perangkat mobile.

##  Teknologi yang Digunakan

- **Flutter** — Framework pengembangan aplikasi mobile.
- **Dart** — Bahasa pemrograman.
- **Dio** — Mengirim permintaan HTTP ke API.
- **Provider** — Mengelola state aplikasi.
- **GoRouter** — Mengatur navigasi ant halaman.
- **Cached Network Image** — Memuat gambar produk dari internet.
- **DummyJSON Products API** — Sumber data produk.

##  API yang Digunakan

Dokumentasi API: https://dummyjson.com/docs/products

Base URL:

`https://dummyjson.com`

Endpoint utama yang digunakan:

| Metode | Endpoint | Fungsi |
|---|---|---|
| GET | `/products` | Mengambil daftar produk |
| GET | `/products/{id}` | Mengambil detail produk |
| GET | `/products/search?q=phone` | Mencari produk |
| GET | `/products/categories` | Mengambil kategori produk |
| GET | `/products/category/{category}` | Memfilter produk berdasarkan kategori |
| POST | `/products/add` | Menambahkan produk |
| PUT | `/products/{id}` | Memperbarui seluruh data yang dikirim |
| PATCH | `/products/{id}` | Memperbarui sebagian data |
| DELETE | `/products/{id}` | Mengirim permintaan penghapusan produk |

**Catatan:** DummyJSON menyimulasikan operasi tambah, edit, dan hapus. Respons API tidak berarti perubahan tersebut tersimpan secara permanen di server.

##  Cara Menjalankan Aplikasi

### Persyaratan

- Flutter SDK
- Dart SDK
- Visual Studio Code atau IDE Flutter lainnya
- Perangkat Android
- Koneksi internet

### Langkah Menjalankan

1. Clone repositori ini ke komputer:

   ```bash
   git clone URL_REPOSITORY_GITHUB
   ```

2. Masuk ke folder proyek:

   ```bash
   cd NAMA_FOLDER_PROYEK
   ```

3. Unduh dependensi:

   ```bash
   flutter pub get
   ```

4. Pastikan perangkat Android terdeteksi:

   ```bash
   flutter devices
   ```

5. Jalankan aplikasi:

   ```bash
   flutter run
   ```

##  Video Penjelasan dan Demo

Video penjelasan dan demonstrasi aplikasi dapat dilihat melalui tautan berikut:

**YouTube:** [Masukkan link video YouTube di sini]

##  Identitas Mahasiswa

- **Nama:** Nayla Octamandhani
- **Nim:** 240102094
- **Kelas:** IF24C
- **Mata Kuliah:** Pemrograman Perangkat Bergerak (PPB)
- **Nama Aplikasi:** Pastel.Shop
- **Link Youtube:** https://youtu.be/HDk0egaEkJ0?si=EyRQRZN4QOK2xoYG

---

Dibuat sebagai  tugas mata kuliah Pemrograman Perangkat Bergerak (PPB).


# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
