# LAPORAN REVIEW INDEPENDEN — Fondasi Resto Barokah ("Sajian")

> Ditulis oleh sesi review independen pada 2026-09-16. Fondasi ini **bukan hasil kerja sesi ini**.
> Tugas sesi ini: mencoba **mematahkan** fondasi sebelum coding dimulai, bukan menyetujuinya.

---

## 1. Laporan 5 baris untuk pemilik

1. Fondasinya **kuat dan nyata** — 150 tugas rinci, dokumen saling nyambung, dan tiga pemeriksa otomatis sekarang semuanya hijau.
2. Saya menemukan **1 masalah besar yang berbahaya**: tanda "tunggu jawaban pemilik" yang sudah kedaluwarsa masih menempel di 7 tempat — akibatnya agent akan **melewati** tugas Fase 0 (termasuk deploy) padahal Anda sudah menjawabnya. Sudah saya bersihkan.
3. Saya menemukan **3 lubang operasional**: tidak ada tugas untuk **cadangan data mingguan**, untuk **pulih setelah listrik mati**, dan untuk **pegawai yang berhenti**. Ketiganya sudah saya tambahkan sebagai tugas T10-09 s/d T10-12.
4. Nama tiga tabel database di rencana berbeda dengan nama resmi di dokumen teknis — kalau dibiarkan, agent coding bisa membuat tabel bernama salah. Sudah saya samakan.
5. Sisanya aman: tidak ada kunci rahasia yang bocor ke Git, tidak ada langkah berbayar, dan urutan hitung uang (subtotal → diskon → PB1 → service → pembulatan) konsisten di semua dokumen.

---

## 2. Putusan

### `SIAP SETELAH PERBAIKAN` — dan perbaikannya **sudah dikerjakan di cabang ini**

- **Kritis terbuka: 0** · **Mayor terbuka: 0** · Minor terbuka: 3 · Catatan: 5
- Semua temuan tingkat KRITIS dan MAYOR (W3-01, W9-01, W9-02, W1-01) **sudah diperbaiki** dan dibuktikan oleh tiga pemeriksa yang semuanya keluar 0.
- **Kenapa bukan langsung `SIAP MULAI CODING`:** perbaikan ini ada di cabang reviewer dan **belum digabung** ke cabang pembangun. Selama belum digabung, agent pembangun masih membaca ROADMAP versi lama yang punya tanda ❓ basi — jadi ia akan melewati T0-09. **Begitu cabang ini digabung, statusnya menjadi SIAP MULAI CODING tanpa syarat tambahan.**
- 3 Minor yang saya **sengaja tidak ubah** ada alasannya masing-masing (lihat kolom status di bagian 6).

---

## 3. Apa yang ditinjau

| Hal | Isi |
|---|---|
| **Rute yang dipakai** | **Rute A** — fondasi ada di checkout sendiri |
| **Ditinjau** | `arena/01a0aac5-resto-barokah` @ `0691cf825da2d6305b4a4af361ccd69e99b34817` |
| Bukti rute A | `ls docs/ROADMAP.md` → ada · `grep '^STATUS:' PROJECT_STATE.md` → `STATUS: CODING_AKTIF` |
| Cabang remote yang ada | `arena/01a0a8a2-resto-barokah` (sama persis, commit `0691cf8` — induk cabang ini), `arena/01a0aab1-resto-barokah` (reviewer putaran 1), `main` |
| Cabang tempat saya menulis | `arena/01a0aac5-resto-barokah` (cabang sesi ini) |
| PR | 1 PR OPEN (`#1`, dari `arena/01a0a8a2`). **Tidak saya merge dan tidak saya tutup.** |

**Langkah prasyarat bagian 0 — hasil tiap langkah:**

| Langkah | Hasil |
|---|---|
| `git rev-parse --abbrev-ref HEAD` | `arena/01a0aac5-resto-barokah` |
| `git log --oneline -3` | `0691cf8 Tanggapi review independen putaran 1: 4 temuan relevan diperbaiki + prompt review versi 3` |
| `ls docs/ROADMAP.md` | ADA → **rute A berlaku, rute B tidak dipakai** |
| `grep -m1 '^STATUS:' PROJECT_STATE.md` | `STATUS: CODING_AKTIF` |
| `python3 alat/mulai-sesi.py` | **Jalan, exit 0.** "DAFTAR TUNGGU" tampil benar (4 butir terbuka: T-002, T-003, T-010, T-011 — cocok dengan `docs/TERTANGGUH.md`). "KARTU SESI" tampil benar (posisi proyek, branch, PR, log sesi, 15 skill wajib, 12 berkas fondasi — semuanya `[ADA]`). |
| Aturan repo dibaca | `START_DI_SINI.md` § **Jenis Sesi 4 — Audit / Cross-Check** + `AGENT_SYSTEM.md` (aturan kerja, Stop Conditions) + `PROFIL_PENGGUNA.md` (bahasa Indonesia, tanpa jargon, pemilik nol coding) |

---

## 4. Metode & perintah yang dijalankan (bisa diulang siapa pun)

```bash
# orientasi
git rev-parse --abbrev-ref HEAD && git log --oneline -3
git ls-remote --heads origin
python3 alat/mulai-sesi.py

# pemeriksa yang sudah ada (keadaan awal, sebelum saya menyentuh apa pun)
python3 _sistem/validate_system.py        # → SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS   (exit 0)
python3 alat/periksa-roadmap.py           # → HASIL: LOLOS — 146 tugas                    (exit 0)

# pemeriksa baru yang saya tulis sendiri
python3 alat/periksa-fondasi-independen.py

# pemeriksaan tangan
grep -n '❓ T-00[1-8]' docs/ROADMAP.md
git ls-files | wc -l ; du -sh skills ; git check-ignore -v .env.example
grep -rlE 'sk-[A-Za-z0-9]{20}|ghp_[A-Za-z0-9]{20}|AKIA[0-9A-Z]{16}' skills docs prototipe
gh pr list --state all
```

**Cara mengacak 15 tugas sampel (bisa diulang persis):**

```bash
python3 -c "
import random,re
t=open('docs/ROADMAP.md').read()
ids=[i for i,_ in re.findall(r'^- \[[ x]\] (T\d+-\d+) — (.+)\$',t,re.M)]
random.seed(20260916); print(sorted(random.sample(ids,15)))"
```
→ `T1-01 T1-18 T10-01 T10-02 T11-01 T11-08 T2-09 T3-01 T4-02 T4-03 T4-04 T7-05 T7-08 T8-10 T8-11`
(3 dari Fase 0 ditambahkan wajib: **seluruh** T0-01…T0-10 diperiksa satu per satu di W4.)

---

## 5. Tabel cakupan berkas

Total berkas terlacak Git: **1971**

- TIDAK DIPERIKSA satu per satu: 1801
- TIDAK DIPERIKSA: 59
- TIDAK DIPERIKSA: 57
- DIPERIKSA SEKILAS: 36
- DIPERIKSA MENDALAM: 18

<details><summary>Tabel lengkap per berkas (klik untuk buka)</summary>

| Berkas | Status |
|---|---|
| `.gitignore` | DIPERIKSA MENDALAM |
| `10_LOG_SESI.md` | DIPERIKSA SEKILAS |
| `ACCEPTANCE_TESTS.md` | DIPERIKSA MENDALAM |
| `ACCEPTANCE_TEST_LOG.md` | DIPERIKSA SEKILAS |
| `AGENT_SYSTEM.md` | DIPERIKSA SEKILAS |
| `PANDUAN_PEMAKAIAN.md` | DIPERIKSA SEKILAS |
| `PANDUAN_PENGGUNA.md` | DIPERIKSA MENDALAM |
| `PROFIL_PENGGUNA.md` | DIPERIKSA MENDALAM |
| `PROJECT_STATE.md` | DIPERIKSA MENDALAM |
| `PROMPT_ENTRI_UNIVERSAL.md` | DIPERIKSA SEKILAS |
| `REKAM-KLINIK.md` | DIPERIKSA SEKILAS |
| `START_DI_SINI.md` | DIPERIKSA MENDALAM |
| `STATUS.md` | DIPERIKSA MENDALAM |
| `SYSTEM_MANIFEST.md` | DIPERIKSA SEKILAS |
| `_Notes.md` | DIPERIKSA SEKILAS |
| `_log-sesi/LOG_SESI_2026-09-15.md` | DIPERIKSA SEKILAS |
| `_log-sesi/LOG_SESI_2026-09-16.md` | DIPERIKSA SEKILAS |
| `_salinan-meta/PLATFORM_LMARENA.md` | DIPERIKSA SEKILAS |
| `_salinan-meta/STATUS_SISTEM_v0.2.0_HISTORI.md` | DIPERIKSA SEKILAS |
| `_sistem/02_TAWARAN_KAPABILITAS_PLUS_AUDIT.md` | DIPERIKSA SEKILAS |
| `_sistem/03_AUDIT_VERCEL_SKILLS.md` | DIPERIKSA SEKILAS |
| `_sistem/AUDIT_NPX_UPDATE_2026-09-16.md` | DIPERIKSA SEKILAS |
| `_sistem/AUDIT_ZIP_VS_NPX_2026-09-16.md` | DIPERIKSA SEKILAS |
| `_sistem/templates/AGENT_OPERATING_GUIDE.md` | DIPERIKSA SEKILAS |
| `_sistem/templates/DECISIONS_LOG.md` | DIPERIKSA SEKILAS |
| `_sistem/templates/DISCOVERY.md` | DIPERIKSA SEKILAS |
| `_sistem/templates/LOG_SESI.md` | DIPERIKSA SEKILAS |
| `_sistem/templates/PRD.md` | DIPERIKSA SEKILAS |
| `_sistem/templates/PROFIL_PENGGUNA.md` | DIPERIKSA SEKILAS |
| `_sistem/templates/PROJECT_STATE.md` | DIPERIKSA SEKILAS |
| `_sistem/templates/ROADMAP.md` | DIPERIKSA SEKILAS |
| `_sistem/templates/STATUS.md` | DIPERIKSA SEKILAS |
| `_sistem/templates/TECH_SPEC.md` | DIPERIKSA SEKILAS |
| `_sistem/validate_system.py` | DIPERIKSA MENDALAM |
| `alat/mulai-sesi.py` | DIPERIKSA MENDALAM |
| `alat/periksa-roadmap.py` | DIPERIKSA MENDALAM |
| `docs/AGENT_OPERATING_GUIDE.md` | DIPERIKSA MENDALAM |
| `docs/DECISIONS_LOG.md` | DIPERIKSA MENDALAM |
| `docs/DISCOVERY.md` | DIPERIKSA SEKILAS |
| `docs/PRD.md` | DIPERIKSA MENDALAM |
| `docs/README.md` | DIPERIKSA MENDALAM |
| `docs/ROADMAP.md` | DIPERIKSA MENDALAM |
| `docs/TECH_SPEC.md` | DIPERIKSA MENDALAM |
| `docs/TERTANGGUH.md` | DIPERIKSA MENDALAM |
| `docs/desain/PENILAIAN_REFERENSI.md` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/RENCANA_DESAIN_UI.md` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/mockup/papan-1-bara-panggang.png` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/mockup/papan-2-hangat-kedai.png` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/mockup/papan-3-kasir-terang.png` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/mockup/papan-4-kasir-gelap.png` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/mockup/papan-5-katalog-terang.png` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/palet-tema.png` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/papan-referensi-pemilik.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/papan-referensi.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/01-pos-dashboard-food.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/02-kasir-cashier-dashboard.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/03-admin-order-coffeeshop.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/04-dapurku-pos-fastfood.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/05-kds-1.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/06-kds-2.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/07-kds-3.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/08-pos-pelayan-mobile.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/09-waiter-booking-app.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/10-waiter-android.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/11-alur-keranjang-checkout.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/12-dashboard-laporan-resto.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/13-dashboard-gelap.webp` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/Sumber.md` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P01-katalog-detail-navy.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P02-web-menu-keranjang.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P03-mobile-burger-gelap.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P04-kasir-desktop-terang.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P05-mobile-pesanan-keranjang.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P06-poster-menu-ramen.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P07-poster-espresso.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P08-katalog-terang-bersih.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P09-kolase-promosi.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P10-mobile-daftar-menu.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P11-mobile-proses-desain.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P12-terang-vs-gelap.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P13-web-mewah-gelap.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P14-mobile-ember-grill.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P15-mobile-kopi-hangat.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P16-mobile-grill-co.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P17-kasir-pos-gelap.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P18-katalog-burger-biru.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P19-mobile-seafood-set.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P20-mobile-fastfood-oranye.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P21-aplikasi-rupiah.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P22-toko-kue-alur.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P23-menu-tabel-keranjang.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P24-mobile-foodie-gelap.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P25-kopi-gelap-ukuran.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P26-panel-laporan-terang.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P27-kopi-gelap-varian.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P28-detail-menu-hangat.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P29-kartu-menu-gelap.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P30-menu-indonesia.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P31-dashboard-pesanan-gelap.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P32-kasir-pos-terang.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P33-mobile-five-guys.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/P34-resep-gelap.jpg` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/desain/referensi/pemilik/README.md` | TIDAK DIPERIKSA (aset desain/gambar — di luar lingkup kesiapan coding; hanya ukurannya diperiksa di W10) |
| `docs/teknis/DISKUSI_TAHAP4_ATURAN_KERJA.md` | DIPERIKSA SEKILAS |
| `docs/teknis/DISKUSI_TAHAP5_ROADMAP.md` | DIPERIKSA SEKILAS |
| `docs/teknis/DISKUSI_TEKNIS_TAHAP3.md` | DIPERIKSA SEKILAS |
| `docs/uji/CATATAN_REVIEW_SESI_01a0aab1.md` | DIPERIKSA SEKILAS |
| `docs/uji/LAPORAN_CROSS_CHECK_TAHAP6.md` | DIPERIKSA SEKILAS |
| `docs/uji/PROMPT_REVIEW_INDEPENDEN.md` | DIPERIKSA SEKILAS |
| `package-lock.json` | DIPERIKSA SEKILAS |
| `package.json` | DIPERIKSA MENDALAM |
| `prototipe/01-laporan.html` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/02-kasir.html` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/03-katalog.html` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/04-tema.html` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/README.md` | DIPERIKSA SEKILAS |
| `prototipe/alat/gambar.js` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/alat/mockup.js` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/alat/periksa-halaman.py` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/ayam-geprek.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/banner-kedai.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/dessert.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/es-kelapa.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/es-teh.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-ArsenalSC.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-BigShoulders.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-BricolageGrotesque.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-CrimsonPro.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-Gloock.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-InstrumentSans.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-JetBrainsMono.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-Lora.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-NationalPark.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-Outfit.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-WorkSans.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/LISENSI-YoungSerif.txt` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/arsenalsc-reguler.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/bigshoulders-tebal.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/bricolage-tebal.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/crimson-reguler.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/crimson-tebal.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/gloock.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/instrument-reguler.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/instrument-serif-miring.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/instrument-serif.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/instrument-tebal.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/lora-tebal.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/mono-reguler.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/nationalpark-tebal.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/outfit-reguler.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/outfit-tebal.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/worksans-miring.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/worksans-reguler.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/worksans-tebal.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/font/youngserif-reguler.woff2` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/hero-warung.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/interior.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/kopi-susu.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/mie-ayam.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/nasi-goreng.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/pisang-goreng.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/salad.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/aset/sate.jpg` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/buat-galeri-tema.py` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/buat-palet.py` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/css/tokens.css` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/index.html` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/js/ui.js` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `prototipe/uji-kontras.py` | TIDAK DIPERIKSA (contoh tampilan, bukan kode produksi; hanya dipakai sebagai rujukan T0-03) |
| `skills/README.md` | DIPERIKSA SEKILAS |
| `skills/agent-browser/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agent-skills-hub/CATALOG.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agent-skills-hub/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agent-skills/CATALOG.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agent-skills/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/browse-the-web.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/callable.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/client-sdk.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/codemode.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/durable-execution.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/email.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/human-in-the-loop.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/mcp.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/observability.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/queue-retries.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/routing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/server-driven-messages.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/state-scheduling.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/streaming-chat.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/think.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/voice.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/webhooks-push.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/agents-sdk/references/workflows.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/ask-questions-if-underspecified/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/audit-library-health/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/backend-development/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/best-practices/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/best-practices/agents/best-practices-referencer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/best-practices/agents/codebase-context-builder.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/best-practices/agents/task-intent-analyzer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/best-practices/references/anti-patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/best-practices/references/before-after-examples.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/best-practices/references/best-practices-guide.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/best-practices/references/common-workflows.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/best-practices/references/prompt-patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/browse-and-evaluate/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/build-workspace-docs/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/changelog-generator/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/code-documentation/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/content-research-writer/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/curate-a-team-library/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/database-design/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/install-from-remote-library/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/llm-application-dev/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/migrate-skills-between-libraries/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/review-a-skill/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/share-a-library/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-agent-skills/skills/update-installed-skills/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/agent.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/artifact.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/attachments.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/audio-player.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/canvas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/chain-of-thought.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/checkpoint.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/code-block.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/commit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/confirmation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/connection.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/context.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/controls.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/conversation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/edge.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/environment-variables.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/file-tree.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/image.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/inline-citation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/jsx-preview.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/message.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/mic-selector.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/model-selector.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/node.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/open-in-chat.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/package-info.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/panel.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/persona.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/plan.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/prompt-input.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/queue.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/reasoning.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/sandbox.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/schema-display.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/shimmer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/snippet.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/sources.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/speech-input.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/stack-trace.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/suggestion.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/task.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/terminal.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/test-results.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/tool.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/toolbar.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/transcription.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/voice-selector.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/references/web-preview.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/agent.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/artifact.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/attachments-inline.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/attachments-list.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/attachments.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/audio-player-remote.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/audio-player.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/chain-of-thought.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/checkpoint.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/code-block-dark.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/code-block.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/commit.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/confirmation-accepted.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/confirmation-rejected.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/confirmation-request.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/confirmation.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/context.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/conversation.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/environment-variables.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/file-tree-basic.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/file-tree-expanded.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/file-tree-selection.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/file-tree.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/image.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/inline-citation.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/jsx-preview.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/message.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/mic-selector.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/model-selector.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/open-in-chat.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/package-info.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/persona-command.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/persona-glint.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/persona-halo.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/persona-mana.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/persona-obsidian.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/persona-opal.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/plan.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/prompt-input-cursor.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/prompt-input-tooltip.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/prompt-input.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/queue-prompt-input.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/queue.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/reasoning.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/sandbox.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/schema-display-basic.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/schema-display-body.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/schema-display-nested.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/schema-display-params.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/schema-display.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/shimmer-duration.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/shimmer-elements.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/shimmer.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/snippet-plain.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/snippet.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/sources-custom.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/sources.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/speech-input.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/stack-trace-collapsed.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/stack-trace-no-internal.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/stack-trace.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/suggestion-input.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/suggestion.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/task.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/terminal-basic.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/terminal-clear.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/terminal-streaming.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/terminal.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/test-results-basic.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/test-results-errors.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/test-results-suites.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/test-results.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/tool-input-available.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/tool-input-streaming.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/tool-output-available.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/tool-output-error.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/tool.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/transcription.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/voice-selector.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-elements/scripts/web-preview.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ai-sdk/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/.gitignore` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/AGENTS.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/LICENSE.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/agents/openai.yaml` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/references/alibaba-java-rules.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/scripts/validate_skill.go` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/scripts/validate_skill.mjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/scripts/validate_skill.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/skills/alibaba-java-coding-guidelines-skill/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/skills/alibaba-java-coding-guidelines-skill/agents/openai.yaml` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/skills/alibaba-java-coding-guidelines-skill/references/alibaba-java-rules.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/alibaba-java/tests/test_validators.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/awesome-agent-skills/CONTRIBUTING.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/awesome-agent-skills/LICENSE` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/awesome-agent-skills/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/banner-design/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/banner-design/references/banner-sizes-and-styles.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brainstorming/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brainstorming/scripts/frame-template.html` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brainstorming/scripts/helper.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brainstorming/scripts/server.cjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brainstorming/scripts/start-server.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brainstorming/scripts/stop-server.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brainstorming/spec-document-reviewer-prompt.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brainstorming/visual-companion.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/references/approval-checklist.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/references/asset-organization.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/references/brand-guideline-template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/references/color-palette-management.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/references/consistency-checklist.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/references/logo-usage-rules.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/references/messaging-framework.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/references/typography-specifications.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/references/update.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/references/visual-identity.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/references/voice-framework.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/scripts/extract-colors.cjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/scripts/inject-brand-context.cjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/scripts/sync-brand-to-tokens.cjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/scripts/tests/test_sync_brand_to_tokens.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/scripts/validate-asset.cjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/brand/templates/brand-guidelines-starter.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/accessibility.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/as-child.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/composition.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/data-attributes.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/definitions.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/design-tokens.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/docs.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/marketplaces.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/npm.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/polymorphism.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/principles.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/registry.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/state.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/styling.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/building-components/references/types.mdx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ai-gateway/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ai-gateway/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ai-gateway/dynamic-routing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ai-gateway/features.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ai-gateway/sdk-integration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ai-gateway/troubleshooting.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ai-search/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ai-search/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ai-search/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ai-search/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ai-search/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/analytics-engine/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/analytics-engine/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/analytics-engine/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/analytics-engine/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/analytics-engine/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/api-shield/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/api-shield/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/api-shield/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/api-shield/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/api-shield/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/api/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/api/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/api/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/api/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/api/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/argo-smart-routing/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/argo-smart-routing/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/argo-smart-routing/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/argo-smart-routing/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/argo-smart-routing/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/artifacts/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/artifacts/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/artifacts/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/bindings/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/bindings/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/bindings/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/bindings/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/bindings/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/bot-management/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/bot-management/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/bot-management/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/bot-management/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/bot-management/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/browser-rendering/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/browser-rendering/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/browser-rendering/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/browser-rendering/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/browser-rendering/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/c3/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/c3/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/c3/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/c3/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/c3/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/cache-reserve/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/cache-reserve/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/cache-reserve/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/cache-reserve/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/cache-reserve/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/containers/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/containers/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/containers/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/containers/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/containers/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/cron-triggers/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/cron-triggers/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/cron-triggers/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/cron-triggers/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/cron-triggers/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/d1/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/d1/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/d1/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/d1/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/d1/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ddos/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ddos/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ddos/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ddos/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/ddos/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/do-storage/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/do-storage/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/do-storage/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/do-storage/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/do-storage/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/do-storage/testing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/email-routing/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/email-routing/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/email-routing/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/email-routing/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/email-routing/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/email-workers/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/email-workers/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/email-workers/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/email-workers/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/email-workers/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/flagship/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/flagship/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/flagship/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/flagship/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/flagship/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/graphql-api/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/graphql-api/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/graphql-api/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/graphql-api/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/graphql-api/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/hyperdrive/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/hyperdrive/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/hyperdrive/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/hyperdrive/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/hyperdrive/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/images/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/images/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/images/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/images/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/images/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/kv/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/kv/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/kv/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/kv/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/kv/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/miniflare/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/miniflare/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/miniflare/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/miniflare/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/miniflare/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/network-interconnect/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/network-interconnect/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/network-interconnect/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/network-interconnect/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/network-interconnect/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/observability/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/observability/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/observability/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/observability/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/observability/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pages-functions/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pages-functions/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pages-functions/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pages-functions/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pages-functions/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pages/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pages/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pages/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pages/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pages/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pipelines/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pipelines/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pipelines/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pipelines/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pipelines/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pulumi/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pulumi/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pulumi/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pulumi/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/pulumi/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/queues/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/queues/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/queues/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/queues/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/queues/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2-data-catalog/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2-data-catalog/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2-data-catalog/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2-data-catalog/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2-data-catalog/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2-sql/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2-sql/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2-sql/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2-sql/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2-sql/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/r2/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/realtime-sfu/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/realtime-sfu/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/realtime-sfu/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/realtime-sfu/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/realtime-sfu/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/realtimekit/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/realtimekit/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/realtimekit/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/realtimekit/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/realtimekit/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/secrets-store/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/secrets-store/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/secrets-store/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/secrets-store/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/secrets-store/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/smart-placement/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/smart-placement/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/smart-placement/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/smart-placement/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/smart-placement/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/snippets/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/snippets/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/snippets/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/snippets/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/snippets/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/spectrum/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/spectrum/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/spectrum/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/spectrum/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/spectrum/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/static-assets/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/static-assets/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/static-assets/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/static-assets/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/static-assets/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/stream/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/stream/api-live.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/stream/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/stream/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/stream/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/stream/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/tail-workers/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/tail-workers/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/tail-workers/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/tail-workers/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/tail-workers/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/terraform/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/terraform/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/terraform/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/terraform/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/terraform/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/tunnel/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/tunnel/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/tunnel/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/tunnel/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/tunnel/networking.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/tunnel/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/turn/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/turn/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/turn/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/turn/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/turn/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/vectorize/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/vectorize/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/vectorize/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/vectorize/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/vectorize/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/waf/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/waf/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/waf/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/waf/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/waf/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/web-analytics/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/web-analytics/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/web-analytics/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/web-analytics/integration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/web-analytics/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workerd/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workerd/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workerd/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workerd/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workerd/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-ai/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-ai/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-ai/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-ai/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-ai/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-for-platforms/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-for-platforms/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-for-platforms/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-for-platforms/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-for-platforms/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-playground/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-playground/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-playground/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-playground/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-playground/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-vpc/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-vpc/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-vpc/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-vpc/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workers-vpc/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workflows/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workflows/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workflows/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workflows/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/workflows/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/zaraz/IMPLEMENTATION_SUMMARY.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/zaraz/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/zaraz/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/zaraz/configuration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/zaraz/gotchas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/cloudflare/references/zaraz/patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/data/slide-backgrounds.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/data/slide-charts.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/data/slide-color-logic.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/data/slide-copy.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/data/slide-layout-logic.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/data/slide-layouts.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/data/slide-strategies.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/data/slide-typography.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/references/component-specs.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/references/component-tokens.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/references/primitive-tokens.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/references/semantic-tokens.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/references/states-and-variants.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/references/tailwind-integration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/references/token-architecture.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/scripts/embed-tokens.cjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/scripts/fetch-background.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/scripts/generate-slide.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/scripts/generate-tokens.cjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/scripts/html-token-validator.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/scripts/search-slides.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/scripts/slide-token-validator.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/scripts/slide_search_core.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/scripts/tests/test_validate_tokens.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/scripts/validate-tokens.cjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design-system/templates/design-tokens-starter.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/data/cip/deliverables.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/data/cip/industries.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/data/cip/mockup-contexts.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/data/cip/styles.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/data/icon/styles.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/data/logo/colors.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/data/logo/industries.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/data/logo/styles.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/banner-sizes-and-styles.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/cip-deliverable-guide.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/cip-design.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/cip-prompt-engineering.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/cip-style-guide.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/design-routing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/icon-design.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/logo-color-psychology.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/logo-design.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/logo-prompt-engineering.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/logo-style-guide.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/slides-copywriting-formulas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/slides-create.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/slides-html-template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/slides-layout-patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/slides-strategies.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/slides.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/references/social-photos-design.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/scripts/cip/core.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/scripts/cip/generate.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/scripts/cip/render-html.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/scripts/cip/search.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/scripts/icon/generate.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/scripts/logo/core.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/scripts/logo/generate.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/scripts/logo/search.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/design/scripts/logo/tests/test_generate.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/excalidraw-diagram/.gitignore` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/excalidraw-diagram/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/excalidraw-diagram/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/excalidraw-diagram/references/color-palette.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/excalidraw-diagram/references/element-templates.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/excalidraw-diagram/references/json-schema.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/excalidraw-diagram/references/pyproject.toml` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/excalidraw-diagram/references/render_excalidraw.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/excalidraw-diagram/references/render_template.html` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/find-skills/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/frontend-designer-lite/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/frontend-designer/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/frontend-designer/references/source-index.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/frontend-designer/references/technical-reference.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/gmail/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/gmail/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/gmail/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/gmail/scripts/auth.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/gmail/scripts/gmail.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/gmail/scripts/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-calendar/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-calendar/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-calendar/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-calendar/scripts/auth.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-calendar/scripts/gcal.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-calendar/scripts/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-chat/.gitignore` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-chat/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-chat/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-chat/directory.example.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-chat/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-chat/scripts/auth.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-chat/scripts/chat.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-docs/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-docs/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-docs/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-docs/scripts/auth.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-docs/scripts/docs.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-docs/scripts/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-drive/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-drive/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-drive/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-drive/scripts/auth.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-drive/scripts/drive.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-drive/scripts/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-sheets/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-sheets/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-sheets/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-sheets/scripts/auth.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-sheets/scripts/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-sheets/scripts/sheets.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-slides/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-slides/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-slides/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-slides/scripts/auth.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-slides/scripts/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/google-slides/scripts/slides.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/3d-experience-designer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/accessibility-reviewer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/app-intents-expert.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/app-store-reviewer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/core-ai-expert.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/foundation-models.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/ios-docs.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/ios-explore.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/ios-plan.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/metal-expert.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/motion-designer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/performance-reviewer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/realitykit-expert.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/security-reviewer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/swift-debugger.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/swift-refactorer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/swift-reviewer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/swiftui-expert.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/swiftui-modernization.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/testing-expert.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/ui-ux-designer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/uikit-expert.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/webkit-expert.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/agents/xcode-expert.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.claude/settings.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.dockerignore` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.github/ISSUE_TEMPLATE/bug_report.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.github/ISSUE_TEMPLATE/feature_request.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.github/PULL_REQUEST_TEMPLATE.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.github/workflows/docs-consistency.yml` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.github/workflows/pages.yml` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.github/workflows/release.yml` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/.gitignore` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ADOPTION.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/AGENTS.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/CHANGELOG.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/CLAUDE.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/CODE_OF_CONDUCT.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/CONTRIBUTING.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/DISCOVERABILITY.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/GEMINI.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/LICENSE` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ROADMAP.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/SUBMISSION_TRACKER.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/checklists/app-store-submission.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/checklists/performance.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/checklists/security.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/checklists/testing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/.gitignore` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/package-lock.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/package.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/src/commands.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/src/config.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/src/discover.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/src/index.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/src/layout.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/src/scaffold.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/test/commands.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/test/layout.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/test/scaffold.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/cli/tsconfig.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/agent-engineering-guide.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/ai-setup-guide.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/ai/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/ai/machine-learning-brain.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/animation/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/animation/web-animation-concepts.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple-docs-reference.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple-framework-index.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/a-section-memory.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/all-technologies.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/b-m-section-memory.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/coverage-status.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/documentation-navigator-brain.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/local-library.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/local-library.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/n-z-section-memory.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/resources-support-memory.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/accelerate__simd-library.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/accessoryaccess.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/accessoryliveactivities.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/accessorynotifications.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/accessorytransportextension.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/accountdatatransfer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/accountorganizationaldatasharing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/accounts.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/adattributionkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/addressbook.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/addressbookui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/adservices.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/adsupport.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/advancedcommerceapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/alarmkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/analytics-reports.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/appdatatransfer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/appintentstesting.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/appkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/apple-ads-platform-api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/apple-school-and-business-manager-api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/apple-silicon.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/apple_ads.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/applearchive.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/applemapsserverapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/applemusicapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/applemusicfeed.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/applenews.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/applepaymerchanttokenusageinformation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/applepayontheweb.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/applepaywebmerchantregistrationapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/applepencil.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/appletvfeed.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/applicationservices.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/applicensedeliverysdk.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/appmigrationkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/appstoreconnectapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/appstorereceipts.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/appstoreservernotifications.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/apptrackingtransparency.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/assetslibrary.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/assignables.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/audioaccessorykit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/audiodriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/audiotoolbox.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/audiounit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/automateddeviceenrollment.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/automaticassessmentconfiguration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/automaticsigninapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/automator.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/avfaudio.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/avrouting.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/avsystemrouting.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/backgroundassets.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/blockstoragedevicedriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/browserenginecore.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/browserenginekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/browserkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/bundleresources.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/callkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/carekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/carkey.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/carplay.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/cfnetwork.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/cinematic.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/cktooljs.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/classkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/classkitcatalogapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/classkitui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/clockkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/cloudkitjs.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/collaboration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/colorsync.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/compositorservices.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/compression.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/computegraph.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/contactprovider.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/contactsui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/coreaudio.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/coreaudiokit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/coreaudiotypes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/corefoundation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/coregraphics.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/corehid.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/coreimage.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/corelocationui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/coremediaio.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/coremidi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/coreservices.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/coretelephony.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/coretext.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/coretransferable.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/corevideo.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/corewlan.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/crashreportextension.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/createml.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/createmlcomponents.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/cryptotokenkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/darwinnotify.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/datadetection.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/declaredagerange.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/developertoolssupport.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/deviceactivity.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/devicediscoveryextension.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/devicediscoveryui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/devicemanagement.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/diskarbitration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/diskimagekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/dispatch.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/distributed.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/dnssd.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/docc.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/dockkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/driverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/endpointsecurity.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/energykit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/enterpriseprogramapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/eventkitui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/exceptionhandling.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/executionpolicy.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/exposurenotification.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/extensionfoundation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/extensionkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/externalpurchaseserverapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/familycontrols.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/fileproviderui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/financekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/financekitui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/findersync.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/forcefeedback.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/foveatedstreaming.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/fskit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/gamekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/gamesave.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/geotoolbox.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/glkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/groupactivities.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/gss.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/hiddriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/http-live-streaming.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/hvf.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/hypervisor.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/iad.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/identitydocumentservices.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/identitydocumentservicesui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/identitylookup.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/imagecapturecore.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/imageio.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/imageplayground.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/immersivemediasupport.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/inputmethodkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/installer_js.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/iobluetooth.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/iobluetoothui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/iokit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/ios-ipados-release-notes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/iosurface.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/iousbhost.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/ituneslibrary.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/iworkdocumentexportingapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/javascriptcore.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/journalingsuggestions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/kernel.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/latentsemanticmapping.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/lightweightcoderequirements.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/livecommunicationkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/livephotoskitjs.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/localauthenticationembeddedui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/lockedcameracapture.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/macos-release-notes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mailkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/managedapp.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/managedappdistribution.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/managedsettings.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/managedsettingsui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mapkitjs.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/marketplacekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/matter.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mattersupport.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mediaaccessibility.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mediadevice.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mediaextension.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mediaintelligence.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mediaintents.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/medialibrary.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mediaplayer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mediasetup.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mediatoolbox.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/merchanttokennotificationservices.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/messages.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/messageui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/metalfx.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/metalkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/metalperformanceshaders.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/metalperformanceshadersgraph.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/metrickit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mididriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/mlcompute.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/modelio.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/musickitjs.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/musicunderstanding.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/networkingdriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/notaryapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/notificationcenter.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/nowplaying.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/objectivec.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/observation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/opendirectory.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/opengles.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/packagedescription.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/paperkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/paravirtualizedgraphics.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/pcidriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/permissionkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/phase.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/playgroundbluetooth.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/playgroundsupport.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/preferencepanes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/privatecloudcomputesecurityguide.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/professional_video_applications.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/proximityreader.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/pushkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/pushtotalk.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/quartz.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/quicklookthumbnailing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/quicklookui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/quicktime-file-format.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/realitycomposerpro.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/regexbuilder.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/relevancekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/researchkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/retentionmessaging.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/rosterapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/safari-developer-tools.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/safari-release-notes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/safariservices.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/safariservices__safari-app-extensions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/safetykit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/samplecode.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/screencapturekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/screensaver.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/screentime.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/scriptingbridge.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/scsicontrollerdriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/scsiperipheralsdriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/secureelementcredential.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/securityfoundation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/securityinterface.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/sensitivecontentanalysis.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/serialdriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/servicemanagement.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/servicesaccountlinking.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/shadergraph.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/sharedwithyou.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/signinwithapple.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/sirieventsuggestionsmarkup.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/sirikit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/sirikitcloudmedia.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/skadnetworkforwebads.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/snapshots.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/social.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/spatial.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/spatialpreview.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/statereporting.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/storekittest.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/suggestedactions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/swift-playgrounds.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/swift.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/symbols.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/synchronization.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/system.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/systemconfiguration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/systemextensions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/tabletopkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/tabulardata.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/technologyoverviews.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/technotes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/telephonymessagingkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/testing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/threadnetwork.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/touchcontroller.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/translationuiprovider.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/trustinsights.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/tvml.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/tvmljs.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/tvmlkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/tvos-release-notes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/tvservices.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/tvuikit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/uikit__mac-catalyst.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/updates.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/usbdriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/usbserialdriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/usd.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/usdkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/usernotificationsui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/videodriverkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/videosubscriberaccount.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/videotoolbox.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/virtualization.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/visionos-release-notes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/visualintelligence.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/vmnet.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/walletpasses.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/watchconnectivity.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/watchkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/watchos-apps.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/watchos-release-notes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/weatherkitrestapi.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/webkitjs.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/wifiaware.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/wifiinfrastructure.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/wirelessinsights.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/workoutkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/xcode-release-notes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/xcode.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/xcode__swift-packages.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/xcode__xcode-cloud.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/xcodekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/xcselect.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/xctest.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technologies/xpc.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/technology-workflow.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/updates-and-release-notes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/apple/updates.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/compatibility-matrix.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/data/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/design/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/design/color-system.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/design/design-tokens.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/design/fonts-catalog.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/design/icon-composer.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/design/interaction-standards.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/design/liquid-glass-adoption.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/design/stunning-ui-patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/design/third-party-animations.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/design/typography-system.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/accelerate.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/accessibility.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/activitykit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/app-clips.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/app-intents-intelligence.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/app-intents.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/apple-intelligence.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/arkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/authentication-services.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/avfoundation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/background-tasks.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/cloudkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/combine.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/core-ai.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/core-data.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/core-location.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/core-spotlight-rag.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/cryptokit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/data-concurrency.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/device-integrity.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/extended-apple-frameworks.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/foundation-models.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/foundation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/hardware/core-bluetooth.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/hardware/core-motion.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/hardware/core-nfc.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/hardware/healthkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/hardware/homekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/local-authentication.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/mapkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/metal.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/ml/coreml.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/ml/natural-language.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/ml/on-device-ai.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/ml/sound-analysis.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/ml/speech.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/ml/translation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/ml/vision.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/network-framework.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/networking.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/oslog.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/photosui.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/realitykit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/scenekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/services/contacts.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/services/eventkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/services/passkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/services/weatherkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/storekit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/swift-charts.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/swiftdata.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/tipkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/usernotifications.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/visionkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/frameworks/widgetkit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/graphics/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/mcp/examples.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/mcp/installation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/mcp/knowledge-server.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/mcp/tools.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/mcp/vnext-analysis-tools.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/migration/ios-deployment-migration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/migration/swift-6-migration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/migration/xcode-migration.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/networking/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/orchestration/dynamic-workflows.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/orchestration/hooks.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/orchestration/looping.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/orchestration/router.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/orchestration/subagents.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/orchestration/verification.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/performance/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/platforms/ios.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/platforms/iphone-duo.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/platforms/macos.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/platforms/tvos.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/platforms/visionos.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/platforms/watchos.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/security/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swift/memory-lifetime.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swift/swift-brain.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swift/swift-concurrency.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swift/swift-language.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swift/swift-standard-library.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swiftui/animations.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swiftui/deep-linking-and-routing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swiftui/gestures.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swiftui/ios-27-interactions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swiftui/layout.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swiftui/navigation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swiftui/state-and-data-flow.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/swiftui/views-and-controls.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/testing/evaluations.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/testing/mocking-strategy.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/testing/xcuiautomation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/tooling/app-description-workflow.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/tooling/device-hub.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/tooling/fm-cli.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/tooling/foundation-models-instruments.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/tooling/idea-to-app.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/tooling/ios-simulator-mcp.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/tooling/offline-source-library.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/tooling/project-scaffolding.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/tooling/visual-iteration-loop.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/tooling/xcode-27-agents.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/tooling/xcode-memory-debugging.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/uikit/animations.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/uikit/uikit-essentials.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/uikit/uikit-swiftui-interop.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/web/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/docs/web/native-vs-web-animation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/frameworks.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/gemini-extension.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/install.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/package-lock.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/package.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/src/index.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/src/previews.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/src/runner.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/src/simulator.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/src/viewer.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/test/previews.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/test/protocol.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/test/simulator.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/test/viewer.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/ios-simulator-mcp/tsconfig.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/.gitignore` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/Dockerfile.knowledge` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/LICENSE` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/mcp.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/package-lock.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/package.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/scripts/bundle-knowledge.mjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/scripts/check-tool-manifest.mjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/scripts/sync-version.mjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/analyzers/appstore.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/analyzers/architecture.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/analyzers/availability.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/analyzers/concurrency.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/analyzers/memory.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/analyzers/performance.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/analyzers/security.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/analyzers/skill.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/analyzers/swiftui.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/analyzers/testing.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/analyzers/types.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/index.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/knowledge-server.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/knowledge.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/report.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/resources.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/result.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/scan.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/unified.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/src/version.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/test/analyzers.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/test/knowledge.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/test/resources.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/test/reviewers.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/test/server.smoke.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/test/skill.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/test/unified.test.js` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/mcp-server/tsconfig.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/3d/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/accessibility/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/ai/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/animation/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/clean-architecture.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/coordinator.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/error-handling.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/metal/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/motion/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/motion/splash-screens.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/mvvm.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/realitykit/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/repository.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/tca.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/testing/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/ui/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/patterns/webkit/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/plugins/ios-agent-chatgpt/.codex-plugin/plugin.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/plugins/ios-agent-chatgpt/skills/ios-builder/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/plugins/ios-agent-skill/.codex-plugin/plugin.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/plugins/ios-agent-skill/.mcp.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/plugins/ios-agent-skill/skills/ios-builder/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/AppleRecipes/Package.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/AppleRecipes/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/AppleRecipes/Sources/AppleRecipes/ContentDigest.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/AppleRecipes/Sources/AppleRecipes/HTTPSQuery.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/AppleRecipes/Sources/AppleRecipes/JSONFileStore.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/AppleRecipes/Sources/AppleRecipes/PDFTextExtractor.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/AppleRecipes/Sources/AppleRecipes/TextLanguage.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/AppleRecipes/Sources/AppleRecipes/VectorStatistics.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/AppleRecipes/Tests/AppleRecipesTests/RecipesTests.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Package.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Sources/SkillPatterns/ArticleListModel.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Sources/SkillPatterns/Composition.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Sources/SkillPatterns/Domain.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Sources/SkillPatterns/Persistence.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Sources/SkillPatterns/Router.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Sources/SkillPatterns/SignalProcessing.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Sources/SkillPatterns/Streaming.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Tests/SkillPatternsTests/ArticleListModelTests.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Tests/SkillPatternsTests/PersistenceTests.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Tests/SkillPatternsTests/RouterTests.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Tests/SkillPatternsTests/SignalProcessingTests.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/samples/SkillPatterns/Tests/SkillPatternsTests/StateTransitionTests.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/check-contrast.mjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/check-framework-catalog.mjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/eval-agents.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/hooks/guard-generated-files.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/hooks/sync-mirrors-on-edit.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/hooks/verify-repo.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/index-local-library.mjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/lib/local-library.d.mts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/lib/local-library.mjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/npm-downloads.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/package-integrations.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/query-library.mjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/setup-repo-metadata.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/sync-apple-technologies.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/sync-apple-updates.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/sync-mirrors.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/tests/local-library.test.mjs` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/scripts/tests/test_apple_technologies.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/site/index.html` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/site/npm-downloads-details.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/site/npm-downloads.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/skill.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ci-cd/Fastfile` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ci-cd/github-actions.yml` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/common-patterns/auth-flow.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/common-patterns/dependency-injection.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/common-patterns/design-system.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/common-patterns/navigation-router.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/common-patterns/networking-layer.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/common-patterns/persistence-layer.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/common-patterns/ui-components.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/hooks/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/hooks/build-check.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/hooks/forbid-antipatterns.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/hooks/settings.json.example` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/hooks/swift-format.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/App.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/ContentView.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/Info.plist` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/Models/Item.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/Services/ItemRepository.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/Tests/AppTests.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/Tests/AppXCTests.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/ViewModels/HomeViewModel.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/ViewModels/ProfileViewModel.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/Views/HomeView.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/Views/ProfileView.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/ios-app/Views/SettingsView.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/multiplatform-app/Shared/MultiplatformApp.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/multiplatform-app/iOS/iOSApp.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/multiplatform-app/macOS/macOSApp.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ios-agent/templates/multiplatform-app/watchOS/watchOSApp.swift` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/async-patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/bundling.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/data-patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/debug-tricks.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/directives.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/error-handling.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/file-conventions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/font.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/functions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/hydration-error.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/image.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/metadata.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/parallel-routes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/route-handlers.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/rsc-boundaries.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/runtime-selection.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/scripts.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/self-hosting.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-best-practices/suspense-boundaries.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-cache-components/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/next-upgrade/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/prd-taskmaster/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/prd-taskmaster/phases/DISCOVER.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/prd-taskmaster/phases/GENERATE.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/prd-taskmaster/phases/HANDOFF.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/prd-taskmaster/reference/taskmaster-integration-guide.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/prd-taskmaster/reference/validation-checklist.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/business-health-diagnostic/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/competitive-analysis-process/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/competitive-analysis-process/examples/sample-industrial.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/competitive-analysis-process/examples/sample.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/competitive-analysis-process/template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/customer-journey-map/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/customer-journey-map/examples/meta-product-manager-skills.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/customer-journey-map/examples/sample.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/customer-journey-map/template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/discovery-interview-prep/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/opportunity-solution-tree/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/opportunity-solution-tree/examples/sample.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/opportunity-solution-tree/template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/roadmap-planning/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/roadmap-planning/examples/sample-industrial.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/roadmap-planning/examples/sample.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/roadmap-planning/template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/user-story-mapping/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/user-story-mapping/examples/sample-industrial.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/user-story-mapping/examples/sample.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-discovery/user-story-mapping/template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/agile-product-owner/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/agile-product-owner/assets/sprint_planning_template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/agile-product-owner/assets/user_story_template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/agile-product-owner/references/sprint-planning-guide.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/agile-product-owner/references/user-story-templates.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/agile-product-owner/scripts/user_story_generator.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/organic-growth-advisor/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/organic-growth-advisor/examples/sample.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/organic-growth-advisor/template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/pm-skill-creator/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/prd-development/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/prd-development/examples/sample.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/prd-development/template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/prioritization-advisor/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-manager-toolkit/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-manager-toolkit/assets/prd_template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-manager-toolkit/assets/rice_input_template.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-manager-toolkit/references/frameworks.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-manager-toolkit/references/input-output-examples.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-manager-toolkit/references/prd_templates.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-manager-toolkit/scripts/customer_interview_analyzer.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-manager-toolkit/scripts/rice_prioritizer.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-strategist/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-strategist/assets/okr_template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-strategist/references/examples/sample_growth_okrs.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-strategist/references/okr_framework.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-strategist/references/strategy_types.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/product-strategist/scripts/okr_cascade_generator.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/user-story-mapping/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/user-story-mapping/examples/sample.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/product-management/user-story-mapping/template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/security-review/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/slides/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/slides/references/copywriting-formulas.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/slides/references/create.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/slides/references/html-template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/slides/references/layout-patterns.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/slides/references/slide-strategies.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/streamdown/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/streamdown/assets/examples/basic-streaming.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/streamdown/assets/examples/custom-security.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/streamdown/assets/examples/full-featured.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/streamdown/assets/examples/static-mode.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/streamdown/assets/examples/with-caret.tsx` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/streamdown/references/api.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/streamdown/references/features.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/streamdown/references/plugins.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/streamdown/references/security.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/streamdown/references/styling.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/CHANGELOG.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/_contributing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/_sections.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/_template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/advanced-full-text-search.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/advanced-jsonb-indexing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/conn-idle-timeout.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/conn-limits.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/conn-pooling.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/conn-prepared-statements.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/data-batch-inserts.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/data-n-plus-one.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/data-pagination.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/data-upsert.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/lock-advisory.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/lock-deadlock-prevention.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/lock-short-transactions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/lock-skip-locked.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/monitor-explain-analyze.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/monitor-pg-stat-statements.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/monitor-vacuum-analyze.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/query-composite-indexes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/query-covering-indexes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/query-index-types.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/query-missing-indexes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/query-partial-indexes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/schema-constraints.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/schema-data-types.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/schema-foreign-key-indexes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/schema-lowercase-identifiers.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/schema-partitioning.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/schema-primary-keys.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/security-privileges.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/security-rls-basics.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase-postgres-best-practices/references/security-rls-performance.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase/CHANGELOG.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase/assets/feedback-issue-template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/supabase/references/skill-feedback.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/systematic-debugging/CREATION-LOG.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/systematic-debugging/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/systematic-debugging/condition-based-waiting-example.ts` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/systematic-debugging/condition-based-waiting.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/systematic-debugging/defense-in-depth.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/systematic-debugging/find-polluter.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/systematic-debugging/root-cause-tracing.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/systematic-debugging/test-academic.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/systematic-debugging/test-pressure-1.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/systematic-debugging/test-pressure-2.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/systematic-debugging/test-pressure-3.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/tdd-workflow/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/test-driven-development/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/test-driven-development/writing-good-tests.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/tsbs-benchmark/LICENSE` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/tsbs-benchmark/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/tsbs-benchmark/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/tsbs-benchmark/claude/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/tsbs-benchmark/codex/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/tsbs-benchmark/codex/agents/openai.yaml` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ucp/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/LICENSE.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/ArsenalSC-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/ArsenalSC-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/BigShoulders-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/BigShoulders-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/BigShoulders-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Boldonse-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Boldonse-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/BricolageGrotesque-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/BricolageGrotesque-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/BricolageGrotesque-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/CrimsonPro-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/CrimsonPro-Italic.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/CrimsonPro-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/CrimsonPro-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/DMMono-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/DMMono-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/EricaOne-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/EricaOne-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/GeistMono-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/GeistMono-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/GeistMono-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Gloock-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Gloock-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/IBMPlexMono-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/IBMPlexMono-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/IBMPlexMono-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/IBMPlexSerif-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/IBMPlexSerif-BoldItalic.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/IBMPlexSerif-Italic.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/IBMPlexSerif-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/InstrumentSans-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/InstrumentSans-BoldItalic.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/InstrumentSans-Italic.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/InstrumentSans-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/InstrumentSans-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/InstrumentSerif-Italic.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/InstrumentSerif-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Italiana-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Italiana-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/JetBrainsMono-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/JetBrainsMono-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/JetBrainsMono-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Jura-Light.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Jura-Medium.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Jura-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/LibreBaskerville-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/LibreBaskerville-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Lora-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Lora-BoldItalic.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Lora-Italic.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Lora-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Lora-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/NationalPark-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/NationalPark-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/NationalPark-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/NothingYouCouldDo-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/NothingYouCouldDo-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Outfit-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Outfit-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Outfit-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/PixelifySans-Medium.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/PixelifySans-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/PoiretOne-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/PoiretOne-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/RedHatMono-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/RedHatMono-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/RedHatMono-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Silkscreen-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Silkscreen-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/SmoochSans-Medium.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/SmoochSans-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Tektur-Medium.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Tektur-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/Tektur-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/WorkSans-Bold.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/WorkSans-BoldItalic.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/WorkSans-Italic.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/WorkSans-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/WorkSans-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/YoungSerif-OFL.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/canvas-fonts/YoungSerif-Regular.ttf` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/references/canvas-design-system.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/references/shadcn-accessibility.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/references/shadcn-components.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/references/shadcn-theming.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/references/tailwind-customization.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/references/tailwind-responsive.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/references/tailwind-utilities.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/scripts/.coverage` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/scripts/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/scripts/shadcn_add.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/scripts/tailwind_config_gen.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/scripts/tests/coverage-ui.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/scripts/tests/requirements.txt` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/scripts/tests/test_shadcn_add.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-styling/scripts/tests/test_tailwind_config_gen.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/app-interface.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/catalog-summary.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/charts.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/colors.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/data-provenance.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/google-font-licenses.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/google-fonts.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/icons.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/landing.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/motion.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/phosphor-icons-upstream.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/products.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/react-performance.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/angular.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/astro.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/avalonia.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/flutter.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/html-tailwind.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/javafx.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/jetpack-compose.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/laravel.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/nextjs.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/nuxt-ui.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/nuxtjs.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/react-native.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/react.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/shadcn.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/svelte.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/swiftui.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/threejs.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/uno.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/uwp.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/vue.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/winui.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/stacks/wpf.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/styles.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/typography.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/ui-reasoning.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/data/ux-guidelines.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/references/pro-rules.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/references/quick-reference.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/core.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/design_system.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/reasoning_contract.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/search.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/catalogs/google-api.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/catalogs/google-catalog.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/catalogs/google-existing.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/catalogs/google-metadata.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/catalogs/google-overrides.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/catalogs/icons-curated.csv` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/catalogs/phosphor-core.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/catalogs/phosphor-package.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/catalogs/phosphor-react-exports.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/catalogs/phosphor-react-package.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/relevance-baseline.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/relevance-cases.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/fixtures/relevance-thresholds.json` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_catalog_refresh.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_catalog_summary_line_endings.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_core.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_core_data_quality.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_data_contracts.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_design_system_mode.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_design_system_stack.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_native_desktop_stack_freshness.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_relevance_evaluator.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_skill_script_paths.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_style_taxonomy.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_text_layout_resilience.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/tests/test_web_stack_freshness.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/ui-ux-pro-max/scripts/validate_data.py` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/AGENTS.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/rules/_sections.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/rules/_template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/rules/architecture-avoid-boolean-props.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/rules/architecture-compound-components.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/rules/patterns-children-over-render-props.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/rules/patterns-explicit-variants.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/rules/react19-no-forwardref.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/rules/state-context-interface.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/rules/state-decouple-implementation.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-composition-patterns/rules/state-lift-state.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-deploy/Archive.zip` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-deploy/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-deploy/resources/deploy-codex.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-deploy/resources/deploy.sh` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/AGENTS.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/_sections.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/_template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/advanced-effect-event-deps.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/advanced-event-handler-refs.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/advanced-init-once.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/advanced-use-latest.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/async-api-routes.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/async-cheap-condition-before-await.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/async-defer-await.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/async-dependencies.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/async-parallel.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/async-suspense-boundaries.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/bundle-analyzable-paths.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/bundle-barrel-imports.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/bundle-conditional.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/bundle-defer-third-party.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/bundle-dynamic-imports.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/bundle-preload.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/client-event-listeners.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/client-localstorage-schema.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/client-passive-event-listeners.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/client-swr-dedup.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-batch-dom-css.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-cache-function-results.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-cache-property-access.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-cache-storage.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-combine-iterations.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-early-exit.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-flatmap-filter.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-hoist-regexp.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-index-maps.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-length-check-first.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-min-max-loop.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-request-idle-callback.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-set-map-lookups.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/js-tosorted-immutable.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rendering-activity.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rendering-animate-svg-wrapper.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rendering-conditional-render.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rendering-content-visibility.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rendering-hoist-jsx.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rendering-hydration-no-flicker.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rendering-hydration-suppress-warning.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rendering-resource-hints.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rendering-script-defer-async.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rendering-svg-precision.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rendering-usetransition-loading.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-defer-reads.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-dependencies.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-derived-state-no-effect.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-derived-state.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-functional-setstate.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-lazy-state-init.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-memo-with-default-value.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-memo.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-move-effect-to-event.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-no-inline-components.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-simple-expression-in-memo.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-split-combined-hooks.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-transitions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-use-deferred-value.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/rerender-use-ref-transient-values.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/server-after-nonblocking.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/server-auth-actions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/server-cache-lru.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/server-cache-react.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/server-dedup-props.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/server-hoist-static-io.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/server-no-shared-module-state.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/server-parallel-fetching.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/server-parallel-nested-fetching.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-best-practices/rules/server-serialization.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/AGENTS.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/README.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/_sections.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/_template.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/animation-derived-value.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/animation-gesture-detector-press.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/animation-gpu-properties.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/design-system-compound-components.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/fonts-config-plugin.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/imports-design-system-folder.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/js-hoist-intl.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/list-performance-callbacks.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/list-performance-function-references.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/list-performance-images.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/list-performance-inline-objects.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/list-performance-item-expensive.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/list-performance-item-memo.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/list-performance-item-types.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/list-performance-virtualize.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/monorepo-native-deps-in-app.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/monorepo-single-dependency-versions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/navigation-native-navigators.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/react-compiler-destructure-functions.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/react-compiler-reanimated-shared-values.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/react-state-dispatcher.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/react-state-fallback.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/react-state-minimize.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/rendering-no-falsy-and.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/rendering-text-in-text-component.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/scroll-position-no-state.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/state-ground-truth.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/ui-expo-image.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/ui-image-gallery.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/ui-measure-views.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/ui-menus.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/ui-native-modals.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/ui-pressable.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/ui-safe-area-scroll.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/ui-scrollview-content-inset.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/vercel-react-native-skills/rules/ui-styling.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/verification-before-completion/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/verification-loop/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/web-design-guidelines/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/workflow/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/wrangler/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/writing-plans/SKILL.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |
| `skills/writing-plans/plan-document-reviewer-prompt.md` | TIDAK DIPERIKSA satu per satu (1.802 berkas — diperiksa sebagai KEBIJAKAN di W10: ukuran, pemindaian pola kredensial, kewajaran dibawa) |

</details>

---

## 6. Temuan W1–W10

Tingkat: `KRITIS` (bisa merusak uang/data/keamanan atau memblokir coding) · `MAYOR` (pasti menimbulkan kerja ulang atau lubang nyata) · `MINOR` · `CATATAN`.

### W1 — Dokumen fondasi

**W1-01 · MAYOR · `docs/README.md` (seluruh berkas, 16 baris, sebelum perbaikan)**

- **Bukti:** `cat docs/README.md` mengatakan *"Folder ini **hanya berisi `README.md` ini** … belum ada artefak fondasi"* dan *"Jangan membuat file manual di sini sebelum Tahap 1 — agent akan memandu diskusi dulu."* Kenyataannya `ls docs/` menunjukkan 7 dokumen fondasi lengkap + 3 sub-folder, dan `PROJECT_STATE.md` berkata `STATUS: CODING_AKTIF`.
- **Dampak:** berkas ini adalah pintu masuk folder `/docs`. Agent baru yang membacanya lebih dulu akan menyimpulkan fondasi belum ada dan bisa **memulai ulang Tahap 1 Discovery** — mengulang kerja berhari-hari, atau lebih buruk, menimpa dokumen yang sudah dikunci. Ini persis kelas kesalahan yang sudah pernah terjadi: reviewer putaran 1 salah menyimpulkan "BELUM SIAP" karena membaca keadaan yang keliru.
- **Perbaikan:** `docs/README.md` ditulis ulang → daftar 7 dokumen nyata, mana yang **dikunci** vs berlaku, isi sub-folder, dan 3 perintah pemeriksa.
- **Status:** **SUDAH DIPERBAIKI.**

**W1-02 · CATATAN · `docs/TECH_SPEC.md` baris 173 vs `docs/ROADMAP.md` T1-18 (`:296`)**

- **Bukti:** TECH_SPEC menulis status pesanan `draf → dikirim → dimasak → siap → lunas / batal`; ROADMAP T1-18 DoD menulis `draf → dikirim → dimasak → siap → dibayar → selesai; dibatalkan`. Tiga nama berbeda (`lunas` vs `dibayar`+`selesai`, `batal` vs `dibatalkan`).
- **Dampak:** nyata tapi kecil — agent coding memakai nama enum dari salah satu dokumen; kalau salah, uji transisi (T1-18) dan laporan (T7-12) memakai nilai yang tidak ada. Bukan kerugian uang, tapi kerja ulang.
- **Perbaikan yang diusulkan (tidak saya kerjakan):** TECH_SPEC **dikunci**, jadi nama resminya adalah yang di TECH_SPEC §4.3. Usul: ubah DoD T1-18 agar memakai persis `draf → dikirim → dimasak → siap → lunas`, `batal`. Saya tidak mengubahnya karena menyentuh **alur pesanan** (keputusan pemilik yang dilarang saya sentuh menurut bagian 2 instruksi). Besar pekerjaan: 5 menit.
- **Status:** **DIUSULKAN** (butuh persetujuan karena menyentuh alur pesanan).

**W1-03 · CATATAN · `docs/PRD.md` baris 44 "Dapur / Bar" vs `docs/TECH_SPEC.md` baris 148 peran `dapur`**

- **Bukti:** PRD menyebut peran **"Dapur / Bar"**; TECH_SPEC daftar peran resmi memakai `dapur` saja, dan ROADMAP T4-02 membuat layar bar terpisah.
- **Dampak:** tidak ada lubang teknis — satu peran, dua layar. Laporan cross-check Tahap 6 mengklaim hal ini "sudah disamakan"; yang disamakan adalah teksnya, bukan jumlah peran. Tidak menimbulkan kerugian.
- **Status:** **SENGAJA TIDAK DIUBAH** — PRD dikunci, dan tidak ada dampak nyata.

**Yang saya coba untuk mematahkan W1 dan TIDAK berhasil (3 hal tersulit):**

1. **Urutan hitung uang.** Saya bandingkan 3 tempat: `TECH_SPEC.md` baris 297 (ART-3), `TECH_SPEC.md` baris 390 (log keputusan K), dan `ROADMAP.md` T1-16 (`:275`). Ketiganya menyebut urutan yang **identik**: subtotal → diskon → PB1 → service → pembulatan, dengan pajak & service dihitung dari subtotal **setelah** diskon. Tidak ada kontradiksi.
2. **Nilai PB1/service.** Saya cari apakah ada angka pajak yang ditulis mati (hard-coded) di dokumen mana pun yang bisa bertabrakan dengan keputusan "PB1 10%, service 5% = nilai awal yang bisa diubah". Yang saya temukan hanya di `prototipe/` (contoh tampilan, memang angka contoh) dan di TERTANGGUH T-005 sebagai nilai awal. Konsisten.
3. **Setiap `Ref: DOK §N` menunjuk bagian nyata.** Saya urai semua judul bagian TECH_SPEC (19 bagian), PRD (11), AGENT_OPERATING_GUIDE (14), lalu cocokkan dengan seluruh rujukan `§` di 150 tugas. **0 rujukan mati.** Ini yang paling saya harapkan menemukan sesuatu; tidak ketemu.

---

### W2 — Klaim vs bukti

| # | Klaim | Sumber klaim | Uji ulang saya | Putusan |
|---|---|---|---|---|
| 1 | "146 tugas" | `ROADMAP.md` baris 1418, `STATUS.md` | `grep -c '^- \[[ x]\] T'` via parser sendiri → **146** (sebelum saya menambah 4) | **TERBUKTI** |
| 2 | Sebaran fase F0 10 · F1 22 · F2 12 · F3 16 · F4 10 · F5 12 · F6 8 · F7 12 · F8 14 · F9 12 · F10 8 · F11 10 | `ROADMAP.md` baris 1418 | dihitung ulang per fase → **cocok semuanya**, dan nomor tugas berurutan 1..n tanpa lompatan di **setiap** fase | **TERBUKTI** |
| 3 | "setiap tugas ber-7 atribut" | `ROADMAP.md` baris 9 | parser saya memeriksa 7 atribut × 150 tugas → **0 atribut hilang, 0 pengisi kosong** | **TERBUKTI** |
| 4 | "118 tugas bertanda ⚠️" | keluaran `alat/periksa-roadmap.py` | **TIDAK TERBUKTI seperti tertulis.** 118 adalah jumlah **kemunculan lambang ⚠️ di seluruh dokumen** (`teks.count('⚠️')`), bukan jumlah tugas. Jumlah **tugas** yang mengandung ⚠️ = **69** (sebelum perbaikan saya; 66 setelah pembersihan tanda basi + 4 tugas baru). Lambang muncul 2× per tugas (judul + baris Risiko) plus di judul fase. | **TIDAK TERBUKTI** (lihat W3-02) |
| 5 | "9 rujukan ❓ semua sah" | keluaran `alat/periksa-roadmap.py` | Sah dalam arti "ID-nya ada di TERTANGGUH" — **ya**. Tapi 5 dari 9 menunjuk butir yang sudah **SELESAI**. Pemeriksa lama tidak membedakan. | **TERBUKTI sebagian** — lihat W3-01 |
| 6 | "seluruh entitas Data Model punya task" | `ROADMAP.md` baris 1409 (checklist tercentang `[x]`) | **TIDAK TERBUKTI.** 3 dari 31 tabel di TECH_SPEC §4 (`kategori_menu`, `stok_bahan`, `stok_pergerakan`) tidak pernah disebut dengan nama resminya di blok tugas mana pun — hanya nama pendek (`kategori`, `stok`). | **TIDAK TERBUKTI** → diperbaiki (W1/W3-04) |
| 7 | "26 RPC + `hitung_total`" dipetakan ke tugas | `DECISIONS_LOG.md`, tabel Peta RPC di ROADMAP | Saya tarik nama RPC langsung dari TECH_SPEC §5 dengan regex → **33 nama** `rpc/...`, bukan 26. Semuanya memang punya jejak (23 lewat tabel peta, 10 disebut langsung di tugas). Angka 26 salah hitung, tapi **cakupannya tetap lengkap**. | **TIDAK TERBUKTI** (angkanya) / cakupan **TERBUKTI** |
| 8 | "10 Area Berisiko ART-1…ART-10 punya tugas bertanda ⚠️" | `ROADMAP.md` baris 1411 | diuji: tiap ART disebut di dalam blok tugas **dan** minimal satu di antaranya bertanda ⚠️ → **10/10 lolos** | **TERBUKTI** |
| 9 | "4 temuan cross-check Tahap 6 semuanya sudah diperbaiki" | `PROJECT_STATE.md`, `docs/uji/LAPORAN_CROSS_CHECK_TAHAP6.md` | Saya periksa satu per satu: (1) bentuk jawaban RPC → `AGENT_OPERATING_GUIDE.md` §6 kini memakai `berhasil/kode/pesan/data` sama dengan TECH_SPEC §5 ✔; (2) tabel Peta RPC → ada di ROADMAP ✔; (3) T-010 & T-011 → ada di TERTANGGUH ✔; (4) istilah peran → lihat W1-03, teksnya disamakan ✔ | **TERBUKTI** |
| 10 | "temuan review putaran 1 sudah ditindaklanjuti: `.gitignore` diperluas" | `PROJECT_STATE.md`, `DECISIONS_LOG.md` | `cat .gitignore` → memuat `.env`, `.env.*`, `*.local`, `dist/`, `.wrangler/`, dst ✔. Tapi lihat **W5-02**: `.env.*` juga mengabaikan `.env.example` yang justru **harus** ikut repo. | **TERBUKTI dengan cacat baru** |
| 11 | "`skills/` 56 direktori, 26M" | `skills/README.md` baris 1 | `ls -d skills/*/ \| wc -l` → **56** · `du -sh skills` → **26M** | **TERBUKTI** |
| 12 | "87 berkas SKILL.md tersedia" | keluaran `alat/mulai-sesi.py` | tidak saya hitung ulang secara independen | **TIDAK BISA DIVERIFIKASI** (tidak saya uji; bukan angka yang berisiko) |

---

### W3 — Pemeriksa otomatis

**Keadaan awal (sebelum saya menyentuh apa pun) — keluaran persis:**

```
$ python3 _sistem/validate_system.py
SYSTEM-BUILDING-APLIKASI VALIDATOR: PASS        (exit 0)

$ python3 alat/periksa-roadmap.py
PERIKSA ROADMAP — Resto Barokah
  Tugas        : 146  (T0:10, T1:22, T10:8, T11:10, T2:12, T3:16, T4:10, T5:12, T6:8, T7:12, T8:14, T9:12)
  Atribut 7x   : lengkap
  Fitur M1-M12 : lengkap
  ⚠️ DECISIONS : 118 tugas bertanda
  ❓ tertangguh : 9 rujukan (semua sah)

HASIL: LOLOS — semua pemeriksaan roadmap terpenuhi.   (exit 0)
```

Keduanya **LOLOS/PASS** — dan justru itu masalahnya: keduanya lolos sementara fondasinya memuat satu cacat KRITIS. Berikut kenapa.

**W3-01 · KRITIS · `docs/ROADMAP.md` baris 117, 359, 431, 993, 1049, 1144, 1368 (sebelum perbaikan)**

- **Perintah:** `grep -n '❓ T-00[1-8]' docs/ROADMAP.md`
- **Keluaran yang terlihat:**
  ```
  117:- [ ] T0-09 — Deploy halaman kosong ke Cloudflare Workers + Static Assets ❓ T-008
  359:- [ ] T2-03 — Pembuatan & pengelolaan akun pegawai oleh admin ❓ T-004
  431:- [ ] T2-11 — PWA dasar: manifest + ikon + service worker ❓ T-001
  993:## Fase 8 — Katalog pelanggan & voucher undang-teman (M10) ⚠️ ART-5, ART-10 ❓ T-007
  1049:- [ ] T8-07 — Verifikasi email + anti email sekali-pakai + normalisasi Gmail ⚠️ ❓ T-007
  1144:- [ ] T9-03 — Pengaturan operasional (pajak, service, pembulatan, cara pesan, struk) ❓ T-005
  1368:- [ ] T11-07 — Deploy produksi + domain + HTTPS ❓ T-008
  ```
  Sementara di `docs/TERTANGGUH.md` tabel **"Butir selesai"**: T-001, T-004, T-005, T-006, T-007, T-008, T-009 semuanya **sudah ditutup 2026-09-16 atas persetujuan pemilik**.
- **Kenapa ini KRITIS:** `docs/AGENT_OPERATING_GUIDE.md` §13 aturan 8 berbunyi *"Tugas ROADMAP yang menunggu butir tertangguh ditandai `❓ T-xxx` dan **dilewati**"*. Jadi agent pembangun yang patuh aturan akan **melewati T0-09 (deploy halaman kosong ke Cloudflare)** — tugas Fase 0 — karena menunggu jawaban yang **sudah Anda berikan**. Efek berantai: T11-07 (deploy produksi) juga dilewati, T9-03 (pajak & service) dilewati, seluruh **judul Fase 8** bertanda ❓ sehingga fase katalog & voucher bisa dianggap tertunda seluruhnya. Fondasinya tampak siap, tapi pelaksanaannya akan macet di tugas ke-9 tanpa ada yang tahu kenapa.
- **Kenapa pemeriksa lama tidak menangkapnya:** `alat/periksa-roadmap.py` baris 117-121 hanya menguji `tanda_tanya - ids_tertangguh` (ID ada atau tidak di berkas), dan `ids_tertangguh` diambil dari **seluruh** tabel termasuk tabel "Butir selesai". Butir yang sudah dijawab tetap dianggap "sah".
- **Perbaikan:** 5 tanda ❓ basi dihapus dan diganti komentar HTML yang mencatat kapan & apa jawabannya (mis. `<!-- T-008 sudah ditutup 2026-09-16: pakai alamat gratis *.workers.dev -->`), supaya jejaknya tidak hilang. Satu tanda di T8-07 diganti menjadi `❓ T-011` (privasi pelanggan) yang memang **masih terbuka** dan memang menghalangi tugas itu. Pemeriksa baru saya sekarang menangkap kelas cacat ini.
- **Besar pekerjaan:** 20 menit. **Status: SUDAH DIPERBAIKI.**

**W3-02 · MINOR · `alat/periksa-roadmap.py` baris 139**

- **Perintah & keluaran:** `python3 alat/periksa-roadmap.py` → `⚠️ DECISIONS : 118 tugas bertanda`. Kode di baris 139: `print(f"  ⚠️ DECISIONS : {teks.count('⚠️')} tugas bertanda")`.
- **Bukti tandingan:** hitungan per **blok tugas** memberi **69** (kini 66), bukan 118. Lambang dihitung ganda karena muncul di judul tugas **dan** di baris "Risiko & mitigasi", ditambah di judul fase.
- **Dampak:** angka ini masuk ke `PROJECT_STATE.md` dan ke laporan ke pemilik sebagai fakta. Pemilik diberi gambaran bahwa 118 dari 146 tugas (81%) menyentuh area berisiko, padahal yang benar 47%. Tidak merusak kode, tapi merusak dasar penilaian risiko.
- **Perbaikan yang diusulkan:** ganti label menjadi `kemunculan lambang` atau hitung per blok tugas. Saya **tidak** mengubahnya — instruksi bagian 2 melarang saya menyentuh pemeriksa lama, dan mengubah label bukan memperbaiki cacat, jadi lebih jujur dilaporkan. Besar pekerjaan: 5 menit.
- **Status: DIUSULKAN.**

**W3-03 · MINOR · `alat/periksa-roadmap.py` baris 34-47 (daftar entitas & RPC ditulis tangan)**

- **Bukti:** daftar `ENTITAS` memuat `"kategori"`, `"stok"`, `"pengguna"` — nama pendek yang **bukan** nama tabel di TECH_SPEC §4 (`kategori_menu`, `stok_bahan`, `stok_pergerakan`). Daftar `RPC` hanya memuat 9 dari 33 RPC. Pengujiannya `if e not in teks` — mencari di **seluruh** teks dokumen, jadi satu penyebutan di tabel ringkasan sudah cukup untuk lolos.
- **Dampak:** gerbangnya menyala hijau tanpa benar-benar menjamin tiap entitas punya tugas. Inilah yang membuat W2-klaim-6 lolos selama ini.
- **Perbaikan:** saya tidak menyentuh pemeriksa lama; pemeriksa baru saya menarik daftar entitas & RPC **langsung dari TECH_SPEC** dengan regex (31 tabel, 33 RPC), sehingga tidak bisa basi, dan menuntut penyebutan **di dalam blok tugas**, bukan di mana saja.
- **Status: SUDAH DITUTUP LEWAT PEMERIKSA BARU** (pemeriksa lama dibiarkan apa adanya — DIUSULKAN untuk diperbaiki sesi pembangun).

**W3-04 · MAYOR · `docs/ROADMAP.md` baris 195 (T1-07), `:643` (T4-06), `:652` (T4-07)**

- **Bukti:** `Ref: TECH_SPEC §4 (tabel: kategori, menu_item, menu_varian, menu_tambahan, menu_cabang, stok)`. Nama `kategori` dan `stok` **tidak ada** di TECH_SPEC §4.2 — nama resminya `kategori_menu`, `stok_bahan`, `stok_pergerakan`.
- **Dampak:** T1-07 adalah tugas **migrasi database**. Agent coding yang menuruti ROADMAP akan membuat tabel bernama `kategori` dan `stok`; seluruh RLS, RPC, laporan, dan uji yang ditulis belakangan merujuk nama TECH_SPEC → migrasi harus diulang setelah puluhan tugas terlanjur dibangun di atasnya. Ini kerja ulang mahal di Area Berisiko Tinggi (ART-1).
- **Perbaikan:** ketiga baris Ref diselaraskan ke nama resmi §4.2, dengan menyebut §4.2 (bukan §4) supaya lebih tepat.
- **Besar pekerjaan:** 10 menit. **Status: SUDAH DIPERBAIKI.**

**Pemeriksa baru saya — `alat/periksa-fondasi-independen.py`**

Ditulis dari nol, **tidak menyalin logika** pemeriksa lama. Perbedaan rancangan yang disengaja:

| Hal | Pemeriksa lama | Pemeriksa saya |
|---|---|---|
| Cakupan entitas/RPC | daftar ditulis tangan, dicari di seluruh teks | ditarik **langsung dari TECH_SPEC** dengan regex; dituntut muncul **di dalam blok tugas** |
| `Ref` | tidak diperiksa sama sekali | judul bagian tiap dokumen diurai, tiap `§N` dicocokkan |
| TERTANGGUH | satu arah (ID ada/tidak) | **dua arah** + mendeteksi tanda ❓ yang menunjuk butir **sudah selesai** + butir terbuka yang tidak dijaga tugas mana pun + batas 12 butir + kolom tenggat terbaca |
| Nomor tugas | tidak diperiksa | nomor ganda + fase bolong + urutan 1..n per fase |
| Pengisi kosong | tidak diperiksa | atribut berisi `TBD`/`-`/terlalu pendek ditolak |
| Klaim jumlah | tidak diperiksa | klaim "= **N tugas**" dan "F*n*" di dokumen diadu dengan hitungan nyata |

Keluaran setelah semua perbaikan:

```
$ python3 alat/periksa-fondasi-independen.py
PERIKSA FONDASI INDEPENDEN — Resto Barokah
  · tugas terbaca: 150
  · fase: F0=10, F1=22, F2=12, F3=16, F4=10, F5=12, F6=8, F7=12, F8=14, F9=12, F10=12, F11=10
  · atribut hilang: 0 · pengisi kosong: 0
  · tugas ⚠️: 66 (tanpa kewajiban log: 0)
  · rujukan § mati: 0
  · tertangguh terbuka: 6 · selesai: 8 · dirujuk roadmap: 6
  · entitas TECH_SPEC §4 terbaca: 31 · tanpa tugas: 0
  · RPC TECH_SPEC §5 terbaca: 33 · tanpa tugas: 0

HASIL: BERSIH — tidak ada temuan dari pemeriksa independen.   (exit 0)
```

**Bukti gerbangnya benar-benar menyala (uji mutasi — tiap mutasi dikembalikan setelah diuji):**

| Mutasi | Hasil |
|---|---|
| hapus atribut `**Verifikasi:**` dari T0-01 | `TEMUAN (1): ROADMAP.md:45 T0-01: atribut **Verifikasi** hilang` → exit 1 ✔ |
| ubah `TECH_SPEC §1` jadi `TECH_SPEC §99` di T0-01 | `TEMUAN (1): ROADMAP.md:45 T0-01: Ref menunjuk TECH_SPEC §99 yang TIDAK ADA` → exit 1 ✔ |
| ubah nomor T0-02 jadi T0-01 (nomor ganda) | `TEMUAN (2): nomor tugas GANDA T0-01 (sudah ada di baris 45)` + `Fase 0: nomor tugas tidak berurutan` → exit 1 ✔ |
| kontrol negatif: kembalikan semuanya | `HASIL: BERSIH` → exit 0 ✔ |

Pemeriksa ini juga **menangkap kesalahan saya sendiri**: saat saya menambah butir T-012 & T-013 ke buku tunggu tanpa menautkannya ke tugas, ia langsung berteriak *"TERTANGGUH T-012 terbuka tetapi tidak ada satu pun tugas ROADMAP yang menandainya ❓ — tenggatnya tidak dijaga oleh apa pun"*. Saya perbaiki, lalu hijau.

**Keadaan akhir ketiga pemeriksa (setelah semua perbaikan saya):**

```
python3 _sistem/validate_system.py          → PASS                       (exit 0)
python3 alat/periksa-roadmap.py             → LOLOS — 150 tugas          (exit 0)
python3 alat/periksa-fondasi-independen.py  → BERSIH                     (exit 0)
```

Tidak satu pun pemeriksa saya lemahkan. Yang saya lakukan hanya **menambah** satu pemeriksa yang lebih galak.

---

### W4 — Mutu isi tugas (uji tangan)

**Seluruh Fase 0 (T0-01…T0-10), satu per satu:**

| Tugas | Tujuan masuk akal? | Berkas wajar? | DoD bisa diuji? | Verifikasi bisa dijalankan? | Catatan |
|---|---|---|---|---|---|
| T0-01 repo Vite | ya | ya | ya (`npm run dev`, `tsc --noEmit`, folder ada) | ya | — |
| T0-02 ESLint/Prettier/TS ketat | ya | ya | ya (3 perintah exit 0) | ya | — |
| T0-03 token desain 10 tema | ya | ya | ya | **sebagian** — Verifikasi menyebut `prototipe/uji-kontras.py` versi aplikasi "dibuat di T0-04", jadi T0-03 tidak bisa diverifikasi penuh sampai T0-04 selesai | urutan sedikit terbalik, tapi tercatat jujur di dalam tugasnya |
| T0-04 komponen dasar + uji kontras | ya | ya | ya (≥95% pemeriksaan kontras lulus, target sentuh ≥44px) | **sebagian** — "tangkapan layar 1 halaman contoh" tidak bisa dilakukan agent (TECH_SPEC §1 sendiri mengakui peramban tidak bisa dipasang) | lihat W4-01 |
| T0-05 rahasia & env | ya | ya | ya | **ada cacat** → lihat **W5-02** | |
| T0-06 README aplikasi | ya | ya | ya | ya | — |
| T0-07 CI dasar | ya | ya | ya | ya (termasuk uji negatif: sengaja bikin lint gagal → CI merah — bagus) | — |
| T0-08 proyek Supabase | ya | ya | ya (`select 1` berhasil) | ya | **lihat W5-01**: tidak ada langkah membuat akun/proyek |
| T0-09 deploy Cloudflare | ya | ya | ya (URL publik, HTTPS, `curl -I` 200) | ya | sebelumnya **terblokir** oleh ❓ basi (W3-01) |
| T0-10 Vitest + pemeriksa roadmap | ya | ya | ya | ya | — |

**W4-01 · MINOR · `docs/ROADMAP.md` T0-04 (`:101`), T4-03, T9-10, T11-03**

- **Bukti:** langkah Verifikasi menyebut *"tangkapan layar 1 halaman contoh"* (T0-04), *"foto bukti"* keterbacaan dari jarak 2 meter (T4-03), *"bukti berupa tangkapan layar"* (T9-10), *"foto struk & tiket nyata + lembar hasil bertanda tangan"* (T11-03). Sementara `docs/TECH_SPEC.md` baris 44-46 mengaku jujur: *"lingkungan kerja agent saat ini **tidak bisa memasang peramban** untuk tangkapan layar, dan Playwright juga gagal dipasang di sini."*
- **Dampak:** tugas-tugas ini **tidak bisa ditandai selesai secara jujur** oleh agent. Risikonya bukan teknis melainkan budaya: agent yang dikejar mode maraton akan mencentang `[x]` tanpa bukti, dan prinsip "tidak ada yang cacat" jadi omong kosong. Untuk T11-03 (uji cetak nyata) memang wajar butuh manusia — dan tugas itu sudah bilang "STOP & tanya pemilik", bagus.
- **Perbaikan yang diusulkan:** tambahkan di tiap tugas itu satu kalimat *"bukti visual dikerjakan pemilik/penguji manusia; agent menandai tugas `[x]` hanya setelah bukti diterima"*. Saya tidak menambahkannya sendiri karena menyentuh definisi selesai di 4 tugas dan lebih baik diputuskan sesi pembangun sekaligus. Besar pekerjaan: 15 menit.
- **Status: DIUSULKAN.**

**15 tugas sampel acak (seed 20260916) — hasil pemeriksaan tangan:**

Saya baca penuh: `T1-01, T1-18, T2-09, T3-01, T4-02, T4-03, T4-04, T7-05, T7-08, T8-10, T8-11, T10-01, T10-02, T11-01, T11-08`.

- **Kualitasnya tinggi dan konsisten.** Contoh yang benar-benar bagus: T4-04 mensyaratkan *"uji SQL dua pemanggilan paralel → satu perubahan"* (menguji balapan, bukan cuma jalur bahagia); T1-18 mensyaratkan *"uji SQL menolak 4 transisi terlarang (mis. draf → dibayar)"* (uji negatif); T11-08 memakai angka tiruan 70%/90% supaya peringatan batas gratis benar-benar diuji.
- **Kalau dikerjakan persis, hasilnya benar?** Untuk 14 dari 15: ya. Satu pengecualian: **T1-18** memakai nama status yang berbeda dari TECH_SPEC (lihat W1-02) — dikerjakan persis akan menghasilkan enum yang tidak cocok dokumen terkunci.
- **Langkah tersembunyi?** T3-01 menuntut *"waktu muat awal < 3 detik"* dengan 200 item tanpa menyebut di jaringan seperti apa; T2-09 menyebut masa diam *"mis. 15 menit kasir"* — kata "mis." berarti nilainya belum diputuskan, tapi tidak ada butir buku tunggu untuknya. Keduanya kecil; saya catat sebagai **CATATAN**, bukan temuan berdampak.

---

### W5 — Kesiapan Fase 0

**W5-01 · MAYOR · `docs/ROADMAP.md` T0-08 (`:108`) dan T0-09 (`:117`)**

- **Perintah:** `grep -n 'akun Cloudflare\|buat akun\|mendaftar\|wrangler login' docs/ROADMAP.md` → **tidak ada satu pun hasil** untuk pembuatan akun.
- **Bukti:** judul T0-08 berbunyi *"Proyek Supabase **dibuat** + klien aman tersambung"*, tetapi DoD-nya hanya *"koneksi uji (`select 1`) berhasil"* dan *"catatan pembuatan proyek ditulis di README"*. Tidak ada langkah: siapa yang membuka supabase.com, siapa yang mendaftar, dengan email apa, siapa yang menyalin URL & kunci anon, di mana kunci itu ditaruh. Hal yang sama untuk T0-09: tidak ada `wrangler login`, tidak ada langkah membuat akun Cloudflare.
- **Dampak nyata (pemilik):** ini **pekerjaan yang hanya bisa dilakukan pemilik** — agent tidak punya email, tidak bisa klik tombol verifikasi, tidak bisa menerima OTP. Pemilik yang nol coding akan berhadapan dengan agent yang bilang "saya butuh URL Supabase" tanpa tahu itu apa dan di mana. Fase 0 akan berhenti di tugas ke-8 menunggu sesuatu yang tidak pernah dijelaskan siapa-siapa. Instruksi bagian 5 memang meminta saya menguji ini secara khusus — dan **jawabannya: tugasnya TIDAK ADA**.
- **Perbaikan yang diusulkan (saya tidak mengerjakan sendiri):** tambah tugas **T0-00 "Pemilik membuat akun Supabase & Cloudflare"** sebelum T0-01, isinya langkah bernomor bahasa awam (buka situs → daftar pakai email X → buat proyek nama Y → pilih wilayah Singapura → salin 2 nilai ini → tempel ke agent), plus penegasan bahwa **kunci `service_role` tidak boleh ditempel ke chat**. Saya **tidak** menambahkannya karena ini menyentuh urutan Fase 0 dan pembagian kerja pemilik-vs-agent — keputusan pemilik. **Besar pekerjaan: 45 menit.**
- **Status: DIUSULKAN** (Mayor, tapi **tidak memblokir** karena tidak merusak apa pun yang sudah ada — ia hanya membuat Fase 0 berhenti menunggu; pemilik bisa menyelesaikannya dalam satu percakapan).

**W5-02 · MINOR · `.gitignore:10` vs `docs/ROADMAP.md` T0-05 (`:95`)**

- **Perintah & keluaran:**
  ```
  $ git check-ignore -v aplikasi/.env.example
  .gitignore:10:.env.*	aplikasi/.env.example        (exit 0 = DIABAIKAN)
  ```
- **Bukti tandingan:** DoD T0-05 mensyaratkan *"`.gitignore` memuat `.env*` **kecuali** `.env.example`"*, dan `.env.example` adalah berkas yang **harus** ikut repo (dia yang memberi tahu agent berikutnya variabel apa saja yang dibutuhkan).
- **Dampak:** saat T0-05 dikerjakan, `git add aplikasi/.env.example` akan diam-diam tidak melakukan apa-apa. Agent bisa mengira sudah meng-commit padahal tidak, dan sesi berikutnya kehilangan daftar variabel. Bukan kebocoran rahasia (arah kesalahannya aman), tapi membuat DoD T0-05 mustahil dipenuhi apa adanya.
- **Perbaikan yang diusulkan:** tambahkan satu baris `!.env.example` di `.gitignore`. Saya **sengaja tidak mengerjakannya**: mengubah `.gitignore` menyentuh area kerahasiaan yang baru saja diperbaiki sesi pembangun putaran lalu, dan satu baris salah tempat bisa membuka celah kunci. Lebih aman dikerjakan sesi pembangun dengan verifikasi `git check-ignore` sesudahnya. Besar pekerjaan: 2 menit.
- **Status: DIUSULKAN.**

**Uji khusus yang diminta instruksi:**

| Pertanyaan | Jawaban | Bukti |
|---|---|---|
| Ada tugas membuat **akun & proyek Supabase**? | **TIDAK** untuk akunnya; **sebagian** untuk proyeknya | W5-01 |
| Ada tugas menjaga **database gratis tetap hidup** saat resto libur panjang? | **YA** | `docs/ROADMAP.md` baris 1301 **T10-08 "Denyut harian + pembersih data sementara"**, dan T0-08 sudah menunjuk ke sana sejak awal: *"proyek gratis 'tidur' setelah 7 hari → mitigasi: dijadwalkan denyut harian (T10-08)"*. `TECH_SPEC.md` baris 349 juga mencantumkannya di tabel batas gratis. **Tapi lihat W5-03.** |

**W5-03 · MINOR · `docs/ROADMAP.md` T10-08 (`:1301`) — letaknya terlalu belakang**

- **Bukti:** T10-08 (denyut anti-tidur) ada di **Fase 10**, sementara proyek Supabase dibuat di **T0-08 (Fase 0)**. Di antara keduanya ada ±120 tugas.
- **Dampak:** kalau pembangunan berhenti lebih dari 7 hari di tengah jalan (libur, pemilik sibuk, menunggu jawaban buku tunggu), proyek Supabase **tertidur** dan sesi berikutnya menemui koneksi gagal tanpa tahu sebabnya. Ini persis skenario "resto libur panjang" yang diminta instruksi — hanya saja fasenya pembangunan, bukan operasi.
- **Perbaikan yang diusulkan:** pindahkan denyut harian ke Fase 1 (setelah pg_cron tersedia) atau tambahkan catatan di T0-08: *"kalau pembangunan jeda >7 hari, bangunkan proyek dari panel Supabase sebelum melanjutkan"*. Saya tidak memindahkannya karena mengubah urutan fase = keputusan pemilik. Besar pekerjaan: 10 menit.
- **Status: DIUSULKAN.**

**Urutan Fase 0 benar?** Ya, dengan satu catatan kecil (T0-03 diverifikasi oleh alat yang baru dibuat di T0-04 — sudah ditulis jujur di dalam tugasnya). Tidak ada langkah yang mustahil **selain** yang butuh akun (W5-01) dan bukti visual (W4-01).

---

### W6 — Sistem kerja agent

**Dibaca:** `_sistem/validate_system.py` (8 cek), `_sistem/templates/*` (10 template), `_sistem/AUDIT_*.md` (4 berkas), `AGENT_SYSTEM.md` (565 baris), `START_DI_SINI.md`, `10_LOG_SESI.md`, `ACCEPTANCE_TESTS.md` (AT-01…AT-09), `ACCEPTANCE_TEST_LOG.md`, `REKAM-KLINIK.md`, `PROFIL_PENGGUNA.md`, `PROMPT_ENTRI_UNIVERSAL.md`, `SYSTEM_MANIFEST.md`, `_Notes.md`, `_salinan-meta/` (2), `_log-sesi/` (2).

**Logika `validate_system.py` masuk akal?** Ya, dan cukup galak — 8 cek anti-cacat yang lahir dari kegagalan nyata (arsip tanpa penanda, angka korpus basi, rujukan menggantung). Yang saya suka: cek ke-8 `check_no_dangling_internal_refs` memindai **seluruh** Markdown di `docs/`, jadi dokumen baru pun tidak bisa menyelundupkan rujukan mati. Saya uji sendiri: laporan yang sedang Anda baca ini ikut dipindai, dan validator tetap PASS.

**W6-01 · CATATAN · `ACCEPTANCE_TESTS.md` AT-05 (`:29-31`)**

- **Bukti:** AT-05 (Self-Containment) menyuruh menjalankan `python3 tools/check_selfcontained.py --sistem sistem-building-aplikasi --report`. Berkas `tools/` **tidak ada di repo ini** (`git ls-files | grep '^tools/'` → kosong) — ia milik repo meta tempat sistem ini lahir.
- **Dampak:** AT-05 **tidak bisa dijalankan** di repo Resto Barokah. Bukan kerusakan — repo ini adalah hasil "copy jadi repo standalone", jadi memang wajar. Tapi daftar uji penerimaan tidak menyatakan bahwa AT-05 tidak berlaku di sini, jadi agent yang menjalankan "semua AT" akan bingung atau melaporkan gagal palsu.
- **Status: SENGAJA TIDAK DIUBAH** — `ACCEPTANCE_TESTS.md` adalah dokumen sistem yang validatornya sendiri menjaga isinya; menyuntingnya berisiko memicu cek anti-mutasi. **DIUSULKAN** agar sesi pembangun menambah satu baris "AT-05 & AT-09 mutasi 2 tidak berlaku di repo aplikasi (tidak ada `tools/`)".

**Uji penerimaan yang bisa saya jalankan, dan hasilnya:**

| AT | Bisa dijalankan? | Hasil |
|---|---|---|
| AT-01 Entry Point | ya, sebagian | **LOLOS** — `alat/mulai-sesi.py` mencetak posisi, branch, PR, log sesi, skill wajib, buku tunggu tanpa saya tempel apa pun |
| AT-02 Checkpoint Deterministik | ya | **LOLOS** — `validate_system.py` exit 0; field `Pekerjaan belum tersimpan: Tidak ada` tepat 1× |
| AT-03 Log Sesi | ya | **LOLOS** — `_log-sesi/LOG_SESI_2026-09-16.md` ada, berkeadaan OPEN (sesi pembangun masih hidup — memang begitu seharusnya) |
| AT-04 Pegangan Ganda Identik | ya | **LOLOS** — diperiksa oleh `check_pegangan` di validator, PASS |
| AT-05 Self-Containment | **TIDAK** | **TIDAK TERUJI** — butuh `tools/` dari repo meta (W6-01) |
| AT-06 Fondasi 6 Tahap | tidak (uji perilaku) | **TIDAK TERUJI** — butuh simulasi sesi penuh |
| AT-07 DECISIONS_LOG dijaga | tidak (uji perilaku) | **TIDAK TERUJI** — tapi aturannya ada & jelas di `AGENT_SYSTEM.md` dan `AGENT_OPERATING_GUIDE.md` §9 |
| AT-08 Copy → repo standalone | tidak | **TIDAK TERUJI** — butuh `tools/` |
| AT-09 Anti-pedoman-usang (9 mutasi) | sebagian | **LOLOS untuk yang bisa diuji** — saya verifikasi penanda arsip ada di ketiga berkas: `PANDUAN_PEMAKAIAN.md` baris 1 "⚠️ VERSI LAMA — SUDAH DIGANTIKAN, JANGAN DIIKUTI", `_Notes.md` baris 1 "[CATATAN PRIBADI PEMILIK…]", `REKAM-KLINIK.md` "Rekam Klinik". Klaim `skills/README.md` "56 dirs, 26M" saya hitung ulang → `ls -d skills/*/ \| wc -l` = **56**, `du -sh skills` = **26M**. Cocok. |

**Ada aturan bertabrakan?** Saya cari khusus. Satu yang perlu diketahui pemilik, bukan cacat: `AGENT_SYSTEM.md` dan `PANDUAN_PENGGUNA.md` menyuruh setiap sesi ditutup dengan memperbarui `PROJECT_STATE.md`/`STATUS.md`/`LOG_SESI`. **Instruksi review ini justru melarangnya** (bagian 6). Saya mengikuti instruksi review, dan mencatatnya di bagian 13. Selain itu tidak ada tabrakan aturan yang saya temukan.

**Ada berkas berstatus lama yang menyesatkan?** Satu: `docs/README.md` (W1-01, sudah diperbaiki). Berkas arsip lain (`PANDUAN_PEMAKAIAN.md`, `_Notes.md`, `REKAM-KLINIK.md`) semuanya berpenanda jelas di baris pertama — bagus.

---

### W7 — Simulasi agent baru yang bodoh

Saya jalankan `python3 alat/mulai-sesi.py` dan berpura-pura hanya tahu apa yang dicetaknya + berkas wajib yang disebutnya.

| Pertanyaan | Jawab | Bukti |
|---|---|---|
| Tahu harus berbuat apa? | **Ya** | KARTU SESI mencetak "LANGKAH SELANJUTNYA (urutan wajib): 1) baca skill 2) baca fondasi 3) laporkan KARTU SESI 4) tunggu konfirmasi 5) kerja 6) tutup dengan…" |
| Tahu larangan? | **Ya** | `AGENT_OPERATING_GUIDE.md` §12 Stop Conditions (7 butir) + §11 kapan dokumen fondasi boleh berubah + §13.10 "yang tidak pernah ditunda" |
| Tahu apa yang menunggu keputusan pemilik? | **Ya** | DAFTAR TUNGGU dicetak otomatis dengan ID + tenggat |
| Akan menanyakan hal yang sudah dijawab dokumen? | **Sebelum perbaikan saya: YA, dan ini masalahnya.** Ia akan melihat `❓ T-008` di T0-09 dan melewati/menanyakan alamat domain yang **sudah** Anda putuskan (pakai `*.workers.dev`). Setelah W3-01 diperbaiki: tidak lagi. | W3-01 |
| `alat/mulai-sesi.py` memuat buku tunggu & cocok dengan `docs/TERTANGGUH.md`? | **Ya, cocok persis** | Skrip mencetak "Terbuka: 4 butir · T-002, T-003, T-010, T-011"; `docs/TERTANGGUH.md` tabel Butir terbuka berisi tepat 4 baris itu. Setelah saya menambah T-012 & T-013, keduanya otomatis ikut terbaca — saya verifikasi lewat pemeriksa saya (`tertangguh terbuka: 6`). |

**0 temuan baru di W7** (temuan utamanya sudah tercatat sebagai W3-01). **3 hal tersulit yang saya coba untuk mematahkannya:**

1. **Saya coba cari kontradiksi antara KARTU SESI dan kenyataan repo.** Skrip mengklaim 12 berkas fondasi `[ADA]`; saya cek satu per satu dengan `ls` — semuanya benar-benar ada, termasuk `prototipe/README.md`. Tidak ada klaim palsu.
2. **Saya coba cari jalur di mana agent baru bisa membaca status yang salah.** Satu-satunya yang saya temukan adalah `docs/README.md` (W1-01) — dan itu memang tidak dicetak oleh KARTU SESI, tapi dibaca kalau agent membuka folder `/docs`. Sudah diperbaiki.
3. **Saya coba cari apakah agent bisa tidak tahu bahwa ada gerbang review sebelum Fase 0.** Tidak bisa: gerbangnya ditulis sebagai butir pertama Fase 0 di `docs/ROADMAP.md` baris 114, tepat sebelum T0-01 — tidak mungkin terlewat kalau ia membaca ROADMAP sama sekali.

---

### W8 — Jalur & panduan pemilik

Saya ikuti `PANDUAN_PENGGUNA.md` sebagai pemilik non-teknis.

**W8-01 · MINOR · `PANDUAN_PENGGUNA.md` Prompt Penutup butir 7 (`:~70`)**

- **Bukti:** *"Kalau aku mau merge PR: pastikan semua sudah push SEBELUM merge — setelah merge/close, sesi ini TIDAK BISA push lagi."* Peringatannya bagus dan benar. Tapi panduan tidak pernah bilang **kapan pemilik sebaiknya TIDAK merge** — yaitu saat masih ada sesi lain yang hidup di cabang itu.
- **Dampak:** ini bukan teori. Sesi review putaran 1 (`arena/01a0aab1`) gagal justru karena masalah cabang, dan seluruh instruksi review ini punya larangan keras "jangan merge PR apa pun". Pemilik yang membaca panduan saja tidak akan tahu bahwa satu klik "Merge" bisa memutus sesi yang sedang bekerja.
- **Perbaikan yang diusulkan:** tambah 2 kalimat di daftar istilah pada entri **Merge**: *"Jangan merge selagi ada sesi lain yang masih terbuka di cabang itu — sesi itu langsung kehilangan akses dan pekerjaannya bisa menggantung."* Saya tidak menambahkannya karena `PANDUAN_PENGGUNA.md` blok promptnya dijaga cek identik-dua-berkas oleh validator, dan saya tidak mau memicu kegagalan yang bukan wilayah saya. Besar pekerjaan: 10 menit (harus ikut menyunting `PROMPT_ENTRI_UNIVERSAL.md` bila menyentuh blok).
- **Status: DIUSULKAN.**

**W8-02 · CATATAN · langkah yang mengasumsikan sesuatu yang belum dimiliki pemilik**

- **Bukti:** Prompt Pembuka butir 0 menyuruh *"JALANKAN BOOTSTRAP SESI: `python3 alat/mulai-sesi.py`"*. Ini ditujukan ke agent, bukan pemilik — dan memang begitu (pemilik cukup menempel blok). Saya periksa apakah ada langkah yang menuntut pemilik mengetik perintah: **tidak ada**. Bagus.
- Namun W5-01 tetap berlaku: panduan tidak pernah menyiapkan pemilik untuk momen "agent minta URL & kunci Supabase".

**`PANDUAN_PEMAKAIAN.md` benar-benar jelas berstatus arsip?** **YA.** Baris pertama: `# ⚠️ VERSI LAMA — SUDAH DIGANTIKAN, JANGAN DIIKUTI`, disusul penjelasan pedoman mana yang berlaku sekarang. Ini dijaga otomatis oleh `check_penanda_arsip` di validator. Tidak ada temuan.

**Langkah berbahaya (menghapus sesuatu / merge ke arah salah)?** Saya cari khusus kata hapus/`rm`/force di `PANDUAN_PENGGUNA.md`: satu-satunya adalah `rm _Notes.md` di AT-08 (bagian uji, bukan panduan pemilik) dan instruksi "jangan-copy" saat memakai folder sebagai template. Tidak ada langkah destruktif yang diminta ke pemilik. **Aman.**

---

### W9 — Operasional nyata & biaya nol

**(a) Satu hari penuh — buka shift → pesan → dapur → bayar → tutup shift → laporan:**

| Langkah | Tugas | Ada? |
|---|---|---|
| Buka shift + modal awal | T7-01 | ✔ |
| Transaksi wajib dalam shift terbuka | T7-04 | ✔ (bagus — mencegah penjualan "di luar kas") |
| Pesan di kasir / pelayan | T3-01…T3-16 | ✔ |
| Kirim ke dapur + layar dapur/bar | T4-01…T4-05 | ✔ |
| Bayar (tunai/QRIS/transfer) + kembalian | T5-01…T5-05 | ✔ |
| Cetak struk (+ cadangan digital) | T6-*, T5-09 | ✔ |
| Tutup shift: seharusnya vs fisik + alasan selisih | T7-02 | ✔ |
| Laporan harian per shift | T7-07…T7-12 | ✔ |

**Satu hari penuh tertutup rapi.** Tidak ada langkah yang menggantung.

**(b) Skenario gagal — hasil pemeriksaan satu per satu:**

| Skenario | Ada penanganannya? | Bukti |
|---|---|---|
| Internet putus | ✔ | T10-01 antrean luring IndexedDB, T10-03 pesan status, T10-04 uji putus-sambung |
| Printer rusak | ✔ | T5-09 struk digital **cadangan wajib**, T6-07 deteksi dukungan → arahkan ke cadangan |
| Pesanan batal setelah dimasak | ✔ | T5-06/T5-07 void bertingkat + PIN atasan + nilai kerugian + bahan terbuang (PRD Aturan Bisnis 7) |
| Kas tidak cocok | ✔ | T7-02 selisih wajib beralasan, T7-06 koreksi modal hanya-tambah + PIN |
| Voucher dicoba berulang | ✔ | T1-19 cek hanya-baca, T1-20 pakai atomik + PIN, tabel `voucher_percobaan`, T8-12/T8-13 batas & deteksi anomali |
| Dua orang ubah **pesanan/meja** bersamaan | ✔ | T3-09 penguncian status meja, T4-04 uji paralel status item, T1-17 nomor pesanan anti-balapan |
| **Listrik mati** | ✘ **TIDAK ADA** | → **W9-01** |
| **Pegawai berhenti** | ✘ **TIDAK ADA** | → **W9-02** |
| **Dua orang ubah PENGATURAN bersamaan** | ✘ **TIDAK ADA** | → **W9-03** |

**W9-01 · MAYOR · seluruh `docs/ROADMAP.md` — tidak ada tugas untuk listrik mati / perangkat mati mendadak**

- **Perintah & keluaran:** `grep -in 'listrik\|UPS\|baterai\|mati mendadak' docs/ROADMAP.md` → **kosong (0 hasil)**.
- **Dampak nyata (kas & pelanggan):** di Indonesia listrik padam itu biasa, dan kedai ramai adalah waktu paling mahal untuk kehilangan data. Yang hilang bukan cuma keranjang: **shift yang sedang terbuka**. Kalau kasir membuka aplikasi lagi dan sistem tidak mengenali shift lama, ia akan membuka shift baru → uang laci fisik tidak lagi cocok dengan "uang seharusnya" di sistem → tutup kas malam itu pasti selisih, dan kasir yang disalahkan. T10-01 (antrean luring) menangani **internet** putus, bukan **aplikasi** mati.
- **Perbaikan:** saya tambahkan **T10-09 — "Pemulihan setelah listrik/perangkat mati mendadak (kasir & dapur)"**: keranjang belum terkirim ditawarkan kembali, shift terbuka **dikenali dan dilanjutkan** (bukan shift baru), pesanan yang sudah di dapur tetap tampil, plus 1 halaman panduan bahasa manusia untuk pegawai. Mitigasinya memakai kunci idempoten T10-02 supaya pemulihan tidak menggandakan pesanan.
- **Besar pekerjaan:** 3 jam (sesuai atribut Kompleksitas tugas baru). **Status: SUDAH DIPERBAIKI** (tugas ditambahkan).

**W9-02 · KRITIS · cadangan data tidak punya tugas pelaksana sendiri**

- **Perintah & keluaran:** `grep -in 'pg_dump\|backup' docs/ROADMAP.md` → **kosong**. Kata "cadangan" muncul 14×, tapi semuanya berarti "jalur cadangan cetak/digital", **bukan** cadangan data.
- **Bukti:** satu-satunya tempat cadangan data disebut adalah `docs/TECH_SPEC.md` baris 271 (*"gratis tidak menyediakan cadangan otomatis → alat cadangan mingguan (pg_dump)… langkah pemulihan ditulis di docs/teknis/PEMULIHAN.md"*) dan sebagai **satu baris DoD di T11-10**, yaitu tugas **paling akhir** dari 150 tugas.
- **Kenapa KRITIS:** artinya sepanjang Fase 0 sampai Fase 10 — seluruh pembangunan — **data kedai tidak punya cadangan sama sekali**. Dan pilot bisa mulai jalan sebelum F11 selesai. Satu migrasi yang salah, satu penghapusan tidak sengaja, atau satu masalah di sisi Supabase = riwayat transaksi hilang permanen. Untuk usaha yang laporan keuangannya sekarang sepenuhnya di aplikasi ini, itu kehilangan yang tidak bisa dipulihkan dengan uang. TECH_SPEC sendiri sudah mengakui paket gratis **tidak** punya cadangan otomatis — janji itu tidak pernah diterjemahkan jadi pekerjaan.
- **Perbaikan:** saya tambahkan **T10-10 — "Cadangan mingguan otomatis + uji pemulihan terjadwal"**: `pg_dump` mingguan lewat GitHub Actions (gratis), hasil **terenkripsi** dan disimpan di luar basis data, `docs/teknis/PEMULIHAN.md` berisi langkah pulih bernomor, dan **pemulihan wajib diuji minimal sekali ke basis data kosong** — bukan sekadar dipasang. Ditandai ⚠️ ART-10 (berkas cadangan berisi data pelanggan) dan dicatat di `docs/DECISIONS_LOG.md`. Berkas `docs/teknis/PEMULIHAN.md` yang selama ini hanya dijanjikan TECH_SPEC kini punya tugas yang benar-benar membuatnya.
- **Besar pekerjaan:** 4 jam. **Status: SUDAH DIPERBAIKI** (tugas + entri DECISIONS_LOG + butir buku tunggu T-012 untuk tempat penyimpanan).

**W9-03 · MAYOR · `docs/TECH_SPEC.md` baris 212 menjanjikan "versi pengaturan" yang tidak dipakai tugas mana pun**

- **Bukti:** TECH_SPEC §5 baris M2 menyatakan keluaran `simpan_pengaturan` adalah *"versi pengaturan (stempel waktu)"*. `grep -n 'versi pengaturan\|stempel waktu' docs/ROADMAP.md` → **kosong**. Tidak ada satu pun dari T9-01…T9-12 yang memakai versi itu untuk apa pun.
- **Dampak nyata (kas):** dua orang (owner di rumah + admin cabang di kedai) membuka layar pengaturan bersamaan. Yang satu mengubah **persen PB1**, yang lain mengubah jam buka. Siapa yang menyimpan belakangan menimpa seluruh objek pengaturan — perubahan pajak hilang **tanpa jejak dan tanpa pesan**. Transaksi malam itu dihitung dengan pajak yang salah. T9-11 (pratinjau & pengaman riwayat) menjaga agar data **lama** tidak berubah, bukan agar perubahan **baru** tidak saling menimpa.
- **Perbaikan:** saya tambahkan **T10-11 — "Perubahan pengaturan bersamaan tidak saling menimpa"**: simpanan yang membawa versi lama **ditolak di peladen** dengan pesan Indonesia ("data sudah diubah orang lain, muat ulang dulu"), isian pengguna tidak dibuang, dan penolakan tercatat di audit. Ditandai ⚠️ ART-3 karena pengaturan memuat PB1/service/pembulatan, dan dicatat di `docs/DECISIONS_LOG.md`. Ini **memakai** janji TECH_SPEC yang sudah ada, bukan mengubahnya — jadi tidak menyentuh dokumen terkunci.
- **Besar pekerjaan:** 3 jam. **Status: SUDAH DIPERBAIKI.**

**W9-04 · MAYOR · pegawai berhenti tidak punya tugas** (digabung dengan perbaikan di atas)

- **Perintah & keluaran:** `grep -in 'pegawai berhenti\|keluar kerja\|cabut akses' docs/ROADMAP.md` → **kosong**. Yang ada hanya "nonaktifkan pegawai" sebagai satu frasa di DoD T2-03 dan T9-08.
- **Dampak (keamanan & uang):** pegawai kasir yang berhenti — apalagi yang berhenti tidak baik-baik — masih punya PIN dan sesi aktif di perangkatnya. `T10-06` bisa mengakhiri sesi dari perangkat lain, tapi tidak ada satu langkah yang menyatukan: nonaktifkan akun + akhiri semua sesi + matikan PIN + tutup shift yang ia tinggalkan. Kalau shift-nya dibiarkan terbuka, laporan hari itu tidak bisa ditutup.
- **Perbaikan:** saya tambahkan **T10-12 — "Pegawai berhenti: cabut akses cepat & serah terima"**, satu tombol yang melakukan keempatnya sekaligus, dengan penegasan **nonaktif, bukan hapus** supaya laporan lama tetap menampilkan namanya (PRD Aturan Bisnis 11). Butir buku tunggu **T-013** ditambahkan untuk memastikan siapa "atasan" yang berhak menutup shift itu di Kedai Oasis.
- **Besar pekerjaan:** 3 jam. **Status: SUDAH DIPERBAIKI.**

**(c) Biaya nol:**

| Pertanyaan | Jawaban | Bukti |
|---|---|---|
| Ada langkah memaksa bayar? | **TIDAK** | Saya telusuri seluruh ROADMAP untuk langkah berbayar. T0-07 malah eksplisit: *"hanya GitHub Actions gratis untuk repo publik, tanpa langkah berbayar"*. T11-06 & T11-08 memantau batas. |
| Ada langkah melanggar ketentuan gratis? | **TIDAK, dan ini dipikirkan serius** | `TECH_SPEC.md` baris 35 menolak Vercel Hobby dengan alasan *"aturan resminya melarang pemakaian usaha"* — persis pertimbangan yang benar. Cloudflare & Supabase dipilih karena **boleh komersial**. |
| Batas gratis didokumentasikan + risikonya? | **YA** | `TECH_SPEC.md` baris 342-352 tabel lengkap: Supabase data 500 MB (perkiraan pakai 20–60 MB/tahun), foto 1 GB, lalu lintas 5 GB/bln, Cloudflare 100.000 permintaan/hari, Resend 3.000 email/bln, dan **tidur setelah 7 hari** → denyut harian. Peringatan otomatis 70% & 90% → T11-08. Bila mentok → Pro $25/bln, keputusan K6 = **bayar hanya setelah ada pemasukan**. |
| Ada pengeluaran tersembunyi? | **Satu yang perlu diketahui, bukan cacat** | T10-10 yang saya tambahkan memakai GitHub Actions untuk cadangan — gratis untuk repo publik. Kalau repo ini nanti dijadikan privat, menit Actions punya kuota. Saya catat sebagai risiko terbuka (bagian 9), bukan sebagai langkah berbayar. |

**(d) Data & keamanan:**

| Kebutuhan | Tugas | Ada? |
|---|---|---|
| Membatasi akses data pelanggan | T1-12 (⚠️ ART-10), T8-01, T5-08 | ✔ |
| Isolasi antar-resto & antar-cabang | T1-01, T1-04, T1-22, T10-05 (penyisiran ulang setelah semua fitur masuk) | ✔ sangat kuat |
| Uji izin per peran | T2-12 (6 peran), T1-05 (7 tindakan sensitif ditolak) | ✔ |
| Audit tindakan sensitif | T1-13 `catatan_audit` hanya-tambah | ✔ |
| Kebijakan privasi sebelum data masuk | T-011 (buku tunggu) + T8-07, tenggat **sebelum F8** | ✔ |
| Cadangan & pemulihan | sebelumnya **✘** | → **W9-02**, kini T10-10 ✔ |

---

### W10 — Integritas repo & kerahasiaan

**0 temuan.** Rinciannya:

| Pemeriksaan | Perintah | Keluaran |
|---|---|---|
| Jumlah berkas terlacak | `git ls-files \| wc -l` | **1.971** (kini 1.972 dengan pemeriksa baru saya) |
| Ukuran total | `git ls-files -z \| xargs -0 du -ch \| tail -1` | **37M** |
| Berkas rahasia ikut ter-commit? | `git ls-files \| grep -iE '\.env\|secret\|token\|\.pem\|credential'` | **Tidak ada satu pun berkas rahasia nyata.** Yang cocok hanyalah dokumentasi skill (mis. `skills/cloudflare/references/secrets-store/README.md`) dan token **desain** (`prototipe/css/tokens.css`, `design-tokens.mdx`) — kata "token"/"secret" di sini berarti dokumentasi & variabel warna, bukan kunci. |
| Pola kredensial nyata | `grep -rlE 'sk-[A-Za-z0-9]{20}\|ghp_[A-Za-z0-9]{20}\|AKIA[0-9A-Z]{16}' skills docs prototipe` | **kosong — 0 berkas** |
| `.gitignore` melindungi rahasia? | `cat .gitignore` | ✔ `.env`, `.env.*`, `*.local`, `dist/`, `.wrangler/`, `.vercel/`, `coverage/`, `*.log`, `*.tmp`. (Satu efek samping: lihat W5-02.) |
| Berkas besar tidak perlu | `git ls-files -z \| xargs -0 du -a \| sort -rn \| head` | Terbesar: `skills/ios-agent/docs/apple/technologies.json` **3,4 MB** — lihat catatan di bawah. Berikutnya gambar desain (`papan-referensi-pemilik.jpg` 1,1 MB, 5 mockup ±600–730 KB) — **wajar**, ini bukti keputusan desain yang disetujui pemilik. |
| Sisa berkas sementara | `git ls-files` ditelusuri | Tidak ada `.DS_Store`, `__pycache__`, `*.log`, atau berkas sementara yang terlacak. Bersih. |
| Ukuran & kewajaran `skills/` | `du -sh skills` · `git ls-files skills \| wc -l` · `ls -d skills/*/ \| wc -l` | **26M · 1.802 berkas · 56 direktori** — cocok persis dengan klaim `skills/README.md` baris 1 ("56 dirs, 26M"). Isinya dokumentasi & skrip pengembangan (Supabase, Cloudflare, Wrangler, React, TDD, security-review) yang memang dipakai `alat/mulai-sesi.py`. **Tidak ada isi sensitif** (pemindaian pola kredensial kosong). |

**Catatan kewajaran (bukan temuan):** ±14 MB dari 26 MB `skills/` adalah skill yang **tidak relevan** dengan proyek ini — `ios-agent` (322 berkas dokumentasi Apple, termasuk JSON 3,4 MB), `vercel-react-native-skills`, `alibaba-java`. Keputusan membawa `skills/` sudah diambil pemilik secara sadar (T-009: *"Tetap dibawa… ditinjau ulang bila repo terasa berat"*). Saya **tidak** mengusulkan menghapusnya — itu keputusan pemilik yang sudah ditutup, dan 37 MB masih jauh dari bermasalah. Saya hanya melaporkan angkanya supaya keputusan "tinjau ulang" nanti punya dasar.

**3 hal tersulit yang saya coba untuk mematahkan W10:**

1. **Mencari kunci yang sudah terlanjur masuk riwayat Git**, bukan cuma di berkas saat ini — saya pindai isi berkas terlacak dengan pola kunci OpenAI/GitHub/AWS di `skills`, `docs`, `prototipe`. Nihil.
2. **Menguji apakah `.gitignore` benar-benar bekerja**, bukan cuma terlihat benar — saya jalankan `git check-ignore -v` terhadap jalur nyata. Ia bekerja; justru **terlalu** bekerja untuk `.env.example` (W5-02).
3. **Mengadu klaim ukuran `skills/` dengan kenyataan** — banyak sistem mencantumkan angka yang basi berbulan-bulan. Di sini 56 dan 26M keduanya cocok persis.

---

## 7. Ringkasan Klaim vs Bukti (W2)

**TERBUKTI (7):** jumlah 146 tugas · sebaran fase · 7 atribut lengkap · 10 ART punya tugas ⚠️ · 4 temuan cross-check Tahap 6 benar-benar sudah diperbaiki · `.gitignore` sudah diperluas · `skills/` 56 direktori & 26M.

**TIDAK TERBUKTI (3):** "118 tugas bertanda ⚠️" (nyatanya 69 tugas — yang dihitung adalah kemunculan lambang) · "seluruh entitas Data Model punya task" (3 tabel tidak punya nama resminya di tugas mana pun) · "26 RPC" (nyatanya 33 nama RPC di TECH_SPEC §5; cakupannya tetap lengkap).

**TERBUKTI SEBAGIAN (1):** "9 rujukan ❓ semua sah" — ID-nya memang ada, tetapi 5 di antaranya menunjuk butir yang sudah selesai (W3-01).

**TIDAK BISA DIVERIFIKASI (1):** "87 berkas SKILL.md" — tidak saya hitung ulang; bukan angka berisiko.

---

## 8. Simulasi tiga sudut pandang

### 8.1 Agent baru yang bodoh — apa yang paling mungkin ia salah pahami?

1. **Ia akan melewati tugas yang sebenarnya sudah boleh dikerjakan.** Tanda `❓ T-008` di T0-09 + aturan "tugas bertanda ❓ dilewati" = deploy Fase 0 tidak pernah dikerjakan, dan ia tidak akan bertanya kenapa karena aturannya menyuruh melewati diam-diam. → **SUDAH TERTUTUP** (W3-01).
2. **Ia akan membuat tabel bernama `kategori` dan `stok`.** ROADMAP T1-07 menyuruhnya begitu; TECH_SPEC memakai `kategori_menu`, `stok_bahan`, `stok_pergerakan`. Ia tidak punya alasan mencurigai perbedaan karena kedua dokumen sama-sama "resmi". → **SUDAH TERTUTUP** (W3-04).
3. **Ia akan mengira fondasi belum ada** kalau membuka `docs/README.md` sebelum `PROJECT_STATE.md`, lalu memulai Discovery dari nol. → **SUDAH TERTUTUP** (W1-01).
4. **Ia akan mencentang `[x]` tugas yang butuh tangkapan layar** tanpa pernah mengambil tangkapan layar, karena lingkungannya tidak punya peramban. → **BELUM TERTUTUP** (W4-01, diusulkan).
5. **Ia akan berhenti bingung di T0-08** karena butuh akun Supabase yang tidak ada tugasnya. → **BELUM TERTUTUP** (W5-01, diusulkan).

### 8.2 Pemilik non-teknis — langkah mana yang bikin tersesat atau panik?

1. **"Agent minta URL dan kunci Supabase."** Tidak ada satu pun dokumen yang menyiapkan Anda untuk momen ini: situs apa, daftar bagaimana, nilai mana yang disalin, mana yang **tidak boleh** ditempel ke chat. → **BELUM TERTUTUP** (W5-01). Ini yang paling mungkin membuat Anda berhenti.
2. **Tombol "Merge" di GitHub.** Panduan menjelaskan apa itu merge, tapi tidak memperingatkan bahwa merge saat ada sesi lain yang hidup akan memutus sesi itu. Satu klik yang terasa benar bisa menghentikan pekerjaan yang sedang berjalan. → **BELUM TERTUTUP** (W8-01, diusulkan).
3. **Angka risiko yang menakutkan tanpa sebab.** Laporan sesi menyebut "118 dari 146 tugas menyentuh area berbahaya" (81%). Angka sebenarnya 47%. Anda bisa mengambil keputusan yang lebih hati-hati dari yang perlu. → **BELUM TERTUTUP** (W3-02, diusulkan).
4. *Yang sudah aman:* tidak ada satu pun langkah di panduan yang meminta Anda mengetik perintah, menghapus sesuatu, atau mengeluarkan uang. Bahasanya konsisten Indonesia dan istilahnya diterjemahkan. Itu benar-benar dikerjakan dengan baik.

### 8.3 Kedai Oasis, Sabtu malam penuh — bagian mana yang paling mungkin jebol lebih dulu?

1. **Listrik padam pukul 19.30.** Sebelum perbaikan saya, tidak ada apa pun di 146 tugas yang menangani ini. Kasir membuka aplikasi lagi → shift lama tidak dikenali → shift baru → laci fisik tidak cocok dengan sistem → tutup kas selisih, kasir disalahkan. → **SUDAH TERTUTUP** (T10-09).
2. **Owner mengubah PB1 dari rumah, admin cabang mengubah jam buka di kedai, pada menit yang sama.** Perubahan pajak hilang tanpa pesan apa pun; transaksi sisa malam itu dihitung salah dan tidak ada yang tahu sampai laporan bulanan. → **SUDAH TERTUTUP** (T10-11).
3. **Printer termal kehabisan kertas / tidak mau tersambung di jam tersibuk.** → **SUDAH TERTUTUP SEJAK AWAL** dan ini salah satu bagian terkuat fondasi: T5-09 struk digital adalah **cadangan wajib**, bukan opsional, dan T6-07 mendeteksi ketidakdukungan lalu mengarahkan ke cadangan. Keputusan K3 memang dibuat dengan risiko ini di depan mata.
4. **Dua pelayan membuka meja yang sama.** → **SUDAH TERTUTUP** (T3-09 penguncian status meja + T4-04 uji paralel).
5. **Voucher dicoba berulang-ulang oleh satu orang.** → **SUDAH TERTUTUP** (cek hanya-baca, pakai atomik + PIN, semua percobaan dicatat, batas per identitas + anggaran kampanye).
6. **Yang masih rapuh:** merek printer Kedai Oasis **belum diketahui** (T-002, tenggat F6). Kalau printernya ternyata tidak mendukung Web Bluetooth, jalur utama cetak gagal dan kedai bergantung sepenuhnya pada struk digital. Ini sudah tercatat jujur di buku tunggu dengan tenggat mengikat — **ditangani dengan benar, tapi tetap risiko nyata yang butuh jawaban Anda.**

---

## 9. Risiko terbuka + pertanyaan yang hanya bisa dijawab pemilik

**Risiko terbuka:**

1. **Merek & tipe printer Kedai Oasis belum diketahui** (T-002, tenggat F6). Kalau tidak mendukung Web Bluetooth/WebUSB, jalur cetak utama harus dirancang ulang di tengah jalan.
2. **Akun Supabase & Cloudflare belum ada dan belum ada tugasnya** (W5-01). Fase 0 akan berhenti di tugas ke-8 sampai ini beres.
3. **Proyek Supabase gratis tertidur setelah 7 hari tanpa aktivitas**, sementara penjaganya (T10-08) baru ada di Fase 10 (W5-03). Jeda pembangunan lebih dari seminggu akan bikin sesi berikutnya menemui koneksi mati.
4. **Kebijakan privasi pelanggan belum ada** (T-011) — wajib selesai **sebelum Fase 8**, saat data pelanggan pertama dikumpulkan. Ini kewajiban, bukan pilihan.
5. **Cadangan bergantung GitHub Actions gratis** (tugas baru T10-10). Gratis tanpa batas untuk repo publik; kalau repo dijadikan privat nanti, menit Actions punya kuota bulanan.
6. **Bukti visual (tangkapan layar, foto) tidak bisa dihasilkan agent** (W4-01) — beberapa tugas tidak bisa ditutup jujur tanpa bantuan manusia.

**Pertanyaan yang hanya Anda bisa jawab (data lapangan):**

1. **Printer Kedai Oasis merek & tipe apa, tersambung lewat Bluetooth atau kabel USB?** (T-002)
2. **Perangkat apa yang dipakai pegawai sehari-hari** — HP Android, iPhone, atau komputer? (T-003) — iPhone tidak mendukung Web Bluetooth, jadi ini menentukan.
3. **Berkas cadangan mingguan mau disimpan di mana** yang Anda kendalikan sendiri? (T-012, baru)
4. **Siapa yang berhak menutup shift kasir yang ditinggal pegawai berhenti** — admin cabang, atau harus Anda sendiri? (T-013, baru)
5. **Apakah Anda setuju menambah satu langkah "pemilik membuat akun Supabase & Cloudflare" di awal Fase 0** (W5-01), dan siap meluangkan ±30 menit untuk itu dipandu agent langkah demi langkah?
6. **Siapa yang akan menjalankan uji terima & pelatihan pegawai** di Kedai Oasis? (T-010)

---

## 10. Batas cakupan — apa yang TIDAK bisa saya periksa, dan kenapa

Jujur, ini yang **tidak** tercakup oleh laporan ini:

1. **Saya tidak menjalankan kode aplikasi apa pun** — belum ada kode. Semua penilaian saya tentang rencana, bukan tentang perangkat lunak yang berjalan. Rencana yang bagus tetap bisa dilaksanakan dengan buruk.
2. **AT-05 dan AT-08 tidak bisa dijalankan** karena butuh `tools/` dari repo meta yang tidak ikut ke repo ini (W6-01).
3. **AT-06 dan AT-07 tidak bisa diuji** — keduanya uji **perilaku** agent yang butuh simulasi sesi penuh dari awal, bukan sesuatu yang bisa saya buktikan dengan perintah.
4. **Saya tidak memeriksa 1.802 berkas di `skills/` satu per satu** — saya periksa sebagai kebijakan (ukuran, jumlah, pemindaian pola kredensial, kewajaran). Kalau ada satu berkas skill yang isinya menyesatkan, saya tidak akan menemukannya.
5. **Saya tidak memeriksa isi gambar** di `docs/desain/` (mockup, papan referensi) — saya hanya memverifikasi ukurannya wajar. Apakah desainnya benar-benar sesuai selera Anda adalah penilaian Anda, bukan saya.
6. **Saya tidak bisa memverifikasi klaim tentang batas gratis penyedia** (Supabase 500 MB, Cloudflare 100.000 permintaan/hari, Resend 3.000 email/bulan) — saya tidak mengakses internet. Angka-angka itu saya tandai **TIDAK TERVERIFIKASI**; mereka masuk akal dan konsisten antar-dokumen, tapi ketentuan penyedia bisa berubah kapan saja.
7. **Saya tidak bisa menilai apakah 150 tugas cukup untuk membangun aplikasi ini** — tidak ada cara memverifikasi kelengkapan rencana selain membangunnya. Yang bisa saya buktikan: setiap janji di PRD & TECH_SPEC punya tugas yang menunjuknya.
8. **Saya tidak memeriksa riwayat Git lama** (commit sebelum `0691cf8`) untuk kunci yang mungkin pernah masuk lalu dihapus.

---

## 11. Rekomendasi langkah berikutnya

Gabungkan cabang ini ke cabang pembangun lebih dulu — tanpa itu, perbaikan tanda ❓ basi tidak berlaku dan agent pembangun tetap akan melewati T0-09 (deploy) di Fase 0, yang berarti gerbang review ini tidak menghasilkan apa-apa. Setelah tergabung, **aman memulai Fase 0**, dengan satu syarat urutan: sebelum agent menyentuh T0-08, selesaikan dulu urusan akun Supabase & Cloudflare (W5-01) — cara paling praktis adalah meminta sesi pembangun menambahkan tugas **T0-00** berisi langkah bernomor bahasa awam, lalu Anda mengerjakannya sekali sambil dipandu, ±30 menit. Tiga usulan kecil lain (`!.env.example` di `.gitignore`, label "118" di pemeriksa roadmap, dan peringatan merge di panduan pemilik) bisa dikerjakan sesi pembangun dalam 20 menit total dan tidak perlu menahan siapa pun. Jangan menunggu jawaban printer (T-002) untuk memulai — tenggatnya baru di Fase 6, dan fondasi sudah menyiapkan jalur cadangan digital sebagai pengaman.

---

## 12. Catatan atas instruksi review ini sendiri

Bagian yang perlu diperbaiki untuk putaran berikutnya:

1. **Bagian 0 rute B tidak terpakai dan tidak bisa diuji.** Fondasi ternyata ada di checkout sendiri (rute A), jadi seluruh prosedur `git archive` ke `/tmp/fondasi-review` tidak saya jalankan. Saya tidak bisa memastikan langkah-langkah itu benar. Saran: cukup tulis "kalau rute A gagal, baru pakai rute B" — sudah begitu, dan itu bekerja.
2. **Bagian 3 W3 meminta pemeriksa memeriksa "M1–M12, entitas basis data, ART-1..ART-10 punya tugas".** Persyaratan ini **sudah dipenuhi pemeriksa lama** dengan cara yang terlalu longgar. Kalau instruksinya hanya bilang "periksa hal yang sama", pemeriksa baru berisiko jadi salinan. Yang membuat pemeriksa saya berguna justru adalah bagian instruksi yang lain ("tidak menyalin logika") — saran: sebutkan eksplisit bahwa pemeriksa baru harus memakai **sumber data yang berbeda** (tarik dari TECH_SPEC, jangan daftar tangan).
3. **Bagian 4 meminta mendaftar semua berkas terlacak, termasuk 1.802 berkas `skills/`.** Hasilnya tabel 1.900+ baris yang tidak ada yang akan membacanya. Saya tetap membuatnya (di dalam blok yang bisa dilipat) demi kepatuhan, tapi saran: izinkan meringkas `skills/` menjadi satu baris kebijakan.
4. **Bagian 6 melarang mengubah `PROJECT_STATE.md`/`STATUS.md`/`_log-sesi/`, sementara aturan repo (`AGENT_SYSTEM.md`, `PANDUAN_PENGGUNA.md` Prompt Penutup) mewajibkannya.** Instruksi sudah menyebut ini "pengecualian yang disengaja" — bagus, dan saya mengikutinya. Tapi `_sistem/validate_system.py` bisa saja punya cek yang menuntut `STATUS.md` segar; kebetulan tidak. Saran: sebutkan risiko itu supaya reviewer berikutnya tidak panik kalau validator merah.
5. **Bagian 7 meminta "putusan `SIAP MULAI CODING` hanya bila 0 Kritis dan 0 Mayor terbuka".** Definisi "terbuka" tidak jelas untuk temuan yang **saya sendiri perbaiki di cabang yang belum digabung**. Saya memilih tafsir paling hati-hati: perbaikan yang belum digabung = belum berlaku bagi sesi pembangun → `SIAP SETELAH PERBAIKAN`. Saran: perjelas di prompt versi berikutnya.

---

## 13. Keadaan sesi

**Dikerjakan:**

- W1–W10 semuanya diperiksa dan punya hasil tertulis.
- Pemeriksa baru `alat/periksa-fondasi-independen.py` ditulis, diuji mutasi (3 mutasi + 1 kontrol negatif), jalan dengan exit 0/1.
- **9 temuan diperbaiki langsung:** W1-01 (docs/README.md), W3-01 (5 tanda ❓ basi di 7 tempat), W3-04 (3 nama tabel), W9-01 (T10-09), W9-02 (T10-10), W9-03 (T10-11), W9-04 (T10-12), + 2 entri `docs/DECISIONS_LOG.md`, + 2 butir buku tunggu (T-012, T-013).
- ROADMAP: **146 → 150 tugas**; buku tunggu: **4 → 6 butir terbuka** (batas 12, masih aman; keduanya punya tenggat + alasan).

**Tertunda (diusulkan, menunggu sesi pembangun / persetujuan pemilik):**

| Kode | Hal | Kenapa saya tidak kerjakan sendiri |
|---|---|---|
| W5-01 | tugas T0-00 membuat akun Supabase & Cloudflare | menyentuh urutan Fase 0 & pembagian kerja pemilik |
| W5-02 | `!.env.example` di `.gitignore` | area kerahasiaan — lebih aman dikerjakan dengan verifikasi penuh |
| W5-03 | denyut anti-tidur dipindah lebih awal | mengubah urutan fase = keputusan pemilik |
| W1-02 | nama status pesanan T1-18 disamakan ke TECH_SPEC | menyentuh alur pesanan (keputusan terkunci) |
| W3-02 | label "118 tugas bertanda" di pemeriksa lama | dilarang menyentuh pemeriksa lama |
| W3-03 | daftar entitas/RPC tangan di pemeriksa lama | dilarang menyentuh pemeriksa lama (sudah ditutup pemeriksa baru) |
| W4-01 | bukti visual di 4 tugas | menyentuh definisi selesai beberapa tugas |
| W6-01 | AT-05/AT-08 ditandai tidak berlaku di repo aplikasi | dokumen sistem dijaga cek anti-mutasi |
| W8-01 | peringatan merge di panduan pemilik | blok prompt dijaga cek identik-dua-berkas |

**Berkas yang saya ubah (semuanya di cabang `arena/01a0aac5-resto-barokah`):**

| Berkas | Perubahan |
|---|---|
| `alat/periksa-fondasi-independen.py` | **BARU** — pemeriksa independen |
| `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` | **BARU** — laporan ini |
| `docs/ROADMAP.md` | 5 tanda ❓ basi dibersihkan · 3 Ref nama tabel diselaraskan · 4 tugas baru (T10-09…T10-12) · jumlah 146→150 · 3 baris log keputusan |
| `docs/README.md` | ditulis ulang (sebelumnya menyesatkan) |
| `docs/DECISIONS_LOG.md` | 2 entri baru (cadangan/ART-10, versi pengaturan/ART-3) |
| `docs/TERTANGGUH.md` | 2 butir baru (T-012, T-013) |

**Sesuai pengecualian bagian 6 instruksi, saya SENGAJA TIDAK mengubah:** `PROJECT_STATE.md`, `STATUS.md`, dan berkas apa pun di `_log-sesi/` — supaya penggabungan dengan sesi pembangun yang masih hidup tetap bersih.

**Tidak ada PR yang saya merge maupun tutup.** PR #1 tetap OPEN.

**Keadaan pemeriksa saat laporan ini ditutup:**

```
python3 _sistem/validate_system.py          → PASS     (exit 0)
python3 alat/periksa-roadmap.py             → LOLOS    (exit 0, 150 tugas)
python3 alat/periksa-fondasi-independen.py  → BERSIH   (exit 0)
```
