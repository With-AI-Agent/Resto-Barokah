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

