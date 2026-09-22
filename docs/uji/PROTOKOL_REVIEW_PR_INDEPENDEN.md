# PROTOKOL REVIEW PR INDEPENDEN (RV-1 … RV-3) — BERLAKU 2026-09-17

> Aturan resmi. Dibuat atas permintaan **Lee**: *"aku sendiri ga bisa melakukan review itu (karena aku sangat awam,
> aku bingung ketika liat komparasi file changed dan sebagainya). Tapi gimana menurut kamu? Aku mau kamu lakukan riset
> dulu agar memastikan apakah ini bagus atau tidak dan jika bagus bagaimana agar hasilnya bener2 bagus dan maksimal dan
> bagaimana cara kerja aku dan agent yang terbaik."*
> Cara Lee memicunya (langkah sederhana): `PANDUAN_PENGGUNA.md` Bagian B, alur **AL-6**.

---

## 1. Kenapa mekanisme ini ada (masalah nyata yang ditutup)

1. **Lee tidak bisa membaca diff.** GitHub menampilkan *Files changed* berisi baris kode hijau/merah — bagi orang non-teknis itu tidak bisa dinilai. Kalau satu-satunya gerbang merge adalah "Lee menekan tombol", maka gerbang itu **kosong**.
2. **Agent tidak boleh mereview PR-nya sendiri.** Riset (maker–checker, LLM self-review) menunjukkan model cenderung meloloskan pekerjaannya sendiri. Review yang dilakukan sesi yang sama = **teater**.
3. **Riset industri 2026 sepakat pada pola yang sama** (lihat §7 sumber): reviewer AI dipakai sebagai **pemberi laporan + klasifikasi risiko**, bukan pemberi "approve"; keputusan merge tetap **satu orang yang bertanggung jawab**; kedalaman review **mengikuti besar risiko**; dan gerbang harus **berbasis bukti yang bisa diukur**, bukan keyakinan.

**Kesimpulan jujur dari riset: ide Lee bagus, dan justru wajib** — dengan tiga syarat supaya tidak jadi teater:
(a) reviewer **sesi baru/model berbeda** dan **hanya-baca**; (b) kedalaman review **ditentukan tingkat risiko** (bukan "teliti" secara umum); (c) Lee menerima **kartu keputusan berbahasa sederhana**, bukan tabel teknis.

---

## 2. Tiga tingkat review PR

| Tingkat | Kapan | Siapa | Keluaran wajib |
|---|---|---|---|
| **RV-1 — Periksa mesin** | Setiap push ke PR (otomatis) | CI + `aplikasi/alat/periksa-semua.sh` | CI hijau di commit PR + uji mutasi untuk perubahan berisiko |
| **RV-2 — Review PR independen** | Setiap PR **sebelum dimintakan merge** ke Lee (wajib), dan setiap PR baru dari sesi baru | **Sesi baru, model berbeda, hanya-baca** | Laporan lolos `alat/review-pr.py --periksa-laporan` + verdict + tingkat risiko |
| **RV-3 — Kalibrasi review PR** | Sebelum pilot, dan berkala (mis. setiap 5 PR atau setiap awal fase) | Reviewer yang sama (tanpa tahu kuncinya) | Skor `Ditemukan: X dari Y` + temuan palsu, dicatat di `docs/uji/REVIEW_PR_RIWAYAT.md` |

**Gerbang merge (keputusan Lee):** PR hanya boleh dimintakan Lee untuk merge bila **semua** terpenuhi:
1. CI hijau pada commit PR terakhir (bukan commit sebelumnya);
2. RV-2 sudah dijalankan pada commit itu dan verdict-nya **BERSIH** atau **BERSIH-DENGAN-CATATAN**;
3. **Tidak ada temuan K-1/K-2 terbuka** (gerbang `tahan_semua`, sama seperti audit);
4. Untuk **PR jalur Merah** (§3): hasil kalibrasi terakhir tidak "gagal" dan laporan memuat **rencana pemulihan** + **apa yang bisa salah** dalam bahasa sederhana;
5. Lee menerima **Kartu Keputusan** (§5) — 5 baris, bahasa manusia.

Agent **dilarang** meminta Lee menekan merge tanpa 5 syarat itu. Kalau syarat belum lengkap, agent menulis di laporan batch: *"Belum boleh merge — kurang: …"*.

---

## 3. Tingkat risiko (menentukan kedalaman review)

| Jalur | Contoh berkas/perubahan | Yang wajib ada di review |
|---|---|---|
| 🔴 **Merah** | `supabase/migrations/**` · policy/RLS/izin · `docs/KEAMANAN.md` · apa pun yang menyentuh uang (kas, pembayaran, harga, diskon, laporan keuangan) · data pelanggan/PII · penghapusan data · alur pemulihan/keamanan akun · mengubah pemeriksa CI (gerbang melemahkan dirinya sendiri) | Lensa L1 (ancaman & akses) **dan** L2 (uang & jejak) **dan** L4 (mutu uji) · bukti uji mutasi (gerbang bisa MERAH) · rencana pemulihan bila salah · pernyataan eksplisit "apa yang bisa salah" + "sisa risiko" |
| 🟡 **Kuning** | logika aplikasi · Edge Functions · alat uji/pemeriksa baru · dokumen fondasi (PRD/TECH_SPEC/ROADMAP) · layar baru | Lensa L4 (mutu uji) + L3 (kesepakatan dokumen) · bukti uji yang relevan |
| 🟢 **Hijau** | dokumen non-fondasi, komentar, format, catatan sesi, aset desain, prototipe | Lensa L3 saja (kesesuaian dengan dokumen) · pemeriksaan rujukan/tautan |

**Aturan pemisahan:** PR yang mencampur banyak risiko (mis. migrasi + UI + dokumen) **wajib dipecah** atau diberi alasan kuat di paket. Reviewer berhak menolak dengan alasan "PR terlalu campur untuk dinilai" — dan itu dihitung sebagai temuan K-3.

---

## 4. Paket review (dibuat mesin, bukan diingat)

`python3 alat/review-pr.py --siapkan` menghasilkan **dua berkas** di `docs/uji/review-pr/`:

1. `PKT-<tanggal>-<slug>.md` — paket untuk reviewer: daftar berkas per jalur risiko, ringkasan perubahan **per tujuan** (bukan per berkas), klaim yang harus dibantah, perintah bukti yang harus dijalankan, format laporan, dan aturan independensi.
2. `PKT-<tanggal>-<slug>-SIAP-TEMPEL.md` — kalimat pembuka reviewer (diambil apa adanya dari `docs/uji/PROMPT_REVIEW_PR_INDEPENDEN.md` bagian B) **+ seluruh paket**. Lee cukup menyalin **satu berkas** ke chat baru.

Mesin juga menulis **Kartu Keputusan** untuk Lee (`--kartu-keputusan <laporan>`).

---

## 5. Kartu Keputusan untuk Lee (bentuk wajib)

Setelah laporan reviewer masuk, agent merangkumnya **maksimal 7 baris**:

```
PR: <nomor/nama> · commit: <sha> · jalur risiko: 🔴/🟡/🟢
Yang berubah (bahasa manusia): <1–2 kalimat>
Hasil reviewer: <BERSIH / BERSIH-DENGAN-CATATAN / TIDAK-BERSIH> · temuan K-1: <n> · K-2: <n> · K-3: <n>
Bukti utama: <uji/CI/mutasi yang dijalankan>
Sisa risiko / yang belum bisa dipastikan: <1 baris>
REKOMENDASI: <BOLEH MERGE / JANGAN MERGE DULU>
Kalau ragu: <satu tindakan konkret + siapa yang mengerjakan>
```

Aturan: rekomendasi **JANGAN MERGE DULU** wajib bila ada K-1/K-2 terbuka, CI belum hijau di commit itu, atau kalibrasi terakhir "gagal".

---

## 6. Laporan reviewer — kontrak (divalidasi mesin)

Bagian wajib (urutan tetap):
1. `## 1. Cakupan diff` — tabel: berkas · jalur risiko · diperiksa (ya/tidak) · bukti; **wajib menyebut jumlah berkas changed dan menyatakan bila ada yang tidak diperiksa**.
2. `## 2. Klaim yang dibantah` — minimal 5 klaim dari paket, masing-masing: klaim · cara membantah (perintah) · hasil nyata.
3. `## 3. Pemeriksaan gerbang` — minimal 5 permintaan: `bash aplikasi/alat/periksa-semua.sh`, `node alat/uji-sql.mjs`, uji mutasi untuk perubahan berisiko, pemeriksa dokumen, dan (untuk Jalur Merah) uji RLS/izin. Tulis keluaran nyatanya, bukan keyakinan.
4. `## 4. Temuan` — tiap temuan berkepala `### [PR-xx] Judul` + 8 bidang: Tingkat (K-1…K-4) · Artefak (berkas:baris) · Klaim yang dilanggar · Bukti (perintah → hasil) · Skenario gagal · Dugaan penyebab · **Cara membuktikan perbaikan** · Status (TERVERIFIKASI/DUGAAN).
5. `## 5. Verdict & tingkat risiko` — satu baris: `Verdict: BERSIH|BERSIH-DENGAN-CATATAN|TIDAK-BERSIH` + `Tingkat risiko: Merah|Kuning|Hijau` + alasan singkat.
6. `## 6. Yang tidak bisa saya verifikasi` — minimal 1 butir (jujur soal batas).
7. `## 7. Pernyataan tidak mengubah apa pun` — kalimat "tidak mengubah" + pernyataan **bukan sesi penulis PR** + pernyataan **laporan ini satu-satunya berkas** yang dibuat.
8. `## 8. Temuan di luar cakupan diff` — **wajib ada** (boleh "tidak ada"): temuan yang tidak berasal dari diff PR ini (berkas lain, dokumen, mekanisme) tetap dilaporkan + saran ditindaklanjuti.

**Aturan konsistensi ditegakkan mesin:** ada K-1/K-2 berstatus TERVERIFIKASI → verdict wajib `TIDAK-BERSIH`; Jalur Merah tanpa bukti uji mutasi/RLS → laporan ditolak; tanpa bagian kalibrasi (bila paket memintanya) → ditolak; klaim tanpa perintah bukti → ditolak.

---

## 6a. Aturan temuan tentang gerbang/CI + bantah-balik (ditambahkan 2026-09-17, putaran11)

**Untuk peninjau:**
1. Temuan yang menyatakan sebuah langkah CI/gerbang "tidak mengerjakan apa pun", "tidak menjalankan uji", atau "dilemahkan"
   **WAJIB** disertai **keluaran mentah** perintah yang dijalankan peninjau sendiri + kode keluar — bukan kutipan potongan kode.
2. Membaca kode boleh menjadi dugaan; dugaan bukan temuan. Tanpa eksekusi → tulis di kolom **DUGAAN**.

**Untuk sesi kerja (diwajibkan, bukan opsional):**
3. **Setiap temuan K-3 ke atas wajib dibantah ulang** (uji ulang di tip: jalankan perintahnya, suntikkan mutasi bila perlu),
   sebelum diterima sebagai cacat. Hasilnya dicatat di `docs/uji/REVIEW_PR_RIWAYAT.md` — termasuk bila temuannya **PALSU**.
4. Temuan palsu yang terbukti **tidak dihapus** dari riwayat: dicatat sebagai "temuan palsu" + bukti pembantahnya, supaya
   angka kejujuran tetap bisa diaudit (minimum = lantai, bukan target; laporan tidak boleh dirapikan agar enak dibaca).

**Kenapa ada:** putaran11 — peninjau melaporkan "CI tidak menjalankan 28 tes SQL, hanya `--daftar`". Setelah diuji, klaimnya
salah (`--daftar` tetap menjalankan seluruh uji). Akarnya: **nama opsi yang menjebak** + peninjau menyimpulkan tanpa menjalankan.
Perbaikan yang dikerjakan: langkah CI memakai perintah penuh (`node alat/uji-sql.mjs`, nama langkah "Uji SQL penuh"),
komentar `alat/uji-sql.mjs` menjelaskan bahwa `--daftar` tidak menggantikan uji, dan pemeriksa baru
`alat/periksa-gerbang-ci.py` (daftar gerbang wajibnya dihitung alat itu sendiri — **jangan menulis angkanya di dokumen, angka gampang basi**; larangan `|| true`/`continue-on-error`/ambang turun; plus uji-diri mutasi).

## 6b. Jalur pulang laporan (dikunci 2026-09-17) + aturan anti-teater

**Jalur pulang (sama seperti audit):** peninjau menulis **satu** berkas `docs/uji/review-pr/LAPORAN_*.md`, lalu
otomatis mengirimnya **tanpa meminta Lee lagi**, menggunakan `alat/kirim-laporan.py --jenis review-pr`
(draf UUID, snapshot, commit/index terisolasi, retry fast-forward). Ikuti UTUH
`docs/uji/PENGIRIMAN_LAPORAN_AMAN.md`: locator privat repo/cabang/SHA paket/path,
SHA target terpisah, wajib verifikasi remote dan bukti repo/cabang/path/commit/hash.
Chat/lokal saja bukan selesai. Cabang/working tree bisa bersama; jangan merge/rebase/
reset/force/menimpa. TERBLOKIR = simpan laporan dan status BELUM TERVERIFIKASI.
Sesi kerja menarik dengan `python3 alat/review-pr.py --ambil-laporan`, lalu memvalidasi
kontrak dan membantah-balik temuan; bukan menggabungkan kode auditor.
Alasan: laporan harus berupa **berkas di Git** (ada jejak, bisa diverifikasi, tidak hilang di chat).

**Aturan anti-teater (dikunci Lee 2026-09-17):**
1. **Ambang minimum = LANTAI, bukan target.** Berhenti tepat di ambang / menambah baris demi syarat = cacat laporan
   (mesin menandai CATATAN dan angka ambang tidak boleh dijadikan tujuan).
2. **Semua temuan wajib dilaporkan**, termasuk di luar diff (bagian 8). Cakupan menentukan sedalam apa sesuatu **wajib**
   diperiksa — bukan apa yang **boleh** dilaporkan.
3. **Dilarang menyusun laporan agar lolos pemeriksa**; format sudah lengkap di paket. Pemeriksa dijalankan sekali di akhir.

## 7. Sumber riset (kenapa aturannya begini)

| Temuan riset | Akibat di protokol ini |
|---|---|
| Vendor AI review (GitHub Copilot, Claude Code Review) secara desain **tidak pernah "approve"** — hanya komentar/neutral check, agar tidak menggantikan manusia | Reviewer kita memberi **verdict + laporan**, Lee tetap pemegang keputusan merge (§5) |
| Pola matang: klasifikasi risiko (A–D / Green–Yellow–Red) menentukan kedalaman review; "auth, payments, schema migrations, deletion paths, regulated data" = jalur wajib manusia | §3 jalur Merah/Kuning/Hijau + syarat tambahan Jalur Merah |
| "Agent must not self-approve PR it authored"; review harus dipisah dari penulis | §2 RV-2 sesi & model berbeda, hanya-baca; kalibrasi RV-3 |
| Gerbang harus **bukti terukur pada commit yang akan masuk** (tests, secrets, dependency, migration rehearsal, rollback), bukan nasihat | §2 syarat 1–4 + §6 bagian 3 (pemeriksaan gerbang dengan keluaran nyata) |
| Dua review pada PR buatan agent (pola Faire) sebelum menyentuh pemilik domain | §2: RV-1 (mesin) **dan** RV-2 (sesi independen) sebelum Lee |
| PR besar campur-risiko sulit dinilai → pecah atau blokir | §3 aturan pemisahan |
| Reviewer yang tidak dikalibrasi = keyakinan tanpa ukuran (sama seperti audit) | RV-3 kalibrasi cacat tanaman, hasil dicatat permanen |

---

## 8. Cara kerja Lee & agent (yang terbaik, dan paling sedikit merepotkan Lee)

| Siapa | Melakukan apa | Kapan |
|---|---|---|
| **Agent (sesi kerja)** | Menjaga CI hijau · menyiapkan paket review (`--siapkan`) · menulis **Kartu Keputusan** · memperbaiki temuan · **tidak pernah** meminta merge sebelum syarat lengkap | setiap batch/PR |
| **Lee** | (1) membuka **chat baru** saat agent bilang paket siap; (2) menyalin **berkas SIAP-TEMPEL**; (3) setelah reviewer selesai, kembali ke sesi kerja bilang *"laporan review sudah masuk"*; (4) membaca **Kartu Keputusan** dan memutuskan merge (atau minta perbaikan) | per PR / per fase |
| **Reviewer (sesi baru)** | Hanya-baca: memeriksa diff, menjalankan perintah bukti, menulis laporan sesuai §6, **tidak memperbaiki apa pun** | saat diminta Lee |

**Kalau Lee tidak sempat membuka sesi baru:** agent boleh melanjutkan pekerjaan yang **tidak menyentuh** PR itu, tetapi **tidak boleh** meminta merge. Ini dikatakan apa adanya di laporan batch.

---

## 9. Risiko sisa yang diakui

1. **Tidak ada jaminan 100%** — review menaikkan & mengukur deteksi, bukan menjamin kesempurnaan.
2. **Kalau platform hanya menyediakan satu keluarga model**, korelasi cacat tetap ada → dicatat sebagai keterbatasan di laporan.
3. **Kunci kalibrasi ada di sistem berkas** — kontrol proses, bukan kontrol teknis (sama seperti audit).
4. **Lee tetap pemegang keputusan tanpa bisa membaca diff** — dikompensasi Kartu Keputusan + reviewer independen + CI; tetapi keputusan akhir tetap tanggung jawab manusia, dan itu memang disengaja (riset: AI tidak boleh jadi satu-satunya penilai untuk uang/keamanan/data pelanggan).

## 10. Log keputusan dokumen ini

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-17 | Dokumen dibuat & BERLAKU; alat `alat/review-pr.py` (`--siapkan` · `--periksa-laporan` · `--kartu-keputusan` · `--kalibrasi-pr-siapkan` · `--kesiapan` · `--uji-diri`) | Permintaan Lee: mekanisme review PR independen karena ia tidak bisa membaca *Files changed*; riset industri 2026 (lihat §7) |
| 2026-09-17 | §6a **aturan temuan gerbang/CI + bantah-balik wajib** + pemeriksa `alat/periksa-gerbang-ci.py` | Temuan palsu peninjau PR-01 (putaran11): menyimpulkan CI tidak menguji apa pun dari membaca kode; dibantah dengan eksekusi (`--daftar` tetap menjalankan 28 uji) |
