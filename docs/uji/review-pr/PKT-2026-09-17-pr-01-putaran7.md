# PAKET REVIEW PR INDEPENDEN — pr-01-putaran7 — 2026-09-17

> Dibuat mesin oleh `alat/review-pr.py`. Berkas ini **untuk peninjau** (sesi baru, model berbeda, hanya-baca).
> Aturan penuh: `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`.

> **CARA PAKAI — untuk Lee (3 langkah):**
> 1. Buka **chat/percakapan BARU** (kalau bisa pilih **model yang berbeda** dari sesi kerja).
> 2. Salin **SELURUH isi berkas `-SIAP-TEMPEL.md`** (berkas kembar paket ini) ke chat baru itu.
> 3. Setelah peninjau selesai, kembali ke sesi kerja dan bilang: **"Laporan review sudah masuk, periksa."**

- **PR / cabang:** `pr-01-putaran7`
- **Dasar (base):** `origin/main` → **Kepala (head):** `origin/arena/01a0a8a2-resto-barokah`
- **Commit yang direview:** `183a3c11aa24f865d6e3140820e64574aea15ff6`
- **Perubahan:** 331 berkas · +41641 / −132 baris
- **Jalur risiko (mesin):** **Merah** — kedalaman review yang diwajibkan: **L1 (ancaman & akses) + L2 (uang & jejak) + L4 (mutu uji) — WAJIB ketiganya**
- **Tugas ROADMAP yang berubah:** - [ ] T0-00, - [ ] T0-08, - [ ] T0-09, - [ ] T0-12, - [ ] T1-11, - [ ] T1-12, - [ ] T1-13, - [ ] T1-14, - [ ] T1-15, - [ ] T1-16, - [ ] T1-17, - [ ] T1-18, - [ ] T1-19, - [ ] T1-20, - [ ] T1-21, - [ ] T1-22, - [ ] T1-24, - [ ] T1-25, - [ ] T1-26, - [ ] T1-27, - [ ] T1-28, - [ ] T1-29, - [ ] T1-30, - [ ] T1-31, - [ ] T1-32, - [ ] T1-33, - [ ] T1-34, - [ ] T1-35, - [ ] T1-36, - [ ] T1-37, - [ ] T1-38, - [ ] T1-39, - [ ] T1-40, - [ ] T1-41, - [ ] T10-01, - [ ] T10-02, - [ ] T10-03, - [ ] T10-04, - [ ] T10-05, - [ ] T10-06, - [ ] T10-07, - [ ] T10-08, - [ ] T10-09, - [ ] T10-10, - [ ] T10-11, - [ ] T10-12, - [ ] T10-13, - [ ] T10-14, - [ ] T10-15, - [ ] T10-16, - [ ] T11-01, - [ ] T11-02, - [ ] T11-03, - [ ] T11-04, - [ ] T11-05, - [ ] T11-06, - [ ] T11-07, - [ ] T11-08, - [ ] T11-09, - [ ] T11-10, - [ ] T11-11, - [ ] T11-12, - [ ] T11-13, - [ ] T2-01, - [ ] T2-02, - [ ] T2-03, - [ ] T2-04, - [ ] T2-05, - [ ] T2-06, - [ ] T2-07, - [ ] T2-08, - [ ] T2-09, - [ ] T2-10, - [ ] T2-11, - [ ] T2-12, - [ ] T2-13, - [ ] T2-14, - [ ] T2-15, - [ ] T2-16, - [ ] T2-17, - [ ] T2-18, - [ ] T2-19, - [ ] T3-01, - [ ] T3-02, - [ ] T3-03, - [ ] T3-04, - [ ] T3-05, - [ ] T3-06, - [ ] T3-07, - [ ] T3-08, - [ ] T3-09, - [ ] T3-10, - [ ] T3-11, - [ ] T3-12, - [ ] T3-13, - [ ] T3-14, - [ ] T3-15, - [ ] T3-16, - [ ] T4-01, - [ ] T4-02, - [ ] T4-03, - [ ] T4-04, - [ ] T4-05, - [ ] T4-06, - [ ] T4-07, - [ ] T4-08, - [ ] T4-09, - [ ] T4-10, - [ ] T5-01, - [ ] T5-02, - [ ] T5-03, - [ ] T5-04, - [ ] T5-05, - [ ] T5-06, - [ ] T5-07, - [ ] T5-08, - [ ] T5-09, - [ ] T5-10, - [ ] T5-11, - [ ] T5-12, - [ ] T6-01, - [ ] T6-02, - [ ] T6-03, - [ ] T6-04, - [ ] T6-05, - [ ] T6-06, - [ ] T6-07, - [ ] T6-08, - [ ] T7-01, - [ ] T7-02, - [ ] T7-03, - [ ] T7-04, - [ ] T7-05, - [ ] T7-06, - [ ] T7-07, - [ ] T7-08, - [ ] T7-09, - [ ] T7-10, - [ ] T7-11, - [ ] T7-12, - [ ] T8-01, - [ ] T8-02, - [ ] T8-03, - [ ] T8-04, - [ ] T8-05, - [ ] T8-06, - [ ] T8-07, - [ ] T8-08, - [ ] T8-09, - [ ] T8-10, - [ ] T8-11, - [ ] T8-12, - [ ] T8-13, - [ ] T8-14, - [ ] T8-15, - [ ] T9-01, - [ ] T9-02, - [ ] T9-03, - [ ] T9-04, - [ ] T9-05, - [ ] T9-06, - [ ] T9-07, - [ ] T9-08, - [ ] T9-09, - [ ] T9-10, - [ ] T9-11, - [ ] T9-12, - [x] T0-01, - [x] T0-02, - [x] T0-03, - [x] T0-04, - [x] T0-05, - [x] T0-06, - [x] T0-07, - [x] T0-10, - [x] T0-11, - [x] T0-13, - [x] T0-14, - [x] T1-01, - [x] T1-02, - [x] T1-03, - [x] T1-04, - [x] T1-05, - [x] T1-06, - [x] T1-07, - [x] T1-08, - [x] T1-09, - [x] T1-10, - [x] T1-23

## ATURAN INDEPENDENSI (tidak bisa ditawar)
1. Kamu **hanya-baca**: SATU-SATUNYA berkas yang boleh kamu buat adalah laporan (§6 format laporan). Selain berkas itu,
   jangan mengubah/memperbaiki apa pun (temuan ditulis, bukan dibetulkan).
2. Kamu **bukan** sesi penulis PR. Tugasmu **membantah** klaim di bawah, bukan mempercayainya.
3. Dilarang memuji, dilarang "looks good", dilarang melaporkan soal gaya penulisan sebagai temuan.
4. Setiap calon temuan wajib diuji ulang di kode sekarang (buka berkas, jalankan perintah). Tidak bisa dibuktikan → **DUGAAN**.
5. Periksa **commit yang dimaksud** (paket menyebut sha-nya). Kalau commit itu tidak ada di repo yang kamu buka,
   jalankan `git fetch origin` lalu periksa sha itu; kalau tetap tidak bisa → **BERHENTI** dan laporkan ke Lee,
   jangan mereview commit lain.

## 0b. Setelah laporan selesai — kirim ke sesi kerja (wajib)

Beri nama berkas dengan **penanda sesimu** di belakang (mis. `__01a0aeb4`) supaya dua sesi peninjau tidak
bertabrakan; penarik laporan menyimpan nama bentrok secara terpisah, tidak menimpa.

```
git add docs/uji/review-pr/ && git commit -m "laporan review PR <nama>" && git push -u origin HEAD
```

Hanya berkas laporan yang di-commit. Bila push tidak bisa, tulis "belum ter-push" + beri tahu Lee di chat.

## 1. Ringkasan perubahan per tujuan (dari judul commit)
- T1-23: peran tunggal + PIN 6 angka unik & kuat (migrasi 0011)
- Paket review PR #1 -> kepala 00e7ce6 (memuat perbaikan mekanisme paket-basi) + riwayat diperbarui
- review-pr: berkas riwayat (REVIEW_PR/AUDIT_RIWAYAT) masuk daftar berkas-netral
- Paket review PR #1 disegarkan ke kepala 9ce6f25 (memuat perbaikan mekanisme paket-basi)
- Catatan sesi: batch RV-2 (paket review putaran6) + cacat mekanisme paket-basi
- RV-2 siap: paket review PR #1 disegarkan + cacat mekanisme paket-basi diperbaiki
- Temuan K-3 audit AUD-3 F-11: pagar + uji regresi yang bisa MERAH + koreksi klaim
- Perbaikan temuan K-2b audit AUD-3: persetujuan void, status pesanan, penjaga stok
- Keputusan Lee: multi-bahasa Opsi 1 (ID+EN+Mandarin di G1, Arab siap di G2)
- Perbaikan temuan K-2a: kredensial PIN, jejak pelaku, batas persen diskon
- Perbaikan temuan K-1 audit AUD-3: uang & isolasi lintas resto (uji merah dulu)
- Anomali sesi audit paralel: laporan tertimpa diselamatkan (cacat mekanisme #12)

## 2. Berkas per jalur risiko
| Jalur | Jumlah | Contoh berkas |
|---|---|---|
| Merah | 52 | A `.github/workflows/ci.yml`, M `_sistem/validate_system.py`, A `alat/audit-independen.py`, A `alat/periksa-fondasi-independen.py` … |
| Kuning | 109 | A `alat/contoh-laporan-review/bagus.md`, A `alat/contoh-laporan-review/buruk-klaim-kurang.md`, A `alat/contoh-laporan-review/buruk-tanpa-bukti.md`, A `alat/contoh-laporan-review/paket-contoh.md` … |
| Hijau | 170 | A `.gitignore`, M `ACCEPTANCE_TESTS.md`, M `PANDUAN_PENGGUNA.md`, M `PROFIL_PENGGUNA.md` … |

## 3. Klaim yang wajib kamu bantah
1. 
2. Uji otomatis membuktikan perilaku baru/bebas regresi pada commit ini (bukan commit sebelumnya).
3. Tidak ada gerbang keamanan/CI yang dilemahkan (ambang diturunkan, uji dimatikan, revoke/hak dicabut dihapus).
4. Perubahan pada jalur uang/keamanan/data pelanggan tidak bisa dilewati lewat pemanggilan langsung (RPC/API).
5. Dokumen yang menyatakan perilaku (fondasi, buku induk, panduan Lee) sudah ikut diperbarui — tidak ada klaim basi.
6. Setiap berkas baru benar-benar dipakai (tidak ada berkas mati / rujukan menggantung).

## 4. Pemeriksaan gerbang yang wajib dijalankan (tempel hasil nyatanya)
1. `bash aplikasi/alat/periksa-semua.sh` — seluruh pemeriksa repo + aplikasi (harus LOLOS).
2. `node alat/uji-sql.mjs` — uji database nyata di dalam Node (harus 10 LULUS · 0 GAGAL atau lebih).
3. `git diff origin/main...origin/arena/01a0a8a2-resto-barokah` — baca diff sungguhan; cari hal yang **tidak** ada di deskripsi.
4. Pemeriksa dokumen: `python3 _sistem/validate_system.py` + `python3 alat/periksa-roadmap.py` + `python3 alat/periksa-panduan.py`.
5. `python3 alat/audit-independen.py --uji-diri` + `python3 alat/review-pr.py --uji-diri` (mekanisme tidak boleh tumpul).

**Tambahan wajib Jalur Merah:**
- Jalankan minimal satu **uji mutasi** pada gerbang yang menyentuh perubahan ini (sengaja rusak → gerbang MERAH → pulihkan → LOLOS) dan tempel hasilnya.
- Untuk perubahan izin/RLS: jalankan `node alat/uji-sql.mjs` dan tunjukkan uji izin/RLS yang relevan **GAGAL saat dilonggarkan**.
- Tulis **rencana pemulihan** (bila perubahan ini salah, apa yang dilakukan agar aman) dan **sisa risiko** dalam bahasa sederhana.

## 5. Bahan kalibrasi cacat tanaman
- Bahan kalibrasi: docs/uji/kalibrasi/pr-bahan-2026-09-17.diff — berkas **diff berisi cacat yang sengaja ditanam**.
- Periksa bahan itu **terpisah** dari PR: salin repo ke folder sementara (`cp -r` ke /tmp lalu `git apply <berkas diff>` di salinan itu) — jangan mengubah repo ini.
- Tulis hasilnya di bagian kalibrasi laporan (`Ditemukan: X dari Y` + jumlah temuan palsu). Kamu tidak diberi tahu jumlah/kelas cacatnya, dan **dilarang mencari kunci jawaban**.

## 6. Format laporan (PERSIS — ditolak mesin bila kurang)
Tulis ke `docs/uji/review-pr/LAPORAN_<tanggal>_<nama-pr>.md`:

```
# LAPORAN REVIEW PR INDEPENDEN — <nama> — <tanggal>

- **Paket review:** `docs/uji/review-pr/<berkas paket>.md`
- **Commit yang direview:** `<sha>`
- **Tingkat risiko:** Merah | Kuning | Hijau
- **Verdict:** BERSIH | BERSIH-DENGAN-CATATAN | TIDAK-BERSIH

## 1. Cakupan diff
| # | Berkas | Jalur risiko | Diperiksa | Bukti (perintah/baris) |
|---|---|---|---|---|

## 2. Klaim yang dibantah
| # | Klaim | Cara membantah | Hasil nyata |
|---|---|---|---|

## 3. Pemeriksaan gerbang
| # | Perintah | Hasil nyata (ringkas) |
|---|---|---|

## 4. Temuan
### [PR-01] Judul temuan
- **Tingkat:** K-1
- **Artefak:** berkas:baris
- **Klaim yang dilanggar:** …
- **Bukti:** perintah → hasil nyata
- **Skenario gagal:** …
- **Dugaan penyebab:** …
- **Cara membuktikan perbaikan:** perintah yang harus hijau
- **Status verifikasi:** TERVERIFIKASI

## 5. Kalibrasi cacat tanaman
Ditemukan: X dari Y · temuan palsu: n · daftar cacat yang saya temukan: …

## 6. Yang tidak bisa saya verifikasi
- …

## 7. Pernyataan tidak mengubah apa pun
Saya hanya-baca, bukan sesi penulis PR. SATU-SATUNYA berkas yang saya buat adalah laporan ini; tidak ada berkas lain
yang saya ubah. Bukti: `git status --short` menampilkan hanya berkas laporan ini.

## 8. Temuan di luar cakupan diff (WAJIB — boleh "tidak ada")
| # | Temuan | Mengapa di luar cakupan diff | Bukti | Saran ditindaklanjuti |
|---|---|---|---|---|
```

**Aturan penulisan laporan (ditegakkan, bukan imbauan):**
- **Ambang minimum adalah LANTAI, bukan target** — jangan berhenti di angka minimum, jangan menambah baris demi syarat.
- **Semua temuan wajib dilaporkan**, termasuk yang kamu temukan **di luar diff** (berkas lain, dokumen, mekanisme) → bagian 8.
  Cakupan menentukan sedalam apa sesuatu **wajib** diperiksa, bukan apa yang **boleh** dilaporkan.
- **Jangan menyusun laporan agar lolos pemeriksa**; format sudah lengkap di paket ini. Jalankan pemeriksa **sekali di akhir**;
  bila ditolak, perbaiki kelengkapan format — bukan menambah temuan yang tidak kamu yakini.
