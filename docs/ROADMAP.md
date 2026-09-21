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

- [x] T0-00 — Pemilik membuat akun Supabase & Cloudflare (dipandu, gratis) — **hanya pemilik yang bisa**
  - **Tujuan:** dua akun gratis siap dipakai agent. Ini satu-satunya tugas Fase 0 yang **harus** dikerjakan pemilik: agent tidak punya email dan tidak bisa menerima kode verifikasi.
  - **Ref:** TECH_SPEC §1 (stack & layanan), §6 (rahasia tidak boleh ikut ke aplikasi); `docs/ops/SIAP_AKUN_PEMILIK.md`
  - **File:** `docs/ops/SIAP_AKUN_PEMILIK.md` (panduan langkah bernomor bahasa awam, ditulis sebelum tugas ini dimulai)
  - **DoD:** akun Supabase + proyek gratis (wilayah Singapura) dan akun Cloudflare aktif; **URL proyek + kunci `anon`** diserahkan ke agent; kunci `service_role` **tidak pernah ditempel ke chat** (langsung ditaruh di berkas rahasia lokal / secrets Cloudflare); catatan "akun sudah ada" ditulis di README aplikasi.
  - **Kompleksitas:** kecil (30 menit dipandu)
  - **Risiko & mitigasi:** kunci rahasia bocor lewat chat atau repo → mitigasi: panduan hanya mengizinkan nilai `anon` ditempel, `.env*` diabaikan Git (T0-05), kunci `service_role` disimpan di secrets Cloudflare.
  - **Verifikasi:** pemilik bisa membuka dashboard kedua layanan; agent menyimpan nilai dari pemilik di berkas rahasia lokal (tidak di-commit) dan `git check-ignore` membuktikan berkas itu diabaikan. · **Bukti 2026-09-19:** pemilik (Lee) membuat akun **Supabase + Resend + Cloudflare**; nilai non-rahasia (URL proyek, kunci publik, id proyek, region **Singapore**, id akun Cloudflare) diserahkan lewat berkas `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md` (commit `bd68685`); kunci `service_role` tidak pernah masuk repo maupun obrolan; butir tunggu `T-018` ditutup.

- [x] T0-01 — Repo aplikasi React + TypeScript + Vite + struktur folder
  - **Tujuan:** aplikasi bisa dijalankan lokal sejak commit pertama dan strukturnya sama dengan rancangan.
  - **Ref:** TECH_SPEC §1 (stack) & §3 (struktur folder); PRD §6 Non-Goals
  - **File:** `aplikasi/package.json`, `aplikasi/vite.config.ts`, `aplikasi/tsconfig.json`, `aplikasi/tsconfig.app.json`, `aplikasi/tsconfig.node.json`, `aplikasi/index.html`, `aplikasi/public/favicon.svg`, `aplikasi/public/robots.txt`, `aplikasi/src/layar/contoh/LayarContoh.tsx`
  - **DoD:** `npm install && npm run dev` jalan tanpa error; folder `/src/{gaya,komponen,layar,lib,hook}` ada; favicon terpasang; `tsc -b --noEmit` bersih (dipakai mode proyek — `tsc --noEmit` biasa memeriksa nol berkas pada susunan referensi, dibuktikan lewat uji mutasi 2026-09-16).
  - **Kompleksitas:** kecil (1 jam)
  - **Risiko & mitigasi:** salah struktur → mitigasi: salin persis struktur `TECH_SPEC.md` §3, jangan improvisasi nama folder.
  - **Verifikasi:** `npm run dev` + buka URL dev; `git status` bersih setelah commit. · **Bukti 2026-09-16:** `npm run dev` melayani halaman (HTTP 200), `main.tsx`, `tema.css`, dan berkas huruf (font/woff2); 7 folder layar + `supabase/{migrations,functions,tes}` ada; berkas huruf **19 berkas** `.woff2` di aplikasi (angka terhitung 2026-09-17; perintah yang bisa diulang: `find aplikasi/src/gaya/aset -name '*.woff2' | wc -l` (huruf ada di `aset/font/`) → 19; prototipe memakai 19 berkas huruf yang sama di `prototipe/aset/font/`). **Riwayat klaim:** angka "31 berkas" dicabut (tidak bisa direproduksi, temuan audit B-F-13); angka "57" juga **dicabut** karena perintah yang dikutip waktu itu (`find aplikasi -name '*.woff2' | wc -l`) menghasilkan 38 — ia menghitung salinan hasil bangun (`dist/`) dan tidak menyebut lingkupnya. Sekarang angkanya dijaga otomatis oleh `aplikasi/alat/periksa-struktur.py` (angka di dokumen ini harus sama dengan hitungan nyata) — klaim lama "31 berkas huruf pindah" **dicabut** karena tidak bisa direproduksi (temuan audit B-F-13); favicon dipakai format SVG (bukan ICO) karena tidak butuh alat pengubah gambar dan tetap tajam di semua ukuran; pemeriksa `aplikasi/alat/periksa-struktur.py` memeriksa pohon folder langsung dari `TECH_SPEC.md` §3.

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
  - **Verifikasi:** `prototipe/uji-kontras.py` versi aplikasi dijalankan (dibuat di T0-04) + inspeksi 3 tema secara visual. · **Bukti 2026-09-16:** `tema.css` identik byte-per-byte dengan `prototipe/css/tokens.css` (diperiksa otomatis), 19 berkas huruf tersalin dan semua rujukan `url()` di dalamnya ada di disk; 10 kode tema di `aplikasi/src/lib/tema.ts` sama persis dengan kode tema di token (diperiksa otomatis); warna `theme-color` peramban diambil dari token `--accent`, bukan ditulis di `index.html`; **76 uji unit hijau** (format uang/tanggal/jam, tema & kerapatan, render layar contoh; angka saat itu 2026-09-18 — perintah: `cd aplikasi && npm test`).

- [x] T0-04 — Komponen dasar + keadaan kosong/memuat/gagal + uji kontras aplikasi
  - **Tujuan:** semua layar memakai komponen yang sama dan tidak pernah menampilkan halaman kosong tanpa penjelasan.
  - **Ref:** TECH_SPEC §3 (folder komponen); AGENT_OPERATING_GUIDE §3 (a11y)
  - **File:** `aplikasi/src/komponen/*.tsx`, `aplikasi/src/gaya/komponen.css`, `aplikasi/alat/uji-kontras.py`, `aplikasi/alat/periksa-komponen-env.py`, `aplikasi/src/layar/contoh/LayarContoh.tsx`
  - **DoD:** komponen Tombol, Kartu, Lapis (mengambang), Toast, Tabel, KolomIsian, KeadaanKosong, KeadaanMemuat, KeadaanGagal ada; target sentuh ≥44 px; fokus keyboard terlihat; uji kontras ≥95% pemeriksaan lulus.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** komponen tidak konsisten → mitigasi: satu komponen satu berkas + token wajib + uji kontras otomatis.
  - **Verifikasi:** `python3 aplikasi/alat/uji-kontras.py` lulus + tangkapan layar 1 halaman contoh. · **Bukti visual** (tangkapan layar/foto) diambil pemilik atau penguji manusia; tugas ditandai `[x]` hanya setelah buktinya diterima. · **Bukti otomatis 2026-09-16:** `uji-kontras.py` versi aplikasi **166 lolos · 0 gagal** (130 pemeriksaan warna 10 tema + 36 aturan desain, termasuk tinggi sentuh ≥44 px); 10 komponen ada dan diperiksa `aplikasi/alat/periksa-komponen-env.py`; **76 uji hijau dalam 10 berkas** (angka saat itu 2026-09-18; perintah yang bisa diulang: `cd aplikasi && npm test`); layar contoh `aplikasi/src/layar/contoh/LayarContoh.tsx` memperagakan semua komponen & ketiga keadaan halaman. **Bukti visual (pemilik) 2026-09-16:** pemilik membuka pratinjau aplikasi lalu menyatakan **“Lanjut”** — tampilan tema (10), kerapatan (nyaman/padat), lapis mengambang, dan ketiga keadaan halaman dinilai pantas. Dengan bukti otomatis + bukti visual itu, tugas ini ditandai `[x]`.

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
  - **Verifikasi:** ikuti README dari nol di folder sementara → berhasil. · **Bukti 2026-09-16:** folder `aplikasi/` disalin ke tempat bersih (tanpa `node_modules`/`dist`), lalu `npm ci` → Prettier → ESLint → TypeScript → **76 uji** (angka saat itu 2026-09-18; perintah: `cd aplikasi && npm test`) → build: **semuanya hijau** mengikuti langkah di README; README memuat prasyarat, cara menjalankan, peta folder, daftar perintah, aturan rahasia, daftar pemeriksa, dan bagian “sebelum mengirim kode”.

- [x] T0-07 — CI dasar (lint + tipe + uji unit)
  - **Tujuan:** setiap push diperiksa otomatis; tidak ada kode rusak yang lolos.
  - **Ref:** AGENT_OPERATING_GUIDE §5 (testing) & §4 (commit)
  - **File:** `.github/workflows/ci.yml`
  - **DoD:** CI menjalankan `npm ci`, `lint`, `typecheck`, `test`; gagal bila ada yang gagal; berlaku untuk branch sesi maupun PR.
  - **Kompleksitas:** kecil (1 jam)
  - **Risiko & mitigasi:** CI lambat/berbiaya → mitigasi: hanya GitHub Actions gratis untuk repo publik, tanpa langkah berbayar.
  - **Verifikasi:** status CI hijau pada push pertama; sengaja membuat lint gagal di uji coba → CI merah. · **Bukti 2026-09-16:** CI menyala di setiap push & pull request; gerbangnya benar-benar bekerja — (a) run 35121292973 **MERAH di langkah ESLint** saat sengaja dipasang variabel tidak terpakai (kode ujinya lalu dihapus), (b) run 35120922393 merah karena folder layar kosong tidak ikut Git, (c) run 35121062046 merah karena satu berkas Markdown belum dirapikan, dan (d) run **35121525551 hijau penuh** (npm ci → Prettier → ESLint → TypeScript → Vitest → build → 5 pemeriksa Python). Artinya: dua cacat nyata tertangkap CI, bukan cuma “hijau karena kebetulan”. Semua ini memakai jatah gratis GitHub Actions (repo privat 2.000 menit/bulan).

- [x] T0-08 — Proyek Supabase dibuat + klien aman tersambung
  - **Tujuan:** aplikasi bisa membaca data dari Supabase dengan kunci publik saja.
  - **Ref:** TECH_SPEC §1 & §6; AGENT_OPERATING_GUIDE §3
  - **File:** `aplikasi/src/lib/supabase.ts`, `supabase/config.toml`, `aplikasi/.env.local` (tidak di-commit)
  - **DoD:** koneksi uji (`select 1`) berhasil dari aplikasi; tidak ada kunci rahasia di klien; catatan pembuatan proyek ditulis di README.
  - **Kompleksitas:** kecil (1 jam)
  - **Risiko & mitigasi:** proyek gratis "tidur" setelah 7 hari → mitigasi: dijadwalkan denyut harian (T10-08).
  - **Catatan jeda:** kalau pembangunan berhenti lebih dari 7 hari (libur/menunggu jawaban), proyek gratis bisa "tertidur" → buka panel Supabase, tekan **Restore/Unpause** sebelum melanjutkan; penyebab paling umum "koneksi gagal" di sesi berikutnya.
  - **Verifikasi:** buka aplikasi di dev → tampilkan hasil `select 1` di console/halaman uji — **sejak 2026-09-19 dijalankan otomatis di CI**: gerbang ke-50 (`npm run cek:supabase`) menguji alamat + kunci + **baca tabel katalog** dari runner GitHub, jadi siapa pun bisa memeriksa ulang.
  - **Progres 2026-09-19:** klien aman + alat uji sambung selesai — `aplikasi/src/lib/supabase.ts` (hanya dua nilai publik, tidak meledak bila pengaturan kosong) + `aplikasi/src/lib/supabase.test.ts` (10 kasus) + `aplikasi/alat/cek-supabase.mjs` (+`--uji-diri` 5 kasus). **Gerbang CI ke-50** menjalankan `npm run cek:supabase` di runner GitHub karena lingkungan agent tidak punya jalan keluar jaringan ke `*.supabase.co` (terbukti: HTTP 000/TLS ditolak). **Sisa DoD:** uji baca data (`select 1`) belum bisa — tabel belum ada di proyek nyata sebab **skema belum disebar** → butir tunggu `T-020`. **Siap dijalankan (2026-09-19):** `supabase/config.toml` (wajib bagi CLI Supabase — bentuk ringkas tanpa `env(...)`, sudah diuji dengan CLI 2.117.0) · alur `.github/workflows/sebar-skema.yml` yang **sengaja dipicu berkas penanda** supabase/SEBAR-SKEMA dan menjalankan **pratinjau `--dry-run` lebih dulu** · panduan pemilik `docs/ops/LANGKAH_PEMILIK_SEKARANG.md` (2 rahasia GitHub, tanpa perintah). Penjaga `alat/periksa-gerbang-ci.py` ikut mengawasi alur di luar `ci.yml` (8 perintah alur ini, dua arah, **urutan diperiksa**) dan `--uji-diri` menolak 9 mutasi alur (termasuk urutan ditukar & pemeriksaan penanda dihapus). **Bukti jalur berfungsi (2026-09-19):** penanda terpasang → alur menyala lalu berhenti di gerbang rahasia (run `35433200326`); penanda dihapus → hijau tanpa kerja (run `35433237658`). **Bukti live 2026-09-19:** langkah itu benar-benar **hijau** di CI — run `35432334878` (langkah ke-11 "Cek sambungan Supabase (kunci publik saja — tugas T0-08)" = success; pranala https://github.com/With-AI-Agent/Resto-Barokah/actions/runs/35432334878). Artinya proyek Supabase nyata menjawab dan menerima kunci publik **dari aplikasi**, tanpa satu pun kunci rahasia. **Bukti 2026-09-19 (skema hidup):** 14 migrasi disebar ke proyek nyata lewat alur disengaja `.github/workflows/sebar-skema.yml` — run `35435248540` **hijau berurutan** (`link` → `db push --dry-run` → `db push` → `migration list`), dan agent tidak pernah melihat kredensial. **Uji baca data** (setara `select 1`) juga hijau di gerbang CI ke-50: run `35435414653` langkah ke-11 success — `GET /rest/v1/menu_item?select=id&limit=1` menjawab **HTTP 200** dengan kunci publik saja. Karena database nyata sudah memuat `0001`–`0014`, berkas itu **dibekukan**: perubahan skema berikutnya WAJIB berkas baru `0015` ke atas (dijaga `alat/periksa-migrasi-beku.py`).

- [x] T0-09 — Deploy halaman kosong ke Cloudflare Workers + Static Assets  <!-- T-008 sudah ditutup 2026-09-16: pakai alamat gratis *.workers.dev -->
  - **Tujuan:** membuktikan jalur deploy bekerja sejak awal (bukan mendadak di akhir).
  - **Ref:** TECH_SPEC §1 (halaman aplikasi) & §7 (integrasi)
  - **File:** `aplikasi/wrangler.toml`, `aplikasi/package.json` (script deploy)
  - **DoD:** halaman kosong dapat diakses publik lewat alamat sementara `*.workers.dev`; HTTPS aktif; deploy bisa diulang dengan satu perintah.
  - **Kompleksitas:** sedang (2 jam)
  - **Risiko & mitigasi:** kuota gratis (100.000 permintaan/hari) → mitigasi: berkas statis tanpa batas; tidak memakai fungsi boros.
  - **Verifikasi:** buka URL publik di luar jaringan lokal; `curl -I` mengembalikan 200 — **dijalankan otomatis
    sejak 2026-09-19**: alur unggah memeriksa alamatnya sendiri dan mencatat hasilnya sebagai anotasi (`node
    aplikasi/alat/catat-alamat.mjs`), jadi "hijau" berarti halaman benar-benar menjawab 200.
  - **Progres 2026-09-19 (SELESAI):** **halaman sudah naik & publik atas izin Lee ("Boleh naik")** — alamat <https://resto-barokah.fatrizmubarok.workers.dev>, bukti: run `35440300274` & `35440432817` hijau, pemeriksaan otomatis HTTP 200 (anotasi pada commit `705ed0f`), dicatat di `docs/ops/ALAMAT_PUBLIK.md`. Persiapan sebelumnya — `aplikasi/wrangler.toml` (Workers + Static Assets, alamat gratis `*.workers.dev`, halaman satu-api `single-page-application`) dan satu perintah rilis `npm run deploy` (bangun lalu unggah). Yang **belum**: menjalankannya, karena deploy publik = tindakan tak bisa dibatalkan → butir tunggu `T-021` (keputusan Lee). **Siap dijalankan (2026-09-19):** alur `.github/workflows/sebar-halaman.yml` (dipicu berkas penanda aplikasi/SEBAR-HALAMAN, memakai rahasia GitHub `CLOUDFLARE_API_TOKEN` + nomor akun Cloudflare yang bukan rahasia) + panduan pemilik `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`. **Bukti jalur berfungsi (2026-09-19):** penanda terpasang → alur menyala lalu berhenti di gerbang rahasia (run `35433200375`); penanda dihapus → hijau tanpa kerja (run `35433237656`).

- [x] T0-10 — Vitest + uji contoh + skrip pemeriksa roadmap
  - **Tujuan:** kerangka uji siap sebelum kode uang/keamanan ditulis (TDD sejak awal).
  - **Ref:** AGENT_OPERATING_GUIDE §5; TECH_SPEC §11
  - **File:** `aplikasi/vitest.config.ts`, `aplikasi/src/lib/format.test.ts`, `aplikasi/src/lib/tema.test.ts`, `aplikasi/src/lib/env.test.ts`, `aplikasi/src/hook/useJam.test.tsx`, `aplikasi/src/hook/useTema.test.tsx`, `aplikasi/src/komponen/komponen.test.tsx`, `aplikasi/alat/periksa-uji.py`, `alat/periksa-roadmap.py`
  - **DoD:** `npm test` lulus; uji contoh format rupiah ada; `python3 alat/periksa-roadmap.py` lulus di dokumen ROADMAP ini.
  - **Kompleksitas:** kecil (1,5 jam)
  - **Risiko & mitigasi:** uji hanya formalitas → mitigasi: uji wajib untuk setiap fungsi uang/izin mulai Fase 1 — **dijaga alat**: `aplikasi/alat/periksa-uji.py` menolak kiriman kode kalau ada berkas logika di `src/lib` atau `src/hook` yang tidak punya berkas ujinya sendiri.
  - **Verifikasi:** `npm test` hijau + `python3 alat/periksa-roadmap.py` hijau. · **Bukti 2026-09-16:** **76 uji hijau dalam 10 berkas** (angka saat itu 2026-09-18; perintah: `cd aplikasi && npm test`; jumlah berkas uji bertambah bersama fase berikutnya) (uang/tanggal/jam · tema & kerapatan · pembacaan pengaturan · jam berdenyut · pemilih tema dengan jsdom · 17 uji komponen · layar contoh); kerangka siap untuk kode uang/izin — jsdom + @testing-library/react terpasang supaya hook bisa diuji seperti pemakaian nyata; pemeriksa baru `aplikasi/alat/periksa-uji.py` (6 OK · 0 GAGAL) menolak berkas logika tanpa uji (dibuktikan lewat uji mutasi); pemeriksa itu ikut jalan di CI; `alat/periksa-roadmap.py` LOLOS.

---

- [x] T0-11 — Buku pedoman induk (manual book) + penjaga otomatis
  - **Tujuan:** pemilik punya **satu buku lengkap** yang memuat semua mekanisme, semua prompt, glosarium, penanganan masalah, dan peta berkas — serta tidak bisa basi pelan-pelan.
  - **Ref:** permintaan pemilik 2026-09-17 (*"satu file untuk pengguna yang betul-betul isinya lengkap… semacam manual book"*); `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §2b
  - **File:** `PANDUAN_PENGGUNA.md` (Bagian A–H) · `alat/periksa-panduan.py` · `.github/workflows/ci.yml` · `docs/PANDUAN_PEMILIK.md`
  - **DoD:** buku memuat A peta cepat · B prompt & kalimat siap pakai · C semua mekanisme (≥10, masing-masing dengan berkas rujukan) · D semua prompt kanonik (termasuk prompt auditor) · E istilah awam + istilah audit · F penanganan masalah · G peta berkas · H template & kebiasaan; blok Prompt Pembuka identik dengan `PROMPT_ENTRI_UNIVERSAL.md`; blok Prompt Auditor identik dengan `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`; setiap rujukan ber-`backtick` hidup (kecuali ditandai "(rencana)"); penjaga ikut CI & `aplikasi/alat/periksa-semua.sh`.
  - **Kompleksitas:** sedang (2,5 jam)
  - **Risiko & mitigasi:** buku dibangun dengan menyalin potongan berkas lama → risiko isi ganda/berbeda; mitigasi: blok prompt **diambil langsung dari sumber kanonik** saat pembangunan + pemeriksa identitas; rujukan basi → pemeriksa rujukan hidup (terbukti menangkap 1 rujukan nyata: `ROADMAP.md` → `docs/ROADMAP.md`).
  - **Verifikasi:** `python3 alat/periksa-panduan.py` LOLOS (angka baris/mekanisme/rujukan dikeluarkan pemeriksa saat dijalankan — jangan dikutip sebagai angka tetap) · `python3 _sistem/validate_system.py` PASS · pemeriksa-panduan muncul di CI & periksa-semua · contoh penolakan nyata tercatat di `docs/uji/AUDIT_RIWAYAT.md` §4 butir 5–6.

- [ ] T0-12 — Audit independen menyeluruh (AUD-3) atas keadaan sekarang + tindak lanjut temuan ⚠️ (paket peninjau sudah disegarkan 2026-09-19; tinggal pemilik menjalankan sesi auditor)
  - **Tujuan:** sebelum pekerjaan ulang (T1-37) dan sebelum melanjutkan Fase 1, **seluruh keadaan sekarang diperiksa sesi auditor independen** dengan lingkup menyeluruh (semua berkas proyek, termasuk berkas untuk pengguna) — sesuai urutan yang diputuskan pemilik: **audit lebih dulu**.
  - **Ref:** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §2b & §11 · permintaan pemilik 2026-09-17 (*"sekarang aku mau audit dulu"*, gerbang `tahan_semua`)
  - **File:** `docs/uji/paket-audit/AUD-3-<tanggal>.md` · `docs/uji/audit/LAPORAN_AUD-3_<tanggal>_menyeluruh.md` · `docs/uji/AUDIT_RIWAYAT.md` · `docs/TERTANGGUH.md` (temuan K-3/K-4 yang ditunda)
  - **DoD:** paket dibuat `--paket AUD-3 --semua`; salinan kalibrasi cacat tanaman disiapkan & dinilai; auditor **sesi baru (idealnya model berbeda)** menjalankan semua lensa; laporan memuat mode `menyeluruh` + `Cakupan menyeluruh: X dari Y berkas` + sub-bagian `### 1a. Berkas untuk pengguna` dan **lolos** `--periksa-laporan`; semua K-1/K-2 ditutup **atau** fase tetap ditahan; verdict + tingkat deteksi dicatat di `docs/uji/AUDIT_RIWAYAT.md`.
  - **Kompleksitas:** besar (1–2 sesi auditor + 1 batch perbaikan)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` bila perbaikan menyentuh keputusan terkunci; audit menyeluruh bisa menemukan banyak K-3/K-4 → dikelola lewat `docs/TERTANGGUH.md` (maks 12) tanpa menutup K-1/K-2; auditor tidak bisa dijalankan di sesi yang sama → pemilik membuka sesi baru (risiko sisa §14 butir 5).
  - **Verifikasi:** laporan lolos kontrak mesin · kalibrasi memenuhi ambang (semua K-1/K-2 tertanam ditemukan, ≥70% total, 0 temuan palsu) · nol K-1/K-2 terbuka sebelum `[x]`.

- [x] T0-13 — Mekanisme review PR independen + Kartu Keputusan untuk Lee
  - **Tujuan:** Lee bisa mengambil keputusan merge **tanpa membaca kode**: peninjau sesi baru menilai diff per jalur risiko, dan mesin mencetak Kartu Keputusan 7 baris.
  - **Ref:** permintaan Lee 2026-09-17 (*"aku sendiri ga bisa melakukan review itu… aku bingung ketika liat komparasi file changed"*); riset industri 2026 (lihat `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` §7)
  - **File:** `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` · `docs/uji/PROMPT_REVIEW_PR_INDEPENDEN.md` · `alat/review-pr.py` · `docs/uji/REVIEW_PR_RIWAYAT.md` · `docs/uji/review-pr/`
  - **DoD:** tiga tingkat RV-1…RV-3 · jalur risiko Merah/Kuning/Hijau menentukan kedalaman review · 5 syarat merge wajib · kartu keputusan dapat dibuat mesin · kalibrasi diff berisi cacat sengaja (kunci di luar repo) · `--uji-diri` membuktikan pemeriksa bisa MENOLAK laporan buruk (3 contoh) · CI menjalankannya.
  - **Kompleksitas:** besar (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: gerbang merge & mutu; risiko reviewer "ramah"/hijau palsu → mitigasi: laporan wajib bukti perintah + kalibrasi + verdict dipaksa `TIDAK-BERSIH` bila ada K-1/K-2 TERVERIFIKASI; risiko PR besar campur-risiko → aturan pemisahan jalur.
  - **Verifikasi:** `python3 alat/review-pr.py --uji-diri` LOLOS · `--siapkan` menghasilkan paket + SIAP-TEMPEL (diuji pada repo ini) · `--kesiapan` melaporkan SIAP/BELUM dengan benar · prosedur tercatat di `PANDUAN_PENGGUNA.md` (AL-6) & `docs/PANDUAN_PEMILIK.md`.

- [x] T0-14 — Buku pedoman induk v2 (berbasis alur + prompt berlabel + penjelasan perintah)
  - **Tujuan:** memperbaiki keluhan Lee bahwa buku masih kurang & cacat: banyak *cara* tidak dijelaskan, prompt tanpa panduan langkah, tabel perintah tanpa penjelasan fungsi, dan ada prompt yang kata-katanya untuk pengguna tetapi disajikan sebagai perintah.
  - **Ref:** pesan Lee 2026-09-17 (lihat `docs/teknis/REKAM_PESAN_PEMILIK.md` §4); `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §2b
  - **File:** `PANDUAN_PENGGUNA.md` · `alat/periksa-panduan.py` · `docs/PANDUAN_PEMILIK.md` · `docs/teknis/REKAM_PESAN_PEMILIK.md` · `PROFIL_PENGGUNA.md`
  - **DoD:** Bagian B = **12 alur** dengan 8 bidang tetap (Apa ini · Kapan dipakai · Kalimat Lee · Langkah Lee · Yang agent lakukan · Bukti yang Lee terima · Lama · Kalau macet) · **setiap blok prompt berlabel** `[LEE → AGENT]` / `[LEE → PENINJAU]` · Bagian E menjelaskan **fungsi, cara pakai, dan arti bila GAGAL** untuk setiap perintah · perintah teknis yang seharusnya tugas agent dipindahkan dari prompt Lee ke deskripsi tugas agent (§C3) · panggilan **Lee** (bukan "Bapak") · pemeriksa menolak buku yang kehilangan bidang/label/penjelasan.
  - **Kompleksitas:** besar (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md`; risiko buku menjadi terlalu panjang dan justru sulit dipakai → mitigasi: §0 tabel "mau melakukan apa → alur mana", tiap alur berformat sama, dan ringkasan terpisah di `docs/PANDUAN_PEMILIK.md`.
  - **Verifikasi:** `python3 alat/periksa-panduan.py` LOLOS (12 alur · 4 blok prompt berlabel · 18 perintah berpenjelasan) · penjaga baru ini **terbukti menolak** saat bidang alur atau label prompt dihapus (uji coba dijalankan sebelum commit).

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
  - **Verifikasi:** uji SQL menolak 7 tindakan sensitif untuk peran yang tidak berizin. · **Bukti 2026-09-16:** `supabase/migrations/0005_izin_berjenjang.sql` + `supabase/tes/izin.sql`. Kamus resmi **10 kode izin** (`izin_kode`) dan **izin bawaan per peran** (`izin_peran`, 50 baris per resto, dipasang otomatis untuk resto baru lewat pemicu). Gerbang tunggal **`boleh(aksi)` / `boleh(aksi, nominal)` / `boleh(aksi, nominal, persen)`** di atas `izin_efektif()`: centang khusus pegawai (`izin`) menang atas bawaan peran, dan bila tidak ada keduanya → **TOLAK**. Matriks 10 izin diuji untuk kasir, admin cabang, dapur, pelayan, dan owner pusat; **13+ tindakan sensitif terbukti ditolak** (kasir 6 · dapur 3 · pelayan 3 · admin 1) dan yang berizin terbukti boleh. Diuji juga: batas diskon (25.000/5 persen kasir · 50.000/10 persen admin) termasuk tepat-di-batas vs lewat-batas, izin **berbeda per cabang** untuk pegawai merangkap (peran dapur di satu cabang, kasir di tingkat akun), **cabang asing ditolak** (tidak diam-diam jatuh ke peran se-resto), aksi tak dikenal ditolak, akun nonaktif & pemilik platform tidak boleh apa pun, kasir tidak bisa mengubah tabel izin, dan resto lain tidak melihat izin peran resto ini. **Gerbang dibuktikan bisa MERAH lewat 4 uji mutasi** (angka saat itu: dijalankan manual pada 2026-09-16; harness mutasi otomatis baru ada untuk pagar 0012 ke atas — lihat `python3 alat/uji-mutasi-0012.py`) — tolak-demi-bawaan dirusak · centang khusus diabaikan · batas diskon diabaikan · cabang asing diterima: semuanya GAGAL, LOLOS setelah dipulihkan. Mutasi ke-4 awalnya **lolos** sehingga mengungkap uji yang lemah (cabang asing diuji dengan tindakan yang memang sudah terlarang di tingkat akun) → uji diperkuat memakai tindakan yang boleh di akun tetapi tidak di cabang itu, dan mutasi yang sama langsung tertangkap.

- [x] T1-06 — PIN pegawai: hash + pembatasan percobaan ⚠️
  - **Tujuan:** PIN tidak bisa dibaca dari database dan tidak bisa ditebak dengan percobaan berulang.
  - **Ref:** TECH_SPEC §4 (`percobaan_pin`) & §9 ART-2; PRD M3 & M12
  - **File:** `supabase/migrations/0006_pin.sql`, `supabase/functions/verifikasi_pin/index.ts`, `supabase/tes/pin.sql`, `supabase/tes/percobaan_pin_perangkat.sql`
  - **DoD:** PIN disimpan sebagai hash (tidak pernah teks biasa); percobaan salah dibatasi (mis. 5×/15 menit) dan tercatat; uji lulus termasuk pemulihan setelah tunggu.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); brute force → mitigasi: pembatasan per pengguna + per perangkat + catatan audit.
  - **Verifikasi:** uji SQL + uji fungsi: 6 percobaan salah berurutan → ditolak dengan pesan jelas. · **Bukti 2026-09-16:** `supabase/migrations/0006_pin.sql`, `supabase/functions/verifikasi_pin/index.ts`, `supabase/tes/pin.sql`, `alat/periksa-fungsi-pin.py`. PIN disimpan **hanya sebagai hash** (`crypt(pin, gen_salt('bf', 10))`) dan database **menolak sendiri** nilai yang bukan berbentuk hash lewat batas (CHECK) — dibuktikan uji: perintah menyimpan `123456` ke kolom `pin_hash` **GAGAL**. Pembatasan percobaan: **5 kali salah per akun** dan **12 kali salah per perangkat** dalam 15 menit; uji menempuh lima kali salah berurutan (sisa percobaan tercatat 4→0) lalu **percobaan keenam DITOLAK walau PIN-nya benar**, dengan pesan berbahasa Indonesia yang menyebut “terkunci sementara”; pindah HP **tidak** menembus batas per akun; 12 kali salah dari satu HP (dibagi 3 akun, masing-masing di bawah batas) **mengunci HP itu** tanpa mengunci akun lain. Pemulihan setelah tunggu diuji dengan memundurkan waktu percobaan → PIN benar diterima lagi. Semua percobaan (berhasil maupun gagal, termasuk yang ditolak karena terkunci) **tercatat** di `percobaan_pin` beserta perangkat, dengan RLS: pegawai hanya melihat catatannya sendiri, pemegang izin kelola_pegawai melihat catatan pegawai restonya, dan **tidak ada** jalur menulis langsung dari klien. PIN benar tetapi pegawainya **tidak berizin** untuk aksi itu → tetap ditolak (memakai `boleh_untuk()`); PIN pegawai resto lain / akun nonaktif → “PIN tidak dikenali” tanpa membocorkan apa pun; `ganti_pin` sendiri wajib PIN lama. **Gerbang dibuktikan bisa MERAH lewat 4 uji mutasi** (batas percobaan dimatikan · PIN disimpan mentah · PIN resto lain diterima · izin penyetuju diabaikan) — semuanya GAGAL, LOLOS setelah dipulihkan. Edge Function `verifikasi_pin` sengaja **tipis** (meneruskan ke RPC) dan dijaga pemeriksa baru `alat/periksa-fungsi-pin.py` yang menolak kiriman kode bila muncul `console.*`, `service_role`, atau penjagaan POST hilang (9 pemeriksaan, 3 uji mutasi menyalakan GAGAL) — pemeriksa itu ikut berjalan di CI. **Batas yang jujur:** waktu uji ini, Deno belum tersedia di ruang kerja sehingga **uji runtime Edge Function langsung** (menembak fungsi dengan HTTP sungguhan) menunggu akun Supabase di T0-08; yang terbukti sekarang = seluruh logika PIN di database + penjagaan statis berkas Edge Function. Di Supabase nanti bcrypt **asli** (pgcrypto) yang dipakai dan uji yang sama dijalankan ulang. **Koreksi kejujuran (audit AUD-3 temuan F-11, 2026-09-17):** klaim “dari satu HP tidak bisa jalan” di atas benar untuk penyerang yang **jujur soal nama perangkatnya**. Penyerang yang memutar nama perangkat hanya tertahan **lapis akun** (5×/15 menit); lapis perangkat belum berarti baginya karena namanya dikirim klien. Sudah diukur & dikunci: `supabase/tes/percobaan_pin_perangkat.sql` (memutar nama tidak menambah jatah · lapis perangkat masih hidup saat namanya jujur · 2 uji mutasi memerah). Perbaikan sebenarnya = identitas perangkat terverifikasi di **T1-24 (0012, Fase 1B)**, dengan pagar baris temuan F-11 di `docs/uji/AUDIT_RIWAYAT.md` §1b.

- [x] T1-07 — Migrasi katalog: kategori, menu, varian, tambahan, harga per cabang, stok
  - **Tujuan:** menu bisa berbeda harga per cabang dan penanda habis bekerja lintas layar.
  - **Ref:** TECH_SPEC §4.2 (tabel resmi: `kategori_menu`, `menu_item`, `menu_varian`, `menu_tambahan`, `menu_cabang`, `stok_bahan`, `stok_pergerakan`); PRD M2, M9, M11
  - **File:** `supabase/migrations/0007_katalog.sql`
  - **DoD:** tabel & relasi sesuai TECH_SPEC §4; harga per cabang opsional (bila kosong → pakai harga pusat); RLS + uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** harga berubah mengubah riwayat → mitigasi: transaksi menyimpan `harga_saat_itu` (dibuktikan di T1-09).
  - **Verifikasi:** uji SQL: ubah harga menu → pesanan lama tetap memakai harga tercatat. · **Bukti 2026-09-16 (bagian katalog & stok):** `supabase/migrations/0007_katalog.sql` + `supabase/tes/katalog.sql` + data uji katalog/stok. Tujuh tabel baru (`kategori_menu`, `menu_item`, `menu_varian`, `menu_tambahan`, `menu_cabang`, `stok_bahan`, `stok_pergerakan`) — seluruhnya RLS aktif + berpolicy (**16 tabel** saat itu; hari ini **26 tabel** — perintah: `select count(*) from pg_tables where schemaname = 'public'`, dan uji cakupan RLS otomatis ada di `supabase/tes/rls_semua_tabel.sql`). **Harga per cabang terbukti:** satu fungsi `harga_berlaku(menu, cabang)` — Nasi Goreng 27.000 di Pusat (harga cabang) tetapi 25.000 di Cabang Dua (jatuh ke harga pusat); Kopi 13.000 di Cabang Dua; `menu_cabang.harga` kosong → harga pusat; menu resto lain **tidak bisa diintip** (hasil null). Penanda **habis** bekerja per cabang (Es Teh habis di Pusat, tersedia di Cabang Dua). **Hak berjenjang terbukti:** kasir tidak bisa menambah menu / mengubah harga (harga tetap 25.000 setelah perintahnya dijalankan); admin cabang bisa menambah menu di restonya tetapi **tidak** bisa menyisipkan menu atau harga ke resto lain; admin cabang Pusat **tidak** bisa mengubah harga cabang lain, sedangkan **owner pusat bisa** (13.000 → 14.000) — inilah sebabnya `cabang_pantau_saya()` dibuat: tanpa itu owner pusat tidak melihat harga cabang mana pun karena ia tidak bertugas di kasir. Dapur ber-izin `ubah_stok` boleh **menandai habis** di cabangnya, tetapi **tidak boleh menetapkan/mengubah harga** (dijaga pemicu, termasuk saat menyisipkan baris baru). **Stok tidak bisa menyimpang dari catatannya:** saldo hanya berubah lewat buku besar `stok_pergerakan` (pemicu yang menjumlahkan); menulis `jumlah` langsung **DITOLAK**; buku besar hanya-bertambah (ubah & hapus ditolak haknya); pergerakan untuk bahan resto lain ditolak; `penyewa_id` catatan **diisi otomatis dari bahannya**, dan nilai yang bertentangan ditolak tegas; catatan `koreksi` wajib beralasan; kasir tanpa izin `ubah_stok` tidak bisa mencatat. **Gerbang dibuktikan bisa MERAH lewat 4 uji mutasi** (penjaga saldo stok dimatikan · harga cabang diabaikan · batas cabang dibuka · harga boleh diubah siapa saja) — semuanya GAGAL, LOLOS setelah dipulihkan. **Catatan jujur:** bagian verifikasi “pesanan lama tetap memakai harga tercatat” baru bisa dibuktikan saat tabel pesanan ada (`harga_saat_itu`) pada **T1-09**; yang terbukti di T1-07 adalah harga berlaku per cabang, isolasi antar-resto, dan keutuhan stok.

- [x] T1-08 — Migrasi meja & status meja
  - **Tujuan:** meja bisa dipantau statusnya (kosong/terisi/siap disajikan) dan diatur per cabang.
  - **Ref:** TECH_SPEC §4; PRD M4
  - **File:** `supabase/migrations/0008_meja.sql`
  - **DoD:** meja per cabang + area + status; nomor meja unik per cabang; uji RLS lulus.
  - **Kompleksitas:** sedang (2 jam)
  - **Risiko & mitigasi:** dua pelayan membuka meja sama → mitigasi: dibahas di T3-09 dengan penguncian status.
  - **Verifikasi:** uji SQL menyisipkan meja di 2 cabang, memastikan tidak saling terlihat. · **Bukti 2026-09-16:** `supabase/migrations/0008_meja.sql` + `supabase/tes/meja.sql` + data uji meja di 3 cabang. Meja terpisah per cabang dan **nama meja unik per cabang** — dibuktikan langsung: nama “Meja 5” berhasil dipakai di **dua cabang berbeda**, sedangkan nama yang sama **ditolak** di cabang yang sama; uji mutasi “nama meja dijadikan unik global” menyalakan GAGAL. Status meja hanya dari daftar resmi (`kosong`/`terisi`/`siap`) — nilai lain ditolak database. Kasir Pusat melihat **2 meja** cabangnya dan **0 meja** Cabang Dua serta **0 meja** resto lain; owner pusat melihat meja seluruh cabangnya (4) tetapi tetap 0 dari resto lain; resto lain tidak bisa mengubah status meja Kedai Oasis (status tetap `siap` setelah perintah dijalankan). Hak dibuktikan berjenjang: kasir/pelayan boleh **mengubah status** (keadaan harian) tetapi **tidak boleh menambah atau menghapus meja**; admin cabang boleh menambah di cabangnya dan **tidak** di cabang lain.

- [x] T1-09 — Migrasi pesanan & item (dengan harga_saat_itu) ⚠️
  - **Tujuan:** pesanan tidak bisa berubah arti walau menu/harga diubah kemudian.
  - **Ref:** TECH_SPEC §4 & §9 ART-3/ART-4; PRD M4
  - **File:** `supabase/migrations/0009_pesanan.sql`
  - **DoD:** `pesanan` + `pesanan_item` ada; setiap item menyimpan `harga_saat_itu`, `nama_saat_itu`, catatan khusus; status pesanan memakai daftar resmi; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4) & Kalkulasi (ART-3); mitigasi: enum status + `harga_saat_itu` wajib NOT NULL.
  - **Verifikasi:** uji SQL: ubah harga setelah pesanan dibuat → struk lama tidak berubah. · **Bukti 2026-09-16:** `supabase/migrations/0009_pesanan.sql` + `supabase/tes/pesanan.sql`. Tabel `pesanan` + `pesanan_item` dengan **salinan beku** `nama_saat_itu` & `harga_saat_itu` (WAJIB/NOT NULL). **Inti ART-3 dibuktikan langsung:** harga Nasi Goreng dinaikkan 25.000 → 31.000 (dan harga cabang 27.000 → 33.000) **setelah** pesanan dibuat; pesanan lama tetap tercatat **27.000**, sedangkan `harga_berlaku()` untuk pesanan baru mengembalikan **33.000** — “struk lama tidak berubah” terbukti, bukan diasumsikan. **Salinan beku tidak bisa ditulis ulang:** pemicu menolak perubahan `nama_saat_itu`, `harga_saat_itu`, `menu_item_id`, dan `pesanan_id` (perbaikan salah harga dilakukan dengan membatalkan item lalu menambah baris baru — jalur yang meninggalkan jejak). Item tanpa `harga_saat_itu` **ditolak database**. **Penomoran & idempotensi:** nomor pesanan **unik per cabang per tanggal** (duplikat ditolak), `kunci_idempoten` mencegah satu keranjang tersimpan dua kali walau tombol ditekan ulang. **Konsistensi antar tabel:** meja cabang lain ditolak, pesanan tidak bisa dibuat di cabang lain / untuk resto lain, item tidak bisa memakai menu resto lain, dan status di luar daftar resmi TECH_SPEC §4.3 (`draf`→`dikirim`→`dimasak`→`siap`→`lunas`/`batal`) ditolak. **Pesanan tidak pernah dihapus** — hak hapus memang tidak diberikan (ditolak langsung, bukan disaring); item boleh dibatalkan tanpa menghilangkan barisnya. Isolasi: resto lain melihat 0 pesanan & 0 item; dapur Cabang Dua melihat 0 pesanan cabang Pusat dan tidak bisa memajukan statusnya; owner pusat melihat seluruh pesanan restonya. **Gerbang dibuktikan bisa MERAH lewat 3 uji mutasi** (angka saat itu: dijalankan manual pada 2026-09-16; harness otomatis untuk pagar ini belum ada) (salinan harga ditimpa dari harga menu saat ini · penjaga salinan beku dimatikan · nama meja dijadikan unik global) — semuanya GAGAL, LOLOS setelah dipulihkan. **Catatan jujur:** penomoran otomatis per zona waktu resto & aturan perpindahan status (mesin status) menyusul di **T1-17** dan **T1-18**; T1-09 menyiapkan kolom, kunci unik, dan bukti salinan bekunya.

- [x] T1-10 — Migrasi pembayaran, metode bayar, diskon, pembatalan
  - **Tujuan:** semua uang masuk dan pembatalan tercatat lengkap dengan bukti.
  - **Ref:** TECH_SPEC §4 & §9 ART-3; PRD M6
  - **File:** `supabase/migrations/0010_pembayaran.sql`
  - **DoD:** tabel pembayaran (banyak baris per pesanan), `metode_bayar` (per penyewa), `diskon_transaksi` (jenis, nilai, batas), `pembatalan` (alasan, pelaku, nilai, bahan terbuang); uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3); pembayaran sebagian disalahartikan → mitigasi: aturan "satu pembayaran = satu transaksi tercatat, tidak boleh dobel".
  - **Verifikasi:** uji SQL: diskon melebihi batas → ditolak; pembatalan tanpa alasan → ditolak. · **Bukti 2026-09-16:** `supabase/migrations/0010_pembayaran.sql` + `supabase/tes/pembayaran.sql` + data uji pesanan berisi uang. Empat tabel baru: `pembayaran` (banyak baris per pesanan = pembayaran terbagi), `metode_bayar` (per resto, **4 metode bawaan dipasang otomatis** untuk resto baru), `diskon_transaksi`, `pembatalan` — total **23 tabel saat itu** (hari ini **26 tabel** — angka saat itu 2026-09-16; perintah: `node alat/uji-sql.mjs --daftar`), semuanya RLS + policy. **Angka uang tidak bisa dikarang dari perangkat:** pemicu menolak total/subtotal/pajak/service/diskon yang bukan-nol bila perintah datang dari klien; kasir **ditolak** (“tidak boleh mengubah total pesanan langsung”, total tetap 62.100), sedangkan fungsi peladen **boleh**. **Satu pembayaran = satu baris tercatat:** kunci idempoten sama → ditolak (tidak dobel saat koneksi putus), baris pembayaran **tidak bisa diubah maupun dihapus**, dan total pembayaran **tidak boleh melebihi total pesanan** (50.000 + 20.000 > 62.100 → ditolak). Tunai tanpa uang diterima ditolak, uang diterima lebih kecil dari jumlah ditolak, bukan tunai tanpa referensi ditolak, kembalian **dihitung database** (100.000 − 50.000 = 50.000), dan jenis pembayaran **diambil dari tabel metode bayar**, bukan dari perangkat. **Diskon:** melebihi batas izin kasir (25.000 / 5%) ditolak lewat gerbang `boleh('beri_diskon', nominal, persen)` yang sama (bukan batas yang disalin ulang); diskon **kedua ditolak** selama resto belum mengizinkan tumpuk diskon, dan **boleh** setelah owner menyalakannya; diskon manual tanpa alasan ditolak; total diskon melebihi subtotal ditolak; dapur tidak bisa memberi diskon. **Pembatalan:** alasan kosong ditolak (diuji dengan tahap & penyetuju yang sudah sah supaya penolakannya benar-benar dari aturan alasan), tahap harus cocok dengan keadaan pesanan, pembatalan **setelah dapur mulai wajib disetujui** pengguna berizin, dan nilai kerugian dihitung dari **salinan harga** (54.000). **6 uji mutasi** (batas diskon dimatikan · kelebihan bayar diizinkan · alasan kosong diizinkan · penjaga angka uang dimatikan · referensi non-tunai diabaikan · kembalian tidak dihitung) — semuanya GAGAL saat dirusak, LOLOS setelah dipulihkan. **Dua cacat nyata ditemukan uji sebelum dikirim:** (1) `peran_peladen()` sempat ditulis `SECURITY DEFINER` sehingga `current_user` selalu menjadi pemilik fungsi — penjaganya jadi **buta** dan kasir bisa mengubah total; (2) dua uji saya sendiri **lulus karena sebab yang salah** (kelebihan bayar & alasan kosong ditolak oleh aturan lain) — ditemukan justru oleh uji mutasi nomor 2 & 3, lalu diperbaiki dengan memilih kasus yang hanya bisa ditolak oleh satu sebab.

- [ ] T1-11 — Migrasi kas & shift + printer
  - **Tujuan:** uang kas selalu bisa diaudit (modal, masuk, keluar, hasil hitung, selisih).
  - **Ref:** TECH_SPEC §4 & §9 ART-6; PRD M7
  - **File:** `supabase/migrations/0018_kas_shift.sql`
  - **DoD:** `shift_kas` (buka/tutup, modal, seharusnya, fisik, selisih, alasan) + `kas_pergerakan` + `printer` (per perangkat/cabang); uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); shift menggantung → mitigasi: aturan & pengingat (T7-05).
  - **Verifikasi:** uji SQL: transaksi di luar shift ditolak.

- [ ] T1-12 — Migrasi pelanggan, kampanye voucher, voucher, percobaan voucher ⚠️
  - **Tujuan:** voucher tidak bisa dipakai dua kali dan data pelanggan sesedikit mungkin (privasi).
  - **Ref:** TECH_SPEC §4 (tabel: pelanggan, kampanye_voucher, voucher, voucher_percobaan) & §9 ART-5/ART-10; PRD M10
  - **File:** `supabase/migrations/0019_voucher.sql`
  - **Catatan penutup celah (review putaran11 PR-01, migrasi `0013`):** selama tabel voucher belum ada, diskon `jenis='voucher'` **DITOLAK gagal-aman** (dulu hanya diperiksa izin `pakai_voucher` sehingga kasir bisa mencatat diskon 100% subtotal tanpa voucher). Saat tugas ini mendarat: pasang kunci asing `voucher_id` dan buka kembali jalur itu **hanya** dengan pemeriksaan sungguhan.
  - **DoD:** tabel pelanggan (nama, email, opsi alamat, persetujuan), kampanye (nilai, minimum, batas potongan, masa berlaku, kuota, anggaran, cabang), voucher (kode acak, status), percobaan (log semua cek/scan); indeks unik mencegah dobel; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Voucher (ART-5) & Privasi (ART-10); dobel pakai → mitigasi: kunci unik + transaksi atomik di T1-20.
  - **Verifikasi:** uji SQL: menyisipkan pemakaian kedua ditolak oleh constraint.

- [ ] T1-13 — Migrasi catatan_audit (hanya-tambah) ⚠️
  - **Tujuan:** jejak tindakan sensitif tidak bisa diubah atau dihapus siapa pun.
  - **Ref:** TECH_SPEC §4 & §9 ART-6; PRD M3
  - **File:** `supabase/migrations/0020_catatan_audit.sql`, `supabase/tes/audit.sql`
  - **DoD:** hanya bisa INSERT; UPDATE/DELETE ditolak untuk semua peran (termasuk owner & service role via policy/trigger); uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Audit (ART-6); hapus jejak untuk menutupi kecurangan → mitigasi: larangan di tingkat database, bukan aplikasi.
  - **Verifikasi:** uji SQL: `UPDATE` dan `DELETE` gagal dengan pesan jelas.

- [ ] T1-14 — Migrasi antrean kirim & catatan kesalahan
  - **Tujuan:** pesanan saat internet putus tidak hilang dan masalah bisa diperiksa tanpa menebak.
  - **Ref:** TECH_SPEC §4 & §9 ART-8; PRD §9 (risiko)
  - **File:** `supabase/migrations/0021_antrean_kesalahan.sql`
  - **DoD:** tabel `antrean_kirim` (kunci idempoten unik) + `catatan_kesalahan` (tingkat, kode, konteks) ada; tidak menyimpan sandi/PIN; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Antrean Offline (ART-8); data sensitif tercatat → mitigasi: daftar kolom terbatas + tinjauan manual.
  - **Verifikasi:** uji SQL: dua kiriman dengan kunci sama → hanya satu yang diterima.

- [ ] T1-15 — Fungsi hitung_total() + 12 uji uang ⚠️
  - **Catatan silang (audit D F-06, 2026-09-20):** fungsinya **sudah hidup** di `supabase/migrations/0014_penutup_celah_putaran13.sql` (versi awal, dipakai `0015` bagian 6 untuk pajak/service setelah diskon + pembulatan ke bawah). **JANGAN menulis `hitung_total` kedua** — dua rumus yang berselisih justru pelanggaran ART-3. Sisa pekerjaan tugas ini: membaca `pengaturan.pembulatan` (T1-16) dan **suite 12 uji uang** (sebagian sudah ada di `supabase/tes/urutan_uang.sql`, belum 12).
  - **Tujuan:** satu-satunya tempat menghitung uang, supaya tidak ada dua rumus yang bisa berselisih.
  - **Ref:** TECH_SPEC §5 & §9 ART-3; PRD M6
  - **File:** `supabase/migrations/0022_hitung_total.sql`, `supabase/tes/uang.sql`
  - **DoD:** mengembalikan rincian {subtotal, diskon, pb1, service, pembulatan, total}; 12 kasus lulus (pajak 0%, service 0%, diskon penuh, pembulatan .01, uang pas, uang lebih, void sebagian); tidak ada tipe pecahan untuk nominal; **wajib `SECURITY DEFINER` + `search_path` dipaku + `revoke execute from public` + `grant` hanya `authenticated`/`service_role`** (fungsi istimewa di skema `public` bisa dipanggil semua peran bila haknya tidak dicabut); menulis **kelima kolom uang sekaligus** (celah sementara T1-10 “batas lebih bayar dilewati saat total = 0” **sudah ditutup lebih dulu** di `supabase/migrations/0010_pembayaran.sql:313` + dijaga `supabase/tes/gerbang_uang.sql`; T1-15 tidak perlu menutupnya lagi — kalimat lama yang menjanjikan penutupan di sini **dicabut** karena menyesatkan, temuan review RV-2 putaran8 PR-19).
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3); dua rumus berbeda → mitigasi: klien DILARANG menghitung; semua pemanggilan lewat RPC ini.
  - **Verifikasi:** `supabase test` 12 kasus hijau + bandingkan 3 contoh struk dengan kalkulator manual.

- [ ] T1-16 — Urutan hitungan resmi & aturan pembulatan dari pengaturan ⚠️
  - **Tujuan:** urutan (subtotal → diskon → PB1 → service → pembulatan) tidak bisa ditafsirkan berbeda antar sesi.
  - **Ref:** TECH_SPEC §9 ART-3 & §13 (log keputusan); PRD M2 & M6
  - **File:** `supabase/migrations/0023_urutan_pembulatan.sql`, `supabase/tes/urutan.sql`
  - **DoD:** diskon dihitung dari subtotal; pajak & service dari subtotal setelah diskon; pembulatan sesuai pengaturan (0/100/500); uji lulus dan hasilnya dicatat di `DECISIONS_LOG.md`.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3); urutan salah → selisih kas → mitigasi: uji contoh nyata + satu fungsi sumber.
  - **Verifikasi:** uji SQL dengan 6 kombinasi diskon × pajak × pembulatan.

- [ ] T1-17 — Penomoran pesanan harian per zona waktu penyewa ⚠️
  - **Catatan silang (audit D F-06, 2026-09-20):** penghitungnya **sudah hidup** di `supabase/migrations/0014_penutup_celah_putaran13.sql` (`nomor_pesanan_berikutnya`, disempurnakan `0015` bagian 4 isolasi lintas resto & bagian 10b kunci serialisasi). **JANGAN menulis versi kedua.** Sisa pekerjaan tugas ini: zona waktu penyewa, dan suite `supabase/tes/penomoran.sql` yang dijanjikan.
  - **Tujuan:** nomor pesanan tidak bentrok, termasuk saat tengah malam.
  - **Ref:** TECH_SPEC §9 ART-9; PRD M8 (kasus tepi tengah malam)
  - **File:** `supabase/migrations/0024_penomoran.sql`, `supabase/tes/penomoran.sql`
  - **DoD:** nomor urut per penyewa/cabang/hari memakai zona waktu penyewa; dua pesanan bersamaan tidak dapat nomor sama; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Zona waktu & penomoran (ART-9); balapan bersamaan → mitigasi: urutan di database (bukan di aplikasi).
  - **Verifikasi:** uji SQL membuat 2 pesanan "bersamaan" (transaksi paralel) → nomor berbeda.

- [ ] T1-18 — State machine pesanan + uji transisi ⚠️
  - **Tujuan:** status pesanan hanya bisa berubah lewat jalur yang sah.
  - **Ref:** TECH_SPEC §9 ART-4; PRD M4, M5, M6
  - **File:** `supabase/migrations/0025_state_machine.sql`, `supabase/tes/status.sql`
  - **DoD:** daftar status resmi **persis seperti `TECH_SPEC.md` §4.3** (draf → dikirim → dimasak → siap → lunas; batal) + aturan transisi; transisi terlarang ditolak; uji lulus untuk 6 skenario.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4); status "nyangkut" → mitigasi: aturan + uji + tampilan yang selalu menunjukkan langkah berikutnya.
  - **Verifikasi:** uji SQL menolak 4 transisi terlarang (mis. draf → lunas).

- [ ] T1-19 — RPC cek_voucher (BACA SAJA) ⚠️
  - **Tujuan:** kasir bisa memeriksa voucher tanpa mengubah statusnya sedikit pun.
  - **Ref:** TECH_SPEC §5 & §9 ART-5; PRD M10 · RPC resmi: `pakai_voucher`, `daftar_voucher`
  - **File:** `supabase/migrations/0026_cek_voucher.sql`, `supabase/tes/cek_voucher.sql`
  - **DoD:** fungsi tidak menulis apa pun (dibuktikan uji: status voucher tidak berubah, tidak ada baris baru); mengembalikan alasan gagal yang spesifik; uji lulus.
  - **Tambahan wajib (review putaran11 PR-01 + migrasi `0013`):** T1-19/T1-20 **mengganti** cabang gagal-aman `jenis='voucher'` di `picu_diskon_batas` dengan pemeriksaan nyata (voucher wajib ada, milik resto ini, belum pernah dipakai, nilainya sama dengan diskon yang dicatat) + uji `supabase/tes/diskon_voucher.sql` diperluas (dulu hanya menguji PENOLAKAN). Sampai itu terjadi, membuka kembali jalur voucher tanpa pemeriksaan = regresi K-2 dan akan memerahkan uji mutasi M12.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Voucher (ART-5); "cek" tidak sengaja memakai voucher → mitigasi: hak database hanya SELECT + uji "tidak ada perubahan".
  - **Verifikasi:** uji SQL membandingkan seluruh isi tabel sebelum & sesudah pemanggilan (harus identik).

- [ ] T1-20 — RPC pakai_voucher (atomik, sekali pakai, + PIN) ⚠️
  - **Tujuan:** voucher tidak mungkin terpakai dua kali walau ada dua kasir bersamaan.
  - **Ref:** TECH_SPEC §5 & §9 ART-5; PRD M10
  - **File:** `supabase/migrations/0027_pakai_voucher.sql`, `supabase/tes/pakai_voucher.sql`
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

## Fase 1B — Keamanan akun, perangkat & jejak (⚠️ disisipkan 2026-09-17, dikerjakan SEBELUM T1-11)

> **Kenapa disisipkan:** pemilik (pesan ke-14) meminta keamanan dimatangkan sebelum lanjut. Pola RLS & cara masuk
> dipakai oleh seluruh migrasi/layar berikutnya — kalau T1-11 dilanjutkan dulu, pembongkaran dilakukan dua kali.
> **Nomor migrasi:** penyisipan ini memakai **0011–0016**; rencana lama (kas & shift dst.) digeser **+7** menjadi
> 0018 dst. **Urutan penerapan = urutan tugas di ROADMAP**, bukan urutan nomor berkas rencana lama.
> **Rujukan resmi:** `docs/KEAMANAN.md`; keputusan: `docs/DECISIONS_LOG.md` 2026-09-17.

- [x] T1-23 — Migrasi 0011: peran tunggal + PIN unik & kuat ⚠️
  - **Tujuan:** satu akun hanya punya satu peran (orang dua fungsi = dua akun) dan PIN tidak bisa dipakai dua orang atau dipilih dari pola lemah.
  - **Ref:** TECH_SPEC §4.1 & §9 ART-12; PRD M3 & M12
  - **File:** `supabase/migrations/0011_peran_tunggal.sql`, `supabase/tes/peran_tunggal.sql`
  - **DoD:** `pengguna_cabang` hanya menyimpan daftar cabang; peran tunggal ditegakkan database; PIN wajib 6 digit, **unik antar pegawai**, pola lemah ditolak; uji SQL lulus; matriks peran tidak berubah setelah migrasi.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-12); peran ganda terselundup lewat tabel lain → mitigasi: pemicu penegak + uji & pemeriksa peran tunggal.
  - **Verifikasi:** uji SQL: sisipkan peran kedua untuk satu akun → ditolak · PIN kembar → ditolak · PIN `123456` → ditolak · akun merangkap dua cabang tetap boleh.
  - **Bukti 2026-09-17:** `supabase/migrations/0011_peran_tunggal.sql` (migrasi BARU; 0002/0005 dibekukan) · uji `supabase/tes/peran_tunggal.sql` (baru), `supabase/tes/kredensial_pin.sql` §5, `supabase/tes/pin_batas_pasang.sql` (baru), `supabase/tes/izin.sql` §8 diganti. **Peran tunggal:** kolom `pengguna_cabang.peran` dihapus (peran kedua mustahil disimpan) + penjaga keanggotaan (akun & cabang wajib satu resto; pemilik platform tidak didaftarkan ke cabang) + `izin_efektif()` membaca `pengguna.peran` dan tetap MENOLAK cabang yang bukan tempatnya bertugas. **PIN:** wajib tepat 6 angka; pola lemah ditolak (semua digit sama · deret · blok berulang · pasangan berurutan · bentuk tanggal) lewat fungsi `pin_lemah()`; **unik antar pegawai satu resto** (bukan lintas resto — supaya angka PIN resto lain tidak bocor). **Pembatas anti-oracle (baru, penting):** uji keunikan bisa dipakai menebak PIN kolega, jadi setiap percobaan pemasangan dicatat di tabel `percobaan_simpan_pin` (tidak bisa dibaca klien) dan dibatasi **20 kali / 15 menit**; penolakan kembar & batas dikembalikan sebagai PESAN (bukan error) — sebab `raise exception` membatalkan baris catatannya sendiri di savepoint, sehingga pembatasnya tidak akan pernah menyala (ditemukan saat uji, ditulis di komentar migrasi + DECISIONS_LOG). **Gerbang dibuktikan bisa MERAH lewat 6 uji mutasi:** peran per cabang dihidupkan lagi · keanggotaan cabang diabaikan · pola lemah dimatikan · keunikan dimatikan · pembatas anti-oracle dimatikan · format verifikasi kembali 4–6 angka — semuanya GAGAL, LOLOS setelah dipulihkan (mutasi ke-6 awalnya **lolos** → mengungkap celah uji, lalu uji jalur verifikasi ditambahkan). Hasil: `node alat/uji-sql.mjs` **21 berkas LULUS · 0 GAGAL**; matriks 10 izin × 5 peran tetap utuh.

- [ ] T1-24 — Migrasi 0012: perangkat terdaftar + `perangkat_sah()` + RLS staf diperketat ⚠️
  - **Tujuan:** bagian staf hanya bisa dibuka dari perangkat terdaftar; perangkat curian/hilang mati seketika; perangkat tidak bisa dipakai masuk sebagai peran lain.
  - **Ref:** TECH_SPEC §4.6 & §9 ART-11; PRD M12
  - **File:** `supabase/migrations/0012_perangkat.sql`, `supabase/tes/perangkat.sql`
  - **DoD:** tabel `perangkat`, `kode_pendaftaran_perangkat`, `persetujuan_perangkat` ada; kode sekali pakai 15 menit; rahasia 32 byte disimpan SHA-256; `peran_diizinkan` ditegakkan; fungsi `perangkat_sah()` `stable` + `search_path` dipaku; policy tabel staf memakai `(select public.perangkat_sah())`; RPC `buat_kode_perangkat`, `daftarkan_perangkat`, `setujui_perangkat_pegawai`, `cabut_perangkat`, `daftar_perangkat`; uji SQL lulus.
  - **Kompleksitas:** besar (6 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Akses Perangkat (ART-11); policy salah membuat semua staf terkunci atau justru terbuka → mitigasi: uji dua arah (perangkat sah boleh · tidak sah ditolak) + uji pencabutan seketika; bukti perangkat lewat header **wajib diuji di Supabase nyata** dulu (T0-08), jaring `sesi_perangkat` tetap berlaku.
  - **Verifikasi:** uji SQL: perangkat tidak terdaftar → tabel staf tertutup · cabut perangkat → permintaan berikutnya gagal · "Tablet Kasir" dipakai masuk sebagai owner → ditolak · kode kadaluwarsa/dipakai dua kali → ditolak.
  - **Catatan penomoran (2026-09-19):** nomor yang direncanakan di berkas ini (**`supabase/migrations/0012_perangkat.sql`**) sudah TERPAKAI oleh migrasi penutup temuan audit (`0012`–`0014`) dan sejak 2026-09-19 berkas `0001`–`0014` **DIBEKUKAN** (lihat `docs/DECISIONS_LOG.md`). Pekerjaan ini wajib memakai nomor BARU **`0015_perangkat.sql`** (dan nama berkas menyesuaikan), dijaga `alat/periksa-migrasi-beku.py`.
  - **Tambahan dari audit AUD-3 temuan F-11 (K-3):** `verifikasi_pin` wajib memakai identitas perangkat **terverifikasi** (`perangkat_id`), bukan nama kiriman klien, dan **menolak perangkat tak terdaftar**. Penutupnya: uji `supabase/tes/percobaan_pin_perangkat.sql` **diperketat** — bagian 1 tidak lagi melayani 5 percobaan melainkan **0** (perangkat asing ditolak) — lalu baris temuan F-11 di `docs/uji/AUDIT_RIWAYAT.md` §1b ditandai DITUTUP dengan bukti uji itu. Jangan menutup T1-24 tanpa memperketat ujinya.
  - **Status 2026-09-21 (maraton):** INTI tugas ini sudah mendarat sebagai `supabase/migrations/0018_perangkat_terdaftar.sql` — perangkat terdaftar (`perangkat` + `kredensial_perangkat` bcrypt), `perangkat_sah()` non-callable klien, `daftarkan_perangkat`/`cabut_perangkat` (izin `kelola_pegawai`), `verifikasi_pin` MENOLAK perangkat tak terdaftar dengan jawaban seragam, dan lapis 12×/15 menit di-key pada `perangkat_id`. Uji `supabase/tes/percobaan_pin_perangkat.sql` sudah DIPERKETAT sesuai amanat di bawah (bagian 1 = 0 percobaan, bukan 5); temuan K F-03 & F-11 §1b DITUTUP dengan bukti itu. **Sisa DoD yang masih terbuka:** kode pendaftaran sekali pakai (15 menit) + tabel `persetujuan_perangkat` + penyimpanan rahasia 32 byte SHA-256, dan penutupan "bagian staf hanya dari perangkat terdaftar" yang bergantung sesi perangkat (T1-25) serta UI (Fase 1C) — karena itu kotak tugas ini BELUM dicentang.

- [ ] T1-25 — Migrasi 0013: sesi perangkat, umur maksimum & pencabutan seketika ⚠️
  - **Tujuan:** sesi punya umur jelas, bisa dicabut seketika, dan perangkat yang ditinggal tidak menyimpan akses.
  - **Ref:** TECH_SPEC §4.6 & §9 ART-11; PRD M12
  - **File:** `supabase/migrations/0013_sesi_perangkat.sql`, `supabase/tes/sesi_perangkat.sql`
  - **DoD:** tabel `sesi_perangkat` (+ kunci unik `session_id`); RPC `ikat_sesi_perangkat`, `daftar_sesi`, `cabut_perangkat`, `keluar_semua_perangkat`; umur maksimum (staf 12 jam · admin/owner 30 hari · pemilik platform 8 jam) ditolak di database; sesi perangkat dicabut saat akun nonaktif; uji SQL lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Akses Perangkat (ART-11); token terbit tetap sah sampai kedaluwarsa (batas Supabase) → mitigasi: pemeriksaan sesi di database tiap permintaan + token akses 15 menit.
  - **Catatan penomoran (2026-09-19):** nomor yang direncanakan di berkas ini (**`supabase/migrations/0013_sesi_perangkat.sql`**) sudah TERPAKAI oleh migrasi penutup temuan audit (`0012`–`0014`) dan sejak 2026-09-19 berkas `0001`–`0014` **DIBEKUKAN** (lihat `docs/DECISIONS_LOG.md`). Pekerjaan ini wajib memakai nomor BARU **`0016_sesi_perangkat.sql`** (dan nama berkas menyesuaikan), dijaga `alat/periksa-migrasi-beku.py`.
  - **Verifikasi:** uji SQL: sesi lewat umur → ditolak · dicabut → ditolak pada permintaan berikutnya · sesi akun nonaktif → ditolak · `session_id` ganda → ditolak.

- [ ] T1-26 — Migrasi 0014: percobaan masuk + kunci 5×/15 menit (akun) & 12×/15 menit (perangkat) ⚠️
  - **Tujuan:** PIN tidak bisa ditebak walau dari perangkat terdaftar.
  - **Ref:** TECH_SPEC §4.6 & §9 ART-12; PRD M12
  - **File:** `supabase/migrations/0014_percobaan_masuk.sql`, `supabase/tes/percobaan_masuk.sql`
  - **DoD:** tabel `percobaan_masuk` mencatat semua percobaan (berhasil/gagal/diblokir); kunci dua lapis berlaku; percobaan yang ditolak karena terkunci tetap dihitung; percobaan gagal memicu pemberitahuan ke owner; uji SQL lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Catatan penomoran (2026-09-19):** nomor yang direncanakan di berkas ini (**`supabase/migrations/0014_percobaan_masuk.sql`**) sudah TERPAKAI oleh migrasi penutup temuan audit (`0012`–`0014`) dan sejak 2026-09-19 berkas `0001`–`0014` **DIBEKUKAN** (lihat `docs/DECISIONS_LOG.md`). Pekerjaan ini wajib memakai nomor BARU **`0017_percobaan_masuk.sql`** (dan nama berkas menyesuaikan), dijaga `alat/periksa-migrasi-beku.py`.
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Keamanan Akun (ART-12); kunci terlalu ketat membuat kasir tidak bisa kerja di jam sibuk → mitigasi: nilai dapat diatur owner + pesan jelas + penghitung mundur di layar.
  - **Verifikasi:** uji SQL: 6 kali salah → ditolak walau PIN benar · 12 kali salah dari satu perangkat (dibagi beberapa akun) → perangkat terkunci · pemulihan setelah 15 menit.

- [ ] T1-27 — Migrasi 0015: `catatan_audit` hanya-tambah + rantai hash ⚠️
  - **Tujuan:** jejak audit tidak bisa diubah/dihapus, dan perubahan langsung di database pun bisa dideteksi.
  - **Ref:** TECH_SPEC §4.3 & §9 ART-13; PRD M12
  - **File:** `supabase/migrations/0015_audit.sql`, `supabase/tes/audit.sql`, `alat/periksa-audit.py`
  - **DoD:** tabel `catatan_audit` ada tanpa hak ubah/hapus; `hash_sebelumnya` & `hash_baris` dihitung pemicu (aman untuk penyisipan bersamaan); pemeriksa rantai menunjuk baris pertama yang putus; audit ditulis oleh perubahan izin, PIN, perangkat, mode dukungan; uji SQL lulus.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Jejak Audit (ART-13); rantai bercabang saat dua penulisan bersamaan → mitigasi: kunci baris terakhir saat pemicu berjalan + uji dua transaksi.
  - **Verifikasi:** uji SQL + pemeriksa: ubah satu baris → pemeriksa menunjuk baris itu; hapus satu baris → putus terdeteksi; audit tidak bisa diubah/dihapus oleh peran mana pun.

- [ ] T1-28 — Migrasi 0016: mode dukungan pemilik platform (beralasan, berbatas waktu, tercatat) ⚠️
  - **Tujuan:** pemilik platform tetap bisa menolong tanpa pernah mengintip data penyewa diam-diam.
  - **Ref:** TECH_SPEC §9 ART-15; PRD §9 & M12
  - **File:** `supabase/migrations/0016_mode_dukungan.sql`, `supabase/tes/mode_dukungan.sql`
  - **DoD:** RPC `mode_dukungan` (alasan wajib, bawaan 60 menit, hanya-baca); policy membedakan pemilik platform biasa vs mode aktif; berakhir otomatis (pg_cron) & saat keluar; catatan audit + pemberitahuan ke owner penyewa; uji SQL lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Akses Lintas Penyewa (ART-15); mode lupa ditutup → data terbuka lebih lama → mitigasi: kedaluwarsa otomatis + pemeriksa berkala.
  - **Verifikasi:** uji SQL: tanpa mode → 0 baris · dengan mode → tulis ditolak · setelah kedaluwarsa → 0 baris lagi · catatan audit & pemberitahuan ada.

- [ ] T1-29 — Uji matriks peran × aksi (otomatis, semua peran) ⚠️
  - **Tujuan:** setiap peran terbukti boleh/tidak boleh untuk setiap aksi — bukan sampel.
  - **Ref:** TECH_SPEC §8 & §11; AGENT_OPERATING_GUIDE §5
  - **File:** `supabase/tes/matriks_izin.sql`, `supabase/tes/matriks_staf.sql`
  - **DoD:** matriks dibuat dari daftar izin & peran (bukan ditulis satu per satu); 6 peran × semua aksi RPC diperiksa; peran tanpa izin **ditolak walau RPC dipanggil langsung**; laporan matriks tercetak di log CI; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-12) & RLS (ART-1); matriks basi saat aksi baru ditambah → mitigasi: daftar aksi diambil dari registri + pemeriksa CI.
  - **Verifikasi:** uji SQL mutasi: longgarkan satu izin → matriks GAGAL; kembalikan → LOLOS.

- [ ] T1-30 — Pemeriksa keamanan SQL + rahasia + dependensi di CI ⚠️
  - **Tujuan:** aturan keamanan yang mudah terlupa diperiksa mesin, bukan ingatan.
  - **Ref:** TECH_SPEC §8 & §11; docs/KEAMANAN.md §16
  - **File:** `alat/periksa-keamanan-sql.py`, `alat/periksa-rahasia.py`, `.github/workflows/ci.yml`
  - **DoD:** pemeriksa menolak: fungsi `SECURITY DEFINER` tanpa `search_path` · tanpa `revoke execute from public` · tabel baru tanpa RLS/policy · policy tanpa `(select …)` untuk fungsi · berkas `.env`/kunci di repo; `npm audit` dijalankan; ketiganya di CI; dibuktikan bisa MERAH.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: RLS (ART-1) & Fungsi Istimewa (ART-11); pemeriksa terlalu longgar = hijau palsu → mitigasi: uji mutasi wajib (matikan satu aturan → pemeriksa GAGAL).
  - **Verifikasi:** jalankan pemeriksa dengan sengaja menyisipkan cacat → GAGAL; setelah dipulihkan → LOLOS; dijalankan di CI.

- [ ] T1-36 — Kunci induk: kode pemulihan darurat + pendaftaran perangkat darurat ⚠️
  - **Tujuan:** kehilangan perangkat owner/admin (bahkan seluruhnya) tidak menghentikan kedai, tanpa membuka pintu belakang yang lebih lemah daripada masuk biasa.
  - **Ref:** TECH_SPEC §9 ART-11 & §5.1; docs/KEAMANAN.md §4b; PRD M12
  - **File:** `supabase/migrations/0016b_pemulihan_perangkat.sql`, `supabase/tes/pemulihan.sql`, `docs/ops/PEMULIHAN_PERANGKAT.md`
  - **DoD:** RPC `buat_kode_pemulihan` (8 kata acak sekali pakai, hanya hash tersimpan, dibuat saat penyiapan), `pulihkan_perangkat` (wajib kode + kata sandi + TOTP → perangkat darurat dengan **masa tenggang 30 menit**), `batalkan_pemulihan`; **kode pemulihan hanya boleh dipakai `owner_pusat`**; kode dibuat sekali saat penyiapan dengan **penyimpanan amplop tersegel dua salinan** (rumah pemilik + arsip kantor di luar ruang kasir) + rotasi setelah dipakai/tahunan; pemberitahuan email + Peringatan dalam aplikasi; peringatan bila perangkat berkuasa tinggal 1; sakelar penghentian jalur pemulihan; langkah pemulihan pemilik platform ditulis di `docs/ops/`; uji SQL + uji mutasi lulus.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Akses Perangkat (ART-11); kode pemulihan dicuri/difoto orang lain → mitigasi: hanya hash, sekali pakai, wajib kata sandi + TOTP, masa tenggang 30 menit + pemberitahuan + bisa dibatalkan + tercatat; dilarang menyimpan kode di ponsel/chat.
  - **Verifikasi:** uji SQL: kode salah/kadaluwarsa/terpakai dua kali → ditolak · perangkat darurat belum bisa dipakai sebelum 30 menit · dibatalkan dari perangkat lain → batal · semua kejadian tercatat & dalam ringkasan harian.
  - **Catatan nomor:** ditambahkan setelah Fase 1C disisipkan (2026-09-17), karena itu bernomor T1-36; pengerjaannya **bersama T1-24/T1-25** (bukan di akhir).

- [ ] T1-37 — Pekerjaan ulang artefak lama yang dibatalkan keputusan keamanan ⚠️
  - **Tujuan:** membereskan pekerjaan T1-01…T1-10 yang bertentangan dengan aturan baru (satu akun satu peran · perangkat terdaftar · percobaan masuk) — dikerjakan lewat migrasi BARU, bukan menyunting migrasi lama.
  - **Ref:** `docs/uji/DAFTAR_PEKERJAAN_ULANG.md` (hasil AUD-0) · TECH_SPEC §4.1 & §9 ART-11/ART-12; PRD M12
  - **File:** `supabase/migrations/0011_peran_tunggal.sql`, `supabase/tes/peran_tunggal.sql`, `supabase/tes/izin.sql`, `alat/sql/data-uji.sql`, `supabase/tes/pin.sql`
  - **DoD:** butir B.1–B.9 daftar kerja ulang selesai: `pengguna_cabang.peran` dibongkar lewat 0011 · `izin_efektif()` ditulis ulang membaca `pengguna.peran` · uji `tes/izin.sql` §8 (peran berbeda per cabang) diganti uji peran tunggal · fixture perangkat ditambahkan · uji lama yang mengasumsikan peran per cabang tidak ada lagi; seluruh uji lulus.
  - **Catatan kemajuan 2026-09-17:** **B.1–B.3 SELESAI** lewat migrasi 0011 (T1-23 `[x]`) — peran per cabang dibongkar, `izin_efektif()` ditulis ulang, uji `izin.sql` §8 diganti uji peran tunggal. Sisa **B.4–B.9** memang milik T1-24/T1-25/T1-26 (perangkat terdaftar, sesi, percobaan masuk, fixture perangkat); tugas ini baru boleh `[x]` setelah semuanya mendarat.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-12) & RLS (ART-1); membongkar kolom yang dipakai fungsi izin bisa membuat semua peran kehilangan izin → mitigasi: matriks 10 izin × 5 peran dijalankan ulang sebelum & sesudah, dan uji mutasi membuktikan gerbang izin masih bisa MERAH.
  - **Verifikasi:** `node alat/uji-sql.mjs` 12 berkas LULUS · matriks izin utuh (kasir tetap tidak boleh apa yang tadinya tidak boleh) · `python3 alat/periksa-roadmap.py` LOLOS.

- [ ] T1-38 — Audit independen AUD-2 atas Fase 1B + bukti ulang pekerjaan lama ⚠️
  - **Tujuan:** sebelum kembali ke T1-11, seluruh pekerjaan keamanan (dan pekerjaan lama yang sudah diulang) diperiksa sesi auditor independen dengan kalibrasi cacat tanaman.
  - **Ref:** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §2 & §6; AGENT_OPERATING_GUIDE §5
  - **File:** `docs/uji/paket-audit/AUD-2-<tanggal>.md`, `docs/uji/audit/LAPORAN_AUD-2_<tanggal>_keamanan.md`, `docs/uji/AUDIT_RIWAYAT.md`
  - **DoD:** paket audit dibuat mesin; auditor **sesi & model berbeda** menjalankan lensa L1/L3/L4 (+L2 untuk uang) · laporan LOLOS `--periksa-laporan` · kalibrasi cacat tanaman dijalankan & tingkat deteksi dicatat · semua temuan K-1/K-2 ditutup atau fase DIHENTIKAN; verdict tercatat di `docs/uji/AUDIT_RIWAYAT.md`.
  - **Kompleksitas:** besar (4 jam, termasuk perbaikan temuan)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: seluruh kontrol keamanan; auditor malas/hijau palsu → mitigasi: kalibrasi cacat tanaman + pemeriksa laporan mesin + syarat "temuan wajib punya perintah bukti".
  - **Verifikasi:** laporan audit LOLOS kontrak · tingkat deteksi kalibrasi ≥ 70% dengan semua K-1/K-2 ditemukan · nol temuan K-1/K-2 terbuka sebelum `[x]`.

## Fase 1C — Kontrak UI & peta aksi (⚠️ disisipkan 2026-09-17, dikerjakan SEBELUM layar pertama Fase 3)

> **Kenapa disisipkan:** pengalaman pemilik pada proyek sebelumnya — banyak tombol kurang dan fungsi "katanya ada"
> tetapi tidak bisa dipakai, walau dokumen fondasi detail. Sebabnya: tidak ada daftar tombol, tidak ada uji
> pemanggilan, dan "selesai" berarti "kode ditulis". Fase ini membuat ketiganya **tidak mungkin** terjadi.
> **Rujukan:** `docs/SPESIFIKASI_UI.md`, `docs/PETA_UI.md` (hasil generate), keputusan `DECISIONS_LOG.md` 2026-09-17.

- [ ] T1-31 — Peta Layar + kontrak layar (template & pengisian awal) ⚠️
  - **Tujuan:** setiap layar punya janji tertulis sebelum dikoding: untuk siapa, jalan masuk, data, aksi, dan **7 keadaan wajib**.
  - **Ref:** docs/SPESIFIKASI_UI.md §3 & §4; AGENT_OPERATING_GUIDE §7
  - **File:** `aplikasi/src/lib/layar.ts`, `docs/SPESIFIKASI_UI.md`, `docs/PETA_UI.md`
  - **DoD:** registri layar (id, rute, peran, izin, 7 keadaan) ada; kontrak layar diisi untuk layar contoh + kerangka layar masuk; peta peran → layar ditulis; pemeriksa `alat/peta-ui.py` mengenali registri.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kelengkapan UI; layar ditambah tanpa kontrak → mitigasi: pemeriksa CI menolak layar tanpa berkas/kontrak.
  - **Verifikasi:** jalankan `python3 alat/peta-ui.py --periksa` → LOLOS; hapus satu kontrak layar → GAGAL.

- [ ] T1-32 — Registri Aksi + komponen `TombolAksi` (satu sumber kebenaran tombol) ⚠️
  - **Tujuan:** tidak ada tombol tanpa entri; izin, konfirmasi, PIN, pesan, dan uji tercatat di satu tempat.
  - **Ref:** docs/SPESIFIKASI_UI.md §2; AGENT_OPERATING_GUIDE §7
  - **File:** `aplikasi/src/lib/aksi.ts`, `aplikasi/src/komponen/TombolAksi.tsx`, `aplikasi/src/komponen/TombolAksi.test.tsx`
  - **DoD:** entri aksi memuat id, label, layar, peran, izin, RPC, jenis, konfirmasi, butuh-PIN, pesan sukses/gagal, uji; `TombolAksi` menolak id tak dikenal (gagal saat pembangunan); peran tanpa izin → disembunyikan/nonaktif + alasan; uji komponen lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kelengkapan UI; komponen lama memakai tombol mentah → mitigasi: pemeriksa statis menolak `<button` di luar `TombolAksi` pada folder layar.
  - **Verifikasi:** uji komponen: klik aksi → RPC tiruan terpanggil dengan argumen benar; aksi tanpa uji → pemeriksa GAGAL.

- [ ] T1-33 — Pemeriksa peta aksi/layar + jejak fitur M1–M12 (CI) ⚠️
  - **Tujuan:** dokumen tidak bisa basi dan tidak ada aksi/layar/fitur yang lepas dari jejak.
  - **Ref:** docs/SPESIFIKASI_UI.md §5; docs/PRD.md M1–M12
  - **File:** `alat/peta-ui.py`, `.github/workflows/ci.yml`, `docs/PETA_UI.md`
  - **DoD:** CI gagal bila: RPC aksi tidak ada di migrasi · kode izin tidak ada · aksi tanpa uji · layar tanpa berkas/rute · `docs/PETA_UI.md` berbeda dari hasil generate · fitur PRD M1–M12 tanpa layar/aksi; dibuktikan bisa MERAH untuk keenam sebab.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kelengkapan UI; pemeriksa hijau palsu → mitigasi: enam uji mutasi (satu per sebab) dijalankan dan dilaporkan.
  - **Verifikasi:** `python3 alat/peta-ui.py --periksa` di CI + enam uji mutasi MERAH.

- [ ] T1-34 — Harness uji komponen per layar (jsdom + Testing Library) + DoD UI ⚠️
  - **Tujuan:** setiap tombol dibuktikan benar-benar memanggil fungsi yang benar, sesuai peran, dengan 7 keadaan.
  - **Ref:** AGENT_OPERATING_GUIDE §5 & §7; docs/SPESIFIKASI_UI.md §6
  - **File:** `aplikasi/src/uji/harness.tsx`, `aplikasi/src/uji/harness.test.tsx`, `docs/AGENT_OPERATING_GUIDE.md`
  - **DoD:** harness menyediakan data contoh + tiruan RPC + konteks peran; uji contoh membuktikan aksi berizin terpanggil, aksi terlarang tidak ada, keadaan kosong/memuat/gagal/antrean tampil; DoD UI ditulis di panduan; `npm test` lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kelengkapan UI; uji yang hanya memeriksa tampilan (bukan pemanggilan) → mitigasi: aturan "tiap aksi wajib ada uji pemanggilan" + pemeriksa peta aksi.
  - **Verifikasi:** `npm test` + mutasi: alihkan satu aksi ke RPC salah → uji GAGAL.

- [ ] T1-35 — Naskah jalan pemilik bernomor (`W-<fase>-<nomor>`) + aturan bukti pratinjau ⚠️
  - **Tujuan:** setiap fitur bisa diuji pemilik sendiri di pratinjau, langkah demi langkah, sebelum dianggap selesai.
  - **Ref:** docs/SPESIFIKASI_UI.md §7; AGENT_OPERATING_GUIDE §7
  - **File:** `docs/uji/NASKAH_JALAN.md`, `docs/SPESIFIKASI_UI.md`
  - **DoD:** format naskah (langkah, hasil yang harus muncul, kode) ditulis; tugas Fase 1B & layar contoh punya naskahnya; setiap tugas UI di ROADMAP wajib menyebut nomor naskah di DoD-nya; pratinjau menyala dengan data contoh.
  - **Kompleksitas:** sedang (2 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kelengkapan UI; naskah dianggap cukup tanpa dijalankan → mitigasi: aturan "naskah dijalankan sebelum `[x]`" + bukti di ROADMAP.
  - **Verifikasi:** jalankan 3 langkah pertama naskah di pratinjau → hasil sesuai; pemeriksa menolak tugas UI tanpa nomor naskah.

---

- [ ] T1-39 — Isi PETA_UI untuk SEMUA layar G1 (kontrak + registri aksi) ⚠️
  - **Tujuan:** menutup celah yang ditemukan Lee — *"banyak tombol yang kurang, fungsi yang katanya ada tapi ga bisa dipake"*: isi **setiap** layar (daftar tombol, aksi, keadaan, masuk-dari-mana, keluar-ke-mana, perilaku & gerakan) ditulis lebih dulu sebagai data, bukan diserahkan ke ingatan saat mengoding.
  - **Ref:** `docs/SPESIFIKASI_UI.md` §2–§4 & **§9 (perilaku & gerakan, baru)**; pesan Lee ke-14 & putaran 5 (`docs/teknis/REKAM_PESAN_PEMILIK.md` §6)
  - **File:** `docs/PETA_UI.md` · `aplikasi/src/lib/layar.ts` · `aplikasi/src/lib/aksi.ts` · `alat/peta-ui.py`
  - **DoD:** setiap layar G1 punya baris kontrak lengkap (id · rute · tujuan · peran · masuk dari mana · data · daftar aksi · 8 keadaan §9.1 · aturan tampilan · berkas uji · nomor naskah jalan); setiap aksi punya entri Registri Aksi lengkap (nama · RPC/tabel · peran yang boleh · syarat · umpan balik · akibat gagal); pemeriksa `alat/peta-ui.py` **hijau** dan **terbukti bisa MERAH** (sengaja hapus satu aksi → MERAH).
  - **Kompleksitas:** besar (4 jam, dikerjakan bersama T1-31/T1-32)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` bila pola kontrak berubah; risiko daftar layar G1 tidak lengkap → mitigasi: diambil dari `docs/ROADMAP.md` Fase 3–9 (per fase ada daftar layar) + uji silang pemeriksa.
  - **Verifikasi:** `python3 alat/peta-ui.py` LOLOS · uji mutasi MERAH saat satu aksi/tombol dihapus · naskah jalan tiap layar bisa dijalankan Lee.

- [ ] T1-40 — Kerangka bahasa (i18n): teks tidak boleh ditulis di layar
  - **Tujuan:** aplikasi mendukung banyak bahasa tanpa menyentuh logika — keputusan Lee 2026-09-17 (**Opsi 1**): rilis G1 memakai **Indonesia · Inggris · Mandarin**; **Arab** disiapkan kuncinya + tata letak RTL diuji di G1, teksnya menyusul G2.
  - **Ref:** `docs/DECISIONS_LOG.md` «Bahasa aplikasi» · `docs/SPESIFIKASI_UI.md` §10 (bahasa & arah teks)
  - **File:** `aplikasi/src/bahasa/id.ts` (sumber) · `en.ts` · `zh.ts` · `ar.ts` (kunci saja) · `aplikasi/src/bahasa/index.ts` · pengalih bahasa di `docs/PETA_UI.md` · `aplikasi/alat/periksa-bahasa.py`
  - **DoD:** setiap kalimat UI diambil dari berkas bahasa (tidak ada teks keras di komponen — pemeriksa menolak, bukan mengimbau); pilihan bahasa per pengguna + bawaan per resto untuk perangkat bersama; format uang & tanggal tetap Indonesia (`Rp`, `id-ID`) di SEMUA bahasa; kunci yang hilang di satu bahasa = CI merah; pemeriksa **terbukti bisa MERAH** (sengaja hapus satu kunci → MERAH).
  - **Kompleksitas:** sedang (2–3 jam, sebelum layar G1 pertama ditulis)
  - **Risiko & mitigasi:** ⚠️ teks keras yang lolos sekali akan mahal dibereskan → pemeriksa di CI sejak commit pertama; risiko terjemahan salah arti di menu keuangan → istilah baku ditinjau Lee sebelum dipakai.
  - **Verifikasi:** `python3 aplikasi/alat/periksa-bahasa.py` LOLOS di CI · uji mutasi MERAH · tiga bahasa berpindah tanpa memuat ulang (layar contoh) · angka & tanggal tidak berubah antar bahasa.

- [ ] T1-41 — Arah teks (RTL) & huruf Mandarin/Arab
  - **Tujuan:** memastikan tata letak siap Arab sejak awal (bukan tambalan belakangan) dan huruf Mandarin tidak memberatkan perangkat kedai.
  - **Ref:** `docs/DECISIONS_LOG.md` «Bahasa aplikasi» (Opsi 1) · `docs/SPESIFIKASI_UI.md` §10
  - **File:** `prototipe/` (2 layar contoh bercermin) · `aplikasi/src/gaya/arah.css` (token arah, logis `inline-start/end`) · berkas huruf Mandarin terpotong (subset) · `aplikasi/alat/periksa-arah.py`
  - **DoD:** dua layar contoh tampil benar saat arah dibalik (RTL) tanpa mengubah kode layar (hanya token arah); tabel & keranjang tidak rusak; ukuran berkas huruf Mandarin di bawah ambang yang ditetapkan (diperiksa otomatis); pemeriksa **terbukti bisa MERAH**.
  - **Kompleksitas:** sedang (2–3 jam)
  - **Risiko & mitigasi:** ⚠️ RTL menyentuh hampir semua tata letak → dikerjakan **sebelum** layar G1 diperbanyak, dengan 2 layar contoh sebagai bukti; huruf Mandarin besar → wajib subset + ambang ukuran diperiksa mesin.
  - **Verifikasi:** 2 layar contoh RTL benar · pemeriksa arah & ukuran huruf LOLOS (uji mutasi MERAH) · dalamnya tetap hijau: kontras 166 lolos · halaman prototipe 183/183.

- [ ] T1-42 — Bantuan kontekstual di SETIAP laman (tanda "?" + isi bantuan dijaga mesin)
  - **Tujuan:** pegawai baru bisa memakai setiap laman tanpa harus mengingat sosialisasi — bantuan singkat muncul di tempat kerja, bukan di buku terpisah. (Permintaan Lee 2026-09-17.)
  - **Ref:** permintaan Lee 2026-09-17 (`docs/teknis/REKAM_PESAN_PEMILIK.md` §9) · `docs/SPESIFIKASI_UI.md` §11 · ART-13 (kontrak layar)
  - **File:** `docs/SPESIFIKASI_UI.md` §11 · `aplikasi/src/kontrak/bantuan.ts` · `aplikasi/src/komponen/LembarBantuan.tsx` · `alat/periksa-bantuan.py`
  - **DoD:** setiap layar di registri punya tanda "?"; isi bantuan satu sumber dengan registri aksi (1–2 kalimat + maksimal 5 langkah + "kalau macet" + siapa yang boleh memakai); petunjuk pertama kali muncul sekali per perangkat lalu bisa ditutup permanen; teks tersedia dalam 3 bahasa lewat kerangka T1-40; ada 1 halaman ringkas per peran untuk dicetak.
  - **Kompleksitas:** sedang (3–4 jam)
  - **Risiko & mitigasi:** bantuan basi (dokumen tumbuh, kode berubah) → pemeriksa wajib memastikan setiap aksi di registri punya bantuan **dan** setiap teks bantuan menunjuk aksi/layar yang ada (uji mutasi MERAH); bantuan terlalu panjang → batas 5 langkah, selebihnya materi pelatihan.
  - **Verifikasi:** `alat/periksa-bantuan.py` LOLOS + uji mutasi MERAH (hapus bantuan satu aksi → GAGAL) · uji komponen: "?" membuka & menutup tanpa menghalangi pekerjaan · tangkapan layar 3 tema.

- [ ] T1-43 — Buku Uji Pemilik (lembar uji bertahap + kolom hasil + gema di chat)
  - **Tujuan:** Lee punya SATU lembar kerja untuk mencoba & menilai sendiri hal-hal yang memang harus dinilai manusia — ditulis bertahap mengikuti jalannya proyek (bukan dibuat di akhir), dengan kolom "sudah dilakukan? hasilnya?"; setiap baris baru juga ditampilkan di chat supaya Lee tidak perlu mencari berkas.
  - **Ref:** permintaan Lee 2026-09-17 (`docs/teknis/REKAM_PESAN_PEMILIK.md` §9) · `PANDUAN_PENGGUNA.md` Bagian B · `docs/AGENT_OPERATING_GUIDE.md`
  - **File:** `docs/uji/BUKU_UJI_PEMILIK.md` · `alat/periksa-buku-uji.py` · `alat/tambah-uji.py`
  - **DoD:** buku punya dua bagian tetap — (1) yang harus Lee **lakukan** (mis. penyiapan Supabase, keputusan biaya) dan (2) yang harus Lee **coba**; tiap baris wajib punya langkah (maksimal 5), "yang seharusnya terjadi", kotak hasil (OK/gagal), dan catatan; setiap tugas ROADMAP yang DoD-nya menyebut uji pemilik punya minimal satu baris; aturan menulis: baris ditambahkan **bersamaan** pekerjaan itu selesai, dan diringkas di chat batch yang sama.
  - **Kompleksitas:** sedang (2–3 jam)
  - **Risiko & mitigasi:** buku jadi daftar raksasa yang tidak diisi → satu baris = satu hal, maksimal 5 langkah, peta cepat di atas + penanda "sejak kapan menunggu diisi"; buku dianggap pengganti uji mesin → ditulis tegas di kepala buku: uji mesin tetap di CI, buku ini hanya untuk yang butuh mata manusia.
  - **Verifikasi:** `alat/periksa-buku-uji.py` LOLOS + uji mutasi MERAH (hapus langkah · hapus harapan · rusak kotak hasil → GAGAL) · 3 baris pertama benar-benar dikerjakan Lee (pratinjau desain · jalankan pemeriksaan · jalankan sesi review PR) dan hasilnya tercatat.

- [ ] T1-44 — Perketat mekanisme paket audit & review (lingkup dari commit target + CI wajib hijau)
  - **Tujuan:** menutup tiga temuan mekanisme sekaligus (B F-09, B F-16, B F-17): paket selalu menunjuk commit yang benar, memuat lingkup beserta hitungan yang dibuat mesin (termasuk berkas paket itu sendiri), dan tidak pernah menyuruh auditor memeriksa commit yang belum pernah lewat CI.
  - **Ref:** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §5b–§5c · `docs/uji/AUDIT_RIWAYAT.md` §1b · `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` §RV-1
  - **File:** `alat/audit-independen.py` · `alat/review-pr.py` · `docs/uji/paket-audit/` · `docs/uji/review-pr/`
  - **DoD:** daftar lingkup dihitung dari **pohon commit target** (bukan meja kerja sesi), dengan penanda eksplisit untuk berkas paket sendiri; angka tiap grup dihitung mesin; pembuatan paket **ditolak** bila CI commit target bukan hijau (atau tidak ada run-nya).
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** lingkungan tanpa `gh`/GitHub membuat paket tidak bisa dibuat → sediakan `--tanpa-ci` yang **mencatat jujur** "CI belum diperiksa" di kepala paket (bukan lolos diam-diam); hitungan dari pohon commit bisa berbeda dari meja kerja → perbedaan itu justru yang dicari.
  - **Verifikasi:** 3 uji mutasi pada salinan (lingkup diambil dari meja kerja → GAGAL · angka grup ditulis tangan → GAGAL · CI merah/tanpa run → paket ditolak) · paket berikutnya dibuat dengan mekanisme baru dan tetap bisa ditarik lewat `--ambil-laporan`.

- [ ] T1-45 — Penutupan temuan putaran verifikasi 2026-09-19 + AUD-3 2026-09-20 (43 temuan NYATA: AUD-3 D + review PR putaran16 + AUD-3 F; **+ 31 temuan dua laporan lanjutan 2026-09-20** — laporan H sesi `01a0bbcb` dan laporan I ronde kedua `01a0bbd2`, sudah terdaftar di daftar penutup §1d/§1e `docs/uji/AUDIT_RIWAYAT.md`) ⚠️
  - **Tujuan:** menutup seluruh temuan yang ditemukan dua peninjau independen pada commit `93a50ba` dan sudah **dibantah-balik dengan probe sendiri** di sesi kerja — 1 temuan K-1 (penanda transaksi bisa dipalsukan kasir), 5 K-2 (diskon pada pesanan lunas · void satu item membatalkan seluruh pesanan · kebocoran hitungan lintas resto · oracle PIN kembar · kunci kalibrasi di dalam repo), sisanya K-3/K-4 (izin & jejak, PIN warisan, gerbang CI gagal-terbuka, grant, tautan meja, dsb.).
  - **Ref:** `docs/uji/AUDIT_RIWAYAT.md` §1b & §1c · `docs/uji/REVIEW_PR_RIWAYAT.md` §1b · `docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md` · `docs/KEAMANAN.md` §1
  - **File:** `supabase/migrations/0015_penutup_celah_putaran16.sql`, `supabase/tes/`, `alat/periksa-gerbang-ci.py`, `alat/audit-independen.py`, `alat/lanjut-sesi.py`
  - **DoD:** setiap temuan punya uji regresi yang bisa MERAH (mutasi) dan tercatat DITUTUP dengan bukti hidup; tanpa menyisakan satu pun temuan terbuka tanpa pemilik.
  - **Kompleksitas:** besar (6 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: keamanan uang & jejak; menyentuh pemicu pembatalan/diskon/PIN → setiap perubahan diuji ulang suite penuh + mutasi; perubahan yang mengubah aturan (mis. cara membuktikan persetujuan) dicatat sebagai keputusan, bukan tambalan.
  - **Progres 2026-09-20 (pendaftaran laporan audit lanjutan) — DUA LAPORAN AUDIT BARU MASUK & TERDAFTAR:** sesi auditor `arena/01a0bbcb` (**laporan H**, 10 temuan, kalibrasi 12/12) dan ronde kedua sesi `arena/01a0bbd2` (**laporan I**, 21 temuan, kalibrasi 5/5, cakupan 442/480) mengaudit commit `4830b5a`. Laporan I **LOLOS KONTRAK**; laporan H **DITOLAK MESIN** karena kelengkapan format (label grup cakupan diparafrase) tetapi **isinya tetap dipakai** sesuai aturan proyek (format ditolak ≠ temuan hilang). Keduanya sudah masuk `alat/periksa-temuan-audit.py` (kunci H & I; ringkasan alat kini data-driven) dan **seluruh 31 temuan punya baris penutup** di §1d/§1e `docs/uji/AUDIT_RIWAYAT.md` (2 di antaranya sudah DITUTUP karena perbaikannya mendarat sesudah commit yang diaudit: urutan uang F-01 dan oracle peran F-13; satu DITUTUP sebagian: F-17). Daftar penutup kini **86 temuan terlacak · 29 ditutup · 52 terbuka**. Dua temuan yang menyerang mekanisme kita sendiri langsung ditindak: kunci kalibrasi masih terbaca dari repo (H F-01 → `T1-44`) dan paket audit menargetkan commit yang CI-nya belum hijau (H F-02 → `T1-44`). **Temuan pemilik yang penting (H F-03):** database nyata baru memuat `0001`–`0014` — `0015` belum tersebar, dan klaim "tidak ada langkah menunggu" di `docs/ops/LANGKAH_PEMILIK_SEKARANG.md` **dikoreksi**; penyebaran menunggu batch selesai (berkas migrasi yang sudah masuk database tidak boleh diubah lagi). Sisa: 52 temuan terbuka + 16 temuan lama K-3/K-4.
  - **Progres 2026-09-20 (tiga temuan tuntas: sambungan jujur · Storage tidak meledak · uji aplikasi dibuktikan bisa MERAH):** **(1) F F-14 & I F-05** — `ujiSambungan()` dulu bilang "berhasil" hanya dari kesehatan Auth walau jalur data 401/404/500; kini `ok = auth && data`, status tiap jalur dilaporkan (`jalur`), dan pesannya menyebut jalur mana yang gagal (7 uji baru dengan status berbeda per jalur; mutasi `ok = auth saja` → 7 uji MERAH). **(2) I F-06** — kegagalan `localStorage` (`SecurityError`/`QuotaExceededError`) dulu menembus helper tema karena penjagaan hanya mengelilingi pengambilan objek; kini `bacaKunci()`/`tulisKunci()` menjaga pemanggilannya, `simpanPilihan()` mengembalikan false dengan jujur, dan tema tetap berganti di layar. **(3) Pagar baru** `aplikasi/alat/uji-mutasi-app.mjs`: salinan sementara + kontrol hijau + 5 mutasi perilaku yang WAJIB membuat uji MERAH (merah palsu dari galat startup ditolak), dijalankan di CI + `periksa-semua.sh` + terdaftar di gerbang wajib. Total uji aplikasi: **87 → 100** (13 uji baru).
  - **Progres 2026-09-20 (temuan I F-19 tuntas: nama uji tidak boleh lebih kuat daripada yang diuji):** uji bernama `'memanggil onUbah saat diisi'` dulu hanya merender HTML (SSR) dan justru memastikan callback TIDAK terpanggil — handler `onChange` yang tidak tersambung pun akan hijau. Kini ujinya benar-benar mengisi isian (jsdom + `@testing-library/react`) dan memeriksa **nilai** yang dikirim ke callback; ditambah penjaga mesin di `aplikasi/alat/periksa-uji.py` (aturan 3) yang **langsung menunjuk cacat aslinya** sebelum diperbaiki: uji yang namanya menjanjikan interaksi wajib memicu kejadian, kalau tidak → GAGAL berkas:baris. Bukti mutasi: handler dilepas → 1 uji GAGAL; nilai salah → 1 uji GAGAL; dipulihkan → 18 uji LULUS.
  - **Progres 2026-09-20 (temuan I F-21 tuntas: versi Node yang diiklankan diturunkan dari pustaka terkunci):** aplikasi mengiklankan `engines.node: ">=20"` sementara `aplikasi/package-lock.json` memuat `@supabase/supabase-js` (>=22.0.0) dan `vitest` (^22.12.0) — pemakai yang menuruti README bisa memasang Node yang tidak didukung. Kini batas minimum **dihitung mesin** (`aplikasi/alat/periksa-node.py`) dari seluruh entri lock non-opsional → `>=22.12.0`, README menulis `22.12+`, dan **CI berjalan tepat di versi itu** (`node-version: '22.12.0'`), jadi yang diiklankan sekaligus diuji. Entri opsional sengaja tidak ikut menaikkan syarat (dikunci satu kasus kontrol di `--uji-diri`).
  - **Progres 2026-09-20 (temuan I F-07 tuntas: batas Edge Function diuji sungguhan):** sebelum ini berkas Edge hanya dijaga pemeriksa TEKS — tidak ada yang pernah MENJALANKAN handler-nya, jadi cacat batas (JSON `null` → TypeError, 36 tanda minus lolos sebagai UUID, jaringan putus & jawaban bukan-JSON → exception) tidak tertangkap. Sekarang ada `alat/uji-edge-pin.mjs`: berkas ASLI `supabase/functions/verifikasi_pin/index.ts` diubah TS → JS dengan esbuild lalu dijalankan di VM **tanpa jaringan** (`Response`/`Request` milik Node), menuntut 17 batas (E01–E17; awalnya 11) termasuk "PIN tidak pernah muncul di jawaban mana pun". Uji itu MERAH pada empat kasus sebelum perbaikan dan HIJAU sesudahnya; handler diperbaiki (badan diperiksa · UUID lengkap · satu bentuk jawaban gagal terkendali) dan ikut dijalankan di `aplikasi/alat/periksa-semua.sh` serta CI.
  - **Progres 2026-09-20 (batch "dokumen jujur": 8 temuan + 4 duplikat ditutup):** H F-06 (`docs/KEAMANAN.md` menyebut `hitung_total()` "belum mendarat" padahal versi awalnya sudah hidup di 0014 — sekarang ditulis apa adanya: versi awal hidup, pembulatan & 12 uji uang belum), H F-08 (bukti T0-03 memakai jalur lengkap `aplikasi/src/lib/tema.ts`), H F-10 (justifikasi klasifikasi: eksploitasi penanda-palsu di produksi menuntut koneksi SQL langsung; 0015 tetap dipertahankan), I F-09 (`aplikasi/README.md` tidak lagi mencampur dua folder kerja), I F-10 (auditor wajib kembali ke cabang sesinya & push eksplisit — `git symbolic-ref` + `git push origin HEAD:refs/heads/<cabang>`), I F-11 (janji rahasia GitHub dikoreksi: terenkripsi ≠ tak terbaca; least privilege + TTL), I F-12 (satu aturan pindah sesi: melihat pekerjaan TIDAK perlu merge; merge PR tetap keputusan Lee), D F-06 (catatan silang T1-15/T1-17: jangan tulis rumus kedua). Empat duplikat ditutup karena obatnya sudah mendarat: B F-09/B F-17/D F-03/D F-04 (paket wajib menunjuk induk commit sendiri · gerbang CI · pemecah artefak).
  - **Progres 2026-09-20 (temuan H F-05 & I F-20 tuntas: pembuat paket berhenti menuduh perintah/glob sebagai "berkas hilang"):** paket audit menyuruh auditor mencari "berkas" yang sebenarnya NYATA — `python3 alat/periksa-roadmap.py` (perintah), `aplikasi/src/komponen/*.tsx` (pola yang cocok 13 berkas), `src/lib/tema.ts` (jalur relatif folder `aplikasi/`). Sekarang ada pemecah artefak bersama `alat/artefak.py` (`pisah_artefak()`) yang dipakai pembuat paket `alat/audit-independen.py` DAN `alat/periksa-temuan-audit.py` (pemeriksa itu dulu juga menuduh bukti berpola/jalur-relatif sebagai "berkas mati"): **berkas** · **perintah** · **pola** (dihitung berapa berkas nyata yang cocok) · **hilang**; jalur relatif folder kerja diselesaikan, rujukan baris (`…sql:120`) dibuang, dan baris "TIDAK ADA" dihitung sekali per jalur+tugas (dulu duplikat dihitung sebagai baris terpisah, sehingga angka "12 baris" menyesatkan). Perintah tampil tersendiri di bagian "1a. Perintah bukti" supaya auditor MALAH memakainya. Bukti: paket baru pada pohon sekarang → bagian "sudah [x] — berkasnya TIDAK ADA" **0 baris** (dari 13), sementara artefak yang benar-benar hilang tetap dilaporkan; `--uji-diri` +10 contoh di pembuat paket dan +2 kasus di `alat/periksa-temuan-audit.py` (pola/jalur relatif diterima · yang benar-benar hilang tetap ditolak).
  - **Progres 2026-09-20 (temuan I F-03 & I F-04 tuntas: penjaga PIN dan penilai mutasi diperkuat):** dua cacat "gerbang palsu" ditutup. (1) **I F-03** — `alat/periksa-fungsi-pin.py` dulu meloloskan balasan yang mengembalikan PIN dan log lewat `console['log']`; sekarang setiap bentuk `console` ditolak (titik/bracket/alias/`globalThis.console`) dan variabel PIN dibatasi ke tiga jalur sah (baca · periksa bentuk · teruskan ke RPC), dengan jalur teruskan melekat pada RENTANG panggilan `fetch(... rpc/ ...)` sehingga `p_pin: pin` di balasan tetap ditolak; ada `--uji-diri` 9 kasus (sumber sah diterima, 8 contoh cacat ditolak dengan alasan yang benar) yang ikut berjalan di `periksa-semua.sh`. (2) **I F-04** — penilai mutasi `lulus = (kode != 0)` diganti `alat/klasifikasi_mutasi.py`: hanya merah yang berasal dari **asersi** di berkas `supabase/tes/` yang dihitung bukti pagar bekerja; crash/sintaks/migrasi gagal = RUSAK dan membuat harness GAGAL. Pengetatan itu **langsung menemukan bukti palsu historis**: satu mutasi ("pagar dikembalikan ke versi lama") sebenarnya gagal dikompilasi dan dulu dilaporkan "MERAH (benar)" — kini diperbaiki dan benar-benar memerahkan uji K-1. Seluruh 26 mutasi + kontrol penutup kini LOLOS sebagai MERAH-PAGAR.
  - **Progres 2026-09-20 (paket wajib menunjuk commit ber-CI hijau — temuan H F-02 tuntas):** protokol sudah mewajibkan "commit ber-CI hijau", tetapi tidak ada penegaknya (paket AUD-3 2026-09-19 menargetkan `4830b5a` yang dua run CI-nya `cancelled`). Sekarang ada **penegak**: `alat/ci_target.py` bertanya ke GitHub Actions, dan **pembuat paket MENOLAK jalan** bila CI commit target belum hijau — baik `alat/audit-independen.py --paket` maupun `alat/review-pr.py --siapkan`. Statusnya ditulis di dalam paket (`- **CI commit target:** success (run …)`), dan pengecualian hanya lewat `--izinkan-ci-belum-hijau "<alasan>"` yang juga **tercetak di paket** sebagai izin pemilik. Penjaga `alat/periksa-paket.py` aturan **F-02**: paket bertanggal ≥ 2026-09-20 wajib punya baris status CI, klaim "success" diperiksa ulang ke GitHub, dan "belum hijau" tanpa baris izin pemilik ditolak (+2 kasus `--uji-diri`, salah satunya mencari commit non-hijau sungguhan lalu membuktikan klaim palsu ditolak). Bukti langsung: `python3 alat/audit-independen.py --paket AUD-2 --tugas T1-01` **MENOLAK** dengan pesan "commit target … BELUM punya CI hijau".
  - **Progres 2026-09-20 (katalog cacat kalibrasi dikeluarkan dari repo — temuan H F-01 TUNTAS):** dengan izin Lee (*"Aku ikut yang terbaik menurut kamu. Klo sebaiknya dikeluarkan, silahkan keluarkan"*), berkas `alat/kalibrasi-cacat.json` — pasangan cari/ganti = **kunci jawaban** kalibrasi — **dipindah ke luar repo** (`KALIBRASI_DIR`, baku `/home/user/.kalibrasi/kalibrasi-cacat.json`) dan berjejak di `docs/uji/BERKAS_PENSIUN.md` baris #2 (siapa memutuskan, kapan, kenapa, nasib isi di riwayat Git). Alat sekarang **gagal-tertutup**: katalog hanya dibaca dari luar repo, dan `alat/periksa-kunci-kalibrasi.py` aturan **A2** menolak bila katalog muncul lagi di dalam repo. Dua efek samping yang sekalian dibereskan: (a) `alat/periksa-rujukan.py` dan `alat/periksa-temuan-audit.py` kini **mengakui daftar pensiun**, supaya riwayat yang jujur menyebut berkas pensiun tidak lagi terbaca "rujukan mati"; (b) penjaga temuan mengambil token pertama rujukan sehingga sel bukti boleh memuat perintah (`alat/periksa-x.py --uji-diri`). Bukti: `--uji-diri` periksa-kunci-kalibrasi **13 kasus** (semua menolak), `--kalibrasi-siapkan` & `--kalibrasi-pr-siapkan` berjalan dengan bahan di luar repo, `--uji-diri` periksa-rujukan kini 5 kasus. Sisa temuan mekanisme: **H F-02** (paket audit menargetkan commit ber-CI-belum-hijau) dan **I F-20/I F-04/I F-03** (mutu alat audit sendiri).
  - **Progres 2026-09-20 (kebocoran kunci kalibrasi — audit H F-01) — SALINAN KALIBRASI TIDAK LAGI MEMBAWA KUNCI:** bantah-balik temuan auditor membuktikan cacatnya **lebih parah dari dugaan**: jalur mesin dulu membuat salinan auditor dengan `git worktree add`, jadi di dalam salinan itu `git diff`/`git show` **langsung memperlihatkan baris mana yang ditanami cacat** (perubahan ditanam sebagai perubahan belum-di-commit), dan berkas katalog `alat/kalibrasi-cacat.json` (pasangan cari/ganti = daftar jawaban) ikut tersalin. Artinya auditor bisa memalsukan skor kalibrasi tanpa mengulas. Perbaikan: salinan dibuat lewat `git archive` + **satu commit bersih** (riwayat tidak membocorkan apa pun, tetapi alat berbasis-git tetap jalan), katalog **dikeluarkan** dari salinan, dan ada pemeriksa baru `pastikan_salinan_bersih()` yang menolak salinan bila masih membawa katalog/berkas kunci atau perubahan belum di-commit (`alat/audit-independen.py`). Jalur review PR kini **gagal-tertutup**: `alat/review-pr.py` hanya membaca katalog dari LUAR repo (`KALIBRASI_DIR`, baku `/home/user/.kalibrasi`) dan menolak membuat bahan bila katalog masih di dalam repo — lebih baik kalibrasi tidak jalan daripada skornya bisa dipalsukan. Dijaga mesin: `alat/periksa-kunci-kalibrasi.py` aturan F & G + **3 mutasi uji-diri baru** (12 kasus). **Sisa yang butuh keputusan Lee:** memindahkan berkas katalog itu sendiri ke luar repo (termasuk baris daftar pensiun) → `T1-44`.
  - **Progres 2026-09-20 (bagian 10–11) — DUA TEMUAN "DUGAAN" TERBUKTI NYATA & DITUTUP (F-10, F-11) + SATU DIREDAM (F-13):** bantah-balik tidak lagi menebak: **F-10** diuji lewat probe sendiri `docs/uji/audit/probe-2026-09-20/aud-3-f10-admin-cabang-izin.sql` → NYATA (admin Cabang Pusat membaca izin pegawai Cabang Dua, 8 baris = seluruh penyewa) — kontrak `docs/TECH_SPEC.md` §294 + `docs/PRD.md` berkata "admin cabang hanya cabangnya", jadi policy `izin_pilih` diselaraskan dengan kontrak **dan** dengan pola policy `pengguna_pilih` (satu aturan, bukan dua tafsir); uji `supabase/tes/rls_pengguna.sql` §5 dikoreksi dari ekspektasi lama yang justru mengunci kebocoran (8 → 4 baris + larangan melihat izin pegawai cabang lain). **F-11** diuji lewat probe `docs/uji/audit/probe-2026-09-20/aud-3-f11-helper-pin.sql` → NYATA (kasir bisa memanggil `peran_lebih_tinggi` dengan UUID siapa pun, termasuk lintas resto) → hak execute klien dicabut **dan** `p_pemanggil` dipakukan ke `auth.uid()` (lapis kedua diuji lewat pembungkus SECURITY DEFINER = skenario "jalur baru tanpa pembungkus identitas"); uji baru `supabase/tes/pin_helper_pribadi.sql` memastikan jalur sah owner tetap terbuka. **F-13** (DUGAAN, K-2): pengambilan nomor pesanan kini di bawah `pg_advisory_xact_lock` per (cabang, tanggal) dan fungsinya kembali VOLATILE — risikonya diredam, tetapi uji dua transaksi nyata **belum bisa dijalankan** di lingkungan uji (PGlite satu koneksi) sehingga temuan tetap **TERBUKA dengan catatan jujur** (bukan dicap selesai); yang dijaga mesin sekarang = sifat serialisasinya (`supabase/tes/nomor_pesanan_kunci.sql` + 2 mutasi wajib-MERAH). Bukti batch ini: suite SQL **53 berkas LULUS · 0 GAGAL** · `alat/uji-mutasi-0015.py` **25 mutasi wajib MERAH terbukti + kontrol hijau** · daftar temuan `docs/uji/AUDIT_RIWAYAT.md` §1c kini **26 DITUTUP / 23 TERBUKA** · keputusan dikunci di `docs/DECISIONS_LOG.md`. Catatan mekanisme (pelajaran CI merah hari ini): sejak `0015` menulis ulang fungsi yang sama di beberapa bagian, **definisi yang berlaku = kemunculan TERAKHIR** — mutasi wajib menyentuh kemunculan terakhir (`ganti_terakhir`), kalau tidak mutasinya tumpul. Sisa temuan audit F: 8 (F-07 → `T1-13`, F-09 → `T8-01`, F-12 & F-13 dipagari, sisanya TERBUKA dengan pemilik) + 16 temuan lama K-3/K-4.
  - **Progres 2026-09-20 (bagian 9) — F-04 DITUTUP (state machine status item):** dibuktikan NYATA dulu lewat probe sendiri `docs/uji/audit/probe-2026-09-20/aud-3-f04-status-item.sql` (dulu LULUS = cacat ada: item bisa LAHIR `siap`, status bisa melompat `baru → siap`/mundur, dan item bisa dibatalkan hanya dengan mengubah statusnya — tanpa alasan, tanpa baris `pembatalan`, tanpa nilai kerugian), lalu ditutup di `supabase/migrations/0015_penutup_celah_putaran16.sql` bagian 9: status item hanya **maju satu langkah** `baru → dimasak → siap` (TECH_SPEC ART-4) dan `batal` **bukan transisi biasa** — satu-satunya jalur adalah baris `pembatalan` resmi (beralasan, ber-PIN bila sesudah dapur), sehingga pembatalan pra-dapur pun berjejak. Uji regresi baru `supabase/tes/status_item_transisi.sql`; dua uji lama (`supabase/tes/pesanan.sql`, `supabase/tes/uang_peladen.sql`) **diselaraskan** ke jalur pembatalan resmi. Suite SQL **51 berkas LULUS · 0 GAGAL**; `alat/uji-mutasi-0015.py` **21 kasus** (mutasi baru wajib MERAH, terbukti). Catatan mekanisme: dua mutasi lama disesuaikan karena `picu_item_jaga` kini punya definisi berlaku di bagian 9 — mutasi wajib menyentuh definisi TERAKHIR, bukan yang pertama (kalau tidak, mutasinya tumpul). Sisa temuan audit F: 11 (bantah-balik berurutan) + 16 temuan lama K-3/K-4.
  - **Progres 2026-09-20 (bagian 8) — TIGA CACAT K-2 AUDIT F DITUTUP (F-03/F-05/F-06):** ketiganya dibuktikan NYATA dulu lewat probe sendiri `docs/uji/audit/probe-2026-09-20/aud-3-f03-f05-f06-uang.sql` (dulu LULUS = cacat ada), lalu ditutup di `supabase/migrations/0015_penutup_celah_putaran16.sql` bagian 8. **F-03:** metode bayar yang dinonaktifkan pemilik tidak bisa lagi mencatat uang (uji `supabase/tes/metode_bayar_nonaktif.sql`) · **F-05:** satu target pembatalan = satu jejak — kiriman ulang (klik ganda/antrean offline) ditolak, laporan kerugian tidak lagi bisa tergandakan (uji `supabase/tes/pembatalan_sekali.sql`; uji lama `supabase/tes/pembayaran.sql` diselaraskan memakai pesanan kedua) · **F-06:** stempel lifecycle (`dibayar_pada`, `dibatalkan_pada`, `alasan_batal`) tidak bisa dikarang perangkat lewat UPDATE biasa, jalur peladen tetap bebas (uji `supabase/tes/lifecycle_pesanan.sql`). Suite SQL **50 berkas LULUS · 0 GAGAL**; `alat/uji-mutasi-0015.py` **20 kasus** (3 mutasi baru wajib MERAH, terbukti); probe ketiga kini GAGAL (= cacat hilang). Sisa temuan audit F: 12 (bantah-balik berurutan) + 16 temuan lama K-3/K-4.
  - **Progres 2026-09-20 (bagian 6) — ATURAN UANG DIPERBAIKI, 3 CACAT AUDIT F DITUTUP:** audit menyeluruh ronde baru (`arena/01a0bbd2`, laporan `docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2.md`, LOLOS KONTRAK) membawa **18 temuan**; tiga di antaranya cacat jalur uang dan **dibuktikan NYATA dengan probe sendiri** (`docs/uji/audit/probe-2026-09-20/aud-3-f01-f02-uang.sql` dijalankan `node alat/uji-sql.mjs` → dulu LULUS karena cacat ada). **F-01a DITUTUP:** pajak PB1 & service kini dihitung dari subtotal **setelah** diskon (contoh: 100.000 − diskon 20.000 → PB1 8.000 · service 4.000 · total 92.000, dulu 10.000/5.000/95.000) · **F-01b DITUTUP:** `pengaturan.pembulatan` dibaca lagi dan diterapkan di langkah **terakhir**, arah **ke bawah** (31.050 → 31.000 pada langkah 500) · **F-02 DITUTUP:** pesanan `lunas`/`batal` tidak bisa dihitung ulang dari perangkat (guard `pg_trigger_depth() = 0`; jalur pemicu peladen tetap sah) · baris pesanan dikunci `for update`. Uji regresi baru `supabase/tes/urutan_uang.sql` (6 bagian) + 4 mutasi wajib-MERAH di `alat/uji-mutasi-0015.py` (kini **17 kasus**); probe lama kini GAGAL (= cacat hilang). Seluruh 18 temuan F punya pemilik: daftar penutup §1c `docs/uji/AUDIT_RIWAYAT.md` (F-17 → `T1-44`; F-07 → `T1-13`; F-09 → `T8-01`). Sisa temuan T1-45: 16 (K-3 & K-4) + 15 temuan F (bantah-balik berurutan).
  - **Progres 2026-09-19 (bagian 4–5) — SELURUH K-2 TUNTAS (4/4):** **PR-03 DITUTUP** — `nomor_pesanan_berikutnya()` kini memeriksa keterlihatan cabang (`cabang_pantau_saya`) seperti `hitung_total`/`total_dibayar`; kasir resto lain tidak lagi bisa membaca hitungan pesanan resto A · uji `supabase/tes/nomor_pesanan_isolasi.sql`. **PR-04 DITUTUP** — pesan PIN kembar tidak lagi menyebut "pegawai lain" (tidak memastikan angka kiriman adalah PIN aktif kolega); alasan sebenarnya tetap tercatat, pengendali biaya menebak tetap pembatas 20 percobaan/15 menit · uji `supabase/tes/pin_bukan_oracle.sql`. Suite SQL 46 berkas; `alat/uji-mutasi-0015.py` 15 kasus (13 wajib MERAH, terbukti). Sisa temuan 18 → **16**.
  - **Progres 2026-09-19 (bagian 2–3):** **F-01 audit D (diskon sesudah lunas/batal) DITUTUP** — pemicu baru `diskon_awal_pesanan` (`supabase/migrations/0015_penutup_celah_putaran16.sql` bagian 3) menolak tambah/ubah/hapus baris diskon pada pesanan lunas/batal; nama pemicu sengaja berjalan SEBELUM pemicu nilai supaya penolakannya berbunyi tentang status (dikunci mutasi urutan) · uji `supabase/tes/diskon_sesudah_lunas.sql`. **PR-02 (void satu item) DITUTUP** — bagian 2: pesanan hanya ditutup bila tidak ada item hidup tersisa, dan pesanan yang ditutup menandai seluruh itemnya batal; pembayaran sisa tidak lagi buntu · uji `supabase/tes/void_satu_item.sql`. Suite SQL 44 berkas; mutasi `0015` kini 11 kasus (10 wajib MERAH, terbukti). Sisa temuan 20 → **18**.
  - **Progres 2026-09-19 (sebagian):** **PR-01 (K-1, paling berbahaya) DITUTUP** — migrasi baru `supabase/migrations/0015_penutup_celah_putaran16.sql` bagian 1: penanda transaksi palsu (`resto.pembatalan_*`) tidak lagi diakui; pembatalan item setelah dapur hanya lewat baris pembatalan resmi. Uji regresi `supabase/tes/pembatalan_penanda_palsu.sql` + `alat/uji-mutasi-0015.py` (6 mutasi, terbukti bisa MERAH) masuk CI sebagai gerbang ke-52 · **PR-12 DITUTUP** (temuan K-4: label gerbang `12/12` basi di `aplikasi/alat/periksa-semua.sh` — label kini tanpa angka, angka benar datang dari ringkasan alat) · **PR-10 DITUTUP** (penjaga gerbang CI gagal-terbuka → kini **dua arah**: 49 perintah CI seluruhnya diawasi — **50** setelah gerbang uji sambung Supabase T0-08 ditambahkan, `if:` dilarang, terbukti menolak di salinan `/tmp/gc2`) · **D F-05 DITUTUP** — kunci kalibrasi dikeluarkan dari repo, bahan review PR hidup di luar repo & disematkan ke paket, dijaga `alat/periksa-kunci-kalibrasi.py` (6 mutasi uji-diri) + aturan rotasi di `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7 · jalur pensiun terdaftar di `docs/uji/BERKAS_PENSIUN.md` (paket & laporan peninjau tidak disunting) · penjaga paket F-11 diperbaiki (dulu satu suntingan sah menuduh 22 paket lama); gerbang CI 22 → **24**. Sisa 24 temuan menunggu migrasi `0015+` & perbaikan alat.
  - **Verifikasi:** `node alat/uji-sql.mjs` hijau dengan uji baru per temuan · `python3 alat/uji-mutasi-0015.py` semua MERAH · `bash aplikasi/alat/periksa-semua.sh` hijau.

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

- [ ] T2-04 — Masuk pelanggan: Google (utama) + email terverifikasi (kedua) ❓ T-022
  - **Tujuan:** pelanggan bisa mendaftar tanpa SMS dan tanpa biaya.
  - **Ref:** PRD M10 & M12; TECH_SPEC §7 (integrasi)
  - **File:** `aplikasi/src/layar/masuk/LayarMasukPelanggan.tsx`, `aplikasi/src/lib/google.ts`
  - **DoD:** "Daftar dengan Google" bekerja; jalur email mengirim verifikasi; identitas pelanggan tersimpan tanpa data berlebih; uji manual dua jalur lulus.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Privasi (ART-10); data berlebih → mitigasi: hanya nama, email, nomor HP opsional, persetujuan.
  - **Verifikasi:** uji manual masuk Google di perangkat Android + jalur email di desktop.

- [ ] T2-05 — Pemulihan akses pelanggan (lupa PIN / ganti perangkat) ❓ T-022 ❓ T-023
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

- [ ] T2-13 — Kunci kedua (TOTP) untuk peran berkuasa + jalan pemulihannya ⚠️
  - **Tujuan:** akun yang bisa mengubah uang & pegawai dilindungi dua lapis, tanpa memacetkan kerja saat HP hilang.
  - **Ref:** TECH_SPEC §5.1 & §9 ART-12; PRD M12 & Aturan Bisnis 16
  - **File:** `aplikasi/src/layar/masuk/Totp.tsx`, `supabase/functions/atur_ulang_mfa/index.ts`, `alat/periksa-fungsi-mfa.py`, `supabase/tes/mfa.sql`
  - **DoD:** pendaftaran & verifikasi TOTP untuk `pemilik_platform`, `owner_pusat`, `admin_cabang`; akun tanpa TOTP tidak bisa masuk; RPC + Edge Function `atur_ulang_mfa` (tipis, tanpa `console.*`, wewenang diperiksa di database) mengatur ulang MFA dengan catatan audit + pemberitahuan; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Keamanan Akun (ART-12); admin terkunci karena HP hilang → mitigasi: jalan pemulihan diuji lebih dulu + langkah di Buku Insiden.
  - **Verifikasi:** uji SQL + uji komponen: masuk tanpa TOTP → ditolak; pengaturan ulang oleh yang tidak berizin → ditolak; pengaturan ulang berizin → akun bisa masuk lagi + jejak audit ada.

- [ ] T2-14 — Layar masuk staf: pilih nama → PIN (hanya perangkat terdaftar) ⚠️
  - **Tujuan:** kasir & pelayan masuk dalam hitungan detik dari tablet yang sudah didaftarkan.
  - **Ref:** TECH_SPEC §5.1 & §9 ART-12; PRD M12
  - **File:** `aplikasi/src/layar/masuk/MasukStaf.tsx`, `aplikasi/src/lib/sesi.ts`, `docs/SPESIFIKASI_UI.md`
  - **DoD:** daftar akun di perangkat itu (sesuai `peran_diizinkan`) + papan angka besar; PIN salah → pesan jelas + sisa percobaan; PIN benar tetapi perangkat tidak terdaftar → pesan tegas + arahan minta persetujuan admin; kontrak layar + 7 keadaan + uji komponen lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Keamanan Akun (ART-12); staf tidak bisa masuk saat jam sibuk → mitigasi: papan angka besar, tanpa kata sandi, pesan berbahasa Indonesia, dan tombol "minta bantuan admin".
  - **Verifikasi:** uji komponen (aksi terdaftar `masuk.pin` memanggil RPC yang benar) + naskah jalan pemilik.

- [ ] T2-15 — Pendaftaran perangkat (kode/QR) + persetujuan pegawai baru ⚠️ ❓ T-015
  - **Tujuan:** hanya perangkat yang didaftarkan admin/owner yang bisa dipakai kerja, dan pegawai baru harus disetujui pemilik.
  - **Ref:** TECH_SPEC §4.6 & §9 ART-11; PRD M12
  - **File:** `aplikasi/src/layar/pengaturan/Perangkat.tsx`, `supabase/functions/kode_perangkat/index.ts`, `docs/SPESIFIKASI_UI.md`
  - **DoD:** **owner pusat (semua cabang) & admin cabang (cabangnya)** membuat kode sekali pakai (15 menit) + QR; perangkat baru mendaftar & menyimpan rahasia; pemilik menyetujui pasangan (pegawai × perangkat); perangkat dengan peran lain tidak bisa dipakai masuk; perangkat pertama owner didaftarkan sekali saat penyiapan (bootstrap); peringatan bila perangkat berkuasa tinggal 1; uji komponen + SQL lulus.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Akses Perangkat (ART-11); kode disalin orang lain → mitigasi: sekali pakai, 15 menit, tercatat, dan tetap butuh persetujuan pemilik per pegawai.
  - **Verifikasi:** uji SQL + naskah jalan: daftar perangkat baru → tampil di daftar; pakai kode dua kali → ditolak.

- [ ] T2-16 — Kunci otomatis saat menganggur + tombol "Kunci sekarang" ⚠️
  - **Tujuan:** tablet yang ditinggal tidak menyimpan sesi apa pun.
  - **Ref:** TECH_SPEC §9 ART-11; PRD M12
  - **File:** `aplikasi/src/hook/useKunciOtomatis.ts`, `aplikasi/src/komponen/KunciSekarang.tsx`, `aplikasi/src/hook/useKunciOtomatis.test.tsx`
  - **DoD:** batas menganggur per peran (15/15/15/30/60 menit) **hanya berlaku di luar jam aktif**; **jam aktif per cabang diatur owner di Pengaturan** (bawaan: jam buka–tutup + masa persiapan) dan di luar itu kunci otomatis 15 menit; saat kunci → sesi dihapus dari perangkat + antrean offline tetap terjaga; tombol Kunci selalu tampil di layar staf; uji unit lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Akses Perangkat (ART-11); pesanan di antrean hilang saat kunci → mitigasi: antrean disimpan di IndexedDB (ART-8) + uji khusus.
  - **Verifikasi:** uji unit: lewat batas → terkunci; buka lagi → wajib PIN; antrean utuh setelah kunci.

- [ ] T2-17 — Layar Perangkat & Sesi: daftar, cabut, tandai hilang ⚠️
  - **Tujuan:** owner bisa mematikan akses perangkat hilang dalam hitungan detik dan melihat apa yang sedang aktif.
  - **Ref:** TECH_SPEC §5.1 & §9 ART-11; PRD M12
  - **File:** `aplikasi/src/layar/pengaturan/DaftarPerangkat.tsx`, `docs/uji/NASKAH_JALAN.md`
  - **DoD:** daftar perangkat (nama, cabang, peran, terakhir aktif, status) + daftar sesi aktif; aksi cabut/hilang dengan konfirmasi + alasan; cabut berlaku seketika (uji SQL); kontrak layar + uji komponen lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Akses Perangkat (ART-11); salah cabut perangkat yang sedang dipakai → mitigasi: konfirmasi menyebut nama perangkat + pesan bahwa kasir akan langsung keluar.
  - **Verifikasi:** uji komponen + naskah jalan: cabut → perangkat lain langsung tidak bisa melakukan permintaan berikutnya.

- [ ] T2-18 — Masuk admin/owner: kata sandi + TOTP + perangkat (dengan bootstrap) ⚠️
  - **Tujuan:** peran berkuasa masuk dengan aman di perangkat yang terdaftar, tanpa terkunci saat gagal.
  - **Ref:** TECH_SPEC §5.1 & §9 ART-11/ART-12; PRD M12
  - **File:** `aplikasi/src/layar/masuk/MasukPengelola.tsx`, `docs/SPESIFIKASI_UI.md`
  - **DoD:** alur kata sandi → TOTP → cek perangkat; perangkat pertama owner boleh didaftarkan sendiri (bootstrap); perangkat berikutnya butuh persetujuan perangkat aktif; pesan gagal tidak membocorkan apakah akun ada; uji komponen lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Akses Perangkat (ART-11); owner terkunci di luar restonya sendiri → mitigasi: bootstrap diuji + langkah pemulihan di Buku Insiden + akses pemilik platform.
  - **Verifikasi:** uji komponen + uji SQL: perangkat belum disetujui → ditolak; setelah disetujui → berhasil.

- [ ] T2-19 — Uji menyeluruh masuk & perangkat (6 peran × skenario) ⚠️
  - **Tujuan:** membuktikan aturan masuk benar untuk semua peran, termasuk kasus jahat.
  - **Ref:** TECH_SPEC §11 & §9 ART-11/ART-12; docs/KEAMANAN.md §14
  - **File:** `supabase/tes/masuk_perangkat.sql`, `aplikasi/src/layar/masuk/masuk.test.tsx`
  - **DoD:** matriks skenario diuji: perangkat tidak terdaftar · peran tidak cocok · kode kadaluwarsa · sesi lewat umur · perangkat dicabut · akun nonaktif · percobaan berulang · TOTP hilang → jalur pemulihan; semua lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Keamanan Akun (ART-11/ART-12); uji hanya jalur bahagia → mitigasi: wajib ada uji negatif untuk setiap skenario.
  - **Verifikasi:** uji SQL + komponen hijau + ringkasan matriks tercetak di laporan batch.

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
  - **File:** `supabase/migrations/0028_simpan_pesanan.sql`, `supabase/tes/simpan_pesanan.sql`
  - **DoD:** RPC menolak duplikat dengan kunci idempoten; menolak pesanan tanpa item; menolak di luar shift terbuka; hak akses diperiksa; uji lulus (termasuk 5 pemanggilan kunci sama).
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4) & Antrean (ART-8); pesanan dobel → mitigasi: kunci unik di database + uji paralel.
  - **Verifikasi:** uji SQL: 5 pemanggilan dengan kunci sama → 1 pesanan; tanpa kunci → ditolak.

- [ ] T3-06 — Pindah meja + status meja
  - **Tujuan:** pelanggan pindah meja tanpa membingungkan dapur/kasir.
  - **Ref:** PRD M4 (kasus tepi)
  - **File:** `aplikasi/src/layar/kasir/PindahMeja.tsx`, `supabase/migrations/0029_pindah_meja.sql`
  - **DoD:** pindah meja tercatat (dari → ke, oleh siapa); status meja otomatis (kosong/terisi/siap); riwayat tetap.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** salah pindah → mitigasi: konfirmasi + catatan audit.
  - **Verifikasi:** uji manual + uji SQL riwayat pindah meja.

- [ ] T3-07 — Penguncian menu habis di kasir
  - **Tujuan:** pelanggan tidak memesan yang sudah habis.
  - **Ref:** PRD M9 (kriteria selesai); TECH_SPEC §4.2 (`stok_pergerakan`, jenis `opname`)
  - **File:** `aplikasi/src/layar/kasir/Katalog.tsx` (penanda habis), `supabase/migrations/0030_menu_habis.sql`
  - **DoD:** menandai habis dari kasir & dapur; item habis tidak bisa ditambahkan; pencabutan penanda butuh izin; perubahan tampil di katalog publik.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** penanda lupa dicabut → mitigasi: daftar "menu habis hari ini" di layar kasir + pengingat pagi.
  - **Verifikasi:** uji manual + uji SQL (item habis ditolak di RPC pesanan).

- [ ] T3-08 — Kirim ke dapur (status pesanan berubah)
  - **Tujuan:** dapur mulai bekerja begitu pesanan dikirim, dan kasir tahu statusnya.
  - **Ref:** PRD M4 & M5; TECH_SPEC §9 ART-4
  - **File:** `aplikasi/src/layar/kasir/KirimDapur.tsx`, `supabase/migrations/0031_kirim_dapur.sql`
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
  - **File:** `aplikasi/src/layar/kasir/BatalPesanan.tsx`, `supabase/migrations/0032_batal_pra_dapur.sql`
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
  - **File:** `aplikasi/src/layar/dapur/LayarBar.tsx`, `supabase/migrations/0033_tujuan_item.sql`
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
  - **File:** `supabase/migrations/0034_status_item.sql`, `supabase/tes/status_item.sql`
  - **DoD:** status per item (menunggu → dimasak → siap) dan per pesanan; perubahan ganda dari dua perangkat hanya menghasilkan satu perubahan tercatat; uji paralel lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4); mitigasi: transisi divalidasi di database + kunci idempoten.
  - **Verifikasi:** uji SQL dua pemanggilan paralel → satu perubahan.

- [ ] T4-05 — Tombol menu habis dari dapur (mengunci kasir + katalog)
  - **Tujuan:** satu tombol di dapur langsung mencegah penjualan menu yang habis.
  - **Ref:** PRD M5 & M9
  - **File:** `aplikasi/src/layar/dapur/TombolHabis.tsx`, `supabase/migrations/0035_menu_habis_sumber.sql`
  - **DoD:** penanda habis dari dapur langsung berlaku di kasir & katalog publik (realtime); tercatat siapa & kapan; pencabutan butuh izin.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** penanda tidak tersinkron → mitigasi: satu sumber kebenaran di database + uji lintas layar.
  - **Verifikasi:** uji manual dua perangkat (dapur & kasir).

- [ ] T4-06 — Stok sederhana per bahan + riwayat
  - **Tujuan:** owner tahu persediaan tanpa buku catatan terpisah.
  - **Ref:** PRD M9; TECH_SPEC §4.2 (tabel resmi: `stok_bahan`, `stok_pergerakan`) · RPC resmi: `set_stok`, `opname_stok`
  - **File:** `aplikasi/src/layar/dapur/Stok.tsx`, `supabase/migrations/0036_stok.sql`
  - **DoD:** bahan bisa dicatat/diabaikan (opsional); penambahan/pengurangan; riwayat perubahan (siapa, kapan, berapa); uji lulus.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** stok tidak akurat → mitigasi: dinyatakan tegas "pencatatan sederhana, bukan resep otomatis (fase 2)" + opname berkala.
  - **Verifikasi:** uji manual + uji SQL riwayat.

- [ ] T4-07 — Opname berkala + selisih
  - **Tujuan:** selisih stok terlihat, bukan disembunyikan.
  - **Ref:** PRD M9 (kriteria selesai)
  - **File:** `aplikasi/src/layar/dapur/Opname.tsx`, `supabase/migrations/0037_opname.sql`
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
  - **File:** `supabase/migrations/0038_bayar_pesanan.sql`, `supabase/tes/bayar.sql`
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
  - **File:** `supabase/migrations/0039_diskon.sql`, `supabase/tes/diskon.sql`
  - **DoD:** bawaan menolak diskon kedua; bila pengaturan mengizinkan tumpuk, total diskon tidak boleh melebihi batas; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3); kombinasi diskon merugikan → mitigasi: batas total + uji kombinasi.
  - **Verifikasi:** uji SQL: 2 diskon tanpa izin tumpuk → ditolak; dengan tumpuk & melebihi batas → ditolak.

- [ ] T5-05 — Diskon manual butuh izin + PIN di atas batas ⚠️
  - **Tujuan:** kasir bisa memberi diskon kecil, tetapi tidak bisa memberi diskon besar tanpa atasan.
  - **Ref:** PRD M3 (batas maksimal %) & M6; TECH_SPEC §9 ART-2
  - **File:** `aplikasi/src/layar/kasir/DiskonManual.tsx`, `supabase/migrations/0040_diskon_izin.sql`
  - **DoD:** batas per pegawai dari pengaturan izin; di atas batas → wajib PIN atasan; tercatat (pelaku, nilai, alasan).
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); mitigasi: gerbang `boleh()` + PIN + audit.
  - **Verifikasi:** uji manual 3 kasus (di bawah batas, di atas batas tanpa PIN, dengan PIN).

- [ ] T5-06 — Void sebelum dapur mulai (alasan wajib) ⚠️
  - **Tujuan:** salah input cepat dibereskan, selalu dengan jejak.
  - **Ref:** PRD M6 (aturan bertingkat); TECH_SPEC §9 ART-4
  - **File:** `supabase/migrations/0041_void_pra.sql`, `supabase/tes/void_pra.sql`
  - **DoD:** hanya sebelum dimasak; alasan wajib dari daftar/ketik; masuk laporan; tidak ada penghapusan data; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: State Machine (ART-4); mitigasi: aturan di database + laporan harian.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T5-07 — Void setelah dapur mulai: PIN atasan + bahan terbuang ⚠️
  - **Tujuan:** kerugian terlihat sebagai angka, bukan hilang diam-diam.
  - **Ref:** PRD M6 (dikunci pemilik); TECH_SPEC §9 ART-4
  - **File:** `supabase/migrations/0042_void_pasca.sql`, `aplikasi/src/layar/kasir/VoidPasca.tsx`
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
  - **File:** `supabase/migrations/0043_laporan_pembatalan.sql`, `aplikasi/src/layar/laporan/DaftarPembatalan.tsx`
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
  - **File:** `supabase/migrations/0044_printer.sql`, `aplikasi/src/layar/pengaturan/PengaturanPrinter.tsx`
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
  - **File:** `supabase/migrations/0045_buka_shift.sql`, `aplikasi/src/layar/kasir/BukaKas.tsx`
  - **DoD:** modal awal wajib; satu shift terbuka per kasir per cabang; tercatat siapa & kapan; uji lulus.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); mitigasi: aturan satu shift terbuka + audit.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T7-02 — Tutup kas (seharusnya vs fisik) + alasan selisih ⚠️
  - **Tujuan:** kasir tidak pernah dituduh selisih, owner melihat kenyataan.
  - **Ref:** PRD M7 (kriteria selesai)
  - **File:** `supabase/migrations/0046_tutup_shift.sql`, `aplikasi/src/layar/kasir/TutupKas.tsx`
  - **DoD:** sistem menghitung uang seharusnya (modal + tunai masuk − tunai keluar); kasir memasukkan hasil hitung fisik; bila selisih → alasan wajib; nilai & alasan muncul di laporan.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); mitigasi: rumus di peladen + uji golden.
  - **Verifikasi:** uji SQL 5 kasus (pas, lebih, kurang, tanpa alasan, dua kasir satu shift).

- [ ] T7-03 — Kas pergerakan (masuk/keluar tunai, setoran) ⚠️
  - **Tujuan:** uang yang keluar-masuk di luar penjualan tetap tercatat.
  - **Ref:** PRD M7; TECH_SPEC §4 (kas_pergerakan)
  - **File:** `supabase/migrations/0047_kas_pergerakan.sql`, `aplikasi/src/layar/kasir/KasKeluarMasuk.tsx`
  - **DoD:** pencatatan keluar (belanja mendadak, ambil setoran) & masuk (tambahan modal) dengan alasan & izin; masuk hitungan tutup kas.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); mitigasi: izin + audit.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T7-04 — Transaksi hanya dalam shift terbuka ⚠️
  - **Tujuan:** tidak ada penjualan "di luar kas" yang tidak bisa diaudit.
  - **Ref:** PRD M7 (kriteria selesai)
  - **File:** `supabase/migrations/0048_wajib_shift.sql`, `supabase/tes/wajib_shift.sql`
  - **DoD:** memesan/membayar di luar shift terbuka ditolak dengan pesan jelas; uji lulus.
  - **Kompleksitas:** sedang (2,5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); kasir lupa buka kas saat sibuk → mitigasi: pengingat + tombol buka kas cepat.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T7-05 — Pengingat shift belum ditutup
  - **Tujuan:** shift menggantung tidak menumpuk dan tidak merusak laporan.
  - **Ref:** PRD M7 (kasus tepi)
  - **File:** `aplikasi/src/komponen/PengingatShift.tsx`, `supabase/migrations/0049_pengingat_shift.sql`
  - **DoD:** pengingat saat jam tutup, banner di layar kasir, catatan di laporan bila shift melewati tengah malam.
  - **Kompleksitas:** kecil (2 jam)
  - **Risiko & mitigasi:** pengingat diabaikan → mitigasi: tercatat di laporan harian owner.
  - **Verifikasi:** uji manual (ubah jam sistem uji) + uji SQL.

- [ ] T7-06 — Koreksi modal awal dengan izin atasan ⚠️
  - **Tujuan:** salah isi modal bisa dibetulkan tanpa menghapus data.
  - **Ref:** PRD M7 (kasus tepi)
  - **File:** `supabase/migrations/0050_koreksi_modal.sql`
  - **DoD:** koreksi tercatat sebagai baris baru (bukan menimpa), wajib PIN atasan + alasan, muncul di laporan.
  - **Kompleksitas:** sedang (2,5 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kas & Shift (ART-6); mitigasi: hanya-tambah + PIN.
  - **Verifikasi:** uji SQL (riwayat koreksi tetap ada).

- [ ] T7-07 — Laporan A: kas harian per shift
  - **Tujuan:** owner membuka satu layar dan langsung tahu kondisi hari ini.
  - **Ref:** PRD M8 (kriteria selesai — laporan A dikunci untuk G1) · RPC resmi: `laporan_shift`, `laporan_harian`
  - **File:** `supabase/migrations/0051_laporan_kas.sql`, `aplikasi/src/layar/laporan/LaporanKas.tsx`
  - **DoD:** memuat omzet (makanan/minuman/lainnya), jumlah transaksi, rincian metode bayar, diskon & voucher, pembatalan, kas awal/masuk/seharusnya/fisik/selisih, nama kasir & jam shift; filter cabang sesuai peran; angka dari peladen.
  - **Kompleksitas:** besar (5 jam)
  - **Risiko & mitigasi:** angka tidak cocok → mitigasi: uji golden (T7-12) + satu sumber hitung.
  - **Verifikasi:** uji SQL golden + uji manual bandingkan dengan data transaksi.

- [ ] T7-08 — Laporan penjualan dasar (kategori, metode)
  - **Tujuan:** owner tahu dari mana uang datang.
  - **Ref:** PRD M8
  - **File:** `supabase/migrations/0052_laporan_penjualan.sql`, `aplikasi/src/layar/laporan/LaporanPenjualan.tsx`
  - **DoD:** omzet per kategori, tren harian sederhana, rincian metode bayar; bisa dilihat per cabang & gabungan (owner).
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** laporan berat → mitigasi: agregasi di peladen + batas rentang tanggal.
  - **Verifikasi:** uji SQL + uji manual.

- [ ] T7-09 — Laporan menu terlaris + diskon/voucher terpakai
  - **Tujuan:** owner tahu menu andalan & biaya promosi.
  - **Ref:** PRD M8 & M10
  - **File:** `supabase/migrations/0053_laporan_menu.sql`, `aplikasi/src/layar/laporan/LaporanMenu.tsx`
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
  - **File:** `supabase/migrations/0054_katalog_publik.sql`, `supabase/tes/katalog_publik.sql`
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
  - **File:** `supabase/migrations/0055_voucher_terbit.sql`, `aplikasi/src/layar/voucher/KartuVoucher.tsx`
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
  - **File:** `aplikasi/src/layar/pengaturan/Kampanye.tsx`, `supabase/migrations/0056_kampanye_aturan.sql`
  - **DoD:** persen/nominal, minimum belanja, batas potongan, masa berlaku, kuota, anggaran, cabang berlaku; pratinjau aturan dalam bahasa manusia; validasi mencegah aturan mustahil.
  - **Kompleksitas:** sedang (4 jam)
  - **Risiko & mitigasi:** aturan salah → mitigasi: validasi + pratinjau ("pelanggan belanja 50rb → potongan maksimal 15rb").
  - **Verifikasi:** uji manual membuat 3 kampanye berbeda + uji SQL validasi.

- [ ] T8-12 — Pengaman anti-kecurangan (10 lapis) + batas klaim + log percobaan ⚠️
  - **Tujuan:** kampanye tidak bisa diborong satu orang atau satu perangkat.
  - **Ref:** PRD M10 (pengaman 1–10); TECH_SPEC §9 ART-5
  - **File:** `supabase/migrations/0057_pengaman_voucher.sql`, `supabase/tes/pengaman_voucher.sql`
  - **DoD:** satu voucher per identitas per kampanye; batas per outlet per hari; anggaran kampanye tidak bisa dilampaui; semua cek/scan tercatat; batas percobaan per perangkat; uji lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Voucher (ART-5); mitigasi: batas berlapis di database + laporan anomali.
  - **Verifikasi:** uji SQL: klaim ke-2 identitas sama → ditolak; lampaui anggaran → ditolak.

- [ ] T8-13 — Laporan klaim voucher + dasar deteksi anomali
  - **Tujuan:** owner melihat apakah kampanye berjalan wajar atau ada pola aneh.
  - **Ref:** PRD M10 (laporan anomali fase 2 → dasar di G1)
  - **File:** `supabase/migrations/0058_laporan_voucher.sql`, `aplikasi/src/layar/laporan/LaporanVoucher.tsx`
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

- [ ] T8-15 — Migrasi 0017: privasi pelanggan (persetujuan & anonimisasi) ⚠️ ❓ T-011
  - **Tujuan:** data pelanggan hanya disimpan dengan persetujuan, dan bisa dianonimkan atas permintaan (UU PDP).
  - **Ref:** TECH_SPEC §9 ART-14; PRD M10 & M12; docs/KEAMANAN.md §11
  - **File:** `supabase/migrations/0017_privasi_pelanggan.sql`, `supabase/tes/privasi.sql`, `aplikasi/src/layar/pelanggan-publik/KebijakanPrivasi.tsx`
  - **DoD:** kolom persetujuan + waktu + versi kebijakan; fungsi anonimisasi menghapus kontak tanpa menghapus catatan keuangan; halaman kebijakan berbahasa Indonesia; uji SQL lulus; draf kebijakan ditinjau pemilik sebelum data pelanggan pertama masuk.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Data Pelanggan (ART-14); data terlanjur tersimpan tanpa persetujuan → mitigasi: pendaftaran tanpa centang = ditolak database; anonimisasi menyisakan jejak audit.
  - **Verifikasi:** uji SQL: pelanggan tanpa persetujuan ditolak · anonimisasi menghapus kontak · transaksi & voucher tetap ada.

## Fase 9 — Pengaturan tanpa koding & multi-cabang (M1, M2, M3, M11)

- [ ] T9-01 — Pengaturan identitas & tampilan resto
  - **Tujuan:** owner mengubah nama, logo, banner, tagline sendiri tanpa menghubungi siapa pun.
  - **Ref:** PRD M2 (identitas & tampilan) · RPC resmi: `simpan_pengaturan`, `simpan_menu`, `simpan_meja`, `simpan_metode_bayar`
  - **File:** `aplikasi/src/layar/pengaturan/Identitas.tsx`, `supabase/migrations/0059_unggah_gambar.sql`
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
  - **File:** `aplikasi/src/layar/pengaturan/Operasional.tsx`, `supabase/migrations/0060_pengaturan_operasional.sql`
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
  - **File:** `aplikasi/src/layar/pengaturan/Menu.tsx`, `supabase/migrations/0061_urut_menu.sql`
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
  - **File:** `aplikasi/src/layar/pengaturan/Izin.tsx`, `supabase/migrations/0062_kelola_izin.sql`
  - **DoD:** centang izin per pegawai (termasuk batas diskon %/nominal), reset PIN, nonaktifkan akun, riwayat tetap; perubahan izin tercatat di audit.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Role & Permission (ART-2); izin salah memberi akses uang → mitigasi: daftar izin jelas + audit perubahan + uji peran (T2-12).
  - **Verifikasi:** uji manual mengubah izin → perilaku berubah di layar kasir; uji SQL audit.

- [ ] T9-09 — Kelola cabang (tambah, printer, nonaktifkan) ⚠️
  - **Tujuan:** membuka cabang baru tidak butuh bantuan teknis.
  - **Ref:** PRD M11; TECH_SPEC §9 ART-1 · RPC resmi: `set_akses_cabang`
  - **File:** `aplikasi/src/layar/pengaturan/Cabang.tsx`, `supabase/migrations/0063_kelola_cabang.sql`
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
  - **File:** `supabase/migrations/0064_idempoten.sql`, `supabase/tes/idempoten.sql`
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
  - **File:** `supabase/migrations/0065_pg_cron.sql`, `alat/denyut.py`
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
  - **File:** `supabase/migrations/0066_versi_pengaturan.sql`, `supabase/tes/pengaturan_bersamaan.sql`
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

- [ ] T10-13 — Ringkasan peringatan harian ke owner (email) ⚠️
  - **Tujuan:** hal aneh (void, diskon, selisih kas, percobaan masuk gagal, perubahan perangkat) terlihat tanpa owner membuka aplikasi.
  - **Ref:** TECH_SPEC §5.1 & §9 ART-13; docs/KEAMANAN.md §9
  - **File:** `supabase/functions/ringkasan_harian/index.ts`, `supabase/migrations/0066_ringkasan_harian.sql`, `aplikasi/src/layar/laporan/Peringatan.tsx`, `supabase/tes/ringkasan.sql`
  - **DoD:** laporan ringkas 1×/hari (pg_cron) dikirim **via email owner DAN dapat dilihat di layar Peringatan dalam aplikasi** (keputusan pemilik 2026-09-17), memuat omzet, transaksi, void, diskon, selisih kas, percobaan masuk gagal, perubahan perangkat, pemakaian jalur pemulihan; **tanpa** data pribadi pelanggan; rantai audit diperiksa dan dilaporkan bila putus; uji SQL lulus.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Jejak Audit (ART-13) & Data Pelanggan (ART-14); email bocor/tersalah kirim → mitigasi: hanya angka + nama pegawai, tanpa kontak pelanggan; penerima dapat diatur owner.
  - **Verifikasi:** uji SQL + kirim percobaan ke email pemilik pada tahap uji terima.

- [ ] T10-14 — Pemeriksa rahasia, dependensi & header keamanan halaman ⚠️
  - **Tujuan:** kunci rahasia tidak bocor dan aplikasi tidak dibuka dengan pengaturan peramban yang longgar.
  - **Ref:** TECH_SPEC §6 & §8; docs/KEAMANAN.md §16
  - **File:** `alat/periksa-rahasia.py`, `aplikasi/public/_headers`, `.github/workflows/ci.yml`
  - **DoD:** pemeriksa menolak berkas rahasia & pola kunci di repo; `npm audit` dijalankan; header keamanan (CSP, `X-Frame-Options`, `Referrer-Policy`) terpasang di Cloudflare; kontras & struktur halaman tetap hijau setelah CSP.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Kunci & Penerapan; CSP terlalu ketat mematikan aplikasi → mitigasi: diuji di pratinjau sebelum produksi + laporan bila ada pelanggaran.
  - **Verifikasi:** pemeriksa + `npm audit` + halaman pratinjau berjalan tanpa galat CSP.

- [ ] T10-15 — Latihan pemulihan cadangan & uji Buku Insiden ⚠️
  - **Tujuan:** cadangan terbukti bisa dipulihkan, dan langkah darurat bisa diikuti orang lain tanpa bertanya.
  - **Ref:** TECH_SPEC §8 & §11; docs/teknis/BUKU_INSIDEN.md
  - **File:** `docs/teknis/PEMULIHAN.md`, `docs/teknis/BUKU_INSIDEN.md`, `alat/pulihkan-cadangan.sh`
  - **DoD:** dump cadangan dipulihkan ke database bersih → jumlah baris tabel inti cocok dengan sumber; langkah perangkat hilang & akun diduga bocor diuji berurutan pada salinan; temuan dicatat & diperbaiki.
  - **Kompleksitas:** besar (4 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Ketahanan; cadangan rusak tanpa disadari → mitigasi: latihan nyata minimal sekali sebelum pilot + pemeriksa cadangan berjadwal.
  - **Verifikasi:** laporan latihan (tanggal, jumlah baris, temuan) + langkah Buku Insiden dijalankan.

- [ ] T10-16 — Tinjauan kode pemulihan MFA & kata sandi bocor (T-016) ⚠️ ❓ T-016
  - **Tujuan:** menutup dua celah yang kini sengaja dibiarkan (pemulihan MFA mandiri & pemeriksa kata sandi bocor), dengan keputusan pemilik bila ada biaya.
  - **Ref:** docs/KEAMANAN.md §7 & §15; docs/TERTANGGUH.md T-016
  - **File:** `docs/teknis/TINJAUAN_KEAMANAN_F10.md`, `supabase/tes/mfa.sql`
  - **DoD:** tinjauan tertulis berisi: apakah kode pemulihan mandiri diperlukan (dan bagaimana aman), status nyata pemeriksa HaveIBeenPwned di paket gratis, serta rekomendasi + dampak biaya = nol; keputusan pemilik dicatat.
  - **Kompleksitas:** sedang (2 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: Keamanan Akun (ART-12); keputusan diambil tanpa data → mitigasi: tinjauan memuat bukti (dokumentasi resmi) + uji perilaku.
  - **Verifikasi:** tinjauan ditinjau pemilik + uji MFA tetap hijau.

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

- [ ] T11-11 — Uji peramban (Playwright) 9 alur wajib di CI
  - **Tujuan:** membuktikan alur nyata bisa diklik dari awal sampai akhir tanpa tangan manusia.
  - **Ref:** TECH_SPEC §11 & §9 ART-7/ART-8; AGENT_OPERATING_GUIDE §5
  - **File:** `.github/workflows/e2e.yml`, `uji-e2e/*.spec.ts`
  - **DoD:** 9 alur (buka shift → pesan → dapur → bayar → cetak → void berjenjang → tutup kas, voucher, katalog publik) berjalan di CI dengan data contoh; tangkapan layar & rekaman disimpan sebagai artefak; kegagalan menunjuk langkah & sebabnya.
  - **Kompleksitas:** besar (6 jam)
  - **Risiko & mitigasi:** Chromium **tidak bisa diunduh di ruang kerja agent** (sudah dicoba 2026-09-17) sehingga uji ini hanya jalan di CI → mitigasi: jaring lokal tetap uji komponen + uji SQL; bila CI juga gagal, dilaporkan jujur dan diganti (bukan diklaim hijau).
  - **Verifikasi:** CI hijau + artefak tangkapan layar tiap alur + satu uji mutasi (matikan satu aksi → alur GAGAL).

- [ ] T11-12 — Uji terima keamanan bersama pemilik (naskah W + perangkat nyata)
  - **Tujuan:** pemilik sendiri membuktikan perangkat hilang, PIN salah, dan pencabutan bekerja di perangkat yang sebenarnya.
  - **Ref:** docs/uji/NASKAH_JALAN.md; docs/KEAMANAN.md §14
  - **File:** `docs/uji/NASKAH_JALAN.md`, `docs/uji/HASIL_UJI_TERIMA_KEAMANAN.md`
  - **DoD:** naskah keamanan dijalankan pemilik di Kedai Oasis (perangkat nyata): daftar perangkat · cabut perangkat saat dipakai · PIN salah 5× · kunci otomatis · TOTP · mode dukungan; hasil dicatat (lulus/cacat) dan cacat diperbaiki sebelum pilot.
  - **Kompleksitas:** sedang (3 jam)
  - **Risiko & mitigasi:** pemilik menemukan hal yang tidak nyaman di akhir → mitigasi: naskah keamanan dijalankan **lebih awal** (setelah Fase 2) sebagai uji antara, bukan hanya di akhir.
  - **Verifikasi:** naskah bertanda tangan pemilik (setuju/cacat) + daftar cacat ditutup.

- [ ] T11-13 — Audit adversarial menyeluruh (AUD-3) + kalibrasi cacat tanaman sebelum pilot ⚠️
  - **Tujuan:** pembuktian terakhir sebelum Kedai Oasis memakai sistem: seluruh janji (PRD → kode → uji) diperiksa sesi independen dengan enam lensa, termasuk serangan nyata (perangkat hilang, PIN ditebak, penyewa lain mengintip, uang dikarang).
  - **Ref:** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §2 (AUD-3), §7; `docs/PANDUAN_PEMILIK.md` §3
  - **File:** `docs/uji/paket-audit/AUD-3-<tanggal>.md`, `docs/uji/audit/LAPORAN_AUD-3_<tanggal>_pilot.md`, `docs/uji/AUDIT_RIWAYAT.md`
  - **DoD:** semua enam lensa dijalankan · ≥12 serangan nyata dilakukan · kalibrasi cacat tanaman: semua K-1/K-2 ditemukan & ≥70% total · laporan LOLOS kontrak · temuan K-1/K-2 nol yang terbuka · hasil + angka kalibrasi dicatat di `docs/uji/AUDIT_RIWAYAT.md`.
  - **Kompleksitas:** besar (6 jam)
  - **Risiko & mitigasi:** ⚠️ wajib update `DECISIONS_LOG.md` — Area: seluruh Area Berisiko Tinggi; audit dianggap formalitas → mitigasi: pemeriksa laporan menolak laporan tanpa bukti & kalibrasi menentukan apakah verdict boleh dipercaya; pemilik mengikuti naskah jalan sendiri (`docs/uji/NASKAH_JALAN.md`).
  - **Verifikasi:** laporan AUD-3 LOLOS kontrak + tingkat deteksi kalibrasi memenuhi ambang + naskah jalan pemilik dijalankan di perangkat nyata.

## Checklist kelengkapan sebelum ROADMAP disetujui (Tahap 5)

- [x] Semua fitur **Must Have** M1–M12 punya task: M1 → T9-10 · M2 → T9-01…T9-07 · M3 → T1-05/T1-06/T9-08 · M4 → T3-01…T3-16 · M5 → T4-01…T4-05 · M6 → T5-01…T5-12 · M7 → T7-01…T7-06 · M8 → T7-07…T7-12 · M9 → T4-06/T4-07/T3-07 · M10 → T8-01…T8-14 · M11 → T9-06/T9-09 · M12 → T1-01…T1-22, T2-09/T2-10/T2-12, T10-05/T10-06, T11-05
- [x] Semua **entitas Data Model** punya task migrasi (+seed): T1-01…T1-14 (seluruh tabel dari `TECH_SPEC.md` §4) + seed T1-21
- [x] Semua **API/RPC** punya task endpoint + uji: `simpan_pesanan` T3-05 · `bayar_pesanan` T5-02 · `batal_pesanan` T3-13/T5-06/T5-07 · `buka_shift` T7-01 · `tutup_shift` T7-02 · `cek_voucher` T1-19/T8-09 · `pakai_voucher` T1-20/T8-09 · `katalog_publik` T8-01 · `hitung_total` T1-15/T1-16 · laporan T7-07…T7-12
- [x] Semua **Area Berisiko Tinggi** ada di Fase 1 + bertanda `⚠️` (ART-1 T1-01/T1-04/T1-22 · ART-2 T1-05/T1-06 · ART-3 T1-15/T1-16 · ART-4 T1-18/T3-05 · ART-5 T1-19/T1-20 · ART-6 T1-11/T1-13 · ART-7 T6-01/T6-06/T6-08 · ART-8 T1-14/T10-01/T10-02 · ART-9 T1-17 · ART-10 T1-12/T5-08/T8-01)
- [x] Setup repo, env, lint, uji, CI, deploy: T0-01…T0-03, T0-05, T0-07, T0-09, T0-10, T11-07
- [x] Integrasi pihak ketiga punya task setup + uji: Supabase T0-00/T0-08/T1-* · Google T2-04 · Resend T2-04/T2-05/T8-07 · Cloudflare+Wrangler T0-00/T0-09/T11-07 · pg_cron T10-08
- [x] Hal kecil tidak terlupakan: `README.md` T0-06 · `.env.example` T0-05 · favicon T0-01 · halaman error T2-08 · keadaan memuat/kosong/gagal T0-04/T3-15/T4-10 · a11y T0-04/T3-10/T11-05 · responsif T11-05 · panduan pegawai T11-09 · cadangan T11-10

**Keterangan ❓ (semua ada di `docs/TERTANGGUH.md`):** T-002 (printer) → T6-08, T11-03 · T-003 (perangkat) → T11-04 · T-010 (pelatihan) → T11-09 · T-011 (privasi pelanggan) → T8-07 · Butir T-001 (nama → "Sajian"), T-004, T-005, T-006, T-007, T-008, T-009, **T-012** (cadangan di artefak terenkripsi repo privat) dan **T-013** (penutup shift = Admin Cabang → Owner Pusat) sudah **ditutup** 2026-09-16 (lihat tabel Butir selesai di `docs/TERTANGGUH.md`).

**Jumlah tugas:** F0 15 · F1 45 · F2 19 · F3 16 · F4 10 · F5 12 · F6 8 · F7 12 · F8 15 · F9 12 · F10 16 · F11 13 = **193 tugas**, semuanya ber-7 atribut. (F1 41 → 44 pada 2026-09-17: +T1-42 bantuan kontekstual · +T1-43 Buku Uji Pemilik · +T1-44 perketat paket audit; 44 → **45** pada 2026-09-19: **+T1-45 penutupan temuan putaran verifikasi**.)
| 2026-09-17 (putaran 4) | **Buku pedoman induk + penjaga mesin** (+T0-11 `[x]`) dan **audit menyeluruh lebih dulu** (+T0-12 ⚠️) → **184 tugas**; AUD-3 memakai lingkup menyeluruh (`--semua`) & gerbang `tahan_semua` | Permintaan pemilik: *"sekarang aku mau audit dulu"*; mekanisme harus menyeluruh *"termasuk file2 yang disiapkan untuk pengguna"*; *"satu file untuk pengguna yang betul-betul isinya lengkap… semacam manual book"* |

| 2026-09-17 (putaran 5) | **Mekanisme review PR independen** (T0-13 `[x]`) + **buku pedoman induk v2** (T0-14 `[x]`) → **186 tugas**; ditambah: independensi base branch audit (`--verifikasi-lingkup`), rekam pesan Lee (`docs/teknis/REKAM_PESAN_PEMILIK.md`), panggilan **Lee** | Permintaan Lee: (a) tidak bisa menilai *Files changed* → butuh review PR independen + kartu keputusan; (b) buku masih kurang & cacat (cara, prompt tanpa panduan, prompt yang kata-katanya untuk pengguna); (c) jangan panggil "Bapak"; (d) base branch peninjau jangan harus ditentukan presisi |

| 2026-09-17 (putaran 6b) | **+T1-40** (kerangka bahasa: ID·EN·Mandarin di G1) + **T1-41** (RTL + huruf Mandarin/Arab) + `docs/SPESIFIKASI_UI.md` **§10 bahasa & arah teks** → **189 tugas** | Permintaan Lee: aplikasi multi-bahasa termasuk Mandarin & Arab; diputuskan **Opsi 1** — tiga bahasa di G1, Arab disiapkan kuncinya + tata letak diuji, teksnya G2 |
| 2026-09-17 (putaran 5b) | **+T1-39** (isi PETA_UI semua layar G1) + `docs/SPESIFIKASI_UI.md` **§9 perilaku & gerakan** → **187 tugas** | Jawaban jujur atas pertanyaan Lee: yang belum matang bukan mekanisme kelengkapan UI, melainkan **isinya** (daftar tombol/aksi per layar) dan **spesifikasi gerakan/perilaku** |

> **Catatan 2026-09-17:** angka di atas **diukur ulang** dari berkas ini setelah penyisipan keamanan & kelengkapan UI (+T1-36 jalur pemulihan perangkat · +T1-37 pekerjaan ulang & T1-38 audit independen · +T11-13 audit adversarial)
> (Fase 1B `T1-23…T1-30` · Fase 1C `T1-31…T1-35` · perluasan Fase 2/8/10/11). **Nomor migrasi rencana lama bergeser +7**
> (kas & shift 0011 → **0018**, dst.) supaya 0011–0017 dipakai penyisipan; urutan penerapan mengikuti **urutan tugas**.
> Pelajaran T1-07/…/T1-10 diulang: jumlah tugas **tidak boleh** ditulis dari ingatan — ambil dari hasil pemeriksa.

**Uji terima antar-fase (aturan gelombang):** fase N+1 tidak dimulai sebelum (a) semua tugas fase N `[x]`, (b) uji otomatisnya hijau, (c) `python3 alat/periksa-roadmap.py` lulus, (d) `DECISIONS_LOG.md` diperbarui untuk tugas bertanda ⚠️, (e) ringkasan 5 baris ditulis di LOG_SESI.

## Log Keputusan

| Tanggal | Keputusan | Alasan |
|---|---|---|
| 2026-09-17 | **+3 tugas Fase 1C** (T1-42 bantuan kontekstual · T1-43 Buku Uji Pemilik · T1-44 perketat paket audit) | Permintaan Lee 2026-09-17: bantuan di setiap laman; lembar uji bertahap dengan kolom hasil (ditulis mengikuti proyek + diringkas di chat); serta tiga temuan mekanisme audit yang harus ditutup (B F-09/F-16/F-17) |

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-16 | `ROADMAP.md` ditulis (146 tugas, 11 fase) | Urutan fase disetujui pemilik via delegasi; Tahap 5 selesai |
| 2026-09-16 | Tugas **T0-00** ditambah di awal Fase 0 (pemilik membuat akun Supabase & Cloudflare, dipandu) → 151 tugas | Temuan review independen W5-01: tanpa itu Fase 0 berhenti di T0-08 menunggu sesuatu yang tidak dijelaskan siapa-siapa; akun hanya bisa dibuat pemilik |
| 2026-09-17 | **Mekanisme audit independen ditanam** (`docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`, `alat/audit-independen.py`, `docs/PANDUAN_PEMILIK.md`) + **3 tugas baru**: T1-37 pekerjaan ulang · T1-38 audit independen Fase 1B · T11-13 audit adversarial sebelum pilot → **182 tugas** | Permintaan pemilik: audit/pemeriksaan/review independen yang teliti, terukur, bisa ia picu sendiri; plus kesadaran bahwa pekerjaan lama mungkin perlu diulang (terbukti: AUD-0 menemukan 9 butir kerja ulang) |
| 2026-09-17 | **Penyisipan keamanan & kelengkapan UI** (pesan pemilik ke-14): Fase 1B (peran tunggal, perangkat terdaftar, sesi & pencabutan, percobaan masuk, audit berantai, mode dukungan, matriks izin, pemeriksa keamanan) + Fase 1C (peta layar, registri aksi, pemeriksa peta UI, harness uji komponen, naskah jalan) + perluasan Fase 2 (TOTP, masuk staf, pendaftaran perangkat, kunci otomatis, daftar & cabut perangkat, masuk pengelola, uji masuk) + Fase 8 T8-15 (privasi) + Fase 10 (+4) + Fase 11 (+2) → **178 tugas** | Pemilik meminta matangkan dulu keamanan akun/perangkat & rencana UI sebelum lanjut; dua fase disisipkan **sebelum** Fase 2 supaya pola RLS/cara masuk tidak dibongkar dua kali; rujukan `docs/KEAMANAN.md` |
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
| 2026-09-16 | **T0-10 selesai**: kerangka uji diperkuat (jsdom + @testing-library/react, 51 uji angka saat itu) + pemeriksa baru `aplikasi/alat/periksa-uji.py` yang menolak berkas logika tanpa uji | Tujuan T0-10 adalah TDD sejak awal; risiko “uji hanya formalitas” dijawab dengan gerbang otomatis, bukan janji |
| 2026-09-16 | Aturan baru: **pemulihan setelah ruang kerja dinyalakan ulang** (`aplikasi/alat/pratinjau.sh` + `alat/pulihkan-git.sh`) masuk `AGENT_OPERATING_GUIDE.md` §0 dan prompt pembuka universal | Kejadian nyata: setelah restart, pustaka aplikasi hilang (pratinjau mati) dan salinan Git lokal mundur ke `main` — sesi berikutnya (model apa pun) harus tahu cara memulihkan tanpa menebak |
| 2026-09-19 (putaran verifikasi) | **Tiga cacat nyata ditutup + dua paket peninjau disegarkan**: (1) angka jumlah tugas basi **189 → 192** di `STATUS.md`/`PROJECT_STATE.md` + **Aturan 2** di `alat/periksa-angka-bukti.py` (uji-diri 3 → 5 kasus); (2) `alat/periksa-paket.py` (F-11/F-12) & `alat/periksa-angka-bukti.py` (F-14) kini **dijalankan sungguhan** di CI & `periksa-semua.sh` (dulu hanya uji-dirinya) + checkout `fetch-depth: 0` + gerbang CI **19 → 22**; (3) riwayat review yang bolong (putaran13–15) diisi + **Aturan 3** penjaga riwayat. Paket: audit `AUD-3-2026-09-19` (192 tugas · 117 berkas) & review `PKT-2026-09-19-pr-01-putaran16` (PR #2 · `93a50ba`) | Permintaan Lee: **putaran verifikasi** — dua putaran berturut-turut menemukan cacat nyata, jadi paket peninjau wajib menyegar; cacat yang ditemukan sendiri ditutup lebih dulu supaya peninjau tidak membuang waktu pada cacat yang sudah diketahui |
| 2026-09-19 (laporan peninjau masuk) | **+T1-45** — penutup 25 temuan NYATA dari 2 peninjau independen (AUD-3 `01a0b85b`: 10 temuan; review PR putaran16 `01a0b85b`: 15 temuan) → **193 tugas**; laporan audit **DITOLAK MESIN** karena format label grup (isi tetap dipakai setelah dibantah-balik) | Dua laporan masuk lewat `--ambil-laporan`; setiap temuan diuji ulang dengan probe sendiri (25/25 NYATA, 0 palsu) — K-1: penanda transaksi `resto.pembatalan_*` bisa dipalsukan kasir untuk membatalkan item sesudah dapur tanpa PIN |
