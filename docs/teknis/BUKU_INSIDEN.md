# BUKU INSIDEN — Langkah Cepat Saat Ada Masalah (Resto Barokah)

> **Untuk siapa:** pemilik resto (owner), admin cabang, dan pemilik platform. Ditulis **bahasa manusia**, tanpa istilah teknis.
> **Aturan penting:** kerjakan berurutan, **jangan melompati langkah**, dan **catat di Log Insiden** (bagian 12) —
> termasuk kalau masalahnya selesai sendiri. Catatan itu yang membuat kita belajar, bukan mengulang kesalahan yang sama.
>
> Rujukan aturan: `docs/KEAMANAN.md` · keputusan: `docs/DECISIONS_LOG.md` 2026-09-17.

---

## 1. Cara pakai buku ini

> **STATUS KETERSEDIAAN (2026-09-20 — temuan audit I F-08/K F-01, jangan dihapus sampai fiturnya nyata):**
> aplikasi masih **kerangka Fase 0/1** — jalur menu **Pengaturan → Perangkat & Sesi / Pegawai / Jejak Audit BELUM ADA**,
> TOTP/MFA belum dipasang (`T1-25`), jejak audit `catatan_audit` belum ada (`T1-27`), antrean offline belum ada
> (Fase 1C), dan cadangan otomatis mingguan belum dijadwalkan (`T10-10`). Bagian 2, 3, 4, 7, dan 10 di bawah
> ditulis untuk keadaan FINAL. **Jalur sementara sampai fitur itu mendarat:** jangan cari menunya — minta **agen
> sesi kerja** melakukan tindakan setara langsung di database (nonaktifkan akun pegawai, cabut/ganti PIN, tarik
> catatan aktivitas), dan catat tindakannya di Log Insiden §12 + `docs/DECISIONS_LOG.md`.

1. Cari nama masalahnya di daftar ini (atau tekan Ctrl+F dan ketik kata kuncinya).
2. Ikuti langkah 1 → 2 → 3. Setiap langkah punya hasil yang harus terlihat.
3. Kalau macet di langkah mana pun: **berhenti, jangan mengulang terus**, tulis di Log Insiden, lalu hubungi pemilik platform.
4. Setelah selesai: **ganti PIN/kata sandi yang mungkin terlihat** dan periksa laporan hari itu.

**Daftar masalah:** perangkat hilang (2) · HP pegawai hilang/TOTP (3) · akun diduga dibobol (4) · pegawai berhenti (5) · data pelanggan bocor (6) · Skenario 1: internet kedai mati (7) · Skenario 2: Supabase "tidur" / batas gratis (8) · Skenario 3: printer bermasalah / macet (9) · cadangan & pemulihan (10) · kunci rahasia bocor (11) · Skenario 4: token kedaluwarsa di tengah shift (12) · Skenario 5: salah void / pembatalan keliru (13) · Pemulihan listrik & perangkat mati mendadak (14) · Log insiden (15).

---

## 2. Perangkat hilang atau dicuri (tablet kasir, HP kasir, laptop owner)

**Status Operasional (Aktif per Fase 10 / T10-06 & T10-15):** Menu Sesi Aktif tersedia di antarmuka (**Pengaturan → Sesi Aktif**) dan didukung RPC peladen `tandai_perangkat_hilang` serta `akhiri_sesi`. Pemutusan akses instan tanpa menunggu token kedaluwarsa telah teruji 100% pada latihan pemulihan bencana (`alat/pulihkan-cadangan.sh`).

**Tanda:** perangkat tidak ada di tempatnya · ada aktivitas kasir yang tidak dikenal · kasir mengaku bukan dia.

**Langkah (target: di bawah 2 menit):**

1. **Cabut perangkatnya.** Dari perangkat lain yang masih masuk: **Pengaturan → Sesi Aktif → pilih perangkat/sesi → Tandai Hilang** (atau tombol Cabut). Tulis alasan: "hilang dicuri". Hasil: perangkat itu **langsung mati fungsi seketika** — seluruh sesi aktifnya dicabut, permintaan berikutnya dari perangkat itu ditolak, dan jejak audit tercatat kekal.
2. **Tandai "hilang"** pada perangkat yang sama (supaya namanya tetap terlihat di daftar dengan lencana merah, tidak hilang dari catatan).
3. **Ganti PIN pegawai** yang terakhir memakai perangkat itu (**Pengaturan → Kelola Pegawai → Ganti PIN**). Hasil: sesi lama tidak bisa dipakai lagi.
4. **Periksa aktivitas hari itu**: daftar pesanan, pembayaran, void, buka laci dari tab **Laporan → Peringatan**. Kalau ada yang aneh: catat di Log Insiden + simpan tangkapan layar.
5. **Laporkan polisi** bila memang dicuri (untuk keperluan asuransi/klaim); nomor seri perangkat ada di daftar Perangkat.
6. **Ganti perangkatnya** dengan yang baru → daftarkan lewat kode dari admin (lihat panduan pegawai), lalu minta persetujuan pemilik untuk pegawai yang akan memakainya.

**Yang TIDAK perlu dilakukan:** mengubah kata sandi pemilik · mematikan internet kedai · menghapus data apa pun.

---

## 3. HP pegawai hilang (dan TOTP tidak bisa dibuka)

**Status 2026-09-20:** TOTP/MFA belum dipasang (`T1-25`) — bagian ini berlaku setelah Fase 1B.

**Siapa yang bisa menolong:** HP **admin cabang** hilang → **owner pusat**. HP **owner pusat** hilang → **pemilik platform**.

**Langkah:**

1. Pegawai melapor ke atasan (sebutkan: nama, peran, kapan HP hilang, apakah HP ada kunci layar).
2. Atasan membuka **Pengaturan → Kelola Pegawai → pilih pegawai → Atur ulang kunci kedua (MFA)** → tulis alasan. Hasil: pegawai bisa masuk lagi dengan kata sandi, lalu **mendaftarkan TOTP di HP baru** saat itu juga.
3. Semua tindakan ini **tercatat** (siapa, kapan, alasan) dan pemilik menerima pemberitahuan — jadi tidak ada pengaturan ulang yang diam-diam.
4. Kalau HP yang hilang adalah milik pegawai **kasir/pelayan/dapur**: tidak perlu apa-apa — mereka tidak memakai TOTP; cukup pastikan perangkat kerja sudah dicabut bila HP itu juga dipakai kerja (bagian 2).

**Pencegahan:** daftarkan TOTP **saat penyiapan/training**, bukan saat jam sibuk; simpan cadangan kode di tempat aman milik owner (bila fitur kode pemulihan ditambahkan di Fase 10).

---

## 4. Akun diduga dibobol (ada yang bisa masuk padahal bukan pegawainya)

**Status Operasional (Aktif per Fase 9 & Fase 10 / T9-08, T10-06 & T10-15):** Penonaktifan cepat akun tersedia di **Pengaturan → Kelola Pegawai** via RPC `set_status_pengguna`, pencabutan seluruh sesi aktif via `keluar_semua_perangkat` di **Pengaturan → Sesi Aktif**, dan reset PIN via `reset_pin_pegawai`. Layar pengawasan jejak audit dan deteksi anomali tersedia di antarmuka (**Laporan → Peringatan**). Teruji 100% pada latihan pemulihan bencana (`alat/pulihkan-cadangan.sh`).

**Tanda:** ada aktivitas aneh (void/diskon di luar kebiasaan) · percobaan masuk gagal beruntun di ringkasan harian · pegawai melapor "PIN saya diminta orang lain".

**Langkah:**

1. **Nonaktifkan akunnya** (**Pengaturan → Kelola Pegawai → pilih akun → Nonaktifkan**). Hasil: akun langsung tidak bisa apa-apa, **termasuk sesi yang sedang jalan**.
2. **Cabut semua perangkat** yang biasa dipakai akun itu (**Pengaturan → Sesi Aktif → Keluar Semua Perangkat** atas nama akun tersebut).
3. **Ganti PIN/kata sandi** akun tersebut (**Pengaturan → Kelola Pegawai → Reset PIN**) **dan** akun lain yang mungkin ikut terlihat (khususnya yang menyetujui uang).
4. **Periksa jejak audit** (**Laporan → Peringatan**) untuk 7 hari terakhir: cari tindakan atas nama akun itu yang tidak dikenali; simpan tangkapan layar.
5. Kalau ada uang yang tidak sesuai: hitung, catat di Log Insiden, dan tentukan langkah (teguran/penggantian/laporan polisi).
6. **Hidupkan kembali akun** hanya setelah PIN baru + perangkat baru disetujui; kalau pelakunya pegawai itu sendiri → jangan dihidupkan (bagian 5).

---

## 5. Pegawai berhenti (daftar simak offboarding)

**Status Operasional (Aktif per Fase 10 / T10-12):** Tombol **Pegawai Berhenti** tersedia di **Pengaturan → Kelola Pegawai**. Mengeksekusi penonaktifan akun, pemusnahan PIN di basis data, pemutusan sesi aktif seketika, dan menandai shift kasir terbuka untuk ditutup atasan (`perlu_tutup_atasan`) dalam 1 transaksi atomik (`public.pegawai_berhenti`). Riwayat transaksi finansial dan nama kasir di laporan lama tetap utuh (Aturan Bisnis 11).

Kerjakan **di hari terakhir**, jangan menunda:

1. **Gunakan tombol Pegawai Berhenti**: Masuk ke **Pengaturan → Kelola Pegawai → pilih pegawai → Pegawai Berhenti**. Ketik konfirmasi 'CABUT' dan masukkan alasan offboarding.
2. **Serah terima shift kasir**: Bila pegawai tersebut memiliki shift kasir yang masih terbuka, shift otomatis ditandai `perlu_tutup_atasan`. Admin Cabang atau Owner Pusat melakukan hitung fisik uang kas di laci kasir dan menutup shift dari tab serah terima.
3. **Cabut perangkat pribadi** miliknya dari daftar Perangkat (kalau ada); perangkat kedai tetap dipakai pegawai lain.
4. **Periksa jejak audit 30 hari terakhir** untuk akun itu dari tab **Laporan → Peringatan** (void, diskon, pembatalan, laci) — kalau ada yang janggal, catat sebelum menutup.
5. **Catat di Log Insiden**: nama pegawai, tanggal berhenti, serah terima kas, dan nama atasan yang memproses.

1. **Nonaktifkan akun** (langsung mematikan sesi & akses).
2. **Cabut perangkat pribadi** miliknya dari daftar Perangkat (kalau ada); perangkat kedai tetap dipakai pegawai lain.
3. **Ganti PIN** akun itu (kalau nanti dihidupkan lagi untuk pegawai baru, PIN baru diberikan).
4. **Periksa jejak audit 30 hari terakhir** untuk akun itu (void, diskon, pembatalan, laci) — kalau ada yang janggal, catat sebelum menutup.
5. **Serahkan tugas terbuka**: tagihan yang belum dibayar, shift yang belum ditutup (kalau dia kasir → tutup manual oleh admin cabang dengan alasan "pegawai berhenti").
6. **Catat di Log Insiden**: nama, tanggal berhenti, siapa yang memproses.

---

## 6. Data pelanggan bocor (kewajiban UU PDP: lapor maksimal 3×24 jam)

**Contoh kejadian:** daftar nama + nomor HP pelanggan terkirim ke orang yang salah · ada yang bisa membuka data pelanggan tanpa izin · kunci sistem bocor.

**Langkah (jam demi jam):**

1. **Hentikan kebocoran** — cabut akses yang bocor (cabut perangkat, nonaktifkan akun, ganti kunci rahasia — bagian 11).
2. **Catat pemahaman awal** (maksimal 1 jam): data apa, berapa banyak, sejak kapan, bagaimana.
3. **Hubungi pemilik platform** — jangan mengurus sendiri.
4. **Susun pemberitahuan** memakai template di bawah (isi: data apa, kapan & bagaimana, langkah pemulihan).
5. **Kirim paling lambat 3×24 jam** sejak kejadian diketahui: ke **pelanggan yang terdampak** (email/WhatsApp) **dan** ke **lembaga pengawas** (Lembaga PDP). Simpan tanda bukti kirim.
6. **Catat semuanya** di Log Insiden + simpan tangkapan layar pemeriksaan.
7. **Perbaiki akar masalahnya** dan uji ulang aturannya (tambahkan uji agar tidak terulang).

**Template pemberitahuan (ringkas, bahasa manusia):**

> Kami memberitahukan adanya kejadian keamanan pada sistem kami di [nama resto].
> **Data yang terdampak:** [mis. nama dan nomor HP yang dipakai saat mendaftar voucher].
> **Kapan & bagaimana:** [tanggal/jam] kami mengetahui bahwa [penjelasan singkat tanpa istilah teknis].
> **Yang sudah kami lakukan:** [mis. akses ditutup, data diamankan, pemeriksaan menyeluruh].
> **Yang bisa Anda lakukan:** waspadai pesan mencurigakan yang mengatasnamakan kami; hubungi kami di [kontak] bila ada pertanyaan.
> Kami meminta maaf dan akan menjaga keamanan data Anda sebagaimana kewajiban kami.

---

## 7. Skenario 1 — Internet kedai mati (atau putus-sambung)

**Status implementasi (T10-02 s/d T10-04, T10-09):** antrean offline lokal (`antrean-offline.ts`), penyimpanan tiket cadangan (`antrean-lokal.ts`), dan kunci idempoten menyeluruh (migrasi `0080`) aktif di seluruh transaksi kasir dan dapur.

**Yang terjadi di aplikasi:**
* Aplikasi otomatis mendeteksi status putus internet dan menampilkan bilah status **"Luring"** / **"Menunggu Terkirim"**.
* Kasir tetap bisa memasukkan pesanan, memilih menu, dan mencatat transaksi ke antrean luring di peramban.
* Setiap transaksi dibubuhi **kunci idempoten** unik sehingga peladen menolak duplikat saat sinkronisasi ulang (tidak akan dobel pesanan, dobel pembayaran, atau dobel voucher).

**Langkah kasir & staf:**

1. **Lanjutkan melayani pelanggan seperti biasa.** Transaksi otomatis masuk ke antrean lokal peramban.
2. **Periksa status jujur:** Pastikan pesanan berstatus **"Menunggu terkirim"** (aplikasi dilarang mengaku transaksi sudah sukses tersimpan di awan sebelum internet tersambung).
3. **JANGAN menghapus data riwayat/cache peramban** selama internet mati agar antrean lokal tidak terhapus.
4. **Saat internet kembali terhubung:** Sistem otomatis mengirimkan seluruh antrean transaksi tertunda secara berurutan. Periksa indikator antrean hingga berubah hijau ("Daring / semua terkirim").
5. **Mode darurat tanpa internet seharian penuh:** Catat pesanan di nota kertas bernomor fisik berurutan. Setelah sambungan pulih, masukkan transaksi tersebut ke aplikasi kasir berurutan.

---

## 8. Skenario 2 — Supabase "tidur" atau peladen mati / batas gratis tercapai

**Tanda:** Aplikasi menampilkan pesan galat "Antrean tidak bisa diambil dari peladen" atau data tidak dapat termuat sama sekali.

**Pencegahan otomatis:** Denyut harian otomatis via `pg_cron` (`denyut_harian()` pada migrasi `0082`) aktif mencegah Supabase tertidur karena tidak ada aktivitas selama 7 hari.

**Langkah penanganan:**

1. **Periksa status panel Supabase:** Pemilik platform membuka panel Supabase (dashboard). Jika proyek tertulis *"Paused"*, tekan tombol **Restore / Unpause**. Data transaksi dan akun dijamin tidak hilang; sistem hanya tidur karena jeda operasional.
2. **Bila batas kuota tercapai (500 MB data / 1 GB foto / 5 GB bandwidth):**
   * Periksa rincian penggunaan kuota di menu Pengaturan Platform.
   * Bila kuota data mendekati 90%, diskusikan dengan pemilik resto untuk melakukan pembersihan log sementara via `bersihkan_data_sementara()` (tugas T10-08) atau melakukan *upgrade* paket ke Supabase Pro ($25/bulan).
3. **Ketahanan di kedai saat peladen belum aktif:** Layar kasir dan layar dapur (KDS) tetap menampilkan draf dan antrean pesanan terakhir dari cadangan memori perangkat lokal (`antrean-lokal.ts`). Kedai tidak mengalami kelumpuhan total.

---

## 9. Skenario 3 — Printer bermasalah / macet / habis kertas

**Tanda:** Struk kasir atau tiket pesanan dapur tidak keluar, lampu printer berkedip merah, atau kertas macet di pisau pemotong.

**Prinsip keamanan finansial:** Kegagalan mencetak struk fisik **TIDAK PERNAH membatalkan atau menghilangkan transaksi keuangan di sistem**. Uang dan pesanan sudah sah tercatat di database peladen.

**Langkah kasir:**

1. **JANGAN menekan tombol cetak berkali-kali!** Hal ini mencegah kertas tercetak dobel ketika printer terhubung kembali.
2. **Periksa fisik printer:**
   * Pastikan kabel daya terpasang kuat dan adaptor menyala.
   * Periksa gulungan kertas: pastikan kertas tidak habis, tidak terbalik posisinya, dan penutup tertutup rapat hingga berbunyi klik.
   * Periksa kabel USB atau sambungan Bluetooth ke perangkat kasir.
3. **Gunakan jalur cadangan (Digital & KDS):**
   * **Stasiun Dapur/Bar:** Tidak membutuhkan kertas cetak karena layar KDS Dapur sudah menampilkan tiket pesanan secara realtime.
   * **Pelanggan:** Tampilkan bukti pembayaran langsung di layar kasir, atau gunakan fitur bagikan struk digital via QR Code / pesan (fitur Struk Digital T5-09).
4. **Cetak Ulang Struk:** Setelah printer diperbaiki atau kertas diganti, kasir dapat mencetak ulang dari menu **Daftar Transaksi → Pilih Transaksi → Cetak Ulang**. Struk hasil cetak ulang otomatis memuat cap **"SALINAN"** resmi demi mencegah penyalahgunaan nota ganda.

---

## 10. Cadangan & pemulihan (latihan sebelum pilot)

**Status Operasional (Aktif per Fase 10 / T10-10 & T10-15):** Cadangan otomatis mingguan terjadwal di GitHub Actions (`.github/workflows/cadangan.yml`), skrip pembuatan dump & enkripsi AES-256 (`alat/cadangan.sh`), serta skrip eksekutif latihan pemulihan & dril insiden (`alat/pulihkan-cadangan.sh`). Panduan SOP 7 tahap dan laporan resmi latihan pemulihan tersedia di `docs/teknis/PEMULIHAN.md`.

1. Cadangan otomatis berjalan mingguan (dump terenkripsi AES-256); pemilik mengunduh salinannya **sebulan sekali** ke komputer/Drive miliknya.
2. **Latihan pemulihan** (dilakukan secara berkala sebelum pilot): pulihkan cadangan ke basis data bersih → bandingkan jumlah baris tabel inti → jalankan simulasi dril 4 insiden nyata via perintah `bash alat/pulihkan-cadangan.sh`. Hasil latihan tercatat resmi di `docs/teknis/PEMULIHAN.md`.
3. Kalau ada data yang tidak sengaja terhapus/berubah: **jangan** menambal dengan mengubah data lama — catat sebagai koreksi baru (aplikasi memang dirancang begitu untuk data keuangan), dan kalau perlu pulihkan dari cadangan **ke lingkungan uji dulu**.

---

## 11. Kunci rahasia bocor (kunci sistem terlihat di tempat umum/dikirim ke orang)

1. Pemilik platform segera **mengganti kunci** di panel Supabase/Cloudflare (panduan langkah ada di `docs/ops/`).
2. Perbarui kunci di tempat yang seharusnya (panel rahasia), **bukan** di kode.
3. Periksa jejak audit untuk aktivitas mencurigakan sejak kunci itu mungkin terlihat.
4. Panggil ulang (deploy) aplikasi supaya memakai kunci baru.
5. Catat di Log Insiden: kunci apa, kapan terganti, siapa yang tahu, apa yang diperiksa.

---

## 12. Skenario 4 — Token login kedaluwarsa di tengah shift

**Tanda:** Kasir sedang bekerja atau perangkat ditinggal sejenak, lalu muncul dialog permintaan masuk ulang atau verifikasi PIN karena masa berlaku token akses habis (token akses 15 menit).

**Prinsip keamanan & perlindungan:**
* Kedaluwarsa token akses adalah mekanisme keamanan standar (TECH_SPEC §8).
* Sistem melakukan penyegaran token (*refresh token*) otomatis di latar belakang.
* Bila perangkat terkunci otomatis karena tidak ada sentuhan selama 15 menit, **DRAF PESANAN DAN SHIFT KASIR TIDAK BOLEH HILANG**.

**Langkah kasir:**

1. **Jangan panik atau memuat ulang paksa (refresh) halaman:** Draf keranjang yang sedang disusun tersimpan aman di penyimpanan lokal perangkat (`simpanDrafKasir`).
2. **Masukkan PIN kasir 6 digit:** Kasir yang sedang bertugas cukup memasukkan PIN 6 digit miliknya untuk membuka kunci layar.
3. **Periksa kelanjutan shift:** Shift kasir yang sedang berjalan tetap aktif dan tidak tertutup. Saldo modal awal dan pembukuan kas tidak terpecah menjadi shift baru.
4. **Lanjutkan transaksi:** Keranjang belanja dan rincian pesanan tetap berada di posisi semula siap diproses ke dapur atau kasir pembayaran.

---

## 13. Skenario 5 — Salah void / pembatalan transaksi keliru

**Tanda:** Kasir atau pelayan tidak sengaja membatalkan (void) item pesanan atau seluruh tiket meja padahal pesanan tersebut sudah dimasak atau tamu tetap menghendakinya.

**Aturan database (TECH_SPEC §4 & §9):**
* Tabel `catatan_audit` dan tabel `pembatalan` bersifat **hanya-tambah (append-only)**.
* Riwayat void yang sudah disetujui **TIDAK DAPAT DIHAPUS** dari database oleh siapa pun, termasuk admin atau pemilik platform (Aturan Bisnis 8). Ini adalah fondasi anti-kecurangan kasir.

**Langkah penanganan:**

1. **Pahami bahwa catatan void tidak bisa dihapus diam-diam:** Jangan mencoba mengubah atau memanipulasi riwayat pembatalan.
2. **Untuk item makanan yang tetap dimasak/disajikan:**
   * Kasir membuat pesanan baru untuk item yang keliru dibatalkan.
   * Beri catatan khusus pada item baru: *"Koreksi salah void tiket #XXX"*.
   * Kirim pesanan ke dapur dengan memberitahukan staf dapur agar tidak memasak dua porsi (karena makanan sudah disiapkan dari tiket sebelumnya).
3. **Bila terjadi selisih kas pada akhir shift:**
   * Jika pembatalan keliru tersebut menyebabkan perbedaan antara uang fisik di laci dan pencatatan komputer, kasir wajib mencatat alasan selisih secara jujur pada layar **Tutup Shift & Rekonsiliasi Kas** (`TutupKas.tsx`): *"Selisih RpXX karena salah void tiket #YYY (sudah dikonfirmasi atasan)"*.
   * Catat juga pada Log Insiden (§15) di bawah untuk mempermudah verifikasi saat pemilik memeriksa laporan bulanan.

---

## 14. Pemulihan Listrik & Perangkat Mati Mendadak (Kasir & Dapur)

> Panduan cepat 1 halaman khusus staf lapangan tersedia di `docs/ops/PEMULIHAN_LISTRIK.md`.

**Tujuan:** Memastikan kedai dapat langsung melanjutkan penjualan setelah listrik padam tanpa kehilangan pesanan yang sedang berjalan, tanpa merusak pembukuan shift kas, dan tanpa membuat data peladen tertimpa data lokal usang.

### A. Apa yang Terjadi Saat Listrik Mati Mendadak?
1. **Draf Keranjang Kasir:** Disimpan otomatis di memori perangkat lokal (`resto.kasir.draf.{cabangId}`).
2. **Shift Kasir Aktif:** Status shift yang sedang berjalan tetap tercatat di peladen (`sesi_perangkat` & `shift_kas`). Saldo modal awal tidak hilang.
3. **Pesanan yang Sudah Dikirim ke Dapur:** Sudah tercatat di database peladen dan tersimpan di cadangan tampilan KDS (`resto.antrean-terakhir.dapur`).
4. **Tagihan Terbuka (Open Bill):** Tersimpan di peladen dan dicadangkan di penyimpanan lokal (`resto.kasir.tagihan-terbuka.{cabangId}`).

### B. Prosedur Pemulihan Saat Listrik Menyala:
1. **Nyalakan kembali modem internet dan komputer/tablet kasir.**
2. **Buka aplikasi Resto Barokah dan masuk menggunakan PIN kasir.**
3. **Kelanjutan Shift Otomatis:** Sistem mendeteksi bahwa shift kasir pada hari tersebut masih aktif. Layar kasir **TIDAK MEMAKSA kasir membuka shift baru**, sehingga saldo modal awal tetap bersambung.
4. **Pemulihan Draf Keranjang:** Layar kasir otomatis menampilkan banner pemberitahuan:
   > ⚡ **Pesanan dipulihkan:** Draf transaksi sebelum perangkat terhenti dimuat kembali (X item).
   * Kasir dapat menekan **"Lanjutkan"** untuk menyelesaikan pesanan, atau **"Buang Draf"** jika pesanan tersebut dibatalkan pelanggan.
5. **Layar Dapur (KDS):** Memuat kembali antrean tiket terakhir secara instan. Begitu koneksi peladen terhubung, status item langsung disinkronkan secara mulus.

### C. Aturan Rekonsiliasi Peladen Selalu Menang (Server-Wins)
* **Mitigasi risiko data lokal usang:** Bila terjadi benturan data antara cadangan lokal perangkat dengan peladen (misal status pesanan di peladen sudah berubah menjadi *'dimasak'* atau *'lunas'* oleh perangkat lain), **versi peladen selalu menang (server-wins)**.
* Fungsi `rekonsiliasiEntitas()` dan `rekonsiliasiDaftarPesanan()` di `aplikasi/src/lib/antrean-lokal.ts` menjamin data lokal tidak pernah menimpa catatan yang lebih mutakhir di peladen.
* Bila kasir membuka kembali tagihan yang statusnya berbeda, sistem memberikan notifikasi yang jujur kepada kasir.

---

## 15. Log Insiden (selalu diisi)

| # | Tanggal & jam | Kejadian | Langkah yang dilakukan | Hasil | Uang/data terdampak? | Ditangani oleh | Sudah diperbaiki? |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |

**Aturan pengisian:** (a) tulis juga kejadian yang selesai sendiri; (b) **jangan** menulis PIN/kata sandi/kunci di kolom mana pun; (c) setiap insiden uang ≥ Rp 100.000 wajib dibaca pemilik dalam 1×24 jam; (d) setiap insiden data pelanggan wajib masuk hitungan 3×24 jam UU PDP (bagian 6).
