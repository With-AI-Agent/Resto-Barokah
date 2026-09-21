# PAPAN TUGAS MARATON — kerja sama multi-sesi (alur AL-16)

> **Penulis tunggal papan ini = sesi INTEGRATOR** (sesi kerja utama). Pekerja TIDAK menulis di sini;
> bukti selesai pekerja = laporan di cabangnya sendiri (G3: namespace `docs/uji/audit/`; gelombang kode lama: `docs/ops/maraton/LAPORAN-<tugas>.md`) yang
> dibaca integrator saat panen. Aturan lengkap: `PANDUAN_PENGGUNA.md` alur **AL-16**.
>
> **Status yang sah:** `DIBERIKAN` (ditugaskan, belum ada laporan) · `SELESAI` (pekerja lapor + push,
> menunggu panen) · `DITERIMA` (sudah dipanen integrator, bukti tercatat) · `DITOLAK (<alasan>)`
> (dinilai gagal; tugas kembali ke kolam) · `DIBATALKAN (<alasan>)`.
> **Lingkup berkas = EKSKLUSIF**: dua tugas aktif tidak boleh bersinggungan berkas apa pun.
> **Nomor migrasi = dicadangkan integrator** (pekerja tidak boleh memilih sendiri).
> Papan ini diperiksa mesin: `python3 alat/periksa-maraton.py` (juga jalan di CI).

| Tugas | Lingkup berkas eksklusif | No. migrasi cadangan | Pekerja (cabang) | Status | DoD & bukti wajib | Catatan panen |
|---|---|---|---|---|---|---|
| T-01 | `supabase/migrations/0020_catatan_audit.sql`, `supabase/tes/catatan_audit.sql` (rencana — keduanya dibuat pekerja T-01) | 0020 | pekerja-1 (sesi 01a0c1d7 dipakai bersama — insiden, pelindung ditempel) | DITERIMA | Tabel `catatan_audit` (temuan F F-07/T1-13): kolom minimal `id`, `penyewa_id` (FK), `pelaku_id` (FK pengguna, boleh null = sistem), `aksi` (text), `entitas` (text), `entitas_id` (uuid null), `nilai_lama`/`nilai_baru` (jsonb null), `waktu` (timestamptz default now); RLS: baca hanya `kelola_pegawai` se-penyewa, TANPA grant insert/update/delete ke klien (jalur peladen/definer saja); TANPA trigger dulu (pencatatan otomatis menyusul di panen berikutnya — JANGAN menyentuh fungsi lain). Uji `supabase/tes/catatan_audit.sql`: insert via klien ditolak (sebab dipatok `harap_gagal_sebab`), baca kasir tanpa izin = 0 baris, admin cabang melihat catatan penyewanya, lintas penyewa 0 baris, insert jalur pemilik berhasil & terbaca. Bukti: `node alat/uji-sql.mjs supabase/tes/catatan_audit.sql` LULUS + seluruh suite tetap hijau. | cabang-bersama 01a0c1d7; DIPANEN dari d205955 (0020 + uji + laporan; tanpa trigger sesuai DoD; klaim 61 uji jujur untuk pohonnya) |
| T-02 | `supabase/tes/perangkat_registrasi_tepi.sql` (rencana — dibuat pekerja T-02) | — | arena/01a0c1d7-resto-barokah | DITERIMA | Uji TEPI tambahan untuk perangkat terdaftar (melengkapi `perangkat_registrasi.sql`, TANPA migrasi baru, TANPA mengubah berkas lain): (a) nama perangkat kembar dalam satu penyewa ditolak (sebab dipatok), (b) nama sama di penyewa BERBEDA diperbolehkan, (c) cabang nonaktif ditolak saat mendaftar, (d) perangkat dicabut lalu didaftarkan ulang dengan nama sama → berhasil & perangkat baru sah dipakai, (e) kunci 16 karakter tepat di batas diterima, 15 ditolak. Semua penolakan dipatok dengan `uji.harap_gagal_sebab` (bukan `harap_gagal` polos — ada pagarnya). Bukti: `node alat/uji-sql.mjs supabase/tes/perangkat_registrasi_tepi.sql` LULUS + suite tetap hijau. | cabang-bersama 01a0c1d7; DIPANEN: DoD benar -> 0018 jadi indeks parsial + uji dilengkapi integrator (bukti (d) pekerja dipakai) |
| T-03 | docs/PRIVASI_PELANGGAN.md — rencana, dibuat pekerja T-03 (nama berkas sengaja tanpa backtick: belum ada, aturan AT-08) | — | arena/01a0c1d7-resto-barokah | DITERIMA | DRAF kontrak privasi pelanggan (temuan F F-09, bahan T8-01) dalam bahasa Indonesia sederhana untuk Lee: data pelanggan apa yang dikumpulkan/diproses (dari `DISCOVERY.md`, `PRD.md`, skema `supabase/migrations/`), dasar & tujuan, masa simpan, hak pelanggan (akses/koreksi/penghapusan), anonimisasi/pseudonimisasi yang direncanakan, dan jalur implementasinya per fase — semua WAJIB bersumber dari berkas repo (sebutkan rujukannya per bagian), tanpa mengarang mekanisme; bagian yang belum diputuskan ditandai `TODO(keputusan Lee)` — jangan memutuskan sendiri. Status berkas: DRAF. Bukti: laporan berisi daftar sumber per bagian. | cabang-bersama 01a0c1d7; DIPANEN dari 61e739b + poles 1 baris (nama rencana tanpa backtick, AT-08) |

| T-04 | `docs/uji/audit/LAPORAN_G3_T04_*.md` | — | pekerja-1 (cabang platform dicatat dalam laporan) | DIBERIKAN | G3 laporan-saja: bantah-balik A-F01 + A-F03, CTE bayar+edit satu statement, kontrol sebelum/sesudah bayar, bukti commit uang+kolom, SQL vs keterjangkauan klien, fixture utuh. Paket `docs/uji/maraton/G3-T-04-2026-09-21-SIAP-TEMPEL.md`. | cabang-bersama diantisipasi; namespace G3_T04 + UUID/hash; belum mulai/diterima; target e50bac4 |
| T-05 | `docs/uji/audit/LAPORAN_G3_T05_*.md` | — | pekerja-2 (cabang platform dicatat dalam laporan) | DIBERIKAN | G3 laporan-saja: bantah-balik A-F02, matriks tenant/role/sub/RPC, current_user vs session_user di definer, jalur peladen sah dan keterjangkauan klien dipisah; fixture utuh. Paket `docs/uji/maraton/G3-T-05-2026-09-21-SIAP-TEMPEL.md`. | cabang-bersama diantisipasi; namespace G3_T05 + UUID/hash; belum mulai/diterima; target e50bac4 |
| T-06 | `docs/uji/audit/LAPORAN_G3_T06_*.md` | — | pekerja-3 (cabang platform dicatat dalam laporan) | DIBERIKAN | G3 laporan-saja: bantah-balik B-F01..B-F09, kontrol+mutan+keluaran/exit pada setiap ID, runtime bukan bukti pagar; PARTIAL jujur bila belum semua teruji. Paket `docs/uji/maraton/G3-T-06-2026-09-21-SIAP-TEMPEL.md`. | cabang-bersama diantisipasi; namespace G3_T06 + UUID/hash; belum mulai/diterima; target e50bac4 |


## Gelombang 3 — pemeriksaan laporan-saja (mandat Lee 2026-09-21)

**Siap dibagikan, bukan klaim tiga sesi sudah berjalan.** T-04/A, T-05/B, T-06/C
bekerja paralel di **salinan uji unik**; kode asli tidak diubah. Target bersama
`e50bac4d897ca65b37dde9e64dbd246a3891b041`, CI **35600019563 SUCCESS**;
bandingkan laporan historis target `09bcb89fc139b3be32ab874e7a004f0a3b0480ee`.
SHA penerbitan paket berbeda, dicantumkan pada prompt chat. Ini bantah-balik,
bukan audit AUD-2 pengganti; dua laporan lama tetap dipakai, sesi error lama diabaikan.

**Aturan G3 mengungguli mekanisme pekerja kode lama:** lingkup eksklusif tabel
adalah **tambahan laporan terpublikasi**, bukan larangan membaca berkas sama.
Tidak ada alokasi migrasi atau izin edit kode/pemeriksa/CI/lockfile/keputusan uang.
Draf/cadangan `.laporan-lokal/` + salinan uji pribadi diperbolehkan; tidak di-commit.
Pakai `alat/kirim-laporan.py --jenis audit --penanda G3_T04` (atau G3_T05/G3_T06)
dari SHA paket; bukan git add/commit folder bersama. Otomatis push dan verifikasi
remote tanpa pengingat Lee. Cabang/working tree boleh sama antar-pekerja—jangan
anggap sesi baru memberi cabang unik, jangan meminta Lee mengatur nama cabang.
Tetap gunakan cabang sesi masing-masing, bukan cabang sumber/main.

Integrator satu-satunya penulis papan. Setelah laporan masuk: catat cabang aktual
(dan penanda cabang-bersama jika dipakai beberapa tugas), verifikasi repo/ref/blob,
arsipkan **laporan saja**, ulangi bukti, terima/tolak per DoD. Tidak merge cabang
pekerja. Pengiriman remote terverifikasi ≠ isi laporan diterima. Hasil parsial/blocked
disimpan tetapi tugas tidak ditandai selesai substantif. Panen bisa satu per satu.

Perbaikan yang beririsan dikerjakan integrator **berurutan** setelah reproduksi,
bukan paralel; setiap batch perlu regresi/mutasi/CI dan tinjauan sesuai risiko.
Tidak ada izin merge PR/deploy. T1-30/T1-45 tetap terbuka.
Sisa **A-F04/A-F05/A-F06/B-F10** tetap milik integrator setelah K-2/pagar uji;
lihat `docs/uji/TINDAK_LANJUT_AUD2_2026-09-21.md`. Jika ada keputusan uang/keamanan
baru yang tidak bisa diputuskan dari kontrak terkunci, stop aman dan catat eskalasi.


## Kolam tugas (belum dibagi)

- **Gelombang 2 (2026-09-21): T-01 DITERIMA · T-02 DITERIMA · T-03 DITERIMA** — insiden: 3 chat pekerja dibuka dalam SATU sesi Arena sehingga berbagi cabang `arena/01a0c1d7-resto-barokah` (obat: AL-16 + templat pekerja + `alat/periksa-maraton.py`). T-02 dipanen (keputusan + uji lengkap); T-03 dipanen (61e739b + poles 1 baris); T-01 dipanen (d205955); gelombang 2 SELESAI.

- **Catatan kolam di bawah adalah riwayat gelombang 2, bukan pekerjaan aktif G3; status terbaru ada di handoff dan ledger tindak lanjut.**
- F F-18 (sisa oracle boolean pemasangan PIN) — sengaja DITAHAN integrator (pekerjaan keamanan halus, integrator sendiri).
- B F-14 / B F-16 (pemeriksa) — wilayah `alat/` = terlarang bagi pekerja; integrator sendiri.
- F F-12 / F F-13 — terblokir lingkungan (butuh 2 koneksi database nyata).

## Riwayat gelombang

| Gelombang | Tanggal | Pekerja | Hasil |
|---|---|---|---|
| 1 | 2026-09-21 | (belum dibuka) | DIBATALKAN sebelum jalan — tidak ada pekerja yang dibuka, tidak ada kerja yang hilang; peluncuran dipindah ke sesi baru |
| 2 | 2026-09-21 | arena/01a0c1d7-resto-barokah (1 cabang dipakai 3 pekerja — insiden) | T-02 DIPANEN (keputusan + uji lengkap) · T-03 DIPANEN (61e739b + poles 1 baris) · T-01 DIPANEN (d205955); gelombang 2 SELESAI |

| 3 | 2026-09-21 | pekerja-1/2/3; cabang aktual belum diketahui | DIBERIKAN T-04/T-05/T-06; pemeriksaan laporan-saja, belum ada hasil; paket baru bukan audit ulang |
