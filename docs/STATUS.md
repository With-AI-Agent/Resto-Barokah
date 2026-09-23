# Status Proyek Resto Barokah

Ringkasan keadaan kerja untuk sesi berikutnya. Rincian rencana ada di
`docs/ops/SIAP-LANJUT.md` §3; keputusan terkunci di `docs/DECISIONS_LOG.md`.

- Fase 1–3: selesai (fondasi, keamanan, kasir POS — CI hijau terbukti).
- Fase 4 SQL: T4-02/04 (`0032`,`0033`) + T4-05/06/07 (`0035`–`0037`) + uji anti-dobel selesai — suite SQL 78 berkas lulus.
- Fase 4 UI: KartuPesanan, LayarDapur, LayarBar, TombolHabis, Stok, Opname + keadaan/mode TV/cadangan offline — 253 tes aplikasi lulus.
- Fase 4 bukti nyata: uji konkuren 2 koneksi (T-409) terkalibrasi lulus di alat/uji-konkuren.py.
- Menunggu Lee: bukti visual/manual (T4-03 foto, uji manual T4-01/05/10), keputusan infra e2e Playwright (dapur.spec.ts).

**Pekerjaan belum tersimpan:** Tidak ada

> **Catatan (2026-09-23):** commit `227a51b` dan `7aec492` yang sempat tertahan token GitHub
> kedaluwarsa **sudah ter-push**. Tidak ada pekerjaan yang tertinggal.

**Waktu pembaruan:** 2026-09-23 — Fase 5: T5-01…T5-05 selesai (353 tes aplikasi, 84 uji SQL, mutasi 0041 6/6 MERAH, mutasi UI 20/20 MERAH); T-026 & T-027 menunggu Lee
