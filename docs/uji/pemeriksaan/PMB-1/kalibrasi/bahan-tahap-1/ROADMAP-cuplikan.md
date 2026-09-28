# Cuplikan ROADMAP — usulan pembaruan status Fase 7 (bahan kalibrasi; lihat README.md)

> Angka bukti terakhir: `node alat/uji-sql.mjs` → 128/128 berkas uji SQL lulus (2026-09-27).

- [x] T7-04 — Transaksi hanya dalam shift terbuka ⚠️
  - **Tujuan:** tidak ada penjualan "di luar kas" yang tidak bisa diaudit.
  - **Ref:** PRD M7 (kriteria selesai)
  - **File:** `supabase/migrations/0048_wajib_shift.sql`, `supabase/tes/wajib_shift.sql`
  - **DoD:** memesan/membayar di luar shift terbuka ditolak dengan pesan jelas; uji lulus; **disaksikan pemilik di perangkat kasir nyata dan ditandatangani di berita acara**.
  - **Kompleksitas:** sedang (2,5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); kasir lupa buka kas saat sibuk → mitigasi: pengingat + tombol buka kas cepat.
  - **Verifikasi:** uji SQL + uji manual. · **Bukti 2026-09-27:** pemicu `wajib_shift` ada di migrasi 0048 dan uji `supabase/tes/wajib_shift.sql` hijau; tombol buka kas cepat ada di layar kasir.

- [x] T7-05 — Pengingat shift belum ditutup
  - **Tujuan:** shift yang lupa ditutup tidak mencemari laporan besok.
  - **Ref:** PRD M7 (kasus tepi)
  - **File:** `aplikasi/src/layar/kas/` (komponen pengingat), `supabase/migrations/0085_ringkasan_harian.sql`
  - **DoD:** pengingat tampil bila shift melewati jam tutup cabang; laporan harian menandai shift yang ditutup lewat tengah malam.
  - **Verifikasi:** uji komponen + uji SQL.
