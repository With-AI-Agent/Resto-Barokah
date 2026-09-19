# LAPORAN AUDIT INDEPENDEN — AUD-2 — 2026-09-17

- **Auditor:** sesi-auditor-contoh (model keluarga berbeda dari penulis kode)
- **Tanggal:** 2026-09-17
- **Tingkat audit:** AUD-2
- **Commit yang diaudit:** `961d193c3f839a050e2ed69c0808c4cdb21b26a7`
- **Paket audit:** `docs/uji/paket-audit/AUD-2-2026-09-17.md`
- **Alasan commit berbeda:** repo berjalan satu commit setelah audit dimulai (penambahan dokumen mekanisme audit).
- **Verdict:** BERSIH-DENGAN-CATATAN

## 1. Cakupan

| # | Artefak | Diperiksa | Bukti |
|---|---|---|---|
| 1 | `supabase/migrations/0004_pola_rls.sql` | ya | `grep -c "penyewa_saya()" supabase/migrations/0004_pola_rls.sql` → 8 |
| 2 | `supabase/migrations/0005_izin_berjenjang.sql` | ya | `grep -n "revoke all on function" supabase/migrations/0005_izin_berjenjang.sql` → 3 baris |
| 3 | `supabase/migrations/0006_pin.sql` | ya | `grep -n "BATAS_AKUN\|BATAS_PERANGKAT" ...` → 5 / 12 |
| 4 | `supabase/tes/izin.sql` | ya | `node alat/uji-sql.mjs` → 10 LULUS · 0 GAGAL |
| 5 | `docs/KEAMANAN.md` | ya | `docs/KEAMANAN.md:130` (batas percobaan: 5×/15 menit per akun) |
| 6 | `alat/periksa-roadmap.py` | ya | `python3 alat/periksa-roadmap.py` → LOLOS (15 aturan aktif) |
| 7 | `docs/TECH_SPEC.md` §9 | ya | `docs/TECH_SPEC.md:412` (ART-11…ART-15 terdefinisi) |

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | ROADMAP T1-10: "pembayaran tidak boleh melebihi total" | `node alat/uji-sql.mjs` + baca 0010:296 | TERBUKTI (ditolak, pesan jelas) |
| 2 | ROADMAP T1-06: "PIN hanya hash bcrypt" | `grep -n "pin_hash" supabase/migrations/0006_pin.sql` | TERBUKTI (CHECK menolak bukan-hash) |
| 3 | ROADMAP T1-04: "tanpa policy = gagal" | `node alat/uji-sql.mjs` (rls_semua_tabel) | TERBUKTI (23 tabel, semua RLS+policy) |
| 4 | Dokumen: "satu akun satu peran" | `grep -n "peran" supabase/migrations/0002_*.sql` | TERBANTAH — `pengguna_cabang.peran` masih ada (lihat F-01) |
| 5 | Dokumen: "kode pendaftaran perangkat" | `ls supabase/migrations/` | BELUM ADA (memang Fase 1B — bukan cacat) |

## 3. Serangan yang dijalankan (kill attempts)

| # | Skenario | Cara | Hasil |
|---|---|---|---|
| 1 | Anon memanggil gerbang izin | jalankan `select public.boleh('beri_diskon')` sebagai anon | DITOLAK (baik) |
| 2 | Kasir menulis angka uang | `update pesanan set total = 1` sebagai kasir | DITOLAK (baik) |
| 3 | Sesi pegawai nonaktif | set aktif=false lalu panggil `cabang_saya()` | kosong (baik) |
| 4 | Hapus baris audit | `delete from catatan_audit` sebagai owner | tabel belum ada (Fase 1B) |
| 5 | Baca pengaturan penyewa lain | SELECT sebagai kasir resto B | 0 baris (baik) |

## 4. Temuan

### [F-01] `pengguna_cabang.peran` masih menjadi sumber wewenang padahal aturan baru menyebut satu akun satu peran
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0002_pengguna_izin_pengaturan.sql:54`
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §3 "satu akun satu peran; `pengguna_cabang` hanya menyimpan daftar cabang"
- **Bukti:** `sed -n '51,64p' supabase/migrations/0002_pengguna_izin_pengaturan.sql` → kolom `peran` masih ada + komentar "perannya bisa berbeda per cabang"
- **Skenario gagal:** pegawai diberi peran `dapur` di satu cabang — izin berbeda per cabang tetap mungkin, bertentangan dengan ART-12
- **Dugaan penyebab:** keputusan peran tunggal (2026-09-17) datang setelah 0002 ditulis; migrasi lama dibekukan
- **Cara membuktikan perbaikan:** setelah T1-23: `grep -c "peran" supabase/migrations/0002_pengguna_izin_pengaturan.sql` tetap ada (beku) TETAPI `node alat/uji-sql.mjs` + `supabase/tes/peran_tunggal.sql` menolak peran kedua
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman

(tidak dijalankan — AUD-2; kalibrasi wajib pada AUD-3)

## 6. Yang tidak bisa saya verifikasi

- Perilaku `current_setting('request.headers')` di Supabase nyata — butuh akun Supabase (T0-08) yang belum ada.
- Uji peramban/Playwright — Chromium tidak dapat diunduh di ruang kerja ini.

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca dan **tidak mengubah** berkas apa pun selain laporan ini — laporan ini satu-satunya berkas yang saya buat. Bukti: `git status --short` menampilkan hanya berkas laporan ini.

## 8. Temuan di luar cakupan

| # | Temuan | Mengapa di luar cakupan | Bukti | Syarat dilanjutkan ke audit lain |
|---|---|---|---|---|
| 1 | `docs/PANDUAN_PEMILIK.md` belum menyebut kalibrasi (sudah diperbaiki dalam batch lain) | di luar lensa L3/L4 yang diminta paket | `grep -c kalibrasi docs/PANDUAN_PEMILIK.md` → 0 saat itu | audit dokumen pengguna putaran berikutnya |
