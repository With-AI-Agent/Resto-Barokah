# DAFTAR TUNGGU LEE — semua yang menunggu keputusan/tindakan Lee (DIBUAT MESIN, jangan diedit tangan)

> Dibuat oleh `python3 alat/susun-daftar-tunggu-lee.py` dari Buku Besar PMB-1, `docs/ROADMAP.md`, `docs/TERTANGGUH.md`, dan Buku Uji Pemilik.
> Diperbarui otomatis pada setiap integrasi (`alat/pmb-integrasi.py`); CI GAGAL bila berkas ini basi (`--periksa`).
> Kunci K2 "Jaminan Tuntas" (keputusan Lee 2026-09-29): Lee cukup membaca SATU berkas ini — tidak ada yang perlu diingat.

## Ringkasan angka

| Bagian | Isi | Jumlah |
|---|---|---|
| A1 | Masih menunggu keputusan/tindakan Lee | 6 |
| A2 | Sudah diputuskan Lee, menunggu dieksekusi agent | 4 |
| B | Temuan K-1 terbuka | 3 |
| C | Tugas ROADMAP dibuka kembali, masih `[ ]` | 7 |
| D | Centang lama menunggu sensus klaim (⏳ BUKTI-BELUM) | 139 |
| E | Butir tertangguh terbuka | 2 |
| F | Baris Buku Uji belum diisi Lee | 23 |

Temuan terbuka semua tingkat: BARU 14 · TERVERIFIKASI 164 · PERLU-INFO 0 · DIPERBAIKI 4 · **total 182** (gerbang akhir PMB menuntut 0, kecuali DITANGGUHKAN oleh Lee dengan tanggal tinjau).

## A. Keputusan / tindakan yang ditunggu dari Lee (temuan terbuka berpenanda LEE)

### A1. Masih MENUNGGU keputusan/tindakan Lee

| ID | Tingkat | Potongan | Status | Apa yang diminta dari Lee |
|---|---|---|---|---|
| PMB1-F-019 | K-2 | F-02 | TERVERIFIKASI | **MENUNGGU KEPUTUSAN LEE:** (kartu B-F-02 §3, arena/01a0eff7-resto-barokah): membalik dasar pengenaan PBJT berarti MENGUBAH urutan hitungan uang yang DIKUNCI dan disetujui pemilik (TECH_SPEC §13 20… |
| PMB1-F-037 | K-2 | F-03 | TERVERIFIKASI | **MENUNGGU KEPUTUSAN LEE:** (kartu B-F-03 §3, arena/01a0eff7-resto-barokah): pilih arah wajib_shift — (a) kembalikan ketat sesuai versi dikunci c5dbc98: migrasi baru mengubah bawaan `wajib_shift` m… |
| PMB1-F-038 | K-2 | F-03 | TERVERIFIKASI | **MENUNGGU KEPUTUSAN LEE:** HAKIM H-F-03.5 (arena/01a0fc20, kartu `kartu/H-F-03.5.md`, 2026-10-02) mengembalikan F-038 ke TERVERIFIKASI — (A) normalisasi `0095` masih bocor untuk 9 penulisan lain (… |
| PMB1-F-048 | K-2 | F-03 | TERVERIFIKASI | **BUTUH LEE/OPERATOR:** (kartu B-F-03 §3, arena/01a0eff7-resto-barokah): notifikasi owner saat mode dukungan dibuka butuh mekanisme email — kanal email masih ditahan gerbang T-022 (`docs/TERTAN… |
| PMB1-F-128 | K-2 | F-09 | TERVERIFIKASI | **BUTUH LEE/OPERATOR:** uji perangkat nyata T-015 untuk T2-15 — atau keputusan Lee mengembalikan T2-15 ke [ ] (status ROADMAP = wewenang Perencana); kartu B-F-09 §3 · arena/01a0ec8d-resto-barok… |
| PMB1-F-129 | K-2 | F-09 | TERVERIFIKASI | **BUTUH LEE/OPERATOR:** cek Dashboard Supabase → Authentication → SMTP (Enable Custom SMTP) + keputusan kanal T-022 + dua uji manual jalur email — atau keputusan Lee mengembalikan T2-04/T2-05 k… |

Jumlah A1: **6**

### A2. Sudah DIPUTUSKAN Lee — menunggu dieksekusi agent (penanda `KEPUTUSAN LEE <tanggal>:`)

| ID | Tingkat | Potongan | Status | Keputusan Lee & yang harus dikerjakan |
|---|---|---|---|---|
| PMB1-F-001 | K-1 | F-10 | TERVERIFIKASI | **KEPUTUSAN LEE 2026-09-29 (klaster cara masuk = B):** Pembangun menyiapkan perbaikan di kode + uji lokal saja (migrasi baru/kode di balik saklar), TIDAK dipasang ke produksi dan cara masuk Lee tidak berubah sampai Lee memer… |
| PMB1-F-052 | K-1 | P-10-00 | TERVERIFIKASI | **KEPUTUSAN LEE 2026-09-29 (klaster cara masuk = B):** Pembangun menyiapkan perbaikan di kode + uji lokal saja (migrasi baru/kode di balik saklar), TIDAK dipasang ke produksi dan cara masuk Lee tidak berubah sampai Lee memer… |
| PMB1-F-063 | K-1 | F-04 | DIPERBAIKI | **KEPUTUSAN LEE 2026-09-29 = B) — saklar `pengaturan.izin_daftar_perangkat_bebas_peran_berkuasa` bawaan FALSE (0090) dan definisi final `verifikasi_pin_perangkat` (0091) menolak pendaftaran perangkat baru peran berkuasa BILA penyewa sudah punya perangkat aktif (skenario persis F-063, kode `PERANGKAT_BELUM_DISETUJUI`); uji `supabase/tes/daftar_perangkat_beru_peran_berkuasa.sql` (kasus 2 + prasyarat "sudah ada perangkat aktif" eksplisit F-063) dan kasus 7a/7b `verifikasi_pin_perangkat.sql`; probe hakim `bukti/F-03-hakim-owner-perangkat.sql` yang dulu LULUS kini GAGAL — celah tertutup (bukti `bukti/B-F-04-F-063-tertutup.txt`). DISIAPKAN, BELUM DIPASANG (saklar mati) — produksi dan cara masuk Lee tidak berubah sampai Lee memerintahkan pemasangan (REKAM §31 butir 21).:**  |
| PMB1-F-117 | K-2 | F-09 | TERVERIFIKASI | **KEPUTUSAN LEE 2026-09-29 (klaster cara masuk = B):** Pembangun menyiapkan perbaikan di kode + uji lokal saja (migrasi baru/kode di balik saklar), TIDAK dipasang ke produksi dan cara masuk Lee tidak berubah sampai Lee memer… |

Jumlah A2: **4**

## B. Temuan K-1 (berat) yang masih terbuka — wajib 0 sebelum data asli/pilot

| ID | Potongan | Status | Artefak |
|---|---|---|---|
| PMB1-F-001 | F-10 | TERVERIFIKASI | `supabase/migrations/0086_data_awal_dan_autentikasi_perangkat.sql:286` |
| PMB1-F-052 | P-10-00 | TERVERIFIKASI | `supabase/migrations/0087_perbaiki_search_path_kripto_dan_rpc.sql:267-290` |
| PMB1-F-063 | F-04 | DIPERBAIKI | `docs/TECH_SPEC.md:19` (bukti: `aplikasi/src/lib/auth.ts:174-181`; `supabase/migrations/0… |

Jumlah: **3**

## C. Tugas ROADMAP yang DIBUKA KEMBALI (dulu diklaim selesai, ternyata belum) dan masih `[ ]`

| Tugas | Judul | Temuan pembuka | Bukti yang wajib ada sebelum boleh dicentang lagi |
|---|---|---|---|
| T3-01 | Layar kasir: katalog nyata dari database | PMB1-F-130 | `aplikasi/src/layar/kasir/Katalog.test.tsx` (uji pemuatan tabel menu_item basis data nyata, bukan data statis… |
| T3-06 | Pindah meja + status meja | PMB1-F-131 | `supabase/tes/pindah_meja_riwayat.sql`, `aplikasi/src/layar/kasir/PemilihMeja.test.tsx` |
| T3-11 | Layar pesanan pelayan (HP di samping meja) | PMB1-F-133 | `aplikasi/src/layar/pelayan/LayarPelayanAlur.test.tsx`, Buku Uji Pemilik U-11 (skenario sinkronisasi dua pera… |
| T6-02 | Sambungan Web Bluetooth (Android/Windows) | PMB1-F-118 | `aplikasi/src/layar/pengaturan/PasangPrinter.test.tsx` (pengkabelan props `onUjiCetak` & `onSimpan` di App.ts… |
| T6-03 | Sambungan WebUSB (komputer) | PMB1-F-118 | `aplikasi/src/lib/printer/kirim.test.ts`, Buku Uji Pemilik U-16 |
| T6-04 | Cetak struk (header/footer dari pengaturan) | PMB1-F-118 | `aplikasi/src/layar/kasir/LayarKasirCetak.test.tsx`, `aplikasi/src/lib/printer/struk.test.ts` |
| T6-05 | Cetak tiket dapur | PMB1-F-118 | `aplikasi/src/layar/dapur/LayarDapurCetak.test.tsx`, `aplikasi/src/lib/printer/tiket.test.ts` |

Jumlah: **7**

## D. Centang lama `⏳ BUKTI-BELUM` yang menunggu sensus klaim Tahap 2 PMB (belum berbukti menurut aturan K3)

| Fase | Jumlah | ID tugas |
|---|---|---|
| T0 | 14 | T0-00, T0-01, T0-02, T0-03, T0-04, T0-05, T0-06, T0-07, T0-08, T0-09, T0-10, T0-11, T0-13, T0-14 |
| T1 | 30 | T1-01, T1-02, T1-03, T1-04, T1-05, T1-06, T1-07, T1-08, T1-09, T1-10, T1-13, T1-23, T1-24, T1-25, T1-26, T1-27, T1-28, T1-29, T1-30, T1-36, T1-31, T1-32, T1-33, T1-34, T1-35, T1-39, T1-40, T1-41, T1-42, T1-43 |
| T2 | 18 | T2-01, T2-02, T2-03, T2-04, T2-05, T2-06, T2-07, T2-08, T2-09, T2-10, T2-11, T2-12, T2-14, T2-15, T2-16, T2-17, T2-18, T2-19 |
| T3 | 10 | T3-02, T3-03, T3-04, T3-07, T3-08, T3-10, T3-12, T3-14, T3-15, T3-16 |
| T5 | 11 | T5-01, T5-02, T5-03, T5-04, T5-05, T5-06, T5-07, T5-08, T5-09, T5-11, T5-12 |
| T6 | 1 | T6-01 |
| T7 | 12 | T7-01, T7-02, T7-03, T7-04, T7-05, T7-06, T7-07, T7-08, T7-09, T7-10, T7-11, T7-12 |
| T8 | 15 | T8-01, T8-02, T8-03, T8-04, T8-05, T8-06, T8-07, T8-08, T8-09, T8-10, T8-11, T8-12, T8-13, T8-14, T8-15 |
| T9 | 12 | T9-01, T9-02, T9-03, T9-04, T9-05, T9-06, T9-07, T9-08, T9-09, T9-10, T9-11, T9-12 |
| T10 | 16 | T10-01, T10-02, T10-03, T10-04, T10-05, T10-06, T10-07, T10-08, T10-09, T10-10, T10-11, T10-12, T10-13, T10-14, T10-15, T10-16 |

Jumlah: **139** (daftar beku: `docs/uji/pemeriksaan/PMB-1/BUKTI_BELUM_BASELINE.txt`, hanya boleh menyusut)

## E. Butir tertangguh yang masih terbuka (`docs/TERTANGGUH.md`) — hanya Lee yang boleh menutup

| ID | Tanggal | Hal |
|---|---|---|
| T-026 | 2026-09-23 | **Infra uji peramban (Playwright) + langkah CI-nya** |
| T-028 | 2026-09-23 | **Jejak audit untuk CETAK ULANG struk (T5-10) belum ada di peladen** |

Jumlah: **2**

## F. Baris Buku Uji Pemilik yang belum Lee isi hasilnya (`docs/uji/BUKU_UJI_PEMILIK.md`)

Belum diisi: **23** → U-01, U-02, U-03, U-04, U-05, U-06, U-07, U-08, U-09, U-10, U-11, U-12, U-13, U-14, U-15, U-16, U-17, U-18, U-19, U-20, U-21, U-22, U-23

Cara mengisi: bilang di chat `Buku uji baris U-nn: OK` (atau `GAGAL — apa yang terjadi`); agent mencatatnya. Baris `U-nn` yang Lee isi `OK` menjadi bukti sah untuk centang `[x]` ROADMAP (aturan K3).
