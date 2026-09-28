# RANCANGAN PEMERIKSAAN BERTAHAP — "Pemeriksaan Mendalam Putaran Besar" (PMB)

> **Status: RANCANGAN (draft) — menunggu keputusan Lee.** Belum ada yang dijalankan.
> Ditulis sesi `arena/01a0e747` (2026-09-28) atas permintaan Lee: *"rancang dulu mekanismenya
> supaya benar-benar maksimal … pikirkan secara mendalam dan riset di internet."*
> Bahasa: Indonesia sederhana. Yang bertanda **[usul]** adalah pendapat agent; yang bertanda
> **[fakta repo]** dihitung dari isi repo hari ini; yang bertanda **[riset]** punya sumber di §12.

---

## 0. Ringkasan satu menit (untuk Lee)

Gagasan Lee **benar arahnya** dan didukung riset: pemeriksaan dalam **potongan kecil**, **beberapa
giliran chat** ("lanjut … lanjut"), **fondasi dulu** baru hasil kerja, dan **pencatatan** yang bisa
dibaca sesi lain. Riset inspeksi perangkat lunak menunjukkan pemeriksa menemukan cacat paling
banyak bila memeriksa **200–400 baris per sesi** dan turun tajam bila dipaksa lebih cepat; riset LLM
menunjukkan kemampuan agent **turun drastis saat konteks chat penuh** (bahkan model berkonteks 1 juta
token sudah melemah di ±100 ribu token). Bukti dari repo kita sendiri sejalan: **tiga sesi** yang
menjalankan prompt "Pemeriksa Fase 0–10" yang sama menghasilkan **3, 13, dan 11 temuan** — satu chat
untuk 11 fase terlalu besar, hasilnya untung-untungan.

Yang saya usulkan **menambah** empat hal pada gagasan Lee:

1. **Satu Buku Besar Temuan + Matriks Telusur** (bukan laporan lepas-lepas) — supaya "tidak ada yang
   terlewat" bisa **dibuktikan mesin**, bukan diyakini.
2. **Lapis Hakim** di antara Pemeriksa dan Pembangun — riset menunjukkan pemeriksa LLM berlensa ganda
   menemukan lebih banyak, tetapi **separuh temuannya bisa palsu**; tanpa hakim, pembangun akan
   "memperbaiki" yang tidak rusak.
3. **Pemeriksaan lintas-fase** setelah per-fase — cacat paling mahal hidup di **sambungan** antar fase
   (uang, multi-penyewa, offline), bukan di dalam satu fase.
4. **Tahap lapangan** untuk yang **tidak bisa diperiksa dari repo** (Supabase Cloud, Cloudflare,
   printer, perangkat) — di sinilah tangan Lee dibutuhkan.

Keputusan yang saya minta dari Lee ada di **§11** (8 pertanyaan pendek).

---

## 1. Peta unsur repo — "ada apa saja yang harus diperiksa" **[fakta repo]**

Dihitung dari berkas terlacak Git di `main` (commit `141d40f0`, 2026-09-28):

| # | Unsur | Isi nyata | Cara memeriksanya berbeda |
|---|---|---|---|
| U1 | **Fondasi (dokumen pengikat)** | `docs/DISCOVERY.md` (310 baris) · `docs/PRD.md` (323) · `docs/TECH_SPEC.md` (475) · `docs/ROADMAP.md` (2.223 baris, **193 tugas**: 155 tuntas, 38 belum) · `docs/DECISIONS_LOG.md` (3.276) · `docs/KEAMANAN.md` (232) · `docs/SPESIFIKASI_UI.md` (232) · `docs/AGENT_OPERATING_GUIDE.md` (400) · `docs/TERTANGGUH.md` · `docs/PRIVASI_PELANGGAN.md` · `docs/PETA_UI.md` · **suara Lee**: `docs/teknis/REKAM_PESAN_PEMILIK.md` (§1–§30) | Konsistensi antar-dokumen, kelengkapan, ketertelusuran, **asumsi yang belum dibuktikan**, kesesuaian dengan kata-kata Lee, kesesuaian dengan dunia luar (aturan pajak/PB1, UU PDP, standar ESC/POS, WCAG, batas gratis Supabase/Cloudflare) |
| U2 | **Hasil kerja — basis data** | `supabase/migrations/` **84 migrasi SQL** · `supabase/functions/` **6 Edge Function** · `supabase/tes/` **132 berkas uji SQL** | RLS & isolasi penyewa, uang & pembulatan, idempoten, `security definer`, jejak audit, uji yang bisa MERAH |
| U3 | **Hasil kerja — aplikasi** | `aplikasi/src/` **129 berkas TS/TSX sumber**: 76 layar · 23 komponen · 20 lib · 9 hook · bahasa (4 kamus) · gaya · kontrak · **122 berkas uji Vitest** · 2 e2e | 7 keadaan layar, tombol mati/aksi tanpa tombol, offline & antrean, keyboard fisik, kontras & sentuh, bahasa, kontrak ke RPC |
| U4 | **Bukti & uji (dokumen)** | `docs/uji/` **177 berkas**: buku uji pemilik, rencana uji manual, naskah jalan, 64 laporan audit, 26 paket audit, 40 review PR, 6 bahan kalibrasi, uji terima G1, kinerja & batas | Apakah bukti **masih bisa direproduksi hari ini**; apakah temuan lama benar-benar tertutup |
| U5 | **Perkakas & pagar (mesin penjaga)** | `alat/` **123 skrip** (31 `periksa-*.py`, 68 `uji-mutasi-*.py`, uji-sql, cadangan, denyut, latihan insiden, `lanjut-sesi.py`, `audit-independen.py`) · `aplikasi/alat/` 14 · **CI 5 alur kerja** (`ci.yml`, `cadangan.yml`, `denyut-harian.yml`, `sebar-halaman.yml`, `sebar-skema.yml`) | Apakah penjaga **benar-benar bisa merah** (mutasi), apakah ada celah `|| true`, apakah yang dijaga = yang dijanjikan |
| U6 | **Desain** | `prototipe/` 58 berkas · `docs/desain/` 59 berkas | Apakah aplikasi masih setia pada sumber desain; token, kerapatan, tema |
| U7 | **Untuk manusia & operasional** | `docs/ops/` 17 (DEPLOY, PANDUAN_PEGAWAI, SERAH_TERIMA_G1, PEMULIHAN_*) · `docs/teknis/` 8 (BUKU_INSIDEN, PEMULIHAN) · berkas untuk Lee di akar: `PANDUAN_PENGGUNA.md`, `docs/PANDUAN_PEMILIK.md`, `START_DI_SINI.md`, `PRO.md`, `PANDUAN_PEMAKAIAN.md` | **Diperiksa dengan cara pengguna**: bisakah orang non-teknis mengikuti langkahnya apa adanya |
| U8 | **Mesin kerja agent (meta)** | `PRO.md`, `PROMPT_*.md`, `AGENT_SYSTEM.md`, `SYSTEM_MANIFEST.md`, `_sistem/` 15, `_log-sesi/` 16, `skills/` (88 SKILL.md **pihak ketiga**, 1.803 berkas) | Apakah mekanisme sesi/audit/maraton konsisten dengan kenyataan; `skills/` cukup dicatat, tidak diaudit baris demi baris |
| U9 | **Di luar repo (produksi nyata)** | Proyek Supabase Cloud (Singapore), Cloudflare Workers, GitHub Secrets/Actions, printer & perangkat kasir, akun Google/Resend | **Tidak bisa dibaca dari repo** — perlu tangan Lee atau akses baca-saja; ini "unsur ke-9" yang sering terlupa |

> Catatan kejujuran: skills pihak ketiga (U8) dan salinan meta (`_salinan-meta/`) sebaiknya **dicatat &
> dikecualikan dengan alasan**, bukan dibaca baris demi baris — sesuai kebiasaan AUD-3 §2b butir 4.

---

## 2. Apa yang sudah kita punya, dan pelajarannya

**Sudah ada dan bagus (jangan dibuang):** `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` — aturan
independensi (sesi terpisah, hanya-baca, buta pembenaran), **6 lensa** (L1 ancaman, L2 uang, L3
kesepakatan dokumen, L4 mutu uji, L5 lapangan/UI, L6 privasi), kontrak laporan yang **divalidasi mesin**,
**kalibrasi cacat tanaman**, aturan anti-teater, temuan luar cakupan wajib dilaporkan, dan penjaga
`alat/periksa-temuan-audit.py` (117 temuan terlacak).

**Kelemahan yang terlihat dari riwayat** **[fakta repo]**:

| Kelemahan | Bukti | Akibat |
|---|---|---|
| Satu prompt = seluruh sistem | Pemeriksaan Akbar: 1 chat untuk 11 fase; 1 chat untuk 84 migrasi | 3 sesi, prompt sama → **3 / 13 / 11 temuan**; laporan 70 baris vs 296 baris |
| Laporan lepas-lepas, format berbeda-beda | 64 berkas di `docs/uji/audit/` (format AUD-3 ≠ format LAPORAN_AKBAR) | Penutupan temuan dicatat di §1a–§1g `AUDIT_RIWAYAT.md` secara tambal-sulam; sulit menjawab "temuan X sudah ditutup belum?" |
| Tidak ada matriks janji → kode → uji → pemeriksaan | Lensa L3 menanyakannya, tapi tidak ada tabel tunggal | "Tidak ada yang terlewat" belum bisa dibuktikan mesin |
| Fondasi tidak pernah diperiksa **sebagai tahap sendiri** | Audit selalu mencampur fondasi + kode | Cacat fondasi (asumsi salah) baru ketahuan lewat kode |
| Verifikasi temuan bergantung sesi kerja | Sesi kerja yang membantah/menerima temuan (contoh: PR-01 "terbantah dengan eksekusi") | Pembangun jadi hakim atas temuan terhadap dirinya — konflik kepentingan halus |

---

## 3. Prinsip rancangan (tiap prinsip punya dasar)

| # | Prinsip | Dasar |
|---|---|---|
| P1 | **Potongan kecil, satu giliran satu potongan.** Ukuran: ±200–400 baris kode inti (+ ujinya) atau 8–12 halaman dokumen per giliran; ≤ 60–90 menit kerja. | **[riset]** inspeksi optimal 150–400 baris/jam; > 500 baris/jam deteksi turun tajam; 200–400 baris per sesi menemukan 70–90 % cacat |
| P2 | **Konteks chat dijaga tetap kecil; ingatan disimpan di berkas, bukan di chat.** Tiap giliran: baca papan → kerjakan 1 potongan → tulis kartu + buku besar → berhenti. Chat boleh diteruskan dengan "lanjut", tetapi **setiap giliran harus bisa dimulai dari chat baru** tanpa kehilangan apa pun. | **[riset]** *context rot / lost in the middle*; agent 1M token melemah di ±100K; teknik *structured note-taking* & *sub-agent dengan konteks bersih* (Anthropic) |
| P3 | **Fondasi dulu, dikunci, lalu jadi tolok ukur.** Setelah Tahap Fondasi selesai & diperbaiki, fondasi diberi **tag Git** (baseline). Semua pemeriksaan sesudahnya memeriksa "sesuai baseline atau tidak". | **[riset]** IV&V: validasi kebutuhan dulu karena "setiap cacat hilir menelusur ke kebutuhan yang tidak lengkap/ambigu"; matriks telusur dibekukan di gerbang kebutuhan |
| P4 | **Banyak lensa, lalu hakim.** Pemeriksa berbeda lensa menemukan cacat berbeda (korelasi rendah), gabungannya jauh lebih banyak; tetapi tingkat temuan palsu tinggi → wajib lapis **Hakim** yang mereproduksi setiap temuan sebelum masuk daftar perbaikan. | **[riset]** multi-agent verification: 1 agen 33 % → 4 agen 76 % deteksi, tetapi FP ±50 %; protokol kita sendiri §3 butir 6 (refutasi sebelum lapor) |
| P5 | **Satu Buku Besar, ID stabil, siklus status yang dijaga mesin.** | **[riset]** artefak IV&V: *findings register*, *traceability matrix*, *remediation evidence pack*, *audit trail* |
| P6 | **Kualitas diukur dengan nama, bukan kesan.** Pakai 9 ciri mutu ISO/IEC 25010:2023 (kesesuaian fungsi, kinerja, kompatibilitas, kemampuan interaksi, keandalan, keamanan, keterpeliharaan, fleksibilitas, keselamatan) yang dipetakan ke lensa L1–L6 + daftar periksa per jenis artefak. | **[riset]** ISO/IEC 25010:2023 |
| P7 | **Kejujuran terukur.** Kalibrasi cacat tanaman tetap dipakai **per tahap** (bukan sekali), dan setiap kartu wajib memuat "angka usaha" + "yang tidak bisa saya verifikasi". Tidak ada janji 100 %: inspeksi formal terbaik menemukan ±60–85 % cacat — karena itu berlapis (mesin + pemeriksa + hakim + Lee). | **[riset]** Capers Jones 60–65 %; Fagan 70–85 %; protokol kita §14 |

---

## 4. Tahapan **[usul]**

```
Tahap 0  Siapkan mekanisme (1–2 sesi kerja + 1 uji coba auditor)  ── gerbang: uji-diri mesin LOLOS + uji coba 1 potongan
Tahap 1  FONDASI (U1)                                             ── gerbang KERAS: 0 temuan K-1/K-2 terbuka → tag `fondasi-baseline-<tanggal>`
Tahap 2  PER FASE (vertikal) Fase 0 → 1 → 1B → 1C → 2 → … → 11      ── tiap fase: semua potongan SELESAI + DIHAKIMI
Tahap 3  LINTAS-FASE (horizontal): uang hulu-hilir · multi-penyewa/RLS · offline & idempoten · akun/perangkat/sesi · privasi PDP · kinerja/batas gratis · bahasa/aksesibilitas
Tahap 4  UNTUK MANUSIA & OPERASIONAL (U7) — diuji "dengan cara pengguna"
Tahap 5  MESIN PENJAGA & MESIN KERJA AGENT (U5, U8) — apakah pagarnya benar-benar bisa merah; apakah mekanisme sesi/audit konsisten
Tahap 6  LAPANGAN & PRODUKSI NYATA (U9) — bersama Lee: Supabase/Cloudflare/secrets/printer/perangkat
Tahap 7  PENUTUP: verifikasi ulang seluruh temuan DITUTUP, kalibrasi akhir, pernyataan kesiapan pilot
```

Aturan urutan **[usul]**:
- **Tahap 1 adalah gerbang keras** — Tahap 2 tidak mulai sebelum fondasi dikunci (kalau tidak, pemeriksa
  fase memeriksa terhadap sasaran yang bergerak).
- Tahap 2–5 **boleh berjalan paralel lintas sesi** (potongan berbeda diklaim sesi berbeda di papan),
  karena tiap potongan mandiri. Ini cara memakai beberapa sesi Arena sekaligus tanpa saling menimpa.
- **Perbaikan** dilakukan **per tahap** (bukan per temuan) oleh sesi pembangun, **kecuali K-1** yang
  diperbaiki segera. Setiap perbaikan diverifikasi ulang oleh Hakim (bukan oleh pembangunnya).
- Tahap 6 dan sebagian Tahap 4 butuh Lee — dijadwalkan agar tidak menghambat tahap lain.

### 4a. Tahap 1 — Fondasi diperiksa dengan pertanyaan yang tepat

Potongan fondasi (perkiraan **10–12 potongan**): DISCOVERY · PRD (janji M1–M12 + aturan bisnis) ·
TECH_SPEC §1–§5 (arsitektur & skema) · TECH_SPEC §6–§13 (keamanan, risiko, batas gratis, DoD) ·
KEAMANAN.md · SPESIFIKASI_UI + PETA_UI · ROADMAP (struktur & klaim bukti — dicicil 2–3 potongan) ·
DECISIONS_LOG (keputusan yang saling bertentangan) · AGENT_OPERATING_GUIDE + TERTANGGUH · REKAM_PESAN_PEMILIK
(apakah setiap kata Lee punya jejak keputusan/tugas).

Pertanyaan pemicu tiap potongan fondasi:
1. **Konsisten?** Apakah PRD, TECH_SPEC, KEAMANAN, ROADMAP saling setuju (istilah, angka, aturan)?
2. **Lengkap?** Adakah janji tanpa aturan, aturan tanpa tugas, tugas tanpa bukti?
3. **Asumsi?** Kalimat mana yang **mengasumsikan** sesuatu tentang dunia (pajak, hukum, perangkat, batas
   gratis, perilaku kasir) tanpa bukti? → masuk **Daftar Asumsi** dengan status (dibuktikan/dibantah/terbuka)
   dan **riset internet** yang diwajibkan untuk membuktikannya.
4. **Sesuai suara Lee?** Apakah ada keputusan yang menyimpang dari kata-kata Lee di REKAM_PESAN_PEMILIK?
5. **Masih benar hari ini?** Angka/klaim yang basi (jumlah migrasi, tabel, uji) — basi = temuan.

Keluaran Tahap 1: temuan fondasi (diperbaiki dulu), **Matriks Telusur v1** (janji → tugas → berkas → uji),
**Daftar Asumsi v1**, lalu **tag baseline**.

### 4b. Tahap 2 — Per fase, dipotong kecil

Satu fase **bukan** satu potongan. Contoh Fase 1 (database, keamanan, uang): ±40 entitas & belasan
migrasi → dipotong per **kelompok tabel/RPC** (mis. "identitas & peran", "menu & katalog", "pesanan & item",
"pembayaran", "jejak audit"), tiap potongan = migrasi + RPC + uji SQL + mutasi + tugas ROADMAP terkait.
Perkiraan kasar seluruh Tahap 2: **60–90 potongan** (angka pasti ditetapkan di Tahap 0 saat papan dibuat).

Tiap potongan menjawab, wajib dengan bukti perintah:
1. **Sesuai baseline?** (Matriks Telusur: janji mana yang dipenuhi potongan ini; adakah yang menyimpang)
2. **Benar?** (lensa L1/L2/L5/L6 sesuai jenis artefak)
3. **Ujinya jujur?** (L4: uji bisa MERAH? mutasi? lulus karena sebab yang salah?)
4. **Mutu?** (ciri ISO 25010 yang relevan: keandalan, keterpeliharaan, kemampuan interaksi, dsb.)
5. **Asumsi baru?** (asumsi yang dibuat fase ini terhadap fase sebelumnya/dunia luar → Daftar Asumsi)
6. **Klaim bukti ROADMAP direproduksi?** (perintah dijalankan ulang hari ini)

---

## 5. Satu giliran pemeriksa — alur "lanjut" yang tahan putus **[usul]**

```
Giliran ke-n (chat yang sama ATAU chat baru — hasilnya harus sama):
 1. baca  docs/uji/pemeriksaan/<putaran>/PAPAN.md            → ambil potongan pertama berstatus BELUM (atau yang ditunjuk Lee)
 2. tulis status DIKLAIM (sesi, waktu) di PAPAN, commit+push  → sesi lain tidak mengambil potongan yang sama
 3. baca hanya berkas dalam lingkup potongan + baseline yang dirujuk (bukan seluruh repo)
 4. periksa dengan lensa & daftar periksa jenis artefak; jalankan perintah bukti; riset bila menyentuh asumsi
 5. tulis kartu  kartu/K-<ID>.md  (cakupan · klaim yang dicoba dibantah · serangan · temuan · asumsi · yang tak bisa diverifikasi · angka usaha)
 6. tambah baris temuan ke BUKU_BESAR_TEMUAN.md (status BARU) + perbarui MATRIKS_TELUSUR (kolom "diperiksa di")
 7. jalankan  python3 alat/periksa-pemeriksaan.py (rencana)   → LOLOS (format, ID unik, bukti ada, status sah)
 8. PAPAN: potongan → SELESAI; commit+push; BERHENTI dan tulis:  "Potongan K-.. selesai. Langkah Lee: ketik `lanjut`."
```

- **Kenapa berhenti tiap potongan, bukan lanjut sendiri?** Supaya konteks chat tidak menggelembung (P2), dan
  supaya Lee bisa mengganti model/sesi kapan saja tanpa kehilangan apa pun. Kalau Lee ingin lebih cepat,
  "lanjut" bisa diganti "lanjut 3 potongan" — mesin tetap mencatat per potongan.
- **Hakim** memakai alur yang sama, tetapi objeknya = baris BUKU BESAR berstatus BARU: mereproduksi bukti,
  lalu menetapkan **TERVERIFIKASI** / **PALSU** (dengan alasan) / **PERLU-INFO** — Hakim **tidak boleh** sesi
  yang sama dengan Pemeriksa yang menemukan, dan tidak boleh pembangun.
- **Pembangun** hanya mengambil temuan **TERVERIFIKASI**, memperbaiki, menulis bukti perbaikan, status →
  **DIPERBAIKI**; Hakim memverifikasi ulang → **DITUTUP**. Temuan tidak pernah dihapus, hanya berubah status.

---

## 6. Peran & independensi **[usul]**

| Peran | Siapa | Boleh mengubah repo? | Catatan |
|---|---|---|---|
| **Perencana/Integrator** | sesi kerja utama (sesi ini) | ya (mekanisme, papan, perbaikan) | membuat papan & potongan, menyiapkan kalibrasi, menjalankan perbaikan per tahap |
| **Pemeriksa** | sesi baru per giliran, **model berbeda** dari pembangun bila Arena memungkinkan | hanya berkas di `docs/uji/pemeriksaan/<putaran>/` | boleh beberapa sesi paralel; tiap sesi 1 potongan per giliran |
| **Hakim** | sesi baru, **bukan** pemeriksa yang menemukan & bukan pembangun | hanya kolom status/alasan di Buku Besar + kartu hakim | mereproduksi bukti; membuang temuan palsu dengan alasan tertulis |
| **Pembangun** | sesi kerja (boleh sesi utama) | ya | hanya mengerjakan TERVERIFIKASI; tidak boleh menutup temuannya sendiri |
| **Pemilik (Lee)** | Lee | keputusan | memutuskan gerbang tahap, menutup tertangguh, mengerjakan Tahap 6 |

Aturan lama tetap berlaku (hanya-baca, buta pembenaran, tidak ramah, refutasi sebelum lapor, temuan luar
cakupan wajib ditulis, dilarang membaca kunci kalibrasi).

---

## 7. Pencatatan — supaya sesi mana pun bisa membaca dan memperbaiki **[usul]**

```
docs/uji/pemeriksaan/
  RANCANGAN_PEMERIKSAAN_BERTAHAP.md       ← berkas ini (rancangan yang disetujui Lee = kontrak)
  PMB-1/                                   ← satu putaran besar (rencana)
    PAPAN.md                ← papan potongan: ID · tahap · lingkup berkas · lensa wajib · ukuran · status (BELUM/DIKLAIM/SELESAI/DIHAKIMI) · sesi · tanggal
    BUKU_BESAR_TEMUAN.md    ← SATU baris per temuan, ID stabil PMB1-F-001…; kolom: tingkat K-1..K-4 · potongan · artefak:baris · janji/aturan baseline yang dilanggar · ciri mutu · bukti (perintah→hasil) · status · hakim · perbaikan (commit) · verifikasi tutup
    MATRIKS_TELUSUR.md      ← janji (PRD M*, aturan bisnis, TECH_SPEC ART-*, KEAMANAN §) → tugas ROADMAP → berkas implementasi → uji → potongan yang memeriksa → hasil
    ASUMSI.md               ← daftar asumsi: kalimat asumsi · sumber (dokumen/fase) · status (dibuktikan/dibantah/terbuka) · riset/bukti · dampak bila salah
    kartu/K-<ID>.md         ← satu kartu per potongan (pemeriksa) dan H-<ID>.md (hakim)
    kalibrasi/              ← bahan cacat tanaman per tahap (kunci jawaban TETAP di luar repo)
    RINGKASAN_TAHAP-<n>.md  ← dibuat mesin dari Buku Besar saat gerbang tahap
```

**Siklus status temuan (dijaga mesin):** `BARU → TERVERIFIKASI | PALSU | PERLU-INFO → DIPERBAIKI → DITUTUP`
(+ `DITANGGUHKAN` hanya oleh keputusan Lee, dengan rujukan `docs/TERTANGGUH.md`). Transisi di luar ini
ditolak pemeriksa mesin.

**Penjaga mesin baru (rencana):** `alat/periksa-pemeriksaan.py` — memeriksa: ID unik & berurutan;
setiap temuan punya bukti perintah & artefak yang **ada**; status sah; potongan SELESAI punya kartu;
gerbang tahap hanya LOLOS bila 100 % potongan tahap itu SELESAI + DIHAKIMI dan 0 K-1/K-2 terbuka;
Matriks Telusur tidak punya janji tanpa potongan pemeriksa ("yatim"). Dilengkapi `--uji-diri` (mutasi:
mesin harus bisa MERAH) dan didaftarkan ke CI lewat `alat/periksa-gerbang-ci.py`, mengikuti pola
penjaga yang sudah ada.

**Hubungan dengan pencatatan lama:** `docs/uji/AUDIT_RIWAYAT.md` §1b tetap menjadi daftar induk temuan
lintas putaran — Buku Besar PMB-1 **dirujuk** dari sana (satu baris ringkasan per tahap), bukan
menggantikannya, supaya `alat/periksa-temuan-audit.py` tetap berlaku.

---

## 8. "Kualitas" yang bisa diperiksa — daftar periksa per jenis artefak **[usul]**

| Jenis artefak | Ciri mutu utama (ISO 25010) | Pertanyaan wajib (contoh) |
|---|---|---|
| Dokumen fondasi | kesesuaian fungsi (lengkap, benar), keterpeliharaan (konsisten) | §4a butir 1–5 |
| Migrasi SQL / RPC | keamanan (kerahasiaan, integritas, akuntabilitas), keandalan, keselamatan (uang) | RLS per tabel & per peran; `security definer` + `search_path`; idempoten; pembulatan rupiah; jejak audit tak bisa diubah; migrasi beku tidak disentuh; uji SQL bisa MERAH |
| Layar / komponen | kemampuan interaksi (operabilitas, perlindungan salah pakai, aksesibilitas), keandalan (offline) | 7 keadaan layar; tombol mati; kontras ≥ 4,5:1; sentuh ≥ 44 px; kamus 4 bahasa lengkap; pesan galat manusiawi + kode; antrean offline & idempoten |
| Uji (Vitest/SQL/e2e/mutasi) | keterpeliharaan (keterujian), kejujuran bukti | uji lulus karena sebab yang benar; mutasi menangkap; tidak ada `skip`/`only`; angka bukti ROADMAP direproduksi |
| Penjaga & CI | keandalan mekanisme | tidak ada `|| true`/`continue-on-error`; `--uji-diri` ada & bisa merah; yang dijaga = yang dijanjikan |
| Dokumen manusia (panduan, SOP, insiden) | kemampuan interaksi (mudah dipelajari), kesesuaian | dijalankan **apa adanya** oleh pemeriksa seolah pengguna baru; setiap perintah/tautan hidup; langkah tanpa jalan buntu |
| Infrastruktur nyata | keamanan, keandalan, fleksibilitas (batas gratis) | pengaturan Supabase (RLS aktif, kunci anon vs service), header Cloudflare, secrets tidak bocor, cadangan bisa dipulihkan, denyut berjalan |

---

## 9. Kalibrasi & ukuran kejujuran **[usul]**

- **Per tahap** disiapkan **bahan cacat tanaman** oleh Perencana (kunci di luar repo): Tahap 1 → cacat
  dokumen (janji tanpa tugas, angka basi, aturan bertentangan); Tahap 2 → cacat SQL/UI; Tahap 4 → cacat
  panduan; Tahap 5 → penjaga yang dilonggarkan.
- Ukuran yang dilaporkan di RINGKASAN tiap tahap: **tingkat deteksi** cacat tanaman (per K-tingkat),
  **temuan palsu** (PALSU ÷ BARU), **cakupan potongan** (SELESAI ÷ total), **cakupan janji** (janji yang
  diperiksa ÷ janji di Matriks), **waktu per potongan**.
- Pemeriksa yang tingkat deteksinya rendah **bukan dihukum** — potongannya diulang oleh pemeriksa lain
  (itulah gunanya ukuran).

---

## 10. Beda dengan mekanisme lama (ringkas)

| Hal | Lama (AUD-3 / Akbar) | PMB (usul) |
|---|---|---|
| Unit kerja | 1 chat = seluruh sistem / 1 peran | 1 giliran = 1 potongan kecil |
| Ingatan | di dalam chat | di papan, kartu, buku besar (chat boleh mati) |
| Verifikasi temuan | sesi kerja (pembangun) | Hakim terpisah |
| Fondasi | dicampur dengan kode | tahap sendiri + baseline bertag |
| Bukti "tidak ada yang terlewat" | keyakinan + cakupan ≥ 90 % berkas | Matriks Telusur tanpa janji yatim + papan 100 % |
| Paralel lintas sesi | sulit (laporan saling timpa pernah terjadi) | papan klaim per potongan |
| Kalibrasi | sekali per audit | per tahap, dengan ukuran temuan palsu |

---

## 11. Pertanyaan keputusan untuk Lee

1. **Urutan tahapan §4** disetujui? Khususnya: **Fondasi sebagai gerbang keras** sebelum per-fase?
2. **Ukuran potongan** ±200–400 baris kode inti atau 8–12 halaman dokumen per giliran — setuju, atau Lee
   ingin lebih kecil lagi?
3. **Lapis Hakim** (sesi terpisah yang mereproduksi tiap temuan sebelum diperbaiki) — dipakai?
4. **Perbaikan per tahap** (kumpulkan, lalu perbaiki, lalu verifikasi ulang), dengan **K-1 segera** — setuju?
5. **Model berbeda per peran** — bersediakah Lee memilih model yang berbeda untuk Pemeriksa/Hakim vs
   Pembangun saat membuka sesi di Arena? (Kalau tidak bisa, dicatat sebagai keterbatasan.)
6. **Temuan audit lama** (117 di AUDIT_RIWAYAT): diperlakukan sebagai **"regresi wajib"** (Hakim memverifikasi
   ulang bahwa tiap penutupan benar) — atau dianggap selesai?
7. **Paralel:** berapa sesi pemeriksa yang nyaman Lee jalankan sekaligus? (Papan mendukung berapa pun; 2–3
   biasanya pas.)
8. **Nama putaran:** `PMB-1` (Pemeriksaan Mendalam putaran Besar ke-1) — atau nama lain pilihan Lee?

---

## 12. Sumber riset yang dipakai

- Inspeksi perangkat lunak: laju optimal 150–400 baris/jam, > 500 baris/jam turun tajam; 200–400 baris per
  sesi ≤ 60–90 menit menemukan 70–90 % cacat; inspeksi formal 60–65 % (Capers Jones), Fagan 70–85 %.
  <https://en.wikipedia.org/wiki/Code_review> · <https://smartbear.com/learn/code-review/best-practices-for-peer-code-review/> ·
  <https://www.processimpact.com/articles/inspects.pdf>
- Konteks panjang melemahkan agent: *lost in the middle* (Liu dkk. 2023); agent 1–2 juta token melemah > 50 %
  di ±100K token (arXiv 2512.02445); *context rot* (Chroma 2025).
  <https://arxiv.org/html/2512.02445v1> · <https://www.producttalk.org/context-rot/>
- Teknik tugas panjang: *structured note-taking*, *compaction*, *sub-agent* berkonteks bersih; keluaran
  sub-agent ke sistem berkas untuk menghindari "pesan berantai".
  <https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents> ·
  <https://www.anthropic.com/engineering/multi-agent-research-system>
- Verifikasi multi-agen: agen berlensa berbeda menangkap cacat berbeda (korelasi 0,05–0,25); 1 agen 33 % →
  gabungan 76 %; tetapi temuan palsu ±50 % → perlu lapis verifikasi. <https://arxiv.org/html/2511.16708>
- IV&V & matriks telusur: validasi kebutuhan dulu; artefak wajib = matriks telusur, register temuan, paket
  bukti perbaikan, jejak audit. <https://i3solutions.com/custom-application-development-services/iv-and-v-best-practices/> ·
  <https://qajobfit.com/resources/requirement-traceability-matrix>
- Model mutu ISO/IEC 25010:2023 (9 ciri). <https://www.monterail.com/blog/software-qa-standards-iso-25010>

---

## 13. Bila Lee setuju — isi Tahap 0 (yang akan saya kerjakan dulu)

1. Buat folder `PMB-1/` (rencana) dengan **PAPAN** berisi seluruh potongan Tahap 1 (fondasi) dan kerangka
   Tahap 2–6 (potongan Tahap 2 diisi rinci setelah baseline dikunci).
2. Tulis **Matriks Telusur v0** dari PRD/TECH_SPEC/KEAMANAN/ROADMAP (mesin membantu: janji & ART-* & tugas).
3. Tulis **prompt giliran** untuk Pemeriksa dan Hakim (satu berkas statis siap-salin, baris pertama diisi
   Lee: putaran + peran) — mengikuti pola `PROMPT_SESI_BARU.md`.
4. Buat `alat/periksa-pemeriksaan.py` (rencana) + `--uji-diri`, daftarkan ke CI.
5. Siapkan bahan kalibrasi Tahap 1 (kunci di luar repo).
6. **Uji coba 1 potongan** dengan sesi pemeriksa sungguhan → perbaiki mekanisme dari pengalaman itu →
   baru Tahap 1 dimulai.
