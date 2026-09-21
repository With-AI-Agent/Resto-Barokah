# KONTRAK PRIVASI PELANGGAN — Resto Barokah

> **Status: DRAF** — belum mengikat apa pun, belum diimplementasikan apa pun.
> Ditulis untuk ditinjau Lee **sebelum data pelanggan pertama masuk** (gerbang itu tercatat di
> `docs/TERTANGGUH.md` butir T-011). Bagian yang belum Lee putuskan ditandai
> `TODO(keputusan Lee)` — sengaja dibiarkan terbuka, bukan diarang.
>
> **Asal tugas:** temuan audit **F F-09** — "Kontrak privasi pelanggan belum punya jalur
> implementasi" (`docs/uji/AUDIT_RIWAYAT.md` §1c, status TERBUKA, pemilik `T8-01` Fase 8).
> Ditulis pekerja maraton T-03 (cabang `arena/01a0c1d7-resto-barokah`, 2026-09-21, alur AL-16
> di `docs/ops/PAPAN_TUGAS.md`).
>
> **Cara baca:** setiap bagian ditutup baris **Sumber** — rujukan ke berkas repo yang jadi
> dasarnya. Tidak ada mekanisme yang dikarang: yang di sini hanyalah yang sudah tertulis di
> berkas-berkas itu, ditambah penanda TODO untuk yang memang belum diputuskan.

---

## 0. Keadaan jujur hari ini (sebelum kontraknya)

- **Fitur pelanggan belum dibangun.** Migrasi yang hidup saat ini (`supabase/migrations/`,
  nomor 0001–0019) **belum punya tabel pelanggan apa pun** — tidak ada `pelanggan`,
  `kampanye_voucher`, `voucher`, atau `voucher_percobaan`. Tabel-tabel itu baru **rencana** di
  `docs/TECH_SPEC.md` §4.4, dan tugasnya (Fase 8, `T8-01`…`T8-15` di `docs/ROADMAP.md`)
  masih terbuka semua.
- **Konsekuensinya: sampai hari ini belum ada data pelanggan siapa pun yang tersimpan**
  (`docs/TERTANGGUH.md` T-011: "sekarang belum ada data siapa pun").
- Jadi kontrak ini adalah **aturan main yang disepakati lebih dulu**: apa yang BAKAL
  dikumpulkan, untuk apa, selama apa, dan apa hak pelanggan — supaya saat Fase 8 dibangun,
  kodenya mengikuti kontrak, bukan sebaliknya.
- **Cakupan dokumen: data pelanggan saja.** Data pegawai (akun, PIN, perangkat) dan data
  usaha pemilik resto (tabel `penyewa`/`cabang` di `supabase/migrations/0001_penyewa_cabang.sql`,
  termasuk nomor telepon usaha di sana) **di luar dokumen ini** — keduanya diatur
  `docs/KEAMANAN.md`.

**Sumber:** `supabase/migrations/` (0001–0019) · `docs/TECH_SPEC.md` §4.4 · `docs/ROADMAP.md` Fase 8 · `docs/uji/AUDIT_RIWAYAT.md` §1c (F F-09) · `docs/TERTANGGUH.md` (T-011)

---

## 1. Data apa yang dikumpulkan & diproses

Setelah Fase 8 (katalog pelanggan + voucher undang-teman) dibangun, data yang tersimpan per
pelanggan adalah — sesuai rancangan `docs/TECH_SPEC.md` §4.4:

| Data | Keterangan | Sifat |
|---|---|---|
| Nama | diisi saat pendaftaran voucher | wajib |
| Email | dipakai verifikasi & pemulihan | wajib, kecuali jalur didaftarkan kasir |
| Nomor HP | **opsional** — hanya bila pelanggan mau poin/voucher | opsional |
| Alamat | diisi saat pendaftaran | opsional |
| Cara masuk | Google (utama) atau email terverifikasi (jalur kedua) | teknis |
| Waktu verifikasi + siapa mendaftarkan | bila kasir yang mendaftarkan (pelanggan tanpa email & tidak mau Google), tercatat siapa yang mendaftarkan | teknis |
| Voucher + riwayat pemakaian | kode voucher (acak, unik), status, kapan/di mana dipakai | wajib untuk fitur |
| Log percobaan cek/scan voucher | kode yang dicoba, hasilnya, kasir & perangkat yang mencoba | log keamanan |

**Jalur pengumpulannya** (`docs/PRD.md` M10): tautan kampanye → halaman pendaftaran → isi nama,
alamat (opsional), nomor HP/email → verifikasi → kode voucher muncul. Verifikasi memakai
**"Daftar dengan Google" sebagai jalur utama** + email terverifikasi (lewat penyedia gratis
Resend/Mailjet/Brevo, **bukan** email bawaan Supabase) dan **tanpa SMS** (`docs/DISCOVERY.md`
butir 98 & keputusan 12).

**Yang diproses saat pakai voucher:** kasir menekan **Cek** (hanya membaca, tidak mengubah apa
pun) lalu **Pakai** (sekali pakai, wajib PIN kasir/atasan, tercatat). Semua percobaan cek/scan
dicatat (`voucher_percobaan` di `docs/TECH_SPEC.md` §4.4) — itu pengaman anti-kecurangan,
bukan pelacakan pelanggan.

**Yang TIDAK akan disimpan** — dibatasi tegas oleh aturan yang sudah dikunci:
**tidak ada NIK, tidak ada lokasi, tidak ada data biometrik, tidak ada pelacakan**
(`docs/KEAMANAN.md` §11 "Minimalisasi"; `docs/TECH_SPEC.md` ART-14; keputusan di
`docs/DECISIONS_LOG.md` 2026-09-17). Kontak dipakai **hanya** untuk voucher & pemulihan
(`docs/TECH_SPEC.md` ART-10).

**Di mana datanya:** region proyek Supabase = **Singapore (Asia Tenggara)** — diputuskan Lee
2026-09-17 (T-014 selesai; `docs/KEAMANAN.md` §11, `docs/TECH_SPEC.md` §12).

**Sumber:** `docs/TECH_SPEC.md` §4.4 + ART-10 + ART-14 + §12 · `docs/PRD.md` M10 + §8 (Aturan Bisnis 3) · `docs/DISCOVERY.md` (butir 98, keputusan 12) · `docs/KEAMANAN.md` §11 · `docs/DECISIONS_LOG.md` (2026-09-17, "Privasi pelanggan & UU PDP") · `docs/TERTANGGUH.md` (T-014)

---

## 2. Dasar hukum & tujuan

**Dasar hukum:** kepatuhan **UU PDP (UU 27/2022)** — proyek ini menyimpan data pelanggan
(voucher undang-teman), jadi kewajibannya berlaku **sejak pilot**, bukan "nanti". Ancaman
yang diukur terbuka: denda administratif s.d. 2% pendapatan tahunan + risiko pidana
(`docs/PRD.md` §9 risiko #10; alasan di `docs/DECISIONS_LOG.md` 2026-09-17).

**Dasar pemrosesan: persetujuan eksplisit sebelum data disimpan.** Aturan yang sudah dikunci:

- Kalimat persetujuan **singkat + tautan kebijakan** tampil di halaman pendaftaran voucher —
  bukan centang tersembunyi (`docs/KEAMANAN.md` §11; `docs/PRD.md` §10.7).
- Kalimat itu wajib menyebut **apa yang disimpan, untuk apa, berapa lama, dan cara minta
  dihapus** (`docs/DECISIONS_LOG.md` 2026-09-17).
- Pendaftaran **tanpa persetujuan ditolak di database**, bukan cuma di tombol
  (`docs/ROADMAP.md` T8-15, mitigasi risiko).

**Tujuan (sempit, persis seperti tercatat):**

1. **Kampanye voucher undang-teman** — diskon terdaftar, satu voucher per identitas per
   kampanye (`docs/PRD.md` M10).
2. **Pemulihan** — pelanggan lupa PIN → pemulihan lewat email (`docs/PRD.md` M10 kasus tepi).
3. Kontak **hanya** untuk voucher & pemulihan — tidak untuk hal lain
   (`docs/TECH_SPEC.md` ART-10).

**Transfer lintas wilayah:** data disimpan di Singapore (luar Indonesia); dasar transfernya
**persetujuan + pengamanan penyedia** — sudah diputuskan Lee 2026-09-17
(`docs/KEAMANAN.md` §11; `docs/TERTANGGUH.md` T-014).

> `TODO(keputusan Lee)` — **kalimat persetujuan akhirnya belum ada di berkas mana pun.**
> DRAF ini adalah bahan untuk kalimat itu (butir tertangguh T-011: agent menyiapkan draf,
> pemilik meninjau sebelum data pelanggan pertama masuk). Selesai ditulis & disetujui Lee,
> kalimatnya akan jadi bagian halaman pendaftaran (tugas `T8-06`/`T8-07` Fase 8).

**Sumber:** `docs/KEAMANAN.md` §11 · `docs/DECISIONS_LOG.md` (2026-09-17) · `docs/PRD.md` §9 (#10) + §10.7 + M10 · `docs/TECH_SPEC.md` ART-10 + §12 · `docs/ROADMAP.md` T8-06/T8-07/T8-15 · `docs/TERTANGGUH.md` (T-011, T-014)

---

## 3. Masa simpan

- **Catatan keuangan (transaksi, pembayaran, voucher terpakai):** **tidak ada penghapusan
  permanen** oleh pengguna; koreksi selalu dicatat sebagai pencatatan baru
  (`docs/PRD.md` §8 Aturan Bisnis 11; pola "hanya-tambah" seperti `catatan_audit` di
  `docs/TECH_SPEC.md` §4.3). Artinya catatan keuangan bertahan sepanjang data berada di sistem.
- **Cadangan:** cadangan `pg_dump` mingguan, terenkripsi, disimpan di luar basis data dengan
  **masa simpan 90 hari** (artefak terenkripsi repo privat + salinan bulanan milik Lee)
  (`docs/DECISIONS_LOG.md` 2026-09-16; `docs/TERTANGGUH.md` T-012 selesai). Data pelanggan
  ikut berada di dalam cadangan selama masa itu.
- **Data pribadi (nama, email, HP, alamat):**

> `TODO(keputusan Lee)` — **masa simpan data pribadi belum diputuskan di mana pun di repo.**
> Contoh bentuk keputusannya: kontak dianonimkan otomatis setelah voucher kedaluwarsa, atau
> setelah N hari tanpa transaksi terakhir. Ini **harus** diputuskan sebelum kalimat
> persetujuan ditulis, karena kalimatnya wajib menyebut "berapa lama"
> (`docs/DECISIONS_LOG.md` 2026-09-17).

**Sumber:** `docs/PRD.md` §8 (Aturan Bisnis 11) · `docs/TECH_SPEC.md` §4.3 · `docs/DECISIONS_LOG.md` (2026-09-16 cadangan; 2026-09-17 privasi) · `docs/TERTANGGUH.md` (T-012)

---

## 4. Hak pelanggan (akses · koreksi · penghapusan)

**Akses (minta salinan data sendiri):** pelanggan boleh minta salinan datanya
(`docs/teknis/USULAN_KEAMANAN_DAN_KELENGKAPAN_UI.md` §B8 "minta salinan/hapus";
`docs/KEAMANAN.md` §11 "akses & hapus"). **Waktu tanggap komitmen: 3×24 jam**
(`docs/KEAMANAN.md` §11).

**Penghapusan:** permintaan hapus ditanggapi dengan **anonimisasi** — nama/kontak **dihapus
atau diganti**, tetapi **catatan keuangan tetap utuh** (Aturan Bisnis 11)
(`docs/KEAMANAN.md` §11; `docs/TECH_SPEC.md` ART-14; `docs/PRD.md` §8 Aturan Bisnis 18).
Prosedur teknisnya sudah dirancang di Fase 8 (bagian 5).

**Koreksi (memperbaiki data yang salah):**

> `TODO(keputusan Lee)` — **jalur koreksi belum dirancang di mana pun di repo.** Repo hanya
> merancang akses & penghapusan. Keputusan yang dibutuhkan: apakah pelanggan boleh meminta
> perbaikan nama/email/HP, dan bila ya — siapa yang memproses (kasir? owner?) dan bagaimana
> itu tercatat di jejak audit.

**Cara mengajukan permintaan (akses/hapus):**

> `TODO(keputusan Lee)` — **kanal permintaan belum diputuskan** (email tertentu? lewat
> kasir? formulir?). Diperlukan karena kalimat persetujuan wajib menyebut "cara minta
> dihapus" (`docs/DECISIONS_LOG.md` 2026-09-17).

**Sumber:** `docs/KEAMANAN.md` §11 · `docs/TECH_SPEC.md` ART-14 · `docs/PRD.md` §8 (Aturan Bisnis 18) · `docs/teknis/USULAN_KEAMANAN_DAN_KELENGKAPAN_UI.md` §B8

---

## 5. Anonimisasi & pseudonimisasi yang direncanakan

**Anonimisasi — sudah dirancang** (akan diimplementasikan di Fase 8, tugas `T8-15`):

- Fungsi **anonimisasi** menghapus kontak pelanggan **tanpa menghapus catatan keuangan**
  (`docs/ROADMAP.md` T8-15 DoD; `docs/TECH_SPEC.md` ART-14 "uji wajib: anonimisasi menghapus
  kontak tetapi tidak menghapus transaksi").
- Kolom **persetujuan + waktu + versi kebijakan** di data pelanggan; pendaftaran tanpa
  centang persetujuan **ditolak database** (`docs/ROADMAP.md` T8-15 DoD & mitigasi).
- **Anonimisasi menyisakan jejak audit** — siapa, kapan, untuk siapa (`docs/ROADMAP.md`
  T8-15, baris mitigasi risiko).
- Uji wajib lulus: pelanggan tanpa persetujuan ditolak · anonimisasi menghapus kontak ·
  transaksi & voucher tetap ada (`docs/ROADMAP.md` T8-15 Verifikasi).

**Pseudonimisasi — belum dirancang:**

> `TODO(keputusan Lee)` — **tidak ada desain pseudonimisasi di repo.** Jika Lee ingin
> skema di mana voucher/laporan bisa menautkan pelanggan tanpa kontak langsung
> (mis. kode acak pengganti nama), keputusan bentuknya di sini — pekerja T-03 tidak
> memutuskan sendiri.

**Pengaman yang sudah berlaku hari ini untuk data pelanggan (meski datanya belum ada):**

- **Isolasi antar penyewa:** data satu resto tidak terlihat resto lain — janji utama platform
  (`docs/KEAMANAN.md` §2; `docs/PRD.md` §8 Aturan Bisnis 9).
- **Laporan & email dilarang memuat kontak pelanggan** (`docs/KEAMANAN.md` §11;
  `docs/TECH_SPEC.md` ART-14).
- **Rahasia tidak pernah ditulis:** data pribadi pelanggan tidak boleh masuk log, pesan
  error, commit, atau dokumen (`docs/KEAMANAN.md` §1 butir 6).

**Sumber:** `docs/ROADMAP.md` T8-15 · `docs/TECH_SPEC.md` ART-14 · `docs/KEAMANAN.md` §1/§2/§11 · `docs/PRD.md` §8 (Aturan Bisnis 9)

---

## 6. Kalau data bocor — apa yang pelanggan terima

Pemberitahuan **tertulis paling lambat 3×24 jam** sejak kejadian diketahui, dikirim ke
**pelanggan yang terdampak dan ke lembaga pengawas (Lembaga PDP)** — kewajiban UU PDP Pasal 46.
Isi pemberitahuan: **data apa yang terdampak, kapan & bagaimana kejadian, dan langkah
pemulihan** (`docs/KEAMANAN.md` §11; `docs/TECH_SPEC.md` ART-14; `docs/DECISIONS_LOG.md`
2026-09-17).

Langkah jam-demi-jam dan **template pemberitahuan berbahasa manusia** sudah tersedia dan
bukan draf lagi: `docs/teknis/BUKU_INSIDEN.md` §6 ("Data pelanggan bocor").

**Sumber:** `docs/KEAMANAN.md` §11 · `docs/TECH_SPEC.md` ART-14 · `docs/DECISIONS_LOG.md` (2026-09-17) · `docs/teknis/BUKU_INSIDEN.md` §6

---

## 7. Jalur implementasi per fase

| Fase | Isi | Status | Sumber |
|---|---|---|---|
| **Fase 1B** (mendarat 2026-09-17) | "Hukum"-nya: aturan privasi mengikat di `docs/KEAMANAN.md` §11 · keputusan dikunci di `docs/DECISIONS_LOG.md` (persetujuan, minimalisasi, anonimisasi, lapor 3×24 jam) · template kebocoran di `docs/teknis/BUKU_INSIDEN.md` §6 | **sudah ada** — yang belum ada hanya kontrak untuk pelanggan (DRAF ini) | `docs/KEAMANAN.md` §11 · `docs/DECISIONS_LOG.md` 2026-09-17 |
| **Sebelum data pertama masuk** (gerbang) | DRAF ini **ditinjau Lee** → kalimat persetujuan + tautan kebijakan disepakati. Gerbangnya tercatat dua kali: butir tertangguh T-011 ("sebelum F8") dan catatan di T8-07 ("wajib ada SEBELUM tugas ini mengumpulkan data pelanggan pertama") | terbuka — menunggu tinjauan Lee | `docs/TERTANGGUH.md` T-011 · `docs/ROADMAP.md` T8-07 · `docs/PRD.md` §10.7 |
| **Fase 8** (katalog pelanggan & voucher — `T8-01`…`T8-15`) | `T8-01` katalog publik: fungsi memakai **daftar kolom tegas**, uji "tidak ada kolom sensitif" · `T8-06` halaman pendaftaran menampilkan kalimat persetujuan + tautan kebijakan · `T8-07` verifikasi email (dipagari T-011) · **`T8-15` privasi pelanggan**: kolom persetujuan + versi kebijakan, fungsi anonimisasi, halaman kebijakan berbahasa Indonesia, uji SQL | terbuka semua — DRAF ini menjadi **bahan** fase ini (temuan F F-09 menunjuk ke sini) | `docs/ROADMAP.md` Fase 8 · `docs/uji/AUDIT_RIWAYAT.md` §1c (F F-09) |
| **Setelah Fase 8** | Semua `TODO(keputusan Lee)` di dokumen ini dikunci ke teks kebijakan · kontrak terus diperiksa: tingkat audit **L6** ("Privasi & Kepatuhan") mewajibkan verifikasi persetujuan-sebelum-simpan, minimalisasi, anonimisasi tanpa hapus keuangan, dan jalur kebocoran 3×24 jam | rencana | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` (L6) |

**Catatan jujur soal nomor migrasi:** judul tugas `T8-15` di `docs/ROADMAP.md` menyebut
"Migrasi 0017", dan `docs/DECISIONS_LOG.md` menyebut nama berkas rencana
`supabase/migrations/0017_privasi_pelanggan.sql` (rencana — belum ada) — tetapi nomor 0017 sudah terpakai untuk
migrasi lain (kini migrasi tertinggi yang hidup = 0019, dan 0020 sudah dicadangkan integrator
untuk `T-01` di `docs/ops/PAPAN_TUGAS.md`). Log keputusan sendiri menandai nama itu sebagai
"rencana … nama final bisa berbeda". **Pekerja T-03 tidak memilih nomor migrasi** (aturan
AL-16) — penyejangan judul tugas ini menjadi urusan integrator saat panen.

**Sumber:** `docs/ROADMAP.md` Fase 8 (T8-01…T8-15) · `docs/DECISIONS_LOG.md` (2026-09-17, "File terkait") · `docs/ops/PAPAN_TUGAS.md` (cadangan 0020) · `docs/uji/AUDIT_RIWAYAT.md` §1c · `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` L6

---

## 8. Ringkasan bagian yang BELUM diputuskan (daftar `TODO(keputusan Lee)`)

| # | Yang belum diputuskan | Kenapa penting | Bagian terdampak |
|---|---|---|---|
| 1 | **Masa simpan data pribadi** (nama/email/HP/alamat) | kalimat persetujuan wajib menyebut "berapa lama"; pemicu anonimisasi butuh aturan | §3 · §2 (kalimat persetujuan) |
| 2 | **Jalur koreksi** — apakah & bagaimana pelanggan memperbaiki data yang salah | salah satu hak yang disebut kontrak; belum ada desainya di repo | §4 |
| 3 | **Kanal permintaan** akses/hapus (email? kasir? formulir?) | kalimat persetujuan wajib menyebut "cara minta dihapus" | §4 · §2 |
| 4 | **Kalimat persetujuan akhirnya** | bahan = DRAF ini; ditulis & disetujui Lee sebelum data pertama masuk (T-011) | §2 |
| 5 | **Pseudonimisasi** — apakah dibutuhkan & bentuknya | belum ada desain di repo; hanya anonimisasi yang dirancang | §5 |
| 6 | **Kapan teks kebijakan diperbarui** (versi kebijakan) | `T8-15` sudah merancang kolom "versi kebijakan", tetapi frekuensi/pernyataan pembaruannya belum diputuskan | §5 · §7 |

---

## 9. Daftar sumber per bagian

| Bagian dokumen | Sumber di repo |
|---|---|
| 0 — keadaan jujur | `supabase/migrations/` (0001–0019: tidak ada tabel pelanggan) · `docs/TECH_SPEC.md` §4.4 (rencana tabel) · `docs/ROADMAP.md` Fase 8 (tugas terbuka) · `docs/uji/AUDIT_RIWAYAT.md` §1c (F F-09) · `docs/TERTANGGUH.md` (T-011) · `supabase/migrations/0001_penyewa_cabang.sql` (data usaha, di luar cakupan) |
| 1 — data dikumpulkan/diproses | `docs/TECH_SPEC.md` §4.4 + ART-10 + ART-14 + §12 · `docs/PRD.md` M10 + §8 (Aturan Bisnis 3) · `docs/DISCOVERY.md` (butir 98, keputusan 12, §7 butir 10) · `docs/KEAMANAN.md` §11 · `docs/DECISIONS_LOG.md` (2026-09-17) |
| 2 — dasar & tujuan | `docs/KEAMANAN.md` §11 · `docs/DECISIONS_LOG.md` (2026-09-17) · `docs/PRD.md` §9 (#10) + §10.7 + M10 (kasus tepi) · `docs/TECH_SPEC.md` ART-10 + §12 · `docs/ROADMAP.md` T8-06/T8-07/T8-15 · `docs/TERTANGGUH.md` (T-011, T-014) |
| 3 — masa simpan | `docs/PRD.md` §8 (Aturan Bisnis 11) · `docs/TECH_SPEC.md` §4.3 · `docs/DECISIONS_LOG.md` (2026-09-16 cadangan) · `docs/TERTANGGUH.md` (T-012 selesai) |
| 4 — hak pelanggan | `docs/KEAMANAN.md` §11 · `docs/TECH_SPEC.md` ART-14 · `docs/PRD.md` §8 (Aturan Bisnis 18) · `docs/teknis/USULAN_KEAMANAN_DAN_KELENGKAPAN_UI.md` §B8 |
| 5 — anonimisasi/pseudonimisasi | `docs/ROADMAP.md` T8-15 · `docs/TECH_SPEC.md` ART-14 · `docs/KEAMANAN.md` §1 (butir 6), §2, §11 · `docs/PRD.md` §8 (Aturan Bisnis 9) |
| 6 — kebocoran | `docs/KEAMANAN.md` §11 · `docs/TECH_SPEC.md` ART-14 · `docs/DECISIONS_LOG.md` (2026-09-17) · `docs/teknis/BUKU_INSIDEN.md` §6 |
| 7 — jalur per fase | `docs/ROADMAP.md` Fase 8 · `docs/DECISIONS_LOG.md` (2026-09-17, "File terkait") · `docs/ops/PAPAN_TUGAS.md` (cadangan 0020) · `docs/uji/AUDIT_RIWAYAT.md` §1c · `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` (L6) |
