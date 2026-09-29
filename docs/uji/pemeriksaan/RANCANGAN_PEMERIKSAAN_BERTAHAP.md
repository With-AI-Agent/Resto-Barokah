# RANCANGAN PEMERIKSAAN BERTAHAP — "Pemeriksaan Mendalam Putaran Besar" (PMB)

> **Status: DISETUJUI LEE 2026-09-28** (*"Ya, aku setuju dengan semua rancangan kamu itu"* — `docs/teknis/REKAM_PESAN_PEMILIK.md` §31),
> dengan dua tambahan Lee: **tahap & petugas pemeriksaan MENYELURUH** (§4c) dan **penegasan bahwa Fase 11 belum dikerjakan** (§4d).
> **Tahap 0 disiapkan 2026-09-28** (papan 63 potongan, buku besar, matriks v0, regresi wajib, asumsi, kartu templat, prompt giliran,
> kalibrasi Tahap 1, penjaga `alat/periksa-pemeriksaan.py` di CI). Gerbang Tahap 0 yang tersisa: **uji coba satu potongan (F-01) oleh sesi
> pemeriksa sungguhan** → mekanisme diperbaiki dari pengalaman itu → Tahap 1 dibuka. Belum ada pemeriksaan resmi yang dijalankan.
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
5. **(Tambahan Lee)** **Tahap MENYELURUH** dengan petugas sendiri (**Pemeriksa Menyeluruh**): sistem dilihat
   sebagai satu kesatuan lewat alur bisnis hulu-ke-hilir, dengan ketelitian yang sama seperti per-fase (§4c).

Keputusan Lee atas 8 pertanyaan §11: **setuju semua** (2026-09-28). **PMB ≠ Fase 11** — lihat §4d.

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

## 4. Tahapan **[disetujui Lee]**

```
Tahap 0  Siapkan mekanisme (1–2 sesi kerja + 1 uji coba auditor)  ── gerbang: uji-diri mesin LOLOS + uji coba 1 potongan
Tahap 1  FONDASI (U1)                                             ── gerbang KERAS: 0 temuan K-1/K-2 terbuka → tag `fondasi-baseline-<tanggal>`
Tahap 2  PER FASE (vertikal) Fase 0 → 1 → 1B → 1C → 2 → … → 10 → 11 ── tiap fase: semua potongan SELESAI + DIHAKIMI
Tahap 3  LINTAS-FASE (sambungan): uang hulu-hilir · multi-penyewa/RLS · offline & idempoten · akun/perangkat/sesi · privasi PDP · kinerja/batas gratis · bahasa/aksesibilitas
Tahap 4  MENYELURUH (holistik, petugas: Pemeriksa Menyeluruh) — sistem sebagai satu kesatuan, potongan = alur bisnis ujung-ke-ujung (§4c)
Tahap 5  UNTUK MANUSIA & OPERASIONAL (U7) — diuji "dengan cara pengguna"
Tahap 6  MESIN PENJAGA & MESIN KERJA AGENT (U5, U8) — apakah pagarnya benar-benar bisa merah; apakah mekanisme sesi/audit konsisten
Tahap 7  LAPANGAN & PRODUKSI NYATA (U9) — bersama Lee: Supabase/Cloudflare/secrets/printer/perangkat
Tahap 8  PENUTUP: verifikasi ulang seluruh temuan DITUTUP, kalibrasi akhir, pernyataan kesiapan → barulah FASE 11 (finishing) dikerjakan
```

Aturan urutan:
- **Tahap 1 adalah gerbang keras** — Tahap 2 tidak mulai sebelum fondasi dikunci (kalau tidak, pemeriksa
  fase memeriksa terhadap sasaran yang bergerak).
- **Tahap 4 (Menyeluruh) dijalankan SETELAH Tahap 2–3** — supaya Pemeriksa Menyeluruh membaca sistem yang
  cacat-cacat lokalnya sudah diketahui, dan bisa fokus pada hal yang hanya terlihat dari kejauhan (alur putus,
  janji PRD yang secara teknis "ada" tetapi tidak bisa dipakai kasir sungguhan, pengalaman pemilik SaaS).
- Tahap 2, 3, 5, 6 **boleh berjalan paralel lintas sesi** (potongan berbeda diklaim sesi berbeda di papan),
  karena tiap potongan mandiri. Ini cara memakai beberapa sesi Arena sekaligus tanpa saling menimpa.
- **Perbaikan** dilakukan **per tahap** (bukan per temuan) oleh sesi pembangun, **kecuali K-1** yang
  diperbaiki segera. Setiap perbaikan diverifikasi ulang oleh Hakim (bukan oleh pembangunnya).
- Tahap 7 dan sebagian Tahap 5 butuh Lee — dijadwalkan agar tidak menghambat tahap lain.

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

### 4c. Tahap 4 — Menyeluruh (tambahan Lee): petugas sendiri, ketelitian sama

**Kenapa perlu tahap sendiri:** per-fase dan lintas-fase memeriksa *bagian*; masih ada kelas cacat yang hanya
terlihat bila sistem dipakai **dari ujung ke ujung sebagai satu kesatuan** — mis. setiap layar benar tetapi
alur "pesan → dapur → bayar → cetak → tutup kas" putus di satu sambungan; atau janji PRD terpenuhi secara
teknis tetapi kasir sungguhan tidak bisa memakainya dalam 15 menit; atau pengalaman Lee sebagai **pemilik
platform SaaS** (mendaftarkan resto baru, memantau kuota, menonaktifkan penyewa) tidak pernah dilalui utuh.

**Cara agar tetap seteliti per-fase:** tahap ini **tidak** dikerjakan dalam satu chat. Potongannya = **satu
alur/skenario ujung-ke-ujung** (bukan berkas), tiap potongan dijalankan dalam satu giliran dengan kartu, bukti,
dan Buku Besar yang sama. Contoh potongan (dirinci di Tahap 0):

| Potongan | Kacamata | Alur yang dilalui utuh |
|---|---|---|
| M-01 | Lee sebagai **pemilik platform SaaS** | daftar resto baru → buat cabang → tunjuk admin → kode perangkat → pegawai pertama masuk → kuota & status pemakaian → nonaktifkan penyewa |
| M-02 | **Owner pusat** (TOTP) | masuk 2FA → atur menu/harga/pajak → lihat laporan lintas cabang → mode dukungan berbatas waktu |
| M-03 | **Kasir** satu shift penuh | buka kas → pesan dine-in & bungkus → kirim dapur → diskon dengan izin atasan → bayar tunai & QRIS → cetak/struk digital → void berjenjang → tutup kas & selisih |
| M-04 | **Dapur/bar** | tiket masuk → status masak/saji → stok habis → antrean menumpuk |
| M-05 | **Pelanggan** | katalog publik → voucher undang-teman → persetujuan privasi → anonimisasi |
| M-06 | **Hari buruk** | listrik/jaringan putus di tengah pembayaran → antrean offline → pulih → tidak ada dobel; perangkat hilang → cabut → PIN salah 5× → kunci |
| M-07 | **Isolasi penyewa** | dua resto berbeda memakai sistem bersamaan — tidak ada data yang saling terlihat di alur mana pun |
| M-08 | **Angka uang hulu-hilir** | dari item pesanan → pajak/service → diskon/voucher → pembayaran → kas → laporan harian: satu rupiah pun tidak hilang |

Petugas **Pemeriksa Menyeluruh** memakai lensa semua (L1–L6) tetapi pertanyaan pemicunya berbeda: *"Bisakah
alur ini diselesaikan orang sungguhan, dari awal sampai akhir, tanpa saya menutup mata pada satu langkah pun?"*
Setiap langkah alur dicatat dengan bukti (perintah/uji/tangkapan layar pratinjau); langkah yang hanya bisa
dibuktikan di perangkat nyata **ditandai** dan diteruskan ke Tahap 7.

### 4d. Hubungan dengan Fase 11 (penegasan Lee: Fase 11 BELUM dikerjakan)

**PMB ≠ Fase 11.** Fase 11 di ROADMAP = *finishing* penutup Gelombang 1 (13 tugas). PMB = mekanisme
**pemeriksaan** yang dijalankan **sebelum** finishing. Urutan resmi: **PMB → Fase 11 → pilot.**
Per 2026-09-28 (keputusan Lee), Fase 11 **belum dikerjakan kecuali T11-07** (deploy Cloudflare); tugas yang
sempat ditandai selesai dikembalikan ke `[ ]` di ROADMAP dengan baris "Koreksi status".

| Tugas Fase 11 | Hubungan dengan PMB | Tetap harus dikerjakan di Fase 11? |
|---|---|---|
| T11-13 Audit adversarial (AUD-3) sebelum pilot | **Diserap PMB** (PMB lebih luas & lebih dalam; DoD T11-13 = syarat minimum penutup PMB) | Tidak — ditutup oleh Tahap 8 PMB |
| T11-05 Audit tampilan | Sebagian diperiksa di Tahap 3 (a11y/bahasa) & Tahap 4 | Ya — pemeriksaan manusia 3 ukuran layar |
| T11-03 cetak nyata · T11-04 perangkat kedua · T11-12 keamanan bersama pemilik | Tahap 7 (lapangan) **menyediakan wadahnya**, tetapi hasilnya dicatat sebagai bukti tugas Fase 11 | Ya — dilaksanakan Lee di perangkat nyata |
| T11-02 uji terima pemilik · T11-09 pelatihan · T11-10 serah terima | Tidak termasuk PMB (ini finishing) | Ya — setelah PMB selesai |
| T11-06 angka nyata batas gratis · T11-08 peringatan 70/90 % | Alat & kodenya diperiksa di Tahap 2 (Fase 10/11) | Ya — angka & peringatan di lingkungan nyata |
| T11-01 · T11-11 Playwright di CI (T-026) | Tidak termasuk PMB | Ya — menunggu keputusan Lee atas T-026 |
| T11-07 deploy | **Sebagian**: jalur deploy nyata (commit `b3e00686`, versi pra-PMB); Tahap 7 memeriksa produksi vs repo (termasuk DoD "data uji tidak ada di produksi") | Ya — deploy final setelah PMB; domain kustom tetap opsional per T-008 |

**Temuan pra-registrasi (ditemukan saat memverifikasi klaim deploy, sebelum Buku Besar ada — dipindahkan ke Buku Besar di Tahap 0):**
`PMB1-F-001` · BARU · kandidat K-1 · migrasi `0086` Bagian 2 menanam akun percontohan `@resto.test` ber-PIN bawaan **hanya di produksi**
(dilewati saat uji lokal → tidak pernah tertangkap uji SQL), sementara `verifikasi_pin_perangkat` mendaftarkan perangkat baru sendiri dan repo
GitHub publik. Bukti: `git show 8bba597c --stat`; run `sebar-skema.yml` 2026-09-28 07:49 UTC hijau. Bertentangan dengan DoD T11-07.
Keputusan mitigasi produksi = Lee (REKAM §31 butir 6). Pelajaran mekanisme: blok "hanya di produksi" adalah **titik buta uji lokal** → Tahap 1
wajib memeriksa setiap `if not exists (... nspname = 'uji')` / cabang khusus produksi.

Pelajaran yang langsung dipakai PMB: kelas cacat **"klaim vs kenyataan"** — tugas ditandai selesai padahal
DoD-nya menuntut tangan pemilik/perangkat nyata. Tahap 1 (potongan ROADMAP) wajib menyisir **semua** tugas
`[x]` yang DoD/Verifikasinya memuat kata *pemilik*, *nyata*, *perangkat*, *tanda tangan*, *pelatihan* dan
menuntut buktinya.

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

- **Lintas cabang:** setiap sesi Arena terikat cabangnya sendiri, jadi sesi giliran push ke cabangnya dan **Perencana menggabungkan**
  (perintah Lee `integrasikan <cabang>` → `git fetch` + `git merge --no-ff`, hanya berkas `PMB-1/` yang diharapkan berubah; tabrakan
  diselesaikan dengan mempertahankan semua baris; sejak 2026-09-29 dikerjakan `alat/pmb-integrasi.py` — gabungan baris demi baris,
  penomoran ulang otomatis, sengketa dua hakim tidak diputuskan mesin melainkan dengan aturan tertulis di `PMB-1/README.md`).
  Klaim di PAPAN baru terlihat sesi lain setelah digabung — karena itu Lee sebaiknya
  **menunjuk potongan** di baris `POTONGAN` prompt bila membuka beberapa sesi sekaligus.
- **Kenapa berhenti tiap potongan, bukan lanjut sendiri?** Supaya konteks chat tidak menggelembung (P2), dan
  supaya Lee bisa mengganti model/sesi kapan saja tanpa kehilangan apa pun. Kalau Lee ingin lebih cepat,
  "lanjut" bisa diganti "lanjut 3 potongan" — mesin tetap mencatat per potongan.
- **Pemeriksa Menyeluruh** (Tahap 4) memakai alur yang sama; potongannya adalah alur M-xx (§4c), bukan berkas.
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
| **Pemeriksa Menyeluruh** | sesi baru per giliran (Tahap 4), model berbeda bila bisa | hanya berkas di `docs/uji/pemeriksaan/<putaran>/` | satu alur ujung-ke-ujung per giliran; menandai langkah yang butuh perangkat nyata untuk Tahap 7 |
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
  PROMPT_GILIRAN.md                        ← naskah statis siap-salin untuk sesi giliran (PERAN · POTONGAN · CABANG PERENCANA di 3 baris pertama)
  PMB-1/                                   ← satu putaran besar (README.md = peta folder)
    PAPAN.md                ← papan potongan: ID · tahap · lingkup berkas · lensa wajib · ukuran · status (BELUM/DIKLAIM/SELESAI/DIHAKIMI) · sesi · tanggal
    BUKU_BESAR_TEMUAN.md    ← SATU baris per temuan, ID stabil PMB1-F-001…; kolom: tingkat K-1..K-4 · potongan · artefak:baris · janji/aturan baseline yang dilanggar · ciri mutu · bukti (perintah→hasil) · status · hakim · perbaikan (commit) · verifikasi tutup
    MATRIKS_TELUSUR.md      ← janji (PRD M*, aturan bisnis, TECH_SPEC ART-*, KEAMANAN §) → tugas ROADMAP → berkas implementasi → uji → potongan yang memeriksa → hasil
    ASUMSI.md               ← daftar asumsi: kalimat asumsi · sumber (dokumen/fase) · status (dibuktikan/dibantah/terbuka) · riset/bukti · dampak bila salah
    REGRESI_WAJIB.md        ← 117 temuan lama + (otomatis) klaim `[x]` ROADMAP yang DoD-nya menuntut pelaksanaan nyata
    kartu/K-<ID>.md         ← satu kartu per potongan (pemeriksa) dan H-<ID>.md (hakim)
    kalibrasi/              ← bahan cacat tanaman per tahap; kunci jawaban TERENKRIPSI (`KUNCI-TAHAP-<n>.enc`, sandi hanya di tangan Lee)
                              + sidik jari `.sha256` — penyesuaian dari protokol §7 karena PMB berjalan lintas banyak sesi (lihat kalibrasi/README.md)
    RINGKASAN_TAHAP-<n>.md  ← dibuat mesin dari Buku Besar saat gerbang tahap
```

**Siklus status temuan (dijaga mesin):** `BARU → TERVERIFIKASI | PALSU | PERLU-INFO → DIPERBAIKI → DITUTUP`
(+ `DITANGGUHKAN` hanya oleh keputusan Lee, dengan rujukan `docs/TERTANGGUH.md`). Tambahan dari uji coba 2026-09-28: `DUPLIKAT` (Hakim; kembar dari temuan lain yang lebih dulu, dinilai lewat induknya — tidak dihitung palsu). Transisi di luar ini
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
  dokumen (janji tanpa tugas, angka basi, aturan bertentangan); Tahap 2 → cacat SQL/UI; Tahap 4 → alur yang
  sengaja diputus di satu sambungan; Tahap 5 → cacat panduan; Tahap 6 → penjaga yang dilonggarkan.
- Ukuran yang dilaporkan di RINGKASAN tiap tahap: **tingkat deteksi** cacat tanaman (per K-tingkat),
  **temuan palsu** (PALSU ÷ BARU), **cakupan potongan** (SELESAI ÷ total), **cakupan janji** (janji yang
  diperiksa ÷ janji di Matriks), **waktu per potongan**.
- Pemeriksa yang tingkat deteksinya rendah **bukan dihukum** — potongannya diulang oleh pemeriksa lain
  (itulah gunanya ukuran).
- **Ulangan independen** (dua sesi memeriksa potongan yang sama tanpa saling tahu) memberi ukuran kesepakatan antar-pemeriksa
  gratis; Perencana boleh menyengajakannya untuk ±1 dari 5 potongan. Kartunya `K-<ID>.2.md`, temuan kembar → `DUPLIKAT` oleh Hakim.

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

## 11. Pertanyaan keputusan untuk Lee — **DIJAWAB 2026-09-28: "setuju semua"**

> Catatan pelaksanaan: (5) pemilihan model berbeda dilakukan Lee saat membuka tiap sesi peran — bila tidak
> tersedia, dicatat sebagai keterbatasan di kartu; (7) jumlah sesi paralel mengikuti kenyamanan Lee, bawaan 2–3.
> Tambahan Lee di luar 8 pertanyaan: tahap & petugas **Menyeluruh** (§4c) dan **Fase 11 belum dikerjakan** (§4d).


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
   Tahap 2–8 (potongan Tahap 2 diisi rinci setelah baseline dikunci; potongan Tahap 4 = alur M-01…M-08 §4c;
   Fase 11 ikut Tahap 2 sebagai fase yang **belum dikerjakan** — yang diperiksa adalah instrumennya).
2. Tulis **Matriks Telusur v0** dari PRD/TECH_SPEC/KEAMANAN/ROADMAP (mesin membantu: janji & ART-* & tugas).
3. Tulis **prompt giliran** untuk Pemeriksa dan Hakim (satu berkas statis siap-salin, baris pertama diisi
   Lee: putaran + peran) — mengikuti pola `PROMPT_SESI_BARU.md`.
4. Buat `alat/periksa-pemeriksaan.py` (rencana) + `--uji-diri`, daftarkan ke CI.
5. Siapkan bahan kalibrasi Tahap 1 (kunci di luar repo) + daftar **regresi wajib**: 117 temuan lama
   (AUDIT_RIWAYAT) dan semua klaim `[x]` ROADMAP yang menuntut pelaksanaan nyata (§4d).
6. **Uji coba 1 potongan** dengan sesi pemeriksa sungguhan → perbaiki mekanisme dari pengalaman itu →
   baru Tahap 1 dimulai.

**Status 2026-09-28:** butir 1–5 selesai (commit sesi arena/01a0e747; papan nyata 17 potongan Tahap 1 + 46 kerangka Tahap 2–8;
penjaga dan penyusun matriks terdaftar di CI dengan `--uji-diri`). Butir 6 **selesai 2026-09-28**: Lee membuka **dua** sesi dengan prompt F-01 yang sama (arena/01a0e807 & arena/01a0e806) → keduanya
mengikuti alur utuh tanpa bantuan (klaim → periksa → kartu → Buku Besar → asumsi → penjaga LOLOS → push; hanya menulis di `PMB-1/`),
masing-masing ±65 menit, 3 temuan K-3 (18 tautan riset) vs 1 K-3 + 3 K-4 (11 tautan; termasuk 1 temuan luar cakupan di kode
`0072` — validasi pajak sampai 100 % tanpa pagar batas legal 10 %). **Kesamaan tema** (tanpa sumber di DISCOVERY · dasar hukum PB1/PBJT ·
Web Bluetooth tidak ada di iOS · tabel harga) dengan **tingkat K yang berbeda** — persis kelas ketidaksepakatan yang harus dinormalkan
Hakim. Perbaikan mekanisme yang lahir: (1) kartu ulangan independen `kartu/K-<ID>.<n>.md` didukung penjaga; (2) status `DUPLIKAT`
untuk temuan kembar; (3) klaim di papan tidak terlihat lintas cabang → **Perencana menunjuk potongan berbeda per sesi** dalam prompt
singkat (ulangan independen tetap boleh bila disengaja, sebagai pembanding kalibrasi alami); (4) kolom "Model" tidak bisa diisi agent
(antarmuka tidak menampilkannya) → Lee yang mencatat model di chat bila ingin. **Tahap 1 dibuka.**

**Putaran 2 (2026-09-28 malam – 2026-09-29 pagi; cabang 01a0e834 · 01a0e836 · 01a0e839):** Lee menjalankan **2–3 agent per cabang**
(hakim paralel di 834; tiga pemeriksa F-02 di 836; tiga pemeriksa F-03 di 839). Para agent menangani sendiri tabrakan di dalam cabang
(kartu `.2`/`.3`, ID dilanjutkan, "gabung tanpa menimpa") — mekanisme bertahan tanpa instruksi tambahan. Hasil: F-01 **DIHAKIMI**
(7 TERVERIFIKASI · 1 DUPLIKAT; F-007/F-008 dinaikkan K-4→K-3; pendapat kedua berbeda pada F-004/F-006 tercatat di H-F-01), F-02 21 temuan
(4 K-2), F-03 20 temuan (**2 K-1**: voucher dapat diklaim peran anon tanpa verifikasi — probe SQL `PMB-1/bukti/F-03-voucher-anon.sql`;
owner cukup email + PIN dari browser mana pun karena RPC mendaftarkan perangkat sendiri). Hakim menemukan cacat nyata pada mesin PMB
(**PMB1-F-009**: `--uji-diri` tumpul begitu tidak ada baris BARU) → uji-diri ditulis ulang agar tiap kasus membuat cacat sintetisnya sendiri
(13 kasus, LOLOS di tiga keadaan buku besar). Aturan yang lahir: temuan baru hakim tentang mesin → potongan `G-04` (bukan potongan yang
dihakimi); ID selalu lengkap `PMB1-…`; sel tabel tanpa pipa; ≥2 agent per cabang = kartu `.n`. Beban Hakim F-02/F-03 besar (21 & 20 baris,
banyak kembar lintas tiga pemeriksa) → **satu Hakim per potongan**, dan Perencana tidak lagi menyarankan tiga pemeriksa untuk satu potongan
kecuali sebagai kalibrasi yang disengaja.

**Putaran 3 (2026-09-29 pagi; cabang 01a0ea8f · 01a0ea90 · 01a0ea91 · 01a0ea92):** HAKIM F-02 (16 TERVERIFIKASI · 5 DUPLIKAT; F-009 DITUTUP
oleh hakim, bukan pembangun ✓), **dua HAKIM F-03 independen di cabang berbeda** (sepakat 15/20; 3 sengketa validitas → `PERLU-INFO`,
1 K disamakan ke yang lebih berat, 1 TERVERIFIKASI-vs-DUPLIKAT tetap TERVERIFIKASI; masing-masing hakim juga menemukan 1 temuan baru
K-2/K-1 di RPC login → `P-10-00`), dan satu cabang dengan **enam agent** (F-04/F-05/F-06 masing-masing dua kartu; 39 temuan yang
sudah mereka nomori ulang sendiri di dalam cabang). Integrasi tangan sudah tidak aman pada volume ini → lahir `alat/pmb-integrasi.py`
(gabungan baris demi baris; 4 cabang digabung tanpa satu baris pun hilang, penjaga LOLOS di tiap langkah). Aturan baru: sengketa hakim
(README PMB-1) + siklus `TERVERIFIKASI`/`PALSU → PERLU-INFO` khusus sengketa/bukti baru. Buku Besar: 91 temuan · 60 asumsi.

**Putaran 4 (2026-09-29 pagi; cabang 01a0eaca · 01a0eacb · 01a0eacc · 01a0eacd):** HAKIM F-04 (dua hakim dalam satu cabang, aturan sengketa
README **diterapkan sendiri oleh agent**), HAKIM F-05, HAKIM F-06 (dua hakim), **hakim ketiga F-03** (tiga sengketa tuntas: F-044 & F-049
TERVERIFIKASI, F-050 PALSU), PEMERIKSA F-07, F-08 (×2), F-09 (×2). `alat/pmb-integrasi.py` menggabung empat cabang (satu sengketa PAPAN
F-09: klaim tanpa kartu vs SELESAI; satu berkas bukti dengan byte bukan-UTF-8 → alat kini mempertahankan byte apa adanya). Hakim F-06
menemukan dua cacat mesin lagi: **PMB1-F-092** probe SQL pemeriksa yang tautologis (tidak memanggil RPC, tidak mungkin merah) dan
**PMB1-F-094** rujukan `berkas:baris` yang salah baris tidak terdeteksi penjaga → kontrak bukti diperketat (probe wajib memanggil artefak +
kontrol negatif; kutipan 3–8 kata per rujukan baris) dan penjaga menolak nomor baris di luar panjang berkas. Dua hakim F-03 & hakim F-06
juga mencatat temuan luar cakupan di potongan yang masih RENCANA (`P-10-00`, `P-9-00`, `P-1B-00`) → naskah Hakim kini mengatur giliran
"hakim untuk potongan RENCANA" (hanya baris, tanpa mengubah PAPAN). Sesudah putaran 4: **135 temuan** (83 TERVERIFIKASI · 36 BARU ·
11 DUPLIKAT · 2 PALSU · 2 DIPERBAIKI · 1 DITUTUP) · 77 asumsi; F-01…F-06 DIHAKIMI, F-07…F-09 SELESAI, F-10…F-17 BELUM.
**Kelompok K-1 terverifikasi (F-001, F-031, F-036, F-063) semuanya menyangkut RPC login/perangkat & voucher** — layak diputuskan Lee
apakah Pembangun mulai sekarang (K-1 boleh segera) atau menunggu gerbang Tahap 1.

**Putaran 5 (2026-09-29 siang; cabang 01a0eb0a · 01a0eb0d · 01a0eb15 · 01a0eb17 · 01a0eb0f · 01a0eb0e):** HAKIM F-07 (dua laporan
H-F-07.2/H-F-07.3), HAKIM F-08 (dua hakim) + PEMERIKSA F-12 di cabang yang sama, HAKIM P-10-00 (dua hakim, PAPAN tetap RENCANA — aturan
baru §5 bekerja), HAKIM F-09 (dua hakim; **satu SENGKETA HAKIM: PMB1-F-129** TERVERIFIKASI vs PERLU-INFO → hakim ketiga/Lee), PEMERIKSA F-10 (×2)
dan F-11 (×2). Pelajaran mesin: (1) hakim F-07 menyentuh berkas handoff di luar PMB-1 → alat integrasi mendapat `--abaikan-luar-pmb`
(perubahan luar dibuang, dicatat); (2) empat sesi berbeda menutup PMB1-F-092/F-094 → aturan "penutup ganda" dimesinkan (`‖ PENUTUP KEDUA`);
(3) **PMB1-F-136** (hakim F-08): penjaga menerima status berputusan dengan kolom Hakim sembarang → kini wajib menyebut kartu `H-` yang ada
(`3f56abb`); (4) dua giliran berhenti palsu (rujukan kartu ulangan yang tak pernah ada; baris "CI terakhir" handoff yang selalu tertinggal
satu commit) → `9b6481d`. Sesudah putaran 5: **170 temuan** (116 TERVERIFIKASI · 36 BARU · 11 DUPLIKAT · 3 DITUTUP · 2 PALSU · 1 DIPERBAIKI ·
1 PERLU-INFO) · 111 asumsi; **F-01…F-09 DIHAKIMI, F-10…F-12 SELESAI, F-13…F-17 BELUM**. **Enam K-1 semuanya TERVERIFIKASI**
(F-001, F-031, F-036, F-052, F-063, F-127) — menunggu keputusan Lee soal Pembangun. Pengamatan platform: Arena menjalankan **dua agent per
prompt pada cabang yang sama**; mekanisme (kartu `.2`, aturan sengketa, penomoran ulang) sudah menampungnya, tetapi Lee dianjurkan melanjutkan
satu agent saja per potongan.

**Putaran 6 (2026-09-29 siang; cabang 01a0eb68 · eb6c · eb67 · eb73 · eb71 · eb74 · eb6d · eb76):** HAKIM F-11 + F-12 (satu cabang), hakim
ketiga F-09 (**PMB1-F-129 TERVERIFIKASI K-2**, sengketa tuntas; hakim ketiga kedua di cabang eb76 berputusan sama), HAKIM F-10 (13 TERVERIFIKASI ·
1 PALSU · 2 DUPLIKAT · F-171 baru di P-10-00), PEMERIKSA F-13, F-14, F-16, F-17 (F-17 = bahan kalibrasi, 10 "cacat" dicatat). Tiga giliran HAKIM
dijalankan pada potongan yang belum diperiksa (F-14, F-15, F-17) → kartu `H-` kosong ("objek kosong"), PAPAN tidak diubah — naskah §5 bekerja,
tidak ada kerusakan. Enam sesi menutup PMB1-F-136 → aturan penutup ganda otomatis (satu kasus manual karena kolom Hakim ikut disentuh).
`_sistem/validate_system.py` menolak rentang baris bertanda `–` (K-F-14) → diselaraskan dengan `alat/artefak.py`. Sesudah putaran 6: **201 temuan**
(148 TERVERIFIKASI · 33 BARU · 13 DUPLIKAT · 4 DITUTUP · 3 PALSU) · 130 asumsi; **F-01…F-12 DIHAKIMI, F-13/F-14/F-16/F-17 SELESAI, F-15 BELUM**.
**Gerbang Tahap 1 (`--gerbang 1`) menuntut 0 K-1/K-2 terbuka: saat ini 51 (5 K-1 · 46 K-2) di potongan F** → fase Pembangun adalah pekerjaan
besar berikutnya; naskah PEMBANGUN dirinci (§5 PROMPT_GILIRAN: satuan = potongan, satu commit per temuan, kartu `B-`, larangan menyentuh
produksi/PIN/cara masuk Lee, F-001 dilewati sampai keputusan Lee, F-17 tidak dibangun). **Rencana penilaian kalibrasi di gerbang:** Perencana
membuka kunci, mencocokkan baris F-17 dengan daftar cacat tanaman; baris yang cocok → `DITUTUP` oleh Perencana dengan catatan "kalibrasi: cacat
tanaman #n" (sha = commit pembukaan kunci), baris yang tidak cocok = cacat nyata pada dokumen asli → dipindahkan ke potongan pemilik artefak asli
(atau DUPLIKAT bila sudah ada); angka tangkapan/palsu dicatat di `RINGKASAN_TAHAP-1.md`.

**Putaran 7 (2026-09-29 sore; cabang 01a0ec14 · ec18 · ec1b · ec16 · ec13):** HAKIM F-13, F-14 (`H-F-14.2`, kartu pertama kosong), F-16, F-17
(`H-F-17.2`; 9 TERVERIFIKASI · 1 PALSU pada bahan kalibrasi), PEMERIKSA F-15 (13 temuan, F-203…F-215). Hakim F-14 menemukan **PMB1-F-202** (K-4,
G-04): perintah bukti kartu K-F-14 menyebut nama migrasi yang tidak pernah ada → kontrak §4 diperketat (perintah bukti harus benar-benar
dijalankan; nama berkas dari `ls`); sengaja **tidak** dimesinkan karena nama yang salah juga sah dikutip hakim/Buku Besar sebagai barang bukti.
Sesudah putaran 7: **215 temuan** (174 TERVERIFIKASI · 18 BARU · 15 DUPLIKAT · 4 DITUTUP · 4 PALSU) · 136 asumsi; **16 dari 17 potongan
Tahap 1 DIHAKIMI; F-15 SELESAI menunggu HAKIM**. K-1/K-2 terbuka Tahap 1: 52 (5 K-1 · 47 K-2). Setelah HAKIM F-15: fase **PEMBANGUN** (satu
potongan per sesi, berurutan), keputusan Lee tentang klaster cara masuk, lalu pembukaan kunci kalibrasi & `--gerbang 1`.
