# REKONSILIASI PENGHAKIMAN F-08 — dua hakim, satu potongan

> **Kenapa berkas ini ada.** Potongan **F-08** dihakimi **dua kali secara konkuren** pada sesi
> dan cabang yang sama (`arena/01a0eb0d-resto-barokah`) pada 2026-09-29. Lee 2026-09-29:
> *"Biarkan sesi lain kerja dan kamu juga kerja. Jangan saling menimpa dan menghapus hasil kerja
> dan hasil laporan. Aku mau kalian saling melengkapi. Biarkan agent penerima laporan bisa melihat
> hasil dari semuanya."* Kedua kartu **dipertahankan utuh** dan berkas ini menjembatani
> keduanya supaya penerima laporan **tidak perlu menebak angka mana yang benar**.
> Berkas ini **tidak mengganti apa pun**: hanya navigasi + rekonsiliasi angka.

- **Kartu hakim A:** `kartu/H-F-08.md` · commit `8fee61e` (tidak diubah sejak itu)
- **Kartu hakim B:** `kartu/H-F-08.2.md` · commit `ea81fec`
- **PAPAN:** baris F-08 `DIHAKIMI`; kolom Sesi memuat catatan kedua hakim
- **Buku Besar:** kolom Hakim tiap baris F-101…F-116 memuat **kedua** catatan, dipisah tanda `‖`

## 1. Putusan: kedua hakim sepakat

Tidak ada satu pun baris yang berbeda status maupun tingkat. Kolom berikut disalin apa adanya
dari Buku Besar (sumber tunggal, bukan ringkasan):
**16 TERVERIFIKASI · 0 DUPLIKAT · 0 PALSU · 0 PERLU-INFO · 0 koreksi tingkat.**

| Tingkat | Jumlah | Baris |
|---|---|---|
| **K-1** | **0** | — |
| **K-2** | **5** | `PMB1-F-109`, `F-110`, `F-111`, `F-112`, `F-113` |
| **K-3** | **8** | `PMB1-F-101`, `F-102`, `F-103`, `F-104`, `F-106`, `F-107`, `F-114`, `F-115` |
| **K-4** | **3** | `PMB1-F-105`, `F-108`, `F-116` |

## 2. Rekonsiliasi angka yang berbeda di kedua kartu

Tujuh titik di mana kedua hakim mengukur hal sama dan angkanya beda. Semua **diukur ulang hari
ini (2026-09-29)** oleh hakim B; kolom terakhir menyatakan siapa yang benar supaya penerima laporan
tidak perlu memilih.

| # | Hal yang diukur | Kartu A (`H-F-08.md`) | Kartu B (`H-F-08.2.md`) | Hasil ukur ulang | Benar |
|---|---|---|---|---|---|
| 1 | Baris kamus `ART` di `alat/periksa-roadmap.py` | `:55` | `:54` → **diperbaiki jadi `:55`** | `grep -n "^ART = " ` → **55** | **A** |
| 2 | Baris `len(kolom) < 5` di `alat/periksa-buku-uji.py` | `:39` | `:38` → **diperbaiki jadi `:39`** | `grep -n` → **39** | **A** |
| 3 | `.github/workflows/ci.yml` | 1 job `periksa`, 59 langkah | 2 job → **diperbaiki** | 3 kunci top-level (`push`, `pull_request` = trigger; `periksa` = job) + **59 langkah bernama** | **A** |
| 4 | Asersi `supabase/tes/matriks_izin_6_peran.sql` | 65 `boleh()` + asersi mode dukungan | 68 `boleh()` → **diperbaiki** | `grep -c "uji.sama"` = **68**, `grep -c "public.boleh("` = **65** → **65 boolean + 3 asersi mode dukungan** (b.35, b.40, b.64) | **A** |
| 5 | Cakupan `useBahasa` di layar | 50 dari 68 berkas non-uji | 18 dari 141 `.tsx` → **dinyatakan dua-duanya** | 68 berkas non-uji, **18 memakai / 50 tanpa**; seluruh `.tsx` termasuk uji = 141 | **A** (cakupan lebih sempit & relevan) |
6 | Baris yang rusak di `BUKU_UJI_PEMILIK.md` | 55–56, antara U-07 & U-08 | 55–56, antara U-07 & U-08 | **sama** | keduanya |
| 7 | Jumlah nama `uji` di `aplikasi/src/lib/aksi.ts` | 65 | 65 | **sama** (kartu K menulis 61 — dua hakim mengoreksinya ke 65) | keduanya |

**Kesimpulan rekonsiliasi:** tidak ada temuan yang gugur karena perbedaan ini; yang beda hanya
**dosis bukti di dalam catatan hakim**. Angka baku sudah disamakan untuk satu file di
`Buku_BESAR_TEMUAN.md`.

## 3. Yang hanya ditemukan satu hakim (belum ada di kartu selain)

| Temuan | Hakim | Bukti | Catatan |
|---|---|---|---|
| RPC `kirim_ke_dapur` **tidak ada sama sekali** di `supabase/migrations/` (0 fungsi) | A | `grep -rn "kirim_ke_dapur" supabase/migrations/` → hanya kolom `dikirim_ke_dapur_pada` di `0009_pesanan.sql` | A mengaitkannya ke `PMB1-F-060`; B tidak mengukur ini |
| Bukti T1-25 salah label umur sesi: ROADMAP:430 menulis "8 jam **owner**", padahal `0030:470-476` memberi 8 jam ke `pemilik_platform` dan 30 hari ke `admin_cabang`/`owner_pusat` | A | `sed -n '470,476p' supabase/migrations/0030_sesi_dan_persetujuan_perangkat.sql` | memperkuat `PMB1-F-110`; B tidak mengukur ini |
| `alat/peta-ui.py:13` masih menulis docstring "Kelengkapan **7** keadaan" | B | `sed -n '13p' alat/peta-ui.py` | memperkuat `PMB1-F-112` |
| `aplikasi/alat/periksa-struktur.py` menerima folder layar `pelayan` sebagai **INFO, bukan pelanggaran** | B | `python3 aplikasi/alat/periksa-struktur.py` → "layar tambahan (bukan pelanggaran): ['contoh', 'pelayan', 'platform']" | memperkuat `PMB1-F-112` |
| `mode_dukungan_aktif(uuid)` (`0031:84-108`) **yatim** — 0 pemanggil di seluruh repo | kedua | `grep -rn mode_dukungan_aktif` → hanya definisi + `grant` di `0031` | mendukung `PMB1-F-109` |
| Regresi **§A** (9 temuan audit lama) & **§B** (19 tugas `[x]` milik F-08) disisir hari ini | B | `kartu/H-F-08.2.md` §3; `periksa-temuan-audit.py` LOLOS (117 temuan terlacak) | memenuhi `REGRESI_WAJIB.md` — A tidak menyusun bagian ini |
| Temuan baru mesin PMB `PMB1-F-136` (G-04) + penutupan `PMB1-F-092` & `PMB1-F-094` | A | `kartu/H-F-08.md` §2 butir 3 & §3 | di luar potongan F-08; milik `G-04` |

## 4. Peta berkas (agar penerima laporan melihat semuanya)

**Kartu pemeriksa (bukan hasil hakim — dasar putusan):**
`kartu/K-F-08.md` (agent pertama, `F-101`…`F-108`) · `kartu/K-F-08.2.md` (ulangan independen,
`F-109`…`F-116`)

**Kartu hakim:**
`kartu/H-F-08.md` (hakim A) · `kartu/H-F-08.2.md` (hakim B — incl. §2.1 rekap 9 koreksi bukti,
§2.3 catatan yang diserahkan ke Perencana/Lee, §3 regresi)

**Bukti mentah:**
| Berkas | Pemilik | Isi |
|---|---|---|
| `bukti/H-F-08-statis.txt` | A | keluaran statis semua temuan |
| `bukti/H-F-08-mutasi.txt` | A | uji mutasi penjaga |
| `bukti/H-F-08-mode-dukungan-tulis.sql` | A | probe PGlite `F-109` (2 kontrol negatif + transaksi) |
| `bukti/H-F-08-2-mode-dukungan-tulis.sql` / `.txt` | B | probe PGlite `F-109` (1 kontrol negatif) |

Kedua probe memanggil RPC `simpan_urutan_metode_bayar` yang **sungguhan** dari kursi
`pemilik_platform`, punya kontrol negatif, dan **LULOS** → saling mengonfirmasi, bukan tafsir.

**Perintah untuk memverifikasi ulang sendiri (tidak perlu percaya kartu mana pun):**

```
node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-08-mode-dukungan-tulis.sql
node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-08-2-mode-dukungan-tulis.sql
node alat/uji-sql.mjs            # 132 LULUS · 0 GAGAL
python3 alat/periksa-pemeriksaan.py
python3 alat/periksa-bersih.py
```

## 5. Yang masih terbuka (untuk penerima laporan / Lee)

Tidak satu pun menjadi baris `BARU` baru, karena artefaknya **milik potongan F-08 yang sedang
dihakimi** (PROMPT_GILIRAN §5, pelajaran `PMB1-F-009`) — sengaja diserahkan lewat kartu, bukan
didaftarkan, supaya F-08 tetap bisa `DIHAKIMI`.

1. `docs/ROADMAP.md:578` (Bukti T1-40) masih menulis "100% paritas **102 kunci**"; hari ini
   `aplikasi/alat/periksa-bahasa.py` → **284 kunci**. Kelas yang sama dengan `L F-06` & `B F-13`
   yang sudah ditutup — tapi angka ini **tidak** dijaga penjaga mana pun.
2. `J F-08` (AUDIT_RIWAYAT:110) menutup diri dengan "terjadwal di `T1-31`…`T1-35`"; kelima tugas
   itu kini **semuanya `[x]`** sementara komponen keadaan tetap 3 (`KeadaanGagal`/`Kosong`/`Memuat`).
3. `PMB1-F-136` (potongan `G-04`, temuan baru hakim A) belum diputuskan — bukan lingkup F-08.
4. Handoff (`docs/ops/SIAP-LANJUT.md`, `STATUS.md`, `PROJECT_STATE.md`) masih basi. **HAKIM tidak
   boleh menyentuhnya** — itu giliran Perencana.
