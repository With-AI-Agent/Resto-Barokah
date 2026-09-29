# PAPAN POTONGAN — PMB-1 (Pemeriksaan Mendalam Bertahap, putaran 1)

> Kontrak: `docs/uji/pemeriksaan/RANCANGAN_PEMERIKSAAN_BERTAHAP.md` (disetujui Lee 2026-09-28).
> Cara satu giliran: `docs/uji/pemeriksaan/PROMPT_GILIRAN.md`. Penjaga mesin: `python3 alat/periksa-pemeriksaan.py`.
> **Satu baris = satu potongan = satu giliran chat.** Ambil potongan **BELUM** pertama pada tahap yang sedang berjalan
> (atau yang ditunjuk Lee), tulis **DIKLAIM** + sesi + tanggal, commit, baru bekerja.
>
> Status potongan: `RENCANA` (belum dirinci) → `BELUM` → `DIKLAIM` → `SELESAI` (kartu `kartu/K-<ID>.md` ada) → `DIHAKIMI`
> (kartu `kartu/H-<ID>.md` ada & tidak ada temuan `BARU` dari potongan ini). Lensa: L1 keamanan · L2 uang/data · L3 kesesuaian
> baseline · L4 kejujuran uji/bukti · L5 pengalaman pengguna & aksesibilitas · L6 operasional/pemulihan (rincian lensa:
> `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §4 dan rancangan §8). Ukuran menuruti P1 (±200–400 baris kode / 8–12 halaman dokumen).
>
> **Tahap yang sedang berjalan: 1 (Fondasi).** Dibuka 2026-09-28 setelah uji coba F-01 oleh dua sesi independen (arena/01a0e807 & 01a0e806)
> dan perbaikan mekanisme (kartu ulangan `K-<ID>.<n>.md`, status `DUPLIKAT`, potongan ditunjuk Lee per sesi). Ulangan independen
> potongan yang sama **diperbolehkan** dan berguna sebagai pembanding, tetapi bukan pengganti Hakim.

## Tahap 1 — Fondasi (gerbang KERAS → tag `fondasi-baseline-<tanggal>`)

| ID | Tahap | Potongan | Lingkup (berkas / baris) | Lensa wajib | Ukuran | Status | Sesi | Tanggal |
|---|---|---|---|---|---|---|---|---|
| F-01 | 1 | DISCOVERY — masalah, pengguna, batasan dunia nyata; asumsi tentang kedai, pajak, perangkat | `docs/DISCOVERY.md` | L3 L5 L6 | 310 baris | DIHAKIMI | HAKIM: dua hakim paralel di arena/01a0e834-resto-barokah (putusan utama + pendapat kedua, kartu H-F-01) — 7 TERVERIFIKASI · 1 DUPLIKAT; DIHAKIMI ditetapkan Perencana saat integrasi 2026-09-29 setelah temuan hakim PMB1-F-009 dipindah ke G-04 (alasan hakim menahan status hilang) · pemeriksa: arena/01a0e807 K-F-01 + arena/01a0e806 K-F-01.2 | 2026-09-28 |
| F-02 | 1 | PRD bagian 1 — tujuan, pengguna, janji M1–M6 + aturan bisnis di dalamnya | `docs/PRD.md` baris 1–138 | L2 L3 L5 | ±140 baris | SELESAI | arena/01a0e836-resto-barokah (K-F-02 + kembar K-F-02.2 + giliran ke-3 K-F-02.3) | 2026-09-28 |
| F-03 | 1 | PRD bagian 2 — janji M7–M12, non-goals, kasus tepi, metrik | `docs/PRD.md` baris 139–323 | L1 L2 L3 | ±185 baris | SELESAI | arena/01a0e839-resto-barokah (K-F-03) + arena/01a0e839-resto-barokah (ulangan independen K-F-03.2, agent ke-2 di cabang yang sama, dikerahkan Lee) + arena/01a0e839-resto-barokah (ulangan independen ke-2 K-F-03.3, agent ke-3 di cabang yang sama, dikerahkan Lee) | 2026-09-28 |
| F-04 | 1 | TECH_SPEC bagian 1 — stack, arsitektur, struktur folder, skema data, kontrak API | `docs/TECH_SPEC.md` §0–§5 (baris 1–266) | L1 L2 L3 | ±265 baris | DIKLAIM | arena/01a0ea92-resto-barokah | 2026-09-29 |
| F-05 | 1 | TECH_SPEC bagian 2 — env, integrasi, keamanan ringkas, ART-1…15, batas gratis, DoD, keputusan | `docs/TECH_SPEC.md` §6–§13 (baris 267–475) | L1 L3 L4 L6 | ±210 baris | SELESAI | arena/01a0ea92-resto-barokah (K-F-05) | 2026-09-29 |
| F-06 | 1 | KEAMANAN — prinsip, ancaman, identitas, perangkat, PIN, sesi, otorisasi, uang, audit, PDP, matriks uji | `docs/KEAMANAN.md` | L1 L2 L3 | 232 baris | BELUM | — | — |
| F-07 | 1 | SPESIFIKASI_UI + PETA_UI — kontrak layar (7 keadaan, aksesibilitas, bahasa) vs janji PRD | `docs/SPESIFIKASI_UI.md`, `docs/PETA_UI.md` | L3 L5 | 353 baris | BELUM | — | — |
| F-08 | 1 | ROADMAP bagian 1 — struktur, aturan, Fase 0–1C (klaim bukti, DoD, "klaim vs kenyataan") | `docs/ROADMAP.md` baris 1–658 | L3 L4 | ±660 baris (tabel) | BELUM | — | — |
| F-09 | 1 | ROADMAP bagian 2 — Fase 2–6 | `docs/ROADMAP.md` baris 659–1518 | L3 L4 | ±860 baris (tabel) | BELUM | — | — |
| F-10 | 1 | ROADMAP bagian 3 — Fase 7–11 + penutup & daftar periksa akhir | `docs/ROADMAP.md` baris 1519–2239 | L3 L4 | ±720 baris (tabel) | BELUM | — | — |
| F-11 | 1 | DECISIONS_LOG bagian 1 — keputusan awal & Putaran 1–13 (yang bertentangan / tidak tercermin di PRD & TECH_SPEC) | `docs/DECISIONS_LOG.md` baris 1–833 | L3 | ±830 baris (log) | BELUM | — | — |
| F-12 | 1 | DECISIONS_LOG bagian 2 | `docs/DECISIONS_LOG.md` baris 834–1659 | L3 | ±825 baris (log) | BELUM | — | — |
| F-13 | 1 | DECISIONS_LOG bagian 3 | `docs/DECISIONS_LOG.md` baris 1660–2475 | L3 | ±815 baris (log) | BELUM | — | — |
| F-14 | 1 | DECISIONS_LOG bagian 4 — sampai keputusan terbaru | `docs/DECISIONS_LOG.md` baris 2476–3276 | L3 | ±800 baris (log) | BELUM | — | — |
| F-15 | 1 | AGENT_OPERATING_GUIDE + TERTANGGUH — aturan kerja agent, butir tertangguh (siapa boleh menutup) | `docs/AGENT_OPERATING_GUIDE.md`, `docs/TERTANGGUH.md` | L3 L4 L6 | 459 baris | BELUM | — | — |
| F-16 | 1 | REKAM_PESAN_PEMILIK — apakah setiap kata Lee punya jejak keputusan/tugas/bukti | `docs/teknis/REKAM_PESAN_PEMILIK.md` | L3 | 567 baris | BELUM | — | — |
| F-17 | 1 | **Kalibrasi Tahap 1** — bahan cacat tanaman (jumlah, lokasi & kelas dirahasiakan) | `docs/uji/pemeriksaan/PMB-1/kalibrasi/bahan-tahap-1/` | L1 L2 L3 L4 | ±120 baris | BELUM | — | — |

Catatan Tahap 1: rancangan §4a memperkirakan 10–12 potongan; papan nyata = **17** karena DECISIONS_LOG (3.276 baris) dan ROADMAP
(2.239 baris) tidak jujur bila dipaksa satu potongan. Setiap potongan ROADMAP wajib menyisir `REGRESI_WAJIB.md` bagian B
untuk rentang barisnya.

## Tahap 2 — Per fase (dirinci setelah baseline dikunci; ID `P-<fase>-<nn>`)

| ID | Tahap | Potongan | Lingkup (berkas / baris) | Lensa wajib | Ukuran | Status | Sesi | Tanggal |
|---|---|---|---|---|---|---|---|---|
| P-0-00 | 2 | Fase 0 — rangka kerja, CI, alat sesi (dipotong per kelompok alat) | `alat/`, `.github/workflows/`, `PRO.md` | L4 L6 | dirinci | RENCANA | — | — |
| P-1-00 | 2 | Fase 1 — database, keamanan & uang (dipotong per kelompok tabel/RPC: identitas & peran · menu · pesanan · pembayaran · jejak audit · uang & pembulatan) | `supabase/migrations/0001–0017`, `supabase/tes/` | L1 L2 L4 | dirinci | RENCANA | — | — |
| P-1B-00 | 2 | Fase 1B — akun, perangkat, PIN, sesi, jejak | `supabase/migrations/0018–0030` (perkiraan) | L1 L4 | dirinci | RENCANA | — | — |
| P-1C-00 | 2 | Fase 1C — kontrak UI & peta aksi | `aplikasi/src/kontrak/`, `docs/PETA_UI.md` | L3 L5 | dirinci | RENCANA | — | — |
| P-2-00 | 2 | Fase 2 — masuk & kerangka aplikasi | `aplikasi/src/layar/masuk/`, `aplikasi/src/lib/` | L1 L5 | dirinci | RENCANA | — | — |
| P-3-00 | 2 | Fase 3 — pesanan & kasir (M4) | `aplikasi/src/layar/kasir/` (perkiraan) | L2 L5 | dirinci | RENCANA | — | — |
| P-4-00 | 2 | Fase 4 — dapur/KDS & stok (M5, M9) | `aplikasi/src/layar/dapur/` (perkiraan) | L2 L5 | dirinci | RENCANA | — | — |
| P-5-00 | 2 | Fase 5 — pembayaran & pembatalan (M6) | `aplikasi/src/layar/bayar/` (perkiraan), RPC bayar/void | L1 L2 | dirinci | RENCANA | — | — |
| P-6-00 | 2 | Fase 6 — cetak termal ESC/POS (ART-7) | `aplikasi/src/lib/cetak/` (perkiraan) | L5 L6 | dirinci | RENCANA | — | — |
| P-7-00 | 2 | Fase 7 — kas & shift, laporan harian (M7, M8) | RPC shift/kas, `aplikasi/src/layar/kas/` (perkiraan) | L2 L4 | dirinci | RENCANA | — | — |
| P-8-00 | 2 | Fase 8 — katalog pelanggan & voucher (M10; ART-5, ART-10) | `aplikasi/src/layar/voucher/`, RPC voucher | L1 L2 | dirinci | RENCANA | — | — |
| P-9-00 | 2 | Fase 9 — pengaturan tanpa koding & multi-cabang (M1, M2, M3, M11) | `aplikasi/src/layar/pengaturan/`, `aplikasi/src/layar/platform/`, migrasi 0079 | L1 L3 | dirinci | RENCANA | — | — |
| P-10-00 | 2 | Fase 10 — ketahanan & keamanan lanjutan (M12, K4; ART-8) | migrasi 0080–0087, `supabase/functions/`, cadangan & denyut | L1 L6 | dirinci | RENCANA | — | — |
| P-11-00 | 2 | Fase 11 — **belum dikerjakan** (REKAM §31): yang diperiksa = instrumennya (skenario uji terima, panduan pegawai, serah terima, deploy) | `docs/uji/UJI_TERIMA_G1.md`, `docs/ops/PANDUAN_PEGAWAI.md`, `docs/ops/DEPLOY.md`, `docs/ops/SERAH_TERIMA_G1.md` | L3 L5 L6 | dirinci | RENCANA | — | — |

## Tahap 3 — Lintas-fase (sambungan)

| ID | Tahap | Potongan | Lingkup (berkas / baris) | Lensa wajib | Ukuran | Status | Sesi | Tanggal |
|---|---|---|---|---|---|---|---|---|
| X-01 | 3 | Uang hulu-hilir: item → pajak/service → diskon/voucher → bayar → kas → laporan (pembulatan, satu rupiah) | RPC & layar yang menyentuh nominal (ditentukan dari Matriks) | L2 L4 | dirinci | RENCANA | — | — |
| X-02 | 3 | Multi-penyewa & RLS: setiap tabel, setiap peran, setiap RPC `security definer` | seluruh `supabase/migrations/` (kebijakan) + `alat/periksa-keamanan-sql.py` | L1 | dirinci | RENCANA | — | — |
| X-03 | 3 | Offline & idempoten: antrean, kunci idempoten, konflik, pemulihan listrik | `aplikasi/src/lib/` antrean/offline, RPC berkunci | L2 L6 | dirinci | RENCANA | — | — |
| X-04 | 3 | Akun, perangkat, sesi, PIN: dari pendaftaran sampai pencabutan (tangga pemulihan KEAMANAN §4b) | migrasi 0018+, 0086, layar masuk/perangkat | L1 | dirinci | RENCANA | — | — |
| X-05 | 3 | Privasi & UU PDP: data pelanggan, persetujuan, anonimisasi, retensi, ekspor | tabel pelanggan/voucher, kebijakan, teks persetujuan | L1 L3 | dirinci | RENCANA | — | — |
| X-06 | 3 | Kinerja & batas paket gratis: Supabase/Cloudflare/Resend, denyut, peringatan 70/90 % | `docs/uji/KINERJA_DAN_BATAS.md`, Edge Functions, cron | L6 | dirinci | RENCANA | — | — |
| X-07 | 3 | Bahasa & aksesibilitas lintas layar: kamus 4 bahasa, kontras, fokus, ukuran sentuh | `aplikasi/src/` kamus & komponen, `aplikasi/alat/periksa-bahasa.py` | L5 | dirinci | RENCANA | — | — |

## Tahap 4 — Menyeluruh (petugas: Pemeriksa Menyeluruh; potongan = alur ujung-ke-ujung, rancangan §4c)

| ID | Tahap | Potongan | Lingkup (berkas / baris) | Lensa wajib | Ukuran | Status | Sesi | Tanggal |
|---|---|---|---|---|---|---|---|---|
| M-01 | 4 | Lee sebagai pemilik platform: daftar resto → cabang → admin → kode perangkat → pegawai pertama masuk → kuota → nonaktifkan penyewa | alur lintas layar & RPC (dijalankan di pratinjau) | L1 L3 L5 | 1 alur | RENCANA | — | — |
| M-02 | 4 | Owner pusat: masuk 2FA → menu/harga/pajak → laporan lintas cabang → mode dukungan berbatas waktu | alur lintas layar & RPC | L1 L3 L5 | 1 alur | RENCANA | — | — |
| M-03 | 4 | Kasir satu shift penuh: buka kas → pesan → dapur → diskon berizin → bayar tunai & QRIS → struk → void berjenjang → tutup kas | alur lintas layar & RPC | L2 L5 | 1 alur | RENCANA | — | — |
| M-04 | 4 | Dapur/bar: tiket masuk → status masak/saji → stok habis → antrean menumpuk | alur lintas layar & RPC | L5 L6 | 1 alur | RENCANA | — | — |
| M-05 | 4 | Pelanggan: katalog publik → voucher undang-teman → persetujuan privasi → anonimisasi | alur lintas layar & RPC | L1 L5 | 1 alur | RENCANA | — | — |
| M-06 | 4 | Hari buruk: listrik/jaringan putus saat bayar → antrean offline → pulih tanpa dobel; perangkat hilang → cabut; PIN salah 5× | alur lintas layar & RPC | L1 L2 L6 | 1 alur | RENCANA | — | — |
| M-07 | 4 | Isolasi penyewa: dua resto bersamaan — tidak ada data saling terlihat di alur mana pun | dua penyewa di pratinjau, semua layar | L1 | 1 alur | RENCANA | — | — |
| M-08 | 4 | Angka uang hulu-hilir dari kacamata pemilik: satu hari transaksi → laporan harian cocok sampai rupiah | alur lintas layar & RPC + perhitungan tangan | L2 L4 | 1 alur | RENCANA | — | — |

## Tahap 5 — Untuk manusia & operasional (dijalankan "dengan cara pengguna")

| ID | Tahap | Potongan | Lingkup (berkas / baris) | Lensa wajib | Ukuran | Status | Sesi | Tanggal |
|---|---|---|---|---|---|---|---|---|
| D-01 | 5 | Panduan pemilik & pengguna: `PANDUAN_PEMILIK.md`, `PANDUAN_PENGGUNA.md` dijalankan apa adanya | `docs/PANDUAN_PEMILIK.md`, `PANDUAN_PENGGUNA.md` | L5 L6 | dirinci | RENCANA | — | — |
| D-02 | 5 | Panduan pegawai & serah terima (instrumen Fase 11) | `docs/ops/PANDUAN_PEGAWAI.md`, `docs/ops/SERAH_TERIMA_G1.md` | L5 | dirinci | RENCANA | — | — |
| D-03 | 5 | Buku insiden, pemulihan listrik/perangkat, pemulihan cadangan | `docs/teknis/BUKU_INSIDEN.md`, `docs/ops/PEMULIHAN_LISTRIK.md`, `docs/ops/PEMULIHAN_PERANGKAT.md`, `docs/teknis/PEMULIHAN.md` | L6 | dirinci | RENCANA | — | — |
| D-04 | 5 | Deploy, kunci pemilik, alamat publik, langkah pemilik sekarang | `docs/ops/DEPLOY.md`, `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md`, `docs/ops/ALAMAT_PUBLIK.md`, `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`, `docs/ops/SIAP_AKUN_PEMILIK.md` | L1 L6 | dirinci | RENCANA | — | — |

## Tahap 6 — Mesin penjaga & mesin kerja agent

| ID | Tahap | Potongan | Lingkup (berkas / baris) | Lensa wajib | Ukuran | Status | Sesi | Tanggal |
|---|---|---|---|---|---|---|---|---|
| G-01 | 6 | CI & gerbang: apakah setiap pagar benar-benar bisa MERAH; tidak ada penanda lolos-paksa (`or true`, `continue-on-error`); paritas lokal | `.github/workflows/`, `alat/periksa-gerbang-ci.py`, `aplikasi/alat/periksa-semua.sh` | L4 | dirinci | RENCANA | — | — |
| G-02 | 6 | Penjaga dokumen & roadmap (`periksa-*.py` di `alat/`) — dipotong per kelompok | `alat/periksa-*.py` | L4 | dirinci | RENCANA | — | — |
| G-03 | 6 | Penjaga aplikasi & uji mutasi | `aplikasi/alat/`, `aplikasi/alat/uji-mutasi-app.mjs` | L4 | dirinci | RENCANA | — | — |
| G-04 | 6 | Mesin sesi & audit: `lanjut-sesi.py`, `mulai-sesi.py`, `audit-independen.py`, `review-pr.py`, PMB sendiri (`periksa-pemeriksaan.py`) | `alat/lanjut-sesi.py`, `alat/mulai-sesi.py`, `alat/audit-independen.py`, `alat/review-pr.py`, `alat/periksa-pemeriksaan.py` | L4 L6 | dirinci | RENCANA | — | — |

## Tahap 7 — Lapangan & produksi nyata (bersama Lee)

| ID | Tahap | Potongan | Lingkup (berkas / baris) | Lensa wajib | Ukuran | Status | Sesi | Tanggal |
|---|---|---|---|---|---|---|---|---|
| L-01 | 7 | Produksi vs repo: skema Supabase nyata = migrasi; RLS aktif; kunci anon vs service; **data uji tidak ada** (PMB1-F-001) | Supabase dashboard (luar repo) | L1 L6 | 1 sesi Lee | RENCANA | — | — |
| L-02 | 7 | **Bootstrap dari nol (usul Lee):** bersihkan penyewa percontohan → buat pemilik platform → daftar resto → owner → admin → perangkat → pegawai — lewat alur resmi | produksi (luar repo) + `docs/ops/SIAP_AKUN_PEMILIK.md` | L1 L3 L5 | 1 sesi Lee | RENCANA | — | — |
| L-03 | 7 | Cloudflare: header keamanan, HTTPS/HSTS, PWA terpasang di HP, alamat publik | Cloudflare dashboard + HP Lee (luar repo) | L1 L5 | 1 sesi Lee | RENCANA | — | — |
| L-04 | 7 | Rahasia & kunci: secrets GitHub/Cloudflare/Supabase tidak bocor, rotasi tercatat | GitHub/Supabase (luar repo), `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md` | L1 | 1 sesi Lee | RENCANA | — | — |
| L-05 | 7 | Printer termal nyata & perangkat kedua (wadah T11-03/T11-04) | perangkat Lee (luar repo), `docs/uji/UJI_PERANGKAT.md` | L5 L6 | 1 sesi Lee | RENCANA | — | — |
| L-06 | 7 | Cadangan bisa dipulihkan & denyut berjalan | `.github/workflows/cadangan.yml`, `.github/workflows/denyut-harian.yml`, `alat/pulihkan-cadangan.sh` + bukti run | L6 | 1 sesi Lee | RENCANA | — | — |
| L-07 | 7 | Keamanan bersama pemilik (wadah T11-12): skenario `docs/uji/HASIL_UJI_TERIMA_KEAMANAN.md` dijalankan sungguhan | produksi + HP Lee (luar repo) | L1 | 1 sesi Lee | RENCANA | — | — |

## Tahap 8 — Penutup

| ID | Tahap | Potongan | Lingkup (berkas / baris) | Lensa wajib | Ukuran | Status | Sesi | Tanggal |
|---|---|---|---|---|---|---|---|---|
| Z-01 | 8 | Verifikasi ulang seluruh temuan DITUTUP (contoh acak ≥ 20 % + semua K-1/K-2) | `BUKU_BESAR_TEMUAN.md` | L4 | dirinci | RENCANA | — | — |
| Z-02 | 8 | Kalibrasi akhir & pernyataan kesiapan → Fase 11 boleh dimulai | `RINGKASAN_TAHAP-*.md` (dibuat mesin) | L4 | dirinci | RENCANA | — | — |
