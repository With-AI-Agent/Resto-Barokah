# USULAN — Mematangkan Keamanan Akun/Perangkat & Kelengkapan Fitur–Layar–Tombol

> **Status: USULAN (belum berlaku).** Ditulis 2026-09-17 atas permintaan pemilik (pesan ke-14):
> *"kita belum diskusi soal keamanan dengan sempurna … mekanisme login terbaik dan teraman untuk setiap role …
> perangkat yang sudah ditentukan … jangan sampai perangkat kecurian lalu akunnya dipakai orang lain …
> dan kita juga harus rencanakan setiap fitur, fungsi, laman, UI, tombol-tombol secara lebih matang."*
>
> Pemilik meminta agent **tidak langsung meng-iya-kan**, tetapi berpikir & meriset mendalam, dan berani
> mengusulkan yang lebih baik. Naskah ini hasil riset itu. **Belum ada satu pun dokumen terkunci yang diubah.**
> Perubahan baru dikerjakan setelah pemilik memutuskan (lihat §E).
>
> Rujukan: `docs/PRD.md` (dikunci) · `docs/TECH_SPEC.md` (dikunci, §8 & ART-1…ART-10) · `docs/ROADMAP.md`
> (Fase 1 selesai 10/22) · `docs/DECISIONS_LOG.md` (7 entri Fase 1) · keterampilan yang dipakai:
> `skills/security-review`, `skills/supabase`, `skills/supabase-postgres-best-practices`, `skills/ui-ux-pro-max`,
> `skills/prd-taskmaster`, `skills/writing-plans`, `skills/verification-before-completion`.

---

## A. Ringkasan untuk pemilik (baca ini dulu)

**Yang Anda benar (dan memang bolong):**

1. **Login per peran belum pernah dibahas sungguh-sungguh.** Yang ada baru "email + PIN per pegawai"
   (TECH_SPEC §8.3, T2-02) — belum ada: apa yang membuat **kasir hanya bisa membuka kasir**, bagaimana
   **perangkat ditentukan**, bagaimana **perangkat hilang dicabut**, dan bagaimana **satu orang dua fungsi** dicatat.
2. **Perangkat hilang = masalah nyata** dan belum punya jawaban. Sekarang: sesi Supabase bisa dicabut,
   tapi **token akses yang sudah keluar tetap sah sampai kedaluwarsa** (dokumentasi Supabase; Supabase sendiri
   menyebut "tidak ada cara mencabut access token sebelum kedaluwarsa").
3. **Rencana fitur → layar → tombol memang belum punya mekanisme yang menahan kesalahan.** ROADMAP punya
   DoD per tugas, tapi belum ada yang memaksa **setiap tombol punya entri, setiap entri punya uji**.
4. **Sebagian sudah ada, jangan diulang:** T2-01…T2-12 (Supabase Auth, PIN, batas percobaan, sesi berakhir
   otomatis, PWA) sudah direncanakan. Yang kurang adalah **kekuatan yang mengikat** (perangkat, satu-akun-satu-peran,
   pencabutan seketika, matriks uji izin × tombol).

**Yang saya usulkan berbeda dari ide Anda (dan alasannya):**

| Ide Anda | Usulan saya | Alasan |
|---|---|---|
| Staff login "mudah tapi aman" | **PIN 6 digit = kredensial masuk, TAPI hanya sah di perangkat terdaftar**; login pertama di perangkat baru harus disetujui pemilik | PIN saja lemah; perangkat terdaftar saja lemah (perangkat kecurian). **Dua-duanya bersama** = kuat, dan tetap 2 detik untuk kasir (industri POS melakukan ini: "device code" Square, passcode kasir) |
| Satu orang dua fungsi → dua akun | **Setuju**, diperketat: satu akun = satu peran, di seluruh cabangnya. Izin (centang) tetap boleh beda per pegawai | Peran tunggal membuat RLS, laporan, dan jejak audit tidak ambigu; kalau tidak, "kasir yang juga pelayan" membingungkan siapa boleh apa |
| Staff hanya di perangkat tertentu | **Setuju**, dan ditegakkan **di database**, bukan di layar | Layar bisa dikakali; database tidak. Ditambah: sesi dicabut seketika saat perangkat hilang |
| Perangkat tidak boleh dipakai orang lain kalau kecurian | **Perangkat + PIN + kunci otomatis saat menganggur + pencabutan dari jauh + jejak perangkat** | Kalau perangkat kecurian tanpa PIN: tidak ada yang bisa dibuka. Ada PIN tapi sudah dilaporkan hilang: tercabut dalam hitungan detik. Keduanya jalan tanpa biaya |
| Rencanakan UI/tombol lebih matang | **Registri Aksi di kode + peta layar otomatis + pemeriksa CI + uji komponen per layar + naskah jalan untuk pemilik** | Ini yang membuat "tombol kurang / fungsi katanya ada tapi tak bisa dipakai" **tidak bisa lolos** — bukan sekadar niat, tapi diperiksa mesin |

**Batas jujur (ditemukan saat riset):**

- **Supabase gratis tidak punya** "time-box sesi", "batas menganggur", dan "satu sesi per pengguna" (itu Pro).
  Maka kendali sesi kita **buat sendiri** di tabel kita + kunci otomatis di aplikasi. Ini justru lebih baik karena
  pencabutan jadi **seketika**, tidak menunggu token kedaluwarsa.
- **Pemeriksa kata sandi bocor (HaveIBeenPwned) juga Pro.** Di paket gratis: kita pakai daftar larangan sendiri
  (PIN berurutan/berulang/tanggal lahir) + PIN wajib unik antar pegawai.
- **Peramban (Playwright) tidak bisa dipasang di ruang kerja ini** (sudah saya coba: unduhan Chromium diblokir).
  Di **GitHub Actions** hampir pasti bisa — akan dibuktikan, bukan diklaim. Selama itu, jaring utamanya:
  uji SQL (PGlite), uji komponen (jsdom), pemeriksa statis, dan naskah jalan manual.

---

## B. Bagian KEAMANAN — rancangan yang diusulkan (calon `docs/KEAMANAN.md`)

### B1. Peta ancaman (siapa menyerang apa)

| # | Ancaman nyata di kedai | Akibat bila dibiarkan | Kendali yang diusulkan |
|---|---|---|---|
| 1 | Kasir curang: void/diskon untuk teman, pembayaran "lunas" padahal uang tidak masuk | Uang bocor tanpa jejak | Izin berjenjang + PIN atasan + `catatan_audit` (sudah ada) + **peringatan harian ke owner** + rekonsiliasi QRIS |
| 2 | Pegawai berhenti, akun & PIN masih hidup | Mantan pegawai bisa masuk | **Nonaktifkan akun = sesi & perangkat dicabut seketika** + daftar simak offboarding |
| 3 | Tablet kasir ditinggal/ dicuri | Orang lain main aplikasi kasir | **Perangkat terdaftar + PIN + kunci otomatis**; tanpa PIN perangkat mati fungsi; dicabut dari jauh |
| 4 | PIN dilihat/ditebak (6 digit) | Akun pegawai dipakai orang lain | PIN wajib **unik antar pegawai**, larangan pola lemah, kunci 5×/15 menit per akun **dan** 12×/15 menit per perangkat, semua percobaan dicatat (sudah ada di 0006, diperluas ke login) |
| 5 | Pemilik PIN atasan dijebak: "PIN kamu berapa, biar aku yang approve" | Void besar lolos | PIN = rahasia pribadi (ditulis di panduan pegawai), laporan "siapa menyetujui apa", **peringatan bila 1 orang menyetujui terus-menerus** |
| 6 | Penyewa A mengintip data penyewa B | Kebocoran antar-usaha | RLS deny-by-default + **uji matriks otomatis per peran × tabel × aksi** (ditingkatkan dari uji per tabel) |
| 7 | Data pelanggan (nama/HP/email) bocor | Kena UU PDP: lapor 3×24 jam, denda administratif s.d. 2% pendapatan tahunan | Data seminimal mungkin, persetujuan eksplisit, enkripsi saat diam (bawaan Supabase), cadangan terenkripsi, **Buku Insiden** siap |
| 8 | Penyalahgunaan katalog/voucher publik (bot) | Kuota & anggaran kampanye habis | 10 lapis pengaman (sudah di PRD M10) + pembatasan per perangkat/IP + log percobaan |
| 9 | Kunci rahasia bocor (repo/HP) | Akses penuh | `service_role` **tidak pernah** di klien (sudah), pemeriksa rahasia di CI (ditambah), rotasi kunci terdokumentasi |
| 10 | Platform owner (Anda) mengintip data penyewa | Kehilangan kepercayaan | **Mode dukungan**: hanya dengan alasan, berbatas waktu, tercatat, + pemberitahuan ke owner resto |

### B2. Identitas & peran — "satu akun = satu fungsi"

- **Peran tetap 6** (tidak berubah). **Satu akun hanya punya satu peran**, berlaku di semua cabang yang ditugaskan.
  Pegawai merangkap peran → **dua akun** (persis usul Anda) dengan **PIN berbeda**.
- `pengguna_cabang` disederhanakan menjadi **daftar cabang tempat peran itu berlaku** (kolom peran per cabang dihapus).
  Alasan: aturan "peran tunggal" harus tidak bisa dilanggar diam-diam oleh tabel lain.
  → Berdampak ke migrasi `0002` → ditambah migrasi baru + `DECISIONS_LOG.md` + uji (bukan mengubah berkas lama).
- **Izin (centang) tetap boleh berbeda per pegawai** — itu penyetelan halus di dalam satu peran
  (mis. kasir A boleh `lihat_laporan`, kasir B tidak), bukan peran kedua.
- Pemilik platform (`pemilik_platform`) **tidak punya akses isi transaksi** penyewa; hanya daftar penyewa + status,
  kecuali **mode dukungan** (§B8).

### B3. Perangkat terdaftar (device binding) — inti jawaban "perangkat yang ditentukan"

Tabel baru (calon migrasi `0011_perangkat.sql`):

| Tabel | Isi penting |
|---|---|
| `perangkat` | `id`, `penyewa_id`, `cabang_id`, `nama` ("Tablet Kasir 1"), `jenis`, `peran_diizinkan` (mis. hanya `kasir`), `rahasia_hash` (SHA-256 dari rahasia acak 32 byte), `status` (aktif/dicabut/hilang), `terakhir_aktif`, `terdaftar_oleh`, `dicabut_oleh`, `catatan` |
| `kode_pendaftaran_perangkat` | kode sekali pakai (masa berlaku 15 menit), dibuat admin/owner, dipakai → jadi baris `perangkat` |
| `sesi_perangkat` | `session_id` (dari token Supabase), `perangkat_id`, `pengguna_id`, `mulai`, `berakhir_pada`, `status` (aktif/selesai/dicabut) |
| `percobaan_masuk` | semua percobaan masuk (berhasil/gagal/diblokir) + akun + perangkat + sebab — dasar kunci 5×/15 menit |

Alur:
1. **Owner/admin membuat kode pendaftaran** di layar "Perangkat" → muncul kode/QR.
2. Di perangkat baru, pegawai memasukkan kode → perangkat mengirim identitas + rahasia acak → server menyimpan **hash**-nya.
3. Perangkat itu hanya boleh untuk peran yang dicentang (`peran_diizinkan`). "Tablet Kasir 1" tidak bisa dipakai masuk sebagai owner.
4. **Setiap permintaan** menyertakan bukti perangkat; fungsi `perangkat_sah()` memeriksa: perangkat aktif,
   sesi aktif & belum kedaluwarsa, pengguna aktif, peran cocok, dan (opsional kuat) **hash rahasia perangkat cocok**.
5. **Pencabutan seketika**: owner menekan "Cabut perangkat" → semua permintaan dari perangkat itu **ditolak di database**
   pada detik itu juga (tidak menunggu token kedaluwarsa). Buku: siapa mencabut, kapan, alasan.

Catatan teknis (untuk agent sesi berikutnya):
- Pemeriksaan bukti perangkat memakai header permintaan (`current_setting('request.headers')` → cara resmi PostgREST),
  dan **wajib dibuktikan di Supabase nyata** (T0-08) sebelum dijadikan syarat tunggal. Bila header tidak andal,
  jaring pengamannya tetap kuat: `sesi_perangkat` + perangkat aktif dicek tiap permintaan (tanpa header).
- Setiap fungsi RLS baru **wajib** `stable`, `search_path` dipaku, dan dipanggil `(select public.perangkat_sah())`
  supaya tidak dievaluasi ulang per baris (aturan skill `supabase-postgres-best-practices`).
- **Fungsi `SECURITY DEFINER` wajib** `revoke execute from public` + `grant` eksplisit (sudah jadi kebiasaan di
  migrasi 0001–0010; akan **dijadikan pemeriksa otomatis**, bukan ingatan).

### B4. Masuk cepat tapi aman (menjawab "satset")

| Peran | Cara masuk | Kenapa |
|---|---|---|
| **Kasir · Pelayan · Dapur** | **Pilih nama → PIN 6 digit** — hanya di perangkat terdaftar | Tidak ada kata sandi tertulis di meja kasir; 2 detik; perangkat menahan penyalahgunaan |
| **Admin Cabang** | Kata sandi (≥12 karakter) + **TOTP opsional** + perangkat terdaftar | Bisa mengelola uang & pegawai |
| **Owner Pusat** | Kata sandi + **TOTP** (disarankan wajib) | Akar kepercayaan restonya |
| **Pemilik Platform (Anda)** | Kata sandi + **TOTP wajib** | Satu akun ini menyentuh semua penyewa |
| **Pelanggan** | Google (utama) / email terverifikasi (kedua) — **tanpa** pengikatan perangkat | Mereka memakai HP sendiri |

- **PIN bukan kata sandi biasa:** PIN hanya sah bersama perangkat terdaftar, jadi menebak PIN dari luar tidak ada gunanya
  (tanpa rahasia perangkat, sesi tidak bisa diikat → RLS menolak semua tabel staf).
- **PIN tidak pernah dipakai sebagai kunci enkripsi lokal** (ide yang sengaja ditolak): PIN 6 digit bisa dibobol
  secara luring dari perangkat curian. Yang dipakai: verifikasi PIN **di peladen** + perangkat.
- **Login kustom (Edge Function yang menerbitkan sesi sendiri) ditolak**: menambah jalur rahasia baru yang harus
  dijaga sempurna; paket gratis sudah cukup dengan cara di atas.
- **Lupa PIN:** direset admin/owner (wajib izin `kelola_pegawai`), tercatat, dan PIN baru wajib unik + bukan pola lemah.
  Tidak ada pemulihan lewat email untuk staf (menutup pintu pengambilalihan akun lewat email).

### B5. Sesi, kunci otomatis, dan pencabutan

| Kendali | Nilai usulan | Penegak |
|---|---|---|
| Umur token akses | 15 menit (dapat diatur di Supabase, gratis) | Supabase |
| **Kunci otomatis saat menganggur** | Kasir/pelayan/dapur 15 menit · admin 30 menit · owner/platform 60 menit; tombol "Kunci sekarang" selalu ada | Aplikasi (+ aturan di dokumen) |
| Kunci = apa | **Sesi dihapus dari perangkat**, buka lagi wajib PIN/kata sandi | Aplikasi |
| **Umur maksimum sesi** | Staf 12 jam (satu shift) · admin/owner 30 hari · platform 8 jam | Database (`sesi_perangkat.berakhir_pada`) |
| Batas percobaan masuk | 5×/15 menit per akun · 12×/15 menit per perangkat · semua dicatat | Database (perluasan 0006) |
| Pencabutan | Per perangkat · per akun · semua perangkat; seketika untuk permintaan baru | Database + RPC |
| Sesi saat internet mati | Tetap jalan (pesanan masuk antrean); setelah terkunci, butuh internet untuk buka lagi | Aplikasi + `ART-8` |

### B6. Uang & kecurangan operasional (kontrol tambahan)

1. **Rekonsiliasi non-tunai wajib**: setiap pembayaran non-tunai menyimpan `referensi` (sudah ada); layar tutup kas
   menampilkan **daftar referensi** agar owner mencocokkan dengan aplikasi QRIS/bank.
2. **Ringkasan peringatan harian ke owner** (1 email/hari, gratis): total omzet, void, diskon, selisih kas,
   percobaan masuk gagal, perubahan perangkat. Kecurangan kecil jadi terlihat tanpa owner harus membuka laporan.
3. **Void & diskon** tetap berjenjang (sudah dikunci di T1-10) + **laporan siapa menyetujui apa** per bulan.
4. **Buka laci tanpa transaksi** wajib izin + alasan (sudah di rencana) — dan hanya dari perangkat kasir terdaftar.

### B7. Jejak audit yang tidak bisa diakali

- `catatan_audit` hanya-tambah (sudah dikunci) + **rantai hash** (setiap baris menyimpan hash baris sebelumnya):
  kalau ada yang mengubah/menghapus satu baris, **rantai putus** dan pemeriksa akan menunjukkannya.
  Biaya kecil, nilainya besar: bukti utuh untuk sengketa uang.
- Pemeriksa otomatis: `alat/periksa-audit.py` (verifikasi rantai + laporan bila putus) dijalankan terjadwal.

### B8. Privasi pelanggan & UU PDP (Indonesia, UU 27/2022)

- **Dasar hukum: persetujuan eksplisit** saat pendaftaran voucher (kotak centang + kalimat singkat: apa yang disimpan,
  untuk apa, berapa lama, bagaimana minta dihapus).
- **Data seminimal mungkin**: nama, kontak, catatan voucher. Tidak ada NIK, tidak ada lokasi, tidak ada biometrik.
- **Hak pelanggan**: minta salinan/hapus → data pelanggan di-*anonimkan* (catatan keuangan tidak dihapus — Aturan Bisnis 11).
- **Kebocoran**: lapor **3×24 jam** ke subjek data + lembaga pengawas → langkah-langkahnya ada di **Buku Insiden**.
- **Lokasi data**: Supabase region dipilih saat T0-08 (usul: Singapore, terdekat & sah untuk transfer lintas negara
  dengan pengamanan); dicatat sebagai butir tertangguh T-014 (keputusan pemilik).
- **Mode dukungan** (platform owner): alasan + batas waktu (mis. 60 menit) + tercatat di `catatan_audit`
  + pemberitahuan ke owner penyewa.

### B9. Operasional & pemulihan (yang murah tapi sering terlupa)

- **Daftar simak offboarding**: nonaktifkan akun → cabut perangkat pribadi bila ada → ganti PIN → periksa jejak 30 hari.
- **Buku Insiden** (`docs/teknis/BUKU_INSIDEN.md`, bahasa manusia): perangkat hilang · akun diduga dibobol ·
  data bocor · batas gratis terlampaui · Supabase "tidur" · internet kedai mati · printer bermasalah ·
  cadangan gagal. Setiap bab: **tanda-tanda · langkah berurutan · siapa yang memberitahu siapa**.
- **Latihan pemulihan cadangan** minimal sekali sebelum pilot (bukti bahwa cadangan benar-benar bisa dipulihkan).
- **Kebiasaan perangkat (fisik)**: setiap tablet punya slot/nomor di bilik pengisian, dicek saat tutup kedai,
  mode "sekunci layar" (kiosk/guided access) untuk tablet yang hanya untuk satu fungsi, layar terkunci saat ditinggal.
- **Pemeriksa CI tambahan**: rahasia tidak masuk repo · `npm audit` · kunci paket dipaku (`package-lock`).

### B10. Matriks uji keamanan (yang akan dibuat, bukan dijanjikan)

| Uji | Bentuk | Dijalankan |
|---|---|---|
| Isolasi penyewa & cabang, semua tabel | SQL otomatis | sudah ada, ditingkatkan: **per peran × tabel × operasi** |
| Perangkat tidak terdaftar → semua tabel staf tertutup | SQL otomatis | baru (Fase 1B) |
| Cabut perangkat → permintaan berikutnya gagal dalam detik yang sama | SQL otomatis | baru |
| Sesi kedaluwarsa (umur maksimum) → ditolak | SQL otomatis | baru |
| Kunci 5×/15 menit & 12×/15 menit | SQL otomatis | perluasan uji 0006 |
| PIN lemah & PIN kembar ditolak | SQL otomatis | baru |
| Rantai audit utuh; perubahan baris terdeteksi | SQL otomatis | baru |
| Setiap tombol → aksi izin benar; peran tanpa izin **tidak bisa** walau RPC dipanggil langsung | Uji komponen + SQL | baru (Bagian C) |
| Replay kunci idempoten (dobel simpan/bayar) | SQL otomatis | sudah ada, ditambah pembayaran |

---

## C. Bagian KELENGKAPAN — mekanisme agar "tombol kurang / fungsi palsu" tidak bisa lolos

### C1. Akar masalah dari pengalaman Anda sebelumnya (jujur, ini bukan soal AI-nya)

Aplikasi yang dibangun cepat dengan agent biasanya gagal di enam titik ini — dan keenamnya bisa ditutup mekanisme:

1. **Spesifikasi → kode: ada jarak.** Dokumen menulis fitur; kode menafsir. → ditutup **kontrak layar** (§C3).
2. **Tidak ada daftar tombol.** Tombol "yang penting ada" → ada tombol tanpa fungsi. → ditutup **Registri Aksi** (§C2).
3. **"Selesai" = kode ditulis**, bukan "bisa dipakai". → ditutup **DoD v2** (§C6).
4. **Data contoh menyembunyikan kegagalan** (di demo jalan, di data asli error). → ditutup **data uji/seed yang sama dengan uji**.
5. **Tidak ada yang mencoba tombol itu** sampai pemilik menemukannya sendiri. → ditutup **uji komponen per layar** + **naskah jalan** (§C5).
6. **Perubahan dokumen tidak ikut berubah di kode** (drift). → ditutup **pemeriksa otomatis di CI** yang membandingkan dokumen ↔ kode.

### C2. Registri Aksi (di kode, satu-satunya sumber kebenaran tombol)

`aplikasi/src/lib/aksi.ts` — setiap aksi (tombol/menu/gestur) punya satu entri:

```
id: 'kasir.bayar'
label: 'Bayar'
layar: 'kasir'
peran: ['kasir', 'admin_cabang', 'owner_pusat']
izin: null                    // atau 'beri_diskon' dsb.
rpc: 'bayar_pesanan'          // nama fungsi peladen
jenis: 'tulis'
konfirmasi: 'Uang sudah diterima lengkap?'
pin: false / true
audit: true
sukses: 'Pembayaran tercatat. Kembalian Rp …'
gagal: { 'BY-201': 'Uang diterima kurang dari total' }
uji: ['kasir.bayar.tunai', 'kasir.bayar.kurang']
```

- **Semua tombol dirender** lewat komponen `<TombolAksi id="…" />`. Tombol tanpa entri **tidak bisa dirender**
  (langsung ketahuan saat pembangunan, bukan saat pemilik memakainya).
- Peran tanpa izin: tombol **disembunyikan** atau **ditampilkan nonaktif + alasan** (dipilih per aksi, ditulis di entri).
- Aksi uang **wajib** `audit: true` dan **wajib** punya ≥1 uji.
- Aksi yang butuh PIN **wajib** deklarasikan; alur PIN jadi seragam di seluruh aplikasi (tidak ada layar yang "lupa" minta PIN).

### C3. Peta Layar & Kontrak Layar

`aplikasi/src/lib/layar.ts` — daftar layar: id, rute, judul, peran yang boleh, izin, dan **7 keadaan wajib**.

**Kontrak layar** (template, satu tabel per layar di `docs/SPESIFIKASI_UI.md`):

| Bagian | Isi wajib |
|---|---|
| Tujuan | Satu kalimat: untuk siapa, menyelesaikan apa |
| Masuk dari mana | Tombol/tautan yang menuju layar ini (harus ada minimal satu) |
| Data yang tampil | Kolom/angka/kartu — dan dari RPC/tabel mana |
| Aksi | Semua entri Registri Aksi layar ini |
| **7 keadaan** | Kosong · Memuat · Gagal(+coba lagi) · Menunggu terkirim (antrean) · Tidak punya akses · Data sebagian · Berhasil |
| Aturan tampilan | Target sentuh ≥44 px, kontras, teks Indonesia, tanpa angka uang dari klien |
| Bukti | Uji komponen mana yang membuktikan · nomor naskah jalan pemilik |

### C4. Pemeriksa otomatis (gerbang CI, bukan ingatan)

`alat/peta-ui.py` men-generate `docs/PETA_UI.md` dari `aksi.ts` + `layar.ts`, dan **CI gagal** bila salah satu ini tidak terpenuhi:

1. Aksi menunjuk RPC yang **tidak ada** di migrasi → gagal.
2. Aksi menunjuk kode izin yang **tidak ada** di `izin_kode` → gagal.
3. Aksi **tanpa uji** (id uji tidak ditemukan di berkas uji) → gagal.
4. Layar tanpa berkas / rute tak terjangkau peran mana pun → gagal.
5. `docs/PETA_UI.md` **berbeda** dengan hasil generate (dokumen basi) → gagal.
6. Fitur PRD M1–M12 tanpa layar/aksi → gagal (jejak dua arah: fitur ↔ layar ↔ aksi ↔ uji).

### C5. Bukti bahwa tombol benar-benar bekerja

- **Uji komponen (jsdom + Testing Library)** untuk setiap layar: dirender per peran, lalu diperiksa —
  tombol ada/tidak ada sesuai izin · klik memanggil RPC yang benar (ditiru) · keadaan kosong/memuat/gagal/antrean tampil ·
  pesan berhasil/gagal sesuai kontrak · tombol nonaktif menampilkan alasan. **Ini bisa dijalankan di ruang kerja ini.**
- **Uji peramban (Playwright) di GitHub Actions** untuk 9 alur wajib (buka shift → pesan → dapur → bayar → cetak →
  void → tutup kas + voucher + katalog). Di ruang kerja ini Chromium tidak bisa diunduh (sudah dicoba) — akan
  dibuktikan di CI, dan kalau ternyata gagal, dilaporkan jujur lalu dicari penggantinya.
- **Naskah jalan untuk pemilik** (bahasa manusia, bernomor `W-<fase>-<nomor>`): *"Tekan ini → harus muncul itu"*,
  dijalankan di pratinjau dengan data contoh. Setiap tugas UI di ROADMAP **wajib** mencantumkan nomor naskah jalan-nya.
- **Uji mutasi** (kebiasaan Fase 1, diteruskan): matikan satu aturan → uji wajib MERAH. Kalau tetap hijau, ujinya lemah.

### C6. Definisi Selesai versi baru (untuk tugas UI)

Sebuah tugas layar/fitur hanya `[x]` bila **semua** ini benar:
kontrak layar ditulis · semua aksi terdaftar · 7 keadaan tertangani · uji komponen hijau · pemeriksa peta-UI hijau ·
naskah jalan ditulis & dijalankan di pratinjau · izin dicek di **database** (bukan hanya sembunyi di layar) ·
`DECISIONS_LOG` bila menyentuh uang/keamanan/data pelanggan.

---

## D. Dampak ke dokumen fondasi & ROADMAP (rencana perubahan)

| Dokumen | Perubahan yang diusulkan |
|---|---|
| `docs/PRD.md` | **M12 diperdalam**: perangkat terdaftar, satu akun satu peran, masuk cepat PIN, pencabutan sesi, kunci otomatis, laporan peringatan harian; **aturan bisnis baru** (perangkat wajib untuk peran staf; PIN unik; nonaktif = cabut; mode dukungan) ; **§9 risiko** + risiko "perangkat hilang"; **§10/§11** disesuaikan |
| `docs/TECH_SPEC.md` | **§4**: tambah `perangkat`, `kode_pendaftaran_perangkat`, `sesi_perangkat`, `percobaan_masuk`; peran tunggal; **§5**: RPC baru (`daftarkan_perangkat`, `ikat_sesi_perangkat`, `cabut_perangkat`, `daftar_perangkat`, `verifikasi_masuk`, `mulai_mode_dukungan`); **§8 ditulis ulang** (menjadi ringkasan rujukan ke `docs/KEAMANAN.md`); **§9**: **ART-11 (perangkat & sesi)**, **ART-12 (identitas & peran tunggal)**, **ART-13 (jejak audit berantai)**, **ART-14 (privasi pelanggan/UU PDP)**, **ART-15 (mode dukungan)**; **§11** uji + Playwright di CI |
| `docs/KEAMANAN.md` **(baru)** | Isi Bagian B naskah ini, versi final |
| `docs/SPESIFIKASI_UI.md` **(baru)** | Aturan kelengkapan + kontrak layar (template §C3) + peta peran→layar |
| `docs/PETA_UI.md` **(baru, hasil generate)** | Daftar layar & aksi (dibuat mesin; dilarang disunting tangan) |
| `docs/teknis/BUKU_INSIDEN.md` **(baru)** | 8 bab insiden + langkah + siapa memberitahu siapa + tenggat UU PDP |
| `docs/ROADMAP.md` | **Fase 1B baru** (T1-23…T1-30: perangkat, sesi, RLS diperketat, `catatan_audit` + rantai hash, kunci percobaan masuk, mode dukungan, uji matriks izin, uji keamanan perangkat) · **Fase 1C baru** (T1-31…T1-35: peta layar, registri aksi, pemeriksa CI, harness uji komponen, format naskah jalan) · **Fase 2 diperluas** (T2-13…T2-19: TOTP, pendaftaran perangkat, masuk PIN, kunci otomatis, daftar & cabut perangkat, persetujuan perangkat baru, uji masuk 6 peran) · **Fase 10/11** ditambah (mode dukungan, rantai audit, pemeriksa rahasia/`npm audit`, latihan pemulihan, Playwright di CI) · DoD tugas UI mengikuti §C6 |
| `docs/AGENT_OPERATING_GUIDE.md` | §5 uji (uji komponen + peta UI) · §7 DoD v2 · §11 daftar dokumen fondasi bertambah · §12 stop condition keamanan akun/perangkat · §13 butir tertangguh baru |
| `docs/DECISIONS_LOG.md` | Satu entri per keputusan yang disetujui (perangkat, peran tunggal, sesi, privasi, registri aksi) |
| `docs/TERTANGGUH.md` | **T-014** region Supabase (pemilik) · **T-015** panduan mode kiosk untuk tablet Android (agent) |
| `docs/desain/RENCANA_DESAIN_UI.md` | Rujukan ke §C2–C6 (registri aksi & 7 keadaan), tanpa mengubah keputusan desain v3 |

**Urutan kerja yang saya usulkan (penting):** Fase 1 **berhenti di T1-10** (sudah di titik bersih ini), lalu
**Fase 1B → Fase 1C → baru lanjut T1-11 dst.** Alasan: pola RLS & kerangka layar akan dipakai oleh seluruh
migrasi/layar berikutnya; kalau urutannya dibalik, kita harus membongkar dua kali.

---

## E. Keputusan yang diminta dari pemilik

1. **Masuk staf**: PIN 6 digit hanya sah di perangkat terdaftar (rekomendasi) / kata sandi panjang + PIN hanya untuk menyetujui aksi / lainnya.
2. **Kekuatan perangkat**: kode pendaftaran oleh admin + **persetujuan pemilik saat pegawai pertama kali memakai perangkat itu** (rekomendasi) / cukup kode pendaftaran saja / semua perangkat butuh persetujuan tiap kali masuk.
3. **Satu akun satu peran** (dua akun untuk dua fungsi) — setuju / setuju tapi peran boleh ganda dalam satu akun / lainnya.
4. **TOTP (Google Authenticator)**: wajib untuk Pemilik Platform + owner, opsional admin (rekomendasi) / wajib untuk owner & admin juga / tanpa TOTP.
5. **Mode dukungan platform owner**: berbatas waktu + beralasan + tercatat + memberi tahu owner resto (rekomendasi) / platform owner bebas melihat / tidak boleh sama sekali.
6. **Rencana perubahan dokumen & 2 fase baru (§D + urutan kerja)** — disetujui / disetujui sebagian (sebutkan) / ubah dulu.

Setelah jawaban: setiap keputusan ditulis di `docs/DECISIONS_LOG.md`, dokumen fondasi ditulis ulang,
ROADMAP disusun ulang, pemeriksa baru dibuat & dibuktikan bisa MERAH, lalu batch pertama Fase 1B dikerjakan.
