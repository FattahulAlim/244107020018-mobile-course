# Week 2

## Tujuan Pembelajaran
1. Menjelaskan prinsip declarative UI dan hubungan antara widget, konfigurasi, serta state.
2. Menggunakan StatelessWidget, StatefulWidget, Container, Row, Column, dan Expanded.
3. Membedakan komponen Material 3 dan Cupertino untuk kebutuhan platform yang berbeda.
4. Membangun layout responsif untuk ukuran layar mobile dan tablet.
5. Menerapkan theme, dark mode, styling, dan aksesibilitas dasar.

## Fitur Utama
1. Header Profil Mahasiswa: Menampilkan identitas diri meliputi nama, NIM dan kelas menggunakan container + row + column
2. Kartu informasi Akademik: 4 Kartu yang menampilkan ringkasan data mahasiswa (Assignments, Attendance, Portofolio, Current week)
3. Layout Responsif: Tata letak yang otomatis menyesuaikan lebar layar dengan 1 kolom pada layar sempit dan 2 kolom pada layar lebar. Tata letak menggunakan kombinasi LayoutBuilder dan Gridview.count dengan breakpoint 700px
4. Tema terang dan gelap: Pengguna bisa mengganti tema secara langsung lewat toggle CupertinoSwitch, dengan warna latar dan warna teks yang menyesuaikan otomatis supaya tetap kontras dan terbaca di kedua tema
5. Menambahkan label informasi atau semantics: elemen penting seperti switch tema dan kartu informasi dilengkapi label semantics yang bermakna

## Stack teknologi
- Bahasa Pemrograman: Dart
- Framework Pengembangan Aplikasi: Flutter
- Lingkungan Pengembangan (IDE): Visual Studio Code
- Target Platform / Lingkungan Uji Coba: Web Browser
- Sistem Kontrol Versi: Git (untuk penyimpanan repository pribadi)

## Cara Menjalankan
1. Persiapan Lingkungan: Pastikan laptop Anda sudah terinstal Git, Flutter SDK (dengan path yang ditambahkan ke Environment Variables), dan browser Chrome atau Android Studio sebagai target perangkat. Selain itu, siapkan juga IDE Visual Studio Code yang telah dipasangi ekstensi Flutter dan Dart.
2. Buka Terminal, PowerShell, atau Command Prompt pada direkotori yang anda inginkan dan jalankan perintah di bawah:
``` 
https://github.com/FattahulAlim/244107020018-mobile-course.git
```
3. Masuk ke direktori repository yang baru saja diunduh:
```
cd 244107020018-mobile-course/02-week-2-declarative-ui-responsive-design
```
4. Arahkan secara spesifik ke direktori tempat proyek Flutter berada. Berdasarkan struktur path, masuk ke folder aplikasi contoh:
```
cd praktikum2/responsive_dashboard
```
5. Unduh semua dependensi atau library yang dibutuhkan oleh aplikasi:
```
flutter pub get
```
6. Buka folder proyek (responsive_dashboard) di VS Code.
7. Buka terminal bawaan VS Code (Ctrl + `).
8. Jalankan perintah kompilasi:
```
flutter run
```
9. Jika terdapat lebih dari satu perangkat yang terdeteksi, terminal akan meminta Anda memilih target (contoh: [1] Windows, [2] Chrome, [3] Edge).
10. Ketik angka yang merujuk pada browser Chrome
11. Tunggu proses build selesai. Halaman profil akan otomatis terbuka di browser anda

## Hasil yang dicapai
### Memahami Prinsip Declarative UI
Declrative ui merupakan antarmuka aplikasi yang dibangung dengan cara mendeskripsikan seperti apa tampilan UI yang diinginkan berdasarkan kondisi atau state aplikasi saat ini, sehingga developer tidak perlu mengatur setiap perubahan secara manual. 
- Widget: Widget merupakan komponen dasar untuk membangun antarmuka flutter seperti text, button, container, row, dan column. Widget berfungsi untuk mendeskripsikan struktur dan tampilan UI
- Konfigurasi: Widget memiliki konfigurasi yang menentukan bagaimana widget tersebut ditampilkan dan berperilaku. contohnya TextStyle milik widget Text
- State: State merupakan data atau kondisi yang dapat berubah selama aplikasi berjalan dan memengaruhi tampilan UI, contohnya penggunaan tema gelap dan terang

### Mempelajari serta menerapkan Extended dan mainAxisSize

Expanded merupakan sebuah widget di Flutter yang digunakan untuk membuat 
widget anak mengisi sisa ruang kosong pada Row atau Column, sehingga 
dapat membantu mencegah overflow pada kasus-kasus umum. Sementara mainAxisSize merupakan sebuah properti yang digunakan untuk menentukan seberapa besar ruang yang akan diambil oleh bari atau kolom pada sumbu utamanya

#### Percobaan pada praktikum layout sederhana


##### Percobaan Expanded
| Tampilan Normal | Nama panjang tanpa expanded | Nama panjang + expanded|
|:---:|:---:|:---:|
|     ![Tampilan Normal](./screenshots/prak1-tampilan_normal.jpeg)   |  ![Tampilan Normal](./screenshots/prak1-peringatan_overflow.jpeg) | ![Nama Panjang + Expanded](./screenshots/prak1-dengan_expanded.jpeg)|

##### Percobaan mainAxisSize
| mainAxisSize.min | mainAxisSize.max / ukuran default|
|:---:|:---:|
|     ![mainAxisSize.min](./screenshots/prak1-tampilan_normal.jpeg)   |  ![mainAxisSize.max](./screenshots/prak1-mainaxissize_max.jpeg) | 

##### Menambahkan satu kolom pada card
![menambah satu kolom baru](./screenshots/prak1-tambah_absen.jpeg)

### Praktikum 2 - Implementasi widget dan perbandingan material 3 dengan cupertino pada fitur dark mode

| Tampilan light mode | Tampilan Dark Mode|
|:---:|:---:|
|     ![light mode](./screenshots/prak2-light_mode.jpeg)   |  ![dark mode](./screenshots/prak2-dark_mode.jpeg) | 

Pada tampilan layout yang diatas, digunakan 2 tombol sekaligus untuk mempermudah perbandingan. Tombol di kiri merupakan cupertino sementara tombol di kanan merupakan material 3, Cupertino sendiri merupakan desain milik Apple / ios semenyata material 3 milik google sehingga bisa digunakan di android dan cross-platform. Secara visual terlihat berbeda di pada pilihan warna serta garis border nya, yang paling mencolok terjadi pada dark mode nya. Cupertino akan berwarna hijau sementara material 3 akan menyesuaikan dengan warna yang dipilih pada properti widget yang pada kasus kali ini yaitu warna indigo. Cupertion sendiri warnanya sudah fix mengikuti tampilan ios sehingga meskipun sudah diatur pada kode program indigo warna cupertino akan tetap hijau di dark mode nya

#### Tampilan Desain Masing Masing

##### Tampilan desain Cupertino
| Tampilan light mode | Tampilan Dark Mode|
|:---:|:---:|
|     ![cupertino light mode](./screenshots/prak2-cup_light.jpeg)   |  ![cupertino dark mode](./screenshots/prak2-cup_dark.jpeg) |

##### Tampilan desain Material 3
| Tampilan light mode | Tampilan Dark Mode|
|:---:|:---:|
|     ![material3 light mode](./screenshots/prak2-cup_light.jpeg)   |  ![material3 dark mode](./screenshots/prak2_mat3-dark.jpeg) |


### Implementasi Aksesibilitas Dasar

semantics merupakan widget flutter yang berfungsi untuk menambahkan informasi tambahan ke sebuah widget yang dipakai khusus oleh screen reader untuk membacakan isi layar ke pengguna yang tidak bisa atau kesulitan melihat. Contoh semantic yang digunakan ada pada tombol toggle tema dan informasi kartu performa akademik:

| Semantic Toggle | Semantic informasi kartu| Cek aksesibilitas|
|:---:|:---:|:---:|
|     ![Semantic Toggle](./screenshots/semantics-toggle-tema.png)   |  ![Semantic informasi kartu](./screenshots/semantics-toggle-tema.png) | ![Semantic informasi kartu](./screenshots/cek-aksesibilitas.png) |

## AI Prompt Challenge

### "Bandingkan dua tata letak dashboard akademik untuk Flutter: versi GridView dan versi LayoutBuilder + Column. Jelaskan trade-off responsif dan aksesibilitasnya.

Jawaban AI
![jawaban AI 1 part 1](./screenshots/jawabanai-1_pt1.png)
![jawaban AI 1 part 2](./screenshots/jawabanai-1_pt2.png)
![jawaban AI 1 part 3](./screenshots/jawabanai-1_pt3.png)
![jawaban AI 1 part 4](./screenshots/jawabanai-1_pt4.png)

Rekomendasi, Implementasi dan Alasan dari AI
![Rekomendasi dan Alasan part 1](./screenshots/penerapan-pt1.png)
![Rekomendasi dan Alasan part 2](./screenshots/penerapan-pt2.png)
![Penerapan portrait light mode](./screenshots/penerapan-portrait.png)
![Penerapan portrait dark mode](./screenshots/penerapan-portrait-dk.png)
![Penerapan landscape light mode](./screenshots/penerapan-landscape.png)
![Penerapan landscape dark mode](./screenshots/penerapan-landscape-dk.png)

Dapat dilihat perbedaan tampilan yang direkomendasikan oleh ai hanya ada pada informasi identitas diri yang diletakkan sejajar dengan card pada mode portrait di row yang sama

### "Jelaskan kapan penggunaan Expanded justru menyebabkan overflow di dalam Row, beri contoh kode yang gagal dan perbaikannya"

Jawaban AI
![jawaban AI 2 part 1](./screenshots/jawabanai-2_pt1.png)
![jawaban AI 2 part 2](./screenshots/jawabanai-2_pt2.png)
![jawaban AI 2 part 3](./screenshots/jawabanai-2_pt3.png)
![jawaban AI 2 part 4](./screenshots/jawabanai-2_pt4.png)

### "Periksa kembali rekomendasi layout di atas: apakah tetap responsif di bawah 600px, apakah mengurangi aksesibilitas, dan apakah ada widget yang tidak tersedia di Flutter stabil saat ini?"

Jawaban AI
![jawaban AI 3 part 1](./screenshots/jawabanai-3-pt1.png)
![jawaban AI 3 part 2](./screenshots/jawabanai-3-pt2.png)

## Refactoring challenge

### 1. Ekstrak kartu informasi menjadi widget reusable (misal InfoCard) yang menerima title dan value, sehingga tidak ada duplikasi widget.

Mengubah nama DashboardCard menjadi InfoCard
![Refactoring Challenge 1](./screenshots/refactoring-1.png)

### 2. Ganti warna dan ukuran yang di-hardcode dengan Theme.of(context) agar mengikuti tema terang/gelap secara otomatis.

![Refactoring Challenge 2](./screenshots/refactoring-2.png)

### 3. Pindahkan breakpoint ke satu konstanta bernama (misal const kWideBreakpoint = 700;) agar hanya didefinisikan satu kali.

Memindahkan kWideBreakpoint menjadi konstanta sehingga hanya didefinisikan satu kali dan bisa digunakan ulang tanpa perlu hardcode
![Refactoring Challenge 3](./screenshots/refactoring-3.png)

Penggunaan kWideBreakpoint
![Refactoring Challenge 3](./screenshots/refactoring-3-pt2.png)


### 4. Jalankan flutter analyze dan pastikan tidak ada error maupun warning baru.

![Refactoring Challenge 4](./screenshots/refactoring-4.png)

## Testing dasar

Tambahkan widget test di folder test/ untuk memverifikasi perilaku responsif. Override ukuran layar menggunakan tester.view:
![testing dasar](./screenshots/testing-dasar.png)

Menjalankan flutter test
![notif flutter test](./screenshots/error-test.png)
Terjadi Error akibat element yang akan di test terdiri dari 4 element, sementara fungsi getSize() sendiri mewajibkan hanya ada tepat satu widget yang ditemukan untuk diukur, karena element yang ada lebih dari satu itulah yang membuat error "too many element" muncul.

Solusi: Menambahkan first di akhir kode sehingga element pertama saja yang diambil bukan semua element
![testing fix](./screenshots/testing-dasar-fix.png)

Menjalankan flutter test:
![flutter success](./screenshots/testing-fix.png)

## Refleksi 

### 1. Apa perbedaan cara berpikir imperative dan declarative saat membangun UI?
Imperatice: Menulis tiap baris kode per langkah tentang bagaimana cara mengubah tampilannya sehingga sesuai dengan yang diinginkan atau dengan kata lain menulis dan mengatur setiap perubahan state ke UI secara Manual

Declarative: Mendeskripsikan seperti apa tampilan UI seharusnya berdasarkan state tertentu sehingga UI bisa memiliki tampilan yang dinamis sesuai dengan state yang dialami

### 2. Kapan Expanded membantu dan kapan menyebabkan error

Expanded membantu ketika king sebuah widget mengisi sisa ruang kosong secara prorporsional di dalam row atau column. Namun expanded dapat menyebabkan error ketika digunakan di luar row/column/flex sehingga tidak punya batasan ukuran yang jelas dan dapat menyebabkan error unbounded height/width 

### 3. Bagaimana breakpoint dan theme memengaruhi pengalaman pengguna?

Breakpoint membuat layout menyesuaikan diri di berbagai ukuran layar (HP, tablet, desktop), sehingga tampilan tetap rapi dan mudah digunakan di semua device, tidak terpotong atau berantakan.

Theme memberikan konsistensi visual (warna, font, spacing) di seluruh aplikasi, membuat aplikasi terasa lebih profesional, mudah dikenali, dan juga memudahkan penerapan dark mode/light mode sesuai preferensi pengguna.

### 4. Apa yang Anda verifikasi dari rekomendasi AI setelah tugas inti selesai?

- Mengecek apakah kode benar-benar berjalan tanpa error saat dijalankan langsung.
- Menguji ulang di berbagai kondisi untuk memastikan tidak ada bug yang terlewat
- Membandingkan dengan dokumentasi resmi untuk memastikan penjelasan AI sudah benar.









