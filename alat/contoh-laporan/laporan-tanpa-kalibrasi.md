# LAPORAN AUDIT INDEPENDEN — AUD-3 — 2026-09-17

- **Auditor:** sesi-auditor-tanpa-kalibrasi
- **Tanggal:** 2026-09-17
- **Tingkat audit:** AUD-3
- **Commit yang diaudit:** `961d193c3f839a050e2ed69c0808c4cdb21b26a7`
- **Paket audit:** `docs/uji/paket-audit/AUD-3-2026-09-17.md`
- **Alasan commit berbeda:** repo maju satu commit karena dokumen mekanisme audit ditambahkan.
- **Verdict:** BERSIH

## 1. Cakupan

| # | Artefak | Diperiksa | Bukti |
|---|---|---|---|
| 1 | `supabase/migrations/0001_penyewa_cabang.sql` | ya | `node alat/uji-sql.mjs` → 10 LULUS |
| 2 | `supabase/migrations/0003_helper_identitas.sql` | ya | `grep -n "p.aktif" 0003` → 4 |
| 3 | `supabase/migrations/0004_pola_rls.sql` | ya | `grep -c penyewa_saya 0004` → 8 |
| 4 | `supabase/migrations/0005_izin_berjenjang.sql` | ya | `grep -n "revoke all" 0005` → 3 |
| 5 | `supabase/migrations/0006_pin.sql` | ya | `grep -n BATAS_AKUN 0006` → 5 |
| 6 | `supabase/migrations/0010_pembayaran.sql` | ya | `sed -n 288,300p 0010` |
| 7 | `docs/KEAMANAN.md` | ya | `grep -n "5×/15" docs/KEAMANAN.md` → 1 |
| 8 | `alat/periksa-roadmap.py` | ya | `python3 alat/periksa-roadmap.py` → LOLOS |

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| 1 | T1-01 isolasi antar resto | jalankan uji SQL | TERBUKTI |
| 2 | T1-04 tabel tanpa policy = gagal | jalankan uji katalog | TERBUKTI |
| 3 | T1-06 batas 5×/akun | jalankan uji PIN | TERBUKTI |
| 4 | T1-10 lebih bayar ditolak | jalankan uji pembayaran | TERBUKTI |
| 5 | Dokumen 5×/15 menit | bandingkan dengan 0006 | TERBUKTI |
| 6 | Dokumen satu peran | bandingkan dengan 0002 | TERBANTAH (F-01, DUGAAN) |

## 3. Serangan yang dijalankan (kill attempts)

| # | Skenario | Cara | Hasil |
|---|---|---|---|
| 1 | anon memanggil `boleh()` | jalankan sebagai anon | ditolak |
| 2 | kasir menulis `pesanan.total` | update sebagai kasir | ditolak |
| 3 | kasir menghapus pembayaran | delete sebagai kasir | ditolak |
| 4 | pembayaran melebihi total | insert 100.000 pada pesanan 62.100 | ditolak |
| 5 | diskon ganda | insert diskon kedua | ditolak (tumpuk mati) |
| 6 | void setelah dapur tanpa PIN atasan | panggil pembatalan | ditolak |
| 7 | baca pengaturan penyewa lain | select sebagai resto B | 0 baris |
| 8 | pegawai nonaktif memakai cabang | set aktif=false lalu panggil | kosong |
| 9 | akun tanpa cabang memakai cabang asing | panggil dengan uuid asing | ditolak |
| 10 | PIN resto lain | verifikasi PIN lintas resto | "PIN tidak dikenali" |
| 11 | item pesanan tanpa `harga_saat_itu` | insert langsung | ditolak |
| 12 | ubah `harga_saat_itu` | update baris item | ditolak |

## 4. Temuan

### [F-01] `pengguna_cabang.peran` masih ada padahal aturan satu peran sudah berlaku
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0002_pengguna_izin_pengaturan.sql:54`
- **Klaim yang dilanggar:** `docs/KEAMANAN.md` §3
- **Bukti:** `sed -n '54p' supabase/migrations/0002_pengguna_izin_pengaturan.sql` → kolom `peran text not null check (...)`
- **Skenario gagal:** peran berbeda per cabang masih mungkin
- **Dugaan penyebab:** keputusan menyusul setelah migrasi dibekukan
- **Cara membuktikan perbaikan:** `supabase/tes/peran_tunggal.sql` hijau setelah T1-23
- **Status verifikasi:** DUGAAN

## 5. Kalibrasi cacat tanaman

Tidak dijalankan pada audit ini.

## 6. Yang tidak bisa saya verifikasi

- Perilaku Supabase nyata (T0-08 belum jalan) dan uji peramban (Chromium tidak bisa diunduh).

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca dan tidak mengubah berkas apa pun. Bukti: `git status --short` kosong.
