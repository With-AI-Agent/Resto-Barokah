# BUKU INSIDEN — Langkah Cepat Saat Ada Masalah (Resto Barokah)

> **Untuk siapa:** pemilik resto (owner), admin cabang, dan pemilik platform. Ditulis **bahasa manusia**, tanpa istilah teknis.
> **Aturan penting:** kerjakan berurutan, **jangan melompati langkah**, dan **catat di Log Insiden** (bagian 12) —
> termasuk kalau masalahnya selesai sendiri. Catatan itu yang membuat kita belajar, bukan mengulang kesalahan yang sama.
>
> Rujukan aturan: `docs/KEAMANAN.md` · keputusan: `docs/DECISIONS_LOG.md` 2026-09-17.

---

## 1. Cara pakai buku ini

1. Cari nama masalahnya di daftar ini (atau tekan Ctrl+F dan ketik kata kuncinya).
2. Ikuti langkah 1 → 2 → 3. Setiap langkah punya hasil yang harus terlihat.
3. Kalau macet di langkah mana pun: **berhenti, jangan mengulang terus**, tulis di Log Insiden, lalu hubungi pemilik platform.
4. Setelah selesai: **ganti PIN/kata sandi yang mungkin terlihat** dan periksa laporan hari itu.

**Daftar masalah:** perangkat hilang (2) · HP pegawai hilang/TOTP (3) · akun diduga dibobol (4) · pegawai berhenti (5) · data pelanggan bocor (6) · internet kedai mati (7) · Supabase "tidur" / batas gratis (8) · printer bermasalah (9) · cadangan & pemulihan (10) · kunci rahasia bocor (11).

---

## 2. Perangkat hilang atau dicuri (tablet kasir, HP kasir, laptop owner)

**Tanda:** perangkat tidak ada di tempatnya · ada aktivitas kasir yang tidak dikenal · kasir mengaku bukan dia.

**Langkah (target: di bawah 2 menit):**

1. **Cabut perangkatnya.** Dari perangkat lain yang masih masuk: **Pengaturan → Perangkat & Sesi → pilih perangkatnya → Cabut** (tulis alasan: "hilang"). Hasil: perangkat itu **langsung mati fungsi** — permintaan berikutnya dari perangkat itu ditolak, tidak menunggu apa-apa.
2. **Tandai "hilang"** pada perangkat yang sama (supaya namanya tetap terlihat di daftar, tidak hilang dari catatan).
3. **Ganti PIN pegawai** yang terakhir memakai perangkat itu (Pengaturan → Pegawai → Ganti PIN). Hasil: sesi lama tidak bisa dipakai lagi.
4. **Periksa aktivitas hari itu**: daftar pesanan, pembayaran, void, buka laci. Kalau ada yang aneh: catat di Log Insiden + simpan tangkapan layar.
5. **Laporkan polisi** bila memang dicuri (untuk keperluan asuransi/klaim); nomor seri perangkat ada di daftar Perangkat.
6. **Ganti perangkatnya** dengan yang baru → daftarkan lewat kode dari admin (lihat panduan pegawai), lalu minta persetujuan pemilik untuk pegawai yang akan memakainya.

**Yang TIDAK perlu dilakukan:** mengubah kata sandi pemilik · mematikan internet kedai · menghapus data apa pun.

---

## 3. HP pegawai hilang (dan TOTP tidak bisa dibuka)

**Siapa yang bisa menolong:** HP **admin cabang** hilang → **owner pusat**. HP **owner pusat** hilang → **pemilik platform**.

**Langkah:**

1. Pegawai melapor ke atasan (sebutkan: nama, peran, kapan HP hilang, apakah HP ada kunci layar).
2. Atasan membuka **Pengaturan → Pegawai → pilih pegawai → Atur ulang kunci kedua (MFA)** → tulis alasan. Hasil: pegawai bisa masuk lagi dengan kata sandi, lalu **mendaftarkan TOTP di HP baru** saat itu juga.
3. Semua tindakan ini **tercatat** (siapa, kapan, alasan) dan pemilik menerima pemberitahuan — jadi tidak ada pengaturan ulang yang diam-diam.
4. Kalau HP yang hilang adalah milik pegawai **kasir/pelayan/dapur**: tidak perlu apa-apa — mereka tidak memakai TOTP; cukup pastikan perangkat kerja sudah dicabut bila HP itu juga dipakai kerja (bagian 2).

**Pencegahan:** daftarkan TOTP **saat penyiapan/training**, bukan saat jam sibuk; simpan cadangan kode di tempat aman milik owner (bila fitur kode pemulihan ditambahkan di Fase 10).

---

## 4. Akun diduga dibobol (ada yang bisa masuk padahal bukan pegawainya)

**Tanda:** ada aktivitas aneh (void/diskon di luar kebiasaan) · percobaan masuk gagal beruntun di ringkasan harian · pegawai melapor "PIN saya minta orang lain".

**Langkah:**

1. **Nonaktifkan akunnya** (Pengaturan → Pegawai → Nonaktifkan). Hasil: akun langsung tidak bisa apa-apa, **termasuk sesi yang sedang jalan**.
2. **Cabut semua perangkat** yang biasa dipakai akun itu (bagian 2 langkah 1, pilih "semua/akun ini").
3. **Ganti PIN/kata sandi** akun tersebut **dan** akun lain yang mungkin ikut terlihat (khususnya yang menyetujui uang).
4. **Periksa jejak audit** (Pengaturan → Jejak Audit) untuk 7 hari terakhir: cari tindakan atas nama akun itu yang tidak dikenali; simpan tangkapan layar.
5. Kalau ada uang yang tidak sesuai: hitung, catat di Log Insiden, dan tentukan langkah (teguran/penggantian/laporan polisi).
6. **Hidupkan kembali akun** hanya setelah PIN baru + perangkat baru disetujui; kalau pelakunya pegawai itu sendiri → jangan dihidupkan (bagian 5).

---

## 5. Pegawai berhenti (daftar simak offboarding)

Kerjakan **di hari terakhir**, jangan menunda:

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

## 7. Internet kedai mati (atau mati sebentar)

**Yang terjadi di aplikasi:** pesanan/kasir tetap bisa dicatat, tetapi berkas dikirim setelah internet kembali; **kalau perangkat dalam keadaan terkunci, membuka lagi butuh internet**.

**Langkah:**

1. Pastikan aplikasi **tidak** menampilkan "berhasil" untuk pesanan yang masih menunggu terkirim — statusnya "menunggu terkirim".
2. Lanjutkan melayani pelanggan **seperti biasa** (pesanan masuk antrean lokal, tidak dobel karena ada kunci idempoten).
3. Kalau internet mati lebih dari 15 menit: **jangan mengunci aplikasi atas kemauan sendiri** (biarkan sesi tetap terbuka supaya antrean bisa terkirim saat internet kembali).
4. Setelah internet kembali: **periksa antrean kosong** di layar Kasir → "Menunggu terkirim". Kalau ada yang gagal, catat nomor pesanannya.
5. Kalau perangkat sudah terlanjur terkunci: tunggu internet, buka dengan PIN, lalu periksa antrean.
6. **Mode darurat tanpa internet sama sekali (mis. mati seharian):** catat pesanan di kertas kecil bernomor (nomor sementara), lalu masukkan ke aplikasi setelah internet kembali; **jangan lupa menandai** pesanan yang sudah dibayar supaya tidak dobel. Catat di Log Insiden.

---

## 8. Supabase "tidur" atau batas gratis tercapai

**Tanda:** aplikasi tidak bisa memuat data sama sekali · email dari Supabase tentang batas pemakaian.

**Langkah:**

1. Buka panel Supabase (akun pemilik platform) → kalau proyek tertulis "paused", tekan **Restore/Unpause**. Data tidak hilang; proyek tidur karena 7 hari tanpa aktivitas.
2. Setelah hidup: cek aplikasi masih normal (buka 1 layar kasir).
3. Kalau yang muncul adalah **peringatan batas pemakaian** (data/pengiriman): jangan panik — ukur dulu (bagian ini mencatat angkanya), lalu putuskan bersama pemilik: rapikan foto/laporan, atau naik kelas (berbayar) — **keputusan pemilik**, karena menyentuh biaya.
4. Supaya tidak tidur lagi: buka panel Supabase **sekali setiap beberapa hari** sampai "denyut harian" otomatis (pg_cron) terpasang — pemasangannya bagian dari penyiapan Supabase (tugas **T0-08**). Catatan jujur: sebelum itu terpasang, tidak ada alat bantu khusus; jangan mengandalkan berkas yang belum ada.

---

## 9. Printer bermasalah (struk/tiket tidak keluar)

1. **Jangan ulangi tekan cetak berkali-kali** (bisa keluar dobel saat printer hidup) — periksa dulu apakah tiket masih ada di layar.
2. Pastikan printer menyala, kertas ada, dan Bluetooth/USB tersambung ke perangkat yang benar.
3. Kalau tetap gagal: pakai **jalur cadangan** — layar dapur tetap menampilkan pesanan, struk bisa **ditampilkan di layar** dan dikirim ke pelanggan (foto/berkas) sampai printer hidup.
4. Catat kejadiannya (tanggal, perangkat, merek printer) di Log Insiden supaya pola masalahnya terlihat.
5. Kalau terjadi berulang: laporkan ke pemilik platform sebelum pilot supaya penggantian printer dipertimbangkan.

---

## 10. Cadangan & pemulihan (latihan sebelum pilot)

1. Cadangan otomatis berjalan mingguan (dump terenkripsi); pemilik mengunduh salinannya **sebulan sekali** ke komputer/Drive miliknya.
2. **Latihan pemulihan** (dilakukan agent bersama pemilik platform, minimal sekali sebelum pilot): pulihkan cadangan ke database bersih → bandingkan jumlah baris tabel inti → tulis hasilnya di `docs/teknis/PEMULIHAN.md` (berkas ini **belum dibuat**; dibuat saat latihan pemulihan dijalankan pada tugas `T11-10`).
3. Kalau ada data yang tidak sengaja terhapus/berubah: **jangan** menambal dengan mengubah data lama — catat sebagai koreksi baru (aplikasi memang dirancang begitu untuk data keuangan), dan kalau perlu pulihkan dari cadangan **ke lingkungan uji dulu**.

---

## 11. Kunci rahasia bocor (kunci sistem terlihat di tempat umum/dikirim ke orang)

1. Pemilik platform segera **mengganti kunci** di panel Supabase/Cloudflare (panduan langkah ada di `docs/ops/`).
2. Perbarui kunci di tempat yang seharusnya (panel rahasia), **bukan** di kode.
3. Periksa jejak audit untuk aktivitas mencurigakan sejak kunci itu mungkin terlihat.
4. Panggil ulang (deploy) aplikasi supaya memakai kunci baru.
5. Catat di Log Insiden: kunci apa, kapan terganti, siapa yang tahu, apa yang diperiksa.

---

## 12. Log Insiden (selalu diisi)

| # | Tanggal & jam | Kejadian | Langkah yang dilakukan | Hasil | Uang/data terdampak? | Ditangani oleh | Sudah diperbaiki? |
|---|---|---|---|---|---|---|---|
| 1 | | | | | | | |

**Aturan pengisian:** (a) tulis juga kejadian yang selesai sendiri; (b) **jangan** menulis PIN/kata sandi/kunci di kolom mana pun; (c) setiap insiden uang ≥ Rp 100.000 wajib dibaca pemilik dalam 1×24 jam; (d) setiap insiden data pelanggan wajib masuk hitungan 3×24 jam UU PDP (bagian 6).
