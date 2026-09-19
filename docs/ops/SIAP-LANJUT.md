# SIAP LANJUT — penunjuk keadaan untuk sesi berikutnya

> Berkas ini DIBUAT MESIN oleh `python3 alat/lanjut-sesi.py --siapkan` dan diperiksa
> `python3 alat/lanjut-sesi.py`. Jangan disunting tangan pada bagian 1–2; bagian 3
> (rencana) justru WAJIB ditulis agent dan akan dipertahankan saat disegarkan.
> Aturan kesegaran: berkas ini wajib ikut ter-commit di commit TERAKHIR setiap batch.

## 1. Keadaan sekarang (dibaca sesi baru lebih dulu)

- **Cabang yang dilanjutkan:** `arena/01a0b7d1-resto-barokah`
- **Dasar pilihan cabang:** pilihan Lee yang tersimpan di handoff sebelumnya
- **Ditulis oleh sesi:** `arena/01a0b7d1-resto-barokah`
- **Commit keadaan kerja:** `1bbc2508b36fb4149dc7470121a7060009a19517`
- **PR:** PR #2 (base main)
PR #1 (base main) — **JANGAN MERGE tanpa keputusan Lee**
- **CI terakhir:** (run 35428582314, commit 1bbc2508)
- **PERHATIAN:** CI terakhir BUKAN success — perbaiki CI lebih dulu sebelum pekerjaan baru.
- **Ditulis:** 2026-09-19 (sebelum commit yang memuat berkas ini; jadi commit keadaan di atas
  adalah induk commit ini)
- **Ruang kerja:** bersih & ter-push (dijaga pemeriksa; kalau tidak, berkas ini tidak akan lolos)
- **Berkas yang Lee salin ke chat baru:** `PROMPT_SESI_BARU.md` (STATIS — mesin memeriksanya, bukan
  menulisnya ulang tiap batch; Lee hanya mengisi baris pertama `SESI YANG AKU LANJUT`)

## 2. Keadaan proyek & butir tertangguh

- Posisi proyek: lihat `PROJECT_STATE.md` (STATUS + PUTARAN terakhir) dan `STATUS.md`.
- Bukti terakhir yang hijau: `node alat/uji-sql.mjs` · `python3 alat/uji-mutasi-0012.py` ·
  `python3 alat/uji-mutasi-0014.py` · `bash aplikasi/alat/periksa-semua.sh` · CI (lihat baris CI di atas).
- Butir tertangguh terbuka: **7** — T-018, T-002, T-003, T-010, T-011, T-015, T-016
  (rincian: `docs/TERTANGGUH.md`; hanya Lee yang boleh menutupnya)
- **Paket peninjau terbaru:** audit `AUD-3-2026-09-19.md` → `93a50bac` (4 commit di bawah HEAD saat ini) · review `PKT-2026-09-19-pr-01-putaran16.md` → `93a50bac` (4 commit di bawah HEAD saat ini) — segarkan paket SEBELUM meminta peninjau bekerja bila
  jaraknya jauh: `python3 alat/audit-independen.py --paket AUD-3 --semua` ·
  `python3 alat/review-pr.py --siapkan --pr 1 --nama pr-01-putaranNN`
- **Ruang kerja baru:** `aplikasi/node_modules` & `alat/node_modules` TIDAK ikut tersimpan di snapshot.
  Sebelum pratinjau/uji aplikasi: `bash aplikasi/alat/pratinjau.sh` (±1–2 menit). Uji SQL & pemeriksa
  Python tetap berjalan tanpa pemasangan itu.

## 2b. Kalau kamu sesi baru: cara menyusul pekerjaan ini

Sesi baru di platform ini mulai dari `main`, sedangkan pekerjaan ada di cabang sesi.
Jalankan (tanpa memindahkan cabang sesimu):

```
git fetch origin arena/01a0b7d1-resto-barokah:refs/remotes/origin/kerja-terakhir
git merge --ff-only origin/kerja-terakhir
python3 alat/mulai-sesi.py      # cetak KARTU SESI, lalu LAPORKAN ke Lee
```

Cabang `arena/01a0b7d1-resto-barokah` di atas adalah **pilihan Lee** (bukan tebakan mesin). Lee juga bebas memilih sesi
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

## 3. Rencana berikutnya (ditulis agent; DIPERTAHANKAN apa adanya saat disegarkan)

**PUTARAN 18 (2026-09-19) — LAPORAN PENINJAU SUDAH MASUK & DIPERIKSA; BERIKUTNYA: TUTUP TEMUAN `T1-45`.**

Dua laporan diterima (satu sesi peninjau `arena/01a0b85b`): AUD-3 menyeluruh (10 temuan, **laporan DITOLAK MESIN**
karena kelengkapan format — label grup cakupan diparafrase + cabang memuat 2 laporan) dan review PR putaran16
(15 temuan, **LOLOS KONTRAK**, verdict TIDAK-BERSIH). Sesi kerja sudah **membantah-balik semuanya dengan probe
sendiri: 25/25 NYATA, 0 palsu** (probe tersimpan di `docs/uji/audit/probe-2026-09-19/`; ringkasan per temuan di
`docs/uji/REVIEW_PR_RIWAYAT.md` §1b dan `docs/uji/AUDIT_RIWAYAT.md` §"2026-09-19").

**Langkah berikutnya yang wajib (urut):**
1. **Tutup temuan lewat `T1-45`**: buat `supabase/migrations/0015_penutup_celah_putaran16.sql` — mulai dari K-1
   (penanda `resto.pembatalan_*` jangan dipercaya; ganti dengan bukti baris `pembatalan` yang nyata) lalu K-2
   (diskon pada pesanan lunas/batal · void satu item jangan menutup pesanan · kebocoran `nomor_pesanan_berikutnya`
   · oracle PIN kembar · kunci kalibrasi keluar dari repo). Setelah itu K-3/K-4: gerbang CI gagal-terbuka,
   label `12/12`, tabel hantu `percobaan_masuk`, grant `service_role`/`anon`, tautan meja, generator paket audit.
2. Setiap perbaikan: uji regresi baru + `alat/uji-mutasi-0015.py` (semua mutasi WAJIB MERAH) + suite penuh hijau.
3. Dua hal menunggu keputusan Lee (jangan dikerjakan sendiri): **(a)** keluarkan docs/uji/kalibrasi/pr-bahan-2026-09-17.diff
   dari repo (kunci kalibrasi) — ini menghapus berkas, tunggu izin; **(b)** auditor diminta memperbaiki format laporan
   (label grup + satu laporan per cabang) lalu kirim ulang agar auditnya sah formal.
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

**Sesi ditutup (putaran 16, 2026-09-18)** atas perintah Lee: *"Siapkan pindah sesi dan tutup sesi ini dengan baik."*
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
3. **Lihat pratinjau** (10 tema, mode Nyaman/Padat) kalau Lee ingin menilai tampilan langsung.

Kalau Lee hanya menulis "lanjut" tanpa memilih: kerjakan **(1) penyiapan putaran verifikasi** sampai
tuntas (paket + arahan siap tempel), lalu tanyakan **satu** pertanyaan singkat: "verifikasi (jalankan
2 chat) atau langsung T1-24?" — jangan menebak di antara dua jalur besar yang tidak bisa dibatalkan.
