# Dokumen Temuan Profiling Performa (*Performance Findings*)

**Mata Kuliah:** Pemrograman Mobile  
**Minggu 11:** *Performance Optimization*  
**Nama Mahasiswa:** Muhammad Fattahul Alim  
**NIM:** 244107020018  
**Kelas:** TI - 3G / Absen 15  
**Proyek:** `campus_notify`  
**Platform Target Profiling:** Android (`arm64 (64 bit) android`)  
**Graphics Rendering Engine:** Impeller  

---

## 1. Latar Belakang & Baseline Profiling

Sebelum menerapkan optimasi kode, dilakukan investigasi profil awal (*baseline profiling*) menggunakan **Flutter DevTools** yang dijalankan pada mode profil (`flutter run --profile`) di perangkat fisik Android `arm64 (64 bit)`. 

### Skenario Uji Profiling:
1. Membuka halaman login dan navigasi ke beranda (`HomePage`).
2. Membuka daftar catatan (`NotesPage`), melakukan *fast-scrolling* naik dan turun secara berulang.
3. Membuka detail pengumuman (`AnnouncementPage`), memuat konten, kembali ke beranda, dan mengulang 5 kali.
4. Memicu interaksi antarmuka dan mengambil *Heap Snapshot* pada tab Memory.

---

## 2. Metrik Baseline Hasil Pengukuran DevTools (Berdasarkan Screenshot)

| Parameter Profiling | Nilai Baseline DevTools | Status Ambang Batas (*Budget*) | Keterangan Diagnostik Visual |
|---|---|---|---|
| **Average Frame Rate** | **56 FPS** | ⚠️ Di bawah target 60 FPS | Terdapat lag visual saat interaksi antarmuka |
| **Performance Jank Badge** | **6 Kejadian Jank** | ❌ Kritis (> 16.67 ms) | Terdeteksi 6 frame lambat pada DevTools tab Performance |
| **Puncak Durasi Frame Lambat** | **> 27 ms (~31 ms)** | ❌ Sangat Kritis | Frame 5, 12, dan 158 melonjak merah menembus budget |
| **Beban Raster Thread** | **Hingga ~11 ms - 16 ms** | ⚠️ Cukup Berat | GPU terbebani decode dan pengecatan ulang layer viewport |
| **Dart Heap Memory (Snapshot)** | **14.8 MB** (Reachable: 12.7 MB) | ⚠️ Cukup Tinggi | Banyak objek UI dan elemen stateful tertahan |
| **Retaining Path UI** | `ScaffoldState`, `StatefulElement` | ❌ Berpotensi Leak | Komponen antarmuka menahan referensi di memori |
| **Kueri Jaringan HTTP** | 100% selalu fetch ulang | ❌ Tidak Efisien | Tidak ada caching data pengumuman di level lokal |

---

## 3. Identifikasi Masalah Utama (*Key Performance Bottlenecks*)

Berdasarkan analisis visual Flame Chart, Timeline Events, dan Heap Snapshot pada DevTools (`screenshots/before-profile.png`, `screenshots/before-profile2.png`, dan `screenshots/memory-heap-before.png`), diidentifikasi 5 masalah performa utama:

### Masalah 1: Rebuild Berlebih pada Seluruh Hirarki Widget (*Over-Rebuilding Root Tree*)
- **Lokasi Kode:** `lib/features/notes/presentation/pages/notes_page.dart` dan `lib/features/announcements/presentation/pages/announcement_page.dart`
- **Temuan DevTools:**
  - Pada tab *Performance (Flame Chart)*, terlihat pemanggilan berulang `build` pada komponen root `Scaffold`, `AppBar`, dan `NotesPage` setiap kali state Riverpod mengalami perubahan.
  - Pada `NotesPage`, pembacaan provider menggunakan `ref.watch(notesProvider)` di method build utama menyebabkan seluruh halaman ter-rebuild meskipun hanya ada pembaruan parsial data atau saat scrolling.
  - Widget tidak memanfaatkan selektor spesifik seperti `ref.watch(provider.select(...))` dan minim penggunaan konstruktor `const`, sehingga Flutter runtime terpaksa menginstansiasi ulang seluruh elemen tree.

### Masalah 2: Redundant Network Requests & Ketiadaan Strategi Caching
- **Lokasi Kode:** `lib/features/announcements/data/repositories/announcement_repository_impl.dart` & `lib/infrastructures/api_client.dart`
- **Temuan DevTools:**
  - Tab *Network* merekam setiap perpindahan navigasi ke detail pengumuman selalu memicu HTTP GET request baru ke endpoint `/announcements/:id`.
  - Tidak ada mekanisme *caching* lokal maupun *stale-while-revalidate*. Ketika perangkat berada pada jaringan lambat atau terputus (offline), aplikasi langsung mengalami kegagalan (*NetworkFailure*) tanpa menampilkan data historis yang sudah pernah diunduh.
  - Klien HTTP `Dio` belum memiliki konfigurasi timeout yang ketat dan belum mendukung kompresi payload `gzip/deflate` secara eksplisit.

### Masalah 3: Rendering & Decoding Gambar Resolusi Penuh (*Unbounded Raster Memory*)
- **Lokasi Kode:** `lib/features/announcements/presentation/pages/announcement_page.dart`
- **Temuan DevTools:**
  - Pada tab *Raster Thread*, frame merah terpanjang dipicu oleh event `Image decode` dan `Rasterizer::Draw`.
  - Gambar banner pengumuman diunduh dan didekode pada dimensi aslinya tanpa batasan `memCacheWidth` dan `memCacheHeight`, membebani GPU saat komposisi layer.

### Masalah 4: Repainting Menyeluruh pada ListView Tanpa Isolasi Layer Grafis
- **Lokasi Kode:** `lib/features/notes/presentation/pages/notes_page.dart`
- **Temuan DevTools:**
  - Pada screenshot `before-profile.png` dan `before-profile2.png`, frame 5, 12, dan 158 menunjukkan lonjakan waktu render yang tajam (> 27 ms).
  - Setiap `ListTile` tidak dibungkus oleh `RepaintBoundary`. Akibatnya, pergeseran posisi scroll atau efek ripple pada satu baris memaksa Raster Thread menggambar ulang seluruh viewport daftar catatan.

### Masalah 5: Tertahannya Objek UI di Memori (*Retaining Path Overheads*)
- **Lokasi Kode:** `lib/features/notes/presentation/pages/notes_page.dart`
- **Temuan DevTools:**
  - Pada screenshot `memory-heap-before.png`, penelusuran *Shortest Retaining Path* untuk instance `ContainerNode` menunjukkan rantai penahan:
    `Isolate -> WidgetsFlutterBinding -> _GrowableList -> _List -> ScaffoldState -> StatefulElement -> ConsumerState...`
  - Ini membuktikan bahwa widget UI stateful dari halaman yang telah dikunjungi masih tertahan di memori karena ketiadaan pelepasan listener dan controller (`dispose()`) yang presisi.

---

## 4. Rencana Solusi & Rekomendasi Optimasi

1. **Menerapkan Konstruktor `const` & Ekstraksi Widget Terisolasi:**
   Memecah widget monolitik menjadi widget modular independen (`NoteItemTile`, `NotesCountBadge`, `AnnouncementBannerImage`, `AnnouncementHeader`).
2. **Isolasi Paint dengan `RepaintBoundary`:**
   Membungkus card dan item list yang dinamis dengan `RepaintBoundary` untuk memangkas *raster thread time*.
3. **Optimasi Riverpod dengan `select`:**
   Menggunakan `ref.watch(notesProvider.select(...))` agar widget hanya ter-rebuild saat properti data yang relevan berubah.
4. **Penerapan Lazy Loading & Infinite Scroll:**
   Menyematkan `ScrollController` dengan ambang batas piksel viewport untuk memuat data secara bertahap (chunk 20 item).
5. **Optimasi Gambar dengan `CachedNetworkImage` + Disk & Memory Cache Resizing:**
   Menggunakan `memCacheWidth: 600` dan `memCacheHeight: 400`, placeholder transisi cepat, dan caching disk otomatis.
6. **Strategi Jaringan Stale-While-Revalidate & Dio Optimization:**
   Mengimplementasikan fallback cache di level repository, in-memory GET caching, retry handling, dan header kompresi data.
