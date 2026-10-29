# AI Assisted Development Log (`docs/ai-log.md`)

Dokumentasi lengkap proses siklus **Prompt -> Generate -> Verify -> Test -> Refactor -> Explain** pada penambahan fitur pencarian catatan (*Search Notes*) dan *Empty State* pada project `week5_offline_notes` (Minggu 9 - AI-assisted Development / Vibe Coding).

---

## 1. Praktikum 1: Prompt & Context Engineering

### Formula 5 Slot Prompt
Sesuai panduan Codelab Minggu 9, perancangan prompt wajib mengisi 5 slot spesifik tanpa menyertakan kredensial/secret:

| Slot | Definisi & Nilai |
|------|------------------|
| **Peran** | Senior Flutter & Dart Developer |
| **Konteks** | Flutter 3.x, Feature-first architecture (`presentation` -> `domain` <- `data`), Riverpod 3.x (`NotifierProvider` / `AsyncNotifier`), SQLite (`sqflite`), Offline Notes app |
| **Tugas** | Tambahkan fitur pencarian (*search*) judul dan isi catatan (*notes*) lengkap dengan komponen *empty state* saat hasil pencarian tidak ditemukan |
| **Batas** | Jangan ubah struktur arsitektur yang ada; jangan lakukan query database langsung dari Widget UI; pisahkan logika filter ke domain use case murni (tanpa import Flutter/Dio/SQLite); maks 80 baris per fungsi/komponen |
| **Output** | Kode domain use case murni (`filterNotes` / `SearchNotesUseCase`), provider Riverpod, komponen UI, unit test (minimal 1 sukses dan 1 gagal/edge case), dan cara pengujian |

### Raw Prompt yang Dikirim ke AI
```text
Peran: Senior Flutter Developer
Konteks: Proyek Flutter offline_notes dengan arsitektur layered (presentation -> domain <- data). Menggunakan state management Riverpod 3.x, penyimpanan lokal SQLite (sqflite), dan Dio. Model Note memiliki atribut: id (int?), title (String), body (String), updatedAt (DateTime), dirty (bool).
Tugas: Buatkan fitur pencarian catatan (search notes) berdasarkan judul dan isi catatan, lengkap dengan penanganan empty state saat pencarian tidak menghasilkan data.
Batas:
- Jangan panggil SQLite atau query database langsung dari dalam Widget UI.
- Logika filtering harus berupa use case domain murni (pure Dart) tanpa dependensi package flutter/* atau sqflite.
- Jangan melebihi 80 baris per file/fungsi.
Output: Kode Dart untuk domain use case, Riverpod provider, integrasi UI NotesPage, dan unit test pengujian query cocok, tidak cocok, serta empty state.
```

---

## 2. Praktikum 2: Generate & Verifikasi Search

### Draft Kode Awal Hasil Generate AI (Raw AI Output)
```dart
// DRAFT AWAL HASIL GENERASI AI (Belum diverifikasi):
class SearchService {
  List<Note> search(List<Note> notes, String query) {
    // Naive filter
    return notes.where((note) => note.title.contains(query)).toList();
  }
}

// Widget search bar usulan AI:
class NotesSearchBar extends StatelessWidget {
  final Function(String) onSearch;
  const NotesSearchBar({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: (val) {
        // AI menyarankan langsung query SQLite via repository di callback widget
        onSearch(val);
      },
    );
  }
}
```

### Verifikasi 6 Langkah

1. **Baca baris demi baris:**
   - Logika `note.title.contains(query)` bersifat *case-sensitive*. Jika pengguna mengetik `"belanja"`, catatan dengan judul `"Daftar Belanja"` tidak akan ditemukan.
   - Pengecekan tidak melakukan `.trim()`, sehingga spasi di awal atau akhir (*trailing spaces*) merusak hasil filter.
   - Hanya memeriksa `title`, mengabaikan isi catatan (`body`).
2. **Cek Import Domain:**
   - Memastikan `lib/domain/usecases/search_notes_usecase.dart` **100% bebas** dari `package:flutter/...`, `package:sqflite/...`, dan `package:dio/...`.
   - Menggunakan pure Dart murni.
3. **Cek Validitas API:**
   - Memeriksa metode `where`, `toLowerCase`, `trim`, dan operator pencarian Dart standar yang terbukti stabil di SDK Dart ^3.x.
4. **Analisis Statis (`flutter analyze`):**
   - Menjalankan static analysis hingga mencapai **0 warning / 0 issue**.
5. **Unit & Widget Testing:**
   - Membuat unit test `test/search_filter_test.dart` (5 pengujian mencakup case-insensitive, query kosong, query tidak cocok, leading/trailing space trimming, dan pencarian pada body).
   - Membuat widget test `test/search_widget_test.dart` (5 skenario pengujian UI, interaksi pengetikan query, kemunculan empty state, dan tombol pembersihan pencarian).
6. **Uji Manual:**
   - Query kosong: menampilkan seluruh catatan.
   - Query cocok: hanya menampilkan catatan yang relevan.
   - Query tak cocok: menampilkan `EmptyStateWidget` dengan pesan jelas dan tombol pemulihan.

### Bukti Bug & Halusinasi AI yang Ditemukan
- **Bug/Halusinasi 1 (Case-Sensitivity & Whitespace Failure):**
  - *Temuan:* AI menghasilkan filter `note.title.contains(query)`.
  - *Bukti Uji:* Saat diuji dengan unit test `filterNotes(list, 'belanja')` pada item berlabel `"Belanja"`, panjang hasil adalah 0 (gagal / test merah).
  - *Perbaikan:* Menggunakan `.trim().toLowerCase()` baik pada query maupun atribut target (`note.title` dan `note.body`).
- **Bug/Halusinasi 2 (Pencampuran Layer UI dan Database):**
  - *Temuan:* Pada salah satu draf alternatif, AI menyarankan memanggil query database langsung dari method `onChanged` TextField.
  - *Bukti Pembuktian:* Menabrak Clean Architecture Minggu 7, menyulitkan unit testing tanpa mocking DB.
  - *Perbaikan:* Dipisahkan ke `SearchNotesUseCase` di layer domain dan dihubungkan ke UI melalui `filteredNotesProvider` Riverpod.

---

## 3. Praktikum 3: Debug & Refactor ke Clean Architecture

### Siklus Debugging Test Merah (Red-Green-Refactor)
1. **Reproduksi:** Memasukkan query `"belanja"` terhadap catatan `"Daftar Belanja Mingguan"`.
2. **Isolasi Masalah:** Fungsi awal AI gagal karena perbedaan kapitalisasi huruf (`'b'` vs `'B'`).
3. **Test Merah (Failing Test):**
   ```dart
   test('filter abaikan huruf besar/kecil', () {
     final results = rawAiFilter(sampleNotes, 'belanja');
     expect(results, hasLength(2)); // Gagal: expected 2, actual 0
   });
   ```
4. **Perbaikan (Green):** Mengimplementasikan normalisasi teks:
   ```dart
   final trimmed = query.trim().toLowerCase();
   if (trimmed.isEmpty) return notes;
   return notes.where((n) =>
       n.title.toLowerCase().contains(trimmed) ||
       n.body.toLowerCase().contains(trimmed)).toList();
   ```
5. **Refactoring:** Mengekstraksi kode menjadi kelas domain use case terpisah dan komponen widget modular:
   - `lib/domain/usecases/search_notes_usecase.dart` (Clean domain rule)
   - `lib/widgets/empty_state_widget.dart` (Modular empty state presentation)
   - `lib/widgets/note_search_bar.dart` (Modular search bar presentation)

---

## 4. AI Challenge & Review Skenario

### Prompt Review Kode ke AI (Senior Dev Review)
```text
Review kode fitur search Flutter berikut sebagai Senior Mobile Engineer:
- File: search_notes_usecase.dart, notes_page.dart, empty_state_widget.dart, note_search_bar.dart
Konteks: Clean Architecture (presentation -> domain <- data), Riverpod 3.x, SQLite offline-first.
Fokus: Kebenaran logika, integritas arsitektur, reaktivitas state, dan kemudahan pengujian (testability).
Berikan minimal 3 temuan dengan level urgensi (Blocker / Warning / Saran) beserta alasan teknisnya.
```

### Temuan Review & Keputusan Evaluasi

| No | Temuan AI Assistant | Level Urgensi | Keputusan | Alasan Teknis & Tindakan |
|----|---------------------|---------------|-----------|--------------------------|
| 1 | **Logika filter wajib mengabaikan spasi berlebih (leading/trailing whitespace) dan case-folding** | Blocker | **DITERIMA** | Spasi tidak sengaja dari keyboard mobile pengguna akan menggagalkan pencarian jika tidak di-trim. Diterapkan `query.trim().toLowerCase()`. |
| 2 | **Pisahkan TextEditingController lifecycle ke ConsumerStatefulWidget agar tidak memicu memory leak** | Warning | **DITERIMA** | Penggunaan controller di dalam stateless widget berisiko kebocoran resource atau kesulitan membuang (*dispose*) listener. Diterapkan `ConsumerStatefulWidget` dengan `dispose()`. |
| 3 | **Gunakan SQLite `LIKE %query%` di NoteRepository untuk efisiensi memori dibanding filtering in-memory** | Saran | **DITOLAK** | Untuk aplikasi catatan luring berskala kecil-menengah (< 500 data), filtering in-memory via Riverpod jauh lebih responsif (instant UI update tanpa async database I/O lag) dan menjaga layer domain murni terisolasi. Query database berulang setiap ketukan tombol (*keystroke*) justru meningkatkan beban I/O disk lokal dan memperlambat rendering jika tanpa debouncer kompleks. |

---

## 5. Ringkasan Verifikasi & Bukti Mesin

- **Dart Format:** 100% konsisten (`dart format .` lolos).
- **Flutter Analyze:** `No issues found!` (0 error, 0 warning, 0 hint).
- **Flutter Test:** 14/14 tests PASSED:
  - `test/note_test.dart` (4 test bawaan repository & model)
  - `test/search_filter_test.dart` (5 unit test use case & fungsi murni)
  - `test/search_widget_test.dart` (5 widget test UI, empty state, & user interaction)

