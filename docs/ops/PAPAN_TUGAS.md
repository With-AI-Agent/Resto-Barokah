# PAPAN TUGAS MARATON — kerja sama multi-sesi (alur AL-16)

> **Penulis tunggal papan ini = sesi INTEGRATOR** (sesi kerja utama). Pekerja TIDAK menulis di sini;
> bukti selesai pekerja = laporan di cabangnya sendiri (`docs/ops/maraton/LAPORAN-<tugas>.md`) yang
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

## Kolam tugas (belum dibagi)

- **Gelombang 2 (2026-09-21): T-01 DITERIMA · T-02 DITERIMA · T-03 DITERIMA** — insiden: 3 chat pekerja dibuka dalam SATU sesi Arena sehingga berbagi cabang `arena/01a0c1d7-resto-barokah` (obat: AL-16 + templat pekerja + `alat/periksa-maraton.py`). T-02 dipanen (keputusan + uji lengkap); T-03 dipanen (61e739b + poles 1 baris); T-01 dipanen (d205955); gelombang 2 SELESAI.

- F F-18 (sisa oracle boolean pemasangan PIN) — sengaja DITAHAN integrator (pekerjaan keamanan halus, integrator sendiri).
- B F-14 / B F-16 (pemeriksa) — wilayah `alat/` = terlarang bagi pekerja; integrator sendiri.
- F F-12 / F F-13 — terblokir lingkungan (butuh 2 koneksi database nyata).

## Riwayat gelombang

| Gelombang | Tanggal | Pekerja | Hasil |
|---|---|---|---|
| 1 | 2026-09-21 | (belum dibuka) | DIBATALKAN sebelum jalan — tidak ada pekerja yang dibuka, tidak ada kerja yang hilang; peluncuran dipindah ke sesi baru |
| 2 | 2026-09-21 | arena/01a0c1d7-resto-barokah (1 cabang dipakai 3 pekerja — insiden) | T-02 DIPANEN (keputusan + uji lengkap) · T-03 DIPANEN (61e739b + poles 1 baris) · T-01 DIPANEN (d205955); gelombang 2 SELESAI |
