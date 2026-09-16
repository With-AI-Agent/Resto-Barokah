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

