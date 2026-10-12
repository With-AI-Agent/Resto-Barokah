# LAPORAN PEMERIKSAAN INDEPENDEN FASE 10 — AGEN 2

- **Nama Agen:** Agen 2: Frontend & UI/UX (Kepatuhan Peta UI, Ketahanan Luring, Aksesibilitas)
- **Target Cabang:** `arena/01a0d09b-resto-barokah` (diminta) → dieksekusi pada `arena/01a0e1ee-resto-barokah` @ `5f7b38b`
- **Waktu Pemeriksaan:** 2026-09-27, 08:15–09:10 UTC (Asia/Jakarta 15:15–16:10)
- **Status Akhir (Verdict):** **PERLU PERBAIKAN** — 0 cacat K-1/K-2 aktif; 4 temuan K-3 (2 dokumen paket audit, 2 arsitektural/laten pada produk); 4 catatan K-4. Produk **aman lanjut Fase 11**; perbaikan K-3 produk dijadwalkan di Fase 11 (bukan blocker).

## 1. Ringkasan Eksekutif Hasil Uji

Seluruh pagar otomatis frontend terverifikasi **HIJAU dan fail-closed** dengan bukti eksekusi nyata: Peta UI 12 layar/57 aksi lolos (uji-diri 6/6), kontras WCAG **166/166 pada 10 tema**, kerapatan Nyaman/Padat terbukti memadat terukur (18 kelas aplikasi), perilaku modal Esc/fokus/pluar-klik terkunci di aplikasi + sumber desain (uji-diri 10/10), suite Vitest **123 berkas / 1011 uji LULUS** (melampaui klaim 106+), uji luring 7/7 tanpa duplikasi, uji mutasi aplikasi **81/81 MERAH**, `typecheck` bersih, `vite build` sukses 3.17s, dan `git status` kosong sebelum/sesudah (audit read-only terhadap kode; satu-satunya penambahan adalah berkas laporan ini).

Pemeriksaan mendalam (baca penuh `antrean-offline.ts` 543 baris, `useAntrean.ts` 401 baris, `StatusAntrean.tsx` 580 baris, `TombolAksi.tsx`, `Lapis.tsx`, `Navigasi.tsx`, dan sweep seluruh produsen antrean + seluruh pemakaian tombol) menemukan 2 hal yang luput dari pemeriksaan permukaan: (1) komponen `TombolAksi` penegak izin **tidak dipakai sama sekali** di kode produksi (401 tombol memakai `<Tombol>` tanpa ikatan registri) sehingga klaim "zero unmapped buttons" bersifat dokumenter, bukan mekanis — penegakan izin di UI hanya level navigasi + peladen (temuan F10-A2-05, K-3; temuan lama F-08/F-09 yang masih terbuka); (2) pola sanitasi PIN memakai exact-match sehingga **lolos untuk kunci `pinKasir`** — persis kunci yang dibaca cabang voucher offline `penanganDefault`, cabang yang juga **nol cakupan uji** (temuan F10-A2-06, K-3, laten: produksi hari ini hanya mengantrekan `simpan_pesanan` tanpa PIN, terverifikasi). Ditambah 2 kesalahan jalur perintah di dokumen paket audit (F10-A2-01/02, K-3) dan 4 catatan K-4 (redaksi AAA-vs-AA, tombol mentah layar contoh, chunk build 1 MB, cakupan tipis LayarPelayan).

## 2. Bukti Eksekusi Perintah Wajib

| # | Perintah | Keluaran |
|---|----------|----------|
| 0 | `git branch --show-current && git branch -a && git status --short && git log --oneline -3` | Cabang aktif `arena/01a0e1ee-resto-barokah`; remote hanya `main`; `git status` **kosong**; HEAD `5f7b38b`. Cabang `arena/01a0d09b-resto-barokah` tidak ada di checkout → audit di cabang sesi (aturan Arena), read-only |
| 1 | `python3 alat/peta-ui.py --periksa` | **LULUS** — `SEMUA PEMERIKSAAN HIJAU (Layar, Aksi, RPC, Izin, Uji, PRD M1–M12, Bebas Button Liar)` |
| 1b | `python3 alat/peta-ui.py --uji-diri` | **LULUS 6/6** mutasi tertangkap (RPC/izin fiktif, aksi tulis tanpa uji, layar tanpa peran, drift dokumen, `<button>` liar) |
| 2a | `python3 aplikasi/alat/periksa-kontras.py` (verbatim paket) | **GAGAL EKSEKUSI** — `[Errno 2] No such file` → F10-A2-01 |
| 2a′ | `python3 aplikasi/alat/uji-kontras.py` (berkas sebenarnya) | **LULUS 166/166, 0 gagal** — 10 tema × 13 pasangan (teks utama 11.84–21.00:1; redup 5.43–13.58:1; tombol 6.40–11.39:1; semua ≥4.5:1) + 36 aturan desain; uji-diri 5/5 |
| 2b | `python3 aplikasi/alat/periksa-kerapatan.py` | **LULUS** — 10 token menyusut (`--s-1` 4→3px … `--s-10` 72→54px), 18 kelas aplikasi bereaksi; uji-diri 5/5 |
| 2c | `python3 aplikasi/alat/periksa-antarmuka.py` | **LULUS** — klik·Esc(+fokus pulang)·klik-luar·fokus-keluar·pilih-tutup; CSS identik sumber desain; uji-diri 10/10 |
| 3 | `cd aplikasi && npm ci && npm test -- --run` | **LULUS — 123 berkas · 1011 uji · 0 gagal · 123.62s**; `npm ci`: 273 paket, `found 0 vulnerabilities` |
| 4 | `npx vitest run uji/e2e/luring.spec.ts` | **LULUS 7/7** — pesanan/bayar/voucher idempoten tepat-1, flapping berhenti-anggun-lanjut-tanpa-dobel, integrasi `useAntrean`+`StatusAntrean` |
| 4b | `npx vitest run uji/e2e/mati-mendadak.spec.ts` | **LULUS 7/7** (draf keranjang, shift aktif, tagihan terbuka, tiket KDS, server-wins) |
| 5 | `node alat/uji-mutasi-app.mjs` (verbatim paket) | **GAGAL EKSEKUSI** — `MODULE_NOT_FOUND` → F10-A2-02 |
| 5′ | `node aplikasi/alat/uji-mutasi-app.mjs` | **LULUS — kontrol hijau + 81/81 mutasi MERAH** (salinan sementara; repo tak disentuh) |
| 6 | `npm run typecheck` (`tsc -b --noEmit`) | **LULUS**, exit 0 |
| 7 | `npm run build` (`vite build`) | **SUKSES 3.17s**; peringatan chunk 1.06 MB (gzip 280 KB) → F10-A2-07 (K-4) |
| 8 | `python3 alat/periksa-bahasa.py` | **LULUS** — paritas 283 kunci × en/zh/ar |
| 9 | `python3 alat/periksa-arah.py` | **LULUS** — RTL/LTR + 19 berkas huruf 461 KB < 650 KB |
| 10 | `python3 aplikasi/alat/periksa-struktur.py` | **LOLOS** — 29 OK · 4 INFO · 0 GAGAL |

Perintah 6–10 adalah pemeriksaan tambahan auditor di luar daftar wajib (bukti ketelitian).

## 3. Daftar Temuan Masalah

### F10-A2-01 (K-3) — Jalur perintah kontras salah di paket audit

- **Lokasi Berkas & Baris:** `docs/uji/PAKET_AUDIT_F10_3_AGEN.md` §4C; `docs/uji/PROMPT_AGEN_2_FRONTEND.md:30`
- **Deskripsi Masalah:** Perintah wajib `python3 aplikasi/alat/periksa-kontras.py` menunjuk berkas yang tidak ada; pemeriksa sebenarnya `aplikasi/alat/uji-kontras.py`.
- **Langkah / Perintah Reproduksi:** `python3 aplikasi/alat/periksa-kontras.py` → `can't open file ... [Errno 2]`
- **Dampak Bisnis (Multi-Tenant / Keamanan / Kasir):** Nol pada operasional kasir (pemeriksa benar lolos 166/166); sedang pada tata kelola — paket resmi tidak terreproduksi verbatim.
- **Rekomendasi Solusi:** Ubah §4C menjadi `python3 aplikasi/alat/uji-kontras.py` (atau sediakan alias); sinkronkan `PROMPT_AGEN_2_FRONTEND.md`.

### F10-A2-02 (K-3) — Jalur uji mutasi salah di paket audit

- **Lokasi Berkas & Baris:** `docs/uji/PAKET_AUDIT_F10_3_AGEN.md` §4C; `docs/uji/PROMPT_AGEN_2_FRONTEND.md:34`
- **Deskripsi Masalah:** Perintah wajib `node alat/uji-mutasi-app.mjs` tidak ada; lokasi benar `aplikasi/alat/uji-mutasi-app.mjs`.
- **Langkah / Perintah Reproduksi:** `node alat/uji-mutasi-app.mjs` → `Error: Cannot find module ... MODULE_NOT_FOUND`
- **Dampak Bisnis (Multi-Tenant / Keamanan / Kasir):** Nol pada produk (81/81 mutasi MERAH di jalur benar); sedang pada reproduksibilitas audit.
- **Rekomendasi Solusi:** Ubah §4C menjadi `node aplikasi/alat/uji-mutasi-app.mjs`; tambahkan prasyarat `cd aplikasi && npm ci` (pemeriksa sudah gagal-jujur bila `vitest` hilang — perilaku fail-closed yang baik).

### F10-A2-03 (K-4) — Redaksi "WCAG AAA" paket vs jaminan "AA" produk

- **Lokasi Berkas & Baris:** `docs/uji/PAKET_AUDIT_F10_3_AGEN.md` §4B-3 vs `aplikasi/alat/uji-kontras.py:209`, `aplikasi/src/layar/pengaturan/Tampilan.tsx:53-123`
- **Deskripsi Masalah:** Paket menuntut AAA 7:1; produk menjamin/memvalidasi AA ≥4.5:1. Ukur nyata: 130/130 lolos AA, tetapi **60/130 pasangan <7:1** (teks redup 5.43–6.64:1 di 7 tema terang). Teks utama 11.84–21.00:1 lolos AAA.
- **Langkah / Perintah Reproduksi:** `python3 aplikasi/alat/uji-kontras.py` → hitung rasio `<7` dari 130 pasangan.
- **Dampak Bisnis (Multi-Tenant / Keamanan / Kasir):** Minimal — AA adalah standar industri POS; keterbacaan baik (redup ≥5.43:1). Selisih redaksional, bukan cacat kode.
- **Rekomendasi Solusi:** Revisi redaksi paket → "AA minimum, AAA teks utama"; atau Fase 11 angkat token `--text-redup` 7 tema terang ke ≥7:1. Non-blocker.

### F10-A2-04 (K-4) — Tiga `<button>` mentah di layar contoh (dikecualikan sah)

- **Lokasi Berkas & Baris:** `aplikasi/src/layar/contoh/LayarContoh.tsx:119,137,150`; pengecualian `alat/peta-ui.py:399-401`
- **Deskripsi Masalah:** Pemilih tema/kerapatan/bahasa memakai `<button>` mentah, bukan `TombolAksi`. Fungsinya terpetakan (`contoh.ganti_tema`, `contoh.ganti_kerapatan`) dan pengecualian tertulis eksplisit di Aturan 7.
- **Langkah / Perintah Reproduksi:** `grep -rn "<button" aplikasi/src/layar --include="*.tsx" | grep -v test` → tepat 3 hit, semua di `LayarContoh.tsx`.
- **Dampak Bisnis (Multi-Tenant / Keamanan / Kasir):** Nihil — layar dev-only.
- **Rekomendasi Solusi:** Biarkan, atau migrasikan ke `TombolAksi` sebagai dogfooding Fase 11.

### F10-A2-05 (K-3) — `TombolAksi` penegak izin tidak dipakai di produksi; ikatan registri dokumenter, bukan mekanis

- **Lokasi Berkas & Baris:** `docs/SPESIFIKASI_UI.md:44-46` (mandat) vs `aplikasi/src/komponen/Tombol.tsx` + seluruh `aplikasi/src/layar/` (fakta)
- **Deskripsi Masalah:** Spesifikasi memandatkan "Semua tombol di folder `layar/` dirender lewat `TombolAksi.tsx`" dengan penolakan id tak dikenal dan gating peran/izin. Fakta ukur: **`TombolAksi` dipakai 0× di kode produksi** (hanya definisi + 2 berkas uji); **401 pemakaian `<Tombol>`** yang tidak mengenal `aksiId`/izin (`Tombol.tsx` hanya punya `onClick`/`nonaktif`). Akibatnya: (a) "zero unmapped buttons" hanya berarti "tanpa `<button>` mentah" (Aturan 7 peta-ui), bukan "setiap tombol terikat entri registri saat render"; (b) gating izin level-tombol registri (sembunyi/nonaktif+alasan, `TombolAksi.tsx:36-46`) tidak beroperasi — pengguna bisa melihat tombol yang nantinya ditolak peladen; (c) penegakan izin di klien hanya level navigasi (`Navigasi.ambilMenuPeran`, terverifikasi per-peran) + level layar, sedangkan penegakan nyata bertumpu pada RLS/RPC peladen (arsitektur benar, defense-in-depth klien tipis). Temuan lama **F-08/F-09** (`docs/uji/audit/LAPORAN_audit_21b5...md:30,39`) sudah menandai hal yang sama dan **masih terbuka** (tidak ada entri di `DAFTAR_PEKERJAAN_ULANG.md`/`TINDAK_LANJUT_AUD2_2026-09-21.md`).
- **Langkah / Perintah Reproduksi:** `grep -rn "TombolAksi" aplikasi/src --include="*.tsx" --include="*.ts" | grep -v test` → hanya `TombolAksi.tsx` (definisi); `grep -rn "<Tombol" aplikasi/src/layar --include="*.tsx" | grep -v test | wc -l` → 401.
- **Dampak Bisnis (Multi-Tenant / Keamanan / Kasir):** Keamanan data TIDAK jebol (peladen tetap menolak via RLS/RPC — domain Agen 1); dampaknya UX + jejak audit UI: kasir/pelayan dapat menekan tombol yang pasti gagal di peladen (mis. aksi di luar izinnya bila berhasil mencapai layar), dan klaim kubernur "tombol tanpa entri tidak bisa dirender" tidak berlaku. Bukan K-2 karena tidak ada bypass keamanan — hanya hilangnya lapisan UI.
- **Rekomendasi Solusi (Fase 11, non-blocker):** Opsi A — kabelkan `TombolAksi` bertahap mulai layar uang (Kasir bayar/diskon/void, Pengaturan) + perketat Aturan 7 menolak `<Tombol onClick>` tanpa `aksiId` di layar produksi; Opsi B — jika disengaja, amandemen `SPESIFIKASI_UI.md` §3 + `DECISIONS_LOG.md` ke model "Tombol + gating navigasi + penegakan peladen" agar klaim jujur. Tutup F-08/F-09 dengan keputusan eksplisit.

### F10-A2-06 (K-3) — Celah sanitasi laten: `pinKasir` lolos dari `POLA_KUNCI_SENSITIF` + cabang voucher offline tak teruji

- **Lokasi Berkas & Baris:** `aplikasi/src/lib/antrean-offline.ts:43-46` (regex exact-match) × `aplikasi/src/hook/useAntrean.ts:201-212` (`m.pinKasir` → `p_pin_kasir`)
- **Deskripsi Masalah:** Dua sisi satu koin. (a) Sanitasi: `POLA_KUNCI_SENSITIF = /^(pin|pin_lama|…)$/i` hanya exact-match, sehingga kunci **`pinKasir` (camelCase) TIDAK disaring** dan akan tersimpan plaintext di IndexedDB bila ada produsen mengantrekannya — padahal `penanganDefault` cabang `pakai_voucher` justru membaca `m.pinKasir` dari muatan antrean. (b) Fungsional/uji: produksi hari ini **tidak pernah** mengantrekan voucher (satu-satunya produsen `App.tsx:127-142` hanya `simpan_pesanan` tanpa PIN — terverifikasi; uji voucher memakai penangan kustom, `luring.spec.ts:219-280`), sehingga cabang default voucher **tak pernah dieksekusi dan 0 cakupan uji** (`grep penanganDefault|p_pin_kasir` di `*.test.*`/`*.spec.*` = kosong): bila dieksekusi, ia selalu mengirim `p_pin_kasir: ''` → ditolak peladen → jalur voucher offline mati-dengan-desain.
- **Langkah / Perintah Reproduksi:** (a) `node -e` mental/regex: `/^(pin|…)$/i.test('pinKasir')` → `false`; (b) `grep -rn "tambahKeAntrean" aplikasi/src --include="*.tsx" | grep -v test` → hanya `App.tsx:127` (`simpan_pesanan`, muatan tanpa PIN); (c) `grep -rn "penanganDefault\|p_pin_kasir" aplikasi/src aplikasi/uji --include="*.test.*" --include="*.spec.*"` → kosong.
- **Dampak Bisnis (Multi-Tenant / Keamanan / Kasir):** Hari ini NOL (tidak ada PIN tersimpan — terbukti via sweep seluruh `setItem`/`store.add`: kunci storage hanya tema/bahasa/draf/tagihan/perangkat/sesi-tanpa-PIN). Risiko laten: pengembang Fase 11 yang "melengkapi" antrean voucher offline dengan `pinKasir` akan tanpa sadar menaruh PIN di IndexedDB; atau sebaliknya voucher offline tetap gagal misterius. Bukan K-2 karena belum terpicu.
- **Rekomendasi Solusi (Fase 11, non-blocker):** (1) Lebarkan pola ke pencocokan kata-bagian, mis. `/(pin|password|kata.?sandi|secret|kredensial|token|auth(oriz)?)/i` + uji regresi `pinKasir`/`PIN_Kasir`; (2) putuskan arsitektur: voucher = **online-only** (hapus cabang menyesatkan, dokumentasikan) ATAU uji cabang default + minta PIN ulang saat sinkron (PIN dari memori, tidak dari muatan).

### F10-A2-07 (K-4) — Bundel JS 1.06 MB tanpa code-splitting

- **Lokasi Berkas & Baris:** keluaran `npm run build` — `dist/assets/index-CCBkg6oV.js 1,062.42 kB (gzip 279.74 kB)` + peringatan Rollup >500 kB
- **Deskripsi Masalah:** Seluruh aplikasi (kasir+dapur+laporan+pengaturan+17 berkas huruf woff2) dibundel satu chunk; tablet/HP kasir dengan jaringan lemah memuat ~280 KB gzip JS + ~81 KB CSS sebelum bisa transaksi.
- **Langkah / Perintah Reproduksi:** `cd aplikasi && npm run build` → peringatan chunk + angka di atas; exit 0 (build sukses).
- **Dampak Bisnis (Multi-Tenant / Keamanan / Kasir):** Muat-pertama lambat di perangkat/jaringan marginal; tidak memengaruhi kebenaran transaksi.
- **Rekomendasi Solusi (Fase 11):** `dynamic import()` per layar + `manualChunks` (vendor/react/supabase terpisah); target chunk awal <500 kB.

### F10-A2-08 (K-4, observasi) — Cakupan uji LayarPelayan tipis

- **Lokasi Berkas & Baris:** `aplikasi/src/layar/pelayan/LayarPelayan.tsx` (259 baris) vs `LayarPelayan.test.tsx` (65 baris, 3 uji)
- **Deskripsi Masalah:** Peran `pelayan` (pesanan meja, status pesanan, voucher pelanggan) hanya dilindungi 3 uji, jauh di bawah kedalaman kasir (23 berkas) — padahal menyentuh alur pesanan lintas peran.
- **Langkah / Perintah Reproduksi:** `wc -l` + `grep -c "it("` kedua berkas di atas.
- **Dampak Bisnis (Multi-Tenant / Keamanan / Kasir):** Regresi alur pelayan lebih mudah lolos; layar kecil/sederhana sehingga risiko moderat-rendah.
- **Rekomendasi Solusi (Fase 11):** Tambah uji alur pelayan (buat pesanan meja → lacak status → klaim voucher) setara `AlurKasirE2E.test.tsx`.

**Pernyataan kelengkapan:** TIDAK DITEMUKAN CACAT K-1 MAUPUN K-2 AKTIF. Keempat K-3 terdiri dari 2 kesalahan dokumen paket audit + 1 penyimpangan arsitekturUI-terhadap-spesifikasi (penegakan peladen tetap utuh) + 1 celah laten yang terbukti belum terpicu. Seluruh pemeriksa fail-closed terverifikasi lewat uji-diri (peta-ui 6/6, kontras 5/5, kerapatan 5/5, antarmuka 10/10, mutasi-app 81/81).

## 4. Kesimpulan & Rekomendasi untuk Pemilik Platform (Lee)

**Keputusan: lanjut Fase 11, dengan 4 pekerjaan K-3 terjadwal (bukan blocker).** Fondasi frontend kokoh dan jujur: kontrak Peta UI konsisten mesin (32 RPC × migrasi + 8 izin × kamus terverifikasi silang manual, Lampiran A), kasir luring benar-benar tahan-putus (IndexedDB + idempoten + sanitasi + dialog StatusAntrean lengkap + anti-dobel e2e), aksesibilitas AA 100% dengan keyboard/modal/kerapatan terukur, dan 1011 uji + 81 mutasi + typecheck + build semuanya hijau. Perbaiki dulu 2 jalur dokumen (F10-A2-01/02, <15 menit) agar auditor berikutnya bisa reproduksi verbatim; di Fase 11, kabelkan `TombolAksi` atau amandemen spesifikasinya (F10-A2-05), keraskan regex sanitasi + putuskan nasib voucher offline (F10-A2-06), pecah bundel JS (F10-A2-07), dan tebali uji pelayan (F10-A2-08). Audit ini read-only terhadap kode (`git status` kosong; satu-satunya artefak baru adalah berkas laporan ini untuk keterbacaan lintas-sesi).

---

# LAMPIRAN BUKTI MENDALAM (hasil baca penuh + eksekusi nyata)

## Lampiran A — Peta UI: verifikasi silang manual 57 aksi

- `grep -c "id: '" aplikasi/src/lib/aksi.ts` → **57** (klop dengan `docs/PETA_UI.md`: 42 tulis / 7 baca / 8 navigasi; 34 izin-spesifik; 19 konfirmasi; 34 audit).
- 8 izin unik (`atur_pengaturan`, `beri_diskon`, `kelola_pegawai`, `lihat_laporan`, `pakai_voucher`, `tutup_kas`, `ubah_stok`, `void_sebelum_dapur`) — masing-masing ditemukan di 6–18 berkas migrasi; kamus `izin_kode` di `0005_izin_berjenjang.sql:17-31` terkonfirmasi.
- 32 RPC unik — masing-masing ditemukan di 1–6 berkas migrasi (`bayar_pesanan` 3, `hitung_total` 5, `tutup_shift` 5, `verifikasi_pin` 6, sisanya 1–3). Tidak ada RPC gantung.
- `DAFTAR_LAYAR` (`layar.ts`, 416 baris): tiap kontrak memuat 7–8 keadaan (`kosong/memuat/gagal/menunggu/tidakPunyaAkses/dataSebagian/berhasil` + opsional `konflik`), peran, `masukDari`, `berkasUji`, `naskahJalan` — cakupan PRD M1–M12 divalidasi peta-ui (Aturan 6, HIJAU).
- Aturan 7 hanya menolak `<button>` mentah di `layar/` kecuali `LayarContoh.tsx` dan `*.test.*` (`peta-ui.py:397-403`) — celahnya adalah `<Tombol>` yang tak terikat registri (lihat F10-A2-05).

## Lampiran B — Tombol: sensus lengkap

- `<button` mentah di `layar/` non-uji: **3** (semua `LayarContoh.tsx:119,137,150`, dikecualikan sah).
- `<Tombol` di `layar/` non-uji: **401** (`Tombol.tsx` 55 baris: tanpa `aksiId`, tanpa cek izin).
- `TombolAksi` di produksi: **0** (`TombolAksi.tsx:36-46` logika gating tidak pernah dieksekusi di luar uji).
- Gating pengganti terverifikasi: `Navigasi.ambilMenuPeran` (7 cabang peran, `Navigasi.tsx:24-72`); layar diganti via state internal `layarAktif` (tanpa URL-router → injeksi rute via UI tidak dimungkinkan); `TidakPunyaAkses.tsx` tersedia; contoh proteksi fitur: `DiskonManual` (batas izin + PIN atasan), `CabutAkses` (ketik 'CABUT', `CabutAkses.tsx:45,162`), `VoucherKasir` (PIN wajib, `VoucherKasir.tsx:141-150`).

## Lampiran C — Antrean luring: baca penuh + sweep produsen

- `antrean-offline.ts` (543 baris) dibaca penuh: DB IndexedDB `antrean_kirim` + indeks unik `kunciIdempoten` (`:147-176`); `tambahKeAntrean` sanitasi-otomatis + tolak-dobel-lokal (`:188-199`); FIFO `ambilSemuaAntrean` (`:247-293`); `prosesAntrean` sekuensial + berhenti-anggun saat `network/fetch/koneksi`/`!navigator.onLine` (`:500-541`); fallback memori di semua kegagalan DB; siaran `resto:antrean-berubah`.
- `useAntrean.ts` (401 baris) dibaca penuh: `penanganDefault` menangani `simpan_pesanan` (insert + 23505→sukses + `hitung_total`), `bayar_pesanan` (RPC + kunci stabil), `pakai_voucher` (**membaca `m.pinKasir`** — lihat F10-A2-06); auto-sync event `online` (`:301-328`); pesan manusia "menunggu dikirim N" (`:358-378`); pengaman proses-ganda `sedangProsesRef`.
- Sweep produsen: satu-satunya pemanggil produksi `App.tsx:127-142` → jenis `simpan_pesanan`, muatan `{pesananId,penyewaId,cabangId,mejaId,tipe,shiftId,items}` — **tanpa PIN** ✅.
- Sweep storage: kunci tulis hanya `sajian.tema/kerapatan`, bahasa, `resto.kasir.draf/tagihan-terbuka.*`, `resto.antrean-terakhir.dapur`, id/nama perangkat, sesi (`sessionStorage`, tanpa PIN). Draf kasir/tagihan/KDS berisi data transaksi, bukan kredensial ✅.
- `StatusAntrean.tsx` (580 baris) dibaca penuh: `role="status" aria-live="polite"`, 3 lencana hitungan, tombol massal (`btn-coba-lagi-semua-gagal`, `btn-kirim-antrean-sekarang`), dialog `Lapis` (peringatan ART-8, retry massal, daftar item per-status, galat jujur + hitungan percobaan + waktu terakhir, hapus 2-langkah `konfirmasi-hapus-*`, bersihkan-sukses), keadaan kosong; dipakai produksi di `LayarKasir.tsx` ✅. 8 uji T10-03 + 4 uji mode ringkas/offline lulus.

## Lampiran D — Aksesibilitas: kontras, keyboard, kerapatan

- Kontras (data penuh §2-2a′): AA 130/130; AAA-ketat 70/130 (60 di bawah 7:1 — seluruhnya teks redup/label di tema terang + sebagian aksen-lembut). Tertinggi: Kontras Tinggi 21.00:1; redup terendah: Terang 5.43:1 (tetap >4.5 ✅).
- Keyboard/modal: `Lapis.tsx:36` Esc→tutup; jebak-Tab + pulihkan fokus (`:43-77`); `role="dialog" aria-modal`; kunci-scroll body; klik-latar tutup + `stopPropagation` panel. `PemilihRingkas.tsx:63-69` Esc tutup+fokus-pulang, klik-luar tutup-tanpa-rampas-fokus. Diuji `komponen.test.tsx:96-137`, `PemilihRingkas.test.tsx:57-102` ✅.
- Kerapatan: blok `[data-density="padat"]` (`tema.css:496-536`) menurunkan 10 token `--s-*` + aturan 18 kelas aplikasi; uji CSS mengukur angka (`kerapatan-css.test.ts`: tinggi menyusut, lebar tetap, sentuh ≥44px, warna tak berubah) ✅.
- Kustom merek terkendali: `Tampilan.tsx:53-123` menolak warna aksen <4.5:1 dengan pesan + label `WCAG AA Lolos` (`Tampilan.test.tsx:57-67`) ✅.
- Bahasa/arah: paritas 283 kunci (id/en/zh/ar); font CJK/Arab + total 461 KB <650 KB ✅.

## Lampiran E — Layar: integritas per area + konflik versi

- Hitung uji: kasir 23 · dapur 6 · pelayan 1 · laporan 8 · pengaturan 18 · masuk 6 · pelanggan-publik 4 · voucher 3 · platform 1 · contoh 2 · komponen 14 · hook 9 · lib 21 · bahasa 1 · gaya 1 · e2e 2 · akar+akses 2 (`App`, `TidakPunyaAkses`) = **123 berkas** ✅.
- 8 layar wajib pengaturan terverifikasi ada + beruji: `Identitas` (validasi logo≤2MB/banner≤3MB/JPG-PNG-WebP, nama 1–120 char; galat tanpa reset form `:188-212`), `Tampilan` (10 tema + validasi AA), `Operasional`, `Meja`, `KelolaPegawai`, `SesiAktif` (3 dialog `Lapis`), `CabutAkses` (ketik-CABUT), + `laporan/Peringatan` (669 baris + 9 uji).
- Konflik versi tidak menghilangkan input: `Menu.tsx:348-352` gagal → `setPesanGalat + return` (modal tetap buka, `editKategoriData` utuh); `setModalKategoriBuka(false)` hanya di jalur sukses (`:382`); `versi_lama: diubah_pada` terkirim (`:324,346,484,564`); `Pratinjau.tsx` pola draf-vs-aktif + reset eksplisit; `Identitas.test.tsx:176` menguji kegagalan simpan ✅.

## Lampiran F — Mutasi & ketahanan eksekusi

- `uji-mutasi-app.mjs`: 81 mutasi perilaku (uang, diskon, void, PDP, struk/SALINAN, pajak-server, tarif T-027, printer ESC/POS+tiket, shift/kas, voucher) — semua MERAH; kontrol hijau ✅.
- Uji-diri pemeriksa: peta-ui 6/6 · kontras 5/5 · kerapatan 5/5 · antarmuka 10/10 ✅ (semua fail-closed).
- `npm test`: 123/123 berkas, 1011/1011 uji; satu-satunya noise log adalah `window.alert` jsdom yang memang tidak diimplementasikan (di `AlurKasirE2E`, uji tetap lulus — bukan kegagalan).
- Insiden eksekusi auditor (transparansi): `mati-mendadak.spec.ts` sempat "no tests, 1 error" saat dijalankan dari direktori salah (repo-root tanpa config); dari `aplikasi/` → 7/7 lulus. Bukan cacat produk.

## Lampiran G — Jejak perintah (ringkas, dapat diulang)

```bash
git branch --show-current && git status --short && git log --oneline -2
python3 alat/peta-ui.py --periksa && python3 alat/peta-ui.py --uji-diri
python3 aplikasi/alat/uji-kontras.py && python3 aplikasi/alat/uji-kontras.py --uji-diri
python3 aplikasi/alat/periksa-kerapatan.py && python3 aplikasi/alat/periksa-antarmuka.py --uji-diri
cd aplikasi && npm ci && npm test -- --run && npx vitest run uji/e2e/luring.spec.ts \
  && npx vitest run uji/e2e/mati-mendadak.spec.ts && npm run typecheck && npm run build && cd ..
node aplikasi/alat/uji-mutasi-app.mjs
grep -rn "TombolAksi" aplikasi/src --include="*.tsx" | grep -v test   # -> hanya definisi
grep -rn "tambahKeAntrean" aplikasi/src --include="*.tsx" | grep -v test  # -> hanya App.tsx:127
```

---
*Disusun read-only terhadap kode; artefak baru satu berkas laporan ini (agar agen sesi lain dapat membaca via GitHub). Verdict: **PERLU PERBAIKAN** (4×K-3 non-blocker + 4×K-4).*
