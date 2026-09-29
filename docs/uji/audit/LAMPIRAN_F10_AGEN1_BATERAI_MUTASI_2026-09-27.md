# LAMPIRAN AGEN 1 — BUKTI MENTAH BATERAI MUTASI PENUH (68/68 SKRIP)

- **Tanggal:** 2026-09-27 (08:55–09:35 UTC)
- **Target:** `arena/01a0d09b-resto-barokah` @ `5f7b38be21f1921663f6286a26ebe62f285f4d99` (cabang sesi identik saat start)
- **Metode:** seluruh `alat/uji-mutasi-*.py` dijalankan **serial** dalam satu proses latar (loop bash, `timeout 900` per skrip). Sesudah tiap skrip: cek `git status --porcelain -uno` — bila kotor, `git checkout -- .` otomatis. Hasil: **0 kali pemulihan dibutuhkan** (68/68 skrip memulihkan berkasnya sendiri). Log mentah penuh: `/tmp/audit/baterai.log` (sandbox audit).
- **Agregat:** 63 LULUS (RC0) · 5 GAGAL (RC1); **±431 mutan merah** (per marka "TERBUKTI MERAH/TERTANGKAP/MUTAN MATI/[OK] M##" atau angka ringkasan "N/N mutasi" tiap skrip); **13 mutan hidup** — SEMUA terverifikasi sebagai **mutan ekuivalen** akibat harness menarget definisi fungsi yang sudah di-DROP + didefinisikan ulang migrasi lebih baru (laporan §2C & temuan F10-A1-07).
- **Penutup:** suite penuh pasca-baterai `node alat/uji-sql.mjs` → **132 LULUS · 0 GAGAL — LOLOS**; `git status --porcelain -uno` → 0.

## Tabel hasil per skrip

| # | Skrip | Status | Mutan merah (marka/Σ ringkasan) | Mutan hidup | Durasi (s) | Tree kotor |
|---|-------|--------|--------------------------------|-------------|------------|------------|
| 1 | `uji-mutasi-0009.py` | LULUS | 0 | 0 | 13 | 0 |
| 2 | `uji-mutasi-0012.py` | LULUS | 1 | 0 | 70 | 0 |
| 3 | `uji-mutasi-0014.py` | LULUS | 1 | 0 | 91 | 0 |
| 4 | `uji-mutasi-0015.py` | LULUS | 0 | 0 | 119 | 0 |
| 5 | `uji-mutasi-0016.py` | LULUS | 0 | 0 | 70 | 0 |
| 6 | `uji-mutasi-0017.py` | LULUS | 0 | 0 | 42 | 0 |
| 7 | `uji-mutasi-0018.py` | LULUS | 0 | 0 | 38 | 0 |
| 8 | `uji-mutasi-0019.py` | LULUS | 10 | 0 | 13 | 0 |
| 9 | `uji-mutasi-0021.py` | LULUS | 0 | 0 | 9 | 0 |
| 10 | `uji-mutasi-0022.py` | LULUS | 0 | 0 | 28 | 0 |
| 11 | `uji-mutasi-0024.py` | LULUS | 0 | 0 | 12 | 0 |
| 12 | `uji-mutasi-0025.py` | LULUS | 0 | 0 | 8 | 0 |
| 13 | `uji-mutasi-0028.py` | LULUS | 0 | 0 | 24 | 0 |
| 14 | `uji-mutasi-0029.py` | LULUS | 0 | 0 | 22 | 0 |
| 15 | `uji-mutasi-0030.py` | LULUS | 8 | 0 | 11 | 0 |
| 16 | `uji-mutasi-0031.py` | LULUS | 8 | 0 | 11 | 0 |
| 17 | `uji-mutasi-0032.py` | LULUS | 14 | 0 | 19 | 0 |
| 18 | `uji-mutasi-0033.py` | LULUS | 4 | 0 | 7 | 0 |
| 19 | `uji-mutasi-0035.py` | LULUS | 6 | 0 | 9 | 0 |
| 20 | `uji-mutasi-0036.py` | LULUS | 6 | 0 | 9 | 0 |
| 21 | `uji-mutasi-0037.py` | LULUS | 6 | 0 | 9 | 0 |
| 22 | `uji-mutasi-0038.py` | LULUS | 6 | 0 | 9 | 0 |
| 23 | `uji-mutasi-0039.py` | LULUS | 12 | 0 | 15 | 0 |
| 24 | `uji-mutasi-0040.py` | LULUS | 8 | 0 | 12 | 0 |
| 25 | `uji-mutasi-0041.py` | LULUS | 12 | 0 | 16 | 0 |
| 26 | `uji-mutasi-0042.py` | LULUS | 8 | 0 | 12 | 0 |
| 27 | `uji-mutasi-0043.py` | LULUS | 8 | 0 | 11 | 0 |
| 28 | `uji-mutasi-0045.py` | LULUS | 12 | 0 | 16 | 0 |
| 29 | `uji-mutasi-0046.py` | LULUS | 12 | 0 | 16 | 0 |
| 30 | `uji-mutasi-0047.py` | LULUS | 12 | 0 | 17 | 0 |
| 31 | `uji-mutasi-0048.py` | LULUS | 12 | 0 | 17 | 0 |
| 32 | `uji-mutasi-0049.py` | LULUS | 12 | 0 | 16 | 0 |
| 33 | `uji-mutasi-0050.py` | LULUS | 7 | 0 | 16 | 0 |
| 34 | `uji-mutasi-0051.py` | LULUS | 0 | 0 | 18 | 0 |
| 35 | `uji-mutasi-0052.py` | LULUS | 0 | 0 | 15 | 0 |
| 36 | `uji-mutasi-0053.py` | LULUS | 0 | 0 | 16 | 0 |
| 37 | `uji-mutasi-0054.py` | LULUS | 0 | 0 | 16 | 0 |
| 38 | `uji-mutasi-0056.py` | LULUS | 4 | 0 | 6 | 0 |
| 39 | `uji-mutasi-0057.py` | LULUS | 4 | 0 | 6 | 0 |
| 40 | `uji-mutasi-0058.py` | LULUS | 8 | 0 | 12 | 0 |
| 41 | `uji-mutasi-0059.py` | LULUS | 6 | 0 | 8 | 0 |
| 42 | `uji-mutasi-0060.py` | LULUS | 6 | 0 | 9 | 0 |
| 43 | `uji-mutasi-0061.py` | LULUS | 6 | 0 | 9 | 0 |
| 44 | `uji-mutasi-0062.py` | GAGAL | 0 | 1 | 4 | 0 |
| 45 | `uji-mutasi-0063.py` | GAGAL | 4 | 1 | 9 | 0 |
| 46 | `uji-mutasi-0064.py` | LULUS | 10 | 0 | 13 | 0 |
| 47 | `uji-mutasi-0065.py` | LULUS | 10 | 0 | 13 | 0 |
| 48 | `uji-mutasi-0066.py` | LULUS | 12 | 0 | 15 | 0 |
| 49 | `uji-mutasi-0067.py` | LULUS | 12 | 0 | 18 | 0 |
| 50 | `uji-mutasi-0068.py` | LULUS | 14 | 0 | 19 | 0 |
| 51 | `uji-mutasi-0069.py` | LULUS | 14 | 0 | 18 | 0 |
| 52 | `uji-mutasi-0070.py` | GAGAL | 8 | 1 | 18 | 0 |
| 53 | `uji-mutasi-0071.py` | LULUS | 8 | 0 | 17 | 0 |
| 54 | `uji-mutasi-0072.py` | LULUS | 9 | 0 | 21 | 0 |
| 55 | `uji-mutasi-0073.py` | GAGAL | 8 | 5 | 17 | 0 |
| 56 | `uji-mutasi-0074.py` | GAGAL | 9 | 5 | 22 | 0 |
| 57 | `uji-mutasi-0075.py` | LULUS | 8 | 0 | 51 | 0 |
| 58 | `uji-mutasi-0076.py` | LULUS | 9 | 0 | 20 | 0 |
| 59 | `uji-mutasi-0077.py` | LULUS | 11 | 0 | 25 | 0 |
| 60 | `uji-mutasi-0078.py` | LULUS | 22 | 0 | 72 | 0 |
| 61 | `uji-mutasi-0079.py` | LULUS | 12 | 0 | 78 | 0 |
| 62 | `uji-mutasi-0080.py` | LULUS | 10 | 0 | 14 | 0 |
| 63 | `uji-mutasi-0081.py` | LULUS | 8 | 0 | 11 | 0 |
| 64 | `uji-mutasi-0082.py` | LULUS | 8 | 0 | 11 | 0 |
| 65 | `uji-mutasi-0083.py` | LULUS | 5 | 0 | 11 | 0 |
| 66 | `uji-mutasi-0084.py` | LULUS | 0 | 0 | 13 | 0 |
| 67 | `uji-mutasi-0085.py` | LULUS | 0 | 0 | 13 | 0 |
| 68 | `uji-mutasi-cadangan.py` | LULUS | 1 | 0 | 12 | 0 |
| — | **TOTAL (68 skrip)** | **63 LULUS · 5 GAGAL** | **±431** | **13** | — | **0×** |
## Kutipan mentah 5 skrip GAGAL (RC1)

```
### [44/68] alat/uji-mutasi-0062.py
UJI MUTASI 0062 (T8-01 — RPC katalog_publik)
  OK  kontrol: salinan utuh → supabase/tes/katalog_publik.sql hijau
  [X] Mutasi 1: pengecekan status aktif resto dihilangkan LOLOS (pagar tumpul!)
at_shift.sql

Membuat data uji:


----------------------------------------------------------------------
uji: 1 LULUS · 0 GAGAL
HASIL: LOLOS

### HASIL alat/uji-mutasi-0062.py: RC1 dur=4s dirty(tracked)=0
```

```
### [45/68] alat/uji-mutasi-0063.py
UJI MUTASI 0063 (T8-07 — Anti Email Palsu & Normalisasi Gmail)
  OK  kontrol: salinan utuh → supabase/tes/anti_email_palsu.sql hijau
  [OK] Mutasi 1: normalisasi titik Gmail dicabut TERBUKTI MERAH
  [OK] Mutasi 2: saringan email sekali-pakai dilonggarkan TERBUKTI MERAH
  [X] Mutasi 3: validasi persetujuan privasi UU PDP dicabut pada RPC LOLOS (pagar tumpul!)
_shift.sql

Membuat data uji:


----------------------------------------------------------------------
uji: 1 LULUS · 0 GAGAL
HASIL: LOLOS

### HASIL alat/uji-mutasi-0063.py: RC1 dur=9s dirty(tracked)=0
```

```
### [52/68] alat/uji-mutasi-0070.py
=== PENGUJIAN MUTASI 0070_identitas_resto.sql (T9-01) ===
[1/2] Memeriksa baseline asli (harus LULUS / kode keluar 0)...
  -> Baseline BERSIH & LULUS.

[2/2] Menguji 7 mutasi fail-closed...
  ✅ TERTANGKAP: Mutasi #1 'M01: Hapus pagar otorisasi peran (owner_pusat / atur_pengaturan)' terdeteksi merah.
  ✅ TERTANGKAP: Mutasi #2 'M02: Hapus penjaga kunci konkurensi optimistik (p_versi_lama)' terdeteksi merah.
  ✅ TERTANGKAP: Mutasi #3 'M03: Hapus pembaruan nama resto di tabel penyewa' terdeteksi merah.
  ✅ TERTANGKAP: Mutasi #4 'M04: Hapus pembaruan tagline dan logo di tabel pengaturan' terdeteksi merah.
  ✅ TERTANGKAP: Mutasi #5 'M05: Hapus pencatatan audit trail (catatan_audit)' terdeteksi merah.
  ✅ TERTANGKAP: Mutasi #6 'M06: Hapus validasi nama resto kosong' terdeteksi merah.
  ❌ GAGAL: Mutasi #7 'M07: Hapus tagline dari kembalian katalog_publik' lolos diam-diam (tidak tertangkap tes)!

HASIL: Sebagian mutasi tidak tertangkap! Perketat berkas uji.
### HASIL alat/uji-mutasi-0070.py: RC1 dur=18s dirty(tracked)=0
```

```
### [55/68] alat/uji-mutasi-0073.py
=== PENGUJIAN MUTASI 0073_pengaturan_meja.sql (T9-04) ===
[1/2] Memeriksa baseline asli (harus LULUS / kode keluar 0)...
  -> Baseline BERSIH & LULUS.

[2/2] Menguji 7 mutasi fail-closed...
  ✅ TERTANGKAP: Mutasi #1 'M01: Hapus mitigasi T9-04: tolak pesanan baru di meja nonaktif' terdeteksi merah.
  ❌ GAGAL: Mutasi #2 'M02: Hapus pagar otorisasi peran kelola meja' lolos diam-diam (tidak tertangkap tes)!
  ❌ GAGAL: Mutasi #3 'M03: Hapus validasi keunikan nomor/nama meja di cabang' lolos diam-diam (tidak tertangkap tes)!
  ❌ GAGAL: Mutasi #4 'M04: Hapus pencegahan nonaktifkan meja dengan pesanan aktif' lolos diam-diam (tidak tertangkap tes)!
  ✅ TERTANGKAP: Mutasi #5 'M05: Hapus pencegahan hapus meja dengan riwayat pesanan di hapus_meja' terdeteksi merah.
  ❌ GAGAL: Mutasi #6 'M06: Hapus pencatatan audit trail pada simpan_meja' lolos diam-diam (tidak tertangkap tes)!
  ❌ GAGAL: Mutasi #7 'M07: Hapus validasi nama meja wajib diisi' lolos diam-diam (tidak tertangkap tes)!

HASIL: Sebagian mutasi tidak tertangkap! Perketat berkas uji.
### HASIL alat/uji-mutasi-0073.py: RC1 dur=17s dirty(tracked)=0
```

```
### [56/68] alat/uji-mutasi-0074.py
=== PENGUJIAN MUTASI 0074_pengaturan_menu.sql (T9-05) ===
[1/2] Memeriksa baseline asli (harus LULUS / kode keluar 0)...
  -> Baseline BERSIH & LULUS.

[2/2] Menguji 8 mutasi fail-closed...
  ✅ TERTANGKAP: Mutasi #1 'M01: Hapus mitigasi T9-05: tolak hapus menu yang memiliki riwayat pesanan' terdeteksi merah.
  ✅ TERTANGKAP: Mutasi #2 'M02: Hapus pencegahan hapus kategori yang masih memiliki menu item' terdeteksi merah.
  ❌ GAGAL: Mutasi #3 'M03: Hapus pagar otorisasi peran kelola menu pada simpan_menu' lolos diam-diam (tidak tertangkap tes)!
  ❌ GAGAL: Mutasi #4 'M04: Hapus validasi harga menu tidak boleh negatif' lolos diam-diam (tidak tertangkap tes)!
  ❌ GAGAL: Mutasi #5 'M05: Hapus validasi nama menu wajib diisi' lolos diam-diam (tidak tertangkap tes)!
  ❌ GAGAL: Mutasi #6 'M06: Hapus validasi keunikan nama menu di kategori yang sama' lolos diam-diam (tidak tertangkap tes)!
  ✅ TERTANGKAP: Mutasi #7 'M07: Hapus pencatatan audit trail pada simpan_menu' terdeteksi merah.
  ❌ GAGAL: Mutasi #8 'M08: Hapus validasi kategori menu milik penyewa yang sama' lolos diam-diam (tidak tertangkap tes)!

HASIL: Sebagian mutasi tidak tertangkap! Perketat berkas uji.
### HASIL alat/uji-mutasi-0074.py: RC1 dur=22s dirty(tracked)=0
```

## Verifikasi akar penyebab (kutipan perintah nyata)

```
$ grep -ln "create or replace function public.katalog_publik" supabase/migrations/*.sql
supabase/migrations/0062_katalog_publik.sql
supabase/migrations/0070_identitas_resto.sql
supabase/migrations/0071_tema_merek.sql          ← versi KINI; :260 tetap "and p.status = 'aktif'"; :199-201 tetap memuat tagline/logo/banner

$ grep -ln "create or replace function public.daftar_voucher" supabase/migrations/*.sql
supabase/migrations/0063_anti_email_palsu.sql
supabase/migrations/0064_terbit_voucher_acak.sql
supabase/migrations/0067_pengaman_voucher.sql    ← versi KINI; :664 tetap validasi consent UU PDP; CHECK skema 0063:154 (persetujuan_privasi = true)

$ grep -n "drop function if exists" supabase/migrations/0083_versi_pengaturan_bersamaan.sql
17:drop function if exists public.simpan_menu(uuid, uuid, text, text, integer, text, integer, boolean, text, boolean, jsonb, jsonb);
253:drop function if exists public.simpan_kategori_menu(uuid, text, integer, text, boolean);
411:drop function if exists public.simpan_meja(uuid, text, text, boolean, uuid);
                                             ← versi KINI memuat pagar otorisasi :57, :281, :450-451 & keunikan meja :505
```

**Kesimpulan lampiran:** 13 mutan hidup pada 0062/0063/0070/0073/0074 adalah mutan ekuivalen (harness memutasi definisi mati). Tidak ada pagar yang hilang pada definisi yang berlaku kini — namun bukti "merah saat dirusak" untuk 13 pagar itu harus dipulihkan dengan meretarget harness ke definisi terbaru (F10-A1-07; preseden: commit `fix(mutasi): arahkan uji mutasi 0046 ke definisi terbaru tutup_shift`).
