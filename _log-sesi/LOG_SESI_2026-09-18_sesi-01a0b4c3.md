# LOG SESI — 2026-09-18 (putaran 15 · sesi `01a0b4c3`)

> Berkas ini dibaca otomatis oleh `alat/mulai-sesi.py` (baris "LOG_SESI terbaru").
> **Keadaan:** OPEN — sesi berjalan; batch pertama sudah di-commit & di-push.

## Keadaan Sesi

- **Sesi:** kerja ringan (pratinjau + perbaikan mekanisme) di cabang `arena/01a0b4c3-resto-barokah`,
  menyusul pekerjaan sesi sebelumnya (`arena/01a0a8a2-resto-barokah` @ `51feb34`).
- **Konteks masuk:** kartu sesi dibaca; KARTU SESI dilaporkan ke Lee sebelum bekerja; Lee memilih
  **jalur "nyalakan pratinjau"** + mode **maraton**. Arahan besar (verifikasi putaran / lanjut T1-24)
  masih **menunggu pilihan Lee** setelah ia melihat tampilan.
- **Model sesi ini:** tidak bisa dipastikan dari dalam sesi (Arena memilih model); dicatat apa adanya
  karena aturan mewajibkan sesi baru TIDAK mengasumsikan model sama dengan sesi sebelumnya.

## Yang dikerjakan (batch 1)

1. **Menyusul basis yang benar** — salinan lokal ternyata **mundur** ke `main` (1 commit).
   `git fetch origin arena/01a0a8a2-resto-barokah:refs/remotes/origin/kerja-terakhir` +
   `git merge --ff-only` → `51feb34` (135 commit di depan `main`). Tidak ada satu pun berkas ditulis
   ulang dari ingatan.
2. **Pratinjau dinyalakan untuk Lee** (permintaan Lee):
   - `bash aplikasi/alat/pratinjau.sh` → memasang `node_modules` (264 paket) + **Vite di port 5173**
     (layar contoh aplikasi: 10 tema + mode Nyaman/Padat). `vite.config.ts` sudah `host: true` +
     `allowedHosts: true` sehingga bisa dibuka lewat pratinjau.
   - **`prototipe/` di port 8080** (`python3 -m http.server 8080 --bind 0.0.0.0`) → 5 halaman contoh:
     awal / laporan / kasir / katalog / **galeri 10 tema**.
   - Bukti sehat: `uji-kontras.py` **166 lolos · 0 gagal** · `periksa-halaman.py` **183/183** ·
     `curl` ke 5 halaman → `200` semua.
3. **Tiga temuan saat orientasi, ketiganya nyata, ketiganya ditutup dengan mesin** (bukan janji):
   - **`alat/mulai-sesi.py` buta terhadap STATUS tidak kanonik.** `CODING_DIJEDA_SADAR` tidak cocok ke
     satu pun baris pemetaan → kartu hanya mencetak 1 skill. Sekarang: skill diambil dari
     **keluarga fase** (`CODING*`/`SIKLUS*`/`DESAIN`) + kartu mencetak `[catatan]` bila nama STATUS
     menyimpang. **Ditambah `--uji-diri` 19 kasus** (4 mutasi wajib terdeteksi).
   - **Kartu sesi melaporkan skill "TIDAK ADA" untuk direktori induk.** `skills/product-management/`
     dan `skills/product-discovery/` tidak punya `SKILL.md` di akar (isinya sub-skill) — AGENT_SYSTEM
     sudah memperingatkan ini, tapi alatnya tidak. Sekarang induk diuraikan ke sub-skillnya; dan
     `PHASE_SKILLS["FONDASI_TAHAP_1"]` ternyata menunjuk `product-discovery/journey-map` yang
     **tidak pernah ada** (nama asli: `customer-journey-map`) → diperbaiki.
   - **Nomor migrasi rencana di ROADMAP basi.** T1-24…T1-28 masih "Migrasi 0012…0016" padahal
     0012/0013/0014 terpakai penutup celah review/audit. Digeser: **T1-24→0015 … T1-36→0020**,
     rantai lama **T1-11→0021 · T1-12→0022 · T1-13→0023 · antrean→0024 · T8-15→0025**. Berkas
     migrasi yang sudah ada (0001–0014) TIDAK disentuh. Ditulis sebagai **perkiraan** + aturan
     "ambil nomor bebas pertama saat mengerjakan".
4. **Penjaga baru:** butir 8 di `alat/periksa-roadmap.py` (`cek_nomor_migrasi`) — MENOLAK tugas terbuka
   yang menunjuk nomor migrasi sudah terpakai, dengan 2 kontrol negatif (rujukan kerja ulang ke berkas
   yang ada; angka di kalimat narasi). `--uji-diri` 6 kasus. Keduanya (periksa-roadmap & mulai-sesi)
   ikut **CI** dan `periksa-semua.sh`; gerbang wajib `periksa-gerbang-ci.py` **18 → 20** + mutasi baru
   ("langkah uji-diri bootstrap sesi dihapus" → ditolak).
5. **Angka basi di dokumen:** `docs/AGENT_OPERATING_GUIDE.md` §2 menyebut "56 folder, 87 berkas
   SKILL.md" (nyata 57 / 88, dan akan berubah lagi) → angka dihapus dari dokumen, diganti rujukan ke
   keluaran `alat/mulai-sesi.py` (pelajaran B F-13 "angka bukti basi").
6. **Buku tunggu bertambah 1, disegarkan 1:** **T-020** (urutan pembuatan vs pengerasan
   `catatan_audit` antara T1-13 dan T1-27 — ditemukan saat memeriksa akibat renumber; ditandai
   `❓ T-020` di T1-27 sehingga penjaga memakainya sebagai pagar) dan **T-019** (paket audit/review)
   kini mencatat fakta terukur: paket terbaru menunjuk `cdd80b6` = **12 commit di bawah tip**, dan
   `git diff cdd80b6..HEAD` membuktikan kode aplikasi/databasis tidak berubah sejak itu (hanya
   `aplikasi/alat/periksa-semua.sh`), jadi temuan auditor tetap sah untuk kode — hanya bagian
   `ci.yml` yang perlu paket segar. **9 butir terbuka (batas 12).** Tidak ada butir yang ditutup.

## Kejujuran: satu kesalahan saya di sesi ini

- Saya pernah menulis kasus uji yang menunjuk `supabase/migrations/0013_penutup_celah_review.sql` —
  berkas itu **tidak ada** (yang ada `0012_penutup_celah_review.sql`). Pemeriksa benar, kasus uji saya
  yang salah, dan ia tertangkap oleh `--uji-diri` saya sendiri sebelum sempat menipu siapa pun.
  Dicatat karena pelajaran sesi sebelumnya persis ini: **klaim harus dijalankan, bukan diingat.**
- Langkah penanda "sesi ini belum selesai": `periksa-buku-uji`/`lanjut-sesi` MENOLAK saat pohon kerja
  kotor — itu memang rancangannya; saya tidak mengakalinya (tidak ada `--force`, tidak ada pelonggaran).

## Bukti hijau (setelah batch ini)

`node alat/uji-sql.mjs` → **41 LULUS · 0 GAGAL** · `alat/uji-mutasi-0012.py` → **16/16 MERAH** ·
`alat/uji-mutasi-0014.py` → **17/17 MERAH** · `periksa-roadmap` (+`--uji-diri`) · `periksa-fondasi-independen`
BERSIH · `periksa-temuan-audit` 27 terlacak · `periksa-gerbang-ci --uji-diri` 11/11 · `mulai-sesi --uji-diri`
19/19 · `validate_system` PASS · 76 uji unit aplikasi · build Vite bersih.

## Yang belum selesai / akan dikerjakan berikutnya

- Menunggu Lee: **(a)** kesan terhadap pratinjau (10 tema · Nyaman/Padat) dan **(b)** arah — putaran
  verifikasi (paket review + audit di tip) **atau** langsung `T1-24` (perangkat terdaftar, `0015`).
- Menawarkan jawaban butir tertangguh ke Lee (T-019 · T-018 · T-002 · T-003 · T-010 · T-011 · T-015 ·
  T-016 · **T-020**) — cukup "setuju semua" untuk yang boleh dijawab agent.
- Belum disentuh (sengaja): kode aplikasi, skema databasis, `docs/TECH_SPEC.md`, PR #1 (tidak di-merge).
