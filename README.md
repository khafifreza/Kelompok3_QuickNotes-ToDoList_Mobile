# Quick Notes & To-Do List

## Program dan Penjelasan Program

**Quick Notes & To-Do List** adalah aplikasi Flutter untuk membuat dan mengelola catatan singkat. Pengguna dapat menulis judul dan isi catatan, menyematkan catatan penting, mencari catatan berdasarkan judul, serta mengatur urutannya. Aplikasi menyediakan tema terang dan gelap, sementara catatan disimpan secara lokal menggunakan SQLite.

Walaupun nama aplikasi menyebut *To-Do List*, fitur yang tersedia saat ini berfokus pada pencatatan. Belum ada fitur khusus untuk membuat daftar tugas dengan status selesai atau belum selesai.

### Fitur

- Membuat, melihat, mengubah, dan menghapus catatan.
- Memvalidasi agar judul dan isi catatan tidak kosong.
- Menyematkan atau melepas sematan catatan.
- Menampilkan semua catatan atau hanya catatan yang disematkan.
- Mencari catatan berdasarkan judul.
- Mengurutkan catatan berdasarkan waktu penambahan atau judul, serta membalik urutannya.
- Mengganti tema terang dan gelap; pilihan tema disimpan di preferensi perangkat.
- Menyimpan catatan di basis data lokal SQLite.
- Menyesuaikan tampilan daftar untuk layar sempit dan lebar.
- Menggunakan bahasa Indonesia pada antarmuka.

## Teknologi

- Flutter dan Dart
- SQLite melalui paket `sqflite`
- `shared_preferences` untuk menyimpan pilihan tema
- Dukungan SQLite untuk web dan desktop melalui `sqflite_common_ffi` dan `sqflite_common_ffi_web`

## Struktur Program

```text
lib/
├── main.dart                    # Inisialisasi aplikasi, bahasa, dan tema
├── database/
│   └── db_helper.dart           # Pembuatan dan operasi basis data catatan
├── models/
│   └── note_model.dart          # Model data catatan
└── screens/
    ├── home_screen.dart         # Daftar, pencarian, filter, dan pengurutan catatan
    └── note_editor_screen.dart  # Formulir untuk membuat dan mengubah catatan
```

## Menjalankan Program

Pastikan Flutter SDK telah terpasang, lalu jalankan perintah berikut dari direktori proyek:

```bash
flutter pub get
flutter run
```

Untuk memilih perangkat atau target tertentu, gunakan:

```bash
flutter devices
flutter run -d <id-perangkat>
```

Proyek ini menyertakan konfigurasi platform Android, iOS, web, Windows, macOS, dan Linux. Ketersediaan target untuk menjalankan atau membangun aplikasi bergantung pada Flutter SDK, perangkat, serta toolchain yang terpasang.
