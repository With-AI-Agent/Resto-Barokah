# PMB-1 — peta folder (baca ini dulu, lalu `PAPAN.md`)

| Berkas | Isi | Siapa menulis |
|---|---|---|
| `PAPAN.md` | daftar potongan per tahap + status (BELUM/DIKLAIM/SELESAI/DIHAKIMI) — **pintu masuk tiap giliran** | Pemeriksa/Hakim (kolom status, sesi, tanggal); Perencana (baris) |
| `BUKU_BESAR_TEMUAN.md` | satu baris per temuan `PMB1-F-nnn`, siklus status dijaga mesin | Pemeriksa (baris baru), Hakim (Status/Hakim), Pembangun (Perbaikan) |
| `MATRIKS_TELUSUR.md` | janji → tugas ROADMAP → berkas (otomatis) + penugasan potongan & hasil (manual) | mesin (`alat/susun-matriks-telusur.py`) + Perencana |
| `REGRESI_WAJIB.md` | 117 temuan lama + klaim `[x]` yang menuntut pelaksanaan nyata (otomatis) | mesin + Perencana |
| `ASUMSI.md` | asumsi `PMB1-A-nnn` dengan status TERBUKA/DIBUKTIKAN/DIBANTAH | Pemeriksa |
| `kartu/K-<ID>.md` · `kartu/H-<ID>.md` · `kartu/B-<ID>.md` | kartu pemeriksa / kartu hakim / kartu pembangun per potongan (templat `TEMPLAT_K.md`, `TEMPLAT_H.md`, `TEMPLAT_B.md`; penjaga menolak kartu yang bagian wajibnya kurang) | Pemeriksa / Hakim / Pembangun |
| `kalibrasi/` | bahan cacat tanaman per tahap + kunci **terenkripsi** (sandi di tangan Lee) | Perencana |
| `DAFTAR_TUNGGU_LEE.md` | **satu berkas untuk Lee**: semua yang menunggu keputusan/tindakannya (A1 menunggu Lee · A2 sudah diputuskan, menunggu dieksekusi · B K-1 terbuka · C tugas ROADMAP dibuka kembali · D centang ⏳ BUKTI-BELUM · E tertangguh · F Buku Uji belum diisi) — kunci K2 Jaminan Tuntas | mesin (`alat/susun-daftar-tunggu-lee.py`; dibuat ulang tiap integrasi; CI menolak bila basi) |
| `BUKTI_BELUM_BASELINE.txt` | daftar **beku** 146 centang `[x]` ROADMAP yang belum berbukti saat aturan K3 berlaku (2026-09-29); hanya boleh menyusut lewat sensus klaim Tahap 2 / Pembangun dokumen | Perencana (awal) · pemeriksa Tahap 2 & Pembangun dokumen (menghapus ID) |
| `RINGKASAN_TAHAP-<n>.md` | dibuat mesin saat `python3 alat/periksa-pemeriksaan.py --gerbang <n>` | mesin (+ baris kalibrasi oleh Perencana) |

Aturan main lengkap: `../RANCANGAN_PEMERIKSAAN_BERTAHAP.md` (kontrak), `../PROMPT_GILIRAN.md` (naskah lengkap peran), `../PROMPT_SINGKAT.md`
(prompt pendek yang Perencana berikan ke Lee di chat; menyuruh agent membaca `PRO.md` dan semua konteks dulu).
Penjaga: `python3 alat/periksa-pemeriksaan.py` (+ `--uji-diri`, `--gerbang <n>`), berjalan di CI.

**Integrasi lintas sesi:** tiap sesi giliran bekerja di cabang Arena-nya sendiri dan hanya menulis di folder ini. Perencana menggabungkan
dengan `git fetch origin <cabang> && git merge --no-ff origin/<cabang>` (perintah Lee: `integrasikan <cabang>`), menyelesaikan tabrakan
di PAPAN/Buku Besar dengan **mempertahankan semua baris** (ID temuan yang bertabrakan dinomori ulang oleh Perencana dan dicatat di kartu),
lalu menjalankan penjaga dan push. Sejak 2026-09-29 penggabungan memakai **`python3 alat/pmb-integrasi.py origin/<cabang>`**
(gabungan **baris demi baris**: ID baru dinomori ulang melanjutkan ID tertinggi, rujukan di kartu/bukti ikut digeser, kartu untuk potongan yang
sudah punya kartu disimpan sebagai `.2`/`.3`, baris yang diubah dua pihak dilaporkan sebagai SENGKETA dan **tidak** diputuskan mesin).
Dua kekecualian mesin yang **deterministik** (putaran 5, 2026-09-29): (a) **penutup ganda** — dua sesi sama-sama menutup temuan yang sama
(hanya kolom status→DITUTUP & tutup yang berubah) → baris HEAD dipertahankan dan penutup kedua ditambahkan ke kolom tutup dengan penanda
`‖ PENUTUP KEDUA`; (b) `--abaikan-luar-pmb` — bila cabang giliran menyentuh berkas di luar `PMB-1/` (pelanggaran kontrak, mis. handoff),
Perencana boleh membuang perubahan luar itu (versi HEAD dipertahankan) dan pelanggarannya tercatat di pesan commit integrasi.
Catatan hakim di luar kartu (mis. `BERKAS-INTEGRASI-F-08.md`, `REKONSILIASI-F-08.md` dari hakim F-08) bersifat **informatif**; yang
kanonik tetap PAPAN, Buku Besar, ASUMSI, dan kartu `K-`/`H-`/`B-`. **Cabang PEMBANGUN** (sejak 2026-09-29, putaran 8) diintegrasikan dengan `python3 alat/pmb-integrasi.py origin/<cabang> --pembangun`: berkas proyek (kode, migrasi baru, uji, dokumen) ikut dimerge `--no-ff`; yang tetap terlarang = trio handoff, `PRO.md`, naskah & alat mekanisme PMB, `kalibrasi/` (daftar `TERLARANG_PEMBANGUN` di alat); setiap baris yang menjadi `DIPERBAIKI` harus menyebut sha commit yang benar-benar ada di cabang itu (kalau tidak → SENGKETA); konflik git pada berkas proyek tidak diputuskan mesin (SENGKETA, merge dibiarkan terbuka); penjaga tambahan `alat/periksa-bersih.py` harus LOLOS sebelum commit. Naskah giliran berikutnya: catatan seperti itu ditaruh di `kartu/` atau `bukti/`. **Sejak 2026-09-30 (putaran 11, pelajaran PMB1-F-216/F-217 dari integrasi `arena/01a0eff4`):** alat integrasi **berhenti sebelum merge (kode 3)** bila cabang (a) menimpa/menghapus berkas `bukti/` yang sudah ada di basis (**bukti kekal** — hanya penambahan di ujung yang boleh; keluaran giliran = berkas baru berawalan ID kartunya), (b) pada `--pembangun` menghapus baris `docs/ROADMAP.md` di luar pola PEMBANGUN dokumen (`[x]`→`[ ]` teks sama, `Bukti: ⏳ BUKTI-BELUM`, `DoD`, `Verifikasi`) — dilonggarkan hanya oleh Perencana dengan `--izinkan-hapus-roadmap` setelah membaca barisnya, atau (c) menambah `- [x]` di ROADMAP (K6, tidak bisa dilonggarkan). **Arahan Lee 2026-09-30 (REKAM §31 butir 22): hasil giliran harus masuk GitHub** — kartu `B-*.md` wajib baris `- **Ter-push sampai:** `<sha>`` (dari `python3 alat/periksa-push.py`); bila kartu lupa, alat integrasi mengisinya dari tip origin cabang yang diintegrasikan. **Bukti hijau sebelum integrasi (pelajaran PMB1-F-218, cabang `01a0eff7` ditolak 2026-09-30):** Perencana tidak mengintegrasikan cabang Pembangun sebelum (1) CI GitHub tip cabang = `success` (`gh run list --branch <cabang>`), atau bila belum selesai (2) `python3 alat/rantai-bukti-giliran.py` pada worktree tip cabang berakhir `RANTAI: LOLOS`; kartu B yang menulis "LOLOS" tanpa itu tidak dipercaya. Cabang merah dikembalikan ke sesi gilirannya dengan prompt perbaikan singkat (bukan diperbaiki Perencana). **Pengecualian "merah acak" (pelajaran PMB1-F-219, 2026-09-30; hanya bila keempatnya terbukti):** CI merah **tidak** menghalangi integrasi bila (a) langkah yang gagal tidak menyentuh berkas yang ada di diff cabang itu, (b) perintah yang sama dijalankan ulang **≥2×** pada pohon identik (worktree tip) → LOLOS, (c) `python3 alat/rantai-bukti-giliran.py` (jalan penuh) → `RANTAI: LOLOS`, dan (d) run ID, langkah yang gagal, dan bukti (b)–(c) dicatat di kartu B cabang itu + temuan G-01. Tanpa keempatnya, aturan lama berlaku: CI tip cabang wajib `success`.

**Aturan sengketa (dua hakim independen untuk potongan yang sama, diterapkan Perencana saat integrasi — pertama kali F-03, 2026-09-29):**
hakim yang selesai lebih dulu = Hakim 1 (`H-<ID>.md`), yang lain = Hakim 2 (`H-<ID>.2.md`); kedua putusan dicatat di kolom Hakim.
Putusan sama → tetap. Keduanya TERVERIFIKASI dengan tingkat berbeda → tingkat yang **lebih berat**. TERVERIFIKASI vs DUPLIKAT → tetap
TERVERIFIKASI (tidak ada yang hilang; induk disebut). TERVERIFIKASI/PALSU/PERLU-INFO saling bertentangan → **`PERLU-INFO` berawalan
"SENGKETA HAKIM"** → diputuskan hakim ketiga (sesi yang bukan kedua hakim itu) atau Lee. Penutup ganda untuk temuan DIPERBAIKI → kedua
verifikasi dicatat di "Verifikasi tutup".
