# BERKAS INTEGRASI F-08 — siap diambil Lee

> **Untuk apa berkas ini.** Potongan **F-08 sudah `DIHAKIMI`** oleh dua hakim (lihat
> `kartu/H-F-08.md` dan `kartu/H-F-08.2.md`; rekonsiliasi angkanya di
> `REKONSILIASI-F-08.md`). Berkas ini adalah **satu-satunya halaman yang perlu Lee baca** untuk
> mengambil keputusan: apa putuskanannya, siapa yang harus mengerjakan apa, di mana, dan perintah
> apa untuk memverifikasinya. Berkas ini **tidak menghapus apa pun** — hanya memberi urutan.
>
> Percayalah atau tidak: semua angka di sini bisa Lee ukur ulang sendiri dengan perintah yang
> tercantum. Tidak ada satu pun yang perlu percaya kata hakim.

- **PAPAN:** `F-08` = `DIHAKIMI` · **Buku Besar:** 16 baris `PMB1-F-101`…`F-116` = `TERVERIFIKASI`
- **Cabang:** `arena/01a0eb0d-resto-barokah` · **Commit dasar:** `1b06104`
- **Tanggal:** 2026-09-29 · Peran penyusun: HAKIM (hanya boleh menulis di `docs/uji/pemeriksaan/PMB-1/`)

---

## 1. Putusan final (kanonik)

**Kartu kanonik: `kartu/H-F-08.md`** — dipilih karena memuat bagian `## 3. Verifikasi perbaikan`
(penutupan `PMB1-F-092` & `PMB1-F-094`) dan temuan baru mesin PMB `PMB1-F-136`, dan karena
`alat/periksa-pemeriksaan.py` mewajibkan `kartu/H-F-08.md` ada untuk status `DIHAKIMI`.
`kartu/H-F-08.2.md` **tetap ada sebagai catatan silang** (regresi `REGRESI_WAJIB.md` §A/§B + 9
koreksi bukti). **Kedua kartu tidak digabung, tidak ada yang dihapus.**

| Tingkat | Jumlah | Baris |
|---|---|---|
| **K-1** | **0** | — |
| **K-2** | **5** | `PMB1-F-109`, `F-110`, `F-111`, `F-112`, `F-113` |
| **K-3** | **8** | `PMB1-F-101`, `F-102`, `F-103`, `F-104`, `F-106`, `F-107`, `F-114`, `F-115` |
| **K-4** | **3** | `PMB1-F-105`, `F-108`, `F-116` |

Status: **16 TERVERIFIKASI · 0 DUPLIKAT · 0 PALSU · 0 PERLU-INFO · 0 BARU tersisa.**

## 2. Urutan kerja — K-2 lebih dulu (5 pekerjaan, wajib beres)

| # | Temuan | Yang harus diperbaiki | Di mana | Tanda "selesai" (bisa diuji) |
|---|---|---|---|---|
| 1 | **F-109** | Mode dukungan `pemilik_platform` bisa **menulis** data resto sasaran. Tambah pemeriksaan peran pada RPC tulis, **atau** pisahkan hak baca dari `penyewa_saya()` | `supabase/migrations/0031_mode_dukungan_platform.sql:51` (`penyewa_saya()`) + tiap RPC `SECURITY DEFINER` yang hanya bersandar padanya tanpa `peran_saya()` | `node alat/uji-sql.mjs …/bukti/H-F-08-mode-dukungan-tulis.sql` → **GAGAL** (tidak boleh LULUS lagi) |
| 2 | **F-110** | `session_id` ganda **tidak ditolak**, hanya ditimpa & dihidupkan ulang; 4 skenario penolakan T1-25 dan skenario 6×/12×/15 menit T1-26 tidak pernah diuji | `supabase/migrations/0030_sesi_dan_persetujuan_perangkat.sql:489` (`on conflict (session_id) do update`) · `supabase/tes/sesi_dan_perangkat.sql` | 4 skenario T1-25 + 6×/12×/15m T1-26 ada di berkas uji dan **MERAH** saat mutasi |
| 3 | **F-111** | Matriks izin bukan turunan otomatis; 0 asersi RPC; kamus `dapur.ubah_stok: False` **bertentangan** dengan data uji `true` | `alat/periksa-matriks-izin.py:45-49` · `supabase/tes/matriks_izin_6_peran.sql` · `alat/sql/data-uji.sql:62` | matriks turun dari daftar RPC/tabel **atau** DoD `docs/ROADMAP.md:460-467` diturunkan jujur |
| 4 | **F-112** | 65 nama uji di `aksi.ts` **tidak ada di berkas uji mana pun**; 7/12 layar menunjuk naskah yang salah/tak ada; keadaan ke-8 `konflik` opsional & tanpa komponen | `aplikasi/src/lib/aksi.ts` · `alat/peta-ui.py:369` (hanya cek `len(uji) == 0`) · `aplikasi/src/lib/layar.ts:13-22` (keadaan) & kolom `naskahJalan` di berkas yang sama | uji nyata per aksi + cek naskah + 8 keadaan; `peta-ui.py --periksa` **MERAH** saat satu nama uji dihapus |
| 5 | **F-113** | 0 berkas font Mandarin/Arab (Mandarin ikut rilis G1); penjaga arah hanya mengecek **nama variabel CSS**, bukan font; 0 layar RTL di `prototipe/`; bantuan dijaga per-layar bukan per-aksi; `tampilkanOtomatisPertamaKali` 0 pemanggil | `aplikasi/src/gaya/aset/font/` · `aplikasi/alat/periksa-arah.py:35-36` · `prototipe/` · `alat/periksa-bantuan.py:48-59` · `aplikasi/src/komponen/LembarBantuan.tsx:16` | font CJK/Arab terpasang **dan** `periksa-arah.py` mengukur berkas, bukan deklarasi |

> Detail bukti tiap baris ada di kolom Hakim Buku Besar (dipisah tanda `‖` sudah memuat catatan
> kedua hakim) dan di kedua kartu. Tidak perlu membuka ulang dari nol.

## 3. Urutan kerja — K-3 lalu K-4 (11 pekerjaan)

| Temuan | Satu kalimat perbaikan | Di mana |
|---|---|---|
| **F-101** | 5 entri aksi menunjuk `rpc: 'hitung_total'` yang bukan RPC aksi tersebut; gerbang hanya menolak RPC *tak terdefinisi* | `aplikasi/src/lib/aksi.ts:86,102,118,135,739` · `alat/peta-ui.py` Aturan 1 |
| **F-102** | Hapus/tulis ulang dalih "repo privat" (repo **publik**: `isPrivate=false`) | `docs/ROADMAP.md:115,1977` |
| **F-103** | T1-30 `[x]` bertabrakan dengan catatan resmi "jangan centang" & T1-45 `[ ]` | `docs/ROADMAP.md:468` |
| **F-104** | Kotak T1-19/20/22 tidak mencerminkan kenyataan (RPC & bukti sudah ada) | `docs/ROADMAP.md:354,364,382` |
| **F-105** | Kepala ROADMAP masih "menunggu Tahap 6" & "ART-1…ART-10" (sebenarnya 15 ART) | `docs/ROADMAP.md:3,13` |
| **F-106** | Janji "pemeriksa menolak tugas UI tanpa nomor naskah" tidak ada penegaknya | `docs/ROADMAP.md:551-558` · `alat/peta-ui.py` |
| **F-107** | Kolom `Hasil` U-01…U-04 kosong padahal ditagih T1-43; penjaga tak pernah membacanya | `docs/uji/BUKU_UJI_PEMILIK.md` · `alat/periksa-buku-uji.py` |
| **F-108** | Kepala Fase 1B salah nomor migrasi ("0011–0016", "+7 menjadi 0018") | `docs/ROADMAP.md:395-400` |
| **F-114** | `ART` hanya 1–10; cek `⚠️` tak pernah menuntut; tabel Peta RPC kehilangan **12** RPC keamanan | `alat/periksa-roadmap.py:55` · `docs/ROADMAP.md:20-33` |
| **F-115** | Angka tetap T0-14 basi (tulisannya 12 alur·18 perintah, nyata **16 alur·30 perintah**); "Sisa DoD" bertabrakan dengan "hijau" pada baris yang sama | `docs/ROADMAP.md:126,185` · `aplikasi/README.md` |
| **F-116** | Dua baris 2-kolom merusak tabel 5-kolom; penjaga `:39` meloloskannya | `docs/uji/BUKU_UJI_PEMILIK.md:55-56` · `alat/periksa-buku-uji.py:39` |

## 4. Dua catatan yang sengaja TIDAK dijadikan baris temuan

Alasannya: artefaknya **milik potongan F-08 yang sudah `DIHAKIMI`**, dan menambah baris `BARU`
di sini akan membatalkan status itu (PROMPT_GILIRAN §5, pelajaran `PMB1-F-009`). Lee yang
memutuskan — keduanya tinggal dikerjakan.

1. **`docs/ROADMAP.md:578`** (Bukti T1-40) masih "100% paritas **102 kunci**"; nyata
   `aplikasi/alat/periksa-bahasa.py` → **284 kunci**. Kelas yang sama dengan `L F-06` & `B F-13`
   yang sudah ditutup, tapi angka ini **tidak dijaga penjaga mana pun**.
2. **`J F-08`** (AUDIT_RIWAYAT:110) menutup diri dengan "terjadwal di `T1-31`…`T1-35`"; kelima
   tugas itu kini **semuanya `[x]`** sementara komponen keadaan tetap 3.

## 5. Di luar lingkup F-08 (milik potongan lain — jangan digabung ke sini)

| Temuan | Potongan | Status | Catatan |
|---|---|---|---|
| `PMB1-F-136` — penjaga PMB menerima status non-`BARU` dengan kolom Hakim sembarang | `G-04` | `RENCANA` | temuan baru hakim; aman — G-04 baru bisa memicu gerbang setelah punya kolom Hakim terisi |
| `PMB1-F-137`…`F-140`, `PMB1-A-079`…`A-080` | `F-12` | `F-12` = `SELESAI`, kartu `K-F-12` + `K-F-12.2` | hasil sesi paralel, tidak disentuh |
| Handoff `SIAP-LANJUT.md` / `STATUS.md` / `PROJECT_STATE.md` masih basi | — | — | **HAKIM tidak boleh menyentuhnya.** Lee/Perencana menjalankan sendiri: `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari arena/01a0eb0d-resto-barokah` lalu commit |

## 6. Perintah verifikasi (Lee bisa menjalankan sendiri, tanpa percaya siapa pun)

```bash
# 1) dua probe F-109 harus LULOS (= cacatnya benar-benar ada)
node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-08-mode-dukungan-tulis.sql
node alat/uji-sql.mjs docs/uji/pemeriksaan/PMB-1/bukti/H-F-08-2-mode-dukungan-tulis.sql
# 2) seluruh uji SQL
node alat/uji-sql.mjs                                   # 132 LULUS · 0 GAGAL
# 3) penjaga wajib
python3 alat/periksa-pemeriksaan.py                    # LOLOS
python3 alat/periksa-bersih.py                         # LOLOS
# 4) angka yang sering berbeda antar kartu (rekonsiliasi)
grep -n "^ART = " alat/periksa-roadmap.py               # 55
grep -n "len(kolom) < 5" alat/periksa-buku-uji.py      # 39
python3 aplikasi/alat/periksa-bahasa.py                # 284 kunci
python3 alat/periksa-panduan.py                        # 16 alur · 30 perintah
```

## 7. Peta berkas F-08 (lengkap — tidak ada yang tersembunyi)

| Peran | Berkas |
|---|---|
| Kartu pemeriksa (dasar) | `kartu/K-F-08.md` · `kartu/K-F-08.2.md` |
| Kartu hakim A (**kanonik**) | `kartu/H-F-08.md` |
| Kartu hakim B (silang: regresi + 9 koreksi bukti) | `kartu/H-F-08.2.md` |
| Rekonsiliasi dua hakim | `REKONSILIASI-F-08.md` |
| Bukti A | `bukti/H-F-08-statis.txt` · `bukti/H-F-08-mutasi.txt` · `bukti/H-F-08-mode-dukungan-tulis.sql` |
| Bukti B | `bukti/H-F-08-2-mode-dukungan-tulis.sql` · `bukti/H-F-08-2-mode-dukungan-tulis.txt` |
| Berkas ini | `BERKAS-INTEGRASI-F-08.md` |

**Yang TIDAK boleh terjadi saat integrasi:** menghapus salah satu kartu hakim, memaksa merge,
mendorong ke `main`, atau menutup temuan sebelum ada uji yang bisa MERAH.
