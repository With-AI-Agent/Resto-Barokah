# TECH_SPEC.md — Rancangan Teknis Resto Barokah

> **Status: DISETUJUI & DIKUNCI PEMILIK — 2026-09-16** (jawaban pemilik: **"Ya, setuju"**). Dokumen ini ditulis
> setelah pemilik menyerahkan pilihan teknis kepada agent (keputusan K1–K6 diambil sesuai usul agent —
> dicatat di `_log-sesi/LOG_SESI_2026-09-16.md`). Sejak dikunci: **perubahan yang menyentuh Area Berisiko Tinggi
> (ART-1…ART-10) WAJIB lewat `DECISIONS_LOG.md` + persetujuan pemilik** — dilarang mengubah diam-diam.
>
> Ditulis: 2026-09-16 · Disetujui: 2026-09-16 · Rujukan: `docs/PRD.md` (dikunci) · `docs/DISCOVERY.md` (dikunci) ·
> `docs/teknis/DISKUSI_TEKNIS_TAHAP3.md` (bahan diskusi putaran 1) · sistem desain `prototipe/css/tokens.css` (v3)

---

## 0. Ringkasan bahasa manusia (untuk pemilik)

1. **Bentuknya:** satu aplikasi web yang dipasang di HP/tablet/komputer (bisa ditambahkan ke layar utama seperti aplikasi biasa). Satu kode untuk kasir, dapur, laporan, katalog pelanggan, dan voucher — tampilannya menyesuaikan peran yang masuk.
2. **Tempat tinggalnya:** halaman aplikasi di **Cloudflare** (gratis, boleh untuk usaha, tanpa tagihan kejutan) dan data, akun, foto, serta fungsi rahasia di **Supabase** (gratis, boleh untuk usaha).
3. **Uang tidak bisa "dikira-kira":** semua hitungan total, pajak, service, diskon, dan kembalian dihitung **di sisi peladen (server)**, bukan di HP. Nominal disimpan sebagai bilangan bulat rupiah.
4. **Yang bikin orang tidak bisa curang:** setiap data terpisah per resto & per cabang, setiap tindakan sensitif butuh PIN dan tercatat di buku catatan yang **tidak bisa dihapus atau diubah**.
5. **Perangkat yang boleh kerja (baru 2026-09-17):** bagian staf (kasir, dapur, pelayan, admin cabang, owner) hanya bisa dibuka dari **perangkat yang sudah didaftarkan** admin/owner — tablet kasir tidak bisa dipakai masuk sebagai owner, dan kalau perangkat hilang/dicuri, aksesnya **mati seketika** begitu dicabut dari aplikasi. Masuk kerjanya tetap cepat: pilih nama → PIN 6 digit, hanya dari perangkat itu.
5. **Kalau internet putus sebentar:** kasir tetap bisa mencatat, pesanan menunggu di antrean dan terkirim sendiri saat internet kembali — tanpa dobel.
6. **Cetak struk:** printer termal tersambung ke perangkat kasir (Bluetooth/USB). Kalau printer bermasalah, selalu ada jalur cadangan: tiket dapur tetap di layar dan struk bisa ditampilkan/dibagikan.
7. **Batas gratis yang jujur:** data 500 MB · foto 1 GB · lalu lintas 5 GB/bulan · 50.000 pelanggan aktif · proyek Supabase "tidur" bila 7 hari tidak dipakai (tidak masalah untuk kedai harian, dan tetap dijaga oleh penjadwal otomatis). Perkiraan pemakaian Kedai Oasis 1 cabang: **jauh di bawah** batas itu.
8. **Perkiraan luasnya:** G1 (yang dipakai harian di Kedai Oasis) ≈ 10–14 minggu kerja agent, bertahap, tiap gelombang wajib lulus uji sebelum lanjut.

---

## 1. Tech Stack (dengan alasan)

| Lapis | Pilihan | Alasan (dan apa yang ditolak) |
|---|---|---|
| **Aplikasi (klien)** | **React 19 + TypeScript + Vite**, dibangun sebagai **PWA** (service worker, bisa dipasang ke layar utama, tahan gangguan jaringan) | Satu kode untuk semua perangkat (syarat pemilik "jalan di perangkat apa pun"); PWA = biaya nol, pemutakhiran langsung. **Ditolak:** aplikasi Android/iOS asli (biaya Play Store + waktu 2×, iPhone tetap butuh versi lain). |
| **Gaya/tampilan** | Token desain dari `prototipe/css/tokens.css` v3 dipindah apa adanya ke proyek aplikasi (10 tema, tangga jarak, tangga huruf, bayangan berlapis) + komponen React | Karya desain yang sudah disetujui tidak dibuang; tema tetap bisa diganti tanpa koding. |
| **Data & akun** | **Supabase** (Postgres 17 + Auth + Storage + Realtime + Edge Functions + pg_cron) | Postgres = data keuangan yang bisa diuji & dihitung tepat; RLS bawaan untuk pemisahan data antar-resto; gratis **dan boleh komersial**. **Ditolak:** Firestore/NoSQL (lemah untuk laporan & transaksi keuangan yang butuh konsistensi). |
| **Halaman aplikasi** | **Cloudflare Workers + Static Assets** (menyajikan berkas aplikasi) | Gratis, **boleh komersial**, berkas statis tanpa batas, dekat ke Indonesia. **Ditolak:** Vercel Hobby (aturan resminya **melarang pemakaian usaha**), Netlify (batas build lebih ketat untuk pemakaian ini). |
| **Logika sensitif** | **Supabase Edge Functions (Deno)** + **fungsi SQL (RPC)** di Postgres | Hitung uang, pakai voucher, verifikasi PIN, dan kirim email harus di sisi peladen — tidak boleh dari HP. |
| **Email verifikasi** | **Resend** (gratis 3.000/bulan; cadangan Brevo 300/hari atau Mailjet) | Email bawaan Supabase hanya 2 email/jam (tidak layak produksi) — sudah tercatat di PRD. |
| **Waktu & tugas berkala** | **pg_cron** di Supabase | Penutup hari otomatis, penagihan laporan harian, "denyut" harian agar proyek gratis tidak tidur, dan pembersih data sementara. |
| **Cetak** | ESC/POS langsung dari browser: **Web Bluetooth** (Android/Windows) & **WebUSB**; jalur cadangan cetak PDF/bagikan | Sesuai keputusan K3 (printer tersambung perangkat + cadangan digital). **Ditolak:** printer jaringan sebagai jalur utama (bergantung Wi-Fi kedai). |
| **Uji** | **Vitest** (unit) + **Uji SQL RLS** (pgtap/psql) + **Playwright** (end-to-end di lingkungan pengembangan) + `uji-kontras.py` & `prototipe/alat/periksa-halaman.py` yang sudah ada | Prinsip "tidak ada yang cacat": setiap gelombang wajib lulus uji otomatis + daftar uji terima manual. |
| **Bahasa** | Seluruh teks aplikasi Bahasa Indonesia; kode & nama tabel Bahasa Indonesia agar mudah dibaca agent berikutnya | Menghindari salah tafsir antar sesi (pemilik tidak memakai istilah Inggris). |

> Catatan kejujuran: lingkungan kerja agent saat ini **tidak bisa memasang peramban** untuk tangkapan layar, dan
> Playwright juga gagal dipasang di sini. Playwright **wajib** dipasang di lingkungan pengembangan/CI nanti;
> selama belum ada, uji yang bisa dijalankan adalah uji SQL, uji unit, dan pemeriksa statis yang sudah ada.

---

## 2. Arsitektur (pola + diagram teks)

**Pola: aplikasi satu halaman (SPA) + peladen data tanpa lapisan perantara milik sendiri.**
Klien tidak pernah memutuskan angka uang; klien hanya mengumpulkan maksud pengguna, lalu memanggil fungsi
peladen yang memutuskan dan mencatat.

```
        HP kasir / tablet pelayan / layar dapur / komputer owner / HP pelanggan
                                   │  HTTPS
                                   ▼
        ┌──────────────────────────────────────────────────────────────┐
        │  Cloudflare Workers + Static Assets                          │
        │  (menyajikan berkas aplikasi React+Vite:PWA — gratis, boleh  │
        │   komersial, berkas statis tanpa batas)                      │
        └──────────────────────────────────────────────────────────────┘
                                   │  (aplikasi memanggil)
                                   ▼
        ┌──────────────────────────────────────────────────────────────┐
        │  Supabase                                                    │
        │  ├─ Auth ............ masuk pegawai (email+PIN) & pelanggan  │
        │  │                    (Google utama, email terverifikasi)    │
        │  ├─ Postgres + RLS .. semua data; tiap baris terkunci ke     │
        │  │                    resto & cabangnya                      │
        │  ├─ Fungsi SQL (RPC)  hitung total, simpan pesanan, bayar,   │
        │  │                    void, voucher, tutup kas, laporan      │
        │  ├─ Edge Functions ... kirim email, verifikasi PIN, cetak,   │
        │  │                    pemicu laporan                         │
        │  ├─ Storage ......... foto menu & logo (≤1000 px, webp)      │
        │  ├─ Realtime ........ layar dapur, status meja, keranjang    │
        │  └─ pg_cron ......... penutup hari, denyut harian, bersih-   │
        │                       bersih data sementara                  │
        └──────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
        ┌──────────────────────────────────────────────────────────────┐
        │  Pihak ketiga gratis: Google (masuk), Resend/Brevo (email),  │
        │  printer termal (Bluetooth/USB, dari perangkat kasir)        │
        └──────────────────────────────────────────────────────────────┘
```

**Alur satu pesanan (ringkas):**

1. Kasir menekan menu → keranjang disusun **di HP** (belum diputuskan).
2. Tekan **Kirim**: klien memanggil `simpan_pesanan(...)` dengan **kunci idempoten** (kode unik sekali pakai).
3. Fungsi SQL memeriksa izin, mengunci harga saat itu (`harga_saat_itu`), **menghitung total/pajak/service/diskon**, menyimpan, dan mengembalikan nomor pesanan.
4. Realtime mendorong pesanan ke **layar dapur**; bila printer aktif, perangkat kasir mengirim ESC/POS.
5. Tekan **Bayar**: `bayar_pesanan(...)` mencatat metode, uang diterima, kembalian, menandai pesanan lunas — semuanya di peladen.
6. **Sebelum pembayaran pertama**, batal/void mengikuti **state machine** + PIN atasan (bila sudah masuk dapur) → tercatat sebagai bahan terbuang bernilai rupiah. **Setelah pembayaran pertama (termasuk sebagian), isi/nominal, diskon, dan void terkunci**; PIN atasan tidak menjadi pengecualian (T-025(a), penegak 0022; pesan BY-201).
7. Tutup kas: `tutup_shift(...)` membandingkan uang seharusnya vs hitung fisik → selisih wajib beralasan.

---

## 3. Struktur Folder

```
/aplikasi                       ← aplikasi React + Vite (PWA)
  /public
    manifest.webmanifest        ← agar bisa dipasang ke layar utama
    sw.js                       ← service worker (cache + antrean kirim ulang)
  /src
    /gaya
      token/*.css               ← 10 tema (dipindah dari prototipe/css/tokens.css v3)
      komponen.css
    /komponen                   ← tombol, kartu, kaca, lapis mengambang, tabel, toast…
    /layar
      /kasir  /dapur  /laporan  /pengaturan  /pelanggan-publik  /voucher  /masuk
    /lib
      supabase.ts               ← klien Supabase (aman untuk publik)
      antrean-offline.ts        ← antrean di IndexedDB + kunci idempoten
      printer-escpos.ts         ← Bluetooth/USB
      format.ts                 ← rupiah, tanggal, jam (WIB)
    /hook                       ← pemakaian data (React Query ringan)
/supabase
  /migrations/*.sql             ← skema & kebijakan RLS (bernomor, tidak pernah diubah setelah jalan)
  /functions/*                  ← Edge Functions (email, PIN, cetak, pemicu)
  /seed.sql                     ← data awal: 1 penyewa contoh, 10 tema, metode bayar, meja
  /tes/*.sql                    ← uji RLS & uji hitungan uang
/prototipe                      ← contoh tampilan (sudah ada, tetap dipakai sebagai acuan desain)
/docs                           ← DISCOVERY, PRD, TECH_SPEC (dokumen ini), ROADMAP, AGENT_OPERATING_GUIDE
/alat                           ← skrip bantu (bootstrap sesi mulai-sesi.py, denyut harian, cadangan, pemeriksa)
```

---

## 4. Data Model / Skema Database

**Aturan umum (mengikat):**

- **Setiap tabel milik penyewa wajib punya `penyewa_id`** (dan `cabang_id` bila per cabang). Tidak ada pengecualian.
- **Uang disimpan sebagai bilangan bulat rupiah** (`integer`), bukan pecahan — Rp 25.000 disimpan `25000`.
- **Harga & nama disalin saat transaksi** (`harga_saat_itu`, `nama_saat_itu`) — supaya mengubah menu tidak mengubah struk & laporan lama (Aturan Bisnis 10).
- **Tidak ada penghapusan permanen.** Tabel transaksi memakai kolom `dibatalkan_pada`, `alasan_batal`; koreksi ditulis sebagai baris baru.
- **Waktu disimpan UTC**, ditampilkan memakai zona waktu penyewa (bawaan `Asia/Jakarta`).
- **Nomor pesanan harian per cabang** dibuat berurutan di peladen (bukan di HP).

### 4.1 Penyewa, cabang, pengguna, izin

| Tabel | Kolom inti | Catatan |
|---|---|---|
| `penyewa` | `id`, `nama`, `slug`, `status` (aktif/nonaktif), `zona_waktu`, `mata_uang`, `dibuat_pada` | Isolasi tingkat 1 (resto) |
| `cabang` | `id`, `penyewa_id`, `nama`, `alamat`, `telepon`, `aktif` | Isolasi tingkat 2 (cabang) |
| `pengguna` | `id` (= id Auth), `penyewa_id` (boleh null untuk Pemilik Platform), `nama`, `email` (alias internal untuk staf), `peran`, `pin_diubah_pada`, `aktif`, `terakhir_masuk`, `mfa_wajib`, `mfa_terdaftar_pada`, `catatan` | `peran`: `pemilik_platform` · `owner_pusat` · `admin_cabang` · `kasir` · `pelayan` · `dapur`. **Satu akun = satu peran** (DECISIONS_LOG 2026-09-17); staf memakai alias email internal sehingga pemulihan lewat admin, bukan email |
| `pengguna_cabang` | `pengguna_id`, `cabang_id`, `aktif` | **Daftar cabang** tempat akun bertugas (peran per cabang tidak lagi menjadi sumber wewenang — satu peran berlaku di semua cabangnya) |
| `izin` | `pengguna_id`, `kode_izin`, `boleh` (bool), `batas_nominal`, `batas_persen` | Centang izin per pegawai (M3). Kode: `ubah_harga`, `beri_diskon`, `void_sebelum_dapur`, `void_sesudah_dapur`, `lihat_laporan`, `kelola_pegawai`, `atur_pengaturan`, `pakai_voucher`, `tutup_kas`, `ubah_stok` |
| `pengaturan` | `penyewa_id`, `pajak_pb1_persen`, `service_persen`, `pembulatan` (none/100/500/1000), `tumpuk_diskon` (bool), `batas_maks_potongan_persen`, `batas_maks_potongan_nominal`, `header_struk`, `footer_struk`, `cara_pesan`, `jam_buka` | Aturan Bisnis 1, 2 |
| `metode_bayar` | `penyewa_id`, `kode` (tunai/qris/transfer/ewallet/kartu), `aktif`, `urutan` | Pencatatan, bukan integrasi otomatis |
| `printer` | `cabang_id`, `nama`, `jenis` (bluetooth/usb), `peran` (kasir/dapur/tiket), `alamat`, `aktif` | Dipakai perangkat kasir/dapur |

### 4.2 Menu & stok

| Tabel | Kolom inti | Catatan |
|---|---|---|
| `kategori_menu` | `id`, `penyewa_id`, `nama`, `urutan`, `aktif` | |
| `menu_item` | `id`, `penyewa_id`, `kategori_id`, `nama`, `deskripsi`, `harga`, `foto_path`, `urutan`, `unggulan`, `jenis` (makanan/minuman/lainnya), `aktif` | `jenis` menentukan tujuan tiket (dapur vs bar) |
| `menu_varian` | `menu_item_id`, `nama` (panas/es, reguler/jumbo), `tambahan_harga`, `aktif` | |
| `menu_tambahan` | `menu_item_id` (boleh null = berlaku semua), `nama`, `harga`, `aktif` | |
| `menu_cabang` | `cabang_id`, `menu_item_id`, `harga` (boleh null = ikut pusat), `aktif`, `habis` | Harga beda per cabang + penanda habis (M9) |
| `stok_bahan` | `id`, `penyewa_id`, `nama`, `satuan`, `jumlah`, `minimum`, `dipantau` (bool) | Stok sederhana G1 |
| `stok_pergerakan` | `id`, `stok_bahan_id`, `jenis` (masuk/keluar/opname/koreksi), `jumlah`, `alasan`, `pelaku_id`, `waktu` | Riwayat — tidak dihapus |

### 4.3 Pesanan, pembayaran, kas

| Tabel | Kolom inti | Catatan |
|---|---|---|
| `shift_kas` | `id`, `cabang_id`, `dibuka_oleh`, `ditutup_oleh`, `dibuka_pada`, `ditutup_pada`, `modal_awal`, `uang_seharusnya`, `uang_fisik`, `selisih`, `alasan_selisih` | M7. Selisih wajib beralasan |
| `kas_pergerakan` | `id`, `shift_id`, `jenis` (setoran/pengeluaran/koreksi), `jumlah`, `alasan`, `pelaku_id`, `disetujui_oleh` | Buka laci tanpa transaksi wajib tercatat |
| `pesanan` | `id`, `penyewa_id`, `cabang_id`, `nomor` (per cabang/hari), `tipe` (dinein/takeaway/ojol), `meja_id`, `status`, `pelayan_id`, `kasir_id`, `shift_id`, `dibuat_pada`, `dikirim_ke_dapur_pada`, `catatan`, `subtotal`, `pajak`, `service`, `total_diskon`, `total`, `dibayar_pada`, `dibatalkan_pada`, `alasan_batal`, `kunci_idempoten` (unik) | `status`: `draf` → `dikirim` → `dimasak` → `siap` → `lunas` / `batal` |
| `pesanan_item` | `id`, `pesanan_id`, `menu_item_id`, `nama_saat_itu`, `harga_saat_itu`, `qty`, `varian` (jsonb), `tambahan` (jsonb), `catatan`, `status` (baru/dimasak/siap/batal), `subtotal` | Catatan khusus per item (M4) |
| `pembayaran` | `id`, `pesanan_id`, `metode`, `jumlah`, `diterima`, `kembalian`, `referensi`, `kasir_id`, `shift_id`, `waktu`, `kunci_idempoten` | Tunai → hitung kembalian; lain-lain → catat referensi |
| `diskon_transaksi` | `id`, `pesanan_id`, `jenis` (voucher/manual/promo), `persen`, `nominal`, `nilai`, `alasan`, `pelaku_id`, `disetujui_oleh`, `voucher_id` | Aturan Bisnis 2 & 8 |
| `pembatalan` | `id`, `pesanan_id`, `pesanan_item_id` (boleh null), `tahap` (sebelum_dapur/sesudah_dapur), `pelaku_id`, `disetujui_oleh`, `alasan`, `nilai_kerugian`, `bahan_terbuang` (bool), `waktu` | Void bertingkat (Aturan Bisnis 7) |
| `meja` | `id`, `cabang_id`, `nama`, `area`, `status` (kosong/terisi/siap), `aktif` | M4 |
| `catatan_audit` | `id`, `penyewa_id`, `cabang_id`, `pelaku_id`, `tindakan`, `entitas`, `entitas_id`, `nilai_sebelum` (jsonb), `nilai_sesudah` (jsonb), `alasan`, `perangkat`, `waktu` | **Hanya bisa ditambah** — dilarang diubah/dihapus oleh siapa pun (Aturan Bisnis 8) |

### 4.4 Pelanggan & voucher

**T-023 (Lee, 2026-09-21): tanpa PIN pelanggan.** Identitas melalui Supabase Auth: Google Sign-In utama, email terverifikasi kedua. Tabel pelanggan tidak menyimpan PIN/hash PIN; kredensial PIN pegawai di §4.5 bukan milik pelanggan. Kanal email tetap mengikuti gerbang T-022/T2-04.

| Tabel | Kolom inti | Catatan |
|---|---|---|
| `pelanggan` | `id` (= id Auth), `penyewa_id`, `nama`, `email`, `telepon`, `alamat`, `cara_masuk` (google/email), `terverifikasi_pada`, `didaftarkan_oleh` (bila didaftarkan kasir) | Nomor HP opsional (Aturan Bisnis 3) |
| `kampanye_voucher` | `id`, `penyewa_id`, `nama`, `jenis` (persen/nominal), `nilai`, `min_belanja`, `maks_potongan`, `mulai`, `selesai`, `kuota`, `anggaran_maks`, `cabang_berlaku` (jsonb), `aktif` | Diatur admin (M10) |
| `voucher` | `id`, `kampanye_id`, `pelanggan_id`, `kode` (acak, unik), `status` (aktif/terpakai/kedaluwarsa/dibatalkan), `dibuat_pada`, `terpakai_pada`, `terpakai_di_cabang`, `terpakai_oleh`, `pesanan_id` | 10 pengaman anti-kecurangan (M10) |
| `voucher_percobaan` | `id`, `kode_dicoba`, `hasil`, `alasan`, `kasir_id`, `cabang_id`, `perangkat`, `waktu` | Log semua percobaan cek/scan |

### 4.5 Pendukung

| Tabel | Kolom inti | Catatan |
|---|---|---|
| `antrean_kirim` | `id`, `jenis`, `muatan` (jsonb), `status`, `percobaan`, `dibuat_pada`, `kunci_idempoten` | Untuk K4: antrean kirim ulang saat internet putus |
| `kredensial_pin` | `pengguna_id`, `pin_hash`, `diubah_pada` | Rahasia PIN dipisah dari `pengguna` (yang bisa dibaca klien) — laporan AUD-3 K-2; tidak ada hak baca untuk klien |
| `percobaan_pin` | `id`, `pengguna_id`, `perangkat`, `berhasil`, `aksi`, `waktu` | Batas percobaan **verifikasi** PIN (anti tebak) + bukti persetujuan (aksi yang diminta) |
| `percobaan_simpan_pin` | `id`, `pengguna_id`, `perangkat`, `berhasil`, `alasan`, `waktu` | Catatan pemasangan PIN (T1-23) — dasar pembatas anti-oracle keunikan PIN (20×/15 menit) |
| `catatan_kesalahan` | `id`, `penyewa_id`, `cabang_id`, `jenis`, `pesan`, `data` (jsonb), `perangkat`, `waktu` | Bantu perbaikan tanpa membocorkan data keuangan |

### 4.6 Perangkat, sesi & percobaan masuk (ditambahkan 2026-09-17 — lihat `docs/KEAMANAN.md`)

| Tabel | Kolom inti | Catatan |
|---|---|---|
| `perangkat` | `id`, `penyewa_id`, `cabang_id`, `nama`, `jenis`, `peran_diizinkan`, `rahasia_hash`, `status` (aktif/dicabut/hilang), `terakhir_aktif`, `terdaftar_oleh`, `dicabut_oleh`, `catatan` | Perangkat terdaftar: peran staf hanya bisa bekerja dari perangkat ini. Rahasia 32 byte, disimpan SHA-256 |
| `kode_pendaftaran_perangkat` | `id`, `penyewa_id`, `kode`, `kedaluwarsa_pada`, `dibuat_oleh`, `dipakai_pada`, `perangkat_id` | Kode sekali pakai, masa berlaku 15 menit |
| `sesi_perangkat` | `session_id` (dari token Supabase), `perangkat_id`, `pengguna_id`, `cabang_id`, `mulai`, `berakhir_pada`, `status` (aktif/selesai/dicabut), `disetujui_oleh` | Dasar pencabutan seketika & umur maksimum sesi |
| `persetujuan_perangkat` | `perangkat_id`, `pengguna_id`, `disetujui_oleh`, `waktu` | Persetujuan pemilik saat pegawai pertama memakai perangkat itu |
| `percobaan_masuk` | `id`, `pengguna_id` (boleh null), `perangkat_id` (boleh null), `berhasil`, `sebab`, `waktu` | Semua percobaan masuk (berhasil/gagal/diblokir) — dasar kunci 5×/15 menit per akun & 12×/15 menit per perangkat |

**Indeks wajib (contoh):** `pesanan(cabang_id, dibuat_pada desc)`, `pesanan(shift_id)`, `pesanan_item(pesanan_id)`,
`menu_cabang(cabang_id, habis)`, `voucher(kode) unique`, `voucher(kampanye_id, status)`,
`catatan_audit(penyewa_id, waktu desc)`, `pembayaran(shift_id)`, `pelanggan(penyewa_id, email)`,
`sesi_perangkat(session_id) unique`, `sesi_perangkat(perangkat_id, status)`, `perangkat(penyewa_id, status)`,
`kode_pendaftaran_perangkat(kode) unique`, `percobaan_masuk(pengguna_id, waktu desc)`, `percobaan_masuk(perangkat_id, waktu desc)`.

---

## 5. API Contract per fitur MVP

Bentuknya: **fungsi SQL (RPC)** untuk semua yang mengubah atau menghitung uang, **tabel langsung (dengan RLS)**
untuk pembacaan yang aman, **Edge Function** untuk hal yang butuh kunci rahasia.

| Fitur | Panggilan | Masukan | Keluaran |
|---|---|---|---|
| M1 penyewa & cabang | `rpc/buat_penyewa` · `rpc/set_status_penyewa` · `rpc/tambah_cabang` | data penyewa/cabang | id baru |
| M2 pengaturan | `rpc/simpan_pengaturan` · `rpc/simpan_menu` · `rpc/simpan_meja` · `rpc/simpan_metode_bayar` | objek pengaturan | versi pengaturan (stempel waktu) |
| M2 foto | `storage/upload` ke `foto-menu/{penyewa_id}/…` (gambar ≤1000 px) | berkas | alamat aman |
| M3 izin & peran | `rpc/set_izin` · `rpc/simpan_pin` · `rpc/verifikasi_pin` | pengguna, kode izin, PIN | berhasil/gagal + sisa percobaan |
| M3 audit | tabel `catatan_audit` (baca sesuai peran) | — | daftar kejadian |
| M4 pesanan | `rpc/simpan_pesanan` (kunci idempoten) · `rpc/kirim_ke_dapur` · `rpc/pindah_meja` · `rpc/tambah_item` | keranjang + meja | pesanan lengkap (nomor, total) |
| M5 dapur | `rpc/set_status_item` (dimasak/siap) · `rpc/tandai_habis` | id item/menu | status baru |
| M6 bayar & batal | `rpc/bayar_pesanan` · `rpc/batal_pesanan` · `rpc/batal_item` (PIN bila perlu) | metode, uang diterima, alasan, PIN | hasil + nilai kerugian bila void |
| M7 kas & shift | `rpc/buka_shift` · `rpc/tutup_shift` · `rpc/kas_pergerakan` | modal awal / uang fisik / alasan | selisih & ringkasan |
| M8 laporan | `rpc/laporan_shift` · `rpc/laporan_harian` | tanggal/cabang | angka & daftar (omzet, metode, void, voucher, kas) |
| M9 stok | `rpc/set_stok` · `rpc/opname_stok` · `rpc/tandai_habis` | bahan/jumlah/alasan | jumlah baru + riwayat |
| M10 katalog publik | `rpc/katalog_publik` (tanpa masuk) | slug resto | menu, harga, jam buka, cabang |
| M10 voucher | `rpc/cek_voucher` (**hanya membaca**) · `rpc/pakai_voucher` (PIN + sekali pakai) · `rpc/daftar_voucher` | kode, pelanggan | potongan / sebab gagal |
| M11 multi-cabang | `rpc/tambah_cabang` · `rpc/set_akses_cabang` | cabang, pengguna | hasil |
| M12 keamanan | `rpc/keluar_semua_perangkat` · `rpc/ganti_pin` | pengguna | hasil |

**Batas PIN pelanggan (T-023):** tidak ada RPC membuat, mengganti, memeriksa, atau memulihkan PIN pelanggan. Panggilan PIN dalam §5/§5.1 adalah untuk **pegawai/persetujuan**, termasuk kasir/atasan pada `pakai_voucher`; identitas pelanggan tetap Google/email melalui Auth.

### 5.1 RPC keamanan akun, perangkat & sesi (ditambahkan 2026-09-17 — rincian di `docs/KEAMANAN.md`)

| Fitur | Panggilan | Masukan | Keluaran |
|---|---|---|---|
| Perangkat | `rpc/buat_kode_perangkat` · `rpc/daftarkan_perangkat` · `rpc/setujui_perangkat_pegawai` · `rpc/cabut_perangkat` · `rpc/daftar_perangkat` | nama perangkat, peran yang diizinkan, cabang, kode | id perangkat / daftar perangkat & status |
| Sesi | `rpc/ikat_sesi_perangkat` · `rpc/daftar_sesi` · `rpc/keluar_semua_perangkat` | session id + bukti perangkat / pengguna / perangkat | sesi aktif tercatat / daftar sesi / jumlah sesi yang diakhiri |
| Akun & MFA | `rpc/atur_ulang_mfa` · `rpc/simpan_pin` · `rpc/ganti_pin` · `rpc/set_izin` | pengguna target, alasan | hasil + jejak audit |
| Mode dukungan | `rpc/mode_dukungan` | penyewa, alasan, lama (menit) | mode aktif/berakhir + catatan audit |
| Pemulihan perangkat (bila perangkat hilang) | `rpc/buat_kode_pemulihan` · `rpc/pulihkan_perangkat` · `rpc/batalkan_pemulihan` | kode pemulihan (8 kata) + kata sandi + TOTP · id perangkat baru | perangkat darurat dengan **masa tenggang 30 menit** (bisa dibatalkan) + pemberitahuan |

**Edge Functions (pintu tipis, logika tetap di database):** `verifikasi_pin` (ada) · `atur_ulang_mfa` (pengaturan ulang TOTP oleh peran di atasnya) · `ringkasan_harian` (email peringatan harian owner). Ketiganya: hanya POST, tanpa `console.*`, memakai token pemanggil + kunci publik (bukan `service_role`) kecuali `atur_ulang_mfa` yang memang butuh hak admin Auth — dengan pemeriksaan wewenang di database lebih dulu.

**Aturan bentuk jawaban (semua RPC):** selalu `{ berhasil: bool, kode: teks, pesan: teks, data: … }` dengan
`pesan` berbahasa Indonesia siap ditampilkan (mis. *"Voucher sudah dipakai pada 12.04 oleh kasir Rina di Cabang Pusat"*).

---

## 6. Environment Variables (rahasia tidak boleh ikut ke aplikasi)

| Nama | Dipakai di | Isi | Sifat |
|---|---|---|---|
| `VITE_SUPABASE_URL` | aplikasi | alamat proyek Supabase | publik (aman) |
| `VITE_SUPABASE_ANON_KEY` | aplikasi | kunci publik | publik (aman, dibatasi RLS) |
| `SUPABASE_SERVICE_ROLE_KEY` | Edge Functions/alat | kunci penuh | **rahasia** |
| `RESEND_API_KEY` (atau `BREVO_API_KEY`) | Edge Function | kirim email verifikasi | **rahasia** |
| `GOOGLE_CLIENT_ID/SECRET` | Supabase Auth | masuk dengan Google | **rahasia** (disimpan di Supabase) |
| `CLOUDFLARE_API_TOKEN` | penerapan (deploy) | unggah aplikasi | **rahasia** |
| `DENYUT_URL` | pg_cron/alat | denyut harian anti-tidur | rahasia rendah |

**Aturan:** kunci rahasia **tidak pernah** masuk ke kode aplikasi atau ke repositori; hanya lewat panel rahasia
(Cloudflare/Supabase). Repositori hanya berisi contoh kosong (`.env.example`).

---

## 7. Integrasi Pihak Ketiga

| Layanan | Untuk | Gratisnya | Risiko bila mentok |
|---|---|---|---|
| **Google Sign-In** | masuk pelanggan (utama) | tanpa batas email | hampir tidak ada |
| **Resend / Brevo / Mailjet** | email verifikasi & pemulihan | 3.000–9.000/bulan | pindah penyedia (kode sudah disiapkan agar bisa ditukar) |
| **Supabase** | data, akun, foto, realtime | 500 MB · 1 GB · 5 GB · 50.000 pengguna | naik ke Pro $25/bln saat sudah menghasilkan (keputusan K6) |
| **Cloudflare** | menyajikan aplikasi | berkas statis tanpa batas | hampir tidak ada |
| **Printer termal (perangkat keras)** | struk & tiket | sekali beli Rp 300–600 rb | jalur cadangan: layar + struk digital |

---

## 8. Pertimbangan Keamanan (ringkasan — rujukan resmi: `docs/KEAMANAN.md`)

> Sejak **2026-09-17**, rincian keamanan akun/perangkat/sesi/data pelanggan tinggal di **`docs/KEAMANAN.md`**.
> Bagian ini sengaja dibuat ringkas supaya tidak ada dua aturan yang saling bertentangan; bila berbeda, `KEAMANAN.md` menang.

1. **Pemisahan data (multi-penyewa):** setiap tabel punya `penyewa_id`; RLS **menolak secara bawaan**; uji dua akun beda penyewa wajib lulus.
2. **Pemisahan cabang:** `admin_cabang`, `kasir`, `pelayan`, `dapur` hanya cabangnya; owner seluruh cabang restonya; **pemilik platform tidak melihat isi transaksi** kecuali **mode dukungan** (beralasan, berbatas waktu, tercatat, dan owner penyewa diberitahu).
3. **Satu akun = satu peran**; orang dengan dua fungsi memakai dua akun (PIN berbeda). Izin dicentang per pegawai.
4. **Perangkat terdaftar:** peran staf hanya bisa bekerja dari perangkat yang didaftarkan admin/owner (kode sekali pakai) + disetujui pemilik saat pegawai baru pertama memakai perangkat itu; **pencabutan seketika** (diperiksa di database tiap permintaan).
5. **Masuk satset:** kasir/pelayan/dapur = **perangkat + PIN 6 digit** (unik antar pegawai); admin/owner/pemilik platform = **kata sandi ≥12 + TOTP wajib**; pelanggan = Google (utama) / email terverifikasi.
6. **Sesi:** token akses 15 menit; umur maksimum sesi (staf 12 jam · admin/owner 30 hari · pemilik platform 8 jam); **kunci otomatis** saat menganggur (15/15/15/30/60 menit); semua kendali ditegakkan di database/aplikasi karena fitur serupa di Supabase adalah paket Pro.
7. **Batas percobaan masuk:** 5×/15 menit per akun dan 12×/15 menit per perangkat; semua percobaan masuk `percobaan_masuk`; PIN salah berkali-kali terkunci, bukan menunggu.
8. **Tindakan sensitif butuh PIN** dan disetujui pengguna berizin (`boleh_untuk()`); PIN disimpan ter-hash (bcrypt), tidak pernah ditulis di log.
9. **Semua tindakan sensitif dicatat** di `catatan_audit` **hanya-tambah** + **rantai hash** (perubahan/penghapusan langsung di database terdeteksi).
10. **Uang dihitung di peladen**; klien tidak pernah mengirim total yang dipercaya; non-tunai wajib referensi + ringkasan peringatan harian ke owner.
11. **Fungsi istimewa dijaga:** `SECURITY DEFINER` wajib `search_path` dipaku + `revoke execute from public` + `grant` eksplisit + pemeriksaan izin di dalam badan fungsi.
12. **Privasi pelanggan (UU PDP):** persetujuan eksplisit, minimalisasi data, hak akses/hapus (anonimisasi), pemberitahuan kebocoran ≤ 3×24 jam (template di `docs/teknis/BUKU_INSIDEN.md`).
13. **Cadangan & pemulihan:** dump mingguan terenkripsi (T-012) + latihan pemulihan minimal sekali sebelum pilot.
14. **Rencana bila internet kedai mati:** antrean lokal + kunci idempoten (ART-8) + prosedur catat manual sementara (Buku Insiden).

---

## 9. Area Berisiko Tinggi (WAJIB — dibaca sebelum menyentuh)

> Bagian ini ditulis untuk agent sesi berikutnya. Aturan intinya ditulis ringkas & tegas; kalau mau mengubah,
> **wajib** menulis entri di `DECISIONS_LOG.md` lebih dulu.

### ART-1. RLS & isolasi penyewa (paling berbahaya)
- **Aturan:** setiap tabel milik penyewa **wajib** punya `penyewa_id`; RLS aktif di **semua** tabel tanpa kecuali (`alter table … enable row level security`).
- Kebijakan **deny by default**: tidak ada tabel tanpa kebijakan; akses dibuka hanya lewat kebijakan eksplisit `select/insert/update` per peran.
- Nilai penyewa & cabang diambil dari **tabel `pengguna` lewat id Auth** (fungsi `penyewa_saya()` / `cabang_saya()`), **bukan** dari `user_metadata` yang bisa diubah klien.
- Klien hanya memakai kunci publik. Kunci penuh hanya di Edge Function.
- **Uji wajib:** setiap migrasi menyertakan uji dua-penyewa & uji antar-cabang di `/supabase/tes/`.

### ART-2. Peran & izin berjenjang
- Sumber kebenaran izin: tabel `izin` (+ `pengguna_cabang`). Jangan menebak dari peran saja.
- Aturan khusus: **void sesudah dapur mulai** & **diskon di atas batas** **wajib** disetujui pengguna lain berizin (PIN), dan pelakunya tetap dicatat.
- Pegawai merangkap cabang → izin **per cabang**, bukan per akun saja.
- Perubahan izin **selalu** menulis `catatan_audit`.

### ART-3. Rantai perhitungan uang (mudah salah & mahal)
- **Urutan baku (tidak boleh ditukar):** subtotal (jumlah `harga_saat_itu × qty`) → **diskon** → **pajak PB1** → **service** → pembulatan → **total**.
- Diskon dihitung dari **subtotal**, pajak & service dihitung dari **subtotal setelah diskon** (keputusan ini ditulis di sini supaya tidak ditafsirkan ulang; bila pemilik minta lain → ubah di sini + `DECISIONS_LOG.md`).
- Semua nominal **bilangan bulat rupiah**; pembulatan hanya di langkah terakhir sesuai pengaturan resto.
- Satu fungsi tunggal `hitung_total(pesanan_id)` — **jangan** menduplikasi rumus di tempat lain.
- Semua nilai disalin saat transaksi (`harga_saat_itu`) — perubahan menu tidak boleh mengubah struk/laporan lama.

### ART-4. State machine pesanan
- Transisi sah: `draf → dikirim → dimasak → siap → lunas`; dan `→ batal` dengan syarat izin.
- `simpan_pesanan` & `bayar_pesanan` **wajib** memakai `kunci_idempoten` (unik) — mencegah dobel saat antrean offline mengirim ulang.
- Status item dapur hanya boleh maju (`baru → dimasak → siap`), tidak mundur; dua dapur menandai selesai bersamaan → operasi atomik (`update … where status='dimasak'`), bukan baca-lalu-tulis.
- Setelah `lunas` **tidak ada** perubahan nominal; koreksi = baris baru (Aturan Bisnis 11).

### ART-5. Voucher (rawan kecurangan)
- `cek_voucher` **hanya membaca** — dilarang mengubah status apa pun (keputusan pemilik).
- `pakai_voucher` **atomik sekali pakai**: `update voucher set status='terpakai' where kode=… and status='aktif' returning …` — bila tidak ada baris yang kembali, berarti gagal (jangan percaya pemeriksaan di klien).
- Semua syarat diperiksa **di peladen**: minimum belanja, batas maksimal potongan, masa berlaku, kuota kampanye, **anggaran kampanye**, cabang berlaku, satu voucher per identitas per kampanye.
- Kode **acak tidak berurutan**; setiap percobaan cek/scan masuk `voucher_percobaan`.
- Normalisasi email Gmail (titik & tanda `+`) dan tolak email sekali-pakai.

### ART-6. Kas & shift
- Transaksi **hanya** boleh terjadi bila ada shift terbuka di cabang itu.
- `uang_seharusnya = modal_awal + penerimaan tunai − pengeluaran tunai` (hitungan peladen).
- Selisih ≠ 0 **wajib** beralasan (tidak bisa disimpan tanpa alasan).
- Setelah shift ditutup: **beku** — koreksi berupa baris `kas_pergerakan` baru bertanda koreksi, bukan mengubah angka lama.
- Transaksi lewat tengah malam masuk **tanggal transaksi**, bukan tanggal tutup kas (PRD M8).

### ART-7. Cetak (ESC/POS) & perangkat
- Perintah cetak disusun di satu berkas (`lib/printer-escpos.ts`); bila ada perubahan, **uji cetak nyata** wajib diulang.
- Wajib ada **jalur cadangan**: tiket dapur tetap tampil di layar; struk bisa ditampilkan/dibagikan sebagai berkas.
- Jangan menganggap printer selalu siap: status printer harus terlihat di layar, dan kegagalan cetak **tidak boleh** membatalkan/menghilangkan pesanan.

### ART-8. Antrean offline & dobel data
- Semua penulisan dari antrean **wajib** membawa `kunci_idempoten`; peladen menolak duplikat dengan anggun (`on conflict do nothing` + balasan pesanan yang sudah ada).
- Jangan menampilkan "berhasil" untuk pesanan yang masih di antrean — status harus jujur ("menunggu terkirim").

### ART-9. Zona waktu & penomoran
- Simpan UTC; tampilkan per zona penyewa. Penomoran pesanan harian memakai zona penyewa (bukan UTC) — kalau salah, nomor pesanan bisa "melompat hari".
- Laporan harian memakai batas hari menurut zona penyewa.

### ART-10. Data pelanggan & privasi
- Jangan menyimpan lebih dari yang diperlukan; nomor HP/email hanya untuk voucher & pemulihan.
- Tampilkan persetujuan singkat saat pendaftaran voucher; ada cara menghapus data pelanggan (permintaan) tanpa menghapus catatan keuangan (anonymize).

### ART-11. Perangkat terdaftar & sesi (pencabutan seketika)
- **Aturan:** peran staf (kasir/pelayan/dapur/admin cabang/owner pusat) **wajib** memakai perangkat terdaftar (`perangkat.status = aktif`, `peran_diizinkan` cocok, ada sesi aktif di `sesi_perangkat` yang belum kedaluwarsa).
- **Pencabutan** (perangkat hilang/dicuri, pegawai berhenti, kecurigaan) **wajib** berlaku seketika: karena token akses yang sudah terbit tidak bisa ditarik, pemeriksaan perangkat/sesi **wajib** dilakukan di database pada setiap permintaan — dilarang hanya mengandalkan klaim JWT.
- **Bukti perangkat** (header → `current_setting('request.headers')`) adalah penguat tambahan; bila terbukti tidak andal di Supabase nyata, penegakan lewat `sesi_perangkat` tetap berlaku. Jangan menjadikan bukti perangkat sebagai satu-satunya penjaga tanpa membuktikannya lebih dulu.
- **Dilarang** menambah jalan pintas "perangkat sementara" tanpa persetujuan pemilik (lewat `DECISIONS_LOG.md`).
- **Uji wajib:** perangkat tidak terdaftar → tabel staf tertutup · cabut perangkat → permintaan berikutnya gagal · sesi lewat umur → ditolak · perangkat dengan peran lain → ditolak.

### ART-12. Identitas & cara masuk (satu akun satu peran)
- **Aturan:** satu akun = satu peran (di semua cabangnya); orang dengan dua fungsi memakai dua akun dengan **PIN berbeda**; PIN wajib **unik** antar pegawai dan bukan pola lemah.
- **Masuk:** staf = perangkat terdaftar + PIN 6 digit; admin cabang/owner pusat/pemilik platform = kata sandi ≥12 karakter + **TOTP wajib**; pelanggan = Google (utama) / email terverifikasi (kedua).
- **Pemulihan:** PIN staf direset admin/owner (izin `kelola_pegawai`, tercatat); MFA admin cabang direset owner pusat; MFA owner pusat direset pemilik platform. **Dilarang** menambah pemulihan mandiri lewat email untuk akun staf.
- **Dilarang:** PIN sebagai kunci enkripsi lokal, Edge Function yang menerbitkan sesi sendiri, atau memakai `user_metadata` untuk keputusan otorisasi.
- **Uji wajib:** PIN benar + perangkat tidak terdaftar = gagal · PIN salah = gagal + tercatat · PIN benar + perangkat terdaftar = berhasil · PIN kembar/lemah ditolak · admin tanpa TOTP tidak bisa masuk.

### ART-13. Jejak audit berantai
- **Aturan:** `catatan_audit` hanya-tambah (tidak ada hak ubah/hapus untuk siapa pun) + **rantai hash** (`hash_sebelumnya`, `hash_baris`) dihitung pemicu, bukan aplikasi.
- Semua tindakan sensitif **wajib** menulis catatan: void, diskon manual, ubah harga, buka laci tanpa transaksi, pakai voucher, perubahan pengaturan/izin/pegawai/PIN, pendaftaran & pencabutan perangkat, persetujuan PIN, mode dukungan, percobaan masuk.
- **Uji wajib:** mengubah satu baris → pemeriksa menunjuk baris itu; menghapus satu baris → rantai putus terdeteksi; penyisipan bersamaan tidak menghasilkan rantai bercabang.

### ART-14. Data pelanggan & privasi (UU PDP)
- **Aturan:** persetujuan eksplisit sebelum menyimpan; minimalisasi (nama, kontak opsional, catatan voucher); tidak ada NIK/lokasi/biometrik/pelacakan.
- Permintaan akses/hapus → **anonimisasi** data pribadi; catatan keuangan tetap utuh (Aturan Bisnis 11); tanggap 3×24 jam.
- Kebocoran → pemberitahuan tertulis ≤3×24 jam (subjek data + lembaga pengawas) memakai template `docs/teknis/BUKU_INSIDEN.md`.
- Laporan/email **dilarang** memuat kontak pelanggan.
- **Uji wajib:** pelanggan tanpa persetujuan ditolak; anonimisasi menghapus kontak tetapi tidak menghapus transaksi.

### ART-15. Mode dukungan pemilik platform
- **Aturan:** bawaan `pemilik_platform` **tidak** punya akses isi data penyewa; akses hanya lewat **mode dukungan**: wajib alasan, berbatas waktu (bawaan 60 menit), **hanya-baca**, tercatat di `catatan_audit`, dan **owner penyewa diberi tahu**.
- Mode berakhir otomatis (pg_cron) dan saat pemilik platform keluar; **dilarang** memberi hak mengubah data.
- **Uji wajib:** tanpa mode → 0 baris · dengan mode → perintah tulis ditolak · setelah kedaluwarsa → 0 baris lagi · catatan audit & pemberitahuan terkirim.

---

## 10. Batas gratis & rencana naik kelas (keputusan K6)

| Layanan | Batas gratis | Perkiraan Kedai Oasis | Peringatan otomatis | Bila mentok |
|---|---|---|---|---|
| Supabase data | 500 MB | ± 20–60 MB/tahun | 70% & 90% (pg_cron → email pemilik) | Pro $25/bln |
| Supabase foto | 1 GB | ± 150–400 MB (13 foto/menu) | 70% & 90% | rapikan/webp dulu, lalu Pro |
| Supabase lalu lintas | 5 GB/bln | < 1 GB | 70% & 90% | Pro |
| Supabase tidur | 7 hari tanpa aktivitas | kedai buka harian | **denyut harian** via pg_cron | bangunkan dari panel |
| Cloudflare | berkas statis tanpa batas | aman | — | — |
| Email | 3.000–9.000/bulan | < 300 | — | ganti penyedia (kode sudah bisa ditukar) |

---

## 11. Uji & Definisi Selesai (prinsip "tidak ada yang cacat")

1. **Uji SQL wajib** setiap migrasi: pemisahan penyewa & cabang (RLS), ketepatan hitungan uang (pajak/service/diskon/pembulatan), atomisitas voucher, larangan ubah `catatan_audit`.
2. **Uji unit** untuk fungsi hitung & pemformatan (Vitest).
3. **Uji ujung-ke-ujung (Playwright)** untuk 7 alur wajib: buka shift → pesan → kirim dapur → bayar → cetak → void berjenjang → tutup kas; ditambah alur voucher & katalog publik.
4. **Uji cetak nyata di Kedai Oasis** (risiko #1 PRD) sebelum gelombang berikutnya dimulai.
5. **Uji tampilan** memakai alat yang sudah ada: `prototipe/uji-kontras.py` (kontras & aturan desain) dan `prototipe/alat/periksa-halaman.py` — diperluas ke aplikasi.
6. **Definisi selesai satu fitur:** kode + migrasi + uji otomatis lulus + daftar uji terima manual ditulis + bahasa Indonesia + laporkan ke pemilik dalam bahasa sehari-hari.
7. **Aturan gelombang:** G2 tidak dimulai sebelum G1 lulus semua uji & dipakai harian tanpa masalah.
8. **Uji keamanan akun & perangkat** (baru 2026-09-17): peran × aksi (matriks) · perangkat tidak terdaftar ditolak · pencabutan seketika · sesi lewat umur · kunci percobaan masuk · PIN lemah/kembar · rantai audit · mode dukungan — daftar lengkap di `docs/KEAMANAN.md` §14.
9. **Uji kelengkapan UI** (baru 2026-09-17): setiap layar punya **kontrak layar** + **7 keadaan** wajib + **uji komponen** (jsdom + Testing Library) yang membuktikan setiap tombol memanggil RPC yang benar sesuai peran; pemeriksa `alat/peta-ui.py` menggagalkan CI bila ada aksi tanpa uji, RPC/izin yang tidak ada, layar tanpa berkas, dokumen peta basi, atau fitur PRD tanpa jejak layar.
10. **Uji peramban (Playwright) dijalankan di CI**, bukan di ruang kerja agent (Chromium tidak bisa diunduh di ruang kerja ini — sudah dicoba 2026-09-17); 9 alur wajib + naskah jalan pemilik bernomor (`W-<fase>-<nomor>`) untuk setiap tugas UI.

---

## 12. Yang masih perlu diputuskan/diketahui dari lapangan

| # | Hal | Kenapa penting | Cara mendapatkannya |
|---|---|---|---|
| 1 | Merek & tipe printer Kedai Oasis + cara menyambungnya | Menentukan ESC/POS Bluetooth vs USB; risiko #1 PRD | Tanya pengelola kedai |
| 2 | Daftar perangkat (Android/iPhone/komputer) | iPhone tidak mendukung Web Bluetooth → perlu jalur cadangan | Tanya pengelola kedai |
| 3 | Nilai pajak & service nyata, jumlah shift, jam operasional | Wajib untuk uji buka/tutup kas & laporan | Diisi saat penyiapan resto (sudah tercatat di PRD) |
| 4 | Nama produk platform | Dipakai sebagai nama aplikasi & domain | Pilihan: Langgan · Baraka · Sajian · Rame · Nota |
| 5 | Domain sendiri untuk email verifikasi | Beberapa penyedia email butuh domain (Resend bisa tanpa domain dengan batas terbatas) | Putuskan di Tahap 4 |
| 6 | Apakah semua pegawai punya email aktif | Masuk pegawai memakai email + PIN | Tanya saat penyiapan |
| 7 | **Region proyek Supabase** | Menentukan lokasi data pelanggan & dasar transfer UU PDP | **DIPUTUSKAN pemilik 2026-09-17: Singapore (Asia Tenggara)** — T-014 selesai |
| 8 | **Tablet Android yang dipakai untuk mode terkunci satu-aplikasi (kiosk)** | Menentukan langkah penyiapan perangkat di panduan pegawai | Ditulis agent sebagai panduan (tanpa biaya) — dicatat sebagai **T-015** |

---

## 13. Log Keputusan (Tahap 3 — putaran 1)

| Tanggal | Keputusan | Alasan |
|---|---|---|
| 2026-09-16 | **K1 = PWA** (aplikasi web terpasang), bukan aplikasi Android/iOS asli | Syarat "jalan di perangkat apa pun" + biaya nol; aplikasi asli bisa menyusul di fase 3 |
| 2026-09-16 | **K2 = Cloudflare (halaman aplikasi) + Supabase (data/akun)** | Satu-satunya kombinasi gratis yang **boleh dipakai untuk usaha**; Vercel Hobby dilarang untuk komersial |
| 2026-09-16 | **K3 = printer tersambung perangkat kasir** (Bluetooth/USB) + **cadangan digital wajib** | Paling murah & umum; risiko printer ditutup oleh jalur cadangan + uji nyata di Kedai Oasis |
| 2026-09-16 | **K4 = daring dulu + tahan gangguan kecil** (antrean lokal + kunci idempoten) | Sesuai kondisi pilot (internet lancar) tanpa mengorbankan keamanan data; offline penuh masuk fase 3 |
| 2026-09-16 | **K5 = email + PIN per pegawai; pelanggan Google (utama) + email terverifikasi** | Sesuai PRD; cepat di kasir; tanpa biaya SMS |
| 2026-09-16 | **K6 = bayar setelah ada pemasukan**, dengan peringatan otomatis 70% & 90% | Menjaga prinsip biaya nol tanpa jebakan mendadak |
| 2026-09-16 | **Urutan hitungan uang dikunci:** subtotal → diskon → PB1 → service → pembulatan (diskon dari subtotal; pajak & service dari subtotal setelah diskon) | Menghindari tafsir berbeda antar sesi (ART-3) |
| 2026-09-16 | **Teknologi aplikasi: React + Vite (SPA/PWA)**, bukan Next.js | Mengurangi lapisan & pemakaian fungsi Cloudflare; cukup untuk kebutuhan kasir/laporan; tetap memakai aturan React dari skill |
| 2026-09-16 | **Dokumen TECH_SPEC disetujui & DIKUNCI pemilik** (jawaban: "Ya, setuju") | Fondasi teknis resmi — sesi berikutnya berpedoman ke dokumen ini, bukan menebak ulang dari kode |
| 2026-09-16 | **Aturan perubahan dokumen:** apa pun yang menyentuh ART-1…ART-10 wajib lewat `DECISIONS_LOG.md` **dan** persetujuan pemilik dulu | Menjaga keputusan berisiko tinggi tidak diubah diam-diam oleh sesi berikutnya |
| 2026-09-17 | **Keamanan akun diperdalam (pesan pemilik ke-14)**: satu akun satu peran · perangkat terdaftar (kode + persetujuan pemilik) · masuk staf = perangkat + PIN 6 digit · TOTP wajib untuk 3 peran berkuasa + jalan pemulihan · kendali sesi dibuat sendiri · mode dukungan · privasi UU PDP · audit berantai. Rincian resmi pindah ke **`docs/KEAMANAN.md`**; ART baru: **ART-11…ART-15** | Pemilik meminta jeda sadar sebelum lanjut karena merasa keamanan belum dibahas sempurna (perangkat hilang, peran ganda, login satset); riset menunjukkan kendali sesi bawaan Supabase (time-box/inactivity/HIBP) ada di paket **Pro**, jadi kendali dibuat sendiri agar pencabutan berlaku seketika |
| 2026-09-17 | **Jawaban lanjutan pemilik**: kode pendaftaran perangkat diterbitkan **owner pusat & admin cabang (cabangnya)** · peran berkuasa **tetap wajib perangkat terdaftar** dengan **tangga pemulihan** saat perangkat hilang (kode pemulihan sekali pakai + masa tenggang 30 menit + jalur pemilik platform) · kunci otomatis mengikuti **jam aktif per cabang yang diatur owner** · region data **Singapore** · pemberitahuan lewat **email + dalam aplikasi** · **setiap penyimpangan teknis wajib ditanyakan dulu, dijelaskan bahasa sederhana, dan dicatat** | Kekhawatiran pemilik: *"kalau perangkat admin hilang atau dicuri, gimana solusinya? Itu harus dipikirkan"*; pemilik juga meminta agent tidak menyimpang diam-diam |
| 2026-09-17 | **Jalur pemulihan perangkat hilang DISETUJUI pemilik** ("setuju seperti rancangan"): tangga 4 tingkat · kode pemulihan hanya owner pusat · kode disimpan dalam **amplop tersegel dua salinan** (rumah pemilik + arsip kantor di luar ruang kasir) + rotasi · perangkat cadangan wajib | Menjawab kekhawatiran pemilik soal perangkat admin/owner hilang atau dicuri; penyimpanan kode diserahkan pemilik ke agent ("aku minta saran kamu") |
| 2026-09-17 | **Kelengkapan UI dijadikan gerbang otomatis**: Registri Aksi (satu sumber kebenaran tombol) + Peta Layar + kontrak layar + pemeriksa `alat/peta-ui.py` + uji komponen per layar + naskah jalan pemilik + DoD v2 | Pengalaman pemilik pada proyek sebelumnya: banyak tombol kurang dan fungsi "katanya ada" tapi tidak bisa dipakai, walaupun dokumen fondasi detail — penyebabnya tidak ada daftar tombol, tidak ada uji pemanggilan, dan "selesai" berarti "kode ditulis" |

| 2026-09-21 | **T-023:** §4.4 dan §5 menegaskan tanpa PIN pelanggan, bukan menghapus PIN pegawai/persetujuan. **T-025(a):** contoh alur §2 membatasi void sebelum pembayaran pertama | Pelaksanaan keputusan Lee setuju-semua; tidak menambah RPC/kolom atau mengubah ART baru |
