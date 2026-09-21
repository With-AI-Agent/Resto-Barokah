# Decisions Log

> Dokumen ini dicatat oleh AI agent SELAMA coding berjalan, bukan di awal.
> Setiap keputusan teknis nyata yang menyangkut Area Berisiko Tinggi
> (lihat TECH_SPEC.md) WAJIB dicatat di sini sebelum lanjut ke task lain.
> Sebelum menyentuh ulang area yang tercatat di sini, WAJIB baca dulu
> entri terkait — jangan menebak ulang dari kode.

## Cara menambah entri baru
Format:

### [Fase/Tanggal] Judul Singkat Keputusan
- **Area:** (misal: RLS/Auth, Role & Permission, Kalkulasi Keuangan)
- **Keputusan:** apa yang diputuskan/diimplementasikan, sekonkret mungkin
- **Alasan:** kenapa begini, bukan cara lain
- **File terkait:** file/folder yang mengimplementasikan ini
- **Implikasi:** hal lain yang HARUS ikut pola ini / tidak boleh menyimpang

---

### [Tahap 6/2026-09-16] Bentuk jawaban semua RPC mengikuti TECH_SPEC §5
- **Area:** Kontrak API & format error (menyentuh semua fitur uang/izin)
- **Keputusan:** semua RPC mengembalikan `{ berhasil: bool, kode: teks, pesan: teks, data: … }`; klien hanya menampilkan `pesan`, tidak menyusun pesan sendiri.
- **Alasan:** pemeriksaan silang menemukan `AGENT_OPERATING_GUIDE.md` sempat memakai bentuk lain (`ok/data/kode/pesan`) — dua bentuk berbeda akan membuat klien dan uji saling tidak cocok. `TECH_SPEC.md` adalah dokumen terkunci, jadi ia yang menjadi sumber kebenaran.
- **File terkait:** `docs/AGENT_OPERATING_GUIDE.md` §6, `docs/TECH_SPEC.md` §5, `docs/uji/LAPORAN_CROSS_CHECK_TAHAP6.md`
- **Implikasi:** dilarang membuat bentuk jawaban lain; kode error wajib memakai kelompok kode (PS-1xx, BY-2xx, VC-3xx, KS-4xx, PR-5xx, AK-6xx, UM-9xx) dan bahasa Indonesia siap tampil.

### [Tahap 6/2026-09-16] Nama RPC = kontrak; dipetakan ke tugas di ROADMAP
- **Area:** Kontrak API (semua fitur)
- **Keputusan:** nama fungsi resmi diambil persis dari `TECH_SPEC.md` §5 (**33 RPC** + fungsi `hitung_total`; angka 26 pada versi awal entri ini dikoreksi hasil review independen 2026-09-16); `ROADMAP.md` memuat tabel "Peta nama RPC resmi → tugas" supaya agent coding tidak menamai sendiri.
- **Alasan:** ROADMAP sebelumnya menjelaskan fungsinya tetapi tidak menyebut nama resminya → risiko menyimpang dari kontrak.
- **File terkait:** `docs/ROADMAP.md` (bagian Peta RPC), `docs/TECH_SPEC.md` §5
- **Implikasi:** kalau sebuah tugas butuh RPC baru yang belum ada di TECH_SPEC §5 → masuk kategori perubahan dokumen fondasi (Stop Condition) dan wajib disetujui pemilik lebih dulu.

### [Tahap 6/2026-09-16] Kebijakan privasi pelanggan = prasyarat sebelum mengumpulkan data (T-011)
- **Area:** Privasi pelanggan (ART-10)
- **Keputusan:** data pelanggan (nama, email/HP, persetujuan) baru boleh dikumpulkan setelah ada kebijakan privasi sederhana + kotak persetujuan di layar pendaftaran; tenggat: sebelum Fase 8 dimulai.
- **Alasan:** kewajiban etis & kepatuhan; juga bahan uji "pelanggan tahu datanya dipakai untuk apa".
- **File terkait:** `docs/TERTANGGUH.md` (T-011), tugas T8-07, T8-06
- **Implikasi:** T8-06/T8-07 tidak boleh ditandai selesai bila kotak persetujuan & kebijakan belum ada.

### [Tahap 6/2026-09-16] Keputusan yang ditutup dari buku tunggu (nilai awal)
- **Area:** Produk & konfigurasi (menyentuh Kalkulasi Keuangan: nilai pajak awal)
- **Keputusan:** nama kerja produk **"Sajian"**; tema bawaan **"Terang Bersih"**; **PB1 10% & service 5% & 1 shift** sebagai nilai awal; **tanpa domain khusus** dulu (Resend + alamat `*.workers.dev`); **aset `skills/` tetap dibawa** di repo. Semua ini dipilih atas usulan agent dan disetujui pemilik (2026-09-16).
- **Alasan:** semuanya bisa diubah **tanpa koding** (pengaturan aplikasi), sehingga tidak perlu menahan pekerjaan; hanya merek printer (T-002) dan daftar perangkat (T-003) yang benar-benar butuh data lapangan.
- **File terkait:** `docs/TERTANGGUH.md` (tabel Butir selesai), `prototipe/css/tokens.css` (tema), tugas T9-03 (pajak/service)
- **Implikasi:** perubahan nilai ini nanti TIDAK menghapus data lama — transaksi lama tetap memakai nilai yang tersimpan saat transaksi dibuat (`harga_saat_itu`).

### [Tahap 6/2026-09-16] `.gitignore` diperluas: rahasia dilarang masuk Git
- **Area:** Keamanan & kerahasiaan (kunci Supabase/Cloudflare/Resend)
- **Keputusan:** `.gitignore` di akar repo diperluas — `.env`, `.env.*`, `*.local`, `dist/`, `build/`, `.next/`, `.vercel/`, `.wrangler/`, `coverage/`, `*.log`, `*.tmp`, `.DS_Store` — di samping aturan lama (`__pycache__/`, `*.pyc`, `node_modules`).
- **Alasan:** sebelumnya berkas rahasia tidak di-ignore, jadi satu `git add -A` yang lengah bisa meng-commit kunci layanan. Ditemukan oleh review independen (temuan W10-01) dan diverifikasi sendiri: tidak ada berkas terlacak yang cocok pola baru.
- **File terkait:** `.gitignore`, tugas T0-05 (`.env.example`), T0-08 (kunci klien Supabase)
- **Implikasi:** rahasia disimpan di berkas yang di-ignore (lokal) dan di secrets Cloudflare (produksi); `.env.example` yang ikut repo hanya berisi nama variabel tanpa nilai.

### [Tahap 6/2026-09-16] Pemeriksa rujukan diperluas ke seluruh Markdown di docs/
- **Area:** Mutu dokumen & gerbang otomatis (ART-10 tidak langsung, tapi menjaga janji dokumen)
- **Keputusan:** `_sistem/validate_system.py` (`check_no_dangling_internal_refs`) memindai **seluruh berkas `.md` di dalam `docs/`**, bukan hanya daftar dokumen tetap; path yang disebut di baris `**File:**` ROADMAP (artefak rencana yang memang dibuat nanti) dan 2 berkas yang menunggu dibuat sesi review dikecualikan **secara tercatat** di dalam skrip; pola tanggal (`YYYY`) tidak dianggap path.
- **Alasan:** temuan review independen W3-03/W6-01; kelas cacat "rujukan menggantung di dokumen baru" sudah pernah lolos gerbang.
- **File terkait:** `_sistem/validate_system.py`, `ACCEPTANCE_TESTS.md` (baris log), `docs/TECH_SPEC.md`, `docs/teknis/DISKUSI_TAHAP4_ATURAN_KERJA.md`
- **Implikasi:** dokumen baru di `docs/` otomatis ikut dijaga; bila sebuah dokumen menyebut berkas yang belum ada, pengecualiannya harus ditulis di skrip (terlihat di riwayat Git), bukan disembunyikan dengan menghapus backtick tanpa alasan.

### [Review independen/2026-09-16] Cadangan & pemulihan data jadi tugas sendiri (bukan hanya butir DoD)
- **Area:** Data pelanggan & privasi (ART-10) + ketahanan data
- **Keputusan:** cadangan `pg_dump` mingguan otomatis + uji pemulihan dijadikan tugas tersendiri **T10-10** di Fase 10, bukan hanya satu baris DoD di T11-10 (tugas penutup). Berkas cadangan wajib terenkripsi, disimpan di luar basis data, masa simpan dibatasi, dan **tidak pernah masuk repo**.
- **Alasan:** paket gratis Supabase tidak menyediakan cadangan otomatis (`TECH_SPEC.md` §8 butir 9). Sebelumnya satu-satunya penjaga adalah DoD tugas terakhir G1 — artinya sepanjang Fase 0–10 data kedai nyata tidak punya cadangan sama sekali, padahal pilot sudah bisa jalan sebelum F11 selesai.
- **File terkait:** `docs/ROADMAP.md` (T10-10, T11-10), `docs/TECH_SPEC.md` §8, `alat/cadangan.sh` (dibuat nanti), `docs/teknis/PEMULIHAN.md` (dibuat nanti)
- **Implikasi:** berkas cadangan berisi data pelanggan → tunduk pada kebijakan privasi (T-011). Dilarang menaruh berkas cadangan atau kuncinya di Git. Pernyataan "siap pakai harian" (T11-10) tidak boleh ditandatangani sebelum pemulihan benar-benar pernah diuji.

### [Review independen/2026-09-16] Perubahan pengaturan bersamaan wajib ditolak di peladen (T10-11)
- **Area:** Kalkulasi Keuangan (ART-3) — pengaturan memuat PB1, service, dan aturan pembulatan
- **Keputusan:** `simpan_pengaturan` / `simpan_menu` memakai **versi pengaturan (stempel waktu)** yang sudah dijanjikan `TECH_SPEC.md` §5 sebagai penjaga: simpanan yang membawa versi lama **ditolak** dengan kode & pesan Indonesia, bukan ditimpa diam-diam.
- **Alasan:** TECH_SPEC §5 sudah menjanjikan keluaran "versi pengaturan (stempel waktu)", tetapi tidak ada satu pun tugas yang memakainya. Tanpa itu, dua admin yang mengubah pajak/menu bersamaan bisa membuat perubahan satunya hilang tanpa jejak — dan yang hilang bisa berupa nilai pajak.
- **File terkait:** `docs/ROADMAP.md` (T10-11), `docs/TECH_SPEC.md` §5, `supabase/migrations/0059_versi_pengaturan.sql` (dibuat nanti)
- **Implikasi:** semua RPC penyimpan pengaturan wajib menerima & memeriksa versi; klien wajib menampilkan pesan "data sudah diubah orang lain" tanpa membuang isian pengguna.

### [Review independen/2026-09-16] Tempat penyimpanan berkas cadangan & penutup shift pegawai yang berhenti
- **Area:** Data pelanggan & privasi (ART-10) · Role & Permission (ART-2)
- **Keputusan:** (1) **T-012** — berkas cadangan mingguan berbentuk **artefak terenkripsi dari GitHub Actions** pada repo privat (masa simpan 90 hari), dan pemilik mengunduh salinannya sebulan sekali ke penyimpanan miliknya sendiri; tidak ada salinan cadangan di tempat publik dan berkas cadangan tidak pernah masuk Git. (2) **T-013** — penutup shift kasir yang ditinggal pegawai berhenti adalah **Admin Cabang**, dan bila yang berhenti adalah Admin Cabang sendiri → **Owner Pusat**.
- **Alasan:** paket gratis tidak punya cadangan otomatis, jadi tempat penyimpanan harus diputuskan sebelum T10-10 selesai; dan shift yang dibiarkan terbuka membuat laporan hari itu tidak bisa ditutup. Keduanya bisa diubah tanpa koding.
- **File terkait:** `docs/TERTANGGUH.md` (T-012, T-013 pindah ke tabel Butir selesai), `docs/ROADMAP.md` (T10-10, T10-12)
- **Implikasi:** berkas cadangan berisi data pelanggan → wajib terenkripsi, akses terbatas, masa simpan dibatasi. Penutupan shift oleh atasan wajib tercatat di `catatan_audit` (bukan menghapus jejak pegawai).

### [Fase 0/2026-09-16] Rangka kerja aplikasi: susunan berkas gaya, cara memilih tema, dan cara memeriksanya
- **Area:** Fondasi kode (menyentuh semua layar; belum menyentuh uang/izin)
- **Keputusan:**
  1. Token rancangan v3 dipindah **apa adanya** ke `aplikasi/src/gaya/token/tema.css` (berisi token + kelas rancangan yang sudah disetujui pemilik: `btn`, `card`, `chip`, `table`, `segmen`, dsb.). Berkas itu **tidak boleh diubah** selama Fase 0 — pemeriksa membandingkannya byte-per-byte dengan `prototipe/css/tokens.css`.
  2. Hal tingkat aplikasi yang belum diatur token masuk `aplikasi/src/gaya/token/dasar.css`; tata letak khusus aplikasi masuk `aplikasi/src/gaya/komponen.css`. Keduanya **dilarang memuat warna mentah** (hanya `var(--...)`).
  3. Pemilihan tema & kerapatan lewat `aplikasi/src/lib/tema.ts` (daftar tema/kerapatan, pasang atribut ke elemen akar, simpan di `localStorage`) + `aplikasi/src/hook/useTema.ts`. Warna bilah peramban (`theme-color`) diisi dari token `--accent` saat tema dipasang.
  4. Pemeriksa baru `aplikasi/alat/periksa-struktur.py`: pohon folder dibaca langsung dari `docs/TECH_SPEC.md` §3, token wajib identik dengan prototipe, semua rujukan huruf wajib ada di disk, tanpa warna mentah di luar token, dan kode tema di aplikasi wajib sama dengan kode tema di token.
  5. `typecheck` memakai `tsc -b --noEmit` (mode proyek), bukan `tsc --noEmit`.
- **Alasan:** (1) DoD T0-03 berbunyi "pindahkan berkas apa adanya, jangan ketik ulang" — membandingkan byte adalah cara membuktikannya; (2) warna mentah di luar token membuat penggantian tema rusak sebagian; (3) `tsc --noEmit` pada `tsconfig.json` yang hanya berisi referensi **memeriksa nol berkas** — dibuktikan lewat uji mutasi (berkas bersalah tetap lolos) sehingga tampak hijau padahal tidak menjaga apa pun.
- **File terkait:** `aplikasi/src/gaya/token/tema.css`, `aplikasi/src/gaya/token/dasar.css`, `aplikasi/src/gaya/komponen.css`, `aplikasi/src/lib/tema.ts`, `aplikasi/src/hook/useTema.ts`, `aplikasi/alat/periksa-struktur.py`, `aplikasi/tsconfig*.json`
- **Implikasi:** menyentuh `tema.css` (mis. menyesuaikan tema) berarti mengubah kesepakatan desain → wajib lulus pemeriksa kontras + catatan di sini. Komponen baru wajib memakai kelas rancangan atau token; warna mentah akan menyalakan pemeriksa.

### [Fase 0/2026-09-16] Bentuk komponen dasar, penanganan rahasia, dan gerbang CI
- **Area:** Fondasi kode (dipakai semua layar; belum menyentuh uang/izin)
- **Keputusan:**
  1. **Satu komponen satu berkas** di `aplikasi/src/komponen/` (10 berkas) dan semuanya memakai kelas rancangan v3 (`btn`, `card`, `chip`, `table`, `input`, `segmen`) — dilarang menulis warna mentah; semua nilai dari token.
  2. **Setiap layar wajib punya tiga keadaan**: kosong, memuat, gagal. Komponennya sudah disiapkan (`KeadaanKosong`, `KeadaanMemuat`, `KeadaanGagal`). `Tabel` otomatis menampilkan keadaan kosong kalau tidak ada baris — jadi tidak ada tabel kosong tanpa penjelasan.
  3. **Lapis mengambang** (`Lapis`) memakai `role="dialog"` + `aria-modal`, menutup dengan Esc/klik latar, dan mengunci guliran halaman belakang. **Toast** memakai `role="status"` + `aria-live="polite"`, **KeadaanGagal** memakai `role="alert"`.
  4. **Rahasia:** hanya `VITE_SUPABASE_URL` & `VITE_SUPABASE_ANON_KEY` boleh dibaca aplikasi; variabel rahasia **tidak boleh berawalan `VITE_`** (kalau berawalan, ikut terbundel ke peramban). `.env` diabaikan Git, `.env.example` ikut Git. `src/lib/env.ts` tidak meledak saat nilai belum diisi — layar yang membutuhkannya menampilkan `KeadaanGagal` dengan pesan bahasa Indonesia.
  5. **Gerbang CI = sumber kebenaran.** Pemeriksaan yang sama wajib bisa dijalankan di komputer lewat `bash aplikasi/alat/periksa-semua.sh`. Pemeriksa Python ikut jalan di CI (bukan hanya di komputer agent).
- **Alasan:** (1) keseragaman tampilan & satu tempat perbaikan; (2) syarat pemilik “tidak ada halaman kosong tanpa penjelasan” dan pengalaman pegawai di lapangan (jaringan kedai tidak selalu bagus); (3) aksesibilitas + keselamatan kerja (toast tidak boleh merebut fokus kasir); (4) kebocoran kunci adalah risiko Termahal yang bisa dicegah gratis; (5) CI pertama menemukan **dua cacat nyata** yang tidak terlihat di komputer (folder kosong tidak ikut Git, berkas Markdown belum dirapikan) — jadi “hijau di komputer” tidak boleh dipercaya tanpa CI.
- **File terkait:** `aplikasi/src/komponen/*.tsx`, `aplikasi/src/gaya/komponen.css`, `aplikasi/src/lib/env.ts`, `aplikasi/.env.example`, `.github/workflows/ci.yml`, `aplikasi/alat/periksa-komponen-env.py`, `aplikasi/alat/periksa-semua.sh`
- **Implikasi:** layar baru wajib memakai komponen ini (bukan menulis ulang gaya sendiri) dan wajib menyiapkan tiga keadaan. Nilai rahasia baru: tambahkan di tabel `TECH_SPEC.md` §6 dulu, lalu di `.env.example` sebagai komentar (tanpa awalan `VITE_`). Setiap kirim kode wajib menjalankan `periksa-semua.sh`.

### [Fase 0/2026-09-16] Uji wajib sejak awal + prosedur pemulihan ruang kerja
- **Area:** Fondasi kerja (mutu kode & keselamatan pekerjaan; belum menyentuh uang/izin)
- **Keputusan:**
  1. **Gerbang TDD aktif sekarang:** setiap berkas logika di `aplikasi/src/lib/*` dan `aplikasi/src/hook/*` wajib punya berkas ujinya sendiri (`*.test.ts(x)`). Dijaga alat `aplikasi/alat/periksa-uji.py` yang ikut berjalan di CI — jadi kode uang/izin mulai Fase 1 tidak bisa masuk tanpa uji.
  2. **Kerangka uji disiapkan untuk pemakaian nyata:** jsdom + `@testing-library/react` terpasang; uji boleh menandai berkasnya `// @vitest-environment jsdom` (lingkungan bawaan tetap `node` supaya cepat).
  3. **Prosedur pemulihan ruang kerja** (dicatat di `docs/AGENT_OPERATING_GUIDE.md` §0): pratinjau mati → `bash aplikasi/alat/pratinjau.sh`; riwayat Git lokal mundur → `bash alat/pulihkan-git.sh` (periksa) lalu `--perbaiki`. Pemulih **menolak** berjalan kalau masih ada perubahan belum di-commit, dan **tidak pernah** memakai `--hard`/`--force`.
  4. **Larangan menulis ulang berkas dari ingatan** saat pemulihan — sumber kebenaran hanya GitHub + dokumen di repo.
- **Alasan:** (1) risiko “uji hanya formalitas” sudah tercatat di ROADMAP T0-10; janji saja tidak cukup, jadi dibuat gerbang yang benar-benar menolak; (2) pada 2026-09-16 ruang kerja restart: `node_modules` hilang (pratinjau mati) dan salinan Git lokal mundur ke `main` — ditangani tanpa kehilangan data, tetapi prosedurnya harus tertulis supaya sesi/model berikutnya tidak menebak; (3) menulis ulang dari ingatan berisiko menghasilkan kode yang mirip tapi tidak identik dan menghapus perbaikan sebelumnya.
- **File terkait:** `aplikasi/alat/periksa-uji.py`, `aplikasi/vitest.config.ts`, `aplikasi/src/lib/env.test.ts`, `aplikasi/src/hook/useTema.test.tsx`, `aplikasi/src/hook/useJam.test.tsx`, `alat/pulihkan-git.sh`, `aplikasi/alat/pratinjau.sh`, `docs/AGENT_OPERATING_GUIDE.md` §0
- **Implikasi:** berkas logika baru tanpa uji = kiriman kode ditolak CI. Saat memulihkan ruang kerja: periksa dulu (`git status`), jangan pernah `--hard`/`--force`, dan setelah pulih jalankan `bash aplikasi/alat/periksa-semua.sh` lalu commit + push.

### [Fase 1/2026-09-16] Fase 1 dimulai lebih dulu tanpa akun Supabase + uji SQL lokal pada PostgreSQL asli
- **Area:** Cara kerja & RLS/Auth (ART-1) — menyentuh semua migrasi berikutnya
- **Keputusan:**
  1. **Fase 1 dikerjakan sekarang tanpa menunggu akun.** T0-00 (pemilik membuat akun) ditunda atas permintaan pemilik; T0-08/T0-09 tetap menunggu akun, tetapi seluruh migrasi, kebijakan RLS, peran, izin, dan fungsi uang dapat dikerjakan dan **diuji sungguhan** lebih dulu.
  2. **Cara mengujinya tanpa akun:** PostgreSQL asli dijalankan di dalam Node (pustaka PGlite, gratis, tanpa server) melalui alat baru `alat/uji-sql.mjs`. Alat ini meniru Supabase: peran `anon` / `authenticated` / `service_role`, skema `auth` lengkap dengan `auth.users`, `auth.uid()`, `auth.jwt()`, dan alat bantu uji `uji.klaim()` / `uji.harap()` / `uji.sama()` / `uji.harap_gagal()`.
  3. **Setiap berkas `supabase/tes/*.sql` dijalankan dalam transaksinya sendiri yang WAJIB dibatalkan (rollback)** — jadi urutan uji tidak saling mencemari dan data uji tidak pernah tertinggal. Data uji dibuat ulang setiap kali jalan dari `alat/sql/data-uji.sql` (2 resto × 3 cabang × 7 akun).
  4. **Uji SQL masuk CI** (`npm ci --prefix alat` lalu `node alat/uji-sql.mjs --daftar`) dan masuk `aplikasi/alat/periksa-semua.sh`, sehingga "lulus di komputer" dan "lulus di CI" memakai perintah yang sama.
- **Alasan:** (a) pemilik sedang sibuk dan minta maraton tetap jalan; (b) Fase 1 adalah fase **paling berisiko** (isolasi data antar-resto, izin, uang) — menundanya sampai akun jadi berarti 22 tugas berisiko menumpuk di akhir; (c) yang sebenarnya dibutuhkan untuk menguji Fase 1 adalah **PostgreSQL asli**, bukan layanan Supabase — dan PostgreSQL asli bisa dijalankan di dalam Node tanpa akun; (d) "hijau di komputer pernah menipu" (folder kosong & Markdown), jadi bahaya terbesar bukan menunda, melainkan **menguji dengan logika tiruan** — karena itu yang dipakai PostgreSQL asli, dan hasilnya dijalankan ulang di Supabase begitu akun jadi; (e) alat uji buatan sendiri harus dibuktikan bisa MERAH, bukan hanya hijau.
- **File terkait:** `alat/uji-sql.mjs`, `alat/package.json`, `alat/sql/data-uji.sql`, `supabase/migrations/0001..0004`, `supabase/tes/*.sql`, `.github/workflows/ci.yml`, `aplikasi/alat/periksa-semua.sh`, `supabase/README.md`, `docs/ROADMAP.md` (T1-01…T1-04)
- **Implikasi:** 1) Berkas uji baru **wajib** berbentuk uji perilaku (nyatakan harapan, bukan hanya "perintah berhasil"), supaya bisa gagal saat kode dirusak. 2) Kalau nanti di Supabase nyata ada perbedaan hasil, yang diperbaiki adalah **kode/migrasinya**, bukan ujinya dilemahkan. 3) `alat/node_modules` diabaikan Git; kunci versi (`alat/package-lock.json`) ikut Git. 4) T0-08 & T0-09 tetap menjadi syarat penutup Fase 0 — Fase 0 **belum** boleh dinyatakan selesai.

### [Fase 1/2026-09-16] Pola RLS seragam & satu sumber identitas untuk semua tabel (T1-01…T1-04)
- **Area:** RLS/Auth (ART-1) & Role/Permission (ART-2) — menyentuh semua tabel & policy Fase 1 ke atas
- **Keputusan:**
  1. **RLS aktif sejak tabel pertama dibuat; policy ditulis di migrasi terpisah.** `0001`/`0002` membuat tabel dengan RLS aktif **tanpa policy** (artinya: tidak ada yang bisa membaca = tolak-dulu), lalu `0004` menuliskan policy resminya. Jeda antara keduanya tidak bisa membocorkan data.
  2. **Satu sumber identitas tunggal** (`0003`): `penyewa_saya()` · `peran_saya()` · `cabang_saya()` · `cabang_ids_saya()` · `sepenyewa(uuid)`. Semua `SECURITY DEFINER` + `search_path` dikunci + hak jalan **hanya** `authenticated` & `service_role` (`anon` ditolak). **Semua policy dilarang menulis subquery langsung** ke tabel lain — wajib lewat fungsi ini, supaya tidak ada RLS yang berputar/berulang.
  3. **Dua tingkat peran:** `pengguna.peran` = peran se-resto (`owner_pusat`, `admin_cabang`, `kasir`, `pelayan`, `dapur`) atau `pemilik_platform` (yang berdiri di luar semua resto); `pengguna_cabang.peran` = peran **per cabang** sehingga pegawai bisa merangkap beberapa cabang dengan peran berbeda.
  4. **Cabang aktif diambil dari klaim token, tetapi selalu diverifikasi ulang** ke tabel `pengguna_cabang` — klaim palsu atau kedaluwarsa tidak memberi akses (ART-1: jangan percaya klien).
  5. **Izin tidak boleh diubah lewat tabel langsung** (hanya lewat RPC berizin di T1-05 dst.); **akun nonaktif** langsung kehilangan seluruh identitas (penyewa, peran, cabang).
- **Alasan:** (1) kesalahan policy = kebocoran data antar-resto, satu-satunya risiko yang bisa mematikan kepercayaan pemilik kedai; satu pola + satu sumber identitas membuat pemeriksaan bisa otomatis dan tidak bergantung pada ketelitian penulis kode; (2) `SECURITY DEFINER` tanpa `search_path` terkunci adalah celah klasik, dan menjalankan fungsi berhak lewat peran `anon` memperluas serangan tanpa manfaat; (3) `pengguna_cabang` dibutuhkan nyata karena kasir sering membantu cabang lain, tetapi laporan tetap harus utuh per cabang; (4) akun pegawai yang berhenti harus langsung kehilangan akses tanpa menunggu penghapusan baris.
- **File terkait:** `supabase/migrations/0001_penyewa_cabang.sql`, `0002_pengguna_izin_pengaturan.sql`, `0003_helper_identitas.sql`, `0004_pola_rls.sql`, `supabase/tes/helper.sql`, `rls_penyewa.sql`, `rls_pengguna.sql`, `rls_semua_tabel.sql`
- **Implikasi:** 1) Tabel baru **wajib** punya RLS + policy yang menyebut `penyewa_saya()` bila punya kolom `penyewa_id` — kalau tidak, CI merah (uji katalog di `supabase/tes/rls_semua_tabel.sql` membaca katalog PostgreSQL, jadi tabel yang lupa dikunci ketahuan tanpa perlu diuji manual). 2) Menambah peran/izin baru berarti menambah di `0003`/`0005` + uji, bukan menyebar di banyak tempat. 3) Uji 4 berkas Fase 1 ini **terbukti bisa MERAH**: 3 uji mutasi (RLS dimatikan · policy dibuka lebar · cacat akun nonaktif) semuanya menyalakan GAGAL, lalu LOLOS setelah dipulihkan. 4) **Ditemukan & diperbaiki dalam batch ini:** rancangan awal `cabang_saya()`/`cabang_ids_saya()` masih memberi cabang kepada pegawai yang sudah dinonaktifkan — ditangkap uji `helper.sql`, diperbaiki sebelum dikirim.

### [Fase 1/2026-09-16] Gerbang izin tunggal `boleh()`: satu tempat memutuskan, bukan tersebar di banyak layar (T1-05)
- **Area:** Role & Permission (ART-2) — menyentuh semua RPC & layar yang menyentuh uang, void, laporan, dan pegawai
- **Keputusan:**
  1. **Izin disimpan di dua tingkat.** `izin` (per pegawai, centang khusus) **menang** atas `izin_peran` (bawaan per peran per resto). Bila pegawai tidak punya centang khusus dan perannya tidak punya bawaan → **TOLAK**. Resto baru otomatis mendapat izin bawaan lewat pemicu, jadi tidak ada kondisi "semua tertutup".
  2. **Satu gerbang untuk semua tindakan:** `boleh(aksi)` · `boleh(aksi, nominal)` · `boleh(aksi, nominal, persen)` — semuanya membaca satu fungsi perhitungan `izin_efektif(aksi, cabang)`. Tidak ada RPC atau layar yang boleh menyimpulkan izin sendiri dari peran.
  3. **Izin mengikuti peran DI CABANG itu**, bukan hanya peran se-resto: pegawai merangkap cabang bisa berperan Kasir di satu cabang dan Dapur di cabang lain, dan gerbangnya menilai sesuai cabang yang sedang dipakai. **Cabang yang bukan milik pengguna = TOLAK** (tidak diam-diam jatuh ke peran se-resto).
  4. **Batas uang menempel pada izin:** `batas_nominal` dan `batas_persen` disimpan bersama izin dan diperiksa oleh gerbang — jadi aturan "diskon maksimal 25.000 untuk kasir" tidak perlu ditulis ulang di layar kasir.
  5. **Bawaan per peran yang dipasang:** owner pusat boleh semuanya · admin cabang boleh operasi harian (diskon sampai 50.000 / 10 persen) tetapi **tidak** boleh mengubah pengaturan resto · kasir boleh jual + diskon kecil (25.000 / 5 persen) + batal sebelum dapur + tutup kas · pelayan hanya memakai voucher · dapur hanya stok.
  6. **Kamus 10 kode izin** (`izin_kode`) menjadi daftar resmi; kode izin baru = migrasi baru + baris kamus + uji.
- **Alasan:** (1) izin yang tersebar di banyak tempat adalah cara paling umum uang bocor tanpa jejak — dengan satu gerbang, kebijakan bisa diuji otomatis dan berubah satu tempat; (2) deny by default berarti pegawai baru tidak bisa apa-apa sampai dicentang, jauh lebih aman daripada "boleh dulu, dicabut kemudian"; (3) kasir yang membantu cabang lain adalah kenyataan lapangan, jadi izin per cabang bukan kemewahan; (4) batas diskon harus ditegakkan di tempat yang tidak bisa dilewati aplikasi, bukan di layar yang bisa diakali.
- **File terkait:** `supabase/migrations/0005_izin_berjenjang.sql`, `supabase/tes/izin.sql`
- **Implikasi:** 1) Setiap RPC baru **wajib** memanggil `boleh(...)` sebagai baris pertamanya, bukan memeriksa `peran` sendiri — ini akan diperiksa pada tugas RPC (T1-15 dst.). 2) Perubahan izin wajib menulis `catatan_audit` (ART-2) — tabel & pemicunya menyusul pada migrasi `catatan_audit` (T1-11/T1-13); sampai itu ada, perubahan izin hanya bisa dilakukan owner pusat dan jejaknya tersimpan di kolom `diubah_oleh`/`diubah_pada`. 3) Uji `izin.sql` **terbukti bisa MERAH lewat 4 uji mutasi**, dan mutasi keempat mengungkap uji yang lemah → uji diperkuat, bukan gerbangnya dilonggarkan. 4) Menambah izin baru berarti menambah kode + bawaan per peran + uji matriks, bukan menulis kondisi `if` baru di layar.

### [Fase 1/2026-09-16] PIN pegawai: hash di database, batas percobaan dua lapis, dan Edge Function yang tipis (T1-06)
- **Area:** Role & Permission (ART-2) + keamanan data pegawai
- **Keputusan:**
  1. **PIN hanya disimpan sebagai hash bcrypt** (`crypt(pin, gen_salt('bf', 10))` dari pgcrypto). Sebagai pengaman kedua, kolom `pin_hash` diberi **batas (CHECK)** yang menolak nilai bukan-hash — jadi kalaupun ada kode yang keliru menyimpan PIN mentah, **database** yang menolaknya. Tidak ada fungsi apa pun yang mengembalikan hash.
  2. **Pembatasan percobaan dua lapis:** 5 kali salah **per akun** dan 12 kali salah **per perangkat** dalam 15 menit. Lapis perangkat penting di resto: satu tablet dipakai bergantian, jadi menebak dari satu HP harus mentok walau targetnya berganti-ganti akun.
  3. **Semua percobaan dicatat** di `percobaan_pin` (berhasil/gagal + perangkat). Percobaan yang **ditolak karena terkunci ikut dihitung**, supaya mengetuk terus-menerus tidak memperpendek masa tunggu.
  4. **PIN benar belum cukup:** bila dipakai untuk menyetujui aksi (`void_sesudah_dapur`, diskon di atas batas, dsb.), izin **pemilik PIN** diperiksa lewat `boleh_untuk()` — jadi PIN pegawai dapur tidak bisa dipakai menyetujui void hanya karena PIN-nya benar.
  5. **Ganti PIN sendiri wajib PIN lama**; mengganti PIN pegawai lain wajib izin `kelola_pegawai` dan hanya dalam resto yang sama. `ganti_pin` (M12) memanggil `simpan_pin` — satu isi, bukan dua.
  6. **Edge Function `verifikasi_pin` sengaja tipis:** hanya POST, meneruskan ke RPC dengan **token pemanggil + kunci publik** (bukan `service_role`, supaya RLS tidak dilewati), dan **tidak memakai `console.*` sama sekali** sehingga PIN tidak mungkin masuk log. Dijaga pemeriksa `alat/periksa-fungsi-pin.py` di CI.
  7. **Rumus izin tetap satu:** parameterisasi `izin_efektif_untuk(pengguna, aksi, cabang)` ditambahkan, dan `izin_efektif` (0005) kini menjadi pembungkusnya — bukan rumus kedua.
- **Alasan:** (1) PIN adalah kunci tindakan uang (void, diskon, voucher); kebocoran hash jauh lebih ringan daripada kebocoran PIN, dan penolakan di tingkat tabel membuat kesalahan kode tidak berakibat fatal; (2) restoran nyata memakai satu tablet bersama — tanpa batas per perangkat, penebak bisa berputar akun; (3) mencatat penolakan menjaga bukti dan mencegah serangan "tunggu sampai jendela habis"; (4) PIN atasan yang bisa dipakai untuk apa saja akan membuat izin berjenjang tidak berarti.
- **File terkait:** `supabase/migrations/0006_pin.sql`, `supabase/functions/verifikasi_pin/index.ts`, `supabase/tes/pin.sql`, `alat/periksa-fungsi-pin.py`, `.github/workflows/ci.yml`
- **Implikasi:** 1) **Batas yang jujur:** Deno belum tersedia di ruang kerja ini, jadi uji **runtime** Edge Function (permintaan HTTP sungguhan) menunggu akun Supabase di **T0-08**; yang terbukti sekarang adalah seluruh logika PIN di database (PostgreSQL asli) + penjagaan statis berkas Edge Function (9 pemeriksaan, terbukti bisa merah). Ini juga berlaku untuk Edge Function berikutnya (email, cetak): **logika wajib ada di database**, fungsi Edge hanya pintu tipis. 2) Di Supabase, bcrypt asli (pgcrypto) yang dipakai; di uji lokal dipakai **tiruan berlabel** karena PGlite tidak memuat pgcrypto — yang diuji perilakunya, bukan kekuatan algoritmanya, dan uji yang sama akan dijalankan ulang di Supabase. 3) Setiap RPC yang butuh persetujuan PIN wajib memanggil `verifikasi_pin(..., p_aksi => ...)`, bukan memeriksa PIN sendiri. 4) PIN tidak pernah boleh muncul di log aplikasi mana pun — aturan ini dijaga pemeriksa statis.

### [Fase 1/2026-09-16] Katalog & stok: harga per cabang satu rumus, siapa boleh apa, dan stok yang tak bisa menyimpang (T1-07)
- **Area:** Katalog/menu (M2, M9, M11), stok, dan pembagian hak
- **Keputusan:**
  1. **Harga per cabang lewat SATU fungsi** `harga_berlaku(menu, cabang)`: harga khusus cabang bila ada, kalau tidak harga pusat (`menu_cabang.harga` null = ikut pusat). Layar kasir, katalog pelanggan, dan perhitungan uang wajib memakai fungsi ini — tidak ada rumus harga kedua.
  2. **Siapa yang boleh mengubah katalog:** owner pusat & admin cabang (daftar izin resmi tidak memuat kode “kelola menu”, jadi ini ditetapkan per peran — dicatat di sini supaya tidak jadi kebiasaan diam-diam). Kasir/pelayan/dapur hanya bisa **melihat**.
  3. **Penanda “habis” adalah tugas harian**, jadi pegawai ber-izin `ubah_stok` (dapur/kasir) boleh menandainya **di cabangnya sendiri**; **menetapkan/mengubah harga tetap milik owner pusat & admin cabang**, dijaga pemicu di database (berlaku saat menyisipkan maupun mengubah baris) — bukan hanya disembunyikan di layar.
  4. **`cabang_pantau_saya()` (baru):** pemegang hak atas satu cabang = pegawai yang bertugas di situ, **atau owner pusat untuk semua cabang restonya**. Tanpa aturan ini, owner pusat (yang memang tidak bertugas di kasir) tidak melihat harga cabang mana pun — cacat ini **ditemukan uji** sebelum dikirim.
  5. **Stok hanya berubah lewat buku besar.** `stok_pergerakan` bersifat hanya-bertambah (hak ubah/hapus tidak diberikan); setiap baris **menjumlahkan sendiri** ke `stok_bahan.jumlah`; menulis `jumlah` langsung **ditolak** pemicu. `jumlah` pada buku besar selalu **PERUBAHAN (delta)**: masuk +, keluar −, opname/koreksi boleh ±, dan `koreksi` wajib beralasan.
  6. **Tambahan kolom `penyewa_id` pada `menu_tambahan` & `stok_pergerakan`** (di luar daftar kolom TECH_SPEC §4.2): tanpa itu, baris “tambahan berlaku untuk semua menu” dan baris buku besar stok tidak bisa dipisahkan per resto sesuai ART-1. Pada `stok_pergerakan` kolom itu **diisi otomatis dari bahannya**, dan nilai yang bertentangan **ditolak tegas** (bukan diam-diam dibetulkan).
  7. **Pemicu menjaga konsistensi antar tabel:** tambahan↔menu harus satu resto; harga cabang hanya untuk cabang & menu satu resto.
- **Alasan:** (1) harga yang dihitung di dua tempat adalah cara paling halus untuk kehilangan uang; (2) katalog adalah wajah kedai — salah harga menimbulkan keributan di kasir, jadi haknya sengaja dipegang owner/admin; (3) “habis” berubah puluhan kali sehari dan harus bisa dilakukan siapa pun yang jaga, tanpa membuka pintu pengubahan harga; (4) stok yang boleh ditulis langsung akan selalu berbeda dengan catatannya — dan pada saat itu laporan laba/harga pokok tidak bisa dipercaya, jadi lebih baik ditolak oleh database sejak sekarang; (5) menambah kolom penyewa pada dua tabel adalah harga kecil untuk isolasi data yang tidak bisa ditawar.
- **File terkait:** `supabase/migrations/0007_katalog.sql`, `supabase/tes/katalog.sql`, `alat/sql/data-uji.sql`
- **Implikasi:** 1) RPC/SQL uang (T1-15 `hitung_total`) **wajib** memakai `harga_berlaku()`; dilarang membaca `menu_item.harga` langsung, karena itu akan mengabaikan harga cabang. 2) Tabel baru apa pun yang menyimpan harga/uang harus tetap menyimpan **salinan saat transaksi** (`harga_saat_itu`) agar riwayat tidak berubah bila harga diubah — dibuktikan di T1-09. 3) Stok tidak boleh diubah dengan `update`; gunakan `catat_stok()`. 4) Menu yang ditandai habis tetap boleh dilihat pelanggan sebagai “habis” (bukan disembunyikan) — perilaku layar menyusul di Fase 8. 5) Uji `katalog.sql` terbukti bisa MERAH lewat 4 uji mutasi; cacat “owner pusat tidak melihat harga cabang” dan “dapur bisa menetapkan harga saat menyisipkan baris” ditemukan uji sebelum dikirim.

### [Fase 1/2026-09-16] Riwayat pesanan dibekukan: salinan nama & harga, nomor per cabang/hari, dan pesanan yang tak bisa dihapus (T1-09)
- **Area:** State Machine (ART-4) & Kalkulasi (ART-3) — menyentuh seluruh uang & laporan
- **Keputusan:**
  1. **Setiap baris pesanan menyimpan SALINAN** `nama_saat_itu` dan `harga_saat_itu` (keduanya WAJIB). Menu boleh berubah nama/harga kapan saja; struk, laporan, dan laba hari itu **tidak ikut berubah**.
  2. **Salinan beku dijaga pemicu**: `nama_saat_itu`, `harga_saat_itu`, `menu_item_id`, dan `pesanan_id` **tidak boleh diubah** oleh siapa pun (termasuk owner). Salah harga diperbaiki dengan **membatalkan baris itu lalu menambah baris baru** — itulah jalur yang meninggalkan jejak.
  3. **Nomor pesanan unik per cabang per tanggal** (`unique (cabang_id, tanggal, nomor)`); kolom `tanggal` disiapkan sekarang, sedangkan **penghitungan menurut zona waktu resto** dan pemberian nomornya dikerjakan di T1-17.
  4. **`kunci_idempoten` unik per cabang** — satu keranjang tidak bisa tersimpan dua kali walau koneksi terputus dan kasir menekan tombol lagi (dasar perilaku “daring + tahan gangguan”).
  5. **Pesanan tidak pernah dihapus**: hak `DELETE` memang tidak diberikan, dan pembatalan memakai kolom `status`/`dibatalkan_pada`/`alasan_batal`. Membatalkan SATU baris (`pesanan_item.status = 'batal'`) juga tidak menghapus barisnya.
  6. **Status resmi mengikuti TECH_SPEC §4.3** (`draf` → `dikirim` → `dimasak` → `siap` → `lunas`, dan `batal`); aturan perpindahannya dijaga menyusul di **T1-18** (mesin status), bukan disebar di banyak layar.
  7. **Konsistensi antar tabel dijaga database**: meja harus satu cabang dengan pesanannya; pesanan tidak bisa dibuat di cabang/resto lain; item pesanan tidak bisa memakai menu resto lain; pemilik resto tidak bisa “menitipkan” pesanan ke resto lain.
- **Alasan:** (1) harga yang berubah mengubah riwayat adalah masalah uang paling halus dan paling mahal — pelanggan bisa memegang struk yang tidak cocok dengan tagihan, dan laporan bulan lalu berubah sendiri; (2) membekukan salinan berarti pertanyaan “kenapa harganya begini?” selalu bisa dijawab; (3) nomor ganda atau pesanan ganda membuat dapur memasak dua kali dan stok keluar dua kali; (4) pesanan yang bisa dihapus membuat kecurangan kasir tidak bisa ditelusuri.
- **File terkait:** `supabase/migrations/0009_pesanan.sql`, `supabase/tes/pesanan.sql`, `supabase/migrations/0008_meja.sql`, `supabase/tes/meja.sql`, `alat/sql/data-uji.sql`
- **Implikasi:** 1) RPC `simpan_pesanan` (T3-05) **wajib** mengambil harga dari `harga_berlaku()` saat pesanan dibuat dan menulis salinannya — dilarang menghitung ulang dari tabel menu setelahnya. 2) `hitung_total()` (T1-15) menghitung dari **salinan** di baris pesanan, bukan dari harga menu terkini. 3) Bila nanti menu benar-benar salah harga saat pembuatan, jalurnya adalah batal + tambah baru (berjejak), bukan `update`. 4) Laporan & struk tidak boleh membaca tabel menu sama sekali. 5) Uji `pesanan.sql` terbukti bisa MERAH lewat 3 uji mutasi.

### [Fase 1/2026-09-16] Uang masuk & pembatalan: angka uang milik peladen, satu pembayaran satu baris, diskon dibatasi izin (T1-10)
- **Area:** Kalkulasi Keuangan (ART-3) & Aturan Bisnis 7 (void bertingkat)
- **Keputusan:**
  1. **Angka uang pesanan hanya boleh diisi fungsi peladen.** Pemicu menolak `subtotal`/`pajak`/`service`/`total_diskon`/`total` yang bukan-nol bila perintah datang dari klien; jalur sahnya adalah fungsi peladen (`hitung_total()` di T1-15). Pembeda "peladen vs klien" memakai **peran efektif** (pemilik tabel / `service_role`) — **tidak bisa dipalsukan** klien, berbeda dari penanda sesi.
  2. **Satu pembayaran = satu baris tercatat.** `kunci_idempoten` unik per pesanan; baris pembayaran **tidak bisa diubah/dihapus** (haknya memang tidak diberikan) — koreksi lewat pembatalan, sehingga selalu berjejak. Banyak baris per pesanan tetap sah (pembayaran terbagi).
  3. **Kembalian & jenis pembayaran dihitung database**, bukan dikirim perangkat: tunai wajib menyebut uang diterima (`kembalian = diterima − jumlah`), bukan tunai wajib menyebut referensi, dan `jenis` diambil dari tabel `metode_bayar` (disalin ke baris sebagai `jenis_saat_itu` supaya riwayat tidak berubah bila metode diubah namanya).
  4. **Pembayaran tidak boleh melebihi total pesanan.** Bila `total` masih 0 (belum dihitung `hitung_total`), pemeriksaan dilewati supaya pencatatan tidak macet — celah sementara ini **tertutup di T1-15** karena pembayaran hanya sah setelah total dihitung. **(DIREVISI 2026-09-17 setelah audit AUD-3: celah itu NYATA dan tidak boleh menunggu T1-15 — lihat entri "Perbaikan K-1" di bawah. Kini pembayaran DITOLAK selama total belum dihitung.)**
  5. **Batas diskon memakai gerbang izin yang sama** (`boleh('beri_diskon', nominal, persen)`), jadi batas kasir 25.000 / 5% dan admin 50.000 / 10% tidak pernah disalin ulang di tempat lain. **Tumpuk diskon mengikuti pengaturan resto** (bawaan: satu diskon per transaksi — Aturan Bisnis 2). Diskon manual wajib beralasan; total diskon tidak boleh melebihi subtotal.
  6. **Pembatalan wajib beralasan & bertahap.** Tahap ditentukan database dari **dua tanda** (waktu kirim ke dapur **dan** status pesanan) — memakai satu tanda saja rapuh: bila salah satu lupa diisi, pembatalan bisa lolos tanpa PIN. Setelah dapur mulai wajib disetujui pengguna yang benar-benar berizin `void_sesudah_dapur` (diperiksa lewat `boleh_untuk()`); nilai kerugian dihitung dari **salinan harga**, bukan harga menu sekarang.
  7. **Metode bayar per resto dengan 4 bawaan** (Tunai/QRIS/Transfer/Kartu) dipasang otomatis lewat pemicu — resto baru tidak pernah kehabisan cara bayar, dan menambah metode lain tidak butuh koding.
- **Alasan:** (1) kalau perangkat boleh mengirim angka uang, seluruh perhitungan peladen hanya jadi saran; (2) pembayaran dobel saat koneksi kedai jelek adalah kejadian nyata, dan koreksi yang bisa menghapus baris membuat kecurangan tidak bisa ditelusuri; (3) kembalian yang dihitung perangkat bisa berbeda dengan struk; (4) diskon adalah tempat uang paling sering bocor tanpa jejak; (5) “kapan dapur mulai” adalah penentu siapa yang boleh membatalkan — salah menilai tahap berarti salah menentukan siapa yang berwenang.
- **File terkait:** `supabase/migrations/0010_pembayaran.sql`, `supabase/tes/pembayaran.sql`, `alat/sql/data-uji.sql`
- **Implikasi:** 1) `hitung_total()` (T1-15) **wajib** SECURITY DEFINER + menulis kelima kolom uang sekaligus, dan **wajib** memeriksa ulang total setelah diskon berubah. 2) `bayar_pesanan` (T5-02) memakai `total_dibayar()` sebagai sumber tunggal. 3) `diskon_transaksi.voucher_id` masih belum berkunci asing — kuncinya dipasang di **T1-12** saat tabel `voucher` ada; begitu juga `pembayaran.shift_id` di **T1-11**. 4) Uji `pembayaran.sql` terbukti bisa MERAH lewat 6 uji mutasi, dan **dua uji yang lulus karena sebab yang salah** ditemukan lewat uji mutasi itu lalu diperbaiki — aturan kerjanya: uji negatif wajib memilih kasus yang hanya bisa ditolak oleh satu sebab.

### [Fase 1B/2026-09-17] Satu akun = satu peran (identitas tidak boleh bercampur) — keputusan pemilik, dikuatkan agent
- **Area:** Role & Permission (ART-2) + Keamanan Akun (ART-12 baru)
- **Keputusan:**
  1. **Setiap akun hanya punya SATU peran**, berlaku di semua cabang yang ditugaskan. Orang yang punya dua fungsi (mis. kasir merangkap pelayan) **wajib punya dua akun** dengan **PIN berbeda**.
  2. **`pengguna_cabang` disederhanakan**: hanya menyimpan **daftar cabang** tempat akun itu bertugas (kolom `peran` per cabang dihapus/diabaikan). Peran datang dari satu tempat saja (`pengguna.peran`).
  3. **PIN wajib unik antar pegawai dalam satu resto** (PIN tidak boleh dipakai dua akun), dan PIN tidak boleh berpola lemah (semua angka sama, berurutan, tanggal lahir `ddmmyy`).
  4. **Izin (centang) tetap boleh berbeda per akun** — itu penyetelan di dalam satu peran, bukan peran kedua.
  5. Pengelompokan "satu orang, dua akun" untuk laporan dilakukan lewat **nama pegawai yang sama + peran berbeda**; tabel `orang` (HR ringan) **tidak** dibuat di G1.
- **Alasan:** (1) ide pemilik & memang benar: bila satu akun boleh dua peran, maka "siapa berwenang apa" tidak lagi bisa dibuktikan hanya dari data — dan izin berjenjang yang sudah dibuktikan di T1-05 jadi kabur; (2) satu peran = satu jalur pemeriksaan, jadi uji matriks izin × peran bisa dibuat otomatis dan tidak ada kombinasi tersembunyi; (3) jejak audit menjadi tegas: setiap tindakan punya peran yang jelas; (4) PIN unik mencegah "PIN bertukar" yang membuat tindakan seseorang tercatat atas nama orang lain.
- **File terkait:** `docs/KEAMANAN.md` (bagian identitas), `supabase/migrations/0011_peran_tunggal.sql`, `supabase/tes/peran_tunggal.sql`
- **Implikasi:** 1) Migrasi baru wajib (tidak boleh mengubah `0002` yang sudah jalan): menegakkan peran tunggal, memasang kunci pada `pengguna_cabang`, dan menyesuaikan fungsi `peran_saya()`/`cabang_ids_saya()` bila perlu. 2) Perangkat terdaftar menyimpan **peran yang diizinkan** — sehingga satu tablet kasir tidak bisa dipakai masuk sebagai owner. 3) Uji matriks (T1-29) memakai daftar peran dari `pengguna.peran`, bukan dari beberapa sumber. 4) Laporan "pegawai merangkap" tetap bisa dibuat dengan menggabungkan baris akun bernama orang yang sama.

### [Fase 1B/2026-09-17] Perangkat terdaftar: kode pendaftaran + persetujuan pemilik + pencabutan seketika
- **Area:** Keamanan Akun & Perangkat (ART-11 baru)
- **Keputusan:**
  1. **Setiap peran staf (kasir/pelayan/dapur/admin cabang/owner pusat) hanya bisa memakai aplikasi dari perangkat yang TERDAFTAR**; pendaftaran memakai **kode sekali pakai** (masa berlaku 15 menit) yang dibuat admin/owner, dan perangkat menyimpan **rahasia acak 32 byte** yang di server hanya tersimpan sebagai **SHA-256** (rahasia 256-bit tidak bisa ditebak, jadi tidak perlu bcrypt yang lambat).
  2. **Persetujuan pemilik saat pegawai pertama kali memakai perangkat itu** (pilihan pemilik): perangkat terdaftar belum cukup; setiap pasangan (pegawai × perangkat) baru wajib disetujui owner/admin yang berizin — bisa dari jauh, dan tercatat.
  3. **Perangkat punya `peran_diizinkan`** (mis. "Tablet Kasir 1" hanya untuk peran kasir) + `cabang_id` + nama + status (`aktif`/`dicabut`/`hilang`).
  4. **Pencabutan seketika**: status perangkat dan sesi diperiksa **di database pada setiap permintaan**, bukan hanya saat masuk. Alasannya teknis dan penting: dokumentasi Supabase menyatakan **token akses yang sudah diterbitkan tidak bisa dicabut sebelum kedaluwarsa** — jadi pencabutan tidak boleh bergantung pada token.
  5. **Pemilik platform (`pemilik_platform`) dikecualikan** dari pengikatan perangkat (harus bisa menolong dari mana saja), sebagai gantinya: TOTP wajib + umur sesi pendek (8 jam) + **tidak punya akses isi data penyewa** kecuali mode dukungan.
  6. **Bootstrap**: perangkat pertama milik owner pusat boleh didaftarkan sendiri dengan **kata sandi + TOTP** (dia akar kepercayaan restonya); perangkat berikutnya butuh persetujuan dari perangkat aktif.
- **Alasan:** (1) inilah jawaban langsung atas kekhawatiran pemilik: perangkat kecurian tanpa PIN tidak membuka apa pun, dan begitu dilaporkan hilang, aksesnya mati dalam hitungan detik; (2) pola kode perangkat adalah praktik industri POS (Square memakai "device code" per perangkat & per lokasi) — bukan eksperimen; (3) memeriksa di database (bukan di aplikasi) membuat aturan ini tidak bisa dilangkahi lewat API langsung; (4) mengecualikan pemilik platform menjaga jalan darurat tetap ada, dengan pengaman setara (TOTP + sesi pendek + tanpa data penyewa).
- **File terkait:** `supabase/migrations/0012_perangkat.sql`, `supabase/migrations/0013_sesi_perangkat.sql`, `supabase/tes/perangkat.sql`, `supabase/tes/sesi_perangkat.sql`, `docs/KEAMANAN.md` *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
- **Implikasi:** 1) Seluruh policy RLS untuk peran staf wajib memakai `perangkat_sah()` — pola ini dipasang sebelum migrasi `kas/shift` (T1-11) supaya tidak dibongkar dua kali. 2) Bukti perangkat dikirim sebagai header permintaan dan dibaca lewat `current_setting('request.headers')`; **wajib dibuktikan di Supabase nyata (T0-08)** sebelum dijadikan syarat tunggal — jaring pengaman `sesi_perangkat` tetap berlaku tanpa header. 3) Fungsi `perangkat_sah()` wajib `stable`, `search_path` dipaku, dan dipanggil `(select public.perangkat_sah())` agar tidak dievaluasi ulang per baris. 4) Uji wajib: perangkat tidak terdaftar → tabel staf tertutup; cabut perangkat → permintaan berikutnya gagal; perangkat dengan peran lain → ditolak.

### [Fase 1B/2026-09-17] Masuk staf satset tapi aman: PIN 6 digit HANYA sah di perangkat terdaftar
- **Area:** Keamanan Akun (ART-12 baru) + Role & Permission (ART-2)
- **Keputusan:**
  1. **Kasir/pelayan/dapur masuk dengan "pilih nama → PIN 6 digit"**, dan kombinasi itu hanya berlaku dari perangkat terdaftar yang `peran_diizinkan`-nya cocok. Tanpa perangkat terdaftar, PIN sekuat apa pun tidak menghasilkan sesi yang bisa dipakai (ikatan sesi ditolak).
  2. **Akun staf tidak memakai email nyata**: email Supabase memakai **alias internal** resto (tidak pernah dipakai mengirim email). Konsekuensi jujur: **pemulihan akun/PIN staf dilakukan admin/owner** (wajib izin `kelola_pegawai`, tercatat) — dan justru itu yang menutup pintu pengambilalihan akun lewat email.
  3. **Ditolak dengan sadar:** (a) PIN sebagai kunci enkripsi lokal (PIN 6 digit bisa dibobol luring dari perangkat curian); (b) Edge Function yang menerbitkan sesi sendiri (menambah jalur rahasia baru yang harus dijaga sempurna — risiko jauh lebih besar daripada manfaatnya di proyek ini); (c) PIN bisa dipakai dari perangkat mana saja.
  4. **Kata sandi panjang** hanya untuk admin cabang, owner pusat, dan pemilik platform; staf tidak perlu menghafal kata sandi apa pun.
- **Alasan:** (1) permintaan pemilik: "mudah tapi aman, mereka perlu kerja satset" — 2 detik, tanpa kata sandi tertulis di meja kasir; (2) keamanan sesungguhnya berasal dari KOMBINASI (perangkat yang harus ada + PIN yang harus diketahui), bukan dari panjang PIN; (3) memakai mekanisme bawaan Supabase (kata sandi + sesi) menghindari kriptografi buatan sendiri yang paling sering menjadi sumber cacat.
- **File terkait:** `docs/KEAMANAN.md`, `supabase/migrations/0013_sesi_perangkat.sql`, `supabase/migrations/0014_percobaan_masuk.sql`, `supabase/tes/percobaan_masuk.sql` *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
- **Implikasi:** 1) PIN staf **sama** dengan PIN persetujuan (satu rahasia per pegawai, dua kegunaan) — tidak ada dua PIN yang membuat staf bingung. 2) Tabel uji wajib membuktikan: PIN benar + perangkat tidak terdaftar = **gagal**; PIN salah + perangkat terdaftar = **gagal** + tercatat; PIN benar + perangkat terdaftar = **berhasil**. 3) Kunci otomatis (idle) berarti sesi dihapus dari perangkat, jadi perangkat yang ditinggal tidak menyimpan apa pun. 4) Kalau internet mati saat perangkat terkunci, staf tidak bisa membuka sampai internet kembali — dicatat sebagai kasus tepi di PRD & Buku Insiden.

### [Fase 1B/2026-09-17] TOTP wajib untuk 3 peran berkuasa + jalan pemulihan yang tidak memacetkan kerja
- **Area:** Keamanan Akun (ART-12 baru)
- **Keputusan:**
  1. **TOTP (aplikasi authenticator) WAJIB untuk `pemilik_platform`, `owner_pusat`, dan `admin_cabang`.** TOTP gratis di semua paket Supabase (TOTP MFA tersedia bawaan).
  2. **Kasir/pelayan/dapur tidak memakai TOTP** — keamanan akun mereka sudah dua lapis (perangkat terdaftar + PIN), dan memaksa TOTP di dapur/kasir justru mendorong PIN ditempel atau HP dipinjam-pinjamkan.
  3. **Jalan pemulihan (agar tidak memacetkan kerja):** admin cabang yang kehilangan HP → **owner pusat bisa mengatur ulang MFA-nya** (tercatat + notifikasi); owner pusat yang kehilangan HP → **pemilik platform** yang mengatur ulang lewat panel; pemilik platform kehilangan HP → langkahnya ada di Buku Insiden.
  4. **Tanpa kode pemulihan mandiri di G1** (sengaja): kode pemulihan menambah jalur rahasia baru yang harus dijaga; ditinjau lagi di Fase 10 bila terasa perlu (dicatat di TERTANGGUH T-016).
- **Alasan:** (1) jawaban atas kebimbangan pemilik: admin cabang memang memegang akses penting (harga cabang, printer, opname stok, laporan cabang) sehingga pantas dilindungi TOTP; (2) tetapi mewajibkan tanpa jalan pemulihan = risiko operasional nyata (HP hilang = pegawai berhenti kerja) → karena itu jalan pemulihan dibuat lebih dulu, bukan belakangan; (3) memberi TOTP ke kasir/pelayan/dapur menambah friksi harian terbesar dengan tambahan keamanan terkecil — kombinasi perangkat+PIN sudah setara.
- **File terkait:** `docs/KEAMANAN.md`, `supabase/functions/atur_ulang_mfa/index.ts`, `alat/periksa-fungsi-mfa.py`, `supabase/tes/mfa.sql` *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
- **Implikasi:** 1) Edge Function `atur_ulang_mfa` wajib **tipis**: pemeriksaan wewenang dilakukan di database (RPC memakai `boleh('kelola_pegawai')` + target harus satu resto + peran target lebih rendah), fungsi Deno hanya meneruskan; dilarang memakai `console.*`. 2) Setiap pengaturan ulang MFA menulis `catatan_audit` + mengirim pemberitahuan. 3) Pendaftaran TOTP dilakukan **saat penyiapan/training**, bukan saat jam sibuk (masuk daftar langkah Fase 11). 4) Uji: admin cabang tanpa TOTP tidak bisa masuk; setelah diatur ulang, TOTP bisa didaftarkan lagi; pengaturan ulang oleh yang tidak berizin ditolak.

### [Fase 1B/2026-09-17] Kendali sesi dibuat sendiri (karena batas paket gratis) — dan justru lebih kuat
- **Area:** Keamanan Sesi (ART-11 baru)
- **Keputusan:**
  1. **Kebijakan sesi ditegakkan di database kita** (`sesi_perangkat`): umur maksimum sesi staf **12 jam** (satu shift), admin/owner **30 hari**, pemilik platform **8 jam**; sesi kedaluwarsa ditolak walau tokennya masih sah.
  2. **Token akses dipendekkan (15 menit)** lewat pengaturan Supabase (gratis), dan **kunci otomatis saat menganggur** (kasir/pelayan/dapur 15 menit · admin 30 menit · owner/platform 60 menit) dengan tombol "Kunci sekarang" di semua layar staf.
  3. **Kunci = sesi dihapus dari perangkat**; membuka lagi wajib PIN/kata sandi (membuka sesi baru). Jadi perangkat yang ditinggal tidak menyimpan token sama sekali.
  4. **Batas percobaan masuk: 5×/15 menit per akun dan 12×/15 menit per perangkat**, semua percobaan (berhasil/gagal/diblokir) masuk `percobaan_masuk`; kunci bertambah tidak memperpendek masa tunggu.
  5. **Catatan jujur:** "time-box sesi", "inactivity timeout", "satu sesi per pengguna", dan pemeriksa kata sandi bocor (HaveIBeenPwned) adalah fitur **Pro**. Untuk kata sandi owner/admin, kompensasinya: panjang minimum 12 karakter, dilarang pola umum, dan TOTP wajib.
- **Alasan:** (1) pencabutan lewat database berlaku **seketika**, sedangkan kendali bawaan (bila ada) baru berlaku saat token diperbarui — untuk kasus perangkat hilang, detik itu penting; (2) kunci otomatis menutup celah terbesar di kedai: tablet ditinggal di meja; (3) batas percobaan harus milik kita karena Supabase hanya membatasi per IP dan tidak mengunci per pengguna.
- **File terkait:** `supabase/migrations/0013_sesi_perangkat.sql`, `supabase/migrations/0014_percobaan_masuk.sql`, `aplikasi/src/lib/sesi.ts` (T2-16)
- **Implikasi:** 1) Aplikasi wajib menyimpan penanda WAKTU aktif terakhir per perangkat dan mengunci sendiri (`onVisibilityChange` + pengatur waktu). 2) Uji SQL wajib: sesi lewat umur → ditolak; sesi dicabut → ditolak; percobaan ke-6 → diblokir 15 menit. 3) Sesi yang dikunci di tengah antrean offline berarti antrean baru terkirim setelah masuk lagi — dicatat di ART-8 & Buku Insiden. 4) Pengaturan "kunci otomatis" dibuat per peran dan bisa diubah owner tanpa koding.

### [Fase 1B/2026-09-17] Kecurangan uang: rekonsiliasi non-tunai + ringkasan peringatan harian
- **Area:** Kalkulasi Keuangan (ART-3) + Kas & Shift (ART-6)
- **Keputusan:**
  1. **Setiap pembayaran non-tunai wajib menyimpan `referensi`** (nomor transaksi QRIS/transfer/kartu) — sudah ada di T1-10; sekarang **ditampilkan sebagai daftar di layar tutup kas** agar owner bisa mencocokkan dengan aplikasi QRIS/bank.
  2. **Ringkasan peringatan harian ke owner (1 email/hari, gratis lewat Resend):** omzet, jumlah transaksi, void (siapa/nilai/alasan), diskon (siapa/nilai), selisih kas, percobaan masuk gagal, dan perubahan perangkat. Tujuannya bukan laporan lengkap, tetapi **membuat hal aneh terlihat tanpa owner harus membuka aplikasi**.
  3. **Laporan "siapa menyetujui apa" per bulan** (PIN persetujuan): mencegah PIN atasan dipakai berulang tanpa terasa.
- **Alasan:** (1) pembayaran non-tunai adalah tempat paling mudah "menandai lunas tanpa uang masuk" — pencocokan berkala menutupnya tanpa integrasi berbayar; (2) kecurangan kecil biasanya ketahuan terlambat karena tidak ada yang melihat; email harian menghilangkan alasan "tidak sempat membuka laporan"; (3) ini semua memakai data yang sudah ada — tambahannya kecil, nilainya besar.
- **File terkait:** `docs/KEAMANAN.md`, `supabase/functions/ringkasan_harian/index.ts` *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
- **Implikasi:** 1) RPC laporan baru wajib membaca **salinan** (`harga_saat_itu`) dan tidak boleh menghitung ulang dari menu. 2) Email ringkasan tidak boleh memuat data pribadi pelanggan (UU PDP) — hanya angka & nama pegawai. 3) Uji: ringkasan memuat baris void & selisih yang benar untuk data uji yang sudah ada.

### [Fase 1B/2026-09-17] `catatan_audit` hanya-tambah DITAMBAH penguncian rantai hash
- **Area:** Jejak Audit (ART-13 baru)
- **Keputusan:**
  1. `catatan_audit` tetap **hanya-tambah** (tidak ada hak ubah/hapus untuk siapa pun, termasuk owner).
  2. Setiap baris menyimpan **`hash_sebelumnya` dan `hash_baris`** (SHA-256 atas isi baris kanonik + hash sebelumnya). Rantai dihitung pemicu, bukan oleh aplikasi.
  3. Pemeriksa `alat/periksa-audit.py` bisa memverifikasi rantai dan **menunjuk baris pertama yang putus** — mis. bila seseorang dengan akses database mengubah atau menghapus satu baris. *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
- **Alasan:** hak "hanya-tambah" melindungi dari pengguna aplikasi, tetapi tidak dari seseorang yang bisa menulis langsung ke database; rantai hash mengubah "tidak bisa diubah" dari janji menjadi **bukti yang bisa diperiksa** — penting untuk sengketa uang dengan pegawai/pelanggan.
- **File terkait:** `supabase/migrations/0015_audit.sql`, `supabase/tes/audit.sql`, `alat/periksa-audit.py` *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
- **Implikasi:** 1) Pemicu wajib mengambil baris terakhir dengan kunci (lock) agar dua penyisipan bersamaan tidak menghasilkan rantai bercabang. 2) Uji wajib: ubah satu baris → pemeriksa menunjuk baris itu; hapus satu baris → putus terdeteksi. 3) Verifikasi rantai dijalankan berkala (pg_cron) dan hasilnya dikirim sebagai bagian ringkasan harian bila putus.

### [Fase 1B/2026-09-17] Privasi pelanggan & UU PDP (Indonesia): persetujuan, minimalisasi, anonimisasi, lapor 3×24 jam
- **Area:** Data Pelanggan (ART-14 baru)
- **Keputusan:**
  1. **Persetujuan eksplisit** sebelum data pelanggan disimpan (kalimat singkat: apa yang disimpan, untuk apa, berapa lama, cara minta dihapus) — bukan centang tersembunyi.
  2. **Minimalisasi:** hanya nama, kontak (opsional), dan catatan voucher. Tidak ada NIK, tidak ada lokasi, tidak ada data biometrik, tidak ada pelacakan.
  3. **Hak pelanggan:** permintaan akses/hapus → data pribadi **dianonimkan** (nama/kontak dihapus atau diganti), sementara catatan keuangan tetap utuh (Aturan Bisnis 11). Waktu tanggap 3×24 jam.
  4. **Kebocoran data:** pemberitahuan tertulis maksimal **3×24 jam** kepada subjek data + lembaga pengawas (UU PDP Pasal 46), dengan isi: data apa, kapan/bagaimana, dan langkah pemulihan. Template & langkah ada di `docs/teknis/BUKU_INSIDEN.md`.
  5. **Lokasi data:** region proyek Supabase ditetapkan pemilik saat T0-08 (usul: Singapore); bila di luar Indonesia, dasar transfer = persetujuan + pengamanan kontrak penyedia.
- **Alasan:** (1) proyek ini menyimpan data pelanggan (voucher undang-teman) — jadi kewajiban UU PDP berlaku sejak pilot, bukan "nanti"; (2) denda administratif sampai 2% pendapatan tahunan + ancaman pidana jauh lebih mahal daripada menulis kalimat persetujuan; (3) anonimisasi menjaga dua kepentingan sekaligus: hak pelanggan dan keutuhan catatan uang.
- **File terkait:** `docs/KEAMANAN.md`, `docs/teknis/BUKU_INSIDEN.md`, `supabase/migrations/0017_privasi_pelanggan.sql`, `supabase/tes/privasi.sql` *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
- **Implikasi:** 1) T-011 (kebijakan privasi) berubah menjadi pekerjaan agent di Fase 1B, ditinjau pemilik sebelum Fase 8. 2) Halaman pendaftaran voucher wajib menampilkan kalimat persetujuan + tautan kebijakan. 3) Laporan/email tidak boleh memuat kontak pelanggan. 4) Uji: pelanggan tanpa persetujuan ditolak; permintaan anonimisasi menghapus kontak tetapi tidak menghapus transaksi.

### [Fase 1B/2026-09-17] Mode dukungan pemilik platform: beralasan, berbatas waktu, tercatat, diberitahukan
- **Area:** Akses Lintas Penyewa (ART-15 baru) + RLS (ART-1)
- **Keputusan:**
  1. **Bawaan: `pemilik_platform` TIDAK bisa melihat isi data penyewa** — hanya daftar penyewa, cabang, dan status.
  2. Bila ada masalah nyata, pemilik platform membuka **mode dukungan**: wajib **alasan**, berbatas waktu (bawaan 60 menit, tidak bisa diperpanjang otomatis), dan **hanya-baca**.
  3. Setiap mode dukungan menulis `catatan_audit` **dan** mengirim pemberitahuan ke owner penyewa (email) — sehingga tidak ada pengintaian diam-diam.
  4. Mode dukungan **tidak** memberi hak mengubah data; perbaikan data selalu lewat jalur normal pemilik resto (atau jalur pemulihan bencana yang terdokumentasi di Buku Insiden).
- **Alasan:** (1) ini janji di PRD §9 yang harus punya bentuk teknis, bukan sekadar niat; (2) tanpa jalan dukungan, pemilik platform akan terdorong memakai kunci penuh (`service_role`) di luar prosedur — jauh lebih berbahaya; (3) pemberitahuan otomatis membuat penyewa merasa aman tanpa menghalangi bantuan.
- **File terkait:** `supabase/migrations/0016_mode_dukungan.sql`, `supabase/tes/mode_dukungan.sql`, `docs/KEAMANAN.md` *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
- **Implikasi:** 1) Policy RLS wajib membedakan "pemilik platform biasa" dan "mode dukungan aktif" — diuji keduanya. 2) Mode dukungan berakhir otomatis (pg_cron) dan berakhir bila pemilik platform keluar. 3) Uji: tanpa mode dukungan → 0 baris; dengan mode dukungan → hanya-baca (perintah tulis ditolak); setelah kedaluwarsa → 0 baris lagi.

### [Fase 1C/2026-09-17] Kelengkapan UI: Registri Aksi + Peta Layar + pemeriksa otomatis (anti "tombol mati")
- **Area:** Arsitektur Klien & Kelengkapan Fitur (bukan Area Berisiko Tinggi, tetapi mengikat semua tugas UI)
- **Keputusan:**
  1. **Registri Aksi** (`aplikasi/src/lib/aksi.ts`) menjadi **satu-satunya sumber kebenaran** untuk setiap tombol/menu/gestur: id, label, layar, peran, izin, RPC, jenis, konfirmasi, butuh-PIN, pesan sukses/gagal, dan daftar uji. **Semua tombol dirender lewat `<TombolAksi id="…">`**; aksi tanpa entri tidak bisa dirender. *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
  2. **Peta Layar** (`aplikasi/src/lib/layar.ts`): id, rute, judul, peran yang boleh, dan **7 keadaan wajib** (kosong · memuat · gagal · menunggu terkirim · tidak punya akses · data sebagian · berhasil). *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
  3. **Kontrak layar** wajib ditulis untuk setiap layar di `docs/SPESIFIKASI_UI.md` sebelum layar dikerjakan (tujuan, jalan masuk, data, aksi, 7 keadaan, bukti uji, nomor naskah jalan).
  4. **Pemeriksa otomatis** `alat/peta-ui.py` men-generate `docs/PETA_UI.md` dari kedua registri dan **menggagalkan CI** bila: RPC aksi tidak ada di migrasi · kode izin tidak ada · aksi tanpa uji · layar tanpa berkas/rute · dokumen peta basi · fitur PRD M1–M12 tanpa jejak layar/aksi. *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
  5. **Uji komponen tiap layar** (jsdom + Testing Library, sudah terpasang): dirender per peran; tombol yang seharusnya ada benar-benar **memanggil RPC yang benar** (ditiru); tombol terlarang tidak ada; 7 keadaan tampil. Ini yang membuktikan "tombol benar-benar bisa dipakai", bukan sekadar ada.
  6. **Naskah jalan pemilik** bernomor (`W-<fase>-<nomor>`, bahasa manusia "tekan ini → harus muncul itu") wajib ditulis & dijalankan di pratinjau untuk setiap tugas UI.
  7. **DoD versi baru** untuk tugas UI: kontrak layar · aksi terdaftar · 7 keadaan · uji komponen hijau · pemeriksa peta-UI hijau · naskah jalan dijalankan · **izin dicek di database** (bukan hanya disembunyikan di layar).
  8. **Uji peramban (Playwright) ditaruh di GitHub Actions**, bukan di ruang kerja agent: Chromium **tidak bisa diunduh** di ruang kerja ini (sudah dicoba 2026-09-17) tetapi CI menjalankannya pada mesin Ubuntu. Kalau ternyata gagal, dilaporkan jujur dan diganti — bukan diklaim.
- **Alasan:** (1) ini jawaban langsung atas pengalaman pemilik ("banyak tombol kurang, fungsi katanya ada tapi tak bisa dipakai") — penyebabnya bukan AI-nya, melainkan tidak ada daftar tombol, tidak ada uji pemanggilan, dan "selesai" yang berarti "kode ditulis"; (2) registri membuat tombol **tidak bisa lahir tanpa uji**, dan pemeriksa membuat dokumen tidak bisa basi; (3) kontrak layar memaksa 7 keadaan diputuskan sebelum dikoding — tempat paling sering muncul "fitur palsu" (layar yang jalan hanya bila data ada).
- **File terkait:** `aplikasi/src/lib/aksi.ts`, `aplikasi/src/lib/layar.ts`, `aplikasi/src/komponen/TombolAksi.tsx`, `alat/peta-ui.py`, `docs/SPESIFIKASI_UI.md`, `docs/PETA_UI.md` *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
- **Implikasi:** 1) Fase 1C dikerjakan **sebelum** layar pertama Fase 3 dibuat, supaya semua layar mengikutinya sejak awal. 2) Layar contoh (`LayarContoh`) dijadikan contoh kontrak pertama. 3) Setiap tugas UI di ROADMAP wajib menyebut nomor kontrak layar & naskah jalan. 4) Menambah aksi berarti mengubah registri + uji + dokumen hasil generate; tidak ada jalur pintas.

### [Fase 1B/2026-09-17] Penerbit kode perangkat + peran berkuasa tetap wajib perangkat terdaftar
- **Area:** Akses Perangkat (ART-11) & Role (ART-12)
- **Keputusan:** (1) Kode pendaftaran perangkat dibuat **owner pusat (semua cabangnya)** dan **admin cabang (cabangnya saja)** — sekali pakai, sah 15 menit, tercatat pembuatnya. (2) **Semua peran** — termasuk `owner_pusat`, `admin_cabang`, `pemilik_platform` (kecuali pemilik platform yang memang lintas penyewa) — **wajib memakai perangkat terdaftar**; perangkat pertama owner didaftarkan sekali saat penyiapan (bootstrap), perangkat berikutnya lewat persetujuan perangkat aktif. (3) Perangkat cadangan **wajib** untuk peran berkuasa (minimal 2 terdaftar) + peringatan bila tinggal 1.
- **Alasan:** pemilik menyetujui rekomendasi tetapi mengangkat risiko nyata: *"gimana kalau perangkat admin hilang atau dicuri? Itu harus dipikirkan"*. Karena itu pemulihan dirancang sekaligus (keputusan berikutnya), bukan ditambahkan kemudian. Keuntungan perangkat wajib: tablet kasir tidak akan pernah bisa dibuka sebagai owner meski kata sandi bocor.
- **File terkait:** `supabase/migrations/0012_perangkat.sql`, `supabase/tes/perangkat.sql`, `docs/KEAMANAN.md` §4, ROADMAP T2-15
- **Implikasi:** 1) Bootstrap hanya berlaku selama belum ada perangkat aktif. 2) Perangkat berkuasa minimal 2 → peringatan otomatis. 3) Uji wajib: perangkat tidak terdaftar ditolak untuk **semua** peran, termasuk owner.

### [Fase 1B/2026-09-17] Tangga pemulihan perangkat hilang (kunci induk + masa tenggang 30 menit)
- **Area:** Akses Perangkat (ART-11)
- **Keputusan:** Kehilangan perangkat diselesaikan bertingkat: **(1)** cabut perangkat, kerja lanjut dari perangkat terdaftar lain (PIN melekat pada orang) · **(2)** perangkat admin hilang → perangkat cadangan, atau owner pusat reset MFA lalu daftarkan perangkat baru lewat kode biasa · **(3)** perangkat owner hilang → **kode pemulihan darurat** (8 kata, sekali pakai, hanya hash tersimpan, disimpan tercetak di luar kedai) + kata sandi + TOTP → perangkat darurat dengan **masa tenggang 30 menit** (dinotifikasi & bisa dibatalkan) · **(4)** semua gagal → pemulihan lewat panel Supabase oleh pemilik platform (dipandu `docs/ops/`). Ditambah sakelar penghentian jalur pemulihan.
- **Alasan:** tanpa jalur pemulihan, "perangkat wajib" berubah menjadi risiko operasional (kedai bisa berhenti hanya karena satu HP hilang). Masa tenggang + pemberitahuan + pembatalan dibuat agar kode pemulihan yang dicuri tidak memberikan akses instan; menghindari pemulihan lewat email/WhatsApp yang justru lebih lemah.
- **File terkait:** `supabase/migrations/0016b_pemulihan_perangkat.sql`, `supabase/tes/pemulihan.sql`, `docs/ops/PEMULIHAN_PERANGKAT.md`, `docs/KEAMANAN.md` §4b, ROADMAP T1-36
- **Implikasi:** 1) Kode pemulihan dibuat saat penyiapan (bagian dari syarat "penyiapan selesai"). 2) Latihan pemulihan wajib sekali sebelum pilot. 3) Semua pemakaian jalur pemulihan masuk ringkasan harian. **Status: DISETUJUI pemilik 2026-09-17** ("setuju seperti rancangan"); hanya `owner_pusat` yang boleh memakai kode pemulihan.

### [Fase 2/2026-09-17] Kunci otomatis mengikuti jam aktif cabang + pemberitahuan dua jalur
- **Area:** Sesi (ART-11) & Pemberitahuan (ART-13)
- **Keputusan:** (1) Batas menganggur (15/15/15/30/60 menit) hanya berlaku **di luar jam aktif**; **jam aktif per cabang diatur owner** di Pengaturan (bawaan: jam buka–tutup + masa persiapan); di luar jam aktif kunci otomatis **15 menit**. (2) Semua pemberitahuan penting (ringkasan harian, perangkat dicabut, percobaan masuk gagal beruntun, reset PIN/MFA, pemakaian jalur pemulihan) dikirim **via email owner DAN tampil di layar Peringatan dalam aplikasi**. (3) Data Supabase berlokasi **Singapore (Asia Tenggara)** — menutup T-014.
- **Alasan:** pemilik memilih "owner mengatur sendiri jamnya" supaya tablet yang tertinggal di kedai malam hari tidak bisa dipakai; memilih email **dan** dalam aplikasi agar hal aneh terlihat dari dua jalur; memilih Singapore karena paling dekat (aplikasi terasa cepat) dan tetap sesuai kewajiban UU PDP (persetujuan + pengamanan penyedia).
- **File terkait:** `aplikasi/src/hook/useKunciOtomatis.ts`, `aplikasi/src/layar/laporan/Peringatan.tsx`, `supabase/functions/ringkasan_harian/index.ts`, `docs/KEAMANAN.md` §7 & §9, ROADMAP T2-16 & T10-13
- **Implikasi:** 1) Pengaturan baru: jam aktif per cabang (dengan nilai bawaan aman). 2) Uji: pesanan di antrean tetap utuh saat perangkat terkunci di luar jam aktif. 3) Daftar Peringatan masuk Registri Aksi Fase 1C.

### [Semua fase/2026-09-17] Aturan pemilik: penyimpangan teknis wajib ditanyakan lebih dulu & dicatat
- **Area:** Tata kelola pekerjaan (bukan fitur)
- **Keputusan:** Agent **dilarang** menyimpang dari deskripsi/rancangan yang pemilik tulis tanpa bertanya lebih dulu. Bentuknya: **tanya** → **jelaskan dengan bahasa yang mudah dipahami** (plus alasan & pilihan) → **baru dikerjakan** → **dicatat** (`DECISIONS_LOG.md` + laporan). Berlaku juga untuk perbaikan yang niatnya baik.
- **Alasan:** jawaban pemilik (2026-09-17) atas pertanyaan bebas menyimpang: *"Harus tanyakan dulu ke aku. Dia harus kasih tau dan jelasin alasannya dengan bahasa yang mudah aku pahami. Dan kemudian itu harus tercatat."*
- **File terkait:** `docs/AGENT_OPERATING_GUIDE.md` §11 & §12, `docs/KEAMANAN.md` §16, `docs/SPESIFIKASI_UI.md`
- **Implikasi:** 1) Stop Condition baru di panduan agent. 2) Penjelasan wajib tanpa istilah teknis. 3) Semua penyimpangan yang tetap diputuskan masuk DECISIONS_LOG + laporan batch.
### [Fase 1B/2026-09-17] Penyimpanan & rotasi kode pemulihan (diserahkan pemilik ke agent)
- **Area:** Akses Perangkat (ART-11)
- **Keputusan:** Kode pemulihan disimpan sebagai **dua salinan kertas dengan kode sama**, masing-masing di **amplop tersegel** (lakban/lem + tanda tangan & tanggal pada lipatan): satu di rumah pemilik, satu di lemari arsip kantor kedai **di luar ruang kasir**. Segel rusak → kode dianggap bocor → dibuat kode baru dari perangkat aktif. Kode **diganti** setiap habis dipakai, sekali setahun, dan saat pegawai yang tahu tempat penyimpanannya berhenti.
- **Alasan:** pemilik menyerahkan pilihan ini ("aku minta saran kamu"). Dua salinan hampir tidak menambah risiko karena kertas **tidak cukup untuk masuk** — wajib kata sandi + TOTP + hanya owner pusat + masa tenggang 30 menit + dapat dibatalkan; sedangkan satu salinan punya kelemahan nyata (pemilik tidak bisa dijangkau saat darurat). Amplop tersegel adalah cara murah "pemberitahuan tanpa alat": segel rusak = ada kemungkinan kode pernah dilihat. Alternatif yang ditolak: menyimpan di ponsel/chat (rawan difoto/diteruskan), hanya di kedai (ikut hilang saat dirampok), atau tanpa kertas (pemulihan jadi lambat > 1 jam).
- **File terkait:** `docs/KEAMANAN.md` §4b, ROADMAP T1-36, `docs/ops/PEMULIHAN_PERANGKAT.md`
- **Implikasi:** 1) Penyiapan resto belum "selesai" sebelum dua amplop tersegel ada & dicatat tanggalnya. 2) Sakelar penghentian dipakai bila ada segel rusak yang tidak jelas. 3) Rotasi kode masuk daftar simak tahunan (ditambahkan ke Buku Insiden & `docs/ops/`).
### [Semua fase/2026-09-17] Mekanisme audit independen sebagai gerbang wajib (AUD-0…AUD-3)
- **Area:** Tata kelola pekerjaan (mengikat semua Area Berisiko Tinggi)
- **Keputusan:** Sistem ini memiliki **mekanisme audit independen** resmi: **AUD-0** audit dampak saat keputusan berubah · **AUD-1** periksa batch oleh mesin (CI) · **AUD-2** review independen akhir fase/perubahan berisiko oleh **sesi baru & model berbeda, hanya-baca** · **AUD-3** audit adversarial menyeluruh + **kalibrasi cacat tanaman** sebelum pilot dan kapan pun pemilik meminta. Laporan auditor **wajib lolos** `alat/audit-independen.py --periksa-laporan`; verdict BERSIH pada AUD-3 hanya sah bila auditor lulus kalibrasi (semua cacat K-1/K-2 ditemukan, ≥70% total, tanpa temuan palsu). Ada temuan K-1/K-2 TERVERIFIKASI → **verdict wajib TIDAK-BERSIH** dan fase tidak boleh ditutup. Pemilik memicu audit dengan kalimat bebas ("Audit independen sekarang") dan caranya tertulis di `docs/PANDUAN_PEMILIK.md` §3.
- **Alasan (riset, bukan selera):** (a) studi 2026 menunjukkan model AI **cenderung meloloskan karyanya sendiri** walau diperintah kritis, sedangkan pemeriksa dari sesi/model berbeda menemukan cacat yang tak terlihat pembuatnya (*maker–checker separation*, IV&V); (b) *Perspective-Based Reading* — reviewer dengan skenario per lensa menemukan cacat **~41–58% lebih banyak** daripada reader ad-hoc/daftar periksa; (c) **defect injection** — kemampuan pemeriksa harus **diukur** dengan cacat berjawaban diketahui, kalau tidak "BERSIH" hanya keyakinan; (d) *consensus is not correctness* — tiap temuan wajib lolos upaya **refutasi** sebelum dilaporkan. Permintaan pemilik 2026-09-17: audit yang "sangat teliti", memakai skill, memakai riset internet, dan bisa ia picu sendiri.
- **File terkait:** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`, `alat/audit-independen.py`, `alat/kalibrasi-cacat.json`, `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`, `docs/PANDUAN_PEMILIK.md`, `docs/uji/AUDIT_RIWAYAT.md`, `docs/uji/DAFTAR_PEKERJAAN_ULANG.md`, ROADMAP T1-38 & T11-13
- **Implikasi:** 1) `--uji-diri` ikut dijalankan di CI (mekanisme yang tak teruji = tak bisa dipercaya). 2) Setiap perubahan uang/keamanan/data pelanggan belum boleh `[x]` sebelum AUD-2. 3) Kalibrasi menyuntikkan cacat pada salinan HEAD dengan **kunci jawaban di luar repo**; hasilnya dicatat di `docs/uji/AUDIT_RIWAYAT.md`. 4) Batas jujur: 100% tidak bisa dijamin (studi inspeksi: ~58% deteksi pada tim terlatih) — karena itu lapisnya mesin + auditor + pemilik.

### [Fase 1/2026-09-17] AUD-0: pekerjaan T1-01…T1-10 yang dibatalkan keputusan keamanan wajib diulang
- **Area:** Role & Permission (ART-12) · Akses Perangkat (ART-11) · RLS (ART-1)
- **Keputusan:** Sebagian pekerjaan Fase 1 **dinggap batal & dikerjakan ulang** (bukan ditambal di tempat): kolom `pengguna_cabang.peran` dibongkar lewat migrasi **0011** (migrasi lama 0002 dibekukan, tidak disunting) · `izin_efektif()` ditulis ulang membaca `pengguna.peran` · uji `supabase/tes/izin.sql` §8 ("peran berbeda per cabang") **dibuang** karena menguji perilaku yang kini dilarang · fungsi identitas diperkuat pemeriksaan sesi/perangkat · policy tabel staf memakai `perangkat_sah()` · `percobaan_pin` digantikan `percobaan_masuk` (FK perangkat + jenis percobaan) dengan drop beralasan (belum ada data produksi) · fixture perangkat ditambahkan. Rincian per butir: `docs/uji/DAFTAR_PEKERJAAN_ULANG.md`.
- **Alasan:** permintaan pemilik — *"Bahkan sesi coding yang sebelumnya udh sempet kita mulai, klo itu perlu diulang karena berkaitan dengan perubahan ini, maka harus diulang."* Bukti audit dampak: 9 butir nyata (B.1–B.9) bertentangan dengan ART-11/ART-12, termasuk satu uji yang menguji kebalikan dari aturan baru.
- **File terkait:** `docs/uji/DAFTAR_PEKERJAAN_ULANG.md`, ROADMAP T1-37, `supabase/migrations/0011_peran_tunggal.sql`
- **Implikasi:** 1) T1-37 dikerjakan **bersamaan** dengan T1-23/T1-24/T1-26 (satu migrasi dapat menutup beberapa butir). 2) Matriks izin 10×5 wajib dijalankan sebelum & sesudah pembongkaran kolom. 3) Aturan baru: setiap keputusan keamanan memicu AUD-0 di hari yang sama.

### [Fase 1B/2026-09-17] `percobaan_pin` dihentikan, digantikan `percobaan_masuk`
- **Area:** Keamanan Akun (ART-12) · Akses Perangkat (ART-11)
- **Keputusan:** Tabel `percobaan_pin` (dibuat di 0006 dengan kolom `perangkat` berupa teks bebas) **digantikan** `percobaan_masuk`: kolom `perangkat_id` (FK ke `perangkat`), `jenis` (`pin`/`kata_sandi`/`mfa`), `berhasil`, `sebab`, waktu. Tabel lama **di-drop** pada migrasi 0014 (belum ada data produksi — proyek belum dipakai di kedai) dan namanya tidak dipakai lagi.
- **Alasan:** kolom teks bebas tidak bisa menegakkan "perangkat terdaftar" (ART-11) dan tidak bisa menampung percobaan masuk kata sandi/TOTP untuk peran berkuasa. Bila nanti ada data produksi, aturannya berubah: migrasi hanya boleh menambah tabel baru + memindahkan data, **tidak** menghapus.
- **File terkait:** `supabase/migrations/0014_percobaan_masuk.sql`, `supabase/tes/percobaan_masuk.sql`, `docs/uji/DAFTAR_PEKERJAAN_ULANG.md` butir B.6–B.8, ROADMAP T1-26
- **Implikasi:** 1) `verifikasi_pin` dan `alat/periksa-fungsi-pin.py` menyesuaikan. 2) Uji `tes/pin.sql` dijalankan ulang dengan perangkat nyata. 3) Catatan historis tetap ada di `DECISIONS_LOG.md` (tabel lama tidak hilang dari riwayat).

### [Sistem/2026-09-17] Mekanisme audit diperluas ke lingkup menyeluruh + buku pedoman induk dijaga mesin
- **Area:** tata kelola kualitas (mekanisme audit) · berkas untuk pengguna
- **Keputusan:** (1) AUD-3 memakai **lingkup menyeluruh**: `alat/audit-independen.py --paket AUD-3 --semua` mengelompokkan **seluruh berkas proyek** (17 grup, kode + dokumen + desain + berkas pengguna + CI; kumpulan skill pihak ketiga dikecualikan dengan alasan tertulis) dan laporan auditor **ditolak mesin** bila tidak memuat mode `menyeluruh`, ringkasan `Cakupan menyeluruh: X dari Y berkas`, satu baris bukti per grup, sub-bagian `### 1a. Berkas untuk pengguna`, atau cakupan < 90%. (2) **Berkas untuk pengguna = bagian lingkup audit**, diperiksa dengan cara pengguna (langkah bisa diikuti orang non-teknis? prompt bisa disalin apa adanya? ada rujukan/perintah mati? buku induk lengkap?). Langkah pengguna yang tidak bisa dijalankan apa adanya diperlakukan minimal **K-2**. (3) Buku pedoman pengguna `PANDUAN_PENGGUNA.md` dinaikkan menjadi **buku induk (manual book)** dan dijaga `alat/periksa-panduan.py` di CI (bagian A–H wajib ada · topik wajib · ≥10 mekanisme terdaftar · blok prompt wajib identik dengan sumber kanonik · semua rujukan berkas ber-backtick harus hidup kecuali ditandai "(rencana)"). (4) Gerbang fase = **`tahan_semua`**: K-1 **dan** K-2 menahan fase.
- **Alasan:** permintaan pemilik 2026-09-17 (putaran 4) — *"sekarang aku mau audit dulu"*; mekanisme harus *"bener-bener menyeluruh… termasuk file2 yang disiapkan untuk pengguna"*; dan *"satu file untuk pengguna yang betul-betul isinya lengkap… semacam manual book… termasuk mekanisme audit dan pemeriksaan, dan juga ada semua prompt yang dibutuhkan"*. Pilihan gerbang ditanyakan langsung ke pemilik; jawabannya `tahan_semua`.
- **File terkait:** `PANDUAN_PENGGUNA.md` (Bagian A–H), `alat/periksa-panduan.py`, `alat/audit-independen.py` (`--semua`, validator mode menyeluruh), `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §2b & §14, `docs/AGENT_OPERATING_GUIDE.md` §5 butir 4f + §7 DoD, `docs/PANDUAN_PEMILIK.md`
- **Implikasi:** 1) Setiap mekanisme/prompt baru **wajib** masuk buku induk di batch yang sama — kalau tidak, CI merah. 2) Audit menyeluruh memeriksa SELURUH berkas proyek dalam 17 grup; jumlah berkasnya **dihitung mesin saat paket dibuat** (jangan dikutip sebagai angka tetap di dokumen keadaan — prinsip C5/AT-16). 3) Buku yang basi tidak lagi bisa "lolos diam-diam"; rujukan mati langsung menahan CI. 4) Agent pembangun tetap **tidak bisa** mengaudit dirinya sendiri — sesi auditor dibuka pemilik, dicatat sebagai risiko sisa §14 butir 5. 5) Mesin juga menulis berkas **siap-tempel** (`<paket>-SIAP-TEMPEL.md`) supaya pemilik tidak perlu menggabungkan sendiri kalimat pembuka + paket.

### [Sistem/2026-09-17] Review PR independen + buku pedoman v2 + independensi base branch (putaran 5)
- **Area:** gerbang merge & mutu · berkas untuk pengguna · mekanisme audit
- **Keputusan:**
  1. **Review PR independen** dipasang sebagai mekanisme resmi (`docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` + `alat/review-pr.py` + `docs/uji/PROMPT_REVIEW_PR_INDEPENDEN.md`): tiga tingkat (RV-1 mesin/CI · RV-2 sesi peninjau independen · RV-3 kalibrasi), **jalur risiko** Merah/Kuning/Hijau menentukan kedalaman review, **5 syarat merge** (CI hijau pada commit PR · review independen selesai · K-1/K-2 tertutup · kalibrasi tidak gagal untuk Jalur Merah · Kartu Keputusan di tangan Lee), dan **Kartu Keputusan 7 baris** berbahasa manusia. Agent **tidak pernah** menekan merge dan tidak pernah meminta merge tanpa syarat lengkap.
  2. **Buku pedoman induk v2** (`PANDUAN_PENGGUNA.md`): Bagian B = **12 alur** berformat tetap (Apa ini · Kapan dipakai · Kalimat Lee · Langkah Lee · Yang agent lakukan · Bukti yang Lee terima · Lama · Kalau macet); **setiap blok prompt berlabel** `[LEE → AGENT]` / `[LEE → PENINJAU]`; Bagian E menjelaskan **fungsi + cara pakai + arti bila GAGAL** setiap perintah. Penjaga `alat/periksa-panduan.py` diperluas (12 alur, 8 bidang/alur, label prompt wajib, tabel perintah wajib, larangan sapaan "Bapak" kecuali dalam kalimat larangan).
  3. **Independensi base branch audit:** mesin menulis commit target + **LANGKAH 0** di paket; alat `--verifikasi-lingkup` memberi langkah pasti (cocok / beda-tetapi-ada → `checkout --detach` / tidak ada → berhenti & lapor). Lee bebas memilih base branch mana pun.
  4. **Panggilan:** agent memanggil **Lee**, bukan "Bapak" (masuk `PROFIL_PENGGUNA.md` sebagai aturan tetap).
  5. **Rekam pesan Lee** dikunci di `docs/teknis/REKAM_PESAN_PEMILIK.md`: semua permintaan (verbatim bila ada) + status, supaya tidak ada yang terlewat saat chat dihapus.
- **Alasan:** permintaan Lee 2026-09-17 putaran 5 — ia tidak bisa menilai *Files changed*; buku induk masih kurang/cacat; pertanyaan base branch peninjau; larangan sapaan "Bapak". Riset industri 2026 mendukung pola ini (reviewer AI = laporan + klasifikasi risiko, bukan pemberi approve; keputusan merge tetap manusia; kedalaman review mengikuti risiko; gerbang berbasis bukti pada commit yang akan masuk).
- **File terkait:** `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`, `alat/review-pr.py`, `docs/uji/PROMPT_REVIEW_PR_INDEPENDEN.md`, `docs/uji/REVIEW_PR_RIWAYAT.md`, `PANDUAN_PENGGUNA.md`, `docs/PANDUAN_PEMILIK.md`, `docs/teknis/REKAM_PESAN_PEMILIK.md`, `alat/audit-independen.py` (`--verifikasi-lingkup`), ROADMAP T0-13/T0-14
- **Implikasi:** 1) Setiap PR wajib melewati RV-2 sebelum dimintakan merge — kalau tidak, PR tidak boleh dimintakan. 2) Laporan peninjau tanpa bukti ditolak mesin (bukan dinegosiasikan). 3) Jalur Merah menambah syarat bukti (mutasi + rencana pemulihan) — memperlambat PR berisiko, dan itu disengaja. 4) Buku induk kini bisa menahan CI bila kehilangan alur/label/penjelasan. 5) Bahan kalibrasi tidak boleh memuat penanda pembocor (cacat mekanisme #8) — diperiksa sebelum bahan diserahkan.

### [Sistem/2026-09-17] Hasil AUD-3 diperiksa: 3 cacat mekanisme ditutup + temuan auditor diverifikasi ulang (putaran 6)
- **Area:** tata kelola kualitas (audit) · keamanan (temuan menunggu perbaikan)
- **Keputusan:**
  1. **Jalur pulang laporan dipakai sungguhan & bekerja:** 2 dari 3 sesi auditor mengirim lewat push laporan-tunggal; sesi kerja menariknya dengan `--ambil-laporan` (bukan menyalin dari chat).
  2. **Tiga cacat mekanisme ditutup (ditemukan oleh pemakaian nyata, bukan teori):** #9 nama berkas bentrok antar sesi → nama bentrok disimpan **terpisah** sebagai `<nama>.dari-<cabang>.md`, tidak pernah menimpa, dan prompt meminta **penanda sesi** di nama berkas; #10 pemeriksa menolak laporan **sah** → syarat bagian 8 kini **sadar-versi** (dicek dari commit yang diaudit) dan cek kebersihan memakai **bukti dari cabang auditor** (“hanya menambah berkas laporan”), bukan `git status` meja kerja sesi kerja; #11 kunci kalibrasi jalur auditor hidup di `/tmp` → dibangun ulang dari bahan & dicatat risikonya.
  3. **Temuan auditor tidak dipercaya begitu saja:** sesi kerja menjalankan **9 pemeriksaan eksekusi** (`docs/uji/audit/bukti-verifikasi-2026-09-17.sql`) yang membuktikan cacat-cacat terpenting benar ada pada tip; setelah diperbaiki, berkas itu **wajib pindah** ke `supabase/tes/` dengan harapan dibalik.
  4. **Lingkup commit audit:** laporan menunjuk `442913e`; berkas aplikasi/skema tidak berubah sesudahnya, jadi temuan berlaku untuk tip — tetapi audit ulang kecil tetap dijadwalkan setelah perbaikan.
- **Alasan:** permintaan Lee *“Laporan audit sudah masuk, periksa”*; aturan Lee sebelumnya: temuan yang perlu dilaporkan tetap dilaporkan biarpun di luar cakupan, lantai minimum bukan target, dan tidak menyusun laporan demi lolos pemeriksa.
- **File terkait:** `alat/audit-independen.py`, `alat/review-pr.py`, `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §5c, `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`, `docs/uji/AUDIT_RIWAYAT.md` §1/§1a/§4, `docs/uji/audit/bukti-verifikasi-2026-09-17.sql`, `docs/uji/audit/LAPORAN_AUD-3_2026-09-17_menyeluruh.md` + `.dari-01a0aeb0.md`
  5. **Anomali sesi paralel (temuan Lee):** tiga sesi audit dibuka berbarengan, tetapi dua di antaranya bekerja di **satu cabang yang sama** dengan **nama berkas yang sama** → laporan pertama tertimpa dan hanya hidup di riwayat commit. Laporan itu **diselamatkan** dan dinyatakan **tidak sah untuk putusan** (sesinya tidak menerima paket/commit target). Penarik laporan diperbaiki agar menelusuri **seluruh riwayat** cabang. Kesimpulan: **semua hasil sesi yang sah sudah masuk** — tidak perlu menagih sesi ketiga.
- **Implikasi:** 1) Perbaikan K-1/K-2 menjadi pekerjaan berikutnya (gerbang `tahan_semua`) — didahulukan sebelum Fase 1C/1B. 2) Setiap perbaikan wajib menambah uji merah-di-awal di `supabase/tes/` agar cacat tidak bisa kembali. 3) Sesi auditor ke-3 yang belum mengirim **tidak menahan** perbaikan (dua laporan sudah sepakat pada cacat terberat dan sudah diverifikasi mesin); laporannya tetap diterima bila menyusul. 4) Laporan auditor kini **diakui hanya bila** kontraknya lolos + kalibrasinya lulus — bukan karena “kelihatan serius”.

### [Keamanan/2026-09-17] Perbaikan temuan K-1 audit AUD-3: uang tidak boleh masuk sebelum total pasti + isolasi lintas resto pada pintu fungsi
- **Area:** keamanan (uang & isolasi penyewa) · migrasi 0006 & 0010
- **Keputusan:**
  1. **Pembayaran ditolak selama total pesanan belum dihitung.** Sebelumnya pemeriksaan "tidak boleh melebihi total" **dilewati** bila `total` masih 0; karena `hitung_total` (T1-15) belum ada, SEMUA pesanan bertotal 0 → berapa pun uangnya diterima, dan baris uang tidak bisa diubah/dihapus (tidak ada jalan pemulihan). Sekarang `picu_pembayaran_jujur` menolak dengan pesan "Total pesanan belum dihitung". Konsekuensi yang disengaja: alur kasir belum bisa mencatat uang sampai T1-15 — **lebih baik uang tidak tercatat daripada tercatat di atas angka yang belum pasti.**
  2. **`total_dibayar(uuid)` tidak lagi bocor lintas resto.** Fungsi SECURITY DEFINER melewati RLS, jadi ditambah saringan keterlihatan `auth.uid() is null or pesanan_sepenyewa(...)`. **Pelajaran penting:** jangan memakai `peran_peladen()` di dalam fungsi SECURITY DEFINER — `current_user` di sana adalah pemilik fungsi, sehingga jawabannya selalu "peladen" dan penjaganya buta (kebocoran tetap terjadi sampai uji menangkapnya); yang dipakai adalah identitas pemanggil dari token.
  3. **Pintu izin pegawai lain ditutup untuk klien.** `izin_efektif_untuk()` & `boleh_untuk()` (menjawab "apa izin ORANG LAIN") dicabut dari peran `authenticated` (kini hanya `service_role`), **dan** di dalamnya ditambah pemeriksaan penyewa. Aplikasi tetap memakai `izin_efektif()`/`boleh()` untuk DIRI SENDIRI; gerbang persetujuan PIN berjalan di peladen.
- **Alasan:** audit AUD-3 (dua laporan independen, keduanya TERKALIBRASI) menemukan tiga cacat **K-1**; sesi kerja memverifikasi ulang dengan eksekusi sebelum memperbaiki (gerbang `tahan_semua`, permintaan Lee 2026-09-17).
- **File terkait:** `supabase/migrations/0006_pin.sql`, `supabase/migrations/0010_pembayaran.sql`, `supabase/tes/gerbang_uang.sql` (baru), `supabase/tes/isolasi_lintas_penyewa.sql` (baru), `docs/uji/audit/bukti-verifikasi-2026-09-17.sql`, `docs/uji/AUDIT_RIWAYAT.md` §1b
- **Implikasi:** 1) Uji baru **wajib merah dulu** sebelum perbaikan (dibuktikan: `12 LULUS` sesudah, sedangkan sebelumnya 2 uji itu GAGAL). 2) T1-15 (`hitung_total`) kini menjadi **penentu**: alur pembayaran baru bisa dipakai setelah total dihitung peladen. 3) Setiap fungsi SECURITY DEFINER baru wajib punya saringan keterlihatan sendiri — RLS tidak melindunginya. 4) Temuan K-2 (PIN, jejak pelaku, status pesanan, diskon persen, penjaga stok, hak kolom `pin_hash`) masih terbuka dan menjadi batch berikutnya.

### [Produk/2026-09-17] Bahasa aplikasi: rencana multi-bahasa (Indonesia · Inggris · Mandarin · Arab) — MENUNGGU KEPUTUSAN LEE
- **Area:** produk (lingkup rilis) · teknis (fondasi teks) · berkas untuk pengguna
- **Permintaan Lee (2026-09-17, disampaikan saat batch K-2 berjalan):** aplikasi mendukung **multi-bahasa, termasuk Mandarin dan Arab**; kalau berat di awal, setidaknya rilis awal mendukung **2 bahasa: Inggris + Indonesia**.
- **Analisis (jawaban jujur atas "berat atau tidak"):**
  1. **Menambah bahasa TIDAK berat**, asalkan dilakukan dengan cara yang benar sejak awal: tidak ada satu pun kalimat yang ditulis langsung di dalam layar — semua teks UI diambil dari berkas bahasa (`aplikasi/src/bahasa/id.ts` *(rencana T1-40)* sebagai sumber, lalu `en.ts`, `zh.ts`, `ar.ts`). Biaya per bahasa = menerjemahkan kumpulan kalimat itu + menguji tampilannya; tidak menyentuh logika aplikasi. *(rencana: nama berkas saat keputusan dibuat — nama final bisa berbeda)*
  2. **Yang benar-benar berat adalah menyisipkannya BELAKANGAN**: menyapu ratusan kalimat yang sudah tertanam di layar. Karena layar G1 belum ditulis (Fase 1C), **sekarang justru waktu termurah** — kuncinya dibeli sekarang, dipakai mulai layar pertama.
  3. **Arab (RTL) menuntut kerja tambahan, bukan sekadar terjemahan:** tata letak harus bercermin (arah, ikon, bilah gulir), dan itu harus dirancang sejak awal. Diperkirakan menambah sekitar 10–15% pekerjaan UI G1 kalau dikerjakan sekarang, jauh lebih mahal bila ditambal belakangan.
  4. **Mandarin punya masalah huruf tersendiri:** berkas huruf Mandarin jauh lebih besar (ribuan karakter) sehingga harus dipotong ke karakter yang benar-benar dipakai ("subset") supaya tidak memberatkan perangkat kedai, dan aturan penskalaan huruf tetap dipakai.
  5. **Yang TIDAK diterjemahkan (penting, tidak boleh salah):** (a) **format uang & tanggal** mengikuti aturan Indonesia (`Rp`, `id-ID`); (b) **isi database** — nama menu, nama pegawai, catatan stok — adalah data kedai, bukan terjemahan (nama menu bisa berbahasa apa pun yang diketik kedai); (c) **struk** dicetak sesuai bahasa yang dipilih kedai; (d) **dokumen internal proyek & pesan audit** tetap Indonesia (dibaca Lee & agent).
  6. **Pilihan bahasa wajib bisa diatur per pengguna** (kasir asing memakai Inggris, owner memakai Indonesia di perangkatnya sendiri) **dan punya bawaan per resto** untuk perangkat bersama.
- **Usulan (keputusan Lee diminta):** **(Opsi 1 — rekomendasi)** G1 sejak awal memakai fondasi multi-bahasa + 3 bahasa rilis: **Indonesia · Inggris · Mandarin**; **Arab disiapkan kuncinya dan diverifikasi layoutnya (RTL) di G1 tetapi teksnya menyusul di G2**. Rincian: kerangka i18n + berkas `id/en/zh` + dua layar contoh RTL + pemeriksa otomatis "tidak ada teks keras di komponen" (gagal → CI merah) pada Fase 1C. **(Opsi 2)** rilis awal 2 bahasa (ID+EN) saja; Mandarin & Arab di G2. **(Opsi 3)** keempat bahasa sekarang (biaya UI ~10–15% lebih besar di G1).
- **Alasan:** pertanyaan Lee *"apakah itu berat di awal atau tidak"* — jawabannya "tidak, kalau pondasinya dibeli sekarang; ya, kalau ditambal belakangan", dan biaya RTL/subset huruf Mandarin perlu diketahui Lee sebelum memutuskan lingkup G1.
- **Implikasi:** 1) **Belum ada tugas Fase 1C yang dikerjakan**, jadi rencana ini bisa masuk sebelum T1-31 dimulai — tidak ada pekerjaan yang dibuang. 2) Tugas baru yang disiapkan (setelah Lee memilih): **T1-40 kerangka bahasa** (berkas terjemahan + pengalih bahasa + larangan teks keras), **T1-41 RTL & subset huruf**, lalu penyesuaian `docs/SPESIFIKASI_UI.md` (bagian bahasa) dan buku induk. 3) Setiap bahasa baru setelah rilis = satu berkas terjemahan + satu baris pemeriksa, bukan proyek baru.
- **KEPUTUSAN LEE (2026-09-17, hari yang sama):** memilih **Opsi 1** — rilis G1 memakai **Indonesia · Inggris · Mandarin**; **Arab** disiapkan (berkas kunci + tata letak RTL diuji di G1), teksnya menyusul di **G2**. Dasar: menghindari +10–15% kerja UI di rilis pertama tanpa membuang persiapan; seluruh biaya bahasa masuk sebelum layar G1 ditulis.
- **Tindak lanjut yang sudah dikunci bersamaan:** ROADMAP **+T1-40** (kerangka bahasa: berkas terjemahan, pengalih bahasa per pengguna + bawaan per resto, pemeriksa "tidak ada teks keras", format uang/tanggal tetap `id-ID`) dan **+T1-41** (RTL: token arah + 2 layar contoh bercermin; subset huruf Mandarin dengan ambang ukuran diperiksa mesin) → **189 tugas**; `docs/SPESIFIKASI_UI.md` **§10** ditulis (bahasa & arah teks). Keduanya wajib **sebelum** layar G1 pertama (Fase 1C) supaya tidak ada pekerjaan yang terbuang.
- **Status:** **DIPUTUSKAN (Opsi 1)** — pelaksanaan menunggu urutan Fase 1C (setelah perbaikan temuan audit selesai).

### [Keamanan/2026-09-17] Perbaikan temuan K-2b audit AUD-3: persetujuan void, status pesanan, penjaga stok
- **Area:** keamanan (alur persetujuan & integritas status/stok) · migrasi 0006, 0007, 0009, 0010
- **Keputusan:**
  1. **Persetujuan void sesudah dapur wajib TERBUKTI dengan PIN.** Sebelumnya pemicu hanya memeriksa bahwa penyetuju itu **berwenang** (`boleh_untuk`), bukan bahwa ia **menyetujui** — kasir bisa menuliskan nama owner sebagai penyetuju tanpa owner menyentuh perangkat. Sekarang wajib ada catatan PIN **benar**, **untuk aksi itu** (`void_sesudah_dapur`), dan **baru saja** (jendela 5 menit); buktinya diambil dari `percobaan_pin` yang tidak bisa ditulis klien. Kolom `aksi` ditambahkan ke `percobaan_pin` supaya bukti terikat pada tindakan yang disetujui.
  2. **Perpindahan status pesanan diatur per peran & hanya lewat jalur resmi** (TECH_SPEC §4.3): `draf → dikirim` (owner/admin/kasir/pelayan, wajib menyertakan waktu kirim), `dikirim → dimasak → siap` (owner/admin/dapur); **`lunas` dan `batal` hanya boleh ditetapkan peladen** (setelah uangnya benar-benar masuk / lewat jalur pembatalan). Tanda `dikirim_ke_dapur_pada` **tidak boleh dihapus** klien — kalau boleh, pembatalan sesudah dapur bisa "diturunkan" jadi sebelum dapur dan lolos tanpa persetujuan.
  3. **Penjaga saldo stok tidak lagi memakai penanda sesi.** Versi lama memakai `current_setting('app.stok_dari_buku_besar')` yang bisa dipasang klien sendiri (`set_config`), sehingga dapur bisa menulis angka stok berapa pun tanpa baris buku besar. Penggantinya: bukti peladen yang tak bisa dipalsukan klien (`peran_peladen()`), dan **fungsi penjaganya tidak boleh SECURITY DEFINER** (kalau definer, `current_user` = pemilik fungsi → selalu "peladen" → buta).
- **Alasan:** tiga temuan **K-2** dari audit AUD-3 (dua laporan independen); sesi kerja memverifikasi ulang lewat eksekusi sebelum memperbaiki (gerbang `tahan_semua`).
- **File terkait:** `supabase/migrations/0006_pin.sql`, `0007_katalog.sql`, `0009_pesanan.sql`, `0010_pembayaran.sql`, `supabase/tes/persetujuan_void.sql` (baru), `supabase/tes/status_pesanan.sql` (baru), `supabase/tes/penjaga_stok.sql` (baru), `supabase/tes/pembayaran.sql` (uji lama ikut aturan baru), `docs/uji/AUDIT_RIWAYAT.md` §1b
- **Implikasi:** 1) **Seluruh temuan K-1 & K-2 audit AUD-3 TUNTAS** (gerbang `tahan_semua` terpenuhi untuk kelas berat). 2) Alur void di layar nanti wajib meminta PIN penyetuju **di perangkat yang sama** sebelum mengirim pembatalan — sudah tertulis di spesifikasi; T1-15/`terima_bayar` kelak memakai jalur peladen untuk menetapkan `lunas`. 3) Pola wajib untuk penjaga baru: fungsi penjaga **tanpa** `security definer`, dan bukti dari sumber yang tak bisa ditulis klien (`auth.uid()`, hak pemilik tabel, atau catatan resmi seperti `percobaan_pin`). 4) Sisa temuan K-3/K-4 audit masuk daftar tertangguh/pekerjaan berikutnya.

### [Keamanan/2026-09-17] Temuan F-11 (lapis kedua pembatasan PIN) — dikunci uji sekarang, mekanismenya di Fase 1B
- **Area:** keamanan (PIN & perangkat) · tingkat **K-3** (mengikuti laporan audit B §F-11; sebelumnya tercatat K-2, dikoreksi)
- **Keputusan:** temuan *"12 kali salah per perangkat"* tidak bisa diperbaiki sekarang karena **identitas perangkat belum bisa dipercaya** — `p_perangkat` datang dari klien, dan perangkat terdaftar baru ada di Fase 1B (T1-24). Karena itu:
  1. **Yang memang benar hari ini dikunci uji** `supabase/tes/percobaan_pin_perangkat.sql`: memutar nama perangkat tidak menambah jatah (batas akun 5×/15 menit tetap), hasilnya sama dengan nama perangkat tetap, dan lapis perangkat masih hidup **saat namanya jujur** (percobaan ke-13 ditolak) — supaya "memperbaiki" F-11 dengan menghapus lapis kedua tidak lolos. Dua uji mutasi memerah (batas akun dimatikan · lapis perangkat dihapus).
  2. **Pagar wajib:** T1-24 harus memakai `perangkat_id` terverifikasi, menolak perangkat tak terdaftar, lalu **memperketat** uji itu (bagian 1 → 0 percobaan dilayani) dan menutup baris F-11 di `docs/uji/AUDIT_RIWAYAT.md` §1b. Ditulis di DoD/Verifikasi T1-24.
  3. **Klaim berlebih dikoreksi:** `docs/KEAMANAN.md` §4 & ROADMAP T1-06 kini menyebut dengan jujur bahwa lapis kedua baru berlaku setelah perangkat terdaftar; batas aman yang berlaku sekarang = **5×/15 menit per akun**.
  4. Butir ini **tidak** dimasukkan `docs/TERTANGGUH.md`: TERTANGGUH untuk hal yang menunggu keputusan pemilik, sedangkan ini pekerjaan terjadwal yang bisa ditutup dengan bukti (pemeriksa fondasi menandai butir tanpa tugas penunggu sebagai temuan — aturan itu dipatuhi, bukan dilonggarkan).
- **Alasan:** menebak PIN butuh akun pegawai sah + 480 percobaan/hari dibatasi batas akun; memperbaiki sebagian dengan menambah heuristik baru = perubahan kontrol keamanan tanpa persetujuan pemilik (dilarang msg 16) → ditunda ke fase yang memang membangunnya.
- **File terkait:** `supabase/tes/percobaan_pin_perangkat.sql`, `docs/KEAMANAN.md` §4, `docs/ROADMAP.md` T1-06 & T1-24, `docs/uji/AUDIT_RIWAYAT.md` §1b
- **Implikasi:** batas aman PIN hari ini = batas per akun; penyerang yang memutar nama perangkat tidak mendapat keuntungan pada lapis akun; F-11 tetap TERBUKA sampai T1-24 dan tidak boleh ditutup tanpa memperketat uji tersebut.

### [Keamanan/2026-09-17] T1-23 — Peran tunggal (migrasi 0011) & PIN 6 angka yang unik dan kuat
- **Area:** Role & Permission (ART-12) · kredensial PIN · RLS (ART-1) · migrasi `0011_peran_tunggal.sql`
- **Keputusan:**
  1. **Peran per cabang dibongkar lewat migrasi BARU 0011** (0002 & 0005 dibekukan, tidak disunting — sesuai keputusan AUD-0). `pengguna_cabang.peran` dihapus; tabel itu tinggal daftar cabang. Peran tunggal hidup di `pengguna.peran` dan berlaku di **semua** cabang akun itu.
  2. **Penjaga keanggotaan baru** (`picu_jaga_keanggotaan_cabang`): akun & cabang wajib satu resto; pemilik platform tidak boleh didaftarkan ke cabang. Catatan jujur: pemicu tidak bisa "menolak peran kedua" secara literal karena kolomnya sudah tidak ada — penegakannya **struktural** (kolom hilang) + penjaga keanggotaan ini.
  3. **`izin_efektif()` ditulis ulang** di 0011: peran dari `pengguna.peran`; bila cabang disebut, pemanggil tetap harus **anggota** cabang itu (kecuali owner pusat) dan cabang asing tetap DITOLAK, bukan jatuh ke peran se-resto.
  4. **PIN wajib tepat 6 angka** (dulu 4–6) dan **bukan pola lemah** — daftar pola di fungsi baru `pin_lemah()`: semua digit sama · deret naik/turun · blok berulang 2/3 digit · pasangan berurutan (112233) · berbentuk tanggal (ddmmyy). Daftar ini sengaja pendek & bisa dibaca ulang, bukan daftar hitam panjang.
  5. **PIN wajib UNIK antar pegawai satu resto** (bukan lintas resto — supaya angka PIN resto lain tidak bisa dibocorkan lewat pesan penolakan). Perbandingan memakai hash (bcrypt) yang sudah ada, jadi tidak ada PIN tersimpan dua kali.
  6. **Pembatas anti-oracle (baru):** uji keunikan menjawab ya/tidak, dan penyerang yang memegang satu akun sah bisa memakainya sebagai alat ukur (ia tahu PIN-nya sendiri, jadi selalu lolos syarat "PIN lama"). Karena itu setiap percobaan pemasangan dicatat di tabel baru **`percobaan_simpan_pin`** (RLS + policy menolak semua; tidak ada hak klien) dan dibatasi **20 kali / 15 menit** per akun.
  7. **CARA MENOLAK yang wajib tercatat = PESAN, bukan exception.** Ditemukan saat menguji pembatas ini: `raise exception` (atau exception yang ditangkap pemanggil) memakai savepoint dan **membatalkan baris catatan di transaksi yang sama** — pembatas jadi tidak pernah menyala. Kontrak `simpan_pin` karena itu: `'PIN tersimpan.'` = berhasil; pesan lain ('PIN itu sudah dipakai…' / 'Terlalu banyak…') = ditolak **dan tercatat**; exception hanya untuk kesalahan pemakaian/izin (format PIN, tanpa izin, PIN lama salah).
  8. Edge Function `verifikasi_pin` ikut menolak bentuk selain 6 angka; TECH_SPEC §4 diselaraskan (`pengguna` tanpa `pin_hash`, tambah baris `kredensial_pin` & `percobaan_simpan_pin`, `percobaan_pin` bertambah kolom `aksi`).
- **Alasan:** (a) satu orang dua fungsi = dua akun (keputusan pemilik 2026-09-17) hanya tegak kalau wewenang tidak bisa berbeda per cabang; (b) PIN 4 angka hanya 10.000 kemungkinan — dengan batas 5/15 menit pun masih bisa ditebak dalam hitungan hari, sedangkan PIN 6 angka memindahkan masalah itu ke "tidak praktis"; (c) keunikan PIN tanpa pembatas justru membuat PIN lebih mudah dicuri; (d) catatan yang hilang karena exception adalah kelas cacat yang sama dengan "bukti audit yang tidak pernah tersimpan".
- **File terkait:** `supabase/migrations/0011_peran_tunggal.sql`, `supabase/tes/peran_tunggal.sql` (baru), `supabase/tes/pin_batas_pasang.sql` (baru), `supabase/tes/kredensial_pin.sql`, `supabase/tes/izin.sql` §8, `supabase/tes/pin.sql`, `supabase/functions/verifikasi_pin/index.ts`, `alat/sql/data-uji.sql`, `docs/TECH_SPEC.md` §4, `docs/uji/DAFTAR_PEKERJAAN_ULANG.md` B.1–B.3
- **Implikasi:** 1) 6 uji mutasi memeredam gerbang ini (peran per cabang hidup lagi · keanggotaan diabaikan · pola lemah mati · keunikan mati · pembatas mati · format verifikasi kembali 4–6) — satu mutasi awalnya lolos dan memaksa uji baru di jalur verifikasi. 2) Layar PIN (Fase 1C/2) harus menampilkan **teks yang dikembalikan** `simpan_pin` sebagai pesan gagal, bukan hanya menunggu error. 3) T1-24 tetap wajib menolak perangkat tak terdaftar; keunikan PIN kini menutup "PIN dibagikan antar pegawai". 4) Setiap penolakan baru yang wajib tercatat harus memakai pola **pesan**, bukan exception.


### [Mekanisme/2026-09-17] Verifikasi permintaan pemilik, daftar temuan per temuan & tiga penjaga baru
- **Area:** mekanisme kerja (bukan fondasi produk) · `docs/uji/AUDIT_RIWAYAT.md` §1b · `alat/periksa-temuan-audit.py` · `alat/periksa-rujukan.py`
- **Keputusan:**
  1. **Daftar temuan audit wajib per temuan** (bukan gelondongan): setiap temuan kedua laporan punya baris; `DITUTUP` wajib menunjuk bukti yang ada di repo; `TERBUKA` wajib menunjuk tugas ROADMAP. Dijaga mesin (`alat/periksa-temuan-audit.py`, 3 uji mutasi).
  2. **Rujukan di dokumen pengikat dijaga mesin** (`alat/periksa-rujukan.py`): rujukan berkas harus hidup atau ditandai rencana + tugas. Menutup temuan A-F-08/B-F-08 (3 rujukan mati ditemukan: alat denyut, berkas catatan pemulihan, pemeriksa rantai audit).
  3. **Kerentanan dependency = 0 toleransi**: vitest dinaikkan ke 5.0.1 (dari 5 kerentanan dev, 1 kritis → 0) dan `npm audit --audit-level=low` masuk CI. T1-30 akan memperluas ke rahasia + keamanan SQL.
  4. **Penjaga buku induk**: `MIN_ALUR` = jumlah nyata (12) dan mode `--uji-diri` (3 mutasi: alur dihapus · label prompt hilang · sapaan "Bapak").
  5. **Akun/proyek Supabase pemilik dicatat** sebagai butir tunggu `T-018` + tanda ❓ pada `T0-00`.
  6. **Dua permintaan Lee dijadwalkan**: T1-42 (bantuan kontekstual di setiap laman — satu sumber dengan registri aksi, batas 5 langkah) · T1-43 (Buku Uji Pemilik: dua bagian [yang harus Lee lakukan / yang harus Lee coba], kolom langkah–harapan–hasil–catatan, ditulis bertahap + diringkas di chat, dijaga pemeriksa) · T1-44 (perketat paket audit: lingkup dari commit target, hitungan mesin, CI wajib hijau).
- **Alasan:** Lee meminta pembuktian bahwa permintaan lamanya benar-benar dikerjakan, bukan hanya disimpan. Verifikasi menemukan 6 cacat ketertelusuran — kelas cacat yang paling berbahaya justru karena tidak terlihat (temuan hilang, rujukan menyesatkan, klaim tanpa bukti).
- **Catatan jujur (untuk Lee):** 6 temuan audit masih **terbuka** dan punya tugas: A-F-07 → `T1-24`…`T1-30`; B-F-09/B-F-16/B-F-17 → `T1-44`; B-F-11 → `T1-24`; B-F-14 → `T1-22`. Tidak ada satu pun yang dianggap selesai tanpa bukti.
- **File terkait:** `docs/uji/AUDIT_RIWAYAT.md`, `docs/ROADMAP.md` (T1-42…T1-44), `docs/SPESIFIKASI_UI.md` §5, `docs/teknis/BUKU_INSIDEN.md`, `docs/KEAMANAN.md` §10, `docs/TERTANGGUH.md`, `aplikasi/package.json`, `.github/workflows/ci.yml`, `PANDUAN_PENGGUNA.md`


### [UI/2026-09-17] Cacat "kontrol mati" Nyaman/Padat + daftar tema + lembar kunci pemilik
- **Area:** tampilan (kerapatan & tema) · mekanisme penjaga (pemeriksa baru) · rahasia lokal
- **Laporan Lee:** *"aku cuma liat ada 5 theme doang"* dan *"tombol bertulisan 'Nyaman' dan 'Padat' … waktu aku klik dan switch ga ada efek apa apa. Pastikan berfungsi."*
- **Temuan (diverifikasi, bukan dugaan):**
  1. **Kerapatan memang mati di aplikasi.** Aturan `[data-density="padat"]` hanya menyasar `.kisi-menu`/`.menu-kartu` — kelas yang **hanya ada di prototipe**, tidak dipakai layar aplikasi. Jadi tombol mengubah atribut `<html data-density>` tetapi tak satu pun komponen aplikasi bereaksi. Kelas cacat yang sama dengan "tombol kurang" yang dikhawatirkan Lee: **kontrol yang terlihat hidup tetapi tidak berefek**.
  2. **Uji lama tidak bisa menangkapnya**: uji hanya memastikan tombol **dirender**, bukan bahwa tombol **bekerja** (tidak ada uji interaksi, tidak ada uji CSS).
  3. **10 tema sebenarnya ada** di kode (dan tombolnya berbunyi "Ganti tema (10)"), tetapi panelnya bisa terpotong di layar kecil dan tidak memberi petunjuk bahwa daftarnya bisa digeser — itulah kenapa terlihat hanya 5.
- **Perbaikan (catatan jujur: percobaan pertama agent SALAH TEMPAT dan ditangkap penjaga sendiri).** Agent mula-mula menambal `aplikasi/src/gaya/token/tema.css`. Penjaga struktur (`aplikasi/alat/periksa-struktur.py`) menolak: *"token aplikasi BERBEDA dari prototipe/css/tokens.css (Fase 0 wajib salinan apa adanya)"*. Benar — sumber desain ada di **prototipe**, aplikasi hanya salinan. Perbaikannya lalu dilakukan di `prototipe/css/tokens.css` (sumber) dan disalin apa adanya ke aplikasi.
  1. Kerapatan kini **mengubah token jarak** (`--s-1…--s-10`) sehingga seluruh halaman memadat, ditambah aturan untuk kelas aplikasi (`.card`, `.kisi-2`, `.table`, `.baris-tombol`, `.pemisah`, `.baris-rapat`). **Huruf tidak dikecilkan** (keterbacaan + daerah sentuh 44 px dijaga).
  2. Layar contoh menampilkan **status kerapatan aktif** + kartu "Kerapatan tampilan" berisi baris contoh, supaya efeknya terlihat mata.
  3. Panel tema diberi keterangan jumlah + cara menggeser daftar.
  4. **Penjaga baru `aplikasi/alat/periksa-kerapatan.py`** (3 uji mutasi): token padat wajib mengecil secara terukur, dan aturan kerapatan **dilarang menyasar kelas yang tidak dipakai aplikasi** (persis akar cacat ini).
  5. **Uji interaksi baru** `aplikasi/src/layar/contoh/kerapatan.test.tsx` (5 uji): klik Padat/Nyaman mengubah `<html data-density>`, tersimpan, dan bertahan saat dibuka ulang; memilih tema juga.
  6. **Uji kaskade baru** `aplikasi/src/gaya/kerapatan-css.test.ts` (6 uji, Vitest `css: true`): memasang berkas gaya NYATA lalu **mengukur angka** — padding kartu 20 px → 12 px, sel tabel mengecil, baris contoh mengecil, **huruf tetap sama**, warna tidak berubah; dan **kesepuluh tema terbukti berbeda** (bukan 10 label untuk 5 tampilan). Jumlah uji aplikasi: 51 → **63**.
- **Lembar kunci pemilik:** formulir `docs/ops/DAFTAR_KUNCI_PEMILIK.template.md` (ikut Git, selalu kosong) + berkas kerja terisi bernama DAFTAR_KUNCI_PEMILIK.local.md (dibuat atas permintaan Lee) — berkas kerja itu **tidak pernah masuk Git** (pola `*.local.md`), berisi 7 baris akun/alamat + 6 baris kunci rahasia + 6 baris persiapan Lee. Penjaga `alat/periksa-rahasia.py` (3 uji mutasi: kunci palsu · .gitignore longgar · formulir hilang) menahan: kunci bertekanan tinggi di berkas terlacak, dan berkas rahasia yang ikut ter-commit. Nilai rahasia **tidak lewat chat**; rotasi seluruh kunci sebelum rilis (rencana Lee). **Cacat CI 2026-09-17 (ditemukan langkah CI, bukan oleh mata):** enam dokumen sempat menulis rujukan ber-backtick ke berkas kerja yang tidak ikut Git → di salinan bersih (clone/CI) rujukan itu menggantung. Perbaikan: rujukan diarahkan ke formulir, berkas kerja ditulis tanpa backtick, dan penjaga baru `alat/periksa-bersih.py` menguji dokumen di pohon bersih (hanya berkas terlacak) supaya cacat kelas ini tertangkap di komputer sendiri, bukan baru di CI.
- **File terkait:** `prototipe/css/tokens.css` (**sumber desain** — perbaikan nyata ada di sini) → salinan apa adanya ke `aplikasi/src/gaya/token/tema.css`, `aplikasi/src/gaya/komponen.css`, `aplikasi/src/layar/contoh/LayarContoh.tsx`, `aplikasi/src/layar/contoh/kerapatan.test.tsx`, `aplikasi/alat/periksa-kerapatan.py`, `alat/periksa-rahasia.py`, `alat/periksa-bersih.py`, `docs/uji/BUKU_UJI_PEMILIK.md`, `docs/ops/DAFTAR_KUNCI_PEMILIK.template.md`, `.gitignore`, `.github/workflows/ci.yml`

### [UI/2026-09-17] Kerapatan dua-sumbu · cara menutup panel (disclosure) · jejak pudar tepi gulir · kemampuan desain disimpan

- **Area:** tampilan (kerapatan, panel pemilih, daftar yang bisa digeser) · mekanisme (kemampuan tersimpan + penjaga baru)
- **Laporan Lee (pesan ke-32):** *"blok blok nya hanya berkurang panjang nya aja, tapi lebar (atas-bawah) nya ga ikut mengecil"* ·
  *"Kamu kan punya skill-skill. Kamu harus maksimalkan skill skill itu. Atau klo kamu ga menemukan itu di skill-skill kamu, kamu harus pelajari ilmu desain dan visual dari internet
  dan simpan hasil yang kamu pelajari itu untuk menjadi kemampuan. Dan ingat, jangan hanya disimpan, tapi juga harus digunakan sebagai kemampuan"* ·
  *"(panel) harus bisa ditutup dengan Esc / klik di luar… coba pelajari bagaimana umumnya aplikasi-aplikasi lain"* ·
  *"ujung nya itu kayak nabrak gitu… semacam blur/feather"*.
- **Keputusan 1 — kerapatan mengubah TINGGI, bukan lebar, dan huruf tidak dikecilkan.** Sumber: Material 3 *Density* (**tiap langkah −4 dp tinggi; jarak mendatar
  di dalam komponen tidak berubah; huruf tidak ikut mengecil; sasaran sentuh tetap dijaga; jarak tata letak justru boleh ditambah**) + Cloudscape *content density*
  (padat = padding vertikal + jarak; popover/daftar pilihan hanya dipadatkan sebagian). Token dipisah **per sumbu**: `--tinggi-kendali` 48→44 ·
  `--tinggi-baris-tema` 56→48 · `--pad-v-blok` 20→12 · `--baris-isi` 1,55→1,42; `--pad-h-blok`/`--pad-h-kendali`/`--pad-h-sel` **dikunci sama dengan mode Nyaman**.
  Lantai sentuh **44 px** tetap (WCAG 2.5.5 AAA & Apple HIG 44 pt). Salah kaprah lama (dipadatkan hanya kiri-kanan) resmi ditinggalkan.
- **Keputusan 2 — menutup panel mengikuti pola *disclosure* WAI-ARIA APG, bukan `<details>` bawaan.** Ditemukan sebabnya: `<details>` memang **tidak** menutup saat Esc.
  Yang benar: **Esc menutup DAN mengembalikan fokus** ke tombol · klik di luar menutup (fokus tidak dirampas) · fokus keluar menutup · memilih satu pilihan menutup ·
  `aria-expanded`/`aria-controls`/`aria-labelledby`. Komponen dipakai bersama: `aplikasi/src/komponen/PemilihRingkas.tsx`, dan aturan sama ditulis di sumber desain `prototipe/js/ui.js`
  (id panel/tombol kini **unik per pemilih**, bukan id tetap — dua pemilih di satu halaman dulu saling menunjuk elemen yang salah).
- **Keputusan 3 — tepi area gulir memakai JEJAK PUDAR, bukan potongan mentah.** Sumber: utilitas *scroll fade* 2026 (shadcn/ui; `scroll-mask` twilson.net yang dipakai argos-ci;
  artikel codefronts/panelui). Tiga aturan yang dipakai: maska dengan `mask-image` (ikut tema apa pun tanpa tahu warna latar) · maska dipasang di **elemen yang menggeser**
  (`.picker-daftar`), bukan wadah ber-bordir (`.picker-panel`) — kalau salah, bordir & sudut panel yang luntur · pudarnya **mengikuti posisi gulir** lewat
  `animation-timeline: scroll(self block)`, dengan cadangan statis untuk peramban lama (hanya ujung bawah, supaya tidak "berbohong"). Bantalan `padding` dijaga supaya cincin fokus tidak terpotong maska.
- **Keputusan 4 — ilmu yang dipelajari DISIMPAN sebagai kemampuan dan WAJIB TERPAKAI.** `skills/desain-antarmuka/SKILL.md` (bersumber + daftar periksa) ditambahkan,
  dicantumkan di fase **DESAIN** pada `alat/mulai-sesi.py` (jadi dibaca sesi berikutnya), dan dirujuk dari kode. Penjaga baru `aplikasi/alat/periksa-antarmuka.py`
  menolak keadaan "tersimpan tapi tidak terpakai" — termasuk kalau `skills/desain-antarmuka/SKILL.md` dihapus atau tidak lagi dirujuk kode. Ini menjawab pesan Lee
  *"jangan hanya disimpan, tapi juga harus digunakan sebagai kemampuan"* dengan bukti mesin, bukan janji.
- **Bukti:** `npx vitest run src/gaya/kerapatan-css.test.ts src/layar/contoh/kerapatan.test.tsx src/komponen/PemilihRingkas.test.tsx` → **25 uji LOLOS** ·
  `python3 aplikasi/alat/periksa-antarmuka.py` LOLOS + `--uji-diri` **10/10** (9 mutasi: Esc dihapus · maska di wadah · klik-luar dihapus · salinan CSS menyimpang ·
  id pemilih kembar · kemampuan dihapus · kemampuan tidak dipakai · cadangan peramban dibuang · semua penunjuk kemampuan dihapus) ·
  `alat/periksa-gerbang-ci.py` gerbang wajib 9 → **11** (+mutasi "langkah antarmuka dihapus" → ditolak).
- **Catatan jujur:** uji kaskade sempat MERAH dua kali — (a) helper `var()` hanya menyelesaikan satu lapis sementara token baru berantai, (b) `line-height: var(--baris-isi)`
  terbaca `NaN`. Keduanya diperbaiki di **uji** (resolusi berantai), bukan dengan melonggarkan pemeriksa.
- **File terkait:** `prototipe/css/tokens.css` (**sumber desain**) → salinan apa adanya `aplikasi/src/gaya/token/tema.css` · `aplikasi/src/komponen/PemilihRingkas.tsx` (+uji) ·
  `aplikasi/src/layar/contoh/LayarContoh.tsx` · `aplikasi/src/gaya/kerapatan-css.test.ts` · `prototipe/js/ui.js` · `skills/desain-antarmuka/SKILL.md` ·
  `aplikasi/alat/periksa-antarmuka.py` · `alat/mulai-sesi.py` · `.github/workflows/ci.yml` · `aplikasi/alat/periksa-semua.sh` · `alat/periksa-gerbang-ci.py`

### [ALAT/2026-09-18] Pembuat paket audit mati total + cakupan `--fase` melebar (ditemukan saat menyiapkan paket audit tip)

- **Area:** mekanisme audit independen (`alat/audit-independen.py`) — jalur yang dipakai Lee untuk mengirim sesi auditor
- **Temuan (saat menjalankan jalurnya, bukan membaca kode):**
  1. `python3 alat/audit-independen.py --paket AUD-3 --semua` **MATI** dengan
     `NameError: name 'lingkup' is not defined` — teks prompt penamaan laporan memakai `{lingkup}` yang tidak pernah
     didefinisikan. Artinya paket audit tidak bisa dibuat sama sekali (Lee cukup menyalin berkas SIAP-TEMPEL;
     kalau berkas itu tidak bisa dibuat, seluruh jalur audit berhenti tanpa suara).
  2. Parameter cakupan `semua` ditimpa daftar tugas di baris pertama `mode_paket` (`semua = baca_tugas_roadmap()`),
     sehingga `--fase 1` **diam-diam mengambil seluruh 192 tugas** (cakupan melebar) dan setiap paket dicap "menyeluruh".
- **Keputusan:** nama dipisah (`daftar_tugas` = isi ROADMAP, `menyeluruh` = pilihan cakupan), `lingkup` didefinisikan
  (`menyeluruh`/`terarah`), cakupan `--fase` diurutkan & disaring benar. **Penjaga baru `_uji_pembuat_paket()`** masuk
  `--uji-diri`: pembuat paket dijalankan di SALINAN pohon untuk dua mode, dan isi paketnya diperiksa
  (`AUD-3 --semua` → mode `menyeluruh`; `AUD-2 --fase 1` → semua tugas berawalan `T1-` + mode `terarah`).
  Ini menutup kelas cacat "alat yang tidak pernah dijalankan lagi setelah disunting".
- **Bukti:** `python3 alat/audit-independen.py --uji-diri` LOLOS (termasuk kasus baru) · paket `AUD-3-2026-09-18` &
  `PKT-2026-09-18-pr-01-putaran13` benar-benar terbit untuk tip terkini · `bash aplikasi/alat/periksa-semua.sh` → SEMUA PEMERIKSAAN LOLOS.
- **Catatan jujur:** cacat ini **tidak** ditemukan oleh pemeriksa mana pun (semua hijau) — hanya ketemu karena
  perintahnya benar-benar dijalankan saat menyiapkan paket. Itu alasan aturan "jalankan, jangan baca saja" tetap berlaku.
- **File terkait:** `alat/audit-independen.py`, `docs/uji/paket-audit/AUD-3-2026-09-18.md`,
  `docs/uji/review-pr/PKT-2026-09-18-pr-01-putaran13.md`

## 2026-09-18 — Putaran13: 27 temuan review+audit ditutup migrasi `0014` (keputusan terkunci)

- **Area:** Area Berisiko Tinggi ART-1/ART-3 (uang, jejak, izin) + mekanisme audit
- **Konteks:** Lee menjalankan 4 sesi (2 review PR + 2 audit AUD-3) atas commit `d1f11d7`.
  Seluruh temuan **diverifikasi ulang lebih dulu dengan probe sendiri** sebelum dipercaya
  (aturan yang sama seperti putaran11). 12 temuan review + 15 temuan audit dinyatakan **NYATA**.
- **Keputusan baru yang terkunci:**
  1. **`hitung_total()` ada** dan menjadi SATU-SATUNYA penulis angka uang pesanan
     (subtotal Σ baris non-batal; pajak/service dari `pengaturan`; total = subtotal + pajak +
     service − diskon, minimal 0). Pemicu item & diskon memanggilnya otomatis. Ini menutup
     F-01 (alur uang buntu: pesanan lahir total 0 dan kasir dilarang membetulkan).
  2. **Nomor pesanan SELALU dibuat sistem** (`nomor_pesanan_berikutnya(cabang, tanggal)`);
     nomor kiriman perangkat diabaikan/ditimpa — bukan ditolak, supaya pesanan tidak batal
     hanya karena perangkat salah menghitung (F-04).
  3. **Cap bawaan diskon 50%** (dulu 100% = tanpa cap). Pemicu kumulatif tambahan
     **tidak** dipasang karena penjaga 0013 sudah menahan total; yang salah memang bawaannya (F-03).
  4. **`subtotal` baris pesanan selalu dihitung peladen** (`harga_saat_itu × qty`); angka dari
     perangkat ditimpa, termasuk dari dapur (F-02, PR-01, PR-05).
  5. **Dapur hanya boleh memindahkan status masak** — tidak boleh menyentuh qty/harga/varian/
     catatan. Pembatalan baris setelah dapur mulai wajib berjejak (baris `pembatalan` sah).
  6. **Pesanan `lunas`/`batal` tidak boleh diubah lagi**; salinan harga/nama beku pasca-dapur
     hanya boleh diubah pemegang izin `ubah_harga`.
  7. **PIN berjenjang**: bawahan tidak bisa mengganti PIN atasan (`peran_lebih_tinggi`);
     setiap percobaan dicatat dengan `target_id`, dan korban boleh melihat catatan atas dirinya.
  8. **Penjaga peran/klien WAJIB invoker-rights** — `security definer` membuat `current_user`
     menjadi pemilik fungsi sehingga penjaganya BUTA (kesalahan yang terbukti nyata, dicatat di sini).
- **Mekanisme audit diperkuat (temuan audit F-11/F-12/F-13/F-14/F-15):**
  - `alat/periksa-paket.py` **baru**: paket audit wajib menunjuk **induk commit-nya sendiri**
    dan setiap jalur di bagian 1 wajib benar-benar ada di commit itu; paket lama dikecualikan
    secara eksplisit sampai dibuat ulang. Ada `--uji-diri` (SEMUA kasus harus bisa MERAH).
  - `alat/periksa-angka-bukti.py` **baru**: angka "N uji/tabel" di klaim Bukti ROADMAP wajib
    disertai perintah yang bisa diulang atau penanda jujur "angka saat itu".
  - `periksa-komponen-env.py`: sel gabungan `GOOGLE_CLIENT_ID/SECRET` dipecah; pencocokan
    lewat awal baris → menghapus `# GOOGLE_CLIENT_ID=` sekarang membuat pemeriksa GAGAL (F-15).
  - `uji-mutasi-0012.py`/`uji-mutasi-0014.py`: `berkas_berlaku()` mencari **migrasi terbaru**
    yang memuat pola, mendukung berkas eksplisit, dan **melaporkan mutasi yang dilewati**
    (tidak pernah dicap hijau). Mutasi gabungan menembus penjaga berlapis (M3k/M5k/M8k).
  - `supabase/tes/rls_semua_tabel.sql`: arah **timbal balik** — tabel tanpa `penyewa_id`
    wajib terdaftar dengan jangkarnya, dan jangkar itu benar-benar muncul di policy-nya.
- **Bukti:** `node alat/uji-sql.mjs` → **41 LULUS · 0 GAGAL** · `python3 alat/uji-mutasi-0012.py`
  → **16/16 MERAH** · `python3 alat/uji-mutasi-0014.py` → **17/17 MERAH** ·
  `bash aplikasi/alat/periksa-semua.sh` → **SEMUA PEMERIKSAAN LOLOS** · `python3 alat/periksa-paket.py --uji-diri`
  dan `periksa-angka-bukti.py --uji-diri` LOLOS (terbukti bisa menolak).
- **Catatan jujur:** nilai 50% adalah titik awal yang bisa diubah owner di pengaturan; yang
  dikunci adalah *ada* cap bawaan yang punya arti, bukan angkanya.
- **File terkait:** `supabase/migrations/0014_penutup_celah_putaran13.sql`, `supabase/tes/*`,
  `alat/periksa-paket.py`, `alat/periksa-angka-bukti.py`, `alat/uji-mutasi-0014.py`.

## 2026-09-18 — Pindah sesi: berkas prompt Lee jadi STATIS + sesi boleh ditinggalkan (permintaan Lee, pesan ke-41)

**Keputusan (disetujui Lee dalam pesannya, agent dikritisi lebih dulu lalu menerapkan):**

1. **Berkas prompt untuk membuka sesi baru = STATIS** (`PROMPT_SESI_BARU.md` di akar repo). Alasan Lee:
   berkas yang harus disiapkan ulang setiap kali pindah sesi itu merepotkan; ia ingin satu berkas tetap
   yang sama seperti Prompt Entri Universal. Konsekuensi teknis: berkas itu **tidak boleh** memuat keadaan
   proyek (commit/CI/butir tertangguh) — keadaan dibaca agent dari isi repo setelah mendarat di cabang yang
   benar (`docs/ops/SIAP-LANJUT.md`). Jadi tidak ada klaim yang bisa basi.
2. **Baris pertama berkas statis itu milik Lee:** `SESI YANG AKU LANJUT: <cabang>`. Bila baris itu berbeda
   dengan "Cabang yang dilanjutkan" di handoff mesin, **baris Lee yang menang** (laporkan bedanya, lalu
   rapikan handoff dengan `--siapkan --lanjut-dari <cabang>`).
3. **Mesin tidak menebak.** Bila baris itu kosong, agent baru wajib menampilkan daftar sesi dan menunggu
   Lee memilih — bukan menyusul "sesi terakhir".
4. **Sesi yang sengaja ditinggalkan dicatat** di `docs/ops/SESI_DITINGGALKAN.md`. `alat/lanjut-sesi.py`
   menolak handoff/`--siapkan` yang menunjuk ke sana dan menandainya di `--daftar-sesi`. `--paksa` hanya
   atas perintah Lee, dan jejaknya ditulis di handoff ("DIPAKSA atas perintah Lee").
5. **`docs/ops/SIAP-TEMPEL-SESI-BARU.md` dipensiunkan** menjadi penunjuk (berkas statis itu yang dipakai).
   Alasan: dua berkas yang bisa saling bertentangan = sumber cacat. Sesi yang lebih tua tetap punya berkas
   lama itu apa adanya, dan itu tidak diubah.

**Batas yang disadari (jujur):** berkas statis **tidak bisa** memverifikasi apa pun soal kesegaran; itu
sepenuhnya tugas handoff mesin (§2 dan 2b di `docs/ops/SIAP-LANJUT.md`). Karena itu `--siapkan`/
`periksa()` tetap menjalankan seluruh penjaga handoff seperti sebelumnya.

**Bukti:** `python3 alat/lanjut-sesi.py --uji-diri` → **37 kasus LOLOS** (dua kasus merah pada percobaan
pertama justru menemukan 2 celah penjaga: baris "berkas yang Lee salin" belum dijaga, dan kasus uji cabang
hantu lolos karena alasan yang salah → keduanya ditutup); `python3 alat/periksa-panduan.py` LOLOS
(+3 topik wajib); `python3 alat/lanjut-sesi.py` LOLOS.

**File terkait:** `PROMPT_SESI_BARU.md`, `alat/lanjut-sesi.py`, `docs/ops/SESI_DITINGGALKAN.md`,
`docs/ops/SIAP-TEMPEL-SESI-BARU.md` (pensiun), `PANDUAN_PENGGUNA.md` (AL-13), `docs/PANDUAN_PEMILIK.md` (2b/3).

## 2026-09-18 — "Kalimat perintah sederhana Lee" wajib punya rantai petunjuk yang hidup (jawaban kepercayaan Lee)

**Masalah yang diakui jujur.** Buku induk memuat 13 alur (AL-1…AL-13) + tabel kalimat sehari-hari (C3) + tabel
perintah mesin (Bagian E). Tetapi **tidak ada mata rantai yang memaksa agent baru menemukannya**: Prompt Pembuka
Universal tidak menunjuk `PANDUAN_PENGGUNA.md`, dan KARTU SESI (yang selalu dicetak) juga tidak. Artinya janji
"cukup bilang `Siapkan review PR.`" hanya bergantung pada niat agent membaca dokumen tambahan — bukan pada mekanisme.

**Keputusan:** janji itu dijadikan **mekanisme yang dijaga**:
1. **Prompt Pembuka Universal item 2d** — kalimat perintah sederhana Lee wajib dicari di `PANDUAN_PENGGUNA.md`
   (Bagian C3 / Bagian B alur AL-1…AL-13 / Bagian E), dicocokkan **maksudnya** (bukan huruf per huruf), disebut
   nomor alurnya saat melapor, dan agent **dilarang mengarang mekanisme baru** di luar buku.
2. **KARTU SESI mencetak blok `PETUNJUK_PERINTAH`** — pintu masuk setiap sesi, jadi tidak bergantung pada agent
   membuka buku lebih dulu.
3. **Sinonim & kalimat gabungan diakui** — `Tutup sesi ini dengan baik` = `dengan benar`; dan
   `Siapkan pindah sesi dan tutup sesi ini dengan baik` = AL-3 + AL-13 (dua alur sekaligus).
4. **Dijaga pemeriksa**: `alat/periksa-panduan.py` menolak bila (a) prompt kanonik tidak menunjuk buku / tidak
   mengatur kalimat sederhana, (b) KARTU SESI berhenti mencetak penunjuk, (c) buku kehilangan sinonim/kalimat
   gabungan. `--uji-diri` membuktikan penolakan itu nyata (2 mutasi baru).
5. Berkas pensiun `docs/ops/SIAP-TEMPEL-SESI-BARU.md` **tidak lagi disebut** oleh prompt kanonik; yang disebut
   `PROMPT_SESI_BARU.md` (statis).

**Batas jujur:** mekanisme ini memastikan rantai petunjuk **ada dan hidup**; ia tidak bisa memaksa model yang
tidak patuh. Karena itu setiap kartu sesi menutup dengan kewajiban melaporkan KARTU SESI lebih dulu, dan Lee
selalu bisa memeriksa apakah agent menyebut nomor alurnya.

**Bukti:** `python3 alat/periksa-panduan.py` LOLOS · `--uji-diri` 6 kasus (2 mutasi baru) MENOLAK · 
`python3 alat/mulai-sesi.py --uji-diri` 7 kasus LOLOS · uji rantai dari klon buta `main` → kartu sesi memuat
penunjuk + buku memuat 13 alur · `python3 alat/lanjut-sesi.py` LOLOS · CI hijau.

**File terkait:** `PROMPT_ENTRI_UNIVERSAL.md`, `PANDUAN_PENGGUNA.md` (item 2d, AL-3, AL-13, C3), `alat/mulai-sesi.py`,
`alat/periksa-panduan.py`, `PROMPT_SESI_BARU.md`.

---

## [Keamanan/2026-09-20] Daftar asal (origin) CORS untuk Edge Function verifikasi_pin

**Keputusan:** CORS Edge Function `verifikasi_pin` TIDAK memakai wildcard. Daftar asal sah
(ditanam di `supabase/functions/verifikasi_pin/index.ts` sebagai `ASAL_DIIZINKAN`):

1. `https://resto-barokah.fatrizmubarok.workers.dev` (produksi),
2. `http://localhost:5173` dan `http://127.0.0.1:5173` (pengembangan lokal).

Asal di luar daftar tetap boleh memanggil tetapi TIDAK menerima header CORS, sehingga peramban
menolak membaca jawabannya. Bila alamat produksi berubah (domain sendiri), perbarui daftar ini
di berkas yang sama — penjaga `alat/periksa-fungsi-pin.py` menolak kembalinya wildcard.
Diputus sebagai penutup temuan H F-09 (K-4, pengerasan).

## [Keamanan uji/2026-09-19] Bahan & kunci kalibrasi hidup DI LUAR repo (temuan audit D F-05)

**Konteks:** audit AUD-3 putaran verifikasi menemukan `docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` ikut ter-commit.
Berkas itu adalah diff dari migrasi **nyata** ke versi cacat — jadi siapa pun yang bisa membaca repo (termasuk peninjau
yang sedang dikalibrasi) tahu persis baris mana yang ditanami cacat. Skor "Ditemukan: X dari Y" bisa dipalsukan dan
ambang lulus kalibrasi ("verdict BERSIH boleh dipercaya") kehilangan makna. Ini melanggar janji PROTOKOL §7
("kunci jawaban disimpan di luar repo").

**Keputusan (disetujui Lee 2026-09-19):**
1. **Berkas bahan/kunci kalibrasi tidak boleh hidup di dalam repo.** Bahan review PR disiapkan di luar repo
   (`KAL_DIR_LUAR`, bawaan `/tmp/kalibrasi-pr`, bisa diganti lewat env `KALIBRASI_PR_DIR`); kuncinya tetap
   `/tmp/KUNCI-KALIBRASI-PR-<tanggal>.md`.
2. **Yang masuk ke paket adalah ISI bahan, bukan jalurnya** — `--siapkan` menyematkan blok `diff` ke §5 paket dan
   **menolak** membuat paket bila bahan/kunci masih ada di dalam repo.
3. **Rotasi bahan:** bahan yang pernah bocor — termasuk yang masih terbaca di riwayat Git — **tidak dipakai lagi**
   untuk menilai ketajaman; gantinya bahan baru bertanggal (sama seperti jalur auditor).
4. **Berkas yang keluar dari repo berjejak di DAFTAR PENSIUN** `docs/uji/BERKAS_PENSIUN.md` — jalur, tanggal, pemutus (Lee), alasan, dan nasib isinya. Validator memperlakukan jalur terdaftar sebagai "sengaja tidak ada", sehingga **riwayat, paket, dan laporan peninjau tidak perlu disunting** (barang bukti tetap utuh).
5. **Dijaga mesin:** `alat/periksa-kunci-kalibrasi.py` (aturan A–D) masuk CI (gerbang 22 → **24**; lalu **49** setelah PR-10 — setiap perintah CI diawasi, bukan hanya daftar penjaga terpilih); `--uji-diri` membuktikan 9 mutasi ditolak dan salinan utuh diterima (termasuk "daftar pensiun dihapus", "berkas pensiun muncul lagi", "paket baru menunjuk jalur bahan di repo").

**Batas jujur:** mengeluarkan berkas dari commit **tidak menghapus** isinya dari riwayat Git (`git log --all` masih
memperlihatkannya). Karena itu keputusan ini **bukan** "rahasia kembali aman", melainkan: (a) tidak ada lagi salinan
di keadaan sekarang yang bisa ditemukan tanpa sengaja, (b) bahan lama dinyatakan pensiun, (c) rotasi wajib untuk
putaran berikutnya. Bila kelak ingin membersihkan riwayat, itu tindakan destruktif (tulis ulang riwayat + force push)
— **wajib keputusan Lee, tidak dilakukan sekarang**.

**Cacat mekanisme yang ikut ketahuan (dan ditutup):** `alat/periksa-paket.py` aturan F-11 memakai "commit TERAKHIR yang mengubah paket" — satu suntingan sah (mis. catatan provenance) membuat 22 paket lama dituduh melanggar; sekarang paket sah bila **ada** commit dalam riwayat yang menulisnya tepat sesudah commit target dan targetnya tidak berubah. Uji-diri penjaga kunci juga sempat tumpul karena menguji paket lama sementara aturannya berlaku untuk paket baru.

**Bukti:** percobaan nyata di klon: `--kalibrasi-pr-siapkan` MENOLAK saat bahan masih di repo; setelah dikeluarkan →
bahan ditulis ke `/tmp`, paket memuat blok `diff`; `python3 alat/periksa-kunci-kalibrasi.py` LOLOS · `--uji-diri`
7 kasus (6 mutasi ditolak) LOLOS · `python3 alat/periksa-gerbang-ci.py` 24 gerbang LOLOS · CI hijau.

**File terkait:** `alat/review-pr.py`, `alat/periksa-kunci-kalibrasi.py`, `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7,
`docs/uji/kalibrasi/CARA-PAKAI.md`, `.github/workflows/ci.yml`, `docs/uji/AUDIT_RIWAYAT.md` (D F-05).

---

## [Infrastruktur/2026-09-19] Akun pemilik aktif: nilai PUBLIK boleh hidup di repo/CI, nilai RAHASIA tidak (T0-00 ditutup)

**Konteks:** Lee membuat akun **Supabase + Resend + Cloudflare** (2026-09-19) dan menyerahkan nilai non-rahasia lewat repo
(`docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md`, commit `bd68685`): URL proyek, kunci **publishable/anon**, id proyek, region
**Singapura**, id akun Cloudflare. Kunci `service_role` tidak pernah masuk repo maupun obrolan (aturan `docs/TECH_SPEC.md` §6).

**Keputusan:**
1. **Dua kelas nilai dipisah tegas.** Nilai publik (URL proyek + kunci `publishable`/anon) boleh hidup di repo dan boleh
   tampil di berkas CI — keamanan data dijaga RLS, bukan oleh kerahasiaan nilai itu. Nilai rahasia (`service_role`, Resend,
   Cloudflare, kata sandi database) tetap hanya di berkas lokal yang diabaikan Git (`*.local.md`) atau di panel rahasia
   Cloudflare/Supabase — **tidak pernah** masuk repo, obrolan, atau berkas CI.
2. **Uji sambung T0-08 dijalankan di CI, bukan di mesin agent.** Lingkungan agent tidak punya jalan keluar jaringan ke
   `*.supabase.co` (terbukti: `curl` HTTP 000 / TLS ditolak, domain umum lain pun sama), sedangkan runner GitHub punya.
   Gerbang CI ke-50: `npm run cek:supabase` memakai kunci publik saja (kesehatan Auth + akar PostgREST) — tanpa membaca
   satu baris data.
3. **DoD `select 1` pada T0-08 belum dapat dibuktikan hari ini** karena skema (14 migrasi) **belum disebar** ke proyek
   Supabase nyata; penyebaran butuh keputusan + kredensial pemilik → butir tunggu `T-020`. Tugas `T0-08` karena itu
   **tetap terbuka** dan ditandai `❓ T-020` — bukan ditutup dengan klaim yang tidak bisa dibuktikan.
4. **Deploy publik T0-09 butuh keputusan Lee** (tindakan publik/tak bisa dibatalkan) → butir tunggu `T-021`; persiapan
   (`aplikasi/wrangler.toml` + `npm run deploy`) sudah selesai.

**Batas jujur:** uji sambung membuktikan ALAMAT + KUNCI + JARINGAN (server menerima kunci publik). Ia **tidak** membuktikan
tabel sudah ada, RLS benar, atau aplikasi bisa membaca data nyata — itu tetap sisa pekerjaan (sebar skema + uji di layanan
nyata), bukan klaim selesai.

**Bukti:** gerbang CI ke-50 ada di `.github/workflows/ci.yml` dan diawasi dua arah oleh `python3 alat/periksa-gerbang-ci.py`
(termasuk `--uji-diri`); `node aplikasi/alat/cek-supabase.mjs --uji-diri` 5/5 LOLOS; `pytest`-gaya uji aplikasi
`npx vitest run` menambahkan 10 kasus untuk `aplikasi/src/lib/supabase.ts`.

**File terkait:** `aplikasi/src/lib/supabase.ts`, `aplikasi/alat/cek-supabase.mjs`, `aplikasi/wrangler.toml`,
`.github/workflows/ci.yml`, `alat/periksa-gerbang-ci.py`, `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md`,
`docs/TERTANGGUH.md` (T-018 selesai; T-020/T-021 terbuka).

---

## [Infrastruktur/2026-09-19] Penyebaran ke aset pemilik lewat alur "disengaja" (berkas penanda) — rahasia hanya di kotak rahasia GitHub

**Konteks:** Fase 0 tinggal dua langkah yang menyentuh aset nyata pemilik: menyebar 14 migrasi ke proyek Supabase
(butir `T-020`) dan menaikkan halaman ke Cloudflare (butir `T-021`). Keduanya tidak boleh berjalan di setiap kiriman
kode, dan kuncinya **tidak boleh** masuk repo/obrolan. Lingkungan agent juga tidak punya jalan keluar jaringan ke
`*.supabase.co`, sedangkan runner GitHub punya.

**Keputusan:**
1. **Sengaja, bukan otomatis.** Dua alur terpisah di `.github/workflows/`: `sebar-skema.yml` dan `sebar-halaman.yml`.
   Keduanya hanya menyala lewat **berkas penanda** (supabase/SEBAR-SKEMA dan aplikasi/SEBAR-HALAMAN) yang dibuat
   sesaat lalu dihapus setelah hijau — jadi tidak ada penyebaran tak sengaja di kiriman berikutnya.
2. **Pratinjau lebih dulu.** Alur sebar skema menjalankan `supabase db push --dry-run` **sebelum** penyebaran sungguhan;
   kalau ada migrasi yang tidak cocok, tidak ada yang berubah di proyek nyata dan alurnya langsung merah.
3. **Rahasia hanya di kotak rahasia GitHub.** `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `CLOUDFLARE_API_TOKEN`
   dipasang **pemilik** di Settings → Secrets and variables → Actions. Nilainya tidak pernah masuk repo, commit, laporan,
   atau obrolan; agent tidak pernah melihatnya. Nomor proyek/akun (bukan rahasia) boleh duduk di berkas.
4. **Alur lain ikut diawasi penjaga.** `alat/periksa-gerbang-ci.py` diperluas: perintah di kedua alur diperiksa **dua arah**
   seperti `ci.yml` (8 + 5 perintah), penyaring berkas penanda wajib ada, **URUTAN perintah ikut diperiksa** (pratinjau
   wajib benar-benar mendahului penyebaran — keberadaan saja tidak cukup), dan seluruh berkas alur dilarang memuat
   pelemahan senyap (`continue-on-error`, `|| true`, `if:` pada langkah). `--uji-diri` menambah **9 mutasi alur**,
   semuanya wajib ditolak (mis. dry-run dihapus, urutan ditukar, pemeriksaan penanda dihapus, perintah rilis diganti
   sekadar `build`).
5. **`supabase/config.toml` ditulis ringkas tanpa `env(...)`.** Versi hasil `supabase init` memuat
   `openai_api_key = "env(OPENAI_API_KEY)"` yang membuat CLI menolak berjalan di CI bila variabelnya tidak ada;
   bentuk ringkas sudah diuji dengan CLI **2.117.0** (`db push --dry-run` menerima berkasnya).
6. **Satu blok `run:` berurutan + kata sandi dikirim lewat `--password`.** Semua perintah penyebaran duduk dalam satu
   blok dengan `set -euo pipefail`: (a) pratinjau tidak mungkin terlewat, dan (b) pemeriksaan penanda bisa
   menghentikan SELURUH alur — pada alur berlangkah banyak, `exit 0` hanya menghentikan satu langkah dan langkah
   berikutnya tetap jalan. `link`/`db push`/`migration list` diberi `--password` supaya CLI tidak menunggu jawaban
   (jebakan lama: `db push` di CI bisa "sukses" tanpa menyebar).
7. **Menghapus berkas penanda juga aman.** Kiriman penghapusan tetap menyentuh jalur berkas penanda (itu cara GitHub
   bekerja), tetapi alur langsung berhenti di pemeriksaan penanda dan **hijau tanpa menyentuh proyek** — dibuktikan
   dengan uji sungguhan, bukan asumsi (lihat bukti di `docs/TERTANGGUH.md` butir `T-020`).

**Batas jujur:** keputusan ini **belum** menyebar apa pun — kedua alur baru menyala setelah pemilik memasang rahasia
dan agent membuat berkas penanda. Sampai itu terjadi, `T-020`/`T-021` tetap **terbuka**, dan klaim "skema sudah ada di
proyek nyata" atau "halaman sudah publik" belum boleh ditulis di dokumen mana pun.

**File terkait:** `.github/workflows/sebar-skema.yml`, `.github/workflows/sebar-halaman.yml`, `supabase/config.toml`,
`alat/periksa-gerbang-ci.py`, `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`, `docs/uji/BUKU_UJI_PEMILIK.md` (P-04/P-05),
`docs/TERTANGGUH.md` (T-020/T-021).

---

## [Infrastruktur/2026-09-19] Skema pertama hidup di proyek pemilik → migrasi 0001–0014 DIBEKUKAN

**Konteks:** setelah pemilik memasang dua rahasia Supabase di kotak rahasia GitHub (Langkah A), alur disengaja
`.github/workflows/sebar-skema.yml` dijalankan lewat berkas penanda supabase/SEBAR-SKEMA: run `35435248540` hijau
berurutan — `supabase link` → `db push --dry-run` (pratinjau) → `db push` (penyebaran) → `migration list` (bukti).
Jadi 14 berkas migrasi `0001`–`0014` kini **benar-benar ada** di database milik pemilik (proyek
`bdvjirmbuqelmduztryj`). Bukti susulan yang bisa diperiksa siapa pun: gerbang CI ke-50 membaca satu baris tabel
katalog dengan kunci publik (`GET /rest/v1/menu_item?select=id&limit=1` → HTTP 200) pada run `35435414653`.

**Keputusan: berkas migrasi `0001`–`0014` DIBEKUKAN.**
1. **Kenapa:** database nyata hanya berubah karena PENYEBARAN berkas migrasi. Mengubah berkas lama tidak mengubah
   database nyata, tetapi mengubah hasil uji lokal — persis kelas cacat "bukti tidak mewakili kenyataan".
2. **Aturan:** setiap perubahan skema — termasuk seluruh perbaikan temuan audit (K-1…K-4) — WAJIB ditulis sebagai
   berkas migrasi **baru** bernomor `0015` ke atas. Berkas lama tidak boleh disunting lagi.
3. **Dijaga mesin, bukan ingatan:** penjaga baru `alat/periksa-migrasi-beku.py` memuat sidik SHA-256 ke-14 berkas itu
   dan ikut berjalan di CI. Berkas lama berubah sedikit saja, ada berkas baru bernomor ≤ `0014`, atau nomor migrasi
   kembar → CI **MERAH**; penjaganya punya `--uji-diri` (mutasi wajib ditolak) yang juga berjalan di CI.
4. **Konsekuensi untuk audit:** perbaikan RLS/kebijakan/fungsi berbentuk "migrasi penutup" di `supabase/migrations/`,
   bukan suntingan berkas lama — dan itu memang cara kerja Supabase di proyek nyata.

**Batas jujur:** yang terbukti adalah (a) alur penyebaran hijau sampai `migration list`, dan (b) tabel katalog bisa
dibaca dengan kunci publik dari CI. Uji **penuh** berkas uji di `supabase/tes/` terhadap proyek nyata (bcrypt asli
pgcrypto) belum dijalankan dan tidak diklaim di sini.

---

## [Infrastruktur/2026-09-19] Halaman pertama naik ke internet (publik) — atas izin pemilik & FF, tanpa data pelanggan

**Konteks:** tugas Fase 0 `T0-09` meminta bukti jalur rilis bekerja sejak awal. Deploy publik adalah tindakan yang
**tidak bisa ditarik diam-diam** (Stop Condition §12), jadi agent berhenti dan menunggu lebih dulu; pemilik (Lee)
menulis **"Boleh naik"** di chat pada 2026-09-19. Setelah itu agent memicu berkas penanda `aplikasi/SEBAR-HALAMAN`
(izin tertulis ada di dalam berkas penanda itu sebagai catatan) dan alur `.github/workflows/sebar-halaman.yml`
berjalan dua kali: run `35440300274` (unggahan pertama) dan `35440432817` (unggahan ulang + pencatatan alamat) —
keduanya **hijau**.

**Keputusan & alasan:**
1. **Naik sekarang, bukan nanti.** Halaman masih kerangka: tidak ada data pelanggan, tidak ada menu asli, tidak ada
   kunci rahasia di dalamnya. Membuktikan jalur rilis sedini mungkin mencegah kejutan besar di akhir proyek
   (persis tujuan `T0-09`).
2. **Alamat publik dicatat MESIN, bukan ingatan.** Log job GitHub Actions **tidak bisa dibaca** dari lingkungan
   agent, jadi alat baru `aplikasi/alat/catat-alamat.mjs` menanyakan subdomain ke Cloudflare API, menyusun alamat,
   lalu **membukanya** — hasilnya dipancarkan sebagai **anotasi** (`ALAMAT-PUBLIK url=… http=…`) yang bisa dibaca
   siapa pun lewat API GitHub pada commit itu. Kalau halaman tidak menjawab 200, alat itu **gagal** (alur merah).
   Alamat resminya: **<https://resto-barokah.fatrizmubarok.workers.dev>** (`docs/ops/ALAMAT_PUBLIK.md`).
3. **Tetap lewat penanda.** Alur hanya menyala lewat berkas `aplikasi/SEBAR-HALAMAN`; berkas itu dihapus setelah
   hijau, dan kiriman penghapusan **hijau tanpa kerja** (sudah diuji). Tidak ada unggahan tak sengaja.
4. **Cara mundur dicatat:** pekerja `resto-barokah` bisa dihapus dari dasbor Cloudflare; tidak ada biaya (paket
   gratis, berkas statis). Alamat gratis `*.workers.dev` dipakai sejak `T-008` (2026-09-16).

**Batas jujur:** yang terbukti adalah **halaman kerangka menjawab 200 di alamat publik**. Belum ada satu pun fitur
kedai di sana, dan belum ada domain sendiri (masih memakai alamat gratis `*.workers.dev`, sesuai keputusan T-008).

---

## [Keamanan uang/2026-09-19] Bukti pembatalan harus DATA di tabel, bukan pengaturan transaksi yang bisa ditulis klien

**Konteks (temuan K-1, review PR-01 putaran16):** penjaga item `picu_item_jaga()` menerima bukti "pembatalan ini
resmi" dari `current_setting('resto.pembatalan_pesanan')`. Pengaturan transaksi bisa ditulis **siapa pun** dengan
`set_config(...)`. Rekaman probe: kasir menjalankan tiga baris — pasang penanda, lalu `update pesanan_item set
status='batal'` — dan item sesudah dapur **berhasil** dibatalkan tanpa PIN atasan dan tanpa satu pun baris
`pembatalan`. Artinya: jejak pembatalan bisa dihilangkan, dan laporan kerugian bisa tidak pernah muncul.

**Keputusan:**
1. **Penanda transaksi berhenti dipercaya sama sekali.** Pemeriksaan `current_setting('resto.pembatalan_pesanan')`
   dihapus dari penjaga item; pemicu resmi juga berhenti menulisnya. Tidak ada lagi nilai yang bisa dipalsukan.
2. **Bukti pembatalan harus berbentuk baris tabel** (`public.pembatalan`) yang hanya bisa lahir lewat jalur resmi:
   penjaga 0013 memaksa tahap cocok (sebelum/sesudah dapur), izin `void_sesudah_dapur`, dan **kupon PIN terikat
   pesanan & sekali pakai**.
3. **Pembatalan item / pengecilan jumlah setelah dapur dari perangkat selalu ditolak.** Jalur sahnya: perangkat
   menulis baris `pembatalan` resmi, lalu pemicu resmi (SECURITY DEFINER, berjalan sebagai pemilik tabel) yang
   mengubah baris item. Pekerjaan kasir tidak berkurang — hanya jalur pintasnya yang ditutup.
4. **Dibuktikan bisa MERAH, bukan sekadar hijau.** `alat/uji-mutasi-0015.py` mengembalikan versi lama (percaya
   penanda), melepas pemicunya, dan menyelipkan pengecualian diam-diam untuk peran `kasir` — **semuanya wajib
   memerahkan uji**, dan memang merah. Gerbang CI: uji regresi + bukti mutasi (gerbang ke-52).

**Batas jujur:** bagian 1 ini menutup **satu** temuan (K-1). Temuan K-2…K-4 belum; daftarnya tetap di
`docs/uji/REVIEW_PR_RIWAYAT.md` §1 dan `docs/uji/AUDIT_RIWAYAT.md` §1b dengan pemilik `T1-45`/`T1-44`.
Berkas migrasi `0015` akan bertambah bagian pada batch berikutnya — berkas `0001`–`0014` tetap beku.

---

## [Uang/2026-09-19] Tagihan yang sudah dibayar tidak boleh ditulis ulang — dan batal satu item bukan batal satu pesanan

**Konteks (temuan audit D F-01 + review PR-02, putaran16):** dua keadaan nyata dari kursi kasir.
(1) Pesanan sudah `lunas` (uang diterima & tercatat), lalu baris `diskon_transaksi` disisipkan —
pemicu hitung-ulang mengubah `pesanan.total` SETELAH lunas, tanpa penjelasan resmi di jejak.
(2) Membatalkan SATU item (`pembatalan` dengan `pesanan_item_id`) langsung menulis
`pesanan.status = 'batal'`, padahal item lain masih hidup — akibatnya pembayaran sisa DITOLAK
("pesanan sudah batal") dan pelanggan tidak bisa membayar item yang benar-benar ia terima.

**Keputusan:**
1. **Diskon hanya boleh berubah selama tagihan belum tercatat.** Baris diskon tidak bisa
   ditambah/diubah/dihapus pada pesanan `lunas` atau `batal`, oleh siapa pun. Jalur sah untuk
   memperbaiki uang sesudah tercatat adalah **pembatalan/void resmi** (baris `pembatalan`,
   berikut PIN atasan bila dapur sudah mulai) — bukan menulis ulang tagihan lama.
2. **Status `batal` pada pesanan berarti SELURUH pesanan batal.** Void satu item tidak menutup
   pesanan; pesanan ditutup hanya bila tidak ada item hidup tersisa atau pembatalannya memang
   tingkat pesanan. Pesanan yang ditutup menandai **seluruh** itemnya `batal`, supaya tidak ada
   keadaan setengah jalan (pesanan batal tetapi item tampak masih terutang).
3. **Angka uang tetap dihitung satu tempat** (`hitung_total`): item `batal` tidak ditagih, jadi
   tagihan sisa otomatis benar dan bisa dibayar.
4. **Urutan pemicu adalah bagian dari keputusan.** Pemicu pemeriksa STATUS pesanan bernama
   `diskon_awal_pesanan` supaya berjalan sebelum pemicu nilai `diskon_batas` (PostgreSQL
   menjalankan pemicu sebaris menurut abjad nama): penolakan harus berbunyi tentang status,
   bukan tertutup pesan tentang nilai diskon. Urutan ini dikunci uji (mutasi "nama pemicu
   diubah" wajib MERAH).

**Bukti:** `supabase/tes/void_satu_item.sql` dan `supabase/tes/diskon_sesudah_lunas.sql` (bagian
dari suite 44 berkas). `alat/uji-mutasi-0015.py` kini 11 kasus: 10 mutasi wajib MERAH semuanya
terbukti merah (termasuk "kembalikan perilaku 0014: selalu tutup pesanan", "pagar diskon dihapus",
"pemicu dilepas dari tabel", "urutan pemicu dibalik"), 1 kasus memang diharapkan hijau (penanda
lama ditulis ulang tanpa pagar lama). Berkas `0001`–`0014` tetap beku; semua perubahan hidup di
`0015` yang belum pernah disebar ke proyek nyata.

---

## [Keamanan/2026-09-19] Hitungan pesanan bukan informasi publik lintas resto; pesan PIN kembar dibuat netral

**Konteks (temuan K-2 PR-03 & PR-04, putaran16):** dua kebocoran informasi kecil tetapi nyata.
(1) `nomor_pesanan_berikutnya()` adalah SECURITY DEFINER dan bisa dipanggil klien mana pun: kasir
Resto B memanggilnya untuk cabang Resto A dan membaca berapa pesanan yang sudah dibuat resto A
hari itu. (2) Pesan penolakan `simpan_pin` berbunyi 'PIN itu sudah dipakai pegawai lain di resto
ini' — kalimat itu MEMASTIKAN bahwa angka yang baru saja dikirim adalah PIN aktif seorang kolega.

**Keputusan:**
1. **Penghitung nomor tunduk pada isolasi lintas resto yang sama dengan angka uang**
   (`hitung_total`, `total_dibayar`): pemanggil beridentitas hanya boleh menghitung cabang yang
   boleh ia pantau (`cabang_pantau_saya`); di luar itu DITOLAK, bukan dijawab angka. Pemanggil
   tanpa identitas (penyiapan / `service_role`) tetap boleh, karena pemicu penomoran pesanan baru
   berjalan sebagai peladen.
2. **Pesan PIN kembar dibuat netral** ('PIN itu tidak bisa dipakai — pilih angka lain.').
   Aturan keunikan PIN antar pegawai satu resto (T1-23) TIDAK berubah; yang berubah hanya apa yang
   diberitahukan ke penebak. Alasan sebenarnya tetap tercatat di `percobaan_simpan_pin`
   (`alasan = 'PIN kembar'`) supaya pemilik bisa menelusuri percobaan menebak.
3. **Batas jujur yang dicatat, bukan disembunyikan:** sifat berhasil-vs-ditolak pada akhirnya masih
   bisa dibaca penyerang, jadi pengendali biaya menebak tetap **pembatas 20 percobaan / 15 menit
   per akun** (keputusan T1-23, 2026-09-17) yang ujinya tetap hidup (`supabase/tes/pin_batas_pasang.sql`).
   Menambah derau/heuristik baru untuk menutup sisa itu = mengubah kontrol keamanan tanpa
   persetujuan pemilik → tidak dilakukan sekarang; dicatat sebagai batas.

**Bukti:** `supabase/tes/nomor_pesanan_isolasi.sql` & `supabase/tes/pin_bukan_oracle.sql`; dua uji
lama yang memeriksa pesan lama diselaraskan (`supabase/tes/kredensial_pin.sql`,
`supabase/tes/pin_batas_pasang.sql`). `alat/uji-mutasi-0015.py` **15 kasus** — 13 mutasi wajib MERAH
semuanya terbukti merah, termasuk "pagar isolasi penghitung nomor dihapus" dan "pesan PIN kembar
dikembalikan ke versi lama". Berkas `0001`–`0014` tetap beku.

---

## [Uang/2026-09-20] Urutan hitungan uang dikunci: pajak & service dari subtotal SETELAH diskon, pembulatan ke bawah di langkah terakhir

**Konteks (temuan K-1 audit AUD-3 2026-09-19, sesi `arena/01a0bbd2`):** laporan
`docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2.md` menemukan tiga cacat jalur uang
yang **dibuktikan nyata dengan probe sendiri** (`docs/uji/audit/probe-2026-09-20/aud-3-f01-f02-uang.sql`
dijalankan lewat `node alat/uji-sql.mjs`): (a) `hitung_total` menghitung PB1 & service dari **subtotal
sebelum** diskon, padahal `docs/TECH_SPEC.md` §329-331 mengunci urutannya setelah diskon; (b)
`pengaturan.pembulatan` **tidak pernah dibaca** mesin sehingga angka tagihan bukan angka rupiah yang
diminta pemilik; (c) RPC `hitung_total` bisa dipanggil perangkat dan **menulis ulang angka pesanan yang
sudah lunas** (angka di struk berubah sesudah uang dicatat).

**Keputusan:**
1. **Basis pajak & service = subtotal SETELAH diskon** (aturan terkunci §329-331, kini benar-benar
   dijalankan mesin). Contoh 100.000 dengan diskon 20.000 → dasar 80.000 → PB1 10% = 8.000 ·
   service 5% = 4.000 · total **92.000** (cara lama: 10.000 / 5.000 / 95.000).
2. **Pembulatan dibaca dari `pengaturan.pembulatan` dan diterapkan di langkah TERAKHIR**, dengan arah
   **KE BAWAH** (`(total / langkah) * langkah`). Alasan: dokumen terkunci menyebut "pembulatan"
   sebagai langkah terakhir tetapi **tidak pernah mengunci arahnya** (`PRD.md` §88/§229, `TECH_SPEC.md`
   §331, `ROADMAP.md` T1-15/T1-16 diperiksa ulang 2026-09-20) — jadi arah adalah keputusan baru yang
   **dikunci di sini**: membulatkan ke bawah berarti pelanggan tidak pernah dirugikan oleh pembulatan
   (resto yang menanggung sisa). Arah bisa dibalik satu baris bila pemilik meminta lain, dan uji
   `supabase/tes/urutan_uang.sql` + mutasi "arah pembulatan dibalik" akan menangkapnya.
3. **Angka pesanan yang sudah `lunas`/`batal` tidak bisa dihitung ulang dari perangkat.** Panggilan
   ber-`auth.uid()` pada status itu DITOLAK; **jalur pemicu peladen tetap sah** karena dibedakan
   dengan `pg_trigger_depth() = 0`. Penanda transaksi via `set_config` DITOLAK sebagai mekanisme
   karena bisa dipalsukan klien — itu persis celah K-1 yang baru ditutup (`resto.pembatalan_*`).
4. **Baris pesanan dikunci `for update`** selama perhitungan sehingga dua perhitungan bersamaan
   (temuan dugaan F-12) tidak saling menimpa angka; ini mengurangi risiko, bukan menutup tuntas —
   uji concurrency penuh masih pemilik `T1-45`.

**Alasan memilih menulis ulang `hitung_total` (bukan menambal di pemicu):** aturan uang harus hidup di
**satu tempat**; menambal di pemicu berarti dua rumus berbeda hidup berdampingan dan mudah saling
menyimpang. Berkas `0001`–`0014` tetap beku — seluruh perubahan hidup di
`supabase/migrations/0015_penutup_celah_putaran16.sql` **bagian 6**, dan migrasi itu belum disebar ke
proyek nyata saat keputusan ini dibuat.

**Bukti:** uji regresi baru `supabase/tes/urutan_uang.sql` (6 bagian: tanpa diskon, dengan diskon,
tiga langkah pembulatan, komponen tidak ikut dibulatkan, pesanan lunas tidak bisa dihitung ulang,
jalur pemicu peladen tetap hidup) · ekspektasi uji lama `supabase/tes/diskon_sesudah_lunas.sql`
**diselaraskan ke rumus benar** (29.700 → **29.498**, bukan mesin yang dilemahkan) ·
`alat/uji-mutasi-0015.py` kini **17 kasus**, empat di antaranya mengunci keputusan ini dan
**terbukti MERAH** ("pajak dari subtotal sebelum diskon", "pembulatan diabaikan", "penjaga lunas
dilepas", "pembulatan dibalik ke atas") · probe audit lama kini **GAGAL** = cacat terbukti hilang ·
suite `node alat/uji-sql.mjs` **46 LULUS · 0 GAGAL**.

---

## [Uang/2026-09-20] Tiga penjaga baru: metode bayar wajib aktif, pembatalan sekali per target, stempel lifecycle bukan milik perangkat

**Konteks (temuan K-2 audit AUD-3 2026-09-19, sesi `arena/01a0bbd2`):** tiga temuan K-2 yang
**dibuktikan nyata dengan probe sendiri** sebelum diperbaiki
(`docs/uji/audit/probe-2026-09-20/aud-3-f03-f05-f06-uang.sql`; probe LULUS = cacat ada):
(a) pembayaran lewat **metode bayar yang sudah dinonaktifkan pemilik** tetap diterima karena pemicu
menyamakan "baris metode ada" dengan "metode boleh dipakai"; (b) baris `pembatalan` **tidak
idempoten** — kiriman ulang (klik ganda kasir / antrean perangkat offline) masuk sebagai kejadian
KEDUA sehingga laporan kerugian menghitung satu aksi dua kali; (c) **stempel lifecycle pesanan**
(`dibayar_pada`, `dibatalkan_pada`, `alasan_batal`) bisa dikarang perangkat lewat UPDATE biasa —
laporan membaca "pernah dibayar/dibatalkan" untuk kejadian yang tidak ada.

**Keputusan:**
1. **Metode bayar wajib AKTIF.** Pemicu pembayaran memeriksa `metode_bayar.aktif`; metode yang
   dimatikan pemilik DITOLAK dengan pesan yang menyebut sebabnya ("sudah dinonaktifkan pemilik —
   pilih metode yang masih aktif"). Pilihan metode adalah pengaturan pemilik, bukan kesempatan kasir.
2. **Satu target pembatalan = satu jejak.** Target yang sudah `batal` (item atau pesanan) menolak
   baris `pembatalan` baru — termasuk bila alasannya diganti. Aturan ini dipilih di atas
   "kunci idempotensi pada kesamaan payload" supaya alasannya sederhana dan bisa diaudit: pembatalan
   kedua atas target yang sudah batal memang tidak punya arti. Dua item BERBEDA tetap bisa
   masing-masing dibatalkan sekali (dikunci uji sebagai kontrol positif).
3. **Stempel lifecycle hanya dari jalur peladen.** UPDATE dari perangkat menolak perubahan
   `dibayar_pada`, `dibatalkan_pada`, dan `alasan_batal` (termasuk MENGHAPUSNYA). Jalur peladen —
   pemicu pembatalan/pembayaran dan RPC SECURITY DEFINER — tetap bebas; pengirimannya ke dapur
   (`status` + `dikirim_ke_dapur_pada`) tetap boleh dari perangkat karena itu memang aksi kasir.

**Alasan bentuk perbaikan:** ketiganya ditambahkan sebagai **pemeriksaan pada pemicu yang sudah ada**
(versi barunya hidup di `0015` bagian 8 karena definisi lama ada di berkas beku `0012`/`0013`/`0014`),
bukan pemicu baru di jalur uang — supaya tidak ada dua tempat yang berebut menolak hal yang sama dan
pesan kesalahannya tetap satu.

**Bukti:** uji regresi baru `supabase/tes/metode_bayar_nonaktif.sql`, `supabase/tes/pembatalan_sekali.sql`,
dan `supabase/tes/lifecycle_pesanan.sql`; uji lama `supabase/tes/pembayaran.sql` **diselaraskan**
(kasus kerugian memakai pesanan kedua, karena aturan "satu target = satu jejak" membuat pembatalan
ulang atas pesanan yang sudah batal memang harus ditolak) · `alat/uji-mutasi-0015.py` kini **20 kasus**,
tiga di antaranya membalik masing-masing penjaga dan **terbukti MERAH** · probe audit ketiga kini
**GAGAL** = cacat terbukti hilang · suite `node alat/uji-sql.mjs` **50 LULUS · 0 GAGAL**.

---

## [Uang/2026-09-20] Status item hanya maju satu langkah, dan pembatalan selalu punya jalur resmi (berjejak)

**Konteks (temuan K-2 audit AUD-3 2026-09-19 F-04, dibuktikan nyata lewat probe sendiri
`docs/uji/audit/probe-2026-09-20/aud-3-f04-status-item.sql`):** perangkat bisa (a) memasukkan
item yang **lahir `siap`** — melewati seluruh pemeriksaan "dapur sudah mulai?"; (b) melompat
`baru → siap`; (c) memundurkan status yang sudah maju; dan (d) **membatalkan item hanya dengan
mengubah kolom status** — tanpa alasan, tanpa baris `pembatalan`, tanpa nilai kerugian. Yang
terakhir itu mematikan seluruh rantai bukti pembatalan (Aturan Bisnis 7) dan membuat laporan
kerugian tidak bisa dipercaya.

**Keputusan:**
1. **Status item hanya maju satu langkah: `baru → dimasak → siap`** (aturan terkunci TECH_SPEC
   ART-4). Item baru WAJIB lahir `baru`; lompatan, mundur, dan "menghidupkan kembali" item yang
   sudah batal ditolak.
2. **`batal` bukan transisi biasa.** Satu-satunya jalur yang sah adalah **baris `pembatalan`
   resmi** (beralasan; wajib persetujuan PIN atasannya bila dapur sudah mulai). Pemicu baris itu
   yang menandai item `batal` dan mencatat nilai kerugian dari salinan harga.
3. **Jalur peladen tetap bebas** (peran pemilik tabel / `service_role`): pemicu pembatalan dan
   fungsi peladen tidak ikut tertahan; begitu pula penyiapan data & perbaikan keadaan.

**Alasan:** jalur pembatalan yang "lewat jalur belakang" membuat dua sumber kebenaran untuk
kejadian yang sama — satu dengan jejak, satu tanpa. Aturan transisi ini juga yang membuat arti
status item sama bagi dapur, kasir, dan laporan.

**Bukti:** uji regresi baru `supabase/tes/status_item_transisi.sql`; dua uji lama **diselaraskan**
ke jalur resmi — `supabase/tes/pesanan.sql` (kasir kini membatalkan lewat baris `pembatalan` dan
membuktikan pembatalan langsung DITOLAK) dan `supabase/tes/uang_peladen.sql` (item uji dibatalkan
lewat baris resmi) · `alat/uji-mutasi-0015.py` kini **21 kasus**; mutasi "aturan transisi dilepas"
**terbukti MERAH** · probe F-04 kini **GAGAL** = cacat terbukti hilang · suite
`node alat/uji-sql.mjs` **51 LULUS · 0 GAGAL**. **Catatan mekanisme:** karena definisi berlaku
`picu_item_jaga` kini hidup di bagian 9 (berkas beku `0009`–`0014` tidak disentuh), dua mutasi lama
yang menyunting definisi PERTAMA diperbaiki agar menyentuh definisi TERAKHIR — kalau tidak,
mutasinya tumpul (versi bagian 9 menimpa kembali).


## [Keamanan/2026-09-20] Satu aturan lingkup izin: admin cabang hanya cabangnya — di policy, bukan cuma di kertas

**Konteks (temuan K-2 audit AUD-3 2026-09-19 F-10, dibuktikan NYATA lewat probe sendiri
`docs/uji/audit/probe-2026-09-20/aud-3-f10-admin-cabang-izin.sql`):** tiga sumber tidak sepakat.
Kontrak (`docs/TECH_SPEC.md` §294, `docs/PRD.md` tentang cabang, `docs/DISCOVERY.md` butir 53)
berkata admin cabang hanya cabangnya; policy `izin_pilih` memakai `sepenyewa(pengguna_id)` =
SELURUH penyewa; ujinya (`supabase/tes/rls_pengguna.sql`) malah mengunci perilaku bocor itu
(8 baris). Akibat nyata di layar centang izin (M3): admin Cabang Pusat membaca izin pegawai
Cabang Dua.

**Keputusan:** aturan yang berlaku adalah **kontrak**, dan hanya ada SATU aturan:
1. Pegawai melihat izinnya sendiri.
2. Owner pusat melihat seluruh izin **restonya**.
3. Admin cabang melihat izin pegawai **yang bertugas di cabang yang sedang ia pakai** —
   sama seperti policy `pengguna_pilih`, supaya tidak lahir dua tafsir.
4. Sampai bagian ini belum ada RPC penulis `public.izin`, jadi tidak ada jalur tulis yang perlu
   diselaraskan; yang diperbaiki lingkup BACA.

**Alasan:** aturan keamanan yang hanya hidup di dokumen = aturan yang tidak ditegakkan. Ketika
policy, uji, dan kontrak berbeda, yang menang dalam praktik adalah policy — jadi policy-nya yang
harus diselaraskan ke kontrak, bukan ujinya dibuat nyaman.

**Bukti:** bagian 11 `supabase/migrations/0015_penutup_celah_putaran16.sql` · uji
`supabase/tes/rls_pengguna.sql` §5 dikoreksi (4 baris + larangan melihat izin pegawai cabang lain)
· mutasi "lingkup baca izin dikembalikan ke se-penyewa" **terbukti MERAH** di
`alat/uji-mutasi-0015.py` · probe F-10 kini **GAGAL** = cacat terbukti hilang.

## [Keamanan/2026-09-20] Helper hierarki PIN bukan alat klien: hak execute dicabut + identitas dipakukan

**Konteks (temuan K-2 audit AUD-3 2026-09-19 F-11, dibuktikan NYATA lewat probe sendiri
`docs/uji/audit/probe-2026-09-20/aud-3-f11-helper-pin.sql`):** `peran_lebih_tinggi(p_pemanggil,
p_target)` adalah `SECURITY DEFINER`, diberi execute ke `authenticated`, dan menerima DUA UUID
bebas tanpa membandingkan `p_pemanggil` dengan `auth.uid()`. Dari kursi kasir, satu `select`
cukup untuk memetakan hierarki peran siapa pun — termasuk pegawai resto lain.

**Keputusan (dua lapis, sesuai anjuran laporan):**
1. **Tidak callable klien:** hak execute dicabut dari `public` & `authenticated`; pemakai
   sebenarnya (`simpan_pin`, `SECURITY DEFINER`) tetap bisa memanggilnya.
2. **Identitas dipakukan:** bila ada pemanggil ber-JWT, `p_pemanggil` WAJIB dirinya sendiri;
   selain itu jawabannya `false` — menolak, bukan menjawab atas nama orang lain. Tanpa identitas
   (penyiapan/`service_role`) pemeriksaan dilewati seperti jalur peladen lain di proyek ini.
3. **Aturan umum:** pemeriksaan "atasan" harus bertumpu pada identitas yang sedang masuk, bukan
   UUID kiriman perangkat.

**Bukti:** bagian 10 `supabase/migrations/0015_penutup_celah_putaran16.sql` · uji
`supabase/tes/pin_helper_pribadi.sql` — termasuk skenario "jalur baru tanpa pembungkus identitas"
(pembungkus `SECURITY DEFINER` yang mewakili jalur itu **tidak** bisa mengaku atasan) dan kontrol
bahwa owner tetap boleh mengganti PIN bawahan · 2 mutasi wajib-MERAH ("hak execute dikembalikan",
"pemakuan identitas dilepas") · probe F-11 kini **GAGAL**.

## [Uang/2026-09-20] Nomor pesanan diambil di bawah kunci — tetapi temuan F-12/F-13 BELUM dicap selesai

**Konteks (temuan K-1/K-2 audit AUD-3 2026-09-19 F-12 & F-13, status **DUGAAN**):** hitungan uang
dan nomor pesanan dikerjakan tanpa serialisasi eksplisit, sehingga dua pengiriman bersamaan
berpotensi membaca angka yang sama.

**Keputusan:**
1. **F-13 dirampungkan di mesin:** `nomor_pesanan_berikutnya()` kini mengambil nomor di bawah
   `pg_advisory_xact_lock` per (cabang, tanggal) dan ditandai **VOLATILE** (bukan STABLE) supaya
   kunci memang boleh dipakai. Batas nyata yang sudah ada sebelumnya: kolom `nomor` UNIK per
   (cabang, tanggal) — jadi nomor kembar tidak bisa tersimpan; yang dulu bisa terjadi hanyalah
   INSERT kedua gagal karena bentrok.
2. **F-12** sudah diredam di bagian 6 (`for update` pada baris pesanan sebelum pemeriksaan uang).
3. **Keduanya TETAP TERBUKA (dipagari) dan TIDAK dicap DITUTUP.** Pembuktian yang diminta laporan
   adalah uji dua transaksi nyata; lingkungan uji proyek (PGlite) berjalan di satu koneksi sehingga
   uji itu belum bisa dijalankan. Yang dijaga mesin sekarang adalah **sifat serialisasinya**
   (fungsi volatile + pemanggilan kunci benar-benar ada) lewat `supabase/tes/nomor_pesanan_kunci.sql`
   dan 2 mutasi wajib-MERAH.

**Alasan menahan klaim:** project ini sudah dua kali membayar mahal karena "hijau" yang ternyata
tidak menguji apa-apa. Lebih jujur menulis "dipagari, uji concurrency menyusul" daripada menutup
temuan dengan bukti yang tidak ada.


## [Keamanan/2026-09-20] Katalog cacat kalibrasi dikeluarkan dari repo — penilai ketajaman auditor tidak boleh bisa mencontek

**Konteks (temuan audit H F-01, K-2, 2026-09-20):** `alat/kalibrasi-cacat.json` memuat pasangan `cari`/`ganti`
dari setiap cacat yang ditanam untuk menguji ketajaman auditor/peninjau. Selama berkas itu hidup di dalam repo,
siapa pun yang bisa membaca repo — dan auditor memang pekerjaannya membaca repo — bisa mencocokkan cacat yang
ditanam, lalu menulis skor `Ditemukan: X dari Y` yang sempurna tanpa mengulas apa pun. Bantah-balik sesi kerja
menemukan cacatnya **lebih parah dari dugaan laporan**: salinan kalibrasi jalur mesin dulu dibuat dengan
`git worktree add`, sehingga `git diff`/`git show` **di dalam salinan auditor** langsung memperlihatkan baris mana
yang ditanami cacat (cacat ditanam sebagai perubahan belum-di-commit).

**Keputusan (izin Lee 2026-09-20 — *"Aku ikut yang terbaik menurut kamu. Klo sebaiknya dikeluarkan, silahkan
keluarkan"*):**

1. **Katalog cacat DIPINDAH ke luar repo** — hidup di `KALIBRASI_DIR` (baku `/home/user/.kalibrasi/kalibrasi-cacat.json`),
   berjejak di `docs/uji/BERKAS_PENSIUN.md` baris #2 (siapa memutuskan, kapan, kenapa, nasib isi).
2. **Jalur mesin:** salinan auditor dibuat lewat `git archive` + satu commit bersih (**tanpa riwayat Git bermakna**)
   dan katalog **dikeluarkan** dari salinan; `pastikan_salinan_bersih()` menolak salinan yang masih membawa katalog,
   berkas kunci kalibrasi, lebih dari satu commit, atau perubahan belum-di-commit.
3. **Gagal-tertutup:** alat membaca katalog **hanya** dari luar repo; bila tidak ada, ia menolak berjalan (lebih baik
   kalibrasi tidak jalan daripada skornya bisa dipalsukan).
4. **Aturan berlaku umum:** berkas yang memuat jawaban latihan/uji apa pun tidak boleh hidup di repo yang sedang diuji.

**Bukti:** `alat/periksa-kunci-kalibrasi.py` aturan **A2/F/G** + `--uji-diri` **13 kasus** semuanya menolak;
`python3 alat/audit-independen.py --kalibrasi-siapkan` berjalan dengan salinan bersih (katalog tidak ada, satu commit,
`git diff` kosong); `python3 alat/review-pr.py --kalibrasi-pr-siapkan` berjalan (bahan + kunci di luar repo);
`python3 alat/periksa-rujukan.py` kini mengakui daftar pensiun sehingga riwayat yang jujur tidak dianggap rujukan mati.

## [Infrastruktur/2026-09-20] Versi Node yang diiklankan DITURUNKAN dari pustaka terkunci — bukan ditulis tangan

**Konteks (temuan audit I F-21, K-3, 2026-09-19):** `aplikasi/package.json` mengiklankan `engines.node: ">=20"` dan
`aplikasi/README.md` menulis "Node.js 22 (minimal 20)", padahal pustaka yang terkunci menuntut lebih:
`@supabase/supabase-js` **>=22.0.0** dan `vitest` **^22.12.0 || ^24.0.0 || >=26.0.0**. Orang yang mengikuti README bisa
memasang versi yang tidak didukung pustaka wajib aplikasi — iklan yang salah arah, walau hanya kelas K-3.
Dugaan penyebab di laporan (lock diperbarui tanpa menyelaraskan prasyarat) terbukti: angka di dokumen ditulis tangan.

**Keputusan:**

1. **Batas minimum yang diiklankan = `>=22.12.0`** (batas bawah tertinggi dari seluruh entri lock yang **bukan opsional**).
   Angka ini **diturunkan mesin** oleh `aplikasi/alat/periksa-node.py`, bukan ditulis tangan lagi.
2. **Entri opsional tidak menaikkan syarat minimum** (mis. `@napi-rs/lzma-linux-x64-gnu` bawaan rollup meminta ^22.20).
   Alasannya: npm melewati dependensi opsional yang tidak cocok dengan versi Node, jadi versi itu tidak boleh
   memaksa pengguna menaikkan Node. Aturan ini dikunci kontrol `--uji-diri` (entri opsional menuntut Node 30 → tetap LOLOS).
3. **Iklan dan mesin harus sama**: `aplikasi/README.md` wajib menyebut batas yang sama (`22.12+`). Beda ke arah mana pun
   ditolak pemeriksa.
4. **CI menjalankan versi yang diiklankan**: ketiga alur GitHub memakai `node-version: '22.12.0'`. Jadi janji "minimum
   22.12" diuji sungguhan oleh CI, dan bentuk satu angka (`'22'`) ditolak penjaga karena berarti 22.0.0.
5. **Bentuk `engines` wajib `>=X`** (persis). Bentuk lain (`^22.12.0`, `22.x`) ditolak supaya pemeriksa tidak menebak.
6. **Gagal-tertutup**: kalau `engines.node` hilang dari lock (tidak ada bukti apa pun), pemeriksa MENOLAK — jangan
   mengaku selaras tanpa bukti.

**Bukti:** `aplikasi/alat/periksa-node.py` LOLOS (kebutuhan 22.12.0 dari 187 entri non-opsional; iklan, README, 3 alur, dan
Node lingkungan 22.22.3 semuanya memenuhi) · `--uji-diri` 9 kasus (1 salinan utuh diterima · 7 mutasi ditolak · 1 kontrol) ·
`alat/periksa-gerbang-ci.py` menolak bila langkah pemeriksa ini dihapus dari CI.

## [Mekanisme/2026-09-20] Nama uji tidak boleh lebih kuat daripada yang diuji

**Konteks (temuan audit I F-19, K-3, 2026-09-19):** uji bernama `'memanggil onUbah saat diisi'` hanya merender HTML
(SSR), memeriksa `type="text"`, lalu justru memastikan callback **TIDAK** terpanggil. Rangkaian uji tetap hijau walau
`onChange` tidak tersambung ke apa pun. Ini kelas cacat yang berbahaya justru karena tampak aman: "86 uji terbaca"
padahal sebagian tidak membuktikan apa yang dijanjikan namanya.

**Keputusan:**

1. **Uji yang namanya menjanjikan interaksi wajib memicu kejadian.** Kata janji yang diawasi:
   "saat diisi/diklik/ditekan/diubah/diketik/dipilih/dikirim/di-submit/digulir/disentuh", "memanggil on…", "memicu on…".
   Bukti tindakan yang diterima: `fireEvent`, `userEvent`, `dispatchEvent`, atau `.click(`/`.focus(`/`.blur(`/`.type(`/`.keyboard(`.
2. **Ditegakkan mesin, bukan disiplin:** `aplikasi/alat/periksa-uji.py` aturan 3 memeriksa tiap `it(`/`test(` per berkas uji
   di `src/` dan `e2e/`, menyebut **berkas:baris** saat menolak. Badan uji yang tidak terbaca (bentuk berkas di luar
   dugaan) juga dianggap GAGAL — pemeriksa tidak boleh buta diam-diam.
3. **Bukan uji interaksi? Ganti namanya.** Kalau sebuah uji memang hanya memeriksa markup, namanya tidak boleh memakai
   kata janji di atas. Ini menjaga nama uji sebagai kontrak.
4. **Uji interaksi memakai DOM nyata:** berkas uji yang butuh interaksi memakai `// @vitest-environment jsdom` (per berkas)
   + `@testing-library/react`; uji markup lain di berkas yang sama tetap boleh SSR.

**Bukti:** penjaga menunjuk cacat aslinya sebelum diperbaiki
(`aplikasi/src/komponen/komponen.test.tsx:145`) dan LOLOS sesudahnya · uji baru **merah** saat handler `onChange` dilepas
maupun saat nilainya salah, **hijau** saat dipulihkan (18 uji) · `aplikasi/alat/periksa-uji.py --uji-diri` **5 kasus**
semuanya sesuai harapan · `--uji-diri` ikut CI + `aplikasi/alat/periksa-semua.sh` dan terdaftar di gerbang wajib.

## [Mekanisme/2026-09-20] Uji aplikasi dibuktikan bisa MERAH: harness mutasi kode aplikasi

**Konteks (tiga temuan audit ditutup bersamaan, semuanya kelas yang sama — "alat bilang aman, padahal belum terbukti"):**
**I F-19** uji bernama "memanggil onUbah saat diisi" tidak pernah mengisi input; **F F-14 / I F-05**
`ujiSambungan()` melaporkan "berhasil" hanya dari kesehatan Auth walau jalur data menolak/gagal;
**I F-06** kegagalan `localStorage` (izin ditolak / penyimpanan penuh) menembus helper tema dan memutus
effect React. Ketiganya lolos karena **tidak ada satu pun mekanisme yang membuktikan uji aplikasi bisa MERAH**.

**Keputusan:**

1. **Harness baru `aplikasi/alat/uji-mutasi-app.mjs`** (setara `alat/uji-mutasi-*.py` untuk SQL): salinan
   `aplikasi/` dibuat di folder sementara (`node_modules` disambung), salinan **utuh wajib hijau** dulu
   (kontrol), lalu tiap mutasi perilaku WAJIB membuat uji MERAH. Tidak ada berkas repo yang disentuh.
2. **Merah palsu tidak diterima.** Pelajaran nyata saat membuat harness ini: opsi `--reporter=basic` sudah
   tidak ada di Vitest 5, dan akibatnya SEMUA mutasi terlihat "merah" padahal ujinya tidak pernah jalan
   (vitest keluar bukan-nol saat gagal mulai). Harness sekarang hanya menerima merah yang keluarannya benar-benar
   memuat kegagalan uji dan **bukan** galat startup (`merahSah`).
3. **Gagal-tertutup:** pola mutasi yang tidak ketemu di kode = harness GAGAL (berarti mutasinya tidak diterapkan,
   sehingga tidak membuktikan apa pun). `--uji-diri` membuktikan dua hal: pola salah ditolak, dan saat uji
   dilemahkan (assert interaksi dibuang) mutasi yang sama memang terdeteksi lolos.
4. **Wajib jalan di CI** (sesudah `npm test`) + `aplikasi/alat/periksa-semua.sh`, dan **terdaftar di gerbang wajib**
   `alat/periksa-gerbang-ci.py` supaya tidak bisa dihapus dari CI secara senyap.

**Bukti:** salinan utuh hijau + 5 mutasi perilaku semuanya MERAH (handler `onChange` dilepas · nilai callback
dirusak · `ok` sambungan kembali melihat Auth saja · `getItem` tanpa penjagaan · `setItem` tanpa penjagaan) ·
`--uji-diri` 2/2 sesuai harapan · `--uji-diri` ikut CI.

## [Keamanan/2026-09-20] Penutup celah PIN putaran18 (0016): kecocokan rahasia ≠ otorisasi, dan kontrak pesan `simpan_pin`

**Konteks (empat temuan audit I ditutup satu migrasi, `supabase/migrations/0016_penutup_celah_pin_putaran18.sql`):**
**I F-15** pemanggil nonaktif (`penyewa_saya()` NULL) dulu tetap dilayani pencocokan kredensial;
**I F-16** `verifikasi_pin` (0012) menyimpan baris `berhasil=true` SEBELUM menolak izin aksi, dan konsumen kupon
diskon hanya menyaring baris itu — "PIN benar tetapi tidak berizin" bisa menjadi stempel diskon;
**I F-14** dua jalur `simpan_pin` memakai RAISE sesudah insert catatan percobaan → transaksi abort → catatan hilang
→ pembatas tebakan tidak pernah menyala untuk jalur "PIN lama salah" & "hierarki peran";
**I F-13** helper perbandingan peran bisa menjadi oracle lintas penyewa bila dipanggil pemegang `service_role`.

**Keputusan:**

1. **Kecocokan rahasia BUKAN otorisasi.** Setiap konsumen bukti PIN (void 0013, diskon 0016) WAJIB mengecek ulang
   izin penyetuju saat kupon dikonsumsi (`boleh_untuk(disetujui_oleh, aksi)`). Baris `berhasil=true` di
   `percobaan_pin` hanya berarti "rahasia cocok" — tidak pernah berarti "boleh".
2. **Jawaban seragam untuk pemanggil tak dikenal.** `verifikasi_pin` menolak pemanggil nonaktif/lintas-resto dengan
   `'PIN tidak dikenali.'` SEBELUM kredensial disentuh — tanpa membocorkan keberadaan/status akun.
3. **Kontrak baru `simpan_pin`: PENOLAKAN = PESAN, bukan exception.** Semua jalur penolakan (PIN lemah · kembar ·
   PIN lama salah · hierarki peran · melebihi batas) mengembalikan teks penolakan dan transaksi TETAP commit supaya
   catatan percobaan bertahan. Konsekuensi yang diterima sadar: pemanggil harus membaca pesan (bukan mengandalkan
   error); uji yang dulu memakai `uji.harap_gagal` dikonversi ke asersi pesan (`uji.sama(... like ...)`).
4. **Pagar tenant di helper hierarki.** `peran_lebih_tinggi` menolak perbandingan lintas penyewa bahkan dari
   `service_role`; lapisan pertama tetap pinning `auth.uid()` (F-11, 0015) dan ACL (execute hanya service_role).
5. **Aturan harness ikut diperbarui:** yang berlaku adalah `create or replace` TERAKHIR — dua mutasi
   `alat/uji-mutasi-0015.py` (pesan PIN kembar PR-04 · pemakuan identitas F-11) kini diarahkan ke 0016.
   Blok uji yang butuh pesanan di luar fixture global WAJIB membuat pesannya sendiri (state antar-berkas
   persisten dalam satu run) dan memilih nominal di dalam batas pemohon, supaya yang menolak pastilah pagar
   yang diuji — pelajaran nyata: nominal 3.000 (5,56%) ditolak `diskon_batas` duluan sehingga mutasi F-16
   sempat terlihat tumpul (false-green).

**Bukti:** suite SQL **53 LULUS · 0 GAGAL** · `alat/uji-mutasi-0016.py` 6 mutasi wajib MERAH + kontrol hijau
(`--uji-diri` LOLOS; terdaftar dua arah: ci.yml + `alat/periksa-gerbang-ci.py` + `aplikasi/alat/periksa-semua.sh`) ·
`alat/uji-mutasi-0015.py` kembali LOLOS penuh setelah dua mutasinya diarahkan ke 0016.

## [Uang/2026-09-20] Sisa review putaran16 ditutup: kupon wajib pesanan, saldo awal wajib buku besar, riwayat meja dilindungi

**Konteks:** delapan temuan review putaran16 (PR-05…PR-09, PR-13…PR-15) diverifikasi ulang dengan probe sendiri
lalu ditutup — lima di antaranya lewat `supabase/migrations/0016_penutup_celah_pin_putaran18.sql`.

**Keputusan:**

1. **Kupon persetujuan wajib terikat pesanan di LAPIS DATABASE (PR-07).** `verifikasi_pin` menolak aksi
   `void_sesudah_dapur`/`beri_diskon` tanpa `p_pesanan_id` (pesan + percobaan tercatat, ikut pembatas).
   Edge Function sudah menolak di batas (I F-02) — ini lapis keduanya, supaya jalur RPC langsung tidak
   bisa melahirkan kupon buntu ("tulis bisa, pakai mustahil").
2. **Saldo awal stok wajib lewat buku besar (PR-08).** INSERT `stok_bahan` dengan `jumlah` bukan-nol DITOLAK;
   bahan lahir dengan saldo 0 dan saldo awal dicatat sebagai baris `stok_pergerakan` yang otomatis menjumlah
   ke saldo. Buku besar tetap satu-satunya asal-usul angka stok (penjaga UPDATE 0007 tidak berubah).
3. **PIN warisan 4 angka: naik kelas swadaya, bukan buntu (PR-09).** PIN 4 angka diterima HANYA sebagai
   `p_pin_lama` di `simpan_pin` (dicocokkan langsung ke hash, pembatas 5×/15 menit + catatan `percobaan_pin`
   tetap jalan); verifikasi masuk tetap menuntut 6 angka — aturan 6 angka tidak dilonggarkan.
4. **Hak fungsi dikoreksi DUA arah (PR-14).** `service_role` dipulihkan pada `hitung_total` (jalur peladen
   tidak boleh ikut mati oleh `revoke ... from public`), sementara `peringkat_peran` DICABUT dari anon —
   peta hierarki peran bukan konsumsi publik. Prinsip: revoke massal wajib diikuti audit siapa lagi yang
   kehilangan hak sah.
5. **Riwayat meja dilindungi (PR-15).** Meja yang punya riwayat pesanan (termasuk lunas/batal) tidak bisa
   dihapus — `on delete set null` tidak lagi bisa mencabut "meja mana" dari laporan; jalur yang benar adalah
   nonaktifkan (`aktif = false`). Jalur peladen (`peran_peladen()`) tetap dikecualikan seperti desain 0014.

**Bukti:** 5 berkas uji baru (`kupon_wajib_pesanan`, `pin_warisan`, `saldo_awal_stok`, `hak_fungsi`,
`meja_riwayat`) · suite SQL **58 LULUS · 0 GAGAL** · `alat/uji-mutasi-0016.py` **11 mutasi wajib MERAH**
+ kontrol hijau · probe lama pr05/06/07/08/09/14 kini GAGAL (= cacat hilang); pr15 tetap hijau HANYA karena
probe memakai jalur superuser yang memang melewati penjaga — dicatat jujur, cacat sisi klien ditutup dan
dibuktikan uji regresi + mutasi.

## [Mekanisme/2026-09-20] Migrasi 0015+0016 disebar ke proyek nyata dan dibekukan (sidik sampai 0016)

**Konteks:** atas izin Lee ("Silahkan Sebar"), alur sengaja `sebar-skema.yml` dijalankan untuk pertama
kalinya sejak pembekuan `0001`–`0014`: run `35516000988` hijau berurutan (cek penanda & rahasia →
pratinjau `--dry-run` → `db push` → `migration list` sebagai bukti). Run pertama sebelumnya gagal di
gerbang rahasia karena token Supabase kedaluwarsa; Lee mengganti dengan **token scoped** baru
(proyek Resto-Barokah saja, 90 hari).

**Keputusan:**

1. `0015` dan `0016` masuk daftar beku `alat/periksa-migrasi-beku.py` (sidik SHA-256) dan
   `NOMOR_TERTINGGI_BEKU` naik 14 → **16**; skema berikutnya WAJIB berkas `0017`+.
2. Penanda `supabase/SEBAR-SKEMA` dihapus lagi sesudah hijau (alur yang menyala tanpa penanda
   berhenti sendiri di pemeriksaan `test -f`).
3. Penyebaran berikutnya tetap langkah pemilik BARU — persetujuan "Silahkan Sebar" tidak berlaku
   berulang. Token scoped 90 hari dicatat: perbarui ± 19 Desember 2026 bila dipakai lagi.

**Bukti:** run `35516000988` hijau (semua langkah success) · `python3 alat/periksa-migrasi-beku.py`
LOLOS + `--uji-diri` LOLOS (kasus "berkas baru sah" disegarkan ke `0017`).

---

## [Mekanisme/2026-09-20] Pemicu satu kalimat untuk pemeriksaan/audit/review (AL-15) — prompt pendek

**Keputusan Lee:** "Aku mau mekanisme review dan audit dan pemeriksaan itu semua dibuat lebih
mudah dikerjakan… aku tinggal bilang kata-kata simple… agent kasih prompt yang singkat… setelah
selesai, agent sesi independen otomatis masukin hasilnya ke GitHub" — disetujui ("Baik, aku setuju")
setelah agent menyampaikan kritik & rancangan.

**Aturan yang dikunci:**
1. Pemicu sederhana → mesin: `python3 alat/siapkan-pemeriksaan.py --frasa "<kalimat Lee>"`
   (menyeluruh · bidang keamanan · review PR · fondasi). Frasa tak dikenal DITOLAK, bukan ditebak.
2. Yang Lee tempel ke sesi baru hanyalah PROMPT PENDEK (≤10 baris) berisi SATU URL berkas
   SIAP-TEMPEL + identitas paket + commit target. Prompt panjang TIDAK dihapus — ia tetap berkas
   paket di repo, terjaga `periksa-paket.py` (gerbang CI-hijau H F-02 tetap berlaku saat membuat).
3. `--prompt-pendek` MENOLAK mencetak bila berkas paket belum masuk commit HEAD atau HEAD belum
   di-push (URL harus bisa dibuka dari luar).
4. Jalur balik laporan tetap seperti semula: laporan = berkas Git di cabang sesi independen,
   ditarik `--ambil-laporan` (idempoten); jalur tempel manual tetap sah sebagai cadangan.
5. Audit bidang (`--bidang keamanan`) = audit menyeluruh yang dipersempit prefiks berkas;
   temuan di LUAR lingkup tetap wajib dilaporkan (lingkup = kedalaman wajib, bukan izin melapor).
6. Penjaga: `alat/siapkan-pemeriksaan.py --uji-diri` (13 kasus) terdaftar di CI + gerbang wajib
   + mutasi "langkah dihapus → ditolak" di `periksa-gerbang-ci.py` + `periksa-semua.sh`;
   buku induk dapat alur **AL-15** (`periksa-panduan.py` MIN_ALUR 14→15).

## [Uang/2026-09-21] Pesanan yang sudah lunas/batal beku TOTAL bagi perangkat (bukan cuma nilai uang)

**Konteks (temuan H F-07 audit AUD-3 2026-09-20, sesi `arena/01a0bf6e`):** pembekuan
"pesanan tertutup" sebelumnya hanya dijaga pada nilai uang (0013/0014/0015), item &
baris diskon (0015 D F-01), dan stempel lifecycle (0015 F-06). Probe
`docs/uji/audit/probe-2026-09-21/h-f07-kolom-non-uang.sql` membuktikan kasir masih bisa
menulis `catatan`/`tipe`/`shift_id` pesanan yang sudah `lunas`/`batal` — laporan membaca
jejak yang tidak pernah terjadi.

**Keputusan:** migrasi `supabase/migrations/0017_pesanan_tertutup_beku.sql` — pemicu
BEFORE UPDATE `picu_pesanan_tertutup_beku` menolak SETIAP perubahan baris pesanan
`lunas`/`batal` yang datang dari jalur perangkat (`new is distinct from old`). Jalur
peladen (pemicu pembayaran/pembatalan, RPC SECURITY DEFINER) tetap bebas lewat pola
bypass teruji `auth.uid() is null or public.peran_peladen()` (sama dengan
`picu_pesanan_jejak_jujur` 0015). Koreksi resmi = kejadian baru berjejak, bukan tulis
ulang baris — konsisten dengan [Uang/2026-09-20] (tolak hitung-ulang perangkat pada
pesanan tertutup).

**Bukti:** probe kini GAGAL (cacat hilang) · uji `supabase/tes/pesanan_tertutup_beku.sql`
(kontrol draf boleh diubah; lunas & batal ditolak dengan sebab terpaku; jalur peladen
tetap sah; uang tetap konsisten) · suite SQL **59 LULUS · 0 GAGAL** ·
`alat/uji-mutasi-0017.py` 3 mutasi WAJIB MERAH terbukti (penjaga dihapus · batal tak ikut
beku · beku menyempit ke kolom status) + gerbang CI baru di `periksa-gerbang-ci.py`.

## [Keamanan/2026-09-21] Perangkat terdaftar: identitas perangkat terverifikasi untuk PIN (T1-24 inti, K F-03, F-11 §1b)

**Konteks:** lapis kedua pembatas PIN (12×/15 menit, melintasi akun) di-key pada NAMA
perangkat kiriman klien — penyerang yang memutar nama mendapat jatah baru (temuan
K F-03 / F-11 laporan 2026-09-17; lapis pertama 5×/akun tetap bekerja). ROADMAP T1-24
mengamanatkan identitas perangkat terverifikasi + `perangkat_sah()` + penolakan
perangkat tak terdaftar, dengan uji `percobaan_pin_perangkat.sql` yang DIPERKETAT.

**Keputusan:** migrasi `supabase/migrations/0018_perangkat_terdaftar.sql`:
* tabel `perangkat` (RLS baca hanya `kelola_pegawai`) + `kredensial_perangkat`
  (hash bcrypt, TANPA grant klien — pola `kredensial_pin` 0006/K-3);
* `daftarkan_perangkat`/`cabut_perangkat` = RPC izin `kelola_pegawai`, cabang wajib
  dalam `cabang_ids_saya()`; kunci minimal 16 karakter (dibangkitkan aplikasi);
* `perangkat_sah(id, kunci)` = pemeriksa internal, execute klien DICABUT (pola F-11);
* `verifikasi_pin`/`simpan_pin`/`ganti_pin` memakai `(perangkat_id, perangkat_kunci)`;
  perangkat tak terdaftar/nonaktif/kunci salah → jawaban SERAGAM
  `'Perangkat tidak dikenali.'` (anti-oracle, konsisten 'PIN tidak dikenali.');
* nama yang dicatat di `percobaan_pin` dari tabel (bukan kiriman klien); lapis 12×
  di-key pada `perangkat_id`; tanda tangan lama (p_perangkat text) DI-DROP.
* Edge Function `verifikasi_pin` menyaring bentuk `perangkat_id`/`perangkat_kunci`
  di batas; keputusan sah/tidak tetap di database.
* Sisa DoD T1-24 (kode pendaftaran sekali pakai, `persetujuan_perangkat`, gating
  bagian staf via sesi perangkat) lanjut di T1-25/Fase 1C — kotak T1-24 belum dicentang.

**Bukti:** uji `supabase/tes/percobaan_pin_perangkat.sql` diperketat (perangkat
karangan dilayani 0×; kunci salah & perangkat dicabut dijawab seragam; lapis 12×
hidup di perangkat_id; PR-13 dipertahankan) + `supabase/tes/perangkat_registrasi.sql`
(izin, hash bukan teks, RLS, anti-oracle); suite SQL **60 LULUS · 0 GAGAL**;
`alat/uji-mutasi-0018.py` 3 mutasi wajib MERAH terbukti + gerbang CI baru;
`node alat/uji-edge-pin.mjs` 19/19 (kasus E14/E15 baru); `periksa-fungsi-pin` 14/14.

## [Pesan/2026-09-21] Pesan diskon menunjuk alur yang NYATA — menutup D F-10

**Konteks:** penolakan diskon berbunyi "Minta persetujuan atasan (PIN)." padahal alur
persetujuan-diskon-berbasis-PIN belum ada (kupon tidak menaikkan batas pemanggil;
`approve_diskon` baru rencana T1-30/T1-40). Kasir disuruh menunggu sesuatu yang tidak
pernah datang (temuan D F-10, laporan D 2026-09-18).

**Keputusan:** migrasi `supabase/migrations/0019_pesan_diskon_jujur.sql` mengganti
kalimat menjadi "Diskon ini melebihi batas izin Anda — minta atasan (pemilik/admin)
yang memproses." — jalan yang benar-benar ada hari ini adalah izin `beri_diskon`
berbasis peran. Logika pemicu TIDAK berubah; badan disalin utuh dari definisi berlaku
(0013) supaya tidak membawa pulang perilaku lama 0010/0012. Bila `approve_diskon`
(PIN sungguhan) mendarat di T1-30/T1-40, pesan ini diperbarui lagi ke alur itu.

**Bukti:** pin pesan di `diskon_cap.sql`/`diskon_persen.sql`/`diskon_voucher.sql`/
`pembayaran.sql` ikut disegarkan — sebelum penyegaran keempatnya MERAH
(SEBAB BUKAN YANG DIHARAPKAN), membuktikan pin pesan hidup; sesudahnya suite penuh
**60 LULUS · 0 GAGAL**.

## [Keamanan/2026-09-21] Nama perangkat boleh dipakai ulang sesudah dicabut (panen T-02)

**Konteks:** DoD T-02 (d) menuntut nama perangkat bisa dipakai ulang sesudah
perangkat lama dicabut, tetapi migrasi 0018 memasang `UNIQUE(penyewa_id, nama)`
sementara `cabut_perangkat` hanya mengubah `aktif=false`. Pekerja T-02 berhenti
sesuai AL-16 dengan bukti reproduksi; keputusan di tangan integrator.

**Keputusan:** DoD benar, constraint yang cacat. `UNIQUE(penyewa_id, nama)` di
`supabase/migrations/0018_perangkat_terdaftar.sql` diganti indeks unik parsial
`perangkat_nama_aktif_unik ... WHERE aktif` (in-place; 0018 belum deploy —
preseden 0015). Nama perangkat bersifat posisional ("hp-kasir-1"); otentikasi
tidak terpengaruh karena `perangkat_sah` memakai id+kunci+aktif dan catatan
audit memakai id.

**Bukti:** `supabase/tes/perangkat_registrasi_tepi.sql` (DoD a-e, dilengkapi
integrator dari bukti pekerja) LULUS; suite SQL **61 LULUS · 0 GAGAL**;
`alat/uji-mutasi-0018.py` LOLOS; `node alat/uji-edge-pin.mjs` 19/19;
`alat/periksa-fungsi-pin.py` 14/14.

## [Keamanan/2026-09-21] Tabel catatan_audit mendarat tanpa trigger dulu (panen T-01)

**Konteks:** temuan F F-07 (tabel audit wajib belum ada; pemilik T1-13). Maraton T-01 membangun tabel + RLS + uji; DoD papan T-01 eksplisit "TANPA trigger dulu" (lingkup eksklusif, tidak menyentuh fungsi lain).

**Keputusan:** DITERIMA dengan cakupan jujur: tulis klien (`anon`/`authenticated`, termasuk admin) DITOLAK di level grant; tulis hanya jalur peladen/`service_role`; baca = penyewa sama + izin `kelola_pegawai`. Sisa DoD T1-13 (trigger tolak UPDATE/DELETE termasuk owner & service_role) TIDAK ikut mendarat — T1-13 tetap `[ ]`, F F-07 tetap TERBUKA dengan catatan progres.

**Bukti:** `supabase/tes/catatan_audit.sql` LULUS; suite SQL **62 LULUS · 0 GAGAL**; `rls_semua_tabel.sql` otomatis mencakup tabel baru.

## [Mekanisme-audit/2026-09-21] Lingkup paket dari pohon target; validator tanpa banding per-grup

**Konteks:** temuan B F-16 (tabel lingkup 333/334 + angka `_sistem` 16-vs-15; terakhir dari 3 temuan `T1-44`).

**Keputusan:** (1) pembuat paket baca pohon commit target (`git ls-tree`), bukan indeks meja kerja; (2) tiap paket menandai sumber angka + berkasnya sendiri di luar hitungan; (3) Aturan 6 `alat/periksa-paket.py` menegakkan jumlah-grup = total = pohon + tak-tertutup [] + penanda — tetapi SENGAJA tidak membandingkan angka per grup satu-satu supaya definisi grup boleh bertambah tanpa memalsukan paket lama; (4) paket lama (< 2026-09-21) dikecualikan via gerbang tanggal (tak boleh disunting, F-11).

**Bukti:** `python3 alat/audit-independen.py --uji-diri` (kebal meja kotor) + `python3 alat/periksa-paket.py --uji-diri` (7 kasus Aturan 6) LOLOS; hitung ulang target `4fccc9d5` → 334/15/[].
