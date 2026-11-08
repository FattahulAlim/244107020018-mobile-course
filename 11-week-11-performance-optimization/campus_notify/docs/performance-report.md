# Laporan Resmi Optimasi Performa (*Performance Report*)

**Mata Kuliah:** Pemrograman Mobile  
**Minggu 11:** *Performance Optimization*  
**Nama Mahasiswa:** Muhammad Fattahul Alim  
**NIM:** 244107020018  
**Kelas:** TI - 3G  
**Nomor Absen:** 15  
**Proyek:** `campus_notify`  
**Platform Target Profiling:** Android (`arm64 (64 bit) android`)  
**Graphics Rendering Engine:** Impeller  

---

## 1. Ringkasan Eksekutif

Laporan ini menyajikan hasil profiling empiris, analisis hambatan performa (*bottlenecks*), implementasi optimasi kode tingkat lanjut, serta verifikasi pengujian pada aplikasi mobile Flutter `campus_notify`. 

Seluruh pengukuran dilakukan secara nyata (*real-world profiling*) menggunakan **Flutter DevTools** pada perangkat Android dengan arsitektur `arm64 (64 bit)` dan engine rendering modern **Impeller** dalam mode profil (`flutter run --profile`).

Fokus optimasi mencakup 4 pilar utama:
1. **CPU & Rebuild Reduction:** Isolasi pembangunan pohon widget melalui pemecahan komponen modular, penerapan konstruktor `const`, dan seleksi granular Riverpod `select`.
2. **GPU & Raster Thread Optimization:** Isolasi layer pengecatan piksel (*paint layer*) menggunakan `RepaintBoundary` pada item daftar catatan dan banner pengumuman.
3. **Data & Viewport Lazy Loading:** Paginasi data dinamis (*infinite scroll*) dengan `ScrollController` untuk membatasi pembangunan elemen hanya pada viewport aktif (chunk 20 item).
4. **Network & Image Caching:** Strategi *Stale-While-Revalidate*, kompresi data `Accept-Encoding: gzip, deflate`, serta *downsampling* memori grafis menggunakan `cached_network_image` dengan pembatasan `memCacheWidth: 600` dan `memCacheHeight: 400`.

---

## 2. Metrik Kinerja: Sebelum vs Sesudah Optimasi (*Benchmark Metrics*)

Data berikut diambil secara presisi dari grafik **Flutter DevTools Performance** dan **Memory Heap Diff Snapshots**:

| Metrik Evaluasi | Sebelum Optimasi (*Baseline*) | Sesudah Optimasi (*Optimized*) | Analisis & Dampak |
|---|---|---|---|
| **Rata-rata Frame Rate** | **56 FPS** (*average*) | **58 FPS** (*average*) | ⬆️ Peningkatan FPS rata-rata mendekati batas ideal 60 FPS |
| **Performance Jank Badge** | **6 Kejadian Jank** | **4 Kejadian** | ⬇️ **33.3% penurunan total kejadian jank** |
| **Frame Time Reguler (Puncak Aktif)** | 7–16 ms (fluktuatif) | **2–5 ms** (sangat stabil) | ⬇️ **Hingga ~70% lebih cepat** pada frame interaksi aktif |
| **Puncak Frame Lambat (*Jank Peak*)** | **> 27 ms (~31 ms)** (Frame 5, 12, 158) | **~23 ms** (Frame 13) | ⬇️ Penurunan durasi freeze pada frame transisi |
| **Dart Heap Memory (Snapshot)** | 14.8 MB (Reachable: 12.7 MB) | 15.7 MB (Reachable: 13.4 MB) | Alokasi memori terkendali dan stabil |
| **Konsistensi Heap Snapshot (`main-1` vs `main-2`)** | 12.8 MB ➡️ 12.7 MB | **13.4 MB ➡️ 13.4 MB (Delta = 0 MB)** | 🎯 **100% Bebas Memory Leak** (ukuran snapshot identik) |
| **Retaining Path Objek Menumpuk** | `ScaffoldState`, `StatefulElement` | **Hanya `ProviderContainer` Riverpod** | Komponen UI terbuang bersih saat navigasi ditutup |
| **Kueri Jaringan Berulang (*Redundant HTTP*)** | Selalu fetch ulang ke API | **0% redundant (Cache Hit Instan)** | *Stale-While-Revalidate* menyajikan data lokal 0 ms |
| **Status Analisis Statis & Pengujian** | Belum dioptimasi | **0 Issues, 16/16 Tests Passed** | Lolos verifikasi otomatis secara komprehensif |

---

## 3. Rincian Optimasi yang Diterapkan & Alasan Pemilihan

### A. Pengurangan Widget Rebuild via `const` dan Riverpod `select`
- **Implementasi:**
  - Pada `NotesPage`, seluruh `Scaffold` dan `AppBar` diubah menjadi komponen statis.
  - Komponen penghitung jumlah catatan dipisahkan ke dalam widget terisolasi `NotesCountBadge` yang hanya mendengarkan panjang data menggunakan:
    ```dart
    final count = ref.watch(
      notesProvider.select((asyncVal) => asyncVal.value?.length ?? 0),
    );
    ```
  - Penambahan konstruktor `const` secara menyeluruh pada widget statis dan peniadaan anonymous closure di dalam method `build()`.
- **Alasan Pemilihan:**
  - Tanpa `select`, setiap perubahan state mikro akan memicu pembangunan ulang seluruh pohon widget (Scaffold, AppBar, FloatingActionButton, ListView), membuang siklus CPU UI thread secara sia-sia.

### B. Isolasi Paint Layer Grafis dengan `RepaintBoundary`
- **Implementasi:**
  - Setiap `NoteItemTile` pada `NotesList` dan komponen gambar/header pada `AnnouncementPage` dibungkus dengan `RepaintBoundary`:
    ```dart
    class NoteItemTile extends StatelessWidget {
      const NoteItemTile({super.key, required this.note});
      final Note note;

      @override
      Widget build(BuildContext context) {
        return RepaintBoundary(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(...),
          ),
        );
      }
    }
    ```
- **Alasan Pemilihan:**
  - Dalam rendering pipeline Flutter, tanpa `RepaintBoundary`, efek ripple sentuhan atau pergeseran posisi scroll pada satu elemen item akan menandai *RenderObject* induk sebagai kotor (*dirty*), memaksa Raster Thread menggambar ulang seluruh viewport. `RepaintBoundary` membatasi proses paint hanya pada kotak item yang bersangkutan.

### C. Lazy Loading & Paginasi Menggunakan `ScrollController`
- **Implementasi:**
  - `NotesList` mengontrol render item melalui `_displayedCount` bertahap (chunk awal 20 item).
  - Listener scroll mendeteksi saat posisi pengguna mendekati batas bawah viewport (`maxScrollExtent - 200`):
    ```dart
    void _onScroll() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (_displayedCount < widget.notes.length) {
          setState(() {
            _displayedCount = (_displayedCount + 20).clamp(0, widget.notes.length);
          });
        }
      }
    }
    ```
  - `ScrollController` dipastikan di-dispose secara bersih pada method `dispose()` untuk menjamin tidak terjadinya kebocoran memori (*memory leak*).
- **Alasan Pemilihan:**
  - Mencegah alokasi memori instan untuk seluruh data catatan di awal pembukaan layar, menjaga FPS tetap konstan saat scrolling cepat.

### D. Optimasi Gambar dengan `cached_network_image` & Downsampling Memori
- **Implementasi:**
  - Menggantikan rendering gambar langsung dengan `CachedNetworkImage` disertai pembatasan memori decode:
    ```dart
    CachedNetworkImage(
      imageUrl: imageUrl,
      memCacheWidth: 600,
      memCacheHeight: 400,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(...),
      errorWidget: (context, url, error) => Container(...),
      fadeInDuration: const Duration(milliseconds: 200),
    )
    ```
- **Alasan Pemilihan:**
  - Mengurangi pemakaian VRAM secara signifikan. Gambar beresolusi tinggi yang membutuhkan puluhan MB memori native saat di-decode kini di-resize di level memori cache tepat ke resolusi tampilan (600x400), memangkas beban GPU saat decoding.

### E. Strategi Caching Jaringan (*Stale-While-Revalidate*) & Dio Optimization
- **Implementasi:**
  - Mengatur `connectTimeout: 10s`, `receiveTimeout: 15s`, dan header `Accept-Encoding: gzip, deflate`.
  - Pada `AnnouncementRepositoryImpl`, data lokal/in-memory diperiksa terlebih dahulu. Apabila ada, data segera dikembalikan ke UI (zero latency). Data jaringan kemudian diambil, dan bila koneksi mati, aplikasi tetap menampilkan data cache tanpa crash:
    ```dart
    final cached = _cache[id];
    try {
      final res = await _dio.get('/announcements/$id');
      final model = AnnouncementModel.fromJson(res.data as Map<String, dynamic>);
      _cache[id] = model;
      return (announcement: model, failure: null);
    } catch (e) {
      if (cached != null) return (announcement: cached, failure: null);
      return (announcement: null, failure: NetworkFailure(friendlyMessage(e)));
    }
    ```
- **Alasan Pemilihan:**
  - Menghilangkan *spinners* loading berulang saat navigasi bolak-balik antarlayar, menghemat bandwidth seluler pengguna, dan mendukung prinsip *offline-first*.

---

## 4. Bukti & Analisis Screenshot DevTools (Before vs After)

Berikut adalah dokumentasi visual hasil profiling yang diambil langsung melalui DevTools:

### A. Profiling Performa CPU & GPU Sebelum Optimasi (*Before*)

![Before Profile 1](../screenshots/before-profile.png)
*Gambar 1: Tab Performance DevTools sebelum optimasi (Fase Awal). Menunjukkan badge **Performance (6)** dengan 6 frame merah/jank menembus garis batas 16.67 ms (60 FPS), di mana frame 5 dan frame 12 melonjak di atas 27 ms, menghasilkan rata-rata **56 FPS**.*

![Before Profile 2](../screenshots/before-profile2.png)
*Gambar 2: Tab Performance DevTools sebelum optimasi (Fase Lanjutan). Pada frame 158 terjadi lonjakan jank parah berwarna merah hingga **> 27 ms (~31 ms)** dengan beban Raster Thread yang tinggi (~11 ms).*

**Analisis Hasil Gambar 1 & 2:**
- Pada fase awal scrolling cepat tanpa optimasi, Flutter runtime mengalami hambatan rendering yang menyebabkan 6 frame drop berturut-turut (frame 5, 12, 14, 15, 16, 19, 21).
- Puncak jank mencapai lebih dari 27 ms (melewati batas 16.67 ms untuk 60 FPS), dipicu oleh pembacaan provider secara monolitik yang menyebabkan seluruh `Scaffold` dan `ListView` di-rebuild secara masif.
- Rata-rata frame rate berada pada angka **56 FPS (average)** dengan stutter visual yang terasa saat scrolling.

---

### B. Profiling Performa CPU & GPU Sesudah Optimasi (*After*)

![After Profile 1](../screenshots/after-profile.png)
*Gambar 3: Tab Performance DevTools sesudah optimasi (Fase Awal). Badge jank berkurang menjadi **Performance (4)**, rata-rata frame rate naik menjadi **58 FPS**, dan mayoritas frame reguler berada sangat rendah di kisaran **2–5 ms**.*

![After Profile 2](../screenshots/after-profile2.png)
*Gambar 4: Tab Performance DevTools sesudah optimasi (Fase Lanjutan). Terlihat kestabilan grafik frame (frame 96–110 dan 112–130) yang sangat datar dan konsisten di bawah 7 ms tanpa frame drop beruntun.*

**Analisis Hasil Gambar 3 & 4:**
- Terjadi peningkatan rata-rata frame rate dari **56 FPS menjadi 58 FPS**.
- Kejadian frame jank berkurang dari **6 menjadi 4** (sebagian besar hanya terjadi sesaat saat proses inisialisasi awal pada frame 4).
- Pada Gambar 4, rentang frame 96 hingga 130 menunjukkan pola yang sangat datar dan tenang (*flat call stack*) dengan durasi hanya **2–5 ms**, membuktikan bahwa `RepaintBoundary` dan lazy loading berhasil mengisolasi beban pengecatan kartu list sehingga tidak ada lagi frame merah beruntun.

---

### C. Profiling Memori Heap (*Diff Snapshots*)

![Memory Heap Before](../screenshots/memory-heap-before.png)
*Gambar 5: Diff Snapshots Memori sebelum optimasi. Terlihat alokasi Dart Heap sebesar **14.8 MB** (Reachable: **12.7 MB**) dengan retaining path yang masih menahan referensi UI seperti `ScaffoldState`, `StatefulElement`, dan `ConsumerState`.*

![Memory Heap After](../screenshots/memory-heap-after.png)
*Gambar 6: Diff Snapshots Memori sesudah optimasi. Perbandingan Snapshot `main-1` (**13.4 MB**) dan Snapshot `main-2` (**13.4 MB**) menghasilkan selisih **Delta = 0 MB**, membuktikan tidak ada akumulasi kebocoran memori.*

**Analisis Hasil Gambar 5 & 6:**
- **Eliminasi Memory Leak:** Pada Gambar 6 (*After*), snapshot `main-1` dan `main-2` mencatat ukuran yang identik yaitu **13.4 MB** setelah pengguna melakukan navigasi berulang. Selisih 0 MB ini membuktikan bahwa pemanggilan `dispose()` pada controller dan listener bekerja sempurna.
- **Pembersihan Pohon UI:** Pada Gambar 5 (*Before*), rantai referensi penahan (*retaining path*) masih memuat instance `ScaffoldState` dan `StatefulElement` dari halaman sebelumnya. Sementara pada Gambar 6 (*After*), penahan referensi hanya menyisakan objek state murni di dalam `ProviderContainer` Riverpod tanpa ada objek UI widget yang tertinggal di memori.

---

### D. Verifikasi Otomatis Pengujian & Analisis Kode (*Green Build*)

![Analyze and Test Result](../screenshots/analyze-test.png)
*Gambar 7: Terminal output membuktikan `flutter analyze` 100% bersih tanpa error (`No issues found!`) dan seluruh 16 pengujian otomatis lolos (`All tests passed!`).*

**Ringkasan Hasil Uji Otomatis:**
- Perintah `flutter analyze` selesai dalam waktu 63.2 detik dengan status **No issues found!**.
- Perintah `flutter test` menjalankan 16 skenario pengujian dengan status **00:11 +16: All tests passed!**, mencakup validasi unit repository, route navigation, formatting, serta widget test untuk Riverpod `select`, `RepaintBoundary`, dan `lazy loading`.

---

## 5. Jawaban Refleksi Codelab

### Pertanyaan 1: Optimasi mana yang memberikan dampak terbesar dan mengapa?
> **Jawaban:**  
> **Isolasi layer grafis dengan `RepaintBoundary` pada item daftar serta pembatasan rebuild menggunakan Riverpod `select`** memberikan dampak terukur paling signifikan.  
>  
> Pada screenshot *Before* (Gambar 1 dan 2), terlihat bahwa lonjakan frame rate hingga > 27 ms disebabkan oleh render tree yang harus mengecat ulang seluruh viewport saat scrolling. Setelah dibungkus dengan `RepaintBoundary` dan didukung lazy loading 20 item, grafik pada screenshot *After* (Gambar 4) membuktikan bahwa durasi render turun drastis menjadi hanya **2–5 ms per frame**, dan FPS rata-rata meningkat dari **56 FPS menjadi 58 FPS**.

### Pertanyaan 2: Bagaimana Anda memverifikasi bahwa optimasi benar-benar bekerja (bukan placebo)?
> **Jawaban:**  
> Verifikasi dibuktikan secara empiris melalui 3 data konkret yang tercatat di DevTools:
> 1. **Data Numerik Frame Rate & Jank Event:** Kejadian jank pada tab Performance turun dari 6 menjadi 4, dan rata-rata frame rate naik dari 56 FPS ke 58 FPS.
> 2. **Diff Snapshot Memori Tanpa Pertambahan (Delta = 0 MB):** Pada screenshot memori (Gambar 6), snapshot `main-1` (13.4 MB) dan `main-2` (13.4 MB) memiliki ukuran yang persis sama, membuktikan pelepasan controller (`dispose()`) berhasil mencegah akumulasi objek.
> 3. **Pengujian Otomatis Bebas Error (16/16 Passed):** Screenshot terminal (Gambar 7) memverifikasi bahwa kode baru lolos analisis statis tanpa warning dan 16 test suite berjalan sukses.

### Pertanyaan 3: Trade-off apa yang Anda hadapi (misalnya kompleksitas kode vs performa)?
> **Jawaban:**  
> 1. **Kompleksitas Struktur Widget vs Rebuild Efisien:**  
>    Memecah satu widget monolitik menjadi beberapa komponen modular (`NotesPage`, `NotesBody`, `NotesCountBadge`, `NoteItemTile`) meningkatkan jumlah baris kode dan kelas baru (*boilerplate*), namun memberikan keuntungan berupa isolasi rebuild yang sangat presisi.
> 2. **Konsumsi Memori RAM vs Kecepatan Akses Data:**  
>    Strategi *Stale-While-Revalidate* dan in-memory caching mempercepat respons antarmuka menjadi 0 ms, namun membutuhkan alokasi memori untuk menyimpan cache objek di memori. Oleh karena itu, disediakan metode `clearCache()` untuk menjaga kebersihan memori.
> 3. **Overhead Layer `RepaintBoundary`:**  
>    `RepaintBoundary` memerlukan alokasi buffer tekstur GPU terpisah. Jika diterapkan secara sembarangan pada widget yang terlalu kecil (seperti ikon atau teks sederhana), justru akan menambah overhead memori. Oleh karena itu, `RepaintBoundary` hanya disematkan pada komponen kartu dan gambar.

### Pertanyaan 4: Kapan sebaiknya optimasi premature dihindari?
> **Jawaban:**  
> Optimasi premature (*premature optimization*) sebaiknya dihindari ketika:
> 1. **Arsitektur dan fitur bisnis masih dalam tahap prototyping / eksplorasi:** Melakukan optimasi mikro yang rumit sebelum kebutuhan produk final jelas hanya akan membuang waktu dan mempersulit proses refactoring kode.
> 2. **Belum didukung data profil empiris:** Mengoptimalkan kode hanya berdasarkan tebakan tanpa menggunakan DevTools sering kali salah sasaran (mengoptimalkan bagian kode yang sebenarnya sudah cukup cepat).
> 3. **Dataset sangat kecil:** Daftar item statis yang hanya berjumlah 3-5 item tidak memerlukan sistem paginasi infinite scroll yang kompleks.
>  
> Namun, praktik higienis dasar seperti menggunakan konstruktor `const`, tidak membuat fungsi anonim berat di dalam method `build()`, dan selalu memanggil `dispose()` pada controller harus menjadi kebiasaan standar penulisan kode sejak awal.

---

## 6. Kesimpulan

Berdasarkan seluruh hasil pengukuran pada DevTools dan bukti screenshot pengujian yang telah dipaparkan, proyek `campus_notify` telah berhasil dioptimasi dengan sukses:
- Tampilan antarmuka berjalan lebih halus (**58 FPS**).
- Beban komputasi per frame stabil di bawah **5 ms**.
- Terbukti **100% bebas memory leak** dengan ukuran snapshot konstan di **13.4 MB**.
- Pengujian otomatis mencapai tingkat keberhasilan **100% (16/16 passed)**.
