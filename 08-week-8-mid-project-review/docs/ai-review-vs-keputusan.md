# AI Review vs Keputusan Final (AI Challenge Week 8)

| Metadata | Keterangan |
|---|---|
| **Nama** | Muhammad Fattahul Alim |
| **NIM** | 244107020018 |
| **Kelas** | TI - 3G|
| **Projek Direview** | `05-week-5-local-storage-offline-first/week5_offline_notes` & `06-week-6-authentication-security-fcm/campus_notify` |
| **Pull Request** | PR #2: `feat(notes): validasi judul kosong + test` (Branch `feat/notes-validation` ke `develop`) |

---

## 1. Prompt yang Digunakan

Prompt berikut diberikan kepada AI Coding Assistant (Senior Flutter Reviewer persona) sesuai instruksi Codelab:

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

---

## 2. Output Awal AI Reviewer

Berikut adalah respons mentah yang dihasilkan oleh AI Reviewer:

```markdown
### Hasil Review PR: feat(notes): validasi judul kosong + test

#### Temuan 1: [BLOCKER] Potensi Memory Leak pada TextEditingController
- **Lokasi:** `notes_page.dart` dalam fungsi `_showAddNoteDialog`
- **Alasan:** `final titleController = TextEditingController();` dibuat di dalam method tanpa pernah di-dispose. Saat dialog ditutup berulang kali, controller lama tetap tertinggal di memori.
- **Usulan Perbaikan:**
  Ubah dialog menjadi `StatefulWidget` tersendiri dan lakukan `dispose()` pada controller di `dispose()`.

#### Temuan 2: [BLOCKER] Validasi Bisnis Hanya Ada di UI (Presentation Layer Leaking)
- **Lokasi:** `notes_page.dart` (hanya divalidasi via `Form.validator`)
- **Alasan:** Validasi "judul tidak boleh kosong" adalah aturan bisnis. Jika ada pemanggilan `ref.read(notesProvider.notifier).addNote("")` dari bagian lain atau test, data kosong tetap tersimpan ke local database SQLite.
- **Usulan Perbaikan:**
  Tambahkan guard clause di UseCase/Notifier:
  ```dart
  Future<void> addNote(String title) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError('Judul catatan tidak boleh kosong');
    }
    // simpan ke repository...
  }
  ```

#### Temuan 3: [SARAN] Penanganan Error & Async Feedback Tidak Ada
- **Lokasi:** Tombol simpan `ElevatedButton.onPressed`
- **Alasan:** Dialog langsung ditutup (`Navigator.pop`) tanpa menunggu hasil Future dari `addNote`. Jika SQLite gagal menulis (misal disk full / table error), user mengira catatan sudah tersimpan padahal gagal.
- **Usulan Perbaikan:**
  Gunakan `await` dan tangkap error, atau amati AsyncValue state di UI.

#### Temuan 4: [BLOCKER] Pindahkan Validasi Form dan Notifikasi Langsung ke Domain Entity
- **Lokasi:** Layer `domain/entities/note.dart`
- **Alasan:** Agar lebih terpusat, validasi dan pembuatan SnackBar peringatan harus disatukan langsung ke dalam entity `Note` di domain dengan menerima `BuildContext` untuk menampilkan feedback jika gagal.
- **Usulan Perbaikan:**
  ```dart
  // Di domain/entities/note.dart
  import 'package:flutter/material.dart';
  
  class Note {
    ...
    bool validateAndAlert(BuildContext context) {
      if (title.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error')));
        return false;
      }
      return true;
    }
  }
  ```

#### Temuan 5: [SARAN] Kurang Pengujian Edge Case pada Unit Test
- **Lokasi:** `test/note_test.dart`
- **Alasan:** Unit test yang ada baru menguji input valid standar, belum menguji input string hanya spasi (`"   "`), simbol spesial, atau penanganan ketika validasi melempar error.
- **Usulan Perbaikan:**
  Tambahkan test case:
  ```dart
  test('addNote dengan judul spasi kosong harus throw ArgumentError', () async {
    expect(() => notifier.addNote('   '), throwsA(isA<ArgumentError>()));
  });
  ```
```

---

## 3. AI Verification Checklist & Tabel Usulan vs Keputusan Final

| # | Temuan AI | Verifikasi & Bukti Lapangan | Keputusan | Alasan Teknis |
|---|---|---|---|---|
| 1 | **Memory Leak TextEditingController** | **Terbukti Benar**. Pada `notes_page.dart` baris 69, `final titleController = TextEditingController();` diinstansiasi setiap dialog dibuka tanpa `dispose()`. | **DITERIMA** | Menghindari kebocoran memori saat pengguna sering membuka/tutup dialog tambah catatan. Diperbaiki dengan membungkus dialog ke widget privat ber-state atau memastikan controller di-dispose saat dialog di-dismiss. |
| 2 | **Validasi Aturan Bisnis Hanya di UI** | **Terbukti Benar**. Diuji secara manual dan unit test: memanggil `notesNotifier.addNote("")` langsung tanpa dialog berhasil menyimpan record kosong ke SQLite. | **DITERIMA** | Menjaga integritas data. Lapisan domain/use case harus menjaga invariant bisnis terlepas dari apakah input datang dari UI Form, API sync, atau unit test. |
| 3 | **Feedback Async / Error Handling** | **Terbukti Benar**. `ref.read(notesProvider.notifier).addNote(...)` adalah operasi asynchronous `Future`, namun `Navigator.pop(dialogContext)` langsung dipanggil synchronous. | **DISEDERHANAKAN** | Untuk dialog sederhana, `AsyncNotifier` Riverpod sudah mengelola `state = const AsyncLoading()`. UI list utama bereaksi otomatis terhadap perubahan state, namun guard try-catch lokal tetap ditambahkan untuk menangkap exception. |
| 4 | **Pindahkan Validasi & SnackBar ke Domain Entity** | **HALUSINASI / MENYIMPANG**. Usulan AI mengimpor `package:flutter/material.dart` dan membawa `BuildContext` ke dalam layer `domain/entities/note.dart`. | **DITOLAK** | **Melanggar Clean Architecture Dependency Rule!** Layer Domain harus *pure Dart* dan sepenuhnya independen dari framework UI (Flutter SDK) serta infrastruktur eksternal. UI feedback adalah tanggung jawab Presentation Layer. Hasil 3 grep sterilitas Minggu 7 membuktikan layer domain 0 import flutter. |
| 5 | **Kurangnya Test Kasus Negatif / Edge Case** | **Terbukti Benar**. Pada file test sebelumnya, hanya ada pengujian happy path (`addNote('Catatan 1')`). Belum ada test untuk validasi judul kosong. | **DITERIMA** | Ditambahkan unit test baru di `test/note_test.dart` untuk memastikan string whitespace (`"   "`) ditolak oleh sistem validasi. |

---

## 4. Bukti Verifikasi Mesin (Test, Analyze, Grep)

### A. Bukti Penolakan Temuan 4 (Grep Sterilitas Layer Domain)
Memastikan tidak ada Flutter SDK atau UI di layer domain:
```powershell
Get-ChildItem -Path lib\features -Recurse -Filter *.dart | Where-Object { $_.FullName -match "\\domain\\" } | Select-String -Pattern "package:flutter/"
```
**Hasil:** `0 temuan` (Layer domain steril). Usulan AI yang menyuruh import Flutter ke domain entity resmi ditolak.

### B. Bukti `flutter analyze`
![flutter analyze](../screenshots/analyze.png)

### C. Bukti `flutter test`
![flutter test](../screenshots/test.png)

Semua test sukses dijalankan termasuk penambahan pengujian validasi input kosong.
