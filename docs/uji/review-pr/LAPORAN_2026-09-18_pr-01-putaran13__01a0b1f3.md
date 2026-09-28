# LAPORAN REVIEW PR INDEPENDEN — pr-01-putaran13 — 2026-09-18

- **Paket review:** `docs/uji/review-pr/PKT-2026-09-18-pr-01-putaran13.md`
- **Commit yang direview:** `d1f11d7f32bdb78b14b6ed4d935946c515c656df`
- **Tingkat risiko:** Merah
- **Verdict:** TIDAK-BERSIH

Review ini mengikuti `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`. Tree yang diuji adalah snapshot commit d1 di `/tmp/resto-review-d1`, bukan tip lain dan bukan deskripsi PR. Saya menjalankan lensa L1 (ancaman & akses), L2 (uang & jejak), dan L4 (mutu uji). Temuan K-1 terverifikasi membuat rekomendasi **JANGAN MERGE DULU**.

## 1. Cakupan diff

Perbandingan independen base `origin/main` dengan tree d1 menghasilkan **388 berkas berubah, +52.418/−143 baris**. Paket yang tersimpan di tree d1 sendiri mencetak +52.391, sehingga angka paket juga saya perlakukan sebagai bukti yang perlu diverifikasi, bukan sebagai sumber kebenaran.

Saya tidak membaca 388 berkas baris demi baris. Saya membaca dan menguji seluruh jalur Merah yang relevan dengan 12 klaim, seluruh 31 berkas uji SQL melalui runner, gerbang CI/pemeriksa yang diwajibkan, serta artefak uang/RLS yang ditemukan dari penelusuran. Berkas lain yang tidak diperlukan untuk jalur risiko tersebut tidak saya nyatakan telah diverifikasi satu per satu.

| # | Kelompok berkas | Jumlah di diff | Jalur risiko | Diperiksa | Bukti (perintah/baris) |
|---|---|---:|---|---|---|
| 1 | `supabase/migrations/*.sql` (terutama 0009–0013) | 13 migrasi + `.gitkeep` | Merah | Ya, jalur uang/RLS/jejak | `nl -ba supabase/migrations/0009_pesanan.sql`, `0012_penutup_celah_review.sql`, `0013_penutup_celah_putaran11.sql`; probe langsung di `/tmp/resto-probe-*.sql` |
| 2 | `supabase/tes/*.sql` | 31 uji | Merah | Ya, seluruhnya dieksekusi | `node alat/uji-sql.mjs` → `uji: 31 LULUS · 0 GAGAL` |
| 3 | `.github/workflows/ci.yml`, `aplikasi/alat/periksa-semua.sh`, `alat/uji-mutasi-0012.py`, pemeriksa CI | bagian dari 72 Merah | Merah | Ya, gerbang dan mutasi dijalankan | `bash aplikasi/alat/periksa-semua.sh`; `python3 alat/uji-mutasi-0012.py`; `python3 alat/periksa-gerbang-ci.py --uji-diri` |
| 4 | alat review, pemeriksa dokumen, paket review, bahan kalibrasi | bagian dari Merah/Kuning/Hijau | Merah/Kuning | Ya, yang menjadi klaim atau gerbang | `python3 alat/audit-independen.py --uji-diri`; `python3 alat/review-pr.py --uji-diri`; `python3 alat/periksa-rujukan.py` |
| 5 | aplikasi React/TS, pemeriksa kontras, pemeriksa antarmuka | bagian dari 119 Kuning | Kuning | Ya untuk klaim UI yang diminta; bukan audit visual manual semua komponen | `python3 aplikasi/alat/periksa-antarmuka.py`; `--uji-diri`; Vitest dalam gerbang penuh |
| 6 | dokumen fondasi/panduan/riwayat | bagian dari 197 Hijau dan sebagian Merah | Hijau/Merah | Sebagian; klaim perilaku dan angka yang relevan diperiksa | `python3 _sistem/validate_system.py`; `python3 alat/periksa-roadmap.py`; `python3 alat/periksa-panduan.py`; `python3 alat/periksa-rujukan.py` |

## 2. Klaim yang dibantah

| # | Klaim | Cara membantah | Hasil nyata |
|---:|---|---|---|
| 1 | `skills/desain-antarmuka/SKILL.md` berisi tiga pelajaran, sumber, dan daftar periksa | Pemeriksaan Python atas judul, sumber, daftar periksa, dan alat penegak | **Diterima**: `OK 3 pelajaran`, `OK sumber Material/WAI/shadcn`, `OK daftar periksa`, `OK alat penegak`; exit 0 |
| 2 | Skill itu wajib dibaca pada fase DESAIN | Import `alat/mulai-sesi.py`, panggil `skill_untuk('DESAIN')` | **Diterima**: `DESAIN contains desain-antarmuka: True`; daftar fase memuat `desain-antarmuka`; exit 0 |
| 3 | `aplikasi/alat/periksa-antarmuka.py` memiliki 10 hasil uji-diri dan menolak keadaan rusak | `python3 aplikasi/alat/periksa-antarmuka.py --uji-diri` | **Diterima**: salinan utuh diterima dan 9 mutasi ditolak; `HASIL: LOLOS`; exit 0 |
| 4 | `alat/periksa-rujukan.py` tidak lagi salah membaca `.tsx` sebagai `.ts` | `python3 alat/periksa-rujukan.py` dan `--uji-diri` | **Diterima**: 190 rujukan diperiksa; mutasi rujukan `.tsx` yang dihapus **ditolak**; kedua mode exit 0 |
| 5 | `aplikasi/alat/uji-kontras.py` tetap membaca token setelah komentar CSS | `python3 aplikasi/alat/uji-kontras.py` dan `--uji-diri` | **Diterima**: `RINGKASAN: 166 lolos, 0 gagal`; mutasi token `--t-1` dihapus **ditolak**; kedua mode exit 0 |
| 6 | `periksa-komponen-env.py` menyelesaikan `var()` sebelum menilai lantai sentuh 44 px | `python3 aplikasi/alat/periksa-komponen-env.py` | **Diterima**: `.btn`, `.input`, `.tab` masing-masing `48 px (>= 44)`; `komponen & rahasia: 10 OK · 0 GAGAL`; exit 0 |
| 7 | Perbaikan PR-01 menolak voucher 100% tanpa mesin voucher | `node alat/uji-sql.mjs supabase/tes/diskon_voucher.sql` | **Diterima untuk jalur yang diuji**: `uji: 1 LULUS · 0 GAGAL`, `HASIL: LOLOS`, exit 0 |
| 8 | Perbaikan PR-02 menolak pesanan yang lahir `batal`/`lunas`/bertanda batal | `node alat/uji-sql.mjs supabase/tes/pesanan_status_awal.sql` | **Diterima untuk INSERT langsung yang diuji**: `uji: 1 LULUS · 0 GAGAL`, `HASIL: LOLOS`, exit 0 |
| 9 | Uji otomatis membuktikan perilaku pada commit yang direview, bukan hanya commit sebelumnya | `node alat/uji-sql.mjs`, hitung tree target, dan diff base→target | **Sebagian diterima, tetapi coverage tidak cukup**: runner pada tree d1 menjalankan 31 berkas dan lulus; probe subtotal menunjukkan celah yang tidak diuji. |
| 10 | Tidak ada gerbang keamanan/CI yang dilemahkan | `python3 alat/periksa-gerbang-ci.py` dan `--uji-diri`, plus gerbang penuh dan mutasi | **Diterima untuk pagar yang ada**: 13 gerbang lulus; semua 8 mutasi penjaga CI dalam uji-diri ditolak; suite mutasi uang/RLS `16/16` merah; exit 0. |
| 11 | Jalur uang/keamanan tidak dapat dilewati lewat pemanggilan langsung | `node alat/uji-sql.mjs /tmp/resto-probe-subtotal-dampak.sql` sebagai `authenticated` dengan klaim pengguna dapur | **DITOLAK**: pengguna dapur berhasil mengubah `pesanan_item.subtotal` menjadi 1; pembatalan kemudian mencatat `nilai_kerugian=1`; probe `uji: 1 LULUS · 0 GAGAL`, exit 0 (lulus berarti celah terbukti). |
| 12 | Dokumen perilaku/fondasi sudah diperbarui dan tidak ada klaim basi | `sed` paket/CI + hitung berkas uji + pemeriksa dokumen | **DITOLAK sebagian**: paket d1 menyebut commit `57fe6899...` dan head cabang lama; CI menyebut `28 berkas` padahal tree dan runner memiliki 31. Pemeriksa dokumen tetap exit 0 karena tidak menjaga metadata ini. |

Keluaran ringkas yang menjadi dasar klaim 3–6:

```text
UJI-DIRI periksa-antarmuka
  OK  salinan utuh → kode 0
  OK  mutasi: Esc dihapus dari komponen aplikasi → ditolak
  OK  mutasi: maska dipasang di WADAH (.picker-panel) → ditolak
  OK  mutasi: klik di luar tidak lagi menutup (sumber desain) → ditolak
  OK  mutasi: salinan CSS aplikasi menyimpang dari sumber desain → ditolak
  OK  mutasi: id pemilih kembali kembar (sumber desain) → ditolak
  OK  mutasi: kemampuan desain dihapus → ditolak
  OK  mutasi: kemampuan tidak lagi dipakai sesi berikutnya → ditolak
  OK  mutasi: jalur cadangan peramban lama dibuang → ditolak
  OK  mutasi: semua penunjuk ke kemampuan dihapus dari kode → ditolak
HASIL: LOLOS — pemeriksa terbukti bisa MENOLAK yang rusak dan MENERIMA yang utuh.

PERIKSA RUJUKAN — 11 dokumen pengikat · 190 rujukan diperiksa
HASIL: LOLOS — semua rujukan di dokumen pengikat hidup (yang belum ada ditandai jelas).
UJI-DIRI periksa-rujukan
  OK  salinan utuh → kode 0
  OK  mutasi: rujukan mati disisipkan di Buku Insiden → ditolak
  OK  mutasi: rujukan mati DITANDAI rencana → diterima
  OK  mutasi: berkas .tsx yang dirujuk DIHAPUS → ditolak
HASIL: LOLOS — pemeriksa terbukti bisa MENOLAK yang rusak dan MENERIMA yang utuh.

RINGKASAN: 166 lolos, 0 gagal  -  10 tema, 130 pemeriksaan warna, 36 pemeriksaan aturan desain
UJI-DIRI uji-kontras
  OK  salinan utuh → kode 0
  OK  mutasi: token huruf --t-1 dihapus → ditolak
  OK  mutasi: tinggi kendali 40 px (di bawah lantai 44 px) → ditolak
  OK  mutasi: token --cincin dihapus dari token global → ditolak
  OK  mutasi: cincin fokus (:focus-visible) dilepas → ditolak
HASIL: LOLOS — pemeriksa terbukti bisa MENOLAK yang rusak dan MENERIMA yang utuh.
```

## 3. Pemeriksaan gerbang

| # | Perintah | Hasil nyata (ringkas) |
|---:|---|---|
| 1 | `bash aplikasi/alat/periksa-semua.sh` | exit 0; `SEMUA PEMERIKSAAN LOLOS.`; Vitest `76 passed`; SQL `31 LULUS · 0 GAGAL`; pemeriksa UI/CI/dokumen lulus. |
| 2 | `node alat/uji-sql.mjs` | exit 0; 13 migrasi diterapkan; `Menjalankan 31 berkas uji`; `uji: 31 LULUS · 0 GAGAL`; `HASIL: LOLOS`. |
| 3 | `python3 alat/uji-mutasi-0012.py` | exit 0; kontrol positif hijau; `RINGKASAN: 16/16 mutasi WAJIB terbukti MERAH`; kontrol penutup hijau. |
| 4 | `python3 _sistem/validate_system.py`; `python3 alat/periksa-roadmap.py`; `python3 alat/periksa-panduan.py`; `python3 alat/periksa-rujukan.py` | seluruhnya exit 0; validator sistem `PASS`; roadmap `192` tugas, `HASIL: LOLOS`; panduan dan 190 rujukan `HASIL: LOLOS`. |
| 5 | `python3 alat/audit-independen.py --uji-diri`; `python3 alat/review-pr.py --uji-diri` | kedua perintah exit 0; contoh laporan buruk ditolak dan contoh baik diterima; pemeriksa review berakhir `HASIL: LOLOS`. |
| 6 | `python3 aplikasi/alat/periksa-antarmuka.py`; `--uji-diri` | kedua perintah exit 0; kontrak penutupan panel, maska tepi gulir, dan 9 mutasi UI ditolak. |
| 7 | `python3 alat/periksa-gerbang-ci.py`; `--uji-diri` | kedua perintah exit 0; 13 gerbang lulus dan 8 mutasi pelemahan gerbang ditolak. |
| 8 | Uji izin/RLS saat dilonggarkan di salinan kalibrasi terpisah | exit 1 sesuai harapan: `izin.sql` menerima panggilan `boleh()` dari anon; `rls_pengguna.sql` mendapatkan 2 pengaturan, harap 1; `rls_semua_tabel.sql` melaporkan 1 baris pengaturan resto lain bocor. |
| 9 | Uji direct-DML jalur Merah: `/tmp/resto-probe-subtotal-dampak.sql` | exit 0 tetapi justru membuktikan celah: dapur menulis subtotal 1 dan jejak pembatalan menghasilkan nilai 1. |
| 10 | Uji direct-DML pembatalan → pembayaran: `/tmp/resto-probe-cancel-payment-accepted.sql` | exit 0 tetapi membuktikan celah: baris pembatalan tidak mengubah status (`draf`), lalu pembayaran 10.000 diterima. |

Keluaran mentah pemeriksaan utama:

```text
$ bash aplikasi/alat/periksa-semua.sh
...
RINGKASAN: 166 lolos, 0 gagal  -  10 tema, 130 pemeriksaan warna, 36 pemeriksaan aturan desain
...
SEMUA PEMERIKSAAN LOLOS.
exit code: 0

$ node alat/uji-sql.mjs
Menjalankan 31 berkas uji:
  LULUS supabase/tes/cabang_sesi.sql
  ...
  LULUS supabase/tes/stok_arah.sql
----------------------------------------------------------------------
uji: 31 LULUS · 0 GAGAL
HASIL: LOLOS
exit code: 0

$ python3 alat/uji-mutasi-0012.py
KONTROL PENUTUP (setelah dipulihkan harus hijau)
  OK  semua uji hijau lagi setelah pemulihan
RINGKASAN: 16/16 mutasi WAJIB terbukti MERAH (+ 2 mutasi tunggal pada penjaga bertumpuk: hijau = sesuai dugaan; lapisan itu dibuktikan lewat mutasi gabungan M3k)
exit code: 0

$ python3 alat/periksa-gerbang-ci.py --uji-diri
  OK  mutasi: suite SQL diberi `--daftar` → ditolak
  OK  mutasi: langkah bukti mutasi dihapus → ditolak
  OK  mutasi: npm audit diberi `|| true` → ditolak
  OK  mutasi: ambang audit diturunkan → ditolak
  OK  mutasi: langkah pemeriksa pohon bersih dihapus → ditolak
  OK  mutasi: langkah pemeriksa antarmuka dihapus → ditolak
  OK  mutasi: langkah uji-diri kontras dihapus → ditolak
  OK  mutasi: langkah diberi continue-on-error → ditolak
HASIL: LOLOS — pemeriksa terbukti bisa MENOLAK yang rusak dan MENERIMA yang utuh.
exit code: 0

$ node alat/uji-sql.mjs /tmp/resto-probe-subtotal-dampak.sql
  LULUS /tmp/resto-probe-subtotal-dampak.sql
uji: 1 LULUS · 0 GAGAL
HASIL: LOLOS
exit code: 0

$ node alat/uji-sql.mjs /tmp/resto-probe-cancel-payment-accepted.sql
  LULUS /tmp/resto-probe-cancel-payment-accepted.sql
uji: 1 LULUS · 0 GAGAL
HASIL: LOLOS
exit code: 0
```

Untuk memenuhi pemeriksaan RLS saat dilonggarkan, bahan kalibrasi di salinan `/tmp/resto-calibration-review-d1` mengubah policy secara terpisah; keluaran mentahnya adalah:

```text
sql_exit=1
Menjalankan 31 berkas uji:
  ...
  GAGAL supabase/tes/izin.sql
        ... perintah tidak ditolak (anon tidak boleh memanggil boleh())
  ...
  GAGAL supabase/tes/rls_pengguna.sql
        ... owner pusat hanya melihat pengaturan restonya (dapat 2, harap 1)
  ...
  GAGAL supabase/tes/rls_semua_tabel.sql
        Tabel public.pengaturan membocorkan 1 baris milik resto lain
uji: 28 LULUS · 3 GAGAL
HASIL: GAGAL
exit code: 1
```

## 4. Temuan

### [PR-01] Pengguna dapur dapat mengubah subtotal item dan memalsukan nilai kerugian

- **Tingkat:** K-1
- **Artefak:** `supabase/migrations/0009_pesanan.sql:294-303`; `supabase/migrations/0012_penutup_celah_review.sql:197-212`; konsumen uang di `supabase/migrations/0013_penutup_celah_putaran11.sql:211-236`
- **Klaim yang dilanggar:** Klaim 9 dan 11 — perubahan jalur uang tidak boleh dilewati lewat DML langsung dan subtotal harus dihitung peladen.
- **Bukti:** `node alat/uji-sql.mjs /tmp/resto-probe-subtotal-dampak.sql` → exit 0, `uji: 1 LULUS · 0 GAGAL`. Probe membuat item Rp26.000 sebagai pemilik, mengklaim pengguna dapur `90000000-0000-0000-0000-000000000006`, menjalankan `UPDATE ... SET subtotal = 1` melalui role `authenticated`, lalu sebagai owner memasukkan pembatalan item. Dua assertion probe lulus: subtotal menjadi 1 dan `nilai_kerugian` pembatalan menjadi 1.
- **Skenario gagal:** Pegawai dapur yang memang perlu mengubah status item (`baru → dimasak → siap`) mengirim update langsung pada seluruh baris. Policy `pesanan_item_dapur` memberi UPDATE baris, tetapi tidak membatasi kolom subtotal. Trigger `picu_item_harga_jujur` hanya menghitung ulang pada INSERT atau perubahan `qty`/`harga_saat_itu`; UPDATE subtotal saja melewati trigger tanpa normalisasi. Ketika item kemudian dibatalkan, `picu_pembatalan_sah` mengambil `pi.subtotal` sebagai nilai kerugian. Pada probe, kerugian resmi menjadi Rp1 alih-alih Rp26.000.
- **Dugaan penyebab:** Policy dapur ditambahkan untuk kebutuhan status item tanpa pemisahan hak kolom/penjaga immutable untuk `subtotal`; kondisi penghitungan ulang di 0012 tidak mencakup `new.subtotal is distinct from old.subtotal`.
- **Cara membuktikan perbaikan:** Tambahkan uji SQL role dapur yang mencoba `UPDATE pesanan_item SET subtotal = 1` dan harus ditolak atau selalu menghasilkan `harga_saat_itu * qty`; pertahankan uji status dapur. Setelah itu jalankan probe pembatalan yang sama dan pastikan `nilai_kerugian` tetap 26.000, lalu `node alat/uji-sql.mjs` dan `python3 alat/uji-mutasi-0012.py` harus tetap hijau.
- **Status verifikasi:** TERVERIFIKASI

### [PR-02] Uji resmi tidak memiliki regresi UPDATE langsung terhadap `pesanan_item.subtotal`

- **Tingkat:** K-3
- **Artefak:** `supabase/tes/harga_item.sql:1-80`; `supabase/tes/nilai_kerugian.sql:1-51`; `supabase/migrations/0012_penutup_celah_review.sql:197-204`
- **Klaim yang dilanggar:** Klaim 9 — uji otomatis membuktikan perilaku baru dan bebas regresi pada commit ini.
- **Bukti:** `grep -Rni --include='*.sql' -E 'update[[:space:]]+public\.pesanan_item.*subtotal|update[[:space:]]+public\.pesanan_item[[:space:]]*$' supabase/tes` menghasilkan tidak ada baris dan exit 1. Uji `harga_item.sql` lulus, tetapi hanya menguji INSERT, perubahan harga/nama, dan subtotal hasil INSERT. `node alat/uji-sql.mjs` tetap menghasilkan `31 LULUS · 0 GAGAL`, sehingga celah PR-01 tidak tersentuh.
- **Skenario gagal:** Penjaga dapat diubah atau policy dapur dapat tetap memberikan UPDATE subtotal, sementara seluruh suite tetap hijau karena tidak pernah mengirim UPDATE subtotal-only sebagai dapur. Uji `nilai_kerugian.sql` juga membuat item dengan subtotal awal dan tidak menggabungkan serangan perubahan subtotal oleh dapur sebelum pembatalan.
- **Dugaan penyebab:** Coverage disusun untuk harga/subtotal saat INSERT dan salinan harga immutable, bukan untuk setiap peran yang memperoleh hak UPDATE baris.
- **Cara membuktikan perbaikan:** Tambahkan assertion negatif/positif yang dijalankan sebagai pengguna dapur, lalu tambahkan regresi pembatalan sesudah perubahan status item. Suite penuh harus tetap `31+ LULUS · 0 GAGAL`; mutasi yang menghapus penjaga subtotal harus membuat tes baru merah.
- **Status verifikasi:** TERVERIFIKASI

### [PR-03] INSERT pembatalan tidak menutup pesanan dan pembayaran sesudah pembatalan tetap diterima

- **Tingkat:** K-1
- **Artefak:** `supabase/migrations/0013_penutup_celah_putaran11.sql:140-247`; `supabase/migrations/0010_pembayaran.sql:257-267`; `supabase/tes/persetujuan_void.sql:46-52`
- **Klaim yang dilanggar:** Klaim 8/11 dan aturan status/uang di `docs/TECH_SPEC.md` serta `docs/DECISIONS_LOG.md`: pembatalan berjejak harus menghasilkan keadaan `batal`, dan pesanan batal tidak boleh menerima pembayaran.
- **Bukti:** `node alat/uji-sql.mjs /tmp/resto-probe-cancel-payment.sql` exit 1 dengan keluaran mentah `dapat draf, harap batal`; ini membuktikan INSERT pembatalan tidak memajukan `pesanan.status`. Probe lanjutan `/tmp/resto-probe-cancel-payment-accepted.sql` exit 0, `uji: 1 LULUS · 0 GAGAL`: setelah baris pembatalan dibuat, status masih `draf` dan INSERT pembayaran Rp10.000 diterima. Trigger pembatalan menghitung nilai/izin tetapi tidak menjalankan `UPDATE public.pesanan SET status = 'batal'`.
- **Skenario gagal:** Kasir/owner membatalkan pesanan yang totalnya sudah dihitung. Karena status tetap `draf`, guard pembayaran hanya `if v_pesanan.status = 'batal'` tidak aktif. Pembayaran dapat tercatat untuk pesanan yang sudah memiliki baris pembatalan; jejak status dan uang berlawanan.
- **Dugaan penyebab:** Perbaikan status awal hanya menutup INSERT status `batal`/`lunas`; mesin transisi resmi yang seharusnya menetapkan `batal` sesudah pembatalan masih belum dipanggil oleh trigger/RPC pembatalan.
- **Cara membuktikan perbaikan:** Uji pembatalan harus mengassert `pesanan.status = 'batal'`, `dibatalkan_pada`/`alasan_batal` terisi sesuai kontrak, dan INSERT pembayaran sesudahnya harus gagal dengan alasan pesanan batal. Jalankan juga uji status dan pembayaran penuh setelah perbaikan.
- **Status verifikasi:** TERVERIFIKASI

### [PR-04] Paket review yang ikut di-commit menunjuk commit dan head cabang yang berbeda

- **Tingkat:** K-3
- **Artefak:** `docs/uji/review-pr/PKT-2026-09-18-pr-01-putaran13.md:11-14`
- **Klaim yang dilanggar:** Klaim 9 dan aturan paket review: paket harus mengikat commit yang benar-benar direview.
- **Bukti:** Pada tree d1, `sed -n '11,15p' docs/uji/review-pr/PKT-2026-09-18-pr-01-putaran13.md` mencetak `head: origin/arena/01a0a8a2-resto-barokah`, `Commit yang direview: 57fe6899e0e607149e50a4d827acdb6bab92f42a`, dan `388 berkas · +52391 / −143`. Header tugas ini menetapkan commit d1. Perbandingan base→tree d1 yang saya jalankan menghasilkan 388 berkas, +52418/−143. Saya tetap mereview d1 sesuai instruksi, bukan SHA yang tertulis stale di paket.
- **Skenario gagal:** Peninjau mengikuti paket SIAP-TEMPEL dan menjalankan bukti terhadap 57fe atau head lama, lalu melaporkan hasil yang tidak berlaku untuk d1. Angka perubahan juga dapat membuat kedalaman review/daftar berkas salah.
- **Dugaan penyebab:** Paket disegarkan pada commit sebelumnya tetapi disalin/ditinggalkan ketika target bergerak; tidak ada gerbang yang memeriksa SHA paket terhadap commit yang diminta sebelum review.
- **Cara membuktikan perbaikan:** Regenerasi kedua paket review dari base `origin/main` dan head d1; header harus memuat SHA d1 dan statistik independen harus cocok. Jalankan `python3 alat/review-pr.py --periksa-laporan` pada laporan baru serta pemeriksaan kesiapan paket.
- **Status verifikasi:** TERVERIFIKASI

### [PR-05] Nama langkah CI masih mengklaim 28 berkas padahal tree menjalankan 31

- **Tingkat:** K-3
- **Artefak:** `.github/workflows/ci.yml:67`; `alat/periksa-gerbang-ci.py:6`; `PANDUAN_PENGGUNA.md:63`
- **Klaim yang dilanggar:** Klaim 10/12 — bukti CI dan dokumen tidak boleh memuat cakupan uji basi/menyesatkan.
- **Bukti:** `sed -n '63,70p' .github/workflows/ci.yml` mencetak `Uji SQL penuh ... (28 berkas)`, sedangkan `find supabase/tes -maxdepth 1 -name '*.sql' | wc -l` mencetak `31` dan `node alat/uji-sql.mjs` mencetak `Menjalankan 31 berkas uji` serta `31 LULUS`. `PANDUAN_PENGGUNA.md:63` juga sudah menyebut 31. Gerbang CI memang menjalankan perintah penuh, tetapi labelnya salah dan pemeriksa gerbang tidak menjaga angka label.
- **Skenario gagal:** Lee atau peninjau membaca nama langkah CI sebagai cakupan faktual dan menyimpulkan hanya 28 berkas yang dijalankan, atau tidak tahu bahwa tiga tes tambahan ada.
- **Dugaan penyebab:** Nama langkah dan komentar riwayat tidak disegarkan ketika tiga berkas tes ditambahkan.
- **Cara membuktikan perbaikan:** Ubah label menjadi hitungan yang benar atau hilangkan angka statis; tambahkan pemeriksaan yang membandingkan label bila angka sengaja dipertahankan. Jalankan pemeriksa gerbang dan suite SQL lagi.
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman

Bahan diperiksa **terpisah** dan tidak dipasang pada tree kerja laporan:

```text
rm -rf /tmp/resto-calibration-review-d1
cp -a /tmp/resto-review-d1 /tmp/resto-calibration-review-d1
cd /tmp/resto-calibration-review-d1
 git apply --check docs/uji/kalibrasi/pr-bahan-2026-09-17.diff
 git apply docs/uji/kalibrasi/pr-bahan-2026-09-17.diff
 git_apply_exit=0
```

Saya tidak membaca kunci jawaban di luar repo. Setelah patch diterapkan, `node alat/uji-sql.mjs` pada salinan itu menghasilkan exit 1, `28 LULUS · 3 GAGAL`: dua akar cacat efektif ditemukan (policy `pengaturan` lintas resto dan revoke `boleh(text, uuid)` yang hilang). Tiga assertion gagal berasal dari dua akar yang sama; saya tidak menghitungnya sebagai tiga temuan terpisah. Dua hunk bahan lain tidak efektif pada hasil migrasi final karena definisi berikutnya menimpa fungsi yang diubah (`cabang_saya()` ditimpa di 0012 dan `picu_diskon_batas()` ditimpa di 0013); melaporkannya sebagai cacat runtime akan menjadi temuan palsu.

**Ditemukan: 2 dari 4 perubahan yang ditanam (2 dari 2 cacat efektif) · temuan palsu: 0.** Dua perubahan yang tertimpa saya catat sebagai bahan kalibrasi stale/non-efektif, bukan sebagai cacat proyek. Keluaran salinan yang relevan:

```text
GAGAL supabase/tes/izin.sql
  ... perintah tidak ditolak (anon tidak boleh memanggil boleh())
GAGAL supabase/tes/rls_pengguna.sql
  ... owner pusat hanya melihat pengaturan restonya (dapat 2, harap 1)
GAGAL supabase/tes/rls_semua_tabel.sql
  Tabel public.pengaturan membocorkan 1 baris milik resto lain
uji: 28 LULUS · 3 GAGAL
HASIL: GAGAL
exit code: 1
```

## 6. Yang tidak bisa saya verifikasi

- Saya tidak dapat memverifikasi deployment Supabase nyata, PostgREST/Edge Function nyata, atau RLS pada proyek cloud; runner yang tersedia adalah PostgreSQL PGlite lokal. Probe membuktikan SQL/RLS lokal, bukan konfigurasi cloud.
- Saya tidak dapat memverifikasi run GitHub Actions yang benar-benar terhubung ke commit d1; saya hanya menjalankan salinan gerbang dan mutasinya secara lokal.
- `hitung_total()` belum menjadi fungsi produksi di tree ini (ROADMAP T1-15 masih tertunda), sehingga alur nominal total penuh sampai pembayaran tidak dapat dinilai sebagai alur aplikasi produksi. Guard pembayaran yang ada justru menolak total nol; ini bukan bukti bahwa kalkulasi total kelak benar.
- Saya tidak menjalankan aplikasi pada perangkat kasir/dapur nyata atau menguji API browser terhadap backend cloud.

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca dan bukan sesi penulis PR. Saya tidak mengubah atau memperbaiki snapshot target; semua probe, salinan kalibrasi, dan log ditulis di `/tmp`, di luar repository target. **SATU-SATUNYA berkas yang saya buat/ubah di checkout sesi ini adalah laporan ini**: `docs/uji/review-pr/LAPORAN_2026-09-18_pr-01-putaran13__01a0b1f3.md`. Setelah penulisan, `git status --short` harus menampilkan hanya berkas laporan ini sebelum commit; saya tidak akan memasukkan berkas lain ke commit.

## 8. Temuan di luar cakupan diff

| # | Temuan | Mengapa di luar cakupan diff | Bukti | Saran ditindaklanjuti |
|---:|---|---|---|---|
| 1 | `hitung_total()` belum ada sebagai jalur produksi | Roadmap menandainya sebagai T1-15 yang tertunda; ini batas produk yang belum dibangun, bukan perubahan yang dijanjikan selesai oleh paket ini | `grep -Rni 'hitung_total' supabase/migrations` tidak menemukan fungsi; komentar 0010 menyebut T1-15 | Jangan buka pembayaran produksi sebelum RPC total server-derived hadir dan diuji dengan subtotal/diskon/pajak/service/pembulatan. |
| 2 | Supabase cloud, Edge Functions, dan aplikasi browser belum diverifikasi | Paket hanya menyediakan runner lokal; tidak ada kredensial/proyek cloud yang bisa diuji dalam review ini | `node alat/uji-sql.mjs` sendiri mencetak `tanpa server, tanpa akun`; tidak ada uji deployment yang dijalankan | Jalankan smoke test dan RLS/API test pada proyek staging nyata sebelum pilot. |
| 3 | Bahan kalibrasi yang ikut tree memuat dua hunk yang tertimpa migrasi berikutnya | Ini masalah mutu bahan kalibrasi, bukan cacat runtime tree d1; saya sengaja tidak mengubah bahan | `grep -n 'create or replace function public.cabang_saya\|create or replace function public.picu_diskon_batas' supabase/migrations/0012_penutup_celah_review.sql supabase/migrations/0013_penutup_celah_putaran11.sql` menunjukkan definisi final berikutnya | Segarkan bahan kalibrasi dari tree target final dan validasi bahwa setiap hunk mengubah perilaku efektif sebelum dipakai mengukur reviewer. |

**Rencana pemulihan/sisa risiko:** jangan merge d1. Pertama tutup PR-01 dan PR-03 dengan migrasi/uji merah-dulu; kemudian tambahkan regresi PR-02. Regenerasi paket/label CI dan segarkan bahan kalibrasi. Setelah itu ulangi seluruh gerbang, direct-DML probe, mutasi, dan pemeriksaan pada commit baru. Sisa risiko cloud/browser tetap memerlukan staging nyata.