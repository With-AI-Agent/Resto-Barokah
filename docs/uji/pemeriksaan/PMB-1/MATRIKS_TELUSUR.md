# MATRIKS TELUSUR — PMB-1 (v0, Tahap 0)

> Tujuan: setiap **janji** baseline (PRD M1–M12, TECH_SPEC ART-1…15 & §1–§13, KEAMANAN §1–§15) bisa ditelusuri ke **tugas ROADMAP**,
> **berkas implementasi**, **potongan pemeriksa**, dan **hasil**. Janji yang tidak punya potongan pemeriksa = "yatim" dan menahan
> gerbang Tahap 1 (`python3 alat/periksa-pemeriksaan.py --gerbang 1`).
>
> Bagian A disusun mesin (`python3 alat/susun-matriks-telusur.py`; penjaga `--periksa` menolak blok yang basi).
> Bagian B ditulis manusia (Perencana/Pemeriksa) dan **dinaikkan ke v1** pada akhir Tahap 1.

## A. Janji → tugas ROADMAP → berkas (OTOMATIS)

<!-- OTOMATIS:MULAI -->
_Disusun mesin oleh `python3 alat/susun-matriks-telusur.py` dari `docs/ROADMAP.md` (193 tugas), `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/KEAMANAN.md`. Janji tanpa tugas: **11** — tiap baris ⚠️ wajib dijawab potongan fondasi (janji tidak dibangun? atau `Ref:` ROADMAP tidak lengkap?)._

| Janji (baseline) | Judul | Tugas ROADMAP yang merujuk | Tuntas/total | Berkas implementasi (dari `File:`) |
|---|---|---|---|---|
| PRD M1 | Pendaftaran & pengelolaan penyewa (resto) | T1-01, T1-21, T1-33, T9-10 | 3/4 | `supabase/migrations/0001_penyewa_cabang.sql`, `supabase/tes/rls_penyewa.sql`, `supabase/seed.sql`, `supabase/seed_uji.sql`, `alat/peta-ui.py` +5 |
| PRD M2 | Pengaturan tanpa koding (per penyewa) | T1-02, T1-07, T1-16, T1-21, T3-01, T5-04, T6-04, T8-02, T8-05, T8-11, T9-01, T9-02, T9-03, T9-04, T9-05, T9-07, T9-11, T10-11 | 14/18 | `supabase/migrations/0002_pengguna_izin_pengaturan.sql`, `supabase/migrations/0007_katalog.sql`, `supabase/migrations/0023_urutan_pembulatan.sql`, `supabase/tes/urutan.sql`, `supabase/seed.sql` +25 |
| PRD M3 | Peran, hak akses berjenjang, & jejak audit | T1-02, T1-05, T1-06, T1-13, T1-23, T2-02, T2-03, T2-12, T5-05, T8-09, T9-08, T10-12 | 12/12 | `supabase/migrations/0002_pengguna_izin_pengaturan.sql`, `supabase/migrations/0005_izin_berjenjang.sql`, `supabase/tes/izin.sql`, `supabase/migrations/0006_pin.sql`, `supabase/functions/verifikasi_pin/index.ts` +23 |
| PRD M4 | Pesanan dari kasir & pelayan | T1-08, T1-09, T1-18, T3-01, T3-03, T3-04, T3-06, T3-08, T3-09, T3-11, T3-12, T6-05, T6-06, T9-04, T10-03, T10-09 | 9/16 | `supabase/migrations/0008_meja.sql`, `supabase/migrations/0009_pesanan.sql`, `supabase/migrations/0025_state_machine.sql`, `supabase/tes/status.sql`, `aplikasi/src/layar/kasir/LayarKasir.tsx` +20 |
| PRD M5 | Layar dapur & tiket dapur (KDS) | T1-18, T3-08, T4-01, T4-02, T4-03, T4-04, T4-05, T4-08, T4-09, T6-05 | 1/10 | `supabase/migrations/0025_state_machine.sql`, `supabase/tes/status.sql`, `aplikasi/src/layar/kasir/LayarKasir.tsx`, `supabase/migrations/0032_status_item_dapur.sql`, `aplikasi/src/layar/dapur/LayarDapur.tsx` +10 |
| PRD M6 | Pembayaran, struk, & pembatalan | T1-10, T1-15, T1-16, T1-18, T3-02, T3-13, T5-01, T5-03, T5-04, T5-05, T5-06, T5-07, T5-08, T5-09, T5-10, T5-11, T5-12, T6-04, T9-03 | 13/19 | `supabase/migrations/0010_pembayaran.sql`, `supabase/migrations/0022_hitung_total.sql`, `supabase/tes/uang.sql`, `supabase/migrations/0023_urutan_pembulatan.sql`, `supabase/tes/urutan.sql` +31 |
| PRD M7 | Kas & shift (buka/tutup kasir) | T1-11, T7-01, T7-02, T7-03, T7-04, T7-05, T7-06, T10-09 | 7/8 | `supabase/migrations/0018_kas_shift.sql`, `supabase/migrations/0045_buka_shift.sql`, `aplikasi/src/layar/kasir/BukaKas.tsx`, `supabase/migrations/0046_tutup_shift.sql`, `aplikasi/src/layar/kasir/TutupKas.tsx` +10 |
| PRD M8 | Laporan harian per shift | T1-17, T5-12, T7-07, T7-08, T7-09, T7-10, T7-11 | 6/7 | `supabase/migrations/0024_penomoran.sql`, `supabase/tes/penomoran.sql`, `supabase/migrations/0043_laporan_pembatalan.sql`, `aplikasi/src/layar/laporan/DaftarPembatalan.tsx`, `supabase/migrations/0051_laporan_kas.sql` +7 |
| PRD M9 | Stok dasar | T1-07, T3-07, T4-05, T4-06, T4-07 | 2/5 | `supabase/migrations/0007_katalog.sql`, `aplikasi/src/layar/kasir/Katalog.tsx`, `supabase/migrations/0035_menu_habis_sumber.sql`, `0030_menu_habis.sql`, `aplikasi/src/layar/dapur/TombolHabis.tsx` +4 |
| PRD M10 | Katalog pelanggan & voucher undang-teman | T1-12, T1-19, T1-20, T2-04, T2-05, T5-08, T7-09, T8-01, T8-02, T8-03, T8-04, T8-05, T8-06, T8-07, T8-08, T8-09, T8-10, T8-11, T8-12, T8-13, T8-14, T8-15 | 19/22 | `supabase/migrations/0019_voucher.sql`, `supabase/migrations/0026_cek_voucher.sql`, `supabase/tes/cek_voucher.sql`, `supabase/migrations/0027_pakai_voucher.sql`, `supabase/tes/pakai_voucher.sql` +38 |
| PRD M11 | Multi-cabang (dasar) | T1-01, T1-07, T2-07, T6-07, T9-06, T9-09 | 5/6 | `supabase/migrations/0001_penyewa_cabang.sql`, `supabase/tes/rls_penyewa.sql`, `supabase/migrations/0007_katalog.sql`, `aplikasi/src/hook/useCabang.ts`, `aplikasi/src/komponen/PemilihCabang.tsx` +6 |
| PRD M12 | Keamanan fondasi (lintas fitur) — **diperdalam 2026-09-17** | T1-04, T1-06, T1-23, T1-24, T1-25, T1-26, T1-27, T1-28, T1-36, T1-37, T1-33, T2-01, T2-02, T2-04, T2-09, T2-10, T2-12, T2-13, T2-14, T2-15, T2-16, T2-17, T2-18, T8-15, T10-05, T10-06, T10-10, T10-12, T11-07 | 26/29 | `supabase/migrations/0004_pola_rls.sql`, `supabase/tes/rls_semua_tabel.sql`, `supabase/migrations/0006_pin.sql`, `supabase/functions/verifikasi_pin/index.ts`, `supabase/tes/pin.sql` +68 |
| ART-1 | ART-1…ART-10) WAJIB lewat `DECISIONS_LOG.md` + persetujuan … | T1-01, T1-03, T1-04, T1-22, T2-07, T9-09, T9-10, T10-05 | 7/8 | `supabase/migrations/0001_penyewa_cabang.sql`, `supabase/tes/rls_penyewa.sql`, `supabase/migrations/0003_helper_identitas.sql`, `supabase/tes/helper.sql`, `supabase/migrations/0004_pola_rls.sql` +12 |
| ART-2 | ART-2. Peran & izin berjenjang | T1-03, T1-05, T1-06, T2-03, T2-09, T2-10, T2-12, T5-05, T9-08, T10-12 | 10/10 | `supabase/migrations/0003_helper_identitas.sql`, `supabase/tes/helper.sql`, `supabase/migrations/0005_izin_berjenjang.sql`, `supabase/tes/izin.sql`, `supabase/migrations/0006_pin.sql` +21 |
| ART-3 | ART-3. Rantai perhitungan uang (mudah salah & mahal) | T1-09, T1-10, T1-15, T1-16, T3-02, T5-02, T5-03, T5-04, T9-03 | 7/9 | `supabase/migrations/0009_pesanan.sql`, `supabase/migrations/0010_pembayaran.sql`, `supabase/migrations/0022_hitung_total.sql`, `supabase/tes/uang.sql`, `supabase/migrations/0023_urutan_pembulatan.sql` +12 |
| ART-4 | ART-4. State machine pesanan | T1-09, T1-18, T3-05, T3-08, T3-13, T4-04, T5-06, T5-07 | 4/8 | `supabase/migrations/0009_pesanan.sql`, `supabase/migrations/0025_state_machine.sql`, `supabase/tes/status.sql`, `supabase/migrations/0028_simpan_pesanan.sql`, `supabase/tes/simpan_pesanan.sql` +9 |
| ART-5 | ART-5. Voucher (rawan kecurangan) | T1-12, T1-19, T1-20, T8-07, T8-09, T8-12 | 3/6 | `supabase/migrations/0019_voucher.sql`, `supabase/migrations/0026_cek_voucher.sql`, `supabase/tes/cek_voucher.sql`, `supabase/migrations/0027_pakai_voucher.sql`, `supabase/tes/pakai_voucher.sql` +7 |
| ART-6 | ART-6. Kas & shift | T1-11, T1-13, T7-01 | 2/3 | `supabase/migrations/0018_kas_shift.sql`, `supabase/migrations/0020_catatan_audit.sql`, `supabase/migrations/0029_audit_kekal_rantai.sql`, `supabase/tes/catatan_audit.sql`, `supabase/tes/audit_rantai.sql` +2 |
| ART-7 | ART-7. Cetak (ESC/POS) & perangkat | T5-09, T6-01, T6-06, T11-11 | 2/4 | `aplikasi/src/komponen/StrukDigital.tsx`, `aplikasi/src/komponen/StrukDigital.test.tsx`, `aplikasi/src/lib/printer/expos.ts`, `aplikasi/src/lib/printer/expos.test.ts`, `aplikasi/src/lib/printer/antrean.ts` +3 |
| ART-8 | ART-8) + prosedur catat manual sementara (Buku Insiden). | T1-14, T3-05, T10-01, T10-02, T10-09, T11-11 | 3/6 | `supabase/migrations/0021_antrean_kesalahan.sql`, `supabase/migrations/0028_simpan_pesanan.sql`, `supabase/tes/simpan_pesanan.sql`, `aplikasi/src/lib/antrean-offline.ts`, `aplikasi/src/hook/useAntrean.ts` +7 |
| ART-9 | ART-9. Zona waktu & penomoran | T1-17, T7-11 | 1/2 | `supabase/migrations/0024_penomoran.sql`, `supabase/tes/penomoran.sql`, `supabase/tes/tengah_malam.sql` |
| ART-10 | ART-10. Data pelanggan & privasi | T1-12, T5-08, T8-01, T8-07 | 3/4 | `supabase/migrations/0019_voucher.sql`, `aplikasi/src/layar/kasir/DataPelanggan.tsx`, `aplikasi/src/layar/kasir/DataPelanggan.test.tsx`, `supabase/migrations/0062_katalog_publik.sql`, `supabase/tes/katalog_publik.sql` +3 |
| ART-11 | ART-11. Perangkat terdaftar & sesi (pencabutan seketika) | T1-24, T1-25, T1-36, T1-37, T2-15, T2-16, T2-17, T2-18, T2-19 | 8/9 | `supabase/migrations/0018_perangkat_terdaftar.sql`, `supabase/migrations/0030_sesi_dan_persetujuan_perangkat.sql`, `supabase/tes/perangkat_registrasi.sql`, `supabase/tes/sesi_dan_perangkat.sql`, `alat/uji-mutasi-0030.py` +22 |
| ART-12 | ART-12. Identitas & cara masuk (satu akun satu peran) | T1-23, T1-26, T1-37, T2-13, T2-14, T2-18, T2-19 | 5/7 | `supabase/migrations/0011_peran_tunggal.sql`, `supabase/tes/peran_tunggal.sql`, `supabase/migrations/0030_sesi_dan_persetujuan_perangkat.sql`, `supabase/tes/sesi_dan_perangkat.sql`, `alat/uji-mutasi-0030.py` +17 |
| ART-13 | ART-13. Jejak audit berantai | T1-27, T1-42, T10-13 | 3/3 | `supabase/migrations/0029_audit_kekal_rantai.sql`, `supabase/tes/audit_rantai.sql`, `alat/periksa-audit.py`, `docs/SPESIFIKASI_UI.md`, `aplikasi/src/kontrak/bantuan.ts` +6 |
| ART-14 | ART-14. Data pelanggan & privasi (UU PDP) | T8-15 | 1/1 | `privasi_pelanggan`, `supabase/tes/privasi.sql`, `aplikasi/src/layar/pelanggan-publik/KebijakanPrivasi.tsx` |
| ART-15 | ART-15. Mode dukungan pemilik platform | T1-28 | 1/1 | `supabase/migrations/0031_mode_dukungan_platform.sql`, `0016_mode_dukungan.sql`, `supabase/tes/mode_dukungan.sql`, `alat/uji-mutasi-0031.py` |
| TECH_SPEC §0 | Ringkasan bahasa manusia (untuk pemilik) | ⚠️ **tanpa tugas** | 0/0 | — |
| TECH_SPEC §1 | Tech Stack (dengan alasan) | T0-00, T0-01, T0-03, T0-08, T0-09, T2-01, T2-11, T6-01, T6-02, T6-03, T10-08, T11-07 | 9/12 | `docs/ops/SIAP_AKUN_PEMILIK.md`, `aplikasi/package.json`, `aplikasi/vite.config.ts`, `aplikasi/tsconfig.json`, `aplikasi/tsconfig.app.json` +31 |
| TECH_SPEC §2 | Arsitektur (pola + diagram teks) | ⚠️ **tanpa tugas** | 0/0 | — |
| TECH_SPEC §3 | Struktur Folder | T0-01, T0-04, T1-21, T2-06, T2-11, T8-02 | 5/6 | `aplikasi/package.json`, `aplikasi/vite.config.ts`, `aplikasi/tsconfig.json`, `aplikasi/tsconfig.app.json`, `aplikasi/tsconfig.node.json` +16 |
| TECH_SPEC §4 | Data Model / Skema Database | T1-01, T1-02, T1-03, T1-05, T1-06, T1-07, T1-08, T1-09, T1-10, T1-11, T1-12, T1-13, T1-14, T1-23, T1-24, T1-25, T1-26, T1-27, T1-37, T2-03, T2-15, T3-01, T3-07, T4-06, T5-01, T6-07, T7-03 | 20/27 | `supabase/migrations/0001_penyewa_cabang.sql`, `supabase/tes/rls_penyewa.sql`, `supabase/migrations/0002_pengguna_izin_pengaturan.sql`, `supabase/migrations/0003_helper_identitas.sql`, `supabase/tes/helper.sql` +45 |
| TECH_SPEC §5 | API Contract per fitur MVP | T1-15, T1-19, T1-20, T1-36, T2-13, T2-14, T2-17, T2-18, T3-05, T3-12, T5-02, T8-01, T10-11, T10-13 | 9/14 | `supabase/migrations/0022_hitung_total.sql`, `supabase/tes/uang.sql`, `supabase/migrations/0026_cek_voucher.sql`, `supabase/tes/cek_voucher.sql`, `supabase/migrations/0027_pakai_voucher.sql` +29 |
| TECH_SPEC §6 | Environment Variables (rahasia tidak boleh ikut ke aplikasi) | T0-00, T0-05, T0-08, T10-14 | 4/4 | `docs/ops/SIAP_AKUN_PEMILIK.md`, `aplikasi/.env.example`, `aplikasi/.gitignore`, `aplikasi/src/lib/env.ts`, `aplikasi/src/lib/supabase.ts` +5 |
| TECH_SPEC §7 | Integrasi Pihak Ketiga | T0-09, T2-01, T2-04, T2-05, T11-07 | 4/5 | `aplikasi/wrangler.toml`, `aplikasi/package.json`, `aplikasi/src/lib/auth.ts`, `aplikasi/src/hook/useSesi.ts`, `aplikasi/src/layar/masuk/LayarMasukPelanggan.tsx` +6 |
| TECH_SPEC §8 | Pertimbangan Keamanan (ringkasan — rujukan resmi: `docs/KEA… | T1-29, T1-30, T10-07, T10-10, T10-14, T10-15 | 6/6 | `supabase/tes/matriks_izin_6_peran.sql`, `alat/periksa-matriks-izin.py`, `alat/periksa-keamanan-sql.py`, `alat/periksa-rahasia.py`, `.github/workflows/ci.yml` +7 |
| TECH_SPEC §9 | Area Berisiko Tinggi (WAJIB — dibaca sebelum menyentuh) | T1-01, T1-03, T1-04, T1-05, T1-06, T1-09, T1-10, T1-11, T1-12, T1-13, T1-14, T1-15, T1-16, T1-17, T1-18, T1-19, T1-20, T1-22, T1-23, T1-24, T1-25, T1-26, T1-27, T1-28, T1-36, T1-37, T2-03, T2-07, T2-09, T2-10, T2-12, T2-13, T2-14, T2-15, T2-16, T2-17, T2-18, T2-19, T3-02, T3-05, T3-08, T3-13, T4-04, T5-02, T5-03, T5-04, T5-05, T5-06, T5-07, T5-08, T5-09, T6-01, T6-06, T7-01, T7-11, T8-01, T8-07, T8-09, T8-12, T8-15, T9-03, T9-08, T9-09, T9-10, T10-01, T10-02, T10-05, T10-07, T10-09, T10-12, T10-13, T11-11 | 55/72 | `supabase/migrations/0001_penyewa_cabang.sql`, `supabase/tes/rls_penyewa.sql`, `supabase/migrations/0003_helper_identitas.sql`, `supabase/tes/helper.sql`, `supabase/migrations/0004_pola_rls.sql` +149 |
| TECH_SPEC §10 | Batas gratis & rencana naik kelas (keputusan K6) | T10-08, T10-10, T11-06, T11-08, T11-10 | 2/5 | `supabase/migrations/0082_denyut_harian_pembersih.sql`, `alat/denyut.py`, `alat/eksekusi-denyut.mjs`, `supabase/tes/denyut_pembersih.sql`, `alat/uji-mutasi-0082.py` +9 |
| TECH_SPEC §11 | Uji & Definisi Selesai (prinsip "tidak ada yang cacat") | T0-10, T1-22, T1-29, T1-30, T2-19, T3-14, T3-15, T3-16, T4-09, T6-08, T7-12, T8-14, T10-04, T10-15, T11-01, T11-03, T11-05, T11-11 | 11/18 | `aplikasi/vitest.config.ts`, `aplikasi/src/lib/format.test.ts`, `aplikasi/src/lib/tema.test.ts`, `aplikasi/src/lib/env.test.ts`, `aplikasi/src/hook/useJam.test.tsx` +35 |
| TECH_SPEC §12 | Yang masih perlu diputuskan/diketahui dari lapangan | T6-08, T11-03, T11-04 | 0/3 | `docs/uji/UJI_CETAK_KEDAI_OASIS.md`, `docs/uji/UJI_PERANGKAT.md` |
| TECH_SPEC §13 | Log Keputusan (Tahap 3 — putaran 1) | T1-16, T2-02, T5-09, T6-02, T10-01, T11-06, T11-08 | 3/7 | `supabase/migrations/0023_urutan_pembulatan.sql`, `supabase/tes/urutan.sql`, `aplikasi/src/layar/masuk/LayarMasukPegawai.tsx`, `aplikasi/src/layar/masuk/LayarMasukPegawai.test.tsx`, `aplikasi/src/komponen/StrukDigital.tsx` +11 |
| KEAMANAN §1 | Prinsip (yang tidak boleh dilanggar oleh keputusan lain) | T1-45 | 0/1 | `supabase/migrations/0015_penutup_celah_putaran16.sql`, `supabase/tes/`, `alat/periksa-gerbang-ci.py`, `alat/audit-independen.py`, `alat/lanjut-sesi.py` |
| KEAMANAN §2 | Aset yang dilindungi & peta ancaman | ⚠️ **tanpa tugas** | 0/0 | — |
| KEAMANAN §3 | Identitas & peran | ⚠️ **tanpa tugas** | 0/0 | — |
| KEAMANAN §4 | Perangkat terdaftar | ⚠️ **tanpa tugas** | 0/0 | — |
| KEAMANAN §4b | Jalan keluar saat perangkat hilang / dicuri (tangga pemulih… | T1-36 | 1/1 | `supabase/migrations/0028_pemulihan_perangkat.sql`, `supabase/tes/pemulihan.sql`, `docs/ops/PEMULIHAN_PERANGKAT.md` |
| KEAMANAN §5 | Cara masuk per peran | ⚠️ **tanpa tugas** | 0/0 | — |
| KEAMANAN §6 | PIN | ⚠️ **tanpa tugas** | 0/0 | — |
| KEAMANAN §7 | Sesi | T10-16 | 1/1 | `docs/teknis/TINJAUAN_KEAMANAN_F10.md`, `supabase/tes/mfa.sql` |
| KEAMANAN §8 | Otorisasi (dua lapis, satu gerbang) | ⚠️ **tanpa tugas** | 0/0 | — |
| KEAMANAN §9 | Uang & kecurangan operasional | T10-13 | 1/1 | `supabase/functions/ringkasan_harian/index.ts`, `supabase/migrations/0085_ringkasan_harian.sql`, `aplikasi/src/layar/laporan/Peringatan.tsx`, `supabase/tes/ringkasan.sql` |
| KEAMANAN §10 | Jejak audit | ⚠️ **tanpa tugas** | 0/0 | — |
| KEAMANAN §11 | Data pelanggan & UU PDP (UU 27/2022) | T5-08, T8-15 | 2/2 | `aplikasi/src/layar/kasir/DataPelanggan.tsx`, `aplikasi/src/layar/kasir/DataPelanggan.test.tsx`, `privasi_pelanggan`, `supabase/tes/privasi.sql`, `aplikasi/src/layar/pelanggan-publik/KebijakanPrivasi.tsx` |
| KEAMANAN §12 | Mode dukungan (pemilik platform) | ⚠️ **tanpa tugas** | 0/0 | — |
| KEAMANAN §13 | Operasional (murah, sering terlupa) | ⚠️ **tanpa tugas** | 0/0 | — |
| KEAMANAN §14 | Matriks uji keamanan (wajib hijau sebelum pilot) | T2-19, T11-12 | 1/2 | `aplikasi/src/layar/masuk/SkenarioMasukPeran.test.tsx`, `supabase/tes/sesi_dan_perangkat.sql`, `supabase/tes/matriks_izin_6_peran.sql`, `masuk_perangkat.sql`, `masuk.test.tsx` +2 |
| KEAMANAN §15 | Risiko sisa yang diterima (dicatat terbuka, bukan disembuny… | T10-16 | 1/1 | `docs/teknis/TINJAUAN_KEAMANAN_F10.md`, `supabase/tes/mfa.sql` |
| KEAMANAN §16 | Aturan untuk sesi agent berikutnya | T1-30, T10-14 | 2/2 | `alat/periksa-keamanan-sql.py`, `alat/periksa-rahasia.py`, `.github/workflows/ci.yml`, `aplikasi/public/_headers` |
<!-- OTOMATIS:SELESAI -->

## B. Penugasan pemeriksaan & hasil (MANUAL)

Kolom "Potongan fondasi" = potongan Tahap 1 yang memeriksa **teks janji** itu (konsisten, lengkap, asumsi, suara Lee, masih benar).
Kolom "Potongan fase" diisi saat papan Tahap 2 dirinci (setelah baseline dikunci). "Hasil" = ringkasan status temuan yang menyentuh janji itu.

| Janji | Potongan fondasi | Potongan fase (Tahap 2) | Potongan lintas / menyeluruh | Hasil |
|---|---|---|---|---|
| PRD M1 | F-02 | P-9-00 | M-01, X-02 | — |
| PRD M2 | F-02 | P-9-00 | M-02 | — |
| PRD M3 | F-02 | P-1-00, P-1B-00 | X-04, M-02 | — |
| PRD M4 | F-02 | P-3-00 | M-03 | — |
| PRD M5 | F-02 | P-4-00 | M-04 | — |
| PRD M6 | F-02 | P-5-00 | X-01, M-03 | — |
| PRD M7 | F-03 | P-7-00 | X-01, M-03 | F-03: A-027 terbuka (dua kasir/satu kas) · F-03.2: PMB1-F-037 K-2 (aturan wajib shift dilonggarkan diam-diam), PMB1-F-046 K-3 luar cakupan (uang seharusnya negatif dibulatkan 0) · F-03.3: A-027 dikonfirmasi tetap terbuka (indeks 0045; tanpa entri DECISIONS_LOG) |
| PRD M8 | F-03 | P-7-00 | X-01, M-08 | F-03: PMB1-F-035 (cetak masih disebut fase 2) · F-03.2: klaim cetak = fase 2 bertahan (T7-10 menjembatani) — berbeda pendapat dengan PMB1-F-035, untuk Hakim |
| PRD M9 | F-03 | P-4-00 | M-04 | F-03: tidak ada temuan baru di teks M9 · F-03.2: tidak ada temuan |
| PRD M10 | F-03 | P-8-00 | X-05, M-05 | F-03: PMB1-F-031 K-1, PMB1-F-032 K-2, PMB1-F-034, PMB1-F-035 · F-03.2: PMB1-F-038 K-2 (jalur didaftarkan kasir tanpa kunci identitas), PMB1-F-041 K-3 (alamat/HP tanpa tujuan MVP) · F-03.3: A-039 terbuka (kasus tepi voucher offline tanpa mekanisme) |
| PRD M11 | F-03 | P-9-00 | X-02, M-02 | F-03: PMB1-F-033 (izin per cabang vs skema) · F-03.2: tidak diuji terhadap skema (lihat PMB1-F-033) |
| PRD M12 | F-03 | P-10-00 | X-02, X-04, M-06 | F-03: sesi/PDP angka cocok A-029; gerbang T-011 di PMB1-F-034 · F-03.2: PMB1-F-036 K-1 (owner masuk PIN + perangkat daftar sendiri), PMB1-F-039 K-2 (regresi K F-03), PMB1-F-040 K-3 (rantai audit tanpa jangkar), PMB1-F-042 K-3 (token/sandi di config.toml tidak cocok — angka sesi TIDAK cocok di konfigurasi), PMB1-F-044 K-4, PMB1-F-047 K-4 · F-03.3: PMB1-F-048 K-2 (notifikasi mode dukungan tanpa mekanisme), PMB1-F-049 K-2 (ringkasan harian tanpa penjadwal) |
| PRD §9–§10 (risiko, pertanyaan terbuka) | F-03 | P-10-00 (risiko) | — | F-03.3: PMB1-F-050 K-4 (label cetak "LAN" vs TECH_SPEC "Ditolak: printer jaringan"); temuan §10 basi = kembar PMB1-F-043 (K-F-03.2, untuk Hakim) |
| ART-1 … ART-15 | F-05 | ditentukan per ART saat Tahap 2 dirinci | X-01 … X-07 | — |
| TECH_SPEC §0 | F-04 (ringkasan untuk pemilik: harus cocok dengan §1–§13) | — | — | — |
| TECH_SPEC §1 … §13 | F-04 (§1–§5), F-05 (§6–§13) | — | — | — |
| KEAMANAN §1 … §16 | F-06 | P-1-00, P-1B-00, P-10-00 | X-02, X-04, X-05, M-06, M-07 | — |
| KEAMANAN §4b | F-06 (tangga pemulihan perangkat hilang) | P-1B-00 | X-04, M-06 | — |

## C. Pertanyaan terbuka yang lahir dari matriks (dijawab di Tahap 1)

- Bagaimana **pemilik platform pertama** (`peran = 'pemilik_platform'`, `penyewa_id null` — migrasi 0002) dibuat di produksi tanpa seed?
  Belum ditemukan prosedur tertulisnya; berkaitan dengan PMB1-F-001 dan L-02 (bootstrap dari nol, usul Lee).
- Setiap baris ⚠️ **tanpa tugas** di bagian A: janji tidak dibangun, atau `Ref:` ROADMAP yang tidak lengkap? (F-02/F-03/F-05/F-06 menjawab.)
