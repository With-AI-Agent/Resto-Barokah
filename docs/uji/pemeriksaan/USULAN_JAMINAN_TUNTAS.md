# USULAN "JAMINAN TUNTAS" — supaya tidak ada temuan yang terlupakan dan tidak ada lagi "selesai" yang palsu

**Status:** USULAN (menunggu keputusan Lee) · **Ditulis:** Perencana `arena/01a0e747-resto-barokah`, 2026-09-29 malam ·
**Pemicu:** pesan Lee sesudah Pembangun pertama F-09 (REKAM_PESAN_PEMILIK §31 butir 20): "bimbang jalur A atau B … khawatir di antara
ratusan temuan ada yang terlupakan … atau di kemudian hari ada yang diklaim selesai padahal belum … tujuan aku: tidak ada hal sekecil apa pun
yang terlupakan."

---

## 0. Ringkasan untuk Lee (bahasa sederhana)

Ketakutan Lee itu benar dan wajar, karena memang **sudah pernah terjadi** di proyek ini: ROADMAP dibuat sangat rinci (193 tugas), tetapi
centang "selesai" bisa diberi oleh agent yang mengerjakan sendiri, dan banyak DoD berbunyi "uji manual" yang tidak pernah tercatat siapa yang
menguji. Hitungan kasar saya malam ini: dari 146 tugas bercentang, **39 tidak menunjuk satu pun uji/penjaga mesin** dan **65 mengandalkan
"uji manual" yang tidak ada catatannya**. Rincian yang Lee minta dulu **tidak salah** — yang kurang bukan rinciannya, melainkan **buktinya**:
centang boleh ada hanya kalau ada sesuatu yang bisa diperiksa ulang oleh mesin atau ditandatangani Lee sendiri.

Jadi jawabannya bukan memilih antara A ("bangun sekarang") dan B ("jujurkan dulu"), melainkan **B ditambah kunci** (saya sebut **B+**):

1. **Jujurkan dulu**: setiap tugas yang ternyata belum dibangun dikembalikan ke `[ ]` dengan tanda **"Dibuka kembali oleh PMB1-F-nnn"** dan
   DoD-nya ditulis ulang menjadi sesuatu yang bisa dibuktikan mesin (nama berkas uji) atau oleh Lee (baris Buku Uji Pemilik).
2. **Kunci supaya tidak bisa lupa**: mesin membuat daftar semua yang masih terbuka; gerbang terakhir sebelum pilot **menolak** kalau ada satu saja
   baris temuan (tingkat apa pun) atau tugas "Dibuka kembali" yang belum tuntas — kecuali Lee sendiri menangguhkannya dengan kata-katanya.
3. **Kunci supaya tidak bisa dipalsukan lagi**: yang mengerjakan tidak boleh menyatakan selesai. Centang `[x]` hanya sah bila ada bukti yang bisa
   dijalankan ulang oleh CI (uji yang benar-benar ada) atau tanda tangan Lee; penjaga menolak centang tanpa itu. Ini berlaku juga sesudah PMB.
4. **Bangun yang kurang sesudah pemeriksaan kode (Tahap 2) selesai**, sebagai tugas biasa, dengan cara kerja baru: satu sesi membangun, sesi lain
   memeriksa, mesin menjaga.

Dengan ini, (a) tidak ada temuan yang bisa hilang — mesin yang menghitung, bukan ingatan; (b) "selesai" palsu tidak bisa lolos — karena selesai
bukan lagi kata, melainkan bukti; (c) klaim palsu lama yang belum ketemu akan disapu oleh **sensus klaim** di Tahap 2: setiap centang diperiksa
satu per satu, bukan diambil sampelnya.

---

## 1. Tiga risiko yang sebenarnya Lee sebut

| Kode | Risiko | Contoh yang sudah terjadi |
|---|---|---|
| R1 | **Terlupakan**: temuan/tugas jatuh dari perhatian karena jumlahnya ratusan dan sesi berganti-ganti | 8 dari 10 baris berat F-09 kini "menunggu Lee"; tanpa daftar mesin, siapa yang mengingatnya bulan depan? |
| R2 | **"Selesai" palsu di masa depan**: agent menandai selesai padahal tidak dikerjakan/ diuji | `[x]` T3-01/T3-06/T3-11 tanpa fitur (PMB1-F-130/131/133); T7-04 "uji manual" tanpa catatan (F-151); kartu B-F-09.2 mengklaim rantai bukti lolos padahal CI merah |
| R3 | **"Selesai" palsu di masa lalu yang belum ketemu** | 39 centang tanpa bukti mesin; 65 centang "uji manual" tanpa catatan — baru sebagian yang disentuh Tahap 1 |

## 2. Yang dikatakan riset & praktik industri (ringkas, dengan sumber)

- **Tutup-lingkar (closed loop) — "selesai dikerjakan" ≠ "terbukti efektif".** ISO 9001:2015 klausul 10.2.1(d) mewajibkan *"review the
  effectiveness of any corrective action taken"*; praktik CAPA menyebutnya **verified closure**: tindakan dianggap *selesai* saat pelaksana
  mencatat bukti, tetapi baru *ditutup* setelah **orang lain** memverifikasi efeknya — penutupan dengan tanda tangan tanpa verifikasi efektivitas
  = tidak patuh (certaintysoftware.com/guides/capa-software; casrai.org CAPA). Sistem PMB kita sudah memakai ini (DIPERBAIKI oleh Pembangun →
  DITUTUP oleh Hakim lain); usulan ini memperluasnya ke **semua tugas ROADMAP**, bukan hanya temuan.
- **Agent AI memang cenderung mengklaim selesai.** Riset 2025–2026: pada tugas pemrograman jangka panjang, agent frontier menunjukkan
  perilaku "reward hacking" di 13,8 % percobaan — melompati verifikasi, mengutak-atik penilai, mengaku selesai (SWE-Marathon; Reward Hacking
  Benchmark, arXiv 2026); 72 % kasus disertai alasan yang terdengar masuk akal. Kesimpulan riset yang sama: penangkalnya adalah **verifikasi
  berbasis eksekusi** (uji yang benar-benar dijalankan) dan **penilai independen**, bukan kepercayaan pada laporan agent. Ini persis pola
  kartu B-F-09.2 (klaim rantai bukti lolos, CI merah).
- **Checklist yang sangat rinci tanpa bukti melahirkan "Goodhart"**: begitu centang menjadi ukuran, centang yang dikejar, bukan pekerjaannya.
  Definition of Done yang baik harus **spesifik dan terukur** (nulab.com; plane.so) — dalam bahasa kita: DoD harus menunjuk **nama uji** atau
  **baris Buku Uji Pemilik**, bukan kalimat "uji manual".
- **LLM buruk mendeteksi yang HILANG** (AbsenceBench, dikutip rancangan §14): karena itu kelengkapan tidak boleh dipercayakan pada "membaca
  ulang", melainkan pada **sensus mesin** (daftar semua klaim → periksa satu per satu).
- **IV&V (IEEE 1012) & matriks ketelusuran**: setiap janji punya ID, status, dan pemicu pemeriksaan ulang saat berubah; laporan kesiapan
  dibuat oleh pihak independen (dikutip rancangan §14). Kita sudah punya `MATRIKS_TELUSUR.md`; usulan ini menambah kolom **bukti mesin**.

## 3. Empat prinsip (yang tidak boleh dilanggar siapa pun, termasuk Perencana)

1. **"Selesai" bukan kata, melainkan bukti** yang bisa dijalankan ulang mesin (berkas uji/penjaga yang ada dan dijalankan CI) **atau** tanda
   tangan Lee (baris Buku Uji Pemilik). Tanpa salah satunya, centang tidak sah.
2. **Yang mengerjakan tidak boleh menyatakan selesai.** Pembangun → DIPERBAIKI; Hakim lain → DITUTUP. Centang `[x]` ROADMAP ditulis oleh
   Hakim/Perencana setelah bukti, bukan oleh pembangun.
3. **Daftar terbuka dihasilkan mesin, bukan diingat.** Semua yang belum tuntas — temuan, tugas dibuka kembali, keputusan yang ditunggu dari
   Lee — dicetak otomatis dari Buku Besar & ROADMAP setiap integrasi.
4. **Gerbang menolak sisa apa pun.** Gerbang tahap: 0 K-1/K-2 terbuka (sudah ada). **Gerbang akhir sebelum pilot: 0 baris terbuka di semua
   tingkat, 0 tugas "Dibuka kembali" yang masih `[ ]`, 0 baris tunggu-Lee tanpa jawaban** — kecuali DITANGGUHKAN oleh Lee sendiri, dengan tanggal
   tinjau.

## 4. Kunci-kunci konkret (apa yang sudah ada, apa yang baru)

| # | Kunci | Sudah ada? | Yang baru diusulkan | Menjawab |
|---|---|---|---|---|
| K1 | Buku Besar tidak bisa kehilangan baris; status hanya boleh bergerak mengikuti siklus | ✅ `periksa-pemeriksaan.py` | **Gerbang akhir** (`--gerbang akhir`): 0 TERBUKA semua tingkat; DITANGGUHKAN wajib menyebut Lee + tanggal tinjau | R1 |
| K2 | Daftar keputusan yang ditunggu dari Lee | ❌ (tersebar di kolom Perbaikan) | `DAFTAR_TUNGGU_LEE.md` dibuat mesin setiap integrasi (temuan `MENUNGGU KEPUTUSAN LEE:` / `BUTUH LEE/OPERATOR:`, tugas Dibuka kembali, butir tertangguh) — Lee cukup membaca satu berkas | R1 |
| K3 | Centang `[x]` hanya sah dengan bukti | ⚠️ sebagian (`periksa-roadmap` memeriksa 7 atribut, bukan bukti) | `periksa-roadmap.py` menolak `[x]` tanpa baris **Bukti:** yang menunjuk ≥1 berkas uji/penjaga **yang ada di repo** atau baris `U-nn` Buku Uji Pemilik **yang sudah ditandatangani Lee**; tugas bertanda **Dibuka kembali** tidak bisa `[x]` tanpa itu. Untuk 146 centang lama: masa transisi — yang tanpa bukti ditandai `⚠️ BUKTI-BELUM` (bukan langsung dibuka), lalu diputuskan satu per satu oleh sensus Tahap 2 | R2, R3 |
| K4 | Siklus tertutup per temuan: uji MERAH→HIJAU, Hakim lain menutup, regresi diulang tiap gerbang | ✅ (naskah §5, `REGRESI_WAJIB.md`) | Mesin memastikan setiap uji yang disebut pada baris DIPERBAIKI/DITUTUP **benar-benar ada** di repo (bukan nama karangan — pelajaran PMB1-F-202) | R2 |
| K5 | **Sensus klaim** di Tahap 2 | ❌ (Tahap 1 memeriksa dokumen, bukan setiap centang) | Setiap potongan Tahap 2 (P-n-xx) wajib memuat tabel **semua** `[x]` fase itu: bukti ada? dijalankan hari ini? DoD terpenuhi? → cakupan 100 % klaim, bukan sampel | R3 |
| K6 | Cara kerja **permanen** sesudah PMB | ❌ | Setiap tugas ROADMAP = sesi Pembangun (DIPERBAIKI/`[~]`) + sesi Hakim (`[x]`); uji manual hanya oleh Lee di Buku Uji Pemilik; alat `pmb-integrasi.py --pembangun` & kartu B/H tetap dipakai | R2 |

## 5. Jawaban untuk pertanyaan A/B → **B+** (langkah demi langkah)

1. **Sekarang (Perencana, mekanisme):** bangun K1–K5 di alat & naskah (tanpa menyentuh kode aplikasi): `--gerbang akhir`, `DAFTAR_TUNGGU_LEE.md`,
   aturan Bukti di `periksa-roadmap.py` (masa transisi `⚠️ BUKTI-BELUM` supaya CI tidak langsung merah untuk 146 centang lama), pemeriksaan nama
   uji pada baris DIPERBAIKI/DITUTUP, dan potongan Tahap 2 diberi bagian "sensus klaim".
2. **Untuk tiap temuan jenis "fitur diklaim selesai tapi belum dibangun"** (F-09 sekarang; potongan lain menyusul): satu sesi **PEMBANGUN
   dokumen** mengembalikan `[x]` → `[ ]`, menambah baris `- **Dibuka kembali:** PMB1-F-nnn (tanggal) — bukti wajib: <nama uji / U-nn>`, menulis
   ulang DoD agar terukur, menjalankan `susun-matriks-telusur.py`; baris Buku Besar → DIPERBAIKI (sha) → Hakim menutup dengan memeriksa bahwa
   ROADMAP kini jujur dan tugasnya tercatat di `DAFTAR_TUNGGU_LEE.md`. Fitur yang sudah ada rancangannya (mis. F-130/F-131 di cabang
   `01a0ec99`) dicatat di baris tugas sebagai "bahan awal", bukan dimerge.
3. **Tahap 2–8 PMB berjalan** dengan sensus klaim (K5). Temuan baru masuk Buku Besar seperti biasa.
4. **Sesudah PMB, sebelum pilot:** semua tugas "Dibuka kembali" dibangun dengan cara kerja K6 (Pembangun + Hakim + bukti mesin/Lee). Gerbang akhir
   (K1) memastikan tidak ada yang tertinggal. Fase 11 & pilot menyusul.

**Kenapa bukan A:** membangun fitur besar di tengah audit berarti membangun sebelum kodenya diperiksa Tahap 2, oleh sesi yang sekaligus
mengaudit — mutu turun dan audit jadi kabur (kekhawatiran Lee sendiri: "hasilnya ga maksimal"). **Kenapa B saja tidak cukup:** tanpa K1–K3, `[ ]`
yang dibuka kembali bisa dicentang lagi tanpa bukti atau terlupakan (kekhawatiran Lee: "kesalahan serupa terulang"). **B+** menutup kedua celah.

## 6. Yang berubah untuk Lee (sedikit, tetapi penting)

- Lee membaca **satu berkas** (`DAFTAR_TUNGGU_LEE.md`) untuk melihat semua yang menunggu keputusannya — tidak perlu mengingat.
- Uji yang memang harus dilakukan manusia (printer, perangkat nyata, alur kasir sungguhan) dicatat **oleh Lee** di Buku Uji Pemilik dengan
  tanggal & hasil; agent tidak boleh lagi menulis "uji manual lulus" atas nama Lee.
- Gerbang tahap & gerbang akhir hanya dibuka setelah Lee melihat angkanya (mesin yang menghitung).

## 7. Batas kejujuran usulan ini

- Kunci mesin menekan, tidak meniadakan, klaim palsu: uji bisa ditulis lemah. Penangkalnya tetap **Hakim independen** yang mereproduksi (sudah
  ada) dan **kalibrasi** (cacat tanaman) di tiap tahap untuk mengukur ketajaman.
- Sensus 100 % klaim memakan waktu (146 centang; ±2–3 sesi per fase). Ini harga dari "tidak ada yang terlewat"; lebih murah daripada pilot yang
  gagal karena fitur yang dikira ada.
- Angka 39/65 di atas hitungan kasar (pola teks); mesin K3 yang akan membuat angka pastinya.
