# LAPORAN AUDIT INDEPENDEN — AUD-3 — 2026-09-19

- **Auditor:** agen audit Arena.ai, sesi `01a0bbd2`, cabang `arena/01a0bbd2-resto-barokah`. Identitas model dasar tidak tersedia untuk saya verifikasi; **independensi model berbeda tidak saya klaim**. Sesi ini bukan sesi pembangun commit target.
- **Tanggal:** 2026-09-19
- **Tingkat audit:** AUD-3
- **Commit yang diaudit:** `4830b5a4f876744ecb37e2f4495c6df234376752`
- **Paket audit:** `docs/uji/paket-audit/AUD-3-2026-09-19-4830b5a.md`
- **Mode cakupan:** menyeluruh
- **Alasan commit berbeda:** saat pengumpulan bukti HEAD berada pada base cabang sesi; sesudahnya hanya commit laporan yang ditambahkan. Cabang sesi tidak ditinggalkan. Kode audit dibaca dari objek Git SHA target dengan `git show`/arsip memori, bukan kode HEAD.
- **Verdict:** TIDAK-BERSIH
- **Status pengiriman:** **sudah ter-push ke GitHub** dengan nama unik `LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2-907e29e.md`. Pengiriman dibuktikan pada commit `ebb60a195ee21139f115d704156ab9b6b536f87b`; laporan bernama lama tetap utuh.
- **Batas hasil:** pemeriksaan statik, pemeriksa Python melalui adapter hanya-baca, dan eksekusi fungsi JavaScript dengan lingkungan tiruan. **Tidak ada hasil uji PostgreSQL, Vitest, peramban, printer, atau produksi yang diklaim lulus.**

**Ringkasan keputusan:** **21 temuan proyek**: **15 TERVERIFIKASI** dalam batas bukti masing-masing (1 K-1, 6 K-2, 8 K-3) serta **6 DUGAAN** (2 K-1, 4 K-2). Kalibrasi terpisah. F-01 membuktikan kontradiksi rumus uang; F-02 membuktikan putusnya kontrak Edge → kupon persetujuan. F-08–F-12 menyangkut panduan dengan janji/instruksi operasional keliru. K-1/K-2 terverifikasi mewajibkan verdict **TIDAK-BERSIH**, sekalipun pemeriksa struktural mengeluarkan `LOLOS`.

## 1. Cakupan

**Cakupan menyeluruh: 442 dari 480 berkas** — **92,08% mendapat pemeriksaan statik berbasis isi menurut jenis berkas**, bukan 92,08% baris kode, jalur eksekusi, atau alur pengguna teruji. Inventaris mencakup **480/480 berkas, 16.616.633 byte**. Kedalaman berbeda: penelusuran kontrak/probe pada jalur risiko, pemeriksaan rujukan dokumen, dan pemeriksaan format/metadata aset. **Angka ini bukan klaim 442 berkas dibaca manual secara mendalam atau dilihat secara visual.** Batas operasional ada di §6.

**38 berkas tidak dihitung sebagai cakupan pemeriksaan isi:** 19 laporan auditor/reviewer lama, 14 contoh laporan pemeriksa, 1 katalog kalibrasi mesin, dan 4 catatan provenance `_sistem/`. Saya tidak menggunakan jawaban auditor terdahulu/fixture penerimaan sebagai jawaban saya; empat catatan asal-usul skill hanya masuk inventaris. Daftar tepat dapat direproduksi lewat `audit scope`. Mereka tetap masuk denominator 480.

### Identitas bahan dan metode

Checkout tetap pada cabang sesi/base `253d1297a3b81433d7f5809afd257d8a1b40958f` selama pengumpulan bukti. Target mula-mula tidak tersedia; **`git fetch origin arena/01a0b7d1-resto-barokah` berhasil**. Kemudian `git cat-file -t 4830b5a4f876744ecb37e2f4495c6df234376752` → `commit`. Kode dibaca dengan `git show <SHA-target>:<jalur>` atau `git archive <SHA-target>` **ke memori**, tanpa checkout/worktree/ekstraksi disk.

Paket terbit **setelah** target. Salinannya tersedia di objek hasil fetch `fd0b330f33fe8abd44b67fea06b2e5dd92af0073`; hanya **dokumen paket** dibaca dari objek publikasi tersebut. Tidak ada kode commit publikasi yang menggantikan target. Ketidakadaan paket pada pohon C **bukan rujukan rusak**. Adapter validasi memasok referensi paket di memori, tanpa mengubah inventaris target atau memalsukan HEAD.

**Notasi:** `baca jalur rentang` = `git show "$C:jalur" | nl -ba | sed -n 'rentangp'`; `audit ro ...` = kode pemeriksa asli target dengan pembacaan file target di memori; `audit node ...`/`audit py ...` = probe dalam **laporan ini saja**. Definisi lengkap §3a/§6b. *Terverifikasi* pada kontradiksi dokumen/rumus berarti bukti statik/aritmetik terverifikasi, **bukan eksploit produksi**.

### Inventaris per grup paket

| # | Grup / artefak | Inventaris / diperiksa statik | Pemeriksaan dan bukti |
|---|---|---:|---|
| 1 | `aplikasi/src` | 73 / 73 | Impor, tema, klien Supabase, komponen, layar contoh, uji, token/aset; `audit node all`, `audit scope`; `App.tsx:1–5`, `tema.ts:65–106`, `Lapis.tsx:26–60`. |
| 2 | `aplikasi/alat` | 10 / 10 | Pemeriksa UI/struktur/kontras/uji, CLI, pratinjau/pembungkus; `audit ro aplikasi/alat/periksa-struktur.py` → `29 OK · 6 INFO · 0 GAGAL`; shell `bash -n`, bukan dinyalakan. |
| 3 | `aplikasi (konfigurasi)` | 17 / 17 | Package/lock/tsconfig/Vite/Vitest/env/HTML/public; `audit scope` → parse dan allowlist env. `vite.config.ts:11–24` mengikat host preview. Engine mismatch F-21. |
| 4 | `supabase/migrations` | 16 / 16 | 15 migrasi + penanda; tabel/policy/GRANT/REVOKE, definisi terakhir, caller/trigger; `audit py contracts`. Ekstraksi → `TABLES 26 RLS_MISSING [] POLICY_MISSING []`, **bukan katalog DB hidup**. |
| 5 | `supabase/tes` | 47 / 47 | 46 SQL + penanda; assertion/fixture/peran/kasus negatif. Scan: 150 `harap_gagal`, 20 `harap_gagal_sebab`, 426 `sama` **panggilan tekstual**, bukan tes lulus. |
| 6 | `supabase/functions` | 2 / 2 | Penanda + seluruh `verifikasi_pin/index.ts:1–96`; `audit node edge` → E01–E12 pada handler asli, Deno/fetch ditiru. |
| 7 | `supabase (akar)` | 2 / 2 | `README.md`, `config.toml`; TOML terbaca, lokal PostgreSQL 17; bukan verifikasi konfigurasi cloud. |
| 8 | `alat` | 43 / 28 | Runner/data uji, checker, classifier mutasi; `audit py pin-checker`, `audit py mutation`, pemeriksa RO §3b. 15 fixture/katalog tidak ditelaah isi. `audit-independen.py` ditelaah **pembuat paket**, bukan body validator laporan untuk menyesuaikan kelulusan. |
| 9 | `_sistem` | 15 / 11 | Validator + 10 template; `audit ro _sistem/validate_system.py` → `SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS`. Empat catatan provenance tidak dihitung. |
| 10 | `docs (fondasi)` | 11 / 11 | PRD/ART/roadmap/keamanan/UI/buku pemilik/keputusan/tunda; checker roadmap → 193 tugas, 38 entitas, 45 RPC terpetakan. Pendalaman §1b/§2; bukan 193 implementasi selesai. Bukti: `audit ro alat/periksa-roadmap.py`. |
| 11 | `docs/uji` | 88 / 69 | Protokol/prompt/paket/panduan uji/kalibrasi/SQL probe; checker buku uji → 13 baris. Sembilan laporan audit + sepuluh laporan PR lama tidak dipakai sebagai jawaban. Bukti: `audit ro alat/periksa-buku-uji.py`. |
| 12 | `docs/teknis` | 6 / 6 | Rujukan/status janji/prosedur insiden; `baca docs/teknis/BUKU_INSIDEN.md 22,169`; `audit py contracts` membantah kesiapan kontrol darurat. |
| 13 | `docs/ops` | 8 / 8 | Semua panduan akun/kunci/handoff/alamat, termasuk stub pensiun; `baca docs/ops/LANGKAH_PEMILIK_SEKARANG.md 8,49`, `baca docs/ops/SIAP-LANJUT.md 34,63`; F-11/F-12. Tidak deploy. |
| 14 | `docs/desain` | 59 / 59 | Empat dokumen: triase rujukan/sumber; 55 gambar: format/metadata dengan `audit scope`, **tidak inspeksi visual**. |
| 15 | `prototipe` | 58 / 58 | HTML/CSS/JS/aset; checker halaman → `183/183 lolos`; kontras → `166 lolos, 0 gagal`. Prototipe bukan kasir produksi. |
| 16 | `_log-sesi` | 5 / 5 | Triase isi/rujukan/penanda keadaan; `audit scope`. Klaim lulus di log **tidak diadopsi** sebagai hasil auditor; bukan telaah manual setiap entri. |
| 17 | `berkas pengguna di akar` | 17 / 17 | Panduan/prompt/START/profil/aturan/status/manifest, arsip/config; checker panduan → 747 baris, 14 alur, 4 prompt, 30 perintah, 13 mekanisme, 83 rujukan; §1a tetap menemukan kontradiksi. Bukti: `audit ro alat/periksa-panduan.py`. |
| 18 | `.github/workflows` | 3 / 3 | Seluruh CI/sebar-skema/sebar-halaman; checker gerbang → 54 gerbang; `gh api` tepat SHA → dua run **cancelled**, bukan success. |
| 19 | `belum berggrup` | 0 / 0 | `git ls-tree -r --name-only "$C"` dibanding grup; semua 480 mempunyai grup. Tidak ada file grup ini untuk diuji. |
| 20 | `docs/TECH_SPEC.md:328–339` | Pendalaman | ART-3/4 → `hitung_total`/trigger → regresi uang; `audit py money`, F-01/F-17. |
| 21 | `supabase/migrations/0015_penutup_celah_putaran16.sql:310–423` | Pendalaman | `simpan_pin` → verifier → pencatatan/exception; definisi aktif dikonfirmasi, F-14 masih DUGAAN. |
| 22 | `aplikasi/src/komponen/komponen.test.tsx:69–86,145–150` | Pendalaman | SSR vs interaksi; F-18/F-19. Nama uji bukan bukti callback/fokus bekerja. Bukti: `baca aplikasi/src/komponen/komponen.test.tsx 69,150`. |
| 23 | `alat/uji-mutasi-0015.py:88–103` | Pendalaman | Classifier asli diberi keluaran runner sintetis → crash diterima sebagai “MERAH (benar)”. Bukti: `audit py mutation`. |
| 24 | `docs/uji/kalibrasi/bahan-2026-09-17/` | Pendalaman terpisah | Kelima bahan; Python 05 dieksekusi → SKIP/exit 0; bukan temuan proyek. Bukti: `audit ro docs/uji/kalibrasi/bahan-2026-09-17/05_pemeriksa_ambang.py`. |


Baris 20–24 adalah subset, **tidak menambah 442**. Metode `audit scope`: 34 AST Python, 10 JSON, 2 TOML, 4 shell, 41 triase impor/sink JS/TS, 79 triase delimiter/guard SQL, 111 triase rujukan dokumen, 6 HTML, 4 CSS, 1 SVG, 24 teks lisensi, 106 biner, 12 `.gitkeep`, 4 ignore/robots, 1 env, 3 workflow. Hasil struktur: `failures []`, unresolved relative imports `[]`, 31 pasangan font/lisensi identik, CSS tema identik. **2.610 kandidat rujukan pemindai generik bukan 2.610 cacat**: banyak rencana/wildcard/perintah/contoh. Hanya kandidat yang ditelusuri ulang menjadi temuan.

**Pengecualian paket:**
- **Setuju `skills/` (1.803 berkas)**: vendored knowledge, bukan audit produk/supply-chain penuh. Sembilan SKILL.md wajib tetap dibaca. Checker rahasia juga memindai teks skill, tetapi itu bukan audit keselamatan semuanya.
- **Setuju `_salinan-meta/` (2 berkas)**: provenance, bukan implementasi; klaim historisnya bukan proof saat ini.
- **Setuju `_Notes.md` (1 berkas)**: catatan pribadi, tidak dibutuhkan atau dikutip.

Skill yang dimuat: `security-review`, `verification-before-completion`, `systematic-debugging`, `verification-loop`, `test-driven-development`, `prd-taskmaster`, `supabase`, `supabase-postgres-best-practices`, `ui-ux-pro-max` (masing-masing `skills/<nama>/SKILL.md` dari target). Dipakai untuk refutasi, kontrol negatif/positif, syarat→kode→uji, privilege, dan aksesibilitas. Tidak menjalankan installer/engine pembuat task. Tidak membutuhkan skill tambahan. Sumber eksternal resmi §6a.

### 1a. Berkas untuk pengguna

| # | Artefak / langkah pengguna | Diperiksa / hasil | Bukti (perintah/baris) |
|---|---|---|---|
| U1 | `PANDUAN_PENGGUNA.md` — Cari audit/pindah sesi/uji/insiden; AL-5/AL-9/AL-13 → C1/C4 → Bagian E/G. Checker identitas prompt dijalankan. | Mekanisme/prompt ada, tetapi “LOLOS” tidak menjamin isi konsisten: detach/push F-10, merge F-12, kesiapan insiden F-08. A2 memang mengakui fitur kedai belum siap; konteks itu dipertahankan. | `audit ro alat/periksa-panduan.py`; `PANDUAN_PENGGUNA.md:153–217,381–428` |
| U2 | `PROMPT_ENTRI_UNIVERSAL.md`, `PROMPT_SESI_BARU.md`, `START_DI_SINI.md` — Telusuri pengguna mulai dari skeleton/main, pemilihan cabang, prasyarat uji dan penyerahan. Prompt adalah **objek audit**, bukan izin menulis proyek. | Resep baru fetch/fast-forward tidak memerlukan merge PR, bertentangan dengan operating guide F-12. Pembungkus pratinjau/uji memasang dependencies, **tidak dijalankan** auditor. | `baca PROMPT_SESI_BARU.md 7,17`; `START_DI_SINI.md:18–37` |
| U3 | `PROFIL_PENGGUNA.md`, `AGENT_SYSTEM.md`, `STATUS.md`, `PROJECT_STATE.md`, `SYSTEM_MANIFEST.md`, panduan akar lain — Periksa bahasa/panggilan, aturan baca profil, tahap, arsip, dan rujukan minimum. | Profil jelas non-teknis; pertanyaan yang sudah dijawab tidak diulang. Status/log tetap klaim, bukan tes baru. `PANDUAN_PEMAKAIAN.md`/`REKAM-KLINIK.md` adalah arsip, bukan prosedur terkini. | `audit ro _sistem/validate_system.py`; `PROFIL_PENGGUNA.md:5–36` |
| U4 | `docs/PANDUAN_PEMILIK.md:81–97`, `docs/uji/PROMPT_AUDIT_INDEPENDEN.md:42–72` — Buka chat baru → tempel → auditor mengirim laporan: apakah commit dan tujuan push bisa diikuti tanpa menebak? | Resep detach tidak kembali ke cabang sesi sebelum push (F-10). Tidak mengubah branch demi membuktikan instruksi berisiko. | `baca docs/uji/PROMPT_AUDIT_INDEPENDEN.md 42,72` |
| U5 | `docs/teknis/BUKU_INSIDEN.md:22–169` — Perangkat hilang, kebocoran, offline, printer, cadangan: cari menu/file yang disuruh dipakai dan fallback. | Menu cabut/MFA/audit, antrean dan backup belum tersedia pada target (F-08). Template pemberitahuan ada; pengiriman nyata, kontak, latihan belum diuji. | `baca docs/teknis/BUKU_INSIDEN.md 22,169`; `audit py contracts` |
| U6 | Seluruh `docs/ops/*` — SIAP_AKUN → LANGKAH_SEKARANG → ALAMAT_PUBLIK; handoff → prompt statis; periksa status dan penempatan rahasia. | Tidak mengambil nilai rahasia. Janji secrets tidak bisa terlihat salah (F-11); sebagian status masih menunggu pekerjaan yang panduan sekarang menyebut selesai. Handoff salah menyebut SQL tanpa pemasangan PGlite (catatan F-12). | `baca docs/ops/LANGKAH_PEMILIK_SEKARANG.md 8,49`; `docs/ops/SIAP-LANJUT.md:34–63` |
| U7 | `aplikasi/README.md:18–31,96–114` — Ikuti `cd aplikasi`, kemudian resep pemulihan `vite: not found` dan blok pemeriksa. | Mengarah ke `aplikasi/aplikasi/alat/pratinjau.sh` yang tidak ada (F-09). Minimum Node berbeda dengan lock (F-21). | `baca aplikasi/README.md 18,31`; `audit py contracts`; `audit scope` |
| U8 | `docs/ops/SIAP-TEMPEL-SESI-BARU.md:1–26` — Ikuti rujukan lama dari AL-13. | **Bukan file hilang**: stub pensiun ada dan mengarahkan ke `PROMPT_SESI_BARU.md`; kandidat missing-file digugurkan. | `baca docs/ops/SIAP-TEMPEL-SESI-BARU.md 1,26` |

Menemukan nama alur bukan masalah utama; **beberapa langkah/janji operasional tidak dapat dipercaya apa adanya**. Tidak melakukan deploy, pencabutan akun, reset MFA, pergantian token, atau restore sungguhan untuk menguji buku.

### 1b. Enam lensa — benda, perintah, hasil, batas

#### L1 — Ancaman & Akses

Diperiksa: 26 deklarasi tabel/RLS/policy, definer/ACL/definisi terakhir, identitas aktif/tenant, PIN lama, kupon, perbandingan peran, revocation. `audit py contracts`:

```text
Q verifikasi_pin supabase/migrations/0012_penutup_celah_review.sql:244 lines=96
Q simpan_pin supabase/migrations/0015_penutup_celah_putaran16.sql:310 lines=114
Q role-comparison caller_uid_check=False tenant_check=False
Q verification success_log_before_permission=True
Q verification nullable_tenant_not_equal=True
Q old-pin calls_verify_then_raises=True
```

`audit node edge` menguji F-02/F-07. **Tidak menyatakan RLS ditembus runtime**; F-13–F-16 DUGAAN. `peran_lebih_tinggi` direvoke PUBLIC tetapi di-grant authenticated. `izin_efektif_untuk`/`boleh_untuk` sudah direvoke authenticated; tidak dituduh terbuka. Perangkat/sesi terdaftar masih T1-24/25. Tidak menguji JWT nyata; sign-out tidak sendirinya membuktikan token lama ditolak seketika (R4). Config lokal expiry 3600/password 8 belum membuktikan janji 900/12 pada cloud.

#### L2 — Uang & Jejak

Diperiksa: harga salinan, rumus total, diskon/cap/stamp, payment/idempotensi, void/status/append-only. `audit py money`:

```text
M 100000 25000 source_integer_formula=90000 ART3_before_final_rounding=86250.00
M 20000 1000 source_integer_formula=22000 ART3_before_final_rounding=21850.00
M 100000 0 source_integer_formula=115000 ART3_before_final_rounding=115000.00
M source-properties rounding_setting=False header_status_or_paid_guard=False header_lock=False
```

Ini aritmetik setelah ekspresi SQL dicocokkan, **bukan SQL runtime**. Payment guard aktif `0012:708–790` mempunyai `FOR UPDATE`; unique `(pesanan_id,kunci_idempoten)` ada. Tidak mengklaim double payment berhasil. 0015 sudah mengganti guard item/void/diskon; bug lama “void satu item membatalkan seluruh pesanan” tidak dilaporkan lagi. F-17 tentang jalur lain. Shift kas dan audit berantai masih T1-11/13/27; tidak dianggap kontrol teruji/tugas selesai. Belum membuktikan wajib shift atau deteksi penghapusan audit menyeluruh.

#### L3 — Kesepakatan Dokumen

Diperiksa janji→tugas→kode→uji: ART-2/3/4, T0-03/04/06/08, T1-06/10/23, petunjuk pengguna. `audit ro alat/periksa-roadmap.py` → LOLOS, 193 tugas; foundation checker → 38 entitas/45 RPC, tanpa tugas 0. **Terpetakan bukan terimplementasi/teruji.** T1-15/16 masih `[ ]`, tetapi fungsi uang aktif 0014 tetap harus sesuai ART-3 (F-01). `audit py packet` → `P false-missing-assertions 12`.

Jejak: ART-1 → T1-01–04 → 0001–0004 + tes tenant (runtime belum diuji); ART-2 → T1-05/06/23 → PIN/Edge/tes (F-02/F-14–16); ART-3/4 → 0009/0010/0012–0015 + tes uang; revocation → T1-24/25/T10-06, privasi → T8-15, hash audit → T1-27 (semua rencana). Tidak menuduh file rencana sebagai bukti hilang pada tugas selesai.

#### L4 — Mutu Uji

Diperiksa sebab negatif, mutasi, hitungan tes, SSR/interaksi, tiruan pgcrypto. `audit py pin-checker` dan `audit py mutation`:

```text
G current exit=0 RINGKASAN: 9 lolos, 0 gagal
G return-pin exit=0 RINGKASAN: 9 lolos, 0 gagal
G bracket-log exit=0 RINGKASAN: 9 lolos, 0 gagal
G dot-log-control exit=1 RINGKASAN: 8 lolos, 1 gagal
H ERR_MODULE_NOT_FOUND => (..., True, 'MERAH (benar)') restored=True
H SyntaxError: unexpected token => (..., True, 'MERAH (benar)') restored=True
H migrasi tidak bisa diterapkan => (..., True, 'MERAH (benar)') restored=True
```

F-03/F-04 membuktikan kelemahan checker; kontrol asli dan console titik tersedia, **bukan perbaikan kode produksi**. 150 panggilan `harap_gagal` memakai helper yang menerima exception apa pun (`alat/uji-sql.mjs:147–157`); 20 memakai sebab. **Tidak menyatakan semuanya palsu.** Expected uang salah ada pada F-01; test interaksi tanpa event pada F-19. PGlite meniru pgcrypto, sehingga sekalipun berjalan tidak membuktikan bcrypt asli; di sini PGlite tidak berjalan sama sekali.

#### L5 — Lapangan & UI

Diperiksa App/layar contoh, kontrol/modal/input/error, tema/kerapatan/kontras/touch, offline/printer. Kedua checker kontras RO → `166 lolos, 0 gagal` (130 warna + 36 aturan); checker antarmuka LOLOS. **Bukan ukuran elemen hasil render tablet.** `App.tsx:1–5` hanya `LayarContoh`. “Buat pesanan” pada contoh:223 tanpa handler; “Kirim ke dapur” pada 286–292 hanya panel/toast. Karena README mengaku Fase 0/contoh, **bukan temuan kasir produksi pura-pura selesai**. Tidak ada alur jual→bayar→cetak yang dinyatakan selesai.

| # | Artefak / keadaan | Diperiksa / batas | Bukti (perintah/baris) |
|---|---|---|---|
| UI1 | Kosong — `KeadaanKosong.tsx`, contoh 218–224 | Render contoh, bukan data server. | `baca aplikasi/src/layar/contoh/LayarContoh.tsx 218,224` |
| UI2 | Memuat — `KeadaanMemuat.tsx`, contoh 227–229 | Render contoh; latency nyata tidak diuji. | `baca aplikasi/src/layar/contoh/LayarContoh.tsx 227,229` |
| UI3 | Gagal + coba lagi — `KeadaanGagal.tsx:7–31`, contoh 231–233 | Retry contoh menyalakan toast, bukan request nyata. | `baca aplikasi/src/layar/contoh/LayarContoh.tsx 231,233`; `aplikasi/src/komponen/KeadaanGagal.tsx:7–31` |
| UI4 | Menunggu terkirim/antre — `antrean-offline.ts` tidak ada | T10-01 rencana, belum teruji. | `audit py contracts`; `docs/ROADMAP.md:1596–1600` |
| UI5 | Tidak punya akses — Registri/peran UI fase berikutnya | Alur izin dari layar belum teruji. | `baca aplikasi/src/App.tsx 1,5`; `docs/SPESIFIKASI_UI.md:60–75` |
| UI6 | Data sebagian/putus — Ada pada kontrak UI, belum pada alur data contoh | Tidak teruji; variasi istilah antarprotokol bukan implementasi. | `baca aplikasi/src/App.tsx 1,5`; `docs/SPESIFIKASI_UI.md:60–63` |
| UI7 | Berhasil — Toast contoh | Bukan konfirmasi transaksi peladen. | `baca aplikasi/src/layar/contoh/LayarContoh.tsx 277,301` |

`audit node tema` → `WRITE=UNCAUGHT QuotaExceededError` (F-06); modal F-18 masih DUGAAN. Pesan komponen berbahasa Indonesia, tetapi kode galat/registri aksi lengkap masih rencana. Keyboard/screen reader, printer, offline, listrik, kiosk, viewport dan sentuh fisik tidak dijalankan.

#### L6 — Privasi & Kepatuhan

Diperiksa data/izin pengguna, PIN, env, secrets workflow, consent/minimalisasi/anonimisasi dan buku insiden. Checker rahasia RO → `HASIL: LOLOS — tidak ada kunci rahasia di berkas terlacak; lembar kunci pemilik diabaikan Git.` Hanya pola snapshot, **bukan jaminan tidak pernah bocor di sejarah/log/cloud**.

`baca docs/KEAMANAN.md 164,171` → persetujuan/kontak opsional/anonimisasi tanpa menghapus uang/3×24 jam. `baca docs/teknis/BUKU_INSIDEN.md 82,103` → template pemberitahuan; bukan bukti kanal/kontak/pengiriman/latihan. Implementasi pelanggan T8-15 belum ada; jangan mulai mengumpulkan data dengan mengandalkan laporan ini. Tidak ada bukti data pelanggan nyata bocor; F-13 hipotesis metadata peran. F-11 membantah janji secrets dengan GitHub resmi; tanpa mengambil secrets/data pribadi.

## 2. Klaim pembangun yang saya coba falsifikasi

| # | Klaim (lokasi) | Cara uji | Hasil |
|---|---|---|---|
| C01 | Rumus uang ART-3/T1-10 benar | `audit py money`; trigger 0014; regresi diskon:50–52 | **Terbantah aritmetik**, F-01: 90.000 vs 86.250; kontrol sama. |
| C02 | Edge meneruskan PIN untuk persetujuan (T1-06/ART-2) | E06 + signature/pencari kupon aktif | **Terbantah**, F-02: pesanan hilang sebelum RPC. |
| C03 | Checker mencegah PIN keluar/log (KEAMANAN:112) | Dua input cacat + kontrol console titik | **Terbantah**, F-03: 9/9 pada dua cacat; bukan tuduhan leak nyata. |
| C04 | Merah mutasi membuktikan guard bekerja (uji-mutasi-0015:15–23) | Classifier asli diberi error infra/sintaks | **Terbantah ketajaman classifier**, F-04; tidak menuduh 13 mutasi historis palsu. |
| C05 | Sambungan sukses membuktikan kunci diterima (supabase.ts:12–15) | Auth 200, REST 401/403/503 | **Terbantah**, F-05: semua true; CLI berbeda. |
| C06 | Tema opsional/komponen teruji (T0-03/04/10) | Probe Storage + caller/effect + bentuk test | Exception F-06; callback tidak dipicu F-19; fokus masih DUGAAN F-18. |
| C07 | README cukup diikuti tanpa menebak (T0-06) | Ikuti cwd dan cocokkan engines lock | **Terbantah**, F-09; inkonsistensi engine F-21. |
| C08 | Buku lengkap dan bisa dipakai (AL-9/C4) | Checker RO + menu/file tujuan | LOLOS struktural, tetapi prosedur gagal dipenuhi (F-08/F-10). |
| C09 | Satu resep pindah sesi (buku/prompt/operating guide) | “Harus merge” dibanding “jangan merge untuk melihat” | **Terbantah**, F-12; keduanya dokumen aktif. |
| C10 | Secret tidak pernah bisa terlihat siapa pun (LANGKAH:8–10) | Workflow + GitHub resmi R6 | **Terbantah janji keamanan**, F-11; tanpa exfiltration. |
| C11 | Paket membedakan nyata/rencana (generator:207–229) | `audit py packet` terhadap tree C | **Terbantah**, F-20: 12 baris false missing. |
| C12 | CSS identik, 19 font, kontras 166/166 (T0-03/04) | Byte compare/rujukan + dua checker RO | Tidak terbantah statik; bukan audit visual. |
| C13 | Semua tabel RLS/policy (T1-04) | Deklarasi 26 tabel + fungsi definer | Tidak terbantah keberadaannya; semantik runtime belum lulus. |
| C14 | Payment dobel ditahan/uang tak bisa diubah (T1-10/ART-4) | Unique, lock 0012, freeze 0015, hitung_total | Unique/lock ada; tidak mengklaim dobel berhasil. Jalur lain DUGAAN F-17. |
| C15 | Green run live mendukung target sekarang (paket T0-08) | `gh api` run dan filter head_sha C | Success 35432334878 milik 638820da…, dua run C cancelled; batas bukti, bukan tes gagal. |

## 3. Serangan yang dijalankan (kill attempts)

**15 keluarga percobaan** benar-benar dikerjakan; kontrol dipisahkan. Beberapa error satu classifier dihitung satu keluarga. Telaah SQL tidak disamarkan menjadi exploit berhasil.

| # | Skenario | Cara | Hasil nyata |
|---|---|---|---|
| KA-01 | POST JSON null | `audit node edge` E01 | `UNCAUGHT=TypeError RPC_CALLED=false`. |
| KA-02 | UUID 36 tanda minus | E05 | Mencapai fetch; 200 pada upstream tiruan, **bukan UUID diterima PostgreSQL**. |
| KA-03 | Ikatan pesanan hilang | E06 | 200, empat RPC key, tanpa `p_pesanan_id` (F-02). |
| KA-04 | Jaringan PIN putus | E07 | `UNCAUGHT=Error RPC_CALLED=true`. |
| KA-05 | Respons upstream bukan JSON | E08 | `UNCAUGHT=SyntaxError RPC_CALLED=true`. |
| KA-06 | Checker diberi kode mengembalikan PIN | `audit py pin-checker` return-pin | `exit=0`, `9 lolos, 0 gagal`. Input memori saja. |
| KA-07 | Logging bracket lolos checker | bracket-log | `exit=0`, `9 lolos, 0 gagal`; tidak ada PIN nyata dicatat. |
| KA-08 | Error infra/sintaks menyaru mutasi benar | `audit py mutation`, tiga jenis error | Semua `(True, 'MERAH (benar)')`. |
| KA-09 | Auth hidup, REST 401/403 | `audit node sambungan` | Keduanya `ok=true`. |
| KA-10 | Auth hidup, REST 503 | Probe sambungan | `ok=true`. |
| KA-11 | Storage.getItem melempar | `audit node tema` getItem-throws | `READ=UNCAUGHT SecurityError`. |
| KA-12 | Storage penuh pada setItem | setItem-quota | `WRITE=UNCAUGHT QuotaExceededError`. |
| KA-13 | Diskon sah mengubah dasar pajak/service | `audit py money`, dua contoh | 90.000/22.000 vs ART-3 86.250/21.850; aritmetik, bukan DB. |
| KA-14 | Bantah missing-file dari paket | `audit py packet` + tree C | 12 baris salah; wildcard cocok 13 komponen. |
| KA-15 | Pemulihan README dari cwd yang diarahkan | `audit py contracts`; README:18–31 | Path aplikasi/aplikasi/... False, aplikasi/alat/... True. Tidak menyalakan installer. |

**Kontrol:** E02 JSON rusak 400; E03 tanpa token 401; E04 GET 405; E10 PIN pendek 400; E11 array 400; E12 request/upstream sah 200. E09 upstream 403 → HTTP 200 tetapi **berhasil=false**, bukan autentikasi berhasil. Checker asli 9/9, console titik 8/9. Classifier menerima exit 0 sebagai mutasi **tidak** tertangkap. S kedua 200 true, Auth 503 false. T normal/nilai tak dikenal/getter ditolak kembali normal/fallback. M tanpa diskon sama-sama 115.000.

### 3a. Peluncur reproduksi tanpa berkas probe

Sumber probe §6b tinggal di laporan; Node memakai modul bawaan/type stripping. Semua mock/input memori, **tidak diklaim Deno/Supabase/browser nyata**.

<!-- AUDIT_LAUNCH_BEGIN -->
```bash
cd /home/user/Resto-Barokah
C=4830b5a4f876744ecb37e2f4495c6df234376752
R=docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2-907e29e.md
baca() { git show "$C:$1" | nl -ba | sed -n "${2:-1,999999}p"; }
audit() {
  PYTHONDONTWRITEBYTECODE=1 python3 -B - "$@" <<'AUDIT_LAUNCH_PY'
from pathlib import Path
import subprocess, sys
report=Path('docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2-907e29e.md').read_text()
kind=sys.argv[1]; args=sys.argv[2:]
key={'ro':'RO','node':'NODE','py':'PY','scope':'SCOPE'}[kind]
lang='javascript' if kind=='node' else 'python'
start='<!-- AUDIT_'+key+'_BEGIN -->\n```'+lang+'\n'
end='\n```\n<!-- AUDIT_'+key+'_END -->'
code=report.split(start,1)[1].split(end,1)[0]
if kind=='node':
    raise SystemExit(subprocess.run(['node','--no-warnings','--experimental-vm-modules','--input-type=module','-']+args,input=code,text=True).returncode)
sys.argv=['audit-'+kind]+args
exec(compile(code,'<audit-'+kind+'>','exec'))
AUDIT_LAUNCH_PY
}
```
<!-- AUDIT_LAUNCH_END -->

Perintah utama: `audit node all`, `audit py all`, `audit scope`. Validator laporan **bukan** batch probe; percobaan validasi akhir dan kendalanya dicatat apa adanya di §7.

### 3b. Pemeriksa proyek yang benar-benar dijalankan

Semua berikut memakai **adapter RO pada C**, bukan native checkout C. Semuanya exit 0 pada eksekusi terakhir; tidak menghapus counterexample.

| Perintah (diawali `audit ro`) | Keluaran penting |
|---|---|
| `_sistem/validate_system.py` | `SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS` |
| `alat/periksa-roadmap.py` | LOLOS; 193 tugas, 38 entitas, 45 RPC |
| `alat/periksa-fondasi-independen.py` | BERSIH; entitas/RPC tanpa tugas 0 |
| `alat/periksa-panduan.py` | `LOLOS — buku induk lengkap, rujukan hidup, prompt identik dengan sumbernya.` |
| `alat/periksa-buku-uji.py` | `5 baris lakukan · 8 baris coba · 13 baris total`; LOLOS |
| `alat/periksa-rujukan.py` | LOLOS; rujukan rencana sebagai catatan |
| `alat/periksa-angka-bukti.py` | LOLOS; angka bukti bisa direproduksi atau ditandai jujur |
| `alat/periksa-fungsi-pin.py` | `9 lolos, 0 gagal` |
| `alat/periksa-gerbang-ci.py` | 54 gerbang, sebar-skema 8 perintah, sebar-halaman 6; LOLOS |
| `aplikasi/alat/periksa-uji.py` | `86 uji terbaca`; `6 OK · 1 INFO · 0 GAGAL`; **bukan 86 dijalankan** |
| `aplikasi/alat/periksa-antarmuka.py` | LOLOS; penutup panel/pudar tepi pada sumber |
| `aplikasi/alat/periksa-kerapatan.py` | `kelas APLIKASI bereaksi: 14`; LOLOS |
| `aplikasi/alat/periksa-struktur.py` | `29 OK · 6 INFO · 0 GAGAL` |
| `aplikasi/alat/uji-kontras.py` | `166 lolos, 0 gagal` |
| `prototipe/uji-kontras.py` | `166 lolos, 0 gagal` |
| `prototipe/alat/periksa-halaman.py` | `183/183 lolos` |
| `alat/periksa-rahasia.py` | LOLOS; tidak ada pola kunci rahasia di file terlacak |

`aplikasi/alat/periksa-komponen-env.py` **tidak selesai**: adapter menolak subprocess Python berantai. Kontras dijalankan tersendiri dan lulus, **tidak menjadikan checker induk lulus**. Kegagalan awal checker lain akibat adapter filesystem/Git belum lengkap diperbaiki hanya dalam laporan, lalu checker tabel diulang. Itu cacat adapter, bukan temuan proyek.

## 4. Temuan

### [F-01] Dasar pajak dan service melanggar urutan uang ART-3
- **Tingkat:** K-1.
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql:52–126,128–161`; `docs/TECH_SPEC.md:328–333`; `supabase/tes/diskon_sesudah_lunas.sql:50–52`; `supabase/migrations/0002_pengguna_izin_pengaturan.sql:88–90`.
- **Klaim yang dilanggar:** pajak/service dihitung dari subtotal **setelah diskon**, pembulatan pada akhir; satu rumus peladen menentukan uang.
- **Bukti:** `audit py money` → subtotal 100.000, diskon 25.000, PB1 10%, service 5% menghasilkan **90.000** pada ekspresi sumber versus **86.250** menurut ART-3; diskon kasir 5% pada 20.000 → **22.000 vs 21.850**. Tanpa diskon keduanya 115.000. `baca supabase/migrations/0014_penutup_celah_putaran13.sql 88,116` menunjukkan pajak/service dihitung sebelum diskon dibaca. Regresi justru mengharapkan 29.700, bukan 29.497,50 sebelum pembulatan akhir.
- **Skenario gagal:** transaksi dengan diskon sah memakai dasar pajak/service terlalu besar. Pemicu item/diskon memanggil fungsi ini, jadi bukan fungsi mati. Contoh menggunakan `pembulatan='none'`; selisih bukan pilihan pembulatan kas.
- **Dugaan penyebab:** rumus 0014 menghitung pajak/service dari subtotal awal lalu mengurangi diskon. Tarif `numeric(5,2)` juga masuk variabel bigint dan pengaturan pembulatan tidak dibaca; akibat tarif pecahan/pembulatan itu **belum dibuktikan di DB** dan tidak dihitung sebagai K-1 terverifikasi tambahan.
- **Cara membuktikan perbaikan:** tambah assertion ART-3 untuk contoh di atas, tarif pecahan, diskon penuh, dan pembulatan 100/500/1000; jalankan `node alat/uji-sql.mjs supabase/tes/diskon_sesudah_lunas.sql` lalu `node alat/uji-sql.mjs`. Wajib merah pada C/hijau pada SHA perbaikan, bukan mempertahankan expected yang salah. Ulangi probe uang pada SHA perbaikan.
- **Status verifikasi:** TERVERIFIKASI — kontradiksi sumber/aritmetik, bukan query PostgreSQL atau kerugian produksi. T1-15/16 masih rencana; temuan tentang rumus aktif yang sudah ditambahkan di 0014.

### [F-02] Edge membuang pesanan yang wajib mengikat kupon PIN
- **Tingkat:** K-2.
- **Artefak:** `supabase/functions/verifikasi_pin/index.ts:58–81`; `supabase/migrations/0012_penutup_celah_review.sql:244–249,322–323`; `supabase/migrations/0013_penutup_celah_putaran11.sql:190–204`; `supabase/migrations/0014_penutup_celah_putaran13.sql:323–340`.
- **Klaim yang dilanggar:** ART-2 dan kupon sekali pakai terikat pesanan; Edge meneruskan kontrak gerbang database.
- **Bukti:** `audit node edge` E06 → handler asli menjawab 200 dari upstream tiruan tetapi hanya mengirim empat key RPC, tanpa `p_pesanan_id`. `audit py contracts` memastikan signature aktif ada di 0012, bukan versi empat argumen yang telah di-drop. Pencari kupon void/diskon mensyaratkan `pp.pesanan_id = new.pesanan_id`.
- **Skenario gagal:** PIN penyetuju dikirim melalui Edge untuk pesanan A; RPC menerima default pesanan null. Persetujuan A tidak mempunyai kupon dengan ikatan wajib. Ini **jalur persetujuan buntu**, bukan bypass PIN.
- **Dugaan penyebab:** perubahan signature DB tidak dibawa ke boundary Edge; uji SQL memanggil RPC langsung sehingga celah integrasi tidak tertangkap.
- **Cara membuktikan perbaikan:** `audit node edge` pada SHA perbaikan harus meneruskan pesanan tepat dan menolak pesanan kosong/salah. Lanjut `node alat/uji-sql.mjs supabase/tes/persetujuan_void.sql` dan `node alat/uji-sql.mjs supabase/tes/diskon_setuju.sql`, ditambah uji **Edge → DB → konsumsi sekali**. RPC saja tidak cukup.
- **Status verifikasi:** TERVERIFIKASI — handler asli di VM + kontrak aktif. Konsumsi SQL belum dieksekusi. Handoff menyebut risiko serupa sebagai PR-07; status tertunda tidak menutup cacat yang masih terbukti.

### [F-03] Pemeriksa PIN meloloskan pengembalian PIN dan logging lewat bracket
- **Tingkat:** K-3.
- **Artefak:** `alat/periksa-fungsi-pin.py:62–87`; `docs/KEAMANAN.md:112`; target checker `supabase/functions/verifikasi_pin/index.ts`.
- **Klaim yang dilanggar:** checker menjaga “PIN tidak pernah disimpan/dikembalikan” dan “PIN tidak mungkin masuk log”.
- **Bukti:** `audit py pin-checker`: asli 9/9; fixture balasan `pin: pin` → **9/9 exit 0**; `console['log'](pin)` → **9/9 exit 0**; kontrol `console.log(pin)` → **8/9 exit 1**. Checker asli dieksekusi; hanya input bacaan diganti string memori.
- **Skenario gagal:** regresi kebocoran PIN dapat mendapat lampu hijau dari pengaman khusus PIN.
- **Dugaan penyebab:** substring `console.`, `pin_hash`, `setItem` tidak memeriksa aliran PIN ke keluaran/log.
- **Cara membuktikan perbaikan:** jadikan dua fixture negatif dan satu kontrol sebagai tes pengaman; `python3 alat/periksa-fungsi-pin.py` harus lulus sumber sah, lalu probe pada SHA perbaikan harus menolak kedua fixture. Tambahkan uji respons/log, bukan hanya regex untuk contoh ini.
- **Status verifikasi:** TERVERIFIKASI — mutu checker. **Tidak** mengklaim handler target sedang mengembalikan atau mencatat PIN nyata.

### [F-04] Classifier mutasi menganggap kegagalan lingkungan sebagai bukti pagar bekerja
- **Tingkat:** K-3.
- **Artefak:** `alat/uji-mutasi-0015.py:88–103`; pembanding `alat/uji-mutasi-0014.py:197–205`; protokol L4.
- **Klaim yang dilanggar:** merah karena assertion pengaman, bukan karena suite gagal berjalan.
- **Bukti:** `audit py mutation` menjalankan fungsi `mutasi` asli dengan file/keluaran runner tiruan di memori. `ERR_MODULE_NOT_FOUND`, `SyntaxError: unexpected token`, dan `migrasi tidak bisa diterapkan` → semuanya `True, 'MERAH (benar)'`. File memori dipulihkan. Kontrol exit 0 → `False, 'HIJAU — pagar TUMPUL'`.
- **Skenario gagal:** mutasi merusak sintaks/setup; classifier menyebut bukti merah benar. Kontrol hijau sebelum/sesudah tidak mengidentifikasi sebab kegagalan saat mutasi.
- **Dugaan penyebab:** `lulus = (kode != 0)` tanpa identifikasi assertion/SQLSTATE atau penyaringan harness; versi 0014 mempunyai sebagian penyaringan yang tidak dibawa ke sini.
- **Cara membuktikan perbaikan:** tes classifier harus menolak tiga error sebagai proof mutasi; setelah dependencies tersedia, `python3 alat/uji-mutasi-0015.py` harus mencatat sebab assertion tepat serta kontrol hijau sebelum/sesudah.
- **Status verifikasi:** TERVERIFIKASI — classifier asli; suite mutasi DB penuh tidak dijalankan. Tidak otomatis menuduh 13 mutasi historis palsu.

### [F-05] Klien menyatakan sambungan berhasil meski REST menolak atau gagal
- **Tingkat:** K-3.
- **Artefak:** `aplikasi/src/lib/supabase.ts:103–112`; `aplikasi/src/lib/supabase.test.ts:4–6,77–95`; pembanding `aplikasi/alat/cek-supabase.mjs:104–165`.
- **Klaim yang dilanggar:** status berhasil membuktikan alamat/kunci diterima dan sambungan yang diperlukan tersedia.
- **Bukti:** `audit node sambungan` pada modul asli dengan impor env/SDK tiruan: Auth 200 + REST **401/403/503** semuanya `ok=true`, pesan “Sambungan ... berhasil”. Auth 503 false; kedua 200 true.
- **Skenario gagal:** pemanggil diagnostik menerima status sukses padahal layanan data tidak dapat digunakan. Belum ada caller UI produksi fungsi ini; **tidak diklaim kasir nyata sudah disesatkan**.
- **Dugaan penyebab:** data hanya masuk rincian; syarat sukses melihat Auth saja. Unit test memberi status sama ke kedua endpoint.
- **Cara membuktikan perbaikan:** tambah kombinasi status berbeda, `(cd aplikasi && npm test -- src/lib/supabase.test.ts)` dan probe pada SHA perbaikan harus memberi kegagalan/degradasi yang jujur. CLI berbeda dan sudah memeriksa katalog; jangan membetulkan file yang salah.
- **Status verifikasi:** TERVERIFIKASI — modul asli, transport/import sintetis, bukan request Supabase nyata.

### [F-06] Kegagalan operasi Storage tidak tertangani pada fondasi tema
- **Tingkat:** K-3.
- **Artefak:** `aplikasi/src/lib/tema.ts:65–106,123–132`; `aplikasi/src/main.tsx:9–15`; `aplikasi/src/hook/useTema.ts:20–29`; `aplikasi/src/lib/tema.test.ts:18–32,68–90`.
- **Klaim yang dilanggar:** penyimpanan lokal opsional tidak membuat helper tema meledak; T0-03/04 tidak menjanjikan halaman kosong tanpa penjelasan.
- **Bukti:** `audit node tema`: getter Storage ditolak ditangani, tetapi getItem sintetis melempar → `READ=UNCAUGHT SecurityError`; setItem penuh → `WRITE=UNCAUGHT QuotaExceededError`. R7 mendokumentasikan quota exception. Prototype `prototipe/js/ui.js:24–25` melindungi operasi get/set dengan try/catch.
- **Skenario gagal:** preferensi dibaca sebelum render dan ditulis pada effect pemasangan/perubahan tema. Storage penuh dapat memutus effect alih-alih hanya menggagalkan penyimpanan. **Layar putih/browser crash belum diamati langsung**; kasus baca adalah fault injection sintetis.
- **Dugaan penyebab:** try/catch hanya mengelilingi pengambilan objek, bukan metode Storage; fixture tes selalu menerima get/set.
- **Cara membuktikan perbaikan:** tambah operasi baca/tulis yang melempar; `(cd aplikasi && npm test -- src/lib/tema.test.ts src/hook/useTema.test.tsx)` harus fallback tanpa exception. Verifikasi startup/ubah tema di browser dengan storage penuh/ditolak.
- **Status verifikasi:** TERVERIFIKASI — exception helper asli; dampak visual bukan klaim runtime terverifikasi.

### [F-07] Boundary Edge gagal menangani JSON null dan galat upstream
- **Tingkat:** K-3.
- **Artefak:** `supabase/functions/verifikasi_pin/index.ts:51–65,69–94`.
- **Klaim yang dilanggar:** memeriksa bentuk input dan memberi respons terkontrol, bukan gagal di luar kontrak.
- **Bukti:** `audit node edge`: E01 null → TypeError akses properti; E07 fetch reject → Error; E08 upstream bukan JSON → SyntaxError; semua tidak tertangani. Kontrol JSON rusak → 400. E05 UUID 36 minus mencapai fetch, sehingga regex bukan pemeriksaan bentuk UUID lengkap.
- **Skenario gagal:** JSON valid dengan bentuk salah, atau gangguan jaringan/upstream, tidak mendapat JSON kesalahan seperti jalur lainnya.
- **Dugaan penyebab:** cast `Record` tidak memvalidasi runtime; try/catch hanya mengelilingi `req.json()`, bukan fetch/parse respons.
- **Cara membuktikan perbaikan:** probe Edge pada SHA perbaikan: E01 400 terkontrol, E07/E08 respons gagal terkontrol, E05 ditolak sebelum fetch. Tambahkan tes Deno asli saat tersedia.
- **Status verifikasi:** TERVERIFIKASI — handler asli di VM; bukan status HTTP platform Deno nyata, bypass SQL, atau kebocoran stack/PIN produksi.

### [F-08] Buku darurat menjanjikan kontrol yang belum bisa dipakai
- **Tingkat:** K-2 (langkah pengguna tidak dapat dijalankan apa adanya; protokol §2b.5).
- **Artefak:** `docs/teknis/BUKU_INSIDEN.md:28–30,46–47,60–65,109–118,137–148`; `PANDUAN_PENGGUNA.md:208–217,640–646`; `aplikasi/src/App.tsx:1–5`; roadmap T1-24/25 dan T10-01/06/10.
- **Klaim yang dilanggar:** langkah cepat untuk kejadian nyata dengan hasil terlihat: cabut seketika, reset MFA, jejak audit, antrean offline, cadangan otomatis.
- **Bukti:** `baca docs/teknis/BUKU_INSIDEN.md 22,148`, `audit py contracts` → antrean offline, `alat/cadangan.sh`, workflow cadangan **False**. Migrasi belum membuat perangkat/sesi_perangkat/catatan_audit/shift_kas; App hanya contoh, bukan menu yang diperintahkan. “Cadangan otomatis berjalan mingguan” tidak diberi label rencana meski latihan pemulihan diberi label belum dibuat.
- **Skenario gagal:** pemilik mencari menu Cabut/antrean yang tidak ada atau menganggap backup tersedia. “Lanjut melayani seperti biasa” belum didukung penyimpanan offline target.
- **Dugaan penyebab:** rancangan akhir ditulis sebagai prosedur aktif tanpa penanda kesiapan. A2/README mengakui Fase 0, tetapi buku berdiri sendiri dan AL-9 mengarahkannya untuk insiden nyata.
- **Cara membuktikan perbaikan:** `python3 alat/periksa-rujukan.py` dan `python3 alat/periksa-panduan.py` perlu, tetapi tidak cukup: walkthrough dari aplikasi target harus membuktikan semua kontrol berlabel tersedia. Langkah masa depan ditandai belum tersedia dan mempunyai fallback saat ini.
- **Status verifikasi:** TERVERIFIKASI — instruksi vs ketersediaan snapshot, bukan sekadar “fitur rencana belum dibuat”. Tidak menjalankan cabut/deploy/restore sungguhan.

### [F-09] README memberi perintah akar setelah menyuruh masuk ke aplikasi
- **Tingkat:** K-2 (protokol §2b.5).
- **Artefak:** `aplikasi/README.md:20–28,98–114`; `aplikasi/alat/pratinjau.sh:10–22`.
- **Klaim yang dilanggar:** menjalankan/pulih tanpa menebak cwd (T0-06).
- **Bukti:** `baca aplikasi/README.md 18,31` menyuruh `cd aplikasi`, lalu ketika vite tidak ada: `bash aplikasi/alat/pratinjau.sh`. `audit py contracts` → `aplikasi/aplikasi/alat/pratinjau.sh=False`, path akar sebenarnya True. Blok pemeriksa 99–114 juga berasumsi akar tanpa instruksi kembali.
- **Skenario gagal:** pengguna mengikuti langkah berurutan; pemulihan mendapat file tidak ditemukan sebelum installer/server berjalan.
- **Dugaan penyebab:** dua cwd tercampur dalam satu panduan.
- **Cara membuktikan perbaikan:** pembangun mengikuti langkah README dalam lingkungan berizin instalasi, termasuk node_modules hilang. `bash aplikasi/alat/pratinjau.sh` dari akar atau padanan relatif benar dari aplikasi harus bekerja; `python3 aplikasi/alat/periksa-struktur.py` perlu dilengkapi uji cwd bila dipakai menjaga panduan.
- **Status verifikasi:** TERVERIFIKASI — resolusi path terhadap tree C; installer/server tidak dijalankan auditor.

### [F-10] Resep audit mengarahkan detached HEAD tetapi mengharuskan cabang sesi untuk penyerahan
- **Tingkat:** K-2 (protokol §2b.5).
- **Artefak:** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md:111–118,125–131`; `docs/uji/PROMPT_AUDIT_INDEPENDEN.md:42–45,70–72`; `PANDUAN_PENGGUNA.md:393–396,421–423`; paket §0a/§0c.
- **Klaim yang dilanggar:** copy-paste audit mengambil target dan mengirim hanya laporan ke cabang sesinya tanpa meninggalkan cabang kerja tetap.
- **Bukti:** `baca docs/uji/PROMPT_AUDIT_INDEPENDEN.md 42,72`: `checkout --detach` kemudian `git push -u origin HEAD`, tanpa kembali ke branch sesi. Branch aktual sesi ini `arena/01a0bbd2-resto-barokah`; `git rev-parse --verify 'arena/01a0b7d1-resto-barokah^{commit}'` → exit 128 walau objek SHA target tersedia. R8 menjelaskan detach: HEAD menunjuk commit, bukan branch; resep push tidak menentukan cabang sesi tujuan.
- **Skenario gagal:** resep meninggalkan cabang tetap, nama sesi dari `git branch --show-current` menjadi kosong, tujuan penyerahan tidak terjamin. Contoh memakai branch lokal juga tidak dijamin tersedia setelah fetch. Tidak melakukan checkout/push eksperimen yang melanggar pembatas sesi.
- **Dugaan penyebab:** inspeksi commit dan penyerahan dirancang terpisah; detach disebut tidak mengubah apa pun meski mengganti worktree.
- **Cara membuktikan perbaikan:** `python3 alat/periksa-panduan.py` plus walkthrough base skeleton: objek target dibaca tanpa meninggalkan branch sesi, laporan satu-satunya diff, tujuan eksplisit `git push origin arena/01a0bbd2-resto-barokah` untuk sesi ini. Cek `git symbolic-ref --short HEAD`; jangan push eksperimen ke sumber/main.
- **Status verifikasi:** TERVERIFIKASI — kontradiksi instruksi dan resolusi ref, bukan simulasi detached/push penuh. Jalan keluar auditor adalah baca objek, bukan mengganti commit audit.

### [F-11] Panduan secrets memberi jaminan yang tidak disediakan GitHub
- **Tingkat:** K-2.
- **Artefak:** `docs/ops/LANGKAH_PEMILIK_SEKARANG.md:8–10,43–49`; `.github/workflows/sebar-skema.yml:29–49`; `.github/workflows/sebar-halaman.yml:22–41`.
- **Klaim yang dilanggar:** kunci dipakai mesin “tanpa pernah terlihat oleh siapa pun, termasuk aku”.
- **Bukti:** `baca docs/ops/LANGKAH_PEMILIK_SEKARANG.md 8,49`; workflow memasok repository secrets ke job. GitHub resmi R6: writer dapat mengakses repository secrets lewat workflow, redaction tidak dijamin untuk semua transformasi, environment reviewers dapat membatasi akses. Panduan menyarankan **All accounts**, TTL kosong, bukan lingkup sempit.
- **Skenario gagal:** pemilik menyerahkan token luas dengan asumsi penulis workflow secara teknis tidak mungkin membaca/menyalahgunakannya. Enkripsi at-rest/mask log bukan batas tersebut; penanda file “disengaja” tidak mengisolasi penulis workflow jahat.
- **Dugaan penyebab:** enkripsi penyimpanan disamakan dengan ketidaktersediaan nilai saat job berjalan; least privilege tidak dijelaskan.
- **Cara membuktikan perbaikan:** sesudah panduan diselaraskan, `python3 alat/periksa-panduan.py`/`python3 alat/periksa-gerbang-ci.py`; pemilik meninjau izin token dan environment. Bila perlu proof akses, gunakan canary pada lingkungan uji terpisah, **bukan mengambil secrets produksi**.
- **Status verifikasi:** TERVERIFIKASI — janji dokumentasi bertentangan dengan model keamanan resmi. Tidak mengklaim secret telah bocor atau setting environment live telah diperiksa.

### [F-12] Aturan aktif pindah sesi saling mewajibkan dan melarang merge
- **Tingkat:** K-2 (jalan pengguna buntu/ambigu pada langkah wajib).
- **Artefak:** `docs/AGENT_OPERATING_GUIDE.md:3–5,29–40`; `PANDUAN_PENGGUNA.md:254–272,314–316`; `PROMPT_SESI_BARU.md:7–17,36–38,72–75`; `docs/ops/SIAP-LANJUT.md:38–63`.
- **Klaim yang dilanggar:** pemilik cukup menyalin prompt/pindah chat tanpa menebak atau merge prematur; satu aturan konsisten.
- **Bukti:** `baca docs/AGENT_OPERATING_GUIDE.md 29,40` → **harus merge** sebelum sesi baru; `baca PROMPT_SESI_BARU.md 36,38` → **jangan merge hanya untuk melihat pekerjaan**, handoff memakai fetch/fast-forward. Checker panduan tetap LOLOS. Sesi ini sendiri membaca objek target hasil fetch tanpa merge (§1/§7).
- **Skenario gagal:** agent wajib membaca kedua dokumen aktif lalu harus memilih aturan berlawanan atau meminta merge sebelum review selesai.
- **Dugaan penyebab:** resep baru ditambahkan tanpa menarik norma lama. Pendamping: `SIAP_AKUN_PEMILIK.md:9–11,48` masih menunggu langkah yang `LANGKAH_PEMILIK_SEKARANG.md:12–18` sebut selesai; `SIAP-LANJUT.md:34–36` menyebut SQL tanpa pemasangan padahal runner mengimpor PGlite. Stub prompt pensiun ada, bukan file hilang tambahan.
- **Cara membuktikan perbaikan:** `python3 alat/periksa-panduan.py` dan `python3 alat/lanjut-sesi.py`; walkthrough copy-paste dari skeleton tanpa merge PR, branch tetap, bahan terbaru terbaca, prasyarat PGlite jelas. Auditor tidak menjalankan handoff writer `--siapkan`.
- **Status verifikasi:** TERVERIFIKASI — dua instruksi aktif bertentangan, bukan eksperimen merge/sesi baru.

### [F-13] Fungsi perbandingan peran berpotensi menjadi oracle lintas penyewa
- **Tingkat:** K-1 bila kebocoran terkonfirmasi.
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql:592–610`; caller `supabase/migrations/0015_penutup_celah_putaran16.sql:342–360`; `docs/TECH_SPEC.md:315–320`.
- **Klaim yang dilanggar:** isolasi tenant juga berlaku pada definer, bukan hanya tabel.
- **Bukti:** `audit py contracts` → `caller_uid_check=False tenant_check=False`. `baca supabase/migrations/0014_penutup_celah_putaran13.sql 592,610` → query dua UUID bebas sebagai definer dan grant authenticated; tidak ditemukan revoke berikutnya di migrasi. R1 menjelaskan privilege pemilik fungsi.
- **Skenario gagal:** akun authenticated yang tahu UUID membandingkan kedudukan pegawai tenant lain; perbandingan terhadap referensi diketahui berpotensi mengungkap metadata peran. Tidak mengklaim UUID dapat ditebak praktis atau data telah diambil.
- **Dugaan penyebab:** helper internal diberikan sebagai API tanpa membatasi caller/tenant.
- **Cara membuktikan perbaikan:** DB uji dua tenant, `SET LOCAL ROLE authenticated`, klaim A, panggil `public.peran_lebih_tinggi(uuid_A, uuid_B)` dan dua UUID B. Tambahkan ke `supabase/tes/isolasi_lintas_penyewa.sql`, jalankan `node alat/uji-sql.mjs supabase/tes/isolasi_lintas_penyewa.sql` dan cek `has_function_privilege` role nyata. Harus ditolak/netral tanpa bocoran.
- **Status verifikasi:** DUGAAN — ACL/predicate sumber terbaca, PostgreSQL/REST exploit tidak dijalankan.

### [F-14] Salah PIN lama diduga menggulung balik catatan pembatas percobaan
- **Tingkat:** K-2.
- **Artefak:** `supabase/migrations/0015_penutup_celah_putaran16.sql:364–370,380–386`; `supabase/migrations/0012_penutup_celah_review.sql:298–327`; `docs/KEAMANAN.md:113–115`.
- **Klaim yang dilanggar:** percobaan salah dibatasi dan tercatat, termasuk perubahan PIN sendiri.
- **Bukti:** `audit py contracts` → `old-pin calls_verify_then_raises=True`. `baca supabase/migrations/0015_penutup_celah_putaran16.sql 364,386` → verifier mencatat kegagalan, caller raise exception. Jalur anti-oracle 383–385 justru mengakui rollback dan memakai return. R2 menjelaskan rollback persistent state dalam blok gagal.
- **Skenario gagal:** sesi masih valid mencoba banyak PIN lama enam digit melalui simpan_pin; tiap RPC gagal dan catatan ikut rollback, batas lima gagal tidak bertambah. Catatan penolakan hierarki 358–360 berisiko hilang karena sebab sama.
- **Dugaan penyebab:** catatan dan penolakan berada dalam transaksi yang diabort caller.
- **Cara membuktikan perbaikan:** 6–10 RPC terpisah dengan PIN baru sah/PIN lama salah, hitung catatan dan pastikan penguncian tercapai. Tambahkan ke `supabase/tes/kredensial_pin.sql`/`pin_batas_pasang.sql`; `node alat/uji-sql.mjs supabase/tes/kredensial_pin.sql`, lalu ulangi lewat PostgREST untuk batas transaksi nyata.
- **Status verifikasi:** DUGAAN — trace statik + referensi, bukan brute-force/rollback SQL dieksekusi.

### [F-15] Pemanggil nonaktif dengan tenant NULL diduga lolos pagar verifikasi PIN
- **Tingkat:** K-2.
- **Artefak:** `supabase/migrations/0012_penutup_celah_review.sql:260–290,320–337,344–345`; `supabase/migrations/0003_helper_identitas.sql:20–31`; `docs/KEAMANAN.md:133–135`.
- **Klaim yang dilanggar:** akun nonaktif kehilangan akses; tidak ada jalur verifikasi lintas tenant.
- **Bukti:** `audit py contracts` → `nullable_tenant_not_equal=True`; penyewa_saya menyaring p.aktif. Guard hanya UID bukan-null lalu `v_penyewa_target <> public.penyewa_saya()`. R3: perbandingan dengan NULL menghasilkan unknown, bukan true.
- **Skenario gagal:** JWT akun yang dinonaktifkan masih valid, target aktif punya tenant, caller mendapat tenant NULL; dengan aksi null, penolakan tenant berpotensi dilewati dan PIN target masih diuji. Bukan klaim semua RLS terbuka atau sesi baru diterbitkan.
- **Dugaan penyebab:** ketidaksamaan nullable dipakai sebagai deny guard tanpa mengecek caller aktif; pengecekan target aktif tidak menggantikannya.
- **Cara membuktikan perbaikan:** nonaktifkan caller setelah token dibuat; uji target se-tenant/lintas-tenant, aksi null/non-null. Tambahkan ke `supabase/tes/pin.sql`; `node alat/uji-sql.mjs supabase/tes/pin.sql` harus menolak sebelum pemeriksaan kredensial; ulangi JWT nyata sesuai R4.
- **Status verifikasi:** DUGAAN — tiga-nilai SQL/JWT/endpoint tidak dieksekusi.

### [F-16] PIN benar tetapi aksi ditolak diduga masih bisa menjadi stempel diskon
- **Tingkat:** K-2.
- **Artefak:** `supabase/migrations/0012_penutup_celah_review.sql:320–335`; `supabase/migrations/0014_penutup_celah_putaran13.sql:310–348`; pembanding void `supabase/migrations/0013_penutup_celah_putaran11.sql:178–204`.
- **Klaim yang dilanggar:** PIN benar belum cukup; penyetuju wajib berizin dan jejak persetujuan jujur (ART-2/KEAMANAN §6).
- **Bukti:** `audit py contracts` → `success_log_before_permission=True`. Verifier menyimpan berhasil sebelum boleh_untuk menolak aksi. Kupon diskon disaring berhasil/aksi/pesanan/waktu/belum dipakai, tanpa recheck izin penyetuju. Void mempunyai recheck izin.
- **Skenario gagal:** PIN dapur benar untuk beri_diskon → verifier menjawab gagal izin tetapi menyimpan baris berhasil; kasir yang boleh diskon kecil mencoba mencatat dapur sebagai penyetuju. **Bukan diskon tanpa batas**: guard limit pelaku tetap ada.
- **Dugaan penyebab:** boolean kecocokan rahasia dianggap boolean otorisasi aksi. Ikatan pemanggil dan pencabutan izin setelah kupon juga perlu diuji.
- **Cara membuktikan perbaikan:** kontrol owner berizin, negatif dapur, izin dicabut, caller lain/replay; `node alat/uji-sql.mjs supabase/tes/diskon_setuju.sql`. Kupon dari aksi ditolak tidak boleh membuat stempel; uang/catatan tetap semula.
- **Status verifikasi:** DUGAAN — alur sumber, belum INSERT/konsumsi kupon di DB.

### [F-17] Hitung ulang langsung diduga dapat mengubah nominal yang sudah diterima/lunas
- **Tingkat:** K-1 bila mutasi uang terkonfirmasi.
- **Artefak:** `supabase/migrations/0014_penutup_celah_putaran13.sql:52–126`; `supabase/migrations/0010_pembayaran.sql:161–176,206–243`; `supabase/tes/uang_peladen.sql:47–67`; `docs/TECH_SPEC.md:339`.
- **Klaim yang dilanggar:** sesudah lunas nominal tidak berubah; koreksi berupa baris baru.
- **Bukti:** `audit py money` → `header_status_or_paid_guard=False`, `header_lock=False`. Definer callable authenticated membaca pengaturan terkini lalu menulis nominal tanpa status header; guard uang menerima penulis peladen. `baca supabase/tes/uang_peladen.sql 47,67` mencatat pembayaran 62.100 kemudian membatalkan item dan mengharapkan total 0, tanpa memeriksa rekonsiliasi/refund.
- **Skenario gagal:** pesanan lunas → owner mengubah tarif → caller yang dapat melihat pesanan memanggil hitung_total; histori berpotensi berubah. Jalur kedua: pembayaran sudah ada pada draf tetapi item diturunkan/dibatalkan sehingga diterima melebihi tagihan tanpa koreksi.
- **Dugaan penyebab:** freeze di trigger item/diskon tidak melindungi endpoint hitung ulang; keberadaan pembayaran/snapshot tarif bukan syarat. Race akibat urutan baca/tulis belum dibuktikan.
- **Cara membuktikan perbaikan:** tambah lunas→ubah tarif→hitung ulang serta bayar sebagian/penuh→ubah item; `node alat/uji-sql.mjs supabase/tes/uang_peladen.sql` harus menjaga histori/koreksi eksplisit. Lanjut dua koneksi item versus pembayaran.
- **Status verifikasi:** DUGAAN — belum UPDATE/RPC SQL. Bukan klaim regresi 0015 “diskon sesudah lunas” gagal; jalurnya berbeda.

### [F-18] Dialog berlabel modal belum mempunyai pengelolaan fokus modal
- **Tingkat:** K-2 bila kegagalan aksesibilitas dikonfirmasi di browser.
- **Artefak:** `aplikasi/src/komponen/Lapis.tsx:26–60`; `aplikasi/src/layar/contoh/LayarContoh.tsx:190–191,277–301`; `aplikasi/src/komponen/komponen.test.tsx:69–86`.
- **Klaim yang dilanggar:** modal dapat dipakai keyboard/screen reader, bukan hanya memiliki atribut ARIA (T0-04/a11y/R5).
- **Bukti:** `baca aplikasi/src/komponen/Lapis.tsx 26,60`: effect hanya Escape/overflow; tidak menempatkan, menjebak, memulihkan fokus atau membuat belakang inert. Caller juga tidak mengerjakannya. Test hanya SSR/string role/aria.
- **Skenario gagal:** keyboard membuka lapis, fokus berpotensi tertinggal di pemicu/berpindah ke halaman belakang meski aria-modal=true; kontrol tertutup tetap terjangkau.
- **Dugaan penyebab:** ARIA dan scroll lock dianggap implementasi modal lengkap.
- **Cara membuktikan perbaikan:** tambah keyboard-open, Tab/Shift-Tab containment, Escape dan fokus kembali; `(cd aplikasi && npm test -- src/komponen/komponen.test.tsx)` lalu browser/screen reader nyata sesuai R5.
- **Status verifikasi:** DUGAAN — kode fokus absen, tetapi DOM/keyboard tidak dieksekusi.

### [F-19] Test bernama “memanggil onUbah saat diisi” tidak pernah mengisi input
- **Tingkat:** K-3.
- **Artefak:** `aplikasi/src/komponen/komponen.test.tsx:145–150`; `aplikasi/src/komponen/KolomIsian.tsx:41–51`; `aplikasi/alat/periksa-uji.py`.
- **Klaim yang dilanggar:** test membuktikan callback perubahan, bukan hanya keberadaan file/nama (T0-10/L4).
- **Bukti:** `baca aplikasi/src/komponen/komponen.test.tsx 145,150` → SSR, cek type=text, lalu `expect(onUbah).not.toHaveBeenCalled()`. Inventaris file: 17 nama test, **0 fireEvent/userEvent/dispatchEvent**, SSR=true. Checker periksa-uji tetap menghitungnya dalam 86 test terbaca.
- **Skenario gagal:** handler onChange tidak tersambung pun test ini tidak memicu event untuk membuktikannya. Tidak menyatakan callback implementasi sekarang rusak.
- **Dugaan penyebab:** assertion SSR dipakai untuk janji interaksi; nama lebih kuat daripada yang diuji.
- **Cara membuktikan perbaikan:** render DOM, lakukan input/change, assert nilai callback; `(cd aplikasi && npm test -- src/komponen/komponen.test.tsx)`. Di lingkungan pembangun, hilangkan handler sementara→test harus merah karena callback, pulihkan→hijau.
- **Status verifikasi:** TERVERIFIKASI — ketiadaan tindakan pada isi test. Vitest/mutasi JSX belum dijalankan auditor.

### [F-20] Pembuat paket menyebut perintah/glob sebagai berkas hilang
- **Tingkat:** K-3.
- **Artefak:** `alat/audit-independen.py:207–229` (**pembuat paket**, bukan validator laporan); paket publikasi `docs/uji/paket-audit/AUD-3-2026-09-19-4830b5a.md:289–327`; `docs/ROADMAP.md:75,84` dan bukti terkait.
- **Klaim yang dilanggar:** paket menuduh missing-file hanya bila artefak memang hilang, bukan perintah/glob/path relatif.
- **Bukti:** `audit py packet` → **12 baris** “sudah [x] — berkasnya TIDAK ADA: laporkan!” mempunyai target nyata. Contoh skrip `python3 alat/periksa-roadmap.py` ada; wildcard komponen cocok 13 berkas; `src/lib/tema.ts` ada relatif aplikasi. Generator memakai `(AKAR / f).exists()` pada token mentah.
- **Skenario gagal:** auditor dituntun membuat temuan palsu atau mencari file yang sebenarnya tersedia. Duplikat dihitung sebagai baris salah, **bukan 12 cacat berbeda**.
- **Dugaan penyebab:** regex menangkap interpreter/wildcard/path relatif dari seluruh blok tugas; resolver hanya path literal akar.
- **Cara membuktikan perbaikan:** di lingkungan pembangun, fixture interpreter/glob/cwd lalu `python3 alat/audit-independen.py --paket AUD-3 --semua` dan `python3 alat/periksa-paket.py` tidak boleh menuduh contoh itu hilang. Jangan menyunting paket historis untuk menyembunyikan bukti. Auditor tidak menjalankan generator karena menulis berkas lain.
- **Status verifikasi:** TERVERIFIKASI — paket dicocokkan ke tree C dan cabang kode generator. Membaca paket publikasi bukan audit kode commit lain.

### [F-21] Minimum Node yang diiklankan tidak sesuai dependensi terkunci
- **Tingkat:** K-3.
- **Artefak:** `aplikasi/README.md:12–16`; `aplikasi/package.json:6–7`; `aplikasi/package-lock.json:35,1623–1636,4350–4375`.
- **Klaim yang dilanggar:** Node 20 termasuk minimum yang didukung untuk mengikuti perintah aplikasi/uji.
- **Bukti:** `audit scope`: root `>=20`; Supabase JS 2.116.0 `>=22.0.0`; Vitest 5.0.1 `^22.12.0 || ^24.0.0 || >=26.0.0`. README Node 22/minimal 20. Mesin auditor v22.22.3, tidak menguji Node 20.
- **Skenario gagal:** pengguna memilih versi yang diiklankan valid tetapi di luar dukungan dua dependensi wajib; reproduksibilitas di versi itu belum dibuktikan.
- **Dugaan penyebab:** lock diperbarui tanpa menyelaraskan engines/prasyarat.
- **Cara membuktikan perbaikan:** selaraskan dukungan lalu jalankan `npm ci --prefix aplikasi` dan `npm test --prefix aplikasi` pada versi minimum di lingkungan pembangun berizin instalasi; tambahkan matrix CI bila tetap menjanjikan versi itu.
- **Status verifikasi:** TERVERIFIKASI — deklarasi engine tidak konsisten. Tidak mengklaim npm ci pasti menolak (engine dapat berupa peringatan) atau runtime Node 20 sudah gagal.

## 5. Kalibrasi cacat tanaman

**Ditemukan: 5 dari 5** **kelompok cacat yang saya identifikasi dan yakini** dalam bahan ini. Y adalah pengelompokan saya, **bukan jumlah cacat resmi dari kunci**. Ini **bukan sertifikat lulus 100%**. **Temuan palsu teramati: 0** setelah refutasi sendiri; false positive resmi/cakupan cacat tersembunyi **belum diketahui** sampai pemegang kunci menilai.

Kelima bahan dibaca; tidak mencari/membuka kunci di luar repo, tidak menjalankan `--kalibrasi-nilai`, tidak menggunakan daftar jawaban laporan lama. Pemindai umum membaca byte/struktur korpus, bukan menyajikan jawaban kalibrasi. Contoh laporan/katalog dan 19 laporan lama tidak dihitung telaah isi. Ringkasan status yang menyebut angka kalibrasi lama tidak menjadi dasar skor atau temuan berikut.

| # | Berkas / baris | Kelas dan cacat | Bukti / batas |
|---|---|---|---|
| CAL-01 | `docs/uji/kalibrasi/bahan-2026-09-17/01_gerbang_izin.sql:2–20` | K-2: definer diklaim mencabut execute PUBLIC tetapi hanya ada grant authenticated; grant bukan revoke. | `baca docs/uji/kalibrasi/bahan-2026-09-17/01_gerbang_izin.sql 1,20` → REVOKE tidak ada; R1: default execute PUBLIC. Bukti kekurangan ACL bahan, bukan exploit DB. Tidak menuduh search_path exploitation tanpa bukti. |
| CAL-02 | `docs/uji/kalibrasi/bahan-2026-09-17/02_policy_pengaturan.sql:4–11` | K-1: SELECT penyewa_id bukan-null tidak mengikat caller/tenant. UPDATE hanya mengikat tenant tanpa izin/peran pengaturan. | `baca docs/uji/kalibrasi/bahan-2026-09-17/02_policy_pengaturan.sql 1,11` → SELECT menerima tenant A/B yang bukan-null; analisis policy, bukan query SQL dua-tenant dieksekusi. |
| CAL-03 | `docs/uji/kalibrasi/bahan-2026-09-17/03_fungsi_terima_bayar.sql:12–23` | K-1: batas lebih bayar tidak memasukkan pembayaran baru. | Python `before,incoming,total=9000,2000,10000; print(before>total,before+incoming)` → `False 11000`. Guard menguji pembayaran sebelum, lalu menerima tambahan dan menandai lunas. Tidak menggunakan trigger proyek nyata untuk menyimpulkan fungsi bahan aman. |
| CAL-04 | `docs/uji/kalibrasi/bahan-2026-09-17/04_panduan_singkat.md:4–11` | K-2: perintah/file salah; aturan 10 salah PIN bertentangan dengan batas 5 di kontrak. | `git cat-file -e "$C:aplikasi/pratinjau.sh"`, `git cat-file -e "$C:alat/periksa-struktur.py"`, `git cat-file -e "$C:docs/PANDUAN_KEAMANAN.md"` → semua exit 128. Padanan `aplikasi/alat/pratinjau.sh`, `aplikasi/alat/periksa-struktur.py`, `docs/KEAMANAN.md` → exit 0. |
| CAL-05 | `docs/uji/kalibrasi/bahan-2026-09-17/05_pemeriksa_ambang.py:7–21` | K-3: root dari lokasi bahan keliru, glob tidak rekursif, ambang 5 bukan 20, terlalu sedikit layar justru sukses. | `audit ro docs/uji/kalibrasi/bahan-2026-09-17/05_pemeriksa_ambang.py` → **`SKIP: layar baru 0 — di bawah ambang 5`**, **`RO_EXIT 0`**. Tidak memastikan keadaan layar yang dijanjikan pada korpus ini. |

Baris adalah kelompok dengan subgejala berkaitan, tidak menambahnya sebagai temuan proyek. Jalur mesin/worktree tidak dijalankan karena membuat/mengubah file di luar laporan dan berisiko membuka materi penilaian. Penilaian resmi tetap tugas pemegang kunci setelah laporan masuk.

## 6. Yang tidak bisa saya verifikasi

1. **PostgreSQL/PGlite.** `psql`, `postgres`, Docker, Supabase CLI tidak terpasang; `import.meta.resolve('@electric-sql/pglite')` → `ERR_MODULE_NOT_FOUND`. Tidak menjalankan 46 SQL, `node alat/uji-sql.mjs --daftar`, atau suite mutasi 0012/0014/0015 penuh. Tabel/policy dihitung dari source, bukan pg_catalog. Concurrency, privilege deployment, bcrypt asli, perubahan status/transaksi dan performa belum diuji. F-13–F-17 tetap DUGAAN.
2. **Build/tipe/lint/Vitest/browser.** `vitest`, `typescript`, `react` → `ERR_MODULE_NOT_FOUND`; Deno/Chromium/Chrome tidak ada. Tidak menjalankan npm test/build/typecheck/lint, lint-mutation, npm audit atau tes komponen asli. 86 adalah hitungan checker (11 file test), bukan hasil eksekusi. AST/impor tidak mengganti compiler/typechecker; delimiter SQL bukan parser PostgreSQL.
3. **Larangan instalasi dipatuhi.** Tidak npm ci/install/npx, pratinjau, bundler, atau pembungkus auto-install. Tidak membuat probe/worktree/hasil ekstraksi di file lain termasuk /tmp. Mutasi checker hanya input/objek memori, bukan menerapkan perbaikan sumber.
4. **Kedalaman cakupan.** 442 adalah pemeriksaan statik heterogen, bukan proof semantik/visual setiap file. 38 tidak dihitung; `audit scope` mencetak nama lengkap. Biner: 38 WOFF2 header/panjang, 7 PNG struktur/CRC/dimensi, 50 JPEG SOF/EOI/dimensi, 11 WebP RIFF/panjang. Tidak decoding/rendering/perbandingan visual/OCR, pemeriksaan data pribadi di gambar, atau audit lisensi eksternal lengkap. Keberadaan 24 teks OFL tidak membuktikan provenance seluruh font.
5. **False positive alat auditor digugurkan.** `docs/desain/referensi/10-waiter-android.webp` sebenarnya PNG berstruktur valid, bukan gambar terbukti rusak. `%23n` adalah url di SVG data URI, bukan file hilang. `$tiruan$`/`$garam123$` adalah string hash, bukan delimiter SQL tidak tertutup. Setelah metode dalam laporan diperbaiki, pemeriksaan struktur tidak gagal. Ketiganya **bukan temuan proyek**.
6. **Adapter RO.** Bukan virtualisasi filesystem/OS lengkap atau checkout C. HEAD nyata tetap base untuk Git yang tidak diadaptasi. Checker berbasis HEAD/riwayat/writer/tempfile tidak diklaim sukses. `periksa-komponen-env.py` terblokir subprocess; migration-freeze/clean-copy/whole-suite tidak dibuktikan native. Validator laporan akhir juga RO, bukan native.
7. **Cloud/secrets.** Tidak memeriksa Auth cloud (expiry/password/MFA), role grant aktual, secrets/environment/branch protection, RLS akun nyata, region/transfer data, deploy 0015, log penuh, atau sejarah rahasia lengkap. Config lokal expiry 3600/password 8 berbeda dari rancangan 900/12; perlu diperiksa sebelum fitur keamanan dianggap siap, **bukan bukti setting produksi**. Tidak memakai kunci tersimpan untuk memutasi data live, mengambil rahasia, atau meminta kredensial.
8. **CI tepat commit.** Kueri baca-saja dijalankan:
   ```bash
   gh api repos/With-AI-Agent/Resto-Barokah/actions/runs/35432334878 --jq '{id,head_sha,status,conclusion,html_url}'
   gh api 'repos/With-AI-Agent/Resto-Barokah/actions/runs?head_sha=4830b5a4f876744ecb37e2f4495c6df234376752' --jq '[.workflow_runs[] | {id,head_sha,status,conclusion}]'
   ```
   Hasil: **35432334878 success pada `638820dabc0b31c691927a6334d0f3b82c6a0a29`**; **35447609275 dan 35447607042 cancelled pada C**. Tidak menjalankan ulang workflow. Green historis bukan green SHA audit.
9. **Lapangan.** Tidak menguji tablet, fokus/keyboard/screen reader, tujuh keadaan dengan data nyata, semua peran, printer/Bluetooth/USB, pembayaran offline, listrik padam, pemulihan antrean atau shift. F-18 DUGAAN. Contrast statik 166/166 bukan ukuran/kontras hasil render semua keadaan.
10. **Privasi/insiden.** Consent/minimalisasi/anonimisasi belum bisa diuji karena implementasi rencana. Belum memverifikasi kanal/penerima resmi pemberitahuan, transfer lintas negara atau pemulihan backup. Ini bukan pendapat hukum atau izin produksi.
11. **Independensi/kalibrasi.** Model berbeda tidak dapat dibuktikan. Skor resmi belum dibanding kunci; tidak menyatakan TERKALIBRASI resmi. Status/komentar kode tentang temuan lama bukan proof; setiap kandidat diperiksa terhadap definisi target dan yang belum terbukti tetap DUGAAN.

### 6a. Referensi eksternal yang dibaca

Referensi membantu kontrak/hipotesis, bukan menggantikan uji proyek. PostgreSQL `current` saat dibaca menunjuk versi 18; config lokal target versi 17. Semantik dasar berikut tidak diklaim sudah diuji pada deployment target.

- **R1 — PostgreSQL CREATE FUNCTION, Writing SECURITY DEFINER Functions Safely:** https://www.postgresql.org/docs/current/sql-createfunction.html — privilege pemilik, default execute PUBLIC/revoke, search_path, dan CREATE OR REPLACE; F-13/CAL-01. Bukan tuduhan semua definer bocor.
- **R2 — PostgreSQL PL/pgSQL §41.6.8:** https://www.postgresql.org/docs/current/plpgsql-control-structures.html — rollback persistent state dalam blok gagal; hipotesis F-14.
- **R3 — PostgreSQL comparison/matematika:** https://www.postgresql.org/docs/current/functions-comparison.html dan https://www.postgresql.org/docs/current/functions-math.html — NULL menghasilkan unknown; pembagian integral memotong pecahan. F-15/lanjutan F-01.
- **R4 — Supabase User sessions:** https://supabase.com/docs/guides/auth/sessions — batas sesi Pro, JWT expiry, pemeriksaan session_id terhadap auth.sessions untuk jaminan setelah sign-out; bukan proof setting proyek.
- **R5 — W3C WAI-ARIA APG Dialog Modal:** https://www.w3.org/WAI/ARIA/apg/patterns/dialog-modal/ — initial focus, containment, return, inert background; F-18.
- **R6 — GitHub Secure use reference:** https://docs.github.com/en/actions/reference/security/secure-use — writer/workflow dapat mengakses repository secrets, redaction tidak dijamin, least privilege/environment reviewers; F-11.
- **R7 — MDN Storage.setItem:** https://developer.mozilla.org/en-US/docs/Web/API/Storage/setItem — QuotaExceededError ketika ruang habis/kapasitas ditolak; F-06 bukan kejadian yang diklaim pada tablet Lee.
- **R8 — Git checkout/push:** https://git-scm.com/docs/git-checkout dan https://git-scm.com/docs/git-push — detached HEAD dan refspec; F-10 tanpa push eksperimen ke cabang lain.
- **Supabase changelog:** https://supabase.com/changelog.md — indeks dibaca, entri terbaru terlihat 2026-09-18; tidak dijadikan temuan tanpa applicability. https://supabase.com/docs/guides/monitoring-and-debugging.md mengarah ke https://supabase.com/docs/guides/observability.md; tidak berarti log proyek telah dibuka.

### 6b. Lampiran kode reproduksi hanya-baca

Kode berikut bagian laporan, bukan perubahan aplikasi. C memaku target. Untuk verifikasi perbaikan, pembangun menggunakan salinan probe di lingkungannya dengan C = SHA perbaikan, tidak menimpa bukti laporan. Adapter menolak tulis/subprocess yang tidak diizinkan tetapi bukan virtualisasi OS lengkap. Hanya referensi paket publikasi dipasok tambahan saat validasi akhir.

<!-- AUDIT_RO_BEGIN -->
```python
import ast, builtins, contextlib, fnmatch, importlib.abc, importlib.util
import io, os, pathlib, re, subprocess, sys, tarfile, traceback, types
from unittest.mock import patch
C = '4830b5a4f876744ecb37e2f4495c6df234376752'
ROOT = pathlib.Path('/home/user/Resto-Barokah')
sys.dont_write_bytecode = True
raw = subprocess.check_output(['git', 'archive', C], cwd=ROOT)
with tarfile.open(fileobj=io.BytesIO(raw)) as ar:
    DATA = {m.name: ar.extractfile(m).read() for m in ar if m.isfile()}
del raw
DIRS = {'.'}
for n in DATA:
    DIRS.update(str(p) for p in pathlib.PurePosixPath(n).parents)
REPORT = 'docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2-907e29e.md'
SNAPSHOT_FILES = set(DATA)
DATA[REPORT] = (ROOT / REPORT).read_bytes()
# Only the reference packet is supplied from its publication object.
# Project code/inventory remain C; actual Git HEAD is never rewritten.
if len(sys.argv)>2 and sys.argv[1]=='alat/audit-independen.py' and '--periksa-laporan' in sys.argv:
    PACKET = 'docs/uji/paket-audit/AUD-3-2026-09-19-4830b5a.md'
    DATA[PACKET] = subprocess.check_output(['git','show','fd0b330f33fe8abd44b67fea06b2e5dd92af0073:'+PACKET],cwd=ROOT)
ORIGINAL_OPEN = builtins.open
ORIGINAL_RUN = subprocess.run

def key(p):
    if isinstance(p, int): return None
    s = os.path.abspath(os.fspath(p))
    if s == str(ROOT): return '.'
    return s[len(str(ROOT))+1:] if s.startswith(str(ROOT)+'/') else None

def outside(p):
    k = key(p)
    return k is None or k == '.git' or k.startswith('.git/')

def rd(p):
    k = key(p)
    if outside(p):
        with ORIGINAL_OPEN(p, 'rb') as f: return f.read()
    if k not in DATA: raise FileNotFoundError(str(p))
    return DATA[k]

def op(p, mode='r', buffering=-1, encoding=None, errors=None, newline=None, **kw):
    if any(c in mode for c in 'wax+'):
        raise PermissionError('AUDIT READ ONLY: ' + str(p))
    if outside(p):
        return ORIGINAL_OPEN(p, mode, buffering, encoding, errors, newline, **kw)
    b = rd(p)
    f = io.BytesIO(b) if 'b' in mode else io.StringIO(b.decode(encoding or 'utf-8', errors or 'strict'), newline=newline)
    f.name = str(p)
    return f

def match(parts, pattern):
    if not pattern: return not parts
    if pattern[0] == '**':
        return match(parts, pattern[1:]) or bool(parts) and match(parts[1:], pattern)
    return bool(parts) and fnmatch.fnmatchcase(parts[0], pattern[0]) and match(parts[1:], pattern[1:])

def glob(p, pattern):
    k = key(p)
    prefix = '' if k == '.' else k + '/'
    for n in sorted(set(DATA) | DIRS):
        if n.startswith(prefix) and n != k and match(n[len(prefix):].split('/'), str(pattern).split('/')):
            yield ROOT / n

def children(p):
    k = key(p)
    prefix = '' if k == '.' else k + '/'
    names = {n[len(prefix):].split('/')[0] for n in set(DATA) | DIRS if n.startswith(prefix) and n != k}
    for n in sorted(names):
        if n != '.': yield p / n

ORIGINAL_EXISTS = pathlib.Path.exists
ORIGINAL_IS_FILE = pathlib.Path.is_file
ORIGINAL_IS_DIR = pathlib.Path.is_dir
ORIGINAL_LISTDIR = os.listdir
ORIGINAL_PATH_EXISTS = os.path.exists
ORIGINAL_PATH_ISFILE = os.path.isfile
ORIGINAL_PATH_ISDIR = os.path.isdir
ORIGINAL_GETSIZE = os.path.getsize

def run(args, *a, **kw):
    if not isinstance(args, (list, tuple)) or not args or args[0] != 'git':
        raise PermissionError('AUDIT: subprocess not executed: ' + repr(args))
    cmd = list(args)
    if len(cmd)>3 and cmd[1]=='-C':
        if os.path.abspath(cmd[2]) != str(ROOT):
            raise PermissionError('AUDIT: Git root is not target repository')
        cmd = [cmd[0]] + cmd[3:]
    permitted = {'show','ls-tree','ls-files','cat-file','rev-parse','log','diff','status','check-ignore','merge-base','for-each-ref'}
    if len(cmd)<2 or cmd[1] not in permitted:
        raise PermissionError('AUDIT: Git write/non-allowlisted command not executed: ' + repr(cmd))
    if cmd[1] == 'ls-files':
        if any(x.startswith('-') and x not in ('-z','--') for x in cmd[2:]):
            raise PermissionError('AUDIT: unsupported git ls-files arguments: '+repr(cmd))
        filters = [x for x in cmd[2:] if not x.startswith('-')]
        sep = '\0' if '-z' in cmd else '\n'
        out = sep.join(sorted(n for n in SNAPSHOT_FILES if not filters or any(n == f or n.startswith(f.rstrip('/')+'/') or fnmatch.fnmatchcase(n,f) for f in filters))) + sep
        if not (kw.get('text') or kw.get('encoding') or kw.get('universal_newlines')):
            out = out.encode()
        return subprocess.CompletedProcess(args, 0, out, '' if isinstance(out,str) else b'')
    # Other Git queries retain actual HEAD. Do not pretend C is checked out.
    return ORIGINAL_RUN(cmd, *a, **kw)

class Finder(importlib.abc.MetaPathFinder, importlib.abc.Loader):
    def find_spec(self, fullname, path=None, target=None):
        for base in ('alat/', 'aplikasi/alat/', '_sistem/'):
            n = base + fullname.replace('.', '/') + '.py'
            if n in DATA:
                return importlib.util.spec_from_loader(fullname, self, origin=str(ROOT/n))
    def create_module(self, spec): return None
    def exec_module(self, module):
        module.__file__ = module.__spec__.origin
        exec(compile(rd(module.__file__), module.__file__, 'exec'), module.__dict__)

sys.meta_path.insert(0, Finder())

def guard(event, args):
    if event == 'open':
        mode, flags = args[1:3]
        if isinstance(mode,str) and any(c in mode for c in 'wax+') or isinstance(flags,int) and flags & (os.O_WRONLY|os.O_RDWR|os.O_CREAT|os.O_TRUNC):
            raise PermissionError('AUDIT: filesystem write refused')
    if event in {'os.mkdir','os.remove','os.rename','os.rmdir','os.system','os.chmod','os.symlink','os.link','shutil.copyfile','shutil.rmtree'}:
        raise PermissionError('AUDIT: filesystem mutation refused: '+event)

sys.addaudithook(guard)
if len(sys.argv) < 2: raise SystemExit('Supply target Python script path')
name = sys.argv[1]
sys.argv = [str(ROOT/name)] + sys.argv[2:]
with contextlib.ExitStack() as stack:
    changes = [
        (builtins,'open',op), (io,'open',op),
        (pathlib.Path,'read_bytes',lambda p:rd(p)),
        (pathlib.Path,'read_text',lambda p,encoding=None,errors=None:rd(p).decode(encoding or 'utf-8',errors or 'strict')),
        (pathlib.Path,'exists',lambda p:ORIGINAL_EXISTS(p) if outside(p) else key(p) in DATA or key(p) in DIRS),
        (pathlib.Path,'is_file',lambda p:ORIGINAL_IS_FILE(p) if outside(p) else key(p) in DATA),
        (pathlib.Path,'is_dir',lambda p:ORIGINAL_IS_DIR(p) if outside(p) else key(p) in DIRS),
        (pathlib.Path,'glob',glob), (pathlib.Path,'rglob',lambda p,pat:glob(p,'**/'+str(pat))),
        (pathlib.Path,'iterdir',children), (subprocess,'run',run),
        (os,'listdir',lambda p='.':ORIGINAL_LISTDIR(p) if outside(p) else [x.name for x in children(pathlib.Path(p))]),
        (os.path,'exists',lambda p:ORIGINAL_PATH_EXISTS(p) if outside(p) else key(p) in DATA or key(p) in DIRS),
        (os.path,'isfile',lambda p:ORIGINAL_PATH_ISFILE(p) if outside(p) else key(p) in DATA),
        (os.path,'isdir',lambda p:ORIGINAL_PATH_ISDIR(p) if outside(p) else key(p) in DIRS),
        (os.path,'getsize',lambda p:ORIGINAL_GETSIZE(p) if outside(p) else len(rd(p))),
    ]
    for obj,attr,value in changes: stack.enter_context(patch.object(obj,attr,value))
    g = {'__name__':'__main__','__file__':str(ROOT/name)}
    try: exec(compile(DATA[name],str(ROOT/name),'exec'),g)
    except SystemExit as e:
        print('RO_EXIT',e.code)
        raise
```
<!-- AUDIT_RO_END -->

<!-- AUDIT_NODE_BEGIN -->
```javascript
import vm from 'node:vm';
import {execFileSync} from 'node:child_process';
import {stripTypeScriptTypes} from 'node:module';
const C = '4830b5a4f876744ecb37e2f4495c6df234376752';
const source = p => execFileSync('git', ['show', `${C}:${p}`], {encoding:'utf8'});
const mode = process.argv[2] || 'all';
if (mode === 'all' || mode === 'edge') {
  const code = stripTypeScriptTypes(source('supabase/functions/verifikasi_pin/index.ts'));
  const base = {pengguna_id:'90000000-0000-0000-0000-000000000004',pin:'628491',aksi:'beri_diskon',perangkat:'audit-synthetic'};
  const cases = [
    ['E01',null,{}], ['E02','{invalid',{raw:true}],
    ['E03',base,{noToken:true}], ['E04',null,{method:'GET'}],
    ['E05',{...base,pengguna_id:'-'.repeat(36)},{}],
    ['E06',{...base,pesanan_id:'eeee0000-0000-0000-0000-000000000010'},{}],
    ['E07',base,{network:true}], ['E08',base,{badJSON:true}],
    ['E09',base,{status:403}], ['E10',{...base,pin:'12345'},{}],
    ['E11',[],{}], ['E12',base,{}],
  ];
  for (const [id,body,opts] of cases) {
    let handler, forwarded;
    const context = vm.createContext({Request,Response,JSON,
      Deno:{serve:f=>{handler=f},env:{get:k=>k==='SUPABASE_URL'?'https://audit.invalid':'synthetic-public-key'}},
      fetch:async (_url,o)=>{
        forwarded=JSON.parse(o.body);
        if(opts.network) throw new Error('synthetic network failure');
        return new Response(opts.badJSON?'not-json':JSON.stringify([{berhasil:true,sisa_percobaan:5,pesan:'synthetic'}]),{status:opts.status||200});
      }
    });
    vm.runInContext(code,context);
    const method=opts.method||'POST';
    const req=new Request('https://audit.invalid/pin',{method,
      headers:opts.noToken?{}:{Authorization:'Bearer synthetic-token'},
      ...(method==='POST'?{body:opts.raw?body:JSON.stringify(body)}:{})});
    try {
      const response=await handler(req);
      console.log(id,'HTTP='+response.status,await response.text(),
        'RPC_KEYS='+JSON.stringify(Object.keys(forwarded||{})));
    } catch(e) {console.log(id,'UNCAUGHT='+e.name,'RPC_CALLED='+Boolean(forwarded));}
  }
}
if(mode==='all'||mode==='sambungan') {
  const context=vm.createContext({AbortSignal,Date,Error,Response,fetch});
  const env=new vm.SyntheticModule(['alamatSupabase','envLengkap','kunciAnonSupabase','pesanEnvKurang'],function(){
    this.setExport('alamatSupabase',()=> 'https://audit-probe.supabase.co');
    this.setExport('envLengkap',()=>true);
    this.setExport('kunciAnonSupabase',()=> 'synthetic-public-key');
    this.setExport('pesanEnvKurang',()=> 'synthetic missing env');
  },{context});
  const client=new vm.SyntheticModule(['createClient'],function(){this.setExport('createClient',()=>({}));},{context});
  const m=new vm.SourceTextModule(stripTypeScriptTypes(source('aplikasi/src/lib/supabase.ts')),{context});
  await m.link(s=>s==='./env'?env:client);await m.evaluate();
  for(const [a,b] of [[200,401],[200,403],[200,503],[503,200],[200,200]]) {
    const h=await m.namespace.ujiSambungan({fetchUji:async u=>new Response('{}',{status:String(u).includes('/auth/')?a:b})});
    console.log('S',a,b,'ok='+h.ok,h.pesan);
  }
}
if(mode==='all'||mode==='tema') {
  for(const state of ['normal','bad-values','getter-denied','getItem-throws','setItem-quota']) {
    const context=vm.createContext({Error});
    const storage={getItem:()=>{if(state==='getItem-throws')throw new Error('SecurityError');return state==='bad-values'?'not-a-theme':null;},
      setItem:()=>{if(state==='setItem-quota')throw new Error('QuotaExceededError');}};
    Object.defineProperty(context,'localStorage',{get(){if(state==='getter-denied')throw new Error('SecurityError');return storage;}});
    const m=new vm.SourceTextModule(stripTypeScriptTypes(source('aplikasi/src/lib/tema.ts')),{context});
    await m.link(()=>{});await m.evaluate();
    let read,write;
    try{read=JSON.stringify(m.namespace.bacaPilihanTersimpan());}catch(e){read='UNCAUGHT '+e.message;}
    try{m.namespace.simpanPilihan('terang','nyaman');write='returned';}catch(e){write='UNCAUGHT '+e.message;}
    console.log('T',state,'READ='+read,'WRITE='+write);
  }
}
```
<!-- AUDIT_NODE_END -->

<!-- AUDIT_PY_BEGIN -->
```python
import ast, contextlib, fnmatch, io, pathlib, re, subprocess, sys, tarfile
from decimal import Decimal
from unittest.mock import patch
C = '4830b5a4f876744ecb37e2f4495c6df234376752'
ROOT = pathlib.Path('/home/user/Resto-Barokah')
def src(p):
    return subprocess.check_output(['git','show',C+':'+p],text=True)
mode = sys.argv[1] if len(sys.argv)>1 else 'all'
if mode in ('all','pin-checker'):
    p='alat/periksa-fungsi-pin.py'; code=src(p)
    edge=src('supabase/functions/verifikasi_pin/index.ts')
    fixtures=[('current',edge),
      ('return-pin',edge.replace('berhasil: hasil?.berhasil === true,','berhasil: hasil?.berhasil === true,\n    pin: pin,')),
      ('bracket-log',edge.replace('const jawab = await fetch',"console['log'](pin);\n  const jawab = await fetch")),
      ('dot-log-control',edge.replace('const jawab = await fetch','console.log(pin);\n  const jawab = await fetch'))]
    class MemoryInput:
        def __init__(self,s): self.s=s
        def exists(self): return True
        def read_text(self,**kw): return self.s
        def relative_to(self,p): return 'synthetic-edge-input'
    for name,text in fixtures:
        g={'__name__':'audit_input','__file__':str(ROOT/p)}
        exec(compile(code,p,'exec'),g);g['BERKAS']=MemoryInput(text)
        out=io.StringIO()
        with contextlib.redirect_stdout(out): rc=g['utama']()
        print('G',name,'exit='+str(rc),out.getvalue().strip().splitlines()[-1])
if mode in ('all','mutation'):
    p='alat/uji-mutasi-0015.py';g={'__name__':'audit_input','__file__':str(ROOT/p)}
    exec(compile(src(p),p,'exec'),g)
    class MemoryFile:
        def __init__(self): self.s='VALID ORIGINAL'
        def __truediv__(self,p): return self
        def read_text(self,**kw): return self.s
        def write_text(self,s,**kw): self.s=s
    f=MemoryFile();g['KERJA']=f
    for rc,msg in [(1,'ERR_MODULE_NOT_FOUND'),(1,'SyntaxError: unexpected token'),(2,'migrasi tidak bisa diterapkan'),(0,'all correct assertions passed')]:
        g['jalankan_uji']=lambda u,c=rc,m=msg:(c,m)
        print('H',msg,'=>',g['mutasi']('synthetic runner result',lambda t:t+' MUTANT'),'restored='+str(f.s=='VALID ORIGINAL'))
if mode in ('all','money'):
    s=src('supabase/migrations/0014_penutup_celah_putaran13.sql')
    f=re.search(r'create or replace function public.hitung_total\(.*?\$\$;',s,re.S).group()
    assert 'v_total := greatest(v_subtotal + v_pajak + v_service - v_diskon, 0)' in f
    assert 'round(v_subtotal * coalesce(v_pajak, 0) / 100)' in f
    assert 'round(v_subtotal * coalesce(v_service, 0) / 100)' in f
    for subtotal,disc in [(100000,25000),(20000,1000),(100000,0),(27000,1350)]:
        actual=subtotal+subtotal*10//100+subtotal*5//100-disc
        expected=(Decimal(subtotal)-disc)*Decimal('1.15')
        print('M',subtotal,disc,'source_integer_formula='+str(actual),'ART3_before_final_rounding='+str(expected))
    code=re.sub(r'--[^\n]*','',f)
    print('M source-properties','rounding_setting='+str('pembulatan' in code),'header_status_or_paid_guard='+str(any(x in code for x in ('v_pesanan.status', "'lunas'", 'total_dibayar', 'public.pembayaran'))),'header_lock='+str('for update' in code.lower()))
if mode in ('all','contracts'):
    paths=subprocess.check_output(['git','ls-tree','-r','--name-only',C],text=True).splitlines()
    names=['hitung_total','verifikasi_pin','simpan_pin','peran_lebih_tinggi','picu_diskon_setuju_jujur','picu_item_jaga','picu_pembatalan_sah']
    latest={}
    for p in paths:
        if p.startswith('supabase/migrations/') and p.endswith('.sql'):
            s=src(p)
            for n in names:
                for m in re.finditer(r'create or replace function public\.'+n+r'\(.*?\$\$;',s,re.S):
                    latest[n]=(p,s[:m.start()].count('\n')+1,m.group())
    for n,(p,line,body) in latest.items():
        print('Q',n,p+':'+str(line),'lines='+str(body.count('\n')+1))
    f=latest['peran_lebih_tinggi'][2]
    print('Q role-comparison','caller_uid_check='+str('auth.uid()' in f),'tenant_check='+str('penyewa' in f))
    f=latest['verifikasi_pin'][2]
    print('Q verification','success_log_before_permission='+str(f.index('v_saya, p_pesanan_id);',f.index('v_berhasil :=')) < f.index("not public.boleh_untuk")))
    print('Q verification','nullable_tenant_not_equal='+str('v_penyewa_target <> public.penyewa_saya()' in f))
    f=latest['simpan_pin'][2]
    print('Q old-pin','calls_verify_then_raises='+str(f.index('from public.verifikasi_pin') < f.index("raise exception 'PIN lama salah.")))
    for p in ['aplikasi/aplikasi/alat/pratinjau.sh','aplikasi/alat/pratinjau.sh','aplikasi/src/lib/antrean-offline.ts','.github/workflows/cadangan.yml','alat/cadangan.sh']:
        print('D actual-path',p,p in paths)
if mode in ('all','packet'):
    # Only the packet is read from its later publication object; no code is audited there.
    A='fd0b330f33fe8abd44b67fea06b2e5dd92af0073'
    pkt=subprocess.check_output(['git','show',A+':docs/uji/paket-audit/AUD-3-2026-09-19-4830b5a.md'],text=True)
    paths=set(subprocess.check_output(['git','ls-tree','-r','--name-only',C],text=True).splitlines())
    s=pkt.split('## 1b.',1)[1].split('## 2.',1)[0];bad=[]
    for raw,task in re.findall(r'\| `([^`]+)` \| ([^|]*sudah \[x\][^|]*)\|',s):
        f=' '.join(raw.split());normalized=f.split(' ',1)[1] if f.startswith(('node ','python3 ')) else f
        if normalized.startswith('src/'): normalized='aplikasi/'+normalized
        found=[p for p in paths if fnmatch.fnmatchcase(p,normalized)]
        if found: bad.append((f,task.strip().split(' ',1)[0],len(found)))
    print('P false-missing-assertions',len(bad))
    for item in bad: print('P',item)
```
<!-- AUDIT_PY_END -->

<!-- AUDIT_SCOPE_BEGIN -->
```python
import ast, collections, fnmatch, hashlib, io, json, pathlib, posixpath, re
import struct, subprocess, tarfile, tomllib, zlib
from html.parser import HTMLParser
from xml.etree import ElementTree
C='4830b5a4f876744ecb37e2f4495c6df234376752'
with tarfile.open(fileobj=io.BytesIO(subprocess.check_output(['git','archive',C]))) as ar:
    all_data={m.name:ar.extractfile(m).read() for m in ar if m.isfile()}
D={p:b for p,b in all_data.items() if not p.startswith(('skills/','_salinan-meta/')) and p!='_Notes.md'}
# Do not expose calibration answers in old reports, checker fixtures, or the machine catalog.
withheld={p for p in D if (p.startswith(('docs/uji/audit/','docs/uji/review-pr/')) and pathlib.PurePosixPath(p).name.startswith('LAPORAN_'))
          or p.startswith(('alat/contoh-laporan/','alat/contoh-laporan-review/')) or p=='alat/kalibrasi-cacat.json'
          or (p.startswith('_sistem/') and p.endswith('.md') and '/templates/' not in p)}
counts=collections.Counter();checks=collections.defaultdict(list);missing_imports=[];doc_candidates=[];fail=[]
def mark(p,kind): checks[p].append(kind);counts[kind]+=1
for p,b in sorted(D.items()):
    if p in withheld: continue
    try:
        ext=pathlib.PurePosixPath(p).suffix
        if ext=='.woff2':
            assert b[:4]==b'wOF2' and struct.unpack('>I',b[8:12])[0]==len(b)
            mark(p,'WOFF2 magic+length')
        elif ext in ('.png','.jpg','.jpeg','.webp'):
            if b[:8]==b'\x89PNG\r\n\x1a\n':
                w,h=struct.unpack('>II',b[16:24]);i=8;end=False
                while i<len(b):
                    n=struct.unpack('>I',b[i:i+4])[0];chunk=b[i+4:i+8+n]
                    assert zlib.crc32(chunk)&0xffffffff==struct.unpack('>I',b[i+8+n:i+12+n])[0]
                    end=end or chunk[:4]==b'IEND';i+=n+12
                assert i==len(b) and end and min(w,h)>0;mark(p,'PNG chunks+dimensions')
            elif b[:2]==b'\xff\xd8':
                assert b.rfind(b'\xff\xd9')>0;i=2;size=None
                while i<len(b)-2:
                    if b[i]!=255:i+=1;continue
                    tag=b[i+1]
                    if tag in [0,255] or 0xd0<=tag<=0xd9:i+=2;continue
                    n=struct.unpack('>H',b[i+2:i+4])[0]
                    if tag in [0xc0,0xc1,0xc2,0xc3,0xc5,0xc6,0xc7,0xc9,0xca,0xcb,0xcd,0xce,0xcf]:
                        size=struct.unpack('>HH',b[i+5:i+9]);break
                    i+=n+2
                assert size and min(size)>0;mark(p,'JPEG SOF+EOI')
            else:
                assert b[:4]==b'RIFF' and b[8:12]==b'WEBP' and struct.unpack('<I',b[4:8])[0]+8==len(b)
                mark(p,'WebP RIFF length')
        elif p.endswith('.gitkeep'):
            assert not b;mark(p,'empty-directory marker')
        else:
            s=b.decode('utf-8')
            if ext=='.py': ast.parse(s,p);mark(p,'Python AST syntax')
            elif ext=='.json': json.loads(s);mark(p,'JSON parse')
            elif ext=='.toml': tomllib.loads(s);mark(p,'TOML parse')
            elif ext=='.svg': ElementTree.fromstring(s);mark(p,'SVG XML parse')
            elif ext=='.sh':
                r=subprocess.run(['bash','-n'],input=s,text=True,capture_output=True)
                assert r.returncode==0,r.stderr;mark(p,'bash -n')
            elif ext=='.md':
                # Resolve backtick paths against both repository and document directory.
                # Planned/archival examples remain candidates, not findings.
                for m in re.finditer(r'`([^`\n]+)`',s):
                    v=m[1].strip();v=re.sub(r'^(?:python3|node|bash)\s+','',v).split(' ')[0].split(':')[0]
                    if not re.match(r'^(?:aplikasi|supabase|alat|docs|prototipe|_sistem|_log-sesi)/',v):continue
                    if any(c in v for c in '<>…'):continue
                    if not re.search(r'\.(?:md|py|sql|mjs|sh|ts|tsx|yml|json)$',v):continue
                    if not any(fnmatch.fnmatchcase(n,v) or n.startswith(v.rstrip('/')+'/') for n in D):
                        doc_candidates.append((p,s[:m.start()].count('\n')+1,v))
                mark(p,'document reference/command triage')
            elif ext in ('.ts','.tsx','.js','.mjs'):
                for m in re.finditer(r'(?:from\s*|import\s*)[\'\"]([^\'\"]+)[\'\"]',s):
                    v=m[1]
                    if not v.startswith('.'):continue
                    target=posixpath.normpath(posixpath.join(posixpath.dirname(p),v))
                    if not any(target+suffix in D for suffix in ('','.ts','.tsx','.js','.mjs','.css','/index.ts','/index.tsx')):
                        missing_imports.append((p,v))
                # This is dependency-path and sink triage, NOT typechecking/JSX execution.
                re.findall(r'\b(?:fetch|localStorage|innerHTML|eval|console|child_process)\b',s)
                mark(p,'JS/TS import and sink triage')
            elif ext=='.sql':
                code=re.sub(r'--[^\n]*','',s)
                # Dollar characters inside quoted mock hashes are not SQL delimiters.
                without_strings=re.sub(r"'(?:''|[^'])*'", "''", code)
                delimiters=collections.Counter(re.findall(r'\$[A-Za-z_0-9]*\$',without_strings))
                assert all(n%2==0 for n in delimiters.values()),delimiters
                re.findall(r'(create policy|security definer|grant|revoke|uji\.(?:sama|harap_gagal_sebab|harap_gagal))',code,re.I)
                mark(p,'SQL delimiter and guard/assertion triage')
            elif ext=='.css':
                assert len(s)>0
                # Exclude nested url(#...) inside an SVG data URI before local-asset lookup.
                text=re.sub(r'url\(\s*([\'\"])(data:.*?)\1\s*\)','',s,flags=re.S)
                for v in re.findall(r'url\([\'\"]?([^\)\'\"]+)',text):
                    if v.startswith(('http:','https:','data:','#')):continue
                    target=posixpath.normpath(posixpath.join(posixpath.dirname(p),v))
                    assert target in D,(p,v)
                mark(p,'CSS asset resolution')
            elif ext=='.html':
                parser=HTMLParser();parser.feed(s);parser.close()
                assert '<html' in s.lower();mark(p,'HTML parse/document structure')
            elif ext=='.txt' and '/font/' in p:
                assert 'SIL OPEN FONT LICENSE' in s;mark(p,'OFL license text presence')
            elif ext=='.yml':
                assert 'jobs:' in s and 'runs-on:' in s and 'steps:' in s
                mark(p,'workflow job/runner/step structure')
            elif p.endswith('.env.example'):
                keys=re.findall(r'^\s*(?:#\s*)?([A-Z][A-Z0-9_]+)=',s,re.M)
                assert 'VITE_SUPABASE_URL' in keys and 'VITE_SUPABASE_ANON_KEY' in keys
                active=re.findall(r'^\s*(VITE_[A-Z0-9_]+)=',s,re.M)
                assert set(active)<= {'VITE_SUPABASE_URL','VITE_SUPABASE_ANON_KEY'}
                mark(p,'public env-name allowlist')
            elif p.endswith(('.gitignore','.prettierignore','robots.txt')):
                assert s.strip();mark(p,'ignore/robots rule inspection')
            else: raise ValueError('unclassified file type')
    except Exception as e:fail.append((p,str(e)));mark(p,'check failed; requires review')
pairs=0
for p,b in D.items():
    if p.startswith('aplikasi/src/gaya/aset/font/'):
        other=p.replace('aplikasi/src/gaya/aset/','prototipe/aset/')
        assert other in D and D[other]==b,(p,other);pairs+=1
assert D['aplikasi/src/gaya/token/tema.css']==D['prototipe/css/tokens.css']
print('SCOPE inventory',len(D),'bytes',sum(map(len,D.values())),'content-triage',len(checks),'withheld',len(withheld))
print('SCOPE methods',json.dumps(counts,sort_keys=True))
print('SCOPE failures',fail)
print('SCOPE unresolved-relative-imports',missing_imports)
print('SCOPE document-path-candidates',len(doc_candidates),'NOT findings; includes planned files')
print('SCOPE duplicate-font/license-pairs',pairs,'CSS-copy-identical=True')
print('SCOPE withheld paths:')
for p in sorted(withheld):print(p)
# Package engine promises, without installing or sending dependencies elsewhere.
for p in ('aplikasi/package-lock.json','alat/package-lock.json'):
    data=json.loads(D[p]);items=data.get('packages',{})
    print('SCOPE lock',p,'entries',len(items),'root-engines',items.get('',{}).get('engines',{}))
    for name in ('node_modules/@supabase/supabase-js','node_modules/vite','node_modules/vitest','node_modules/@electric-sql/pglite'):
        if name in items:print('SCOPE engine',name,items[name].get('version'),items[name].get('engines'))
```
<!-- AUDIT_SCOPE_END -->

## 7. Pernyataan tidak mengubah apa pun

Saya **tidak mengubah** kode, migrasi, pengujian, konfigurasi, panduan proyek, atau dependensi. **Laporan ini satu-satunya berkas yang saya tulis.** Selama pengumpulan bukti tidak menerapkan perbaikan, membuat probe terpisah, memasang dependensi, checkout/worktree, merge, deploy, atau memutasi DB produksi. Pada penyerahan lanjutan 2026-09-20, nama laporan ini diubah dan hanya **riwayat laporan** digabungkan; laporan remote lama diambil tanpa satu byte perubahan. Terhadap remote sebelum penyerahan, satu-satunya perubahan adalah penambahan laporan bernama unik ini. Tidak ada penggabungan kode aplikasi. Rincian dan bukti penyerahan ada di bawah.

Bukti sebelum penyerahan, `git status --short --untracked-files=all`:

```text
?? docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2.md
```

`git diff --stat` pada tracked files kosong; branch aktif `arena/01a0bbd2-resto-barokah`; HEAD saat pengumpulan bukti `253d1297a3b81433d7f5809afd257d8a1b40958f`. Itu **bukan** SHA kode yang diaudit; pembacaan target dijelaskan §1.

**Validasi laporan di akhir (riwayat tiga percobaan dijelaskan di bawah):** `python3 alat/audit-independen.py --periksa-laporan "$R"` tidak tersedia native di skeleton. Implementasi target dengan argumen sama dijalankan melalui:

```bash
audit ro alat/audit-independen.py --periksa-laporan "$R"
```

<!-- VALIDATOR_RESULT_BEGIN -->
**Riwayat validasi akhir: 3 percobaan, bukan satu pemanggilan tanpa gangguan.** Permintaan awal sekali di akhir tidak tercapai secara jumlah pemanggilan: percobaan 1 terblokir adapter; percobaan 2 menolak format tabel bukti dan status Git yang mengelompokkan folder untracked; percobaan 3 sesudah hanya perbaikan format bukti/alasan HEAD dan staging satu laporan. **Temuan, kelas, dan cakupan tidak diubah untuk mengejar hasil checker.**

**Bukti percobaan terdahulu (dipertahankan):**

**Catatan eksekusi jujur:** validasi akhir dicoba **2 kali**, bukan satu eksekusi tanpa gangguan. Percobaan pertama terhenti oleh adapter pada pembacaan Git `for-each-ref`, tanpa keputusan validator. Adapter laporan ditambah izin perintah baca-saja itu; temuan, kelas, dan angka cakupan tidak diubah untuk mengejar kelulusan. Tidak membaca implementasi validator untuk menyesuaikan hasil.

**Percobaan 1 (terblokir adapter):**

Pemanggilan **1 kali**, melalui adapter RO; exit **1**. Ini validasi laporan, bukan kelulusan aplikasi.

```text

STDERR:
Traceback (most recent call last):
  File "<stdin>", line 13, in <module>
  File "<audit-ro>", line 147, in <module>
  File "/home/user/Resto-Barokah/alat/audit-independen.py", line 1425, in <module>
  File "/home/user/Resto-Barokah/alat/audit-independen.py", line 1412, in main
  File "/home/user/Resto-Barokah/alat/audit-independen.py", line 887, in mode_periksa_laporan
  File "/home/user/Resto-Barokah/alat/audit-independen.py", line 845, in periksa_laporan
  File "/home/user/Resto-Barokah/alat/audit-independen.py", line 621, in _kenali_cabang_asal
  File "/home/user/Resto-Barokah/alat/audit-independen.py", line 106, in jalankan
  File "<audit-ro>", line 91, in run
PermissionError: AUDIT: Git write/non-allowlisted command not executed: ['git', 'for-each-ref', '--format=%(refname:short)', 'refs/remotes/origin/']
FINAL_REPORT_VALIDATOR_EXIT=1
```

**Percobaan 2 (hasil aktual):**

```text
PERIKSA LAPORAN AUDIT — LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2.md
  artefak diperiksa : 41
  klaim dibantah    : 15
  serangan          : 33
  temuan            : 21
  mode              : menyeluruh
  cakupan berkas    : 442/480 (92%)
  berkas pengguna   : 17 baris
  kalibrasi         : 5/5 cacat ditemukan
  di luar cakupan   : 3 temuan
  CATATAN: commit diaudit (4830b5a4) ≠ HEAD (253d1297) — wajib ada 'Alasan commit berbeda'

HASIL: DITOLAK (21 alasan) — laporan belum memenuhi kontrak:
  - cakupan baris 10: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 11: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 17: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 22: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 23: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 24: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 25: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 26: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 27: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 29: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 30: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 31: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 34: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 35: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 36: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 37: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 38: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 39: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 40: bukti harus berupa perintah ber-backtick atau berkas:baris
  - cakupan baris 41: bukti harus berupa perintah ber-backtick atau berkas:baris
  - repo TIDAK bersih saat laporan diperiksa — auditor wajib hanya-baca (contoh: docs/uji/)
RO_EXIT 1
FINAL_REPORT_VALIDATOR_EXIT=1
```

**Percobaan 3 — hasil terakhir:**

```text
PERIKSA LAPORAN AUDIT — LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2.md
  artefak diperiksa : 39
  klaim dibantah    : 15
  serangan          : 33
  temuan            : 21
  mode              : menyeluruh
  cakupan berkas    : 442/480 (92%)
  berkas pengguna   : 15 baris
  kalibrasi         : 5/5 cacat ditemukan
  di luar cakupan   : 3 temuan
  CATATAN: saat cek kebersihan, berkas saluran laporan diabaikan: docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2.md

HASIL: LOLOS KONTRAK — laporan boleh diakui sebagai hasil audit independen.
RO_EXIT 0
FINAL_REPORT_VALIDATOR_EXIT=0
```

Angka otomatis adalah hitungan baris tabel: 33 “serangan” memasukkan tabel checker; usaha adversarial yang saya klaim tetap **15 keluarga** (§3). Tiga baris “di luar cakupan” adalah batas audit, bukan tiga cacat tambahan. Cetakan “kalibrasi 5/5” membaca angka laporan, **bukan penilaian dengan kunci**. Kelulusan format tidak membuktikan aplikasi aman/tes runtime lulus.

Status sesudah staging: `git status --short --untracked-files=all` → `A  docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2.md`; `git diff --cached --name-only` hanya jalur itu, `git diff --cached --check` kosong.
<!-- VALIDATOR_RESULT_END -->

**Riwayat penyerahan awal: belum ter-push pada percobaan pertama.** Hanya laporan di-stage dan di-commit. Percobaan berikut benar-benar dijalankan dan ditolak:

```text
git push origin arena/01a0bbd2-resto-barokah
! [rejected] arena/01a0bbd2-resto-barokah -> arena/01a0bbd2-resto-barokah (fetch first)
error: failed to push some refs
```

Pemeriksaan baca-saja sesudah penolakan: `git fetch origin arena/01a0bbd2-resto-barokah`; `git rev-list --left-right --count HEAD...FETCH_HEAD` → `1  1`. Common base `253d1297a3b81433d7f5809afd257d8a1b40958f`. Remote `3976b528e2b4b04a6e27702d12f60f4878a0e7d9` juga menambahkan **jalur laporan yang sama**, tetapi blob-nya `f6963997d24406e2d8e8b74628edad14969adb35`, berbeda dari blob lokal saat percobaan `1a836a4d1404384d8fc9c4f5a5e074f8a6f059e3`. Ukuran laporan remote 44.169 byte. Yang dibaca hanya nama, ukuran, hash dan metadata commit; **isi laporan remote tidak dibuka**.

Pada penyerahan awal saya tidak melakukan force push, merge/rebase atau menimpa versi remote. Commit lokal saat itu adalah `907e29ee558bc8a184a5926e14c870c52c74fcaa`. Setelah pengguna meminta agar hasil tersedia di GitHub untuk sesi lain, penyerahan dilanjutkan dengan **nama file unik**, bukan mengganti isi laporan remote. Versi remote pada nama lama tetap laporan berbeda — jangan disamakan dengan laporan ini.

Catatan hasil validasi: cetakan LOLOS di atas terjadi sebelum penambahan metadata kegagalan pengiriman ini. Temuan, tingkat, cakupan dan bukti audit tidak berubah; tidak menjalankan validator lagi untuk metadata penyerahan.

### Penyerahan lanjutan — 2026-09-20 WIB

Pengguna meminta laporan tersedia di GitHub agar agent sesi lain dapat membacanya. Laporan sesi ini diberi nama unik:

`docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2-907e29e.md`

Akhiran `907e29e` menunjuk commit lokal sebelum penamaan ulang; bukan SHA kode yang diaudit. Target audit tetap `4830b5a4f876744ecb37e2f4495c6df234376752`. Temuan, tingkat, cakupan dan hasil kalibrasi tidak berubah. Tiga rujukan aktif ke file sendiri dalam peluncur/adapter diselaraskan; nama pada keluaran validasi/status **historis** sengaja tidak ditulis ulang.

Strategi penyerahan: gabungkan riwayat Git pada cabang sesi yang sama, pertahankan file laporan remote lama byte-per-byte, dan tambahkan laporan bernama unik ini. Perubahan terhadap remote awal harus hanya penambahan file ini; tidak ada kode aplikasi, migrasi, konfigurasi atau dependensi yang diubah. Tidak memakai force push atau cabang lain.

<!-- DELIVERY_RESULT_BEGIN -->
**Sudah ter-push pada 2026-09-20 WIB.** Perintah `git push origin arena/01a0bbd2-resto-barokah` berhasil tanpa force push:

```text
3976b52..ebb60a1  arena/01a0bbd2-resto-barokah -> arena/01a0bbd2-resto-barokah
git ls-remote origin refs/heads/arena/01a0bbd2-resto-barokah
ebb60a195ee21139f115d704156ab9b6b536f87b  refs/heads/arena/01a0bbd2-resto-barokah
```

GitHub Contents API pada commit tersebut juga mengembalikan file bernama unik ini. Laporan remote lama tetap mempunyai blob `f6963997d24406e2d8e8b74628edad14969adb35`, sama persis sebelum dan sesudah penggabungan. Diff dari remote awal `3976b528e2b4b04a6e27702d12f60f4878a0e7d9` hanya **penambahan laporan unik ini**; tidak ada file kode yang berubah. Working tree sesudah push bersih.

**Untuk agent sesi lain:** baca [laporan sesi ini di GitHub](https://github.com/With-AI-Agent/Resto-Barokah/blob/arena/01a0bbd2-resto-barokah/docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2-907e29e.md). Jika mengambil melalui Git, tidak perlu mengganti branch kerja:

```bash
git fetch origin arena/01a0bbd2-resto-barokah
git show FETCH_HEAD:docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2-907e29e.md
```

Baca berkas **berakhiran `-907e29e.md`** untuk laporan ini, bukan laporan bernama lama. Isi temuan/kalibrasi tetap identik dengan commit lokal sebelum penyerahan; SHA-256 bagian tersebut: `5712502030e1e953dc9b28bc0882bb4a316bfa38e9070134f4879468e06296a8`. Catatan keberhasilan ini ditambahkan setelah bukti push di atas; commit berikutnya hanya memperbarui metadata penyerahan dan tidak mengubah verdict/temuan. Tidak menjalankan ulang validator untuk pembaruan pengiriman/nama file.
<!-- DELIVERY_RESULT_END -->

## 8. Temuan di luar cakupan

**Tidak ada temuan tambahan terverifikasi di luar 480 berkas proyek.** F-01–F-21 berada dalam lingkup; F-20 memakai paket publikasi sebagai keluaran pembanding generator target, bukan audit kode commit publikasi.

| # | Catatan/batas luar cakupan | Alasan bukan temuan tambahan | Bukti | Syarat audit lanjutan |
|---|---|---|---|---|
| O-01 | Setting cloud/secrets/review environment, kebocoran historis, supply-chain vendored | Tidak diuji live/menyeluruh; tidak boleh dinyatakan bocor atau aman | §6, R4/R6; tidak mengambil secret | Audit akses baca pengaturan/log yang sah, tanpa mengirim rahasia ke chat. |
| O-02 | Visual/provenance lisensi semua gambar/font | Metadata/format/teks lisensi bukan bukti tampilan atau hak sumber eksternal | `audit scope`: 68 gambar + 38 WOFF2 | Review visual/sumber/lisensi terpisah; PNG berakhiran webp bukan bug rendering tanpa bukti. |
| O-03 | Skor resmi kalibrasi/bahan mesin | Kunci tidak boleh diakses auditor | §5; daftar withheld scope | Pemegang kunci menilai sesudah laporan; rotasi bahan bila jawaban tersebar. |

**Prioritas tindak lanjut:** tutup F-01/F-02 dan langkah pengguna K-2; PostgreSQL untuk mengonfirmasi/menolak F-13–F-17, browser untuk F-18; audit ulang pada SHA perbaikan dengan dependencies siap. Checker struktural hijau/skor kalibrasi mandiri bukan alasan menaikkan verdict.
