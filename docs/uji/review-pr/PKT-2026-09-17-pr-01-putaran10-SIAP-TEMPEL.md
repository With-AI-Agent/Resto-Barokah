> BERKAS SIAP-TEMPEL — salin SELURUH isi berkas ini ke chat/percakapan BARU (idealnya model berbeda).
> Dibuat mesin oleh `alat/review-pr.py`; kalimat pembuka diambil apa adanya dari sumber kanonik.

===== MULAI SALIN DARI SINI =====

Kamu adalah PENINJAU PR INDEPENDEN untuk proyek Resto Barokah. Kamu BUKAN penulis perubahan ini, bukan sesi yang
mengerjakannya, dan kamu TIDAK BOLEH mengubah, memperbaiki, atau menerapkan perubahan apa pun. Tugasmu: membantah
klaim pembangun dan menemukan masalah nyata pada perubahan (diff) yang dimaksud — bukan menyenangkan pembuatnya.

Kerjakan berurutan:
1. Baca `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` (aturan main), lalu paket review yang saya tempel di bawah.
2. Muat skill yang relevan dari daftar paket (mis. `skills/security-review/SKILL.md`,
   `skills/verification-before-completion/SKILL.md`, `skills/systematic-debugging/SKILL.md`,
   `skills/verification-loop/SKILL.md`, `skills/test-driven-development/SKILL.md`, `skills/supabase/SKILL.md`).
   Bila butuh skill lain, pakai `skills/find-skills` atau katalog `skills/agent-skills-hub`.
3. Periksa diff yang dimaksud (paket menyebut commit & perintah untuk melihatnya). Untuk tiap berkas yang berubah,
   tentukan jalur risikonya (Merah/Kuning/Hijau) dan periksa sesuai kedalaman yang diwajibkan protokol.
4. Bantah klaim pembangun satu per satu — JANGAN mempercayai deskripsi PR. Jalankan perintah buktinya sendiri dan
   tempel keluaran nyatanya (bukan ringkasan keyakinan).
5. Setiap calon temuan: uji ulang di kode sekarang (buka berkas, telusuri pemanggil, jalankan perintah). Tidak bisa
   dibuktikan → tandai DUGAAN. Bisa dibuktikan → TERVERIFIKASI + perintahnya.
6. Jalankan pemeriksaan gerbang yang diminta paket (mis. `bash aplikasi/alat/periksa-semua.sh`, `node alat/uji-sql.mjs`)
   dan tulis hasil nyatanya. Bila tidak bisa dijalankan (pustaka belum terpasang), tulis di bagian
   "Yang tidak bisa saya verifikasi" — jangan menebak.
7. Bila paket memuat **bahan kalibrasi cacat tanaman** (berkas diff terpisah yang berisi cacat sengaja), periksa bahan
   itu secara terpisah dan tulis hasilnya di bagian kalibrasi (`Ditemukan: X dari Y` + jumlah temuan palsu). Kamu tidak
   diberi tahu berapa jumlahnya, di berkas mana, atau kelasnya. Dilarang mencari kunci jawaban.
8. Laporkan SEMUA yang kamu temukan — termasuk yang di luar diff PR ini (bagian 8 laporan). Ambang minimum di paket
   adalah LANTAI, bukan target: jangan berhenti di angka minimum dan jangan menambah baris demi syarat. Jangan menyusun
   laporan agar lolos pemeriksa; formatnya sudah lengkap di paket.
9. Tulis laporan PERSIS dengan format di paket (bagian "Format laporan") ke
   `docs/uji/review-pr/LAPORAN_<tanggal>_<nama-pr>.md`. Berkas ini SATU-SATUNYA yang boleh kamu buat/ubah.
10. Jalankan `python3 alat/review-pr.py --periksa-laporan docs/uji/review-pr/<berkas-laporan>.md` (sekali di akhir).
    Bila ditolak: perbaiki KELENGKAPAN FORMAT-nya, bukan menambah temuan yang tidak kamu yakini.
11. Supaya hasilmu sampai ke sesi kerja, commit + push HANYA berkas laporan itu ke cabang sesi ini. Contoh:
    `git add docs/uji/review-pr/ && git commit -m "laporan review PR <nama>" && git push -u origin HEAD`
    (jangan mengubah/meng-commit berkas lain; bila push tidak bisa, tulis "belum ter-push" dan beri tahu saya).
12. Laporkan verdict + tingkat risiko + ringkasan temuan ke saya di chat.

Larangan keras: memuji, "looks good", melaporkan soal gaya penulisan sebagai temuan, mengubah berkas selain laporan,
mempercayai deskripsi PR tanpa membuktikan, menaikkan verdict di atas bukti, dan menyusun laporan demi memenuhi ambang /
kelulusan pemeriksa — itu teater, bukan review.

===== SAMBUNGAN: PAKET REVIEW =====

# PAKET REVIEW PR INDEPENDEN — pr-01-putaran10 — 2026-09-17

> Dibuat mesin oleh `alat/review-pr.py`. Berkas ini **untuk peninjau** (sesi baru, model berbeda, hanya-baca).
> Aturan penuh: `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`.

> **CARA PAKAI — untuk Lee (3 langkah):**
> 1. Buka **chat/percakapan BARU** (kalau bisa pilih **model yang berbeda** dari sesi kerja).
> 2. Salin **SELURUH isi berkas `-SIAP-TEMPEL.md`** (berkas kembar paket ini) ke chat baru itu.
> 3. Setelah peninjau selesai, kembali ke sesi kerja dan bilang: **"Laporan review sudah masuk, periksa."**

- **PR / cabang:** `pr-01-putaran10`
- **Dasar (base):** `origin/main` → **Kepala (head):** `origin/arena/01a0a8a2-resto-barokah`
- **Commit yang direview:** `597cc77e8c81adda7c3ae51cb9017f781f16d364`
- **Perubahan:** 363 berkas · +46257 / −132 baris
- **Jalur risiko (mesin):** **Merah** — kedalaman review yang diwajibkan: **L1 (ancaman & akses) + L2 (uang & jejak) + L4 (mutu uji) — WAJIB ketiganya**
- **Tugas ROADMAP yang berubah:** - [ ] T0-00, - [ ] T0-08, - [ ] T0-09, - [ ] T0-12, - [ ] T1-11, - [ ] T1-12, - [ ] T1-13, - [ ] T1-14, - [ ] T1-15, - [ ] T1-16, - [ ] T1-17, - [ ] T1-18, - [ ] T1-19, - [ ] T1-20, - [ ] T1-21, - [ ] T1-22, - [ ] T1-24, - [ ] T1-25, - [ ] T1-26, - [ ] T1-27, - [ ] T1-28, - [ ] T1-29, - [ ] T1-30, - [ ] T1-31, - [ ] T1-32, - [ ] T1-33, - [ ] T1-34, - [ ] T1-35, - [ ] T1-36, - [ ] T1-37, - [ ] T1-38, - [ ] T1-39, - [ ] T1-40, - [ ] T1-41, - [ ] T1-42, - [ ] T1-43, - [ ] T1-44, - [ ] T10-01, - [ ] T10-02, - [ ] T10-03, - [ ] T10-04, - [ ] T10-05, - [ ] T10-06, - [ ] T10-07, - [ ] T10-08, - [ ] T10-09, - [ ] T10-10, - [ ] T10-11, - [ ] T10-12, - [ ] T10-13, - [ ] T10-14, - [ ] T10-15, - [ ] T10-16, - [ ] T11-01, - [ ] T11-02, - [ ] T11-03, - [ ] T11-04, - [ ] T11-05, - [ ] T11-06, - [ ] T11-07, - [ ] T11-08, - [ ] T11-09, - [ ] T11-10, - [ ] T11-11, - [ ] T11-12, - [ ] T11-13, - [ ] T2-01, - [ ] T2-02, - [ ] T2-03, - [ ] T2-04, - [ ] T2-05, - [ ] T2-06, - [ ] T2-07, - [ ] T2-08, - [ ] T2-09, - [ ] T2-10, - [ ] T2-11, - [ ] T2-12, - [ ] T2-13, - [ ] T2-14, - [ ] T2-15, - [ ] T2-16, - [ ] T2-17, - [ ] T2-18, - [ ] T2-19, - [ ] T3-01, - [ ] T3-02, - [ ] T3-03, - [ ] T3-04, - [ ] T3-05, - [ ] T3-06, - [ ] T3-07, - [ ] T3-08, - [ ] T3-09, - [ ] T3-10, - [ ] T3-11, - [ ] T3-12, - [ ] T3-13, - [ ] T3-14, - [ ] T3-15, - [ ] T3-16, - [ ] T4-01, - [ ] T4-02, - [ ] T4-03, - [ ] T4-04, - [ ] T4-05, - [ ] T4-06, - [ ] T4-07, - [ ] T4-08, - [ ] T4-09, - [ ] T4-10, - [ ] T5-01, - [ ] T5-02, - [ ] T5-03, - [ ] T5-04, - [ ] T5-05, - [ ] T5-06, - [ ] T5-07, - [ ] T5-08, - [ ] T5-09, - [ ] T5-10, - [ ] T5-11, - [ ] T5-12, - [ ] T6-01, - [ ] T6-02, - [ ] T6-03, - [ ] T6-04, - [ ] T6-05, - [ ] T6-06, - [ ] T6-07, - [ ] T6-08, - [ ] T7-01, - [ ] T7-02, - [ ] T7-03, - [ ] T7-04, - [ ] T7-05, - [ ] T7-06, - [ ] T7-07, - [ ] T7-08, - [ ] T7-09, - [ ] T7-10, - [ ] T7-11, - [ ] T7-12, - [ ] T8-01, - [ ] T8-02, - [ ] T8-03, - [ ] T8-04, - [ ] T8-05, - [ ] T8-06, - [ ] T8-07, - [ ] T8-08, - [ ] T8-09, - [ ] T8-10, - [ ] T8-11, - [ ] T8-12, - [ ] T8-13, - [ ] T8-14, - [ ] T8-15, - [ ] T9-01, - [ ] T9-02, - [ ] T9-03, - [ ] T9-04, - [ ] T9-05, - [ ] T9-06, - [ ] T9-07, - [ ] T9-08, - [ ] T9-09, - [ ] T9-10, - [ ] T9-11, - [ ] T9-12, - [x] T0-01, - [x] T0-02, - [x] T0-03, - [x] T0-04, - [x] T0-05, - [x] T0-06, - [x] T0-07, - [x] T0-10, - [x] T0-11, - [x] T0-13, - [x] T0-14, - [x] T1-01, - [x] T1-02, - [x] T1-03, - [x] T1-04, - [x] T1-05, - [x] T1-06, - [x] T1-07, - [x] T1-08, - [x] T1-09, - [x] T1-10, - [x] T1-23

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
**102 commit** dalam rentang ini (seluruhnya, bukan contoh):
- Perbaiki panel tema terpotong + blok mode Padat (laporan pemilik 2026-09-17)
- Perketat gerbang review PR: verdict, kalibrasi, kedalaman, klaim, bahan kalibrasi
- Tutup temuan review putaran8 (migrasi 0012 + 7 uji baru + bukti mutasi 12/12)
- Paket review PR putaran9 (@ b8679ec) + baris riwayat
- Tutup cacat CI: rujukan ke berkas non-Git + penjaga pohon bersih
- Perbaiki cacat "kontrol mati": Nyaman/Padat + bukti 10 tema + lembar kunci pemilik
- RV-2: paket review putaran8 @ 7e8c0b9 (putaran verifikasi + Buku Uji Pemilik)
- Verifikasi permintaan Lee + Buku Uji Pemilik + 3 penjaga baru
- RV-2: paket review putaran7 @ 183a3c1 (T1-23 ikut direview)
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
- Laporan AUD-3 diperiksa: 3 cacat mekanisme ditutup + temuan diverifikasi ulang
- Paket AUD-3 & paket review PR disegarkan (aturan berkas-tunggal + langkah push laporan)
- Jalur pulang laporan + aturan anti-teater (jawaban Lee putaran 6)
- Kalibrasi review PR: penanda SENGAJA dibuang dari bahan (cacat mekanisme #8) + paket disegarkan
- Paket audit & paket review PR disegarkan (commit kode terakhir)
- Prompt pembuka: langkah 2b baca REKAM_PESAN_PEMILIK (permintaan Lee tidak boleh terlewat di sesi baru)
- Paket AUD-3 & paket review PR #1 disegarkan pada commit kode terakhir
- Rujukan bagian prompt diperbaiki (C4) + penjaga rujukan bernomor 'Bagian X<n>'
- Paket AUD-3 & paket review PR #1 ditulis ulang pada commit kode terakhir
- review-pr: kesiapan sadar ayam-dan-telur (perubahan setelah target hanya berkas paket = paket tetap berlaku)
- Paket AUD-3 & paket review PR #1 (jalur Merah) + bahan kalibrasi review PR
- Putaran 5: rekam pesan Lee, buku induk v2, review PR independen, base branch bebas
- Paket AUD-2 & AUD-3 dibuat ulang: berkas SIAP-TEMPEL + catatan commit yang diaudit
- Berkas SIAP-TEMPEL untuk paket audit + buku/panduan/protokol menyesuaikan
- Buang angka berkas yang cepat basi (DECISIONS_LOG, ROADMAP) - prinsip C5/AT-16
- LOG_SESI: catatan putaran 4 (buku induk, audit menyeluruh, kalibrasi dua jalur)
- Paket audit: blok CARA PAKAI 3 langkah untuk pemilik (kurangi salah pakai)
- Paket AUD-3 final (menunjuk commit 9370cc1) + folder laporan audit
- Buku pedoman induk + penjaga CI + audit menyeluruh (AUD-3) + kalibrasi dua jalur
- Perbaiki mekanisme audit untuk klon dangkal (penyebab CI merah 7f3974f)
- Mekanisme audit independen ditanam (AUD-0..AUD-3) + daftar pekerjaan ulang
- Jalur pemulihan perangkat DISETUJUI pemilik + aturan simpan kode pemulihan
- Keamanan & kelengkapan UI: jawaban lanjutan pemilik + jalur pemulihan perangkat
- Fondasi: matangkan keamanan akun/perangkat & kelengkapan UI
- Naskah usulan: mematangkan keamanan akun/perangkat & kelengkapan fitur-layar-tombol
- Fase 1 T1-10: pembayaran, metode bayar, diskon berbatas, pembatalan berjejak
- Koreksi angka: jumlah tabel yang diperiksa uji (16 setelah T1-07, 19 setelah T1-09, 9 setelah T1-06)
- Fase 1 T1-08 + T1-09: meja per cabang, pesanan dengan salinan harga beku
- Fase 1 T1-07: katalog + harga per cabang + stok ber-buku-besar
- Fase 1 T1-06: PIN pegawai ber-hash + batas percobaan dua lapis + Edge Function tipis terjaga
- Fase 1 T1-05: izin berjenjang + gerbang tunggal boleh()
- Fase 1 T1-01…T1-04: skema inti + identitas + pola RLS, diuji pada PostgreSQL asli di Node
- Pemeriksa struktur: tolak artefak build yang ikut Git
- Bersihkan artefak build yang tidak sengaja ikut Git (*.tsbuildinfo)
- Fase 0: T0-04 selesai (bukti visual pemilik) + T0-10 kerangka uji & gerbang TDD + aturan pemulihan ruang kerja
- Pratinjau: skrip anti-mati aplikasi/alat/pratinjau.sh + catatan di README
- Dokumen Fase 0: T0-04…T0-07 selesai, CI hijau & terbukti bisa merah
- Fase 0 T0-04…T0-07: komponen dasar, rahasia/env, README, CI dasar
- Batalkan uji sengaja + naikkan versi action CI ke v5
- UJI SENGAJA (T0-07): kode dengan variabel tidak terpakai — harus membuat CI MERAH
- Perbaikan CI: rapikan src/layar/README.md + perintah periksa-semua.sh
- Perbaikan dari CI pertama: folder layar kosong ternyata tidak ikut Git
- Fase 0: T0-04 komponen dasar + T0-05 env + T0-06 README + T0-07 CI
- Fase 0: T0-01/T0-02/T0-03 selesai — aplikasi React+TS+Vite, aturan kode otomatis, token desain v3
- Review independen putaran 2 digabung: 9 temuan diperbaiki + 4 perbaikan tambahan; tiga pemeriksa hijau
- Review independen fondasi: 9 temuan diperbaiki + pemeriksa independen baru
- Tanggapi review independen putaran 1: 4 temuan relevan diperbaiki + prompt review versi 3
- Prompt review independen versi 2: sesi reviewer tanpa merge PR, hasilnya kembali ke sesi pembangun
- Gerbang sebelum coding: prompt review independen untuk sesi baru disiapkan
- Tahap 6 SELESAI: pemeriksaan silang (4 temuan diperbaiki) + docs/DECISIONS_LOG.md dibuat; STATUS: CODING_AKTIF
- Tahap 5 SELESAI: ROADMAP 146 tugas (11 fase) + pemeriksa otomatis alat/periksa-roadmap.py
- Mode Maraton + Buku Tunggu (permintaan pemilik): kerja terus-menerus dengan pagar pengaman
- Tahap 5 dimulai: bahan diskusi ROADMAP (11 fase, +/- 136 pekerjaan, checklist kelengkapan)
- Tahap 4 SELESAI: aturan kerja agent + pemasangan skill otomatis tiap sesi
- Tahap 3 SELESAI: TECH_SPEC disetujui & DIKUNCI pemilik; Tahap 4 dimulai (aturan kerja agent)
- Tahap 3: DRAF docs/TECH_SPEC.md (13 bagian, data model, API M1-M12, Area Berisiko Tinggi ART-1..ART-10)
- Tahap 3 dimulai: bahan diskusi teknis putaran 1 (6 keputusan) + batas gratis diperiksa ulang
- Desain ronde 3 lanjutan: sistem desain v3 "KERAJINAN" — 5 halaman ditulis ulang, 13 huruf & 13 foto, pemeriksa 166 & 183 lolos
- Desain ronde 3: 8 standar kehalusan (font, layout, jarak, shadow, glow, transisi, laman mengambang, blur) + 5 papan bukti gambar + pemeriksa halaman
- Desain: tema 4 -> 10 (pakai seluruh skill desain) + huruf OFL lokal + galeri tema
- Desain: 3 contoh tampilan (mockup) siap & bisa diklik + sistem desain 4 tema
- Desain: 34 gambar referensi pemilik masuk repo (P01-P34) + penilaian lengkap & pola kasir dikunci
- Input gambar referensi
- Desain: folder penerima gambar referensi pemilik (docs/desain/referensi/pemilik/) + petunjuk unggah
- Desain: penilaian 10 gambar referensi kiriman pemilik + 2 mode kepadatan (Mode Kasir / Mode Katalog)
- Catat kejadian platform: git kotak kerja ter-reset di tengah sesi (ditangani tanpa kehilangan data)
- Tahap 2 selesai: PRD dikunci -> sesi Desain & UI dimulai (referensi gambar + papan + rancangan 4 tema)
- Tahap 2: DRAF PRD.md ditulis (12 kelompok fitur MVP M1-M12, 13 aturan bisnis, non-goals)
- PRD giliran 2 dijawab: hak akses berjenjang + approval owner, aturan void anti-rugi, diskon konfigurabel
- PRD giliran 1 dijawab: peran MVP dikoreksi jadi 6, voucher & katalog masuk MVP, alur campur, pajak konfigurabel
- TAHAP 1 SELESAI: DISCOVERY.md disetujui & dikunci -> status naik ke FONDASI_TAHAP_2_PRD
- Tahap 1: DRAF DISCOVERY.md ditulis (103 ide fitur) + jawaban desain & dokumen hidup
- Ronde 6: dump fitur pemilik disaring 4 keranjang + konsep voucher undang-teman + riset keamanan verifikasi
- Ronde 5 lanjutan: laporan A dikunci untuk G1, stok bertahap disetujui, PROJECT_STATE disegarkan
- Ronde 5: G1 diperluas disetujui (delegasi), contoh 3 laporan keuangan disiapkan, rekomendasi stok bertahap
- Penutup ronde 4: DISCOVERY ditahan, nama produk diusulkan, penyesuaian G1 diperluas
- Ronde 4 dijawab: perangkat bebas, semua alur & penyesuaian tanpa koding, ojol manual dulu, merek per-resto, gelombang disetujui
- Ronde 3 dijawab + riset loyalitas/referral + rencana bergelombang 3 tahap
- Ronde 2 dijawab + riset pasar: multi-cabang ya, pilot gratis di resto teman, harga & fitur pesaing dipetakan
- Ronde 1 Discovery dijawab: lingkup terkonfirmasi platform multi-penyewa (bukan satu resto) + batasan biaya nol
- Tahap 1 Discovery dimulai: profil pengguna terisi, PROJECT_STATE dibuat, STATUS jadi state aplikasi

## 2. Berkas per jalur risiko
| Jalur | Jumlah | Contoh berkas |
|---|---|---|
| Merah | 66 | A `.github/workflows/ci.yml`, M `_sistem/validate_system.py`, A `alat/audit-independen.py`, A `alat/periksa-bersih.py` … |
| Kuning | 116 | A `alat/bantu_uji_diri.py`, A `alat/contoh-laporan-review/bagus.md`, A `alat/contoh-laporan-review/buruk-kedalaman-kata.md`, A `alat/contoh-laporan-review/buruk-klaim-kurang.md` … |
| Hijau | 181 | A `.gitignore`, M `ACCEPTANCE_TESTS.md`, M `PANDUAN_PENGGUNA.md`, M `PROFIL_PENGGUNA.md` … |

## 3. Klaim yang wajib kamu bantah
1. Verdict (PR-09): "BERSIH-DENGAN-CATATAN" tidak lagi diterima bila ada temuan
2. Kalibrasi (PR-14): berkas paket yang tidak ada = GAGAL (dulu seluruh
3. Kedalaman jalur Merah (PR-14): kata kunci mutasi/RLS/pemulihan dulu cukup
4. Ambang minimum (PR-14): baris kepala tabel tidak lagi dihitung sebagai data.
5. Klaim (PR-17): bug operator membuat baris acak (termasuk kosong) jadi "klaim";
6. Paket (PR-18): daftar commit ditulis SELURUHNYA dengan jumlahnya (dulu 12
7. Bahan kalibrasi (PR-04/PR-06): penanda "SENGAJA" dibuang SEBELUM git diff
8. Diskon: jenis 'promo' ditolak sampai T1-19/T1-20 (dulu kasir bisa mencatat
9. Uji otomatis membuktikan perilaku baru/bebas regresi pada commit ini (bukan commit sebelumnya).
10. Tidak ada gerbang keamanan/CI yang dilemahkan (ambang diturunkan, uji dimatikan, revoke/hak dicabut dihapus).
11. Perubahan pada jalur uang/keamanan/data pelanggan tidak bisa dilewati lewat pemanggilan langsung (RPC/API).
12. Dokumen yang menyatakan perilaku (fondasi, buku induk, panduan Lee) sudah ikut diperbarui — tidak ada klaim basi.

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
- Bahan kalibrasi: `docs/uji/kalibrasi/pr-bahan-2026-09-17.diff` — berkas **diff berisi cacat yang sengaja ditanam**.
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
