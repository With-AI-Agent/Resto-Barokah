# BUKU BESAR TEMUAN — PMB-1

> **Satu baris = satu temuan. Temuan tidak pernah dihapus, hanya berubah status.** ID stabil `PMB1-F-001`, `PMB1-F-002`, …
> berurutan tanpa lompatan. Penjaga: `python3 alat/periksa-pemeriksaan.py` (format, ID, artefak ada, status & transisi sah).
> Induk lintas putaran tetap `docs/uji/AUDIT_RIWAYAT.md` §1b — satu baris ringkasan per tahap ditambahkan di sana saat gerbang tahap.
>
> **Siklus status:** `BARU → TERVERIFIKASI | PALSU | PERLU-INFO` (Hakim) `→ DIPERBAIKI` (Pembangun, wajib commit) `→ DITUTUP` (Hakim
> memverifikasi ulang). `DITANGGUHKAN` hanya oleh keputusan Lee dengan rujukan `T-0xx` di `docs/TERTANGGUH.md`.
> **Tingkat:** K-1 uang hilang / data bocor lintas penyewa / akses tanpa hak / produksi terbuka · K-2 fungsi inti salah atau janji
> baseline dilanggar · K-3 mutu (keandalan, keterpeliharaan, aksesibilitas, dokumen menyesatkan) · K-4 kosmetik / konsistensi.
> **Bukti:** perintah yang dijalankan → hasil nyata (bukan "seharusnya"), boleh merujuk kartu `kartu/K-<ID>.md` untuk rincian.
> **Artefak:** jalur repo yang ada (`berkas:baris` atau `berkas §bagian`); untuk hal di luar repo tulis `(luar repo) <apa>`.

| ID | Tingkat | Potongan | Artefak | Baseline yang dilanggar | Ciri mutu | Bukti (perintah → hasil) | Status | Hakim | Perbaikan | Verifikasi tutup |
|---|---|---|---|---|---|---|---|---|---|---|
| PMB1-F-001 | K-1 | F-10 | `supabase/migrations/0086_data_awal_dan_autentikasi_perangkat.sql:286` | KEAMANAN §6.1 (PIN pola lemah 123456 dilarang); ROADMAP T11-07 DoD "data uji tidak ada di produksi"; `docs/ops/DEPLOY.md` §1 klaim "BERSIH 100 %" | keamanan (kerahasiaan, akuntabilitas) | `sed -n 286,300p` migrasi 0086 → blok seed `if not exists (… nspname = 'uji')` = **hanya berjalan di produksi**; `grep -n "crypt('123456'"` → PIN bawaan untuk `owner/kasir/dapur/pelayan@resto.test`; `sed -n 28,60p` → RPC `verifikasi_pin_perangkat` menerima `p_perangkat_id` null dan **mendaftarkan perangkat baru** sendiri; `gh run list --workflow=sebar-skema.yml` → run 2026-09-28 07:49 UTC (commit `b3e00686`) **success** = 0086 sudah dieksekusi di Supabase nyata; `gh repo view --json isPrivate` → `false` (repo publik). Lee mengonfirmasi akun itu yang ia pakai (REKAM §31). **Keputusan Lee 2026-09-28:** PIN tidak diganti/dihapus selama masa percobaan (tanpa data asli) — temuan tetap terbuka, wajib ditutup sebelum data asli/pilot (L-01/L-02). | BARU | — | — | — |
