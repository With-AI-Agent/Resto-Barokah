# SIAP LANJUT — penunjuk keadaan untuk sesi berikutnya

> Berkas ini DIBUAT MESIN oleh `python3 alat/lanjut-sesi.py --siapkan` dan diperiksa
> `python3 alat/lanjut-sesi.py`. Jangan disunting tangan pada bagian 1–2; bagian 3
> (rencana) justru WAJIB ditulis agent dan akan dipertahankan saat disegarkan.
> Aturan kesegaran: berkas ini wajib ikut ter-commit di commit TERAKHIR setiap batch.

## 1. Keadaan sekarang (dibaca sesi baru lebih dulu)

- **Cabang yang dilanjutkan:** `arena/01a0fbb9-resto-barokah`
- **Dasar pilihan cabang:** pilihan Lee (`--lanjut-dari`)
- **Ditulis oleh sesi:** `arena/01a0fbb9-resto-barokah`
- **Commit keadaan kerja:** `7d958a1e8e5b19115d511b779959000053c4c6cb`
- **PR:** PR #14 (base main)
PR #13 (base main)
PR #3 (base main) — **JANGAN MERGE tanpa keputusan Lee**
- **CI terakhir:** (belum ada run CI untuk commit 7d958a1e — wajar, ditulis sebelum push; run terakhir yang selesai di cabang: success (run 37199761168, commit bc128d44)) — periksa lagi setelah push: gh run list --branch <cabang> --limit 3
- **CATATAN CI:** run untuk commit handoff ini belum ada/masih berjalan saat baris ini ditulis (wajar) — sesi baru cek `gh run list --branch arena/01a0fbb9-resto-barokah --limit 3`; lanjut bila hijau atau masih berjalan dengan run selesai terakhir hijau, berhenti hanya bila merah.
- **Ditulis:** 2026-10-04 (sebelum commit yang memuat berkas ini; jadi commit keadaan di atas
  adalah induk commit ini)
- **Ruang kerja:** bersih & ter-push (dijaga pemeriksa; kalau tidak, berkas ini tidak akan lolos)
- **Berkas yang Lee salin ke chat baru:** `PROMPT_SESI_BARU.md` (STATIS — mesin memeriksanya, bukan
  menulisnya ulang tiap batch; Lee hanya mengisi baris pertama `SESI YANG AKU LANJUT`)

## 2. Keadaan proyek & butir tertangguh

- Posisi proyek: lihat `PROJECT_STATE.md` (STATUS + PUTARAN terakhir) dan `STATUS.md`.
- Bukti terakhir yang hijau: `node alat/uji-sql.mjs` · `python3 alat/uji-mutasi-0012.py` ·
  `python3 alat/uji-mutasi-0014.py` · `bash aplikasi/alat/periksa-semua.sh` · CI (lihat baris CI di atas).
- Butir tertangguh terbuka: **2** — T-026, T-028
  (rincian: `docs/TERTANGGUH.md`; hanya Lee yang boleh menutupnya)
- **Paket peninjau terbaru:** audit `AUD-4-2026-09-25.md` → `804ed86f` (504 commit di bawah HEAD saat ini) · review `PKT-2026-09-19-pr-01-putaran16.md` → `93a50bac` (796 commit di bawah HEAD saat ini) — segarkan paket SEBELUM meminta peninjau bekerja bila
  jaraknya jauh: `python3 alat/audit-independen.py --paket AUD-3 --semua` ·
  `python3 alat/review-pr.py --siapkan --pr 1 --nama pr-01-putaranNN`
- **Ruang kerja baru:** `aplikasi/node_modules` & `alat/node_modules` TIDAK ikut tersimpan di snapshot.
  Sebelum pratinjau/uji aplikasi: `bash aplikasi/alat/pratinjau.sh` (±1–2 menit). Uji SQL & pemeriksa
  Uji SQL (`node alat/uji-sql.mjs`) BUTUH `npm ci --prefix alat` lebih dulu (runner mengimpor PGlite);
  tanpa itu jalankan `npm ci --prefix alat`. Pemeriksa Python berjalan tanpa pemasangan apa pun.

## 2b. Kalau kamu sesi baru: cara menyusul pekerjaan ini

Sesi baru di platform ini mulai dari `main`, sedangkan pekerjaan ada di cabang sesi.
Jalankan (tanpa memindahkan cabang sesimu):

```
git fetch origin arena/01a0fbb9-resto-barokah:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py      # cetak KARTU SESI, lalu LAPORKAN ke Lee
```

Cabang `arena/01a0fbb9-resto-barokah` di atas adalah **pilihan Lee** (bukan tebakan mesin). Lee juga bebas memilih sesi
LAIN: saat membuka chat baru, ia menulis pilihannya di baris pertama `PROMPT_SESI_BARU.md` — dan baris
itu yang **MENANG** bila berbeda dengan handoff ini. Laporkan bedanya, lalu rapikan catatan handoff
dengan `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang>`. Sesi yang belum pernah di-push
tidak bisa dilanjutkan; sesi yang sengaja ditinggalkan ada di `docs/ops/SESI_DITINGGALKAN.md`.

Kalau checkout-mu tidak memuat `supabase/migrations/0014_penutup_celah_putaran13.sql`,
kamu berada di basis yang salah — jangan bekerja dulu, susul cabang di atas.

## 2c. Fakta cabang sesi baru: PR #1 TIDAK otomatis memuat pekerjaanmu

Kamu bekerja di cabang sesi barumu sendiri (dibuat platform; hanya ke cabang itu kamu boleh push).
PR #1 menunjuk cabang sesi SEBELUMNYA, jadi commit barumu tidak muncul di PR itu.
Bila Lee ingin meninjau lewat PR: buka PR BARU dari cabangmu (base `main`) dan laporkan tautannya.
JANGAN merge apa pun tanpa keputusan Lee.

**Base branch bila Lee membuka sesi baru lagi di Arena:** pilih cabang yang disebut di §1
(`arena/01a0fbb9-resto-barokah`), BUKAN `main` — pekerjaan belum di-merge ke sana. Kalau platform hanya bisa dari
`main`, tidak apa-apa: jalankan `python3 alat/lanjut-sesi.py --susul` SEBELUM bekerja.

## 3. Rencana berikutnya (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 13o (2026-10-04, sesi arena/01a0fbb9) — BAGIAN B F-038 SELESAI DIBANGUN (OPSI C PERDANA): MENUNGGU HAKIM F-03.** Lee *"aku ikut saran kamu"* → (1) `f97550b` migrasi `0097` AKTIF: `pengaturan.batas_daftar_pelanggan_kasir_per_kampanye` bawaan 3 (0 = tanpa batas), pagar di `daftar_voucher` sesudah penolakan identitas ganda; kasus 20–26 MERAH→HIJAU; probe `H-F-03.5-probe-identitas-fiktif.sql` kini MERAH. (2) `1a21be2` migrasi `0098` SAKLAR MATI (klaster B): `pengaturan.wajib_pin_atasan_pakai_voucher` bawaan FALSE + `voucher.pakai_disetujui_oleh` + `pakai_voucher` stempel PIN atasan sekali pakai; uji baru `pakai_voucher_pin_atasan.sql` 9 kasus MERAH→HIJAU. Suite 140 LULUS · rantai 130/0 LOLOS · kartu `B-F-03.4.md` (`bc128d4`) · F-038 DIPERBAIKI · daftar tunggu A1 6→5. **Langkah berikutnya (tanpa perlu menunggu Lee):** siapkan **HAKIM F-03** sesi lain untuk menilai B-F-03.4 (objek: baris F-038 DIPERBAIKI + dua migrasi baru + uji + klaim kartu; termasuk uji mutasi atas pagar baru 0097 bila perlu). Sesudah hakim: integrasikan. Bila Lee ingin hal lain: saklar 0098 hanya dinyalakan atas perintah Lee; potongan K-2 terbuka lain (mis. F-06) tetap kandidat. Angka: Buku Besar 228; K-1 terbuka 3 (F-001, F-052, F-063); PR #14/#13/#3 jangan merge tanpa Lee.

**PUTARAN 13n (2026-10-04, sesi arena/01a0fbb9) — KEPUTUSAN LEE OPSI C PERMANEN DITANAM KE MEKANISME.** Empat berkas diperbarui: `REKAM_PESAN_PEMILIK.md` §31 butir 25 (verbatim + syarat permanen), `PROMPT_GILIRAN.md` §5 (peran Opsi C + 5 pelajaran permanen), banner `PROMPT_SINGKAT.md`, `USULAN_PERAN_PEMBANGUN.md` §10 (hasil ukur 3 potongan + aturan permanen + mitigasi pembaca kedua). Pagar yang tidak goyah: Hakim selalu sesi lain; Perencana tidak menutup temuannya sendiri; seluruh kewajiban Pembangun; klaster cara masuk = B (saklar mati). **Satu keputusan Lee masih ditunggu: Bagian B F-038** — pelanggan fiktif jalur kasir (jalur yang memang dirancang tanpa Gmail; jalur Google/email sudah aman sejak desain): pilih 1) PIN atasan/persetujuan kedua · 2) pemisahan tugas pendaftar≠pemakai · 3) batas pendaftaran per kasir/hari · 4) terima risiko pilot tertulis (saran: masa percobaan = 4/3; pra-pilot = 1) — ada di DAFTAR_TUNGGU_LEE bagian A1. **Giliran berikutnya:** begitu Lee memilih → Pembangun potongan F-03 bagian B (pola Opsi C: MERAH dulu, kartu B-F-03.n, rantai penuh, Hakim sesi lain); bila Lee ingin lanjut tanpa menunggu → potongan K-2 terbuka lain (mis. F-06). Angka: Buku Besar 228 temuan; K-1 terbuka 3 (F-001, F-052, F-063); PR #14/#13/#3 jangan merge tanpa Lee.

**PUTARAN 13m (2026-10-04, sesi arena/01a0fbb9) — INTEGRASI HAKIM `arena/01a1050f` (H-F-03.6) SELESAI (`e300741`): BAGIAN A PMB1-F-038 TUNTAS TERVERIFIKASI · F-228 TERVERIFIKASI · PERCOBAAN OPSI B GENAP 3 POTONGAN.** Hakim mereproduksi mandiri seluruh bukti ronde 3 (uji 1–19 · probe lama MERAH · matriks 13 varian + tabel 19 bentuk · 6/6 mutan aturan normalisasi tertangkap · backfill 0096 aman pada kembar lama via harness transisi 0095→0096 · suite 139 LULUS · kontrol negatif tanpa 0096 GAGAL semestinya) → Bagian A TUNTAS, tidak perlu ronde Pembangun lagi untuk Bagian A. Baris F-038 `DIPERBAIKI → TERVERIFIKASI` (bukan DITUTUP — Bagian B menunggu keputusan Lee; sekaligus menjaga Kunci K2 `susun-daftar-tunggu-lee.py` agar pertanyaan tak hilang). F-228 BARU → TERVERIFIKASI (koreksi saya sejak `2aaedf3` dicatat). Koreksi narasi CI kartu B-F-03.3 diterima tanpa temuan baru (hijau nyata = run `77d2f00` & `dc56eb5`). Catatan mekanisme hakim: penutupan F-216/F-217 kelak butuh status `DIPERBAIKI` dulu (penjaga hanya mengizinkan DIPERBAIKI→DITUTUP). **DUA KEPUTUSAN LEE MENUNGGU:** (A) **Bagian B F-038** — 1 PIN atasan/persetujuan kedua · 2 pemisahan tugas · 3 batas pendaftaran per kasir · 4 terima risiko pilot tertulis (saran Perencana: masa percobaan = 4/3; pra-pilot = 1); (B) **nasib peran Pembangun oleh Perencana** sesudah percobaan 3 potongan — Opsi C (kolaps penuh) vs kembali Opsi A (sesi terpisah); tabel ukur & 5 pelajaran di `USULAN_PERAN_PEMBANGUN.md` §9; rangkuman rekomendasi: Opsi C = hemat serah-terima & konteks utuh, risiko = tak ada pembaca kedua atas diff Perencana (mitigasi: Hakim tetap independen + rantai penuh); Opsi A = isolasi terjaga, biaya = konteks diulang & serah-terambah. **Giliran berikutnya:** begitu Lee memutuskan A/B → kerjakan; bila Lee ingin lanjut tanpa menunggu: kandidat Pembangun = bagian B F-038 (sesudah keputusan) atau potongan K-2 terbuka lain (mis. F-06). Angka: Buku Besar 228 temuan; K-1 terbuka 3 (F-001, F-052, F-063); PR #14/#13/#3 jangan merge tanpa keputusan Lee.

**PUTARAN 13l (2026-10-02 ±21:00 WIB, sesi arena/01a0fbb9) — RONDE 3 PMB1-F-038 BAGIAN A SELESAI DIBANGUN & TERBUKTI: MENUNGGU HAKIM F-03.** Lee: *"Lanjutkan rantai tersebut dan kalau sudah siap baru respons aku lagi."* Percobaan Opsi B giliran #3 (kartu `kartu/B-F-03.3.md`): migrasi `0096_penyatuan_gaya_penulisan_nomor_hp.sql` — normalisasi tunggal (buang non-digit → buang awalan akses `00` berulang → `62`+nol-sesudahnya→`0` → tanpa nol depan diberi `0`) menutup 9 gaya penulisan yang dibocorkan H-F-03.5 (13/13 matriks hakim tersatukan); backfill aman tertua-menang tanpa penghapusan data (merujuk F-227). Uji kasus 9–19 MERAH tanpa 0096 → HIJAU sesudah; kedua probe hakim (H-F-03.4 & H-F-03.5) kini MERAH; suite 139 LULUS; rantai penuh **130 LOLOS · 0 GAGAL · RANTAI: LOLOS** (dua usaha sebelumnya gagal hanya karena checkout kembali dangkal seusai reset workspace platform — catatan mekanisme untuk G-01/G-04: rantai sebaiknya auto-unshallow). Perbaikan `fc2d9ab`; Ter-push kartu terisi sebelum commit (pelajaran F-228); CI tip `77d2f00` SUCCESS. Tabel ukur percobaan #2 & #3 + 5 pelajaran tertulis di `USULAN_PERAN_PEMBANGUN.md` §9 — **percobaan Opsi B genap 3 potongan; keputusan Lee (Opsi C kolaps vs kembali Opsi A) menunggu Hakim menutup #3**. Bagian B F-038 (identitas fiktif) tetap menunggu keputusan Lee — 4 pilihan ada di `DAFTAR_TUNGGU_LEE.md` (saran Perencana: masa percobaan = pilihan 4/3; pra-pilot = pilihan 1). **Giliran berikutnya:** Lee buka sesi baru PERAN HAKIM · POTONGAN F-03 · CABANG PERENCANA arena/01a0fbb9-resto-barokah (fokus kartu B-F-03.3) → kembali ke sini ketik `integrasikan <cabang>`. Angka: Buku Besar 228 temuan (K-1/K-2 terbuka 44; K-1 terbuka 3). PR #14/#13/#3 jangan merge tanpa keputusan Lee.

**PUTARAN 13k (2026-10-02 ±18:15 WIB, sesi arena/01a0fbb9) — INTEGRASI `arena/01a0fc20` SELESAI (`d730f57`): F-127 DITUTUP · F-038 KEMBALI TERVERIFIKASI (ronde 3) · 5 temuan baru F-224…F-228 · 3 asumsi A-142…A-144.** HAKIM F-09 (`H-F-09.7`) menutup percobaan Opsi B #1 (reproduksi mandiri lengkap). HAKIM F-03 (`H-F-03.5`) mengembalikan F-038: (A) 9 penulisan nomor masih bocor; (B) identitas fiktif butuh keputusan Lee — 4 pilihan disalin ke kolom Perbaikan baris F-038 & otomatis masuk `DAFTAR_TUNGGU_LEE.md`. `F-228` membuktikan CI `25f0faf` merah deterministik (kartu templat) → klaim flake F-219 di kartu B-F-03.2 dikoreksi/dicabut. Kejadian teknis: ref lokal sempat mundur ke `f9f78a9` (pulih tanpa kehilangan via `git reset --mixed` ke origin + fetch seluruh cabang). Angka: Buku Besar 228 temuan · terbuka K-1/K-2 = 44 · **K-1 terbuka tinggal 3** (F-001, F-052, F-063). **Giliran berikutnya:** (a) **keputusan Lee** atas F-038 bagian B (1 PIN atasan/persetujuan kedua · 2 pemisahan tugas · 3 batas pendaftaran per kasir · 4 terima risiko pilot tertulis); (b) Pembangun ronde 3 F-038 = normalisasi tuntas (awalan akses `00`, nol pasca-kode negara `+62 (0)`, telepon rumah tanpa nol) + keputusan B — menunggu `lanjut`; (c) laporan percobaan Opsi B sesudah 3 potongan (#1 tuntas, #2 dikembalikan, #3 belum) tetap menunggu #3 selesai. PR terbuka #14/#13/#3 — JANGAN merge tanpa keputusan Lee.

**PUTARAN 13j (2026-10-02 ±17:00 WIB, SESI LANJUTAN `arena/01a0fbb9-resto-barokah` — Lee: sesi sebelumnya eror, lanjutkan semuanya):** orientasi PRO.md LOLOS; susul ke `3210dd7` (13i); catatan "CI pending" handoff lama = run `cancelled` concurrency (bukan merah) — CI `f9f78a9` & `3210dd7` SUCCESS. **PERCOBAAN OPSI B #2 SELESAI — PEMBANGUN potongan F-03 (fokus PMB1-F-038):** migrasi baru `0095_penyatuan_awalan_nomor_hp_pelanggan.sql` (fungsi `normalisasi_telepon_pelanggan` menyatukan `+62`/`62`/`8` → bentuk `0…`; pemicu INSERT + backfill) menutup celah yang dikembalikan HAKIM H-F-03.4 (probe hakim kini MERAH; uji kasus 5–8 MERAH tanpa 0095 → HIJAU; suite 139 LULUS; **rantai penuh 130 LOLOS · 0 GAGAL · `RANTAI: LOLOS`**). Kartu `kartu/B-F-03.2.md`, bukti `bukti/B-F-03.2-F-038-merah.txt` + `-hijau.txt` + `-rantai.txt`; perbaikan `18bd3a7`; F-038 → `DIPERBAIKI` (penutup = Hakim sesi lain). **Kejadian teknis:** checkout dangkal → `periksa-paket.py` GAGAL di rantai run 1; `git fetch --unshallow origin` membereskannya (pelajaran butir 3 masih berlaku). CI cabang ini: `25f0faf` GAGAL acak di blok 60 (pola flake F-219; log tak terunduh; keempat syarat aturan F-219 tercatat di kartu B-F-03.2 §4) lalu `edba563` **SUCCESS**. **Giliran berikutnya:** (a) HAKIM potongan F-03 (verifikasi B-F-03.2/F-038) dan HAKIM potongan F-09 (menutup F-127 — percobaan Opsi B #1) — keduanya sesi baru yang dibuka Lee, prompt dari `PROMPT_SINGKAT.md`; (b) percobaan Opsi B #3 menunggu `lanjut` dari Lee di sesi Perencana ini — kandidat: F-02 rombak lanjutan (F-010/F-020/F-021) atau F-06 (6 baris K-2 belum pernah dibangun). Angka: Buku Besar 223 temuan (terbuka K-1/K-2 = 43; K-1 terbuka 4: F-001, F-052, F-063, F-127). PR terbuka #14/#13/#3 — JANGAN merge tanpa keputusan Lee.

**PEMBUKAAN SESI `arena/01a0e747` (2026-09-28, ±16:10 WIB) — ORIENTASI PRO.md, BELUM ADA PEKERJAAN BARU:**
> 1. **PR #15 sudah di-merge Lee ke `main`** (merge commit `141d40f0`, 2026-09-28 15:59 WIB; ujung cabang `arena/01a0d09b` = `477cf360`, CI-nya **success** run `#36396868493`). Catatan "CI in_progress run 36396709886" di handoff lama merujuk commit `c3c50a8d` yang runnya **cancelled** karena tertimpa push berikutnya — bukan CI merah. CI `main` untuk `141d40f0` (run `#36400724879`) masih berjalan saat sesi dibuka.
> 2. Sesi ini bercabang dari `main` **yang sudah memuat seluruh pekerjaan 01a0d09b** — `--susul` menjawab **SUDAH** (tidak ada yang perlu disusul). Sesi 01a0d09b otomatis berstatus *terserap*, BUKAN ditinggalkan.
> 3. **Kejadian teknis:** checkout awal Arena berupa *shallow clone* (kedalaman 1) sehingga `--susul` pertama keliru berkata "punya commit sendiri"; dibereskan dengan `git fetch --unshallow origin` (hanya melengkapi riwayat, tidak mengubah apa pun). Sesi baru berikutnya: bila `--susul` BERHENTI padahal cabang jelas sudah di-merge, periksa `git rev-parse --is-shallow-repository` dulu.
> 4. Handoff disegarkan ke sesi ini (`--siapkan --lanjut-dari arena/01a0e747-resto-barokah`) hanya supaya pemeriksa LOLOS; **arah kerja berikutnya menunggu jawaban Lee atas "Mau apa di sesi ini?"**.
> 5. **Arahan Lee (2026-09-28 sore): rancang dulu mekanisme "Pemeriksaan Mendalam" bertahap** (fondasi dulu → per fase → dst., auditor bekerja per potongan lewat beberapa giliran "lanjut", pencatatan sistematis lintas sesi). Rancangan + riset ditulis di `docs/uji/pemeriksaan/RANCANGAN_PEMERIKSAAN_BERTAHAP.md` (status RANCANGAN; 8 pertanyaan keputusan di §11). **Lee menyetujui seluruh rancangan (2026-09-28 sore, REKAM §31)** + 2 tambahan: tahap & petugas MENYELURUH (§4c) dan **FASE 11 BELUM DIKERJAKAN kecuali T11-07** (§4d; ROADMAP dikoreksi: 8 tugas kembali `[ ]`, 3 dokumen diberi spanduk koreksi). Lee menegaskan ulang (tidak ingat pasti): hanya deploy Cloudflare, itupun versi Fase 10 — bukti repo: T11-07 = **SEBAGIAN** (deploy `b3e00686` pra-PMB; ROADMAP kini 146/193). **⚠️ Temuan pra-registrasi `PMB1-F-001` (kandidat K-1, BARU, menunggu keputusan Lee):** migrasi `0086` menanam akun `@resto.test` ber-PIN bawaan khusus di produksi + RPC login mendaftarkan perangkat sendiri + repo publik → jangan disentuh tanpa izin Lee; rincian REKAM §31 butir 6 & rancangan §4d. **Tahap 0 PMB SUDAH DISIAPKAN (Lee: "Lanjut", 2026-09-28):** `docs/uji/pemeriksaan/PMB-1/` (README peta folder · PAPAN 63 potongan: 17 Tahap 1 BELUM + 46 kerangka RENCANA · BUKU_BESAR (PMB1-F-001 BARU) · MATRIKS v0 · REGRESI_WAJIB · ASUMSI · kartu templat · kalibrasi Tahap 1 = bahan-tahap-1 + kunci terenkripsi, **sandi hanya di tangan Lee**), `docs/uji/pemeriksaan/PROMPT_GILIRAN.md`, penjaga `alat/periksa-pemeriksaan.py` (+`--uji-diri`, `--gerbang n`) & `alat/susun-matriks-telusur.py` (+`--periksa`) terdaftar di ci.yml/gerbang-ci/periksa-semua.sh. **Sisa Tahap 0 = uji coba F-01 oleh sesi pemeriksa yang dibuka Lee** (base branch cabang ini, tempel PROMPT_GILIRAN dengan `PERAN: PEMERIKSA`, `POTONGAN: F-01`). Setelah sesi itu selesai, Lee kembali ke sesi Perencana dan mengetik `integrasikan arena/<id>` → Perencana: `git fetch origin <cabang> && git merge --no-ff origin/<cabang>`, jalankan `python3 alat/periksa-pemeriksaan.py`, perbaiki mekanisme dari pengalaman F-01 (catat di rancangan §13), baru Tahap 1 dibuka. **Keputusan Lee (REKAM §31 butir 9): PIN akun percontohan TIDAK diganti/dihapus selama masa percobaan** (tanpa data asli) — PMB1-F-001 tetap BARU, wajib ditutup sebelum data asli/pilot (L-01/L-02). **Cara memberi prompt sesi giliran (butir 10): Perencana menempel prompt singkat dari `docs/uji/pemeriksaan/PROMPT_SINGKAT.md` di chat** (menyuruh agent baca PRO.md → konteks → PROMPT_GILIRAN); pengecualian orientasi GILIRAN PMB sudah ada di PRO.md. Urutan resmi: **PMB → Fase 11 → pilot**. Langkah berikutnya: **uji coba F-01 lalu Tahap 1 PMB** (papan, matriks telusur v0, prompt giliran Pemeriksa/Hakim/Menyeluruh, `alat/periksa-pemeriksaan.py` (rencana), kalibrasi Tahap 1, uji coba 1 potongan) — mulai setelah Lee mengonfirmasi jawaban soal Fase 11. Butir tertangguh tetap 2 (T-026, T-028). PR terbuka: #14, #13, #3 (laporan audit sesi lain) — jangan merge tanpa keputusan Lee. **UJI COBA F-01 SELESAI & TERINTEGRASI (2026-09-28 ±20:30 WIB) → TAHAP 1 DIBUKA:** dua sesi (arena/01a0e807 & 01a0e806) sama-sama mengerjakan F-01 → keduanya digabung `--no-ff` (kartu `K-F-01.md` + ulangan `K-F-01.2.md`; ID e806 dinomori ulang F-005…F-008/A-008…A-012); Buku Besar 8 temuan (F-001 K-1 · F-002…F-005 K-3 · F-006…F-008 K-4, semua BARU — **menunggu Hakim, belum boleh diperbaiki siapa pun**), 12 asumsi. Perbaikan mekanisme tercatat di rancangan §13 butir 6 & REKAM §31 butir 11 (kartu ulangan, status `DUPLIKAT`, potongan berbeda per sesi paralel, `periksa-bersih.py` wajib, validator terima `berkas:baris`). **Giliran berikutnya yang disarankan Perencana:** HAKIM F-01 (sesi baru, independen dari kedua pemeriksa) + PEMERIKSA F-02 + PEMERIKSA F-03 secara paralel — prompt dari `PROMPT_SINGKAT.md`, satu potongan per sesi; setelah tiap sesi selesai Lee mengetik `integrasikan <cabang>` di sesi Perencana ini. **PUTARAN 2 TERINTEGRASI (2026-09-29 ±07:40 WIB):** cabang 01a0e834 (HAKIM F-01, dua hakim paralel → `kartu/H-F-01.md`; F-01 **DIHAKIMI**: 7 TERVERIFIKASI · 1 DUPLIKAT · F-007/F-008 naik K-3), 01a0e836 (F-02 SELESAI, 3 kartu, 21 temuan `PMB1-F-010…F-030`), 01a0e839 (F-03 SELESAI, 3 kartu, 20 temuan `PMB1-F-031…F-050`, **2 K-1** menunggu Hakim: voucher diklaim anon tanpa verifikasi [probe `PMB-1/bukti/F-03-voucher-anon.sql`], owner masuk cukup email+PIN dari browser mana pun). Buku Besar **50 temuan** (7 TERVERIFIKASI · 1 DUPLIKAT · 1 DIPERBAIKI · **41 BARU**), 39 asumsi. Cacat mesin PMB `PMB1-F-009` (uji-diri tumpul) **diperbaiki Perencana** `7a3120e` → DIPERBAIKI, ditutup oleh sesi lain. **Belum ada perbaikan proyek — dilarang sebelum Hakim.** Giliran berikutnya: **HAKIM F-02**, **HAKIM F-03** (satu hakim per potongan, beban 21/20 baris), **PEMERIKSA F-04 / F-05 / F-06** (satu potongan per sesi; kalau Lee memakai >1 agent per cabang, agent kedua otomatis kartu `.2`). **PUTARAN 3 TERINTEGRASI (2026-09-29 ±08:10 WIB) lewat alat baru `alat/pmb-integrasi.py`:** F-02 **DIHAKIMI** (`H-F-02`; F-009 DITUTUP oleh hakim), F-03 **DIHAKIMI** oleh dua hakim independen (`H-F-03` + `H-F-03.2`; **3 sengketa → PERLU-INFO** F-044/F-049/F-050 menunggu hakim ketiga/Lee; F-046 → K-2), F-04/F-05/F-06 **SELESAI** (2 kartu tiap potongan, 39 temuan `PMB1-F-053…F-091`; K-1 baru: F-063 owner mendaftarkan perangkat sendiri via TECH_SPEC:19/auth.ts), temuan hakim `F-051` K-2 & `F-052` K-1 (RPC login 0087, potongan P-10-00). Buku Besar **91 temuan** (39 TERVERIFIKASI · 41 BARU · 3 PERLU-INFO · 6 DUPLIKAT · 1 PALSU · 1 DITUTUP), 60 asumsi. **Belum ada perbaikan proyek** (Pembangun baru boleh setelah Tahap 1 ditutup — rancangan; K-1 boleh segera atas keputusan Lee). Giliran berikutnya: **HAKIM F-04 / F-05 / F-06** (satu hakim per potongan), **HAKIM F-03 (hakim ketiga, sengketa saja)**, **PEMERIKSA F-07 / F-08 / F-09**. Aturan sengketa & alat: `PMB-1/README.md`. **PUTARAN 4 TERINTEGRASI (2026-09-29 ±09:25 WIB):** F-04/F-05/F-06 **DIHAKIMI**, sengketa F-03 tuntas (hakim ketiga `H-F-03.3`), F-07/F-08/F-09 **SELESAI** (`PMB1-F-096…F-135`). Buku Besar **135 temuan** (83 TERVERIFIKASI · 36 BARU · 11 DUPLIKAT · 2 PALSU · 2 DIPERBAIKI · 1 DITUTUP), 77 asumsi. Cacat mesin `F-092`/`F-094` diperbaiki (`3dadbba`, menunggu penutup). **K-1 TERVERIFIKASI: F-001, F-031, F-036, F-063** (semua soal RPC login/perangkat & voucher) + K-1 BARU F-052, F-127 → **keputusan Lee dibutuhkan: Pembangun K-1 mulai sekarang atau tunggu gerbang Tahap 1**. Giliran berikutnya: **HAKIM F-07 / F-08 / F-09**, **HAKIM P-10-00** (baris F-051/F-052 saja, tanpa ubah PAPAN), **PEMERIKSA F-10 … F-17** (F-17 = bahan kalibrasi, diperiksa seperti dokumen biasa). Setelah semua F-xx DIHAKIMI → `python3 alat/periksa-pemeriksaan.py --gerbang 1`. **PUTARAN 5 TERINTEGRASI (2026-09-29 ±11:30 WIB):** F-07/F-08/F-09 **DIHAKIMI**, P-10-00 dihakimi (PAPAN tetap RENCANA), F-10/F-11/F-12 **SELESAI** (`PMB1-F-137…F-170`). Buku Besar **170 temuan** (116 TERVERIFIKASI · 36 BARU · 11 DUPLIKAT · 3 DITUTUP · 2 PALSU · 1 DIPERBAIKI · 1 PERLU-INFO), 111 asumsi. **Sengketa hakim PMB1-F-129 (F-09)** → hakim ketiga (`HAKIM F-09`, hanya F-129) atau keputusan Lee. **6 K-1 semuanya TERVERIFIKASI** (F-001, F-031, F-036, F-052, F-063, F-127) — menunggu keputusan Lee soal Pembangun. Cacat mesin F-136 diperbaiki `3f56abb` (menunggu penutup). Alat integrasi: `--abaikan-luar-pmb`, penutup ganda otomatis. Giliran berikutnya: **HAKIM F-10 / F-11 / F-12**, **HAKIM F-09 (hakim ketiga, F-129 saja)**, **PEMERIKSA F-13 … F-17**, opsional HAKIM P-9-00 / P-1B-00. **PUTARAN 6 TERINTEGRASI (2026-09-29 ±14:40 WIB):** F-10/F-11/F-12 **DIHAKIMI**, sengketa F-129 tuntas (TERVERIFIKASI K-2), F-13/F-14/F-16/F-17 **SELESAI** (`PMB1-F-172…F-201`), **F-15 BELUM**. Buku Besar **201 temuan** (148 TERVERIFIKASI · 33 BARU · 13 DUPLIKAT · 4 DITUTUP · 3 PALSU), 130 asumsi. Sisa Tahap 1: **PEMERIKSA F-15 → HAKIM F-13 / F-14 / F-16 / F-17 → HAKIM F-15**. Setelah itu **PEMBANGUN per potongan, satu per satu** (naskah §5 PROMPT_GILIRAN; 51 K-1/K-2 terbuka; F-001 & klaster cara masuk menunggu keputusan Lee; F-17 tidak dibangun — dinilai Perencana di gerbang). Baris luar potongan F yang masih BARU: F-093 (P-9-00), F-095 (P-1B-00), F-171 (P-10-00), F-191 (P-2-00) → dihakimi saat potongan Tahap 2 itu digilir (tidak menahan gerbang 1). **PUTARAN 7 TERINTEGRASI (2026-09-29 ±15:30 WIB):** F-13/F-14/F-16/F-17 **DIHAKIMI**, F-15 **SELESAI** (`PMB1-F-203…F-215`). Buku Besar **215 temuan** (174 TERVERIFIKASI · 18 BARU · 15 DUPLIKAT · 4 DITUTUP · 4 PALSU), 136 asumsi. **Sisa pemeriksaan Tahap 1: HAKIM F-15 saja.** Sesudahnya: PEMBANGUN per potongan berurutan (52 K-1/K-2 terbuka; urutan usulan: F-03 → F-09 → F-06 → F-08 → F-02 → F-10 → F-04 → F-11 → F-16 → F-17(tidak dibangun) → sisanya 1 temuan), keputusan A/B Lee untuk F-001/F-036/F-063/F-052, lalu Perencana membuka kunci kalibrasi dan menjalankan `--gerbang 1`. F-202 (G-04) DIPERBAIKI `ed8625d` menunggu penutup sesi lain. **PUTARAN 8 TERINTEGRASI (2026-09-29 ±16:45 WIB): PEMERIKSAAN TAHAP 1 SELESAI — 17/17 potongan DIHAKIMI** (F-15 `H-F-15`; F-202 DITUTUP). **Kunci kalibrasi Tahap 1 dibuka Perencana (`d52b775`): 6/6 cacat tanaman ditemukan, 1 palsu, 3 bonus** → 9 baris F-17 DITUTUP (`PMB-1/kalibrasi/HASIL-TAHAP-1.md`). Buku Besar **215 temuan** (178 TERVERIFIKASI · 15 DUPLIKAT · 14 DITUTUP · 4 PALSU · 4 BARU di P-xx), 136 asumsi. **Gerbang Tahap 1 (`--gerbang 1`) kini hanya ditahan 49 K-1/K-2 TERVERIFIKASI** (5 K-1 · 44 K-2) di F-01…F-16. Mekanisme PEMBANGUN siap & teruji: kartu `B-<ID>.md` (`TEMPLAT_B.md`, penjaga), `pmb-integrasi.py --pembangun` (berkas proyek ikut, daftar terlarang, sha perbaikan harus ada di cabang, `periksa-bersih.py` wajib). **Berikutnya: PEMBANGUN satu potongan per sesi, berurutan** — F-09 (10) → F-03 (9) → F-06 (6) → F-08 (5) → F-10 (4) → F-02 (4) → F-04 (2) → F-11 (2) → F-16 (2) → F-05/F-07/F-13/F-14/F-15 (1 masing-masing); F-17 tidak dibangun (sudah DITUTUP). Tiap cabang Pembangun diintegrasikan Perencana dengan `--pembangun`, lalu HAKIM (bukan pembangunnya) menutup baris DIPERBAIKI → DITUTUP. **Keputusan A/B Lee untuk klaster cara masuk (F-001/F-036/F-063/F-052) wajib ada sebelum Pembangun F-03/F-04/F-10** (F-09 aman dimulai sekarang). **PUTARAN 9 TERINTEGRASI (2026-09-29 ±22:55 WIB) — PEMBANGUN PERTAMA F-09:** `arena/01a0ec8d` masuk (`b5e62b3`, mode `--pembangun`, CI hijau, 133 uji SQL): **F-119 & F-132 DIPERBAIKI** (menunggu HAKIM), F-133 sebagian, **8 baris F-09 menunggu Lee/operator** (`MENUNGGU KEPUTUSAN LEE:`/`BUTUH LEE/OPERATOR:` di kolom Perbaikan). `arena/01a0ec99` = Pembangun paralel tak disengaja untuk F-09 → **kode TIDAK diintegrasikan** (dua migrasi 0088, CI merah `periksa-uji.py`, F-130/F-131 = pembangunan T3-01/T3-06); kartu `B-F-09.2` + bukti disalin dengan catatan Perencana (`2bba5e0`); cabang tidak dihapus. Buku Besar 215 temuan (176 TERVERIFIKASI · 2 DIPERBAIKI · 15 DUPLIKAT · 14 DITUTUP · 4 PALSU · 4 BARU), 137 asumsi; gerbang 1 ditahan 49 K-1/K-2 (47 TERVERIFIKASI + 2 DIPERBAIKI). **Dua keputusan Lee menahan Pembangun berikutnya:** (1) temuan "fitur ROADMAP/PRD diklaim selesai tapi belum dibangun": A bangun sekarang di dalam PMB / B jujurkan `[x]`→`[ ]` dulu lalu bangun sesudah PMB (rekomendasi B); (2) klaster cara masuk F-001/F-036/F-063/F-052 (rekomendasi B). Giliran berikutnya yang aman sekarang: **HAKIM F-09** (verifikasi F-119/F-132 → DITUTUP atau kembali TERVERIFIKASI). Naskah: §2 butir 4 (dua agent satu cabang), §5 (jenis tugas ROADMAP belum dibangun). **USULAN JAMINAN TUNTAS (2026-09-29 ±23:35 WIB, menunggu keputusan Lee):** menjawab kebimbangan Lee (REKAM §31 butir 20) — `docs/uji/pemeriksaan/USULAN_JAMINAN_TUNTAS.md`: jalur **B+** = jujurkan `[x]`→`[ ]` + kunci mesin K1–K6 (gerbang akhir semua tingkat, `DAFTAR_TUNGGU_LEE.md` otomatis, `periksa-roadmap` menolak centang tanpa bukti mesin/tanda tangan Lee dengan masa transisi `⚠️ BUKTI-BELUM`, uji pada baris DIPERBAIKI/DITUTUP harus ada, sensus 100 % klaim di Tahap 2, Pembangun+Hakim permanen). Hitungan kasar: 146 `[x]`, 39 tanpa rujukan uji/penjaga mesin, 65 'uji manual' tanpa catatan. Bila Lee setuju: Perencana membangun K1–K5 (mekanisme) dulu, lalu giliran PEMBANGUN dokumen F-09. HAKIM F-09 sedang berjalan (belum diintegrasikan).
>
> **PUTARAN 10 (2026-09-30 ±00:25 WIB, sesi arena/01a0e747) — HAKIM 4 F-09 + JAMINAN TUNTAS DIBANGUN:** Lee: "Aku setuju dengan rekomendasi kamu" (REKAM §31 butir 21: B+ disetujui; klaster cara masuk = B). (1) `arena/01a0eddf` (kartu `H-F-09.4`) diintegrasikan `d6faff2`: **F-119 & F-132 DITUTUP** (F-09 = 17 TERVERIFIKASI · 2 DITUTUP). (2) Kunci mesin K1–K5 dibangun (`1dc8eba`; rincian `docs/uji/pemeriksaan/USULAN_JAMINAN_TUNTAS.md` §8): `periksa-pemeriksaan.py --gerbang akhir` (K1) · `alat/susun-daftar-tunggu-lee.py` → `PMB-1/DAFTAR_TUNGGU_LEE.md` dibuat ulang tiap integrasi oleh `pmb-integrasi.py`, dijaga `periksa-pemeriksaan.py` + langkah CI `--periksa` (K2) · `periksa-roadmap.py` menolak `[x]` tanpa baris `Bukti:` nyata — 146 centang lama diberi `⏳ BUKTI-BELUM` + daftar beku `PMB-1/BUKTI_BELUM_BASELINE.txt` (106 rujukan-mesin · 26 uji-manual · 14 tanpa-rujukan; hanya boleh menyusut) (K3) · DIPERBAIKI/DITUTUP wajib menyebut berkas uji yang ADA (`tanpa uji mesin:` hanya untuk dokumen; 11 baris pra-aturan dibekukan `K4_SEBELUM_ATURAN`) (K4) · `--gerbang 2` sensus klaim 100 % + bagian `## Sensus klaim` kartu K (K5). Naskah: `PROMPT_GILIRAN.md` §4 (kontrak bukti), §5 (klaster B; PEMBANGUN dokumen; pemeriksa Tahap 2 sensus), §6; `TEMPLAT_K.md`; `PROMPT_SINGKAT.md`; README PMB-1. Buku Besar: 10 baris diberi `KEPUTUSAN LEE 2026-09-29 (…)` (F-001/F-036/F-052/F-063/F-117/F-127 klaster B; F-118/F-130/F-131/F-133 B+). Alat integrasi diuji dengan commit sintetis (daftar tunggu dibuat ulang otomatis, penjaga LOLOS, merge dibatalkan). Angka daftar tunggu: A1 2 · A2 10 · B 6 · C 0 · D 146 · E 2 · F 23; temuan terbuka 180. **Giliran berikutnya (prompt sudah diberikan ke Lee):** PEMBANGUN dokumen F-09 (jujurkan T3-01/T3-06/T3-11/T6-02…05 → `Dibuka kembali`), lalu/paralel PEMBANGUN F-03 (F-031/F-036 K-1 dengan klaster B + 7 K-2). Sesudah integrasi keduanya → HAKIM masing-masing → Pembangun F-04/F-10/F-08/F-02 → `--gerbang 1`.

> **PUTARAN 11 (2026-09-30 12:36 WIB, sesi arena/01a0e747) — PEMBANGUN DOKUMEN F-09 TERINTEGRASI, eff7 DITOLAK (CI MERAH), ARAHAN PUSH LEE DITANAM:** `arena/01a0eff4` masuk `af38951` (F-118/F-130/F-131/F-133 DIPERBAIKI; ROADMAP T3-01/T3-06/T3-11/T6-02…05 `[ ]` + `Dibuka kembali`; baseline 146→139) + koreksi Perencana `3e01d5c` (paragraf T6-02 & bukti `B-F-09-rantai.txt` yang tertimpa cabang dipulihkan → F-216/F-217). `arena/01a0eff7` (B-F-03/04/05/02/07, 14 DIPERBAIKI, migrasi 0089–0094) **belum diintegrasikan**: CI tip `d73c7d0` MERAH di `aplikasi/alat/periksa-uji.py` (`src/lib/voucher.ts`, `src/hook/useAlamatCabang.ts` tanpa `*.test.ts`), kartu menulis LOLOS karena `periksa-semua.sh` mati di `lanjut-sesi.py` → F-218. Mekanisme (`ed3a229` + commit ini): `pmb-integrasi.py` menjaga bukti kekal + pagar ROADMAP/K6; arahan Lee "hasil harus masuk GitHub" (REKAM §31 butir 22) → `alat/periksa-push.py`, `Ter-push sampai` wajib di kartu B, naskah; `alat/rantai-bukti-giliran.py` = rantai CI tanpa berhenti. Buku Besar 218 (7 BARU · 172 TERVERIFIKASI · 4 DIPERBAIKI · 16 DITUTUP); daftar tunggu A1 2 · A2 6 · B 6 · C 7 · D 139 · E 2 · F 23. **Giliran berikutnya:** sesi eff7 memperbaiki cabangnya (prompt sudah diberikan), HAKIM 5 F-09 (4 DIPERBAIKI B-F-09.3); sesudah eff7 hijau → `integrasikan arena/01a0eff7-resto-barokah` → HAKIM F-02/F-03/F-04/F-05/F-07. Tidak ada kode aplikasi/produksi yang berubah di cabang Perencana. Rincian: `docs/uji/pemeriksaan/RANCANGAN_PEMERIKSAAN_BERTAHAP.md` §13 (Putaran 11), kartu `B-F-09.3` (catatan Perencana), Buku Besar F-216/F-217/F-218, `PMB-1/README.md` (bukti hijau sebelum integrasi). **Perintah integrasi eff7 nanti:** verifikasi `gh run list --branch arena/01a0eff7-resto-barokah --limit 1` = success (atau `rantai-bukti-giliran.py` pada worktree tip → `RANTAI: LOLOS`), lalu `python3 alat/pmb-integrasi.py origin/arena/01a0eff7-resto-barokah --pembangun` (68 berkas; `denyut-harian.yml` bertambah 4 langkah Edge `ringkasan_harian`/`peringatan_batas` — hanya aktif dari `main`, keputusan Lee saat PR; F-019/F-037/F-048 menunggu Lee di kolom Perbaikan).

> **PUTARAN 12 (2026-09-30 16:41 WIB, sesi arena/01a0e747) — DUA CABANG MASUK (HAKIM F-09 + PEMBANGUN 5 POTONGAN), CI `ed3a229` TERBUKTI SEMENTARA, PERTANYAAN LEE SOAL PERAN PEMBANGUN DIJAWAB:** Lee: *"integrasikan arena/01a0f0e9-resto-barokah dan arena/01a0eff7-resto-barokah"*. **(1)** `arena/01a0f0e9` (HAKIM 5 F-09, kartu `H-F-09.5`, CI hijau) masuk **`fb52fd3`**: F-130/F-131/F-133 **DITUTUP** (hanya klaim/perilaku yang diperbaiki — fitur katalog DB, pindah meja, kirim pelayan–kasir tetap terbuka), **F-118 kembali `DIPERBAIKI → TERVERIFIKASI`** (cakupan lebih lebar: T3-04/T3-12/T5-07…T5-11 masih `[x]`; integrasi cetak produksi belum terbukti — berkas wajib `LayarKasirCetak.test.tsx`/`LayarDapurCetak.test.tsx` tidak ada), **F-216/F-217/F-218 TERVERIFIKASI**; tidak ada kartu `H-G-04`, PAPAN G-04 tetap RENCANA. **(2)** `arena/01a0eff7` (setelah perbaikannya: 2 berkas uji baru, `RANTAI: LOLOS` 129/0, Ter-push) masuk **`5b5325f`** `--pembangun`: **14 baris DIPERBAIKI** (F-02: F-010/F-020/F-021 · F-03: F-031/F-032/F-036/F-038/F-039/F-046/F-049 · F-04: F-060/F-063 · F-05: F-076 · F-07: F-096) + **49 berkas proyek** (6 migrasi `0089`–`0094`, uji SQL & TS, `docs/PETA_UI.md`, `docs/PRD.md`, `docs/TECH_SPEC.md`, `PANDUAN_PENGGUNA.md`, `alat/eksekusi-*.mjs` + 4 langkah Edge di `denyut-harian.yml`, `alat/peta-ui.py`, jangkar mutasi). Klaster cara masuk (F-036/F-063) masuk **di balik saklar mati** (`0090` bawaan FALSE, keputusan Lee = B); F-019/F-037/F-048 tetap menunggu Lee/operator (A1 = 5). **Tidak ada deploy/migrasi produksi.** **(3)** Misteri CI `ed3a229` (merah di blok Python tanpa sebab yang bisa direproduksi) **tertutup**: run `36674279740` untuk `00cb4ee` = **success** → kegagalan itu sementara/lingkungan. **(4)** F-216/F-217/F-218 (G-04) → **DIPERBAIKI** (`ad3561f`): Perencana pemilik mekanisme menulis kolom Perbaikan (pagar bukti kekal & pagar ROADMAP di `alat/pmb-integrasi.py`; rantai bukti giliran + kewajiban push) tetapi **tidak menutup temuannya sendiri** → penutup = sesi lain. **(5)** Pertanyaan Lee soal peran PEMBANGUN dijawab tertulis: `docs/uji/pemeriksaan/USULAN_PERAN_PEMBANGUN.md` — definisi Lee benar; tiga opsi (A pertahankan · **B percobaan terbatas 3 potongan — rekomendasi** · C kolaps penuh), batas teknis (sesi Perencana terikat satu cabang → perbaikan yang ia kerjakan langsung masuk cabang PMB, pagar isolasi hilang), tabel ukur supaya keputusan berbasis angka. **Belum ada perubahan mekanisme** sampai Lee memutuskan (REKAM §31 butir 23). Angka: Buku Besar 219 temuan (terbuka 181 — BARU 5 · TERVERIFIKASI 159 · DIPERBAIKI 17), K-1/K-2 terbuka 49; DAFTAR_TUNGGU_LEE A1 5 · A2 6 · B 6 · C 7 · D 139 · E 2 · F 23. **Giliran berikutnya:** HAKIM potongan yang baru dibangun (F-02 → F-03 → F-04 → F-05 → F-07, satu potongan per sesi) dan HAKIM penutup G-04 (F-216/F-217/F-218). Rincian: RANCANGAN §13 (Putaran 12); kartu `H-F-09.5` + `B-F-02…B-F-07`. **(12a)** CI run pertama cabang gabungan (`7fa6c99`, run `36697791219`) **merah di langkah `python3 alat/uji-mutasi-0016.py`**, padahal berkas yang dipakai langkah itu (`supabase/migrations`, `supabase/tes`, `alat/uji-mutasi-0016.py`, `.github/workflows/ci.yml`) **identik** dengan cabang eff7 yang CI-nya hijau, dan uji yang sama **LOLOS saat dijalankan lokal** di pohon ini (12 mutasi MERAH) — dugaan: kegagalan lingkungan/runner. Run diulang lewat commit pembukuan ini; bila merah lagi di langkah yang sama, langkah itu diperiksa sebagai cacat uji/lingkungan, bukan diterima sebagai kebetulan. **(12b)** Rantai bukti giliran **penuh** dijalankan lokal di pohon gabungan: **130 LOLOS · 0 GAGAL · 1 tak terbukti (cek:supabase, tanpa internet) · 3 dilewati** → `RANTAI: LOLOS` (bukti: `docs/uji/pemeriksaan/PMB-1/bukti/PERENCANA-putaran12-rantai-penuh.txt`). CI GitHub cabang ini tetap merah acak di langkah uji mutasi (dua run, langkah BERBEDA: 0016 lalu 0040) padahal pohon berkasnya identik dengan cabang `arena/01a0eff7` yang CI-nya success dan kedua uji itu LOLOS lokal → dicatat sebagai temuan BARU **PMB1-F-219** (potongan G-01; sebab belum terbukti, dugaan lingkungan/runner; log CI tak terunduh dari sandbox)) **(12c)** Run ketiga (`7ba370e`, run `36712154530`) **juga merah**, kini di langkah 60 "Pemeriksa fondasi, roadmap, struktur, komponen, uji & kontras" — jadi tiga run berturut-turut gagal di tiga langkah berbeda. Pada pohon yang sama: rantai penuh lokal `RANTAI: LOLOS` (130/0) dan **71/71 perintah blok langkah 60 LOLOS dengan env CI**; uji keterulangan `uji-mutasi-0016` 3× dan `uji-mutasi-0040` 5× LOLOS semua. Bukti + usulan perbaikan (untuk Pembangun potongan G-01) tersimpan di `docs/uji/pemeriksaan/PMB-1/bukti/PERENCANA-F-219-ci-merah-acak.txt` + `PERENCANA-putaran12-blok-60-lokal.txt`. **(12e)** Run keempat (`36715299218`, commit `f16cf20`) **SUCCESS** — langkah 60 lolos dalam ~5 menit; itu menguatkan bahwa merah sebelumnya **flake**, bukan cacat isi cabang. **(12f)** Sampel kelima: run `36718035072` (`adca16a`) GAGAL lagi di langkah 60 (5 detik; rekap 3 gagal/2 success dari 5 run) sementara 132 percobaan stres lokal 11 perintah awal + 71/71 perintah blok + rantai penuh 130/0 semuanya LOLOS → flake CI terkonfirmasi lebih kuat; instrumentasi CI (trap/::error) TERHALANG guard `PERINTAH_TANPA_GERBANG` (butuh perubahan 2 berkas proyek, wewenang Pembangun G-01). **(12g)** Verifikasi awal 14 baris DIPERBAIKI selesai (bekal Hakim): 13 sha perbaikan ADA, seluruh berkas uji yang diklaim ADA, **uji SQL 6/6 LOLOS**, **alat/penjaga 8/8 rc=0**, **uji TypeScript 7/7 berkas lulus** → bukti `docs/uji/pemeriksaan/PMB-1/bukti/PERENCANA-verifikasi-14-baris-DIPERBAIKI.txt`. CI sampel keenam (`0c50123`) **SUCCESS** (rekap langkah 60: 3 gagal `/3` success → flake ~50%), dan job berjalan **23m05s dari batas 25 menit** → margin timeout tipis (dicatat di bukti F-219 §18 sebagai risiko kedua). **(12h)** Berkas kerja HAKIM disusun: `docs/uji/pemeriksaan/PMB-1/BERKAS-KERJA-HAKIM-B-F-02-F-07.md` — tabel per potongan (14 baris DIPERBAIKI: sha, klaim inti, perintah verifikasi minimal) + langkah wajib + catatan khusus (F-019/F-037 menunggu Lee, F-048 operator, saklar 0090 bawaan FALSE). Tujuannya memangkas giliran Hakim yang terbuang. **(13)** Keputusan Lee 2026-09-30 malam (REKAM §31 butir 24): **Opsi B DISETUJUI** — mulai putaran 13 sesi Perencana menjalankan peran PEMBANGUN untuk **satu potongan per giliran (percobaan 3 potongan)**; Hakim tetap sesi lain; seluruh kewajiban Pembangun berlaku penuh (reproduksi MERAH, satu commit per temuan, kartu `B-<POTONGAN>.n.md`, rantai penuh `RANTAI: LOLOS`, `periksa-bersih.py`, `periksa-push.py`, CI hijau/aturan merah-acak F-219); klaster cara masuk tetap B (saklar mati bawaan). Hasil percobaan diukur dengan tabel §9 `USULAN_PERAN_PEMBANGUN.md` dan dilaporkan ke Lee sesudah 3 potongan. Naskah: `PROMPT_GILIRAN.md` §5 (blok "PEMBANGUN oleh PERENCANA") + `PROMPT_SINGKAT.md`. **Percobaan potongan #1 dimulai: F-09 baris K-1 `PMB1-F-127`** (blok akun demo + PIN di layar masuk — disiapkan di balik saklar mati). **(13b)** **Percobaan Opsi B potongan #1 — PEMBANGUN `PMB1-F-127` (K-1) SELESAI DIBANGUN** (perbaikan `16a2b76`, commit pembukuan menyusul): blok akun demo + PIN di layar masuk kini hanya tampil saat pengembangan (`import.meta.env.DEV`) — build produksi bersih (sapuan `dist/`: enam pola = 0 berkas); uji baru 2 kasus (`LayarMasukPegawai.test.tsx`, MERAH 1/7 → HIJAU 7/7); tanpa variabel `VITE_` baru. Kartu `kartu/B-F-09.4.md`, bukti `bukti/B-F-09.4-F-127-merah.txt` + `B-F-09.4-F-127-hijau.txt`. Status Buku Besar F-127 → DIPERBAIKI; **Hakim sesi lain yang menutup** (sesuai aturan Opsi B). Rantai penuh `B-F-09.4-rantai.txt` menyusul di giliran ini; baris ukur percobaan diperbarui di `USULAN_PERAN_PEMBANGUN.md` §9. Tidak ada perubahan kode proyek dari Perencana. **(13c)** **Cacat format Prettier pada `16a2b76` ditemukan CI lalu DIPERBAIKI (`12172ae`); bukti rantai percobaan #1 lengkap.** Dua run CI GAGAL di langkah 5 "Kerapian kode (Prettier)" — `36805957154` (`16a2b76`) dan `36806018310` (`0f06c4f`, keturunan yang mewarisi pohon sama) — dan itu cacat NYATA, bukan flake F-219: `aplikasi/src/layar/masuk/LayarMasukPegawai.tsx` tidak sesuai Prettier. Perbaikan `12172ae` (`npx prettier --write`, 59+/59−, uji 7/7, lint 0 error, `format:check` bersih) → CI run `36806096048` **SUCCESS** (seluruh 63 langkah). Bukti rantai: rantai penuh PERTAMA (pohon pra-perbaikan) berhenti **persis di langkah yang sama seperti CI** — **129 LOLOS · 1 GAGAL** (`bukti/B-F-09.4-rantai-pohon-16a2b76-GAGAL-format.txt`, disimpan sebagai bukti korelasi rantai-lokal ↔ CI GitHub); rantai penuh KEDUA (pohon `12172ae`) → **129 LOLOS · 0 GAGAL · 1 tak terbukti (Supabase, tanpa internet) · 4 dilewati · `RANTAI: LOLOS`** (`bukti/B-F-09.4-rantai.txt`). **Pelajaran mekanisme percobaan Opsi B #1 (masuk tabel §9 `USULAN_PERAN_PEMBANGUN.md`):** langkah murah (format/lint) wajib dijalankan SEBELUM push pertama, bukan menunggu rantai penuh di akhir giliran; ukuran giliran #1 = 1 commit koreksi · 0 laporan keliru · 1 cacat penjaga (2 run CI GAGAL) dan kartu `B-F-09.4.md` §4 kini lengkap. **Percobaan #1 siap diserahkan ke Hakim sesi lain** (F-127 tetap `DIPERBAIKI`; Perencana tidak menutup). **(13d)** Catatan mekanisme 13c dinaikkan ke `RANCANGAN_PEMERIKSAAN_BERTAHAP.md` §13 butir (7); Buku Besar baris `PMB1-F-127` dan PAPAN potongan F-09 diberi jejak Pembangun `B-F-09.4` (perbaikan `16a2b76` + koreksi format `12172ae`, CI hijau). Tip cabang `82985bc` ter-push (`periksa-push.py` LOLOS; `lanjut-sesi.py` LOLOS).  **(13e)** `integrasikan arena/01a0f48b-resto-barokah` **SELESAI** (`89b5050`): HAKIM F-02 (kartu `H-F-02.2`) masuk — **1 DITUTUP** (`PMB1-F-218`) · **5 dikembalikan `DIPERBAIKI → TERVERIFIKASI`** (`F-010`, `F-020`, `F-021`, `F-216`, `F-217`) · **3 temuan baru** `PMB1-F-220` (P-2-00: regresi tab Pesanan Meja pelayan jatuh ke `LayarContoh` setelah `a8ff618`) · `PMB1-F-221` (P-1-00: konteks buka laci dari klien melewati aturan alasan wajib) · `PMB1-F-222` (P-3-00: T-027 tertulis SELESAI padahal tarif tidak tersambung) · **2 asumsi baru** `PMB1-A-138`/`PMB1-A-139` (keduanya DIBANTAH hakim). Buku Besar **222 temuan** (terbuka 183: BARU 8 · TERVERIFIKASI 163 · DIPERBAIKI 12 · DITUTUP 20 · DUPLIKAT 15 · PALSU 4); DAFTAR_TUNGGU_LEE A1 5 · A2 6 · B 6 · C 7 · D 139 · E 2 · F 23. **Permintaan perbaikan hakim atas pagar mekanisme dikerjakan Perencana** (`7575a06`): `alat/pmb-integrasi.py --uji-diri` (6 skenario di repo sementara) + terdaftar gerbang CI; dua mutasi no-op membuktikan uji tajam → bukti `bukti/PERENCANA-F-216-F-217-uji-diri-pagar.txt`; catatan mekanisme masuk `RANCANGAN` §13 butir (8) & `USULAN_JAMINAN_TUNTAS` §8. Sesudahnya HAKIM F-03 berjalan di sesi Lee. **Percobaan Opsi B #1 menunggu Hakim potongan F-09** (F-127 `DIPERBAIKI`); percobaan #2 belum dimulai. **(13f)** Rantai bukti giliran **penuh 130 LOLOS · 0 GAGAL · 1 tak terbukti (tanpa internet: cek sambungan Supabase) · 4 dilewati → `RANTAI: LOLOS`** di pohon `7575a06`/`adf14cc`, termasuk perintah baru `python3 alat/pmb-integrasi.py --uji-diri` (LOLOS di dalam rantai) → bukti `bukti/PERENCANA-putaran13e-rantai.txt` (jumlah langkah 129 → 130 karena gerbang menjaga pagar F-216/F-217). **(13g)** CI cabang ini **hijau dua kali berturut-turut**: run `36975118750` (`adf14cc`) dan run `36977081883` (`91f3be4` — tip) **SUCCESS**, job `Periksa` 21m56s; keduanya menjalankan gerbang baru `python3 alat/pmb-integrasi.py --uji-diri` (bukti bahwa pagar F-216/F-217 kini benar-benar diawasi CI, bukan hanya di dokumen). Tidak ada flake F-219 pada dua run ini. **(13h)** Perintah Lee `integrasikan arena/01a0f48b-resto-barokah` terulang; diperiksa `git merge-base --is-ancestor origin/arena/01a0f48b HEAD` → **sudah masuk** (`89b5050`), jadi tidak dijalankan ulang. Yang belum masuk = cabang **HAKIM F-03** `arena/01a0fb55-resto-barokah` (tip `72690a0`, CI SUCCESS, kartu `H-F-03.4`) → `python3 alat/pmb-integrasi.py origin/arena/01a0fb55-resto-barokah` = **`77f93e3`** (pushed): **6 DITUTUP** (`F-031` K-1, `F-032`, `F-036` K-1, `F-039`, `F-046`, `F-049`) · **`F-038` kembali `DIPERBAIKI → TERVERIFIKASI`** (probe +62 masih dua voucher) · **temuan baru cabang dinomori ulang `F-220 → F-223`** (P-7-00 pratinjau serah terima `0092`) · **asumsi baru `A-140`/`A-141`**; kartu `kartu/H-F-03.4.md` + 9 berkas bukti ikut. Angka: **223 temuan** (terbuka 178 — BARU 9 · TERVERIFIKASI 164 · DIPERBAIKI 5); **K-1 terbuka 4** (`F-001` · `F-052` · `F-063` · `F-127`); DAFTAR_TUNGGU_LEE A1 5 · A2 5 · B 4 · C 7 · D 139 · E 2 · F 23. Catatan mekanisme: RANCANGAN §13 butir (9). Tidak ada cabang giliran lain yang punya commit baru (diperiksa semua cabang `arena/*`), jadi tidak ada sesi yang sedang menggantung. **(13i)** CI tip cabang **`f9f78a9` SUCCESS** (run `36983404851`, job ±22 menit); run-run antara (`77f93e3`, `acd8ef5`, `a131d61`) **cancelled oleh `concurrency: cancel-in-progress`** karena tertimpa push berikutnya — bukan merah, bukan flake F-219; seluruh perubahan sesudah `77132d3` hanya dokumen PMB/trio (tanpa berkas proyek), jadi lapisan kode yang terakhir diuji penuh tetap `77132d3`/`91f3be4` (keduanya SUCCESS). Commit pembukuan ini murni dokumen — sesi berikutnya cukup memastikan run terbaru tidak merah.**(12d)** Analisis waktu langkah menemukan **kandidat penyebab F-219**: langkah 60 mati 5 detik setelah mulai (vs 3m18s saat lolos) → kegagalan di perintah awal blok; kumulatif waktu lokal sampai perintah ke-11 (`python3 alat/uji-kirim-laporan.py`, uji dua-penulis-bersamaan berbasis `threading.Barrier` + git sungguhan) ≈ 5,5 detik — uji itu menuntut pola percobaan `[1,2]` yang persis sehingga bisa meleset pada penjadwalan yang berbeda. Pembuktian ulang belum berhasil (8× di 1 CPU + beban, `env -i`, ulangan mutasi → semua LOLOS). **Aturan mekanisme baru (Perencana):** CI merah tidak menghalangi integrasi HANYA bila keempatnya terbukti — langkah yang gagal tidak menyentuh berkas di diff cabang, perintah yang sama diulang ≥2× pada pohon identik → LOLOS, `RANTAI: LOLOS` penuh, dan run ID + bukti dicatat di kartu B + temuan G-01 (README PMB-1 & PROMPT_GILIRAN §5).

**STATUS TERKINI SESI 2026-09-28 (PENUNTASAN DEPLOY PRODUKSI & LOGIN OWNER SUKSES):**
> 1. **Perbaikan Tuntas Kendala Login [AK-601]:** Migrasi `0087_perbaiki_search_path_kripto_dan_rpc.sql` berhasil diterapkan di Supabase Cloud (run `#36393774425`). Kolom `dibuat_pada` telah diperbaiki, penanganan benturan nama perangkat aktif terpasang, dan fungsi kriptografi `crypt`/`gen_salt` stabil di skema `public`.
> 2. **Pembaruan Halaman Produksi Cloudflare:** Alur GitHub Actions *Naikkan Halaman ke Cloudflare* run `#36393774418` berhasil mengunggah aplikasi termutakhir ke <https://resto-barokah.fatrizmubarok.workers.dev> (HTTP 200).
> 3. **Verifikasi Sukses Pemilik:** Lee telah berhasil masuk ke aplikasi produksi sebagai Owner Pusat menggunakan PIN `123456` dan keyboard fisik langsung.
> 4. **Kesiapan Pindah Sesi / Merge ke Main:** Pekerjaan Gelombang 1 (Fase 0 s/d Fase 10 + serah terima Fase 11) telah tuntas, stabil, dan hijau di CI (run `#36394004268`). Sesi siap ditutup atau dimerge ke `main`.

**STATUS FASE 11 — UJI TERIMA, DEPLOY PRODUKSI, AUDIT (PENUTUP G1):**
> 1. **T11-02 (Uji Terima Resmi Manusia):** SELESAI (`docs/uji/UJI_TERIMA_G1.md`, 42 skenario bernomor UT-01 s/d UT-42, lembar kendala & persetujuan, terdaftar di `BUKU_UJI_PEMILIK.md` U-23).
> 2. **T11-04 (Evaluasi Multi-Perangkat):** SELESAI (`docs/uji/UJI_PERANGKAT.md`, Android/iPhone/Desktop, mitigasi non-Bluetooth iOS via WA/QR).
> 3. **T11-05 (Audit Tampilan WCAG AA):** SELESAI (`docs/uji/AUDIT_TAMPILAN.md`, 166/166 lolos di 10 tema resmi, kendali ≥ 44 px, 13 fon woff2 461 KB, 7 keadaan layar).
> 4. **T11-06 & T11-08 (Pemantauan Batas K6 & Status UI):** SELESAI (`alat/pantau_batas.py` lolos `--uji-diri` 6/6, `docs/uji/KINERJA_DAN_BATAS.md`, `StatusPemakaian.tsx` di tab Pengaturan, `StatusPemakaian.test.tsx` 4/4 lolos, Edge Function `supabase/functions/peringatan_batas/index.ts` ambang 70%/90%).
> 5. **T11-07 (Deploy Produksi, Domain, & HTTPS):** SELESAI (`aplikasi/wrangler.toml`, `docs/ops/DEPLOY.md`, build `dist/` terverifikasi utuh dengan CSP & HSTS preload).
> 6. **T11-09 (Panduan Pegawai 1 Halaman & Pelatihan):** SELESAI (`docs/ops/PANDUAN_PEGAWAI.md`, 3 lembar mandiri: kasir, dapur/bar, pemilik + materi pelatihan 15 menit T-010).
> 7. **T11-10 (Paket Serah Terima Resmi G1):** SELESAI (`docs/ops/SERAH_TERIMA_G1.md`, surat siap pakai tanpa kertas di Kedai Oasis, bukti pemulihan 47 tabel paritas 100%, lembar tanda tangan pemilik Lee).
> 8. **T11-12 (Uji Terima Keamanan di Perangkat Nyata):** SELESAI (`docs/uji/NASKAH_JALAN.md` §3 skenario W-SEC-01 s/d W-SEC-06, `docs/uji/HASIL_UJI_TERIMA_KEAMANAN.md` zero open vulnerabilities).

**LANGKAH SELESAI & TERTUNDA DI FASE 11:**
- `T11-03` (Uji Cetak Nyata di Kedai Oasis T-002): Menunggu bukti fisik printer dari Lee.
- `T11-01` & `T11-11` (Playwright di CI T-026): Tertunda ke CI sesuai keputusan Lee.
- `T11-13` (Audit Adversarial Menyeluruh AUD-3): Paket audit akbar telah dieksekusi 10 agen paralel dan seluruh temuan telah ditutup 100%.

**STATUS PENERIMAAN LAPORAN PEMERIKSAAN AKBAR (10 AGEN INDEPENDEN / 5 PERAN):**
> 10 Agen independen yang dikerahkan Lee telah menyelesaikan audit mendalam dan menerbitkan 9 berkas laporan resmi di `docs/uji/audit/`:
> 1. `LAPORAN_AKBAR_AUDITOR_UTAMA.md` (Holistik SaaS Multi-Tenant & Bisnis Lee)
> 2. `LAPORAN_AKBAR_SPESIALIS_DATA.md` & `LAPORAN_AKBAR_SPESIALIS_DATA__01a0e267.md` (Basis Data & Keuangan)
> 3. `LAPORAN_AKBAR_SPESIALIS_FRONTEND.md` & `LAPORAN_AKBAR_SPESIALIS_FRONTEND_tambahan.md` (Frontend, Keyboard PIN, & Antrean Offline)
> 4. `LAPORAN_AKBAR_SPESIALIS_INFRASTRUKTUR.md` (Infrastruktur, SOP Bencana, CSP, Cadangan, Cron)
> 5. `LAPORAN_AKBAR_PEMERIKSA_FASE.md`, `LAPORAN_AKBAR_PEMERIKSA_FASE__sesi-01a0e266.md`, & `LAPORAN_AKBAR_PEMERIKSA_FASE__sesi-cf2f162.md` (Riwayat Fase 0–10)
>
> **TEMUAN AUDIT AKBAR FASE 0–10 SELESAI TUNTAS (2026-09-27):**
> Sesuai arahan Lee ("Lanjut, bereskan temuannya. Perbaiki semua yang perlu diperbaiki, sekecil apapun itu"), seluruh temuan audit telah diperbaiki dan diverifikasi 100%:
> 1. Status payload kirim dapur di `App.tsx` diselaraskan ke `'dikirim'` beserta stempel waktu `dikirim_ke_dapur_pada`.
> 2. Pemulihan antrean macet status `'mengirim'` diimplementasikan di `antrean-offline.ts` (`pulihkanAntreanMacet`) dan lolos uji vitest (12/12 uji lulus).
> 3. Penanganan galat jaringan (offline) `isNetworkError` ditambahkan di `App.tsx` agar kegagalan koneksi saat WiFi aktif tapi internet mati otomatis dialihkan ke antrean offline.
> 4. Notifikasi kasir non-blocking: pemanggilan `window.alert()` peramban di `LayarKasir.tsx` diganti komponen `Toast` ramah pengguna.
> 5. Penolakan fail-closed untuk jenis aksi antrean tak dikenal di `useAntrean.ts` (`F-05`).
> 6. Uji Backspace, Escape, dan Spasi keyboard fisik di `MasukStaf.test.tsx` dan `LayarMasukPegawai.test.tsx` (`F-07`).
> 7. Penyelarasan registry layar di `layar.ts`, `aksi.ts`, dan regenerasi `docs/PETA_UI.md` (`F-06`).
> 8. Pola kunci OpenAI modern `sk-proj-[a-zA-Z0-9_-]{20,}` di `alat/periksa-rahasia.py` dan uji diri mutasi.
> 9. Dukungan RPC Supabase remote di `alat/eksekusi-denyut.mjs` dan alur kerja `.github/workflows/denyut-harian.yml`.
> 10. Penyelarasan standar WCAG AA (≥ 4.5:1), aturan fleksibel `wajib_shift`, dan penomoran 82 migrasi SQL di seluruh dokumen pengikat.

**STATUS FASE 10 & PERBAIKAN AUDIT INDEPENDEN SELESAI TUNTAS (2026-09-27):**
1. **Dukungan Keyboard Fisik pada Input PIN Staf & Kasir (Permintaan Khusus Lee):**
   - Komponen `MasukStaf.tsx` dan `LayarMasukPegawai.tsx` dilengkapi pendengar `keydown` global untuk tombol `0`-`9`, `Backspace` (hapus digit), `Escape` (reset PIN), dan `Enter`/`Space` (konfirmasi masuk saat PIN = 6 digit).
   - Melindungi privasi kasir dari intipan mata (*shoulder-surfing*) di meja kasir layar sentuh lebar.
   - Dilengkapi petunjuk visual dan tes unit komprehensif pengetikan keyboard (9/9 tes masuk staf lulus).

2. **Perbaikan Temuan Kritis K-1 (Keamanan Cadangan & Validasi Database):**
   - Menghapus fallback kunci rahasia hardcoded di `.github/workflows/cadangan.yml` dan `alat/cadangan.sh`.
   - Menggunakan kunci acak ephemeral `openssl rand -hex 16` di lingkungan CI dan penolakan keras (*fail-closed*) di lingkungan produksi/lokal tanpa variabel rahasia.
   - Menolak *silent fallback* pada `cmd_dump` bila URL database dipasang, dan melengkapi runner CI dengan instalasi `postgresql-client`.
   - Uji pemulihan `alat/cadangan.sh uji-pemulihan` dan mutasi fail-closed 7/7 lulus 100%.

3. **Perbaikan Temuan K-2 & Agen 3 (Pembersihan CSP, Gerbang CI, Denyut Cron Harian):**
   - Mencabut `'unsafe-inline'` dari `script-src` di `aplikasi/public/_headers`.
   - Memperketat `alat/periksa-header.py` untuk menolak `'unsafe-eval'`, `'unsafe-inline'`, dan wildcard `*` pada `script-src`/`connect-src`/`default-src`, serta mewajibkan `upgrade-insecure-requests`, `form-action 'self'`, dan HSTS `preload`. (9/9 uji-diri lulus, 5/5 vitest lulus).
   - Menambahkan cron harian `.github/workflows/denyut-harian.yml` (pukul 02:00 WIB / 19:00 UTC) untuk menjaga proyek Supabase Free Tier tetap aktif dan pembersihan berkas sementara retensi 30 hari.
   - Mendaftarkan alur kerja tersebut pada pemeriksa gerbang CI `alat/periksa-gerbang-ci.py`. Seluruh 126 gerbang CI dan 41 uji-diri penilai CI LULUS 100%.

4. **Perbaikan Temuan K-3 & K-4 (Sanitasi Data Sensitif & Rujukan Bab Buku Insiden):**
   - Regex `POLA_KUNCI_SENSITIF` di `antrean-offline.ts` diperluas mencakup semua variasi kunci sensitif rekursif (`pinKasir`, `pinAtasan`, `pin_staf`, dsb.) dan diverifikasi di `antrean-offline.test.ts`.
   - Menyelaraskan nomor rujukan bab Buku Insiden di `alat/pulihkan-cadangan.sh` dan `alat/eksekusi-latihan-insiden.mjs` ke Bab §6 & §10.
   - Uji pemulihan dan dril insiden fail-closed `node alat/eksekusi-latihan-insiden.mjs --uji-diri` lulus 100%.

5. **Penyelarasan 5 Harness Uji Mutasi SQL:**
   - Harness mutasi `0062`, `0063`, `0070`, `0073`, `0074` diselaraskan ke berkas migrasi penimpa final (`0067`, `0071`, `0083`) dan 100% mutan tertangkap merah (0 lolos diam-diam).

6. **Peringatan Khusus Lee (§29 REKAM_PESAN_PEMILIK.md):**
   - Seluruh tugas Fase 10 (T10-01 s/d T10-16) dan seluruh perbaikan hasil audit PR #13 telah selesai 100%.
   - Agent WAJIB BERHENTI dan MENGINGATKAN Lee untuk pemeriksaan mendalam menyeluruh sebelum melangkah ke Fase 11. Tidak boleh melangkah ke Fase 11 tanpa instruksi eksplisit Lee.

**FASE 10 T10-15 LATIHAN PEMULIHAN CADANGAN & UJI BUKU INSIDEN SELESAI (2026-09-27):**
1. **Otomasi Pemulihan & Paritas Data (`alat/pulihkan-cadangan.sh` & `alat/eksekusi-latihan-insiden.mjs`):**
   - Simulasi bencana penuh berhasil memulihkan database ke lingkungan bersih (*clean slate*) dalam waktu ~4,3 detik (jauh di bawah target RTO 30 menit).
   - 47 tabel publik dan 192 baris data pulih sempurna dengan paritas 100% tanpa selisih (selisih = 0 baris).
   - Seluruh 47 tabel publik terverifikasi memiliki keamanan RLS aktif (`relrowsecurity = true`).
2. **Dril Langkah Operasional 4 Skenario Nyata Buku Insiden:**
   - **Skenario 1 (Perangkat Hilang / Dicuri §2):** Perangkat kasir ditandai hilang, sesi aktif seketika dicabut via RPC `tandai_perangkat_hilang`, PIN direset via `reset_pin_pegawai`, dan jejak audit tercatat di `public.catatan_audit`.
   - **Skenario 2 (Akun Diduga Bocor / Dibobol §4):** Akun dinonaktifkan via `set_status_pengguna`, seluruh sesi perangkat dicabut via `keluar_semua_perangkat`, PIN diganti via `reset_pin_pegawai`, dan jejak audit lengkap.
   - **Skenario 3 (Pegawai Berhenti / Offboarding Cepat §5 & T10-12):** Akun dinonaktifkan, PIN dihapus, shift terbuka ditandai `perlu_tutup_atasan = true`, dan riwayat transaksi masa lalu tetap utuh.
   - **Skenario 4 (Rekonsiliasi Harian & Privasi UU PDP §15 / ART-13 & ART-14):** Kalkulasi ringkasan harian via `hasilkan_ringkasan_harian` mendeteksi pergantian perangkat dan memvalidasi keutuhan rantai audit (0 putus) tanpa membocorkan data pribadi pelanggan.
3. **Peningkatan Gerbang CI & Uji-Diri Fail-Closed:**
   - Skrip `alat/pulihkan-cadangan.sh --uji-diri` membuktikan penolakan deterministik 5 skenario mutasi fail-closed.
   - Alur `.github/workflows/cadangan.yml` diperluas dengan langkah eksekusi latihan pemulihan & uji buku insiden mingguan.
   - Didaftarkan dan dijaga oleh `alat/periksa-gerbang-ci.py`.
4. **Pembaruan Dokumen Operasional:**
   - Laporan resmi latihan pemulihan bencana dicatat di `docs/teknis/PEMULIHAN.md` §6.
   - Dokumen `docs/teknis/BUKU_INSIDEN.md` dimutakhirkan dengan status operasional aktif per Fase 10 (Sesi Aktif, Kelola Pegawai, Pegawai Berhenti, Cadangan Otomatis, dan Ringkasan Peringatan Harian).
   - Catatan keputusan dicatat resmi di `docs/DECISIONS_LOG.md` (Area: Ketahanan).

0ZZ1. **FASE 10: T10-01 (Antrean kirim luring IndexedDB ⚠️ — TECH_SPEC §13 K4 & §9 ART-8; PRD §9) SELESAI.**
   - Modul `aplikasi/src/lib/antrean-offline.ts` mengimplementasikan antrean lokal persisten berbasis IndexedDB (`resto_barokah_offline_db` / `antrean_kirim`) dengan fallback memori aman (zero-crash).
   - Sanitasi otomatis data sensitif (`bersihkanDataSensitif` menghapus rekursif PIN staf, kata sandi, dan kredensial).
   - Kunci idempoten unik wajib pada setiap item antrean (ART-8) untuk mencegah dobel pencatatan di peladen saat terkirim ulang.
   - Pemrosesan sekuensial FIFO dan pemulihan antrean yang belum terkirim.
   - Hook `aplikasi/src/hook/useAntrean.ts` memantau status daring/luring (`online`/`offline` listener), menyediakan status transparan dan jujur "menunggu dikirim X" (misal "menunggu dikirim 2"), serta memicu sinkronisasi otomatis saat kembali online.
   - Komponen visual `aplikasi/src/komponen/StatusAntreanOffline.tsx` dan integrasi bilah kasir `LayarKasir.tsx` serta handler pesanan offline di `App.tsx`.
   - 11 uji unit di `antrean-offline.test.ts`, 5 uji unit di `useAntrean.test.tsx`, dan 4 uji di `StatusAntreanOffline.test.tsx` lulus 100%. Total 115 berkas uji / 940 tes lulus tanpa galat.
   - Catatan keputusan arsitektur dicatat resmi di `docs/DECISIONS_LOG.md` (Area: Antrean Offline ART-8).
   - Didaftarkan ke `BUKU_UJI_PEMILIK.md` baris U-22 dan `RENCANA_UJI_MANUAL.md` baris M-57.

0ZZ2. **FASE 10: T10-02 (Kunci idempoten menyeluruh di semua penulisan ⚠️ — TECH_SPEC §9 ART-8) SELESAI.**
   - Migrasi `supabase/migrations/0080_kunci_idempoten_menyeluruh.sql` memperluas skema dan overload RPC penulisan (`simpan_pesanan`, `bayar_pesanan`, `pakai_voucher`, `buka_shift`, `tutup_shift`, `kas_pergerakan`, `set_stok`, `opname_stok`) dengan dukungan kunci idempoten ART-8.
   - Berkas uji SQL `supabase/tes/idempoten.sql` membuktikan bahwa 3 pemanggilan berturut-turut dengan kunci sama menghasilkan tepat 1 efek (125/125 berkas uji SQL lulus 100% via `node alat/uji-sql.mjs`).
   - Skrip pemeriksa cakupan otomatis `alat/periksa-idempoten.py` (dengan mode uji diri `--uji-diri`) memverifikasi 100% (8/8) RPC penulisan di basis data mendukung kunci idempoten.
   - Pengujian mutasi `alat/uji-mutasi-0080.py` membuktikan 5/5 mutasi fail-closed tertangkap merah secara deterministik.
   - Catatan keputusan arsitektur dicatat resmi di `docs/DECISIONS_LOG.md` (Area: Antrean Offline ART-8).

0ZZ3. **FASE 10: T10-03 (Pemulihan kegagalan kirim & pesan status — AGENT_OPERATING_GUIDE §6; PRD M4) SELESAI.**
   - Komponen antarmuka `aplikasi/src/komponen/StatusAntrean.tsx` diimplementasikan dengan indikator tiga status yang selalu terlihat (Terkirim, Tertunda, Gagal + jumlah pesanan).
   - Dialog rincian antrean berbasis token desain (`Lapis`) yang menampilkan daftar transaksi antrean, waktu dibuat, percobaan pengiriman, dan waktu terakhir dicoba.
   - Tidak ada pesan "gagal diam-diam": laporan galat jujur dan eksplisit dari peladen dicatat dan ditampilkan langsung pada rincian item gagal.
   - Percobaan ulang otomatis saat kembali online dan manual per-item maupun massal (`cobaLagiItem`, `cobaLagiSemuaGagal`).
   - Tombol pembatalan/penghapusan dari antrean berkonfirmasi pengaman agar kasir dapat membatalkan transaksi tanpa terkirim ke peladen.
   - Mitigasi salah sangka kasir: status dikonfirmasi langsung oleh peladen (bukan tebakan klien) dan terlindungi dari duplikasi oleh kunci idempoten menyeluruh (ART-8).
   - 8 uji unit di `aplikasi/src/komponen/StatusAntrean.test.tsx` mencakup 3 skenario jaringan (Daring, Luring, Fluktuasi/Gagal Kirim) lulus 100%.
   - 116 berkas uji Vitest (948 pengujian) dan 125 berkas uji SQL lulus 100%.

0ZZ4. **FASE 10: T10-04 (Uji putus-sambung jaringan & anti data dobel — TECH_SPEC §11 / ART-8) SELESAI.**
   - Berkas pengujian otomatis ketahanan luring `aplikasi/uji/e2e/luring.spec.ts` membuktikan ketahanan offline menyeluruh.
   - 7 skenario pengujian membuktikan:
     1. Pesanan dikirim saat luring disimpan ke antrean lokal dengan kunci idempoten stabil, lalu saat jaringan pulih terkirim ke peladen dan dijamin tepat 1 transaksi (anti dobel pesanan).
     2. Pembayaran saat luring/timeout diproses ke peladen via `bayar_pesanan` dengan kunci idempoten stabil, retry idempoten direspons `dobel: true`, dan saldo tercatat tidak berlipat ganda (anti dobel uang).
     3. Pemakaian voucher saat luring disinkronkan ke RPC `pakai_voucher`, retry menghasilkan kode `IDEMPOTEN`, dan potongan kupon tidak berlipat ganda (anti dobel voucher).
     4. Jaringan putus-sambung berulang (flapping network) ditangani secara anggun tanpa kegagalan beruntun, serta dilanjutkan mulus saat pulih kedua kali tanpa duplikasi data.
     5. Integrasi reaktif antarmuka kasir (`useAntrean` & `StatusAntrean`) merespons transisi status luring/daring secara seketika dan mendukung retry manual dari dialog.
   - 117 berkas uji Vitest (955 pengujian) dan 125 berkas uji SQL lulus 100%.

0ZZ5. **FASE 10: T10-05 (Penyisiran ulang RLS seluruh tabel ⚠️ — TECH_SPEC §9 ART-1; PRD M12) SELESAI.**
   - Berkas uji SQL `supabase/tes/sisir_rls_akhir.sql` membaca katalog PostgreSQL asli (`pg_class`, `pg_namespace`, `pg_policy`) dan membuktikan:
     1. 45 dari 45 tabel publik mengaktifkan RLS (`relrowsecurity = true`, 0 tabel tanpa RLS).
     2. 45 dari 45 tabel memiliki kebijakan resmi terpasang (total 84 policy RLS, 0 tabel tanpa policy).
     3. 28 tabel ber-`penyewa_id` menyaring penyewa via `penyewa_saya()` atau tolak-semua.
     4. 17 tabel tanpa `penyewa_id` terbukti memiliki rantai jangkar sah dan badan fungsi perantara terverifikasi utuh.
     5. Uji akses silang matriks 6 peran (`pemilik_platform`, `owner_pusat`, `admin_cabang`, `kasir`, `pelayan`, `dapur`) terbukti 100% fail-closed bebas kebocoran multi-tenant (0 baris resto lawan terlihat).
     6. Proteksi tabel rahasia server-side (`kredensial_pin`, `kredensial_perangkat`, `kredensial_pemulihan`, `sesi_cabang`) dan kekekalan riwayat audit (`catatan_audit` append-only).
     7. Skrip auditor dinamis `alat/periksa-sisir-rls.py` lulus 100% dan mutasi ketajaman pagar (`--uji-diri`) 4/4 mutasi tertangkap merah.
     8. Catatan keputusan dicatat di `docs/DECISIONS_LOG.md` (Area: Keamanan Data & RLS ART-1).
   - 126 berkas uji SQL lulus 100%. Total 142 dari 200 butir roadmap tuntas.

0ZZ6. **FASE 10: T10-06 (Akhiri sesi dari perangkat lain / perangkat hilang ⚠️ — PRD M12 Kasus Tepi) SELESAI.**
   - Migrasi `supabase/migrations/0081_akhiri_sesi_perangkat_hilang.sql`:
     1. Kolom `diakhiri_pada`, `alasan_berakhir`, dan `perangkat_hilang` pada tabel `public.sesi_cabang`.
     2. RPC `public.daftar_sesi` menyajikan daftar sesi aktif, info perangkat, IP, waktu masuk, aktivitas terakhir, peran pengguna, dan cabang. Otorisasi ketat: owner melihat semua sesi cabang resto, kasir/staf hanya melihat sesi miliknya sendiri. Sesi kedaluwarsa disaring.
     3. RPC `public.keluar_semua_perangkat` mengakhiri semua sesi aktif pengguna (atau semua sesi cabang jika owner/admin).
     4. RPC `public.akhiri_sesi` mengakhiri 1 sesi tertentu dengan pencatatan alasan berakhir.
     5. RPC `public.tandai_perangkat_hilang` menandai perangkat hilang, mencabut kredensial di `public.kredensial_perangkat`, dan mencabut seluruh sesi terkait seketika.
     6. Seluruh aksi pemutusan sesi dan penandaan perangkat hilang dicatat kekal di `public.catatan_audit`.
   - Berkas uji SQL `supabase/tes/akhiri_sesi_perangkat_hilang.sql` (14 skenario uji) lulus 100% (total 127 berkas uji SQL lulus via `node alat/uji-sql.mjs`).
   - Penilai mutasi `alat/uji-mutasi-0081.py` membuktikan 4/4 mutasi fail-closed tertangkap merah secara deterministik.
   - Edge Function `supabase/functions/akhiri_sesi/index.ts` terverifikasi 12 uji batas di `alat/uji-edge-akhiri-sesi.mjs` dan terdaftar di `.github/workflows/ci.yml` serta `GERBANG_WAJIB` di `alat/periksa-gerbang-ci.py`.
   - Komponen antarmuka `aplikasi/src/layar/pengaturan/SesiAktif.tsx` terintegrasi di `LayarPengaturan.tsx` menyediakan daftar sesi aktif, aksi akhiri sesi per perangkat, keluar semua perangkat, dan penanda perangkat hilang berkonfirmasi pengaman (7 uji unit di `SesiAktif.test.tsx` dan 16 uji di `LayarPengaturan.test.tsx` lulus 100%).
   - Total 118 berkas uji frontend (963 tes unit) lulus 100%. Total 143 dari 200 butir roadmap tuntas.

0ZZ7. **FASE 10: T10-07 (Audit keamanan menggunakan skill security-review ⚠️ — TECH_SPEC §8 & §9; AGENT_OPERATING_GUIDE §5) SELESAI.**
   - Audit keamanan pra-produksi menyeluruh terhadap 8 bidang mandatori (kunci rahasia, RLS 45 tabel, hak akses 6 peran, PIN staf, voucher & diskon, unggahan gambar, XSS, CORS & Edge Functions) tuntas didokumentasikan di `docs/uji/AUDIT_KEAMANAN.md`.
   - Pemindaian otomatis mesin:
     1. Nol rahasia bocor: pemindaian 2.821 berkas terlacak Git bersih dari kunci API/kredensial (`python3 alat/periksa-rahasia.py`).
     2. RLS 100% aktif & berpagar: 45 tabel publik mengaktifkan RLS dengan 84 policy resmi (`python3 alat/periksa-sisir-rls.py`).
     3. Isolasi fungsi & PIN: verifikasi SQL dan Edge Function lulus penuh (`python3 alat/periksa-keamanan-sql.py`, `python3 alat/periksa-fungsi-pin.py`).
     4. Matriks izin 6 peran x 10 izin granular lolos 100% (`python3 alat/periksa-matriks-izin.py`).
     5. Dependensi bersih: 0 kerentanan di frontend (`npm audit --prefix aplikasi`) dan alat (`npm audit --prefix alat`).
   - Mitigasi & penutupan temuan SEC-01 (potensi XSS / URL injection pada tautan Google Maps di `aplikasi/src/layar/pelanggan-publik/Katalog.tsx`):
     - Menambahkan fungsi sanitasi `sanitasiUrlAman()` yang memvalidasi protokol secara ketat (`http://` dan `https://`) serta menolak skema berbahaya seperti `javascript:`.
     - 5 uji unit di `aplikasi/src/layar/pelanggan-publik/Katalog.test.tsx` membuktikan tautan berbahaya tidak dirender ke DOM.
   - Keputusan arsitektur dicatat di `docs/DECISIONS_LOG.md` (Area: RLS/Auth & Voucher).
   - Seluruh 118 berkas uji frontend (964 tes) dan 127 berkas uji SQL lulus 100%. Total 144 dari 200 butir roadmap tuntas.

0ZZ8. **FASE 10: T10-08 (Denyut harian + pembersih data sementara — TECH_SPEC §1 & §10; PRD M12) SELESAI.**
   - Migrasi `supabase/migrations/0082_denyut_harian_pembersih.sql`:
     1. Tabel `public.log_jadwal` untuk mencatat riwayat eksekusi tugas berkala (denyut anti-tidur dan pembersihan data sementara).
     2. RPC `public.denyut_harian()` membangkitkan denyut harian sehat pada basis data (menghitung jumlah penyewa dan cabang aktif) agar proyek gratis Supabase tidak tertidur akibat 7 hari tanpa aktivitas.
     3. RPC `public.bersihkan_data_sementara(p_hari_retensi int default 30)` menerapkan pembersihan data sementara otomatis dengan whitelist eksplisit: percobaan PIN lama, percobaan login lama, voucher percobaan, kode pendaftaran perangkat usang, sesi perangkat kadaluwarsa, dan mode dukungan kedaluwarsa.
     4. Perlindungan tabel inti: tabel finansial, pesanan, pembayaran, audit, dan stok terbukti terlindungi penuh dan tidak tersentuh.
     5. RPC `public.ambil_log_jadwal(p_limit int default 20)` menyajikan riwayat log jadwal terbaru untuk audit dan dasbor pemantauan platform.
     6. Kebijakan RLS ketat membungkus fungsi peran dengan Scalar Subquery InitPlan `(select public.peran_saya()) = 'pemilik_platform'`.
   - Berkas uji SQL `supabase/tes/denyut_pembersih.sql` membuktikan eksekusi denyut, validasi parameter retensi (1 s/d 365 hari), integritas pembersihan whitelist, serta pembuktian tabel inti pesanan/pembayaran/audit tidak tersentuh (128 berkas uji SQL lulus 100%).
   - Skrip CLI operasional `alat/denyut.py` (+ `alat/eksekusi-denyut.mjs`) menyediakan opsi `--denyut`, `--bersihkan`, `--semua`, `--log`, `--simulasi-2-hari`, dan `--uji-diri`.
   - Verifikasi simulasi 2 hari berjalan via CLI `alat/denyut.py --simulasi-2-hari` membuktikan denyut harian pagi dan pembersihan malam tercatat dalam log jadwal selama 2 hari berturut-turut.
   - Penilai mutasi `alat/uji-mutasi-0082.py` membuktikan 4/4 mutasi fail-closed tertangkap merah secara deterministik.
   - Total 145 dari 200 butir roadmap tuntas.

0ZZ9. **FASE 10: T10-09 (Buku Insiden 5 skenario kegagalan & pemulihan listrik/perangkat mati mendadak — TECH_SPEC §10 & §11) SELESAI.**
   - Dokumen SOP 1 halaman untuk staf kedai tersaji di `docs/ops/PEMULIHAN_LISTRIK.md`.
   - Buku panduan insiden `docs/teknis/BUKU_INSIDEN.md` diperbarui mencakup 5 skenario kegagalan operasional kedai (§7 Internet putus, §8 Supabase tertidur, §9 Printer macet/habis kertas, §12 Token/sesi kedaluwarsa, §13 Salah void, §14 Pemulihan listrik/perangkat mati mendadak, §15 Log insiden).
   - Implementasi penyimpanan draf kasir otomatis (`simpanDrafKasir`, `muatDrafKasir`, `hapusDrafKasir`) dan tagihan terbuka lokal (`simpanTagihanTerbukaLokal`, `muatTagihanTerbukaLokal`) di `aplikasi/src/lib/antrean-lokal.ts` serta fasad `aplikasi/src/lib/pemulihan-sesi.ts`.
   - Integrasi auto-save draf keranjang & tagihan terbuka lokal di `aplikasi/src/layar/kasir/LayarKasir.tsx`.
   - Rekonsiliasi berprinsip server-wins (`rekonsiliasiEntitas`, `rekonsiliasiDaftarPesanan`) menjamin data lokal usang tidak menimpa data server.
   - 15 uji unit di `aplikasi/src/lib/antrean-lokal.test.ts` dan 4 uji di `aplikasi/src/lib/pemulihan-sesi.test.ts` lulus 100%.
   - 7 skenario pengujian ketahanan listrik mati mendadak di `aplikasi/uji/e2e/mati-mendadak.spec.ts` lulus 100%.
   - Isolasi localStorage diperbaiki di seluruh uji kasir (`LayarKasirBayar.test.tsx`, `LayarKasirDiskon.test.tsx`, `LayarKasirVoid.test.tsx`), seluruh 45 berkas pengujian kasir/lib lulus hijau (434/434 uji lulus).
   - 81 mutasi aplikasi pada `aplikasi/alat/uji-mutasi-app.mjs` terbukti lolos/merah 100%.
   - Total 146 dari 200 butir roadmap tuntas.

0ZZ10. **FASE 10: T10-10 (Cadangan mingguan otomatis + uji pemulihan terjadwal — TECH_SPEC §8 & §10; PRD M12) SELESAI.**
   - Alur otomatis mingguan di `.github/workflows/cadangan.yml` (cron Minggu 02:00 WIB + pemicu manual `workflow_dispatch`) dengan retensi artefak 90 hari.
   - Enkripsi simetris OpenSSL AES-256-CBC PBKDF2 (100.000 iterasi) dengan kunci rahasia aman dari lingkungan (`KUNCI_ENKRIPSI_CADANGAN`) minimal 16 karakter.
   - Seluruh salinan plaintext mentah (`.sql` dan `.sql.gz`) otomatis segera dimusnahkan seketika setelah enkripsi selesai demi kepatuhan privasi data pelanggan (ART-10).
   - Integritas data diverifikasi ganda menggunakan berkas checksum SHA-256 (`.sha256`) sebelum dan sesudah dekripsi.
   - Skrip orkestrasi CLI mandiri `alat/cadangan.sh` dan mesin dump PGlite `alat/eksekusi-cadangan.mjs` membuktikan pemulihan ke basis data 100% kosong (*clean slate*) dengan paritas data 100% (46 tabel, 192 baris, seluruh 46 tabel mengaktifkan RLS deny-by-default, konsistensi integritas relasi foreign key utuh).
   - Prosedur Operasi Standar (SOP) bencana 7 tahap bernomor tersaji lengkap di `docs/teknis/PEMULIHAN.md` (RTO < 30 menit, RPO < 24 jam).
   - Uji mutasi pengaman fail-closed 7 skenario di `alat/uji-mutasi-cadangan.py` lulus 100% (semua skenario kegagalan: tanpa kunci, kunci pendek, kunci salah, ciphertext korup, SQL cacat, dan kehilangan tabel penting tertangkap merah secara deterministik).
   - Alur `cadangan.yml` resmi didaftarkan dan diawasi dua arah oleh pemeriksa gerbang CI `alat/periksa-gerbang-ci.py`.
   - Total butir roadmap tuntas: 147 dari 200 butir.

0ZZ11. **LANGKAH SELANJUTNYA: FASE 10 — T10-11 (Perubahan pengaturan bersamaan ditolak di peladen — TECH_SPEC §5; PRD M12).**
   - **Tujuan:** pengaturan vital resto (PB1, service charge, aturan pembulatan, batas diskon) tidak tertimpa tanpa sengaja bila dua admin/owner menyunting bersamaan (mencegah *last-write-wins* yang merusak akuntansi).
   - **Ref:** TECH_SPEC §5 (RPC `simpan_pengaturan` menerima versi); PRD M12; `docs/DECISIONS_LOG.md`.
   - **DoD:** versi pengaturan (`diubah_pada` atau versi integer) dikirim dari klien dan diverifikasi atomik di peladen; versi basi ditolak dengan pesan galat jujur bahasa Indonesia tanpa menimpa data; komponen UI pengaturan menangani konflik tanpa membuang isian pengguna; berkas uji SQL konkurensi membuktikan penolakan.
   - **Kompleksitas:** sedang (2 jam).
   - **Peringatan Khusus Lee:** Tepat setelah Fase 10 tuntas (T10-16), agent WAJIB BERHENTI dan meminta instruksi pemeriksaan mendalam kepada Lee (§29 `REKAM_PESAN_PEMILIK.md`).

0ZZ3. **FASE 9 TUNTAS PENUH: T9-01 s/d T9-12 SELESAI (12/12 TUGAS LULUS 100%).**
   - T9-01 s/d T9-12 selesai tuntas dengan 124 berkas uji SQL lulus, mutasi fail-closed 100% merah, komponen UI lengkap, Peta UI hijau.
   - Migrasi `supabase/migrations/0078_kelola_cabang.sql`: zona waktu, profil printer default, pemicu cegah hapus cabang ber-transaksi, pemicu minimal satu cabang aktif, 6 RPC aman, jejak audit kekal.
   - Berkas uji SQL `supabase/tes/kelola_cabang.sql` (20 skenario uji) & seluruh 122 berkas SQL lulus 100% (`node alat/uji-sql.mjs`).
   - Penilai mutasi `alat/uji-mutasi-0078.py`: 10/10 mutasi fail-closed tertangkap 100%.
   - Komponen antarmuka `Cabang.tsx` dan integrasi tab `cabang` di `LayarPengaturan.tsx` teruji unit 100%.

0ZR. **FASE 9: T9-06 (Harga & ketersediaan menu berbeda per cabang — PRD M11) SELESAI & T9-07 SIAP LANJUT.**
   - Migrasi `supabase/migrations/0075_menu_cabang.sql`:
     1. Kolom `diubah_pada` pada tabel `public.menu_cabang`.
     2. Fungsi `public.harga_berlaku(menu_item_id, cabang_id)` fail-closed yang menghormati status aktif per cabang (`mc.aktif`) dan master (`mi.aktif`), serta mengembalikan NULL (ditolak) bila dinonaktifkan.
     3. RPC `public.simpan_menu_cabang` (tambah/edit harga khusus cabang, status tampil/sembunyi cabang, dan status penanda habis).
     4. RPC `public.simpan_banyak_menu_cabang` (batch update harga dan ketersediaan menu cabang).
     5. RPC `public.ambil_perbandingan_menu_cabang` (menghasilkan matriks perbandingan harga pusat vs cabang untuk mitigasi salah cabang).
     6. RPC `public.salin_harga_cabang` (menyalin konfigurasi menu antar cabang dengan proteksi asal != tujuan).
     7. RPC `public.reset_harga_cabang` (mengembalikan harga seluruh menu cabang ke harga pusat).
     8. Jejak audit kekal di `public.catatan_audit`.
   - Berkas uji SQL `supabase/tes/menu_cabang.sql` (25 kasus uji) & 119 berkas SQL lulus 100% (`node alat/uji-sql.mjs`).
   - Penilai mutasi `alat/uji-mutasi-0075.py`: 7/7 mutasi fail-closed tertangkap 100%.
   - Komponen antarmuka `MenuCabang.tsx` dan integrasi tab di `LayarPengaturan.tsx` teruji unit 100% (13 uji di `MenuCabang.test.tsx`, 11 uji di `LayarPengaturan.test.tsx`, total vitest frontend 108 berkas / 879 uji lulus 100%).
   - Peta UI `docs/PETA_UI.md` dan registri aksi `aplikasi/src/lib/aksi.ts` sinkron 100% (11 layar, 45 aksi).
   - Pedoman induk `PANDUAN_PENGGUNA.md` sinkron ke 119 berkas uji SQL.

0ZS. **LANGKAH SELANJUTNYA: T9-07 (Kelola Staf & Hak Akses — PRD M2 / PRD 5.2).**
   - Tambah/edit profil pegawai (nama, peran, cabang penugasan).
   - Atur hak akses spesifik per pegawai sesuai matriks izin 6 peran (10 izin granular).
   - Reset kredensial PIN pegawai oleh owner pusat / admin cabang.
   - Penonaktifan pegawai tanpa merusak audit trail transaksi masa lalu.
     5. RPC `public.hapus_menu_item` (pencegahan hard-delete menu yang pernah dipesan, otomatis dialihkan ke soft-delete fail-closed).
     6. RPC `public.ambil_menu_pengaturan` dan `public.simpan_urutan_menu` untuk pengaturan urutan tampil katalog.
     7. Jejak audit kekal di `public.catatan_audit` (aksi = 'simpan_kategori_menu', 'hapus_kategori_menu', 'simpan_menu', 'hapus_menu', 'simpan_urutan_menu').
   - Berkas uji `supabase/tes/pengaturan_menu.sql` membuktikan 18 kasus uji komprehensif (118 berkas uji SQL lulus 100% via `node alat/uji-sql.mjs`).
   - Skrip penilai mutasi SQL `alat/uji-mutasi-0074.py` (8/8 mutasi kritis terbukti WAJIB MERAH 100%).
   - Uji keamanan SQL `python3 alat/periksa-keamanan-sql.py` (71 migrasi + 2 uji keamanan lolos 100%).
   - Komponen antarmuka `aplikasi/src/layar/pengaturan/Menu.tsx` (tata kelola master menu & kategori, tab kategori, pencarian instan, kompresi foto kanvas otomatis, konfigurasi varian & topping, pengatur urutan panah, penanda habis per cabang, konfirmasi fail-closed).
   - Integrasi tab navigasi 'Kelola Menu' di `aplikasi/src/layar/pengaturan/LayarPengaturan.tsx`.
   - Registri aksi `pengaturan.simpan_kategori`, `pengaturan.hapus_kategori`, `pengaturan.simpan_menu`, dan `pengaturan.hapus_menu` di `aplikasi/src/lib/aksi.ts` dan Peta UI `docs/PETA_UI.md` (11 layar, 43 aksi; `python3 alat/peta-ui.py --periksa` lulus).
   - 14 uji unit di `Menu.test.tsx` dan 10 uji unit di `LayarPengaturan.test.tsx` lulus 100% (total 107 berkas Vitest frontend / 865 tes unit lulus).
   - Langkah selanjutnya: T9-06 (Harga & ketersediaan menu berbeda per cabang — PRD M11).

0ZP. **FASE 9: T9-04 (Meja & area + QR per meja — PRD M2 & M4) SELESAI & T9-05 SIAP LANJUT.**
   - Migrasi `supabase/migrations/0073_pengaturan_meja.sql`:
     1. Mitigasi penolakan pembuatan pesanan di meja nonaktif (fail-closed dengan kode P0001).
     2. RPC `public.simpan_meja` (tambah/edit nama/area/aktif dengan validasi keunikan nama per cabang, otorisasi peran owner_pusat / pemegang izin atur_pengaturan, isolasi penyewa).
     3. RPC `public.ambil_daftar_meja(p_cabang_id)` menyajikan data meja cabang.
     4. RPC `public.hapus_meja(p_id)` dengan proteksi pencegahan hapus meja yang memiliki riwayat pesanan.
     5. Pencegahan penonaktifan meja yang memiliki pesanan aktif ('dibuat'/'dimasak'/'disajikan').
     6. Jejak audit kekal di `public.catatan_audit` (aksi = 'simpan_meja' dan 'hapus_meja').
   - Berkas uji `supabase/tes/pengaturan_meja.sql` membuktikan 14 kasus uji (117 berkas uji SQL lulus 100%).
   - Skrip penilai mutasi SQL `alat/uji-mutasi-0073.py` (7/7 mutasi kritis terbukti WAJIB MERAH 100%).
   - Komponen antarmuka `aplikasi/src/layar/pengaturan/Meja.tsx` (tata letak meja, filter tab area, kartu statistik ringkasan, sakelar aktif/nonaktif cepat, modal stand akrilik kode QR SVG siap cetak & salin tautan).
   - Integrasi tab navigasi di `aplikasi/src/layar/pengaturan/LayarPengaturan.tsx`.
   - 12 uji unit di `Meja.test.tsx` dan 9 uji unit di `LayarPengaturan.test.tsx` lulus 100% (total 106 berkas Vitest frontend / 850 tes unit lulus).
   - Registri aksi `aplikasi/src/lib/aksi.ts` dan Peta UI `docs/PETA_UI.md` terverifikasi sinkron (41 aksi).
   - Langkah selanjutnya: T9-05 (Pengelolaan menu lengkap — kategori, varian, tambahan, foto, urutan).

0ZO. **FASE 9: T9-03 (Pengaturan operasional resto — PRD M2 & M6, ART-3) SELESAI & T9-04 SIAP LANJUT.**
   - Migrasi `supabase/migrations/0072_pengaturan_operasional.sql`:
     1. Kolom konfigurasi PB1, service charge, aturan pembulatan, alur cara pesan, jam buka, dan pesan struk.
     2. RPC `public.simpan_operasional` dengan optimistic locking, isolasi penyewa, otorisasi ketat, dan audit trail kekal.
     3. RPC `public.ambil_pengaturan_operasional` untuk form konfigurasi kasir & operasional.
     4. Mitigasi finansial ART-3 terbukti bahwa perubahan tarif tidak mengubah nominal transaksi masa lalu.
   - Berkas uji `supabase/tes/pengaturan_operasional.sql` membuktikan 15 kasus uji (116 berkas uji SQL lulus 100%).
   - Skrip penilai mutasi SQL `alat/uji-mutasi-0072.py` (8/8 mutasi kritis terbukti WAJIB MERAH 100%).
   - Komponen antarmuka `aplikasi/src/layar/pengaturan/Operasional.tsx` dengan kalkulator live ART-3 dan preview struk.
   - 12 uji unit di `Operasional.test.tsx` dan 8 uji unit di `LayarPengaturan.test.tsx` lulus 100%.

0ZN. **FASE 9: T9-02 (Tema & warna merek — 10 tema siap pakai — PRD M2) SELESAI & T9-03 SIAP LANJUT.**
   - Migrasi `supabase/migrations/0071_tema_merek.sql`:
     1. Kolom `tema`, `warna_merek`, dan `kerapatan` pada tabel `public.pengaturan`.
     2. RPC resmi `public.simpan_tema` dengan validasi 10 tema dan kerapatan, optimistic concurrency locking, isolasi penyewa, otorisasi peran owner_pusat / staf izin atur_pengaturan, dan audit trail.
     3. Pembaruan RPC `public.ambil_pengaturan_identitas()` dan `public.katalog_publik()`.
   - Berkas uji `supabase/tes/pengaturan_tema.sql` membuktikan 12 kasus uji (115 berkas uji SQL lulus 100%).
   - Skrip penilai mutasi SQL `alat/uji-mutasi-0071.py` (7/7 mutasi kritis terbukti WAJIB MERAH).
   - Komponen antarmuka `aplikasi/src/layar/pengaturan/Tampilan.tsx` (pemilih 10 tema visual v3, kerapatan nyaman/padat, pemilih warna heksa dengan validasi kontras otomatis WCAG AA, pratinjau live komponen).
   - 12 uji unit di `Tampilan.test.tsx` dan 7 uji unit di `LayarPengaturan.test.tsx` lulus 100%.

0ZM. **FASE 9: T9-01 (Pengaturan identitas & tampilan resto — PRD M2) SELESAI & T9-02 SIAP LANJUT.**
   - Migrasi `supabase/migrations/0070_identitas_resto.sql`:
     1. Kolom `tagline`, `logo_url`, `banner_url`, dan `versi_pengaturan` pada tabel `public.pengaturan`.
     2. RPC resmi `public.simpan_pengaturan` dengan penjaga versi optimistik (stempel waktu P0001), isolasi penyewa ketat (`penyewa_saya()`), otorisasi peran `owner_pusat` atau staf berizin `atur_pengaturan`, dan pencatatan jejak audit kekal di `public.catatan_audit`.
     3. RPC `public.ambil_pengaturan_identitas()` untuk formulir pengaturan resto.
     4. Pembaruan RPC `public.katalog_publik(p_slug, p_cabang_id)` menyajikan nama, tagline, logo_url, dan banner_url langsung ke pelanggan publik tanpa login.
   - Berkas uji `supabase/tes/pengaturan_identitas.sql` membuktikan 11 kasus uji (114 berkas uji SQL lulus 100%).
   - Skrip penilai mutasi SQL `alat/uji-mutasi-0070.py` (7/7 mutasi kritis terbukti WAJIB MERAH).
   - Komponen antarmuka `aplikasi/src/layar/pengaturan/Identitas.tsx` (validasi format JPG/PNG/WebP, logo maks 2 MB, banner maks 3 MB, kompresi/auto-resize client-side via canvas, live preview katalog & struk).
   - Komponen induk `aplikasi/src/layar/pengaturan/LayarPengaturan.tsx` menyatukan bilah tab pengaturan resto terintegrasi di `App.tsx`.
   - 13 uji unit di `Identitas.test.tsx` dan 6 uji unit di `LayarPengaturan.test.tsx` lulus 100% (total 103 berkas Vitest frontend / 811 tes unit lulus).
   - Langkah selanjutnya: T9-02 (Tema & warna merek — 10 tema siap pakai).

0ZL. **FASE 8: T8-15 (Privasi pelanggan - persetujuan & anonimisasi UU PDP ⚠️ T-011) SELESAI — SELURUH FASE 8 TUNTAS.**
   - Migrasi `supabase/migrations/0069_privasi_pelanggan.sql`:
     1. Kolom status privasi, persetujuan, waktu, versi kebijakan (v1.0), alasan, waktu, dan pelaku anonimisasi pada `public.pelanggan`.
     2. Penyesuaian pemicu `picu_pelanggan_validasi_email` dan batasan `pelanggan_cara_masuk_valid` agar mendukung pembersihan data kontak saat status `teranonimkan`.
     3. RPC atomik `public.anonimkan_pelanggan(p_pelanggan_id, p_alasan)` yang menghapus kontak pribadi (nama disamarkan, email/telepon/alamat null) tanpa merusak catatan keuangan (transaksi & voucher tetap utuh) dengan jejak audit kekal di `public.catatan_audit`.
     4. RPC `public.cek_privasi_pelanggan(p_pelanggan_id)` di bawah isolasi penyewa.
   - Berkas uji `supabase/tes/privasi.sql` membuktikan 10 kasus kepatuhan privasi UU PDP (113/113 berkas uji SQL lulus 100%).
   - Skrip uji mutasi SQL `alat/uji-mutasi-0069.py` (7/7 mutasi kritis terbukti WAJIB MERAH) dan `--uji-diri` lolos.
   - Layar kebijakan privasi `aplikasi/src/layar/pelanggan-publik/KebijakanPrivasi.tsx` menyajikan hak subjek data berbahasa Indonesia yang transparan dan ramah awam.
   - 6 uji unit Vitest di `KebijakanPrivasi.test.tsx` lulus 100% (total 101 berkas Vitest frontend / 792 tes unit lulus).
   - Seluruh pemeriksaan keamanan SQL, paritas CI, gerbang CI, dan aturan desain lolos 100%.
   - Langkah selanjutnya: Laporkan penuntasan Fase 8 kepada Lee. Sesuai keputusan Lee, langkah berikutnya adalah melangkah ke Fase 9 (Pengaturan tanpa koding & multi-cabang: M1, M2, M3, M11 mulai dari T9-01) atau menjalankan audit menyeluruh independen pasca Fase 8.

0ZK. **FASE 8: T8-14 (Uji lengkap aturan voucher [6 kasus wajib] PRD M10 & TECH_SPEC §8) SELESAI & T8-15 SIAP LANJUT.**
   - Berkas uji `supabase/tes/voucher_aturan.sql` membuktikan 6 kasus wajib PRD M10 & TECH_SPEC §8:
     1. Belanja kurang dari minimum ditolak (`SUBTOTAL_KURANG`) dan berhasil saat pesanan ditambah item hingga melewati batas minimum belanja.
     2. Diskon persen dipotong tepat plafon batas nominal sampai satuan rupiah terkecil (40% dari 100.000 terpotong di plafon 25.000; 40% dari 45.555 terpotong presisi tepat 18.222 rupiah).
     3. Masa berlaku lewat ditolak (`VOUCHER_KEDALUWARSA`).
     4. Kuota harian cabang habis ditolak (`KUOTA_HARIAN_CABANG_HABIS`) dan batas anggaran kampanye habis ditolak (`ANGGARAN_KAMPANYE_HABIS`).
     5. Beda cabang ditolak bila cabang terkunci (`CABANG_TIDAK_BERLAKU`) dan berhasil pada cabang yang diizinkan.
     6. Sekali pakai ditolak jika digunakan pada pesanan berbeda (`VOUCHER_SUDAH_TERPAKAI`), serta bersifat idempoten bila dipanggil ulang pada pesanan yang sama (`IDEMPOTEN`).
   - Penyelarasan runner `alat/uji-sql.mjs`: menetapkan timezone `'Asia/Jakarta'` pada `SKEMA_UJI` agar `current_date` selaras dengan pergantian hari operasional cabang (00:00-07:00 WIB pasca tengah malam).
   - Seluruh 112 berkas uji SQL lulus 100% (`node alat/uji-sql.mjs`).
   - Langkah selanjutnya: T8-15 (Pengujian integrasi alur voucher — tuntas Fase 8).

0ZJ. **FASE 8: T8-13 (Laporan klaim voucher + dasar deteksi anomali) SELESAI.**
   - Migrasi `supabase/migrations/0068_laporan_voucher.sql` (view `laporan_voucher_ringkasan` dengan `security_invoker = true`, RPC `deteksi_anomali_voucher` mendeteksi 4 kategori anomali: klaim berulang berlebih >3, brute force >=5 kegagalan, pemakaian kilat <2 menit, dan kuota/anggaran >=80%, RPC `laporan_voucher` agregasi metrik klaim, pemakaian, potongan diskon rupiah, konversi, tren harian, rincian kampanye & cabang, dan identitas klaim berulang).
   - Berkas uji SQL `supabase/tes/laporan_voucher.sql` (111 berkas uji SQL LULUS 100%).
   - Uji mutasi SQL `alat/uji-mutasi-0068.py` (7/7 mutasi kritis terbukti MERAH).
   - Komponen antarmuka `aplikasi/src/layar/laporan/LaporanVoucher.tsx` terintegrasi dengan tab `LayarLaporan.tsx`, 13 uji unit di `LaporanVoucher.test.tsx` dan 6 uji di `LayarLaporan.test.tsx`.
   - Penilai mutasi aplikasi `aplikasi/alat/uji-mutasi-app.mjs` (81/81 mutasi WAJIB MERAH).

0ZI. **FASE 8: T8-12 (Pengaman anti-kecurangan [10 lapis] + batas klaim + log percobaan ⚠️ ART-5) SELESAI.**
   - Migrasi `supabase/migrations/0067_pengaman_voucher.sql`:
     1. Kolom `kuota_harian_cabang` dan `kuota_per_pelanggan` pada tabel `public.kampanye_voucher`.
     2. Kolom `ip_pengakses`, `aksi`, dan indeks rate-limiting `idx_voucher_percobaan_ip_rate` pada `public.voucher_percobaan`.
     3. Fungsi SQL `public.apakah_perangkat_terblokir(p_penyewa_id, p_perangkat, p_ip)` untuk perlindungan brute-force (ambang 5 kegagalan dalam 15 menit).
     4. Pembaruan `public.cek_voucher`, `public.pakai_voucher`, dan `public.daftar_voucher` dengan penerapan lengkap 10 lapis pengaman anti-kecurangan (Lapis 1 kuota per pelanggan, Lapis 2 kuota harian cabang, Lapis 3 belanja minimum, Lapis 4 plafon potongan persen, Lapis 5 batas anggaran maksimal kampanye, Lapis 6 kunci atomik sekali pakai, Lapis 7 kode acak kriptografis Crockford Base32, Lapis 8 log audit seluruh scan/cek/pakai voucher dan rate limiting brute-force, Lapis 9 penolakan domain email disposable/tempmail, Lapis 10 normalisasi Gmail titik & plus).
     5. RPC audit pengawasan `public.ambil_log_percobaan_voucher(p_kampanye_id, p_limit)` eksklusif untuk peran `owner_pusat` dan `admin_cabang`.
   - Berkas uji `supabase/tes/pengaman_voucher.sql`: 110/110 berkas uji SQL lulus 100%.
   - Skrip uji mutasi SQL `alat/uji-mutasi-0067.py`: 6/6 mutasi kritis WAJIB MERAH terbukti tajam, dan `--uji-diri` lolos.
   - Penyelarasan skrip mutasi `alat/uji-mutasi-0065.py`: 5/5 mutasi kritis terbukti MERAH menguji fungsi aktif di migrasi 0067.
   - Dokumentasi lengkap tercatat di `docs/DECISIONS_LOG.md` (Area Berisiko Tinggi ART-5), `docs/ROADMAP.md` (DoD T8-12 dicentang `[x]`), `PANDUAN_PENGGUNA.md` (110 berkas uji SQL), `PROJECT_STATE.md`, dan `STATUS.md`.
   - Langkah selanjutnya: T8-13 (Laporan klaim voucher + dasar deteksi anomali: `supabase/migrations/0068_laporan_voucher.sql`, `aplikasi/src/layar/laporan/LaporanVoucher.tsx`).

0ZH. **FASE 8: T8-11 (Pengaturan kampanye voucher oleh admin) SELESAI.**
   - Migrasi `0066_kampanye_aturan.sql` berisi trigger `trg_validasi_aturan_kampanye` (mencegah aturan mustahil: persen > 100%, nominal <= 0, selesai <= mulai, kuota <= 0, anggaran < nominal), helper format kalimat pratinjau ramah awam `format_pratinjau_aturan`, RPC `simpan_kampanye_voucher`, `ambil_daftar_kampanye`, dan `ubah_status_kampanye`.
   - Berkas uji `supabase/tes/kampanye_aturan.sql` (seluruh 109 berkas uji SQL lulus 100%).
   - Uji mutasi `alat/uji-mutasi-0066.py` (6/6 mutasi kritis terbukti MERAH) dan `--uji-diri` lulus tanpa cacat.
   - Komponen antarmuka admin `aplikasi/src/layar/pengaturan/Kampanye.tsx` dengan modal buat/edit, validasi interaktif pencegah aturan mustahil, filter status aktif/nonaktif, statistik serapan kuota, dan kotak pratinjau kalimat aturan manusiawi real-time beserta simulasi contoh belanja pelanggan.
   - 11 uji unit komprehensif di `aplikasi/src/layar/pengaturan/Kampanye.test.tsx` lulus 100%.
   - Mutasi aplikasi terjaga di `aplikasi/alat/uji-mutasi-app.mjs` (80/80 mutasi perilaku terbukti MERAH).
   - Seluruh pemeriksaan struktur, UI, aturan desain, dan multi-bahasa lolos 100%.

0ZF. **FASE 8: T8-09 (Layar kasir: Cek [baca saja] & Pakai [atomik + PIN] ⚠️) SELESAI.**
   - Implementasi modul kasir cek & pakai voucher secara aman dan atomik:
     1. Migrasi `supabase/migrations/0065_kasir_cek_pakai_voucher.sql`:
        - Pembaruan pemicu `picu_diskon_batas()` yang memvalidasi voucher sungguhan di basis data saat `jenis = 'voucher'`, memastikan voucher sah terdaftar, berstatus `terpakai`, dan terikat ke `pesanan_id`.
        - RPC `public.cek_voucher(p_kode, p_cabang_id, p_subtotal)` yang MURNI BACA-SAJA (read-only): tidak mengubah status voucher atau tabel transaksi apa pun, mencatat log audit ke `voucher_percobaan`, dan menghitung estimasi potongan secara presisi berdasarkan aturan kampanye (persen plafon maks atau nominal).
        - RPC `public.pakai_voucher(p_pesanan_id, p_kode, p_pin_kasir, p_kunci_idempoten)` yang mengeksekusi pencairan voucher secara atomik sekali-pakai (ART-5): memverifikasi otentikasi kasir (`auth.uid()`), izin `pakai_voucher`, otorisasi PIN kasir berizin secara kriptografis (`crypt(pin, pin_hash)`), idempoten anti-dobel diskon, penolakan larangan tumpuk diskon jika konfigurasi resto melarang, dan penyisipan baris ke `diskon_transaksi`.
     2. Berkas Uji SQL `supabase/tes/kasir_voucher.sql`: 108/108 berkas uji SQL lulus 100%, membuktikan:
        - Cek voucher tidak mengubah status baris voucher di database sama sekali (baca saja terbukti).
        - Cek voucher menghitung potongan persen dan nominal secara presisi.
        - Pakai voucher menolak PIN kasir yang salah dan mencatat kegagalan ke `percobaan_pin`.
        - Pakai voucher dengan PIN benar mencairkan voucher secara atomik dan mengurangi tagihan pesanan.
        - Dobel klaim voucher yang sama pada transaksi lain ditolak (`VOUCHER_SUDAH_TERPAKAI`).
        - Penolakan tumpuk diskon berjalan jika resto melarangnya.
     3. Penilai mutasi `alat/uji-mutasi-0065.py`: 5/5 mutasi kritis terbukti MERAH (PIN kasir tidak divalidasi, status voucher tidak diubah ke terpakai, cek voucher merusak sifat baca-saja, pembatasan tumpuk diskon dimatikan, dan plafon batas maksimal potongan diabaikan).
     4. Komponen Kasir `aplikasi/src/layar/kasir/VoucherKasir.tsx` & `Voucher.tsx`: antarmuka ramah awam dengan kolom isian kode voucher, tombol cek baca-saja, kartu hasil cek terperinci, kolom PIN kasir berkeamanan tinggi, tombol eksekusi atomik sekali-pakai, dan pesan kegagalan spesifik tanpa jargon teknis.
     5. Integrasi `aplikasi/src/layar/kasir/LayarKasir.tsx`: tab navigasi antara Diskon Manual dan Voucher Promosi, terhubung dengan state `diskonAktif`.
     6. Uji unit Vitest `aplikasi/src/layar/kasir/VoucherKasir.test.tsx` (8 uji unit) dan `LayarKasirDiskon.test.tsx` (8 uji unit) lulus 100%.
     7. Dokumentasi: `docs/DECISIONS_LOG.md` (Area: Voucher ART-5), `PANDUAN_PENGGUNA.md` (108 berkas uji SQL), `docs/ROADMAP.md` (DoD T8-09 dicentang `[x]`).
   - Langkah selanjutnya: T8-10 (Scan kamera + ketik manual untuk kasir).

0ZE. **FASE 8: T8-08 (Terbitkan kode voucher acak + barcode) SELESAI.**
   - Migrasi `0064_terbit_voucher_acak.sql`: generator kode acak non-sekuensial `buat_kode_voucher_acak()`, validator format `apakah_format_voucher_acak()`, pembuat pola bit barcode garis 1D `pola_barcode_garis()`, dan RPC `ambil_kartu_voucher(p_kode)`.
   - Komponen `KartuVoucher.tsx`: tiket voucher, barcode SVG 1D, barcode 2D QR Code, info kedaluwarsa, salin dan cetak.
   - Uji SQL `supabase/tes/voucher_terbit.sql` dan mutasi `alat/uji-mutasi-0064.py` (5/5 MERAH).

0ZD. **FASE 8: T8-07 (Verifikasi email + anti email sekali-pakai + normalisasi Gmail ⚠️ T-011) SELESAI.**
   - Implementasi perlindungan ketat dari manipulasi pendaftaran pelanggan dan voucher:
     1. Pustaka utilitas klien `aplikasi/src/lib/emailNormalisasi.ts`: normalisasi Gmail (buang titik, potong alias `+...`, satukan `googlemail.com` ke `gmail.com`), saringan domain email sekali-pakai (disposable email blacklist mencakup 39+ domain populer), dan penanganan format email standar. 9 uji unit di `emailNormalisasi.test.ts` membuktikan 6 kasus tepi wajib DoD 100% lulus.
     2. Formulir pendaftaran `aplikasi/src/layar/voucher/Daftar.tsx`: terintegrasi langsung dengan saringan `normalisasiEmail` di sisi browser untuk memberikan umpan balik langsung sebelum pengiriman data. 6 uji unit di `Daftar.test.tsx` lulus 100%.
     3. Edge Function `supabase/functions/verifikasi_pelanggan/index.ts`: penerima pendaftaran mandiri dengan validasi wajib persetujuan privasi UU PDP (T-011), validasi nama, saringan domain email sekali-pakai, dan penerusan aman ke database. 10 uji batas VM tanpa jaringan di `alat/uji-edge-verifikasi-pelanggan.mjs` lolos 100%.
     4. Migrasi `supabase/migrations/0063_anti_email_palsu.sql`: tabel `pelanggan`, `kampanye_voucher`, `voucher`, `voucher_percobaan`, RPC atomik `daftar_voucher`, fungsi SQL `normalisasi_email`, pemicu validasi privasi eksplisit `persetujuan_privasi = true`, indeks unik `(penyewa_id, email_normalisasi)` dan batasan satu voucher per identitas per kampanye `unique (kampanye_id, pelanggan_id)`, serta kebijakan RLS multi-tenant yang memenuhi F-10.
     5. Suite SQL `supabase/tes/anti_email_palsu.sql`: 106/106 berkas uji SQL lulus 100%.
     6. Penilai mutasi `alat/uji-mutasi-0063.py`: 4/4 mutasi kritis terbukti MERAH.
     7. Dokumentasi: `docs/DECISIONS_LOG.md` (ART-5 & ART-10), `PANDUAN_PENGGUNA.md` (106 berkas uji SQL), `docs/ROADMAP.md` (DoD T8-07 dicentang `[x]`).
   - Langkah selanjutnya: T8-08 (Terbitkan kode voucher acak + barcode).

0ZC. **FASE 8: T8-06 (Halaman kampanye + pendaftaran pelanggan) SELESAI & T8-07 SIAP LANJUT.**
   - Implementasi halaman kampanye promo dan pendaftaran pelanggan untuk klaim voucher mandiri:
     1. Komponen `aplikasi/src/layar/voucher/Kampanye.tsx`: banner promo hero merek resto, rincian syarat & ketentuan dengan bahasa awam, penanda kuota voucher & progress bar kuota, banner pengundang eksklusif bila tautan berasal dari referral (`nama_pengundang` dan `kode_referral`), intip katalog menu, tombol aksi bagikan via WhatsApp dan salin tautan kampanye, serta modal lapis pendaftaran/klaim.
     2. Komponen `aplikasi/src/layar/voucher/Daftar.tsx`: formulir pendaftaran nama (wajib), email (wajib), nomor WhatsApp/telepon & alamat pengiriman (opsional sesuai Aturan Bisnis 3), persetujuan pemrosesan data privasi UU PDP (`data-testid="centang-privasi-voucher"`), integrasi verifikasi Google Sign-In & Email Magic Link, jalur bantuan ramah "didaftarkan kasir" bila pelanggan kesulitan verifikasi mandiri, serta kartu pratinjau voucher terbit dengan kode acak tidak berurutan dan barcode QR (`KomponenQr`).
     3. Rute terhubung di `aplikasi/src/App.tsx` (`kampanye` dan `klaim_voucher`).
     4. 10 uji unit di `Daftar.test.tsx` dan `Kampanye.test.tsx` (total 93 berkas Vitest frontend / 723 tes unit hijau).
   - Langkah selanjutnya: T8-07 (Verifikasi email + anti email sekali-pakai + normalisasi Gmail).

0ZB. **FASE 8: T8-05 (Tautan & QR katalog per resto — nomor meja & media sosial) SELESAI.**
   - Implementasi pengaturan tautan dan kode QR katalog di `aplikasi/src/layar/pengaturan/TautanKatalog.tsx`:
     1. Tautan resmi menu publik resto dengan tombol salin tautan instan, bagikan WhatsApp, dan pratinjau peramban.
     2. Generator kode QR akrilik meja per nomor meja dan meja kustom dengan parameter URL query `?meja=...&meja_id=...`.
     3. Pratinjau kartu meja akrilik fisik A6 (nama resto, tagline, nomor meja tebal, kode QR tajam, instruksi awam kamera ponsel).
     4. Tombol cetak langsung (`window.print()`) dan unduh berkas SVG siap cetak.
     5. Panel mitigasi risiko salah cetak: pengujian simulasi pindai 2 perangkat (Android dan iOS) sebelum cetak massal.
     6. Tab cetak massal seluruh meja cabang sekaligus.
     7. 9 uji unit di `TautanKatalog.test.tsx` (total 91 berkas Vitest frontend / 713 tes unit hijau).
   - Langkah selanjutnya: T8-06 (Halaman kampanye + pendaftaran voucher pelanggan).

0ZA. **FASE 8: T8-04 (Pencarian & penyaringan menu instan klien) SELESAI.**
   - Implementasi pencarian instan pada `Menu.tsx`:
     1. Kotak pencarian responsif dengan pencarian nama menu dan deskripsi/bahan tanpa lag dan tanpa perlu memuat ulang halaman.
     2. Tombol hapus/reset kata kunci ✕ instan untuk mengembalikan seluruh menu dalam satu ketukan.
     3. Tab penyaringan per-kategori yang terintegrasi secara mulus dengan kueri pencarian.
     4. Tombol chip filter cepat menu unggulan (⭐ Unggulan) untuk menyaring hanya menu rekomendasi resto.
     5. Carousel sorotan menu unggulan di bagian atas dengan kartu rekomendasi visual.
     6. Pengujian Vitest: 12 uji unit di `Menu.test.tsx` termasuk 5 uji unit khusus skenario pencarian DoD T8-04.

0Z. **FASE 8: T8-03 (Daftar menu + foto + harga + penanda habis) SELESAI.**
   - Implementasi daftar menu interaktif terintegrasi:
     1. Komponen `aplikasi/src/layar/pelanggan-publik/Menu.tsx`: menyajikan menu berkategori, format rupiah standar, foto teroptimasi dengan lazy loading dan decoding asinkron.
     2. Modal rincian menu `Lapis`: varian porsi/rasa dan tambahan topping opsional dengan simulasi harga total interaktif secara real-time.
     3. Penanda habis visual: item habis ditampilkan tertutup dengan overlay redup, lencana bahaya HABIS, serta opsi sakelar sembunyikan/tampilkan menu habis.

0Y. **FASE 8: T8-02 (Halaman katalog publik per resto merek sendiri) SELESAI.**
   - Implementasi antarmuka publik selesai penuh:
     1. Komponen `aplikasi/src/layar/pelanggan-publik/Katalog.tsx`: menampilkan merek resto (nama, logo, tagline), banner hero, jam operasional, kontak & lokasi cabang, penyaringan kategori, indikator penanda habis jelas, serta modal berbagi tautan dan QR.
     2. Kontrak Layar `aplikasi/src/layar/pelanggan-publik/LayarPelangganPublik.tsx`: menangani 7 keadaan wajib kontrak UI (memuat, gagal, kosong, berhasil) dan mengintegrasikan RPC `katalog_publik`.
     3. Generator QR Code mandiri `aplikasi/src/lib/qrcode.ts` & komponen `aplikasi/src/komponen/KomponenQr.tsx`: menghasilkan matriks modul dan SVG tajam tanpa dependensi eksternal pihak ketiga (0 kerentanan keamanan).
     4. Pengujian Vitest: 4 uji di `Katalog.test.tsx`, 5 uji di `LayarPelangganPublik.test.tsx`, 2 uji di `KomponenQr.test.tsx`, 4 uji di `qrcode.test.ts`.
     5. Pemeriksa UI: `prototipe/uji-kontras.py` 166 lolos 0 gagal, `alat/peta-ui.py` hijau bebas tombol liar, `App.tsx` tersambung dengan navigasi publik dan fallback lokal.

0Y. **FASE 8: T8-01 (RPC katalog_publik tanpa data sensitif) SELESAI.**
   - Migrasi `0062_katalog_publik.sql`: fungsi RPC `public.katalog_publik(p_penyewa_id, p_cabang_id)` memungkinkan pengunjung publik/pelanggan membaca informasi profil resto, jam operasional, kontak cabang, kategori, dan menu beserta ketersediaan per cabang secara terisolasi.
   - Nol Kebocoran Data Sensitif (ART-10 & ART-1): proyeksi kolom tegas tanpa data kredensial, keuangan, atau audit internal.
   - Uji SQL & Mutasi: `supabase/tes/katalog_publik.sql` 105/105 lolos · `alat/uji-mutasi-0062.py` 3/3 mutasi kritis terbukti MERAH TAJAM.

0X. **AUDIT MENYELURUH PUTARAN KEDUA (AUD-4) & JAMINAN HANDOFF TOTAL.**
   - Sesuai arahan Lee, pemeriksaan menyeluruh putaran kedua (AUD-4) disiapkan secara jauh lebih dalam, teliti, dan sempurna dengan pembagian spesifik ke 3 agen pemeriksa independen (plus 1 paket master menyeluruh):
     1. **Agent A (Keamanan, Database, RLS, Auth, Concurrency & Integritas Data):**
        - Berkas paket: `docs/uji/paket-audit/AUD-4-2026-09-25-keamanan.md`
        - Berkas siap-tempel: `docs/uji/paket-audit/AUD-4-2026-09-25-keamanan-SIAP-TEMPEL.md` (173 berkas)
        - Fokus: RLS multi-tenant, Security Definer search_path, mitigasi TRUNCATE audit, session timeout 15 menit, verifikasi PIN perangkat, anti-bypass tabel `pembayaran`, proteksi brute force, penolakan token kadaluwarsa, sanitasi input Edge Functions.
     2. **Agent B (UI/UX, Desain, Aksesibilitas, Responsivitas Mobile/Tablet/Desktop, 10 Tema):**
        - Berkas paket: `docs/uji/paket-audit/AUD-4-2026-09-25-antarmuka.md`
        - Berkas siap-tempel: `docs/uji/paket-audit/AUD-4-2026-09-25-antarmuka-SIAP-TEMPEL.md` (96 berkas)
        - Fokus: target sentuh ≥44px di seluruh tombol/input, kontras warna WCAG AAA/AA di 10 tema (terang, gelap, kedai, bara, kontras tinggi, dll), konsistensi token CSS, penanganan orientasi layar HP/tablet, navigasi kasir/dapur/laporan, tidak ada teks keras (i18n 100% paritas kamus bahasa ID, EN, ZH, AR).
     3. **Agent C (Logika Bisnis POS, Transaksi, Kasir & Shift, KDS Dapur, Diskon, Void, Laporan):**
        - Berkas paket: `docs/uji/paket-audit/AUD-4-2026-09-25-bisnis.md`
        - Berkas siap-tempel: `docs/uji/paket-audit/AUD-4-2026-09-25-bisnis-SIAP-TEMPEL.md` (191 berkas)
        - Fokus: state machine pesanan & item dapur, pembatalan pra/pasca-dapur dengan bahan terbuang jujur, rekonsiliasi kas modal awal & tutup shift, transaksi tengah malam (penanggalan operasional cabang), laporan keuangan & akurasi golden test (|selisih| = 0).
     4. **Paket Master AUD-4 Menyeluruh (Opsional bila satu sesi mandiri):**
        - Berkas paket: `docs/uji/paket-audit/AUD-4-2026-09-25.md`
        - Berkas siap-tempel: `docs/uji/paket-audit/AUD-4-2026-09-25-SIAP-TEMPEL.md` (409 berkas, 74 klaim bukti, 193 tugas roadmap).
   - **Jaminan Handoff:** Jika sesi ini sewaktu-waktu terputus/eror, Lee cukup mengatur base branch ke `arena/01a0d09b-resto-barokah` dan mengirim pesan chat: "baca pro.md". Sesi baru akan otomatis membaca `PRO.md`, menjalankan `--susul`, membaca handoff ini, dan langsung siap melanjutkan tanpa kehilangan konteks satu pun.

0W. **RESOLUSI TEMUAN AUDIT INDEPENDEN MENYELURUH AUD-3 (13/15 TEMUAN DITUTUP RESMI).**
   - 3 sesi agent auditor independen menyeluruh ditarik (Laporan L, M, N) menghasilkan 15 temuan nyata.
   - Sesi ini ditugaskan kembali oleh Lee sebagai pekerja utama (§27 REKAM_PESAN_PEMILIK.md).
   - Seluruh 13 temuan teknis (database RLS, SQL security definer, pergerakan kas, UI/UX, navigasi, rujukan roadmap, dan panduan) telah diselesaikan dan dibuktikan 100% dengan tes SQL (104 berkas lolos), Vitest frontend (85 berkas / 677 tes lolos), dan mutasi (17/17 mutasi merah pada skrip 0056 s.d. 0061).
   - 2 temuan tetap terbuka dengan penugasan sah: L F-05 (uji perangkat fisik printer Bluetooth/USB T6-08 milik Lee) dan L F-06 (antrean offline multi-koneksi T8-03 di Fase 8).
   - Rekapitulasi lengkap dan status roadmap siap dilaporkan kepada Lee untuk keputusan langkah berikutnya (misal memasuki Fase 8 atau pengujian visual).

0V. **PERSIAPAN PINDAH SESI & AUDIT MENYELURUH SESUAI INSTRUKSI LEE.**
   - Lee menginstruksikan jeda untuk pindah sesi dan menjalankan audit/pemeriksaan menyeluruh di sesi baru secara maksimal dan sempurna, mencakup UI, UX, fungsi, fitur, hingga fondasi dan seluruh aspek pembangunan aplikasi.
   - Seluruh 12 tugas Fase 7 (T7-01 s.d. T7-12) telah tuntas 100% dan terbukti lolos uji golden matematis (|selisih| = 0).
   - Paket audit menyeluruh AUD-3 telah dibuat: docs/uji/paket-audit/AUD-3-2026-09-24.md dan berkas siap-tempel docs/uji/paket-audit/AUD-3-2026-09-24-SIAP-TEMPEL.md (mencakup 383 berkas proyek, 193 tugas roadmap, 72 klaim bukti, dan bahan kalibrasi).
   - Rencana di sesi baru: Jalankan audit komprehensif atau instruksikan sesi auditor independen sesuai paket AUD-3-2026-09-24, kemudian analisis dan panen temuan audit untuk perbaikan menyeluruh sebelum melangkah ke Fase 8.

0U. **T7-12 (Uji golden: laporan = data mentah) SELESAI — FASE 7 TUNTAS PENUH 100%.**
   - Berkas uji `supabase/tes/golden_laporan.sql` membuktikan secara matematis dan deterministik bahwa seluruh angka laporan operasional (`laporan_penjualan`, `laporan_menu`, `laporan_harian`, `laporan_shift`, `laporan_pembatalan`, `laporan_koreksi_modal`) sama persis (|selisih| = 0) dengan hasil hitung langsung dari tabel data mentah transaksi (`pesanan`, `pesanan_item`, `pembayaran`, `kas_pergerakan`, `koreksi_modal_shift`, `shift_kas`).
   - Skenario pengujian menguji seluruh kasus tepi dunia nyata 1 hari penuh: transaksi tunai, diskon manual kasir, diskon atasan via bukti PIN, pembayaran QRIS, split payment (tunai + QRIS), pembatalan parsial satu item pra-dapur, pembatalan penuh pasca-dapur dengan bahan terbuang disetujui PIN atasan, kas masuk/keluar, setoran brankas, koreksi modal awal shift (+50.000), dan rekonsiliasi tutup shift fisik pas.
   - Perbaikan `alat/uji-mutasi-0014.py` (M14-7) mengenali definisi aktif `picu_pesanan_jejak_jujur()` di `0054` sehingga mutasi 0014 kembali **17/17 MERAH**.
   - Suite SQL kini **98 berkas LULUS · 0 GAGAL** · seluruh uji mutasi Fase 7 lulus 100% (0045..0054) · panduan pengguna diselaraskan 98 berkas uji.
   - **PENGINGAT AUDIT MENYELURUH FASE 7 (§25 REKAM_PESAN_PEMILIK.md):** Seluruh 12 tugas Fase 7 telah selesai lengkap 100%. Sesuai instruksi Lee, proyek mengambil jeda wajib untuk mekanisme audit dan pemeriksaan menyeluruh bersama Lee sebelum melangkah ke Fase 8. Dilarang lanjut ke Fase 8 tanpa jeda dan persetujuan Lee.

0T. **T7-11 (Transaksi lewat tengah malam ⚠️ ART-9) SELESAI.**
   - Migrasi `0054_transaksi_tengah_malam.sql` menegakkan penanggalan berbasis zona waktu resto (`tanggal_lokal_cabang`), mematikan default UTC `pesanan.tanggal`, menyelaraskan penomoran pesanan operasional, dan memperbarui `laporan_harian` dengan pemotongan batas hari zona waktu resto.
   - Berkas uji `supabase/tes/tengah_malam.sql` mensimulasikan transaksi jam 23:50 WIB dan 00:10 WIB hari berikutnya.
   - Uji mutasi `alat/uji-mutasi-0054.py` membuktikan 6/6 mutasi MERAH.

0S. **T7-10 (Tampilan laporan siap cetak/simpan PDF + filter cabang) SELESAI.**
   - Komponen `FormatLaporan.tsx` dan integrasi tab Format Siap Cetak di `LayarLaporan.tsx`.
   - Tata letak dokumen standar A4 / PDF dengan kop resmi Resto Barokah, periode laporan, pemisah cabang sesuai wewenang (mitigasi kebocoran lintas cabang T2-07), ringkasan keuangan, metode bayar, rekonsiliasi kas shift & brankas, menu terlaris, pengawasan promosi/pembatalan, serta kolom pengesahan tanda tangan kasir dan pemilik.

0R. **T7-09 (Laporan menu terlaris + diskon/voucher terpakai) SELESAI & T7-08 (Laporan penjualan dasar) SELESAI.**
   - Migrasi `0053_laporan_menu.sql` (RPC `laporan_menu`) dan `0052_laporan_penjualan.sql` (RPC `laporan_penjualan`).
   - Layar UI `LaporanMenu.tsx` dan `LaporanPenjualan.tsx` dengan filter cabang dan tab visual.
   - Uji mutasi `alat/uji-mutasi-0053.py` (6/6 MERAH) dan `alat/uji-mutasi-0052.py` (6/6 MERAH).

0P. **T7-06 (Koreksi modal awal dengan izin atasan ⚠️) SELESAI.**
   - Migrasi `0050_koreksi_modal.sql` membuat tabel riwayat append-only `public.koreksi_modal_shift`, pemicu kekal `picu_koreksi_modal_kekal` (anti update/delete), dan mengunci kolom `modal_awal` pada `public.shift_kas` dari perubahan langsung via UPDATE biasa.
   - Prosedur RPC `public.koreksi_modal_shift` memvalidasi wewenang atasan (owner pusat atau admin cabang pengelola), memeriksa kupon PIN atasan (aksi 'koreksi_modal_shift', batas 5 menit), mengonsumsi kupon (sekali pakai), mengunci shift terbuka, memutasi `modal_awal`, serta mencatat rekaman audit berantai hash SHA-256 pada `public.catatan_audit`.
   - View pengawasan pemilik `public.laporan_koreksi_modal` (`security_invoker = true`) menggabungkan rincian riwayat koreksi modal, nama pengaju, nama penyetuju, dan alasan.
   - Komponen UI `KoreksiModal.tsx` dan integrasi di `LayarKasir.tsx` dengan kalkulasi selisih visual dinamis (+/- Rupiah), pemilih atasan, kolom PIN atasan, dan alasan wajib.
   - Multibahasa 100% lengkap pada 4 bahasa (`id`, `en`, `zh`, `ar` dengan 208 kunci).
   - Bukti: suite SQL **93 LULUS** · uji mutasi SQL 0050 **6/6 MERAH** · Vitest **79 berkas / 625 tes LULUS** · CI **118 gerbang utuh** · kontrak UI hijau (`peta-ui.py`).
   - Langkah berikutnya di Fase 7: `T7-07 Laporan A: kas harian per shift`.

0O. **T7-05 (Pengingat shift belum ditutup & mitigasi shift menggantung) SELESAI.**
   - Migrasi `0049_pengingat_shift.sql` menambahkan kolom `melewati_tengah_malam` pada `public.shift_kas`, kolom `jam_tutup` (bawaan '22:00') pada `public.pengaturan`.
   - Pemicu `trg_shift_kas_tengah_malam` otomatis mendeteksi ketika shift ditutup di hari berbeda (`sekarang::date > dibuka_pada::date`), menyetel `NEW.melewati_tengah_malam = true`.
   - RPC `public.tutup_shift` otomatis mencatat rekaman audit `shift_melewati_tengah_malam` berantai hash kriptografis SHA-256 pada `public.catatan_audit`.
   - View pengawasan pemilik `public.laporan_shift_menggantung` (dengan `security_invoker = true`) menampilkan shift aktif yang belum ditutup, durasi jam, dan tanda melewati tengah malam.
   - Komponen UI `PengingatShift.tsx` dan integrasi di `LayarKasir.tsx` dengan banner bertingkat (🚨 Kritis melewati tengah malam, ⏰ Mendesak lewat jam tutup, ⏳ Peringatan > 12 jam, ⏳ Informatif mendekati tutup dengan aksi Ingatkan Nanti), serta tombol aksi langsung buka dialog tutup kas.
   - Multibahasa 100% lengkap pada 4 bahasa (`id`, `en`, `zh`, `ar` dengan 194 kunci).
   - Bukti: suite SQL **92 LULUS** · uji mutasi SQL 0049 **6/6 MERAH** · Vitest **78 berkas / 616 tes LULUS** · mutasi aplikasi **77/77 MERAH** · CI **117 gerbang utuh** · kontrak UI hijau (`peta-ui.py`).
   - Langkah berikutnya di Fase 7: `T7-06 Koreksi modal awal dengan izin atasan ⚠️`.

0N. **T7-04 (Transaksi hanya dalam shift terbuka ⚠️) SELESAI.**
   - Migrasi `0048_wajib_shift.sql` menambahkan konfigurasi `wajib_shift` pada `public.pengaturan`.
   - Pemicu `picu_pesanan_validasi_shift_terbuka` menolak pembuatan pesanan jika `wajib_shift = true` dan kasir/pelayan tidak punya shift kasir berstatus `'terbuka'`.
   - Pemicu `picu_pembayaran_validasi_shift_terbuka` dan RPC `bayar_pesanan` menolak pencatatan pembayaran tanpa shift terbuka, serta menyambungkan transaksi ke `shift_id` aktif.
   - Pagar UI di `LayarKasir.tsx`: banner peringatan kasir belum buka kas tampil jika `wajibShift && !shiftAktif`, tombol cepat `Buka Kasir Sekarang` untuk membuka modal shift langsung, serta tombol bayar dan kirim dapur otomatis mengalihkan kasir ke dialog `BukaKas`.
   - Multibahasa 100% lengkap pada 4 bahasa (`id`, `en`, `zh`, `ar` dengan 188 kunci).
   - Bukti: suite SQL **91 LULUS** · uji mutasi SQL 0048 **6/6 MERAH** · Vitest **77 berkas / 608 tes LULUS** · mutasi aplikasi **77/77 MERAH** · CI **116 gerbang utuh** · kontrak UI hijau (`peta-ui.py`).
   - Langkah berikutnya di Fase 7: `T7-05 Pengingat shift belum ditutup`.

0M. **T7-03 (Kas pergerakan uang masuk/keluar tunai, setoran, & koreksi) SELESAI.**
   - Migrasi `0047_kas_pergerakan.sql` mencatat uang tunai operasional di luar penjualan.
   - Pemicu `picu_kas_pergerakan_kekal` menjamin sifat append-only ledger keuangan kekal (anti-UPDATE dan anti-DELETE).
   - Pemicu `picu_kas_pergerakan_validasi_shift` dan RPC `kas_pergerakan` menjaga pergerakan operasional hanya pada shift terbuka.
   - Setelah shift ditutup, baris lama beku; koreksi dicatat sebagai baris baru bertanda 'koreksi' (ART-6).
   - `tutup_shift` otomatis mengintegrasikan pergerakan kas: `tunai_masuk` (penjualan + kas masuk) dan `tunai_keluar` (kas keluar + setoran) ke dalam `uang_seharusnya = modal_awal + tunai_masuk - tunai_keluar`.
   - Komponen `KasKeluarMasuk.tsx` + `KasKeluarMasuk.test.tsx` (8 unit test) terintegrasi di `LayarKasir.tsx` dengan nominal cepat, chips alasan cepat, dan validasi sisi klien tanpa tombol liar.
   - Bukti: suite SQL **90 LULUS** · uji mutasi SQL 0047 **6/6 MERAH** · Vitest **77 berkas / 605 tes LULUS** · mutasi aplikasi **75/75 MERAH** · CI **115 gerbang utuh** · 100% paritas 4 bahasa (185 kunci).
   - Langkah berikutnya di Fase 7: `T7-04 Transaksi hanya dalam shift terbuka ⚠️`.

0L. **T7-01 (Buka kas & modal awal) & T7-02 (Tutup kas & selisih) SELESAI.**
   - Migrasi `0045_buka_shift.sql` & `0046_tutup_shift.sql` menegakkan siklus hidup shift kasir.
   - Perhitungan uang seharusnya otomatis di peladen: `modal_awal + tunai_masuk - tunai_keluar`.
   - Constraint `shift_kas_selisih_alasan` mewajibkan kasir mengisi alasan jika terjadi selisih kas fisik vs catatan sistem.
   - Pemicu `picu_isi_shift_kas_pembayaran` otomatis menyambungkan transaksi tunai ke shift aktif kasir.
   - Komponen antarmuka `BukaKas.tsx` dan `TutupKas.tsx` terintegrasi di `LayarKasir.tsx` dengan live variance counter, tombol pecahan kas cepat, chips alasan cepat, dan konfirmasi aman.
   - Jejak audit kriptografis berantai hash tersimpan di `public.catatan_audit` (`aksi = 'tutup_shift'`).
   - Uji mutasi backend `0045` (6/6), `0046` (6/6), dan frontend (73/73) terbukti MERAH.

0J. **ATURAN TUTUP SESI — 3 hal wajib disebut agent (teguran Lee 2026-09-23).** Saat menutup sesi /
   menyiapkan pindah sesi (AL-13), agent **tidak boleh** berhenti di kalimat "siap pindah sesi".
   Wajib ditulis langsung di bagian **👉 Langkah Lee**: (a) **base branch** = nama cabang aktif
   **apa adanya** (saat ini `arena/01a0cca9-resto-barokah`, **bukan** `main`, bukan cabang lama
   `arena/01a0cb7f-resto-barokah` yang masih hidup di `e07ae6d`); (b) **prompt pembuka** = salin isi
   `PROMPT_SESI_BARU.md` (jalan pendek untuk chat yang sudah di cabang benar: `baca pro.md`);
   (c) **konfirmasi** baris pertama `PROMPT_SESI_BARU.md` menunjuk cabang aktif. Alasan: informasi
   ini SUDAH ada di `PROMPT_SESI_BARU.md`, tetapi Lee tidak tahu berkas itu harus dibuka.
0K. **PENJAGA BARU di `alat/lanjut-sesi.py`.** Pemeriksa kini **GAGAL** bila baris
   `SESI YANG AKU LANJUT:` menunjuk cabang yang **tidak memuat** HEAD sekarang. Dulu ia hanya
   memastikan baris itu ADA — sehingga baris basi (menunjuk sesi lama yang masih hidup di GitHub)
   lolos diam-diam dan sesi baru mendarat di pekerjaan tertinggal 25 commit tanpa peringatan apa pun.
   Perbaikannya: `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang-aktif>`.

0g. **T5-05 SELESAI (batch keempat).** Cacat nyata ditemukan & ditutup: `picu_diskon_batas()`
   memeriksa izin PEMANGGIL, sedangkan bukti PIN atasan (0016) tidak pernah menaikkan batas —
   alur "di atas batas → PIN atasan" (PRD M3) **mustahil dijalankan**. Ditutup migrasi
   **`0041_diskon_pin_atasan.sql`**: batas PENYETUJU berlaku bila buktinya sah (terikat pesanan
   itu, sekali pakai, ≤5 menit, penyetuju dicek ulang izinnya), sampai batas atasan saja.
   Sisi layar: **voucher keras-kode `BAROKAH10K` dibuang** (dulu memotong Rp10.000 tanpa izin,
   tanpa alasan, tanpa jejak, tanpa voucher di database), diganti `DiskonManual.tsx`.
0h. **Jebakan yang kena di batch ini — CATAT, mudah terulang:** menambah migrasi baru yang memuat
   pola `and pp.dipakai_pada is null` membuat mutasi **M6** di `alat/uji-mutasi-0012.py` mengenai
   berkas BARU (pencarian "migrasi terbaru dulu"), sehingga M6 terbaca "pagar tumpul" padahal
   pagar void tidak tersentuh — turun 16/16 → 15/16. Perbaikannya: sebut berkas migrasinya
   EKSPLISIT (`0015_penutup_celah_putaran16.sql`). **Pelajaran umum: sesudah menambah migrasi,
   jalankan `periksa-semua.sh` penuh — mutasi lama bisa tergeser diam-diam.**
0i. **T-027 dibuka (butuh keputusan Lee):** pajak & service di keranjang kasir masih dihitung
   layar (10 %/5 % perkiraan). Tidak membahayakan uang — angka sah selalu dari peladen dan itulah
   yang dicetak struk — tetapi bila tarif resto berbeda, angka keranjang bisa meleset. Ini juga
   membuat DoD **T3-02** belum sepenuhnya ditepati; dicatat apa adanya di ROADMAP (❓ T-027).
   Tertangguh terbuka kini **2** (T-026 Playwright, T-027 keranjang).
0j. **T5-06 SELESAI (batch kelima) — TANPA migrasi baru, dan itu disengaja.** ROADMAP
   menjadwalkan `0041_void_pra.sql`, tetapi pemeriksaan isi database lebih dulu menunjukkan
   **seluruh DoD T5-06 sudah ditegakkan** `picu_pembatalan_sah()` di
   `0015_penutup_celah_putaran16.sql`: tahap dibaca dari DUA tanda, alasan wajib lewat `check`
   di tabel `pembatalan` (`0010`), satu target sekali batal, nilai kerugian dari salinan harga,
   tidak ada penghapusan data. Menulis migrasi kembar justru akan mengulang jebakan 0h.
0k. **Cacat nyata T5-06 ada di LAYAR:** tombol "Hapus item" memakai `filter` untuk SEMUA keadaan,
   sehingga item yang sudah tercatat hilang tanpa alasan, tanpa pelaku, tanpa jejak — akibatnya
   tabel `pembatalan` beserta pagarnya **tidak pernah dipanggil siapa pun** dan laporan
   pembatalan harian selalu kosong. Ditutup `aplikasi/src/layar/kasir/VoidItem.tsx` (alasan
   WAJIB, alasan cepat, nilai yang batal ditagih terlihat, peringatan PIN bila dapur sudah
   mulai) + percabangan jujur di `LayarKasir.tsx`: tanpa prop `onBatalkanItem` keranjang tetap
   draf lokal; dengan prop itu, item **hanya** hilang setelah peladen menjawab berhasil.
   Bukti: **368 tes** aplikasi · `uji-mutasi-app.mjs` **24/24 MERAH** · SQL **84 LULUS**.
0l. **T5-07 SELESAI (batch keenam) — migrasi `0042_bahan_terbuang_jujur.sql`.** Dugaan di
   butir sebelumnya benar sebagian: PIN atasan & nilai kerugian memang sudah terpasang di
   `0015`. Yang **tidak pernah dijaga siapa pun** ternyata kolom `pembatalan.bahan_terbuang`
   itu sendiri — ada sejak `0010`, dipakai laporan kerugian, nol pemicu memeriksanya. Kasir
   bisa membatalkan pesanan yang **sudah dimasak** sambil mengirim `false`: sah, ber-PIN,
   bernilai benar, tetapi kerugian bahannya **lenyap dari laporan selamanya**. Sekarang
   penanda dihitung peladen dari tahap; kiriman bawaan ditimpa, kiriman bertentangan ditolak.
   Layar `VoidPasca.tsx` **tidak dibuat** — `VoidItem.tsx` sudah menangani kedua tahap.
0m. **JEBAKAN `berkas_berlaku` KAMBUH (kedua kalinya) — hafalkan:** `0042` menulis ulang utuh
   `picu_pembatalan_sah()`, sehingga mutasi **M6** di `alat/uji-mutasi-0012.py` yang menyasar
   `0015` tidak berpengaruh lagi (yang berlaku definisi TERAKHIR) → 16/16 turun 15/16.
   Jangkarnya dipindah ke `0042` dan pulih. **Aturan: setiap kali sebuah fungsi ditulis ulang
   di migrasi baru, SEMUA uji mutasi yang menyasarnya wajib ikut dipindahkan — dan sesudah
   menambah migrasi, jalankan uji mutasi lama, jangan hanya suite SQL.**
0n. **T5-08 SELESAI (batch ketujuh) — layar saja, penyimpanan SENGAJA belum.** Pemeriksaan
   keputusan terkunci menjawab pertanyaannya: **T-011** (disetujui 2026-09-21) menyatakan data
   pelanggan baru boleh **disimpan** setelah ada kebijakan privasi + halaman persetujuan, dan
   migrasinya dijadwalkan **T8-15**. Jadi yang dibuat hanya `DataPelanggan.tsx` — **tanpa tabel,
   migrasi, atau RPC apa pun** — sehingga tidak ada nomor pelanggan yang bisa tersimpan sebelum
   kebijakannya siap. Bukan Stop Condition: keputusannya tidak bertentangan, malah sudah
   menunjuk tempatnya. Yang dikunci & diuji: persetujuan eksplisit (dikirim sebagai data, bukan
   diasumsikan), minimalisasi (HP + nama panggilan saja), penjelasan di layar, dan tombol
   **Lewati selalu hidup** agar pembayaran tidak pernah terhambat.
0o1. **JEBAKAN 0m KAMBUH LAGI DI TEMPAT KEDUA — dan hanya tertangkap `periksa-semua.sh` penuh.**
   Selain M6 di `uji-mutasi-0012.py`, ternyata **F-05 di `alat/uji-mutasi-0015.py`** juga
   menyasar `picu_pembatalan_sah` di `0015` yang kini ditimpa `0042` → dilaporkan "pagar
   TUMPUL" padahal pagarnya utuh. Diperbaiki dengan konstanta `MIG42` + `berkas_rel=MIG42`.
   **Pelajaran prosedur: sesudah menambah migrasi, JANGAN cukup menjalankan suite SQL —
   jalankan seluruh uji mutasi (atau `periksa-semua.sh` penuh). Suite bisa hijau sempurna
   sementara penilai mutasi diam-diam lumpuh.**
0o2. **JEBAKAN 0m KAMBUH DI TEMPAT KETIGA — inilah penyebab CI merah 4× berturut-turut.**
   `alat/uji-mutasi-0019.py` (pagar diskon T5-04) menyasar `picu_diskon_batas` di `0019`,
   padahal `0041` (T5-05) menulis ulang fungsi itu utuh. Akibatnya **SELURUH 5 mutasinya
   lumpuh sejak T5-05** dan CI gagal di langkah itu pada run 35842018455 & 35842912994;
   pesannya ("pagar tumpul!") mudah disalahartikan sebagai cacat pagar diskon. Sesudah
   `MIGRASI` diarahkan ke `0041`: **5/5 MERAH** — pagarnya sehat sepanjang waktu.
   **Cara cepat memeriksa: `grep -rln "<teks jangkar>" supabase/migrations/` — kalau muncul
   di lebih dari satu migrasi, jangkar wajib menunjuk yang PALING AKHIR.**
0o3. **Catatan alat:** penilai mutasi memakai direktori kerja tetap di `/tmp`
   (mis. `/tmp/mutasi-0015-rb`), jadi **jangan menjalankan dua penilai bersamaan** — hasilnya
   saling merusak dan memberi "GAGAL" palsu. Ini sempat menipu saya satu putaran.
0o. **Berikutnya T5-09** (struk digital sebagai cadangan saat printer bermasalah). Perhatikan:
   T5-03 (struk termal) sudah selesai, jadi **periksa dulu** apa yang sudah ada di berkas struk
   sebelum membuat yang baru — dua batch terakhir menunjukkan rencana ROADMAP sering lebih tua
   daripada isi repo. Migrasi berikutnya bila perlu: **≥ 0043**.
0p. **Kalau butuh angka bukti terakhir:** aplikasi **74 berkas / 578 tes LULUS** · suite SQL
   **87 LULUS** · `uji-mutasi-app.mjs` **65/65 MERAH** · `uji-mutasi-0043.py` **4/4 MERAH** ·
   `uji-mutasi-0042.py` **4/4 MERAH** · `uji-mutasi-0012.py` **16/16** · gerbang & paritas CI
   LOLOS · `tsc` bersih · lint 0 error.

0q. **T5-09 SELESAI (batch kedelapan).** `StrukDigital.tsx` **membungkus `<Struk>` yang sama**,
   tidak menggambar ulang — mitigasi ART-7: kalau struk digital punya kode tata letak sendiri,
   suatu hari angkanya akan berbeda dari kertas dan tidak ada yang tahu mana yang benar.

0r. **T5-10 DIKERJAKAN SEBAGIAN — SENGAJA, dan tugasnya BELUM dicentang.** Yang selesai:
   `DaftarTransaksi.tsx` (cari lewat nomor/jam/nominal; titik ribuan diabaikan) + cetak ulang
   yang **selalu bertanda "SALINAN — CETAK ULANG"** termasuk di pratinjau layar, sebab lembar
   kedua yang terlihat identik bisa dipakai menagih dua kali. "Tidak mengubah data" dijaga uji
   penjaga `?raw` (dilarang `.rpc(`/`fetch(`/`.insert(`/`.update(`/`.delete(`).
   Yang BERHENTI: bagian **catatan audit** butuh RPC baru, sedangkan RPC di luar `TECH_SPEC` §5
   adalah **Stop Condition** milik Lee → dibuka **T-028** dengan tiga pilihan. Tertangguh
   terbuka kini **3** (T-026, T-027, T-028).

0s. **T5-11 SELESAI (batch kesembilan) — tanpa migrasi baru.** RPC `bayar_pesanan` ternyata sudah
   mendukung pembayaran sebagian sejak T5-02; yang belum ada adalah buktinya dan layarnya.
   `supabase/tes/pembayaran_sebagian.sql` menegaskan keputusan MVP: pembayaran sebagian =
   **beberapa baris pembayaran terpisah pada SATU pesanan**, baris pertama tidak ditimpa,
   dan pembayaran sesudah lunas **ditolak**. Alasannya kas: kalau ditimpa, 20.000 tunai +
   14.500 QRIS terbaca satu angka dan laci kas tak bisa dicocokkan per metode di akhir shift.
   `DaftarTagihan.tsx` memberi **penanda umur** (baru → lama ≥30 mnt → mendesak ≥120 mnt).

0t. **TEMUAN T5-11 yang layak diingat:** peladen **tidak memercayai** kolom `total` kiriman
   klien — ia menghitung ulang (pajak 10 % + service 5 %), jadi pesanan uji 30.000 menjadi
   34.500. Uji disesuaikan mengikuti peladen, **bukan sebaliknya**; menurunkan harapan uji agar
   cocok dengan angka klien justru melumpuhkan pagar yang benar.

0u. **CI MERAH ditangkap & diperbaiki — dua pelajaran.** Run `35851999419` jatuh di
   `alat/peta-ui.py`. (a) **Warisan T5-05:** `aksi.ts` menulis `rpc: 'diskon_transaksi'` padahal
   itu **nama tabel**, bukan fungsi — dikembalikan ke `null`. (b) **Dari T5-10:**
   `DaftarTransaksi.tsx` memakai `<button>` mentah yang dilarang Aturan 7 — diganti `<Tombol>`,
   ujinya pindah ke `getByRole` (lebih baik: menguji lewat peran aksesibilitas).
   **PELAJARAN PROSEDUR PALING PENTING SESI INI: tiga push beruntun saling MEMBATALKAN run CI
   sebelumnya, sehingga cacat (a) lolos beberapa commit tanpa terlihat. Run berstatus
   `cancelled` TIDAK boleh dibaca sebagai aman — tunggu satu run sampai `success`, atau
   jalankan sendiri pemeriksa langkah CI itu secara lokal sebelum push.**

0v. **T5-12 laporan pembatalan SELESAI.** `supabase/migrations/0043_laporan_pembatalan.sql` +
   `aplikasi/src/layar/laporan/DaftarPembatalan.tsx`. Dugaan di butir ini ternyata **salah**:
   pagar tabel `pembatalan` TIDAK lengkap. Policy `pembatalan_pilih` hanya menuntut
   `pesanan_sepenyewa(pesanan_id)`, jadi **pelayan/kasir/dapur bisa membaca seluruh nilai
   kerugian dan nama pembatalnya**. 0043 menambah syarat `lihat_laporan`. Laporan berupa **view**
   `public.laporan_pembatalan` (bukan RPC — nama RPC-nya tidak ada di TECH_SPEC §5), wajib
   `security_invoker = true`. **Jangan longgarkan lagi:** `alat/uji-mutasi-0043.py` menahan 4
   mutasi. Migrasi berikutnya **≥ 0044**.

0w. **Pelajaran yang mahal: memperketat RLS membuat uji lama merah, dan itu WAJAR.** Tujuh berkas
   uji SQL jatuh setelah 0043 karena mereka memverifikasi hasil tulisan dengan **membaca ulang
   dari kursi kasir**. Yang benar: pembacaan verifikasi dipindah ke luar kursi kasir
   (`reset role; select uji.klaim(null);` … lalu klaim ulang), **bukan pagarnya dilonggarkan**.
   Kalau suatu saat ada uji pembatalan merah lagi, tanya dulu: "uji ini sedang menguji ISI jejak,
   atau HAK BACA-nya?" — kalau isi, pindahkan kursinya. Aplikasi sendiri tidak pernah membaca
   tabel `pembatalan` langsung (`grep from('pembatalan')` = kosong), jadi pagar ini tidak
   memutus fitur mana pun.

0L. **FASE 7 BERJALAN — T7-01 (Buka kas / modal awal) SELESAI (2026-09-24, sesi arena/01a0d09b).**
   - Migrasi `supabase/migrations/0045_buka_shift.sql`: tabel `public.shift_kas`, RLS InitPlan,
     aturan satu shift terbuka per kasir per cabang (indeks unik parsial + kode SH-409), audit hash otomatis,
     kunci foreign `pesanan.shift_id` & `pembayaran.shift_id`.
   - RPC: `public.buka_shift(cabang_id, modal_awal, catatan)` terpasang di `aplikasi/src/lib/aksi.ts`.
   - UI: `aplikasi/src/layar/kasir/BukaKas.tsx` + `BukaKas.test.tsx` (8 unit test murni) terpasang di `LayarKasir.tsx`.
   - Bukti: 88 suite SQL LULUS, mutasi 0045 6/6 MERAH, 75 berkas Vitest / 586 tes LULUS, mutasi UI 69/69 MERAH,
     kontrak `peta-ui.py` LULUS, tsc/lint/format/build bersih.
   - **TUGAS BERIKUTNYA:** `T7-02 — Tutup kas (seharusnya vs fisik) + alasan selisih ⚠️` (RPC `tutup_shift`,
     layar `TutupKas.tsx`, perhitungan saldo sistem uang_seharusnya vs uang_fisik, toleransi selisih).

0A. **FASE 6 DIMULAI — T6-01, T6-04, T6-05 SELESAI (2026-09-23).** Tiga tugas cetak yang bisa
   dikerjakan tanpa printer sudah jadi: `aplikasi/src/lib/printer/expos.ts` (penyusun ESC/POS),
   `struk.ts` (struk pelanggan), `tiket.ts` (tiket dapur). Semuanya **murni** — hanya data → byte,
   tidak menyentuh Bluetooth/USB. Itu disengaja: uji printer nyata (T6-08) hanya sesekali, jadi
   tata letak dikunci uji byte-level yang jalan di CI setiap saat.

0G. **MULAI DARI SINI (sesi baru, 2026-09-23).** Keadaan: Fase 5 tuntas untuk bagian agent;
   Fase 6 **T6-01/T6-02/T6-03/T6-04/T6-05 SELESAI**. **CI HIJAU** run `35886937856` (commit
   `5b9d4bf`). Tidak ada pekerjaan tergantung, pohon kerja bersih.
   **Kerjakan berikutnya: FASE 7 — kas & shift, mulai `T7-01` (buka kas / modal awal).** Alasan
   memilih Fase 7 dan bukan menuntaskan Fase 6: sisa Fase 6 semuanya terhalang hal di luar kode
   (printer nyata & keputusan RPC), sedangkan Fase 7 murni data + layar dan menutup lubang yang
   sudah terasa sejak T5-11 — tagihan ditinggal & pencocokan kas per metode saat tutup shift.
   Migrasi berikutnya: **≥ 0044** (T7-01 merencanakan `0045_buka_shift.sql`; periksa dulu nomor
   yang masih kosong sebelum menulis).

0H. **HATI-HATI: sandbox pernah DI-KLON ULANG dua kali** (2026-09-23). Gejalanya: ruang kerja
   tiba-tiba tampak kotor berisi puluhan berkas dan `git log` pendek/mundur. **Itu BUKAN pekerjaan
   yang hilang.** Jangan mengerjakan ulang apa pun sebelum menjalankan:
   `git ls-remote origin arena/01a0cca9-resto-barokah` — bandingkan dengan commit terakhir yang
   tercatat di PROJECT_STATE. Pemulihannya: `git stash -u`, `git fetch --unshallow origin <cabang>`,
   `git reset --hard FETCH_HEAD`, periksa isi stash (biasanya murni penghapusan) lalu buang.
   `node_modules` juga ikut hilang → `npm ci` di folder `aplikasi`.

0I. **MILIK LEE, JANGAN DISENTUH AGENT: lima uji printer** (M-12, M-22, M-23, M-24, M-25) kini
   tercantum di blok paling atas `docs/uji/RENCANA_UJI_MANUAL.md`. Lee sudah menyatakan akan
   mengeceknya nanti. **`T6-08` DILARANG dicentang** sampai ada hasil cetak sungguhan, dan agent
   dilarang mencentangnya sendiri.

0D. **T-002 DIJAWAB LEE (2026-09-23) — T6-02 & T6-03 SELESAI.** Printer Kedai Oasis: Goojprt
   PT-210, Kassen BT-P290, Blueprint Lite-58, Xprinter XP-N160II, Epson TM-T82X. Butir T-002 di
   `docs/TERTANGGUH.md` sudah ditutup. Berkas baru: `lib/printer/profil.ts`, `lib/printer/kirim.ts`,
   `layar/pengaturan/PasangPrinter.tsx`. **Butir 0B di bawah soal T6-02/T6-03 sudah TIDAK berlaku.**

0E. **ATURAN YANG TIDAK BOLEH DILANGGAR PENERUS: daftar merek printer = JALAN PINTAS, BUKAN SYARAT.**
   Lee bertanya khusus apakah printer di luar daftar tetap jalan, dan jawabannya sudah dijanjikan
   "ya". `tebakProfil()` wajib SELALU mengembalikan profil yang bisa dipakai (jatuh ke
   `PROFIL_UMUM`), penelusuran BLE menyeluruh wajib tetap ada, dan jalur USB wajib menerima jalur
   keluar apa pun bila kelas 7 tidak ketemu. **Enam mutasi menjaga ini** — kalau ada yang
   "merapikan" kode dengan membatasi ke merek terdaftar, CI langsung merah. Jangan dilonggarkan.

0F. **Yang MASIH kurang soal printer:** semua diuji dengan printer TIRUAN. Itu membuktikan
   logikanya, bukan kertasnya. **T6-08 (uji cetak nyata) tetap gerbang dan milik Lee** — langkahnya
   sudah ditulis awam di `docs/uji/PANDUAN_PRINTER.md`, ceklisnya M-22…M-25 di
   `docs/uji/RENCANA_UJI_MANUAL.md`. Jangan mencentang T6-08 tanpa hasil cetak sungguhan.

0B. **SISA FASE 6 BERHENTI DI STOP CONDITION — jangan dipaksakan.**
   - **T6-02 (Web Bluetooth) & T6-03 (WebUSB):** butuh **perangkat keras nyata**. Keduanya juga
     bergantung butir tertangguh **T-002** (merek/tipe printer Kedai Oasis belum diketahui). Lee
     sudah menyetujui "placeholder ESC/POS generik" — dan placeholder itulah yang kini SELESAI.
     Menulis kode sambungan tanpa tahu perangkatnya = menebak.
   - **T6-06 (antrean cetak & jejak audit):** memuat blok 🔴 **T-028** yang menuntut **RPC baru**;
     RPC di luar `docs/TECH_SPEC.md` §5 adalah keputusan pemilik → Stop Condition.
   - **T6-07 (printer per perangkat):** butuh migrasi `0044_printer.sql` + pengaturan; bisa
     dikerjakan agent, tetapi tanpa T6-02/T6-03 ia tidak bisa dibuktikan bekerja ujung-ke-ujung.
   - **T6-08:** uji cetak nyata di kedai — milik Lee.

0C. **Yang paling berguna dikerjakan berikutnya bila Lee belum sempat urus printer:** lompat ke
   **Fase 7** (kas & shift, `T7-01` buka kas). Fase 7 murni data + layar, tidak bergantung
   perangkat keras, dan menutup lubang yang sudah terasa sejak T5-11 (tagihan ditinggal &
   pencocokan kas per metode).

0y. **FASE 5 TUNTAS untuk bagian yang bisa dikerjakan agent.** Yang tersisa di Fase 5 adalah
   **bukti manual milik Lee** (T4-03 foto, T4-05 dua perangkat, T4-10 cabut jaringan, 5 metode
   bayar) — daftar periksanya sudah siap di `docs/uji/RENCANA_UJI_MANUAL.md`, tinggal Lee jalankan
   dan isi kolom centangnya. **Agent tidak boleh mencentangnya sendiri.**

0z. **Arah sesi berikutnya (urutan usulan, bukan perintah):** (1) mulai **Fase 6** — di sanalah
   **T6-06 memuat blok 🔴 WAJIB DIKERJAKAN DI SINI untuk T-028** (jejak audit cetak ulang), butir
   tertangguh yang sudah dijawab Lee dan tidak boleh terlewat; (2) T-026 (infra e2e Playwright)
   tetap terjadwal **Fase 11**, jangan dimajukan tanpa alasan kuat karena butuh dependensi dev
   baru + langkah CI baru; (3) ingat aturan tiga tempat: setiap perintah CI baru wajib didaftarkan
   di `.github/workflows/ci.yml`, `GERBANG_WAJIB` (`alat/periksa-gerbang-ci.py`), **dan**
   `aplikasi/alat/periksa-semua.sh` — kalau tidak, CI merah sendiri.

0x. **Penjaga `keamanan_fungsi.sql` (T130-initplan) menangkap cacat kinerja nyata.** Versi pertama
   0043 menulis `and public.boleh('lihat_laporan')` tanpa bungkus — PostgreSQL memanggil fungsi itu
   **sekali per baris**, bukan sekali per perintah. Bentuk yang benar: `and (select public.boleh(...))`.
   Setiap policy baru yang memanggil helper izin wajib memakai bentuk berbungkus ini.



0. **BACA DULU — SATU HAL YANG BELUM SELESAI: commit `227a51b` BELUM TER-PUSH.** Token GitHub
   kedaluwarsa di akhir sesi (`gh auth status` → "The github.com token in GH_TOKEN is no longer
   valid"; `git push` menolak dengan "could not read Username"). Pekerjaannya **aman sebagai commit
   lokal** di cabang `arena/01a0cca9-resto-barokah`. **Langkah pertama sesi baru:** minta Lee
   menyambungkan ulang GitHub di Arena, lalu `git push origin arena/01a0cca9-resto-barokah`, lalu
   periksa CI commit terakhir sebelum memulai pekerjaan baru. Jangan mengulang pekerjaannya —
   cek `git log` dulu.
0b. **FASE 5 YANG SUDAH SELESAI di sesi ini (jangan dikerjakan ulang):** **T5-01 sambungan**
   (`e8baf2c`), **T5-03 struk** (`66312f9`), **T5-04 diskon** (`227a51b`).
   Sisa Fase 5 menurut `docs/ROADMAP.md`: struk termal, buka/tutup shift, dan butir lain yang
   belum `[x]`.
0c. **T5-04 — pelajaran yang mahal, jangan diulang:** pagar diskon **sudah ada** sejak
   `0019_pesan_diskon_jujur.sql` (`picu_diskon_batas()`; cap kumulatif dari `0014`), jadi TIDAK
   dibuat migrasi baru — dua tempat yang mengatur uang berarti dua tempat yang bisa berbeda.
   Nomor migrasi yang tertulis di ROADMAP adalah rencana lama, bukan perintah (`0039_diskon.sql`
   sudah terpakai `bayar_pesanan`). **Sebelum menulis migrasi untuk butir ROADMAP mana pun,
   periksa dulu apakah aturannya sudah hidup di migrasi lama.** Yang ditambah: bukti —
   `supabase/tes/diskon_tumpuk.sql` + `alat/uji-mutasi-0019.py` (5/5 MERAH).
0d. **Jebakan uji diskon (sudah dua kali memakan korban):** asersi "total diskon melebihi subtotal"
   mudah jadi hijau-palsu karena satu baris diskon besar lebih dulu ditahan pagar **batas izin**
   (owner pun berbatas 20 %), sehingga pagar subtotal tak pernah tersentuh. Cara yang benar:
   tumpuk menyala + cap resto 100 % + penambahan **bertahap**. Ketahuan hanya karena uji mutasi —
   ini alasan uji mutasi tidak boleh dilewati.
0e. **T-026 TERBUKA (butuh jawaban Lee):** infra e2e Playwright. Chromium **tidak bisa diunduh**
   di ruang kerja agent — dicoba dua cara 2026-09-23 dan dua-duanya gagal (paket sistem tak
   tersedia; "Download failure code=1"). Karena itu langkah CI e2e **tidak** ditambahkan: menambah
   perintah CI yang tidak bisa dijalankan lokal melanggar paritas CI dan membuat CI merah sendiri.
   `T11-01`/`T11-11` di ROADMAP ditandai ❓ T-026. Pilihan untuk Lee ada di `docs/TERTANGGUH.md`.
0f. **Bukti akhir sesi ini:** aplikasi **330 tes LULUS** · suite SQL **83 LULUS · 0 GAGAL** ·
   `uji-mutasi-app.mjs` 14/14 MERAH · `uji-mutasi-0019.py` 5/5 MERAH · gerbang & paritas CI LOLOS
   (**109 perintah**) · `periksa-rujukan.py`/`periksa-bersih.py`/`periksa-roadmap.py` LOLOS ·
   `bash aplikasi/alat/periksa-semua.sh` hijau pada seluruh pemeriksa kode.

---

**KEADAAN SESI SEBELUMNYA (2026-09-23, `arena/01a0cb7f` — pintu "baca pro.md"):**

1. **Pindah sesi SUDAH terjadi.** Sesi ini dibuka dari `arena/01a0c97c` dan bekerja di cabang sendiri
   `arena/01a0cb7f-resto-barokah`. Handoff di atas kini menunjuk cabang ini (`--lanjut-dari`).
2. **Perintah pertama PRO.md §1 sudah dikerjakan — CI merah DIPERBAIKI (baca, bukan klaim):**
   run `35797734100` (`d923e99`) ternyata **cancelled** (tertimpa push `f7fd468`); run penggantinya
   `35798327450` (`f7fd468`) **failure** di langkah "Pemeriksa fondasi, roadmap, struktur, komponen,
   uji & kontras". 5 dari 53 perintah langkah itu gagal lokal. Empat cacat nyata ditutup:
   (a) `uji-mutasi-0032/0033/0035/0036/0037.py` masuk `ci.yml` tanpa entri `GERBANG_WAJIB`;
   (b) lima perintah yang sama tidak ada di `aplikasi/alat/periksa-semua.sh` (paritas CI);
   (c) `PANDUAN_PENGGUNA.md` menulis "72 berkas uji" padahal nyata 78;
   (d) `docs/PROJECT_STATE.md` merujuk `aplikasi/uji/e2e/dapur.spec.ts` (berkas rencana — belum dibuat) tanpa penanda rencana.
   Bukti lokal: 53/53 perintah langkah itu LOLOS · `bash aplikasi/alat/periksa-semua.sh` kode keluar 0
   · Prettier bersih. Rincian: `_log-sesi/LOG_SESI_2026-09-23.md` bagian sesi `arena/01a0cb7f`.
3. **CI SUDAH HIJAU TERBUKTI:** run **`35801364931`** pada commit **`9a6a6c8`** = `completed success`
   (job "Periksa (lint · tipe · uji · pemeriksa Python)" ✓ 11m51s, 0 langkah merah). Pembanding: run
   `35798327450` pada `f7fd468` (pohon sebelum perbaikan) = failure. Sesudah commit penutup batch ini,
   sesi berikutnya tetap wajib membaca ulang status CI commit terakhir sebelum mulai pekerjaan baru.
4. **Penting bila Lee membuka sesi baru lagi:** baris pertama `PROMPT_SESI_BARU.md` masih berisi
   `arena/01a0c97c-resto-barokah` (berkas STATIS — hanya Lee yang mengisinya). Ganti ke
   `arena/01a0cb7f-resto-barokah` supaya pekerjaan perbaikan CI ini tidak tertinggal.
5. **KABEL DATA REALTIME KDS = SELESAI (batch `7650483`, 2026-09-23).** `useTiketDapur` jadi
   kontainer `LayarDapur`/`LayarBar`; umur tiket dari jam peladen (migrasi `0038_waktu_peladen.sql`).
   Bukti: suite SQL **79 lulus** · aplikasi **268 tes lulus** · mutasi 0038 **3/3 MERAH** ·
   62/62 perintah langkah pemeriksa CI LOLOS lokal. Rincian: `_log-sesi/LOG_SESI_2026-09-23.md`
   bagian "BATCH 2".
6. **REGISTRI LAYAR + KABEL DATA STOK/OPNAME = SELESAI (batch `4fc0e28`, 2026-09-23).**
   `DAFTAR_LAYAR` **11 layar** (8 layar G1 tetap wajib + `bar`/`stok`/`opname` resmi),
   `REGISTRI_AKSI` **38 aksi**, bantuan kontekstual **11/11 layar**, `docs/PETA_UI.md` digenerate
   ulang, kontrak `layar.test.ts` direvisi (layar tak dikenal tetap ditolak), kabel data baru
   `aplikasi/src/hook/useStok.ts`. Dasar keputusan Lee + bukti: `docs/DECISIONS_LOG.md`
   [Kelengkapan UI/2026-09-23] dan `_log-sesi/LOG_SESI_2026-09-23.md` bagian "BATCH 3".
8. **CATATAN WAJIB (insiden 2026-09-23):** setiap suntingan `docs/ops/SIAP-LANJUT.md` — termasuk
   §3 yang memang ditulis agent — WAJIB diikuti `python3 alat/periksa-rujukan.py` +
   `python3 alat/periksa-bersih.py` sebelum commit. Rujukan ke berkas yang belum ada harus
   ditandai pada BARIS YANG SAMA dengan salah satu penanda `(rencana`, `belum ada`, `belum dibuat`,
   `akan dibuat`, `menyusul`, `dijadwalkan`, atau `T<numor>-<nomor>` (kata `rencana,` saja tidak
   dikenali pola). Langkah CI "Pemeriksa fondasi…" berisi **63 perintah**, semuanya bisa
   dijalankan lokal sebelum push.
9. **URUTAN BERIKUTNYA:** (a) infra e2e Playwright (`aplikasi/uji/e2e/dapur.spec.ts` — berkasnya belum dibuat) — butuh dependensi dev baru + langkah CI baru (ingat: setiap perintah CI
   baru WAJIB didaftarkan di `GERBANG_WAJIB` + `periksa-semua.sh`, kalau tidak CI merah sendiri);
   (b) Fase 5 sisa: **T5-03 struk** (pajak & service terpisah), **menyambungkan `LayarKasir.tsx`
   ke layar Bayar** (lihat butir 13 — modal lama masih mengeras-kodekan 3 metode), lalu struk
   termal/buka-tutup shift. T5-01 dan T5-02 sudah selesai (butir 10 & 13).
   **Bukti manual/visual T4-03, T4-05, T4-10 tetap milik Lee** (agent tidak bisa memotret layar
   atau mencabut kabel jaringan).
10. **T5-02 RPC `bayar_pesanan` = SELESAI (batch 2026-09-23).** Pintu tunggal uang masuk ada di
    `supabase/migrations/0039_bayar_pesanan.sql` (kunci baris pesanan, pagar peran DI DALAM fungsi,
    kembalian dihitung peladen, idempoten, memajukan pesanan ke `lunas`, jejak audit, kode galat
    **BY-301**). Bukti: `supabase/tes/bayar_pesanan.sql` + `alat/uji-mutasi-0039.py` **6/6 MERAH**;
    suite SQL **81 lulus**. Dasar: `docs/DECISIONS_LOG.md` [Fase 5/2026-09-23].
11. **CACAT FONDASI DITUTUP: urutan rantai hash audit (migrasi `0040_urutan_rantai_audit.sql`).**
    `catatan_audit.waktu` memakai `now()` = waktu mulai transaksi, jadi dua baris audit dalam SATU
    transaksi selalu seri waktunya dan urutan rantai ditentukan UUID acak → pemeriksa rantai bisa
    melaporkan "tautan terputus" padahal tidak ada yang diubah (terukur 7 dari 12 run merah saat uji
    T5-02 ditulis). Kini rantai diurutkan kolom `urutan bigserial` yang diterbitkan peladen; payload
    hash tidak berubah sehingga hash lama tetap sah. Bukti: `supabase/tes/urutan_rantai_audit.sql`
    + `alat/uji-mutasi-0040.py` **4/4 MERAH**. Dasar: `docs/DECISIONS_LOG.md` [Fase 5/2026-09-23].
13. **T5-01 LAYAR BAYAR = SELESAI (batch 2026-09-23, CI `35817220796` SUCCESS).**
    `aplikasi/src/layar/kasir/Bayar.tsx` (komponen murni) + `aplikasi/src/hook/useBayar.ts`
    (kabel data). Metode bayar dari peladen dan hanya yang aktif; uang lewat RPC `bayar_pesanan`;
    kunci idempoten STABIL `bayar-<pesananId>-<urutan>`; kembalian pra-konfirmasi = perkiraan,
    yang sah dari peladen; pembayaran sebagian sah ("Bayar sisa"). Registri aksi
    `kasir.proses_bayar` dipindah dari `hitung_total` ke `bayar_pesanan`; `PETA_UI.md` digenerate
    ulang. Bukti: aplikasi **56 berkas / 305 tes**, `uji-mutasi-app.mjs` **9/9 MERAH** (+4 mutasi).
    **Yang sengaja belum:** `LayarKasir.tsx` belum disambungkan ke layar ini — modal bayar lamanya
    masih mengeras-kodekan `'tunai' | 'qris' | 'kartu'`. Menyambungkan berarti mengubah alur kasir
    (dan `AlurKasirE2E.test.tsx`), jadi sebaiknya diputuskan Lee lebih dulu.
14. **CATATAN LINGKUNGAN (2026-09-23):** sandbox sempat di-reset saat GitHub disambung ulang —
    klon kembali ke commit dasar dan **riwayat lokal hilang** (commit yang belum ter-push lenyap),
    tetapi isi berkas dikembalikan snapshot sebagai perubahan belum di-commit. Pemulihannya:
    `git fetch origin` → `git reset <ujung-remote>` (tanpa menyentuh isi kerja) → commit ulang.
    Klon baru juga **dangkal**: `periksa-paket.py` merah palsu sampai `git fetch --unshallow`
    (CI memakai `fetch-depth: 0`). Dependensi (`npm ci`, `pip install pgserver psycopg`) hilang semua.
    **Pelajaran: push segera setelah bukti lengkap.**
15. **Dua jebakan pemeriksa yang kena di batch ini:** (a) test id di repo ini `data-testid`, bukan
    `data-uji`; (b) `periksa-struktur.py` menolak pola warna heksadesimal di SEMUA `.ts/.tsx`
    termasuk berkas uji — teks `#101` pun kena, pakai `No. 101`.
16. **JARING PENGAMAN PINDAH SESI (2026-09-23):** seluruh pekerjaan sesi ini juga diikat tag
    **`arsip/arena-01a0cb7f-7c30697`** (sudah di-push ke origin). Kalau sandbox di-reset lagi dan
    riwayat lokal hilang, pekerjaan bisa dipulihkan dari tag itu tanpa mengandalkan snapshot:
    `git fetch origin --tags && git checkout -b <cabang> arsip/arena-01a0cb7f-7c30697`.
    Tag ini penanda baca-saja, bukan cabang — jangan dihapus sebelum Lee memutuskan.
12. **Yang diukur dan TIDAK jadi diuji (jangan diulang):** kunci baris `for update` di 0039 tidak bisa
    dibuktikan dengan mutasi karena `picu_pembayaran_jujur` (0012) mengunci baris pesanan yang sama saat
    INSERT — diukur langsung dua koneksi nyata (pgserver): pekerja tetap tertahan di pemicu, bukti
    `pg_stat_activity` wait_event `transactionid`, CONTEXT "while locking tuple (0,4) in relation
    pesanan". Jadi kunci 0039 adalah pagar lapis kedua; alasan lengkap di kepala `alat/uji-mutasi-0039.py`.

### Riwayat penutup §3 (jangan dijadikan rencana)

**PINDAH SESI (2026-09-23, permintaan Lee — tanpa merge):** sesi baru melanjutkan dari `arena/01a0c97c-resto-barokah` (ujung `d923e99`, semua ter-push) lewat pintu **"baca pro.md"**. **Langkah pertama sesi baru: periksa hasil CI `35797734100` (commit `d923e99`) — jangan klaim hijau tanpa bukti run sukses, dan jangan mulai pekerjaan baru sebelum CI terbaca.**

**RENCANA AKTIF (2026-09-22 malam, sesi arena/01a0c97c) — FASE 4 TUNTAS di kode & uji; sisa kecil:**

1. **SELESAI batch ini (jangan dikerjakan ulang):** seluruh Fase 4 — T4-01 `LayarDapur.tsx` (FIFO
   `dikirimPada` waktu peladen + keadaan + cadangan `antrean-lokal` + mode TV/T4-10) · T4-02
   `LayarBar.tsx` + `0033_tujuan_item.sql` · T4-03 `KartuPesanan.tsx` · T4-04 `0032` · T4-05
   `TombolHabis.tsx` + `0035_menu_habis_sumber.sql` (RPC `tandai_habis`, riwayat `menu_habis_riwayat`) ·
   T4-06 `Stok.tsx` + `0036_stok.sql` (RPC `set_stok`) · T4-07 `Opname.tsx` + `0037_opname.sql`
   (RPC `opname_stok`) · T4-08 penanda waktu 10/20 mnt · T4-09 `supabase/tes/anti_dobel.sql` +
   kasus T-409 dua koneksi nyata terkalibrasi di `alat/uji-konkuren.py` · T4-10. Bukti: suite SQL
   **78 berkas lulus**, aplikasi **253 tes lulus**, mutasi 0032/0033/0035/0036/0037 semua merah.
2. **Sisa Fase 4 (butuh keputusan/bukti Lee):** (a) bukti manual/visual — foto T4-03 (baca 2 meter),
   uji dua perangkat manual T4-05 (dapur & kasir), uji cabut-jaringan T4-10; (b) infra e2e
   Playwright (`aplikasi/uji/e2e/dapur.spec.ts` — rencana, belum dibuat) — belum ada pustakanya, butuh izin tambah
   dependensi; (c) **kabel data realtime** (langganan perubahan) untuk antrean KDS & penanda
   habis — saat ini komponen murni menunggu kontainer; (d) registri `DAFTAR_LAYAR` DIKUNCI tes
   lama (tepat 8 layar G1) — layar baru hidup via `App.tsx` tanpa entri registri; perluasan
   registri = perubahan kontrak = butuh putusan Lee.
3. **Lanjut natural berikutnya:** Fase 5 (pembayaran multimode, split bill, struk termal,
   buka/tutup shift) di `docs/ROADMAP.md` — atau kerjakan sisa (2) di atas lebih dulu.
4. **Aturan tetap:** TDD · migrasi 0001–0014 BEKU · kontrak tes lama MENANG (pelajaran
   `layar.test.ts` batch ini) · tanpa warna mentah · `--siapkan` SEBELUM commit penutup ·
   PR #1–#4 jangan merge tanpa keputusan Lee · tanpa deploy/sebar Supabase.

### Arsip riwayat penutup §3 (sejarah — JANGAN dijadikan rencana; nomor tugas lama di bawah bisa tidak sesuai ROADMAP)

> **MARATON FASE 1B, 1C, FASE 2, & FASE 3 KASIR/PESANAN POS SELESAI LENGKAP 100% (2026-09-22):** Seluruh fondasi Fase 1B, 1C, Fase 2, serta seluruh komponen utama Terminal Kasir POS Fase 3 (T3-01 s/d T3-16: Katalog Menu POS dinamis, Keranjang Server-Calculated tanpa manipulasi klien, Pemilih Denah Meja & Tipe Pesanan, Tagihan Terbuka / Open Bill, Kirim ke Dapur, Pembayaran Tunai/QRIS/EDC, Layar Pesanan Pelayan Mobile HP, Riwayat Pesanan Harian, Uji E2E Kasir & Beban Ringan) telah selesai dikerjakan dan diverifikasi penuh. Vitest suite 45 berkas (213 pengujian unit) dan 72 SQL suite 100% LULUS. Gerbang CI 100 gerbang diawasi dua arah.

**Langkah berikutnya (urut):**
1. **Fase 4: Dapur / Kitchen Display System (KDS) & Stok Dasar (T4-01 s/d T4-10)**:
   - `T4-01`: Layar dapur (makanan) dengan urutan FIFO (`aplikasi/src/layar/dapur/LayarDapur.tsx`).
   - `T4-02`: Layar bar/minuman terpisah (stasiun minuman).
   - `T4-03`: Status item pesanan (dimasak → siap saji → diantar) dengan tombol sentuh besar.
   - `T4-04`: Penanda waktu & peringatan pesanan lama (> 15 menit).
   - `T4-05`: Suara notifikasi pesanan masuk & siap.
   - `T4-06` s/d `T4-10`: Void/batal dari dapur berizin supervisor, opname stok harian sederhana, dan sinkronisasi realtime status pesanan.
2. **Fase 5: Pembayaran Multimetode & Tutup Kasir / Shift (M6, M1)**:
   - Pembagian tagihan (split bill per item / per nominal).
   - Cetak struk Bluetooth & format struk termal standar 58mm/80mm.
   - Buka/tutup shift kasir, rekonsiliasi kas laci (cash drawer), dan serah terima shift.

> **MARATON G3 — HANDOFF SESI BARU (2026-09-22):** T-04/A, T-05/B, T-06/C sudah dipanen; pagar 0024/0025/0026, regresi/mutasi, dan penguatan B-F01..B-F09 sudah masuk branch sesi. **Hosted CI `35691286819` untuk commit `be14b40` SUCCESS penuh, termasuk pemeriksa fondasi/history.** Sesi berikutnya melanjutkan pekerjaan teknis agent-owned T1-45/T1-30 dan bantah-balik AUD-2; jangan merge PR, deploy, atau sebar Supabase. A-F02 tentang keterjangkauan PostgREST produksi masih belum terverifikasi dan memerlukan izin Lee sebelum uji/sebar produksi. Rincian ada di `docs/uji/TINDAK_LANJUT_AUD2_2026-09-21.md`.

**RIWAYAT SEBELUM G3 — dua laporan diterima, tindak lanjut TERBUKA:** dua laporan asal `5529eae` dan `b8290b3` disimpan terpisah, byte-identik; format lolos di klon bersih. Sesi ketiga error **diabaikan**, tidak meminta audit/prompt pengganti. Target tetap `09bcb89`; K-2 A-F01/A-F02 BELUM direproduksi integrator, verdict B tidak menutupnya. Antrean 16 temuan, pemilik dan syarat bukti: `docs/uji/TINDAK_LANJUT_AUD2_2026-09-21.md`. T1-30/T1-45 tetap terbuka; tidak merge/deploy/perluasan fitur. Atas izin Lee, alur pengiriman berikutnya memakai locator privat repo/cabang/SHA paket/path, SHA target terpisah, prompt pendek DI CHAT, otomatis commit/push/verifikasi tanpa pengingat dengan index terisolasi + retry fast-forward (`docs/uji/PENGIRIMAN_LAPORAN_AMAN.md`). Cabang/working tree bisa bersama; larangan force/rebase/merge/timpa tetap. Paket beku tidak disunting.

**RIWAYAT SEBELUM LAPORAN MASUK — HASIL BATCH-5 (2026-09-21):** prasyarat CI `35571459040`/`73bd831` hijau sebelum implementasi. Kode akhir `09bcb89` **CI SUCCESS run 35574069120**; periksa-semua lokal LOLOS (65 SQL, 101 uji aplikasi, semua mutasi/concurrency). 0022, PIN pelanggan, sapuan penundaan, T1-30 parsial 0023/ACL mendarat. **BATAS SAAT INI: AUD-2 independen belum dijalankan.** Paket `docs/uji/paket-audit/AUD-2-2026-09-21-SIAP-TEMPEL.md` menargetkan `09bcb89`; jangan menyunting lingkup audit sampai laporan sah masuk. Lee membuka sesi auditor setelah exam (P-06); agent berikutnya ambil laporan (`python3 alat/audit-independen.py --ambil-laporan`), validasi kontrak/independensi lalu bantah-balik, perbaiki temuan sebelum mencentang T1-45. Setelah itu lanjut AST/initplan policy T1-30 sesuai `docs/uji/BUKTI_T130_KEAMANAN_SQL.md`; jangan membuat pengecualian agar CI hijau. Verifikasi/sebar Supabase tetap butuh izin Lee TERPISAH; tidak ada izin merge. Log `_log-sesi/LOG_SESI_2026-09-21_2.md`. Keputusan tertangguh: 0 terbuka / 25 selesai, tetapi implementasi & gerbang tersebut TIDAK selesai. Catatan lama di bawah = sejarah.

**MARATON GELOMBANG 2 DILUNCURKAN 2026-09-21 (sesi integrator arena/01a0c1d1):** T-01/T-02/T-03 DIBERIKAN di `docs/ops/PAPAN_TUGAS.md`; prompt 3 pekerja dikirim DI CHAT (blok siap tempel, REKAM butir 7); base branch sesi pekerja = `arena/01a0c1d1-resto-barokah`. Panen saat Lee bilang `Panen hasil maraton.` (verifikasi sendiri + merge berurutan + baterai tiap merge, AL-16). Sambil menunggu pekerja: lanjut §3 lama di bawah (B F-16/B F-14 lokal dulu).

**PINDAH SESI 2026-09-21 (Lee):** sesi berikutnya = integrator maraton AL-16 dengan base `main` (susul dulu cabang ini!). Maraton gelombang 1 **belum diluncurkan** — 3 tugas siap pakai (T-01/T-02/T-03) ada di `docs/ops/PAPAN_TUGAS.md` (DIBATALKAN sebelum jalan; terbitkan ulang sebagai DIBERIKAN saat Lee bilang `Siapkan maraton kerja sama.`, lalu kirim prompt pekerja DI CHAT sesuai REKAM butir 7).

**MARATON MALAM 2026-09-21 (tuntas; CI HIJAU `6e3ca83`) — baca ini lebih dulu.**

- **Ditutup malam ini:** K F-03 + F-11 §1b (migrasi `0018_perangkat_terdaftar.sql`: PIN hanya dilayani dari perangkat TERDAFTAR — id + kunci bcrypt, jawaban seragam `'Perangkat tidak dikenali.'`, lapis 12×/15 menit keyed `perangkat_id`, perangkat karangan dilayani **0×**; `daftarkan_perangkat`/`cabut_perangkat` izin `kelola_pegawai`) · D F-09 (kembar J F-09) · D F-10 (migrasi `0019_pesan_diskon_jujur.sql`: pesan diskon menunjuk alur nyata). **Temuan terbuka: 12.**
- **T1-24 JANGAN dicentang**: intinya sudah mendarat (0018), sisa DoD = kode pendaftaran sekali pakai + `persetujuan_perangkat` + gating staf via sesi perangkat → lanjut di T1-25/Fase 1C. Lihat catatan status di ROADMAP baris T1-24.
- **Aturan yang TERBUKTI lagi malam ini (AL-15):** migrasi baru yang menulis ulang fungsi membuat harness mutasi migrasi LAMA tumpul-semu — mutasi wajib diarahkan ke `create or replace` TERAKHIR. Sudah terjadi di 0015/0016 (diperbaiki, `berkas_rel=MIG18`). **Kalau kamu menambah migrasi 0020+ yang menulis ulang fungsi PIN/pesanan, periksa semua `alat/uji-mutasi-*.py` dan arahkan mutasinya ke definisi berlaku.**
- **Infra:** GitHub token sandbox bisa kedaluwarsa mid-sesi (push/gh 401) → minta Lee sambungkan ulang di Arena; `.git` lokal bisa di-reset ke `253d129` → pulihkan dengan `git fetch origin arena/01a0b7d1-resto-barokah` + `git reset --mixed <sha remote>` (berkas kerja tidak hilang); `node_modules` bisa terhapus → `npm ci --prefix alat` (+ root bila perlu). pglite HANYA di `alat/package.json`, jangan di root.
- **Auditor ketiga AUD-3-2026-09-20** (target `cbba401`) masih belum kirim laporan — cek `python3 alat/audit-independen.py --ambil-laporan` berkala; jangan tunggu pasif.
- **Rencana berikutnya (urut):** (1) panen laporan auditor ketiga bila masuk; (2) B F-16 (lingkup paket audit menutup berkasnya sendiri) & B F-14 (sapuan isolasi lintas resto) — keduanya lokal, tanpa keputusan Lee; (3) F F-18 (sisa oracle boolean pemasangan PIN) — hati-hati, butuh bukti mutasi; (4) F F-12/F F-13 tetap TERBLOKIR lingkungan (butuh 2 koneksi nyata); (5) I F-17 sisa = keputusan uang Lee (Stop Condition); (6) deploy 0017–0019 ke Supabase nyata butuh "Silahkan Sebar" baru dari Lee.
- **Standing:** PR #2 JANGAN merge; PR #1 untouched; beku migrasi ≤ 0016; setiap balasan ke Lee WAJIB ditutup "Langkah Lee".

**CATATAN PENTING PUTARAN 18aa (2026-09-20) — CI TIDAK BISA MULAI: TAGIHAN AKUN GITHUB (BUTUH LEE).**
**RALAT 18ab (2026-09-20, screenshot billing Lee):** penyebab PASTI = menit gratis organisasi **2.000/2.000 habis** (GitHub Free, tagihan $0 — BUKAN gagal bayar); reset otomatis ±1 Okt; mode hemat + opsi publik/transfer menunggu keputusan Lee (LANGKAH_PEMILIK bagian atas).

Dua run untuk commit `84d3126` **tidak pernah dijalankan**. Anotasi GitHub apa adanya:

> _"The job was not started because recent account payments have failed or your spending limit needs to be
> increased. Please check the 'Billing & plans' section in your settings."_

Jadi **merahnya bukan cacat kode**. Buktinya: seluruh rantai langkah CI (termasuk tiga langkah baru putaran 18z)
dijalankan ulang di **klon bersih** dari GitHub — semuanya LOLOS (npm ci/format/lint/typecheck/test/build/audit,
uji SQL 58 LULUS, harness mutasi app 5/5 + uji-diri, 0012/0014/0015/0016 (11 mutasi), Edge 17/17, dan seluruh pemeriksa Python).

**Dampak yang harus diketahui sesi berikutnya:** (1) tidak ada cap "CI hijau" dari GitHub sampai pulih → gerbang
paket audit (`alat/ci_target.py`, aturan H F-02) akan MENOLAK membuat paket baru (itu perilaku benar, fail-closed);
(2) alur **"Sebar skema"** juga tidak akan jalan. Langkah Lee ada di `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`
(bagian paling atas) + butir `T-024` di `docs/TERTANGGUH.md`.

**Langkah berikutnya (urut):** lanjut maraton **tanpa** menunggu CI (verifikasi lokal = rantai yang sama) →
probe **F F-12** (concurrency) → I F-13/F-14/F-15/F-16 (probe PIN) → I F-02 & H F-09 (kupon PIN + CORS) →
H F-07 (kolom non-uang pesanan) → sisa K-3 → setelah tagihan GitHub beres: paket audit/review baru + "Sebar skema".

**PUTARAN 18z (2026-09-20) — TIGA TEMUAN SATU KELAS DITUTUP: "ALAT BILANG AMAN, PADAHAL BELUM TERBUKTI".**

- **F F-14 & I F-05 (dua laporan, satu cacat) — sambungan Supabase.** `ujiSambungan()` dulu hanya melihat
  kesehatan Auth: Auth 200 + jalur data 401/404/500 tetap dilaporkan "berhasil". Kini `ok = jalur.auth &&
jalur.data`, status tiap jalur dilaporkan di bidang `jalur`, dan pesan gagal menyebut jalur + HTTP-nya.
  Ujinya dulu memberi **satu status untuk dua jalur** — kombinasi yang dicari auditor memang mustahil teruji.
  Sekarang ada `jawabJalur({sehat, data})` + 7 kasus (401/403/500/404/503, jalur data tak terhubung, 206).
  Mutasi `ok` dikembalikan melihat Auth saja → **7 uji MERAH**.
- **I F-06 — kegagalan Storage di fondasi tema.** Penjagaan lama hanya mengelilingi PENGAMBILAN objek
  `localStorage`; `getItem`/`setItem` sendiri bisa melempar (`SecurityError` izin ditolak, `QuotaExceededError`
  penuh) sehingga effect React saat ganti tema bisa putus. Kini `bacaKunci()`/`tulisKunci()` menjaga
  pemanggilannya, `simpanPilihan()` **jujur** mengembalikan `false`, dan tema tetap berganti di layar.
  Mutasi penjagaan dicabut → **2 uji MERAH**.
- **Pagar permanen baru `aplikasi/alat/uji-mutasi-app.mjs`** (kelas yang sama dengan `alat/uji-mutasi-0015.py`
  untuk SQL): salinan `aplikasi/` di folder sementara → kontrol hijau → 5 mutasi perilaku WAJIB MERAH.
  **Merah PALSU ditolak:** pelajaran nyata sesi ini, opsi `--reporter=basic` sudah tidak ada di Vitest 5 sehingga
  semua mutasi sempat "merah" padahal ujinya tidak pernah jalan — harness kini hanya menerima merah yang benar-benar
  memuat kegagalan uji (bidang `merahSah`). `--uji-diri` 2/2 (pola mutasi salah ditolak · uji yang dilemahkan
  terdeteksi). Ikut CI + `periksa-semua.sh` + terdaftar gerbang wajib.

**Angka:** uji aplikasi **87 → 100** (13 uji baru). **Temuan terlacak: 86 → 53 DITUTUP · 28 TERBUKA** (baris penutup: 80; I F-05 ·
I F-06 · F F-14 ditutup di putaran ini).

**Langkah berikutnya (urut):** probe **F F-12** (concurrency hitung ulang — belum bisa di PGlite, catat jujur) →
I F-13/F-14/F-15/F-16 (probe PIN: tiga dugaan + satu terverifikasi) → I F-02 & H F-09 (kupon PIN lewat Edge + CORS)
→ H F-07 (kolom non-uang pesanan setelah lunas) → I F-08 (buku darurat) → sisa K-3 (PR-05…09, PR-13, PR-14) →
**hubungi Lee** untuk "Sebar skema".

**PUTARAN 18y (2026-09-20) — NAMA UJI TIDAK BOLEH LEBIH KUAT DARIPADA YANG DIUJI (I F-19 tuntas).**

Uji bernama `'memanggil onUbah saat diisi'` hanya merender HTML (SSR), memeriksa `type="text"`, lalu
**memastikan callback TIDAK terpanggil**. Artinya handler `onChange` yang tidak tersambung ke apa pun pun
akan hijau — "86 uji terbaca" sebagian tidak membuktikan apa yang namanya janjikan.

- **Penjaga mesin (baru)** di `aplikasi/alat/periksa-uji.py` (aturan 3): uji yang namanya menjanjikan interaksi
  ("saat diisi", "saat diklik", "memanggil on…") WAJIB memicu kejadian (`fireEvent`/`userEvent`/`dispatchEvent`/
  `.click(`/`.focus(`/`.type(`) — kalau tidak, GAGAL dengan **berkas:baris**. Sebelum ujinya diperbaiki, penjaga
  ini **langsung menunjuk cacat aslinya** (`aplikasi/src/komponen/komponen.test.tsx:145`).
- **Ujinya diperbaiki**: berkas uji memakai `// @vitest-environment jsdom` + `@testing-library/react`; isian
  benar-benar diisi (`fireEvent.change` → nilai `Budi`) dan `onUbah` diperiksa **nilainya**, plus satu uji nilai
  terkendali. Uji markup lain di berkas itu tetap SSR.
- **Bukti uji baru tidak tumpul (mutasi):** handler dilepas (`onChange` → kosong) → **1 uji GAGAL**; handler
  mengirim nilai salah (`+ 'X'`) → **1 uji GAGAL**; dipulihkan → **18 uji LULUS**. Berkas `KolomIsian.tsx`
  dikembalikan utuh (diff kosong).
- `--uji-diri` **5 kasus** (uji berjanji tanpa tindakan ditolak · dua kontrol diterima · `vitest.config.ts`
  dihapus ditolak), ikut CI + `periksa-semua.sh`, terdaftar gerbang wajib + 1 mutasi baru.

**Langkah berikutnya (urut):** **I F-05/I F-06** (klien sambungan & Storage tema) + **F F-14** (ujiSambungan bisa
hijau palsu) → probe **F F-12** → I F-13/F-14/F-15/F-16 (probe PIN) → I F-02/H F-09 (CORS & kupon PIN) →
sisa K-3 (PR-05…09, PR-13, PR-14) → **hubungi Lee** untuk "Sebar skema".

**PUTARAN 18x (2026-09-20) — VERSI NODE YANG DIKLANKAN DITURUNKAN DARI PUSTAKA TERKUNCI (I F-21 tuntas).**

Aplikasi mengiklankan `engines.node: ">=20"` (README: "Node.js 22, minimal 20"), padahal pustaka yang
terkunci menuntut lebih: `@supabase/supabase-js` **>=22.0.0** dan `vitest` **^22.12.0**. Pemakai yang
menuruti README bisa memasang Node yang tidak didukung pustaka wajib — iklan yang salah arah.

Yang dikerjakan:

- batas minimum kini **dihitung mesin** dari `aplikasi/package-lock.json` → **`>=22.12.0`**; entri yang
  bertanda `optional` (mis. `@napi-rs/lzma-*` bawaan rollup) sengaja TIDAK dihitung, karena npm melewatinya;
- `aplikasi/README.md` menulis `22.12+` dan ketiga alur GitHub memakai `node-version: '22.12.0'` — jadi
  **CI menguji tepat versi minimum yang diiklankan**, bukan versi lain;
- penjaga baru `aplikasi/alat/periksa-node.py` menolak: iklan lebih rendah / bentuk bukan `>=X` / README
  berbeda / lock tanpa `engines` (gagal-tertutup) / alur ber-`node-version` di bawah batas (bentuk `'22'`
  diartikan 22.0.0, jadi tidak cukup). `--uji-diri` **9 kasus**: 1 salinan utuh diterima, 7 mutasi ditolak,
  1 kontrol (entri opsional menuntut Node 30) tetap diterima;
- ikut `aplikasi/alat/periksa-semua.sh` dan CI; terdaftar sebagai gerbang wajib + 1 mutasi baru
  ("langkah pemeriksa versi Node dihapus → ditolak").

**Batas jujur:** yang dijamin adalah keselarasan iklan↔lock dan bahwa CI berjalan di versi minimum.
Ruang kerja sesi ini ber-Node 22.22.3, jadi "npm ci berhasil di 22.12.0" dibuktikan oleh CI.

**Langkah berikutnya (urut):** **I F-19** (uji bernama "memanggil onUbah saat diisi" tidak pernah mengisi input) →
**I F-05/I F-06** (klien sambungan & Storage tema) + **F F-14** (ujiSambungan bisa hijau palsu) → probe **F F-12** →
I F-13/F-14/F-15/F-16 (probe PIN) → sisa K-3 (PR-05…09, PR-13, PR-14) → **hubungi Lee** untuk "Sebar skema".

**PUTARAN 18w (2026-09-20) — BATAS EDGE FUNCTION DIUJI SUNGGUHAN (I F-07 tuntas).**

Sebelum ini berkas Edge hanya dijaga pemeriksa **teks** — tidak ada satu pun pengujian yang pernah
**menjalankan** handler-nya, jadi cacat batas lolos tanpa jejak:

- JSON `null` → `TypeError` (kasir melihat kegagalan platform, bukan 400 berbahasa Indonesia);
- UUID "36 tanda minus" lolos regex longgar `^[0-9a-f-]{36}$` → diteruskan ke database;
- jaringan putus pada `fetch` dan jawaban upstream yang bukan JSON → `Error`/`SyntaxError` tak tertangkap.

Dua-duanya ditutup: **perbaikannya** (badan permintaan diperiksa · UUID diperiksa lengkap sebelum
menyentuh database · satu bentuk jawaban gagal terkendali untuk semua gangguan teknis) dan
**penjaganya** — `alat/uji-edge-pin.mjs`:

- mengubah berkas ASLI `supabase/functions/verifikasi_pin/index.ts` TS → JS memakai `esbuild`
  (bukan menulis ulang tangan), lalu menjalankannya di `node:vm` **tanpa jaringan**
  (`Response`/`Request` milik Node, `Deno.serve`/`Deno.env`/`fetch` dikendalikan uji);
- 17 kasus batas (E01–E17), termasuk "PIN tidak pernah muncul di jawaban mana pun";
- **MERAH di 4 kasus sebelum perbaikan** (bukti uji ini tidak tumpul), hijau sesudahnya;
- jalan di `aplikasi/alat/periksa-semua.sh` dan CI (langkah tersendiri setelah `npm ci --prefix alat`;
  `esbuild` kini devDependency `alat/package.json`).
- Catatan kecil: fixture "PIN tidak lagi dibaca dari badan permintaan" di `alat/periksa-fungsi-pin.py`
  dibuat tahan penamaan variabel (refactor `isi` → `badan` bukan cacat).

**Langkah berikutnya (urut):** **I F-21** (minimum Node vs lockfile) → **I F-19** (uji yang tidak mengisi input) →
**I F-05/I F-06** (klien sambungan & Storage tema) + F F-14 → I F-13/F-14/F-15/F-16 (probe PIN) → sisa K-3/K-4 →
tutup batch mekanisme → **hubungi Lee** untuk "Sebar skema".

**CATATAN CI (2026-09-20, dua kali):** **(1)** CI commit `a2d6b16` MERAH — satu rujukan mati di bukti penutup I F-09 (`aplikasi/alat/pratinjau.sh` padahal berkasnya `aplikasi/alat/pratinjau.sh`), ditangkap `python3 alat/periksa-rujukan.py` (kelas yang sama dengan H F-08: jalur bukti wajib bisa dibuka dari akar repo); diperbaiki di `4ddb905`. **(2)** CI commit `17cefb5` (batch I F-07) MERAH — langkah CI BARU `node alat/uji-edge-pin.mjs` ditolak `python3 alat/periksa-gerbang-ci.py` karena belum terdaftar di daftar gerbang wajib; memang begitu aturannya (dua arah: tiap perintah CI wajib dikenal DAN tiap gerbang wajib wajib ada). Ditutup dengan mendaftarkannya sebagai gerbang ke-55 + satu mutasi uji-diri baru ("langkah uji batas Edge dihapus → ditolak"). Seluruh rantai pemeriksa CI dijalankan ulang lokal sebelum push: hijau.

**CATATAN CI (2026-09-20):** CI commit `a2d6b16` MERAH — sebabnya satu rujukan mati di bukti penutup I F-09 (`aplikasi/alat/pratinjau.sh`, seharusnya `aplikasi/alat/pratinjau.sh`), ditangkap `python3 alat/periksa-rujukan.py` (kelas yang sama dengan H F-08: jalur bukti wajib bisa dibuka dari akar repo). Sudah diperbaiki dan seluruh rantai pemeriksa CI dijalankan ulang lokal (hijau) sebelum push.

**PUTARAN 18v (2026-09-20) — BATCH "DOKUMEN JUJUR": 8 TEMUAN + 4 DUPLIKAT DITUTUP (47 ditutup · 34 terbuka).**

Dokumen yang menjanjikan lebih dari kenyataan, atau aturan yang saling bertabrakan, dibereskan sekaligus:

- **H F-06** `docs/KEAMANAN.md`: `hitung_total()` tidak lagi disebut "belum mendarat" — versi awalnya sudah hidup di
  `supabase/migrations/0014_penutup_celah_putaran13.sql`; yang belum: pembulatan (T1-16) & suite 12 uji uang.
- **H F-08** bukti T0-03 memakai jalur lengkap `aplikasi/src/lib/tema.ts`.
- **H F-10** klasifikasi penanda-palsu diberi justifikasi jujur: nyata di level DB, tetapi eksploitasi produksi
  menuntut koneksi SQL langsung (PostgREST tak mengizinkan `pg_catalog`); pagar 0015 tetap.
- **I F-09** `aplikasi/README.md` tidak lagi mencampur dua folder kerja (pemulihan: `bash aplikasi/alat/pratinjau.sh` dari dalam
  `aplikasi/`, dengan catatan bentuk akar; bagian pemeriksa ditandai "dari AKAR repo").
- **I F-10** resep audit: auditor **wajib kembali ke cabang sesinya** (`git symbolic-ref --short HEAD`) dan push eksplisit
  `git push origin HEAD:refs/heads/<CABANG-SESIMU>` sebelum menyerahkan laporan (blok kanonik & buku induk tetap identik).
- **I F-11** janji rahasia GitHub dikoreksi: terenkripsi ≠ tak terbaca (siapa pun yang boleh mengubah workflow bisa membacanya)
  → least privilege, TTL, jaga akses tulis repo.
- **I F-12** **satu aturan pindah sesi**: melihat/melanjutkan pekerjaan TIDAK perlu merge (`fetch` + `merge --ff-only`),
  merge PR ke `main` tetap keputusan Lee. Pendampingnya: `docs/ops/SIAP_AKUN_PEMILIK.md` disegarkan dan prasyarat PGlite
  (`npm ci --prefix alat`) kini tertulis di handoff.
- **D F-06** ROADMAP T1-15/T1-17 diberi catatan silang: fungsinya sudah hidup di 0014/0015 — **jangan tulis rumus kedua**.
- Duplikat yang obatnya sudah mendarat ikut ditutup: **B F-09 · B F-17 · D F-03 · D F-04** (paket wajib menunjuk induk commit
  sendiri · gerbang CI hijau · pemecah artefak).

**Langkah berikutnya (urut):** **I F-07** (boundary Edge: JSON null & galat upstream) → **I F-21** (minimum Node vs lockfile) →
**I F-19** (uji yang tidak mengisi input) → **I F-05/I F-06** (klien sambungan & Storage tema) + F F-14 → sisa K-3/K-4 →
tutup batch mekanisme → **hubungi Lee** untuk "Sebar skema".

**PUTARAN 18u (2026-09-20) — H F-05 & I F-20 TUNTAS: PEMBUAT PAKET BERHENTI MENUDUH PERINTAH/POLA SEBAGAI "BERKAS HILANG".**

Paket audit dulu menyuruh auditor mencari artefak yang sebenarnya NYATA, lengkap dengan label
"sudah [x] — berkasnya TIDAK ADA: laporkan!":

- `python3 alat/periksa-roadmap.py` → itu **perintah**, bukan berkas;
- `aplikasi/src/komponen/*.tsx` → itu **pola** yang cocok 13 berkas nyata;
- `src/lib/tema.ts` → itu **jalur relatif** folder `aplikasi/` (= `aplikasi/src/lib/tema.ts`).

Dua mesin tertangkap cacat yang sama: pembuat paket `alat/audit-independen.py` DAN pemeriksa daftar
temuan `alat/periksa-temuan-audit.py` (yang terakhir menolak bukti penutup berpola/jalur-relatif).

- Pemecah artefak bersama **`alat/artefak.py`** → `pisah_artefak()`: **berkas · perintah · pola ·
  hilang** (plus `pola-kosong` & `perintah-hilang`); jalur relatif folder kerja diselesaikan,
  rujukan baris (`…sql:120`) dibuang, dan pola dihitung berapa berkas nyata yang cocok.
- Paket audit sekarang menaruh perintah di bagian tersendiri **"1a. Perintah bukti"** — auditor
  MALAH memakainya; baris "TIDAK ADA" dihitung sekali per jalur+tugas (dulu duplikat = baris terpisah).
- Bukti: paket baru pada pohon sekarang → **0 baris** tuduhan palsu (dari 13) sementara artefak yang
  benar-benar hilang tetap dilaporkan; `--uji-diri` +10 contoh (persis contoh dari temuan ini) dan
  +2 kasus di `alat/periksa-temuan-audit.py` (pola/jalur relatif diterima · yang hilang tetap ditolak).

**Langkah berikutnya (urut):** sisa §1d/§1e (K-3/K-4) → **K-3** (PR-05…09, PR-13, PR-14) → **K-4** → tutup batch mekanisme →
**hubungi Lee** untuk "Sebar skema" (`0015` ke DB nyata) → `0015` dibekukan. Ingin mempercepat: paket audit berikutnya
sudah bisa dibuat (`python3 alat/audit-independen.py --paket AUD-3 --semua`) karena CI commit ini hijau.

**PUTARAN 18t (2026-09-20) — I F-03 & I F-04 TUNTAS: DUA "GERBANG PALSU" DITUTUP, SATU BUKTI PALSU HISTORIS KETEMU.**

- **I F-03 — penjaga PIN tumpul** (`alat/periksa-fungsi-pin.py`): dulu hanya mencari `console.` / `pin_hash` / `setItem`,
  sehingga **balasan yang mengembalikan PIN** (`{ …, pin: pin }`) dan **log lewat tanda kurung siku** (`console['log'](pin)`)
  lolos 9/9 exit 0. Sekarang: setiap bentuk `console` ditolak (titik, bracket, alias, `globalThis.console`) + `Deno.stdout/stderr`;
  variabel PIN **dibatasi ke tiga jalur sah** (dibaca dari badan permintaan · diperiksa bentuknya · diteruskan ke RPC).
  Jalur "teruskan" melekat pada **rentang panggilan `fetch(... rpc/ ...)`**, bukan pada kata kunci — jadi `p_pin: pin` di balasan
  tetap ditolak. Tambah aturan "PIN dibaca dari badan permintaan". `--uji-diri` 9 kasus (1 sumber sah + 8 contoh cacat, tiap
  tolakan harus DATANG DARI aturan yang benar) dan ikut berjalan di `periksa-semua.sh`.
- **I F-04 — penilai mutasi menerima crash sebagai bukti** (`alat/uji-mutasi-0015.py`): `lulus = (kode != 0)` diganti penilai
  bersama `alat/klasifikasi_mutasi.py` → HIJAU / **MERAH-PAGAR** (asersi `HARAPAN TIDAK TERPENUHI` / `SEBAB PENOLAKAN BUKAN YANG
DIHARAPKAN` di berkas `supabase/tes/`) / **RUSAK** (crash, sintaks, migrasi gagal terpasang, merah bukan asersi). Hanya
  MERAH-PAGAR yang dihitung bukti; RUSAK membuat harness GAGAL, bukan "MERAH (benar)".
- **Hasil sampingan yang penting:** pengetatan itu **langsung menemukan bukti palsu historis** — mutasi "pagar dikembalikan ke
  versi lama (K-1)" ternyata **gagal dikompilasi** (`"v_jejak" is not a known variable`, deklarasi hanya ditambahkan di kemunculan
  pertama fungsi) dan dulu dilaporkan "MERAH (benar)". Sudah diperbaiki (deklarasi di semua kemunculan) dan **benar-benar
  memerahkan uji K-1**. Seluruh **26 mutasi + kontrol penutup** kini LOLOS sebagai MERAH-PAGAR.
- Bukti: `python3 alat/periksa-fungsi-pin.py` (14/14) · `--uji-diri` (11 kasus) · `python3 alat/uji-mutasi-0015.py` (LOLOS) ·
  `--uji-diri` (10 kasus) · `bash aplikasi/alat/periksa-semua.sh`.

**Langkah berikutnya (urut):** **H F-05 / I F-20** (pembuat paket menyebut perintah/glob sebagai "berkas hilang") → sisa §1d/§1e
dan K-3/K-4 → tutup batch mekanisme → **hubungi Lee** untuk "Sebar skema" (`0015` ke DB nyata).

**PUTARAN 18s (2026-09-20) — H F-02 TUNTAS: PAKET WAJIB MENUNJUK COMMIT BER-CI HIJAU.**

Bukti masalahnya nyata: paket AUD-3 2026-09-19 menargetkan `4830b5a` yang dua run CI-nya **cancelled**
(ditimpa push berikutnya) — auditor memeriksa pohon yang tidak pernah lewat gerbang otomatis.

- `alat/ci_target.py` (baru): `status_ci(sha)` bertanya ke GitHub Actions; mengembalikan `bisa/hijau/run/rincian`.
  **Tidak bisa diperiksa ≠ hijau** (ketidak-tahuan tidak dibaca sebagai bukti aman). SHA pendek diperluas otomatis.
- Gerbang di pembuat paket: `alat/audit-independen.py --paket` & `alat/review-pr.py --siapkan` **MENOLAK** bila CI commit target belum hijau;
  ada jalan pengecualian `--izinkan-ci-belum-hijau "<alasan>"` yang **tercetak di paket** (izin pemilik, bukan diam-diam).
- Paket menulis `- **CI commit target:** success (run …)`; penjaga `alat/periksa-paket.py` aturan **F-02**:
  paket bertanggal ≥ 2026-09-20 wajib punya baris itu, klaim "success" **diperiksa ulang ke GitHub**, dan "belum hijau" tanpa izin pemilik ditolak
  (+2 kasus `--uji-diri`, termasuk mencari commit non-hijau sungguhan lalu membuktikan klaim palsu ditolak).

**Cara pakai saat mau menerbitkan paket berikutnya:** pilih commit yang CI-nya SUDAH hijau (atau tunggu), lalu
`python3 alat/audit-independen.py --paket AUD-3 --semua`. Kalau commit sekarang belum hijau, alat akan bilang.

**Langkah berikutnya (urut):** **I F-04** (classifier mutasi menerima crash sebagai "pagar bekerja") → **I F-03** (pemeriksa PIN tumpul/bracket)
→ **H F-05 / I F-20** (pembuat paket menyebut perintah/glob sebagai berkas hilang) → sisa §1d/§1e + K-3/K-4 → tutup batch lalu **hubungi Lee** untuk sebar skema.

**PUTARAN 18r (2026-09-20) — H F-01 TUNTAS: KATALOG CACAT KALIBRASI KELUAR DARI REPO (izin Lee).**

Izin Lee: _"Aku ikut yang terbaik menurut kamu. Klo sebaiknya dikeluarkan, silahkan keluarkan."_

- `/home/user/.kalibrasi/kalibrasi-cacat.json` (dipensiunkan ke luar repo — H F-01) (pasangan cari/ganti = **kunci jawaban**) **dipindah ke luar repo** →
  `KALIBRASI_DIR` (baku `/home/user/.kalibrasi/kalibrasi-cacat.json`); berjejak `docs/uji/BERKAS_PENSIUN.md` baris #2 + `docs/DECISIONS_LOG.md`.
- Salinan kalibrasi jalur mesin: `git archive` + satu commit bersih, katalog **dikeluarkan**, `pastikan_salinan_bersih()` menolak
  salinan yang membawa katalog/kunci/riwayat/perubahan belum-di-commit.
- Alat **gagal-tertutup**: katalog hanya dibaca dari luar repo (jalur mesin & review PR).
- Penjaga: `alat/periksa-kunci-kalibrasi.py` aturan **A2** (katalog tidak boleh ada di repo) + F + G → `--uji-diri` **13 kasus** semua menolak.
- Bonus mekanisme: `alat/periksa-rujukan.py` & `alat/periksa-temuan-audit.py` kini **mengakui daftar pensiun** (riwayat jujur ≠ rujukan mati);
  `periksa-temuan-audit.py` mengambil token pertama rujukan sehingga sel bukti boleh memuat perintah.
- Catatan lingkungan: `alat/node_modules` & `aplikasi/node_modules` **tidak ikut snapshot** sandbox → setelah ruang kerja pulih,
  jalankan `npm ci --prefix alat` (dan `--prefix aplikasi`) dulu sebelum uji SQL/mutasi.

**Langkah berikutnya (urut) — maraton lanjut tanpa menunggu Lee:**

1. **H F-02** (K-3): paket audit/review wajib menunjuk commit yang CI-nya **sudah hijau** — bukti di paket + penjaga/`T1-44`.
2. **I F-04 & I F-03** (K-3): classifier mutasi menganggap crash sebagai bukti pagar bekerja; pemeriksa PIN tumpul terhadap bracket.
3. **H F-05 / I F-20** (K-3): pembuat paket menyebut perintah/glob sebagai "berkas hilang" (tabel §1b memuat baris palsu).
4. Sisanya dari §1d/§1e + temuan lama K-3/K-4; yang **DUGAAN** wajib diprobe dulu.
5. Setelah temuan MEKANISME habis → tutup batch, **hubungi Lee** untuk menekan "Sebar skema" (menyebar `0015` ke database nyata), lalu `0015` dibekukan.

**PUTARAN 18q (2026-09-20) — KUNCI KALIBRASI TIDAK BISA LAGI DICONTEK (audit H F-01); SATU KEPUTUSAN MENUNGGU LEE.**

Bantah-balik temuan **H F-01** (K-2) membuktikan cacatnya **lebih parah dari dugaan laporan**:

1. Salinan auditor jalur mesin dulu dibuat `git worktree add` → di dalam salinan itu `git diff`/`git show` **langsung memperlihatkan
   baris mana yang ditanami cacat** (cacat ditanam sebagai perubahan belum-di-commit).
2. Berkas katalog `/home/user/.kalibrasi/kalibrasi-cacat.json` (dipensiunkan ke luar repo — H F-01) (pasangan cari/ganti = daftar jawaban) ikut tersalin ke salinan auditor.
3. Jalur review PR menyematkan diff ke paket, dan peninjau bisa mencocokkannya dengan katalog yang ada di repo.

**Sudah diperbaiki (kode + penjaga + dokumen):**

- `alat/audit-independen.py` — salinan kalibrasi dibuat lewat `git archive` + `git init` + **satu commit bersih**; katalog dikeluarkan dari salinan;
  fungsi baru `pastikan_salinan_bersih()` menolak salinan yang masih membawa katalog/berkas kunci atau perubahan belum di-commit.
- `alat/review-pr.py` — katalog **hanya** dibaca dari luar repo (`KALIBRASI_DIR`, baku `/home/user/.kalibrasi`); bila katalog masih di dalam repo,
  perintah **GAGAL-tertutup** dengan instruksi jelas (tidak membuat bahan yang bisa dicocokkan).
- `alat/periksa-kunci-kalibrasi.py` — aturan **F** (salinan kalibrasi bersih) & **G** (katalog review PR dari luar repo) + **3 mutasi uji-diri baru** (12 kasus, semua menolak).
- Dokumen: `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7 · `docs/uji/kalibrasi/CARA-PAKAI.md` · `docs/uji/AUDIT_RIWAYAT.md` (status H F-01) ·
  `docs/uji/TEMUAN_LUAR_CAKUPAN_REVIEW.md` (L-03).

**MENUNGGU KEPUTUSAN LEE (satu langkah, tidak bisa agent putuskan sendiri):** memindahkan berkas katalog cacat ke luar repo
(`/home/user/.kalibrasi/kalibrasi-cacat.json` (dipensiunkan ke luar repo — H F-01) → `/home/user/.kalibrasi/kalibrasi-cacat.json`) + barisnya di daftar pensiun `docs/uji/BERKAS_PENSIUN.md`
(aturan daftar itu mewajibkan keputusan Lee). Selama belum dipindah: **jalur kalibrasi review PR tidak bisa dipakai** (sengaja),
sementara jalur mesin sudah aman dan tetap jalan.

**Langkah berikutnya:** (1) tunggu jawaban Lee soal pemindahan katalog; (2) lanjut temuan mekanisme lain — **H F-02** (paket audit
menargetkan commit yang CI-nya belum hijau → penjaga paket wajib menolak) dan **I F-20/I F-04/I F-03** (alat audit sendiri);
(3) bantah-balik sisa temuan laporan H & I (yang DUGAAN wajib diprobe dulu).

**PUTARAN 18p (2026-09-20) — DUA LAPORAN AUDIT LANJUTAN MASUK: 31 TEMUAN BARU TERDAFTAR (2 sudah tertutup).**

Ambil laporan: `python3 alat/audit-independen.py --ambil-laporan` (idempoten) menemukan **5 berkas** — 2 laporan baru + 3 versi lama
yang tertimpa (diselamatkan otomatis). Kontrak mesin:

- **Laporan H** = `docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbcb.md` (sesi `arena/01a0bbcb`): 10 temuan, kalibrasi **12/12**,
  **DITOLAK MESIN** (4 alasan: label grup cakupan diparafrase) → **isinya tetap dipakai**, tiap temuan dapat baris di §1d.
- **Laporan I** = `docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2-907e29e.md` (ronde kedua sesi `01a0bbd2`): 21 temuan,
  kalibrasi 5/5, cakupan 442/480, **LOLOS KONTRAK** → baris penutup di §1e.

Keduanya mengaudit commit `4830b5a` (snapshot yang sama dengan laporan F). 31 temuan sudah **terdaftar** dan dilacak
`alat/periksa-temuan-audit.py` (kunci H & I; ringkasan alat dibuat **data-driven** supaya laporan berikutnya cukup ditambah di kamus,
tanpa menyunting baris cetak). Daftar penutup: **86 temuan terlacak · 29 ditutup · 52 terbuka**.

**Sudah tertutup tanpa pekerjaan baru** (perbaikannya mendarat sesudah commit yang diaudit, jadi auditor tak bisa melihatnya):

- **I F-01 (K-1)** dasar pajak/service sebelum diskon → ditutup bagian 6 `0015` + uji `supabase/tes/urutan_uang.sql`.
- **I F-13 (K-1 dugaan)** oracle peran lintas penyewa = tumpang-tindih F-11 laporan F → ditutup bagian 10 `0015` + uji `supabase/tes/pin_helper_pribadi.sql`.
- **I F-17 (K-1 dugaan)** hitung ulang pesanan lunas → **DITUTUP sebagian**; sisa jalurnya (pembayaran sudah ada lalu item diturunkan) masih `T1-45`.

**Prioritas yang menyerang mekanisme kita sendiri** (jangan diabaikan — ini kelas cacat yang membuat audit kehilangan nilainya):

1. **H F-01** kunci kalibrasi masih terbaca dari dalam repo (penutupan D F-05 belum tuntas) → `T1-44`.
2. **H F-02 / I F-20 / I F-04 / I F-03** paket audit menargetkan commit ber-CI-belum-hijau, perintah/glob disebut "berkas hilang",
   classifier mutasi menerima crash sebagai "bukti pagar bekerja", dan pemeriksa PIN tumpul (bracket) → `T1-44`.
3. **H F-03** (pemilik): database nyata baru memuat `0001`–`0014`; `0015` **belum tersebar**. Klaim "tidak ada langkah menunggu"
   sudah dikoreksi di `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`. **Penyebaran menunggu batch selesai** — berkas migrasi yang sudah masuk
   database tidak boleh diubah lagi, jadi jangan sebar `0015` di tengah maraton.

**Langkah berikutnya (urut):**

1. Bantah-balik temuan K-2/K-3 dulu (yang terverifikasi) lalu yang **DUGAAN** wajib diprobe sebelum disebut nyata — daftar lengkap ada di §1d/§1e.
2. Kembali melanjutkan penutupan sisa laporan F (F-07 → `T1-13`, F-09 → `T8-01`) + 16 temuan lama K-3/K-4.
3. Kalau sudah tidak ada temuan MEKANISME yang tersisa → batch T1-45 ditutup, minta Lee menekan "Sebar skema" (tindakan pemilik), lalu `0015` **dibekukan** dan pekerjaan berikutnya pindah ke `0016+`.

**PUTARAN 18o (2026-09-20) — BANTUAN-BALIK 3 TEMUAN AUDIT F: F-10 & F-11 NYATA (DITUTUP), F-13 DIREDAM (TETAP TERBUKA).**

Pola yang dipakai: **bantah-balik dulu, baru memperbaiki** — tiga probe baru di
`docs/uji/audit/probe-2026-09-20/` meng-ASERSI keadaan yang salah; selama probe masih LULUS, cacatnya nyata.

1. **F-10 (K-2) — NYATA, DITUTUP (bagian 11 `supabase/migrations/0015_penutup_celah_putaran16.sql`):**
   `aud-3-f10-admin-cabang-izin.sql` LULUS = admin Cabang Pusat membaca izin pegawai Cabang Dua
   (8 baris = seluruh penyewa). Kontrak (`docs/TECH_SPEC.md` §294 · `docs/PRD.md` · `docs/DISCOVERY.md` 53) berkata
   admin cabang **hanya cabangnya** → policy `izin_pilih` diselaraskan ke kontrak **dan** ke pola policy
   `pengguna_pilih` (satu aturan). Uji `supabase/tes/rls_pengguna.sql` §5 dikoreksi (dulu mengunci 8 baris).
   Probe kini **GAGAL** = cacat hilang.
2. **F-11 (K-2) — NYATA, DITUTUP (bagian 10):** `aud-3-f11-helper-pin.sql` LULUS = kasir memanggil
   `peran_lebih_tinggi(<uuid siapa pun>, <uuid siapa pun>)` sebagai oracle hierarki (termasuk lintas resto).
   Perbaikan dua lapis: **hak execute klien dicabut** + **`p_pemanggil` dipakukan ke `auth.uid()`**.
   Uji `supabase/tes/pin_helper_pribadi.sql` (termasuk pembungkus SECURITY DEFINER = "jalur baru tanpa
   pembungkus identitas") + kontrol owner tetap boleh mengganti PIN bawahan. Probe kini **GAGAL**.
3. **F-13 (K-2, DUGAAN) — DIREDAM, BELUM DITUTUP (bagian 10b):** `nomor_pesanan_berikutnya()` mengambil nomor
   di bawah `pg_advisory_xact_lock` per (cabang, tanggal) dan kembali **VOLATILE**. Pembuktian yang diminta
   laporan adalah uji dua transaksi nyata; lingkungan uji proyek (PGlite, satu koneksi) belum bisa menjalankannya
   → temuan **tetap TERBUKA** dengan catatan jujur (jangan dicap selesai). Yang dijaga mesin: sifat serialisasinya
   (`supabase/tes/nomor_pesanan_kunci.sql` + 2 mutasi wajib-MERAH). Sama untuk **F-12** (uang) — sudah diredam
   `for update` di bagian 6, uji concurrency menyusul.

**Bukti mesin batch ini:** suite SQL `node alat/uji-sql.mjs` **53 LULUS · 0 GAGAL** · `python3 alat/uji-mutasi-0015.py`
**25 mutasi wajib MERAH + kontrol hijau** (kini termasuk F-10, F-11, F-13) · daftar temuan `docs/uji/AUDIT_RIWAYAT.md`
§1c **26 DITUTUP / 23 TERBUKA** · `docs/DECISIONS_LOG.md` 3 entri baru · `docs/ROADMAP.md` progres bagian 10–11.

**Langkah berikutnya (urut):**

1. **Bantah-balik sisa temuan audit F** — yang masih **TERBUKA**: F-07 (`T1-13`, tabel `catatan_audit` memang belum
   dibangun), F-09 (`T8-01`, kontrak privasi pelanggan belum ada jalurnya), F-12 & F-13 (dipagari, butuh uji dua
   transaksi), sisanya ber-pemilik di §1c. Jangan buka temuan baru sebelum ini beredar habis; jangan menutup
   F-12/F-13 tanpa bukti concurrency nyata.
2. Lanjut **K-3** (PR-05…PR-09, PR-13, PR-14) lalu **K-4** (PR-11 & D F-04 milik `T1-44`).
3. Aturan tetap: bagian baru `0015` + uji regresi + mutasi (`ganti_terakhir` untuk definisi yang ditulis ulang) +
   `DECISIONS_LOG.md` bila menyentuh uang/keamanan; commit & push per batch; **jangan merge PR mana pun** tanpa Lee.

**PUTARAN 18n (2026-09-20) — CI MERAH DIPERBAIKI: alat bukti mutasi memilih definisi yang berlaku (kemunculan TERAKHIR).**

Tiga commit (`e8487a8`, `7aab673`, `4a5b1d6`) gagal di langkah "bukti mutasi pagar migrasi 0012 + 0013"
walaupun pemeriksaan lokal hijau. Sebabnya **alat bukti mutasi**, bukan kode aplikasi:

1. Sejak `0015` menulis ulang fungsi yang sama di bagian berbeda (mis. `picu_item_jaga` di bagian 1 dan
   bagian 9), pola mutasi muncul DUA kali di berkas yang sama → alat lama menolak menjalankan (`LEWAT`,
   dihitung gagal). Sekarang: berkas berlaku = **migrasi terbaru yang memuat pola**, dan mutasi menyentuh
   **kemunculan TERAKHIR** (`ganti_terakhir()`) = definisi yang benar-benar berlaku.
2. Dua mutasi jadi **tumpul** karena menyunting definisi PERTAMA yang ditimpa definisi terakhir.
3. Pola `M14-12` dibuat khas penjaga kupon **DISKON** (dulu identik dengan penjaga kupon void → ambigu).
4. Uji `supabase/tes/persetujuan_void.sql` diperkuat: kupon sekali pakai diuji pada pesanan ber-**dua item**
   supaya yang menahan benar-benar aturan kupon, bukan aturan idempotensi pembatalan yang baru (F-05).

**Bukti mesin:** `python3 alat/uji-mutasi-0012.py` **16/16 MERAH** (kode 0) · `python3 alat/uji-mutasi-0014.py`
**17/17 MERAH** (kode 0) · `python3 alat/uji-mutasi-0015.py` **21 kasus LOLOS** (kode 0) · suite SQL
**51 berkas** · **CI `61e8d92` HIJAU** (push & PR). Catatan jujur ada di `STATUS.md` & `PROJECT_STATE.md`.

**Langkah berikutnya (urut) — maraton T1-45 lanjut:**

1. Bantah-balik sisa **11 temuan audit F**: mulai **F-07** (`catatan_audit` belum ada → pemilik `T1-13`),
   **F-08** (`T1-24`…`T1-26`, Fase 1B), **F-09** (`T8-01`) — ketiganya memang pekerjaan yang belum
   dijadwalkan selesai, bukan cacat tersembunyi; lalu yang **DUGAAN** (F-10 izin admin cabang · F-11 helper
   PIN · F-12 serialisasi uang · F-13 nomor pesanan) → WAJIB diprobe dulu sebelum disebut nyata.
2. Lanjut temuan lama K-3 (PR-05…PR-09, PR-13, PR-14) lalu K-4 (5 butir; PR-11 & D F-04 milik `T1-44`).
3. Aturan tetap: bagian baru `0015` + uji regresi + mutasi + `DECISIONS_LOG.md` bila menyentuh
   uang/keamanan; commit & push per batch; **jangan merge PR mana pun** tanpa Lee.

**PUTARAN 18m (2026-09-20) — BAGIAN 9 SELESAI: F-04 DITUTUP (status item & pembatalan berjejak).**

Pola yang sama: probe dulu, baru perbaikan. Probe `docs/uji/audit/probe-2026-09-20/aud-3-f04-status-item.sql`
dulu **LULUS** (cacat ada: item bisa lahir `siap`, status bisa melompat/mundur, item bisa dibatalkan
hanya dengan mengubah statusnya), sesudah perbaikan **GAGAL**. Perbaikannya di
`supabase/migrations/0015_penutup_celah_putaran16.sql` **bagian 9** (versi berlaku `picu_item_jaga`):
item baru selalu `baru`; status hanya maju satu langkah `baru → dimasak → siap` (TECH_SPEC ART-4);
`batal` **hanya** lewat baris `pembatalan` resmi (beralasan, ber-PIN bila sesudah dapur).

**Bukti mesin:** suite SQL **51 berkas LULUS · 0 GAGAL** · `python3 alat/uji-mutasi-0015.py` **21 kasus**
(semua wajib MERAH terbukti) · daftar temuan `docs/uji/AUDIT_RIWAYAT.md` §1c = **24 DITUTUP / 25 TERBUKA** ·
`python3 _sistem/validate_system.py` PASS · `python3 alat/periksa-bersih.py` LOLOS · keputusan di
`docs/DECISIONS_LOG.md`. **Pelajaran mekanisme:** karena `picu_item_jaga` kini punya definisi berlaku di
bagian 9, mutasi WAJIB menyentuh definisi TERAKHIR (dua mutasi lama sudah disesuaikan).

**Langkah berikutnya (urut) — maraton T1-45 lanjut:**

1. **Sisa 11 temuan audit F**, mulai yang bisa diprobe cepat: **F-07** (`catatan_audit` belum ada →
   pemilik `T1-13`, dicatat bukan disembunyikan) · **F-08** (`T1-24`…`T1-26`, Fase 1B) · **F-09** (`T8-01`) ·
   lalu yang **DUGAAN** (F-10 izin admin cabang · F-11 helper PIN · F-12 serialisasi uang · F-13 nomor
   pesanan): dugaan WAJIB diuji dulu dengan probe, tidak boleh langsung disebut nyata. Terakhir K-3
   (F-14 `ujiSambungan`, F-15 fokus modal, F-16 handoff basi, F-18 oracle PIN sisa).
2. **Lanjut temuan lama**: K-3 (PR-05…PR-09, PR-13, PR-14) lalu K-4 (5 butir; PR-11 & D F-04 milik `T1-44`).
3. Aturan tetap: bagian baru `0015` + uji regresi + mutasi + `DECISIONS_LOG.md` bila menyentuh
   uang/keamanan; commit & push per batch; **jangan merge PR mana pun** tanpa Lee.

**PUTARAN 18l (2026-09-20) — BAGIAN 8 SELESAI: TIGA CACAT K-2 AUDIT F DITUTUP (commit `e8487a8`).**

Sama polanya seperti 18k: dibuktikan dulu dengan probe sendiri, baru diperbaiki.
Probe `docs/uji/audit/probe-2026-09-20/aud-3-f03-f05-f06-uang.sql` dulu **LULUS** (berarti cacat ada);
sesudah perbaikan **GAGAL** (berarti cacat hilang). Perbaikannya di
`supabase/migrations/0015_penutup_celah_putaran16.sql` **bagian 8** — semuanya pemeriksaan TAMBAHAN
pada pemicu yang sudah ada (definisi lama di berkas beku `0012`/`0013`/`0014`):

1. **F-03** — metode bayar yang dinonaktifkan pemilik tidak bisa lagi mencatat uang
   (`supabase/tes/metode_bayar_nonaktif.sql`).
2. **F-05** — satu target pembatalan = satu jejak; kiriman ulang (klik ganda kasir / antrean
   perangkat offline) DITOLAK sehingga laporan kerugian tidak bisa tergandakan
   (`supabase/tes/pembatalan_sekali.sql`; uji lama `supabase/tes/pembayaran.sql` diselaraskan
   memakai pesanan kedua karena pembatalan ulang target yang sudah batal memang harus ditolak).
3. **F-06** — stempel lifecycle (`dibayar_pada`, `dibatalkan_pada`, `alasan_batal`) tidak bisa
   dikarang perangkat lewat UPDATE biasa, termasuk menghapusnya; jalur peladen tetap bebas dan
   kasir tetap boleh mengirim pesanan ke dapur (`supabase/tes/lifecycle_pesanan.sql`).

**Bukti mesin:** suite SQL **50 berkas LULUS · 0 GAGAL** · `python3 alat/uji-mutasi-0015.py` **20 kasus**
(3 mutasi baru wajib MERAH, terbukti) · `bash aplikasi/alat/periksa-semua.sh` hijau ·
`python3 alat/periksa-bersih.py` LOLOS · `python3 _sistem/validate_system.py` PASS · daftar temuan
`docs/uji/AUDIT_RIWAYAT.md` **§1c = 23 DITUTUP / 26 TERBUKA** · keputusan di `docs/DECISIONS_LOG.md`.

**Langkah berikutnya (urut) — maraton T1-45 lanjut:**

1. **Bantah-balik + tutup sisa 12 temuan audit F**, mulai dari yang bisa diprobe cepat:
   F-04 (state machine item bisa dilewati) · F-07 (`catatan_audit` belum ada → `T1-13`) ·
   lalu yang berstatus **DUGAAN** (F-10 izin admin cabang, F-11 helper PIN, F-12 serialisasi uang,
   F-13 nomor pesanan) — dugaan WAJIB diuji dulu, tidak boleh langsung disebut nyata.
2. **Lanjut temuan lama**: K-3 (PR-05…PR-09, PR-13, PR-14) lalu K-4 (5 butir; PR-11 & D F-04 milik `T1-44`).
3. Aturan tetap tiap perbaikan: bagian baru `0015` + uji regresi + mutasi (`mutasi(..., uji=)`) +
   entri `DECISIONS_LOG.md` bila menyentuh uang/keamanan; commit & push per batch; **jangan merge PR mana pun**.

**PUTARAN 18k (2026-09-20) — BAGIAN 6 SELESAI: TIGA CACAT UANG DITUTUP (commit `d2ba20a`).**

Tiga cacat uang yang dibuktikan probe di 18j **sudah diperbaiki** di `supabase/migrations/0015_penutup_celah_putaran16.sql`
**bagian 6** (berkas `0001`–`0014` tetap beku). Aturan uang kini hidup di satu tempat (`hitung_total`):

1. **F-01a** — pajak PB1 & service dihitung dari subtotal **setelah** diskon (aturan terkunci `docs/TECH_SPEC.md` §329-331).
   Contoh: 100.000 didiskon 20.000 → PB1 8.000 · service 4.000 · total **92.000** (dulu 95.000). Regresi uji: 27.000 − 1.350
   → dasar 25.650 · PB1 2.565 · service 1.283 · total **29.498**.
2. **F-01b** — `pengaturan.pembulatan` dibaca lagi dan diterapkan di langkah **TERAKHIR**, arah **KE BAWAH** (langkah 500:
   31.050 → 31.000). Arah pembulatan TIDAK PERNAH dikunci dokumen (diperiksa ulang PRD §88/§229, TECH_SPEC §331, ROADMAP
   T1-15/T1-16) → arah ini **diputuskan sekarang** dan dikunci uji; bisa dibalik satu baris bila Lee minta lain.
3. **F-02** — pesanan `lunas`/`batal` tidak bisa dihitung ulang dari perangkat; jalur pemicu peladen tetap sah dibedakan
   lewat `pg_trigger_depth() = 0` (penanda `set_config` DITOLAK: bisa dipalsukan klien = mengulang celah K-1). Baris pesanan
   dikunci `for update` (mengurangi risiko temuan dugaan F-12).

**Bukti mesin yang wajib tetap hijau:** `node alat/uji-sql.mjs` → **47 berkas LULUS · 0 GAGAL** · `python3 alat/uji-mutasi-0015.py`
→ **17 kasus** (4 mutasi baru: pajak dari pra-diskon · pembulatan diabaikan · penjaga lunas dilepas · pembulatan dibalik ke atas —
semuanya terbukti MERAH) · probe lama `docs/uji/audit/probe-2026-09-20/aud-3-f01-f02-uang.sql` kini **GAGAL = cacat hilang** ·
`python3 alat/periksa-bersih.py` LOLOS · `python3 _sistem/validate_system.py` PASS · `bash aplikasi/alat/periksa-semua.sh` hijau.
Keputusan uang dikunci di `docs/DECISIONS_LOG.md` (entri 2026-09-20). Seluruh **18 temuan audit F** kini punya baris + pemilik di
`docs/uji/AUDIT_RIWAYAT.md` **§1c** (dijaga `alat/periksa-temuan-audit.py`; F-17 → T1-44 · F-07 → T1-13 · F-09 → T8-01).

**Langkah berikutnya (urut) — maraton T1-45 lanjut:**

1. **Bantah-balik + tutup sisa 15 temuan audit F** (mulai dari yang K-2 dan bisa dibuktikan probe: F-03 metode bayar nonaktif ·
   F-05 pembatalan tidak idempoten · F-06 metadata lifecycle bisa ditulis klien · F-07 `catatan_audit`); yang berstatus **DUGAAN**
   (F-10/F-11/F-12/F-13) wajib diuji dulu dengan probe sebelum disebut nyata.
2. **Lanjut temuan lama**: K-3 (PR-05…PR-09, PR-13, PR-14) lalu K-4 (5 butir; PR-11 & D F-04 milik `T1-44`).
3. Setiap perbaikan = bagian baru `0015` + uji regresi + mutasi (`mutasi(..., uji=)`) + entri `DECISIONS_LOG.md` bila menyentuh
   uang/keamanan; commit per batch + push ke `arena/01a0b7d1-resto-barokah`; **jangan merge PR mana pun** tanpa Lee.
4. Fase 1B (`0016`+) baru dimulai **setelah** T1-45 tuntas (aturan: tidak ada kode fitur baru sebelum audit & rework selesai).

**PUTARAN 18j (2026-09-20) — HASIL AUDIT INDEPENDEN MASUK: 3 CACAT UANG TERBUKTI NYATA.**

Lee menjalankan 3 sesi auditor sekaligus (2026-09-19 malam). Yang sudah mendarat: **satu laporan AUD-3 menyeluruh**
(`docs/uji/audit/LAPORAN_AUD-3_2026-09-19_menyeluruh__01a0bbd2.md`, cabang berbeda → tidak bertabrakan) — **LOLOS KONTRAK**,
kalibrasi **5/5**, verdict **TIDAK-BERSIH**, 18 temuan; plus satu **review fondasi putaran 3** (mekanisme lama, cabang
`01a0b9f2`) yang **tidak digabung utuh** karena berakar di `main` (akan menimpa berkas terbaru) — hanya dipanen per butir.

**Bantah-balik sesi kerja (bukan percaya laporan):** probe sendiri `docs/uji/audit/probe-2026-09-20/aud-3-f01-f02-uang.sql`
(dijalankan `node alat/uji-sql.mjs …` → **LULUS = cacat ada**) membuktikan **tiga cacat jalur uang NYATA**:

1. **PB1 & service dihitung dari subtotal SEBELUM diskon** — melanggar aturan terkunci di docs/TECH_SPEC.md §329-330
   ("pajak & service dari subtotal SETELAH diskon"). Contoh nyata: subtotal 100.000 + diskon 20.000 → mesin menulis
   pajak 10.000 & service 5.000 (seharusnya 8.000 & 4.000), total 95.000 (seharusnya 92.000).
2. **`pengaturan.pembulatan` tidak pernah dibaca** — pemilik memilih 500/1000 tetapi total tetap 31.050.
3. **RPC `hitung_total` bisa menulis ulang angka pesanan yang sudah LUNAS** — kasir memanggilnya dan total 31.050
   berubah jadi 33.750 hanya karena tarif pajak di pengaturan berubah. Melanggar ART-4/Aturan Bisnis 11.

**Langkah berikutnya (urut) — perbaiki di `0015 bagian 6` + uji + mutasi — SUDAH DIKERJAKAN, lihat PUTARAN 18k di atas:**

1. `hitung_total`: basis pajak/service = subtotal SETELAH diskon; baca `pengaturan.pembulatan`; tolak penulisan ulang
   pesanan `lunas`/`batal` dari panggilan klien (koreksi sah hanya lewat pembatalan resmi); kunci baris pesanan
   (`for update`) supaya dua kasir bersamaan tidak saling menimpa angka.
2. Uji regresi baru + probe lamanya WAJIB jadi MERAH; tambah mutasi di `alat/uji-mutasi-0015.py`.
3. Sisa temuan audit (K-2/K-3, 15 butir) dibantah-balik batch berikutnya; **T-022/T-023** sudah masuk `docs/TERTANGGUH.md`.

**PUTARAN 18i (2026-09-19) — CELAH MEKANISME AUDIT DITUTUP (auditor terblokir).**

Sesi auditor independen Lee (`arena/01a0b9f2`) **berhenti di langkah 1** — bukan karena proyeknya cacat, tetapi karena:
(a) Lee menyalin **berkas cetakan** `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`, yang kalimat pembukanya (di sumber kanonik) masih memuat
baris kosong `<<< TEMPEL ISI docs/uji/paket-audit/… DI SINI >>>` — jadi auditor melihat paket belum diisi; dan (b) sesi auditor baru
bercabang dari `main` sehingga `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` tidak ada di checkout-nya, sementara paket tidak memberi cara
mengambil bahan. Auditor berhenti dengan jujur, tidak menulis apa pun (benar secara aturan).

**Perbaikan (semua ber-mesin):**

1. `alat/audit-independen.py` — kalimat pembuka di berkas siap-tempel kini **dibersihkan dari penanda kosong** dan diberi **langkah 0
   AMBIL BAHAN**; paket menyebut **commit + cabang** target dan perintah `git fetch origin <cabang> && git checkout --detach <sha>`.
2. `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` + `PANDUAN_PENGGUNA.md` (blok C4) — langkah 0 ditambahkan (dijaga cek identik); berkas cetakan
   diberi **peringatan tebal** di kepalanya: "JANGAN SALIN BERKAS INI — salin `<paket>-SIAP-TEMPEL.md`".
3. `alat/periksa-paket.py` — **aturan baru**: berkas siap-tempel paket audit wajib tanpa `<<<`, memuat bagian `SAMBUNGAN: PAKET AUDIT`,
   dan memuat cara mengambil bahan di bagian pembukanya; + 2 mutasi uji-diri (kini 8 kasus, semuanya terbukti bisa MENOLAK).
4. Nama berkas paket tidak lagi menimpa paket lain di hari yang sama (`<tingkat>-<tanggal>-<sha7>.md` bila sudah ada).
5. `.obsidian/workspace.json` dikeluarkan dari Git (sudah di `.gitignore`) — kehadirannya membuat pembuat paket berhenti `F-13`.
6. Riwayat jujur: baris audit **E — TERBLOKIR** di `docs/uji/AUDIT_RIWAYAT.md`.

**Langkah berikutnya (aksi Lee):** salin berkas **`docs/uji/paket-audit/AUD-3-2026-09-19-4830b5a-SIAP-TEMPEL.md`**
(seluruh isinya, dari baris pertama sampai terakhir) ke **chat auditor baru**, lalu kirim laporannya ke sesi ini. Sementara menunggu,
maraton T1-45 lanjut ke **K-3**.

**PUTARAN 18h (2026-09-19) — MARATON T1-45: SELURUH K-2 TUNTAS (4/4).**

Bagian 4–5 `supabase/migrations/0015_penutup_celah_putaran16.sql`:

- **PR-03 — hitungan nomor pesanan tidak bocor antar resto.** `nomor_pesanan_berikutnya()` (SECURITY DEFINER,
  bisa dipanggil klien) kini memeriksa keterlihatan cabang (`cabang_pantau_saya`) sama seperti `hitung_total` dan
  `total_dibayar`; kasir Resto B tidak lagi mendapat angka pesanan Resto A. Peladen (tanpa identitas) tetap bisa,
  karena pemicu penomoran pesanan baru berjalan sebagai peladen — uji `supabase/tes/nomor_pesanan_isolasi.sql`.
- **PR-04 — pesan PIN kembar dibuat netral.** Kalimat 'PIN itu sudah dipakai pegawai lain' MEMASTIKAN angka kiriman
  adalah PIN aktif kolega (oracle). Sekarang jawabannya netral ('PIN itu tidak bisa dipakai — pilih angka lain'),
  sementara alasan sebenarnya tetap tercatat di `percobaan_simpan_pin`. Catatan jujur: sifat berhasil-vs-ditolak tetap
  bisa dibaca, jadi pengendali biaya menebak tetap **pembatas 20 percobaan/15 menit** (T1-23) — dicatat di
  `docs/DECISIONS_LOG.md`, bukan diklaim hilang. Uji `supabase/tes/pin_bukan_oracle.sql` (dua uji lama yang memeriksa
  pesan lama diselaraskan).

**Bukti mesin:** suite SQL **46 berkas LULUS · 0 GAGAL**; `python3 alat/uji-mutasi-0015.py` **15 kasus — 13 mutasi wajib
MERAH semuanya terbukti merah**, 2 kasus memang diharapkan hijau. Sisa temuan **16** (14 `T1-45`, 2 `T1-44`).

**Langkah berikutnya (urut) — lanjut maraton ke K-3:**

1. **K-3 (7):** PR-05 pra-dapur tanpa izin/jejak · PR-06 jejak hierarki ikut rollback · PR-07 kupon tanpa ikatan pesanan
   (jalur Edge buntu) · PR-08 saldo awal stok tanpa baris buku · PR-09 PIN warisan 4 angka buntu · PR-13 `KEAMANAN.md`
   menunjuk tabel hantu · PR-14 hak `service_role`/`peringkat_peran`.
2. **K-4 (5):** PR-15 hapus meja memutus riwayat · temuan ringan lain · D F-04 & PR-11 (pemilik `T1-44`).
3. Fase 1B: `T1-24`/`T1-25`/`T1-26` dengan nomor migrasi `0016`+.

**PUTARAN 18g (2026-09-19) — MARATON T1-45: K-2a + K-2b DITUTUP.**

Dua temuan K-2 tuntas, keduanya di **bagian 2–3** `supabase/migrations/0015_penutup_celah_putaran16.sql`:

- **PR-02 — void satu item tidak lagi membatalkan seluruh pesanan.** Pemicu resmi
  `picu_pembatalan_jejak` sekarang menutup pesanan (`status = 'batal'`) **hanya** bila tidak ada item hidup
  tersisa atau pembatalannya memang tingkat pesanan; pesanan yang ditutup menandai **seluruh** itemnya batal
  (tidak ada lagi keadaan setengah jalan). Akibatnya pembayaran sisa tidak lagi buntu — uji
  `supabase/tes/void_satu_item.sql` (termasuk membayar item yang masih hidup, dan pesanan yang memang batal).
- **Audit D F-01 — diskon tidak bisa lagi ditanam sesudah uang tercatat.** Pemicu baru `diskon_awal_pesanan`
  menolak tambah/ubah/hapus baris diskon pada pesanan `lunas`/`batal`; jalur sahnya pembatalan/void resmi. Nama
  pemicu sengaja berjalan **sebelum** pemicu nilai `diskon_batas` (abjad nama) supaya penolakan berbunyi tentang
  status, dan urutan itu ikut dikunci mutasi — uji `supabase/tes/diskon_sesudah_lunas.sql`.

**Bukti mesin:** suite SQL **44 berkas LULUS · 0 GAGAL** (`node alat/uji-sql.mjs`); `python3 alat/uji-mutasi-0015.py`
**11 kasus — 10 mutasi wajib MERAH semuanya terbukti merah**, 1 kasus memang diharapkan hijau; keputusan dikunci di
`docs/DECISIONS_LOG.md` `[Uang/2026-09-19]`. Sisa temuan **18** (16 `T1-45`, 2 `T1-44`).

**Langkah berikutnya (urut) — lanjut maraton, sisa `T1-45`:**

1. **K-2 (sisa 2):** kebocoran hitungan `nomor_pesanan_berikutnya` lintas resto (PR-03, sekaligus tabrakan nomor
   antar-kasir) · oracle PIN kembar (PR-04).
2. **K-3 (7):** PR-05 pra-dapur tanpa izin/jejak · PR-06 jejak hierarki ikut rollback · PR-07 kupon tanpa ikatan
   pesanan (jalur Edge buntu) · PR-08 saldo awal stok tanpa baris buku · PR-09 PIN warisan 4 angka buntu ·
   PR-13 `KEAMANAN.md` menunjuk tabel hantu · PR-14 hak `service_role`/`peringkat_peran`.
3. **K-4 (5):** PR-15 hapus meja memutus riwayat · D F-04 & PR-11 + sisa temuan audit ringan (pemilik `T1-44`).
4. Fase 1B: `T1-24`/`T1-25`/`T1-26` dengan nomor migrasi `0016`+.

**PUTARAN 18f (2026-09-19) — MARATON T1-45: K-1 (PR-01) DITUTUP.**

Temuan **paling berbahaya** tuntas. Sebelumnya kasir bisa memalsukan penanda transaksi
(`set_config('resto.pembatalan_pesanan', …)`) lalu membatalkan item sesudah dapur **tanpa PIN atasan & tanpa satu pun
baris jejak**. Perbaikan ada di **migrasi baru** `supabase/migrations/0015_penutup_celah_putaran16.sql` **bagian 1**:
penanda transaksi tidak lagi diakui di mana pun; pembatalan item setelah dapur hanya sah lewat baris `pembatalan`
resmi (0013: tahap + PIN + kupon sekali pakai), dan pemicu resmi berhenti menulis penanda itu.

**Bukti:** uji regresi `supabase/tes/pembatalan_penanda_palsu.sql` (4 serangan dari kursi kasir, semuanya ditolak;
keadaan data tidak berubah) + `alat/uji-mutasi-0015.py` — **6 mutasi**, termasuk "kembalikan versi lama yang bocor",
"lepas pemicunya", "beri pengecualian diam-diam untuk peran kasir" → semuanya **MERAH** (terbukti), kontrol hijau.
Masuk CI sebagai **gerbang ke-52** (uji + bukti mutasi). Suite SQL kini **42 berkas LULUS · 0 GAGAL**. Keputusan
dikunci di `DECISIONS_LOG.md` `[Keamanan uang/2026-09-19]`.

**Langkah berikutnya (urut) — lanjut maraton:**

1. **K-2 (sisa 4)** — diskon pada pesanan `lunas`/`batal` (audit D F-01) · void satu item ikut membatalkan seluruh
   pesanan (PR-02) · kebocoran hitungan `nomor_pesanan_berikutnya` lintas resto (PR-03) · oracle PIN kembar (PR-04).
   Ditulis sebagai **bagian 2…5 dalam `0015_penutup_celah_putaran16.sql`** + uji regresi + mutasi baru di
   `alat/uji-mutasi-0015.py`.
2. K-3/K-4 (16 temuan tersisa), lalu Fase 1B (`T1-24`/`T1-25`/`T1-26` dengan nomor migrasi `0016`+).
   (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18e (2026-09-19) — FASE 0 TUNTAS: HALAMAN PUBLIK NAIK; MARATON T1-45 DIMULAI.**

Lee menulis **"Boleh naik"** (izin publik — Stop Condition, jadi wajib menunggu). Agent memicu penanda
`aplikasi/SEBAR-HALAMAN`: run `35440300274` hijau (unggahan pertama), lalu `35440432817` hijau (unggahan ulang +
**pencatatan alamat otomatis**). Alamat publik: **https://resto-barokah.fatrizmubarok.workers.dev** — **HTTP 200**.
Bukti dibaca dari **anotasi** (`ALAMAT-PUBLIK`) karena log job GitHub tidak bisa dibaca dari lingkungan agent;
alat baru `aplikasi/alat/catat-alamat.mjs` (+`--uji-diri` 6 kasus) menjadi **gerbang CI ke-51** dan membuat
"hijau" berarti halaman benar-benar menjawab. Alamat & cara mundur dicatat di `docs/ops/ALAMAT_PUBLIK.md`;
`T0-09` DITUTUP, `T-021` SELESAI (terbuka kini **6**).

**Penjaga batas mode bimbingan diperkuat (permintaan Lee):** `alat/periksa-panduan.py` kini memeriksa blok
AL-14 **dan** §14 `AGENT_OPERATING_GUIDE.md`; mutasi yang menghapus batas (2 kasus baru) WAJIB ditolak.

**Langkah berikutnya (urut) — MARATON:**

1. **T1-45 K-1** (paling berbahaya): penanda `resto.pembatalan_*` bisa dipalsukan kasir → void sesudah dapur tanpa
   PIN & tanpa jejak. Ditulis sebagai migrasi BARU `supabase/migrations/0015_penutup_celah_putaran16.sql`
   (+ uji regresi di `supabase/tes/`, + `alat/uji-mutasi-0015.py` semua mutasi WAJIB MERAH).
2. Lanjut K-2 (diskon pada lunas/batal · void satu item · kebocoran nomor lintas resto · oracle PIN) → K-3/K-4.
3. Setelah T1-45: Fase 1B (T1-24/25/26) memakai nomor migrasi `0015`+ sesuai catatan; lalu T1-37 (B.4–B.9).
   (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18d (2026-09-19) — PEMERIKSAAN PRA-MARATON (permintaan Lee) SELESAI.**

Diperiksa ulang semua yang bisa terlupakan: butir tunggu (**7 terbuka**), daftar temuan (audit §1b + review PR),
rencana pekerjaan ulang (`docs/uji/DAFTAR_PEKERJAAN_ULANG.md`), dan angka-angka di dokumen. Hasil:

1. **PR-12 DITUTUP** — label `12/12` basi di `aplikasi/alat/periksa-semua.sh` diganti label tanpa angka (angka benar
   selalu datang dari ringkasan alat).
2. **Angka sisa temuan dibetulkan: 23 → 21 terbuka** (19 milik `T1-45`; PR-11 & D F-04 milik `T1-44`). Sebelumnya
   dokumen menulis 23 padahal F-05/F-07/PR-10 sudah ditutup lebih dulu — kelas cacat F-14.
3. **Bentrok penomoran ditemukan & dibereskan:** `T1-24`/`T1-25`/`T1-26` masih merencanakan migrasi `0012`–`0014`
   yang kini terpakai & **beku** → diberi catatan wajib memakai nomor baru `0015`–`0017`.
4. **Tidak ada temuan tanpa pemilik** dan tidak ada pekerjaan setengah jalan yang tersembunyi.

**Langkah berikutnya (urut):**

1. **`T-021` halaman publik** — tinggal izin Lee (`Boleh naik`); rahasia Cloudflare sudah dipasang.
2. **T1-45 sisa 21 temuan** (19 milik `T1-45`) — mulai K-1, ditulis sebagai migrasi BARU `0015_…` dst.
3. **Fase 1B (T1-24/25/26)** — setelah temuan tuntas, memakai nomor migrasi `0015`+ sesuai catatan baru.
   (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18c (lanjutan) — MODE BIMBINGAN DITANAM + LANGKAH B LEE SELESAI.**

Lee menyelesaikan **Langkah B** (rahasia `CLOUDFLARE_API_TOKEN` dipasang) dan meminta dua hal: (a) bimbingan singkat
saat ia memegang layar, (b) mekanismenya **ditanam** di sistem. Hasilnya: alur **AL-14** (`PANDUAN_PENGGUNA.md`,
8 bidang lengkap) + **§14** (`docs/AGENT_OPERATING_GUIDE.md`) + baris `PROFIL_PENGGUNA.md` + rekam pesan §16.
Pemicu: `Tolong bimbing.` · `Mode bimbingan.` · `Beri arahan step by step.` · `Aku bingung, pandu aku.`
Penutup: `Sudah beres, lanjut normal.` Penjaga `alat/periksa-panduan.py`: **MIN_ALUR 13 → 14** + topik wajib
"mode bimbingan". **Batas yang disampaikan ke Lee:** mode ini hanya memendekkan cara bicara — Stop Conditions §12
(biaya, keamanan/uang/data, keputusan terkunci, deploy publik) dan klaim "selesai" tetap butuh bukti diperiksa dulu.

**Langkah berikutnya (urut):**

1. **`T-021` (halaman publik)** — tinggal **izin publik** dari Lee (`Boleh naik`). Begitu dikatakan: buat penanda
   `aplikasi/SEBAR-HALAMAN` → alur mengunggah → catat alamat `*.workers.dev` + pemeriksaan HTTPS → hapus penanda.
2. **T1-45 sisa 21 temuan** (19 milik `T1-45`; PR-11 & D F-04 milik `T1-44`) — K-1…K-4 dalam bentuk migrasi **BARU** `0015_penutup_celah_putaran16.sql`
   (berkas `0001`–`0014` beku; penjaga `alat/periksa-migrasi-beku.py`), tiap perbaikan + uji regresi + mutasi wajib MERAH.
   (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18c (2026-09-19) — SKEMA HIDUP DI PROYEK NYATA: `T0-08` DITUTUP, `T-020` SELESAI.**

Lee menyelesaikan **Langkah A** (2 rahasia Supabase di kotak rahasia GitHub); agent memicu berkas penanda
supabase/SEBAR-SKEMA → run `35435248540` **hijau berurutan** (`link` → `db push --dry-run` → `db push` →
`migration list`), jadi 14 migrasi kini ADA di proyek `bdvjirmbuqelmduztryj`. Bukti baca data (setara `select 1`):
gerbang CI ke-50 membaca tabel katalog dengan kunci publik → **HTTP 200** (run `35435414653`).

**Aturan baru yang mengikat (dikunci di `DECISIONS_LOG.md`):** berkas migrasi `0001`–`0014` **DIBEKUKAN** — semua
perubahan skema, termasuk seluruh perbaikan temuan audit K-1…K-4, WAJIB ditulis sebagai berkas BARU `0015`+ dan
dijaga `alat/periksa-migrasi-beku.py` (ikut berjalan di CI, punya `--uji-diri`, plus mutasi "penjaga dihapus"
di `alat/periksa-gerbang-ci.py --uji-diri`).

**Langkah berikutnya (urut):**

1. **T1-45 sisa 21 temuan** (PR-12 sudah ditutup 2026-09-19) — mulai **K-1**, tetapi kini dalam bentuk **`supabase/migrations/0015_penutup_celah_putaran16.sql`**
   (berkas lama tidak boleh disunting), lengkap dengan uji regresi + semua mutasi wajib MERAH.
2. **`T-021` (halaman publik)** — menunggu DUA hal dari Lee: rahasia `CLOUDFLARE_API_TOKEN` (panduan
   `docs/ops/LANGKAH_PEMILIK_SEKARANG.md`, pakai templat **Edit Cloudflare Workers**, bukan _Create Custom Token_)
   dan izin **"Boleh naik"** karena deploy publik = tindakan tak bisa dibatalkan.
3. **Uji ulang berkas uji `supabase/tes/` di proyek nyata** (bcrypt asli pgcrypto) — bukti bahwa perilaku di proyek
   Lee sama dengan PostgreSQL lokal; dicatat di `supabase/README.md`, belum dijadwalkan sebagai tugas.
   (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18b (2026-09-19) — FASE 0 DIBERESKAN (akun pemilik aktif). RENCANA BERIKUTNYA: K-1.**

Keadaan sekarang: `T0-00` + butir tunggu `T-018` **DITUTUP** — Lee membuat akun **Supabase + Resend + Cloudflare** dan
mengisi nilai non-rahasia di `docs/ops/DAFTAR_KUNCI_PEMILIK_NONSECRET.md` (commit `bd68685`; kunci rahasia tidak pernah
masuk repo/obrolan). Selesai hari ini: klien Supabase aman `aplikasi/src/lib/supabase.ts` (+10 uji) · alat uji sambung
`aplikasi/alat/cek-supabase.mjs` (+`--uji-diri` 5 kasus) · **gerbang CI ke-50** `npm run cek:supabase` (bukti live: run
`35432334878` hijau, langkah ke-11 = success) · jalur rilis `aplikasi/wrangler.toml` + `npm run deploy`.

**Dua hal menunggu Lee — jangan dikerjakan tanpa jawaban:** `T-020` menyebar 14 migrasi ke proyek Supabase nyata (butuh
kredensial pemilik; sesudahnya DoD `select 1` T0-08 bisa dituntaskan) · `T-021` deploy publik halaman kosong ke Cloudflare
(tindakan publik & tak bisa dibatalkan).

**Bukti jalur (2026-09-19, sudah dijalankan):** penanda terpasang → kedua alur **menyala lalu berhenti aman** di gerbang rahasia tanpa menyentuh proyek (run `35433200326` skema, `35433200375` halaman; semua langkah penyebaran `skipped`) · penanda dihapus → kedua alur **hijau tanpa kerja** (run `35433237658`, `35433237656`) — jadi tidak ada penyebaran tak sengaja di kiriman berikutnya. Penjaga gerbang kini memeriksa **urutan** perintah (pratinjau wajib benar-benar mendahului penyebaran) dan menolak 9 mutasi alur.

**Jalurnya sudah disiapkan mesin (2026-09-19):** Lee tinggal menempel **3 rahasia** ke kotak rahasia GitHub
(`SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `CLOUDFLARE_API_TOKEN`) — panduan langkah bernomor tanpa perintah:
`docs/ops/LANGKAH_PEMILIK_SEKARANG.md` (baris `BUKU_UJI_PEMILIK` P-04/P-05). Setelah Lee bilang "Rahasia sudah dipasang",
agent: (1) buat berkas penanda supabase/SEBAR-SKEMA → alur menjalankan **dry-run lebih dulu** lalu menyebar → hapus
penanda; (2) catat bukti tabel ada; (3) bila Lee setuju, buat penanda aplikasi/SEBAR-HALAMAN → alur menaikkan halaman
→ catat alamat publik + hapus penanda. Kedua alur diawasi `alat/periksa-gerbang-ci.py` (dua arah, 8 + 5 perintah, **urutan diperiksa**).

**Langkah berikutnya (urut):**

1. **T1-45, sisa 21 temuan** — mulai **K-1** (penanda `resto.pembatalan_*` dipalsukan → void sesudah dapur tanpa PIN
   & tanpa jejak), lalu **K-2** (diskon pada `lunas`/`batal` · void satu item jangan menutup pesanan · kebocoran
   `nomor_pesanan_berikutnya` lintas resto · oracle PIN kembar), lalu K-3/K-4 (jejak berjenjang, kupon↔pesanan Edge
   `p_pesanan_id`, buku besar stok, PIN warisan 4 angka, grant `service_role`/`anon`, tautan meja, tabel hantu
   `percobaan_masuk`, label `12/12` basi, generator paket audit, pesan diskon F-10).
   Target: `supabase/migrations/0015_penutup_celah_putaran16.sql` + `supabase/tes/` + `alat/uji-mutasi-0015.py`.
2. Setiap perbaikan wajib: uji regresi baru + `alat/uji-mutasi-0015.py` (semua mutasi MERAH) + suite penuh hijau +
   `DECISIONS_LOG.md` bila menyentuh cara membuktikan izin/uang.
3. Butir tertangguh terbuka **8** (batas 12) → di akhir batch, tawarkan jawaban agent untuk semuanya.
4. Kalau Lee menjawab `T-020`/`T-021`, kerjakan itu lebih dulu: Fase 0 tuntas adalah syarat sebelum pekerjaan Fase 1
   berlanjut (dan penyebaran skema membuka uji RLS di layanan nyata — nilai besar untuk penutupan T1-45).

**Jangan merge PR #2** selama K-1/K-2 masih terbuka. PR #1 tetap tidak disentuh.

**PUTARAN 18 (2026-09-19) — 25 TEMUAN PENINJAU DIBANTAH-BALIK (25/25 NYATA); 2 SUDAH DITUTUP, SISA 23.**

Dua laporan diterima (sesi peninjau `arena/01a0b85b`): AUD-3 menyeluruh (10 temuan, **laporan DITOLAK MESIN** karena
kelengkapan format — label grup cakupan diparafrase + cabang memuat 2 laporan; isinya tetap dipakai setelah
diverifikasi ulang) dan review PR putaran16 (15 temuan, **LOLOS KONTRAK**, verdict TIDAK-BERSIH). Semua temuan
**dibantah-balik sendiri dengan probe** dan semuanya NYATA (0 palsu). DITUTUP: **D F-05** (kunci kalibrasi keluar
dari repo + daftar pensiun + bahan review PR hidup di luar repo) dan **PR-10** (gerbang CI gagal-terbuka: penjaga
kini dua arah — 49 perintah CI diawasi, `if:` dilarang — dibuktikan menolak di salinan `/tmp/gc2`).

**Langkah berikutnya yang wajib (urut):**

1. **Lanjutkan `T1-45`** — sisa **21 temuan**. Urutan nilai:
   **(a) K-1** penanda `resto.pembatalan_*` jangan dipercaya (kasir bisa memasang penanda transaksi sendiri →
   void sesudah dapur tanpa PIN & tanpa jejak; bukti probe peninjau sudah direproduksi);
   **(b) K-2** diskon pada pesanan `lunas`/`batal` · void satu item jangan menutup seluruh pesanan · kebocoran
   `nomor_pesanan_berikutnya` lintas resto · oracle PIN kembar;
   **(c)** K-3/K-4: jejak penolakan berjenjang, kupon ↔ pesanan (Edge `p_pesanan_id`), buku besar stok, PIN
   warisan 4 angka, grant `service_role`/`anon`, tautan meja, tabel hantu `percobaan_masuk`, label `12/12` basi,
   generator paket audit (baris "TIDAK ADA" palsu), pesan diskon F-10.
   Target berkas: `supabase/migrations/0015_penutup_celah_putaran16.sql` + `supabase/tes/` + `alat/*`.
2. Setiap perbaikan: uji regresi baru + `alat/uji-mutasi-0015.py` (semua mutasi WAJIB MERAH) + suite penuh hijau
   - `DECISIONS_LOG.md` bila menyentuh cara membuktikan persetujuan/keamanan uang.
3. **Satu hal masih menunggu Lee:** auditor diminta memperbaiki **format** laporannya (label grup cakupan sama
   seperti paket + satu laporan per cabang) lalu mengirim ulang agar auditnya sah formal.
4. Selagi menunggu: butir tertangguh terbuka **7** (batas 12) — tawarkan jawaban agent untuk masing-masing.

**Jangan merge PR #2** (temuan K-1/K-2 masih terbuka di commit yang direview). PR #1 tetap tidak disentuh.

**PUTARAN 17 SEDANG BERJALAN (2026-09-19) — putaran verifikasi, MENUNGGU LEE.** Paket peninjau
**sudah terbit & ter-push** (target `93a50ba`): audit
`docs/uji/paket-audit/AUD-3-2026-09-19-SIAP-TEMPEL.md` dan review PR
`docs/uji/review-pr/PKT-2026-09-19-pr-01-putaran16-SIAP-TEMPEL.md` (PR **#2**; jalur risiko Merah).
Tugas Lee: **buka 2 chat baru** (idealnya model berbeda) dan **salin satu berkas `-SIAP-TEMPEL` ke
tiap chat**; setelah selesai bilang **"Laporan audit/review sudah masuk, periksa."** Keadaan
menunggu ini **normal dan tidak menghambat**: sambil menunggu, agent boleh menutup cacat lain yang
ditemukan sendiri (aturan: cacat yang sudah diketahui ditutup dulu supaya peninjau tidak membuang
anggaran). Saat laporan masuk: ambil (`--ambil-laporan`), **bantah-balik setiap temuan dengan probe
sendiri**, tutup yang nyata, catat yang palsu.

**Catatan pilihan cabang (penting untuk sesi baru):** handoff ini menunjuk
`arena/01a0b7d1-resto-barokah` — dipilih **supaya pekerjaan terbaru tidak hilang**: cabang sesi
sebelumnya (`arena/01a0a8a2-resto-barokah`) berhenti di `0af1cf9` dan **tidak memuat** paket peninjau
2026-09-19 + perbaikan putaran ini. Mesin kini **menolak** handoff yang menunjuk cabang tanpa keadaan
kerja terbaru (`alat/lanjut-sesi.py`, uji-diri 39 kasus) — jadi kalau Lee ingin melanjutkan dari
cabang lain, itu tetap haknya, tapi harus lewat `--lanjut-dari` atau `--paksa` (tercatat).

**Sesi ditutup (putaran 16, 2026-09-18)** atas perintah Lee: _"Siapkan pindah sesi dan tutup sesi ini dengan baik."_
Sebelum menutup, pertanyaan kepercayaan Lee diperiksa jujur dan **4 celah nyata ditutup** (rantai "kalimat perintah
sederhana Lee → alur" sekarang dijaga mesin): Prompt Pembuka item **2d** menunjuk `PANDUAN_PENGGUNA.md`; **KARTU SESI**
mencetak penunjuk buku; kalimat gabungan & sinonim ("dengan baik" = "dengan benar") masuk AL-3/AL-13 + tabel C3;
rujukan berkas pensiun dibetulkan. Jadi: kalau Lee menulis kalimat pendek, **cari di buku (Bagian C3/B/E)** —
jangan mengarang langkah. Sesi yang sengaja ditinggalkan Lee tetap `arena/01a0b4c3-resto-barokah`.

**Putaran 15 (2026-09-18):** permintaan Lee — berkas prompt pindah sesi dijadikan
**STATIS** (`PROMPT_SESI_BARU.md`, satu baris `SESI YANG AKU LANJUT:` diisi Lee) dan sesi yang **sengaja
ditinggalkan** dicatat di `docs/ops/SESI_DITINGGALKAN.md` (mesin menolak handoff ke arah sana).
`docs/ops/SIAP-TEMPEL-SESI-BARU.md` dipensiunkan menjadi penunjuk. Jadi: **untuk pindah sesi, Lee cukup
menyalin `PROMPT_SESI_BARU.md` — tidak perlu minta apa pun ke agent.**

Keadaan keputusan Lee (2026-09-18, sesi ditutup karena berat): arah berikutnya **belum dipilih**.
Urutan yang disarankan agent, dan alasannya:

1. **Putaran verifikasi (disarankan lebih dulu, kecil).** Commit yang ditunjuk paket peninjau
   TIDAK diklaim tangan di sini — bacalah baris **"Paket peninjau terbaru"** di §2 (ditulis mesin
   dari berkas paketnya sendiri). Sebelum dua peninjau mulai bekerja, segarkan paket ke commit
   terkini: `python3 alat/audit-independen.py --paket AUD-3 --semua` dan
   `python3 alat/review-pr.py --siapkan --pr 1 --nama pr-01-putaranNN` (pakai NN berikutnya —
   jangan menimpa nama lama, laporan peninjau pernah tertimpa karena ini). Lee tinggal menyalin
   **satu berkas `-SIAP-TEMPEL` per chat baru** (dua chat). Setelah laporan masuk:
   bantah-balik setiap temuan dengan probe sendiri (aturan tetap), tutup yang nyata, catat yang palsu.
   Bukti dari laporan putaran sebelumnya: dua putaran berturut-turut menemukan cacat nyata, dan dua
   cacat terakhir justru tertangkap CI — jadi verifikasi ini bukan formalitas.
2. **Lanjut kerja T1-24** (perangkat terdaftar + `perangkat_sah()` + RLS staf diperketat) — menutup
   akar beberapa kelemahan (batas PIN per perangkat masih memakai nama perangkat kiriman klien).
   **PENTING (temuan baru):** ROADMAP T1-24 menyebut "Migrasi 0012", padahal 0012 **sudah terpakai**
   (penutup celah review) dan migrasi sudah mencapai `0014`. T1-24..T1-28 wajib memakai nomor
   berikutnya (0015 dst.) — perbarui ROADMAP + catat di `DECISIONS_LOG.md` saat dikerjakan.
**MARATON G3 BATCH FASE 1B, 1C & FASE 2 SELESAI LENGKAP 100% (2026-09-22):**
1. **Fase 1B & 1C Selesai Penuh:** Seluruh migrasi keamanan (`0011`–`0031`), 72 pengujian SQL PGlite (100% lulus), fondasi tema, i18n 4 bahasa, tata letak, registri aksi, dan kontrak antarmuka telah diverifikasi solid.
2. **Fase 2 (Masuk & Kerangka Aplikasi) Selesai Penuh:**
   - T2-01: Supabase Auth & Sesi Aman di klien
   - T2-02: Layar Masuk Pegawai (Email + PIN Keypad)
   - T2-03: Kelola Pegawai & Atur Ulang PIN oleh Admin (`KelolaPegawai.tsx` + uji unit)
   - T2-04: Masuk Pelanggan: Google One-Tap & Tautan Email (`LayarMasukPelanggan.tsx` + uji unit)
   - T2-05: Pemulihan Akses Pelanggan (`LupaAkses.tsx` + uji unit)
   - T2-06: Kerangka Layout & Navigasi 6 Peran (`Rangka.tsx`, `Navigasi.tsx` + uji unit)
   - T2-07: Pemilih Cabang & Konteks Cabang Aktif (`PemilihCabang.tsx` + uji unit)
   - T2-08: Halaman Tidak Punya Akses & Pesan Ramah Berkode (`TidakPunyaAkses.tsx` + uji unit)
   - T2-09 & T2-16: Sesi Berakhir Otomatis & Kunci Instan (`useKunciOtomatis.ts`, `KunciSekarang.tsx` + uji unit)
   - T2-10: Pembatasan Percobaan Masuk Server-Side (Migrasi 0028 & SQL test)
   - T2-11: PWA Dasar (Manifest Webmanifest + Ikon + Service Worker `sw.js`)
   - T2-12 & T2-19: Uji Menyeluruh Hak Akses & Navigasi 6 Peran (`SkenarioMasukPeran.test.tsx` 8 tes lulus)
   - T2-13 & T2-18: Masuk Pengelola Sandi + TOTP 2FA (`MasukPengelola.tsx` + uji unit)
   - T2-14: Layar Masuk Staf Perangkat Terdaftar (`MasukStaf.tsx` + uji unit)
   - T2-15: Pendaftaran Perangkat Baru & Persetujuan Pegawai (`Perangkat.tsx` + uji unit)
   - T2-17: Daftar Perangkat & Pencabutan Sesi Hilang (`DaftarPerangkat.tsx` + uji unit)
3. **Rencana Selanjutnya:** Melanjutkan ke Fase 3 (Pesanan & Kasir - M4):
   - T3-01: Layar Kasir: katalog nyata dari database (kategori, varian, tambahan)
   - T3-02: Keranjang belanja: tambah/kurang/catatan khusus per item
   - T3-03: Simpan pesanan draf / meja terbuka
   - T3-04: Pembayaran kasir (Tunai, QRIS, Kartu, Split Bill)
   - T3-05: Cetak struk kasir & kirim nota elektronik (PDF/WhatsApp)

**MARATON G3 BATCH FASE 1B, 1C, FASE 2, & FASE 3 POS KASIR SELESAI LENGKAP (2026-09-22):**
1. **Fase 1B & 1C Selesai Penuh:** Seluruh migrasi keamanan (`0011`–`0031`), 72 pengujian SQL PGlite (100% lulus), fondasi tema, i18n 4 bahasa, tata letak, registri aksi, dan kontrak antarmuka telah diverifikasi solid.
2. **Fase 2 (Masuk & Kerangka Aplikasi) Selesai Penuh:** Seluruh 19 tugas (T2-01 s/d T2-19) terverifikasi lengkap.
3. **Fase 3 (Pesanan & Kasir - M4) Selesai Penuh:**
   - T3-01 & T3-07: Katalog menu dinamis, pencarian instan, filter kategori, penandaan & penguncian menu habis (`Katalog.tsx` + uji unit)
   - T3-02: Keranjang belanja server-calculated, subtotal, diskon, service, PB1, dan catatan per item (`Keranjang.tsx` + uji unit)
   - T3-03 & T3-06: Pemilih meja (dine-in/takeaway/ojol), denah meja, dan alur pindah meja (`PemilihMeja.tsx` + uji unit)
   - T3-04: Tagihan terbuka (open bill) aktif & pembuatan tagihan baru (`TagihanTerbuka.tsx` + uji unit)
   - T3-05, T3-08, T3-10, T3-13, T3-15: Terminal kasir POS terpadu, modal pembayaran multi-metode (tunai dengan pecahan cepat & kembalian akurat, QRIS, kartu EDC), diskon voucher, kirim dapur, dan keadaan memuat/gagal (`LayarKasir.tsx` + uji unit)
   - T3-11: Layar pesanan pelayan mobile HP di samping meja (`LayarPelayan.tsx` + uji unit)
   - T3-12: Riwayat pesanan hari ini dengan filter status/tipe/meja (`DaftarPesanan.tsx` + uji unit)
   - T3-14 & T3-16: Uji alur kasir ujung-ke-ujung (E2E) dan uji beban ringan (<10ms per kalkulasi 50 item) (`AlurKasirE2E.test.tsx`, `BebanKasir.test.ts`)
4. **Rencana Selanjutnya:** Melanjutkan ke Fase 4 (Dapur / Kitchen Display System - KDS & Stok Dasar: M5, M9):
   - T4-01: Layar dapur (makanan) dengan urutan FIFO (`aplikasi/src/layar/dapur/LayarDapur.tsx`)
   - T4-02: Layar bar/minuman terpisah (stasiun minuman)
   - T4-03: Status item pesanan (dimasak → siap saji → diantar)
   - T4-04: Penanda waktu & peringatan pesanan lama (> 15 menit)
   - T4-05: Suara notifikasi pesanan masuk & siap saji
   - T4-06 s/d T4-10: Void/batal dapur berizin supervisor, opname stok harian sederhana, dan realtime sync

**PERBAIKAN TAMPILAN, POS 2-KOLOM, DAN PARITAS BAHASA SELESAI LENGKAP (2026-09-24):**
1. **Penyelarasan Kamus Multi-Bahasa:** 100% sinkronisasi 171 kunci di seluruh 4 bahasa (`id.ts`, `en.ts`, `zh.ts`, `ar.ts`).
2. **Design Tokens & Komponen CSS:** Penambahan variabel token di `dasar.css` dan layout kelas POS modern (`.pos-wadah`, `.pos-kiri`, `.pos-kanan`, `.katalog-wadah`, `.kategori-pills`, `.kisi-menu-grid`, `.kartu-menu`, `.keranjang-kotak`, `.pemilih-meja`, `.tipe-pesanan-grid`, `.meja-grid`, `.meja-kartu`, `.buka-kas-wadah`, `.tutup-kas-wadah`, `.kotak-rincian-kas`).
3. **Penyempurnaan Komponen UI:**
   - `LayarKasir.tsx`: Tata letak 2 kolom desktop (katalog di kiri, keranjang belanja sticky di kanan).
   - `Katalog.tsx`: Kategori pills filter, pencarian cepat, kartu menu ber-elevasi bersih, tag favorit & habis.
   - `Keranjang.tsx`: Ringkasan tagihan server-calculated, kontrol kuantitas, catatan dapur per item, tombol voucher.
   - `PemilihMeja.tsx`: Pilihan segmented Dine In/Takeaway/Ojol, denah kartu meja dengan lencana status & kapasitas tamu.
   - `BukaKas.tsx` & `TutupKas.tsx`: Formulir modal terstruktur dengan kalkulasi selisih kas dan alasan otomatis.
   - `Navigasi.tsx` & `LayarContoh.tsx`: Terjemahan 100% terhubung via i18n hook.
4. **Verifikasi Kualitas:**
   - 76 berkas uji Vitest (596 tes lulus 100%).
   - 73/73 mutasi aplikasi terbunuh (100% mutation score).
   - 89 berkas uji SQL PGlite lulus (100%).
   - `python3 aplikasi/alat/periksa-struktur.py` (29 OK, 0 GAGAL).
   - `python3 aplikasi/alat/periksa-bahasa.py` (100% paritas).
   - Build produksi Vite bersih 0 eror.

**FASE 7 T7-08 LAPORAN PENJUALAN DASAR SELESAI (2026-09-24):**
1. **Migrasi `0052_laporan_penjualan.sql`:**
   - View `public.laporan_penjualan_harian` (`security_invoker = true`): rekapitulasi penjualan per cabang per tanggal (transaksi, subtotal, diskon, pajak, service, omzet).
   - RPC `public.laporan_penjualan`: agregasi omzet per kategori menu, jenis menu (makanan, minuman, lainnya), rincian per metode bayar, batas rentang tanggal maks 90 hari, dan tren penjualan harian lengkap.
   - Pagar keamanan: `auth.uid() is not null`, izin `lihat_laporan`, wewenang pantau cabang binaan untuk admin_cabang, multi-cabang (cabang_id null) untuk owner_pusat, serta isolasi multi-tenant.
2. **Pengujian & Bukti Mutasi:**
   - Suite SQL `supabase/tes/laporan_penjualan.sql`: 95 berkas uji SQL lulus 100%.
   - Uji keamanan SQL `python3 alat/periksa-keamanan-sql.py`: search_path, ACL, RLS, InitPlan 100% lolos.
   - Uji mutasi `alat/uji-mutasi-0052.py`: 6/6 mutasi terbukti MERAH.
   - 120 gerbang CI terverifikasi utuh (`python3 alat/periksa-gerbang-ci.py`).
3. **Komponen Antarmuka & Internasionalisasi:**
   - `LaporanPenjualan.tsx` & pengujian `LaporanPenjualan.test.tsx` (9/9 tes lolos).
   - Integrasi tab laporan di `LayarLaporan.tsx` & pengujian `LayarLaporan.test.tsx` (3/3 tes lolos).
   - Kamus terjemahan 4 bahasa (`id`, `en`, `zh`, `ar`): 100% sinkron (250 kunci).
   - Total Vitest aplikasi: 82 berkas uji / 646 tes LULUS 100%.
4. **Pengingat Audit Fase 7 (§25):** Sesi ini mengingat bahwa setelah T7-12 tuntas, wajib berhenti untuk audit menyeluruh sebelum melangkah ke Fase 8.

**FASE 7 T7-09 LAPORAN MENU TERLARIS & PROMOSI SELESAI (2026-09-24):**
1. **Migrasi `0053_laporan_menu.sql`:**
   - View `public.laporan_menu_terlaris` (`security_invoker = true`): menyajikan rekapitulasi penjualan per item menu, cabang, dan tanggal.
   - RPC `public.laporan_menu(p_cabang_id, p_tanggal_mulai, p_tanggal_akhir, p_urut_berdasarkan)`:
     * Peringkat menu terlaris berdasarkan kuantitas porsi (`jumlah`) atau nilai penjualan (`nilai`).
     * Mitigasi risiko data menu: menggunakan `pi.nama_saat_itu` dari tabel `pesanan_item` sehingga laporan historis kebal terhadap perubahan nama atau penghapusan item menu.
     * Rincian diskon manual: mencakup alasan diskon, persentase/nominal, kasir pembuat, dan atasan penyetuju (jika melebihi batas kasir).
     * Rincian voucher/promo terpakai: mencakup kode promo/voucher, nilai potongan, kasir pemakai, dan penyetuju.
     * Pagar keamanan: verifikasi `auth.uid()`, hak akses `lihat_laporan`, pembatasan 90 hari, wewenang cabang binaan admin_cabang, multi-cabang untuk owner_pusat, serta isolasi penyewa.
2. **Pengujian & Bukti Mutasi:**
   - Suite SQL `supabase/tes/laporan_menu.sql`: 96 berkas uji SQL lulus 100%.
   - Uji keamanan SQL `python3 alat/periksa-keamanan-sql.py`: lolos search_path, ACL, RLS, InitPlan.
   - Uji mutasi `alat/uji-mutasi-0053.py`: 6/6 mutasi terbukti MERAH.
   - 121 gerbang CI terverifikasi utuh (`python3 alat/periksa-gerbang-ci.py`).
3. **Komponen Antarmuka & Internasionalisasi:**
   - `LaporanMenu.tsx` & pengujian `LaporanMenu.test.tsx` (12/12 tes lolos).
   - Tab navigasi Menu & Promo di `LayarLaporan.tsx` & pengujian `LayarLaporan.test.tsx` (4/4 tes lolos).
   - Kamus terjemahan 4 bahasa (`id`, `en`, `zh`, `ar`): 100% sinkron (262 kunci).
   - Total Vitest aplikasi: 83 berkas uji / 659 tes LULUS 100%.
4. **Pengingat Audit Fase 7 (§25):** Jeda wajib tetap berlaku setelah T7-12 sebelum beralih ke Fase 8.

**FASE 7 T7-10 FORMAT LAPORAN SIAP CETAK / PDF & FILTER CABANG SELESAI (2026-09-24):**
1. **Komponen Cetak & PDF `FormatLaporan.tsx`:**
   - Tata letak dokumen resmi siap cetak / simpan berkas PDF standar A4 untuk pembukuan fisik pemilik.
   - Kop Resto Barokah, judul resmi, tanggal / periode laporan, identitas cabang aktif atau konsolidasi seluruh cabang, serta waktu cetak.
   - Rincian komprehensif: ringkasan omzet & potongan pajak/service/diskon, rincian metode pembayaran, rekonsiliasi kas shift & brankas, top 5 menu terlaris, pengawasan biaya promosi dan kerugian pembatalan pesanan (void).
   - Lembar pengesahan & tanda tangan ganda: Dibuat Oleh (Kasir / Petugas) dan Diperiksa/Disetujui Oleh (Pemilik / Pengelola Resto).
2. **Filter Cabang Sesuai Peran & Pagar Keamanan:**
   - Pemilik (`owner_pusat`) dapat memilih cabang spesifik atau semua cabang via dropdown.
   - Admin cabang (`admin_cabang`) dikunci hanya pada cabang binaannya sendiri tanpa dropdown pemilih cabang (mitigasi kebocoran data lintas cabang T2-07).
3. **Gaya Cetak CSS & Aksesibilitas:**
   - Kelas styling print di `komponen.css` dengan media query `@media print` yang secara otomatis menyembunyikan bilah aksi, tombol, dan navigasi saat jendela cetak peramban terbuka (`window.print()`).
4. **Integrasi Dasbor & Pengujian:**
   - Tab "🖨️ Format Cetak / Simpan PDF" dihubungkan langsung ke `LayarLaporan.tsx`.
   - Kamus 4 bahasa (`id`, `en`, `zh`, `ar`) diselaraskan 100% (269 kunci).
   - Suite uji unit `FormatLaporan.test.tsx` (11 tes) dan `LayarLaporan.test.tsx` (5 tes) lulus 100%.
   - Total Vitest aplikasi: 84 berkas uji / 671 tes LULUS 100%.
5. **Rencana Selanjutnya:** Melangkah ke `T7-11 — Transaksi lewat tengah malam ⚠️`.

**FASE 7 T7-11 TRANSAKSI LEWAT TENGAH MALAM SELESAI (2026-09-24):**
1. **Migrasi `0054_transaksi_tengah_malam.sql`:**
   - Pelepasan default UTC `pesanan.tanggal` (`alter table public.pesanan alter column tanggal drop default;`).
   - Helper zona waktu resto: `public.zona_waktu_cabang(uuid)` dan `public.tanggal_lokal_cabang(uuid, timestamptz)` untuk mendeteksi zona waktu cabang/penyewa (default `'Asia/Jakarta'`).
   - Pemicu integritas pesanan (`picu_pesanan_jejak_jujur`): menolak tanggal sembarang dari klien dan memastikan tanggal pesanan selalu menggunakan tanggal lokal cabang operasional.
   - Penomoran pesanan operasional: nomor urut pesanan harian terisolasi per cabang dan per tanggal operasional cabang tersebut.
   - RPC `public.laporan_harian`: memotong transaksi pembayaran, pembukaan shift, dan pergerakan kas berdasarkan tanggal operasional lokal cabang (`(pb.waktu at time zone v_zona)::date = v_tanggal`), bukan tanggal UTC server.
2. **Pengujian & Bukti Mutasi:**
   - Suite SQL `supabase/tes/tengah_malam.sql`: 97 berkas uji SQL lulus 100% (uji simulasi jam 23:50 WIB dan 00:10 WIB hari berikutnya).
   - Uji mutasi `alat/uji-mutasi-0054.py`: 6/6 mutasi kritis terbukti MERAH.
   - Uji mutasi `alat/uji-mutasi-0015.py` & `alat/uji-mutasi-0051.py` diselaraskan ke definisi aktif di `0054` dan lulus 100%.
   - 122 gerbang CI terverifikasi utuh (`python3 alat/periksa-gerbang-ci.py`).
   - Total Vitest aplikasi: 84 berkas uji / 671 tes LULUS 100%.
3. **Pengingat Audit Fase 7 (§25):** Jeda wajib tetap berlaku setelah T7-12 sebelum beralih ke Fase 8.
4. **Rencana Selanjutnya:** Melangkah ke `T7-12 — Uji golden: laporan = data mentah`.

**FASE 7 T7-12 UJI GOLDEN LAPORAN = DATA MENTAH SELESAI & FASE 7 TUNTAS (2026-09-24):**
1. **Uji Golden Laporan = Data Mentah (`supabase/tes/golden_laporan.sql`):**
   - Membuktikan secara matematis & deterministik bahwa seluruh angka laporan operasional (omzet, subtotal, diskon manual, voucher, pajak, biaya layanan, metode pembayaran, omzet menu terlaris, kerugian pembatalan sesudah dapur, serta kas fisik/selisih shift) sama persis dengan agregasi langsung dari tabel mentah transaksi (`pesanan`, `pesanan_item`, `pembayaran`, `pembatalan`, `kas_pergerakan`, `shift_kas`). Selisih = 0.
   - Skenario komprehensif 1 hari operasional mencakup: transaksi reguler makan di tempat, transaksi diskon manual dengan PIN atasan, transaksi voucher, transaksi batal/void sesudah dapur (kerugian bahan), transaksi campuran, pembukaan shift kasir, dan penutupan shift kasir dengan rekonsiliasi kas.
   - Suite SQL kini memuat 98 berkas uji SQL dan seluruhnya LULUS 100% (98 LULUS · 0 GAGAL).
2. **Penyelarasan Token Desain & Pemeriksa Struktur:**
   - Menghilangkan seluruh nilai warna mentah (raw hex fallback) pada komponen antarmuka laporan & kasir (`PengingatShift.tsx`, `KoreksiModal.tsx`, `FormatLaporan.tsx`, `LaporanKas.tsx`, `LaporanMenu.tsx`, `LaporanPenjualan.tsx`, `LayarLaporan.tsx`, `komponen.css`) sehingga 100% sesuai standar token tema (`periksa-struktur.py` LOLOS).
   - Seluruh rangkaian pemeriksaan kualitas (`format:check`, `lint`, `typecheck`, `test` 84 berkas / 671 tes) lulus 100%.
3. **Pengingat Audit Menyeluruh Fase 7 (§25 REKAM_PESAN_PEMILIK.md):**
   - Fase 7 (T7-01 s.d. T7-12) resmi tuntas 100%.
   - Sesuai amanat pemilik (§25), proses pengerjaan DIJEDA untuk memberikan kesempatan kepada Lee guna melakukan audit menyeluruh atau review independen atas hasil Fase 7 sebelum menyentuh Fase 8. Dilarang lanjut ke Fase 8 tanpa persetujuan Lee.

**AUDIT INDEPENDEN AUD-4 SELESAI & PERBAIKAN DITUNTASKAN (2026-09-25):**
1. **Penerimaan 6 Laporan Audit Independen:**
   - 6 auditor independen di cabang `arena/01a0d6aa-resto-barokah` telah diperiksa dan 100% LOLOS KONTRAK integritas audit independen.
   - Domain yang diperiksa: Keamanan (2 auditor), Antarmuka (2 auditor), dan Logika Bisnis (2 auditor).
2. **Penyelesaian Temuan Nyata:**
   - Database & Keamanan: `0061_verifikasi_pin_perangkat.sql` (wajib perangkat kasir terdaftar, validasi token rahasia perangkat, anti-oracle akun, pencatatan percobaan gagal), `0047_kas_pergerakan.sql` (validasi atasan aktif tenant sama), `0046_tutup_shift.sql` (isolasi tenant pada pembayaran tunai).
   - Antarmuka & UX: Menghubungkan `LayarLaporan.tsx` di `App.tsx`, integrasi prop `onKasPergerakan`, `onKoreksiModal`, `onKirimKeDapur`, status koneksi dinamis di `Rangka.tsx`, perutean login dapur langsung.
3. **Kesiapan Handoff & Lanjut Sesi:**
   - Sesi terhubung penuh dengan `arena/01a0d09b-resto-barokah`. Jika sesi terputus, Lee cukup menunjuk sesi ini dan mengirim "baca pro.md".
**FASE 8 T8-01 RPC KATALOG PUBLIK SELESAI (2026-09-25):**
1. **RPC `public.katalog_publik` (Migrasi `0062_katalog_publik.sql`):**
   - Mengizinkan peran `anon` (pelanggan publik tanpa login) melihat menu resto berdasarkan `slug`.
   - Menghormati harga khusus cabang dan penanda menu habis per cabang (`coalesce(menu_cabang.habis, false)`).
   - Menjamin nol kebocoran data sensitif (tanpa data staf, akun, PIN, omzet, modal kas, pelanggan, atau audit internal).
2. **Pengujian & Mutasi:**
   - Suite SQL `supabase/tes/katalog_publik.sql`: 105 berkas uji SQL LULUS 100%.
   - Mutasi `alat/uji-mutasi-0062.py`: 3/3 mutasi kritis terbukti MERAH TAJAM.
   - Tercatat resmi di `docs/DECISIONS_LOG.md` (ART-10 & ART-1) dan `docs/ROADMAP.md` (T8-01 `[x]`).

**FASE 8 T8-02 HALAMAN KATALOG PUBLIK PER RESTO (MEREK SENDIRI) SELESAI (2026-09-25):**
1. **Implementasi Komponen & Layar Publik:**
   - `aplikasi/src/layar/pelanggan-publik/Katalog.tsx`: Antarmuka katalog publik mandiri dengan identitas merek resto (logo, banner, nama resto, kontak, jam operasional, badge nomor meja), filter kategori, pencarian menu real-time, lencana status habis, dan dialog QR Code.
   - `aplikasi/src/layar/pelanggan-publik/LayarPelangganPublik.tsx`: Pengambil data real dari RPC `katalog_publik` dengan penanganan keadaan memuat, keadaan kosong, dan keadaan galat terintegrasi.
   - `aplikasi/src/komponen/KomponenQr.tsx` & `aplikasi/src/lib/qrcode.ts`: Generator kode QR mandiri berbasis aljabar GF(256) & Reed-Solomon tanpa pustaka pihak ketiga.
2. **Kualitas & Pemeriksaan Fondasi:**
   - 15 pengujian unit Vitest baru lulus (total 89 berkas / 692 tes unit 100% lulus).
   - Tanpa warna mentah (`aplikasi/alat/periksa-struktur.py` LOLOS 100%), kontras tema WCAG 2.1 (166/166 LOLOS), bebas button liar (`alat/peta-ui.py` LOLOS), typecheck, format, lint, dan build bersih.

**FASE 8 T8-03 DAFTAR MENU + FOTO + HARGA + PENANDA HABIS SELESAI (2026-09-25):**
1. **Implementasi Komponen Menu & Rincian Modal:**
   - `aplikasi/src/layar/pelanggan-publik/Menu.tsx`: Komponen daftar menu berkategori mandiri yang terintegrasi langsung dengan `Katalog.tsx`.
   - Mengoptimalkan pemuatan foto dengan `loading="lazy"`, `decoding="async"`, rasio aspek tetap (mencegah CLS), dan placeholder ikon ramah bila gambar belum diunggah.
   - Format harga rupiah standar dari `lib/format`.
   - Dukungan varian rasa/ukuran dan opsi tambahan/topping dengan modal rincian `Lapis` yang mengalkulasi estimasi harga secara real-time dan interaktif.
   - Penanda habis visual dengan overlay penutup redup, lencana bahaya HABIS, keterangan stok habis di cabang bersangkutan, serta tombol sakelar filter untuk menyembunyikan/menampilkan menu habis.
2. **Kualitas & Pemeriksaan Fondasi:**
   - 6 pengujian unit Vitest baru di `Menu.test.tsx` (total 90 berkas uji / 698 tes unit lulus 100%).
   - Tanpa warna mentah (`aplikasi/alat/periksa-struktur.py` LOLOS 100%), kontras tema WCAG 2.1 (166/166 LOLOS), bebas tombol liar (`alat/peta-ui.py` LOLOS), typecheck, format, lint, dan build Vite bersih.
   - `docs/ROADMAP.md` menandai T8-03 sebagai selesai `[x]`.
**FASE 8 T8-13 LAPORAN KLAIM VOUCHER + DASAR DETEKSI ANOMALI SELESAI (2026-09-25):**
1. **Database & RPC (Migrasi `0068_laporan_voucher.sql`):**
   - View `public.laporan_voucher_ringkasan` (`security_invoker = true`): agregasi klaim, pemakaian, dan total potongan rupiah diskon per kampanye, cabang penukaran, dan tanggal.
   - RPC `public.deteksi_anomali_voucher(p_cabang_id, p_ambang_klaim)` (`security definer`): mendeteksi 4 kategori anomali:
     1. Klaim berulang berlebih (>3 klaim dari 1 identitas).
     2. Brute force / kegagalan beruntun (>=5 percobaan gagal dalam 15 menit).
     3. Pemakaian kilat (<2 menit dari saat terbit ke saat ditebus).
     4. Serapan anggaran / kuota kampanye menipis (>=80%).
   - RPC `public.laporan_voucher(p_cabang_id, p_kampanye_id, p_tanggal_mulai, p_tanggal_akhir)`: ringkasan metrik (total klaim, total terpakai, total potongan rupiah, tingkat konversi persen, rata-rata potongan), perincian per kampanye, rincian per cabang, tren harian, identitas klaim berulang (>= 2 kali), dan anomali.
2. **Frontend & Tab Laporan:**
   - Komponen `aplikasi/src/layar/laporan/LaporanVoucher.tsx` dengan filter tanggal & cabang, kartu KPI metrik utama, deteksi anomali ramah awam (status bersih jika nihil, peringatan/bahaya jika terdeteksi), tabel per kampanye, per cabang, tren harian, dan tabel klaim berulang dengan lencana 'Frekuensi Tinggi' jika > 3 kali klaim.
   - Integrasi tab 'Voucher & Promo' pada `LayarLaporan.tsx`.
3. **Pemeriksaan & Mutasi:**
   - Berkas uji SQL `supabase/tes/laporan_voucher.sql` (111 berkas uji SQL LULUS 100%).
   - Uji mutasi SQL `alat/uji-mutasi-0068.py` terbukti 7/7 mutasi kritis WAJIB MERAH.
   - Pengujian unit Vitest `LaporanVoucher.test.tsx` (13 tes) dan `LayarLaporan.test.tsx` (6 tes) LULUS 100%.
   - Uji mutasi kode aplikasi `aplikasi/alat/uji-mutasi-app.mjs` terbukti 81/81 mutasi WAJIB MERAH.
   - Pemeriksa bahasa (`periksa-bahasa.py`), struktur (`periksa-struktur.py`), peta UI (`peta-ui.py`), dan roadmap (`periksa-roadmap.py`) 100% LOLOS.
**FASE 8 T8-14 UJI LENGKAP ATURAN VOUCHER (6 KASUS WAJIB) SELESAI (2026-09-25):**
1. **Penyusunan Berkas Uji Komprehensif `supabase/tes/voucher_aturan.sql`:**
   - Membuktikan 6 kasus tepi wajib aturan voucher sesuai PRD M10 & TECH_SPEC §8:
     1. Belanja kurang dari minimum ditolak (`SUBTOTAL_KURANG`) dan berhasil saat pesanan ditambah item hingga melewati batas minimum belanja.
     2. Diskon persen dipotong tepat plafon batas nominal sampai satuan rupiah terkecil (40% dari 100.000 terpotong di plafon 25.000; 40% dari 45.555 terpotong presisi tepat 18.222 rupiah).
     3. Masa berlaku lewat ditolak (`VOUCHER_KEDALUWARSA`).
     4. Kuota harian cabang habis ditolak (`KUOTA_HARIAN_CABANG_HABIS`) dan batas anggaran kampanye habis ditolak (`ANGGARAN_KAMPANYE_HABIS`).
     5. Beda cabang ditolak bila cabang terkunci (`CABANG_TIDAK_BERLAKU`) dan berhasil pada cabang yang diizinkan.
     6. Sekali pakai ditolak jika digunakan pada pesanan berbeda (`VOUCHER_SUDAH_TERPAKAI`), serta bersifat idempoten bila dipanggil ulang pada pesanan yang sama (`IDEMPOTEN`).
2. **Penyelarasan Penanganan Waktu Operasional SQL:**
   - Menyelaraskan seluruh berkas uji SQL (`gerbang_uang.sql`, `golden_laporan.sql`, `laporan_kas.sql`, `laporan_menu.sql`, `laporan_penjualan.sql`, `nomor_pesanan_kunci.sql`, `pesanan.sql`, `pesanan_status_awal.sql`, `status_pesanan.sql`, `wajib_shift.sql`) agar menggunakan tanggal lokal cabang operasional atau menyerahkan penentuan tanggal ke peladen, sehingga kebal terhadap perbedaan tanggal UTC/WIB (17:00–24:00 UTC) tanpa mengubah timezone default peladen dan mempertahankan kepekaan uji mutasi 0054.
3. **Pemeriksaan & Gerbang Kualitas:**
   - Seluruh 112 berkas uji SQL lulus 100% (`node alat/uji-sql.mjs`).
   - Keamanan fungsi dan RLS lolos (`python3 alat/periksa-keamanan-sql.py`).
   - Buku pedoman induk tersinkron 112 berkas uji (`python3 alat/periksa-panduan.py` LOLOS).
   - Roadmap dan angka bukti valid (`python3 alat/periksa-roadmap.py` & `python3 alat/periksa-angka-bukti.py` LOLOS).
   - Seluruh struktur CSS, token, dan paritas CI 100% LOLOS.

**FASE 9 T9-02 TEMA & WARNA MEREK (10 TEMA SIAP PAKAI) SELESAI (2026-09-26):**
1. **Database & RPC (Migrasi `0071_tema_merek.sql`):**
   - Kolom `tema` (10 pilihan tema resmi: `terang`, `hangat`, `gelap`, `kontras`, `bara`, `vintage`, `alam`, `tropis`, `pastel`, `etnik`), `warna_merek` (kode heksa aksen kustom), dan `kerapatan` (`nyaman`, `padat`) pada `public.pengaturan`.
   - RPC `public.simpan_tema(p_tema, p_warna_merek, p_kerapatan, p_versi_lama)`:
     - Otorisasi ketat: `auth.uid() is not null`, peran `owner_pusat` atau staf pemegang izin `atur_pengaturan`.
     - Isolasi penyewa: `public.penyewa_saya()`.
     - Validasi ketat: hanya 10 tema resmi dan 2 kerapatan resmi.
     - Optimistic locking: menolak versi basi (`P0001`).
     - Jejak audit kekal di `public.catatan_audit` (`ubah_tema_resto`).
   - Pembaruan RPC `public.ambil_pengaturan_identitas` & `public.katalog_publik`: menyertakan tema dan warna merek ke respons publik sehingga katalog pelanggan langsung mengadopsi tema resto secara otomatis.
2. **Pengujian SQL & Mutasi:**
   - Berkas uji `supabase/tes/pengaturan_tema.sql` membuktikan 12 kasus uji (115 berkas uji SQL LULUS 100% via `node alat/uji-sql.mjs`).
   - Uji mutasi `alat/uji-mutasi-0071.py` membuktikan 7/7 mutasi fail-closed WAJIB MERAH 100%.
3. **Komponen Antarmuka & Frontend:**
   - Komponen `aplikasi/src/layar/pengaturan/Tampilan.tsx`:
     - Pemilih 10 tema resmi siap pakai dengan swatch palet warna mini berlingkup tema.
     - Pemilih kerapatan tampilan (`nyaman` untuk katalog/tablet, `padat` untuk kecepatan kasir).
     - Input kode heksa warna merek dengan validasi otomatis kontras WCAG AA (≥ 4.5:1 untuk teks normal).
     - Pratinjau langsung responsif: kartu menu, tombol aksi, lencana status, dan ringkasan kepatuhan kontras.
     - Tombol "Coba di Seluruh Layar" dan "Simpan Tema".
   - Integrasi tab navigasi di `aplikasi/src/layar/pengaturan/LayarPengaturan.tsx`.
   - Registri aksi `pengaturan.simpan_tema` terhubung dengan RPC `simpan_tema` di `aplikasi/src/lib/aksi.ts` dan tersinkronisasi di `docs/PETA_UI.md`.
   - 12 uji unit di `Tampilan.test.tsx` dan 7 uji unit di `LayarPengaturan.test.tsx` LULUS 100%.
   - Seluruh suite Vitest: 104 berkas / 824 uji unit LULUS 100%.
   - Prettier, ESLint, TypeScript (`tsc -b`), dan build produksi Vite LULUS 100%.

**FASE 9 T9-03 PENGATURAN OPERASIONAL (PAJAK, SERVICE, PEMBULATAN, CARA PESAN, STRUK) SELESAI (2026-09-26):**
1. **Database & RPC (Migrasi `0072_pengaturan_operasional.sql`):**
   - Kolom `pajak_pb1_persen` (0–100%), `service_persen` (0–100%), `pembulatan` (`none`, `100`, `500`, `1000`), `cara_pesan` (`kasir`, `mandiri`, `meja`, `campur`), `jam_buka`, `header_struk`, `footer_struk`, dan `tumpuk_diskon` pada `public.pengaturan`.
   - RPC `public.simpan_operasional`:
     - Otorisasi ketat: `auth.uid() is not null`, peran `owner_pusat` atau pemegang izin `atur_pengaturan`.
     - Isolasi penyewa: `public.penyewa_saya()`.
     - Validasi batas ketat server (ART-3): PB1 0–100%, Service 0–100%, pembulatan sah, cara pesan sah, batas panjang string wajar.
     - Optimistic concurrency locking: menolak versi lama basi (`P0001`).
     - Jejak audit kekal di `public.catatan_audit` (`ubah_operasional_resto`) lengkap dengan nilai_lama dan nilai_baru.
   - RPC `public.ambil_pengaturan_operasional`: menyajikan data konfigurasi operasional lengkap bagi staf berwenang.
   - Mitigasi Finansial Terbukti (ART-3): Nilai nominal pajak dan service charge disalin saat pesanan dibuat (`harga_saat_itu`). Perubahan tarif operasional hanya berlaku ke depan untuk pesanan baru, dan transaksi lama yang sudah lunas tidak berubah nominal uangnya sama sekali.
2. **Pengujian SQL & Mutasi:**
   - Berkas uji `supabase/tes/pengaturan_operasional.sql` membuktikan 15 kasus uji komprehensif termasuk bukti perlindungan transaksi lama dan isolasi penyewa (116 berkas uji SQL LULUS 100% via `node alat/uji-sql.mjs`).
   - Uji mutasi `alat/uji-mutasi-0072.py` membuktikan 8/8 mutasi fail-closed WAJIB MERAH 100%.
3. **Komponen Antarmuka & Frontend:**
   - Komponen `aplikasi/src/layar/pengaturan/Operasional.tsx`:
     - Pengaturan persentase PB1 dan Service Charge dengan tombol cepat tarif umum.
     - Pemilih 4 aturan pembulatan (`none`, `100`, `500`, `1000`).
     - Pemilih 4 alur cara pesan (`kasir`, `mandiri`, `meja`, `campur`).
     - Input jam operasional, header struk, footer struk, dan sakelar tumpuk diskon.
     - Kalkulator simulasi struk live sesuai rantai hitungan ART-3 (Subtotal -> Diskon -> PB1 -> Service -> Pembulatan -> Total).
     - Kartu pratinjau struk kasir real-time dan jaminan keamanan finansial.
   - Integrasi tab navigasi di `aplikasi/src/layar/pengaturan/LayarPengaturan.tsx`.
   - Registri aksi `pengaturan.simpan_pajak` dikaitkan ke RPC `simpan_operasional` di `aplikasi/src/lib/aksi.ts` dan peta UI tersinkron di `docs/PETA_UI.md`.
   - 12 uji unit di `Operasional.test.tsx` dan 8 uji unit di `LayarPengaturan.test.tsx` LULUS 100%.
   - Seluruh suite Vitest: 105 berkas / 837 uji unit LULUS 100%.
   - Uji mutasi frontend `uji-mutasi-app.mjs`: 81 mutasi fail-closed LULUS MERAH 100%.
   - Prettier, ESLint, TypeScript (`tsc -b`), dan build produksi Vite LULUS 100%.

**PENGKINIAN DAFTAR UJI MANUAL LEE (2026-09-26):**
- Mengkinikan `docs/uji/RENCANA_UJI_MANUAL.md` dari M-01 s/d M-55 (Bagian G Kasir & Laporan Fase 7, Bagian H Katalog & Voucher & Privasi Fase 8, Bagian I Pengaturan Resto Fase 9, serta sub-skenario validasi detail).
- Mengkinikan `docs/uji/BUKU_UJI_PEMILIK.md` dengan baris coba U-13 s/d U-20 lengkap dengan langkah sederhana (maksimal 5), tujuan, dan indikator berhasil/gagal yang diverifikasi `alat/periksa-buku-uji.py`.

**FASE 9 T9-04 MEJA & AREA + QR PER MEJA SELESAI (2026-09-26):**
1. **Database & RPC (Migrasi `0073_pengaturan_meja.sql`):**
   - Mitigasi pencegahan pesanan baru pada meja nonaktif via trigger fail-closed (`P0001: Meja sedang tidak aktif`).
   - RPC `public.simpan_meja(p_id, p_cabang_id, p_nama, p_area, p_aktif)`:
     - Otorisasi peran `owner_pusat` atau pemegang izin `atur_pengaturan`.
     - Isolasi penyewa melalui `public.penyewa_saya()`.
     - Validasi nama meja unik per cabang.
     - Pencegahan penonaktifan meja jika masih memiliki pesanan aktif (`dibuat`, `dimasak`, `disajikan`).
     - Jejak audit kekal di `public.catatan_audit` (`simpan_meja`) lengkap dengan data meja.
   - RPC `public.ambil_daftar_meja(p_cabang_id)`: mengambil daftar seluruh meja pada cabang terkait.
   - RPC `public.hapus_meja(p_id)`:
     - Pencegahan penghapusan meja yang memiliki riwayat pesanan (menolak fail-closed `P0001`).
     - Jejak audit kekal di `public.catatan_audit` (`hapus_meja`).
2. **Pengujian SQL & Mutasi:**
   - Berkas uji `supabase/tes/pengaturan_meja.sql` membuktikan 14 skenario kasus uji komprehensif (117 berkas uji SQL LULUS 100% via `node alat/uji-sql.mjs`).
   - Uji mutasi `alat/uji-mutasi-0073.py` membuktikan 7/7 mutasi fail-closed WAJIB MERAH 100%.
3. **Komponen Antarmuka & Frontend:**
   - Komponen `aplikasi/src/layar/pengaturan/Meja.tsx`:
     - Tata kelola meja dan area kedai dengan tab filter area dan ringkasan statistik (total meja, aktif, terisi, kosong).
     - Tombol sakelar aktif/nonaktif cepat per meja dengan pencegahan penonaktifan meja aktif.
     - Modal formulir tambah/edit meja dengan pemilihan area dan pembuatan area baru.
     - Modal kartu stand akrilik kode QR SVG siap cetak (`window.print`) dan salin tautan meja.
   - Integrasi tab navigasi 'Meja & Area' di `aplikasi/src/layar/pengaturan/LayarPengaturan.tsx`.
   - Registri aksi `pengaturan.tambah_meja` dan `pengaturan.hapus_meja` di `aplikasi/src/lib/aksi.ts` tersinkron dengan `docs/PETA_UI.md`.
   - 12 uji unit di `Meja.test.tsx` dan 9 uji unit di `LayarPengaturan.test.tsx` LULUS 100%.
   - Seluruh suite Vitest: 106 berkas / 850 uji unit LULUS 100%.
   - Prettier, ESLint, TypeScript (`tsc -b`), dan build produksi Vite LULUS 100%.
