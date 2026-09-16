# Prompt Review Independen — Proyek "Resto Barokah" / aplikasi "Sajian"

**Dibuat:** 2026-09-16 · **Untuk:** pemilik proyek (bukan untuk agent sesi ini)
**Tujuan:** memeriksa SELURUH fondasi, sistem kerja, dan panduan sebelum menulis satu baris kode aplikasi.

---

## Bagian A — Cara pakai (untuk pemilik, 6 langkah)

1. **Merge PR #1 dulu** di GitHub. Alasannya: hasil kerja kita hidup di cabang sesi; kalau belum di-merge, `main` belum memuat dokumen fondasi dan sesi baru tidak bisa melihatnya.
2. Buka **sesi baru** (jangan sesi ini).
3. Salin **seluruh** teks di antara penanda `▼ SALIN MULAI` sampai `▲ SALIN SAMPAI` di bawah, tempel sebagai pesan pertama di sesi baru itu.
4. Diamkan sesi itu bekerja. Ia akan mengerjakan sendiri sampai membuka **PR baru** dan memberi laporan 5 baris.
5. Kamu tidak perlu menjawab apa pun, **kecuali** diminta data lapangan (merek printer, daftar perangkat) — itu memang hanya kamu yang tahu.
6. Setelah PR review di-merge, sesi berikutnya baru mulai **coding Fase 0**.

**Batas satu putaran (penting):** review ini **satu gelombang**, bukan pemeriksaan tanpa ujung. Bila hasilnya menemukan masalah berat (Kritis), boleh ada **satu putaran tambahan** untuk memastikan perbaikannya benar. Setelah itu kita mulai membangun — sambil terus diuji di tiap fase. Tanpa batas ini, proyek bisa berhenti selamanya di tahap "memeriksa".

**Yang tidak bisa dijamin oleh review ini (biar harapan kita akurat):**
- Ia **tidak bisa** membuktikan printer, perangkat, atau struktur menu asli Kedai Oasis cocok — itu data lapangan (butir T-002 & T-003 di buku tunggu).
- Ia **tidak bisa** menjamin kode nanti bebas kesalahan, karena kodenya belum ada. Nilai review ini = memastikan **peta dan aturan kerjanya** sudah benar sebelum kita berjalan jauh.
- Ia memeriksa dokumen dan sistem, bukan pengalaman makan di resto.

---

## Bagian B — Yang akan dikerjakan sesi review (ringkas untukmu)

1. Menjalankan semua pemeriksa otomatis yang sudah ada, lalu **membuat pemeriksa baru sendiri** (tidak menyalin yang lama) untuk menguji ulang semua klaim.
2. Membaca **semua dokumen** dan membuat **daftar per-berkas**: berkas mana diperiksa mendalam, mana sekilas, mana tidak — beserta alasannya. Jadi tidak ada yang "kebetulan terlewat".
3. Menguji jalur pemilik: mengikuti panduan pengguna seperti orang non-teknis, mencari langkah yang bikin tersesat.
4. Menguji sebagai **agent baru yang tidak tahu apa-apa**: cukupkah petunjuk yang ada untuk mulai kerja tanpa bertanya?
5. Menguji **skenario nyata Kedai Oasis** (jam sibuk, hari libur panjang, printer mati, internet putus, kas tidak cocok) dan mencari bagian rencana yang jebol.
6. Menulis temuan ber-bukti, memperbaiki yang boleh diperbaiki, dan **berhenti** setelah laporan + PR.

---

▼ SALIN MULAI (salin dari baris ini ke bawah)

# TUGAS: REVIEW INDEPENDEN MENYELURUH SEBELUM CODING

Halo. Kamu agent baru di repo ini. Fondasi proyek ini **bukan** hasil kerjamu, jadi kamu tidak punya kepentingan untuk membelanya. Tugasmu **satu**: memeriksa semuanya secara teliti sebelum proyek masuk tahap coding, lalu memberi putusan jujur. Kalau ternyata ada masalah besar, mengatakan "belum siap" adalah hasil yang BERHASIL, bukan gagal.

## 0. Prasyarat & urutan awal

1. Jalankan `git log --oneline -5` dan `git status --short`. Fondasi harus sudah ada di `main` (hasil merge PR #1). Tanda paling mudah: berkas `docs/ROADMAP.md`, `docs/TERTANGGUH.md`, `docs/DECISIONS_LOG.md`, dan `docs/uji/LAPORAN_CROSS_CHECK_TAHAP6.md` ada, dan `PROJECT_STATE.md` berisi `STATUS: CODING_AKTIF`.
   - **Kalau berkas-berkas itu tidak ada:** BERHENTI. Laporkan ke pemilik: *"Fondasi belum masuk `main` — mohon merge PR #1 dulu, lalu mulai sesi review ini lagi."* Jangan mencoba menebak atau mencari ke cabang lain.
2. Baca dulu aturan repo ini sendiri sesuai `START_DI_SINI.md` (jenis sesi: **Audit / Cross-Check**), termasuk `AGENT_SYSTEM.md` bagian "LANGKAH PERTAMA DI SETIAP SESI". Aturan repo tetap berlaku untukmu; instruksi di bawah menambah, bukan mengganti.
3. Jalankan `python3 alat/mulai-sesi.py` dan catat apakah "DAFTAR TUNGGU" serta "KARTU SESI" tampil benar.
4. Komunikasi ke pemilik: **bahasa Indonesia sederhana, tanpa jargon**, seperti menjelaskan ke pemilik warung yang tidak menulis kode. Laporan akhir juga begitu.

## 1. Sikap kerja yang wajib (anti-laporan-palsu)

- Kamu **bukan** diminta menyetujui. Kamu diminta **mencoba mematahkan** fondasi ini.
- Dilarang menutup laporan dengan "semuanya sudah bagus" atau pujian tanpa daftar apa yang benar-benar diperiksa.
- Dilarang menulis temuan tanpa bukti. Setiap temuan wajib punya: **lokasi berkas:baris**, **perintah persis yang dijalankan**, **keluaran yang terlihat**, **dampak nyata** (ke pemilik, ke kas, ke pelanggan, ke keamanan), **usulan perbaikan**, dan **perkiraan besar pekerjaan**.
- Kalau di satu area kamu **tidak** menemukan temuan: tulis `0 temuan`, lalu sebutkan **3 hal tersulit yang kamu coba lakukan untuk mematahkan area itu**. Itu bukti kamu benar-benar menguji.
- Dilarang mengarang. Kalau tidak bisa diverifikasi dari isi repo, tulis `TIDAK TERVERIFIKASI` — jangan `sepertinya benar`.
- Angka dikutip dari hasil perintah yang baru kamu jalankan sendiri, bukan dari laporan lama.

## 2. Larangan keras (pelanggaran = tugas gagal)

- Dilarang **melemahkan, melonggarkan, atau menghapus** pemeriksa apa pun (`_sistem/validate_system.py`, `alat/periksa-roadmap.py`, atau pemeriksa lain). Kalau pemeriksa itu sendiri salah, tulis temuannya dan usulkan perbaikan — jangan dilonggarkan supaya lolos.
- Dilarang menghapus berkas, `git reset --hard`, `git push --force`, atau mengubah riwayat Git.
- Dilarang **memulai coding aplikasi** (Fase 0 dan seterusnya), membuat berkas di folder aplikasi, atau menginstal paket aplikasi. Batch ini murni review + perbaikan temuan.
- Dilarang mengubah dokumen terkunci tanpa usulan: `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/DISCOVERY.md`. Untuk dokumen itu: **usulkan di laporan**, jangan sunting sendiri.
- Dilarang mengubah keputusan pemilik (K1–K6, urutan uang, PB1/service, peran, alur pesanan) atas inisiatif sendiri. Perubahan seperti itu harus berbentuk usulan + entri di `docs/DECISIONS_LOG.md` bertanda **MENUNGGU PERSETUJUAN PEMILIK**.
- Dilarang menyentuh atau menampilkan isi berkas rahasia (`.env`, kunci, token). Cukup laporkan keberadaannya.
- Dilarang mengeluarkan biaya apa pun atau mengusulkan langkah yang memaksa pemilik membayar.
- Dilarang memperbaiki hal di luar temuan (jangan memperluas lingkup, jangan merapikan gaya tulisan yang tidak bermasalah).

## 3. Wilayah pemeriksaan (semuanya, tanpa terkecuali)

Periksa kesepuluh wilayah ini. Untuk setiap wilayah, hasilnya = temuan ber-bukti ATAU `0 temuan` + daftar uji yang dicoba.

**W1 — Dokumen fondasi (6 dokumen + pendukung):** `docs/DISCOVERY.md`, `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/AGENT_OPERATING_GUIDE.md`, `docs/ROADMAP.md`, `docs/DECISIONS_LOG.md`, plus `docs/TERTANGGUH.md`, `docs/README.md`, `docs/teknisi/*`, `docs/uji/*`, `docs/desain/*`.
Uji: kesalahan di dalamnya saling bertentangan? Ada janji tanpa tugas, atau tugas tanpa janji? Ada keputusan pemilik yang hilang/berubah diam-diam? Istilah (nama peran, nama berkas, nama RPC, nama menu) konsisten di semua dokumen?

**W2 — Klaim vs bukti.** Kumpulkan setiap klaim kuantitatif yang ditulis di laporan/dokumen (jumlah tugas, sebaran per fase, jumlah tugas berisiko, jumlah entitas, jumlah RPC, jumlah temuan yang diklaim sudah diperbaiki), lalu **uji ulang sendiri** dengan skripmu sendiri. Nyatakan tiap klaim sebagai TERBUKTI / TIDAK TERBUKTI / TIDAK BISA DIVERIFIKASI.

**W3 — Pemeriksa otomatis (uji silang alat).** Jalankan `python3 _sistem/validate_system.py` dan `python3 alat/periksa-roadmap.py`; catat keluaran persisnya. Lalu **tulis pemeriksa barumu sendiri** `alat/periksa-fondasi-independen.py` yang **tidak menyalin logika** `alat/periksa-roadmap.py` (tulis ulang dari nol berdasarkan isi dokumen sumber), bisa dijalankan satu perintah, keluar kode 0 bila bersih dan 1 bila ada temuan, dan mencakup minimal:
- setiap tugas punya 7 atribut (Tujuan, Ref, File, DoD, Kompleksitas, Risiko & mitigasi, Verifikasi) dan **isinya bukan pengisi kosong** (mis. DoD yang tidak bisa diuji);
- setiap tugas berisiko tinggi punya kewajiban `DECISIONS_LOG.md`;
- setiap rujukan `Ref` menunjuk bagian yang **benar-benar ada** di dokumen tujuan;
- setiap butir buku tunggu (`T-xxx`) yang dirujuk benar-benar ada di `docs/TERTANGGUH.md`, dan sebaliknya;
- setiap modul wajib (M1–M12), setiap entitas basis data, dan setiap area berisiko (ART-1..ART-10) punya tugas;
- tidak ada nomor tugas ganda atau fase yang terlewat.
Sertakan hasil jalannya di laporan.

**W4 — Mutu isi tugas (uji tangan, bukan lewat skrip).** Ambil **minimal 15 tugas secara acak** (sebutkan caramu mengacak, dan pastikan minimal 3 dari Fase 0). Untuk setiap tugas, jawab: Tujuannya masuk akal? File yang disebut wajar? DoD benar-benar bisa diuji? Verifikasi bisa dijalankan? Ada langkah tersembunyi yang tidak tertulis? Kalau tugas itu "dikerjakan persis seperti tertulis", hasilnya benar?
Selain sampel acak, periksa **semua** tugas Fase 0 (T0-01..T0-10) satu per satu, karena itu yang dikerjakan pertama.

**W5 — Kesiapan Fase 0 (bisa dijalankan atau tidak).** Baca Fase 0 seperti kamu yang akan mengerjakannya. Apakah semua informasi yang dibutuhkan ada (versi Node, nama paket, langkah Supabase, langkah Cloudflare, cara menyimpan rahasia, alamat deploy, urutan commit)? Apakah ada langkah yang tidak mungkin dikerjakan tanpa akun/alat yang belum disiapkan? Apakah urutannya benar (mis. sesuatu dipakai sebelum dibuat)?
Uji khusus: **apakah ada tugas untuk membuat akun & proyek Supabase, dan apakah ada tugas untuk menjaga basis data gratis tetap hidup saat resto libur panjang?** (Basis data gratis bisa "tertidur" bila lama tidak dipakai.) Kalau tidak ada, itu temuan.

**W6 — Sistem kerja agent (`_sistem/`, berkas akar sistem).** Periksa `_sistem/validate_system.py` (baca logikanya: apakah aturannya masuk akal, ada celah lolos, ada aturan yang bertentangan), `_sistem/templates/*`, berkas `_sistem/AUDIT_*.md`, serta berkas akar: `AGENT_SYSTEM.md`, `START_DI_SINI.md`, `10_LOG_SESI.md`, `ACCEPTANCE_TESTS.md`, `ACCEPTANCE_TEST_LOG.md`, `REKAM-KLINIK.md`, `PROFIL_PENGGUNA.md`, `PROMPT_ENTRI_UNIVERSAL.md`, `SYSTEM_MANIFEST.md`, `_Notes.md`, `_salinan-meta/`, `_log-sesi/*`.
Uji: apakah semua berkas sistem ini masih cocok untuk **proyek nyata yang sedang berjalan** (bukan template kosong)? Ada aturan yang saling bertabrakan? Ada berkas yang menyatakan status lama dan menyesatkan? Jalankan juga uji penerimaan yang ada di `ACCEPTANCE_TESTS.md` sejauh bisa diuji tanpa perangkat tambahan, dan tandai mana yang belum teruji.

**W7 — Simulasi sesi baru yang bodoh (uji paling penting).** Bayangkan kamu agent yang baru masuk, tidak tahu apa pun tentang proyek ini, dan **hanya** membaca berkas wajib menurut aturan repo. Lalu jawab: apakah kamu tahu harus berbuat apa? Apakah kamu tahu batas-batas larangan? Apakah kamu tahu apa yang sedang menunggu keputusan pemilik? Apakah kamu akan bertanya hal yang sebenarnya sudah dijawab di suatu dokumen?
Tulis setiap celah sebagai temuan. Uji juga mekanisme wajib-baca: apakah `alat/mulai-sesi.py` benar-benar memuat buku tunggu, dan apakah isinya cocok dengan `docs/TERTANGGUH.md` (hitung jumlah butir terbuka).

**W8 — Jalur & panduan pemilik.** Ikuti `PANDUAN_PENGGUNA.md` dari awal sampai akhir **sebagai pemilik non-teknis** yang menggunakan GitHub dan sesi AI. Catat setiap langkah yang: tidak bisa dijalankan, tidak jelas, mengasumsikan hal yang tidak dimiliki pemilik, atau bisa membuat pemilik melakukan kesalahan berbahaya (mis. menghapus sesuatu, merge ke arah salah). Periksa juga bahwa berkas versi lama (`PANDUAN_PEMAKAIAN.md`) benar-benar jelas berstatus **arsip** dan tidak menyesatkan.

**W9 — Operasional nyata & biaya nol.** Uji fondasi terhadap kenyataan Kedai Oasis:
- **Satu hari penuh**: dari buka shift → pelanggan memesan → dapur memasak → bayar → tutup shift → laporan. Apakah setiap langkah punya tugas di ROADMAP? Adakah lubang?
- **Skenario gagal:** internet putus saat jam sibuk; listrik mati; printer rusak; pesanan batal setelah dimasak; kas tidak cocok; pelanggan mencurigakan/voucher ganda; pegawai resign (email & PIN); dua orang mengubah pengaturan bersamaan. Adakah tugas/aturan yang menanganinya?
- **Biaya nol:** adakah langkah mana pun di dokumen yang menuntut pembayaran atau melanggar ketentuan layanan gratis? Periksa batas layanan gratis yang dipakai (Cloudflare, Supabase, pengirim email) dan tulis risikonya bila batas itu tembus (mis. aplikasi berhenti bekerja, data tidur, email tidak terkirim).
- **Data & keamanan:** adakah tugas untuk menyandikan/ membatasi akses data pelanggan, cadangan (backup), dan pemulihan? Adakah tugas untuk uji keamanan (siapa boleh lihat apa)?

**W10 — Integritas repo & kerahasiaan.** Periksa isi repo: `git ls-files` (daftar berkas terlacak). Cari berkas besar yang tidak perlu, berkas rahasia yang tidak sengaja masuk, sisa berkas sementara, dan berkas yang seharusnya diabaikan Git. Periksa juga ukuran folder `skills/` dan sampel isinya: apakah wajarnya dibawa di repo ini, dan apakah ada isi sensitif di dalamnya. Laporkan temuan tanpa menampilkan isi rahasia.

## 4. Tabel cakupan berkas — WAJIB

Buat daftar **semua berkas yang dilacak Git** (mis. dari `git ls-files`, kecuali isi `node_modules/` dan isi `skills/` yang diperiksa sebagai kebijakan), lalu beri status per berkas:
`DIPERIKSA MENDALAM` · `DIPERIKSA SEKILAS` · `TIDAK DIPERIKSA (alasan)`.
Tujuannya satu: pemilik minta "semuanya diperiksa tanpa terkecuali", jadi harus terlihat jelas berkas mana yang tidak diperiksa dan kenapa. Berkas yang "tidak relevan" tetap dicantumkan.

## 5. Simulasi tiga sudut pandang (wajib, tulis hasilnya)

1. **Agent baru yang bodoh** — apa yang paling mungkin dia salah pahami, dan instruksi mana yang harus diperjelas?
2. **Pemilik non-teknis** — langkah mana yang bikin dia tersesat atau panik?
3. **Kedai Oasis, Sabtu malam penuh** — bagian rencana mana yang paling mungkin jebol lebih dulu?

Untuk tiap sudut pandang, tulis minimal 3 kelemahan konkret, dan tentukan mana yang sudah tertutup oleh fondasi dan mana yang belum.

## 6. Aturan memperbaiki temuan

- **Boleh langsung diperbaiki** (dan catat di laporan): salah ketik, istilah tidak konsisten, rujukan berkas/bagian salah, informasi kurang di dokumen non-terkunci, tugas yang jelas-jelas kurang, penambahan butir buku tunggu, penambahan catatan/pemeriksa yang memperkuat.
- **Harus diusulkan, tidak boleh diubah sendiri:** `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/DISCOVERY.md`, nilai uang/pajak/service, keputusan K1–K6, peran & izin, alur pesanan, dan apa pun yang membatalkan kesepakatan pemilik.
- Setiap perbaikan harus bisa diuji ulang: setelah memperbaiki, jalankan pemeriksamu sendiri + pemeriksa lama dan tunjukkan hasilnya (harus lebih baik, bukan lebih longgar).
- Kalau kamu menambah butir buku tunggu, patuhi aturan repo: `docs/TERTANGGUH.md` maksimal 12 butir terbuka, setiap butir punya tenggat dan alasan.
- Perbaikan apa pun yang menyentuh area berisiko tinggi wajib punya entri di `docs/DECISIONS_LOG.md`.

## 7. Keluaran (deliverable) batch ini

1. `docs/uji/LAPORAN_REVIEW_INDEPENDEN.md` dengan urutan bagian:
   1. Laporan 5 baris untuk pemilik.
   2. **Putusan**: `SIAP MULAI CODING` / `SIAP SETELAH PERBAIKAN` (sebutkan daftar perbaikannya) / `BELUM SIAP` (sebutkan penghalangnya). Aturan: `SIAP MULAI CODING` hanya boleh dikeluarkan bila **0 temuan Kritis dan 0 temuan Mayor terbuka**.
   3. Metode & perintah yang dijalankan (bisa disalin pemilik/agent lain untuk mengulang).
   4. Tabel cakupan berkas (bagian 4).
   5. Temuan W1–W10 dengan format baku: tingkat (`KRITIS`/`MAYOR`/`MINOR`/`CATATAN`) · lokasi · bukti (perintah + keluaran) · dampak · perbaikan · status (`SUDAH DIPERBAIKI`/`DIUSULKAN`/`SENGAJA TIDAK DIUBAH` + alasan).
   6. Klaim vs bukti (bagian W2).
   7. Hasil simulasi 3 sudut pandang (bagian 5).
   8. Risiko yang masih terbuka + pertanyaan yang hanya bisa dijawab pemilik (data lapangan).
   9. Batas cakupan: apa yang TIDAK bisa kamu periksa dan kenapa (jujur, jangan dibesar-besarkan).
   10. Rekomendasi langkah berikutnya (1 paragraf) + apakah aman memulai Fase 0.
   11. Catatan atas instruksi review ini sendiri: bagian mana yang tidak bisa dijalankan atau menurutmu salah.
2. `alat/periksa-fondasi-independen.py` (pemeriksa barumu, bisa dijalankan, kode keluar 0/1).
3. Perbaikan temuan yang boleh diperbaiki + `docs/DECISIONS_LOG.md` bila perlu.
4. Pembaruan `PROJECT_STATE.md`, `STATUS.md`, dan `_log-sesi/` sesuai aturan repo sendiri (jangan lupa: laporan posisi + ringkasan 5 baris).

## 8. Kriteria selesai (Definition of Done batch ini)

- Semua wilayah W1–W10 punya hasil tertulis, bukan kosong.
- Pemeriksa barumu jalan dan hasilnya tercatat; pemeriksa lama masih `PASS`/`LOLOS` **atau** ada penjelasan jujur kenapa tidak.
- Tabel cakupan berkas lengkap.
- Putusan akhir ada, dengan alasan dan bukti.
- Perubahan tersimpan sebagai **satu commit** yang deskriptif, sudah **push**, dan **dibuka sebagai PR** ke `main` (jangan merge sendiri — merge itu hak pemilik).
- Terakhir, laporkan ke pemilik dalam bahasa sederhana: 5 baris (apa yang dikerjakan · apa yang ditemukan · apa yang sudah diperbaiki · apa yang menunggu keputusan pemilik · langkah berikutnya).
- Setelah itu **BERHENTI**. Jangan mulai Fase 0, jangan mulai coding, jangan menunggu instruksi tambahan dari pemilik di sesi ini.

## 9. Kalau kamu menemukan hal yang membuatmu ragu

Gunakan `Stop Conditions` yang sudah ada di `AGENT_SYSTEM.md`. Untuk tugas ini, berhenti dan tanya pemilik hanya bila: ada masalah keamanan/uang/data pelanggan yang tidak jelas, ada dua dokumen yang saling bertentangan dan tidak bisa kamu putuskan mana yang benar, ada usulan perubahan yang menyentuh keputusan terkunci, atau ada hal yang butuh biaya. Selain itu: **catat sebagai temuan, lanjutkan pemeriksaan, selesaikan laporan.**

▲ SALIN SAMPAI (salin sampai baris ini)

---

## Bagian C — Log keputusan

- 2026-09-16 — Berkas ini dibuat menjelang penutupan sesi pembangunan fondasi, atas permintaan pemilik: *"Apakah menurut kamu ini udh bener-bener siap untuk mulai coding... aku mau lakukan review independen dulu. Aku mau kamu siapkan prompt untuk sesi baru agar sesi tersebut melakukan pemeriksaan mendalam terhadap semua ini, termasuk pada sistem nya, juga pada panduan penggunanya, dan lainnya."* Ditambahkan oleh agent: prasyarat merge PR #1, aturan bukti wajib, larangan melemahkan pemeriksa, tabel cakupan berkas, aturan putusan, dan batas satu gelombang (+1 putaran bila ada temuan Kritis).
