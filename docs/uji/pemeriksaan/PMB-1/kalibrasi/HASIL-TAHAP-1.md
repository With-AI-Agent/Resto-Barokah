# Hasil kalibrasi Tahap 1 — PMB-1 (potongan F-17)

**Dibuka oleh:** Perencana `arena/01a0e747-resto-barokah` · **Tanggal:** 2026-09-29 (16:32 WIB) · **Syarat pembukaan:** kartu
pemeriksa `kartu/K-F-17.md` (sesi `arena/01a0eb76`) dan kartu hakim `kartu/H-F-17.2.md` (sesi `arena/01a0ec1b`) sudah masuk;
seluruh 17 potongan Tahap 1 berstatus DIHAKIMI di `PAPAN.md` (integrasi terakhir `arena/01a0ec4d`, HAKIM F-15).

**Integritas kunci:** `openssl enc -d -aes-256-cbc -pbkdf2 -iter 200000 -a -in kalibrasi/KUNCI-TAHAP-1.enc … | sha256sum` →
`349941f05cef83137d899a062b9ef98f8b39c57455df7ac24a69903676d6a542` = isi `KUNCI-TAHAP-1.sha256` (kunci tidak berubah sejak bahan
dibuat 2026-09-28). Berkas kunci terbuka **tidak** di-commit (protokol §7); yang dicatat di sini hanya hasil pencocokan.

## 1. Kunci vs temuan (6 cacat tanaman)

| # | Berkas bahan | Lokasi | Kelas kunci | Cacat yang ditanam | Temuan pemeriksa | Tingkat pemeriksa | Cocok? |
|---|---|---|---|---|---|---|---|
| 1 | `PRD-cuplikan.md` | M6 butir Diskon | K-2 | "bawaan sampai tiga diskon per transaksi tanpa batas total" | `PMB1-F-193` | K-2 | ✅ tepat |
| 2 | `PRD-cuplikan.md` | M6 butir pembatalan terakhir | K-2 | "void masih diperbolehkan dengan PIN owner" sesudah pembayaran pertama | `PMB1-F-192` | K-2 | ✅ tepat |
| 3 | `KEAMANAN-cuplikan.md` | §6 butir 4 | K-3 | batas percobaan per akun "10×/15 menit" (kontradiksi dengan tabel §7 di berkas yang sama) | `PMB1-F-195` | K-3 | ✅ tepat (kontradiksi internal ikut ditangkap) |
| 4 | `KEAMANAN-cuplikan.md` | §7 tabel umur sesi | K-2 | pemilik platform "30 hari" (asli 8 jam) | `PMB1-F-197` | K-2 | ✅ tepat |
| 5 | `ROADMAP-cuplikan.md` | T7-04 DoD vs bukti | K-3 | DoD menuntut "disaksikan pemilik … berita acara", bukti hanya kode & uji → klaim vs kenyataan | `PMB1-F-200` | K-3 | ✅ tepat |
| 6 | `ROADMAP-cuplikan.md` | kutipan kepala | K-4 | "128/128 berkas uji SQL" (kenyataan 132/132) | `PMB1-F-199` | K-3 | ✅ ditemukan; tingkat satu anak tangga lebih berat dari kunci (Hakim mempertahankan K-3 — pembaca yang menjalankan uji akan meragukan seluruh baris bukti; perbedaan dicatat, tidak diubah) |

**Tingkat deteksi: 6 dari 6 (100 %)** — K-2 3/3 · K-3 2/2 · K-4 1/1. Kesepakatan tingkat: 5/6 tepat, 1/6 lebih berat satu anak tangga.

## 2. Temuan F-17 di luar kunci (4 baris)

| Temuan | Putusan Hakim | Pencocokan Perencana | Tindakan |
|---|---|---|---|
| `PMB1-F-194` (PRD M7 "bawaan `false`/fleksibel" vs ROADMAP T7-04 `[x]` "hanya dalam shift terbuka") | TERVERIFIKASI (K-3, dengan nuansa) | **Bukan tanaman** — M7 disalin utuh dari `docs/PRD.md:145`, T7-04 DoD sama dengan `docs/ROADMAP.md:1548-1552`; ketegangan itu **nyata pada dokumen asli** dan **sudah tercatat** sebagai `PMB1-F-037` (K-2, potongan F-03: baris 145 diganti tanpa entri keputusan) | **Bonus, bukan palsu.** Ditutup sebagai duplikat `PMB1-F-037`; perbaikan mengikuti induk (siklus status tidak mengizinkan TERVERIFIKASI → DUPLIKAT, maka lewat DIPERBAIKI → DITUTUP dengan catatan) |
| `PMB1-F-196` (kalimat "penyatuan ke tabel `percobaan_masuk` adalah RENCANA Fase 1B" disebut basi) | **PALSU** (Hakim membuktikan jalur masuk asli belum memakai tabel itu) | Bukan tanaman; kalimat memang disalin utuh dan masih benar | **Temuan palsu: 1** (sudah PALSU, tidak diubah) |
| `PMB1-F-198` (KEAMANAN §7 "kunci otomatis hanya berlaku di luar jam aktif" membantah diri sendiri) | TERVERIFIKASI (K-3) | **Bukan tanaman** — kalimat identik ada di `docs/KEAMANAN.md:123` (disalin utuh); cacat nyata dan **sudah tercatat** sebagai `PMB1-F-162` (K-3, potongan F-11: "tiga tafsir satu aturan", mengutip KEAMANAN:123) | **Bonus, bukan palsu.** Ditutup sebagai duplikat `PMB1-F-162` (jalur yang sama seperti F-194) |
| `PMB1-F-201` (blok T7-05 merujuk `aplikasi/src/layar/kas/` yang tidak ada dan `0085_ringkasan_harian.sql` yang tidak memuat penanda tengah malam) | TERVERIFIKASI (K-4) | **Bukan tanaman, bukan dokumen proyek** — blok T7-05 adalah **kontrol buatan Perencana** (tidak ada di ROADMAP asli); jalur komponen yang saya tulis memang salah (komponen sebenarnya `aplikasi/src/komponen/PengingatShift.tsx`, penanda tengah malam di `0049_pengingat_shift.sql`). Pemeriksa menangkap kesalahan penyusun bahan | **Bonus, bukan palsu.** Ditutup dengan catatan "cacat bahan kontrol"; tidak ada artefak proyek yang perlu diperbaiki |

## 3. Angka ringkas

| Ukuran | Nilai |
|---|---|
| Cacat tanaman | 6 (K-2 3 · K-3 2 · K-4 1) |
| Ditemukan | **6/6 = 100 %** |
| Temuan palsu (setelah Hakim) | 1 dari 10 baris (`PMB1-F-196`, semula K-3) |
| Bonus (cacat nyata yang tidak disengaja / duplikat temuan asli) | 3 (`F-194` → induk `F-037`, `F-198` → induk `F-162`, `F-201` → cacat bahan kontrol) |
| Kandidat yang dibatalkan pemeriksa sendiri sebelum dicatat (refutasi) | 2 (K-F-17 §8) |
| Usaha | pemeriksa ±55 menit (±35 perintah) · hakim ±100 menit (±70 perintah, 5 mutan merah, suite SQL penuh) |

## 4. Tafsir (jujur tentang batasnya)

- Angka 100 % diukur pada **satu sesi pemeriksa** (`arena/01a0eb76`) atas bahan ±120 baris dengan 6 cacat — contoh kecil; literatur inspeksi
  formal (Fagan, Capers Jones; rancangan §14) menempatkan 60–90 % sebagai kisaran wajar. Hasil ini berarti **jalur kerja pemeriksa (pertanyaan
  pemicu §4a + pembandingan silang ke kode & keputusan Lee + refutasi sendiri) tajam pada bahan itu**, bukan jaminan bahwa 16 potongan lain
  (pemeriksa berbeda) mencapai angka yang sama. Bahan Tahap 2 akan memakai cacat tanaman **di kode/skema**, bukan dokumen, agar ukuran ini
  lebih dekat ke risiko nyata.
- Kualitas lebih menonjol pada **rasio palsu yang rendah** (1/10) dan **3 bonus** yang semuanya benar (dua di antaranya ternyata kembar temuan
  asli dari potongan lain — bukti bahwa pemeriksa bekerja lintas dokumen, bukan hanya membaca cuplikan).
- Kesepakatan tingkat 5/6: satu cacat K-4 dinilai K-3. Arah kesalahan = lebih berat, bukan meremehkan; tidak perlu koreksi kalibrasi tingkat.
- Kesalahan penyusun bahan (#F-201) dicatat sebagai pelajaran Perencana: blok kontrol harus diperiksa jalurnya dengan `ls` sebelum dikunci
  (aturan yang sama seperti kontrak bukti `PROMPT_GILIRAN.md` §4 sesudah `PMB1-F-202`).

## 5. Tindakan pada Buku Besar (oleh Perencana, sesuai rancangan §13 butir "kalibrasi")

- `PMB1-F-192`, `F-193`, `F-195`, `F-197`, `F-199`, `F-200` → DIPERBAIKI ("kalibrasi: cacat tanaman #n", sha = commit pembukaan kunci) → DITUTUP.
- `PMB1-F-194`, `F-198` → DIPERBAIKI → DITUTUP dengan catatan "duplikat `PMB1-F-037` / `PMB1-F-162`; perbaikan mengikuti induk".
- `PMB1-F-201` → DIPERBAIKI → DITUTUP dengan catatan "cacat bahan kontrol T7-05 buatan Perencana; bukan artefak proyek".
- `PMB1-F-196` tetap PALSU.
- `PAPAN.md` F-17 tetap DIHAKIMI; catatan ditambah "KALIBRASI DIBUKA … 6/6".
- Dengan ini **tidak ada baris F-17 yang menahan gerbang Tahap 1** (`python3 alat/periksa-pemeriksaan.py --gerbang 1`); yang menahan hanya
  K-1/K-2 TERVERIFIKASI di F-01…F-16 (52 baris) → fase PEMBANGUN.
