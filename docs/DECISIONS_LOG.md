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
  4. **Pembayaran tidak boleh melebihi total pesanan.** Bila `total` masih 0 (belum dihitung `hitung_total`), pemeriksaan dilewati supaya pencatatan tidak macet — celah sementara ini **tertutup di T1-15** karena pembayaran hanya sah setelah total dihitung.
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
- **File terkait:** `supabase/migrations/0012_perangkat.sql`, `supabase/migrations/0013_sesi_perangkat.sql`, `supabase/tes/perangkat.sql`, `supabase/tes/sesi_perangkat.sql`, `docs/KEAMANAN.md`
- **Implikasi:** 1) Seluruh policy RLS untuk peran staf wajib memakai `perangkat_sah()` — pola ini dipasang sebelum migrasi `kas/shift` (T1-11) supaya tidak dibongkar dua kali. 2) Bukti perangkat dikirim sebagai header permintaan dan dibaca lewat `current_setting('request.headers')`; **wajib dibuktikan di Supabase nyata (T0-08)** sebelum dijadikan syarat tunggal — jaring pengaman `sesi_perangkat` tetap berlaku tanpa header. 3) Fungsi `perangkat_sah()` wajib `stable`, `search_path` dipaku, dan dipanggil `(select public.perangkat_sah())` agar tidak dievaluasi ulang per baris. 4) Uji wajib: perangkat tidak terdaftar → tabel staf tertutup; cabut perangkat → permintaan berikutnya gagal; perangkat dengan peran lain → ditolak.

### [Fase 1B/2026-09-17] Masuk staf satset tapi aman: PIN 6 digit HANYA sah di perangkat terdaftar
- **Area:** Keamanan Akun (ART-12 baru) + Role & Permission (ART-2)
- **Keputusan:**
  1. **Kasir/pelayan/dapur masuk dengan "pilih nama → PIN 6 digit"**, dan kombinasi itu hanya berlaku dari perangkat terdaftar yang `peran_diizinkan`-nya cocok. Tanpa perangkat terdaftar, PIN sekuat apa pun tidak menghasilkan sesi yang bisa dipakai (ikatan sesi ditolak).
  2. **Akun staf tidak memakai email nyata**: email Supabase memakai **alias internal** resto (tidak pernah dipakai mengirim email). Konsekuensi jujur: **pemulihan akun/PIN staf dilakukan admin/owner** (wajib izin `kelola_pegawai`, tercatat) — dan justru itu yang menutup pintu pengambilalihan akun lewat email.
  3. **Ditolak dengan sadar:** (a) PIN sebagai kunci enkripsi lokal (PIN 6 digit bisa dibobol luring dari perangkat curian); (b) Edge Function yang menerbitkan sesi sendiri (menambah jalur rahasia baru yang harus dijaga sempurna — risiko jauh lebih besar daripada manfaatnya di proyek ini); (c) PIN bisa dipakai dari perangkat mana saja.
  4. **Kata sandi panjang** hanya untuk admin cabang, owner pusat, dan pemilik platform; staf tidak perlu menghafal kata sandi apa pun.
- **Alasan:** (1) permintaan pemilik: "mudah tapi aman, mereka perlu kerja satset" — 2 detik, tanpa kata sandi tertulis di meja kasir; (2) keamanan sesungguhnya berasal dari KOMBINASI (perangkat yang harus ada + PIN yang harus diketahui), bukan dari panjang PIN; (3) memakai mekanisme bawaan Supabase (kata sandi + sesi) menghindari kriptografi buatan sendiri yang paling sering menjadi sumber cacat.
- **File terkait:** `docs/KEAMANAN.md`, `supabase/migrations/0013_sesi_perangkat.sql`, `supabase/migrations/0014_percobaan_masuk.sql`, `supabase/tes/percobaan_masuk.sql`
- **Implikasi:** 1) PIN staf **sama** dengan PIN persetujuan (satu rahasia per pegawai, dua kegunaan) — tidak ada dua PIN yang membuat staf bingung. 2) Tabel uji wajib membuktikan: PIN benar + perangkat tidak terdaftar = **gagal**; PIN salah + perangkat terdaftar = **gagal** + tercatat; PIN benar + perangkat terdaftar = **berhasil**. 3) Kunci otomatis (idle) berarti sesi dihapus dari perangkat, jadi perangkat yang ditinggal tidak menyimpan apa pun. 4) Kalau internet mati saat perangkat terkunci, staf tidak bisa membuka sampai internet kembali — dicatat sebagai kasus tepi di PRD & Buku Insiden.

### [Fase 1B/2026-09-17] TOTP wajib untuk 3 peran berkuasa + jalan pemulihan yang tidak memacetkan kerja
- **Area:** Keamanan Akun (ART-12 baru)
- **Keputusan:**
  1. **TOTP (aplikasi authenticator) WAJIB untuk `pemilik_platform`, `owner_pusat`, dan `admin_cabang`.** TOTP gratis di semua paket Supabase (TOTP MFA tersedia bawaan).
  2. **Kasir/pelayan/dapur tidak memakai TOTP** — keamanan akun mereka sudah dua lapis (perangkat terdaftar + PIN), dan memaksa TOTP di dapur/kasir justru mendorong PIN ditempel atau HP dipinjam-pinjamkan.
  3. **Jalan pemulihan (agar tidak memacetkan kerja):** admin cabang yang kehilangan HP → **owner pusat bisa mengatur ulang MFA-nya** (tercatat + notifikasi); owner pusat yang kehilangan HP → **pemilik platform** yang mengatur ulang lewat panel; pemilik platform kehilangan HP → langkahnya ada di Buku Insiden.
  4. **Tanpa kode pemulihan mandiri di G1** (sengaja): kode pemulihan menambah jalur rahasia baru yang harus dijaga; ditinjau lagi di Fase 10 bila terasa perlu (dicatat di TERTANGGUH T-016).
- **Alasan:** (1) jawaban atas kebimbangan pemilik: admin cabang memang memegang akses penting (harga cabang, printer, opname stok, laporan cabang) sehingga pantas dilindungi TOTP; (2) tetapi mewajibkan tanpa jalan pemulihan = risiko operasional nyata (HP hilang = pegawai berhenti kerja) → karena itu jalan pemulihan dibuat lebih dulu, bukan belakangan; (3) memberi TOTP ke kasir/pelayan/dapur menambah friksi harian terbesar dengan tambahan keamanan terkecil — kombinasi perangkat+PIN sudah setara.
- **File terkait:** `docs/KEAMANAN.md`, `supabase/functions/atur_ulang_mfa/index.ts`, `alat/periksa-fungsi-mfa.py`, `supabase/tes/mfa.sql`
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
- **File terkait:** `docs/KEAMANAN.md`, `supabase/functions/ringkasan_harian/index.ts`
- **Implikasi:** 1) RPC laporan baru wajib membaca **salinan** (`harga_saat_itu`) dan tidak boleh menghitung ulang dari menu. 2) Email ringkasan tidak boleh memuat data pribadi pelanggan (UU PDP) — hanya angka & nama pegawai. 3) Uji: ringkasan memuat baris void & selisih yang benar untuk data uji yang sudah ada.

### [Fase 1B/2026-09-17] `catatan_audit` hanya-tambah DITAMBAH penguncian rantai hash
- **Area:** Jejak Audit (ART-13 baru)
- **Keputusan:**
  1. `catatan_audit` tetap **hanya-tambah** (tidak ada hak ubah/hapus untuk siapa pun, termasuk owner).
  2. Setiap baris menyimpan **`hash_sebelumnya` dan `hash_baris`** (SHA-256 atas isi baris kanonik + hash sebelumnya). Rantai dihitung pemicu, bukan oleh aplikasi.
  3. Pemeriksa `alat/periksa-audit.py` bisa memverifikasi rantai dan **menunjuk baris pertama yang putus** — mis. bila seseorang dengan akses database mengubah atau menghapus satu baris.
- **Alasan:** hak "hanya-tambah" melindungi dari pengguna aplikasi, tetapi tidak dari seseorang yang bisa menulis langsung ke database; rantai hash mengubah "tidak bisa diubah" dari janji menjadi **bukti yang bisa diperiksa** — penting untuk sengketa uang dengan pegawai/pelanggan.
- **File terkait:** `supabase/migrations/0015_audit.sql`, `supabase/tes/audit.sql`, `alat/periksa-audit.py`
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
- **File terkait:** `docs/KEAMANAN.md`, `docs/teknis/BUKU_INSIDEN.md`, `supabase/migrations/0017_privasi_pelanggan.sql`, `supabase/tes/privasi.sql`
- **Implikasi:** 1) T-011 (kebijakan privasi) berubah menjadi pekerjaan agent di Fase 1B, ditinjau pemilik sebelum Fase 8. 2) Halaman pendaftaran voucher wajib menampilkan kalimat persetujuan + tautan kebijakan. 3) Laporan/email tidak boleh memuat kontak pelanggan. 4) Uji: pelanggan tanpa persetujuan ditolak; permintaan anonimisasi menghapus kontak tetapi tidak menghapus transaksi.

### [Fase 1B/2026-09-17] Mode dukungan pemilik platform: beralasan, berbatas waktu, tercatat, diberitahukan
- **Area:** Akses Lintas Penyewa (ART-15 baru) + RLS (ART-1)
- **Keputusan:**
  1. **Bawaan: `pemilik_platform` TIDAK bisa melihat isi data penyewa** — hanya daftar penyewa, cabang, dan status.
  2. Bila ada masalah nyata, pemilik platform membuka **mode dukungan**: wajib **alasan**, berbatas waktu (bawaan 60 menit, tidak bisa diperpanjang otomatis), dan **hanya-baca**.
  3. Setiap mode dukungan menulis `catatan_audit` **dan** mengirim pemberitahuan ke owner penyewa (email) — sehingga tidak ada pengintaian diam-diam.
  4. Mode dukungan **tidak** memberi hak mengubah data; perbaikan data selalu lewat jalur normal pemilik resto (atau jalur pemulihan bencana yang terdokumentasi di Buku Insiden).
- **Alasan:** (1) ini janji di PRD §9 yang harus punya bentuk teknis, bukan sekadar niat; (2) tanpa jalan dukungan, pemilik platform akan terdorong memakai kunci penuh (`service_role`) di luar prosedur — jauh lebih berbahaya; (3) pemberitahuan otomatis membuat penyewa merasa aman tanpa menghalangi bantuan.
- **File terkait:** `supabase/migrations/0016_mode_dukungan.sql`, `supabase/tes/mode_dukungan.sql`, `docs/KEAMANAN.md`
- **Implikasi:** 1) Policy RLS wajib membedakan "pemilik platform biasa" dan "mode dukungan aktif" — diuji keduanya. 2) Mode dukungan berakhir otomatis (pg_cron) dan berakhir bila pemilik platform keluar. 3) Uji: tanpa mode dukungan → 0 baris; dengan mode dukungan → hanya-baca (perintah tulis ditolak); setelah kedaluwarsa → 0 baris lagi.

### [Fase 1C/2026-09-17] Kelengkapan UI: Registri Aksi + Peta Layar + pemeriksa otomatis (anti "tombol mati")
- **Area:** Arsitektur Klien & Kelengkapan Fitur (bukan Area Berisiko Tinggi, tetapi mengikat semua tugas UI)
- **Keputusan:**
  1. **Registri Aksi** (`aplikasi/src/lib/aksi.ts`) menjadi **satu-satunya sumber kebenaran** untuk setiap tombol/menu/gestur: id, label, layar, peran, izin, RPC, jenis, konfirmasi, butuh-PIN, pesan sukses/gagal, dan daftar uji. **Semua tombol dirender lewat `<TombolAksi id="…">`**; aksi tanpa entri tidak bisa dirender.
  2. **Peta Layar** (`aplikasi/src/lib/layar.ts`): id, rute, judul, peran yang boleh, dan **7 keadaan wajib** (kosong · memuat · gagal · menunggu terkirim · tidak punya akses · data sebagian · berhasil).
  3. **Kontrak layar** wajib ditulis untuk setiap layar di `docs/SPESIFIKASI_UI.md` sebelum layar dikerjakan (tujuan, jalan masuk, data, aksi, 7 keadaan, bukti uji, nomor naskah jalan).
  4. **Pemeriksa otomatis** `alat/peta-ui.py` men-generate `docs/PETA_UI.md` dari kedua registri dan **menggagalkan CI** bila: RPC aksi tidak ada di migrasi · kode izin tidak ada · aksi tanpa uji · layar tanpa berkas/rute · dokumen peta basi · fitur PRD M1–M12 tanpa jejak layar/aksi.
  5. **Uji komponen tiap layar** (jsdom + Testing Library, sudah terpasang): dirender per peran; tombol yang seharusnya ada benar-benar **memanggil RPC yang benar** (ditiru); tombol terlarang tidak ada; 7 keadaan tampil. Ini yang membuktikan "tombol benar-benar bisa dipakai", bukan sekadar ada.
  6. **Naskah jalan pemilik** bernomor (`W-<fase>-<nomor>`, bahasa manusia "tekan ini → harus muncul itu") wajib ditulis & dijalankan di pratinjau untuk setiap tugas UI.
  7. **DoD versi baru** untuk tugas UI: kontrak layar · aksi terdaftar · 7 keadaan · uji komponen hijau · pemeriksa peta-UI hijau · naskah jalan dijalankan · **izin dicek di database** (bukan hanya disembunyikan di layar).
  8. **Uji peramban (Playwright) ditaruh di GitHub Actions**, bukan di ruang kerja agent: Chromium **tidak bisa diunduh** di ruang kerja ini (sudah dicoba 2026-09-17) tetapi CI menjalankannya pada mesin Ubuntu. Kalau ternyata gagal, dilaporkan jujur dan diganti — bukan diklaim.
- **Alasan:** (1) ini jawaban langsung atas pengalaman pemilik ("banyak tombol kurang, fungsi katanya ada tapi tak bisa dipakai") — penyebabnya bukan AI-nya, melainkan tidak ada daftar tombol, tidak ada uji pemanggilan, dan "selesai" yang berarti "kode ditulis"; (2) registri membuat tombol **tidak bisa lahir tanpa uji**, dan pemeriksa membuat dokumen tidak bisa basi; (3) kontrak layar memaksa 7 keadaan diputuskan sebelum dikoding — tempat paling sering muncul "fitur palsu" (layar yang jalan hanya bila data ada).
- **File terkait:** `aplikasi/src/lib/aksi.ts`, `aplikasi/src/lib/layar.ts`, `aplikasi/src/komponen/TombolAksi.tsx`, `alat/peta-ui.py`, `docs/SPESIFIKASI_UI.md`, `docs/PETA_UI.md`
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
