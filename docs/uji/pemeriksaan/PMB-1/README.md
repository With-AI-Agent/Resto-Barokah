# PMB-1 — peta folder (baca ini dulu, lalu `PAPAN.md`)

| Berkas | Isi | Siapa menulis |
|---|---|---|
| `PAPAN.md` | daftar potongan per tahap + status (BELUM/DIKLAIM/SELESAI/DIHAKIMI) — **pintu masuk tiap giliran** | Pemeriksa/Hakim (kolom status, sesi, tanggal); Perencana (baris) |
| `BUKU_BESAR_TEMUAN.md` | satu baris per temuan `PMB1-F-nnn`, siklus status dijaga mesin | Pemeriksa (baris baru), Hakim (Status/Hakim), Pembangun (Perbaikan) |
| `MATRIKS_TELUSUR.md` | janji → tugas ROADMAP → berkas (otomatis) + penugasan potongan & hasil (manual) | mesin (`alat/susun-matriks-telusur.py`) + Perencana |
| `REGRESI_WAJIB.md` | 117 temuan lama + klaim `[x]` yang menuntut pelaksanaan nyata (otomatis) | mesin + Perencana |
| `ASUMSI.md` | asumsi `PMB1-A-nnn` dengan status TERBUKA/DIBUKTIKAN/DIBANTAH | Pemeriksa |
| `kartu/K-<ID>.md` · `kartu/H-<ID>.md` | kartu pemeriksa / kartu hakim per potongan (templat `TEMPLAT_K.md`, `TEMPLAT_H.md`) | Pemeriksa / Hakim |
| `kalibrasi/` | bahan cacat tanaman per tahap + kunci **terenkripsi** (sandi di tangan Lee) | Perencana |
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

**Aturan sengketa (dua hakim independen untuk potongan yang sama, diterapkan Perencana saat integrasi — pertama kali F-03, 2026-09-29):**
hakim yang selesai lebih dulu = Hakim 1 (`H-<ID>.md`), yang lain = Hakim 2 (`H-<ID>.2.md`); kedua putusan dicatat di kolom Hakim.
Putusan sama → tetap. Keduanya TERVERIFIKASI dengan tingkat berbeda → tingkat yang **lebih berat**. TERVERIFIKASI vs DUPLIKAT → tetap
TERVERIFIKASI (tidak ada yang hilang; induk disebut). TERVERIFIKASI/PALSU/PERLU-INFO saling bertentangan → **`PERLU-INFO` berawalan
"SENGKETA HAKIM"** → diputuskan hakim ketiga (sesi yang bukan kedua hakim itu) atau Lee. Penutup ganda untuk temuan DIPERBAIKI → kedua
verifikasi dicatat di "Verifikasi tutup".
