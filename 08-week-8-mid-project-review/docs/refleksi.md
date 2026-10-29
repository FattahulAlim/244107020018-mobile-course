# Refleksi Pembelajaran Week 8 — Mid Project Review & Code Review

| Field | Detail |
|---|---|
| **Nama** | Muhammad Fattahul Alim |
| **NIM** | 244107020018 |
| **Kelas** | TI - 3G |
| **Absen** | 15 |

---

### 1. Apa beda LGTM ("Looks Good To Me") buta dengan approve yang bertanggung jawab? Apa risikonya bagi tim?

- **LGTM Buta:**
  Reviewer hanya sekadar membuka halaman Pull Request di GitHub, melihat judul sepintas tanpa meng-checkout branch, tidak menjalankan aplikasi, tidak mengecek static analysis/test secara lokal, dan langsung menekan tombol "Approve" dengan komentar formalitas seperti "LGTM".
- **Approve yang Bertanggung Jawab:**
  Reviewer benar-benar memahami konteks masalah (issue) dan solusi yang diajukan. Reviewer memverifikasi apakah branch bersih, menarik kode ke lokal (git checkout), menjalankan `flutter analyze`, `dart format`, dan `flutter test`, serta menguji fungsionalitas dan edge case aplikasi secara manual. Reviewer memastikan tidak ada aturan arsitektur (seperti Clean Architecture dependency rule) yang dilanggar sebelum memberikan approval.
- **Risiko LGTM Buta bagi Tim:**
  1. **Kerusakan di Branch Utama (`develop`/`main`):** Bug, error null-pointer, atau unhandled exceptions lolos ke branch utama dan menyulitkan anggota tim lain yang menarik kode terbaru.
  2. **Architectural Drift:** Pola isolasi layer (misal Clean Architecture) perlahan rusak karena import lintas layer tidak dicegah sejak awal.
  3. **Penurunan Budaya Kualitas Tim:** Developer cenderung menulis kode secara terburu-buru dan tidak disiplin karena tahu PR mereka tidak akan diperiksa secara kritis.

---

### 2. Kapan komentar wajib berstatus Request Changes, dan kapan cukup saran (Comment / Suggestion)?

- **Wajib berstatus Request Changes jika:**
  1. **Kesalahan Logika & Bug Fungsional:** Kode menyebabkan crash, memory leak (seperti controller tidak di-dispose), atau data korup/hilang.
  2. **Pelanggaran Aturan Arsitektur:** Terjadi pelanggaran dependency rule (misal layer `domain` mengimpor layer `presentation` atau framework eksternal Flutter/Dio/SQLite).
  3. **Keamanan & Kredensial:** Ada rahasia (hardcoded API keys, tokens, passwords) atau celah keamanan yang terekspos.
  4. **Pemeriksaan Mesin Gagal:** `flutter analyze` menghasilkan error/warning atau `flutter test` mengalami kegagalan (broken test).
  Pada kondisi ini, PR tidak boleh di-merge sampai author melakukan perbaikan dan meminta re-review.

- **Cukup berstatus Saran (Comment / Suggestion / Nitpick) jika:**
  1. **Keterbacaan & Kosmetik Non-Kritis:** Usulan penamaan variabel yang lebih ekspresif atau pemisahan method kecil yang sifatnya opsional.
  2. **Optimasi Performa Minor:** Penggunaan pola alternatif yang performanya sedikit lebih baik tetapi kode saat ini masih aman dan tidak menyebabkan bottleneck.
  3. **Diskusi Alternatif:** Saran refactor jangka panjang untuk tiket mendatang (*technical debt*) yang tidak menghalangi kelayakan rilis fitur saat ini.

---

### 3. Bagian mana dari review AI yang Anda tolak atau sederhanakan, dan mengapa?

- **Bagian yang DITOLAK KERAS:**
  Usulan AI (Temuan 4) yang menyarankan untuk memindahkan validasi input dan tampilan dialog/SnackBar peringatan langsung ke dalam entity `Note` di layer `domain` dengan mengimpor `package:flutter/material.dart` dan menerima parameter `BuildContext`.
  - **Alasan Penolakan:**
    Usulan tersebut **merusak Clean Architecture Dependency Rule**. Layer `domain` dirancang sebagai lapisan murni logika bisnis (*pure Dart*) yang sama sekali tidak boleh bergantung pada Flutter SDK, UI context, atau package pihak ketiga. Menerima usulan AI ini secara mentah akan merusak sterilitas layer domain yang telah dibangun di Minggu 7.
- **Bagian yang DISEDERHANAKAN:**
  Usulan AI (Temuan 3) mengenai penanganan async feedback dan loading state kompleks pada dialog simpan.
  - **Alasan Penyederhanaan:**
    Karena State Management sudah ditangani secara reaktif menggunakan `AsyncNotifier` dari Riverpod, UI utama di halaman luar sudah otomatis merender kondisi `AsyncLoading` dan `AsyncError`. Dialog cukup memvalidasi form dan memanggil notifier, tanpa perlu membuat state machine tambahan yang over-engineered untuk dialog sederhana.

---

### 4. Satu hal konkret yang Anda perbaiki setelah review sejawat — apa dampaknya?

- **Hal Konkret yang Diperbaiki:**
  Pada implementasi awal tombol tambah catatan (`FloatingActionButton`), aksi tombol langsung mengeksekusi penambahan catatan otomatis dengan teks default berupa timestamp (`Note ${DateTime.now().second}`) tanpa ada interaksi pengguna. Setelah direview oleh rekan sejawat, diberikan masukan bahwa pengguna harus bisa menginput judul catatan sendiri secara fleksibel dan judul tidak boleh disimpan dalam keadaan kosong.
- **Tindakan Perbaikan:**
  Dibuat sebuah dialog input berbasis `AlertDialog` dengan `TextFormField`, lengkap dengan `FormState` validator untuk mencegah judul kosong atau whitespace (`value.trim().isEmpty`).
- **Dampaknya:**
  Aplikasi menjadi jauh lebih manusiawi dan sesuai dengan use case catatan riil, mencegah data sampah (empty records) tersimpan ke dalam database lokal SQLite, serta meningkatkan kualitas UX dan reliabilitas fungsional aplikasi.
