# Laporan Review Independen Fondasi — Resto Barokah (putaran 3, 2026-09-19)

> Ditulis oleh sesi review `arena/01a0b9f2-resto-barokah` (bukan sesi pembangun). Semua angka di laporan ini berasal dari perintah yang dijalankan sendiri di sesi ini; perintahnya ditulis di tiap bagian supaya bisa diulang siapa pun.
> Bahasa sengaja sederhana. Istilah teknis yang tidak terhindarkan dijelaskan saat pertama muncul.
>
> **Catatan penting tentang berkas ini:** di cabang yang ditinjau sudah ada `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` milik review putaran 2 (2026-09-16, 2.641 baris). Laporan putaran 3 ini ditulis di cabang review sendiri pada path yang sama sesuai instruksi. Saat digabungkan ke cabang pembangun, simpan laporan putaran 2 dengan nama lain (mis. `LAPORAN_REVIEW_INDEPENDEN_putaran2.md`) — **jangan dihapus**, karena beberapa keputusan (T10-09…T10-12, T-012, T-013) merujuk ke sana.

---

## 1. Laporan 5 baris (untuk pemilik)

1. **Yang ditinjau:** fondasi di cabang `arena/01a0aac5-resto-barokah` commit `a522db0` (satu-satunya cabang berstatus `CODING_AKTIF`), diuji silang dengan cabang terbaru `arena/01a0b7d1-resto-barokah` commit `267d890` (2026-09-19) yang sudah mengerjakan Fase 0 dan sebagian Fase 1. Jadi anggapan "review sebelum coding" **tidak lagi sepenuhnya benar** — coding sudah berjalan di cabang lain.
2. **Putusan: `SIAP SETELAH PERBAIKAN`.** 0 temuan Kritis, 3 Mayor (2 sudah saya perbaiki di cabang review tetapi belum digabung, 1 butuh keputusan pemilik), 17 Minor, 20 Catatan. Semua pemeriksa lama tetap hijau; pemeriksa ketiga yang baru saya tulis menemukan 31 cacat di `a522db0` dan 37 di `267d890`, lalu 0 setelah perbaikan saya.
3. **Dua hal yang butuh keputusan pemilik** (dicatat sebagai T-022 & T-023 di `docs/TERTANGGUH.md`): (a) email ke pelanggan lewat Resend **tanpa domain sendiri tidak bisa** — Resend hanya mengizinkan kirim ke alamat email pemilik akun; perlu pilih jalur lain yang gratis (usul: Gmail pemilik via sandi aplikasi, atau Brevo). (b) PIN pelanggan dijanjikan di PRD tetapi tidak ada di rancangan basis data — pilih dihapus atau ditambah.
4. **Fakta yang meleset di dokumen:** repo ini **privat** (bukan publik seperti ditulis T0-07 → jatah CI gratis 2.000 menit/bulan, bukan tak terbatas); 19 tugas berisiko tinggi tidak bertanda ⚠️ di judulnya sehingga kewajiban mencatat keputusan bisa terlewat; nama status pesanan di ROADMAP berbeda dari TECH_SPEC; denyut anti-tidur Supabase dirancang dari dalam basis data padahal yang tidur justru basis datanya (dan di cabang terbaru proyek Supabase memang sudah pernah dijeda).
5. **Yang saya kerjakan:** 1 commit di cabang `arena/01a0b9f2-resto-barokah` berisi laporan ini, pemeriksa baru `alat/periksa-fondasi-independen-2.py`, perbaikan 5 dokumen non-terkunci + `.gitignore`, 2 entri `docs/DECISIONS_LOG.md`, dan berkas tambalan `docs/uji/perbaikan-putaran3.patch` untuk sesi pembangun. Tidak ada PR yang di-merge/ditutup, tidak ada coding aplikasi, tidak ada biaya.

---

## 2. Putusan

**`SIAP SETELAH PERBAIKAN`** — aman melanjutkan Fase 0/1 (yang nyatanya sudah berjalan di `267d890`) **setelah** daftar di bawah digabung ke cabang pembangun aktif, dan **Fase 2 (T2-04/T2-05) tidak boleh dimulai** sebelum T-022 & T-023 dijawab pemilik.

Definisi tingkat yang saya pakai: **KRITIS** = uang/data pelanggan/keamanan salah atau proyek tidak bisa jalan sama sekali · **MAYOR** = janji fondasi tidak bisa dipenuhi tanpa keputusan baru atau perubahan rencana · **MINOR** = teks/angka/rujukan salah yang menyesatkan agent tetapi mudah diperbaiki · **CATATAN** = saran/penguat.

| Tingkat | Jumlah | Terbuka setelah sesi ini | Keterangan |
|---|---|---|---|
| KRITIS | 0 | 0 | — |
| MAYOR | 3 | 1 (W9-01 menunggu pemilik) | W1-01 ⚠️ judul & W5-02 repo privat sudah diperbaiki di cabang review (belum digabung = belum berlaku) |
| MINOR | 17 | 6 (semua DIUSULKAN/sudah ditutup di 267d890, bukan penghalang) | rincian di bagian 6 |
| CATATAN | 20 (13 bernomor + 7 di tabel W4/bagian 8) | — | saran |

**Yang harus digabung ke cabang pembangun supaya putusan berlaku** (semua ada di commit sesi ini; tambalan siap: `docs/uji/perbaikan-putaran3.patch`):

1. `docs/ROADMAP.md` — 41 potongan perubahan (⚠️ 19 judul, nama status T1-18/T4-04, 8 Verifikasi generik, T0-01/T0-05/T0-07/T0-08/T10-08/T11-07, T2-04/T2-05/T8-07, T3-05/T1-21, T5-07, T11-03, header & gerbang F0, log keputusan). Ke `267d890`: 34 potongan masuk otomatis, 7 perlu ditulis tangan (daftar di bagian 4.4).
2. `docs/TERTANGGUH.md` — T-022, T-023, tenggat T-013.
3. `docs/DECISIONS_LOG.md` — 2 entri (satu bertanda MENUNGGU PERSETUJUAN PEMILIK).
4. `docs/AGENT_OPERATING_GUIDE.md` §0 — kalimat "PR harus di-merge dulu" diganti (bertentangan dengan keputusan pemilik "jangan merge PR #1").
5. `docs/README.md` — angka 146→150 (di `267d890` sudah benar), tambah perintah pemeriksa ketiga.
6. `.gitignore` — `!.env.example` (di `267d890` sudah ada).
7. `alat/periksa-fondasi-independen-2.py` — pemeriksa ketiga; tambahkan ke CI **tanpa** mengganti dua pemeriksa lama.

Mengapa bukan `SIAP MULAI CODING`: aturan putusan mensyaratkan 0 Mayor terbuka; W9-01 (email) hanya bisa ditutup pemilik, dan perbaikan saya belum digabung. Mengapa bukan `BELUM SIAP`: tidak ada temuan yang membuat Fase 0–1 salah arah; semua Mayor punya jalan keluar gratis dan jelas.

---

## 3. Apa yang ditinjau (cabang, commit, rute)

**Prasyarat 0 — cara menemukan fondasi (dicatat per langkah):**

| Langkah | Perintah | Hasil |
|---|---|---|
| Rute A (checkout sendiri) | `git rev-parse --abbrev-ref HEAD; git log --oneline -3; ls docs/ROADMAP.md` | cabang `arena/01a0b9f2-resto-barokah` = `main` @ `253d129`, **tidak ada** `docs/ROADMAP.md` maupun `PROJECT_STATE.md` → Rute A gagal |
| Rute B (cabang `arena/*` di remote) | `git ls-remote --heads origin` → 13 cabang `arena/*` + `main`; tiap cabang: `git fetch origin <cabang>` lalu `git ls-tree FETCH_HEAD docs/ROADMAP.md` + `git show FETCH_HEAD:PROJECT_STATE.md \| grep STATUS` | 4 cabang punya fondasi: `01a0a8a2`@`0af1cf9` (DIJEDA), **`01a0aac5`@`a522db0` (`CODING_AKTIF`)**, `01a0b4c3`@`1e353fa` (DIJEDA), `01a0b7d1`@`267d890` (`CODING_DIJEDA_SADAR`, terbaru 2026-09-19) |
| Pilihan | aturan instruksi: pilih `CODING_AKTIF` | hanya `a522db0` yang cocok → **target utama**; `267d890` (turunan `a522db0`, +312 berkas baru, 28 berkas berubah) dipakai **uji silang** untuk setiap temuan |
| Ekstrak tanpa pindah cabang | `git archive a522db0 \| tar -x -C /tmp/fondasi-review` (dan `267d890` → `/tmp/fondasi-terbaru`) | 1.973 berkas terlacak (1.802 di `skills/` + 171 lainnya), 38 MB |
| Rute C | — | tidak dipakai |

- **Commit yang ditinjau:** `a522db0c19e92ebf8aeec18d71da4a8b2ded94fc` — "Review independen fondasi: 9 temuan diperbaiki + pemeriksa independen baru" (2026-09-16). Uji silang: `267d8906fac1c8435eaa822460aa026f98f1d283`.
- **Repo:** `With-AI-Agent/Resto-Barokah`, `gh repo view --json isPrivate` → `"isPrivate": true`; PR #1 (`01a0a8a2`) dan PR #2 (`01a0b7d1`) berstatus OPEN — **tidak disentuh**.
- **Aturan repo yang dibaca sebelum bekerja:** `START_DI_SINI.md` (Jenis Sesi 3 Audit/Cross-Check), `AGENT_SYSTEM.md` "LANGKAH PERTAMA DI SETIAP SESI" (baris 42–95), `PROFIL_PENGGUNA.md`, `PROJECT_STATE.md`.
- **`alat/mulai-sesi.py`** dijalankan di `/tmp/fondasi-review`: EXIT 0; blok **DAFTAR TUNGGU** tampil benar (6 butir = 6 baris terbuka di `docs/TERTANGGUH.md`: T-002/003/010/011/012/013); blok **KARTU SESI** tampil; 87 SKILL.md terbaca; 15 skill wajib untuk `CODING_AKTIF`; 12 berkas fondasi ADA. Catatan: karena folder ekstrak bukan repo git, kartu menampilkan `Branch aktif: fatal: not a git repository` — skrip tidak mendeteksi kegagalan git (lihat W7-03).

---

## 4. Metode & perintah

### 4.1 Urutan kerja
1. Baca penuh (bukan skim): `START_DI_SINI.md`, `AGENT_SYSTEM.md` (bagian sesi), `PROJECT_STATE.md`, `PROFIL_PENGGUNA.md`, `docs/TECH_SPEC.md` (§0–§13), `docs/ROADMAP.md` (1.468 baris), `docs/PRD.md`, `docs/AGENT_OPERATING_GUIDE.md`, `docs/TERTANGGUH.md`, `docs/DECISIONS_LOG.md`, `docs/README.md`, `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` (putaran 2), `docs/uji/CATATAN_REVIEW_SESI_01a0aab1.md`, `PANDUAN_PENGGUNA.md` (191 baris, penuh), kedua pemeriksa lama, logika `_sistem/validate_system.py`.
2. Jalankan pemeriksa lama; tulis pemeriksa ketiga dengan sudut pandang berbeda; uji mutasi (`--uji-diri`).
3. Uji tangan 15 tugas acak + T0-01…T0-10.
4. Verifikasi klaim luar (batas gratis Supabase/Cloudflare/Resend/GitHub Actions) ke dokumen resmi.
5. Terapkan perbaikan di checkout sendiri, bangun salinan `a522db0 + perbaikan` di `/tmp/fondasi-perbaikan`, jalankan semua pemeriksa lagi; uji tambalan ke `267d890`.

### 4.2 Perintah utama (bisa diulang)
```bash
# pemeriksa lama pada a522db0 (cwd /tmp/fondasi-review)
python3 _sistem/validate_system.py            # → PASS, exit 0
python3 alat/periksa-roadmap.py               # → LOLOS, 150 tugas, exit 0
python3 alat/periksa-fondasi-independen.py    # → BERSIH, exit 0
python3 alat/mulai-sesi.py                    # → DAFTAR TUNGGU 6 butir, KARTU SESI tampil

# pemeriksa ketiga (baru) — dari checkout review. Di cabang review ini docs/TECH_SPEC.md & docs/PRD.md sengaja TIDAK disalin
# (dokumen terkunci), jadi wajib memberi --akar; tanpa itu skrip berhenti dengan pesan jelas (exit 1).
python3 alat/periksa-fondasi-independen-2.py --akar /tmp/fondasi-review     # → 31 GAGAL, 10 PERINGATAN, exit 1
python3 alat/periksa-fondasi-independen-2.py --akar /tmp/fondasi-terbaru    # → 37 GAGAL, 17 PERINGATAN, exit 1
python3 alat/periksa-fondasi-independen-2.py --akar /tmp/fondasi-perbaikan  # → 0 GAGAL, 10 PERINGATAN, exit 0
python3 alat/periksa-fondasi-independen-2.py --akar /tmp/fondasi-perbaikan --uji-diri  # → 7/7 mutasi tertangkap

# integritas repo
git ls-tree -r --name-only a522db0 | wc -l                       # 1973
git ls-tree -r -l a522db0 | sort -k4 -nr | head                  # berkas terbesar
git check-ignore -v aplikasi/.env.example                        # bukti .env.example ikut terabaikan (a522db0)
```

### 4.3 Sumber luar yang dipakai untuk memverifikasi klaim (dibuka 2026-09-19)
- Supabase — *Going into Prod* (docs resmi): proyek Free dijeda bila aktivitas rendah dalam 7 hari; pemulihan manual dari dashboard; cadangan Free tidak bisa diunduh.
- Resend — *API Reference › Errors* (docs resmi): 403 `validation_error` "You can only send testing emails to your own email address … verify a domain". Paket gratis: 3.000/bulan, **100/hari**, 1 domain.
- Cloudflare — *Workers › Platform › Limits* (docs resmi): Free 100.000 permintaan/hari, permintaan aset statis tidak dihitung, **5 Cron Trigger** per akun.
- GitHub — diskusi komunitas & kalkulator biaya Actions: repo publik gratis tanpa batas; **repo privat paket Free: 2.000 menit/bulan + 500 MB artefak**, batas belanja $0 → workflow berhenti, tidak menagih.
- Diskusi komunitas Supabase (#13121) & dua blog: pg_cron internal tidak bisa membangunkan proyek yang sudah dijeda — perlu pemicu dari luar.

### 4.4 Uji tambalan ke cabang terbaru
`patch -p1 -d /tmp/fondasi-terbaru --dry-run < docs/uji/perbaikan-putaran3.patch` →
`docs/ROADMAP.md` 34 dari 41 potongan masuk (7 gagal: #2 gerbang F0, #4 T0-07, #5 T1-10 area, #8 T1-18 — di sana sudah diperbaiki dengan cara lain, #19 T4-04, #35 T10-08, #41 tabel log); `docs/README.md` 1 dari 2; `docs/TERTANGGUH.md` & `docs/DECISIONS_LOG.md` gagal karena berkasnya sudah jauh berubah (isi entrinya tinggal disalin ke akhir berkas); `.gitignore` sudah berisi perbaikan yang sama; pemeriksa baru masuk utuh.

---

## 5. Tabel cakupan berkas

Status: **MENDALAM** = dibaca seluruhnya/diuji perilakunya · **SEKILAS** = kepala/struktur/grep · **TIDAK** = tidak dibuka (alasan di kolom).
Kebijakan `skills/`: **1.802 berkas, 56 folder, 87 `SKILL.md`, 21,8 MB (blob Git)** — berkas vendor pihak ketiga, tidak ditinjau isinya; yang diperiksa hanya jumlah folder/`SKILL.md` (cocok dengan klaim `AGENT_OPERATING_GUIDE` §2 & `SYSTEM_MANIFEST`), tidak ada pola rahasia di nama berkas, dan `alat/mulai-sesi.py` bisa membacanya.

**Ringkasan 171 berkas non-`skills/`:** MENDALAM 23 · SEKILAS 19 · TIDAK DIPERIKSA 129 (biner gambar/font 87, sisanya alasan di kolom). Dibangkitkan dari `git ls-tree -r -l a522db0` (bukan diketik tangan).

| # | Berkas | Ukuran | Status | Cara/alasan |
|---|---|---|---|---|
| 1 | `.gitignore` | 354 B | MENDALAM | dibaca + diuji `git check-ignore` (W4 T0-05) |
| 2 | `10_LOG_SESI.md` | 3.8 KB | SEKILAS | aturan log; tidak relevan fondasi |
| 3 | `ACCEPTANCE_TESTS.md` | 8.8 KB | MENDALAM | daftar AT-01…AT-09 dibaca; AT-07/08/09 dijalankan (W6-03) |
| 4 | `ACCEPTANCE_TEST_LOG.md` | 25.6 KB | SEKILAS | kepala; bukti run klinik lama |
| 5 | `AGENT_SYSTEM.md` | 50.3 KB | MENDALAM | bagian sesi (baris 42–95), tabel status, prosedur coding; sisanya dibaca sebagian |
| 6 | `PANDUAN_PEMAKAIAN.md` | 9.0 KB | SEKILAS | kepala (penanda arsip) + uji mutasi validator |
| 7 | `PANDUAN_PENGGUNA.md` | 18.6 KB | MENDALAM | dibaca penuh (191 baris) sebagai pemilik non-teknis (W8) |
| 8 | `PROFIL_PENGGUNA.md` | 3.7 KB | MENDALAM | dibaca penuh |
| 9 | `PROJECT_STATE.md` | 4.5 KB | MENDALAM | dibaca penuh; tidak diubah |
| 10 | `PROMPT_ENTRI_UNIVERSAL.md` | 4.8 KB | SEKILAS | blok prompt dibaca (W7/W8) |
| 11 | `REKAM-KLINIK.md` | 7.4 KB | SEKILAS | kepala; arsip perawatan kit |
| 12 | `START_DI_SINI.md` | 4.3 KB | MENDALAM | aturan jenis sesi; dibaca penuh |
| 13 | `STATUS.md` | 25.2 KB | MENDALAM | kepala + field checkpoint; tidak diubah |
| 14 | `SYSTEM_MANIFEST.md` | 22.8 KB | SEKILAS | 60 baris pertama + klaim skills |
| 15 | `_Notes.md` | 587 B | MENDALAM | 9 baris; berisi data pribadi pemilik (W6-02) |
| 16 | `_log-sesi/LOG_SESI_2026-09-15.md` | 20.5 KB | TIDAK | log sesi sebelum fondasi ada |
| 17 | `_log-sesi/LOG_SESI_2026-09-16.md` | 103.5 KB | SEKILAS | grep (@napi-rs/canvas, keputusan) |
| 18 | `_salinan-meta/PLATFORM_LMARENA.md` | 7.7 KB | TIDAK | salinan meta historis; bukan fondasi |
| 19 | `_salinan-meta/STATUS_SISTEM_v0.2.0_HISTORI.md` | 5.3 KB | TIDAK | salinan meta historis; bukan fondasi |
| 20 | `_sistem/02_TAWARAN_KAPABILITAS_PLUS_AUDIT.md` | 10.9 KB | SEKILAS | kepala; arsip bertanggal |
| 21 | `_sistem/03_AUDIT_VERCEL_SKILLS.md` | 11.2 KB | SEKILAS | kepala; arsip |
| 22 | `_sistem/AUDIT_NPX_UPDATE_2026-09-16.md` | 3.3 KB | SEKILAS | kepala; arsip |
| 23 | `_sistem/AUDIT_ZIP_VS_NPX_2026-09-16.md` | 4.3 KB | SEKILAS | kepala; arsip |
| 24 | `_sistem/templates/AGENT_OPERATING_GUIDE.md` | 5.6 KB | TIDAK | templat kit; hanya dipakai validator (waktu) |
| 25 | `_sistem/templates/DECISIONS_LOG.md` | 841 B | TIDAK | templat kit; hanya dipakai validator (waktu) |
| 26 | `_sistem/templates/DISCOVERY.md` | 738 B | TIDAK | templat kit; hanya dipakai validator (waktu) |
| 27 | `_sistem/templates/LOG_SESI.md` | 2.3 KB | TIDAK | templat kit; hanya dipakai validator (waktu) |
| 28 | `_sistem/templates/PRD.md` | 598 B | TIDAK | templat kit; hanya dipakai validator (waktu) |
| 29 | `_sistem/templates/PROFIL_PENGGUNA.md` | 2.8 KB | TIDAK | templat kit; hanya dipakai validator (waktu) |
| 30 | `_sistem/templates/PROJECT_STATE.md` | 421 B | TIDAK | templat kit; hanya dipakai validator (waktu) |
| 31 | `_sistem/templates/ROADMAP.md` | 3.4 KB | TIDAK | templat kit; hanya dipakai validator (waktu) |
| 32 | `_sistem/templates/STATUS.md` | 699 B | TIDAK | templat kit; hanya dipakai validator (waktu) |
| 33 | `_sistem/templates/TECH_SPEC.md` | 789 B | TIDAK | templat kit; hanya dipakai validator (waktu) |
| 34 | `_sistem/validate_system.py` | 19.1 KB | MENDALAM | daftar cek & 3 fungsi kunci dibaca; dijalankan + 4 uji mutasi (W6) |
| 35 | `alat/mulai-sesi.py` | 11.2 KB | MENDALAM | dijalankan 4 kali (a522db0, overlay, status asing, folder non-git); peta status dibaca; kode tidak dibaca baris demi baris |
| 36 | `alat/periksa-fondasi-independen.py` | 11.2 KB | MENDALAM | logika dibaca penuh + dijalankan + uji mutasi (W3) |
| 37 | `alat/periksa-roadmap.py` | 6.4 KB | MENDALAM | logika dibaca penuh + dijalankan + uji mutasi (W3) |
| 38 | `docs/AGENT_OPERATING_GUIDE.md` | 20.1 KB | MENDALAM | §0–§13 dibaca penuh; §0 diperbaiki |
| 39 | `docs/DECISIONS_LOG.md` | 8.0 KB | MENDALAM | 8 entri dibaca; 2 entri ditambah |
| 40 | `docs/DISCOVERY.md` | 22.0 KB | SEKILAS | kepala + status kunci; terkunci |
| 41 | `docs/PRD.md` | 26.6 KB | MENDALAM | §1–§11 dibaca penuh (terkunci, tidak diubah) |
| 42 | `docs/README.md` | 1.6 KB | MENDALAM | dibaca penuh; angka 146→150 |
| 43 | `docs/ROADMAP.md` | 110.9 KB | MENDALAM | 1.468 baris dibaca penuh; 150 tugas diurai 3 pemeriksa; 41 potongan diperbaiki |
| 44 | `docs/TECH_SPEC.md` | 33.3 KB | MENDALAM | §0–§13 dibaca penuh (terkunci, tidak diubah); dipakai sebagai sumber data pemeriksa ketiga |
| 45 | `docs/TERTANGGUH.md` | 4.9 KB | MENDALAM | dibaca penuh; T-022/T-023 ditambah, tenggat T-013 |
| 46 | `docs/desain/PENILAIAN_REFERENSI.md` | 7.0 KB | SEKILAS | kepala |
| 47 | `docs/desain/RENCANA_DESAIN_UI.md` | 21.5 KB | SEKILAS | kepala + baris 118 (klaim woff2) |
| 48 | `docs/desain/mockup/papan-1-bara-panggang.png` | 603.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 49 | `docs/desain/mockup/papan-2-hangat-kedai.png` | 659.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 50 | `docs/desain/mockup/papan-3-kasir-terang.png` | 729.9 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 51 | `docs/desain/mockup/papan-4-kasir-gelap.png` | 709.3 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 52 | `docs/desain/mockup/papan-5-katalog-terang.png` | 663.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 53 | `docs/desain/palet-tema.png` | 287.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 54 | `docs/desain/papan-referensi-pemilik.jpg` | 1102.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 55 | `docs/desain/papan-referensi.jpg` | 140.8 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 56 | `docs/desain/referensi/01-pos-dashboard-food.webp` | 21.6 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 57 | `docs/desain/referensi/02-kasir-cashier-dashboard.webp` | 9.5 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 58 | `docs/desain/referensi/03-admin-order-coffeeshop.webp` | 9.8 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 59 | `docs/desain/referensi/04-dapurku-pos-fastfood.webp` | 13.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 60 | `docs/desain/referensi/05-kds-1.webp` | 10.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 61 | `docs/desain/referensi/06-kds-2.webp` | 131.9 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 62 | `docs/desain/referensi/07-kds-3.webp` | 94.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 63 | `docs/desain/referensi/08-pos-pelayan-mobile.webp` | 12.7 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 64 | `docs/desain/referensi/09-waiter-booking-app.webp` | 16.8 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 65 | `docs/desain/referensi/10-waiter-android.webp` | 63.9 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 66 | `docs/desain/referensi/11-alur-keranjang-checkout.webp` | 129.8 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 67 | `docs/desain/referensi/12-dashboard-laporan-resto.jpg` | 296.6 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 68 | `docs/desain/referensi/13-dashboard-gelap.webp` | 10.0 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 69 | `docs/desain/referensi/Sumber.md` | 2.8 KB | TIDAK | gambar referensi/indeksnya; keputusan desain milik pemilik |
| 70 | `docs/desain/referensi/pemilik/P01-katalog-detail-navy.jpg` | 67.6 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 71 | `docs/desain/referensi/pemilik/P02-web-menu-keranjang.jpg` | 89.5 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 72 | `docs/desain/referensi/pemilik/P03-mobile-burger-gelap.jpg` | 140.4 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 73 | `docs/desain/referensi/pemilik/P04-kasir-desktop-terang.jpg` | 37.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 74 | `docs/desain/referensi/pemilik/P05-mobile-pesanan-keranjang.jpg` | 53.0 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 75 | `docs/desain/referensi/pemilik/P06-poster-menu-ramen.jpg` | 178.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 76 | `docs/desain/referensi/pemilik/P07-poster-espresso.jpg` | 166.9 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 77 | `docs/desain/referensi/pemilik/P08-katalog-terang-bersih.jpg` | 54.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 78 | `docs/desain/referensi/pemilik/P09-kolase-promosi.jpg` | 140.8 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 79 | `docs/desain/referensi/pemilik/P10-mobile-daftar-menu.jpg` | 60.7 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 80 | `docs/desain/referensi/pemilik/P11-mobile-proses-desain.jpg` | 78.5 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 81 | `docs/desain/referensi/pemilik/P12-terang-vs-gelap.jpg` | 62.3 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 82 | `docs/desain/referensi/pemilik/P13-web-mewah-gelap.jpg` | 125.4 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 83 | `docs/desain/referensi/pemilik/P14-mobile-ember-grill.jpg` | 130.7 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 84 | `docs/desain/referensi/pemilik/P15-mobile-kopi-hangat.jpg` | 124.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 85 | `docs/desain/referensi/pemilik/P16-mobile-grill-co.jpg` | 155.9 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 86 | `docs/desain/referensi/pemilik/P17-kasir-pos-gelap.jpg` | 53.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 87 | `docs/desain/referensi/pemilik/P18-katalog-burger-biru.jpg` | 93.6 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 88 | `docs/desain/referensi/pemilik/P19-mobile-seafood-set.jpg` | 95.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 89 | `docs/desain/referensi/pemilik/P20-mobile-fastfood-oranye.jpg` | 22.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 90 | `docs/desain/referensi/pemilik/P21-aplikasi-rupiah.jpg` | 83.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 91 | `docs/desain/referensi/pemilik/P22-toko-kue-alur.jpg` | 64.8 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 92 | `docs/desain/referensi/pemilik/P23-menu-tabel-keranjang.jpg` | 100.0 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 93 | `docs/desain/referensi/pemilik/P24-mobile-foodie-gelap.jpg` | 64.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 94 | `docs/desain/referensi/pemilik/P25-kopi-gelap-ukuran.jpg` | 57.0 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 95 | `docs/desain/referensi/pemilik/P26-panel-laporan-terang.jpg` | 36.5 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 96 | `docs/desain/referensi/pemilik/P27-kopi-gelap-varian.jpg` | 57.3 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 97 | `docs/desain/referensi/pemilik/P28-detail-menu-hangat.jpg` | 103.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 98 | `docs/desain/referensi/pemilik/P29-kartu-menu-gelap.jpg` | 57.7 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 99 | `docs/desain/referensi/pemilik/P30-menu-indonesia.jpg` | 82.6 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 100 | `docs/desain/referensi/pemilik/P31-dashboard-pesanan-gelap.jpg` | 25.9 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 101 | `docs/desain/referensi/pemilik/P32-kasir-pos-terang.jpg` | 55.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 102 | `docs/desain/referensi/pemilik/P33-mobile-five-guys.jpg` | 130.6 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 103 | `docs/desain/referensi/pemilik/P34-resep-gelap.jpg` | 54.4 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 104 | `docs/desain/referensi/pemilik/README.md` | 8.4 KB | TIDAK | gambar referensi/indeksnya; keputusan desain milik pemilik |
| 105 | `docs/teknis/DISKUSI_TAHAP4_ATURAN_KERJA.md` | 12.2 KB | SEKILAS | kepala; bahan diskusi |
| 106 | `docs/teknis/DISKUSI_TAHAP5_ROADMAP.md` | 10.6 KB | SEKILAS | kepala; bahan diskusi |
| 107 | `docs/teknis/DISKUSI_TEKNIS_TAHAP3.md` | 9.9 KB | SEKILAS | kepala + baris 32 (syarat domain email) via grep |
| 108 | `docs/uji/CATATAN_REVIEW_SESI_01a0aab1.md` | 3.0 KB | MENDALAM | dibaca penuh (konteks putaran 1 gagal) |
| 109 | `docs/uji/LAPORAN_CROSS_CHECK_TAHAP6.md` | 4.2 KB | TIDAK | laporan historis Tahap 6; hasilnya sudah dirangkum di PROJECT_STATE |
| 110 | `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` | 434.3 KB | MENDALAM | laporan putaran 2 dibaca penuh (2.641 baris); status tiap temuannya diuji ulang |
| 111 | `docs/uji/PROMPT_REVIEW_INDEPENDEN.md` | 16.2 KB | SEKILAS | versi 3 dibandingkan dengan instruksi sesi ini (grep) |
| 112 | `package-lock.json` | 7.8 KB | TIDAK | berkas kunci paket alat prototipe |
| 113 | `package.json` | 60 B | MENDALAM | 5 baris (@napi-rs/canvas) (W10-01) |
| 114 | `prototipe/01-laporan.html` | 16.9 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 115 | `prototipe/02-kasir.html` | 19.5 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 116 | `prototipe/03-katalog.html` | 19.6 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 117 | `prototipe/04-tema.html` | 46.8 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 118 | `prototipe/README.md` | 7.5 KB | SEKILAS | kepala + tabel isi (klaim font/foto) |
| 119 | `prototipe/alat/gambar.js` | 9.0 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 120 | `prototipe/alat/mockup.js` | 33.5 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 121 | `prototipe/alat/periksa-halaman.py` | 5.0 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 122 | `prototipe/aset/ayam-geprek.jpg` | 77.6 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 123 | `prototipe/aset/banner-kedai.jpg` | 103.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 124 | `prototipe/aset/dessert.jpg` | 63.0 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 125 | `prototipe/aset/es-kelapa.jpg` | 55.3 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 126 | `prototipe/aset/es-teh.jpg` | 59.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 127 | `prototipe/aset/font/LISENSI-ArsenalSC.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 128 | `prototipe/aset/font/LISENSI-BigShoulders.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 129 | `prototipe/aset/font/LISENSI-BricolageGrotesque.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 130 | `prototipe/aset/font/LISENSI-CrimsonPro.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 131 | `prototipe/aset/font/LISENSI-Gloock.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 132 | `prototipe/aset/font/LISENSI-InstrumentSans.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 133 | `prototipe/aset/font/LISENSI-JetBrainsMono.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 134 | `prototipe/aset/font/LISENSI-Lora.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 135 | `prototipe/aset/font/LISENSI-NationalPark.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 136 | `prototipe/aset/font/LISENSI-Outfit.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 137 | `prototipe/aset/font/LISENSI-WorkSans.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 138 | `prototipe/aset/font/LISENSI-YoungSerif.txt` | 4.3 KB | TIDAK | teks lisensi font (OFL); nama diperiksa |
| 139 | `prototipe/aset/font/arsenalsc-reguler.woff2` | 28.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 140 | `prototipe/aset/font/bigshoulders-tebal.woff2` | 19.9 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 141 | `prototipe/aset/font/bricolage-tebal.woff2` | 26.7 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 142 | `prototipe/aset/font/crimson-reguler.woff2` | 20.4 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 143 | `prototipe/aset/font/crimson-tebal.woff2` | 20.9 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 144 | `prototipe/aset/font/gloock.woff2` | 26.6 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 145 | `prototipe/aset/font/instrument-reguler.woff2` | 22.5 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 146 | `prototipe/aset/font/instrument-serif-miring.woff2` | 23.8 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 147 | `prototipe/aset/font/instrument-serif.woff2` | 23.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 148 | `prototipe/aset/font/instrument-tebal.woff2` | 23.0 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 149 | `prototipe/aset/font/lora-tebal.woff2` | 22.5 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 150 | `prototipe/aset/font/mono-reguler.woff2` | 21.3 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 151 | `prototipe/aset/font/nationalpark-tebal.woff2` | 16.9 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 152 | `prototipe/aset/font/outfit-reguler.woff2` | 16.7 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 153 | `prototipe/aset/font/outfit-tebal.woff2` | 16.5 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 154 | `prototipe/aset/font/worksans-miring.woff2` | 32.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 155 | `prototipe/aset/font/worksans-reguler.woff2` | 34.2 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 156 | `prototipe/aset/font/worksans-tebal.woff2` | 36.9 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 157 | `prototipe/aset/font/youngserif-reguler.woff2` | 28.7 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 158 | `prototipe/aset/hero-warung.jpg` | 83.0 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 159 | `prototipe/aset/interior.jpg` | 149.4 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 160 | `prototipe/aset/kopi-susu.jpg` | 74.1 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 161 | `prototipe/aset/mie-ayam.jpg` | 119.6 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 162 | `prototipe/aset/nasi-goreng.jpg` | 110.3 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 163 | `prototipe/aset/pisang-goreng.jpg` | 78.5 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 164 | `prototipe/aset/salad.jpg` | 116.7 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 165 | `prototipe/aset/sate.jpg` | 128.5 KB | TIDAK | biner; hanya nama & ukuran diperiksa |
| 166 | `prototipe/buat-galeri-tema.py` | 16.2 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 167 | `prototipe/buat-palet.py` | 5.5 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 168 | `prototipe/css/tokens.css` | 56.7 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 169 | `prototipe/index.html` | 13.0 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 170 | `prototipe/js/ui.js` | 14.4 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |
| 171 | `prototipe/uji-kontras.py` | 13.9 KB | TIDAK | prototipe tampilan, bukan fondasi; tidak dijalankan |

---

## 6. Temuan per wilayah

Format: **ID · TINGKAT** — lokasi · bukti (perintah → keluaran) · dampak · perbaikan · status. Status: **SUDAH DIPERBAIKI** (di cabang review, belum digabung) · **DIUSULKAN** · **SENGAJA TIDAK DIUBAH** (+alasan). Kolom "267d890" = keadaan di cabang terbaru.

### W1 — Dokumen fondasi (konsistensi, janji ↔ tugas, keputusan pemilik, istilah)

**W1-01 · MAYOR — 19 tugas berisiko tinggi tanpa ⚠️ di judulnya**
- Lokasi: `docs/ROADMAP.md` T1-10 (baris 220), T1-11 (229), T1-14 (256), T2-02 (350), T2-03 (359), T2-04 (368), T2-06 (386), T2-07 (395), T3-02 (462), T3-08 (516), T6-01 (807), T6-02 (816), T6-04 (834), T6-08 (870), T9-03 (1144), T10-10 (1319), T10-11 (1329), T10-12 (1338), T11-03 (1370).
- Bukti: `python3 alat/periksa-fondasi-independen-2.py --akar /tmp/fondasi-review | grep -c "JUDUL tugas tidak memakai"` → `19`. Contoh baris Risiko T9-03: "⚠️ wajib update `DECISIONS_LOG.md` — Area: Kalkulasi Keuangan (ART-3)" tetapi judulnya `T9-03 — Pengaturan operasional (pajak, service, …)` tanpa ⚠️.
- Dampak: aturan gelombang ROADMAP (d) berbunyi "DECISIONS_LOG diperbarui untuk tugas bertanda ⚠️". Agent yang menyaring dari judul (cara paling wajar) melewatkan 19 kewajiban — termasuk pajak/service (uang), login pegawai, RLS lintas cabang, cadangan data pelanggan. Kedua pemeriksa lama tidak menangkap ini karena hanya memeriksa arah ⚠️ → DECISIONS_LOG, bukan sebaliknya. Tiga di antaranya (T10-10…T10-12) justru ditambahkan review putaran 2 dengan cacat yang sama.
- Perbaikan: ⚠️ ditambahkan ke 19 judul; T6-04 kalimat "catatan di DECISIONS_LOG" ditegaskan jadi kewajiban; entri DECISIONS_LOG. Pemeriksa ketiga aturan E menjaga seterusnya.
- Status: **SUDAH DIPERBAIKI**. 267d890: **masih** — 21 tugas (19 + T0-13, T0-14 baru).

**W1-02 · MINOR — Nama status pesanan/item di ROADMAP tidak sama dengan enum TECH_SPEC (tepat di tugas state machine)**
- Lokasi: `docs/ROADMAP.md:292` T1-18 DoD `draf → dikirim → dimasak → siap → dibayar → selesai; dibatalkan` dan Verifikasi `draf → dibayar`; `:628` T4-04 `menunggu → dimasak → siap`. TECH_SPEC §4 baris 173–174 & ART-4 baris 304–306: `draf → dikirim → dimasak → siap → lunas / batal`, item `baru/dimasak/siap/batal`.
- Bukti: pemeriksa ketiga aturan A → 3 GAGAL "rantai status … memakai kata yang TIDAK ada di TECH_SPEC §4 → ['dibayar','selesai'] / ['menunggu']".
- Dampak: migrasi 0018 dan uji SQL bisa ditulis dengan enum yang salah; laporan & dapur (ART-4) memakai kosakata beda dari dokumen terkunci. Temuan W1-02 putaran 2 ternyata **belum** ditutup di `a522db0` walau commit-nya berjudul "9 temuan diperbaiki".
- Perbaikan: T1-18 & T4-04 disamakan; entri DECISIONS_LOG melarang lima kata itu sebagai nama status.
- Status: **SUDAH DIPERBAIKI**. 267d890: T1-18 sudah benar, **T4-04 masih** `menunggu`.

**W1-03 · MINOR — Dua tugas berjudul persis sama**
- Lokasi: `docs/ROADMAP.md:870` T6-08 dan `:1370` T11-03, keduanya "❓ T-002 Uji cetak nyata di Kedai Oasis".
- Bukti: `grep -E '^- \[[ x]\] T' docs/ROADMAP.md | sed 's/^- \[[ x]\] T[0-9-]* — //' | sort | uniq -d` → 1 baris.
- Dampak: laporan kemajuan/DECISIONS_LOG tidak bisa membedakan; agent bisa mencentang yang salah.
- Perbaikan: T11-03 → "Uji cetak nyata ULANG di Kedai Oasis sebelum serah terima (pengulangan T6-08 dengan kode final) ⚠️".
- Status: **SUDAH DIPERBAIKI**. 267d890: masih.

**W1-04 · MINOR — 8 tugas memakai Verifikasi templat "uji SQL + uji manual." (tidak menyebut apa yang diuji)**
- Lokasi: T5-06, T5-11, T7-01, T7-03, T7-04, T7-08, T7-09, T8-13 (termasuk 4 tugas ⚠️ kas/void).
- Bukti: pemeriksa ketiga aturan J → "atribut **Verifikasi** berisi kalimat yang persis sama di 8 tugas".
- Dampak: DoD "uji lulus" tidak bisa dibuktikan; agent bebas menyatakan lulus.
- Perbaikan: 8 Verifikasi ditulis ulang dari DoD masing-masing (mis. T7-04: "`simpan_pesanan` & `bayar_pesanan` di cabang tanpa shift terbuka ditolak dengan kode KS-4xx").
- Status: **SUDAH DIPERBAIKI**. 267d890: masih 8.

**W1-05 · MINOR — Tugas yang tidak bisa selesai di fasenya sendiri**
- Lokasi: `docs/ROADMAP.md:489` T3-05 DoD "menolak di luar shift terbuka" (Fase 3) padahal `buka_shift` dibangun T7-01 (Fase 7) — tabel Peta RPC ROADMAP; `:749` T5-07 Verifikasi "cek kemunculan di laporan (T7-12)".
- Bukti: pemeriksa ketiga aturan O → 2 GAGAL.
- Dampak: gerbang fase ("semua tugas [x] sebelum fase berikutnya") tidak bisa dipenuhi jujur; agent akan mencentang tanpa bukti atau memaksa membangun `buka_shift` lebih awal tanpa rencana.
- Perbaikan: T1-21 seed menambah "1 shift terbuka contoh per cabang (hanya data uji)"; T3-05 & T1-21 diberi baris Catatan; T5-07 Verifikasi tidak lagi bergantung Fase 7.
- Status: **SUDAH DIPERBAIKI**. 267d890: masih keduanya.

**W1-06 · MINOR — Kalimat status yang basi & saling bertentangan tentang cabang/PR**
- Lokasi: `docs/ROADMAP.md:3` "menunggu pemeriksaan silang Tahap 6" (padahal `PROJECT_STATE` sudah `CODING_AKTIF`); `:43` gerbang F0 menyebut base branch `arena/01a0a8a2-resto-barokah` (cabang lama); `docs/AGENT_OPERATING_GUIDE.md:39–40` "Sebelum membuka sesi baru, PR-nya harus di-merge lebih dulu" — bertentangan dengan keputusan pemilik ("JANGAN MERGE PR #1", `PROJECT_STATE.md` 267d890) dan `PANDUAN_PENGGUNA.md` 267d890 baris 266/316 ("pilih base = cabang arena, jangan merge").
- Dampak: agent baru yang patuh pada AOG akan mendesak merge; pemilik yang mengikuti gerbang F0 membuka sesi dari cabang yang salah.
- Perbaikan: ketiga kalimat diperbarui (tanpa mengubah keputusan apa pun).
- Status: **SUDAH DIPERBAIKI**. 267d890: header ROADMAP sudah lain, **AOG §0 masih** → DIUSULKAN di sana.

**W1-07 · MINOR — `docs/README.md` menulis "146 tugas dalam 11 fase"; nyatanya 150 tugas, 12 fase (F0–F11)**
- Bukti: `grep -c '^- \[[ x]\] T' docs/ROADMAP.md` → 150; `grep -c '^## Fase' docs/ROADMAP.md` → 12.
- Status: **SUDAH DIPERBAIKI**. 267d890: sudah benar.

**W1-08 · MINOR — Tenggat T-013 "F7 selesai" tidak dijaga tugas mana pun di F7**
- Lokasi: `docs/TERTANGGUH.md:32`; satu-satunya tugas ❓ T-013 adalah T10-12 (Fase 10).
- Bukti: pemeriksa ketiga aturan M → "hard stop tenggat tidak akan pernah terpicu di fase 7".
- Dampak: aturan "tenggat lewat = hard stop" (TERTANGGUH aturan 4) tidak pernah berbunyi; pertanyaan ke pemilik terlupakan sampai F10.
- Perbaikan: tenggat diubah menjadi "sebelum T10-12 selesai (F10)" dengan catatan alasan (T7-02 memakai nilai sementara "admin cabang/owner" yang sudah aman). Ini perubahan penjadwalan, bukan isi keputusan.
- Status: **SUDAH DIPERBAIKI**. 267d890: tidak lagi muncul (sudah diselaraskan di sana).

**W1-09 · CATATAN — Label area T1-13 "Audit (ART-6)" tidak cocok** — TECH_SPEC §9 ART-6 = "Kas & shift"; tidak ada ART untuk jejak audit. Usul: "Area: Jejak audit — mendukung ART-2 & ART-6", atau (perubahan dokumen terkunci) tambah ART khusus audit seperti yang dilakukan 267d890 (ART-13 "Jejak audit berantai"). Status: **DIUSULKAN** (pemeriksa ketiga memberi PERINGATAN, tidak menggagalkan).

**W1-10 · CATATAN — PRD menjanjikan PIN pelanggan, TECH_SPEC tidak punya tempatnya** — `docs/PRD.md` M10 & §7 langkah 17 ("pelanggan membuat PIN", "lupa PIN") vs `docs/TECH_SPEC.md` §4.4 tabel `pelanggan` (tanpa kolom PIN) & §5 (tanpa RPC). Kedua dokumen terkunci → butir **T-023** + ❓ di T2-05. Status: **DIUSULKAN (keputusan pemilik)**.

**W1-11 · CATATAN — Pemetaan kelengkapan Tahap 5 longgar** — baris "Semua fitur Must Have M1–M12 punya task: … M12 → T1-01…T1-22 …" memetakan 40 tugas yang Ref-nya tidak menyebut fitur itu (M12 → 24 tugas, M4 → 8). Bukti: pemeriksa ketiga aturan H (PERINGATAN). Dampak kecil: klaim "semua fitur punya tugas" benar secara hasil, tetapi peta ini tidak bisa dipakai menelusuri balik. Status: **DIUSULKAN**.

**W1-12 · CATATAN — `aplikasi/alat/uji-kontras.py` (T0-04, T11-05) vs TECH_SPEC §3 yang hanya mengenal `/alat` di akar** — di 267d890 folder `aplikasi/alat/` sudah nyata berisi 5 skrip, jadi TECH_SPEC §3-lah yang perlu disesuaikan (dokumen terkunci → usul). Status: **DIUSULKAN**.

**W1-13 · CATATAN — Angka kecil yang tidak sinkron** — T1-05 DoD mendaftar 8 izin, Verifikasi "menolak 7 tindakan"; T1-06 & T2-09 memakai "mis. 5×/15 menit" di DoD (nilai contoh, bukan nilai yang dikunci); DECISIONS_LOG entri 2026-09-16 menyebut "26 RPC" (TECH_SPEC §5 = 33) — **SENGAJA TIDAK DIUBAH** karena log bersifat tambah-saja (nilai historis), cukup dicatat di sini.

### W2 — Klaim kuantitatif vs bukti → lihat bagian 7.

### W3 — Pemeriksa lama & pemeriksa baru

**Hasil pemeriksa lama pada `a522db0`:** `validate_system.py` PASS (0) · `periksa-roadmap.py` LOLOS (0), "150 tugas", "121 tugas bertanda" · `periksa-fondasi-independen.py` BERSIH (0): 67 tugas ⚠️, 31 entitas, 33 RPC, tertangguh 6 terbuka/8 selesai.

**W3-01 · MINOR — Label "121 tugas bertanda" di `periksa-roadmap.py` menghitung kemunculan lambang, bukan tugas** (baris 132: `teks.count("⚠️")`). Setelah perbaikan saya angkanya jadi "144" padahal tugas dengan ⚠️ di judul = 67 (sebelumnya 48) dan blok ber-⚠️ = 67 (sebelumnya 66). Status: **SENGAJA TIDAK DIUBAH** di `a522db0` (tidak boleh mengubah pemeriksa lama; sudah diperbaiki di 267d890: "dihitung per blok tugas").

**W3-02 · MINOR — Tidak ada pemeriksa yang menjaga isi DECISIONS_LOG (uji penerimaan AT-07)**
- Bukti: di salinan `a522db0`, `head -3 docs/DECISIONS_LOG.md > tmp && mv tmp docs/DECISIONS_LOG.md` lalu jalankan ketiga pemeriksa → `PASS` / `LOLOS` / `BERSIH` semuanya. Aturan 9 pemeriksa putaran 2 hanya memeriksa `keputusan.strip()` tidak kosong.
- Perbaikan: pemeriksa ketiga aturan Q — tugas ⚠️ yang sudah `[x]` wajib disebut ID-nya di DECISIONS_LOG (rentang "T1-01…T1-04" dihitung). Diuji pada 267d890: 8 tugas ⚠️ selesai, 0 tanpa jejak; DECISIONS_LOG 267d890 dikosongkan → 8 GAGAL.
- Status: **SUDAH DIPERBAIKI (penguat baru)**.

**W3-03 · CATATAN — Celah lain pemeriksa lama yang ditutup pemeriksa ketiga:** kosakata status (A), variabel §6 tanpa tugas (B), folder `src/` vs §3 (C), nomor migrasi ganda (D), ⚠️ judul (E), label ART (F), tanda ART di judul fase (G), peta M→tugas (H), tabel/ART/fitur dari dokumen sumber (I), isi kembar (J), rujukan bernomor & berkas (K), tugas di bawah judul fase yang salah (L), tenggat ↔ fase (M), angka dokumen vs disk (N), ketergantungan maju (O), `PROJECT_STATE` (P), jejak DECISIONS_LOG (Q).

**Pemeriksa ketiga — `alat/periksa-fondasi-independen-2.py`** (satu perintah, exit 0/1, hanya pustaka standar). Mengapa bukan menimpa `alat/periksa-fondasi-independen.py`: berkas itu sudah ada (review putaran 2) dan dipanggil CI 267d890 — menimpanya = menghapus pemeriksa (dilarang). Sumber data yang dipakai berbeda dari kedua pemeriksa lama: enum status TECH_SPEC §4/§9, tabel env §6, pohon folder §3, judul ART §9, judul `### Mn.` PRD, jumlah aturan PRD §8 & risiko §9, tabel Peta RPC, baris checklist Tahap 5, `skills/` di disk, `PROJECT_STATE.md` + tabel status `AGENT_SYSTEM.md`, DECISIONS_LOG.

Hasil jalannya (ringkas; keluaran penuh dengan `--akar`):

| Pohon | GAGAL | PERINGATAN | Rincian GAGAL |
|---|---|---|---|
| `a522db0` | **31** | 10 | 19 ⚠️ judul · 3 rantai status · 3 variabel §6 tanpa tugas (`SUPABASE_SERVICE_ROLE_KEY`, `CLOUDFLARE_API_TOKEN`, `DENYUT_URL`) · judul kembar · 8 Verifikasi kembar · T3-05 shift · T5-07 maju · T-013 tenggat · README 146 |
| `267d890` | **37** | 17 | 21 ⚠️ judul · **nomor migrasi ganda 0011 (T1-23/T1-37), 0015 (T1-27 `0015_audit.sql` vs T1-45 `0015_penutup_celah_putaran16.sql` yang sudah ada di disk), 0066 (T10-11/T10-13)** · folder `src/uji`, `src/bahasa`, `src/kontrak` tidak ada di TECH_SPEC §3 · T4-04 status · 2 variabel §6 · judul kembar · 8 Verifikasi kembar · T3-05 · T5-07 · `STATUS: CODING_DIJEDA_SADAR` tidak dikenal `AGENT_SYSTEM.md` |
| `a522db0 + perbaikan` | **0** | 10 | — (PERINGATAN yang tersisa = usulan W1-09, W1-11, W1-12) |

Uji mutasi `--uji-diri` (7 mutasi: ⚠️ dihapus, migrasi ganda, status tak resmi, tugas di bawah fase salah, variabel §6 hilang, klaim jumlah salah, DoD bergantung fase lebih lambat) → **7/7 tertangkap**.

### W4 — Uji tangan tugas

Cara mengacak: `random.Random("a522db0-2026-09-19").sample(<semua ID selain T0-*>, 15)` (benih = commit + tanggal, bisa diulang). Fase 0 diuji seluruhnya (10 tugas) terpisah.

| Tugas | 7 atribut | Ref ada | Temuan |
|---|---|---|---|
| T1-03 | ✓ | §4, §9 ART-1/2 ✓ | 0 temuan |
| T1-05 | ✓ | ✓ | DoD 8 izin vs Verifikasi "7 tindakan" (W1-13) |
| T1-06 | ✓ | ✓ | "mis. 5×/15 menit" — nilai contoh di DoD (W1-13) |
| T1-21 | ✓ | ✓ | seed tidak punya shift terbuka yang dibutuhkan T3-05 (W1-05) → diperbaiki |
| T2-01 | ✓ | §1, §7 ✓ | 0 temuan (rujukan maju hanya di Risiko) |
| T3-03 | ✓ | ✓ | Verifikasi "catatan sampai ke layar dapur" membutuhkan layar dapur Fase 4 — ketergantungan konsep maju, tidak tertangkap pemeriksa (hanya ID). CATATAN |
| T3-06 | ✓ | ✓ | enum meja cocok TECH_SPEC (kosong/terisi/siap). 0 temuan |
| T3-12 | ✓ | ✓ | Verifikasi "300 pesanan contoh (seed)" tetapi seed T1-21 hanya 20 menu, tanpa 300 pesanan. CATATAN |
| T5-10 | ✓ | ✓ | "cetak ulang struk" di Fase 5 sebelum modul cetak Fase 6 — hanya masuk akal untuk struk digital; tidak ditulis. CATATAN |
| T7-02 | ✓ | ✓ | 0 temuan (5 kasus uji jelas) |
| T8-03 | ✓ | ✓ | "< 3 detik di jaringan seluler" tanpa cara ukur baku. CATATAN |
| T8-10 | ✓ | ✓ | pemindai barcode butuh pustaka/`BarcodeDetector` (tidak ada di iPhone) — jalur manual sudah wajib. 0 temuan |
| T11-01 | ✓ | §11, AOG §5 ✓ | Playwright di CI setiap push → menit CI repo privat (W5-02) |
| T11-02 | ✓ | ✓ | 0 temuan |
| T11-07 | ✓ | ✓ | `CLOUDFLARE_API_TOKEN` (siapa memasang) tidak disebut → diperbaiki |

Fase 0 (T0-01…T0-10), semuanya 7 atribut lengkap & Ref sah:

| Tugas | Temuan |
|---|---|
| T0-01 | tidak ada versi Node (`grep -rn "nvmrc\|engines\|Node 2" docs/` → kosong) → **diperbaiki**: Node 22 LTS (sama dengan CI 267d890) |
| T0-02 | 0 temuan |
| T0-03 | Verifikasi memakai alat yang baru dibuat T0-04 (urutan terbalik, satu fase) — CATATAN |
| T0-04 | `aplikasi/alat/` vs §3 (W1-12) |
| T0-05 | root `.gitignore` `.env.*` mengabaikan `.env.example` (`git check-ignore -v aplikasi/.env.example` → `.gitignore:10:.env.*`) → **diperbaiki** `!.env.example` (267d890 sudah); daftar variabel + siapa memasang → **diperbaiki** |
| T0-06 | 0 temuan |
| T0-07 | "repo publik" salah → **W5-02** |
| T0-08 | tidak ada langkah "buat akun/proyek" oleh pemilik → **W5-01**; mitigasi merujuk T10-08 (denyut) yang baru ada di Fase 10 → **W5-03** |
| T0-09 | 0 temuan (T-008 alamat `*.workers.dev` sudah diputuskan) |
| T0-10 | 0 temuan; catatan: DoD hanya menyebut `periksa-roadmap.py`, dua pemeriksa lain belum wajib dijalankan CI — DIUSULKAN tambah ketiganya |

### W5 — Kesiapan Fase 0

**W5-01 · MINOR — Tidak ada tugas/langkah "pemilik membuat akun" untuk 4 layanan** (Supabase, Cloudflare, Google Cloud OAuth, penyedia email). T0-08 langsung "Proyek Supabase dibuat". `grep -n -i "google cloud\|oauth\|client id" docs/ROADMAP.md` → kosong. Dampak: agent berhenti di tengah fase tanpa tahu harus minta apa; pemilik non-teknis tidak diberi langkah. Perbaikan: baris Catatan prasyarat di T0-08 (menunjuk Stop Condition §12.7) + T0-05 menyebut siapa memasang tiap kunci. **SUDAH DIPERBAIKI** (267d890: DECISIONS_LOG "Fase 1 dimulai lebih dulu tanpa akun Supabase" menunjukkan masalah ini memang terjadi).

**W5-02 · MAYOR — T0-07 berasumsi "repo publik → Actions gratis tanpa batas"; repo nyatanya PRIVAT**
- Bukti: `gh repo view --json isPrivate` → `true`. Sumber GitHub: privat paket Free = 2.000 menit/bulan + 500 MB artefak; batas belanja $0 → workflow berhenti (tidak menagih).
- Dampak: dengan T11-01 (Playwright setiap push) + uji SQL 41 kasus setiap push, 2.000 menit bisa habis pertengahan bulan → CI mati → gerbang "CI hijau" tidak bisa dipenuhi. Di 267d890 Risiko T0-07 masih menulis "repo publik" padahal kolom Bukti-nya sendiri menyebut "repo privat 2.000 menit/bulan".
- Perbaikan: teks T0-07 + strategi hemat menit (concurrency/cancel-in-progress, cache, uji berat hanya di PR/jadwal malam, laporan pemakaian per batch). Tidak mengusulkan langkah berbayar; membuat repo publik = keputusan pemilik (tidak saya usulkan karena ada data desain & catatan pribadi).
- Status: **SUDAH DIPERBAIKI (teks)**. 267d890: **masih** kalimat "repo publik".

**W5-03 · MAYOR? → dinilai MINOR — Penjaga "basis data gratis tidak tidur saat libur panjang" dirancang di tempat yang salah dan terlalu terlambat**
- Lokasi: `docs/ROADMAP.md:1301` T10-08 `0058_pg_cron.sql` + `alat/denyut.py`; TECH_SPEC §10 "denyut harian (pg_cron)".
- Bukti: docs resmi Supabase: proyek Free dijeda setelah 7 hari tanpa aktivitas; diskusi #13121: pg_cron berjalan **di dalam** proyek yang dijeda → tidak bisa membangunkan dirinya. Bukti lapangan: `git grep -n "DIJEDA" 267d890 -- .github/` → `ci.yml:75 "sedang DIJEDA karena lama tidak dipakai"`. Uji khusus instruksi: "adakah tugas menjaga DB gratis tak tertidur?" → ada (T10-08) tetapi baru Fase 10, sementara proyek dibuat Fase 0.
- Dampak: kasir Kedai Oasis buka setelah libur Lebaran → aplikasi tidak bisa masuk sampai pemilik menekan "Restore" di panel (butuh beberapa menit, hanya pemilik yang bisa). Bukan kehilangan data; kehilangan waktu jualan.
- Perbaikan: T10-08 ditulis ulang (pemicu dari luar: Cloudflare Cron gratis atau jadwal GitHub Actions memanggil `DENYUT_URL`; pg_cron hanya pembersih; peringatan bila denyut gagal 2 hari); T0-08 Catatan: pasang ping ≤3 hari sejak proyek dibuat + tulis cara membangunkan di README. Tingkat saya turunkan ke MINOR karena tidak ada data hilang dan perbaikannya teks.
- Status: **SUDAH DIPERBAIKI**. 267d890: `alat/denyut.py` dirujuk tetapi tidak ada (ditemukan pemeriksa mereka sendiri); mekanisme belum diubah.

**W5-04 · CATATAN — Urutan commit Fase 0 & gerbang:** gerbang F0 mensyaratkan review independen selesai & temuan ditangani — putaran 2 & 3 sudah ada; 267d890 sudah menjalankan Fase 0 (CI Node 22, 3 workflow, 15 migrasi, 41 uji SQL). Paket: React 19 + Vite + TS ditulis di TECH_SPEC tanpa versi minor (wajar). Deploy: T0-09 (`*.workers.dev`) & T11-07 (produksi) terpisah jelas. Rahasia: T0-05 + `.gitignore` (setelah `!.env.example`). Tidak ada temuan lain.

### W6 — Sistem kerja agent (`_sistem/`, berkas akar)

**W6-01 · MINOR — `validate_system.py` tidak memeriksa `PROJECT_STATE.md` sama sekali**
- Bukti: salinan lengkap `a522db0` (`/tmp/uji-vs`), `rm PROJECT_STATE.md && python3 _sistem/validate_system.py` → `PASS`, exit 0. Sebaliknya `rm docs/TERTANGGUH.md` → GAGAL (tertangkap lewat rujukan backtick di `STATUS.md`), jadi perlindungan `PROJECT_STATE` hanya kebetulan tidak ada.
- Dampak: berkas yang menentukan arah setiap sesi bisa hilang/rusak tanpa alarm. Perbaikan: pemeriksa ketiga aturan P (wajib ada bila ROADMAP ada; nilai `STATUS:` harus dikenal tabel `AGENT_SYSTEM.md`). Usul untuk `validate_system.py` (kit, tidak saya ubah): cek bersyarat yang sama.
- Status: **SUDAH DIPERBAIKI (penguat baru)** + **DIUSULKAN** untuk kit.

**W6-02 · MINOR — `_Notes.md` ada di repo aplikasi padahal uji penerimaan AT-08 mensyaratkan `rm _Notes.md`, dan isinya data pribadi pemilik** (nama akun + tautan chat Claude). Bukti: `git ls-tree 267d890 _Notes.md` → masih ada; `ACCEPTANCE_TESTS.md:44` langkah "`rm _Notes.md`". Dampak: kecil selama repo privat; menjadi kebocoran bila repo dipublikkan (lihat W5-02). Perbaikan: pemilik/sesi pembangun menghapus berkas (saya dilarang menghapus berkas). Status: **DIUSULKAN**.

**W6-03 · CATATAN — Uji penerimaan yang dijalankan:** AT-08 (salinan standalone tanpa `tools/`/`_meta/`: validator PASS, 56 folder skills = klaim) ✓ · AT-09 mutasi "hapus penanda arsip di kepala `PANDUAN_PEMAKAIAN.md`" → GAGAL tertangkap ✓; mutasi "klaim 57 folder skills" → GAGAL tertangkap ✓ · AT-07 (DECISIONS_LOG dijaga) → **tidak dijaga** oleh pemeriksa mana pun (W3-02). `_sistem/templates/*` (10 berkas) **TIDAK DIPERIKSA** (waktu; hanya dipakai `check_template_roadmap_7_atribut`). `_sistem/AUDIT_*.md` = arsip bertanggal, SEKILAS, tidak memengaruhi fondasi.

**W6-04 · CATATAN — Dua buku aturan (kit `AGENT_SYSTEM.md` vs proyek `AGENT_OPERATING_GUIDE.md`)** memberi arahan berbeda soal merge PR (W1-06) dan tabel status (W7-01). Usul: satu kalimat di `START_DI_SINI.md` yang menyatakan mana yang menang bila bertentangan (AOG untuk proyek ini). **DIUSULKAN**.

### W7 — Simulasi agent baru "bodoh" + `mulai-sesi.py`

**W7-01 · MINOR — Nilai status `CODING_DIJEDA_SADAR` (dipakai 3 cabang turunan) tidak ada di tabel status `AGENT_SYSTEM.md`**
- Bukti: `git show 267d890:AGENT_SYSTEM.md | grep -c CODING_DIJEDA_SADAR` → `0`; `AGENT_SYSTEM.md:106` "STATUS: [salah satu nilai yang valid — lihat tabel di atas]" (nilai valid: `FONDASI_TAHAP_1…6`, `CODING_AKTIF`, `SIKLUS_BARU`). Pemeriksa ketiga aturan P menggagalkan 267d890 karena ini.
- Dampak: agent baru yang patuh tidak punya prosedur untuk status itu → menebak atau bertanya; instruksi review ini pun tersesat karena hanya mencari `CODING_AKTIF` (bagian 12).
- Perbaikan: tambah baris tabel di `AGENT_SYSTEM.md` ("`CODING_DIJEDA_SADAR` → baca `PROJECT_STATE.md` DETAIL, jangan lanjut coding sebelum syarat jeda dipenuhi") — berkas kit, **DIUSULKAN**.

**W7-02 · MINOR — Di `a522db0`, `mulai-sesi.py` memetakan status yang tidak dikenal ke 1 skill saja (tanpa peringatan)**
- Bukti: salinan lengkap, `sed -i 's/^STATUS:.*/STATUS: CODING_DIJEDA_SADAR/' PROJECT_STATE.md && python3 alat/mulai-sesi.py` → "SKILL WAJIB … → Jumlah: 1 berkas siap dibaca" (vs 15 untuk `CODING_AKTIF`), tidak ada kalimat "status tidak dikenal".
- Status: **SUDAH DIPERBAIKI di 267d890** (`mulai-sesi.py:119` mencatat temuan ini dan menambah uji); di `a522db0` **DIUSULKAN** (tidak saya ubah — berkas alat yang sudah diperbaiki di hilir; mengubahnya di sini hanya menambah konflik).

**W7-03 · CATATAN — `mulai-sesi.py` tidak mendeteksi kegagalan git:** KARTU SESI berisi "Branch aktif: fatal: not a git repository" dan "Working tree: KOTOR — 1 berkas" saat dijalankan di folder non-git. Usul: bila `git` gagal, tulis "TIDAK DIKETAHUI (git gagal)" dan exit ≠ 0 supaya agent tidak menyalin pesan error ke laporan pemilik. **DIUSULKAN**.

**W7-04 · Cocok:** DAFTAR TUNGGU `mulai-sesi.py` = baris terbuka `docs/TERTANGGUH.md` (6 = 6 di `a522db0`; 8 = 8 setelah T-022/T-023 ditambahkan — diuji di `/tmp/fondasi-perbaikan`).

**Tiga kelemahan konkret dari sudut agent baru** (rinci di bagian 8): (1) prompt pembuka "tidak ada `PROJECT_STATE.md` → proyek baru Tahap 1" + base `main` yang kosong → agent memulai Discovery dari nol, padahal fondasi ada di cabang lain (belum tertutup di kit; PANDUAN_PENGGUNA 267d890 sudah memperingatkan di sisi pemilik); (2) status asing (W7-01, belum tertutup); (3) 19 tugas ⚠️ tanpa tanda di judul (W1-01, tertutup di cabang review).

### W8 — Ikuti `PANDUAN_PENGGUNA.md` sebagai pemilik non-teknis

**W8-01 · MINOR — Prompt Penutup langkah 2 menyebut `STATUS.md` "di folder `sistem-building-aplikasi/`"** — folder itu tidak ada di repo mandiri ini (`ls sistem-building-aplikasi` → tidak ada; `STATUS.md` ada di akar). Pemilik yang menyalin prompt itu membuat agent mencari berkas yang salah. **DIUSULKAN** (berkas ini berbeda +710 baris di 267d890; perbaikan di sana).

**W8-02 · MINOR — Jebakan sesi baru:** prompt pembuka meminta agent mengecek `PROJECT_STATE.md`; di `main` tidak ada → "proyek baru". Di `a522db0` PANDUAN_PENGGUNA belum menjelaskan bahwa pekerjaan hidup di cabang `arena/*` dan base branch harus dipilih. **SUDAH DITUTUP di 267d890** (baris 266/269/316) — di `a522db0` DIUSULKAN; AOG §0 (sisi agent) saya perbaiki.

**W8-03 · CATATAN — Tidak ada daftar "akun yang harus kamu buat" untuk pemilik** (Supabase, Cloudflare, Google Cloud, email) dalam bahasa awam, padahal tanpa itu Fase 0/2 berhenti (W5-01). **DIUSULKAN** untuk PANDUAN_PENGGUNA; sisi ROADMAP sudah ditambah.

**W8-04 · Terverifikasi baik:** `PANDUAN_PEMAKAIAN.md` jelas berpenanda arsip ("⚠️ VERSI LAMA — SUDAH DIGANTIKAN, JANGAN DIIKUTI" baris 1) dan validator memaksanya (uji mutasi W6-03). `PROMPT_ENTRI_UNIVERSAL.md` konsisten dengan `START_DI_SINI.md`.

**W8-05 · CATATAN — Laporan review putaran 2 berukuran 444 KB / 2.641 baris** (`git ls-tree -r -l a522db0 | grep LAPORAN_REVIEW` → 444.762 byte): terlalu panjang untuk dibaca pemilik non-teknis; ringkasan 5 barisnya benar, tetapi butir yang butuh keputusan tenggelam. Laporan ini sengaja lebih pendek.

### W9 — Operasional Kedai Oasis, skenario gagal, biaya nol, data & keamanan

**W9-01 · MAYOR — Keputusan T-007 "email lewat Resend tanpa domain khusus" tidak bisa dijalankan; email ke pelanggan tidak akan terkirim**
- Lokasi: `docs/TERTANGGUH.md` T-007 (selesai, "Mulai tanpa domain khusus (kirim lewat Resend)"); `docs/TECH_SPEC.md` §1 & §10 (email 3.000–9.000/bulan, tanpa syarat domain, tanpa batas harian); ROADMAP T2-04, T2-05, T8-07.
- Bukti: dokumen resmi Resend (Errors, 403 `validation_error`): "You can only send testing emails to your own email address … To send emails to other recipients, please verify a domain." Paket gratis juga dibatasi **100 email/hari** (pengiriman berhenti saat cap). `git grep -n -i "own email\|verifikasi domain" 267d890 -- docs/` → hanya `DISKUSI_TEKNIS_TAHAP3.md:32` "Butuh memverifikasi domain sendiri" — disadari saat diskusi, hilang saat keputusan.
- Dampak: jalur kedua pendaftaran pelanggan (email terverifikasi), pemulihan akses, dan verifikasi anti-kecurangan voucher **gagal total** untuk semua pelanggan, bukan "masuk spam". Google Sign-In tidak terpengaruh.
- Perbaikan yang diusulkan (semua gratis): (a) SMTP Gmail milik pemilik lewat sandi aplikasi (±500 email/hari) — rekomendasi untuk pilot; (b) Brevo gratis 300/hari dengan pengirim terverifikasi; (c) hanya Google + pendaftaran oleh kasir (mengubah PRD M10). Dicatat sebagai **T-022** (tenggat: sebelum T2-04 dimulai), ❓ di T2-05 & T8-07, Catatan di T2-04, entri DECISIONS_LOG **MENUNGGU PERSETUJUAN PEMILIK**. Usulan TECH_SPEC §10 (terkunci): tambah "email: butuh domain terverifikasi untuk Resend; cap harian 100".
- Status: **DIUSULKAN — menunggu pemilik**. 267d890: belum disadari (T-007 tetap selesai).

**W9-02 · Skenario gagal sehari penuh (Sabtu malam penuh, 2 kasir, dapur 1 layar):**

| Skenario | Tertutup oleh | Status |
|---|---|---|
| Internet putus saat 10 pesanan antre | K4 + T3-05 kunci idempoten + T10-01…T10-04 antrean offline + T10-09 | tertutup di rencana; belum ada uji "putus 30 menit lalu 2 kasir kirim ulang bersamaan" — DIUSULKAN tambah ke T11-01 |
| Listrik mati (tablet mati, router mati) | T10-09 pemulihan mendadak | tertutup |
| Printer rusak/habis kertas | T6-05 cadangan digital wajib, T6-07 status printer | tertutup |
| Batal setelah dimasak | T5-07 PIN atasan + `pembatalan` (K3) | tertutup; Verifikasi diperbaiki (W1-05) |
| Kas tidak cocok saat tutup | T7-02 selisih wajib alasan, urutan hitung uang §13 | tertutup |
| Voucher diklaim berulang | T8-07/T8-08/T8-13 (10 pengaman) | tertutup **kecuali** jalur email (W9-01) |
| Pegawai berhenti mendadak di tengah shift | T10-12 + T-013 (nilai sementara aman) | tertutup |
| 2 orang ubah pengaturan bersamaan | T10-11 (penolakan di peladen) | tertutup |
| Basis data tertidur setelah libur panjang | T10-08 | **belum** memadai di `a522db0` → diperbaiki (W5-03) |
| Jatah CI habis di tengah bulan | — | **belum** → diperbaiki teks T0-07 (W5-02) |

**W9-03 · Biaya nol — klaim TECH_SPEC §10 vs sumber resmi:** Supabase (500 MB DB, 1 GB storage, 5 GB egress, tidur 7 hari, cadangan tak bisa diunduh di Free) **TERBUKTI** · Cloudflare (100k permintaan/hari, aset statis tak dihitung) **TERBUKTI**, tambahan: 5 Cron Trigger gratis (cukup untuk denyut) · Email 3.000/bulan **TERBUKTI** tetapi syarat domain & cap 100/hari **TIDAK TERCANTUM** (W9-01) · GitHub Actions "gratis untuk repo publik" **TIDAK BERLAKU** (repo privat, W5-02). Tidak ada langkah berbayar yang diusulkan.

**W9-04 · Data & keamanan (dibaca, 0 temuan baru):** uang integer rupiah & rumus di peladen (ART-3), RLS per penyewa/cabang (ART-1), PIN di-hash + batas percobaan (T1-06), cadangan mingguan via `pg_dump` di GitHub Actions (T10-10; lokasi simpan = T-012 terbuka), kebijakan privasi sebelum data pelanggan (T-011). Tiga hal tersulit yang dicoba: (1) mencari jalur klien menghitung uang → TECH_SPEC §9 + T3-02 melarang & ada uji otomatis; (2) mencari data pelanggan yang keluar ke layanan ketiga tanpa persetujuan → hanya email verifikasi (tergantung T-022) dan Google; (3) mencari tempat kunci `service_role` bisa bocor ke klien → T0-05 Verifikasi `grep service_role aplikasi/src` + `.gitignore`.

### W10 — Integritas repo

- `git ls-tree -r --name-only a522db0 | wc -l` → **1.973** (1.802 `skills/`, 171 lainnya). Blob: `skills/` 21,8 MB, lainnya 11,5 MB.
- 10 berkas terbesar: `skills/ios-agent/docs/apple/technologies.json` 3,5 MB; `docs/desain/papan-referensi-pemilik.jpg` 1,1 MB; 5 mockup PNG 0,6–0,75 MB; `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` 445 KB. Tidak ada yang > 5 MB; tidak perlu Git LFS.
- Pola rahasia (JWT `eyJ…`, `sk_live_`, `re_…`, `AKIA…`, `ghp_…`, `PRIVATE KEY`) di semua berkas teks non-skills: **0 temuan** (hanya jumlah yang dicetak, isi tidak ditampilkan). Nama berkas mencurigakan (`.env`, `.pem`, `.log`, `.tmp`, `.DS_Store`, `node_modules/`): **0** (cocokan `tokens.css`/`secrets-store/*.md` adalah nama biasa).
- **W10-01 · CATATAN — `package.json` + `package-lock.json` di akar** hanya berisi `@napi-rs/canvas` untuk `prototipe/alat/gambar.js` (pembuat papan mockup). Tidak berbahaya, tetapi TECH_SPEC §3 menempatkan aplikasi di `/aplikasi` — akar seharusnya bersih dari paket alat prototipe. **DIUSULKAN** pindah ke `prototipe/` (bukan temuan penghalang).
- **W10-02 · MINOR — `_Notes.md`** (lihat W6-02).
- `.gitignore`: 26 baris, memuat `.env`, `.env.*`, `*.local`, build/cache; cacat `.env.example` (W4/T0-05) diperbaiki.
- `skills/`: satu baris kebijakan di bagian 5.

---

## 7. Klaim kuantitatif vs bukti (W2)

| Klaim (lokasi) | Perintah | Hasil | Status |
|---|---|---|---|
| ROADMAP 150 tugas, 12 fase | `grep -c '^- \[[ x]\] T'` / `grep -c '^## Fase'` | 150 / 12 | TERBUKTI |
| docs/README "146 tugas dalam 11 fase" | sama | 150 / 12 | **TIDAK TERBUKTI** → diperbaiki |
| Tiap tugas 7 atribut | pemeriksa lama + baru (parse berbeda) | 150/150 | TERBUKTI |
| "121 tugas bertanda" (periksa-roadmap) | `grep -c '^- \[[ x]\] T.*⚠️'` (judul) · pemeriksa putaran 2 (blok) | 48 judul / 66 blok (67 / 67 setelah perbaikan) — 121 = jumlah lambang ⚠️ | **TIDAK TERBUKTI** sebagai jumlah tugas (label salah) |
| TECH_SPEC 31 tabel, 33 RPC | regex tabel §4 / `rpc/` §5 | 31 / 33 | TERBUKTI |
| DECISIONS_LOG "26 RPC" | idem | 33 | TIDAK TERBUKTI (historis, sengaja dibiarkan) |
| M1–M12 semua punya tugas | Ref tugas (pemeriksa baru aturan I) | 12/12 | TERBUKTI |
| ART-1…10 semua punya tugas ⚠️ | aturan I | 10/10 | TERBUKTI |
| TERTANGGUH 6 terbuka + 8 selesai | parse tabel | 6 + 8 | TERBUKTI |
| 13 aturan bisnis PRD §8, 6 peran M3 | `grep -c '^[0-9]*\. ' §8` / baca | 13 / 6 | TERBUKTI |
| `skills/` 56 folder, 87 SKILL.md, ±26 MB | `find`/`rglob`/`du` | 56 / 87 / 21,8 MB blob (26 MB di disk termasuk metadata) | TERBUKTI |
| Berkas terlacak 1.972 (STATUS.md) | `git ls-tree -r a522db0 \| wc -l` | 1.973 | selisih 1 (LAPORAN putaran 2 ditambahkan setelah angka ditulis) — TERBUKTI mendekati |
| uji-kontras 166/0, periksa-halaman 183/183, 10 tema, "19 woff2 (13 keluarga)" (prototipe/README), "13 berkas woff2" (RENCANA_DESAIN_UI), 13 foto | `ls prototipe/aset/font/*.woff2 \| wc -l` → 19; `ls prototipe/aset/*.jpg \| wc -l` → 13; prototipe tidak dijalankan | 19 woff2 / 13 foto | README TERBUKTI; RENCANA_DESAIN_UI "13 berkas" TIDAK TERBUKTI (draf lama, tidak diubah); hasil uji kontras/halaman **TIDAK BISA DIVERIFIKASI** tanpa menjalankan prototipe |
| Batas gratis §10 (lihat W9-03) | sumber resmi | — | Supabase & Cloudflare TERBUKTI; email & CI TIDAK LENGKAP/TIDAK BERLAKU |
| Migrasi 0001–0059 unik | aturan D | 59 unik, tanpa lompatan | TERBUKTI (`a522db0`); **TIDAK TERBUKTI di 267d890** (3 nomor ganda) |
| Nomor Node/versi paket | `grep nvmrc\|engines` | kosong | TIDAK TERBUKTI (tidak ada) → diperbaiki |

---

## 8. Tiga sudut pandang

**A. Agent baru "bodoh" (membaca literal, tidak menebak)**
1. Dibuka dari `main` dengan prompt pembuka → tidak ada `PROJECT_STATE.md` → memulai Discovery dari nol. **Belum tertutup** di kit (`PROMPT_ENTRI_UNIVERSAL.md`, `START_DI_SINI.md`); tertutup sebagian di PANDUAN_PENGGUNA 267d890 (sisi pemilik).
2. Menemukan `STATUS: CODING_DIJEDA_SADAR` → tabel `AGENT_SYSTEM.md` tidak punya barisnya → tidak tahu harus apa. **Belum tertutup** (W7-01).
3. Mengerjakan T9-03 (pajak) → judul tanpa ⚠️ → tidak menulis DECISIONS_LOG → gerbang fase tetap lolos karena tidak ada pemeriksa yang menagih. **Tertutup** di cabang review (W1-01 + aturan Q).
4. Menulis migrasi 0018 memakai status `dibayar` seperti tertulis di T1-18 → beda dari TECH_SPEC. **Tertutup** (W1-02).

**B. Pemilik non-teknis**
1. Diminta agent "buat proyek Supabase/Cloudflare/Google" tanpa daftar langkah → berhenti. **Tertutup sebagian** (ROADMAP T0-08 Catatan; PANDUAN_PENGGUNA masih perlu daftar — W8-03).
2. Membaca AOG "PR harus di-merge dulu" vs pesan agent "jangan merge PR #1" → bingung, mungkin menekan Merge. **Tertutup** (W1-06).
3. Menyalin Prompt Penutup dengan path `sistem-building-aplikasi/STATUS.md` yang tidak ada. **Belum tertutup** (W8-01).
4. Setelah libur 10 hari membuka aplikasi → "tidak bisa terhubung" → tidak tahu harus menekan Restore di panel Supabase. **Tertutup di rencana** (W5-03: README + denyut luar), belum di kode.

**C. Kedai Oasis, Sabtu malam penuh**
1. Pelanggan mendaftar voucher lewat email → email verifikasi tidak pernah datang (W9-01). **Belum tertutup — butuh keputusan pemilik.**
2. Dua kasir, internet putus 20 menit, 30 pesanan → kirim ulang bersamaan; kunci idempoten (T3-05) menahan dobel, tetapi belum ada uji khusus dua kasir bersamaan. **Tertutup di rancangan, belum di uji** (usul tambah kasus ke T11-01).
3. Void setelah dimasak butuh PIN atasan; atasan sedang tidak di tempat → pesanan menggantung. PRD/ROADMAP tidak menyebut jalur "tunda void, catat dulu". **Belum tertutup** (CATATAN; keputusan alur pesanan milik pemilik → tidak saya ubah).
4. Printer Bluetooth putus → cadangan digital (T6-05) menyelamatkan; tiket dapur tetap di layar (T4-01). **Tertutup.**

---

## 9. Risiko terbuka & pertanyaan untuk pemilik

**Pertanyaan (jawaban cukup satu kalimat masing-masing):**
1. **T-022 — Email ke pelanggan:** boleh pakai alamat Gmail milikmu (lewat "sandi aplikasi", gratis, ±500 email/hari) untuk mengirim email verifikasi/pemulihan? Kalau tidak, pilih Brevo gratis (300/hari, perlu verifikasi alamat pengirim) atau "hanya masuk lewat Google + kasir mendaftarkan". Dibutuhkan **sebelum Fase 2**.
2. **T-023 — PIN pelanggan:** PRD menjanjikan pelanggan punya PIN, rancangan basis data tidak. Usul saya: **hapus PIN pelanggan** (Google/tautan email sudah cukup). Setuju?

**Risiko terbuka (tidak butuh jawaban sekarang):** repo privat → jatah CI 2.000 menit/bulan (dipantau tiap batch); `_Notes.md` berisi data pribadimu (hapus saat sempat); tiga nomor migrasi ganda di cabang terbaru (`0011`, `0015`, `0066`) harus dinomori ulang sebelum T1-27/T10-11/T10-13 dibangun; TECH_SPEC §3 belum mengenal `aplikasi/alat/`, `src/uji`, `src/bahasa`, `src/kontrak` yang sudah nyata dipakai; label ART-6 di T1-13.

---

## 10. Batas cakupan (apa yang TIDAK saya periksa)

- Isi `skills/` (vendor), `_sistem/templates/*`, `_salinan-meta/*`, `docs/uji/LAPORAN_CROSS_CHECK_TAHAP6.md`, `_log-sesi/LOG_SESI_2026-09-15.md`, gambar/font/foto (biner), `package-lock.json`.
- Prototipe (`prototipe/*`) tidak dijalankan; klaim uji kontras/halaman TIDAK BISA DIVERIFIKASI.
- Kode di `267d890` (`aplikasi/`, `supabase/`, `.github/`) **tidak** ditinjau sebagai kode — hanya dipakai membuktikan fakta (CI Node 22, migrasi 0011/0015 ada, komentar proyek dijeda). Uji SQL 41/41 di sana tidak saya jalankan (butuh PostgreSQL; di luar lingkup "sebelum coding").
- Tidak menghubungi layanan luar dengan akun (tidak ada akun); verifikasi batas gratis hanya dari dokumen resmi tertanggal 2026-09-19.
- `PANDUAN_PENGGUNA.md` versi `a522db0` (191 baris) dibaca penuh; versi 267d890 (741 baris) hanya lewat grep.
- Tidak menilai kualitas desain (docs/desain) — keputusan pemilik.

---

## 11. Rekomendasi

Fondasi ini **layak dilanjutkan**: dokumen terkunci saling konsisten pada hal besar (uang, peran, alur pesanan, RLS), 150 tugas lengkap 7 atribut, dan tiga pemeriksa kini menjaganya dari sudut berbeda. Yang perlu dilakukan sesi pembangun berikutnya, berurutan: (1) gabungkan 7 berkas dari commit sesi ini (tambalan tersedia; 7 potongan ROADMAP ditulis tangan), lalu jalankan `python3 alat/periksa-fondasi-independen-2.py` di cabang aktif dan bereskan sisa GAGAL di sana (21 ⚠️ judul, 3 migrasi ganda, 3 folder §3, T4-04, `DENYUT_URL`/`SUPABASE_SERVICE_ROLE_KEY`, status `CODING_DIJEDA_SADAR`); (2) minta dua jawaban pemilik (T-022, T-023) **sebelum menyentuh T2-04/T2-05**; (3) pasang ping anti-tidur & pemantauan menit CI sejak sekarang. **Aman mulai/melanjutkan Fase 0? Ya** — dengan syarat butir (1) digabung; tidak ada temuan yang mengharuskan membongkar pekerjaan Fase 0/1 yang sudah ada di `267d890`.

---

## 12. Catatan atas instruksi review ini sendiri

1. **Aturan pemilihan cabang "`STATUS: CODING_AKTIF`" sudah basi:** hanya cocok dengan `a522db0` (2026-09-16); tiga cabang turunan memakai `CODING_DIJEDA_SADAR`, sehingga aturan itu selalu memilih fondasi yang tertinggal 3 hari dan 312 berkas. Saya tetap patuh (target utama `a522db0`) tetapi menguji silang setiap temuan ke `267d890` — tanpa itu laporan ini akan mengulang 5 temuan yang sudah ditutup di sana (README 146, `.gitignore`, T1-18, label 121, pemetaan skill). Usul untuk prompt berikutnya: "pilih cabang dengan `UPDATE TERAKHIR` paling baru yang punya `docs/ROADMAP.md`".
2. **Premis "review sebelum coding" tidak berlaku penuh:** Fase 0 selesai dan Fase 1 berjalan di `267d890`. Larangan "jangan mulai Fase 0" saya patuhi; putusan dibaca sebagai "aman melanjutkan".
3. **Nama berkas `alat/periksa-fondasi-independen.py`** yang diminta sudah dipakai review putaran 2 → saya membuat `-2.py` agar tidak menghapus pemeriksa lama (larangan yang lebih kuat). Sama untuk `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` (lihat catatan di kepala laporan).
4. **"Rute B: perbaikan ditulis di checkout sendiri (path sama)"** berarti cabang review memuat salinan 5 dokumen fondasi yang tidak ada di `main`; saat digabung ke cabang pembangun akan konflik dengan versi 267d890 — karena itu tambalan `docs/uji/perbaikan-putaran3.patch` disertakan dan hasil uji terapnya dilaporkan (bagian 4.4).
5. **Kuota TERTANGGUH ≤12** tetap aman (8 terbuka). Penomoran butir baru melompat ke **T-022/T-023** karena `267d890` sudah memakai T-014…T-021 — supaya tidak bentrok saat digabung.
6. Instruksi meminta "jangan menunggu instruksi tambahan" sekaligus "berhenti & tanya bila menyentuh keputusan terkunci": saya memilih **tidak berhenti**, mencatat dua pertanyaan (bagian 9) dan menandai DECISIONS_LOG "MENUNGGU PERSETUJUAN PEMILIK", karena keduanya tidak menghalangi Fase 0–1.

---

## 13. Keadaan sesi

- Cabang: `arena/01a0b9f2-resto-barokah` (base `main` @ `253d129`). Sesuai pengecualian instruksi: **`PROJECT_STATE.md`, `STATUS.md`, `_log-sesi/` tidak diubah/dibuat.**
- Berkas yang ditambah/diubah di commit sesi ini: `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` (laporan ini), `docs/uji/perbaikan-putaran3.patch`, `alat/periksa-fondasi-independen-2.py`, `docs/ROADMAP.md`, `docs/README.md`, `docs/TERTANGGUH.md`, `docs/DECISIONS_LOG.md`, `docs/AGENT_OPERATING_GUIDE.md` (salinan `a522db0` + perbaikan), `.gitignore`. Catatan: di `main` sudah ada `docs/README.md` versi kit (penjelasan folder kosong) — diganti dengan versi fondasi `a522db0` + perbaikan karena instruksi "path sama"; `.gitignore` belum ada di `main`.
- Tidak ada: merge/tutup PR, `git push --force`, penghapusan berkas, perubahan dokumen terkunci (`PRD`, `TECH_SPEC`, `DISCOVERY`), pemasangan paket, coding aplikasi, biaya.
- Salinan kerja sementara di `/tmp` (`fondasi-review`, `fondasi-terbaru`, `fondasi-perbaikan`, `uji-vs`) tidak dipersistenkan.
- Setelah commit & push, sesi **BERHENTI**.
