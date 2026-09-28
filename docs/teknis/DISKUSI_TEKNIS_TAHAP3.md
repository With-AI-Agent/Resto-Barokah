# Bahan Diskusi Teknis (Tahap 3) — Putaran 1

> Untuk pemilik. Ditulis tanpa istilah teknis. Baca bagian **"Yang perlu kamu putuskan"** saja kalau
> tidak sempat membaca semuanya; sisanya untuk menjelaskan alasannya.
>
> Dimulai: 2026-09-16 · Status: **putaran 1 — menunggu keputusan pemilik** · Setelah pemilik bilang
> "cukup, tulis drafnya", barulah `docs/TECH_SPEC.md` ditulis (aturan kerja sistem ini).

---

## 1. Posisi kita sekarang

| Yang sudah selesai | Yang sedang dikerjakan | Yang belum |
|---|---|---|
| DISCOVERY (dikunci) · PRD (dikunci) · contoh tampilan 10 tema (selesai & terkirim) | **Tahap 3 — Rancangan Teknis** (dokumen ini putaran 1) | `TECH_SPEC.md` · `AGENT_OPERATING_GUIDE.md` · `ROADMAP.md` · lalu coding bertahap G1→G2→G3 |

Yang sudah pasti dari PRD — tidak dibahas ulang di sini: 6 peran · voucher undang-teman · katalog pelanggan ·
multi-cabang · pajak & service bisa diatur · biaya nol diutamakan · masuk pakai Google + email (tanpa SMS) ·
pilot di Kedai Oasis · pembagian gelombang G1 → G2 → G3.

---

## 2. Batas layanan gratis — disampaikan terbuka (prinsip "jujur soal batas")

Saya baru memeriksa ulang ketentuan yang berlaku **Agustus–September 2026**:

| Layanan | Gratisnya sebesar | Catatan penting | Boleh untuk usaha? |
|---|---|---|---|
| **Supabase** (tempat data & akun) | 500 MB data · 1 GB foto · 5 GB lalu lintas/bulan · 50.000 pengguna aktif | Proyek **otomatis "tidur" bila 7 hari tidak ada aktivitas** (bisa dibangunkan lagi; untuk kedai yang buka harian tidak masalah) | **Ya, boleh** |
| **Cloudflare** (tempat menjalankan aplikasi) | Halaman statis tanpa batas · fungsi dinamis 100.000 permintaan/hari | Tidak ada tagihan kejutan — kalau lewat batas, layanan berhenti sampai besok (bukan menagih) | **Ya, boleh** |
| **Vercel** (alternatif Cloudflare) | 100 GB/bulan, 1 juta permintaan fungsi | **Hanya untuk proyek pribadi/non-usaha** — aturan resminya melarang pemakaian komersial di paket gratis | **Tidak boleh** ❌ |
| **Resend / Mailjet / Brevo** (email verifikasi) | 3.000–9.000 email/bulan | Butuh memverifikasi domain sendiri | Ya |
| **Google Sign-In** | Tanpa batas email | Jalur masuk utama pelanggan | Ya |

**Perkiraan pemakaian Kedai Oasis (1 cabang, ~100 transaksi/hari):** sekitar 3.000–6.000 permintaan/hari,
data ± 20–60 MB/tahun (teks transaksi sangat kecil; foto menu yang paling besar). Artinya **masih jauh di bawah
batas gratis** — dengan catatan foto menu dirapikan ukurannya (sudah kami lakukan: ≤ 1000 px).

---

## 3. Enam keputusan besar (masing-masing: pilihan · untung · rugi · usul saya)

### K1. Bentuk aplikasinya
| Pilihan | Untung | Rugi |
|---|---|---|
| **A. Aplikasi web yang bisa dipasang di HP (PWA)** — dibuka lewat browser, lalu "Tambahkan ke layar utama" | Berjalan di HP, tablet, laptop, dan komputer kasir sekaligus **tanpa membuat aplikasi terpisah**; pemutakhiran langsung; biaya nol | Tidak ada di toko aplikasi; notifikasi latar terbatas |
| B. Aplikasi Android asli (Play Store) | Ada di toko aplikasi; notifikasi lebih bebas | Perlu akun & biaya pendaftaran Play Store (sekitar Rp 200–300 rb sekali) + waktu pengembangan ± 2× lebih lama; iPhone tetap perlu versi lain |
| C. Dua-duanya | Paling lengkap | Paling lama & dua kali perawatan |

**Usul saya: A (PWA).** Alasannya: syarat utama kamu adalah **"jalan di perangkat apa pun"** dan **"biaya nol"** — PWA memenuhi dua-duanya. Aplikasi asli bisa menyusul di fase 3 kalau memang perlu.

### K2. Tempat menjalankan aplikasi & menyimpan data
| Pilihan | Untung | Rugi |
|---|---|---|
| **A. Cloudflare (aplikasi) + Supabase (data & akun)** | Gratis **dan boleh untuk usaha**; cepat di Indonesia; batasnya besar; tidak ada tagihan kejutan | Perlu dua akun (satu kali penyiapan) |
| B. Semua di Supabase | Satu akun saja | Halaman pelanggan sedikit lebih lambat; fungsi gratisnya terbatas; batas harian lebih cepat penuh |
| C. Vercel + Supabase | Paling populer & mudah | **Melanggar aturan paket gratisnya** untuk aplikasi usaha → risiko akun ditutup |

**Usul saya: A.** Ini satu-satunya kombinasi gratis yang **jujur-jujur boleh dipakai untuk usaha**.

### K3. Cara mencetak struk & tiket dapur
| Pilihan | Untung | Rugi |
|---|---|---|
| **A. Printer termal yang tersambung langsung ke perangkat kasir** (Bluetooth atau kabel USB), dicetak dari aplikasi | Tidak perlu jaringan tambahan; murah (Rp 300–600 rb); umum di kedai | Perlu uji nyata di Kedai Oasis: tidak semua printer & HP cocok; iPhone tidak mendukung Bluetooth-web (Android/Windows aman) |
| B. Printer jaringan (LAN) satu untuk kasir + satu untuk dapur | Printer bisa di mana saja di kedai | Lebih mahal; perlu pengaturan alamat printer; lebih sering bermasalah saat internet/Wi-Fi kedai lemot |
| C. Tanpa printer dulu — struk digital (layar + kirim/lihat di HP) & tiket dapur di layar | Nol biaya langsung; tidak ada risiko printer | Kurang nyaman untuk pelanggan yang minta bukti cetak |

**Usul saya: A sebagai utama + C sebagai cadangan wajib.** PRD sudah menandai ini sebagai risiko nomor satu, jadi uji cetak harus dilakukan **di Kedai Oasis lebih awal**, sebelum fitur lain dianggap selesai. Kalau printer yang ada di Kedai Oasis ternyata tipe jaringan, kita pindah ke B.

### K4. Perilaku saat internet kedai mati
| Pilihan | Untung | Rugi |
|---|---|---|
| **A. Daring dulu, tapi tahan gangguan kecil** — pesanan tetap bisa dicatat sebentar saat internet putus, lalu terkirim sendiri saat internet kembali | Cocok dengan kondisi pilot (internet lancar); tidak ada pesanan "hilang diam-diam" | Bukan mode offline penuh: kalau mati lama (> beberapa jam), kasir diminta kembali ke cara manual sementara |
| B. Tahan offline sejak awal (semua perangkat menyimpan data sendiri lalu disamakan) | Aman walau internet sering mati | Menambah waktu pengembangan cukup banyak (2–3× pada bagian pesanan & kas) dan menambah tempat salah hitung |
| C. Tidak dipikirkan dulu (daring penuh) | Paling cepat jadi | Bila internet putus saat ramai, kasir terhenti |

**Usul saya: A.** Ini sejalan dengan catatan DISCOVERY (Kedai Oasis internetnya lancar) dan tetap melindungi dari gangguan sekejap. Mode offline penuh tetap masuk fase 3 untuk penyewa yang internetnya lemah.

### K5. Masuk (akun) & kunci layar
| Pilihan | Untung | Rugi |
|---|---|---|
| **A. Pegawai: email + PIN 4–6 angka per pegawai · Pelanggan: "Masuk dengan Google" (utama) atau email terverifikasi (kedua)** | Sesuai keputusan PRD; PIN cepat untuk kasir sibuk; tanpa SMS (tidak ada biaya) | Pegawai tetap perlu email untuk login pertama |
| B. Semua pegawai pakai email + kata sandi (tanpa PIN) | Lebih sederhana di awal | Kasir sibuk harus mengetik sandi panjang tiap kali ganti petugas |

**Usul saya: A.** Perlu dipastikan: tiap pegawai Kedai Oasis punya email aktif (kalau ada yang tidak, kita buatkan pola khusus — akan dibahas di pertanyaan terbuka).

### K6. Kalau batas gratis hampir penuh (nanti)
| Pilihan | Untung | Rugi |
|---|---|---|
| **A. Bayar saat sudah menghasilkan** (Supabase Pro $25/bulan; Cloudflare berbayar mulai $5/bulan) | Tidak ada gangguan saat usaha jalan | Ada biaya bulanan — tapi hanya setelah ada pemasukan |
| B. Tetap gratis dengan cara menghemat (pangkas foto, bersihkan data lama, kompres) | Tetap nol biaya | Ada plafon keras; cepat atau lambat tetap perlu naik |
| C. Belum diputuskan sekarang | — | Bisa terkejut saat mentok |

**Usul saya: A, dengan pemicu yang jelas**: perangkat akan menampilkan tanda peringatan di 70% dan 90% pemakaian, dan keputusan naik kelas diambil saat itu — bukan mendadak.

---

## 4. Yang perlu diputuskan pemilik (ringkas)

| Kode | Pertanyaan | Pilihan | Pilihan saya |
|---|---|---|---|
| K1 | Bentuk aplikasi | A · B · C | **A (PWA)** |
| K2 | Tempat menjalankan & menyimpan data | A · B · C | **A (Cloudflare + Supabase)** |
| K3 | Cara cetak struk | A · B · C | **A + C cadangan** |
| K4 | Internet mati | A · B · C | **A** |
| K5 | Masuk & PIN | A · B | **A** |
| K6 | Saat batas gratis penuh | A · B · C | **A** |

Jawaban singkat yang cukup: **"semua pakai usulmu"** — atau sebutkan kode yang mau diubah (contoh: "K3 pakai B").

> **Catatan 2026-09-16:** pemilik membaca bahan ini, **melewati** pertanyaan pilihan, dan menjawab **"Lanjut"** →
> sesuai aturan keputusan yang disepakati ("terserah/kamu yang tahu/kamu yang terbaik = persetujuan resmi & dicatat"),
> keenam keputusan diambil **sesuai usul agent**: K1 A · K2 A · K3 A+C · K4 A · K5 A · K6 A. Keputusan itu dicatat
> di `docs/TECH_SPEC.md` §13 dan `_log-sesi/LOG_SESI_2026-09-16.md`. Pemilik tetap boleh mengubah kapan saja —
> cukup sebut kodenya (contoh: "K4 pakai B").

## 5. Dua hal yang saya butuhkan dari lapangan (bukan keputusan, tapi data)

1. **Printer di Kedai Oasis**: merek & tipe, dan disambung ke apa (HP/tablet/laptop kasir)? Bila belum ada, kami belikan rekomendasi yang sudah terbukti (Rp 300–600 rb).
2. **Perangkat yang dipakai**: berapa HP/tablet/komputer, dan Android atau iPhone? (Menentukan uji Bluetooth & bentuk layar kasir.)

## 6. Setelah pemilik menjawab

1. Saya tulis **`docs/TECH_SPEC.md`**: susunan teknologi, gambar alur, susunan folder, **rancangan database (entitas & relasi)**, daftar API per fitur MVP, variabel lingkungan, integrasi pihak ketiga, pertimbangan keamanan, dan **Area Berisiko Tinggi** yang wajib ditulis eksplisit.
2. Saya tulis **`docs/ROADMAP.md`**: pecahan tugas kecil-kecil untuk G1 (per fitur, dengan urutan dan uji terima).
3. Saya tulis **`docs/AGENT_OPERATING_GUIDE.md`**: aturan kerja agent + `DECISIONS_LOG.md`.
4. Setelah semua disetujui, barulah masuk **tahap coding G1**.

> Aturan yang saya pegang: **dokumen teknis final belum ditulis sampai kamu bilang "cukup, tulis drafnya"** —
> supaya keputusanmu masuk lebih dulu, bukan ditebak-tebak.

## Log putaran ini
| Tanggal | Peristiwa | Oleh |
|---|---|---|
| 2026-09-16 | Putaran 1 dibuka; pemilik menjawab "Lanjut" atas hasil desain → sesi desain dianggap cukup untuk saat ini, lanjut Tahap 3. Batas layanan gratis diperiksa ulang (termasuk menemukan paket gratis Vercel tidak boleh untuk usaha) | Agent |
