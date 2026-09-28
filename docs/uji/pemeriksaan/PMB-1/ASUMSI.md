# DAFTAR ASUMSI — PMB-1

> Asumsi = kalimat di fondasi/kode yang **menganggap sesuatu benar tentang dunia** (pajak, hukum, perangkat, batas gratis, perilaku
> kasir, lingkungan produksi) tanpa bukti di repo. Setiap potongan menambah barisnya; status hanya berubah dengan bukti/riset.
> Status: `TERBUKA` · `DIBUKTIKAN` (bukti/riset tercatat) · `DIBANTAH` (asumsi salah → wajib punya temuan di Buku Besar).

| ID | Asumsi (kalimat) | Sumber (dokumen/fase/berkas) | Status | Bukti / riset (tautan, perintah, tanggal) | Dampak bila salah | Potongan |
|---|---|---|---|---|---|---|
| PMB1-A-001 | "Uji SQL lokal (PGlite) mewakili perilaku migrasi di Supabase produksi" | seluruh uji `supabase/tes/`, `alat/uji-sql.mjs`; sesi 01a0d09b | DIBANTAH | Migrasi `0086` memiliki blok `if not exists (select 1 from pg_namespace where nspname = 'uji')` yang **hanya berjalan di produksi** → 132 uji SQL lokal tidak pernah mengeksekusinya (PMB1-F-001, 2026-09-28) | cacat khusus produksi tidak tertangkap uji apa pun | F-10 |
| PMB1-A-002 | "Akun percontohan aman karena hanya dipakai pemilik saat pembangunan" | sesi 01a0d09b (REKAM §31) | DIBANTAH | repo publik (`gh repo view --json isPrivate` → false) + PIN bawaan tertulis di migrasi + RPC mendaftarkan perangkat sendiri (temuan PMB1-F-001, 2026-09-28) | siapa pun bisa masuk sebagai owner | F-10 |
