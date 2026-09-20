# PROTOKOL_AUDIT_INDEPENDEN.md — Mekanisme Audit, Pemeriksaan & Review Independen

> **Status: BERLAKU sejak 2026-09-17** (permintaan pemilik: *"mekanisme audit, pemeriksaan, analisis dan review
> independen yang sangat teliti dan sangat cerdas… pastikan agent independen betul-betul jeli dan betul-betul
> menemukan masalah… Kalau ada skill yang bisa mendukung, pakai. Kalau perlu riset internet, lakukan."*)
>
> **Prinsip inti:** pembuat **tidak boleh** menjadi pemeriksa pekerjaannya sendiri. Model AI cenderung meloloskan
> karyanya sendiri walau diminta keras (riset 2026: bias "self-preference" bertahan walau diperintah kritis),
> sedangkan pemeriksa dari **sesi & model berbeda** menemukan cacat yang tak pernah terlihat pembuatnya.
> Karena itu audit **wajib** dijalankan di **sesi terpisah**, **model berbeda**, **hanya-baca**, dengan **paket** dan
> **format laporan yang divalidasi mesin**.

---

## 1. Kenapa mekanisme ini dibuat (masalah yang ditutup)

| Masalah nyata | Bukti dari riwayat proyek ini | Penutup dalam protokol ini |
|---|---|---|
| Pembuat menilai pekerjaannya sendiri | Sesi yang menulis RLS juga yang menguji RLS | §3 (sesi & model terpisah) + §5 (paket audit) |
| "Selesai" tanpa bukti | Dulu ada klaim jumlah tabel/tugas yang salah | §6 (kontrak bukti: setiap klaim wajib perintah + hasil) |
| Uji yang lulus karena **sebab yang salah** | T1-10: dua uji ditolak aturan lain, bukan aturan yang diuji | Lensa L4 + §7 (cacat tanaman kalibrasi) |
| "Teliti" tidak terukur | Tanpa ukuran, "BERSIH" hanya keyakinan | §7 (kalibrasi cacat tanaman: deteksi diukur) |
| Temuan tanpa bukti (kebisingan) | — | §6 (temuan wajib punya perintah/baris + skenario gagal) |
| Auditor ikut "memperbaiki" lalu kehilangan independensi | — | §3 larangan mengubah berkas + §6 butir 7 |
| Racun dokumen teater | — | §8 (pemeriksa laporan menolak laporan malas) |

---

## 2. Empat tingkat audit

| Tingkat | Kapan | Siapa | Keluaran wajib | Lama |
|---|---|---|---|---|
| **AUD-0 — Audit dampak** | Setiap kali sebuah **keputusan berubah** dan bisa membatalkan pekerjaan lama (mis. keamanan akun diperdalam) | Agent pembangun (boleh sesi yang sama) | `docs/uji/DAFTAR_PEKERJAAN_ULANG.md` — daftar artefak yang bertentangan + tugas ulang | ≤ 1 jam |
| **AUD-1 — Periksa batch** | Setiap batch pekerjaan, sebelum laporan ke pemilik | Mesin (pemeriksa Python, uji SQL, vitest, CI) + agent | CI hijau + uji mutasi membuktikan gerbang bisa MERAH | otomatis |
| **AUD-2 — Review independen** | Akhir setiap **fase**, atau setiap perubahan yang menyentuh **uang/keamanan/data pelanggan** | **Sesi baru, model berbeda, hanya-baca** | Laporan dengan format §6, lolos `alat/audit-independen.py --periksa-laporan` | 1 sesi |
| **AUD-3 — Audit adversarial menyeluruh** | Sebelum pilot/produksi, sebelum Fase 11 ditutup, dan **kapan pun pemilik meminta** (termasuk **audit lebih dulu** sebelum pekerjaan ulang) | **Sesi baru, model berbeda**, semua lensa + **kalibrasi cacat tanaman**, **lingkup menyeluruh** (§2b) | Laporan AUD-3 + hasil kalibrasi + verdict | 1–2 sesi |

**Aturan gerbang:** fase **tidak boleh** ditutup, dan pekerjaan bergelombang **tidak boleh** lanjut, selama masih ada temuan **K-1 (Kritis)** atau **K-2 (Tinggi)** berstatus TERVERIFIKASI. Temuan K-3/K-4 masuk daftar perbaikan fase (boleh ditunda dengan catatan).

**Pilihan gerbang (diputuskan pemilik 2026-09-17): `tahan_semua`** — temuan **K-1 dan K-2** sama-sama **menahan fase** sampai diperbaiki dan diverifikasi ulang. K-3/K-4 boleh masuk daftar perbaikan fase dengan catatan.

---

## 2b. Lingkup menyeluruh (WAJIB untuk AUD-3 — dikunci pemilik 2026-09-17)

Permintaan pemilik: *"bener-bener menyeluruh… semuanya diperiksa dan diperbaiki. bukan hanya pada hasil codingan, ataupun pada fondasi saja… termasuk file2 yang disiapkan untuk pengguna."* Karena itu AUD-3 **bukan** audit contoh:

1. **Paket dibuat dengan mode menyeluruh:** `python3 alat/audit-independen.py --paket AUD-3 --semua` → mesin menuliskan **seluruh grup berkas proyek** (kode aplikasi · migrasi & uji SQL · Edge Functions · perkakas repo · mesin kerja agent `_sistem/` · dokumen fondasi · dokumen uji/audit · dokumen teknis & operasional · desain & prototipe · **berkas untuk pengguna di akar repo** · CI) beserta jumlah berkas nyatanya.
2. **Berkas untuk pengguna wajib diperiksa dengan cara pengguna:** buku induk `PANDUAN_PENGGUNA.md`, `PROMPT_ENTRI_UNIVERSAL.md`, `PROFIL_PENGGUNA.md`, `START_DI_SINI.md`, `AGENT_SYSTEM.md`, `STATUS.md`, `PROJECT_STATE.md`, `docs/PANDUAN_PEMILIK.md`, `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`, `docs/teknis/BUKU_INSIDEN.md`, `docs/ops/*`. Auditor wajib menjawab: apakah langkahnya bisa diikuti orang non-teknis? apakah prompt bisa disalin apa adanya dan benar-benar bekerja? apakah ada langkah menyebut berkas/perintah yang tidak ada? **apakah buku induk benar-benar lengkap** (semua mekanisme + semua prompt ada)?
3. **Laporan wajib memuat** `- **Mode cakupan:** menyeluruh`, ringkasan `Cakupan menyeluruh: X dari Y berkas`, satu baris bukti untuk **setiap** grup berkas di paket, dan sub-bagian **`### 1a. Berkas untuk pengguna`**. Mesin **menolak** laporan yang lupa salah satunya, atau yang cakupannya < 90% berkas.
4. **Berkas yang dikecualikan** (kumpulan skill pihak ketiga `skills/`, `_salinan-meta/`, `_Notes.md`) wajib disebut auditor + alasan setuju/tolaknya — bukan diam-diam dilewati.
5. **Temuan yang wajib diperbaiki lebih dulu**: selain K-1/K-2, setiap langkah pengguna yang **tidak bisa dijalankan apa adanya** (salah rujukan, perintah tidak ada, prompt yang menuntun ke jalan buntu) diperlakukan minimal **K-2**. Buku pedoman yang basi = temuan, bukan kerapian.

**Penjaga mekanisme ini:** `alat/periksa-panduan.py` (ikut CI, bersama `--uji-diri`) memastikan buku induk tetap lengkap — bagian A–H ada, topik wajib ada, ≥10 mekanisme terdaftar, blok **Prompt Pembuka** identik dengan `PROMPT_ENTRI_UNIVERSAL.md`, blok **Prompt Auditor** identik dengan berkas kanonik, dan **semua rujukan berkas ber-backtick benar-benar ada** (kecuali ditandai `(rencana)`). Tanpa penjaga ini, buku induk akan basi pelan-pelan — persis jenis cacat K-3 yang paling sulit dilihat.

---

## 3. Aturan independensi (wajib, tidak bisa ditawar)

1. **Sesi terpisah.** Auditor bekerja di **sesi/percakapan baru** — bukan sesi yang menulis kode itu.
2. **Model berbeda bila tersedia.** Bila platform memungkinkan memilih model lain (atau sub-agent dengan instruksi & konteks berbeda), gunakan. Bila tidak, wajib dicatat di laporan sebagai **keterbatasan** (jangan diklaim lebih kuat dari kenyataan).
3. **Hanya-baca.** Auditor **dilarang** mengubah, memperbaiki, atau menerapkan perbaikan apa pun — temuan ditulis, bukan dibetulkan. Perbaikan dilakukan pembangun **setelah** laporan selesai.
4. **Buta pada pembenaran.** Auditor menerima **paket audit** (§5) berisi klaim pembangun, tetapi tugasnya **membantah** klaim itu, bukan membaca lalu mempercayainya.
5. **Tidak boleh menjadi kepribadian "ramah".** Dilarang memuji, dilarang "looks good", dilarang melaporkan soal gaya penulisan sebagai temuan. Laporan yang tidak punya temuan **sah** — asalkan **angka usahanya** (jumlah artefak, serangan, klaim yang diuji) memenuhi minimum §6.
6. **Refutasi sebelum lapor.** Setiap calon temuan wajib diuji ulang di kode **sebagaimana adanya sekarang** (buka berkasnya, telusuri pemanggilnya, jalankan perintahnya). Kalau tidak bisa dibuktikan → tulis sebagai **DUGAAN**, bukan TERVERIFIKASI.

---

## 4. Lensa (Perspective-Based Reading) — dipakai sesuai tingkat

Riset *Perspective-Based Reading*: reviewer dengan **skenario tertentu** menemukan cacat jauh lebih banyak daripada reader "ad hoc"/daftar periksa biasa. Karena itu auditor **wajib** memakai lensa, dan setiap lensa punya pertanyaan pemicu.

| Lensa | Nama | Pertanyaan pemicu (wajib dijawab) |
|---|---|---|
| **L1** | Ancaman & Akses | Bisakah orang tanpa hak masuk/naik peran? Bisakah sesi/perangkat yang dicabut masih dipakai? Apakah ada fungsi istimewa (`security definer`) yang bisa dipanggil siapa saja? Apakah ada jalur yang membaca data penyewa lain? |
| **L2** | Uang & Jejak | Bisakah angka uang dibuat/ubah/hapus dari klien? Bisakah pembayaran dobel, void tanpa jejak, diskon lewat batas, kas tanpa shift? Apakah jejak audit benar-benar tak bisa diubah dan bisa mendeteksi penghapusan? |
| **L3** | Kesepakatan Dokumen | Setiap janji PRD/TECH_SPEC punya kode **dan** uji? Setiap klaim "Bukti" di ROADMAP **bisa direproduksi hari ini**? Ada syarat tanpa uji (orphan requirement) atau uji tanpa syarat (orphan test)? |
| **L4** | Mutu Uji | Ada uji yang lulus karena **sebab yang salah**? Negatif-test yang bisa ditolak banyak sebab? Uji yang tidak memeriksa apa pun? Gerbang yang belum pernah dibuktikan bisa MERAH? Ada bagian yang diuji dengan tiruan padahal bisa nyata? |
| **L5** | Lapangan & UI | Alur nyata di tablet kasir bisa selesai? Tujuh keadaan (kosong/memuat/gagal/antre/putus/tanpa-akses/berhasil) tertangani? Ada tombol yang tidak melakukan apa pun atau aksi tanpa tombol? Pesan galat bahasa manusia + kode? Target sentuh & kontras? Printer/offline? |
| **L6** | Privasi & Kepatuhan | Data pelanggan seminimal mungkin? Persetujuan sebelum simpan? Anonimisasi tanpa menghapus catatan keuangan? Jalur kebocoran 3×24 jam siap? Rahasia tidak pernah masuk repo/log? |

**Kombinasi minimum:** AUD-2 → **L1 + L3 + L4** (atau L2 menggantikan L3 bila lingkupnya uang). AUD-3 → **semua enam lensa**.

---

## 5. Paket audit (dibuat mesin, bukan diingat)

Selain paket, mesin menulis **berkas siap-tempel** `<paket>-SIAP-TEMPEL.md`: kalimat pembuka auditor (diambil apa adanya
dari `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` bagian B — bukan disalin tangan) + seluruh paket. Pemilik cukup menyalin
**satu berkas** ke chat baru; ini menutup kegagalan praktis "pemilik hanya menempel separuh berkas".

Perintah: `python3 alat/audit-independen.py --paket AUD-2 --tugas T1-01..T1-10`
Keluaran: berkas paket di docs/uji/paket-audit/ berisi:

1. **Lingkup**: tugas/fase, commit, berkas yang diperiksa (dari atribut `File:` ROADMAP).
2. **Klaim pembangun yang harus dibantah**: seluruh teks `Bukti` pada tugas dalam lingkup + klaim jumlah/statistik.
3. **Lensa + skenario** yang wajib dijalankan (sesuai tingkat).
4. **Perintah bukti** yang disarankan (`node alat/uji-sql.mjs`, pemeriksa Python, `npm test`, dst.).
5. **Skill yang wajib dimuat** auditor (berkas nyata di repo — lihat §9).
6. **Format laporan** (salin dari §6) + aturan independensi (§3).
7. **Perintah validasi** laporannya sendiri: `python3 alat/audit-independen.py --periksa-laporan <berkas>`.

---

## 5b. Independensi terhadap base branch (dikunci 2026-09-17)

Pertanyaan Lee: *"kamu ga jelasin aku harus buat sesi baru dengan base branch apa… klo bisa, aku lebih suka klo mekanisme ini dibuat ga perlu nentuin base branch secara presisi."*

**Jawabannya: ya, bisa — dan tetap maksimal.** Yang menentukan hasil audit bukan cabang, melainkan **commit**:

1. Mesin menulis **commit target** di setiap paket audit (`- **Commit yang diaudit:** <sha>`), dan paket memuat **LANGKAH 0 (wajib)** beserta perintah verifikasinya.
2. Auditor menjalankan `python3 alat/audit-independen.py --verifikasi-lingkup` (atau perintah manual `git rev-parse HEAD` + `git cat-file -e <sha>`).
   - **Cocok** → lanjut mengaudit.
   - **Beda commit tetapi target ada** → `git fetch origin && git checkout --detach <sha>` (hanya-baca) lalu lanjut.
   - **Target tidak ada** → `git fetch origin` sekali lagi; kalau tetap tidak ada, auditor **berhenti dan melaporkan** — bukan mengaudit commit lain. Alasan: mengaudit commit yang salah lebih berbahaya daripada tidak mengaudit, karena menghasilkan rasa aman yang palsu.
3. Laporan tetap mencatat branch/commit apa yang **benar-benar** diperiksa; mesin memvalidasi commit itu ada di repo.

**Konsekuensi untuk Lee:** Lee boleh memilih base branch **mana pun** yang paling mudah (cabang sesi ini, `main`, atau cabang lain) — paket akan mengarahkan peninjau ke commit yang tepat. Satu-satunya syarat: repo yang dipakai peninjau **memuat** commit itu (kalau sesi dibuka dari `main` sementara pekerjaan belum di-merge, `git fetch origin` + `checkout --detach` menyelesaikannya).

## 5c. Bagaimana laporan kembali ke sesi kerja (dikunci 2026-09-17)

**Masalah yang ditutup (pertanyaan Lee):** auditor bekerja di **ruang kerja sendiri** — sesi kerja **tidak bisa melihat**
berkas di sana. Tanpa jalur pulang, laporan bisa hilang di chat, dan Lee harus menyalin manual.

**Jalur resmi (dua arah, keduanya wajib ada di paket & prompt):**
1. Auditor menulis **satu** berkas: `docs/uji/audit/LAPORAN_<TINGKAT>_<tanggal>_<lingkup>__<penanda-sesi>.md`
   (satu-satunya berkas yang boleh ia buat). `<penanda-sesi>` = potongan nama cabang sesi auditor, supaya dua sesi
   auditor tidak memakai nama berkas yang sama (kejadian 2026-09-17 — laporan pertama hampir tertimpa). Bila tetap
   bertabrakan, penarik laporan menyimpannya terpisah sebagai `<nama>.dari-<cabang>.md`; tidak ada laporan yang ditimpa.
2. Auditor **commit + push HANYA berkas itu** ke **cabang sesinya sendiri** (`arena/...` yang diberikan platform):
   `git add docs/uji/audit/ && git commit -m "laporan audit ..." && git push -u origin HEAD`
3. Sesi kerja (pembangun) menjalankan `python3 alat/audit-independen.py --ambil-laporan`, yang:
   mencari **semua cabang `arena/*`** di GitHub, menemukan berkas `docs/uji/audit/LAPORAN_*.md` yang belum ada di sesi ini,
   mengambilnya, dan menaruhnya di `docs/uji/audit/`.
3b. **Dua sesi bisa berbagi SATU cabang** (kejadian nyata 2026-09-17: dua sesi paralel push ke cabang yang sama dengan
   nama berkas yang sama; versi pertama lalu hanya hidup di **riwayat commit**). Karena itu penarik laporan menelusuri
   **seluruh riwayat** berkas laporan di tiap cabang — bukan hanya ujung cabang — dan versi yang tertimpa diselamatkan
   sebagai `<nama>.dari-<penanda-cabang>-<commit8>.md`. **Tidak ada laporan yang hilang atau ditimpa.**
4. Sesi kerja memvalidasi tiap laporan (`--periksa-laporan`), menilai kalibrasi (`--kalibrasi-nilai`), lalu menindaklanjuti.

**Kalau auditor tidak bisa push** (mis. izin): auditor menulis di laporan "belum ter-push" dan menempelkan laporan di chat;
Lee menyalinnya ke berkas di `docs/uji/audit/` (agent boleh membuatkannya kalau Lee menempel teks laporan di sesi kerja).

**Kalau base branch sesi audit bukan cabang sesi kerja:** tidak masalah — laporan tetap diambil dari cabang auditor (§5b).

**Kenapa begini:** laporan menjadi **berkas di Git** (bisa diverifikasi, ada jejaknya, tidak hilang), dan Lee tidak perlu
menyalin apa pun kecuali bila push gagal.

## 6. Kontrak laporan (divalidasi mesin — tanpa ini audit tidak diakui)

Judul & kepala laporan wajib memuat: Auditor · Tanggal · Tingkat audit · **Commit yang diaudit (SHA penuh)** ·
Paket audit · Verdict (`BERSIH` / `BERSIH-DENGAN-CATATAN` / `TIDAK-BERSIH`).

Tujuh bagian wajib, dengan nama **persis**:

1. `## 1. Cakupan` — tabel: artefak · diperiksa? · **bukti** (perintah/baris). Minimum 6 baris.
2. `## 2. Klaim pembangun yang saya coba falsifikasi` — tabel: klaim · cara uji · hasil. Minimum 5 baris.
3. `## 3. Serangan yang dijalankan (kill attempts)` — tabel skenario · cara · hasil. Minimum 5 (AUD-2) / 12 (AUD-3).
4. `## 4. Temuan` — tiap temuan berkepala `### [F-xx] Judul` dengan **delapan bidang**:
   `Tingkat` (K-1…K-4) · `Artefak` (berkas:baris) · `Klaim yang dilanggar` · `Bukti` (perintah → hasil nyata) ·
   `Skenario gagal` · `Dugaan penyebab` · `Cara membuktikan perbaikan` (perintah yang harus hijau) ·
   `Status verifikasi` (`TERVERIFIKASI` / `DUGAAN`). Bila tidak ada temuan → tulis `(tidak ada temuan)`.
5. `## 5. Kalibrasi cacat tanaman` — **wajib untuk AUD-3**: `Ditemukan: X dari Y`, daftar cacat yang ditemukan, dan jumlah temuan palsu.
6. `## 6. Yang tidak bisa saya verifikasi` — minimum 1 butir (jujur soal batas: tanpa akun Supabase, tanpa peramban, dsb.).
7. `## 7. Pernyataan tidak mengubah apa pun` — kalimat berisi "tidak mengubah" + pernyataan bahwa **laporan ini satu-satunya berkas** yang dibuat auditor (sehingga kewajiban menulis laporan tidak bertabrakan dengan aturan "hanya-baca") + bukti `git status --short` yang menampilkan hanya berkas laporan.
8. `## 8. Temuan di luar cakupan` — **wajib ada** (boleh "tidak ada"). Cakupan menentukan sedalam apa sesuatu **wajib** diperiksa, **bukan** apa yang boleh dilaporkan: setiap temuan yang ditemukan di luar cakupan/lensa tetap ditulis di sini beserta bukti + syarat ditindaklanjuti.

**Aturan anti-teater (dikunci Lee 2026-09-17):**
- **Ambang minimum = LANTAI, bukan target.** Berhenti tepat di ambang atau menambah baris demi syarat = cacat laporan (mesin menandainya sebagai CATATAN).
- **Dilarang menyusun laporan agar lolos pemeriksa.** Format sudah lengkap di paket; membaca kode alat pemeriksa untuk menyesuaikan laporan adalah teater. Pemeriksa dijalankan **sekali di akhir**; bila ditolak, perbaiki kelengkapan format — bukan menambah temuan yang tidak diyakini.
- **Temuan di luar cakupan wajib dilaporkan** (bagian 8) — temuan yang benar tidak boleh hilang hanya karena tidak diminta.

**Aturan konsistensi yang ditegakkan mesin:**
- Ada temuan **K-1/K-2** berstatus TERVERIFIKASI → verdict **wajib** `TIDAK-BERSIH` (laporan "BERSIH" ditolak mesin).
- Verdict `BERSIH` pada AUD-3 hanya sah bila **semua cacat tanaman K-1/K-2 ditemukan** dan **≥70%** total ditemukan.
- Setiap temuan TERVERIFIKASI wajib punya perintah bukti; temuan K-1/K-2 wajib punya `Skenario gagal`.

---

## 7. Kalibrasi cacat tanaman (jantung kejujuran mekanisme ini)

Riset *defect injection*: kemampuan pemeriksa **diukur** dengan menyuntikkan cacat yang jawabannya sudah diketahui. Tanpa ini, "BERSIH" hanya keyakinan.

Ada **dua jalur kalibrasi** — keduanya wajib, karena keduanya mengukur hal berbeda:

| Jalur | Mengukur | Bahan | Kunci jawaban |
|---|---|---|---|
| **Mesin** | apakah pemeriksa otomatis menangkap cacat berbahaya | salinan `git archive` **tanpa riwayat Git & tanpa katalog** (sejak 2026-09-20) | di luar repo (`/tmp/...-KUNCI.md`) |
| **Auditor** | apakah auditor (manusia/AI) tajam | folder `docs/uji/kalibrasi/bahan-<tanggal>/` **ikut ter-commit** | di luar repo; **tidak pernah** ditulis di repo atau diberikan ke auditor |
| **Review PR** | apakah peninjau tajam saat mengulas **perubahan nyata** | bahan `pr-bahan-<tanggal>.diff` — berkasnya **di luar repo**, isinya disematkan ke paket review | di luar repo (`/tmp/KUNCI-KALIBRASI-PR-<tanggal>.md`) |

**Cara kerja jalur mesin (dijalankan pembangun, dinilai setelah audit):**

1. Pembangun menjalankan: `python3 alat/audit-independen.py --kalibrasi-siapkan`
   → menyalin HEAD lewat `git archive` (salinan dibuat ulang jadi satu commit, **tanpa riwayat Git**
   dan **tanpa berkas katalog cacat** — audit H F-01), **menanam 6 cacat** dari katalog cacat
   (campuran K-1…K-4; ada yang seharusnya ketangkap mesin, ada yang hanya ketangkap penalaran),
   → menulis **kunci jawaban di luar repo** (`/tmp/...-kunci.md`, tidak boleh dibaca auditor).
2. Auditor memeriksa salinan itu **seperti kode sungguhan** (tanpa tahu kuncinya).
3. Setelah laporan masuk: `python3 alat/audit-independen.py --kalibrasi-nilai <laporan> --kunci <kunci>`
   → menghitung **tingkat deteksi** (per tingkat bahaya), **temuan palsu**, dan memutuskan
   `TERKALIBRASI` / `BELUM TERKALIBRASI`.

**Cara kerja jalur auditor (dipakai untuk AUD-3 — bisa lintas sesi):**

1. Bahan kalibrasi ada **di dalam repo**: `docs/uji/kalibrasi/bahan-<tanggal>/` (berisi cacat yang disengaja,
   termasuk cacat pada **dokumen untuk pengguna** — kelas yang paling sering lolos).
   Ini perbaikan cacat mekanisme yang ditemukan 2026-09-17: bahan di `/tmp` **tidak ikut berpindah** ke ruang kerja
   sesi auditor, sehingga kalibrasi tidak bisa dijalankan lintas sesi.
2. Paket audit menyuruh auditor: *"folder `bahan-*/` berisi cacat yang disengaja — temukan; kamu tidak diberi tahu
   berapa jumlahnya, di berkas mana, atau kelasnya. Cacat di folder itu tidak dihitung sebagai temuan proyek."*
   (Pengungkapan "ada cacat di sini" itu **sengaja**: yang diuji kerahasiaannya adalah **lokasi & jumlah**, bukan
   keberadaan latihannya.)
3. Setelah laporan masuk, pembangun mencocokkan bagian `## 5. Kalibrasi cacat tanaman` dengan kunci di luar repo
   → `Ditemukan: X dari Y` + temuan palsu; hasilnya masuk `docs/uji/AUDIT_RIWAYAT.md`.
4. Bahan **berbeda setiap audit** (nama folder bertanggal). Bahan lama tidak dihapus — supaya tidak ada audit yang
   memakai bahan yang jawabannya sudah bocor di riwayat.

**Cara kerja jalur review PR (bahan di luar repo sejak 2026-09-19 — audit D F-05):**

1. Pembangun menjalankan `python3 alat/review-pr.py --kalibrasi-pr-siapkan` → bahan ditulis **di luar repo**
   (`/tmp/kalibrasi-pr/pr-bahan-<tanggal>.diff`, bisa dipindah lewat env `KALIBRASI_PR_DIR`), kunci jawaban di
   `/tmp/KUNCI-KALIBRASI-PR-<tanggal>.md`.
2. `python3 alat/review-pr.py --siapkan` **menyematkan ISI bahan** ke paket review (§5) dan **menolak** membuat paket
   bila bahan/ kunci masih ada di dalam repo. Peninjau tetap bisa menjalankan latihan: simpan blok diff ke
   `/tmp/pr-bahan.diff`, salin repo ke `/tmp`, `git apply` di salinan itu.
3. **Kenapa bahan ini tidak boleh di dalam repo:** diff-nya dibuat dari migrasi **NYATA**, jadi siapa pun yang bisa
   membaca repo — termasuk peninjau yang sedang dikalibrasi — langsung tahu baris mana yang ditanami cacat; skor
   `Ditemukan: X dari Y` bisa dipalsukan. Dijaga `alat/periksa-kunci-kalibrasi.py` (aturan A–E, plus `--uji-diri`).
4. **Berkas yang dikeluarkan dari repo berjejak:** jalurnya dicatat di daftar pensiun `docs/uji/BERKAS_PENSIUN.md` (dijaga `alat/periksa-kunci-kalibrasi.py` aturan D1) — rujukan lama di riwayat/paket/laporan tetap sah sebagai provenance.
5. **Rotasi bahan:** bahan kalibrasi yang pernah bocor — termasuk yang masih terbaca di riwayat Git —
   **tidak dipakai lagi** untuk menilai ketajaman; gantinya bahan baru bertanggal (sama seperti jalur auditor).

**Paket hanya menargetkan commit ber-CI hijau (audit H F-02, K-3, 2026-09-20):**

Protokol ini sudah lama mewajibkan "commit ber-CI hijau", tetapi **tidak ada yang menegakkannya**: paket AUD-3
2026-09-19 menargetkan commit `4830b5a` yang dua run CI-nya `cancelled` (ditimpa push berikutnya). Akibatnya
auditor memeriksa pohon yang **tidak pernah** melewati gerbang otomatis, sementara paketnya tampak terverifikasi.

1. **Pembuat paket menolak jalan** bila CI commit target belum hijau — baik `alat/audit-independen.py --paket`
   maupun `alat/review-pr.py --siapkan` membaca status itu lewat `alat/ci_target.py` (bertanya ke GitHub Actions).
2. **Status itu ditulis di dalam paket** sebagai baris `- **CI commit target:** success (run …) …` — jadi pembaca
   paket (pemilik/auditor) melihat dasarnya, bukan mengira-ngira.
3. **Pengecualian hanya dengan izin pemilik:** `--izinkan-ci-belum-hijau "<alasan>"`; izin itu **ditulis di paket**
   sebagai baris `- **Izin pemilik untuk commit non-hijau:** …`. Tanpa baris itu, `alat/periksa-paket.py` **menolak**.
4. **Klaim yang tidak cocok dengan kenyataan ditolak:** penjaga memeriksa ulang ke GitHub — paket yang menulis
   "success (run …)" padahal commitnya tidak hijau **ditolak** (dijaga `--uji-diri`).

**Kunci jawaban tidak boleh terbaca dari repo (audit H F-01, 2026-09-20 — K-2):**

Katalog cacat memuat pasangan `cari`/`ganti` = **kunci jawaban**. Selama ia hidup di dalam repo, peninjau/
auditor yang membaca repo (memang pekerjaannya) bisa mencocokkan cacat yang ditanam lalu menulis skor kalibrasi
yang sempurna tanpa mengulas sungguhan. Perbaikan yang sudah berlaku:

1. **Jalur mesin:** salinan auditor dibuat ulang tanpa riwayat Git dan **katalog cacat dikeluarkan dari salinan**
   (`pastikan_salinan_bersih()` menolak salinan yang masih membawa katalog/berkas kunci atau perubahan
   belum di-commit). Sebelum ini, `git diff` di salinan **langsung memperlihatkan** baris yang ditanam.
2. **Jalur review PR:** alat penyiap **hanya** membaca katalog dari **luar repo** (`KALIBRASI_DIR`, baku
   `/home/user/.kalibrasi`). Bila katalog masih di dalam repo, perintahnya **GAGAL-tertutup** (menolak membuat
   bahan) daripada menerbitkan bahan yang bisa dicocokkan.
3. Dijaga mesin: `alat/periksa-kunci-kalibrasi.py` aturan F & G (+3 mutasi uji-diri).
4. **Katalog cacat sudah DIPINDAH ke luar repo** (keputusan Lee 2026-09-20, atas temuan H F-01): berkasnya hidup di
   `KALIBRASI_DIR` (baku `/home/user/.kalibrasi/kalibrasi-cacat.json`) dan jalurnya berjejak di
   `docs/uji/BERKAS_PENSIUN.md` baris #2. Salinan lama masih ada di riwayat Git, jadi katalog versi lama **tidak
   dipakai lagi** untuk menilai ketajaman. Alat membaca katalog dari luar repo dan **menolak jalan** bila tidak ada
   (gagal-tertutup); `alat/periksa-kunci-kalibrasi.py` aturan **A2** menolak bila katalog muncul lagi di dalam repo.

**Ambang & pencatatan (berlaku untuk kedua jalur):**

- Ambang §7: **semua cacat K-1/K-2 wajib ditemukan** + **≥70% total** + **0 temuan palsu** → `TERKALIBRASI`.
- Hasil kalibrasi **dicatat permanen** di `docs/uji/AUDIT_RIWAYAT.md` (tren deteksi lintas audit).
- Katalog/bahan cacat **tumbuh**: setiap cacat nyata baru yang lolos ke repo wajib ditambahkan sebagai butir kalibrasi baru (praktik *"defects → inspection scenarios"*).

---

## 8. Pemeriksa laporan (anti-teater)

`python3 alat/audit-independen.py --periksa-laporan docs/uji/audit/LAPORAN_*.md` menolak laporan yang:
tidak punya bagian wajib · tidak punya SHA · bukti kosong · terlalu sedikit artefak/serangan/klaim · temuan tanpa
perintah bukti · verdict tidak konsisten dengan temuan · AUD-3 tanpa kalibrasi. Pemeriksa ini **sendiri diuji**
(`--uji-diri`) dengan laporan contoh bagus & tiga laporan sengaja buruk — kalau pemeriksa tidak bisa MERAH,
mekanismenya dianggap belum terpasang.

---

## 9. Skill & riset yang wajib dipakai auditor

Dimuat dari repo (berkas nyata, bukan ingatan):

| Skill | Berkas | Untuk lensa |
|---|---|---|
| Security review | `skills/security-review/SKILL.md` | L1, L6 |
| Systematic debugging | `skills/systematic-debugging/SKILL.md` | L4, akar masalah temuan |
| Verification before completion | `skills/verification-before-completion/SKILL.md` | §6 semua klaim bukti |
| Verification loop | `skills/verification-loop/SKILL.md` | urutan periksa (bangun → tipe → uji) |
| Test-driven development | `skills/test-driven-development/SKILL.md` | L4 |
| PRD/taskmaster | `skills/prd-taskmaster/SKILL.md` | L3 jejak syarat → tugas → uji |
| Supabase + Postgres best practices | `skills/supabase/SKILL.md`, `skills/supabase-postgres-best-practices/SKILL.md` | L1, L2 |
| UI/UX | `skills/ui-ux-pro-max/SKILL.md` | L5 |

Auditor **wajib**: (a) memuat skill di atas yang relevan dengan lensanya; (b) memakai `skills/find-skills` atau
`skills/agent-skills-hub` bila butuh skill tambahan; (c) **boleh & dianjurkan** mencari referensi internet
(dokumentasi resmi Supabase/PostgreSQL/OWASP, riset cacat perangkat lunak) dan **wajib mencantumkan tautannya**
di laporan untuk klaim yang bersandar pada perilaku sistem luar.

---

## 10. Alur lengkap (dari pemicu sampai tuntas)

```
PEMILIK/AGENT memutuskan audit (lihat §11)
   ↓
Agent pembangun: siapkan paket (--paket)  [AUD-3: + --kalibrasi-siapkan]
   ↓
PEMILIK membuka SESI BARU (model berbeda) & menempelkan PROMPT_AUDIT_INDEPENDEN (§12)
   ↓
Auditor: jalankan lensa → kumpulkan temuan → refutasi → tulis laporan (§6)   [hanya-baca]
   ↓
Mesin: --periksa-laporan (tolak bila malas/tidak konsisten)  [+ --kalibrasi-nilai untuk AUD-3]
   ↓
Agent pembangun: masukkan temuan ke ROADMAP sebagai tugas perbaikan (K-1/K-2 = menghentikan fase)
   ↓
Perbaikan → uji ulang → **auditor yang sama** (atau sesi independen baru) memverifikasi temuan tertutup
   ↓
Verdict & hasil kalibrasi dicatat di docs/uji/AUDIT_RIWAYAT.md; temuan K-1/K-2 wajib ditutup sebelum lanjut
```

**Batas putaran:** maksimum **2 putaran** audit-perbaikan untuk lingkup yang sama. Bila putaran ke-3 masih ada K-1/K-2,
pekerjaan **dihentikan** dan pemilik diberi penjelasan bahasa sederhana (3 pilihan + rekomendasi).

---

## 11. Kapan audit dijalankan (pemicu)

1. **Otomatis:** akhir setiap fase (AUD-2) · sebelum tugas bertanda uang/keamanan/data pelanggan di-`[x]` (AUD-2 pada perubahan itu) · sebelum pilot & sebelum Fase 11 ditutup (AUD-3).
2. **Saat keputusan berubah:** AUD-0 audit dampak (menghasilkan daftar pekerjaan ulang).
3. **Atas permintaan pemilik:** kalimat pemicu bebas, mis. **"Audit independen sekarang"** + lingkup (mis. "seluruh sistem", "keamanan akun", "Fase 1"). Agent **wajib**: menyiapkan paket dalam batch yang sama, menulis cara memulai sesi audit di `docs/PANDUAN_PEMILIK.md`, dan **tidak mengerjakan pekerjaan lain** sampai laporan masuk (kecuali tugas yang tidak menyentuh lingkup audit).
4. **Audit lebih dulu (audit-first):** bila pemilik meminta audit **sebelum** pekerjaan ulang/lanjutan (2026-09-17), agent **menahan** pekerjaan baru yang menyentuh lingkup audit, menyiapkan paket **menyeluruh** (`--semua`) di batch itu juga, lalu menunggu. Pekerjaan ulang dimulai setelah temuan audit masuk dan diperbaiki — auditor yang memeriksa keadaan sekarang, bukan keadaan setelah diubah.

---

## 12. Prompt auditor (siap tempel)

Teks lengkap + cara pakai ada di `docs/uji/PROMPT_AUDIT_INDEPENDEN.md`; versi terisi-otomatis untuk satu lingkup
tertentu ditulis di berkas paket (§5) sehingga pemilik cukup menyalin dari sana.

---

## 13. Riwayat & log keputusan dokumen ini

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-17 | Dokumen dibuat & BERLAKU; alat `alat/audit-independen.py` (paket · periksa laporan · kalibrasi · uji diri) + `alat/kalibrasi-cacat.json` + `docs/PANDUAN_PEMILIK.md` | Permintaan pemilik: menanam mekanisme audit/review independen yang matang, terukur, dan bisa ia picu sendiri; riset: maker–checker separation, Perspective-Based Reading, defect injection, refutation-before-report |
| 2026-09-17 (putaran 4) | §2b **lingkup menyeluruh** + gerbang **`tahan_semua`** + pemicu **audit-first** (§11) + atas permintaan pemilik buku induk `PANDUAN_PENGGUNA.md` dijadikan **manual book lengkap** (semua mekanisme + semua prompt) dengan penjaga `alat/periksa-panduan.py` di CI; alat dapat `--paket AUD-3 --semua` | Permintaan pemilik: *"sekarang aku mau audit dulu"*; mekanisme harus *"bener-bener menyeluruh… termasuk file2 yang disiapkan untuk pengguna"*; dan *"satu file untuk pengguna yang betul-betul isinya lengkap… semacam manual book"* |

## 14. Risiko sisa yang diakui (jujur, bukan disembunyikan)

1. **Tidak ada jaminan 100%.** Studi inspeksi: tim PBR menemukan rata-rata ~58% cacat. Mekanisme ini **menaikkan & mengukur** deteksi, bukan menjanjikan kesempurnaan; karena itu ada lapis mesin (CI) + lapis auditor + lapis pemilik (uji terima).
2. **Auditor & pembangun bisa berbagi model yang sama.** Bila platform hanya menyediakan satu keluarga model, korelasi cacat tetap ada — dicatat di laporan sebagai keterbatasan, dan dikompensasi lensa + kalibrasi.
3. **Kunci jawaban kalibrasi ada di sistem berkas.** Auditor dilarang membacanya; pelanggaran hanya bisa dideteksi tidak langsung (temuan tanpa bukti → ditolak mesin). Ini kontrol proses, bukan kontrol teknis — dicatat terbuka.
4. **Audit tidak menggantikan uji terima manusia.** Keputusan akhir tetap di tangan pemilik.
5. **Agent pembangun tidak bisa mengaudit dirinya sendiri.** Auditor wajib sesi terpisah (dan bila mungkin model berbeda). Konsekuensi jujur: **pemilik harus membuka sesi baru** untuk menjalankan audit; agent pembangun hanya menyiapkan paket, menahan fase, dan menindaklanjuti temuan. Bila platform hanya menyediakan satu keluarga model, hasilnya tetap dicatat sebagai keterbatasan (butir 2) — bukan diklaim sebagai independensi penuh.
6. **Cakupan menyeluruh menambah waktu.** AUD-3 menyentuh ratusan berkas; satu sesi bisa tidak cukup. Auditor **boleh** menulis laporan bertahap, tetapi verdict akhir hanya sah bila syarat §2b butir 3 terpenuhi (semua grup berkas + berkas pengguna + ≥90% cakupan).
