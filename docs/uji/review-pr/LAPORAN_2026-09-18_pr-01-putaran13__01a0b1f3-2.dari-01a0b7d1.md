# LAPORAN REVIEW PR INDEPENDEN — pr-01-putaran13 — 2026-09-18

- **Paket review:** `docs/uji/review-pr/PKT-2026-09-18-pr-01-putaran13.md`
- **Commit yang direview:** `d1f11d7f32bdb78b14b6ed4d935946c515c656df`
- **Tingkat risiko:** Merah
- **Verdict:** TIDAK-BERSIH

> Catatan peninjau: paket yang Lee tempel menunjuk commit `d1f11d7` (117 commit · 388 berkas · +52418/−143);
> berkas `PKT-2026-09-18-pr-01-putaran13.md` yang tersimpan DI commit itu masih menunjuk `57fe689` (115 commit · +52391/−143).
> Selisihnya dua commit dokumen/paket saja (`1af5bdb`, `d1f11d7` — 6 berkas, semua dokumen/paket), jadi review ini
> mengikuti sha yang disebut paket tempelan: `d1f11d7`. Bukti: `git diff --stat 57fe689..d1f11d7` → 6 berkas
> (PROJECT_STATE.md, docs/DECISIONS_LOG.md, 2 paket audit, 2 paket review). Kedalaman mengikuti jalur Merah:
> **lensa L1 (ancaman & akses) + L2 (uang & jejak) + L4 (mutu uji)** — ketiganya dijalankan.

## 1. Cakupan diff

Total berkas berubah: **388** (378 tambah · 10 ubah) · +52418/−143 baris — sesuai paket tempelan.
Perintah: `git diff --name-status origin/main...d1f11d7 | awk '{print $1}' | sort | uniq -c` → `378 A · 10 M`.

| # | Berkas | Jalur risiko | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|---|
| 1 | `supabase/migrations/0001…0013_*.sql` (13 berkas) | Merah | Ya — dibaca baris-per-baris | `cat supabase/migrations/0013_penutup_celah_putaran11.sql`; migrasi juga diterapkan nyata oleh harness |
| 2 | `supabase/tes/*.sql` (31 berkas) | Merah | Ya — seluruhnya DIJALANKAN; 8 dibaca detail (`diskon_voucher`, `pesanan_status_awal`, `nilai_kerugian`, `stok_arah`, `pin_kunci_silang`, `diskon_cap`, `kredensial_pin`, `izin`) | `node alat/uji-sql.mjs` → `uji: 31 LULUS · 0 GAGAL`, exit 0 |
| 3 | `alat/sql/data-uji.sql` + `alat/uji-sql.mjs` | Kuning | Ya — dibaca penuh (fixture & harness) | `cat alat/sql/data-uji.sql`; harness PGlite + `set local role authenticated`, tiap uji di-rollback |
| 4 | `supabase/functions/verifikasi_pin/index.ts` | Merah | Ya — dibaca penuh | POST-saja, tanpa `console.*`, tanpa service_role; catatan: TIDAK meneruskan `p_pesanan_id` (kupon 0012 tak tercapai lewat fungsi ini) |
| 5 | `.github/workflows/ci.yml` | Merah | Ya — dibaca penuh + pemeriksa dijalankan | `python3 alat/periksa-gerbang-ci.py` → LOLOS; lihat temuan [PR-07] (angka nama langkah basi) |
| 6 | `alat/review-pr.py` | Merah | Ya — dibaca (pembuat klaim + validator laporan) | `sed -n '124,160p' alat/review-pr.py` (sumber klaim = butir pesan commit); `--uji-diri` LOLOS |
| 7 | `alat/periksa-gerbang-ci.py` | Merah | Ya — dibaca + dijalankan | 13 gerbang wajib + larangan `continue-on-error`/`|| true`/`exit 0` |
| 8 | `alat/periksa-{bersih,buku-uji,fondasi-independen,fungsi-pin,panduan,rahasia,roadmap,rujukan,temuan-audit}.py` | Merah | Ya — dijalankan (semua) + `periksa-rujukan`/`periksa-panduan`/`periksa-bersih` dibaca | `bash aplikasi/alat/periksa-semua.sh` → SEMUA PEMERIKSAAN LOLOS, exit 0 |
| 9 | `alat/audit-independen.py` | Merah | Ya — `--uji-diri` dijalankan | LOLOS (termasuk fixture negatif "BELUM TERKALIBRASI" yang benar ditolak), exit 0 |
| 10 | `aplikasi/alat/periksa-*.py`, `periksa-semua.sh`, `uji-kontras.py` | Merah | Ya — dijalankan; `periksa-antarmuka` (10 uji-diri), `uji-kontras` (4), `periksa-komponen-env` dibaca | `periksa-antarmuka.py --uji-diri` → 10 OK; `uji-kontras --uji-diri` → 4 OK; `periksa-komponen-env` menyelesaikan `var()` (baris 81–88) |
| 11 | `_sistem/validate_system.py` | Merah | Ya — dijalankan | `SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS`, exit 0 |
| 12 | `alat/uji-mutasi-0012.py` | Kuning | Ya — dijalankan via gerbang | `RINGKASAN: 16/16 mutasi WAJIB terbukti MERAH` |
| 13 | `aplikasi/src/**` (71 berkas) | Kuning | Ya — dipindai menyeluruh (32 berkas kode; layar lain masih `.gitkeep`) | tidak ada pemanggilan supabase/RPC di `aplikasi/src`; `npm run lint`/`typecheck`/`test` (76 uji)/`build` hijau |
| 14 | `docs/KEAMANAN.md` | Merah | Ya — dibaca | jujur soal `hitung_total` (T1-15) belum ada; klaim §9.6–9.8 dicocokkan dengan 0013 |
| 15 | `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`, `PROTOKOL_AUDIT_INDEPENDEN.md`, `PROMPT_AUDIT_INDEPENDEN.md` | Merah | Ya — dibaca penuh (aturan main) | — |
| 16 | docs/uji/kalibrasi/pr-bahan-2026-09-17.diff | (kalibrasi) | Ya — diterapkan di salinan terpisah & diuji | lihat bagian 5 |
| 17 | `docs/uji/REVIEW_PR_RIWAYAT.md`, `docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md`, `docs/uji/BUKU_UJI_PEMILIK.md` | Hijau | Ya — dibaca (konteks L-01…L-14) | — |
| 18 | `skills/desain-antarmuka/SKILL.md` | Kuning | Ya — dibaca penuh | 3 pelajaran + §Sumber + §Daftar periksa (baris 121, 139) |
| 19 | `docs/{ROADMAP,PRD,TECH_SPEC,DECISIONS_LOG,SPESIFIKASI_UI,PANDUAN_PEMILIK}.md` | Kuning | Ya — via pemeriksa mesin + baca ringkas | `periksa-roadmap.py` LOLOS; `periksa-panduan.py` LOLOS; `periksa-rujukan.py` LOLOS |
| 20 | `prototipe/**` (54 aset + html/js) · `docs/desain/**` (59) | Hijau | Tidak dibaca baris-per-baris — diperiksa LEWAT GERBAUT mesin yang dijalankan | `uji-kontras.py` → `RINGKASAN: 166 lolos, 0 gagal`; `periksa-halaman 183/183` (via periksa-antarmuka) |
| 21 | `package.json`, `package-lock.json` (alat), `supabase/README.md`, `.gitignore`, berkas log/status sesi | Hijau/Kuning | Ya — dilihat ringkas | `cat package.json` (alat) → `@napi-rs/canvas` |

Tidak ada berkas Merah yang dilewati. Berkas Hijau (aset desain/prototipe, mayoritas dokumen) tidak dibaca
satu-satu — diperiksa lewat gerbang mesin yang benar-benar dijalankan (prettier, periksa-antarmuka, uji-kontras,
periksa-halaman, periksa-struktur, periksa-rahasia, periksa-bersih) dan itu saya nyatakan sebagai batas di bagian 6.

## 2. Klaim yang dibantah

| # | Klaim | Cara membantah | Hasil nyata |
|---|---|---|---|
| 1 | `skills/desain-antarmuka/SKILL.md` (3 pelajaran + sumber + daftar periksa) | `grep -n "^## " skills/desain-antarmuka/SKILL.md` | **TERBUKTI.** 3 pelajaran (## 1 Kerapatan, ## 2 Panel/popover, ## 3 Tepi gulir) + `## Sumber` (baris 121) + `## Daftar periksa singkat` (baris 139, 4 butir centang) |
| 2 | wajib dibaca di fase DESAIN (`alat/mulai-sesi.py`) | `grep -n -A2 "DESAIN" alat/mulai-sesi.py` | **TERBUKTI.** `"DESAIN": ["desain-antarmuka", …]` (baris 79) — skill itu didaftarkan pertama |
| 3 | penjaga baru `aplikasi/alat/periksa-antarmuka.py` (10 uji-diri) menolak keadaan rusak | `python3 aplikasi/alat/periksa-antarmuka.py --uji-diri \| grep -c "^  OK"` | **TERBUKTI.** keluaran `10`; mutasi mencakup Esc dihapus, maska di wadah, klik-luar dimatikan, salinan CSS menyimpang, id kembar, kemampuan desain dihapus |
| 4 | `alat/periksa-rujukan.py`: ekstensi `ts` lebih dulu dari `tsx` → rujukan .tsx terbaca (bug, sudah dibetulkan) | `grep -n "POLA_JALUR" alat/periksa-rujukan.py` + uji-diri | **TERBUKTI.** `POLA_JALUR` kini `…\.(?:tsx\|markdown\|mjs\|json\|ya?ml\|sql\|html\|md\|py\|sh\|ts)` — `tsx` lebih dulu; dijaga mutasi "berkas .tsx yang dirujuk DIHAPUS" (baris 122–132); `periksa-rujukan.py --uji-diri` LOLOS |
| 5 | `aplikasi/alat/uji-kontras.py`: komentar di belakang nilai membuat token berikutnya tak terbaca (sudah dibetulkan) | `grep -n -A8 "tanpa_komentar" aplikasi/alat/uji-kontras.py` | **TERBUKTI.** `tanpa_komentar()` mengganti komentar dengan baris kosong TANPA menghapus struktur baris (baris 83–92); uji-diri 4 mutasi OK termasuk "token huruf --t-1 dihapus" |
| 6 | `aplikasi/alat/periksa-komponen-env.py`: menyelesaikan `var()` sebelum menilai lantai 44 px | `sed -n '77,90p' aplikasi/alat/periksa-komponen-env.py` | **TERBUKTI.** `re.fullmatch(r"var\(\s*(--[a-z0-9-]+)\s*\)", nilai)` → nilai token diambil dari CSS akar sebelum dibandingkan `>= 44` |
| 7 | PR-01 putaran11 (K-2, uang): jalur diskon `voucher` ditutup gagal-aman di 0013 | jalankan uji + mutasi balik | **TERBUKTI.** `supabase/tes/diskon_voucher.sql` LULUS; cabang voucher di 0013 `raise exception 'Diskon voucher belum aktif…'`. Uji mutasi saya (cabang dikembalikan ke versi lama) → `diskon_voucher.sql` GAGAL, exit 1 (lihat bagian 3 #6) |
| 8 | PR-02 putaran11 (K-3): pesanan tidak bisa LAHIR `batal`/`lunas` (pemicu baru `picu_pesanan_status_awal`) | `node alat/uji-sql.mjs supabase/tes/pesanan_status_awal.sql` | **TERBUKTI.** LULUS — 4 penolakan (lahir `batal`, lahir `lunas`, bawa tanda kirim, bawa tanda batal) + 2 kontrol hijau; penjaga memang bukan `security definer` (komentar 0013 baris 236–240) |
| 9 | Uji otomatis membuktikan perilaku baru/bebas regresi pada commit ini | `node alat/uji-sql.mjs` pada d1f11d7 + probe independen | **SEBAGIAN DIBANTAH.** 31/31 uji LULUS untuk yang DIUJI, tetapi probe saya menemukan 5 jalur yang TIDAK diuji dan bisa dilalui dari API (temuan PR-01…PR-06 di bawah) — "bebas regresi" hanya berlaku untuk cakupan uji yang ada |
| 10 | Tidak ada gerbang keamanan/CI yang dilemahkan | `python3 alat/periksa-gerbang-ci.py` + baca `ci.yml` + banding basis | **TERBUKTI (dengan catatan).** `ci.yml` berkas BARU vs basis (main tidak punya CI) — tak ada gerbang lama yang dicabut; 13 gerbang wajib ada; tanpa `continue-on-error`/`|| true`; pemeriksa LOLOS. Catatan: angka "28 berkas" pada NAMA langkah uji SQL basi (nyata 31) → temuan [PR-07] |
| 11 | Perubahan jalur uang/keamanan/data pelanggan tidak bisa dilewati lewat pemanggilan langsung (RPC/API) | probe SQL independen sebagai `authenticated` (simulasi PostgREST) lewat PGlite | **DIBANTAH.** Penjaga NOMINAL uang bertahan (kontrol saya semua ditolak), tetapi 6 jalur integritas/jejak bisa dilalui langsung dari "perangkat": rebutan PIN owner→kupon persetujuan palsu [PR-01], INSERT stok bertanda bohong [PR-02], atribusi pesanan dipalsukan [PR-03], cap `disetujui_oleh` diskon dipalsukan [PR-04], item `batal`/qty tanpa jejak & di luar peran [PR-05], label metode pembayaran dikarang [PR-06] |
| 12 | Dokumen perilaku ikut diperbarui — tidak ada klaim basi | `validate_system.py` + `periksa-panduan.py` + `periksa-rujukan.py` + `periksa-bersih.py` + baca `docs/KEAMANAN.md` | **SEBAGIAN DIBANTAH.** Kelima pemeriksa LOLOS dan KEAMANAN.md jujur (mis. `hitung_total` T1-15 dinyatakan belum ada), TETAPI nama langkah CI "(28 berkas)" basi — nyata 31 (temuan [PR-07]); kelas cacat "angka basi" yang sama dengan putaran11 PR-04, tidak dijaga pemeriksa mana pun |

## 3. Pemeriksaan gerbang

| # | Perintah | Hasil nyata (ringkas) |
|---|---|---|
| 1 | `bash aplikasi/alat/periksa-semua.sh` (di salinan commit d1f11d7) | **LOLOS, exit 0.** `Test Files 10 passed (10)` · `Tests 76 passed (76)` · `found 0 vulnerabilities` · `uji: 31 LULUS · 0 GAGAL` · `RINGKASAN: 16/16 mutasi WAJIB terbukti MERAH` · seluruh pemeriksa Python LOLOS · `uji-kontras` 166 lolos/0 gagal · baris akhir `SEMUA PEMERIKSAAN LOLOS.` |
| 2 | `node alat/uji-sql.mjs` | **LOLOS, exit 0.** 13 migrasi OK, data uji OK, `Menjalankan 31 berkas uji` → semua LULUS → `uji: 31 LULUS · 0 GAGAL` · `HASIL: LOLOS` |
| 3 | `git diff origin/main...d1f11d7` | Dibaca sungguhan: 388 berkas (+52418/−143). Yang TIDAK ada di deskripsi paket: seluruh lapisan database (14 migrasi, 31 uji), Edge Function PIN, CI, 13+ pemeriksa Python — dan 6 jalur celah baru yang saya temukan (bagian 4) |
| 4 | `python3 _sistem/validate_system.py` · `python3 alat/periksa-roadmap.py` · `python3 alat/periksa-panduan.py` | `SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS` exit 0 · `HASIL: LOLOS — semua pemeriksaan roadmap terpenuhi.` exit 0 · `HASIL: LOLOS — buku induk lengkap, rujukan hidup…` exit 0 |
| 5 | `python3 alat/audit-independen.py --uji-diri` · `python3 alat/review-pr.py --uji-diri` | Keduanya **LOLOS, exit 0** (audit: fixture negatif "BELUM TERKALIBRASI" benar ditolak + jalur pulang laporan OK; review-pr: 5 contoh laporan buruk ditolak + `bagus.md` diterima) |
| 6 | **Uji mutasi (wajib Merah)** — cabang voucher 0013 dikembalikan ke perilaku lama (hanya cek `boleh('pakai_voucher')`) lalu `node alat/uji-sql.mjs` | **MERAH, exit 1:** `uji: 30 LULUS · 1 GAGAL` — `supabase/tes/diskon_voucher.sql: HARAPAN TIDAK TERPENUHI: perintah tidak ditolak`. Dikembalikan utuh → `uji: 31 LULUS · 0 GAGAL`, exit 0 |
| 7 | **RLS dilonggarkan (wajib Merah)** — policy `izin_peran_pilih` diubah `using (penyewa_id = penyewa_saya())` → `using (true)` lalu `node alat/uji-sql.mjs` | **MERAH, exit 1:** `GAGAL supabase/tes/izin.sql` + `GAGAL supabase/tes/rls_semua_tabel.sql` → `uji: 29 LULUS · 2 GAGAL` · `HASIL: GAGAL`. Dipulihkan → 31 LULUS, exit 0 |
| 8 | Kontrol jalur uang (probe p6): kasir ubah status→`batal`, tulis angka uang, bayar di pesanan total-0, diskon `promo`, `catat_stok` lintas resto | **Semua DITOLAK** (5/5) — penjaga 0009/0010/0012/0013 dan isolasi stok hidup; probe jujur (bukan semua hijau) |
| 9 | Probe bantahan (p1): dapur (izin `ubah_stok`) hapus baris harga cabang `menu_cabang` | **DITOLAK** — `permission denied for table menu_cabang` (grant tingkat tabel hanya insert/update) — hipotesis saya sendiri gagal, dicatat jujur |

## 4. Temuan

> Kedalaman jalur Merah: semua temuan di bawah dibuktikan dengan MENJALANKAN perintah (PGlite asli lewat
> `node alat/uji-sql.mjs <berkas probe>` dengan `set local role authenticated` — simulasi pemanggilan langsung
> API/PostgREST), bukan membaca potongan kode. Probe disimpan di luar repo (`/tmp/probe/*.sql`); repo tidak diubah.

### [PR-01] Pegawai ber-izin `kelola_pegawai` bisa merebut PIN owner lalu memalsukan persetujuan void atas nama owner
- **Tingkat:** K-2
- **Artefak:** `supabase/migrations/0011_peran_tunggal.sql:250-283` (fungsi `simpan_pin`, cabang target ≠ pemanggil hanya memeriksa `sepenyewa` + `boleh('kelola_pegawai')`) · `supabase/migrations/0012_penutup_celah_review.sql:400-417` (kupon persetujuan) · `supabase/migrations/0011_peran_tunggal.sql` izin bawaan `admin_cabang/kelola_pegawai = true` (`0005_izin_berjenjang.sql:89`)
- **Klaim yang dilanggar:** Klaim #11 ("tidak bisa dilewati lewat pemanggilan langsung RPC/API") + jaminan hasil perbaikan AUD-3 K-2/A F-03 ("bukti persetujuan = PIN penyetuju sendiri") yang diklaim dijaga migrasi ini
- **Bukti:** probe `node alat/uji-sql.mjs /tmp/probe/p7_admin_reset_pin_owner.sql` → **LULUS** (artinya seluruh rantai diterima):
  ```
  1. owner memasang PIN '738294'                    → 'PIN tersimpan.'
  2. admin_cabang: simpan_pin('849273', null, <uuid owner>, 'hp-admin')
     → 'PIN tersimpan.'   (TANPA PIN lama, TANPA pemberitahuan ke owner)
  3. admin: verifikasi_pin(<owner>, '849273', 'void_sesudah_dapur', 'hp-admin', <pesanan>)
     → berhasil = true    (kupon persetujuan atas nama owner TERBIT)
  4. insert pembatalan tahap='sesudah_dapur' disetujui_oleh=<owner> → TERSIMPAN
  5. kontrol: select count(*) from percobaan_simpan_pin → DITOLAK
     (owner tidak punya jalan melihat bahwa PIN-nya direbut — tabel tanpa akses klien)
  ```
  `sepenyewa()` hanya memeriksa satu resto; tidak ada pemeriksaan hierarki peran (bawahan boleh reset atasannya). Tidak ada uji yang menyentuh skenario ini (`grep -rn "simpan_pin" supabase/tes/` — semua uji reset-PIN memakai pemanggil owner, bukan admin ke owner).
- **Skenario gagal:** admin cabang yang jahat diam-diam mereset PIN owner, memakainya menyetujui pembatalan-pembatalan "sesudah dapur" (rugi bahan) selama Owner tidak sedang memakai PIN; laporan bulanan "siapa menyetujui apa" (KEAMANAN.md §9.4) menuduh owner. Owner baru sadar saat PIN-nya sendiri tak lagi diterima — dan tidak ada jejak yang bisa ia baca.
- **Dugaan penyebab:** `kelola_pegawai` dimaknai "boleh mengatur PIN siapa pun sekedai", tanpa batas hierarki (pemanggil tidak boleh menyentuh kredensial pengguna yang lebih tinggi perannya) dan tanpa jejak yang terlihat korban.
- **Cara membuktikan perbaikan:** uji baru: `simpan_pin(pin, null, <uuid owner_pusat>, …)` dipanggil admin_cabang → harus DITOLAK; uji rantai: admin reset PIN kasir → kupon void atas nama kasir tanpa izin void_sesudah_dapur → tetap ditolak; dan baris `percobaan_simpan_pin` readable oleh korban/owner. Semua harus merah sebelum perbaikan, hijau sesudahnya (`node alat/uji-sql.mjs` exit 0).
- **Status verifikasi:** TERVERIFIKASI

### [PR-02] INSERT langsung ke `stok_pergerakan` menerima jenis dan tanda yang bertentangan — normalisasi arah hanya ada di `catat_stok`
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0012_penutup_celah_review.sql:489-563` (normalisasi tanda hanya di `catat_stok`) · `supabase/migrations/0007_katalog.sql:449-453` (policy `stok_pergerakan_tambah` mengizinkan INSERT langsung pemegang `ubah_stok`)
- **Klaim yang dilanggar:** klaim #11 + perbaikan putaran8 "arah stok ditentukan JENIS" (commit "Tutup temuan review putaran8 (migrasi 0012 …)")
- **Bukti:** probe `node alat/uji-sql.mjs /tmp/probe/p2_stok_insert_langsung.sql` (sebagai dapur, izin `ubah_stok`) → **LULUS**:
  ```
  saldo awal Beras = 20
  insert into stok_pergerakan (…, jenis='keluar', jumlah=7, …)  -- langsung via API
  → saldo = 27 (NAIK dari baris yang menyebut KELUAR)
  → baris buku besar menyimpan +7 dengan jenis='keluar' (kontradiksi tersimpan permanen)
  ```
- **Skenario gagal:** pegawai stok menyembunyikan kebocoran bahan: baris berlabel "keluar" yang justru menambah saldo (atau "masuk" minus) membuat buku besar dan saldo saling bohong; selisih opname tertutup tanpa jejak jujur — persis dampak temuan putaran8 (laporan C PR-03), kini lewat pintu INSERT langsung.
- **Dugaan penyebab:** perbaikan 0012 menambal RPC saja; policy INSERT langsung (sudah ada sejak 0007) luput ditutup/dinormalisasi di pemicu tabel.
- **Cara membuktikan perbaikan:** pindahkan normalisasi tanda ke pemicu `picu_stok_pergerakan` (atau cabut policy INSERT langsung); uji: insert langsung jenis='keluar' +7 → saldo berkurang 7 ATAU ditolak. `node alat/uji-sql.mjs` hijau.
- **Status verifikasi:** TERVERIFIKASI

### [PR-03] Atribusi pesanan bisa dipalsukan: `pelayan_id`/`kasir_id` dikarang klien; `dibatalkan_pada`+`alasan_batal` bisa ditempel tanpa baris pembatalan
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0009_pesanan.sql` (policy `pesanan_tambah`/`pesanan_ubah`; tidak ada pemicu yang memaksa `pelayan_id`/`kasir_id`/`dibatalkan_pada`) · `supabase/migrations/0013_penutup_celah_putaran11.sql:243-268` (penjaga hanya pada INSERT status/tanda)
- **Klaim yang dilanggar:** klaim #11 + kelas perbaikan AUD-3 K-2 "jejak pelaku tidak boleh dikarang klien" (ditegakkan untuk pembayaran/diskon/pembatalan/stok/pengaturan — pesanan terlewat)
- **Bukti:** probe `node alat/uji-sql.mjs /tmp/probe/p3_jejak_pesanan.sql` (sebagai kasir) → **LULUS**:
  ```
  insert pesanan … pelayan_id = <uuid owner>       → TERSIMPAN (kasir menulis owner sebagai pelayan)
  update pesanan set kasir_id = <uuid pelayan>,
                     dibatalkan_pada = now(),
                     alasan_batal = 'dibatalkan (karangan probe)' → TERSIMPAN
  (jumlah baris pembatalan untuk pesanan itu = 0 — tanda batal tanpa jejak)
  ```
- **Skenario gagal:** laporan "siapa melayan/menagih pesanan apa" bisa dicuci oleh kasir mana pun; tanda `dibatalkan_pada`/`alasan_batal` bisa ditempel pada pesanan hidup tanpa satu baris `pembatalan` — Aturan Bisnis 7 (pembatalan wajib berjejak) tergelincir lewat UPDATE (penjaga 0013 hanya di INSERT).
- **Dugaan penyebab:** perbaikan 0013 menyasar kelahiran pesanan saja; kolom atribusi/tanda-batal pada tabel pesanan tidak pernah dapat penjaga seperti tabel uang lain.
- **Cara membuktikan perbaikan:** pemicu memaksa `pelayan_id`/`kasir_id` = `auth.uid()` (atau tolak nilai lain), dan menolak `dibatalkan_pada`/`alasan_batal` dari perangkat; uji regresi merah→hijau.
- **Status verifikasi:** TERVERIFIKASI

### [PR-04] `diskon_transaksi.disetujui_oleh` bebas dikarang klien — cap "disetujui owner" tanpa PIN/bukti apa pun
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0013_penutup_celah_putaran11.sql:37-153` (fungsi final `picu_diskon_batas` — memaksa `pelaku_id` tetapi `disetujui_oleh` tidak diperiksa sama sekali) · pesan error baris 50: "Minta persetujuan atasan (PIN)" padahal tidak ada mekanisme PIN untuk diskon
- **Klaim yang dilanggar:** klaim #11 + kelas perbaikan AUD-3 K-2/A F-03 (bukti persetujuan) yang untuk `pembatalan` dijaga kupon sekali-pakai
- **Bukti:** probe `node alat/uji-sql.mjs /tmp/probe/p4_diskon_disetujui.sql` (kasir, diskon 2.000 — dalam batas) → **LULUS**:
  ```
  insert into diskon_transaksi (…, jenis='manual', nilai=2000, alasan='diskon dalam batas',
                                disetujui_oleh = <uuid owner>)
  → TERSIMPAN; disetujui_oleh = owner TANPA PIN/kupon/bukti apa pun
  ```
- **Skenario gagal:** kasir memberi diskon (dalam batasnya) lalu menstempel "disetujui owner" — rekam jejak menunjukkan owner menyetujui hal yang tidak pernah ia lihat; pemalsuan atribusi persetujuan pada tabel uang, permanen (baris tak bisa diubah/dihapus).
- **Dugaan penyebab:** kolom `disetujui_oleh` dibuat untuk jalur voucher/promo masa depan; jalur manualnya tidak pernah divalidasi, berbeda dengan `pembatalan` yang sudah memakai kupon PIN.
- **Cara membuktikan perbaikan:** nilai `disetujui_oleh` non-null wajib punya kupon PIN (pola `percobaan_pin` aksi='beri_diskon') atau ditolak; uji merah→hijau.
- **Status verifikasi:** TERVERIFIKASI

### [PR-05] Item pesanan: status `batal` bisa dipasang tanpa baris pembatalan; dapur bisa mengubah `qty` pesanan
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0009_pesanan.sql` (policy `pesanan_item_ubah` untuk kasir/pelayan + `pesanan_item_dapur` untuk dapur — keduanya tanpa batas kolom/pemicu) · tidak ada pemicu pada `pesanan_item` yang menjaga `status`/`qty`
- **Klaim yang dilanggar:** klaim #9 (bebas regresi) + klaim #11; Aturan Bisnis 7 (pembatalan wajib berjejak) tidak ditegakkan di tingkat item
- **Bukti:** probe `node alat/uji-sql.mjs /tmp/probe/p5_item_batal_qty.sql` → **LULUS**:
  ```
  (a) kasir: update pesanan_item set status='batal' where pesanan=<fixture>
      → TERSIMPAN; count(pembatalan untuk pesanan itu) = 0  (pembatalan item TANPA jejak)
  (b) dapur : update pesanan_item set qty=1 (dari 3)
      → TERSIMPAN; subtotal dihitung ulang peladen 39000 → 13000 (isi pesanan diubah dapur)
  ```
- **Skenario gagal:** baris pesanan "dihapus" diam-diam lewat status `batal` tanpa alasan/persetujuan; staf dapur mengubah jumlah jualan suatu pesanan — peran yang tidak berwenang menjual mengubah komposisi transaksi, dan angka item tidak lagi cocok dengan kelak `pesanan.subtotal` peladen.
- **Dugaan penyebab:** policy sengaja memberi dapur akses UPDATE untuk status masak (baru→dimasak→siap) tetapi Postgres RLS tidak bisa membatasi kolom — dan pemicu pembatas kolom belum dibuat.
- **Cara membuktikan perbaikan:** pemicu `pesanan_item`: `status='batal'` wajib disertai baris `pembatalan(pesanan_item_id)` pada transaksi yang sama; perubahan `qty` hanya untuk peran kasir/pelayan (bukan dapur); uji merah→hijau.
- **Status verifikasi:** TERVERIFIKASI

### [PR-06] Pembayaran tanpa `metode_id`: nama/jenis metode + referensi bebas dikarang klien
- **Tingkat:** K-3
- **Artefak:** `supabase/migrations/0012_penutup_celah_review.sql:712-721` (pemicu `picu_pembayaran_jujur` hanya menimpa `metode_nama_saat_itu`/`jenis_saat_itu` BILA `metode_id` diisi)
- **Klaim yang dilanggar:** klaim #11 + KEAMANAN.md §9.2 ("Non-tunai wajib referensi" — bisa disalahlabel)
- **Bukti:** probe `node alat/uji-sql.mjs /tmp/probe/p8_bayar_tanpa_metode_id.sql` (kasir) → **LULUS**:
  ```
  insert into pembayaran (…, metode_id = null, metode_nama_saat_itu='Transfer BCA (karangan)',
                          jenis_saat_itu='tunai', jumlah=62100, diterima=100000,
                          referensi='REF-KARANGAN', …)
  → TERSIMPAN persis seperti dikirim: label 'Transfer BCA (karangan)', jenis 'tunai', WITH referensi
  ```
- **Skenario gagal:** uang non-tunai dicatat sebagai "tunai" dengan `diterima` karangan — rekonsiliasi harian referensi vs mutasi QRIS/bank (fitur yang dijanjikan) kehilangan bahan; label metode pada catatan uang permanen bisa bohong.
- **Dugaan penyebab:** kolom salinan `*_saat_itu` dipercaya dari klien saat `metode_id` kosong, padahal harusnya wajib `metode_id` valid (atau nama/jenis ditolak bila tak cocok kamus resto).
- **Cara membuktikan perbaikan:** `metode_id` WAJIB (atau nama/jenis kiriman divalidasi ke `metode_bayar` resto); uji: pembayaran metode_id null → ditolak; merah→hijau.
- **Status verifikasi:** TERVERIFIKASI

### [PR-07] Angka basi di nama langkah CI: "Uji SQL penuh — … (28 berkas)" padahal nyata 31 berkas
- **Tingkat:** K-4
- **Artefak:** `.github/workflows/ci.yml` (baris nama langkah "Uji SQL penuh — RLS, isolasi resto & fungsi identitas (28 berkas)")
- **Klaim yang dilanggar:** klaim #12 (tidak ada klaim basi) — kelas cacat yang sama dengan putaran11 PR-04 ("21 berkas uji" basi) yang katanya kini dijaga
- **Bukti:** `ls supabase/tes/*.sql | wc -l` → **31**; `grep -n "28 berkas" .github/workflows/ci.yml` → nama langkah masih "(28 berkas)". Tidak ada pemeriksa yang menangkapnya: `alat/periksa-gerbang-ci.py` mencocokkan PERINTAH (`node alat/uji-sql.mjs$`), bukan angka pada nama; `periksa-panduan.py` menjaga angka di dokumen, bukan di CI. Gerbang tetap HIJAU padahal angkanya salah (dibuktikan: `periksa-gerbang-ci.py` LOLOS saat angka 28 basi).
- **Skenario gagal:** Lee/agent membaca nama langkah CI dan mengambil angka yang salah — persis kelas kebingungan "angka bukti basi" yang sudah dua kali diperbaiki (audit B-F-13, putaran11 PR-04).
- **Dugaan penyebab:** tiga uji baru 0013 ditambahkan tanpa menyegarkan nama langkah; penjaga angka tidak mencakup `ci.yml`.
- **Cara membuktikan perbaikan:** hapus angka dari nama langkah (mis. "Uji SQL penuh — seluruh berkas") atau perluas penjaga angka ke `ci.yml`; `python3 alat/periksa-gerbang-ci.py` tetap LOLOS dan `grep "(28 berkas)" .github/workflows/ci.yml` → tidak ada.
- **Status verifikasi:** TERVERIFIKASI

### Rencana pemulihan & sisa risiko (wajib jalur Merah, bahasa sederhana)

**Kalau perubahan ini ternyata salah / harus ditarik:** seluruh lapisan database hidup di berkas migrasi
`0001…0013`; belum ada satu pun migrasi yang dijalankan di Supabase produksi (akun Supabase belum dibuat —
`docs/TERTANGGUH.md` T-018), dan `main` belum pernah menerima PR ini. Pemulihannya sederhana: JANGAN MERGE;
kalau sudah terlanjur merge, revert commit merge (tidak ada data produksi yang perlu diselamatkan karena
belum ada pengguna nyata). Untuk temuan PR-01…PR-06: tutup dengan migrasi `0014` (aturan repo: migrasi lama
dibekukan) + uji baru; PR-01 paling dulu karena menyentuh persetujuan uang.

**Sisa risiko (jujur):** (1) Semua uji database berjalan di PGlite lokal dengan pgcrypto TIRUAN (SHA-256) —
kekuatan bcrypt asli belum pernah diuji (`T0-08` menunggu akun Supabase nyata). (2) Edge Function
`verifikasi_pin` tidak pernah dieksekusi sungguhan (tidak ada deployment test) dan tidak meneruskan
`p_pesanan_id`, jadi alur kupon 0012 hanya tercapai lewat RPC langsung. (3) Penjaga nominal uang terbukti
hidup, tetapi enam celah integritas/jejak di atas masih terbuka sampai ada migrasi penutup + uji. (4) Batas
PIN per perangkat masih memakai nama perangkat kiriman klien (L-06, T1-24 belum selesai).

## 5. Kalibrasi cacat tanaman

Ditemukan: 4 dari 4 · temuan palsu: 0

Bahan docs/uji/kalibrasi/pr-bahan-2026-09-17.diff diterapkan pada salinan terpisah (`cp -r` ke `/tmp/kal-repo`,
`git apply` OK — repo kerja tidak disentuh). Empat hunk, empat cacat, semuanya saya temukan dengan membaca diff
+ menjalankan uji; dua di antaranya saya buktikan TIDAK berdampak pada keadaan akhir karena migrasi berikutnya
menimpa objek yang sama (dicatat jujur, bukan disembunyikan):

| # | Cacat yang ditanam | Dampak nyata di keadaan akhir | Bukti |
|---|---|---|---|
| 1 | `0003` `cabang_saya()`: syarat `and p.aktif` dibuang dari join (akun nonaktif tetap dapat cabang) | **TIDAK AKTIF** — `0012` menulis ulang `cabang_saya()` seluruhnya (berbasis `sesi_cabang`, memeriksa `p.aktif` sendiri); tak ada uji yang merah untuk hunk ini | `node alat/uji-sql.mjs` pada salinan bermutasi: `cabang_sesi.sql` tetap LULUS; hanya 3 uji lain yang merah |
| 2 | `0004` policy `pengaturan_pilih`: `penyewa_id = penyewa_saya()` → `penyewa_id is not null` (bocor lintas resto) | **HIDUP** — seluruh pengaturan uang dua resto terbaca pegawai mana pun | `GAGAL supabase/tes/rls_pengguna.sql` ("owner pusat hanya melihat pengaturan restonya (dapat 2, harap 1)") + `GAGAL supabase/tes/rls_semua_tabel.sql` ("Tabel public.pengaturan membocorkan 1 baris milik resto lain") |
| 3 | `0005`: baris `revoke all on function public.boleh(text, uuid) from public;` dihapus (boleh 2-argumen tetap milik PUBLIC) | **HIDUP** — `anon` bisa memanggil `boleh()` | `GAGAL supabase/tes/izin.sql` ("anon tidak boleh memanggil boleh()") |
| 4 | `0012` cabang `promo`: `raise exception …` diganti `null;` (diskon promo 100% dibuka lagi) | **TIDAK AKTIF** — `0013` menulis ulang `picu_diskon_batas` seluruhnya; penjaga yang hidup adalah salinan 0013 | `node alat/uji-sql.mjs supabase/tes/diskon_cap.sql` pada salinan bermutasi → tetap **LULUS** (bukti hunk 0012 tertimpa) |

Keluaran penuh suite pada salinan bermutasi: `uji: 28 LULUS · 3 GAGAL` (`izin`, `rls_pengguna`,
`rls_semua_tabel`) · `HASIL: GAGAL` · exit 1. Catatan kalibrasi: karena 2 dari 4 cacat tertanam di kode yang
sudah tertimpa migrasi berikutnya, RV-3 putaran ini hanya menguji 2 cacat yang benar-benar bisa ditangkap
gerbang — kemampuan "ditangkap uji" hanya terbukti 2/4; dua sisanya hanya bisa ditemukan dengan membaca
(saya temukan lewat membaca diff, lihat bagian 8 #2).

## 6. Yang tidak bisa saya verifikasi

- Perilaku di Supabase PRODUKSI asli: semua uji database berjalan di PGlite (PostgreSQL WASM) dengan pgcrypto
  TIRUAN berbasis SHA-256 — kekuatan hash bcrypt asli, penerbitan klaim JWT `auth.jwt()`, dan perilaku
  PostgREST sungguhan tidak bisa saya uji (akun Supabase belum ada, `docs/TERTANGGUH.md` T-018).
- CI di infrastruktur GitHub Actions: saya menjalankan perintah-perintah yang SAMA secara lokal di salinan
  commit d1f11d7 (semua LOLOS, exit 0), tetapi tidak bisa memicu workflow GitHub sungguhan.
- Edge Function `verifikasi_pin/index.ts` tidak pernah saya eksekusi (tidak ada Deno/Supabase runtime di sini) —
  diperiksa dengan membaca + penjaga `alat/periksa-fungsi-pin.py` (LOLOS).
- 197 berkas jalur Hijau (aset desain `docs/desain/`, `prototipe/`, sebagian besar dokumen) tidak dibaca
  baris-per-baris — diperiksa lewat gerbang mesin yang saya jalankan (uji-kontras 166/166, periksa-halaman
  183/183, periksa-struktur, periksa-rahasia, periksa-bersih); itu batas kedalaman saya, bukan klaim bersih.
- Dampak runtime `simpan_pin` terhadap pengguna nyata (notifikasi/pemberitahuan di luar database) — tidak ada
  mekanisme notifikasi di repo; analisis PR-01 berdasar perilaku database saja.

## 7. Pernyataan tidak mengubah apa pun

Saya hanya-baca, bukan sesi penulis PR. SATU-SATUNYA berkas yang saya buat adalah laporan ini; tidak ada berkas
lain yang saya ubah. Semua pemeriksaan dijalankan pada salinan kerja di `/tmp` (hasil `cp -r` repo), mutasi
sengaja selalu dipulihkan (`git checkout --`) sebelum menutup langkah. Bukti: `git status --short` di repo sesi
menampilkan hanya berkas laporan ini:
```
$ git status --short
?? docs/uji/review-pr/LAPORAN_2026-09-18_pr-01-putaran13__01a0b1f3-2.md
```

## 8. Temuan di luar cakupan diff (WAJIB — boleh "tidak ada")

| # | Temuan | Mengapa di luar cakupan diff | Bukti | Saran ditindaklanjuti |
|---|---|---|---|---|
| 1 | Paket review yang TERCOMMIT pada `d1f11d7` masih menunjuk commit lama `57fe689` (115 commit · +52391), sedangkan paket yang Lee tempel menunjuk `d1f11d7` (117 · +52418) — mekanisme "paket wajib menunjuk tip" (L-01/L-12/L-13) kembali kecolongan dua commit | Ini keadaan proses/mekanisme paket, bukan cacat kode produk dalam diff | `git show d1f11d7:docs/uji/review-pr/PKT-2026-09-18-pr-01-putaran13.md \| grep "Commit yang direview"` → `57fe6899…`; tempelan Lee → `d1f11d7f…` | Sebelum Lee menilai merge, segarkan paket ke tip (atau tulis pengecualian eksplisit bila memang hanya berkas netral yang bergerak — seperti kasus ini, 6 berkas dokumen/paket) |
| 2 | Pembuat bahan kalibrasi (`--kalibrasi-pr-siapkan`) bisa menanam cacat pada salinan kode yang SUDAH TERTIMPA migrasi berikutnya — 2 dari 4 cacat bahan putaran ini (cabang_saya di 0003, promo di 0012) tidak berdampak dan tak mungkin memerahkan uji | Mekanisme RV-3 (alat review), bukan kode produk; kunci jawaban tidak saya cari | Bagian 5: `diskon_cap.sql` tetap LULUS pada salinan dengan hunk promo bermutasi; `cabang_sesi.sql` tetap LULUS dengan hunk 0003 | Generator memilih berkas migrasi EFEKTIF (yang definisinya masih berlaku di tip — pelajaran yang sama dengan perbaikan harness `uji-mutasi-0012.py`), supaya tiap cacat tanaman benar-benar bisa ditangkap gerbang |
| 3 | (dicatat, bukan cacat) Angka "28 berkas" di `REVIEW_PR_RIWAYAT.md` §2b/`TEMUAN_LUAR_CAKUPAN_REVIEW.md` L-11 adalah catatan sejarah yang benar pada zamannya — berbeda dengan [PR-07] yang menyangkut nama langkah CI HIDUP | Dokumen riwayat, bukan pernyataan keadaan kini | `grep -n "28 berkas" docs/uji/REVIEW_PR_RIWAYAT.md` | Tidak perlu tindakan; jangan dirapikan (angka kejujuran tidak boleh diubah) |