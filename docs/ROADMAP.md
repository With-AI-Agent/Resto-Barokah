# ROADMAP.md — Resto Barokah (Gelombang 1 / G1)

> **Status: DITULIS 2026-09-16 — menunggu pemeriksaan silang Tahap 6.** Urutan fase disetujui pemilik via delegasi
> (*"Aku mau yang terbaik dari kamu"*) — tercatat di `docs/teknis/DISKUSI_TAHAP5_ROADMAP.md`.
>
> **Cara pakai:** ini kontrak kerja harian agent. Kalau tidak ada di daftar ini → tidak dikerjakan.
> Mode **Maraton** berlaku (`docs/AGENT_OPERATING_GUIDE.md` §13): kerjakan tugas berikutnya yang **tidak** tertangguh,
> hanya berhenti pada Stop Conditions. Tugas bertanda **❓ T-xxx** menunggu butir di `docs/TERTANGGUH.md` dan **dilewati**.
>
> **Setiap tugas WAJIB punya 7 atribut:** Tujuan · Ref · File · DoD · Kompleksitas · Risiko & mitigasi · Verifikasi.
> Diperiksa otomatis oleh `python3 alat/periksa-roadmap.py` (wajib PASS sebelum menandai tugas selesai).
>
> Rujukan: `docs/PRD.md` (M1–M12) · `docs/TECH_SPEC.md` (dikunci, ART-1…ART-10) · `docs/AGENT_OPERATING_GUIDE.md`
> Lambang: ⚠️ = menyentuh Area Berisiko Tinggi (wajib tulis `docs/DECISIONS_LOG.md`) · ❓ = menunggu jawaban pemilik

## Peta nama RPC resmi → tugas (hasil pemeriksaan silang Tahap 6)

Sumber kebenaran nama: `docs/TECH_SPEC.md` §5. Setiap nama WAJIB dipakai persis oleh kode yang dibangun.

| RPC (TECH_SPEC §5) | Dikerjakan di tugas |
|---|---|
| `buat_penyewa`, `set_status_penyewa`, `tambah_cabang` | T9-10, T9-09 |
| `simpan_pengaturan`, `simpan_menu`, `simpan_meja`, `simpan_metode_bayar` | T9-01…T9-07, T9-11 |
| `set_izin`, `simpan_pin`, `verifikasi_pin`, `ganti_pin` | T9-08, T1-06, T2-02 |
| `simpan_pesanan`, `tambah_item`, `pindah_meja`, `kirim_ke_dapur` | T3-05, T3-06, T3-08 |
| `set_status_item`, `tandai_habis` | T4-04, T4-05, T3-07 |
| `bayar_pesanan`, `batal_pesanan`, `batal_item` | T5-02, T5-06, T5-07, T3-13 |
| `buka_shift`, `tutup_shift`, `kas_pergerakan` | T7-01, T7-02, T7-03 |
| `laporan_shift`, `laporan_harian` | T7-07…T7-12 |
| `set_stok`, `opname_stok` | T4-06, T4-07 |
| `katalog_publik` | T8-01 |
| `cek_voucher`, `pakai_voucher`, `daftar_voucher` | T1-19, T1-20, T8-09 |
| `set_akses_cabang` | T9-09 |
| `keluar_semua_perangkat` | T10-06 |
| `hitung_total` (fungsi, bukan RPC terpisah) | T1-15, T1-16 |

Bentuk jawaban semua RPC mengikuti `TECH_SPEC.md` §5: `{ berhasil: bool, kode: teks, pesan: teks, data: … }`.

---

## Fase 0 — Persiapan & rangka kerja

- **Gerbang masuk (wajib, atas permintaan pemilik 2026-09-16):** review independen oleh sesi baru (prompt siap pakai di `docs/uji/PROMPT_REVIEW_INDEPENDEN.md`; sesi review dibuat dengan base branch `arena/01a0a8a2-resto-barokah`, tanpa merge PR apa pun, dan dilarang merge/menutup PR) sudah selesai, **temuannya sudah ditangani sesi pembangun**, dan putusan akhirnya bukan `BELUM SIAP`. Selama gerbang ini belum lewat, tugas Fase 0 belum boleh dicentang.

- [ ] T0-00 — Pemilik membuat akun Supabase & Cloudflare (dipandu, gratis) — **hanya pemilik yang bisa**
  - **Tujuan:** dua akun gratis siap dipakai agent. Ini satu-satunya tugas Fase 0 yang **harus** dikerjakan pemilik: agent tidak punya email dan tidak bisa menerima kode verifikasi.
  - **Ref:** TECH_SPEC §1 (stack & layanan), §6 (rahasia tidak boleh ikut ke aplikasi); `docs/ops/SIAP_AKUN_PEMILIK.md`
  - **File:** `docs/ops/SIAP_AKUN_PEMILIK.md` (panduan langkah bernomor bahasa awam, ditulis sebelum tugas ini dimulai)
  - **DoD:** akun Supabase + proyek gratis (wilayah Singapura) dan akun Cloudflare aktif; **URL proyek + kunci `anon`** diserahkan ke agent; kunci `service_role` **tidak pernah ditempel ke chat** (langsung ditaruh di berkas rahasia lokal / secrets Cloudflare); catatan "akun sudah ada" ditulis di README aplikasi.
  - **Kompleksitas:** kecil (30 menit dipandu)
  - **Risiko & mitigasi:** kunci rahasia bocor lewat chat atau repo → mitigasi: panduan hanya mengizinkan nilai `anon` ditempel, `.env*` diabaikan Git (T0-05), kunci `service_role` disimpan di secrets Cloudflare.
  - **Verifikasi:** pemilik bisa membuka dashboard kedua layanan; agent menyimpan nilai dari pemilik di berkas rahasia lokal (tidak di-commit) dan `git check-ignore` membuktikan berkas itu diabaikan.

- [x] T0-01 — Repo aplikasi React + TypeScript + Vite + struktur folder
  - **Tujuan:** aplikasi bisa dijalankan lokal sejak commit pertama dan strukturnya sama dengan rancangan.
  - **Ref:** TECH_SPEC §1 (stack) & §3 (struktur folder); PRD §6 Non-Goals
  - **File:** `aplikasi/package.json`, `aplikasi/vite.config.ts`, `aplikasi/tsconfig.json`, `aplikasi/tsconfig.app.json`, `aplikasi/tsconfig.node.json`, `aplikasi/index.html`, `aplikasi/public/favicon.svg`, `aplikasi/public/robots.txt`, `aplikasi/src/layar/contoh/LayarContoh.tsx`
  - **DoD:** `npm install && npm run dev` jalan tanpa error; folder `/src/{gaya,komponen,layar,lib,hook}` ada; favicon terpasang; `tsc -b --noEmit` bersih (dipakai mode proyek — `tsc --noEmit` biasa memeriksa nol berkas pada susunan referensi, dibuktikan lewat uji mutasi 2026-09-16).
  - **Kompleksitas:** kecil (1 jam)
  - **Risiko & mitigasi:** salah struktur → mitigasi: salin persis struktur `TECH_SPEC.md` §3, jangan improvisasi nama folder.
  - **Verifikasi:** `npm run dev` + buka URL dev; `git status` bersih setelah commit. · **Bukti 2026-09-16:** `npm run dev` melayani halaman (HTTP 200), `main.tsx`, `tema.css`, dan berkas huruf (font/woff2); 7 folder layar + `supabase/{migrations,functions,tes}` ada; 31 berkas huruf pindah; favicon dipakai format SVG (bukan ICO) karena tidak butuh alat pengubah gambar dan tetap tajam di semua ukuran; pemeriksa `aplikasi/alat/periksa-struktur.py` memeriksa pohon folder langsung dari `TECH_SPEC.md` §3.

- [x] T0-02 — Aturan kode otomatis (ESLint + Prettier + TypeScript ketat)
  - **Tujuan:** kode asal-asalan ditolak otomatis sebelum masuk repo.
  - **Ref:** AGENT_OPERATING_GUIDE §3 (konvensi koding)
  - **File:** `aplikasi/eslint.config.js`, `aplikasi/.prettierrc.json`, `aplikasi/.prettierignore`, `aplikasi/tsconfig.app.json`, `aplikasi/tsconfig.node.json`, `aplikasi/vitest.config.ts`, `aplikasi/package.json`
  - **DoD:** `npm run lint` & `npm run format:check` & `npm run typecheck` tersedia dan lulus di repo bersih; `strict: true`; aturan `no-explicit-any` aktif.
  - **Kompleksitas:** kecil (1 jam)
  - **Risiko & mitigasi:** aturan terlalu galak bikin lambat → mitigasi: mulai dari preset standar React+TS, tambah aturan hanya bila terbukti perlu.
  - **Verifikasi:** tiga perintah di atas keluar dengan kode 0. · **Bukti 2026-09-16:** ESLint 9.39 (typescript-eslint 8.70) + Prettier 3.9 + TypeScript 5.7 ketat (`strict`, `noUnusedLocals`, `noUnusedParameters`); gerbang dibuktikan menyala lewat uji mutasi — berkas dengan `any` ditolak lint, berkas dengan salah tipe ditolak `tsc -b --noEmit`, berkas belum diformat ditolak `format:check`; sesudah dibersihkan ketiganya hijau.

- [x] T0-03 — Token desain v3 dipindah ke aplikasi (10 tema)
  - **Tujuan:** tampilan aplikasi memakai bahasa desain yang sudah disetujui pemilik, bukan karangan baru.
  - **Ref:** TECH_SPEC §1 (gaya/tampilan); `prototipe/css/tokens.css`
  - **File:** `aplikasi/src/gaya/token/tema.css`, `aplikasi/src/gaya/token/dasar.css`, `aplikasi/src/gaya/komponen.css`, `aplikasi/src/lib/tema.ts`, `aplikasi/src/hook/useTema.ts`
  - **DoD:** 10 tema + 2 kerapatan (`nyaman` & `padat`) tersedia sebagai variabel CSS; pemilih tema bisa mengganti tanpa memuat ulang halaman; tidak ada warna mentah di luar token.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** token tercecer saat diubah manual → mitigasi: pindahkan berkas apa adanya, jangan ketik ulang.
  - **Verifikasi:** `prototipe/uji-kontras.py` versi aplikasi dijalankan (dibuat di T0-04) + inspeksi 3 tema secara visual. · **Bukti 2026-09-16:** `tema.css` identik byte-per-byte dengan `prototipe/css/tokens.css` (diperiksa otomatis), 19 berkas huruf tersalin dan semua rujukan `url()` di dalamnya ada di disk; 10 kode tema di `src/lib/tema.ts` sama persis dengan kode tema di token (diperiksa otomatis); warna `theme-color` peramban diambil dari token `--accent`, bukan ditulis di `index.html`; 20 uji unit hijau (format uang/tanggal/jam, tema & kerapatan, render layar contoh).

- [x] T0-04 — Komponen dasar + keadaan kosong/memuat/gagal + uji kontras aplikasi
  - **Tujuan:** semua layar memakai komponen yang sama dan tidak pernah menampilkan halaman kosong tanpa penjelasan.
  - **Ref:** TECH_SPEC §3 (folder komponen); AGENT_OPERATING_GUIDE §3 (a11y)
  - **File:** `aplikasi/src/komponen/*.tsx`, `aplikasi/src/gaya/komponen.css`, `aplikasi/alat/uji-kontras.py`, `aplikasi/alat/periksa-komponen-env.py`, `aplikasi/src/layar/contoh/LayarContoh.tsx`
  - **DoD:** komponen Tombol, Kartu, Lapis (mengambang), Toast, Tabel, KolomIsian, KeadaanKosong, KeadaanMemuat, KeadaanGagal ada; target sentuh ≥44 px; fokus keyboard terlihat; uji kontras ≥95% pemeriksaan lulus.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** komponen tidak konsisten → mitigasi: satu komponen satu berkas + token wajib + uji kontras otomatis.
  - **Verifikasi:** `python3 aplikasi/alat/uji-kontras.py` lulus + tangkapan layar 1 halaman contoh. · **Bukti visual** (tangkapan layar/foto) diambil pemilik atau penguji manusia; tugas ditandai `[x]` hanya setelah buktinya diterima. · **Bukti otomatis 2026-09-16:** `uji-kontras.py` versi aplikasi **166 lolos · 0 gagal** (130 pemeriksaan warna 10 tema + 36 aturan desain, termasuk tinggi sentuh ≥44 px); 10 komponen ada dan diperiksa `aplikasi/alat/periksa-komponen-env.py`; 17 uji komponen + 22 uji lain hijau; layar contoh `aplikasi/src/layar/contoh/LayarContoh.tsx` memperagakan semua komponen & ketiga keadaan halaman. **Bukti visual (pemilik) 2026-09-16:** pemilik membuka pratinjau aplikasi lalu menyatakan **“Lanjut”** — tampilan tema (10), kerapatan (nyaman/padat), lapis mengambang, dan ketiga keadaan halaman dinilai pantas. Dengan bukti otomatis + bukti visual itu, tugas ini ditandai `[x]`.

- [x] T0-05 — Berkas rahasia & variabel lingkungan
  - **Tujuan:** kunci rahasia tidak pernah ikut ke git maupun ke perangkat pengguna.
  - **Ref:** TECH_SPEC §6 (env vars)
  - **File:** `aplikasi/.env.example`, `aplikasi/.gitignore`, `aplikasi/src/lib/env.ts`
  - **DoD:** `.env.example` memuat SEMUA var dari TECH_SPEC §6; `.gitignore` memuat `.env*` kecuali `.env.example`; hanya `VITE_SUPABASE_URL` & `VITE_SUPABASE_ANON_KEY` yang bisa dibaca klien; service-role key hanya di sisi peladen.
  - **Kompleksitas:** kecil (1 jam)
  - **Risiko & mitigasi:** kebocoran kunci rahasia → mitigasi: pemeriksa pola kunci di CI + tinjauan manual setiap commit yang menyentuh env.
  - **Verifikasi:** `git check-ignore -v aplikasi/.env` (diabaikan) + `grep -r "service_role" aplikasi/src` tidak menemukan apa pun. · **Bukti 2026-09-16:** `.env.example` memuat **semua 8 nama variabel** dari TECH_SPEC §6 (diperiksa otomatis dari dokumen, bukan dari daftar manual), hanya `VITE_SUPABASE_URL` & `VITE_SUPABASE_ANON_KEY` yang aktif (dua-duanya aman publik), variabel rahasia sengaja tidak berawalan `VITE_` dan hanya dikomentari; `git check-ignore` membuktikan `.env` diabaikan dan `.env.example` ikut Git; tidak ada kata `service_role` di dalam `aplikasi/src`; 10 pemeriksaan `python3 aplikasi/alat/periksa-komponen-env.py` hijau.

- [x] T0-06 — README aplikasi (cara menjalankan & peta folder)
  - **Tujuan:** agent sesi berikutnya (model apa pun) bisa menjalankan proyek tanpa menebak.
  - **Ref:** AGENT_OPERATING_GUIDE §8 (kerja lintas sesi)
  - **File:** `aplikasi/README.md`
  - **DoD:** memuat: prasyarat, langkah menjalankan, penjelasan tiap folder, daftar perintah npm, tautan ke `/docs`.
  - **Kompleksitas:** kecil (1 jam)
  - **Risiko & mitigasi:** README basi → mitigasi: diperbarui bila perintah berubah (dicatat di DoD tugas terkait).
  - **Verifikasi:** ikuti README dari nol di folder sementara → berhasil. · **Bukti 2026-09-16:** folder `aplikasi/` disalin ke tempat bersih (tanpa `node_modules`/`dist`), lalu `npm ci` → Prettier → ESLint → TypeScript → 39 uji → build: **semuanya hijau** mengikuti langkah di README; README memuat prasyarat, cara menjalankan, peta folder, daftar perintah, aturan rahasia, daftar pemeriksa, dan bagian “sebelum mengirim kode”.

- [x] T0-07 — CI dasar (lint + tipe + uji unit)
  - **Tujuan:** setiap push diperiksa otomatis; tidak ada kode rusak yang lolos.
  - **Ref:** AGENT_OPERATING_GUIDE §5 (testing) & §4 (commit)
  - **File:** `.github/workflows/ci.yml`
  - **DoD:** CI menjalankan `npm ci`, `lint`, `typecheck`, `test`; gagal bila ada yang gagal; berlaku untuk branch sesi maupun PR.
  - **Kompleksitas:** kecil (1 jam)
  - **Risiko & mitigasi:** CI lambat/berbiaya → mitigasi: hanya GitHub Actions gratis untuk repo publik, tanpa langkah berbayar.
  - **Verifikasi:** status CI hijau pada push pertama; sengaja membuat lint gagal di uji coba → CI merah. · **Bukti 2026-09-16:** CI menyala di setiap push & pull request; gerbangnya benar-benar bekerja — (a) run 35121292973 **MERAH di langkah ESLint** saat sengaja dipasang variabel tidak terpakai (kode ujinya lalu dihapus), (b) run 35120922393 merah karena folder layar kosong tidak ikut Git, (c) run 35121062046 merah karena satu berkas Markdown belum dirapikan, dan (d) run **35121525551 hijau penuh** (npm ci → Prettier → ESLint → TypeScript → Vitest → build → 5 pemeriksa Python). Artinya: dua cacat nyata tertangkap CI, bukan cuma “hijau karena kebetulan”. Semua ini memakai jatah gratis GitHub Actions (repo privat 2.000 menit/bulan).

- [ ] T0-08 — Proyek Supabase dibuat + klien aman tersambung
  - **Tujuan:** aplikasi bisa membaca data dari Supabase dengan kunci publik saja.
  - **Ref:** TECH_SPEC §1 & §6; AGENT_OPERATING_GUIDE §3
  - **File:** `aplikasi/src/lib/supabase.ts`, `supabase/config.toml`, `aplikasi/.env.local` (tidak di-commit)
  - **DoD:** koneksi uji (`select 1`) berhasil dari aplikasi; tidak ada kunci rahasia di klien; catatan pembuatan proyek ditulis di README.
  - **Kompleksitas:** kecil (1 jam)
  - **Risiko & mitigasi:** proyek gratis "tidur" setelah 7 hari → mitigasi: dijadwalkan denyut harian (T10-08).
  - **Catatan jeda:** kalau pembangunan berhenti lebih dari 7 hari (libur/menunggu jawaban), proyek gratis bisa "tertidur" → buka panel Supabase, tekan **Restore/Unpause** sebelum melanjutkan; penyebab paling umum "koneksi gagal" di sesi berikutnya.
  - **Verifikasi:** buka aplikasi di dev → tampilkan hasil `select 1` di console/​halaman uji.

- [ ] T0-09 — Deploy halaman kosong ke Cloudflare Workers + Static Assets  <!-- T-008 sudah ditutup 2026-09-16: pakai alamat gratis *.workers.dev -->
  - **Tujuan:** membuktikan jalur deploy bekerja sejak awal (bukan mendadak di akhir).
  - **Ref:** TECH_SPEC §1 (halaman aplikasi) & §7 (integrasi)
  - **File:** `aplikasi/wrangler.toml`, `aplikasi/package.json` (script deploy)
  - **DoD:** halaman kosong dapat diakses publik lewat alamat sementara `*.workers.dev`; HTTPS aktif; deploy bisa diulang dengan satu perintah.
  - **Kompleksitas:** sedang (2 jam)
  - **Risiko & mitigasi:** kuota gratis (100.000 permintaan/hari) → mitigasi: berkas statis tanpa batas; tidak memakai fungsi boros.
  - **Verifikasi:** buka URL publik di luar jaringan lokal; `curl -I` mengembalikan 200.

- [x] T0-10 — Vitest + uji contoh + skrip pemeriksa roadmap
  - **Tujuan:** kerangka uji siap sebelum kode uang/keamanan ditulis (TDD sejak awal).
  - **Ref:** AGENT_OPERATING_GUIDE §5; TECH_SPEC §11
  - **File:** `aplikasi/vitest.config.ts`, `aplikasi/src/lib/format.test.ts`, `aplikasi/src/lib/tema.test.ts`, `aplikasi/src/lib/env.test.ts`, `aplikasi/src/hook/useJam.test.tsx`, `aplikasi/src/hook/useTema.test.tsx`, `aplikasi/src/komponen/komponen.test.tsx`, `aplikasi/alat/periksa-uji.py`, `alat/periksa-roadmap.py`
  - **DoD:** `npm test` lulus; uji contoh format rupiah ada; `python3 alat/periksa-roadmap.py` lulus di dokumen ROADMAP ini.
  - **Kompleksitas:** kecil (1,5 jam)
  - **Risiko & mitigasi:** uji hanya formalitas → mitigasi: uji wajib untuk setiap fungsi uang/izin mulai Fase 1 — **dijaga alat**: `aplikasi/alat/periksa-uji.py` menolak kiriman kode kalau ada berkas logika di `src/lib` atau `src/hook` yang tidak punya berkas ujinya sendiri.
  - **Verifikasi:** `npm test` hijau + `python3 alat/periksa-roadmap.py` hijau. · **Bukti 2026-09-16:** **51 uji hijau dalam 7 berkas** (uang/tanggal/jam · tema & kerapatan · pembacaan pengaturan · jam berdenyut · pemilih tema dengan jsdom · 17 uji komponen · layar contoh); kerangka siap untuk kode uang/izin — jsdom + @testing-library/react terpasang supaya hook bisa diuji seperti pemakaian nyata; pemeriksa baru `aplikasi/alat/periksa-uji.py` (6 OK · 0 GAGAL) menolak berkas logika tanpa uji (dibuktikan lewat uji mutasi); pemeriksa itu ikut jalan di CI; `alat/periksa-roadmap.py` LOLOS.

---

## Fase 1 — Database, keamanan & uang (⚠️ Area Berisiko Tinggi — dikerjakan paling awal)

- [x] T1-01 — Migrasi 0001: penyewa + cabang + RLS ⚠️
  - **Tujuan:** data dua resto terpisah total sejak tabel pertama ada.
  - **Ref:** TECH_SPEC §4 (penyewa/cabang) & §9 ART-1; PRD M1 & M11
  - **File:** `supabase/migrations/0001_penyewa_cabang.sql`, `supabase/tes/rls_penyewa.sql`
  - **DoD:** tabel `penyewa` & `cabang` ada; RLS aktif; anon tidak melihat satu baris pun; akun penyewa A tidak melihat data penyewa B; uji SQL lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: RLS/Auth (ART-1); salah policy → kebocoran data antar-resto → mitigasi: satu pola policy untuk semua tabel + uji dua penyewa.
  - **Verifikasi:** `supabase test` (uji SQL) + pemeriksaan manual dengan dua akun berbeda. · **Bukti 2026-09-16:** migrasi `0001` diterapkan pada PostgreSQL asli lalu diuji `supabase/tes/rls_penyewa.sql` — pengunjung belum masuk melihat **0 baris** penyewa & cabang, kasir resto A hanya melihat **1 penyewa & 2 cabangnya**, kasir resto B **tidak melihat satu baris pun** milik resto A; perintah ubah cabang dari resto lain **tidak mengubah apa pun** (RLS menyaring, bukan melempar error — dibuktikan dengan membaca ulang nama cabang dari akun owner). RLS sudah aktif sejak tabel pertama ada, policy-nya sengaja ditulis di `0004` (tolak-dulu).

- [x] T1-02 — Migrasi 0002: pengguna, pengguna_cabang, izin, pengaturan ⚠️
  - **Tujuan:** pegawai punya peran & cabang, dan pengaturan per resto tersimpan rapi.
  - **Ref:** TECH_SPEC §4; PRD M2 & M3
  - **File:** `supabase/migrations/0002_pengguna_izin_pengaturan.sql`
  - **DoD:** tabel-tabel ada dengan kunci asing benar; `pengguna_cabang` mendukung pegawai merangkap cabang; `pengaturan` per penyewa (bukan per cabang, kecuali dinyatakan); RLS + uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); salah model cabang → laporan salah → mitigasi: uji pegawai di dua cabang sejak awal.
  - **Verifikasi:** uji SQL: pegawai cabang 1 tidak bisa melihat data cabang 2. · **Bukti 2026-09-16:** `supabase/tes/rls_pengguna.sql` — kasir hanya melihat **baris dirinya sendiri**, admin cabang Pusat melihat **3 pegawai** cabangnya (bukan yang hanya bertugas di Cabang Dua), owner pusat melihat **seluruh pegawai restonya** dan **0 pegawai resto lain**; izin hanya terlihat oleh yang berhak (kasir **2 baris miliknya**, admin **seluruh izin restonya**, resto lain **0**) dan kasir **ditolak** saat mengubah izin lewat tabel; pengaturan hanya bisa diubah owner pusat — perintah ubah dari resto lain **tidak mengubah nilai apa pun**. Pegawai merangkap dua cabang didukung (`pengguna_cabang` kunci primer gabungan).

- [x] T1-03 — Fungsi bantu identitas: penyewa_id(), cabang_ids(), peran() ⚠️
  - **Tujuan:** semua policy memakai satu sumber identitas yang sama (tidak ada logika ganda).
  - **Ref:** TECH_SPEC §4 & §9 ART-1/ART-2
  - **File:** `supabase/migrations/0003_helper_identitas.sql`, `supabase/tes/helper.sql`
  - **DoD:** tiga fungsi mengembalikan nilai benar untuk 6 peran; dipakai oleh seluruh policy; uji lulus (termasuk akun tanpa cabang).
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: RLS/Auth (ART-1); fungsi bocor hak → mitigasi: `SECURITY DEFINER` hanya bila perlu + uji peran terbatas.
  - **Verifikasi:** uji SQL memanggil ketiga fungsi sebagai anon, pelayan, admin cabang, owner. · **Bukti 2026-09-16:** `supabase/migrations/0003_helper_identitas.sql` + `supabase/tes/helper.sql` — diuji untuk **7 akun** (pemilik platform, owner pusat, admin cabang, kasir, pelayan merangkap dua cabang, dapur, kasir resto lain): pemilik platform tidak punya penyewa/cabang, owner pusat punya penyewa tanpa cabang, pelayan mengembalikan **2 cabang**, akun tanpa cabang mengembalikan **null/kosong** (bukan error). Fungsi juga diuji **negatif**: sebelum masuk (anon) **ditolak** karena hak jalannya hanya untuk `authenticated` & `service_role`; klaim cabang palsu milik resto lain **ditolak** (diverifikasi ulang ke `pengguna_cabang`); akun nonaktif kehilangan seluruh identitas. Uji ini menangkap **satu cacat nyata** pada rancangan awal (`cabang_saya()`/`cabang_ids_saya()` masih memberi cabang ke akun nonaktif) yang langsung diperbaiki.

- [x] T1-04 — Pola RLS seragam + uji isolasi menyeluruh ⚠️
  - **Tujuan:** satu pola seragam supaya tidak ada tabel yang lupa dikunci.
  - **Ref:** TECH_SPEC §9 ART-1; PRD M12
  - **File:** `supabase/migrations/0004_pola_rls.sql`, `supabase/tes/rls_semua_tabel.sql`
  - **DoD:** uji "setiap tabel ber-penyewa_id punya policy" lulus; uji akses silang (penyewa A ↔ B, cabang 1 ↔ 2) lulus untuk semua peran; daftar tabel tanpa policy = kosong.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: RLS (ART-1); tabel baru lupa dikunci → mitigasi: uji otomatis "tanpa policy = gagal" dijalankan di CI.
  - **Verifikasi:** `supabase test` + laporan daftar tabel & policy dicetak ke log CI. · **Bukti 2026-09-16:** `supabase/migrations/0004_pola_rls.sql` + `supabase/tes/rls_semua_tabel.sql`. Uji ini **membaca katalog PostgreSQL**, tidak menyebut nama tabel satu per satu — jadi tabel baru di fase mana pun otomatis diperiksa (RLS aktif · punya policy · yang punya `penyewa_id` wajib menyebut `penyewa_saya()`), plus pemindaian pembocoran baris antar-resto. Daftar saat ini: **6 tabel, semuanya RLS aktif & ber-policy** (penyewa 1 · cabang 3 · pengguna 1 · pengguna_cabang 1 · izin 1 · pengaturan 2). Gerbang ini dijalankan di CI dengan `--daftar` sehingga daftar tabel & policy **tercetak di log setiap kiriman kode**. Dibuktikan bisa MERAH lewat **3 uji mutasi**: RLS dimatikan → GAGAL · policy dibuka lebar → GAGAL · cacat akun nonaktif dikembalikan → GAGAL; setelah dipulihkan → LOLOS.

- [x] T1-05 — Peran & izin berjenjang (centang owner) + fungsi boleh() ⚠️
  - **Tujuan:** tindakan di luar izin tidak bisa dilakukan, bahkan lewat API langsung.
  - **Ref:** TECH_SPEC §4 & §9 ART-2; PRD M3
  - **File:** `supabase/migrations/0005_izin_berjenjang.sql`, `supabase/tes/izin.sql`
  - **DoD:** daftar izin (ubah harga, diskon + batas, void pra/pasca dapur, lihat laporan, kelola pegawai, atur pengaturan, pakai voucher) tersimpan per pegawai/peran; fungsi `boleh(aksi)` dipakai semua RPC; uji tiap peran lulus.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); izin tercecer di banyak tempat → mitigasi: SATU fungsi `boleh()` sebagai gerbang tunggal.
  - **Verifikasi:** uji SQL menolak 7 tindakan sensitif untuk peran yang tidak berizin. · **Bukti 2026-09-16:** `supabase/migrations/0005_izin_berjenjang.sql` + `supabase/tes/izin.sql`. Kamus resmi **10 kode izin** (`izin_kode`) dan **izin bawaan per peran** (`izin_peran`, 50 baris per resto, dipasang otomatis untuk resto baru lewat pemicu). Gerbang tunggal **`boleh(aksi)` / `boleh(aksi, nominal)` / `boleh(aksi, nominal, persen)`** di atas `izin_efektif()`: centang khusus pegawai (`izin`) menang atas bawaan peran, dan bila tidak ada keduanya → **TOLAK**. Matriks 10 izin diuji untuk kasir, admin cabang, dapur, pelayan, dan owner pusat; **13+ tindakan sensitif terbukti ditolak** (kasir 6 · dapur 3 · pelayan 3 · admin 1) dan yang berizin terbukti boleh. Diuji juga: batas diskon (25.000/5 persen kasir · 50.000/10 persen admin) termasuk tepat-di-batas vs lewat-batas, izin **berbeda per cabang** untuk pegawai merangkap (peran dapur di satu cabang, kasir di tingkat akun), **cabang asing ditolak** (tidak diam-diam jatuh ke peran se-resto), aksi tak dikenal ditolak, akun nonaktif & pemilik platform tidak boleh apa pun, kasir tidak bisa mengubah tabel izin, dan resto lain tidak melihat izin peran resto ini. **Gerbang dibuktikan bisa MERAH lewat 4 uji mutasi** — tolak-demi-bawaan dirusak · centang khusus diabaikan · batas diskon diabaikan · cabang asing diterima: semuanya GAGAL, LOLOS setelah dipulihkan. Mutasi ke-4 awalnya **lolos** sehingga mengungkap uji yang lemah (cabang asing diuji dengan tindakan yang memang sudah terlarang di tingkat akun) → uji diperkuat memakai tindakan yang boleh di akun tetapi tidak di cabang itu, dan mutasi yang sama langsung tertangkap.

- [x] T1-06 — PIN pegawai: hash + pembatasan percobaan ⚠️
  - **Tujuan:** PIN tidak bisa dibaca dari database dan tidak bisa ditebak dengan percobaan berulang.
  - **Ref:** TECH_SPEC §4 (`percobaan_pin`) & §9 ART-2; PRD M3 & M12
  - **File:** `supabase/migrations/0006_pin.sql`, `supabase/functions/verifikasi_pin/index.ts`, `supabase/tes/pin.sql`
  - **DoD:** PIN disimpan sebagai hash (tidak pernah teks biasa); percobaan salah dibatasi (mis. 5×/15 menit) dan tercatat; uji lulus termasuk pemulihan setelah tunggu.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); brute force → mitigasi: pembatasan per pengguna + per perangkat + catatan audit.
  - **Verifikasi:** uji SQL + uji fungsi: 6 percobaan salah berurutan → ditolak dengan pesan jelas. · **Bukti 2026-09-16:** `supabase/migrations/0006_pin.sql`, `supabase/functions/verifikasi_pin/index.ts`, `supabase/tes/pin.sql`, `alat/periksa-fungsi-pin.py`. PIN disimpan **hanya sebagai hash** (`crypt(pin, gen_salt('bf', 10))`) dan database **menolak sendiri** nilai yang bukan berbentuk hash lewat batas (CHECK) — dibuktikan uji: perintah menyimpan `123456` ke kolom `pin_hash` **GAGAL**. Pembatasan percobaan: **5 kali salah per akun** dan **12 kali salah per perangkat** dalam 15 menit; uji menempuh lima kali salah berurutan (sisa percobaan tercatat 4→0) lalu **percobaan keenam DITOLAK walau PIN-nya benar**, dengan pesan berbahasa Indonesia yang menyebut “terkunci sementara”; pindah HP **tidak** menembus batas per akun; 12 kali salah dari satu HP (dibagi 3 akun, masing-masing di bawah batas) **mengunci HP itu** tanpa mengunci akun lain. Pemulihan setelah tunggu diuji dengan memundurkan waktu percobaan → PIN benar diterima lagi. Semua percobaan (berhasil maupun gagal, termasuk yang ditolak karena terkunci) **tercatat** di `percobaan_pin` beserta perangkat, dengan RLS: pegawai hanya melihat catatannya sendiri, pemegang izin kelola_pegawai melihat catatan pegawai restonya, dan **tidak ada** jalur menulis langsung dari klien. PIN benar tetapi pegawainya **tidak berizin** untuk aksi itu → tetap ditolak (memakai `boleh_untuk()`); PIN pegawai resto lain / akun nonaktif → “PIN tidak dikenali” tanpa membocorkan apa pun; `ganti_pin` sendiri wajib PIN lama. **Gerbang dibuktikan bisa MERAH lewat 4 uji mutasi** (batas percobaan dimatikan · PIN disimpan mentah · PIN resto lain diterima · izin penyetuju diabaikan) — semuanya GAGAL, LOLOS setelah dipulihkan. Edge Function `verifikasi_pin` sengaja **tipis** (meneruskan ke RPC) dan dijaga pemeriksa baru `alat/periksa-fungsi-pin.py` yang menolak kiriman kode bila muncul `console.*`, `service_role`, atau penjagaan POST hilang (9 pemeriksaan, 3 uji mutasi menyalakan GAGAL) — pemeriksa itu ikut berjalan di CI. **Batas yang jujur:** waktu uji ini, Deno belum tersedia di ruang kerja sehingga **uji runtime Edge Function langsung** (menembak fungsi dengan HTTP sungguhan) menunggu akun Supabase di T0-08; yang terbukti sekarang = seluruh logika PIN di database + penjagaan statis berkas Edge Function. Di Supabase nanti bcrypt **asli** (pgcrypto) yang dipakai dan uji yang sama dijalankan ulang.

- [ ] T1-07 — Migrasi katalog: kategori, menu, varian, tambahan, harga per cabang, stok
  - **Tujuan:** menu bisa berbeda harga per cabang dan penanda habis bekerja lintas layar.
  - **Ref:** TECH_SPEC §4.2 (tabel resmi: `kategori_menu`, `menu_item`, `menu_varian`, `menu_tambahan`, `menu_cabang`, `stok_bahan`, `stok_pergerakan`); PRD M2, M9, M11
  - **File:** `supabase/migrations/0007_katalog.sql`
  - **DoD:** tabel & relasi sesuai TECH_SPEC §4; harga per cabang opsional (bila kosong → pakai harga pusat); RLS + uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** harga berubah mengubah riwayat → mitigasi: transaksi menyimpan `harga_saat_itu` (dibuktikan di T1-09).
  - **Verifikasi:** uji SQL: ubah harga menu → pesanan lama tetap memakai harga tercatat.

- [ ] T1-08 — Migrasi meja & status meja
  - **Tujuan:** meja bisa dipantau statusnya (kosong/terisi/siap disajikan) dan diatur per cabang.
  - **Ref:** TECH_SPEC §4; PRD M4
  - **File:** `supabase/migrations/0008_meja.sql`
  - **DoD:** meja per cabang + area + status; nomor meja unik per cabang; uji RLS lulus.
  - **Kompleksitas:** sedang (2 jam)
  - **Risiko & mitigasi:** dua pelayan membuka meja sama → mitigasi: dibahas di T3-09 dengan penguncian status.
  - **Verifikasi:** uji SQL menyisipkan meja di 2 cabang, memastikan tidak saling terlihat.

- [ ] T1-09 — Migrasi pesanan & item (dengan harga_saat_itu) ⚠️
  - **Tujuan:** pesanan tidak bisa berubah arti walau menu/harga diubah kemudian.
  - **Ref:** TECH_SPEC §4 & §9 ART-3/ART-4; PRD M4
  - **File:** `supabase/migrations/0009_pesanan.sql`
  - **DoD:** `pesanan` + `pesanan_item` ada; setiap item menyimpan `harga_saat_itu`, `nama_saat_itu`, catatan khusus; status pesanan memakai daftar resmi; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4) & Kalkulasi (ART-3); mitigasi: enum status + `harga_saat_itu` wajib NOT NULL.
  - **Verifikasi:** uji SQL: ubah harga setelah pesanan dibuat → struk lama tidak berubah.

- [ ] T1-10 — Migrasi pembayaran, metode bayar, diskon, pembatalan
  - **Tujuan:** semua uang masuk dan pembatalan tercatat lengkap dengan bukti.
  - **Ref:** TECH_SPEC §4 & §9 ART-3; PRD M6
  - **File:** `supabase/migrations/0010_pembayaran.sql`
  - **DoD:** tabel pembayaran (banyak baris per pesanan), `metode_bayar` (per penyewa), `diskon_transaksi` (jenis, nilai, batas), `pembatalan` (alasan, pelaku, nilai, bahan terbuang); uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3); pembayaran sebagian disalahartikan → mitigasi: aturan "satu pembayaran = satu transaksi tercatat, tidak boleh dobel".
  - **Verifikasi:** uji SQL: diskon melebihi batas → ditolak; pembatalan tanpa alasan → ditolak.

- [ ] T1-11 — Migrasi kas & shift + printer
  - **Tujuan:** uang kas selalu bisa diaudit (modal, masuk, keluar, hasil hitung, selisih).
  - **Ref:** TECH_SPEC §4 & §9 ART-6; PRD M7
  - **File:** `supabase/migrations/0011_kas_shift.sql`
  - **DoD:** `shift_kas` (buka/tutup, modal, seharusnya, fisik, selisih, alasan) + `kas_pergerakan` + `printer` (per perangkat/cabang); uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); shift menggantung → mitigasi: aturan & pengingat (T7-05).
  - **Verifikasi:** uji SQL: transaksi di luar shift ditolak.

- [ ] T1-12 — Migrasi pelanggan, kampanye voucher, voucher, percobaan voucher ⚠️
  - **Tujuan:** voucher tidak bisa dipakai dua kali dan data pelanggan sesedikit mungkin (privasi).
  - **Ref:** TECH_SPEC §4 (tabel: pelanggan, kampanye_voucher, voucher, voucher_percobaan) & §9 ART-5/ART-10; PRD M10
  - **File:** `supabase/migrations/0012_voucher.sql`
  - **DoD:** tabel pelanggan (nama, email, opsi alamat, persetujuan), kampanye (nilai, minimum, batas potongan, masa berlaku, kuota, anggaran, cabang), voucher (kode acak, status), percobaan (log semua cek/scan); indeks unik mencegah dobel; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Voucher (ART-5) & Privasi (ART-10); dobel pakai → mitigasi: kunci unik + transaksi atomik di T1-20.
  - **Verifikasi:** uji SQL: menyisipkan pemakaian kedua ditolak oleh constraint.

- [ ] T1-13 — Migrasi catatan_audit (hanya-tambah) ⚠️
  - **Tujuan:** jejak tindakan sensitif tidak bisa diubah atau dihapus siapa pun.
  - **Ref:** TECH_SPEC §4 & §9 ART-6; PRD M3
  - **File:** `supabase/migrations/0013_catatan_audit.sql`, `supabase/tes/audit.sql`
  - **DoD:** hanya bisa INSERT; UPDATE/DELETE ditolak untuk semua peran (termasuk owner & service role via policy/trigger); uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Audit (ART-6); hapus jejak untuk menutupi kecurangan → mitigasi: larangan di tingkat database, bukan aplikasi.
  - **Verifikasi:** uji SQL: `UPDATE` dan `DELETE` gagal dengan pesan jelas.

- [ ] T1-14 — Migrasi antrean kirim & catatan kesalahan
  - **Tujuan:** pesanan saat internet putus tidak hilang dan masalah bisa diperiksa tanpa menebak.
  - **Ref:** TECH_SPEC §4 & §9 ART-8; PRD §9 (risiko)
  - **File:** `supabase/migrations/0014_antrean_kesalahan.sql`
  - **DoD:** tabel `antrean_kirim` (kunci idempoten unik) + `catatan_kesalahan` (tingkat, kode, konteks) ada; tidak menyimpan sandi/PIN; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Antrean Offline (ART-8); data sensitif tercatat → mitigasi: daftar kolom terbatas + tinjauan manual.
  - **Verifikasi:** uji SQL: dua kiriman dengan kunci sama → hanya satu yang diterima.

- [ ] T1-15 — Fungsi hitung_total() + 12 uji uang ⚠️
  - **Tujuan:** satu-satunya tempat menghitung uang, supaya tidak ada dua rumus yang bisa berselisih.
  - **Ref:** TECH_SPEC §5 & §9 ART-3; PRD M6
  - **File:** `supabase/migrations/0015_hitung_total.sql`, `supabase/tes/uang.sql`
  - **DoD:** mengembalikan rincian {subtotal, diskon, pb1, service, pembulatan, total}; 12 kasus lulus (pajak 0%, service 0%, diskon penuh, pembulatan .01, uang pas, uang lebih, void sebagian); tidak ada tipe pecahan untuk nominal.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3); dua rumus berbeda → mitigasi: klien DILARANG menghitung; semua pemanggilan lewat RPC ini.
  - **Verifikasi:** `supabase test` 12 kasus hijau + bandingkan 3 contoh struk dengan kalkulator manual.

- [ ] T1-16 — Urutan hitungan resmi & aturan pembulatan dari pengaturan ⚠️
  - **Tujuan:** urutan (subtotal → diskon → PB1 → service → pembulatan) tidak bisa ditafsirkan berbeda antar sesi.
  - **Ref:** TECH_SPEC §9 ART-3 & §13 (log keputusan); PRD M2 & M6
  - **File:** `supabase/migrations/0016_urutan_pembulatan.sql`, `supabase/tes/urutan.sql`
  - **DoD:** diskon dihitung dari subtotal; pajak & service dari subtotal setelah diskon; pembulatan sesuai pengaturan (0/100/500); uji lulus dan hasilnya dicatat di `DECISIONS_LOG.md`.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3); urutan salah → selisih kas → mitigasi: uji contoh nyata + satu fungsi sumber.
  - **Verifikasi:** uji SQL dengan 6 kombinasi diskon × pajak × pembulatan.

- [ ] T1-17 — Penomoran pesanan harian per zona waktu penyewa ⚠️
  - **Tujuan:** nomor pesanan tidak bentrok, termasuk saat tengah malam.
  - **Ref:** TECH_SPEC §9 ART-9; PRD M8 (kasus tepi tengah malam)
  - **File:** `supabase/migrations/0017_penomoran.sql`, `supabase/tes/penomoran.sql`
  - **DoD:** nomor urut per penyewa/cabang/hari memakai zona waktu penyewa; dua pesanan bersamaan tidak dapat nomor sama; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Zona waktu & penomoran (ART-9); balapan bersamaan → mitigasi: urutan di database (bukan di aplikasi).
  - **Verifikasi:** uji SQL membuat 2 pesanan "bersamaan" (transaksi paralel) → nomor berbeda.

- [ ] T1-18 — State machine pesanan + uji transisi ⚠️
  - **Tujuan:** status pesanan hanya bisa berubah lewat jalur yang sah.
  - **Ref:** TECH_SPEC §9 ART-4; PRD M4, M5, M6
  - **File:** `supabase/migrations/0018_state_machine.sql`, `supabase/tes/status.sql`
  - **DoD:** daftar status resmi **persis seperti `TECH_SPEC.md` §4.3** (draf → dikirim → dimasak → siap → lunas; batal) + aturan transisi; transisi terlarang ditolak; uji lulus untuk 6 skenario.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4); status "nyangkut" → mitigasi: aturan + uji + tampilan yang selalu menunjukkan langkah berikutnya.
  - **Verifikasi:** uji SQL menolak 4 transisi terlarang (mis. draf → lunas).

- [ ] T1-19 — RPC cek_voucher (BACA SAJA) ⚠️
  - **Tujuan:** kasir bisa memeriksa voucher tanpa mengubah statusnya sedikit pun.
  - **Ref:** TECH_SPEC §5 & §9 ART-5; PRD M10 · RPC resmi: `pakai_voucher`, `daftar_voucher`
  - **File:** `supabase/migrations/0019_cek_voucher.sql`, `supabase/tes/cek_voucher.sql`
  - **DoD:** fungsi tidak menulis apa pun (dibuktikan uji: status voucher tidak berubah, tidak ada baris baru); mengembalikan alasan gagal yang spesifik; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Voucher (ART-5); "cek" tidak sengaja memakai voucher → mitigasi: hak database hanya SELECT + uji "tidak ada perubahan".
  - **Verifikasi:** uji SQL membandingkan seluruh isi tabel sebelum & sesudah pemanggilan (harus identik).

- [ ] T1-20 — RPC pakai_voucher (atomik, sekali pakai, + PIN) ⚠️
  - **Tujuan:** voucher tidak mungkin terpakai dua kali walau ada dua kasir bersamaan.
  - **Ref:** TECH_SPEC §5 & §9 ART-5; PRD M10
  - **File:** `supabase/migrations/0020_pakai_voucher.sql`, `supabase/tes/pakai_voucher.sql`
  - **DoD:** memakai transaksi + penguncian baris; memeriksa masa berlaku, minimum belanja, cabang, batas potongan, anggaran kampanye, kuota; wajib PIN kasir/atasan yang berizin; uji lulus termasuk dua pemanggilan bersamaan.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Voucher (ART-5); balapan ganda → mitigasi: `SELECT ... FOR UPDATE` + constraint unik + uji paralel.
  - **Verifikasi:** uji SQL: 2 pemanggilan paralel → tepat satu berhasil.

- [ ] T1-21 — Data awal (seed) + penetapan contoh
  - **Tujuan:** aplikasi bisa diuji tanpa mengetik data manual setiap kali.
  - **Ref:** TECH_SPEC §3 (`supabase/seed.sql`); PRD M1/M2
  - **File:** `supabase/seed.sql`, `supabase/seed_uji.sql`
  - **DoD:** seed memuat 1 penyewa contoh + 2 cabang + 6 akun peran + metode bayar + meja + 20 menu contoh + pengaturan bawaan (PB1 10%, service 5%); **tidak ada** data ini di produksi; uji lulus.
  - **Kompleksitas:** sedang (2 jam)
  - **Risiko & mitigasi:** data contoh terpakai di produksi → mitigasi: seed hanya dijalankan di lingkungan pengembangan + pemisahan tegas berkasnya.
  - **Verifikasi:** jalankan seed di dev → semua layar punya data; produksi tetap kosong.

- [ ] T1-22 — Penyisiran RLS menyeluruh + uji SQL otomatis di CI ⚠️
  - **Tujuan:** pembuktian bahwa TIDAK ADA tabel yang lolos dari penguncian.
  - **Ref:** TECH_SPEC §9 ART-1 & §11; AGENT_OPERATING_GUIDE §5
  - **File:** `supabase/tes/sisir_rls.sql`, `.github/workflows/ci.yml` (langkah uji SQL)
  - **DoD:** skrip daftar tabel ↔ policy (tabel tanpa policy = gagal); CI menjalankan seluruh uji SQL pada setiap push; laporan jumlah tabel & policy tercetak.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: RLS (ART-1); tabel baru mengulang kesalahan yang sama → mitigasi: uji ini otomatis di CI, bukan disiplin manual.
  - **Verifikasi:** CI hijau + sengaja menambah tabel tanpa policy → CI merah.

---

## Fase 2 — Masuk & kerangka aplikasi

- [ ] T2-01 — Pemasangan Supabase Auth di klien + penyimpanan sesi aman
  - **Tujuan:** aplikasi tahu siapa yang sedang masuk dan sesinya tidak bisa dicuri lewat penyimpanan yang salah.
  - **Ref:** TECH_SPEC §1 & §7; PRD M12
  - **File:** `aplikasi/src/lib/auth.ts`, `aplikasi/src/hook/useSesi.ts`
  - **DoD:** sesi tersimpan aman; token disegarkan otomatis; keluar menghapus sesi; tidak ada token di localStorage yang bertahan setelah keluar.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** sesi menggantung di perangkat bersama → mitigasi: sesi berakhir otomatis (T2-09) + keluar dari semua perangkat (T10-06).
  - **Verifikasi:** uji unit + uji manual masuk/keluar pada 2 tab.

- [ ] T2-02 — Layar masuk pegawai (email + PIN)
  - **Tujuan:** pegawai bisa masuk cepat (kasir tidak mengetik sandi panjang) tetapi tetap aman.
  - **Ref:** TECH_SPEC §13 (K5); PRD M3 & M12
  - **File:** `aplikasi/src/layar/masuk/LayarMasukPegawai.tsx`, `supabase/tes/masuk_pegawai.sql`
  - **DoD:** masuk dengan email + PIN; PIN salah dibatasi; pesan gagal jelas (bukan pesan teknis); uji alur lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); PIN mudah ditebak → mitigasi: PIN minimal 6 angka, pembatasan percobaan, catatan audit.
  - **Verifikasi:** uji manual 3 kasus (PIN benar, PIN salah, akun nonaktif).

- [ ] T2-03 — Pembuatan & pengelolaan akun pegawai oleh admin  <!-- T-004 sudah ditutup 2026-09-16: semua pegawai dianggap punya email; admin bisa membuatkan -->
  - **Tujuan:** Owner/Admin Cabang bisa menambah pegawai tanpa bantuan teknis.
  - **Ref:** PRD M3; TECH_SPEC §4 (pengguna) & §9 ART-2
  - **File:** `aplikasi/src/layar/pengaturan/KelolaPegawai.tsx`, `supabase/functions/undang_pegawai/index.ts`
  - **DoD:** admin menambah pegawai (nama, email, peran, cabang, izin), mengirim undangan/pembuatan PIN pertama, menonaktifkan pegawai (riwayat tetap); pegawai tanpa email bisa dibuatkan (opsi tercatat).
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); akun telantar → mitigasi: daftar pegawai nonaktif + tinjauan berkala di panduan owner.
  - **Verifikasi:** uji manual: tambah pegawai → bisa masuk → nonaktifkan → tidak bisa masuk lagi.

- [ ] T2-04 — Masuk pelanggan: Google (utama) + email terverifikasi (kedua)
  - **Tujuan:** pelanggan bisa mendaftar tanpa SMS dan tanpa biaya.
  - **Ref:** PRD M10 & M12; TECH_SPEC §7 (integrasi)
  - **File:** `aplikasi/src/layar/masuk/LayarMasukPelanggan.tsx`, `aplikasi/src/lib/google.ts`
  - **DoD:** "Daftar dengan Google" bekerja; jalur email mengirim verifikasi; identitas pelanggan tersimpan tanpa data berlebih; uji manual dua jalur lulus.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Privasi (ART-10); data berlebih → mitigasi: hanya nama, email, nomor HP opsional, persetujuan.
  - **Verifikasi:** uji manual masuk Google di perangkat Android + jalur email di desktop.

- [ ] T2-05 — Pemulihan akses pelanggan (lupa PIN / ganti perangkat)
  - **Tujuan:** pelanggan tidak terjebak kehilangan vouchernya.
  - **Ref:** PRD M10 (kasus tepi); TECH_SPEC §7
  - **File:** `supabase/functions/pemulihan_pelanggan/index.ts`, `aplikasi/src/layar/masuk/LupaAkses.tsx`
  - **DoD:** pemulihan lewat email terverifikasi bekerja; tidak bisa dipakai untuk mengambil alih akun orang lain (uji 2 kasus penyalahgunaan).
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** pengambilalihan akun → mitigasi: token sekali pakai + masa berlaku pendek + catatan percobaan.
  - **Verifikasi:** uji manual + uji SQL percobaan token kedaluwarsa.

- [ ] T2-06 — Kerangka aplikasi: layout, navigasi per peran, tema
  - **Tujuan:** setiap peran hanya melihat menu yang relevan dan tidak tersesat.
  - **Ref:** PRD §7 (alur pengguna); TECH_SPEC §3
  - **File:** `aplikasi/src/App.tsx`, `aplikasi/src/komponen/Rangka.tsx`, `aplikasi/src/komponen/Navigasi.tsx`
  - **DoD:** menu berbeda untuk 6 peran; halaman awal menyesuaikan peran (kasir → kasir, dapur → dapur); pengalih tema & kerapatan bekerja; akses langsung ke URL terlarang ditolak dengan pesan ramah.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); menu tersembunyi ≠ aman → mitigasi: pembatasan menu hanya kosmetik; keamanan tetap di RLS/RPC.
  - **Verifikasi:** uji manual 6 peran + uji akses URL langsung.

- [ ] T2-07 — Pemilih cabang + konteks cabang aktif
  - **Tujuan:** Admin Cabang terkunci ke cabangnya, Owner bisa berpindah cabang.
  - **Ref:** PRD M11; TECH_SPEC §9 ART-1
  - **File:** `aplikasi/src/hook/useCabang.ts`, `aplikasi/src/komponen/PemilihCabang.tsx`
  - **DoD:** Owner/Admin Pusat bisa memilih cabang; Admin Cabang tidak bisa keluar dari cabangnya (server menolak, bukan hanya UI); pilihan tersimpan sesi.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: RLS (ART-1); kebocoran lintas cabang → mitigasi: server menolak berdasarkan `cabang_ids()`, bukan filter di klien.
  - **Verifikasi:** uji SQL: permintaan data cabang lain sebagai Admin Cabang ditolak.

- [ ] T2-08 — Halaman "tidak punya akses" + pesan ramah berkode
  - **Tujuan:** pengguna tahu apa yang terjadi dan apa langkah berikutnya.
  - **Ref:** AGENT_OPERATING_GUIDE §6 (format error)
  - **File:** `aplikasi/src/layar/TidakPunyaAkses.tsx`, `aplikasi/src/lib/pesan.ts`
  - **DoD:** pesan berisi masalah + tindakan + kode (mis. AK-601); tidak ada istilah teknis; tombol kembali ke halaman yang sesuai.
  - **Kompleksitas:** kecil (1,5 jam)
  - **Risiko & mitigasi:** pesan membocorkan informasi → mitigasi: pesan seragam tanpa detail internal.
  - **Verifikasi:** uji manual 3 kasus akses terlarang.

- [ ] T2-09 — Sesi berakhir otomatis saat tidak dipakai ⚠️
  - **Tujuan:** perangkat yang ditinggal tidak menjadi pintu terbuka.
  - **Ref:** PRD M12; TECH_SPEC §9 ART-2
  - **File:** `aplikasi/src/hook/useKunciSesi.ts`
  - **DoD:** setelah masa diam (mis. 15 menit kasir, 30 menit admin) sesi terkunci dan minta PIN/masuk ulang; pekerjaan yang belum tersimpan diberi peringatan.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); penguncian saat sibuk mengganggu → mitigasi: peringatan 60 detik sebelumnya + masa diam per peran.
  - **Verifikasi:** uji manual menunggu tanpa interaksi → terkunci.

- [ ] T2-10 — Pembatasan percobaan masuk (server-side) ⚠️
  - **Tujuan:** tidak ada yang bisa mencoba-coba masuk berulang kali.
  - **Ref:** PRD M12; TECH_SPEC §9 ART-2
  - **File:** `supabase/functions/pembatas_masuk/index.ts`, `supabase/tes/pembatas.sql`
  - **DoD:** batas percobaan per akun + per perangkat/IP; jeda bertahap; semua percobaan tercatat (kode AK-6xx); uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); memblokir pengguna sah → mitigasi: jeda bertahap, bukan blokir permanen, + jalur atasan.
  - **Verifikasi:** uji fungsi: 10 percobaan berurutan → ditolak dengan pesan jelas.

- [ ] T2-11 — PWA dasar: manifest + ikon + service worker  <!-- T-001 sudah ditutup 2026-09-16: nama kerja "Sajian" -->
  - **Tujuan:** aplikasi bisa dipasang di layar utama perangkat dan tetap terbuka saat internet putus sebentar.
  - **Ref:** TECH_SPEC §1 (PWA) & §3 (`public/`)
  - **File:** `aplikasi/public/manifest.webmanifest`, `aplikasi/public/sw.js`, `aplikasi/public/ikon/*`
  - **DoD:** bisa "Dipasang ke layar utama" di Android/desktop; ikon & nama dari pengaturan; cangkang aplikasi tetap tampil saat luring; tidak menyimpan data sensitif di cache.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** cache menyimpan data pesanan → risiko kebocoran di perangkat bersama → mitigasi: cache hanya berkas tampilan, bukan data; diuji di T10-04.
  - **Verifikasi:** uji manual pemasangan + matikan internet → aplikasi tetap terbuka dengan pesan jelas.

- [ ] T2-12 — Uji menyeluruh masuk & hak akses (6 peran) ⚠️
  - **Tujuan:** membuktikan tiap peran hanya bisa melakukan yang diizinkan.
  - **Ref:** PRD M3 & M12; TECH_SPEC §9 ART-2
  - **File:** `aplikasi/src/layar/masuk/*.test.ts`, `supabase/tes/peran_masuk.sql`
  - **DoD:** uji otomatis: 6 peran masuk; 10 tindakan sensitif diuji (harus ditolak/izin); laporan hasil ditulis di ringkasan fase.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); kesalahan izin terbawa ke fase berikutnya → mitigasi: uji ini dijalankan ulang di T10-05.
  - **Verifikasi:** `npm test` + `supabase test` hijau; hasil dicatat di `docs/DECISIONS_LOG.md`.

---

## Fase 3 — Pesanan & kasir (M4)

- [ ] T3-01 — Layar kasir: katalog nyata dari database
  - **Tujuan:** kasir bisa memilih menu dengan cepat dari data asli (kategori, varian, tambahan).
  - **Ref:** PRD M4 & M2; TECH_SPEC §4
  - **File:** `aplikasi/src/layar/kasir/LayarKasir.tsx`, `aplikasi/src/layar/kasir/Katalog.tsx`
  - **DoD:** kategori & pencarian bekerja; varian/tambahan muncul sesuai pengaturan; item habis terkunci; bahasa Indonesia.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** lambat saat katalog besar → mitigasi: muat bertahap + cache ringan di klien (tanpa data sensitif).
  - **Verifikasi:** uji manual dengan 200 item; waktu muat awal < 3 detik.

- [ ] T3-02 — Keranjang + angka dari peladen (klien tidak menghitung)
  - **Tujuan:** angka di keranjang selalu sama dengan angka resmi sistem.
  - **Ref:** TECH_SPEC §9 ART-3; PRD M6
  - **File:** `aplikasi/src/layar/kasir/Keranjang.tsx`, `aplikasi/src/lib/uang.ts`
  - **DoD:** penambahan/pengurangan item, ubah jumlah, hapus, catatan per item; total diambil dari `hitung_total()`; tidak ada rumus uang di klien (diperiksa grep + uji).
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3); rumus tersalin ke klien → mitigasi: uji otomatis "klien dilarang menghitung" (mencari pola perhitungan nominal di `/src/layar`).
  - **Verifikasi:** uji unit + pemeriksaan otomatis larangan perhitungan di klien.

- [ ] T3-03 — Pilih meja / jenis pesanan + catatan khusus
  - **Tujuan:** pesanan dicatat sesuai kenyataan (dine-in, bawa pulang, ojol) dengan permintaan khusus.
  - **Ref:** PRD M4 (kriteria selesai)
  - **File:** `aplikasi/src/layar/kasir/PemilihMeja.tsx`, `aplikasi/src/komponen/CatatanItem.tsx`
  - **DoD:** pilih meja/kategori pesanan; catatan cepat (tanpa es, kurang pedas, tanpa jeroan) + ketik bebas; catatan tampil mencolok di dapur.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** salah meja → mitigasi: konfirmasi + tampilan nomor meja besar di keranjang.
  - **Verifikasi:** uji manual 3 jenis pesanan + catatan sampai ke layar dapur.

- [ ] T3-04 — Tagihan terbuka (open bill): simpan & lanjutkan
  - **Tujuan:** pelanggan bisa memesan bertahap tanpa tagihan terpisah.
  - **Ref:** PRD M4 (kriteria selesai)
  - **File:** `aplikasi/src/layar/kasir/DaftarTagihan.tsx`
  - **DoD:** pesanan tersimpan sebagai tagihan terbuka; bisa ditambah beberapa kali sebelum dibayar; tagihan ditinggal pelanggan tetap muncul dengan penanda; uji manual lulus.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** tagihan terlupakan → mitigasi: daftar tagihan di layar utama + penanda umur tagihan.
  - **Verifikasi:** uji manual: buka tagihan → tambah 2× → bayar sebagian (dua transaksi) → tercatat benar.

- [ ] T3-05 — RPC simpan_pesanan + kunci idempoten ⚠️
  - **Tujuan:** pesanan tersimpan sekali saja walau tombol ditekan berkali-kali atau internet putus.
  - **Ref:** TECH_SPEC §5 (RPC) & §9 ART-4/ART-8 · RPC resmi: `tambah_item`, `pindah_meja`, `kirim_ke_dapur`
  - **File:** `supabase/migrations/0021_simpan_pesanan.sql`, `supabase/tes/simpan_pesanan.sql`
  - **DoD:** RPC menolak duplikat dengan kunci idempoten; menolak pesanan tanpa item; menolak di luar shift terbuka; hak akses diperiksa; uji lulus (termasuk 5 pemanggilan kunci sama).
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4) & Antrean (ART-8); pesanan dobel → mitigasi: kunci unik di database + uji paralel.
  - **Verifikasi:** uji SQL: 5 pemanggilan dengan kunci sama → 1 pesanan; tanpa kunci → ditolak.

- [ ] T3-06 — Pindah meja + status meja
  - **Tujuan:** pelanggan pindah meja tanpa membingungkan dapur/kasir.
  - **Ref:** PRD M4 (kasus tepi)
  - **File:** `aplikasi/src/layar/kasir/PindahMeja.tsx`, `supabase/migrations/0022_pindah_meja.sql`
  - **DoD:** pindah meja tercatat (dari → ke, oleh siapa); status meja otomatis (kosong/terisi/siap); riwayat tetap.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** salah pindah → mitigasi: konfirmasi + catatan audit.
  - **Verifikasi:** uji manual + uji SQL riwayat pindah meja.

- [ ] T3-07 — Penguncian menu habis di kasir
  - **Tujuan:** pelanggan tidak memesan yang sudah habis.
  - **Ref:** PRD M9 (kriteria selesai); TECH_SPEC §4.2 (`stok_pergerakan`, jenis `opname`)
  - **File:** `aplikasi/src/layar/kasir/Katalog.tsx` (penanda habis), `supabase/migrations/0023_menu_habis.sql`
  - **DoD:** menandai habis dari kasir & dapur; item habis tidak bisa ditambahkan; pencabutan penanda butuh izin; perubahan tampil di katalog publik.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** penanda lupa dicabut → mitigasi: daftar "menu habis hari ini" di layar kasir + pengingat pagi.
  - **Verifikasi:** uji manual + uji SQL (item habis ditolak di RPC pesanan).

- [ ] T3-08 — Kirim ke dapur (status pesanan berubah)
  - **Tujuan:** dapur mulai bekerja begitu pesanan dikirim, dan kasir tahu statusnya.
  - **Ref:** PRD M4 & M5; TECH_SPEC §9 ART-4
  - **File:** `aplikasi/src/layar/kasir/KirimDapur.tsx`, `supabase/migrations/0024_kirim_dapur.sql`
  - **DoD:** status berpindah draf → dikirim lewat jalur sah; item makanan/minuman bertanda tujuan; kasir melihat status (dikirim/dimasak/siap).
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4); kiriman ganda → mitigasi: kunci idempoten dari T3-05 dipakai ulang.
  - **Verifikasi:** uji manual + uji SQL transisi ganda.

- [ ] T3-09 — Konflik meja (dua pelayan, satu meja)
  - **Tujuan:** tidak ada dua orang mengerjakan meja yang sama tanpa sadar.
  - **Ref:** PRD M4 (kasus tepi)
  - **File:** `aplikasi/src/layar/kasir/PeringatanMeja.tsx`, `supabase/tes/konflik_meja.sql`
  - **DoD:** membuka meja terisi → peringatan berisi siapa & sejak kapan; opsi gabung/lanjutkan/pindah; tercatat di audit.
  - **Kompleksitas:** sedang (2,5 jam)
  - **Risiko & mitigasi:** pesanan tertukar → mitigasi: tampilan nama pelayan + jam buka meja.
  - **Verifikasi:** uji manual dua perangkat bersamaan.

- [ ] T3-10 — Keramahan sentuh & papan ketik (kasir sibuk)
  - **Tujuan:** kasir bekerja cepat walau tanpa mouse.
  - **Ref:** AGENT_OPERATING_GUIDE §3 (a11y)
  - **File:** `aplikasi/src/gaya/kasir.css`, `aplikasi/src/hook/usePintasan.ts`
  - **DoD:** target sentuh ≥44 px; pintasan (cari menu, jumlah, bayar, kirim); fokus keyboard jelas; uji kontras lulus di kasir.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** pintasan bentrok → mitigasi: daftar pintasan tampil dengan tombol `?`.
  - **Verifikasi:** uji manual pakai hanya papan ketik + pemeriksa kontras.

- [ ] T3-11 — Layar pesanan pelayan (HP di samping meja)
  - **Tujuan:** pelayan mencatat pesanan tanpa kembali ke kasir.
  - **Ref:** PRD M4 (kriteria selesai)
  - **File:** `aplikasi/src/layar/pelayan/LayarPelayan.tsx`
  - **DoD:** tampilan ringkas untuk HP; hanya menu & meja cabangnya; pesanan masuk ke tagihan yang sama; tersinkron dengan kasir.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** pesanan ganda antara pelayan & kasir → mitigasi: satu tagihan per meja + kunci idempoten + penyegaran langsung.
  - **Verifikasi:** uji manual dua perangkat (kasir + HP) pada satu meja.

- [ ] T3-12 — Daftar pesanan hari ini + filter
  - **Tujuan:** kasir/pelayan bisa menemukan pesanan dengan cepat.
  - **Ref:** PRD M4; TECH_SPEC §5
  - **File:** `aplikasi/src/layar/kasir/DaftarPesanan.tsx`
  - **DoD:** filter status/jenis/meja; pencarian nomor pesanan; hanya data cabang sendiri; kinerja baik untuk 300 pesanan/hari.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** daftar lambat → mitigasi: pemuatan bertahap + indeks database pada kolom pencarian.
  - **Verifikasi:** uji manual dengan 300 pesanan contoh (seed) → respons < 1 detik.

- [ ] T3-13 — Pembatalan sebelum dapur mulai (dari kasir) ⚠️
  - **Tujuan:** salah input bisa dibatalkan cepat, tetapi selalu tercatat dengan alasan.
  - **Ref:** PRD M6 (aturan pembatalan bertingkat); TECH_SPEC §9 ART-4
  - **File:** `aplikasi/src/layar/kasir/BatalPesanan.tsx`, `supabase/migrations/0025_batal_pra_dapur.sql`
  - **DoD:** hanya untuk pesanan yang belum dimasak; alasan wajib (daftar + ketik); masuk laporan pembatalan; tidak ada data yang dihapus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4); pembatalan untuk menutupi kecurangan → mitigasi: wajib alasan + catatan audit + laporan harian.
  - **Verifikasi:** uji manual + uji SQL (pembatalan tanpa alasan ditolak; setelah dimasak ditolak).

- [ ] T3-14 — Uji alur kasir ujung-ke-ujung (dasar)
  - **Tujuan:** jalur utama kasir terbukti bekerja sebelum masuk ke fase berikutnya.
  - **Ref:** TECH_SPEC §11 (uji); AGENT_OPERATING_GUIDE §5
  - **File:** `aplikasi/uji/e2e/kasir.spec.ts`
  - **DoD:** uji otomatis: buka meja → pesan 3 item + catatan → kirim → tampil di dapur (dasar); lulus di CI.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** uji rapuh → mitigasi: pemilih berbasis peran teks bahasa Indonesia (stabil) + tunggu kondisi, bukan waktu.
  - **Verifikasi:** uji dijalankan di CI dan lulus.

- [ ] T3-15 — Keadaan kosong/memuat/gagal di seluruh layar kasir
  - **Tujuan:** kasir tidak pernah melihat layar kosong tanpa penjelasan.
  - **Ref:** AGENT_OPERATING_GUIDE §6; TECH_SPEC §11
  - **File:** `aplikasi/src/layar/kasir/*.tsx`, `aplikasi/src/komponen/Keadaan*.tsx`
  - **DoD:** setiap layar punya 3 keadaan dengan bahasa manusia + tindakan; saat gagal koneksi, pesanan masuk antrean (dasar) dengan pesan.
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** pesan menakutkan → mitigasi: bahasa sederhana + kode (PS-1xx).
  - **Verifikasi:** uji manual: matikan jaringan → semua layar memberi pesan jelas.

- [ ] T3-16 — Uji beban ringan kasir
  - **Tujuan:** kasir tetap cepat saat jam sibuk.
  - **Ref:** PRD §9 (risiko); TECH_SPEC §11
  - **File:** `aplikasi/uji/beban/kasir.test.ts`
  - **DoD:** 50 item dalam satu tagihan & 300 pesanan/hari tetap responsif (< 1 detik per aksi utama); tidak ada kebocoran memori pada sesi 1 jam (uji kasur).
  - **Kompleksitas:** sedang (2,5 jam)
  - **Risiko & mitigasi:** perangkat kasir kelas rendah → mitigasi: hindari animasi berat saat maraton pesanan + ukur di perangkat nyata (T11-04).
  - **Verifikasi:** laporan angka waktu dari uji otomatis dicatat di ringkasan fase.

---

## Fase 4 — Dapur/KDS & stok dasar (M5, M9)

- [ ] T4-01 — Layar dapur (makanan) dengan urutan FIFO
  - **Tujuan:** dapur memasak sesuai urutan masuk, tidak ada yang terlewat.
  - **Ref:** PRD M5 (kriteria selesai)
  - **File:** `aplikasi/src/layar/dapur/LayarDapur.tsx`
  - **DoD:** pesanan makanan tampil urut tertua di atas; tampilan besar terbaca dari jauh; penyegaran otomatis (realtime).
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** urutan berubah saat penyegaran → mitigasi: urutan berdasarkan waktu kirim dari database (bukan waktu terima di klien).
  - **Verifikasi:** uji manual 10 pesanan berurutan.

- [ ] T4-02 — Layar bar (minuman) terpisah
  - **Tujuan:** bar menerima hanya minuman, tidak tercampur.
  - **Ref:** PRD M5 (kriteria selesai)
  - **File:** `aplikasi/src/layar/dapur/LayarBar.tsx`, `supabase/migrations/0026_tujuan_item.sql`
  - **DoD:** pesanan dipisah otomatis berdasarkan kategori/tujuan item; satu pesanan bisa muncul di dua layar (bagian masing-masing); status per bagian.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** item tanpa kategori → tidak muncul di mana pun → mitigasi: kategori wajib + uji "semua item punya tujuan".
  - **Verifikasi:** uji manual + uji SQL (item tanpa tujuan ditolak saat menyimpan menu).

- [ ] T4-03 — Tanda jenis pesanan + instruksi khusus mencolok
  - **Tujuan:** kesalahan hidangan berkurang.
  - **Ref:** PRD M5 (kriteria selesai)
  - **File:** `aplikasi/src/layar/dapur/KartuPesanan.tsx`
  - **DoD:** jenis pesanan (dine-in/bawa pulang/ojol) jelas dengan warna & label; catatan khusus tampil besar; nomor meja jelas.
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** informasi penting tenggelam → mitigasi: uji keterbacaan dari jarak 2 meter (foto bukti).
  - **Verifikasi:** uji manual + pemeriksaan kontras aplikasi. · **Bukti visual** (tangkapan layar/foto) diambil pemilik atau penguji manusia; tugas ditandai `[x]` hanya setelah buktinya diterima.

- [ ] T4-04 — Ubah status per item & seluruh pesanan (anti-dobel) ⚠️
  - **Tujuan:** dua orang menandai item sama tidak menghasilkan status ganda/salah.
  - **Ref:** PRD M5 (kasus tepi); TECH_SPEC §9 ART-4 · RPC resmi: `set_status_item`, `tandai_habis`
  - **File:** `supabase/migrations/0027_status_item.sql`, `supabase/tes/status_item.sql`
  - **DoD:** status per item (menunggu → dimasak → siap) dan per pesanan; perubahan ganda dari dua perangkat hanya menghasilkan satu perubahan tercatat; uji paralel lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4); mitigasi: transisi divalidasi di database + kunci idempoten.
  - **Verifikasi:** uji SQL dua pemanggilan paralel → satu perubahan.

- [ ] T4-05 — Tombol menu habis dari dapur (mengunci kasir + katalog)
  - **Tujuan:** satu tombol di dapur langsung mencegah penjualan menu yang habis.
  - **Ref:** PRD M5 & M9
  - **File:** `aplikasi/src/layar/dapur/TombolHabis.tsx`, `supabase/migrations/0028_menu_habis_sumber.sql`
  - **DoD:** penanda habis dari dapur langsung berlaku di kasir & katalog publik (realtime); tercatat siapa & kapan; pencabutan butuh izin.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** penanda tidak tersinkron → mitigasi: satu sumber kebenaran di database + uji lintas layar.
  - **Verifikasi:** uji manual dua perangkat (dapur & kasir).

- [ ] T4-06 — Stok sederhana per bahan + riwayat
  - **Tujuan:** owner tahu persediaan tanpa buku catatan terpisah.
  - **Ref:** PRD M9; TECH_SPEC §4.2 (tabel resmi: `stok_bahan`, `stok_pergerakan`) · RPC resmi: `set_stok`, `opname_stok`
  - **File:** `aplikasi/src/layar/dapur/Stok.tsx`, `supabase/migrations/0029_stok.sql`
  - **DoD:** bahan bisa dicatat/diabaikan (opsional); penambahan/pengurangan; riwayat perubahan (siapa, kapan, berapa); uji lulus.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** stok tidak akurat → mitigasi: dinyatakan tegas "pencatatan sederhana, bukan resep otomatis (fase 2)" + opname berkala.
  - **Verifikasi:** uji manual + uji SQL riwayat.

- [ ] T4-07 — Opname berkala + selisih
  - **Tujuan:** selisih stok terlihat, bukan disembunyikan.
  - **Ref:** PRD M9 (kriteria selesai)
  - **File:** `aplikasi/src/layar/dapur/Opname.tsx`, `supabase/migrations/0030_opname.sql`
  - **DoD:** mengisi jumlah nyata; sistem menampilkan selisih; tercatat siapa & kapan; koreksi tidak menghapus riwayat.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** opname dijadikan alat menutupi kehilangan → mitigasi: riwayat hanya-tambah + laporan selisih ke owner.
  - **Verifikasi:** uji manual + uji SQL (riwayat tidak bisa diubah).

- [ ] T4-08 — Penanda pesanan menunggu terlalu lama
  - **Tujuan:** dapur tahu mana yang mendesak.
  - **Ref:** PRD M5; PRD §9 (risiko)
  - **File:** `aplikasi/src/layar/dapur/KartuPesanan.tsx` (warna waktu)
  - **DoD:** warna berubah setelah ambang (mis. 10 & 20 menit) yang bisa diatur; tidak memblokir layar bila jam perangkat salah (memakai waktu peladen).
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** warna berkedip mengganggu → mitigasi: hormati pengaturan "kurangi gerak".
  - **Verifikasi:** uji manual dengan pesanan tua (data seed).

- [ ] T4-09 — Uji anti-dobel dapur (dua perangkat)
  - **Tujuan:** membuktikan item tidak diproses dua kali.
  - **Ref:** TECH_SPEC §11; PRD M5 (kasus tepi)
  - **File:** `aplikasi/uji/e2e/dapur.spec.ts`, `supabase/tes/anti_dobel.sql`
  - **DoD:** uji otomatis dua perangkat menandai item sama → satu perubahan; uji lulus di CI.
  - **Kompleksitas:** sedang (2,5 jam)
  - **Risiko & mitigasi:** uji tidak realistis → mitigasi: memakai dua sesi paralel nyata (bukan tiruan).
  - **Verifikasi:** CI hijau + laporan ringkas.

- [ ] T4-10 — Keadaan kosong/memuat/gagal layar dapur & mode layar besar
  - **Tujuan:** layar dapur tetap berguna saat tidak ada pesanan/masalah.
  - **Ref:** AGENT_OPERATING_GUIDE §6
  - **File:** `aplikasi/src/layar/dapur/*.tsx`
  - **DoD:** "Belum ada pesanan" ramah; saat koneksi putus tampil status jelas (dapur tetap menampilkan pesanan terakhir + tanda "tertunda"); tata letak untuk TV/monitor besar.
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** dapur buta saat jaringan putus → mitigasi: simpan pesanan terakhir di perangkat + tanda jelas.
  - **Verifikasi:** uji manual: cabut jaringan → layar tetap informatif.

---

## Fase 5 — Pembayaran & pembatalan (M6)

- [ ] T5-01 — Layar pembayaran (metode + uang diterima)
  - **Tujuan:** kasir menyelesaikan pembayaran dalam hitungan detik dengan pilihan metode yang jelas.
  - **Ref:** PRD M6; TECH_SPEC §4 (metode_bayar)
  - **File:** `aplikasi/src/layar/kasir/Bayar.tsx`
  - **DoD:** metode aktif dari pengaturan (tunai, QRIS, transfer, e-wallet, kartu); tombol uang cepat (50rb/100rb/uang pas); kembalian besar & jelas; metode nonaktif tidak tampil.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** salah tekan nominal → mitigasi: konfirmasi nilai + tampilan kembalian besar + tombol batal mudah.
  - **Verifikasi:** uji manual 5 metode + uji unit format uang.

- [ ] T5-02 — RPC bayar_pesanan (tunai + kembalian) ⚠️
  - **Tujuan:** pembayaran tercatat sekali, benar, dan tidak bisa hilang walau jaringan goyah.
  - **Ref:** TECH_SPEC §5 & §9 ART-3 · RPC resmi: `batal_pesanan`, `batal_item`
  - **File:** `supabase/migrations/0031_bayar_pesanan.sql`, `supabase/tes/bayar.sql`
  - **DoD:** memvalidasi status pesanan, jumlah bayar ≥ total (kecuali dicatat sebagai kurang), menghitung kembalian lewat `hitung_total()`, menulis catatan audit, idempoten (kunci sama = satu pembayaran); uji lulus.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3) & State Machine (ART-4); uang tidak cocok → mitigasi: kembalian dihitung peladen, uji 8 kasus.
  - **Verifikasi:** uji SQL 8 kasus (uang pas, lebih, kurang, metode berbeda, dobel tekan).

- [ ] T5-03 — Pajak & service tampil terpisah di struk
  - **Tujuan:** pelanggan melihat rincian yang benar; owner bisa menjelaskan pajak.
  - **Ref:** PRD M6 (kriteria selesai); TECH_SPEC §9 ART-3
  - **File:** `aplikasi/src/komponen/Struk.tsx`, `supabase/tes/pajak_service.sql`
  - **DoD:** subtotal, diskon, PB1, service, pembulatan, total tampil terpisah; angka identik dengan `hitung_total()`; uji lulus untuk pajak/service 0%.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** pembulatan membuat selisih 1 rupiah → mitigasi: uji kasus .01 & kombinasi diskon penuh.
  - **Verifikasi:** uji unit + bandingkan struk contoh dengan kalkulator.

- [ ] T5-04 — Diskon: satu per transaksi (bawaan) + opsi tumpuk dengan batas ⚠️
  - **Tujuan:** diskon terkendali dan tidak bisa menumpuk tanpa izin.
  - **Ref:** PRD M6 & M2; TECH_SPEC §9 ART-3
  - **File:** `supabase/migrations/0032_diskon.sql`, `supabase/tes/diskon.sql`
  - **DoD:** bawaan menolak diskon kedua; bila pengaturan mengizinkan tumpuk, total diskon tidak boleh melebihi batas; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3); kombinasi diskon merugikan → mitigasi: batas total + uji kombinasi.
  - **Verifikasi:** uji SQL: 2 diskon tanpa izin tumpuk → ditolak; dengan tumpuk & melebihi batas → ditolak.

- [ ] T5-05 — Diskon manual butuh izin + PIN di atas batas ⚠️
  - **Tujuan:** kasir bisa memberi diskon kecil, tetapi tidak bisa memberi diskon besar tanpa atasan.
  - **Ref:** PRD M3 (batas maksimal %) & M6; TECH_SPEC §9 ART-2
  - **File:** `aplikasi/src/layar/kasir/DiskonManual.tsx`, `supabase/migrations/0033_diskon_izin.sql`
  - **DoD:** batas per pegawai dari pengaturan izin; di atas batas → wajib PIN atasan; tercatat (pelaku, nilai, alasan).
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); mitigasi: gerbang `boleh()` + PIN + audit.
  - **Verifikasi:** uji manual 3 kasus (di bawah batas, di atas batas tanpa PIN, dengan PIN).

- [ ] T5-06 — Void sebelum dapur mulai (alasan wajib) ⚠️
  - **Tujuan:** salah input cepat dibereskan, selalu dengan jejak.
  - **Ref:** PRD M6 (aturan bertingkat); TECH_SPEC §9 ART-4
  - **File:** `supabase/migrations/0034_void_pra.sql`, `supabase/tes/void_pra.sql`
  - **DoD:** hanya sebelum dimasak; alasan wajib dari daftar/ketik; masuk laporan; tidak ada penghapusan data; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4); mitigasi: aturan di database + laporan harian.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T5-07 — Void setelah dapur mulai: PIN atasan + bahan terbuang ⚠️
  - **Tujuan:** kerugian terlihat sebagai angka, bukan hilang diam-diam.
  - **Ref:** PRD M6 (dikunci pemilik); TECH_SPEC §9 ART-4
  - **File:** `supabase/migrations/0035_void_pasca.sql`, `aplikasi/src/layar/kasir/VoidPasca.tsx`
  - **DoD:** wajib PIN atasan/owner + alasan; nilai bahan terbuang dihitung dari harga saat itu; muncul di laporan harian sebagai kerugian; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4) & Kalkulasi (ART-3); mitigasi: PIN + audit + laporan.
  - **Verifikasi:** uji SQL + uji manual + cek kemunculan di laporan (T7-12).

- [ ] T5-08 — Nomor HP pelanggan opsional (untuk poin/voucher) ⚠️
  - **Tujuan:** kasir bisa menawarkan voucher tanpa memaksa pelanggan memberi data.
  - **Ref:** PRD M6 & M10; TECH_SPEC §9 ART-10
  - **File:** `aplikasi/src/layar/kasir/DataPelanggan.tsx`
  - **DoD:** bersifat opsional dengan penjelasan singkat; persetujuan dicatat; bisa dilewati; tidak boleh menghambat pembayaran.
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Privasi (ART-10); mitigasi: data minimal + persetujuan + bisa dilewati.
  - **Verifikasi:** uji manual alur cepat tanpa data pelanggan.

- [ ] T5-09 — Struk digital (cadangan wajib saat printer bermasalah) ⚠️
  - **Tujuan:** pembayaran tetap bisa diserahkan ke pelanggan walau printer mati.
  - **Ref:** TECH_SPEC §13 K3 & §9 ART-7; PRD M6 (kasus tepi)
  - **File:** `aplikasi/src/komponen/StrukDigital.tsx`
  - **DoD:** struk tampil di layar dalam format struk; bisa dibagikan (bagikan berkas/gambar) & disimpan PDF; isi identik dengan struk cetak.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Cetak (ART-7); mitigasi: satu tampilan struk untuk semua jalur (cetak & digital).
  - **Verifikasi:** uji manual di Android & desktop.

- [ ] T5-10 — Cetak ulang struk + pencarian transaksi
  - **Tujuan:** struk hilang bisa dicetak ulang tanpa membuat transaksi baru.
  - **Ref:** PRD M6 (kasus tepi)
  - **File:** `aplikasi/src/layar/kasir/DaftarTransaksi.tsx`
  - **DoD:** cari transaksi (nomor/waktu/nominal), cetak ulang (bertanda "cetak ulang"), tidak mengubah data.
  - **Kompleksitas:** sedang (2,5 jam)
  - **Risiko & mitigasi:** penyalahgunaan cetak ulang → mitigasi: tanda "SALINAN" + catatan audit.
  - **Verifikasi:** uji manual + uji SQL (tidak ada perubahan data).

- [ ] T5-11 — Pembayaran sebagian & tagihan ditinggal
  - **Tujuan:** kenyataan lapangan tercatat rapi sesuai keputusan MVP.
  - **Ref:** PRD M6 (kasus tepi)
  - **File:** `supabase/tes/pembayaran_sebagian.sql`, `aplikasi/src/layar/kasir/DaftarTagihan.tsx`
  - **DoD:** di MVP pembayaran sebagian dicatat sebagai dua transaksi terpisah (dibuktikan uji); tagihan ditinggal tetap muncul dengan penanda umur.
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** kesalahpahaman "split bill" → mitigasi: teks di layar menjelaskan; split resmi = fase 2.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T5-12 — Laporan pembatalan (siapa, nilai, alasan)
  - **Tujuan:** owner bisa memeriksa setiap pembatalan, bukan hanya jumlahnya.
  - **Ref:** PRD M8 (kriteria laporan) & M6
  - **File:** `supabase/migrations/0036_laporan_pembatalan.sql`, `aplikasi/src/layar/laporan/DaftarPembatalan.tsx`
  - **DoD:** daftar pembatalan per hari/cabang dengan pelaku, nilai, alasan, jenis (pra/pasca dapur); angka cocok dengan data transaksi (uji golden).
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** laporan tidak cocok dengan data → mitigasi: uji golden membandingkan hasil laporan dengan data mentah.
  - **Verifikasi:** uji SQL golden + uji manual.

---

## Fase 6 — Cetak termal ESC/POS (⚠️ ART-7) ❓ T-002

- [ ] T6-01 — Pembungkus ESC/POS (perintah dasar) + uji unit
  - **Tujuan:** satu lapisan kode untuk menyusun struk/tiket agar mudah diuji tanpa printer.
  - **Ref:** TECH_SPEC §1 (cetak) & §9 ART-7
  - **File:** `aplikasi/src/lib/printer/expos.ts`, `aplikasi/src/lib/printer/expos.test.ts`
  - **DoD:** fungsi susun struk/tiket (baris, tebal, rata, potong kertas, buka laci bila didukung) dengan uji unit byte-level; teks Indonesia (UTF-8/CP437) benar.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Cetak (ART-7); huruf Indonesia rusak → mitigasi: uji teks beraksen & panjang baris 32/48 kolom.
  - **Verifikasi:** `npm test` untuk 10 kasus struk contoh.

- [ ] T6-02 — Sambungan Web Bluetooth (Android/Windows)
  - **Tujuan:** printer termal Bluetooth bisa dipakai dari perangkat kasir.
  - **Ref:** TECH_SPEC §1 & §13 K3
  - **File:** `aplikasi/src/lib/printer/bluetooth.ts`, `aplikasi/src/layar/pengaturan/PasangPrinter.tsx`
  - **DoD:** pemasangan printer (pilih perangkat, simpan), uji cetak halaman contoh, pesan jelas bila tidak didukung perangkat (mis. iPhone).
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Cetak (ART-7); browser tidak mendukung → mitigasi: deteksi dukungan + arahkan ke cadangan digital.
  - **Verifikasi:** uji manual cetak 1 halaman di perangkat Android.

- [ ] T6-03 — Sambungan WebUSB (komputer)
  - **Tujuan:** komputer kasir bisa memakai printer kabel tanpa aplikasi tambahan.
  - **Ref:** TECH_SPEC §1
  - **File:** `aplikasi/src/lib/printer/usb.ts`
  - **DoD:** pemasangan printer USB, uji cetak, penanganan izin perangkat; pesan jelas bila gagal.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** konflik driver → mitigasi: panduan pemasangan singkat + jalur cadangan digital.
  - **Verifikasi:** uji manual cetak via USB (bila perangkat tersedia) atau uji simulasi + cadangan digital.

- [ ] T6-04 — Cetak struk (header/footer dari pengaturan)
  - **Tujuan:** struk memuat identitas resto yang benar tanpa perlu ubah kode.
  - **Ref:** PRD M6 (isi struk) & M2 (header/footer bisa diatur)
  - **File:** `aplikasi/src/lib/printer/struk.ts`
  - **DoD:** nama resto, alamat, tanggal/jam, nomor transaksi, item, subtotal, pajak, service, diskon, total, metode, kasir, ucapan; header/footer dari pengaturan.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** perubahan nama resto mengubah struk lama → mitigasi: struk lama hanya disimpan sebagai data (tidak dicetak ulang dengan header baru) + catatan di DECISIONS_LOG.
  - **Verifikasi:** uji unit struktur + uji manual cetak.

- [ ] T6-05 — Cetak tiket dapur
  - **Tujuan:** dapur menerima tiket fisik walau layar penuh.
  - **Ref:** PRD M4 & M5
  - **File:** `aplikasi/src/lib/printer/tiket.ts`
  - **DoD:** tiket memuat nomor pesanan, meja/jenis, item + jumlah, catatan khusus (mencolok), jam kirim; porsi makanan & minuman bisa dipisah.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** tiket tercetak dua kali → mitigasi: status cetak per pesanan + tanda "SALINAN".
  - **Verifikasi:** uji manual + uji unit.

- [ ] T6-06 — Antrean cetak, cetak ulang, deteksi gagal ⚠️
  - **Tujuan:** printer bermasalah tidak boleh membuat transaksi hilang atau misterius.
  - **Ref:** TECH_SPEC §9 ART-7; PRD M4 (kasus tepi)
  - **File:** `aplikasi/src/lib/printer/antrean.ts`, `aplikasi/src/komponen/StatusPrinter.tsx`
  - **DoD:** bila gagal → pesan jelas + otomatis tawarkan cadangan digital; antrean cetak tidak menumpuk ganda; status printer terlihat di layar kasir.
  - **Kompleksitas:** besar (3,5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Cetak (ART-7); mitigasi: cadangan digital wajib + indikator status selalu terlihat.
  - **Verifikasi:** uji manual: matikan printer di tengah cetak → pesan + cadangan muncul.

- [ ] T6-07 — Printer per perangkat & per cabang
  - **Tujuan:** setiap cabang/perangkat bisa punya printer sendiri tanpa saling mengganggu.
  - **Ref:** PRD M11 (printer per cabang); TECH_SPEC §4 (printer)
  - **File:** `supabase/migrations/0037_printer.sql`, `aplikasi/src/layar/pengaturan/PengaturanPrinter.tsx`
  - **DoD:** pengaturan printer tersimpan per perangkat + catatan cabang; pencetakan memakai printer yang dipasangkan di perangkat itu; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** salah printer tercetak di cabang lain → mitigasi: pemasangan wajib per perangkat + tampilkan nama printer aktif.
  - **Verifikasi:** uji manual 2 perangkat pada 1 cabang.

- [ ] T6-08 — ❓ T-002 Uji cetak nyata di Kedai Oasis
  - **Tujuan:** membuktikan cetak bekerja pada printer sungguhan sebelum gelombang berikutnya (risiko #1 PRD).
  - **Ref:** TECH_SPEC §11 (uji nyata) & §12 (data lapangan); PRD §9 risiko #1
  - **File:** `docs/uji/UJI_CETAK_KEDAI_OASIS.md`
  - **DoD:** hasil uji dicatat (merek, tipe, cara sambung, hasil struk & tiket, masalah + solusi); bila merek belum diketahui → **STOP & tanya pemilik** (butir T-002), jangan menebak.
  - **Kompleksitas:** sedang (3 jam + waktu koordinasi)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Cetak (ART-7); printer tidak kompatibel → mitigasi: jalur cadangan digital sudah wajib + pilihan printer yang didukung dicatat.
  - **Verifikasi:** lembar hasil uji bertanda tangan pemilik/pengelola + foto struk.

---

## Fase 7 — Kas & shift + laporan harian (M7, M8)

- [ ] T7-01 — Buka kas (modal awal) ⚠️
  - **Tujuan:** setiap shift dimulai dengan modal yang tercatat, sehingga selisih bisa dihitung jujur.
  - **Ref:** PRD M7; TECH_SPEC §9 ART-6 · RPC resmi: `tutup_shift`, `kas_pergerakan`
  - **File:** `supabase/migrations/0038_buka_shift.sql`, `aplikasi/src/layar/kasir/BukaKas.tsx`
  - **DoD:** modal awal wajib; satu shift terbuka per kasir per cabang; tercatat siapa & kapan; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); mitigasi: aturan satu shift terbuka + audit.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T7-02 — Tutup kas (seharusnya vs fisik) + alasan selisih ⚠️
  - **Tujuan:** kasir tidak pernah dituduh selisih, owner melihat kenyataan.
  - **Ref:** PRD M7 (kriteria selesai)
  - **File:** `supabase/migrations/0039_tutup_shift.sql`, `aplikasi/src/layar/kasir/TutupKas.tsx`
  - **DoD:** sistem menghitung uang seharusnya (modal + tunai masuk − tunai keluar); kasir memasukkan hasil hitung fisik; bila selisih → alasan wajib; nilai & alasan muncul di laporan.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); mitigasi: rumus di peladen + uji golden.
  - **Verifikasi:** uji SQL 5 kasus (pas, lebih, kurang, tanpa alasan, dua kasir satu shift).

- [ ] T7-03 — Kas pergerakan (masuk/keluar tunai, setoran) ⚠️
  - **Tujuan:** uang yang keluar-masuk di luar penjualan tetap tercatat.
  - **Ref:** PRD M7; TECH_SPEC §4 (kas_pergerakan)
  - **File:** `supabase/migrations/0040_kas_pergerakan.sql`, `aplikasi/src/layar/kasir/KasKeluarMasuk.tsx`
  - **DoD:** pencatatan keluar (belanja mendadak, ambil setoran) & masuk (tambahan modal) dengan alasan & izin; masuk hitungan tutup kas.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); mitigasi: izin + audit.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T7-04 — Transaksi hanya dalam shift terbuka ⚠️
  - **Tujuan:** tidak ada penjualan "di luar kas" yang tidak bisa diaudit.
  - **Ref:** PRD M7 (kriteria selesai)
  - **File:** `supabase/migrations/0041_wajib_shift.sql`, `supabase/tes/wajib_shift.sql`
  - **DoD:** memesan/membayar di luar shift terbuka ditolak dengan pesan jelas; uji lulus.
  - **Kompleksitas:** sedang (2,5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); kasir lupa buka kas saat sibuk → mitigasi: pengingat + tombol buka kas cepat.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T7-05 — Pengingat shift belum ditutup
  - **Tujuan:** shift menggantung tidak menumpuk dan tidak merusak laporan.
  - **Ref:** PRD M7 (kasus tepi)
  - **File:** `aplikasi/src/komponen/PengingatShift.tsx`, `supabase/migrations/0042_pengingat_shift.sql`
  - **DoD:** pengingat saat jam tutup, banner di layar kasir, catatan di laporan bila shift melewati tengah malam.
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** pengingat diabaikan → mitigasi: tercatat di laporan harian owner.
  - **Verifikasi:** uji manual (ubah jam sistem uji) + uji SQL.

- [ ] T7-06 — Koreksi modal awal dengan izin atasan ⚠️
  - **Tujuan:** salah isi modal bisa dibetulkan tanpa menghapus data.
  - **Ref:** PRD M7 (kasus tepi)
  - **File:** `supabase/migrations/0043_koreksi_modal.sql`
  - **DoD:** koreksi tercatat sebagai baris baru (bukan menimpa), wajib PIN atasan + alasan, muncul di laporan.
  - **Kompleksitas:** sedang (2,5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); mitigasi: hanya-tambah + PIN.
  - **Verifikasi:** uji SQL (riwayat koreksi tetap ada).

- [ ] T7-07 — Laporan A: kas harian per shift
  - **Tujuan:** owner membuka satu layar dan langsung tahu kondisi hari ini.
  - **Ref:** PRD M8 (kriteria selesai — laporan A dikunci untuk G1) · RPC resmi: `laporan_shift`, `laporan_harian`
  - **File:** `supabase/migrations/0044_laporan_kas.sql`, `aplikasi/src/layar/laporan/LaporanKas.tsx`
  - **DoD:** memuat omzet (makanan/minuman/lainnya), jumlah transaksi, rincian metode bayar, diskon & voucher, pembatalan, kas awal/masuk/seharusnya/fisik/selisih, nama kasir & jam shift; filter cabang sesuai peran; angka dari peladen.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** angka tidak cocok → mitigasi: uji golden (T7-12) + satu sumber hitung.
  - **Verifikasi:** uji SQL golden + uji manual bandingkan dengan data transaksi.

- [ ] T7-08 — Laporan penjualan dasar (kategori, metode)
  - **Tujuan:** owner tahu dari mana uang datang.
  - **Ref:** PRD M8
  - **File:** `supabase/migrations/0045_laporan_penjualan.sql`, `aplikasi/src/layar/laporan/LaporanPenjualan.tsx`
  - **DoD:** omzet per kategori, tren harian sederhana, rincian metode bayar; bisa dilihat per cabang & gabungan (owner).
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** laporan berat → mitigasi: agregasi di peladen + batas rentang tanggal.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T7-09 — Laporan menu terlaris + diskon/voucher terpakai
  - **Tujuan:** owner tahu menu andalan & biaya promosi.
  - **Ref:** PRD M8 & M10
  - **File:** `supabase/migrations/0046_laporan_menu.sql`, `aplikasi/src/layar/laporan/LaporanMenu.tsx`
  - **DoD:** peringkat menu (jumlah & nilai), daftar diskon manual, daftar voucher terpakai (kampanye, nilai, kasir pemakai).
  - **Kompleksitas:** sedang (3,5 jam)
  - **Risiko & mitigasi:** data menu berubah → mitigasi: memakai `nama_saat_itu` agar laporan lama tidak berubah.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T7-10 — Tampilan laporan siap cetak/simpan + filter cabang
  - **Tujuan:** owner bisa menyimpan laporan harian untuk pembukuan.
  - **Ref:** PRD M8 (kasus tepi: dicetak disimpan = fase 2 → di G1 cukup rapi & bisa disimpan PDF)
  - **File:** `aplikasi/src/layar/laporan/FormatLaporan.tsx`
  - **DoD:** tata letak rapi untuk dicetak/disimpan PDF; judul, tanggal, cabang, tanda tangan pemilik; filter cabang sesuai peran.
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** kebocoran data lintas cabang → mitigasi: filter di peladen (T2-07).
  - **Verifikasi:** uji manual simpan PDF.

- [ ] T7-11 — Transaksi lewat tengah malam ⚠️
  - **Tujuan:** laporan tidak terpecah salah tanggal.
  - **Ref:** PRD M8 (kasus tepi); TECH_SPEC §9 ART-9
  - **File:** `supabase/tes/tengah_malam.sql`
  - **DoD:** transaksi masuk tanggal transaksi (bukan tanggal tutup kas); nomor pesanan mengikuti hari operasional; uji lulus dengan jam simulasi.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Zona waktu (ART-9); mitigasi: semua perhitungan waktu memakai zona penyewa + uji jam simulasi.
  - **Verifikasi:** uji SQL dengan data jam 23.50 & 00.10.

- [ ] T7-12 — Uji golden: laporan = data mentah
  - **Tujuan:** membuktikan laporan tidak berbohong.
  - **Ref:** TECH_SPEC §11
  - **File:** `supabase/tes/golden_laporan.sql`
  - **DoD:** untuk 1 hari data contoh, semua angka laporan (omzet, metode, diskon, pembatalan, kas) sama dengan hasil hitung langsung dari tabel transaksi; uji dijalankan di CI.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** uji tidak menangkap kasus tepi → mitigasi: data contoh memuat void, diskon, voucher, pembayaran campuran.
  - **Verifikasi:** CI hijau + selisih = 0 pada laporan contoh.

---

## Fase 8 — Katalog pelanggan & voucher undang-teman (M10) ⚠️ ART-5, ART-10  <!-- T-007 sudah ditutup 2026-09-16: Resend tanpa domain khusus -->

- [ ] T8-01 — RPC katalog_publik (tanpa data sensitif) ⚠️
  - **Tujuan:** pelanggan bisa melihat menu tanpa pernah menyentuh data internal resto.
  - **Ref:** TECH_SPEC §5 & §9 ART-10; PRD M10
  - **File:** `supabase/migrations/0047_katalog_publik.sql`, `supabase/tes/katalog_publik.sql`
  - **DoD:** hanya mengembalikan menu, harga, foto, jam buka, kontak publik; tidak ada data pegawai/pelanggan/keuangan; item habis dikembalikan sebagai tidak tersedia; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Privasi (ART-10) & RLS (ART-1); mitigasi: fungsi memakai daftar kolom tegas (bukan `select *`) + uji "tidak ada kolom sensitif".
  - **Verifikasi:** uji SQL: hasil tidak memuat kolom sensitif (diperiksa otomatis).

- [ ] T8-02 — Halaman katalog publik per resto (merek sendiri)
  - **Tujuan:** setiap resto punya halaman publik dengan mereknya sendiri.
  - **Ref:** PRD M10 & M2; TECH_SPEC §3 (`/pelanggan-publik`)
  - **File:** `aplikasi/src/layar/pelanggan-publik/Katalog.tsx`
  - **DoD:** nama, logo, warna/tema, banner, tagline, jam buka, kontak/lokasi muncul dari pengaturan; alamat halaman mudah dibagikan (tautan + QR).
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** tampilan berbeda dari prototipe → mitigasi: memakai token desain v3 yang sama + pemeriksa kontras.
  - **Verifikasi:** uji manual di HP + pemeriksa kontras.

- [ ] T8-03 — Daftar menu + foto + harga + penanda habis
  - **Tujuan:** pelanggan tahu apa yang tersedia, tanpa menanyakan ke pegawai.
  - **Ref:** PRD M10 (kriteria selesai)
  - **File:** `aplikasi/src/layar/pelanggan-publik/Menu.tsx`
  - **DoD:** kategori, item, varian, tambahan, harga; foto teroptimasi (ukuran kecil); item habis tampil tertutup/tidak tampil; muat < 3 detik di jaringan seluler.
  - **Kompleksitas:** sedang (3,5 jam)
  - **Risiko & mitigasi:** foto besar membebani kuota gratis → mitigasi: unggah otomatis diperkecil + format modern.
  - **Verifikasi:** uji manual pada HP + ukur ukuran halaman.

- [ ] T8-04 — Pencarian & penyaringan menu
  - **Tujuan:** pelanggan menemukan menu cepat.
  - **Ref:** PRD M10
  - **File:** `aplikasi/src/layar/pelanggan-publik/Menu.tsx`
  - **DoD:** pencarian nama, filter kategori, sorotan item unggulan; hasil instan tanpa memuat ulang.
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** pencarian lambat di perangkat lama → mitigasi: pencarian di klien atas data yang sudah dimuat (tanpa data sensitif).
  - **Verifikasi:** uji manual 5 pencarian.

- [ ] T8-05 — Tautan & QR katalog per resto
  - **Tujuan:** pelanggan bisa membuka menu dari meja atau dari media sosial.
  - **Ref:** PRD M10 & M2 (nomor & area meja)
  - **File:** `aplikasi/src/layar/pengaturan/TautanKatalog.tsx`
  - **DoD:** tautan publik + QR yang bisa diunduh/dicetak; QR per meja opsional (menyertakan nomor meja).
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** QR salah cetak → mitigasi: pratinjau sebelum cetak + uji pindai 2 perangkat.
  - **Verifikasi:** uji pindai QR dengan kamera HP.

- [ ] T8-06 — Halaman kampanye + pendaftaran pelanggan
  - **Tujuan:** calon pelanggan bisa ikut kampanye undang-teman tanpa bantuan kasir.
  - **Ref:** PRD M10 (alur voucher)
  - **File:** `aplikasi/src/layar/voucher/Kampanye.tsx`, `aplikasi/src/layar/voucher/Daftar.tsx`
  - **DoD:** alur: tautan kampanye → isi nama (wajib), email/HP (sekali) → verifikasi → kode voucher muncul; bahasa jelas; tampil rapi di HP.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** pendaftaran gagal karena verifikasi → mitigasi: jalur bantuan "didaftarkan kasir" (T8-07) + pesan jelas.
  - **Verifikasi:** uji manual dua jalur (Google & email) di HP.

- [ ] T8-07 — Verifikasi email + anti email sekali-pakai + normalisasi Gmail ⚠️ ❓ T-011
  - **Tujuan:** satu orang tidak bisa mengklaim berkali-kali dengan email berbeda-beda.
  - **Ref:** PRD M10 (pengaman anti-kecurangan 1–8); TECH_SPEC §9 ART-5/ART-10
  - **File:** `supabase/functions/verifikasi_pelanggan/index.ts`, `aplikasi/src/lib/emailNormalisasi.ts`, `supabase/tes/anti_email_palsu.sql`
  - **Catatan:** ❓ T-011 (kebijakan privasi + kotak persetujuan) wajib ada SEBELUM tugas ini mengumpulkan data pelanggan pertama
  - **DoD:** email wajib terverifikasi (kecuali didaftarkan kasir dengan izin pelanggan & tercatat); email sekali-pakai ditolak; titik & tanda `+` pada Gmail dinormalisasi; satu identitas = satu voucher per kampanye; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Voucher (ART-5) & Privasi (ART-10); mitigasi: daftar domain sekali-pakai + normalisasi + uji kasus.
  - **Verifikasi:** uji fungsi dengan 6 kasus (email asli, sekali-pakai, gmail bertitik, gmail +tag, email kosong, email salah).

- [ ] T8-08 — Terbitkan kode voucher acak + barcode
  - **Tujuan:** kode tidak bisa ditebak atau dibuat sendiri oleh orang luar.
  - **Ref:** PRD M10 (kode acak tidak berurutan)
  - **File:** `supabase/migrations/0048_voucher_terbit.sql`, `aplikasi/src/layar/voucher/KartuVoucher.tsx`
  - **DoD:** kode acak (bukan berurutan), barcode + kode teks, masa berlaku terlihat; satu voucher per identitas per kampanye.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** kode terguess → mitigasi: panjang memadai + pembatasan percobaan (T8-12).
  - **Verifikasi:** uji SQL unik + uji manual tampilan kartu voucher.

- [ ] T8-09 — Layar kasir: Cek (baca saja) & Pakai (atomik + PIN) ⚠️
  - **Tujuan:** kasir bisa memeriksa dengan tenang, lalu memakai sekali saja dengan jejak.
  - **Ref:** PRD M10 (aturan voucher) & M3 (izin pakai voucher); TECH_SPEC §9 ART-5
  - **File:** `aplikasi/src/layar/kasir/Voucher.tsx`
  - **DoD:** tombol Cek tidak mengubah apa pun (dibuktikan uji); Pakai wajib PIN kasir/atasan berizin; hasil jelas (berhasil + rincian potongan / gagal + sebab spesifik); potongan dihitung dari aturan kampanye.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Voucher (ART-5); mitigasi: RPC atomik T1-20 + PIN + uji "cek tidak mengubah".
  - **Verifikasi:** uji manual 6 kasus (voucher sah, sudah dipakai, kedaluwarsa, minimum belum cukup, salah cabang, kuota habis).

- [ ] T8-10 — Scan kamera + ketik manual
  - **Tujuan:** kasir tidak perlu mengetik panjang, tetapi tetap bisa saat kamera bermasalah.
  - **Ref:** PRD M10 (scan kamera atau ketik manual)
  - **File:** `aplikasi/src/layar/kasir/ScanVoucher.tsx`
  - **DoD:** memindai barcode dari kamera; masukan manual sebagai cadangan; pesan kamera tidak tersedia jelas.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** kamera perangkat bermasalah → mitigasi: jalur manual selalu tersedia & sama-sama tercatat.
  - **Verifikasi:** uji manual pindai 3 voucher + 1 masukan manual.

- [ ] T8-11 — Pengaturan kampanye voucher oleh admin
  - **Tujuan:** admin bisa mengatur kampanye sendiri tanpa koding.
  - **Ref:** PRD M10 (aturan diatur admin) & M2
  - **File:** `aplikasi/src/layar/pengaturan/Kampanye.tsx`, `supabase/migrations/0049_kampanye_aturan.sql`
  - **DoD:** persen/nominal, minimum belanja, batas potongan, masa berlaku, kuota, anggaran, cabang berlaku; pratinjau aturan dalam bahasa manusia; validasi mencegah aturan mustahil.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** aturan salah → mitigasi: validasi + pratinjau ("pelanggan belanja 50rb → potongan maksimal 15rb").
  - **Verifikasi:** uji manual membuat 3 kampanye berbeda + uji SQL validasi.

- [ ] T8-12 — Pengaman anti-kecurangan (10 lapis) + batas klaim + log percobaan ⚠️
  - **Tujuan:** kampanye tidak bisa diborong satu orang atau satu perangkat.
  - **Ref:** PRD M10 (pengaman 1–10); TECH_SPEC §9 ART-5
  - **File:** `supabase/migrations/0050_pengaman_voucher.sql`, `supabase/tes/pengaman_voucher.sql`
  - **DoD:** satu voucher per identitas per kampanye; batas per outlet per hari; anggaran kampanye tidak bisa dilampaui; semua cek/scan tercatat; batas percobaan per perangkat; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Voucher (ART-5); mitigasi: batas berlapis di database + laporan anomali.
  - **Verifikasi:** uji SQL: klaim ke-2 identitas sama → ditolak; lampaui anggaran → ditolak.

- [ ] T8-13 — Laporan klaim voucher + dasar deteksi anomali
  - **Tujuan:** owner melihat apakah kampanye berjalan wajar atau ada pola aneh.
  - **Ref:** PRD M10 (laporan anomali fase 2 → dasar di G1)
  - **File:** `supabase/migrations/0051_laporan_voucher.sql`, `aplikasi/src/layar/laporan/LaporanVoucher.tsx`
  - **DoD:** jumlah klaim & pemakaian per kampanye/cabang/hari, nilai potongan, daftar identitas klaim berulang, peringatan sederhana (mis. >3 klaim dari satu identitas).
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** salah tuduh pelanggan → mitigasi: istilah "perlu diperiksa", bukan "curang".
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T8-14 — Uji lengkap aturan voucher (6 kasus wajib)
  - **Tujuan:** aturan voucher terbukti benar sebelum dipakai di kedai.
  - **Ref:** PRD M10 (kasus tepi); TECH_SPEC §11
  - **File:** `supabase/tes/voucher_lengkap.sql`, `aplikasi/uji/e2e/voucher.spec.ts`
  - **DoD:** uji: sekali pakai, kedaluwarsa, minimum belum terpenuhi, salah cabang, kuota habis, cek tidak mengubah status; semua lulus di CI.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** uji tidak menutup seluruh kasus → mitigasi: daftar kasus diambil langsung dari PRD M10.
  - **Verifikasi:** CI hijau + ringkasan hasil dicatat.

---

## Fase 9 — Pengaturan tanpa koding & multi-cabang (M1, M2, M3, M11)

- [ ] T9-01 — Pengaturan identitas & tampilan resto
  - **Tujuan:** owner mengubah nama, logo, banner, tagline sendiri tanpa menghubungi siapa pun.
  - **Ref:** PRD M2 (identitas & tampilan) · RPC resmi: `simpan_pengaturan`, `simpan_menu`, `simpan_meja`, `simpan_metode_bayar`
  - **File:** `aplikasi/src/layar/pengaturan/Identitas.tsx`, `supabase/migrations/0052_unggah_gambar.sql`
  - **DoD:** unggah logo & banner (dengan validasi ukuran/jenis), tagline, nama resto; perubahan langsung terlihat di katalog & struk baru; struk/laporan lama tidak berubah.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** gambar besar → mitigasi: perkecil otomatis + batas ukuran + penyimpanan gratis 1 GB dipantau (T11-06).
  - **Verifikasi:** uji manual unggah 3 gambar (kecil, besar, jenis salah).

- [ ] T9-02 — Tema & warna merek (10 tema siap pakai)
  - **Tujuan:** setiap resto bisa tampil dengan warna sendiri tanpa desain ulang.
  - **Ref:** PRD M2; `prototipe/README.md` (daftar tema)
  - **File:** `aplikasi/src/layar/pengaturan/Tampilan.tsx`
  - **DoD:** pilih tema (10 pilihan) + warna merek; pratinjau langsung; pengaturan tersimpan per penyewa; kontras tetap lulus untuk semua kombinasi.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** warna merek merusak keterbacaan → mitigasi: uji kontras otomatis menolak kombinasi gagal.
  - **Verifikasi:** uji kontras untuk 10 tema × 3 warna merek.

- [ ] T9-03 — Pengaturan operasional (pajak, service, pembulatan, cara pesan, struk)  <!-- T-005 sudah ditutup 2026-09-16: nilai awal PB1 10% · service 5% · 1 shift -->
  - **Tujuan:** aturan uang & layanan sesuai kenyataan kedai, bisa diubah sendiri.
  - **Ref:** PRD M2 & M6; TECH_SPEC §9 ART-3
  - **File:** `aplikasi/src/layar/pengaturan/Operasional.tsx`, `supabase/migrations/0053_pengaturan_operasional.sql`
  - **DoD:** jam buka, PB1 %, service %, aturan pembulatan, cara pesan (dilayani/ambil/dua-duanya), header & footer struk; nilai wajib divalidasi (0–100%); perubahan tercatat di audit dan tidak mengubah transaksi lama.
  - **Kompleksitas:** sedang (3,5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3); perubahan pajak mengubah laporan lama → mitigasi: nilai pajak disalin ke transaksi saat dibuat.
  - **Verifikasi:** uji SQL: ubah PB1 → transaksi lama tetap memakai nilai lama.

- [ ] T9-04 — Meja & area + QR per meja
  - **Tujuan:** tata letak kedai bisa diatur sendiri dan QR meja bisa dipakai.
  - **Ref:** PRD M2 & M4
  - **File:** `aplikasi/src/layar/pengaturan/Meja.tsx`
  - **DoD:** tambah/ubah/nonaktifkan meja & area; nomor meja unik per cabang; QR per meja bisa diunduh.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** meja nonaktif masih bisa dipesan → mitigasi: validasi di server saat membuat pesanan.
  - **Verifikasi:** uji manual + uji SQL.

- [ ] T9-05 — Pengelolaan menu lengkap (kategori, varian, tambahan, foto, urutan)
  - **Tujuan:** menu bisa diperbarui owner sendiri tanpa koding.
  - **Ref:** PRD M2 (menu)
  - **File:** `aplikasi/src/layar/pengaturan/Menu.tsx`, `supabase/migrations/0054_urut_menu.sql`
  - **DoD:** CRUD kategori/menu/varian/tambahan; foto (perkecil otomatis); harga; urutan tampil; item unggulan; penanda habis manual; pratinjau seperti katalog.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** perubahan harga mengubah riwayat → mitigasi: `harga_saat_itu` (T1-09) + peringatan di layar.
  - **Verifikasi:** uji manual menambah 5 menu + uji SQL riwayat harga.

- [ ] T9-06 — Harga & ketersediaan menu berbeda per cabang
  - **Tujuan:** cabang boleh punya harga/menu berbeda tanpa sistem terbelah.
  - **Ref:** PRD M11 (harga & menu boleh berbeda per cabang)
  - **File:** `aplikasi/src/layar/pengaturan/MenuCabang.tsx`
  - **DoD:** atur harga khusus cabang & sembunyikan item per cabang; bila tidak diatur → memakai harga pusat; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** harga salah cabang → mitigasi: tampilkan tabel perbandingan antar cabang + uji SQL.
  - **Verifikasi:** uji manual + uji SQL (2 cabang, 1 menu, harga berbeda).

- [ ] T9-07 — Metode pembayaran aktif + aturan tip
  - **Tujuan:** kasir hanya melihat metode yang benar-benar dipakai resto.
  - **Ref:** PRD M2 (pembayaran)
  - **File:** `aplikasi/src/layar/pengaturan/MetodeBayar.tsx`
  - **DoD:** aktif/nonaktifkan metode; urutan tampil; aturan tip (boleh/tidak, cara hitung); uji manual lulus.
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** tip mempengaruhi setoran kas → mitigasi: tip dicatat terpisah di laporan.
  - **Verifikasi:** uji manual + uji SQL struk dengan tip.

- [ ] T9-08 — Kelola pegawai: peran, izin, PIN ⚠️
  - **Tujuan:** owner memberi kepercayaan bertingkat tanpa kehilangan kendali.
  - **Ref:** PRD M3; TECH_SPEC §9 ART-2 · RPC resmi: `set_izin`, `simpan_pin`, `verifikasi_pin`, `ganti_pin`
  - **File:** `aplikasi/src/layar/pengaturan/Izin.tsx`, `supabase/migrations/0055_kelola_izin.sql`
  - **DoD:** centang izin per pegawai (termasuk batas diskon %/nominal), reset PIN, nonaktifkan akun, riwayat tetap; perubahan izin tercatat di audit.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); izin salah memberi akses uang → mitigasi: daftar izin jelas + audit perubahan + uji peran (T2-12).
  - **Verifikasi:** uji manual mengubah izin → perilaku berubah di layar kasir; uji SQL audit.

- [ ] T9-09 — Kelola cabang (tambah, printer, nonaktifkan) ⚠️
  - **Tujuan:** membuka cabang baru tidak butuh bantuan teknis.
  - **Ref:** PRD M11; TECH_SPEC §9 ART-1 · RPC resmi: `set_akses_cabang`
  - **File:** `aplikasi/src/layar/pengaturan/Cabang.tsx`, `supabase/migrations/0056_kelola_cabang.sql`
  - **DoD:** tambah cabang (nama, alamat, printer), nonaktifkan sementara (data lama tetap); pegawai merangkap 2 cabang bisa diatur; uji isolasi lintas cabang lulus.
  - **Kompleksitas:** sedang (3,5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: RLS (ART-1); mitigasi: uji isolasi otomatis (T1-04/T10-05).
  - **Verifikasi:** uji manual tambah cabang + uji SQL isolasi.

- [ ] T9-10 — Pemilik Platform: daftar penyewa baru (M1) ⚠️
  - **Tujuan:** penyewa baru bisa diaktifkan sendiri oleh Pemilik Platform, dengan data terpisah total.
  - **Ref:** PRD M1; TECH_SPEC §9 ART-1 · RPC resmi: `buat_penyewa`, `set_status_penyewa`, `tambah_cabang`
  - **File:** `aplikasi/src/layar/platform/Penyewa.tsx`, `supabase/functions/daftar_penyewa/index.ts`, `supabase/tes/daftar_penyewa.sql`
  - **DoD:** membuat penyewa + cabang pertama + akun Owner; menonaktifkan penyewa (data tidak dihapus); **uji pembuktian dua penyewa tidak saling melihat** (wajib ditunjukkan buktinya).
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: RLS (ART-1); mitigasi: satu pola RLS + uji dua penyewa setiap kali tabel baru ditambah.
  - **Verifikasi:** uji SQL + uji manual dengan dua akun Owner berbeda (bukti berupa tangkapan layar). · **Bukti visual** (tangkapan layar/foto) diambil pemilik atau penguji manusia; tugas ditandai `[x]` hanya setelah buktinya diterima.

- [ ] T9-11 — Pratinjau perubahan & pengaman riwayat
  - **Tujuan:** owner melihat dampak perubahan sebelum menyimpan, dan data lama tidak berubah diam-diam.
  - **Ref:** PRD M2 (kasus tepi)
  - **File:** `aplikasi/src/layar/pengaturan/Pratinjau.tsx`, `supabase/tes/riwayat_tidak_berubah.sql`
  - **DoD:** pratinjau tampilan & struk sebelum simpan; perubahan nama/warna/harga tidak mengubah struk & laporan lama (uji golden).
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** perubahan tak sengaja → mitigasi: tombol simpan terpisah + pratinjau + audit perubahan penting.
  - **Verifikasi:** uji SQL: ubah identitas → laporan lama identik (dibandingkan byte-per-byte angka).

- [ ] T9-12 — Daftar uji terima pengaturan (bahasa manusia)
  - **Tujuan:** owner bisa menguji sendiri bahwa semua pengaturan bekerja.
  - **Ref:** AGENT_OPERATING_GUIDE §5 (daftar uji terima)
  - **File:** `docs/uji/UJI_TERIMA_PENGATURAN.md`
  - **DoD:** daftar langkah bernomor: ubah nama → cek katalog; ubah pajak → cek struk baru; tambah menu → cek kasir; sembunyikan menu → cek katalog; 12 langkah, tiap langkah punya hasil yang diharapkan.
  - **Kompleksitas:** kecil (1,5 jam)
  - **Risiko & mitigasi:** daftar terlalu teknis → mitigasi: ditulis dari sudut pandang pemilik, diuji coba oleh orang non-teknis.
  - **Verifikasi:** pemilik menjalankan daftar ini dan menandai semua langkah berhasil.

---

## Fase 10 — Ketahanan & keamanan lanjutan (M12, K4) ⚠️ ART-8

- [ ] T10-01 — Antrean kirim luring (IndexedDB) ⚠️
  - **Tujuan:** pesanan tidak hilang saat internet kedai putus sebentar.
  - **Ref:** TECH_SPEC §13 K4 & §9 ART-8; PRD §9 risiko
  - **File:** `aplikasi/src/lib/antrean-offline.ts`, `aplikasi/src/hook/useAntrean.ts`
  - **DoD:** pesanan tersimpan lokal + dikirim otomatis saat kembali daring; status terlihat jelas ("menunggu dikirim 2"); tidak menyimpan data sensitif; uji lulus.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Antrean Offline (ART-8); mitigasi: kunci idempoten wajib + pesan status jelas.
  - **Verifikasi:** uji manual: matikan jaringan → pesan → nyalakan → pesanan terkirim sekali.

- [ ] T10-02 — Kunci idempoten menyeluruh di semua penulisan ⚠️
  - **Tujuan:** satu tindakan tidak pernah tercatat dua kali, dari layar mana pun.
  - **Ref:** TECH_SPEC §9 ART-8
  - **File:** `supabase/migrations/0057_idempoten.sql`, `supabase/tes/idempoten.sql`
  - **DoD:** semua RPC penulisan menerima kunci idempoten (pesanan, pembayaran, voucher, shift, stok); uji paralel untuk masing-masing; laporan cakupan 100%.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Antrean Offline (ART-8); mitigasi: uji otomatis "setiap RPC penulisan punya kunci" (daftar diperiksa).
  - **Verifikasi:** uji SQL: 3 RPC dengan kunci sama → satu efek.

- [ ] T10-03 — Pemulihan kegagalan kirim & pesan status
  - **Tujuan:** kasir tahu pasti pesanannya terkirim atau belum.
  - **Ref:** AGENT_OPERATING_GUIDE §6; PRD M4 (kasus tepi)
  - **File:** `aplikasi/src/komponen/StatusAntrean.tsx`
  - **DoD:** indikator selalu terlihat (terkirim/tertunda/gagal + jumlah); percobaan ulang otomatis & manual; tidak ada pesan "gagal diam-diam".
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** kasir mengira gagal padahal terkirim (atau sebaliknya) → mitigasi: status dari peladen, bukan tebakan klien.
  - **Verifikasi:** uji manual 3 skenario jaringan.

- [ ] T10-04 — Uji putus-sambung jaringan (anti data dobel)
  - **Tujuan:** membuktikan ketahanan luring benar-benar bekerja.
  - **Ref:** TECH_SPEC §11
  - **File:** `aplikasi/uji/e2e/luring.spec.ts`
  - **DoD:** uji otomatis: kirim pesanan saat luring → pulih → jumlah pesanan tetap 1; uji pembayaran & voucher juga; lulus di CI.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** uji jaringan tiruan tidak realistis → mitigasi: uji di perangkat nyata juga (T11-04) + catatan hasil.
  - **Verifikasi:** CI hijau + uji manual di perangkat kasir nyata.

- [ ] T10-05 — Penyisiran ulang RLS seluruh tabel ⚠️
  - **Tujuan:** memastikan tidak ada tabel baru yang lupa dikunci setelah semua fitur masuk.
  - **Ref:** TECH_SPEC §9 ART-1; PRD M12
  - **File:** `supabase/tes/sisir_rls_akhir.sql`
  - **DoD:** daftar tabel ↔ policy diperiksa ulang; uji akses silang untuk 6 peran; laporan akhir "0 tabel tanpa policy" dicetak.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: RLS (ART-1); mitigasi: jadwalkan penyisiran ini setiap akhir gelombang.
  - **Verifikasi:** CI hijau + laporan disimpan di dokumen uji.

- [ ] T10-06 — Akhiri sesi dari perangkat lain (perangkat hilang) ⚠️
  - **Tujuan:** perangkat pegawai yang hilang tidak menjadi pintu masuk.
  - **Ref:** PRD M12 (kasus tepi) · RPC resmi: `keluar_semua_perangkat`
  - **File:** `aplikasi/src/layar/pengaturan/SesiAktif.tsx`, `supabase/functions/akhiri_sesi/index.ts`
  - **DoD:** owner melihat daftar sesi aktif (perangkat, waktu, peran) dan bisa mengakhirinya; catatan audit dibuat; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); mitigasi: hanya owner/admin berizin + audit.
  - **Verifikasi:** uji manual: akhiri sesi dari perangkat A → perangkat B langsung keluar.

- [ ] T10-07 — Audit keamanan (menggunakan skill security-review) ⚠️
  - **Tujuan:** mencari kelemahan sebelum dipakai orang banyak, bukan sesudah.
  - **Ref:** TECH_SPEC §8 & §9; AGENT_OPERATING_GUIDE §5
  - **File:** `docs/uji/AUDIT_KEAMANAN.md`
  - **DoD:** daftar periksa keamanan dijalankan (kunci rahasia, RLS, hak akses, PIN, voucher, unggahan gambar, XSS, CORS); semua temuan diperbaiki atau dicatat dengan alasan + risiko diterima pemilik.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: RLS/Auth, Voucher; mitigasi: temuan berat wajib dibereskan sebelum produksi.
  - **Verifikasi:** dokumen audit bertanda status tiap temuan + uji ulang setelah perbaikan.

- [ ] T10-08 — Denyut harian + pembersih data sementara
  - **Tujuan:** proyek gratis tidak "tidur" dan data sementara tidak menumpuk.
  - **Ref:** TECH_SPEC §1 (pg_cron) & §10 (batas gratis)
  - **File:** `supabase/migrations/0058_pg_cron.sql`, `alat/denyut.py`
  - **DoD:** tugas terjadwal harian (denyut) berjalan; pembersih data sementara (mis. percobaan lama) berjalan malam; log hasil terjadwal; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** pembersih menghapus data penting → mitigasi: daftar tabel yang boleh dibersihkan ditulis eksplisit + uji.
  - **Verifikasi:** jalankan manual + periksa log terjadwal 2 hari.

- [ ] T10-09 — Pemulihan setelah listrik/perangkat mati mendadak (kasir & dapur)
  - **Tujuan:** kedai bisa lanjut jualan setelah listrik padam tanpa kehilangan pesanan yang sedang berjalan.
  - **Ref:** PRD §9 risiko; TECH_SPEC §9 ART-8; PRD M4 & M7
  - **File:** `aplikasi/src/lib/pemulihan-sesi.ts`, `aplikasi/uji/e2e/mati-mendadak.spec.ts`, `docs/ops/PEMULIHAN_LISTRIK.md`
  - **DoD:** keranjang yang belum terkirim tersimpan lokal dan ditawarkan kembali saat aplikasi dibuka ulang; shift yang masih terbuka dikenali dan dilanjutkan (bukan shift baru); pesanan yang sudah masuk dapur tetap tampil; langkah pemulihan ditulis 1 halaman bahasa manusia untuk pegawai.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** pemulihan menggandakan pesanan → mitigasi: kunci idempoten (T10-02) dipakai juga untuk pemulihan; uji "buka ulang 3x" hanya menghasilkan satu pesanan.
  - **Verifikasi:** uji e2e mematikan tab/aplikasi di tengah pesanan → data utuh, tidak dobel.

- [ ] T10-10 — Cadangan mingguan otomatis + uji pemulihan terjadwal
  - **Tujuan:** data kedai tidak hilang selamanya kalau terjadi kesalahan besar (paket gratis tidak punya cadangan otomatis).
  - **Ref:** TECH_SPEC §8 butir 9 (cadangan) & §10; PRD M12
  - **File:** `alat/cadangan.sh`, `docs/teknis/PEMULIHAN.md`, `.github/workflows/cadangan.yml`
  - **DoD:** `pg_dump` mingguan berjalan otomatis (GitHub Actions gratis) dan hasilnya tersimpan terenkripsi di luar basis data; `docs/teknis/PEMULIHAN.md` memuat langkah pulih bernomor; **pemulihan diuji ke basis data kosong minimal sekali** dan hasilnya dicatat; tidak ada rahasia di dalam repo.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Data pelanggan & privasi (ART-10); berkas cadangan berisi data pelanggan → mitigasi: enkripsi + akses terbatas + masa simpan dibatasi.
  - **Catatan:** T-012 sudah ditutup 2026-09-16 → cadangan disimpan sebagai **artefak terenkripsi GitHub Actions (repo privat, masa simpan 90 hari)** + pemilik mengunduh salinannya sebulan sekali.
  - **Verifikasi:** jalankan pemulihan dari satu berkas cadangan → jumlah baris tiap tabel sama dengan sumbernya.

- [ ] T10-11 — Perubahan pengaturan bersamaan tidak saling menimpa
  - **Tujuan:** dua orang yang mengubah pengaturan pada saat yang sama tidak membuat perubahan satunya hilang diam-diam.
  - **Ref:** TECH_SPEC §5 (M2 mengembalikan "versi pengaturan (stempel waktu)"); PRD M2 (kasus tepi)
  - **File:** `supabase/migrations/0059_versi_pengaturan.sql`, `supabase/tes/pengaturan_bersamaan.sql`
  - **DoD:** `simpan_pengaturan`/`simpan_menu` menolak simpanan yang memakai versi lama dengan pesan jelas ("data sudah diubah orang lain, muat ulang dulu"); perubahan yang ditolak tidak hilang dari layar; tercatat di audit.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan & pengaturan (ART-3, menyentuh pajak/service); mitigasi: penolakan di peladen, bukan hanya peringatan di layar.
  - **Verifikasi:** uji SQL dua penyimpanan paralel → satu berhasil, satu ditolak dengan kode jelas.

- [ ] T10-12 — Pegawai berhenti: cabut akses cepat & serah terima
  - **Tujuan:** pegawai yang keluar tidak bisa lagi membuka data kedai, tanpa merusak riwayat transaksinya.
  - **Ref:** PRD M3 & M12; TECH_SPEC §9 ART-2
  - **File:** `aplikasi/src/layar/pengaturan/CabutAkses.tsx`, `supabase/tes/cabut_akses.sql`
  - **DoD:** satu tombol "pegawai berhenti" → akun nonaktif + semua sesi perangkat diakhiri (T10-06) + PIN dimatikan + shift terbuka miliknya ditandai untuk ditutup atasan; nama & riwayat transaksinya TETAP ada di laporan lama.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); menghapus akun akan merusak laporan → mitigasi: nonaktif, bukan hapus (Aturan Bisnis 11).
  - **Catatan:** T-013 sudah ditutup 2026-09-16 → penutup shift = **Admin Cabang**; bila yang berhenti Admin Cabang → **Owner Pusat**.
  - **Verifikasi:** uji SQL: akun nonaktif ditolak masuk, tetapi laporan bulan lalu tetap menampilkan namanya.

---

## Fase 11 — Uji terima, deploy produksi, audit (penutup G1)

- [ ] T11-01 — Playwright: 7 alur wajib + voucher & katalog
  - **Tujuan:** semua alur inti terbukti berjalan otomatis, bukan hanya "katanya".
  - **Ref:** TECH_SPEC §11 (uji ujung-ke-ujung); AGENT_OPERATING_GUIDE §5
  - **File:** `aplikasi/uji/e2e/*.spec.ts`, `.github/workflows/ci.yml`
  - **DoD:** uji otomatis lulus untuk: buka shift → pesan → kirim dapur → bayar → cetak (digital) → void berjenjang → tutup kas, ditambah alur voucher & katalog publik; dijalankan di CI setiap push.
  - **Kompleksitas:** besar (6 jam)
  - **Risiko & mitigasi:** uji rapuh → mitigasi: pemilih stabil (teks peran bahasa Indonesia) + tunggu kondisi.
  - **Verifikasi:** CI hijau + laporan hasil dengan waktu tiap alur.

- [ ] T11-02 — Daftar uji terima bahasa manusia (dijalankan pemilik)
  - **Tujuan:** pemilik/pegawai bisa membuktikan sendiri aplikasi benar sebelum dipakai harian.
  - **Ref:** AGENT_OPERATING_GUIDE §5
  - **File:** `docs/uji/UJI_TERIMA_G1.md`
  - **DoD:** daftar langkah bernomor mencakup kasir, dapur, kas, voucher, laporan, pengaturan; tiap langkah punya hasil yang diharapkan; kolom tanda tangan/centang; ada tempat menulis catatan masalah.
  - **Kompleksitas:** sedang (2 jam)
  - **Risiko & mitigasi:** langkah terlalu teknis → mitigasi: ditulis seperti instruksi ke pegawai baru, diuji dulu oleh 1 orang non-teknis.
  - **Verifikasi:** pemilik menjalankan daftar ini sampai semua langkah tercentang.

- [ ] T11-03 — ❓ T-002 Uji cetak nyata di Kedai Oasis
  - **Tujuan:** risiko #1 PRD (cetak) terbukti selesai, bukan diasumsikan.
  - **Ref:** PRD §9 risiko #1; TECH_SPEC §11 & §12
  - **File:** `docs/uji/UJI_CETAK_KEDAI_OASIS.md` (hasil terisi)
  - **DoD:** struk & tiket tercetak benar di printer nyata; masalah nyata dicatat + solusi; bila merek printer belum diketahui → **STOP & tanya pemilik**.
  - **Kompleksitas:** sedang (2 jam + koordinasi)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Cetak (ART-7); mitigasi: jalur cadangan digital tetap wajib.
  - **Verifikasi:** foto struk & tiket nyata + lembar hasil bertanda tangan. · **Bukti visual** (tangkapan layar/foto) diambil pemilik atau penguji manusia; tugas ditandai `[x]` hanya setelah buktinya diterima.

- [ ] T11-04 — Uji perangkat kedua (iPhone/Android lain) ❓ T-003
  - **Tujuan:** memastikan aplikasi benar-benar "jalan di perangkat apa pun" seperti syarat pemilik.
  - **Ref:** PRD §6 (batasan pemilik: perangkat apa pun); TECH_SPEC §12
  - **File:** `docs/uji/UJI_PERANGKAT.md`
  - **DoD:** hasil uji dicatat untuk minimal 2 perangkat (Android/HP lain, iPhone, komputer); khusus iPhone: dicatat bahwa cetak Bluetooth tidak didukung → jalur cadangan digital dipakai; tidak ada layar rusak.
  - **Kompleksitas:** sedang (3 jam + koordinasi)
  - **Risiko & mitigasi:** perangkat tidak tersedia → mitigasi: uji emulator + minta pemilik menyediakan; jangan menunda tanpa catatan.
  - **Verifikasi:** lembar hasil uji per perangkat + tangkapan layar.

- [ ] T11-05 — Audit tampilan: kontras, a11y, responsif, keadaan layar
  - **Tujuan:** tampilan tetap enak dipakai kasir sibuk dan ramah semua orang.
  - **Ref:** AGENT_OPERATING_GUIDE §3 (a11y); TECH_SPEC §11
  - **File:** `aplikasi/alat/uji-kontras.py`, `docs/uji/AUDIT_TAMPILAN.md`
  - **DoD:** pemeriksa kontras lulus di 10 tema; a11y dasar (label, fokus, urutan tab, ukuran sentuh); responsif di 3 ukuran layar; semua layar punya keadaan kosong/memuat/gagal.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** sebagian layar terlewat → mitigasi: daftar layar diperiksa satu-satu + pemeriksa otomatis.
  - **Verifikasi:** laporan audit + pemeriksa otomatis di CI.

- [ ] T11-06 — Uji kinerja & pemantauan batas gratis (K6)
  - **Tujuan:** tetap nyaman dipakai dan tetap di dalam batas biaya nol.
  - **Ref:** TECH_SPEC §10 (batas gratis) & §13 K6
  - **File:** `alat/pantau_batas.py`, `docs/uji/KINERJA_DAN_BATAS.md`
  - **DoD:** angka nyata dicatat (ukuran data, foto, lalu lintas, pengguna aktif, pemakaian fungsi); ambang peringatan 70% & 90% terpasang; perkiraan bulanan Kedai Oasis dibandingkan batas gratis.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** batas terlampaui tanpa terasa → mitigasi: peringatan otomatis 70%/90% + laporan bulanan.
  - **Verifikasi:** jalankan pemantau → laporan angka + perintah peringatan diuji.

- [ ] T11-07 — Deploy produksi + domain + HTTPS  <!-- T-008 sudah ditutup 2026-09-16: mulai dengan alamat gratis *.workers.dev -->
  - **Tujuan:** aplikasi bisa dipakai harian oleh pegawai Kedai Oasis.
  - **Ref:** TECH_SPEC §1 & §7; PRD M12
  - **File:** `aplikasi/wrangler.toml`, `docs/ops/DEPLOY.md`
  - **DoD:** aplikasi produksi terpasang di Cloudflare; HTTPS; manifest PWA valid; variabel produksi terpisah dari pengembangan; langkah deploy & pemulihan ditulis; **data uji tidak ada di produksi**.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** salah konfigurasi produksi → mitigasi: daftar periksa sebelum deploy + uji 5 menit sesudah deploy.
  - **Verifikasi:** buka dari HP di luar jaringan kantor + daftar periksa tercentang.

- [ ] T11-08 — Peringatan pemakaian 70%/90% + halaman status
  - **Tujuan:** keputusan biaya tidak pernah mendadak (janji K6).
  - **Ref:** TECH_SPEC §13 K6 & §10
  - **File:** `aplikasi/src/layar/pengaturan/StatusPemakaian.tsx`, `supabase/functions/peringatan_batas/index.ts`
  - **DoD:** halaman status menampilkan pemakaian vs batas; peringatan dikirim saat 70% & 90%; catatan kapan terakhir diperiksa.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** angka batas berubah dari pihak penyedia → mitigasi: angka disimpan sebagai pengaturan yang bisa diperbarui + tautan ke dokumentasi.
  - **Verifikasi:** uji dengan angka tiruan (70%, 90%) → peringatan muncul.

- [ ] T11-09 — Panduan pegawai (1 halaman) + pelatihan
  - **Tujuan:** pegawai baru bisa memakai sistem dalam 15 menit.
  - **Ref:** PRD §3 (metrik sukses: tanpa balik ke kertas)
  - **File:** `docs/ops/PANDUAN_PEGAWAI.md` ❓ T-010 (pelatihan & penunjukan admin cabang)
  - **DoD:** panduan 1 halaman berisi 5 alur (buka kas → pesan → kirim dapur → bayar → tutup kas), 1 halaman untuk dapur, 1 halaman untuk pemilik (laporan); bahasa sangat sederhana; ada bagian "kalau ada masalah, lakukan ini".
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** panduan tidak dibaca → mitigasi: ditempel di dekat kasir & dapur + versi ringkas 6 langkah.
  - **Verifikasi:** 1 pegawai mencoba memakai aplikasi hanya dengan panduan (tanpa dibantu) → berhasil.

- [ ] T11-10 — Serah terima G1: cadangan, pemulihan, dan pernyataan siap
  - **Tujuan:** bukti bahwa G1 benar-benar bisa dipakai harian tanpa kertas.
  - **Ref:** PRD §3 (metrik sukses); TECH_SPEC §10
  - **File:** `docs/ops/SERAH_TERIMA_G1.md`, `alat/cadangan.sh`, `docs/teknis/PEMULIHAN.md`
  - **DoD:** cadangan mingguan berjalan & **pemulihan diuji sekali** (bukan hanya dipasang); daftar uji terima G1 semua tercentang; ringkasan angka (laporan, kinerja, batas gratis); surat pernyataan siap pakai harian dengan catatan hal yang belum selesai; pemilik menyetujui.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** cadangan tidak pernah diuji = tidak ada cadangan → mitigasi: uji pemulihan wajib sebelum pernyataan siap.
  - **Verifikasi:** hasil uji pemulihan dari berkas cadangan + tanda tangan pemilik di lembar serah terima.

---

## Checklist kelengkapan sebelum ROADMAP disetujui (Tahap 5)

- [x] Semua fitur **Must Have** M1–M12 punya task: M1 → T9-10 · M2 → T9-01…T9-07 · M3 → T1-05/T1-06/T9-08 · M4 → T3-01…T3-16 · M5 → T4-01…T4-05 · M6 → T5-01…T5-12 · M7 → T7-01…T7-06 · M8 → T7-07…T7-12 · M9 → T4-06/T4-07/T3-07 · M10 → T8-01…T8-14 · M11 → T9-06/T9-09 · M12 → T1-01…T1-22, T2-09/T2-10/T2-12, T10-05/T10-06, T11-05
- [x] Semua **entitas Data Model** punya task migrasi (+seed): T1-01…T1-14 (seluruh tabel dari `TECH_SPEC.md` §4) + seed T1-21
- [x] Semua **API/RPC** punya task endpoint + uji: `simpan_pesanan` T3-05 · `bayar_pesanan` T5-02 · `batal_pesanan` T3-13/T5-06/T5-07 · `buka_shift` T7-01 · `tutup_shift` T7-02 · `cek_voucher` T1-19/T8-09 · `pakai_voucher` T1-20/T8-09 · `katalog_publik` T8-01 · `hitung_total` T1-15/T1-16 · laporan T7-07…T7-12
- [x] Semua **Area Berisiko Tinggi** ada di Fase 1 + bertanda `⚠️` (ART-1 T1-01/T1-04/T1-22 · ART-2 T1-05/T1-06 · ART-3 T1-15/T1-16 · ART-4 T1-18/T3-05 · ART-5 T1-19/T1-20 · ART-6 T1-11/T1-13 · ART-7 T6-01/T6-06/T6-08 · ART-8 T1-14/T10-01/T10-02 · ART-9 T1-17 · ART-10 T1-12/T5-08/T8-01)
- [x] Setup repo, env, lint, uji, CI, deploy: T0-01…T0-03, T0-05, T0-07, T0-09, T0-10, T11-07
- [x] Integrasi pihak ketiga punya task setup + uji: Supabase T0-00/T0-08/T1-* · Google T2-04 · Resend T2-04/T2-05/T8-07 · Cloudflare+Wrangler T0-00/T0-09/T11-07 · pg_cron T10-08
- [x] Hal kecil tidak terlupakan: `README.md` T0-06 · `.env.example` T0-05 · favicon T0-01 · halaman error T2-08 · keadaan memuat/kosong/gagal T0-04/T3-15/T4-10 · a11y T0-04/T3-10/T11-05 · responsif T11-05 · panduan pegawai T11-09 · cadangan T11-10

**Keterangan ❓ (semua ada di `docs/TERTANGGUH.md`):** T-002 (printer) → T6-08, T11-03 · T-003 (perangkat) → T11-04 · T-010 (pelatihan) → T11-09 · T-011 (privasi pelanggan) → T8-07 · Butir T-001 (nama → "Sajian"), T-004, T-005, T-006, T-007, T-008, T-009, **T-012** (cadangan di artefak terenkripsi repo privat) dan **T-013** (penutup shift = Admin Cabang → Owner Pusat) sudah **ditutup** 2026-09-16 (lihat tabel Butir selesai di `docs/TERTANGGUH.md`).

**Jumlah tugas:** F0 11 · F1 22 · F2 12 · F3 16 · F4 10 · F5 12 · F6 8 · F7 12 · F8 14 · F9 12 · F10 12 · F11 10 = **151 tugas**, semuanya ber-7 atribut.

**Uji terima antar-fase (aturan gelombang):** fase N+1 tidak dimulai sebelum (a) semua tugas fase N `[x]`, (b) uji otomatisnya hijau, (c) `python3 alat/periksa-roadmap.py` lulus, (d) `DECISIONS_LOG.md` diperbarui untuk tugas bertanda ⚠️, (e) ringkasan 5 baris ditulis di LOG_SESI.

## Log Keputusan

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-16 | `ROADMAP.md` ditulis (146 tugas, 11 fase) | Urutan fase disetujui pemilik via delegasi; Tahap 5 selesai |
| 2026-09-16 | Tugas **T0-00** ditambah di awal Fase 0 (pemilik membuat akun Supabase & Cloudflare, dipandu) → 151 tugas | Temuan review independen W5-01: tanpa itu Fase 0 berhenti di T0-08 menunggu sesuatu yang tidak dijelaskan siapa-siapa; akun hanya bisa dibuat pemilik |
| 2026-09-16 | Nama RPC resmi disisipkan ke blok tugas yang mengerjakannya (12 tugas) + `lihat_laporan` dikeluarkan dari peta RPC (itu kode izin, bukan RPC) | Temuan review independen W3-03: peta RPC ada di luar blok tugas, sehingga pemeriksa hanya bisa mencari di seluruh dokumen |
| 2026-09-16 | 4 tugas (T0-04, T4-03, T9-10, T11-03) diberi catatan bukti visual diambil manusia; T1-18 disamakan dengan enum `TECH_SPEC.md` §4.3; T0-08 diberi catatan bangunkan database setelah jeda >7 hari | Temuan review independen W4-01, W1-02, W5-03 |
| 2026-09-16 | Review independen: 4 tugas ditambah di Fase 10 (T10-09 pemulihan listrik · T10-10 cadangan+uji pemulihan · T10-11 pengaturan bersamaan · T10-12 pegawai berhenti) → 150 tugas | Skenario operasional nyata belum punya tugas sama sekali; cadangan hanya disebut di TECH_SPEC §8 dan di DoD T11-10, tanpa tugas pelaksana sendiri |
| 2026-09-16 | Review independen: tanda `❓` basi (T-001/T-004/T-005/T-007/T-008 yang sudah ditutup) dibersihkan dari 7 tempat | Tanda itu membuat agent maraton MELEWATI tugas yang sebenarnya sudah boleh dikerjakan — termasuk T0-09 (deploy Fase 0) |
| 2026-09-16 | T-012 & T-013 ditutup dengan nilai usulan agent (cadangan di artefak terenkripsi repo privat + unduhan bulanan pemilik; penutup shift = Admin Cabang → Owner Pusat) — tanda ❓ basi di T10-10/T10-12 dibersihkan | Aturan maraton melewati tugas bertanda ❓; setelah butirnya ditutup, tanda itu justru menyesatkan (kelas cacat yang sama dengan 7 tanda basi sebelumnya) |
| 2026-09-16 | Review independen: nama tabel di Ref T1-07/T4-06/T4-07 diselaraskan dengan TECH_SPEC §4.2 (`kategori_menu`, `stok_bahan`, `stok_pergerakan`) | ROADMAP memakai nama pendek (`kategori`, `stok`) yang tidak ada di skema — agent coding bisa membuat tabel bernama salah |
| 2026-09-16 | Tugas yang menunggu jawaban pemilik ditandai `❓ T-xxx` dan dilewati (mode maraton) | Aturan `AGENT_OPERATING_GUIDE.md` §13: tunda-catat-lanjut, jangan mengerjakan setengah |
| 2026-09-16 | Fase 0 dimulai: **T0-01, T0-02, T0-03 ditandai `[x]`** (repo React+TS+Vite, aturan kode otomatis, token v3 + pemilih tema/kerapatan) | Tiga tugas sudah bisa dibuktikan otomatis; sisa Fase 0 (T0-04…T0-07) menyusul, sedangkan T0-08/T0-09 menunggu akun pemilik (T0-00) |
| 2026-09-16 | T0-01 memakai `favicon.svg` + `robots.txt`, bukan `favicon.ico` | Tidak ada alat pengubah ICO di lingkungan ini; SVG tetap tajam di semua ukuran dan didukung semua peramban modern; robots sengaja `Disallow: /` karena halaman butuh masuk |
| 2026-09-16 | Pemeriksa baru `aplikasi/alat/periksa-struktur.py` (pohon folder dibaca dari `TECH_SPEC.md` §3, token diperiksa identik dengan prototipe, larangan warna mentah di luar token, kode tema aplikasi vs token) | Syarat pemilik "hasil tanpa masalah" harus dibuktikan alat, bukan klaim; uji mutasi membuktikan pemeriksa ini benar-benar menyala |
| 2026-09-16 | T0-04…T0-07 selesai otomatis (komponen dasar + keadaan · rahasia/env · README · CI); T0-04 menunggu bukti visual pemilik sebelum ditandai `[x]` | Pemisahan tugas seperti itu sudah ditetapkan di tugasnya sendiri (bukti visual diambil manusia) |
| 2026-09-16 | CI pertama menemukan 2 cacat nyata: **folder layar kosong tidak ikut Git** (clone bersih kehilangan 7 folder) dan satu berkas Markdown belum dirapikan | Bukti bahwa “hijau di komputer” tidak sama dengan “hijau di tempat lain” — pemeriksa struktur diperkuat (folder wajib harus terlacak Git) + dibuat `aplikasi/alat/periksa-semua.sh` yang menjalankan persis pemeriksaan CI |
| 2026-09-16 | Pemeriksa baru `aplikasi/alat/periksa-komponen-env.py` + `aplikasi/alat/uji-kontras.py` (versi aplikasi) dan `aplikasi/alat/periksa-semua.sh` | Semua klaim Fase 0 harus dibuktikan alat: komponen wajib ada, kontras 166/166, tinggi sentuh ≥44 px, variabel rahasia lengkap, `.env` diabaikan Git |
| 2026-09-16 | **T0-04 ditandai `[x]`** setelah bukti visual pemilik diterima (pemilik membuka pratinjau & menyatakan “Lanjut”) | Aturan bukti visual di tugas itu sendiri; bukti otomatis sudah lengkap sebelumnya |
| 2026-09-16 | **T0-10 selesai**: kerangka uji diperkuat (jsdom + @testing-library/react, 51 uji) + pemeriksa baru `aplikasi/alat/periksa-uji.py` yang menolak berkas logika tanpa uji | Tujuan T0-10 adalah TDD sejak awal; risiko “uji hanya formalitas” dijawab dengan gerbang otomatis, bukan janji |
| 2026-09-16 | Aturan baru: **pemulihan setelah ruang kerja dinyalakan ulang** (`aplikasi/alat/pratinjau.sh` + `alat/pulihkan-git.sh`) masuk `AGENT_OPERATING_GUIDE.md` §0 dan prompt pembuka universal | Kejadian nyata: setelah restart, pustaka aplikasi hilang (pratinjau mati) dan salinan Git lokal mundur ke `main` — sesi berikutnya (model apa pun) harus tahu cara memulihkan tanpa menebak |
