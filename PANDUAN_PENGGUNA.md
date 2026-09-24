---
agent_instruction: IGNORE for execution — USER GUIDE ONLY
user_guide_only: true
purpose: BUKU PEDOMAN INDUK (manual book) untuk Lee — satu tempat untuk SEMUA hal: cara melakukan setiap hal (Bagian B), semua prompt dengan label siapa yang memakainya (Bagian C), semua mekanisme (Bagian D), semua perintah mesin dengan fungsi & cara pakainya (Bagian E), istilah awam (Bagian F), penanganan masalah (Bagian G), peta berkas (Bagian H). Dijaga `alat/periksa-panduan.py` (ikut CI) supaya tidak bisa basi atau kehilangan isi. Agent hanya membaca berkas ini bila diminta eksplisit atau lewat prompt entri.
---

# Buku Pedoman Pengguna — Resto Barokah & Sistem Pembangunnya

> **Untuk Lee.** Buku ini ditulis dengan asumsi pembacanya **tidak paham coding** — dan itu memang tidak perlu.
> Yang perlu Lee lakukan: **memutuskan**, **minta**, **memeriksa** (lewat bukti yang mudah dibaca), **menyetujui**.

**Tiga aturan pemakaian buku ini:**

1. Buku ini **satu-satunya tempat** semua "cara" dikumpulkan. Kalau ada cara/mekanisme/prompt yang **tidak** ada di sini → itu **cacat buku**, katakan ke agent supaya ditambahkan (CI akan menahan sampai ditambahkan).
2. **Setiap prompt punya label siapa yang memakainya:**
   - **[LEE → AGENT]** = Lee tempel di **sesi kerja** (percakapan tempat agent bekerja).
   - **[LEE → PENINJAU]** = Lee tempel di **chat BARU** yang bertugas memeriksa (auditor / peninjau PR).
   Prompt **tidak boleh ditukar**: prompt peninjau kalau ditempel di sesi kerja akan ditolak agent, dan sebaliknya.
3. **Kalau bingung mulai dari mana:** lihat §0 di bawah.

---

## §0. Cara pakai buku ini (30 detik)

**Lee mau melakukan sesuatu** → buka **Bagian B**, cari barisnya di tabel ini, ikuti alurnya.

| Kalau Lee mau… | Alur | Halaman isi |
|---|---|---|
| Melanjutkan pekerjaan (perintah "lanjut") | **AL-1** | kerja harian |
| Minta sesuatu dikerjakan/diubah | **AL-2** | kerja harian |
| Menutup sesi dengan aman (checkpoint) | **AL-3** | kerja harian |
| Minta penjelasan sederhana | **AL-4** | kerja harian |
| **Audit independen** (pemeriksaan menyeluruh) | **AL-5** | kontrol mutu |
| **Review PR sebelum merge** (karena tidak bisa baca *Files changed*) | **AL-6** | kontrol mutu |
| Menindaklanjuti laporan audit/review | **AL-7** | kontrol mutu |
| Menyuruh pekerjaan lama diulang | **AL-8** | kontrol mutu |
| Menangani masalah mendesak (perangkat hilang, akun bocor, data bocor) | **AL-9** | kedaruratan |
| Melihat/menjawab hal yang ditunda | **AL-10** | kerja harian |
| Menguji sendiri di aplikasi | **AL-11** | uji terima |
| Mengubah aturan/gaya/panggilan nama | **AL-12** | pengaturan |
| **Minta dibimbing langkah demi langkah** (mode bimbingan) | **AL-14** | kerja harian |
| **Minta disiapkan pemeriksaan/audit/review** (prompt pendek) | **AL-15** | verifikasi |
| **Maraton kerja sama multi-sesi** (pekerja paralel + satu integrator) | **AL-16** | koordinasi |

> **Sebelum mulai sesi baru:** permintaan Lee sepanjang proyek tersimpan di `docs/teknis/REKAM_PESAN_PEMILIK.md`.
> Agent wajib membacanya di awal sesi (ada di Prompt Pembuka Bagian C1) supaya tidak ada permintaan yang terlewat.

**Tiga cara mencari isi buku ini:** (1) *"aku mau melakukan X"* → Bagian B · (2) *"perintah/alat apa yang ada"* → Bagian E · (3) *"istilah ini apa artinya"* → Bagian F.

---

## Bagian A — Peta cepat

### A1. Apa yang sedang dibangun (dua lapis)

1. **Lapis sistem (mesin kerja):** cara agent bekerja — dokumen fondasi, roadmap, aturan maraton, audit independen, review PR. Berkasnya di akar repo dan di `docs/`.
2. **Lapis aplikasi (produk):** aplikasi kasir/resto **Resto Barokah** untuk Kedai Oasis — kode di `aplikasi/`, database di `supabase/`, alat uji & pemeriksa di `alat/`.

Lee tidak perlu menyentuh kode. Lee **memutuskan**; agent **mengerjakan + membuktikan**.

### A2. Peta kejujuran: apa yang sudah jadi & apa yang belum

| Sudah jadi & teruji | Belum jadi (jangan dipakai untuk kedai dulu) |
|---|---|
| Dokumen fondasi (Discovery, PRD, Tech Spec, aturan agent, Roadmap) — **dikunci** | Layar aplikasi untuk dipakai kedai (baru kerangka; layar fitur menyusul Fase 2–10) |
| Database: penyewa, cabang, pengguna, izin, pengaturan, katalog, stok, meja, pesanan, pembayaran — diuji otomatis (95 berkas uji, semua LULUS) | Perangkat terdaftar & login staf (Fase 1B), kontrak UI (Fase 1C) |
| Alat pemeriksa otomatis + CI (uji SQL, uji unit, pemeriksa dokumen & buku ini) + **uji sambung Supabase** dengan kunci publik (jalan di CI) | Tabel database **sudah** ada di proyek Supabase nyata (14 migrasi tersebar) dan halaman kerangka **sudah** publik di <https://resto-barokah.fatrizmubarok.workers.dev> (HTTP 200). Yang belum: fitur kedai (Fase 2+) dan domain sendiri — masih alamat gratis `*.workers.dev` |
| Mekanisme audit independen + review PR independen (protokol, alat, kalibrasi cacat) | Pekerjaan ulang artefak lama (T1-37) — daftarnya sudah ada & terukur |

### A3. Bukti yang selalu Lee terima (supaya tidak perlu percaya kata)

| Klaim | Bukti yang wajib ada |
|---|---|
| "Uji lulus" | keluaran perintah uji + jumlah lulus/gagal |
| "Gerbang bisa menangkap cacat" | uji mutasi: sengaja dirusak → gerbang MERAH; dipulihkan → LOLOS |
| "Dokumen tidak basi" | pemeriksa otomatis di CI (termasuk pemeriksa buku ini) |
| "Audit/review bersih" | laporan peninjau yang **lolos pemeriksa mesin** + skor **kalibrasi cacat tanaman** |
| "Sudah diperbaiki" | perintah "cara membuktikan perbaikan" dari temuan dijalankan ulang dan hijau |
| "PR siap di-merge" | **Kartu Keputusan** 7 baris (AL-6) + CI hijau pada commit PR itu |

### A4. Siapa memegang apa (agar tidak ada pintu rahasia)

| Hal | Pemegang |
|---|---|
| Keputusan bisnis (harga, jam buka, fitur, biaya) | **Lee** |
| Akun & kunci layanan (Supabase, Cloudflare, email) | **Lee** (agent hanya memandu; kunci rahasia tidak pernah ditulis di kode) |
| Kode, database, uji, dokumen | Agent |
| Audit & review independen | **Sesi & model berbeda** dari yang mengerjakan |
| Kode pemulihan perangkat (darurat) | **Lee** (dua amplop tersegel — `docs/KEAMANAN.md` §4b) |
| Keputusan merge PR | **Lee** (setelah Kartu Keputusan; agent tidak pernah menekan merge) |
| Uji terima terakhir sebelum pilot | **Lee** di perangkat nyata |

### A5. Aturan yang mengikat agent (bukan imbauan)

1. **Delegasi penuh:** kalau Lee menyerahkan pilihan, agent memilih yang terbaik + menulis alasannya di `docs/DECISIONS_LOG.md`.
2. **Mode maraton:** satu perintah "lanjut" = satu batch pekerjaan; hal yang bisa ditunda **dicatat** di `docs/TERTANGGUH.md` (maksimal 12 butir terbuka) dan pekerjaan tetap jalan.
3. **Kualitas di atas kecepatan:** kalau batch tidak bisa dikerjakan dengan bukti yang bisa dipertanggungjawabkan, agent **berhenti di batas bersih**, bukan mengerjakan setengah.
4. **Penyimpangan wajib ditanya dulu:** agent dilarang menyimpang dari kata-kata/rancangan Lee tanpa bertanya, menjelaskan dalam bahasa sederhana, dan mencatatnya.
5. **Panggilan:** agent memanggil **Lee** ("Lee"), bukan "Bapak".
6. **Stop Conditions:** keamanan/uang/data pelanggan belum jelas · muncul biaya · dokumen saling bertentangan · mau mengubah keputusan yang sudah dikunci · tindakan merusak/tak bisa dibatalkan · butir tertangguh > 12 · menemukan cacat pada pekerjaan yang diklaim selesai.
7. **Gerbang audit & review:** temuan **K-1/K-2 menahan fase dan menahan merge** sampai diperbaiki dan diverifikasi; laporan peninjau wajib lolos pemeriksa mesin; verdict "BERSIH" tidak sah bila peninjau gagal kalibrasi.
8. **PR tidak di-merge oleh agent** — merge adalah keputusan Lee.

---

## Bagian B — Semua alur (cara melakukan)

Setiap alur ditulis dengan pola yang sama supaya mudah dibaca:
**Apa ini** · **Kapan dipakai** · **Kalimat Lee** · **Langkah Lee** · **Yang agent lakukan** · **Bukti yang Lee terima** · **Lama** · **Kalau macet**.

### AL-1 — Melanjutkan pekerjaan ("lanjut")

- **Apa ini:** memerintahkan agent mengerjakan **batch berikutnya** tanpa Lee harus tahu detailnya.
- **Kapan dipakai:** kapan saja Lee punya waktu dan ingin proyek maju.
- **Kalimat Lee:** `Lanjut.`
- **Langkah Lee:** tidak ada. Cukup kirim kalimat itu.
- **Yang agent lakukan:** memilih tugas berikutnya yang **tidak** tertangguh dari `docs/ROADMAP.md` → mengerjakan → menjalankan semua pemeriksa → commit + push → memperbarui papan keadaan → melaporkan 5 baris.
- **Bukti yang Lee terima:** laporan 5 baris (apa yang berubah · artinya · bukti · cacat jujur · berikutnya) + tautan commit.
- **Lama:** satu batch biasanya satu sesi kerja.
- **Kalau macet:** agent **berhenti di batas bersih** dan menuliskan alasannya (mutu tidak bisa dijaga) — bukan memaksakan setengah pekerjaan.

### AL-2 — Meminta sesuatu dikerjakan (fitur, perbaikan, perubahan)

- **Apa ini:** meminta perubahan tertentu — fitur baru, perbaikan tampilan, tambah tombol, ubah aturan.
- **Kapan dipakai:** kapan saja Lee menemukan sesuatu yang ingin diubah/ditambah.
- **Kalimat Lee (contoh):** `Aku mau tombol "Cetak ulang struk" ada di layar kasir, dan bisa dipakai kasir sendiri.`
- **Langkah Lee:** tulis permintaan dengan bahasa sendiri (tidak perlu istilah teknis). Kalau perlu, sertakan: seperti apa hasil yang diharapkan.
- **Yang agent lakukan:** (1) memeriksa apakah permintaan bertabrakan dengan keputusan yang sudah dikunci → bila ya, agent **bertanya dulu** dengan bahasa sederhana; (2) menambahkannya sebagai tugas ROADMAP **lengkap 7 atribut** (tujuan, rujukan, berkas, definisi selesai, kompleksitas, risiko, verifikasi) bila belum ada; (3) mengeksekusi + menguji; (4) memperbarui dokumen yang terpengaruh (termasuk buku ini bila menyentuh cara pakai).
- **Bukti yang Lee terima:** tugas baru di ROADMAP + hasil + uji; kalau menyentuh uang/keamanan/data pelanggan → ditambah **review PR independen** (AL-6) sebelum merge.
- **Lama:** tergantung besar-kecilnya; agent menyebutkan perkiraannya di laporan.
- **Kalau macet:** permintaan bertentangan dengan dokumen terkunci → agent menunjukkan bagian yang bertentangan + menawarkan pilihan (ubah keputusan lewat `docs/DECISIONS_LOG.md`, atau ubah permintaan).

### AL-3 — Menutup sesi dengan aman (checkpoint)

- **Apa ini:** memastikan semua pekerjaan tersimpan di GitHub dan sesi bisa ditutup tanpa kehilangan apa pun.
- **Kapan dipakai:** sesi sudah panjang, atau Lee mau berhenti.
- **Kalimat Lee:** `Tutup sesi ini dengan benar.` — atau `Tutup sesi ini dengan baik.` (kalimatmu tidak harus persis sama: agent mencocokkan **maksudnya**).
- **Langkah Lee:** tidak ada.
- **Yang agent lakukan:** memperbarui `PROJECT_STATE.md` + `STATUS.md` + log sesi → commit + push semua → memastikan working tree bersih → melaporkan commit terakhir & langkah aman berikutnya.
- **Bukti yang Lee terima:** pernyataan "sesi aman ditutup" + commit terakhir + status PR.
- **Lama:** beberapa menit.
- **Kalau macet:** kalau ada berkas yang tidak bisa di-push (mis. PR sudah di-merge), agent memberi tahu dan menyiapkan sesi baru.

### AL-4 — Minta penjelasan sederhana

- **Apa ini:** meminta agent menjelaskan apa pun dengan bahasa sehari-hari.
- **Kapan dipakai:** kapan saja ada yang tidak jelas.
- **Kalimat Lee (contoh):** `Jelaskan dengan bahasa sederhana: apa yang baru berubah, dan apa risikonya buat aku.`
- **Langkah Lee:** tulis pertanyaannya apa adanya; tidak perlu istilah teknis.
- **Yang agent lakukan:** menjelaskan tanpa jargon, memakai analogi bila perlu, dan **mengakui batas** ("ini belum bisa saya pastikan karena …").
- **Bukti yang Lee terima:** jawaban singkat + (bila relevan) berkas/tabel pendukung.
- **Lama:** beberapa menit.
- **Kalau macet:** kalau penjelasan agent masih terlalu teknis, Lee cukup bilang **"terlalu teknis, sederhanakan"**.

### AL-5 — Audit independen (pemeriksaan menyeluruh / terarah)

- **Apa ini:** pemeriksaan oleh **sesi lain** (idealnya model berbeda) terhadap pekerjaan agent — mencari masalah nyata: keamanan, uang, janji dokumen, mutu uji, tampilan/UX, privasi. Ada 4 tingkat: **AUD-0** (dampak perubahan keputusan) · **AUD-1** (pemeriksa mesin/CI) · **AUD-2** (review independen akhir fase) · **AUD-3** (audit **menyeluruh**, semua berkas + semua lensa + kalibrasi).
- **Kapan dipakai:** sebelum fase baru, sebelum pilot, setelah perubahan besar, atau **kapan pun Lee mau memastikan**.
- **Kalimat Lee:** `Siapkan audit independen` (lingkup bebas: "seluruh sistem", "keamanan akun", "Fase 1") — atau `Siapkan audit menyeluruh` untuk AUD-3.
- **Langkah Lee (4 langkah):**
  1. Kirim kalimat di atas di **sesi kerja** (sesi ini).
  2. Agent menjawab: nama berkas paket + berkas **SIAP-TEMPEL** + perkiraan lama.
  3. Lee **buka chat/percakapan BARU** (kalau bisa pilih **model berbeda**), lalu **salin seluruh isi berkas SIAP-TEMPEL** ke situ. Tidak perlu menambah apa pun.
  4. Setelah peninjau selesai, ia **menyimpan laporannya sebagai berkas dan mengirimkannya (push)** ke cabang sesinya.
     Lee kembali ke sesi kerja dan bilang: `Laporan audit sudah masuk, periksa.` — agent **menarik laporan itu otomatis**
     dari GitHub (`--ambil-laporan`). Kalau peninjau tidak bisa push, Lee cukup menempelkan isi laporannya di chat.
- **Yang agent lakukan:** menyiapkan paket (mesin yang menulis, bukan diingat) + bahan kalibrasi → **tidak mengerjakan pekerjaan lain** yang menyentuh lingkup audit sampai laporan masuk → memvalidasi laporan dengan pemeriksa mesin → memperbaiki temuan K-1/K-2 lebih dulu → melaporkan.
- **Bukti yang Lee terima:** laporan peninjau (lolos pemeriksa) + **skor kalibrasi** (`Ditemukan: X dari Y`) + daftar temuan per tingkat + verdict.
- **Lama:** AUD-2 satu sesi peninjau; AUD-3 satu sampai dua sesi peninjau.
- **Kalau macet:** kalau peninjau **gagal kalibrasi** (banyak cacat sengaja tidak ditemukan), verdict "BERSIH" **tidak boleh dipercaya** — agent menyiapkan audit ulang (idealnya model lain). Kalau Lee tidak bisa membuka sesi baru hari itu, pekerjaan tetap berhenti di titik bersih dan agent mengatakannya apa adanya.

### AL-6 — Review PR sebelum merge (untuk Lee yang tidak membaca *Files changed*)

- **Apa ini:** PR = "usulan" memindahkan hasil kerja ke `main`. Karena Lee tidak bisa menilai kode, penilaian dilakukan **peninjau independen** yang menghasilkan **Kartu Keputusan** berbahasa manusia. Tiga tingkat: **RV-1** (pemeriksa mesin/CI) · **RV-2** (review PR independen) · **RV-3** (kalibrasi ketajaman peninjau).
- **Kapan dipakai:** setiap PR **sebelum** dimintakan merge ke Lee.
- **Kalimat Lee:** `Siapkan review PR` (agent tahu PR mana yang sedang dibuka; kalau lebih dari satu, sebutkan nomornya).
- **Langkah Lee (4 langkah):**
  1. Kirim kalimat di atas di sesi kerja.
  2. Agent menjawab: nama berkas **SIAP-TEMPEL** di `docs/uji/review-pr/` + **jalur risiko** PR (🔴 Merah / 🟡 Kuning / 🟢 Hijau).
  3. Lee **buka chat BARU** (idealnya model berbeda) dan **salin seluruh isi berkas SIAP-TEMPEL** ke situ.
  4. Setelah peninjau selesai, Lee kembali dan bilang: `Laporan review sudah masuk, periksa.` Agent memberi **Kartu Keputusan** (7 baris) — Lee memutuskan merge atau minta perbaikan.
- **Yang agent lakukan:** memeriksa CI hijau pada commit PR → menyiapkan paket review → (untuk Jalur Merah) menyiapkan bahan kalibrasi → memvalidasi laporan → memperbaiki temuan K-1/K-2 → menulis Kartu Keputusan → **tidak pernah** meminta merge sebelum semua syarat lengkap.
- **Bukti yang Lee terima:** Kartu Keputusan: commit · jalur risiko · hasil peninjau (verdict + jumlah K-1/K-2/K-3) · cakupan (berapa berkas diperiksa) · skor kalibrasi · sisa risiko · **REKOMENDASI: BOLEH MERGE / JANGAN MERGE DULU** · satu tindakan kalau ragu.
- **Lama:** satu sesi peninjau (biasanya < 1 jam untuk PR kecil).
- **Kalau macet:** kalau CI belum hijau pada commit PR, atau ada K-1/K-2 terbuka, atau kalibrasi gagal → rekomendasi otomatis **JANGAN MERGE DULU** dan agent menyebutkan persis apa yang kurang.

### AL-7 — Menindaklanjuti laporan audit/review

- **Apa ini:** mengubah temuan peninjau menjadi perbaikan nyata + bukti.
- **Kapan dipakai:** setiap kali laporan masuk (audit atau review).
- **Kalimat Lee:** `Laporan audit sudah masuk, periksa.` / `Laporan review sudah masuk, periksa.`
- **Langkah Lee:** cukup kirim kalimat itu. Agent menarik laporan dari cabang peninjau secara otomatis; kalau laporan hanya ada di chat,
  Lee menempelkannya. Setelah agent melapor, Lee membaca ringkasannya; kalau ada pilihan keputusan, agent menyebutkannya satu per satu.
- **Yang agent lakukan:** (1) memvalidasi laporan dengan pemeriksa mesin (laporan yang malas/tanpa bukti **ditolak**); (2) mencocokkan kalibrasi dengan kunci jawaban (kunci ada di luar repo); (3) memperbaiki **K-1 dan K-2 lebih dulu**; (4) menguji ulang memakai perintah "cara membuktikan perbaikan" dari tiap temuan; (5) mencatat temuan K-3/K-4 sebagai tugas atau ke buku tunggu; (6) mencatat hasilnya di `docs/uji/AUDIT_RIWAYAT.md` / `docs/uji/REVIEW_PR_RIWAYAT.md`; (7) menjaga daftar temuan tetap jujur: **setiap temuan punya barisnya sendiri**, baris `DITUTUP` wajib menunjuk bukti yang benar-benar ada, baris `TERBUKA` wajib menunjuk tugas ROADMAP — dijaga mesin `alat/periksa-temuan-audit.py` (CI).
- **Bukti yang Lee terima:** tabel temuan → status (tertutup/terbuka) + perintah bukti yang sudah hijau + kesimpulan "fase boleh lanjut / masih ditahan".
- **Lama:** tergantung jumlah temuan.
- **Kalau macet:** kalau temuan menyentuh keputusan yang sudah dikunci, agent **bertanya dulu** ke Lee sebelum mengubah apa pun.

### AL-8 — Menyuruh pekerjaan lama diulang

- **Apa ini:** membatalkan & mengulang pekerjaan lama yang menjadi salah karena aturan/keputusan berubah (contoh nyata: 9 butir di `docs/uji/DAFTAR_PEKERJAAN_ULANG.md`).
- **Kapan dipakai:** saat sebuah keputusan berubah (keamanan, uang, data pelanggan) — atau saat Lee memintanya.
- **Kalimat Lee:** `Audit dulu dampaknya, lalu ulangi pekerjaan lama yang jadi bertentangan.`
- **Langkah Lee:** tidak ada langkah khusus; kalau agent menyebutkan pilihan (ulang total vs tambal), Lee memilih — agent wajib menjelaskan dalam bahasa sederhana.
- **Yang agent lakukan:** (1) **audit dampak (AUD-0)**: mendaftar semua artefak yang bertentangan, dengan bukti; (2) menulis daftar di `docs/uji/DAFTAR_PEKERJAAN_ULANG.md`; (3) menambah tugas ROADMAP untuk tiap butir; (4) mengerjakan berurutan (biasanya satu migrasi baru menutup beberapa butir); (5) **tidak mengedit berkas lama yang sudah dikunci** — bila perlu, pekerjaan baru ditambahkan di atasnya, dan alasan setiap penghapusan ditulis di `docs/DECISIONS_LOG.md`.
- **Bukti yang Lee terima:** daftar butir + status tiap butir + uji setelah dikerjakan.
- **Lama:** beberapa batch (tergantung besar dampaknya).
- **Kalau macet:** kalau butir tidak bisa diulang tanpa menghapus data nyata → agent berhenti dan bertanya (aturan: **tidak menghapus data produksi**).

### AL-9 — Masalah mendesak (insiden)

- **Apa ini:** hal yang harus segera ditangani: perangkat hilang/dicuri, akun diduga dibobol, data pelanggan bocor, internet kedai mati, printer gagal.
- **Kapan dipakai:** begitu masalah terjadi.
- **Kalimat Lee:** `Insiden: <apa yang terjadi>.` (sebutkan cabang & waktu bila ada)
- **Langkah Lee:** untuk kejadian nyata di kedai, ikuti langkah cepat di `docs/teknis/BUKU_INSIDEN.md` (12 bab, tiap bab ada langkah bernomor). Yang paling penting: **jangan panik dan jangan hapus apa pun**.
- **Yang agent lakukan:** memandu langkah dari Buku Insiden, mencabut akses yang perlu dicabut, memastikan jejak (log) tersimpan, mencatat kejadian, dan menyiapkan perbaikan permanen.
- **Bukti yang Lee terima:** langkah yang dilakukan + hasil + catatan insiden + tugas perbaikan permanen.
- **Lama:** menyesuaikan.
- **Kalau macet:** bila butuh keputusan bisnis (mis. menonaktifkan pegawai), agent menyerahkan keputusannya ke Lee dengan pilihan jelas.

### AL-10 — Hal yang ditunda (buku tunggu)

- **Apa ini:** daftar hal yang **sengaja** ditunda (beserta alasan, nilai sementara, tenggat fase, siapa yang menjawab) di `docs/TERTANGGUH.md`. Batasnya 12 butir terbuka.
- **Kapan dipakai:** Lee ingin tahu apa yang menggantung, atau ingin menutupnya.
- **Kalimat Lee:** `Tunjukkan daftar hal yang ditunda beserta usulan jawabannya.`
- **Langkah Lee:** pilih: membalas **"setuju semua"** (agent menutup semuanya sesuai usulan) atau menyebut butir mana yang ingin diubah.
- **Yang agent lakukan:** menampilkan daftar terbuka + usulan + tenggatnya, dan **tidak menutup** butir apa pun tanpa jawaban Lee (kecuali bisa dibuktikan dari dokumen yang sudah dikunci — itu pun ditulis alasannya).
- **Bukti yang Lee terima:** tabel butir + status sebelum/sesudah.
- **Lama:** menit.
- **Kalau macet:** kalau sudah > 12 butir terbuka, agent **wajib berhenti** dan meminta keputusan Lee.

### AL-11 — Menguji sendiri di aplikasi

- **Apa ini:** cara Lee mencoba aplikasi di perangkat nyata (uji terima) — bukan membaca kode.
- **Kapan dipakai:** saat agent sudah menyiapkan pratinjau/layar untuk dicoba, dan nanti sebelum pilot.
- **Kalimat Lee:** `Tunjukkan cara menguji ini di perangkatku.`
- **Langkah Lee:** agent memberi **daftar periksa bernomor** (naskah jalan bernomor `W-<fase>-<nomor>`): "buka ini → tekan ini → yang seharusnya terjadi: …". Lee cukup menjalankan dan bilang hasilnya ("nomor 3 gagal: tombol tidak keluar").
- **Yang agent lakukan:** menyediakan pratinjau yang bisa dibuka, menyiapkan naskah jalan bernomor, dan memperbaiki apa pun yang gagal.
- **Bukti yang Lee terima:** daftar periksa + hasil yang tercatat (`ACCEPTANCE_TEST_LOG.md`).
- **Lama:** 10–30 menit per putaran.
- **Kalau macet:** kalau pratinjau tidak bisa dibuka, agent **wajib** menganggapnya cacat (bukan "coba saja lagi") dan menyediakan bukti tambahan (gambar/tangkapan layar).

### AL-12 — Mengubah aturan, gaya, atau panggilan nama

- **Apa ini:** perubahan preferensi Lee (mis. panggilan nama, bahasa, gaya penjelasan, warna/tema aplikasi).
- **Kapan dipakai:** kapan saja.
- **Kalimat Lee (contoh):** `Mulai sekarang jangan panggil aku Bapak, panggil Lee.`
- **Langkah Lee:** sebutkan perubahannya; kalau menyangkut aplikasi (warna/logo/nama), sebutkan kira-kira tampilannya seperti apa.
- **Yang agent lakukan:** memperbarui `PROFIL_PENGGUNA.md` (untuk preferensi komunikasi) atau pengaturan aplikasi/desain (untuk tampilan), lalu memastikan semua berkas pengguna ikut berubah di batch yang sama.
- **Bukti yang Lee terima:** daftar berkas yang ikut diperbarui + pemeriksa yang hijau.
- **Lama:** menit.
- **Kalau macet:** kalau perubahan gaya menyentuh keputusan desain yang sudah dikunci (10 tema), agent menjelaskan mana yang berubah dan apa dampaknya sebelum mengerjakan.

---

### AL-13 — Ganti ke sesi/chat baru tanpa kehilangan konteks

- **Apa ini:** memindahkan pekerjaan dari chat yang sudah berat/panjang ke chat baru, dengan keadaan yang sudah tertulis rapi di repo (bukan di ingatan agent).
- **Kapan dipakai:** chat terasa berat/lambat, ingin ganti model, atau sesi lama berhenti karena galat.
- **Kalimat Lee:** `Siapkan pindah ke sesi baru.` · `Tutup sesi ini dengan benar.` / `Tutup sesi ini dengan baik.` · sekaligus dua-duanya: **`Siapkan pindah sesi dan tutup sesi ini dengan baik.`** — kalimatmu tidak harus persis sama: agent mencocokkan **maksudnya**, lalu mengikuti langkah alur ini + **AL-3** (tutup sesi).
- **Langkah Lee:** (0) saat membuat sesi baru di Arena: **base branch = cabang yang agent tulis di laporan** (selama pekerjaan belum masuk `main` — agent WAJIB menyebutnya eksplisit di Langkah Lee). (1) Di chat baru, chat singkat **`baca pro.md`** (pintu masuk universal — agent orientasi sendiri lewat `PRO.md`), atau cara lama: buka berkas **`PROMPT_SESI_BARU.md`** (STATIS — disimpan sekali, dipakai terus) → tulis nama cabang sesi
- **Yang agent lakukan:** menjalankan `python3 alat/lanjut-sesi.py --siapkan` (menyegarkan handoff `docs/ops/SIAP-LANJUT.md` + memastikan `PROMPT_SESI_BARU.md` utuh; berkas statis itu **tidak** ditulis ulang setiap batch) → memperbarui `PROJECT_STATE.md`, `STATUS.md`, `_log-sesi/` → commit & push → menjalankan `python3 alat/lanjut-sesi.py` sampai LOLOS (bukti handoff segar & ter-push).
- **Bukti yang Lee terima:** pernyataan "sesi aman dilanjutkan" + nama berkas yang disalin + commit terakhir + jumlah butir tertangguh.
- **WAJIB DISEBUT AGENT DI BALASAN — 3 hal (teguran Lee 2026-09-23).** Menyatakan "siap pindah sesi" saja **tidak cukup**: Lee tidak bisa menebak isi berkas yang belum ia buka. Sebelum menutup, agent **wajib menuliskan langsung di bagian 👉 Langkah Lee**:
  1. **Base branch mana yang dipilih di Arena** — tulis nama cabangnya **apa adanya** (bukan "cabang sesi ini", bukan `main`).
  2. **Prompt pembuka apa yang ditempel** — yaitu isi `PROMPT_SESI_BARU.md`; sebut juga jalan pendeknya (`baca pro.md`) untuk chat yang sudah mendarat di cabang benar.
  3. **Konfirmasi baris pertama `PROMPT_SESI_BARU.md` sudah menunjuk cabang aktif** — sudah dijaga mesin (`alat/lanjut-sesi.py` GAGAL bila menunjuk cabang yang tidak memuat pekerjaan terakhir), tetapi hasilnya tetap dilaporkan ke Lee.
  Ketiganya sudah tertulis di `PROMPT_SESI_BARU.md`; **kesalahan yang dilarang berulang** adalah menganggap Lee otomatis tahu berkas itu harus dibuka.
- **Lama:** beberapa menit (satu kali perpindahan sesi).
- **Kalau macet:** bila `alat/lanjut-sesi.py` menolak, agent **tidak boleh** menyuruh Lee pindah sesi dulu — perbaiki dulu (biasanya: ada pekerjaan belum di-commit, atau handoff belum disegarkan), karena pindah dengan handoff basi = konteks hilang.
  - Bila sesi sebelumnya berhenti dalam keadaan CI merah, berkas handoff menandainya dengan baris **PERHATIAN**; perbaiki CI lebih dulu sebelum pekerjaan baru.

  - **Base branch (fakta 2026-09-21, menggantikan catatan lama "tidak perlu kamu sentuh"):** selama pekerjaan belum di-merge ke `main`, saat membuat sesi baru di Arena pilih **base branch = cabang sesi yang mau dilanjutkan** (ditulis agent di Langkah Lee). Kalau terlanjur dari `main`, tidak apa-apa: agent menyusul dengan `python3 alat/lanjut-sesi.py --susul` (ff-only, aman). Setelah pekerjaan masuk `main`, base branch tidak perlu diatur lagi. Cabang kerja sesi tetap dibuat platform dan tidak bisa diganti.
  - **Prompt penutup di sesi lama: disarankan 1 kalimat, bukan wajib.** Kalau sesi lama masih bisa diajak bicara, tulis `Siapkan pindah ke sesi baru.` supaya agent merapikan pekerjaan yang belum tersimpan + menyegarkan handoff + memastikan pemeriksa LOLOS. Kalau sesi lama sudah mati/mogok, boleh langsung pindah: agent baru wajib memeriksa keadaan repo dulu. Satu-satunya yang bisa tertinggal bila langkah ini dilewati: pekerjaan yang saat itu belum di-commit/belum di-push.
  - **Wajib pakai berkas terbaru** `docs/ops/SIAP-TEMPEL-SESI-BARU.md` (berkas ini berubah setiap batch; minta `Tampilkan berkas siap tempel.`). Salinan lama biasanya masih aman karena resep susul menarik pekerjaan terbaru dari GitHub, tetapi salinan terbaru selalu lebih benar.
  - **Jangan merge PR #1.** Merge adalah keputusan Lee dan mengakhiri sesi cabang ini; tanyakan dulu ke agent bila ingin merge.
  - **Kamu yang menentukan sesi mana yang dilanjutkan** (permintaan Lee 2026-09-18). Tulis `Tampilkan daftar sesi yang bisa dilanjutkan.` — agent menjalankan `python3 alat/lanjut-sesi.py --daftar-sesi` dan menampilkan tiap sesi: nama cabang, tanggal, jumlah commit di atas `main`, dan apakah sesi itu punya berkas mekanisme (sesi lama biasanya belum). Lalu sebutkan pilihanmu (nomor atau nama cabang), dan agent menyiapkan berkas tempel dengan `python3 alat/lanjut-sesi.py --siapkan --lanjut-dari <cabang-pilihanmu>`. Berguna bila ada sesi yang **sengaja ingin kamu tinggalkan** (mis. sesi yang salah arah) — mesin tidak akan menebak sendiri.
  - **Dua batas penting saat memilih sesi:** (1) sesi yang **belum pernah di-push** ke GitHub tidak bisa dilanjutkan — pekerjaannya belum tersimpan di sana, jadi tidak muncul di daftar; (2) sesi **lama** biasanya membawa alat/pemeriksa versi lebih tua — agent wajib memeriksa dan melaporkan bila ada aturan yang belum ada di sesi itu, bukan mengarang mekanisme baru.
  - **Berkas prompt-nya STATIS: tidak perlu disiapkan ulang.** `PROMPT_SESI_BARU.md` tinggal **kamu isi baris pertamanya** (`SESI YANG AKU LANJUT: …`) dan disalin apa adanya — berkas itu **tidak berubah** dari batch ke batch, jadi kamu tidak perlu meminta agent menyiapkan berkas baru tiap kali pindah sesi. Yang berubah tiap batch hanyalah keadaan di repo (`docs/ops/SIAP-LANJUT.md`), dan itu dibaca sendiri oleh agent baru setelah mendarat di cabang yang benar.
  - **Ada sesi yang sengaja kamu tinggalkan?** Catat di `docs/ops/SESI_DITINGGALKAN.md` (satu baris: cabang + tanggal + alasan). Mesin akan **menolak** handoff/`--siapkan` yang menunjuk ke sesi itu, dan `--daftar-sesi` menandainya — jadi tidak ada yang menyarankan sesi itu lagi tanpa perintahmu (`--paksa` tetap tersedia bila kamu berubah pikiran, dan jejaknya tercatat).
  - **Satu sesi aktif pada satu waktu.** Bila kamu memakai dua sesi bersamaan, keduanya bisa memperbaiki hal yang sama dan menghasilkan dua cabang yang berbeda isinya (pernah terjadi 2026-09-18: dua sesi sama-sama menutup tiga cacat mekanisme). Pilih satu untuk melanjutkan; sesi lain cukup ditinggalkan (tidak perlu dihapus).

### AL-14 — Mode bimbingan (dipandu langkah demi langkah)

- **Apa ini:** cara bicara sementara yang membuat agent memandu Lee **satu tindakan sekali** — pendek, tanpa istilah, dan setiap balasan berakhir dengan "klik apa / ketik apa sekarang".
- **Kapan dipakai:** saat Lee sedang memegang layar (Supabase, Cloudflare, GitHub, HP) dan butuh arahan; atau saat Lee bilang bingung/ketinggalan. **Kalimat Lee:** `Tolong bimbing.` · `Mode bimbingan.` · `Beri arahan step by step.` · `Aku bingung, pandu aku.` — kalimatnya tidak harus persis: agent mencocokkan **maksudnya**. **Penutupnya:** `Sudah beres, lanjut normal.` · `Mode normal lagi.` (atau begitu tugas bimbingannya selesai).
- **Langkah Lee:** ikuti satu langkah yang disebut; kalau layarnya tidak cocok dengan yang disebut agent, **bilang apa yang terlihat** (atau kirim tangkapan layar) — jangan menebak.
- **Yang agent lakukan:** (1) menandai di `_log-sesi/` bahwa mode bimbingan aktif + kapan mulai/diakhiri; (2) menjawab **pendek**: satu tindakan sekali, angka urut, tanpa istilah teknis, selalu diakhiri **satu langkah berikutnya yang jelas**; (3) menyebut nama tombol/menu **persis** seperti di layar Lee; (4) tetap bekerja di belakang (memeriksa, mencatat) tetapi **tidak** menumpahkan hasil pemeriksaan ke balasan bimbingan; (5) bila ada dua jalan (mis. templat vs *Create Custom Token*), sebut yang **lebih mudah lebih dulu**, lalu jalan cadangan satu baris.
- **Bukti yang Lee terima:** akhir balasan selalu berbunyi "sekarang: …" (satu tindakan), plus laporan singkat setelah langkahnya berhasil.
  - **Boleh melewati pemeriksaan rutin?** Ya — pemeriksaan rutin yang tidak berhubungan dengan bimbingan **boleh ditunda** supaya balasan cepat; ditunaikan di akhir batch. Yang **tidak boleh ditunda** dengan alasan apa pun: (a) saat ada perubahan baru, (b) saat agent mau bilang "selesai", (c) saat menyangkut biaya, keamanan, uang/data pelanggan, atau tindakan yang tak bisa dibatalkan (mis. menaikkan halaman ke internet). Di tiga keadaan itu agent keluar dari mode singkat dan kembali teliti. Aturan lengkap: `docs/AGENT_OPERATING_GUIDE.md` §14 aturan 7 — penjaganya `alat/periksa-panduan.py` (blok AL-14 + §14 wajib memuat batas ini; mutasi yang menghapusnya WAJIB ditolak).
- **Lama:** sampai tugas bimbingan selesai (biasanya menit).
- **Kalau macet:** bila langkah bimbingan menyentuh **§12 Stop Conditions** (biaya, keamanan/uang/data, keputusan terkunci, tindakan tak bisa dibatalkan seperti deploy publik) atau menyentuh **bukti "selesai"**, agent **keluar dari mode singkat** selama bagian itu saja: menjelaskan singkat kenapa harus berhenti, lalu meminta keputusan Lee — **mode bimbingan tidak mengurangi keselamatan, hanya memendekkan cara bicara**. Bila layar Lee berbeda dari panduan, agent memperbaiki panduannya (dokumen ini) agar sesi berikutnya tidak salah lagi.

### AL-15 — Menyiapkan pemeriksaan/audit/review dengan SATU kalimat (prompt pendek)

- **Apa ini:** cara cepat minta sesi independen (auditor/peninjau) disiapkan. Lee bilang satu kalimat sederhana; agent menyiapkan paket lengkapnya dengan mesin, lalu memberi Lee **prompt PENDEK** (±6 baris) untuk ditempel ke chat baru. Semua detail (kategori, kriteria, lingkup, commit target, aturan main) tetap hidup di berkas paket yang terjaga pemeriksa otomatis — yang pendek hanya yang Lee tempel.
- **Kapan dipakai:** setiap kali Lee mau pemeriksaan/audit/review independen tanpa mengingat nama alat atau bendera perintah; juga untuk menarik laporan yang sudah selesai.
- **Kalimat Lee → yang terjadi:**

| Kalimat Lee (maksudnya dicocokkan, bukan huruf per huruf) | Yang disiapkan agent |
|---|---|
| Pemeriksaan menyeluruh — "Siapkan pemeriksaan independen menyeluruh." / "Siapkan audit menyeluruh." | paket audit AUD-3 seluruh proyek → `python3 alat/siapkan-pemeriksaan.py --frasa "<kalimat Lee>"` |
| Audit satu bidang — "Siapkan pemeriksaan menyeluruh di bidang keamanan." (bidang lain menyusul) | paket audit AUD-3 lingkup bidang (`--bidang keamanan`); temuan di luar lingkup tetap wajib dilaporkan auditor |
| Review PR — "Siapkan review PR." | paket review PR berikutnya → alat yang sama |
| Fondasi — "Jalankan pemeriksaan fondasi." | **tidak perlu sesi baru** — `alat/periksa-fondasi-independen.py` jalan langsung di sesi ini |
| Laporan masuk — "Laporan audit sudah masuk, periksa." / "Laporan review sudah masuk, periksa." | agent menarik laporan dari cabang sesi independen (`--ambil-laporan` alat terkait), memvalidasi kontraknya, lalu memanen temuan (bantah-balik dulu sebelum menutup apa pun) |

- **Langkah Lee:** tempel prompt pendek itu ke chat/percakapan BARU (idealnya model berbeda). Setelah sesi independen selesai dan laporannya ter-push, kembali ke sesi kerja dan bilang `Laporan audit sudah masuk, periksa.`
- **Yang agent lakukan:** (1) siapkan paket sesuai jenis pemeriksaan, hanya pada commit ber-CI-hijau (gerbang H F-02); (2) commit + push paket; (3) cetak dengan `python3 alat/siapkan-pemeriksaan.py --prompt-pendek <jalur-paket>` (pilih jalur eksplisit, jangan menebak paket terbaru); (4) **WAJIB tampilkan prompt pendek langsung DI CHAT dalam blok siap-tempel; tautan saja tidak cukup.** Berlaku untuk setiap penyerahan audit/review/pemeriksaan independen, walau paket dibuat atas inisiatif agent, bukan hanya lewat kalimat AL-15; (5) **Periksa draf sebelum mengirim:** simpan draf respons di luar repo, lalu jalankan alat yang sama dengan `--prompt-pendek <jalur-paket> --periksa-serah <draf-respons>`; kirim blok yang lolos tanpa menggantinya dengan tautan; (6) saat laporan masuk: tarik dengan `--ambil-laporan`, validasi kontrak dan bantah-balik temuan.
- **Isi prompt pendek wajib:** **repo + cabang sumber + SHA paket + path** (SHA penuh, akses git/gh terautentikasi termasuk privat); commit sasaran terpisah; perintah baca SELURUH paket dan gagal-tertutup. URL versi tetap (SHA penuh) hanya tambahan, bukan akses utama. Tanpa meminta Lee lagi: **commit + push ke cabang sesi sendiri** melalui `alat/kirim-laporan.py`, lalu **verifikasi remote**. Cabang/working tree bisa bersama; wajib snapshot, draf UUID, commit/index terisolasi, retry fast-forward terbatas. Dilarang merge/rebase/reset/force/menimpa/push sumber/main. Bukti: repo, cabang tujuan, path laporan, commit SHA, remote_tip, SHA-256; chat/lokal saja bukan selesai. TERBLOKIR = simpan laporan dan status BELUM TERVERIFIKASI, bukan selesai. Kontrak teknis: `docs/uji/PENGIRIMAN_LAPORAN_AMAN.md`.
- **Batas pengaman jujur:** mesin memeriksa **draf respons**, bukan chat yang benar-benar terkirim; agent tetap wajib mencocokkan jawaban akhir. CI menjaga aturan dan kepekaan alat, bukan menjamin agent tak pernah lupa. Bila Lee sudah menjalankan paket dan bilang tidak perlu prompt baru, jangan mengirim ulang/mengganti paket aktif—aturan ini berlaku untuk penyerahan berikutnya.
- **Bukti yang Lee terima:** prompt pendek di chat (locator privat lengkap + dua SHA terpisah), lalu setelah panen: ringkasan temuan + baris riwayat yang diperbarui.
- **Lama:** menyiapkan paket 1–3 menit; sesi independennya terserah Lee (bisa berjalan paralel).
- **Kalau macet:** alat menolak karena CI commit target belum hijau → tunggu CI hijau (jangan pakai `--izinkan-ci-belum-hijau` tanpa izin Lee); URL tidak bisa dibuka → paket belum di-push, agent wajib push dulu; sesi independen tidak bisa push (tanpa akses GitHub) → jalur lama tetap sah: salin isi laporan ke chat, agent menyimpannya sebagai berkas. **Jaminan mutu yang TIDAK dikorbankan:** prompt panjang tidak dihapus — ia pindah ke berkas paket yang ditunjuk SATU URL (anti salah-tempel, pelajaran insiden 2026-09-19); laporan tetap wajib jadi berkas Git; `--ambil-laporan` idempoten; temuan tetap dibantah-balik sebelum ditutup.

---

### AL-16 — Maraton kerja sama (beberapa sesi paralel, satu integrator)

> **Mode pemeriksaan laporan-saja (G3, mandat Lee 2026-09-21):** tiga pekerja hanya membuktikan klaim pada target tetap; tidak memperbaiki kode bersama. Lingkup tulis eksklusif = prefix laporan per tugas + UUID/hash, sedangkan pembacaan kode boleh beririsan. Pakai paket lengkap `docs/uji/maraton/` dan prompt pendek AL-15 yang integrator kirim langsung di chat (ID terisi, cabang pekerja otomatis dari platform—jangan dikarang). Target ber-CI-hijau; paket/SHA target terpisah. Wajib otomatis kirim via `alat/kirim-laporan.py --penanda <namespace-tugas>` dan verifikasi remote tanpa pengingat. Pekerja menguji di salinan unik; jangan `--susul`, checkout, pull/merge, rebase/reset/force, atau stage folder bersama. Integrator memanen **laporan saja tanpa merge cabang**, memeriksa ulang bukti lalu memperbaiki kode berurutan. Ini bukan izin merge/deploy. Aturan mode ini menggantikan langkah pekerja kode/panen merge di bawah untuk gelombang G3; bila keamanan/uang belum jelas, pemeriksaan boleh mengumpulkan bukti tetapi keputusan/perbaikan yang membutuhkan Lee tetap berhenti.

- **Apa ini:** kerja maraton dibagi ke beberapa sesi Arena sekaligus seperti tim: satu **sesi integrator** (sesi kerja utama) membagi tugas; **pekerja** (maksimal **4 per gelombang**) mengerjakan di cabang masing-masing dengan **lingkup berkas eksklusif** dan nomor migrasi cadangan. Hasil dipanen integrator **satu per satu** ke cabang resmi — tidak pernah dua tulisan masuk bersamaan. Papan: `docs/ops/PAPAN_TUGAS.md` (penulis tunggal: integrator; diperiksa `alat/periksa-maraton.py` + CI). **OPT-IN**: hidup hanya bila Lee meminta / agent menawarkan dan Lee setuju; tanpa itu sistem biasa.
- **Kapan dipakai:** ada ≥2 tugas yang benar-benar independen (mis. uji SQL vs dokumen vs komponen UI), CI hijau, handoff bersih. **Agent WAJIB menolak (dengan alasan + tawaran jalan serial) bila:** CI merah · handoff belum bersih · tugas tak bisa dipisah per kepemilikan berkas · sedang refactor satu modul · menyangkut keputusan uang/keamanan belum terkunci · menyentuh migrasi beku.
- **Kalimat Lee → yang terjadi:** `Siapkan maraton kerja sama.` → integrator menyiapkan gelombang (papan + prompt pekerja). · `<N> pekerja maraton sudah selesai.` / `Panen hasil maraton.` → integrator memverifikasi sendiri lalu memanen berurutan (boleh sebagian, tak harus tunggu semua) + menilai vs DoD.
- **Langkah Lee:** (1) bilang `Siapkan maraton kerja sama.`; (2) salin **prompt pekerja yang integrator kirim langsung di chat** (blok siap-tempel, baris pertama sudah terisi: ID tugas + cabang — Lee TIDAK perlu mencari berkas apa pun), buka sesi pekerja (base branch = cabang pekerja itu), tempel; (3) bila pekerja lapor selesai, kabari integrator: `Panen hasil maraton.`
- **PENTING — 1 pekerja = 1 sesi/chat BARU:** satu prompt per sesi agar mandat tidak bercampur. Ini **bukan jaminan cabang berbeda**; platform bisa memberi cabang/working tree yang sama. Mode laporan-saja memakai pengirim terisolasi. Untuk mode penyuntingan kode, berbagi working tree tidak aman hanya karena file berbeda: hentikan penulisan paralel sampai integrator menyiapkan isolasi; jangan pull/merge untuk memaksa push.
- **Yang agent lakukan:** INTEGRATOR: cek kelayakan → pecah tugas per **kepemilikan berkas** + cadangkan nomor migrasi → tulis papan (`DIBERIKAN`, DoD+bukti per tugas) → `alat/periksa-maraton.py` LOLOS → commit+push → **kirim TEKS LENGKAP tiap prompt pekerja langsung di chat sebagai blok kode siap salin-tempel (satu blok per pekerja, baris pertama terisi) — WAJIB; menunjuk berkas saja tanpa menempel isinya = melanggar alur ini**. Saat panen: verifikasi sendiri (papan + `git ls-remote` + baca `docs/ops/maraton/LAPORAN-<tugas>.md` — jangan andalkan kabar) → merge satu per satu, **setiap merge → seluruh baterai uji + CI** → `DITERIMA` / `DITOLAK (<alasan>)` (yang ditolak kembali ke kolam, tidak hilang senyap) → papan final LOLOS → penutup AL-3. PEKERJA: orientasi `PRO.md` MODE PEKERJA (tak bertanya "mau apa") → kerja HANYA di lingkup → uji lingkup hijau → tulis laporan → push cabang sendiri; DILARANG: cabang resmi, migrasi beku, berkas pagar/pemeriksa, keputusan uang, lockfile, papan/handoff.
- **Bukti yang Lee terima:** daftar tugas → status akhir masing-masing + hasil baterai/CI per merge + tugas yang kembali ke kolam (bila ada).
- **Lama:** siapkan ~15 menit; panen ~5–15 menit per pekerja.
- **Kalau macet:** pekerja macet = tulis jujur di laporan, integrator menilai saat panen; papan cacat = `alat/periksa-maraton.py` menolak → perbaiki papan dulu, jangan memanen di atasnya; lingkup ternyata tumpang tindih = pekerja berhenti, integrator yang memutuskan.
- **Dasar riset (2026-09-21):** konflik antar-agent turun ke ~0 bila kepemilikan berkas tidak tumpang tindih; merge wajib berurutan oleh satu integrator dengan verifikasi tiap langkah; klaim tugas eksplisit mencegah kerja ganda; jumlah pekerja dibatasi kapasitas panen, bukan semangat.

## Bagian C — Semua prompt (dengan label siapa yang memakai)

**Aturan label:** **[LEE → AGENT]** = tempel di sesi kerja · **[LEE → PENINJAU]** = tempel di chat BARU (auditor/peninjau). Kalau prompt salah tempat, agent menolak dengan sopan dan meminta yang benar — itu fitur, bukan kerusakan.

### C1. [LEE → AGENT] Prompt Pembuka Universal — untuk SETIAP sesi baru

> Blok di bawah **identik** dengan `PROMPT_ENTRI_UNIVERSAL.md` (dijaga pemeriksa otomatis supaya tidak bisa menyimpang).
> Tempel ini sebagai **pesan pertama** di sesi/percakapan baru sebelum memberi perintah apa pun.

```
ATURAN BAHASA (wajib, jangan dilanggar): semua komunikasi dengan Lee memakai **bahasa Indonesia** yang sederhana dan mudah dipahami — laporan, ringkasan, pertanyaan, dan kartu sesi. Istilah teknis hanya bila perlu dan langsung dijelaskan singkat. Jangan menjawab dalam bahasa lain kecuali Lee memintanya.

Bila ada `PRO.md` di root repo: BACA dan ikuti itu LEBIH DULU — berkas itu pintu masuk universal Lee (kalimatnya: "baca pro.md") dan memuat urutan orientasi wajib (susul sesi aktif, baca handoff/konteks, lalu tanya Lee mau apa).

Cek dulu apakah ada file PROJECT_STATE.md di root repo ini.

Kalau TIDAK ADA (repo kosong/baru): ini proyek baru. Baca AGENT_SYSTEM.md di repo ini secara penuh (di folder sistem-building-aplikasi/ bila sistem ini ada di repo meta, atau di root bila sudah jadi repo standalone), lalu mulai dari TAHAP 1 (Discovery) sesuai AGENT_SYSTEM.md.

Kalau ADA: baca isinya, lihat nilai STATUS-nya, lalu ikuti instruksi yang sesuai di AGENT_SYSTEM.md untuk STATUS tersebut (FONDASI_TAHAP_2_PRD s/d CODING_AKTIF / SIKLUS_BARU).

Setelah kamu tahu posisi kita:

0. JALANKAN BOOTSTRAP SESI: python3 alat/mulai-sesi.py — script ini mencetak KARTU SESI: posisi proyek, keadaan branch/PR, log sesi terbaru, DAFTAR SKILL yang wajib kamu baca untuk fase sekarang, dan berkas fondasi yang wajib dibaca. Kalau script tidak ada/gagal, pakai tabel fase-ke-skill di docs/AGENT_OPERATING_GUIDE.md bagian 2.
1. BACA sungguhan setiap berkas SKILL.md yang tercantum di KARTU SESI (beserta referensi yang ditunjuknya bila relevan) — jangan hanya menyebutnya. Semua skill sudah tersimpan lokal di skills/ (tidak perlu internet, tidak perlu npx). Kalau ada skill yang dibutuhkan fase ini tapi tidak ada di repo, LAPORKAN — jangan dilewati diam-diam.
2. Baca SYSTEM_MANIFEST.md dan STATUS.md (identitas, tahap, pekerjaan belum tersimpan) + PROJECT_STATE.md (posisi sekarang).
2b. Baca docs/teknis/REKAM_PESAN_PEMILIK.md — rekam SEMUA permintaan pemilik (Lee) beserta statusnya. Jangan menutup atau
    mengubah butir di sana tanpa jawaban Lee, dan jangan mengulang pekerjaan yang sudah berstatus selesai di berkas itu.
2c. Bila ada `docs/ops/SIAP-LANJUT.md`, BACA lebih dulu: itu penunjuk keadaan yang dibuat mesin (cabang kerja terakhir, commit, keadaan CI, butir tertangguh, rencana berikutnya). Kalau checkout-mu TIDAK memuat pekerjaan terakhir (mis. kamu mulai dari `main` sedangkan pekerjaan ada di cabang sesi), JANGAN bekerja dulu — susul cabangnya lebih dulu (`git fetch origin <cabang>:refs/remotes/origin/kerja-terakhir && git merge --ff-only origin/kerja-terakhir`), lalu laporkan. 
2d. Kalau Lee memakai KALIMAT PERINTAH SEDERHANA (contoh: `Siapkan audit menyeluruh.` · `Siapkan review PR.` · `Siapkan pindah ke sesi baru.` · `Tutup sesi ini dengan baik.`), JANGAN mengarang langkah sendiri: buka buku pedoman induk `PANDUAN_PENGGUNA.md` dan cari kalimat itu di **Bagian C3** (kalimat sehari-hari) atau **Bagian B** (alur AL-1…AL-13: langkah, berkas yang dibaca, bukti yang dilaporkan) dan **Bagian E** (perintah mesin). Cocokkan **MAKSUDNYA**, bukan huruf per huruf (mis. "dengan baik" = "dengan benar"; urutan kata boleh beda), ikuti langkah alurnya apa adanya, sebut nomor alurnya saat melapor (mis. "AL-13"), dan jangan menambah mekanisme baru di luar buku itu.
3. Verifikasi branch/working tree. Ingat fakta platform: branch arena/... dibuat otomatis dan tidak bisa diganti; base branch dipilih di awal sesi (rekomendasi: main); setiap sesi bisa memakai MODEL AI YANG BERBEDA; setelah PR di-merge atau di-close, akses sesi itu hilang. Laporkan branch aktif, jarak commit terhadap main, commit terakhir, dan working tree bersih/kotor. **Kalau pekerjaan sesi sebelumnya belum di-merge dan kamu perlu melihatnya, pilih base branch = cabang arena sesi itu (mis. arena/01a0a8a2-resto-barokah) saat membuat sesi baru — jangan merge PR hanya supaya bisa melihat pekerjaan.**
3b. Kalau ruang kerja baru dinyalakan ulang: (a) pustaka aplikasi bisa hilang → `bash aplikasi/alat/pratinjau.sh` memasang & menyalakan pratinjau; (b) salinan Git lokal bisa mundur ke `main` → `bash alat/pulihkan-git.sh` untuk memeriksa dan `bash alat/pulihkan-git.sh --perbaiki` bila memang tertinggal (tanpa `--hard`/`--force`). JANGAN menulis ulang berkas dari ingatan — ambil dari GitHub.
4. Cek dan laporkan semua PR (gh pr list --state all) — PR menggantung dari sesi lama bisa membuatmu bekerja dari dasar yang ketinggalan.
5. Cari file LOG_SESI_*.md terbaru di _log-sesi/. Kalau keadaannya OPEN, BACA header Keadaan Sesi + kronologi terakhir, lalu LAPORKAN keadaan sesi sebelumnya SEBELUM bertanya tujuan — jangan minta aku menjelaskan ulang konteks yang sudah tercatat di sana.
6. Baca docs/TERTANGGUH.md (buku tunggu) — KARTU SESI sudah mencetak daftar butir terbukanya. Setiap butir berarti ada hal yang SENGAJA ditunda; kamu WAJIB melaporkan jumlah & ID-nya, dan TIDAK BOLEH menutupnya tanpa jawaban pemilik (kecuali bisa dibuktikan dari dokumen yang sudah dikunci — tulis alasannya).
7. Laporkan posisi + KARTU SESI yang sudah terisi (termasuk: "Skill terpasang: N berkas dari M skill", fondasi yang dibaca, posisi sekarang, rencana sesi ini, yang dibutuhkan dariku) — SEBELUM mulai bekerja.
8. Berdasarkan jawabanku tentang tujuan sesi, baca sendiri file yang relevan (docs/*, PROJECT_STATE.md, docs/ROADMAP.md, docs/DECISIONS_LOG.md) — TANPA perlu aku tempel manual.
9. Jangan menulis/mengeksekusi apa pun sebelum tujuan sesi dikonfirmasi.

MODE MARATON (aturan kerja yang disetujui pemilik): bekerjalah terus-menerus dalam batch — satu perintah "lanjut" dariku = kerjakan sebanyak mungkin tugas berikutnya yang TIDAK tertangguh, tanpa bertanya. Hal yang bisa ditunda JANGAN dijadikan pertanyaan: tunda, catat di docs/TERTANGGUH.md (isi: kenapa boleh ditunda, nilai sementara, tenggat fase, siapa yang menjawab), lalu lanjut bekerja. Kamu HANYA boleh berhenti untuk bertanya pada Stop Conditions: (1) keamanan/uang/data pelanggan belum jelas, (2) muncul biaya apa pun, (3) dokumen fondasi bertentangan, (4) mau mengubah keputusan yang sudah dikunci/di DECISIONS_LOG, (5) tindakan merusak/tak bisa dibatalkan (hapus data, force push, deploy publik), (6) butir tertangguh sudah lebih dari 12 atau tenggatnya lewat. Setiap akhir batch: commit + push + perbarui ROADMAP/PROJECT_STATE/STATUS/LOG_SESI + tawarkan jawaban untuk semua butir tertangguh (aku cukup bilang "setuju semua").

Sebagai langkah TERAKHIR nanti sebelum sesi ini berakhir (baik karena tahap/task selesai, atau karena aku minta checkpoint): WAJIB perbarui PROJECT_STATE.md + STATUS.md + tutup LOG_SESI (CLOSED) + jalankan `python3 alat/lanjut-sesi.py --siapkan` (menyegarkan handoff `docs/ops/SIAP-LANJUT.md` dan memastikan berkas prompt statis `PROMPT_SESI_BARU.md` utuh — berkas itu TIDAK ditulis ulang tiap batch), COMMIT & PUSH semua pekerjaan (tanpa push, pekerjaan bisa hilang dan sesi berikutnya tidak bisa melanjutkan), lalu jalankan `python3 alat/lanjut-sesi.py` sampai LOLOS — barulah laporkan bahwa sesi aman ditutup, sebutkan commit terakhir, dan sebutkan berkas yang disalin Lee untuk lanjut di chat baru (`PROMPT_SESI_BARU.md`, baris pertamanya diisi Lee).
```

### C2. [LEE → AGENT] Prompt Penutup Sesi (aman)

**Prompt Penutup Sesi** — dipakai saat Lee mau menutup sesi dengan aman:

Sebelum menutup sesi — kerja mau di-merge, mau jeda, atau sesi sudah panjang — tempel ini:

```
Tutup sesi ini dengan benar:
1. Update PROJECT_STATE.md (STATUS + DETAIL + UPDATE TERAKHIR) sesuai tahap/fase yang baru selesai — tulis tahap BERIKUTNYA sebagai STATUS.
2. Update STATUS.md di folder sistem-building-aplikasi/ (tahap selesai, tahap berikutnya, pekerjaan belum tersimpan = Tidak ada, waktu pembaruan = YYYY-MM-DD — peristiwa).
3. Tutup log sesi ini: file _log-sesi/ — isi final "Keadaan Sesi" (yang selesai, yang terbuka, langkah berikutnya) dan tandai CLOSED kalau tuntas (atau OPEN + "dilanjutkan di ...").
4. Cek working tree: semua perubahan WAJIB ter-commit dan ter-push — tanpa itu sesi baru tidak bisa melanjutkan (fakta platform).
5. Kalau ada /docs baru/selesai, pastikan sudah ter-commit dan PROJECT_STATE sudah menunjuk tahap berikutnya.
6. Ringkaskan kondisi akhir: commit terakhir, status PR, dan langkah aman berikutnya.
7. Kalau aku mau merge PR: pastikan semua sudah push SEBELUM merge — setelah merge/close, sesi ini TIDAK BISA push lagi (batasan platform); kerja lanjutan harus dari sesi baru yang dibuka dari main.
```

---


### C3. [LEE → AGENT] Kalimat untuk situasi sehari-hari

| Situasi | Kalimat Lee |
|---|---|
| Maraton kerja sama (paralel, satu integrator) | `Siapkan maraton kerja sama.` (= **AL-16** — agent boleh menolak dengan alasan bila fase tidak mengizinkan) |
| Pekerja maraton sudah selesai | `<N> pekerja maraton sudah selesai.` / `Panen hasil maraton.` (= **AL-16** panen berurutan + penilaian) |
| Buka sesi baru untuk APA PUN (lanjut/update/pemeriksaan/tanya) | `baca pro.md` — agent wajib orientasi dulu lewat `PRO.md` (susul sesi aktif, baca handoff/konteks), lalu bertanya mau apa |
| Melanjutkan sesi lama di sesi ini | `mau lanjut sesi` / `lanjutkan sesi yang kemarin` (= susul cabang aktif per `PRO.md` + kerjakan rencana §3 handoff) |
| Minta dijelaskan | `Jelaskan dengan bahasa sederhana: apa yang baru berubah, dan apa risikonya buat aku.` |
| Minta audit menyeluruh | `Siapkan audit menyeluruh.` / `Siapkan pemeriksaan independen menyeluruh.` (= **AL-15**) |
| Minta audit bidang tertentu | `Siapkan pemeriksaan menyeluruh di bidang keamanan.` (= **AL-15**, `--bidang keamanan`) |
| Minta audit terarah | `Siapkan audit independen untuk <lingkup: keamanan akun / Fase 1 / seluruh sistem>.` |
| Laporan sudah masuk | `Laporan audit sudah masuk, periksa.` / `Laporan review sudah masuk, periksa.` (= **AL-15**) |
| Minta review PR | `Siapkan review PR.` (= **AL-15**) |
| Pemeriksaan fondasi | `Jalankan pemeriksaan fondasi.` (= **AL-15**, jalan langsung tanpa sesi baru) |
| Pekerjaan lama diulang | `Audit dampaknya dulu, lalu ulangi pekerjaan lama yang jadi bertentangan.` |
| Menutup sesi dengan aman | `Tutup sesi ini dengan benar.` — atau `Tutup sesi ini dengan baik.` (= **AL-3**) |
| Tutup sesi **sekaligus** pindah ke sesi baru | `Siapkan pindah sesi dan tutup sesi ini dengan baik.` (= **AL-3 + AL-13**) |
| Pindah ke sesi LAIN (bukan sesi terakhir) | `Tampilkan daftar sesi yang bisa dilanjutkan.` (= **AL-13**) |
| Merasa ada yang tidak beres | `Aku merasa ada yang tidak beres pada <hal>. Jangan membela pekerjaan sebelumnya — buktikan ulang dari nol.` |
| Berhenti karena mutu | `Berhenti dulu, aku mau batch bersih.` |
| Sedang pegang layar, minta dipandu | `Tolong bimbing.` / `Mode bimbingan.` / `Beri arahan step by step.` (= **AL-14**) |
| Selesai dibimbing, kembali normal | `Sudah beres, lanjut normal.` (= menutup **AL-14**) |
| Lihat hal tertunda | `Tunjukkan daftar hal yang ditunda beserta usulan jawabannya.` |
| Setuju semua usulan | `Setuju semua.` |
| Selain satu hal | `Selain <hal>, setuju semua.` |
| Uji di perangkat | `Tunjukkan cara menguji ini di perangkatku.` |
| Ubah gaya/panggilan | `Mulai sekarang panggil aku Lee.` |
| Terlalu teknis | `Terlalu teknis, sederhanakan.` |

> **Catatan penting (jawaban atas pertanyaan Lee 2026-09-18):** kalimat-kalimat di atas **cukup** — asal agent baru **mau membaca peta ini**. Karena itu Prompt Pembuka Universal (item 2d) dan **KARTU SESI** sekarang sama-sama menunjuk ke sini: setiap perintah sederhana di tabel ini memetakan ke satu alur di **Bagian B** (AL-1…AL-13) yang memuat langkah, berkas yang dibaca, dan bukti yang dilaporkan. Agent mencocokkan **maksud** kalimatmu (bukan huruf per huruf), menyebut nomor alurnya saat melapor, dan **dilarang mengarang mekanisme baru**. Perintah yang **tidak ada** di tabel ini atau di Bagian E: agent wajib melapor, lalu bertanya.
> Lee **tidak perlu** menyuruh agent menyiapkan paket, menulis prompt, atau mengatur branch — itu tugas agent. Bagian ini dulu berisi
> separuh perintah teknis yang seharusnya dikerjakan agent; sejak 2026-09-17 perintah itu **dipindahkan ke tugas agent** (Bagian B, AL-5).

> **Kalau chat sudah berat / mau lanjut di chat baru:** `Siapkan pindah ke sesi baru.`
> Agent menyegarkan handoff `docs/ops/SIAP-LANJUT.md`; **Lee** menyalin `PROMPT_SESI_BARU.md` (berkas **statis** — cukup diisi baris pertama: sesi mana yang dilanjutkan) ke chat baru. Mekanismenya dijaga mesin (`python3 alat/lanjut-sesi.py`), jadi handoff tidak bisa basi diam-diam. Rinciannya: **AL-13**.

### C4. [LEE → PENINJAU] Prompt Auditor Independen (audit menyeluruh / terarah)

> Blok di bawah **identik** dengan `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` bagian B (dijaga pemeriksa).
> Biasanya Lee **tidak perlu** menyalin ini sendiri: berkas SIAP-TEMPEL di `docs/uji/paket-audit/` sudah memuatnya + paketnya.
> Pakai blok ini kalau berkas SIAP-TEMPEL belum ada atau ingin menambah lingkup.

```
Kamu adalah AUDITOR INDEPENDEN untuk proyek Resto Barokah. Kamu BUKAN penulis kode ini dan kamu
TIDAK BOLEH mengubah, memperbaiki, atau menerapkan perubahan apa pun. Tugasmu menemukan masalah,
bukan menyenangkan pembuatnya.

Kerjakan berurutan:
0. Ambil paket UTUH melalui repo + cabang sumber + SHA paket + path dari prompt pendek,
   memakai git/gh terautentikasi (privat juga); SHA target berbeda dari SHA paket.
   Jika akses/sasaran gagal, berhenti dan laporkan; jangan menebak. Baca target via objek
   Git/salinan sementara unik, TANPA checkout/detach pada working tree bersama.
1. Baca `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` (aturan main), lalu paket audit yang saya tempel di bawah.
2. Muat skill yang disebut paket: `skills/security-review/SKILL.md`, `skills/verification-before-completion/SKILL.md`,
   `skills/systematic-debugging/SKILL.md`, `skills/verification-loop/SKILL.md`, `skills/test-driven-development/SKILL.md`,
   `skills/prd-taskmaster/SKILL.md`, `skills/supabase/SKILL.md`, `skills/supabase-postgres-best-practices/SKILL.md`,
   dan `skills/ui-ux-pro-max/SKILL.md` bila menyentuh tampilan. Bila butuh skill lain, gunakan `skills/find-skills`
   atau `skills/agent-skills-hub/CATALOG.md`.
3. Kerjakan SEMUA lensa yang diminta paket. Untuk tiap lensa tulis: apa yang kamu periksa, perintah yang kamu jalankan,
   dan HASIL NYATA (tempel keluaran penting, bukan ringkasan keyakinan).
4. Bantah klaim pembangun di paket — jangan mempercayainya. Kalau perintah bukti tidak bisa dijalankan
   (mis. pustaka belum dipasang), tulis di bagian "Yang tidak bisa saya verifikasi", jangan menebak.
5. Setiap calon temuan: uji ulang di kode sekarang (buka berkas, telusuri pemanggil, jalankan perintah). Tidak bisa
   dibuktikan → tandai DUGAAN. Bisa dibuktikan → TERVERIFIKASI + sertakan perintahnya.
6. Kamu boleh (dan dianjurkan) mencari referensi internet untuk perilaku Supabase/PostgreSQL/OWASP; cantumkan tautannya.
7. Laporkan SEMUA yang kamu temukan — termasuk yang di luar cakupan/lensa yang diminta (isi bagian 8 laporan).
   Ambang minimum di paket adalah LANTAI, bukan target: jangan berhenti setelah mencapai angka minimum, dan jangan
   menambah baris demi memenuhi syarat. Jangan menyusun laporan supaya lolos pemeriksa — formatnya sudah lengkap di paket.
8. Tulis laporan PERSIS format paket, memakai draf UUID yang dialokasikan pengirim
   dari SHA paket. Nama cabang bukan penanda sesi unik. Kode proyek tidak boleh diubah;
   draf/cadangan/salinan uji terisolasi diperbolehkan.
9. Validasi laporan dengan `alat/audit-independen.py --periksa-laporan <path>` pada
   salinan terisolasi bila checkout bersama kotor. Perbaiki kelengkapan, bukan mengarang temuan.
10. Tanpa meminta Lee lagi, otomatis commit dan push lewat `alat/kirim-laporan.py`
    --jenis audit --sumber <cabang-sumber> --laporan <path>; ikuti langkah bootstrap
    dan keseluruhan `docs/uji/PENGIRIMAN_LAPORAN_AMAN.md` dari SHA paket.
    Pengirim memakai snapshot/index terisolasi + retry fast-forward; jangan git add
    folder, merge/rebase/reset/force/menimpa atau menyatukan verdict.
11. Wajib verifikasi remote: repo, cabang tujuan, path, commit SHA, remote_tip, SHA-256
    dan hasil cek sebenarnya. Chat/lokal saja bukan selesai. TERBLOKIR: simpan laporan,
    nyatakan BELUM TERVERIFIKASI dan hambatan; jangan meminta token. Kirim verdict serta
    ringkasan tanpa menyamakan keberhasilan transport dengan penerimaan temuan.

Larangan keras: memuji, "looks good", melaporkan soal gaya penulisan sebagai temuan, mengubah berkas selain laporan,
mempercayai klaim tanpa membuktikannya, menaikkan verdict di atas bukti, dan menyusun laporan demi memenuhi ambang /
kelulusan pemeriksa — itu teater, bukan audit.

Paket audit:
<<< TEMPEL ISI docs/uji/paket-audit/… DI SINI >>>
```

### C5. [LEE → PENINJAU] Prompt Peninjau PR Independen

> Blok di bawah **identik** dengan `docs/uji/PROMPT_REVIEW_PR_INDEPENDEN.md` bagian B (dijaga pemeriksa).
> Sama seperti audit: berkas SIAP-TEMPEL di `docs/uji/review-pr/` sudah memuat ini + paketnya.

```
Kamu adalah PENINJAU PR INDEPENDEN untuk proyek Resto Barokah. Kamu BUKAN penulis perubahan ini, bukan sesi yang
mengerjakannya, dan kamu TIDAK BOLEH mengubah, memperbaiki, atau menerapkan perubahan apa pun. Tugasmu: membantah
klaim pembangun dan menemukan masalah nyata pada perubahan (diff) yang dimaksud — bukan menyenangkan pembuatnya.

Kerjakan berurutan:
1. Baca `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` (aturan main), lalu paket review yang saya tempel di bawah.
2. Muat skill yang relevan dari daftar paket (mis. `skills/security-review/SKILL.md`,
   `skills/verification-before-completion/SKILL.md`, `skills/systematic-debugging/SKILL.md`,
   `skills/verification-loop/SKILL.md`, `skills/test-driven-development/SKILL.md`, `skills/supabase/SKILL.md`).
   Bila butuh skill lain, pakai `skills/find-skills` atau katalog `skills/agent-skills-hub/CATALOG.md`.
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
```

### C7. Cara review & merge perubahan (tanpa membaca kode)

Lee **tidak perlu** membaca *Files changed*. Alurnya:

1. Agent bekerja di cabang → commit + push → membuka PR (tanpa auto-merge).
2. Agent **menyiapkan review PR independen** (AL-6) dan memberitahu Lee nama berkas SIAP-TEMPEL.
3. Lee menyalin berkas itu ke chat baru; peninjau menulis laporan; agent memvalidasi dan memperbaiki temuan K-1/K-2.
4. Agent menyerahkan **Kartu Keputusan** (7 baris) ke Lee: `BOLEH MERGE` atau `JANGAN MERGE DULU` + alasannya.
5. Kalau Lee setuju: buka PR di GitHub → tab **Conversation** → tombol hijau **Merge pull request**. Kalau belum: tulis komentar di PR; agent memperbaiki di sesi baru.
6. **Sebelum menekan merge, pastikan tidak ada sesi lain yang masih bekerja** di cabang itu (merge = sesi itu kehilangan akses).
7. Kalau ingin melihat sendiri: tab **Files changed** menunjukkan berkas yang berubah (hijau = ditambah, merah = dihapus) — **tidak wajib dibaca**; gunakan Kartu Keputusan.

> **Yang boleh dan tidak boleh Lee putuskan sendiri:** merge = keputusan Lee. Tapi kalau Kartu Keputusan berkata `JANGAN MERGE DULU`, agent wajib menjelaskan apa yang kurang dengan bahasa sederhana — dan Lee tidak disarankan memaksa merge.

### C6. Cara mengisi paket audit/review (kalau disuruh memilih)

| Yang diminta paket | Artinya | Yang Lee tulis |
|---|---|---|
| "Lingkup" | bagian mana yang diperiksa | `seluruh sistem` / `keamanan akun` / `Fase 1` |
| "Tugas (T1-01…)" | nomor tugas ROADMAP | tidak perlu — agent yang mengisi |
| "Nama PR" | PR mana | `PR #1` atau `yang sedang dibuka` |
| "Kalibrasi" | latihan uji ketajaman | tidak perlu — bahan sudah disiapkan agent |

---

## Bagian D — Semua mekanisme yang berjalan

### D1. Daftar mekanisme

| # | Mekanisme | Kapan jalan | Siapa menjaga | Cara Lee memakai | Bukti yang bisa dilihat |
|---|---|---|---|---|---|
| C1 | **Fondasi 6 dokumen** (Discovery → PRD → Tech Spec → aturan agent → Roadmap → cross-check) | di awal proyek, diperbarui bila ada detail baru | Agent | minta dijelaskan bila ingin tahu | `python3 alat/periksa-roadmap.py` LOLOS · `python3 alat/periksa-fondasi-independen.py` BERSIH |
| C2 | **Maraton & buku tunggu** (hal ditunda + tenggat; maks 12) | setiap batch | Agent (isi) · Lee (menutup) | AL-10 | `docs/TERTANGGUH.md` |
| C3 | **Keamanan akun, perangkat, sesi** (PIN di perangkat terdaftar · TOTP untuk peran berkuasa · pencabutan seketika · jalur pemulihan perangkat hilang) | sejak Fase 1B | Agent | minta dijelaskan; keputusan ada di tangan Lee | `docs/KEAMANAN.md` + uji SQL keamanan |
| C4 | **Kelengkapan layar & tombol** (registri aksi, kontrak layar, 7 keadaan, tombol wajib diuji, perilaku & gerakan) | sejak Fase 1C | Agent | AL-11 (uji di perangkat) | `alat/peta-ui.py` (rencana, Fase 1C) + uji komponen (rencana, Fase 1C) |
| C5 | **Audit independen** (AUD-0…AUD-3 + kalibrasi) | sebelum fase baru, sebelum pilot, kapan pun Lee minta | Sesi peninjau | **AL-5** | laporan lolos `alat/audit-independen.py --periksa-laporan` + skor kalibrasi |
| C6 | **Review PR independen** (RV-1…RV-3 + Kartu Keputusan) | setiap PR sebelum merge | Sesi peninjau | **AL-6** | Kartu Keputusan 7 baris (`alat/review-pr.py --kartu-keputusan`) |
| C7 | **Uji otomatis & CI** (uji SQL nyata, uji unit, pemeriksa dokumen & buku) | setiap kiriman kode | Mesin | minta "uji semuanya" | riwayat CI hijau/merah di `.github/workflows/ci.yml` |
| C8 | **Kedaruratan** (perangkat hilang, akun bocor, pegawai berhenti, data bocor 3×24 jam, internet mati, printer, cadangan) | saat masalah | Lee + admin cabang | **AL-9** | `docs/teknis/BUKU_INSIDEN.md` |
| C9 | **Data pelanggan & UU PDP** (persetujuan, minimalisasi, anonimisasi, pemberitahuan kebocoran) | sebelum data pelanggan dikumpulkan (Fase 8) | Agent (teknis) · Lee (kebijakan) | minta dijelaskan; meninjau draf | `docs/KEAMANAN.md` §11 + uji (T8-15) |
| C10 | **Biaya nol** (batas layanan gratis, kapan naik kelas) | sepanjang proyek | Agent (jaga) · Lee (keputusan bila berbiaya) | tidak perlu — agent wajib lapor bila muncul biaya | catatan batas di `docs/TECH_SPEC.md` §10 |
| C11 | **Laporan harian & notifikasi** (omzet, void, diskon, selisih kas, percobaan masuk gagal, perubahan perangkat) | setelah fitur jadi (Fase 10) | Mesin + agent | menerima email + melihat layar Peringatan | berkas rencana `supabase/functions/ringkasan_harian/index.ts` (rencana, Fase 10) + email harian |
| C13 | **Lanjut sesi tanpa kehilangan konteks** (handoff dijaga mesin: cabang, commit, CI, butir tertangguh, rencana; berkas prompt Lee statis) | setiap kali pindah chat / menutup sesi | Mesin (`alat/lanjut-sesi.py`) + agent | **AL-13** — cukup bilang `Siapkan pindah ke sesi baru.` | `docs/ops/SIAP-LANJUT.md` · `PROMPT_SESI_BARU.md` · `docs/ops/SESI_DITINGGALKAN.md` · hasil `python3 alat/lanjut-sesi.py` (LOLOS) |
| C12 | **Buku Uji Pemilik** — apa yang harus Lee lakukan & coba, ditulis bertahap | sepanjang proyek | Lee (mengisi) · Agent (menambah baris + menjaga mesin) | satu lembar kerja: langkah, harapan, kotak hasil, catatan | `docs/uji/BUKU_UJI_PEMILIK.md` · `alat/periksa-buku-uji.py` |

### D2. Cara kerja audit & review (yang paling perlu Lee pahami)

**Audit independen (C5).**
1. **Siapa peninjau:** **sesi baru**, kalau bisa **model berbeda**, dan **hanya-baca** (tidak boleh memperbaiki).
2. **Enam lensa:** Ancaman & Akses · Uang & Jejak · Kesepakatan Dokumen · Mutu Uji · Lapangan/UI · Privasi & Kepatuhan.
3. **Kalibrasi cacat tanaman:** agent menanam cacat **sengaja** (termasuk cacat tersembunyi) di bahan terpisah; peninjau mencari tanpa tahu jawabannya. Kalau banyak yang terlewat → laporan ditandai **belum terkalibrasi** dan verdict "BERSIH"-nya tidak dipakai.
4. **Kontrak laporan:** tiap temuan wajib punya perintah bukti + skenario gagal; "BERSIH" tidak sah kalau ada temuan K-1/K-2.
5. **Gerbang (dipilih Lee): `tahan_semua`** — K-1 **dan** K-2 menahan fase sampai ditutup dan diverifikasi.

**Review PR independen (C6).**
1. **Kenapa:** Lee tidak bisa membaca *Files changed*, jadi penilaian dilakukan peninjau independen yang menghasilkan **Kartu Keputusan** berbahasa manusia; keputusan merge tetap di tangan Lee (riset: alat AI review tidak boleh jadi satu-satunya penilai untuk uang/keamanan/data pelanggan).
2. **Jalur risiko menentukan kedalaman:** 🔴 Merah (migrasi database, izin/RLS, uang, data pelanggan, pemeriksa CI) → wajib lensa L1+L2+L4, uji mutasi, rencana pemulihan · 🟡 Kuning (logika aplikasi, alat, dokumen fondasi) → L3+L4 · 🟢 Hijau (dokumen biasa, catatan) → L3.
3. **Syarat merge (5):** CI hijau pada commit PR · review independen selesai · tidak ada K-1/K-2 terbuka · kalibrasi terakhir tidak gagal (untuk Jalur Merah) · Kartu Keputusan sudah di tangan Lee.
4. **Kalibrasi (RV-3):** bahan berisi cacat sengaja pada diff; skor `Ditemukan: X dari Y` dicatat di `docs/uji/REVIEW_PR_RIWAYAT.md`.
5. **Batas jujur:** kalau platform hanya menyediakan satu model, korelasi cacat tetap ada → dicatat sebagai keterbatasan di laporan.

### D3. Cara kerja keamanan akun (ringkas, karena ini yang paling sensitif)

- **Satu orang satu peran** — kalau satu orang punya dua tugas, dibuatkan **dua akun**.
- **Hanya di perangkat terdaftar:** tiap peran hanya bisa bekerja dari perangkat yang didaftarkan admin cabang/owner pusat.
- **Login staf cepat tapi aman:** PIN untuk staf (cepat), TOTP (kode 6 angka di aplikasi authenticator) untuk owner pusat, admin cabang, dan pemilik platform.
- **Perangkat hilang:** tangga pemulihan 4 tingkat (staf → cabang; admin → owner; owner → kode pemulihan di amplop; darurat terakhir → pemilik platform). Kode pemulihan hanya boleh dipakai **owner pusat**, tercatat, dan diberitahukan.
- **Jejak:** percobaan masuk gagal, perubahan perangkat, dan tindakan sensitif tercatat (bisa diperiksa).
- Rincian: `docs/KEAMANAN.md`. Keputusan yang Lee ambil tercatat di `docs/DECISIONS_LOG.md`.

---

## Bagian E — Semua perintah mesin (fungsi + cara pakai)

**Cara Lee memperlakukan bagian ini:** Lee **tidak wajib** mengetik perintah apa pun. Lee cukup memakai kalimatnya; agent yang menjalankan perintahnya. Perintah ditulis di sini supaya Lee tahu **apa yang sedang terjadi** dan bisa meminta buktinya.

| Perintah | Kalimat Lee | Fungsinya (apa yang dikerjakan) | Hasil yang Lee lihat | Kalau GAGAL artinya |
|---|---|---|---|---|
| `python3 alat/audit-independen.py --paket AUD-3 --semua` | `Siapkan audit menyeluruh.` | Menulis **paket audit menyeluruh** (semua berkas proyek + berkas untuk Lee) + berkas **SIAP-TEMPEL** | nama dua berkas di `docs/uji/paket-audit/` | berkas bahan kalibrasi belum ada → agent menyiapkannya dulu |
| `python3 alat/audit-independen.py --paket AUD-2 --tugas T1-01..T1-10` | `Siapkan audit independen untuk Fase 1.` | Paket audit **terarah** pada lingkup tertentu | nama paket + berkas SIAP-TEMPEL | nomor tugas salah → agent memeriksa daftar tugas di `docs/ROADMAP.md` |
| `python3 alat/audit-independen.py --periksa-laporan <berkas>` | `Laporan audit sudah masuk, periksa.` | **Memvalidasi laporan peninjau** (bagian wajib, bukti, konsistensi verdict) — laporan malas ditolak | LOLOS/GAGAL + daftar kekurangan | laporan tidak memenuhi kontrak → diminta dilengkapi (bukan diterima apa adanya) |
| `python3 alat/audit-independen.py --ambil-laporan` | `Laporan audit sudah masuk, periksa.` | **Menarik laporan auditor** dari cabang sesinya di GitHub ke `docs/uji/audit/` (jalur pulang laporan). Menelusuri seluruh riwayat cabang, jadi laporan yang tertimpa sesi lain tetap terselamatkan | daftar laporan + cabang asalnya + bukti berkas-tunggal | "TIDAK ADA laporan baru" → peninjau belum push; minta ia push atau tempel laporannya di chat |
| `python3 alat/audit-independen.py --verifikasi-lingkup` | (dijalankan peninjau) | Memastikan peninjau memeriksa **commit yang benar**, dari base branch mana pun | COCOK / BEDA COMMIT / TARGET TIDAK ADA + langkah pastinya | TARGET TIDAK ADA → peninjau berhenti & lapor (bukan mengaudit commit lain) |
| `python3 alat/review-pr.py --ambil-laporan` | `Laporan review sudah masuk, periksa.` | **Menarik laporan peninjau PR** dari cabang sesinya | daftar laporan + cabang asalnya | sama: minta peninjau push, atau tempel di chat |
| `python3 alat/audit-independen.py --kalibrasi-nilai <laporan> --kunci <kunci>` | (dijalankan agent) | Menghitung **skor ketajaman peninjau** vs kunci jawaban | `X dari Y` + temuan palsu + status TERKALIBRASI | banyak cacat terlewat → verdict BERSIH tidak dipakai; audit ulang |
| `python3 alat/review-pr.py --siapkan --dasar origin/main --nama pr-01` | `Siapkan review PR.` | Menulis **paket review PR** + berkas **SIAP-TEMPEL** (kalimat pembuka + paket) | nama dua berkas di `docs/uji/review-pr/` + jalur risiko | tidak ada perubahan antara dasar & kepala → agent memeriksa apakah PR sudah berisi pekerjaan |
| `python3 alat/lanjut-sesi.py --siapkan` | `Siapkan pindah ke sesi baru.` | Menulis **handoff** untuk sesi baru (`docs/ops/SIAP-LANJUT.md`) + memastikan berkas prompt statis `PROMPT_SESI_BARU.md` utuh (memuat Prompt Pembuka apa adanya) | nama berkas handoff + keterangan berkas statis + ringkasan (commit, CI, butir tertangguh) | gagal = bukan repositori Git / berkas tidak bisa ditulis / cabang tujuan tidak ada di GitHub / cabang tujuan **tidak memuat keadaan kerja terbaru** (sesi baru akan kehilangan pekerjaan terbaru — perbaiki dengan `--lanjut-dari <cabang sesi ini>`, atau `--paksa` bila sesi ini memang ditinggalkan) |
| `python3 alat/lanjut-sesi.py` | (dijalankan agent) | Memeriksa handoff: ter-push, disegarkan di commit terakhir, berkas tempel memuat prompt kanonik & larangan merge | LOLOS / daftar masalah | GAGAL → jangan pindah sesi dulu; segarkan handoff (`--siapkan`) lalu commit & push |
| `python3 alat/review-pr.py --kesiapan` | (dijalankan agent) | Menjawab: **"apakah commit sekarang sudah punya paket review?"** | SIAP/BELUM + nama paketnya | BELUM → agent wajib menyiapkan paket sebelum meminta merge ke Lee |
| `python3 alat/review-pr.py --periksa-laporan <berkas>` | `Laporan review sudah masuk, periksa.` | Memvalidasi laporan peninjau PR | LOLOS/GAGAL + kekurangan | laporan ditolak → peninjau melengkapi |
| `python3 alat/review-pr.py --kartu-keputusan <berkas>` | (dijalankan agent) | Mencetak **Kartu Keputusan** 7 baris untuk Lee | commit · risiko · verdict · K-1/K-2/K-3 · cakupan · kalibrasi · rekomendasi | rekomendasi **JANGAN MERGE DULU** → agent memperbaiki dulu |
| `python3 alat/review-pr.py --kalibrasi-pr-siapkan` | (dijalankan agent) | Membuat **bahan kalibrasi** untuk review PR (diff berisi cacat sengaja) | berkas `docs/uji/kalibrasi/pr-bahan-*.diff` + kunci di luar repo | katalog cacat basi → agent memperbarui katalog |
| `python3 alat/review-pr.py --uji-diri` | (bagian dari "uji semuanya") | Membuktikan pemeriksa laporan review PR **bisa MENOLAK** laporan buruk (6 contoh: 1 bagus, 5 buruk — termasuk kasus verdict longgar, kedalaman hanya kata, dan paket hilang) | LOLOS + daftar contoh | GAGAL → mekanisme review tidak boleh dipercaya; agent memperbaiki alatnya dulu |
| `python3 aplikasi/alat/periksa-kerapatan.py` | (bagian dari "uji semuanya") | Menjaga **kerapatan tampilan (Nyaman/Padat)**: token jarak wajib mengecil di mode padat dan aturannya wajib menyasar kelas yang benar-benar dipakai aplikasi | `LOLOS` + jumlah token & kelas yang berubah | gagal → agent memperbaiki CSS; artinya tombol kerapatan akan terasa mati lagi |
| `python3 aplikasi/alat/periksa-antarmuka.py` | (bagian dari "uji semuanya") | Menjaga **cara kerja antarmuka**: panel pilihan wajib bisa ditutup dengan Esc (fokus pulang), klik di luar, dan fokus keluar · ujung daftar yang bisa digeser wajib punya jejak pudar **di elemen penggeser** (bukan wadah ber-bordir) · salinan CSS aplikasi wajib identik dengan sumber desain · ilmu desainnya wajib tetap tersimpan & terpakai | `LOLOS` + ringkasan blok CSS & kemampuan | gagal → agent memperbaiki antarmuka/sumber desain; artinya panel terasa "nyangkut" atau tepi daftar terpotong mentah lagi |
| `python3 alat/periksa-rahasia.py` | (bagian dari "uji semuanya") | Menjaga **rahasia**: lembar kunci pemilik tidak boleh masuk Git, dan tidak boleh ada kunci bertekanan tinggi di berkas yang terlacak | `LOLOS`, atau nama berkas + jenis kuncinya | gagal → agent mengeluarkan berkas itu dari Git & memberi tahu Lee untuk mengganti kunci |
| `python3 alat/periksa-bersih.py` | (bagian dari "uji semuanya") | Menguji **pohon bersih**: menyalin hanya berkas yang masuk Git, lalu menjalankan pemeriksa dokumen di salinan itu — supaya cacat yang cuma sehat di komputer sendiri (mis. rujukan ke berkas yang tidak ikut Git) tertangkap sebelum kirim, bukan baru di CI | `LOLOS` + daftar pemeriksa yang hijau + catatan berkas yang tidak ikut Git | gagal → ada dokumen merujuk berkas yang tidak ikut Git, atau berkas baru belum di-`git add` → agent memperbaiki rujukan/berkasnya |
| `python3 alat/periksa-temuan-audit.py` | (bagian dari "uji semuanya") | Menjaga **daftar temuan audit**: setiap temuan dari laporan auditor punya baris · `DITUTUP` wajib ber-bukti hidup · `TERBUKA` wajib bertugas ROADMAP | `LOLOS` + jumlah ditutup/terbuka | gagal → agent melengkapi daftar (temuan tidak boleh hilang) |
| `python3 alat/periksa-rujukan.py` | (bagian dari "uji semuanya") | Menjaga **rujukan hidup** di dokumen pengikat (Buku Insiden, KEAMANAN, daftar tunggu, riwayat audit) — rujukan mati di dokumen darurat pernah menyesatkan | `LOLOS`, atau daftar rujukan mati | gagal → agent memperbaiki rujukan, atau menandainya `(rencana)` + tugas |
| `python3 alat/periksa-panduan.py` | `Uji buku pedoman.` | Menjaga **buku ini**: bagian wajib ada, prompt berlabel & identik sumbernya, semua rujukan berkas hidup | LOLOS + jumlah baris/mekanisme/rujukan | ada rujukan mati / prompt tidak identik → buku diperbaiki di batch itu juga |
| `bash alat/uji-database.sh` | `Uji database.` | Menjalankan **uji database nyata** (PostgreSQL di dalam Node) | baris `uji: <jumlah> LULUS · 0 GAGAL` (jumlahnya bertambah setiap ada uji baru) | ada GAGAL → jangan lanjut; agent memperbaiki + menambah uji yang gagal itu sebagai uji tetap |
| `bash aplikasi/alat/periksa-semua.sh` | `Uji semuanya.` | Menjalankan **seluruh pemeriksa**: dokumen, roadmap, struktur, kontras desain, uji unit | `RINGKASAN: N lolos, 0 gagal` | ada gagal → agent memperbaiki sebelum melapor |
| `python3 _sistem/validate_system.py` | (bagian dari "uji semuanya") | Memeriksa **kesehatan sistem kerja** (berkas wajib, penanda arsip, klaim) | `VALIDATOR: PASS` | GAGAL → ada berkas/aturan sistem yang tidak konsisten |
| `python3 alat/periksa-roadmap.py` | (bagian dari "uji semuanya") | Memeriksa **kelengkapan 7 atribut & konsistensi** tugas ROADMAP | LOLOS + jumlah tugas | GAGAL → ada tugas tidak lengkap |
| `python3 alat/periksa-fondasi-independen.py` | (bagian dari "uji semuanya") | Memeriksa **janji dokumen fondasi vs kode** (tanpa memandang siapa yang menulis) | BERSIH/GAGAL | ada temuan → agent memperbaiki atau menambah tugas |
| `bash alat/pulihkan-git.sh` (+ `--perbaiki`) | `Pulihkan ruang kerja.` | **Memulihkan kerja** bila ruang kerja dinyalakan ulang dan salinan Git tertinggal | pernyataan AMAN / TERDETEKSI + commit sekarang | "BERHENTI: ada berkas belum di-commit" → agent menyelamatkan dulu (aman, tidak menghapus) |
| (otomatis di dalam `bash aplikasi/alat/periksa-semua.sh` dan `bash alat/uji-database.sh`) | — | **Memasang pustaka (`npm ci`) sekali** saat dijalankan di salinan yang baru dibuka — supaya kedua perintah uji bisa dijalankan apa adanya tanpa langkah persiapan (temuan review PR-07) | baris `== memasang pustaka … ==` saat pertama kali | pemasangan gagal → tidak ada internet atau `package-lock.json` berubah; agent memasang manual |
| `bash aplikasi/alat/pratinjau.sh` | `Nyalakan pratinjau.` | Menyalakan aplikasi supaya bisa dilihat di peramban | alamat pratinjau | gagal → agent memberi tahu cara alternatif + bukti gambar |
| `python3 alat/mulai-sesi.py` | (dijalankan agent di awal sesi) | Mencetak **Kartu Sesi**: posisi proyek, branch/PR, log terakhir, skill wajib | Kartu Sesi lengkap | berkas tidak ada → agent memakai jalur manual (tabel fase-ke-skill) |

> **Dua kalimat uji yang paling sering dipakai Lee.** `Uji semuanya.` dan `Uji database.` adalah **kalimat biasa di chat** — bukan mekanisme rahasia dan bukan benda yang harus "dipasang". Keduanya cuma cara singkat menyuruh agent menjalankan perintah yang sudah ada di tabel di atas, lalu **menempelkan hasilnya di chat**. Yang dijaga mesin adalah **isinya** (pemeriksa-pemeriksa itu sendiri), bukan kalimatnya. Kalau Lee tidak mengucapkannya pun, agent tetap menjalankan pemeriksaan itu sebelum setiap kiriman kode.

**Arti kode hasil:** `LOLOS`/`PASS`/`BERSIH` = aman; `GAGAL`/`MERAH` = ada yang harus diperbaiki **sebelum** lanjut; `catatan` = tidak menghambat tetapi wajib dilaporkan.

---

## Bagian F — Istilah (versi awam)

### F1. Istilah dasar

- **Repo** — folder besar di GitHub tempat semua dokumen + kode tersimpan. "Markas" kerja.
- **Branch (cabang)** — salinan kerja repo; tiap sesi agent dapat cabang sendiri supaya versi utama tidak rusak.
- **`main`** — versi utama yang dianggap bersih. Hasil kerja masuk sini setelah **merge**.
- **Commit** — "menyimpan" perubahan.
- **Push** — mengirim commit ke GitHub (baru aman setelah ini; kalau sesi berhenti sebelum push, pekerjaan bisa hilang).
- **PR (Pull Request)** — "usulan" memindahkan hasil kerja ke `main`.
- **Merge** — menyetujui PR sehingga hasilnya resmi masuk `main`. **Jangan merge selagi ada sesi lain masih bekerja.**
- **CI** — mesin pemeriksa otomatis di GitHub: setiap kiriman diuji; merah = belum boleh dianggap selesai.
- **PROJECT_STATE.md** — penunjuk "kita di tahap apa"; dibaca otomatis agent tiap sesi baru.
- **DECISIONS_LOG.md** — catatan keputusan penting + alasannya.
- **Fondasi vs Coding** — Fondasi = dokumen rencana; Coding = mengubah rencana jadi kode.

### F2. Istilah audit & review

| Istilah | Arti singkat |
|---|---|
| **AUD-0** | Audit dampak: memeriksa pekerjaan lama yang jadi bertentangan karena keputusan berubah |
| **AUD-1** | Periksa mesin (CI) pada setiap batch |
| **AUD-2** | Review independen sesi/model berbeda (akhir fase / perubahan berisiko) |
| **AUD-3** | Audit **menyeluruh**: semua berkas + semua lensa + kalibrasi (sebelum pilot) |
| **RV-1 / RV-2 / RV-3** | Periksa mesin pada PR / review PR independen / kalibrasi ketajaman peninjau |
| **K-1 Kritis** | Uang salah · data bocor · tidak bisa dipulihkan → wajib diperbaiki lebih dulu |
| **K-2 Tinggi** | Janji dokumen dilanggar · pengaman wajib hilang → wajib sebelum fase ditutup/merge |
| **K-3 Sedang** | Tidak konsisten · uji kurang · dokumen basi |
| **K-4 Catatan** | Kerapian; tidak menghambat |
| **TERVERIFIKASI / DUGAAN** | Sudah dibuktikan ulang / masih dugaan (tidak dihitung berat) |
| **Lensa (L1…L6)** | Sudut pandang pemeriksaan: ancaman · uang · dokumen · mutu uji · lapangan/UI · privasi |
| **Jalur risiko** | 🔴 Merah / 🟡 Kuning / 🟢 Hijau — menentukan sedalam apa review dilakukan |
| **Kalibrasi cacat tanaman** | Latihan dengan cacat sengaja untuk mengukur ketajaman peninjau |
| **Terkalibrasi** | Peninjau terbukti menemukan cacat sengaja; verdict BERSIH-nya boleh dipercaya |
| **Verdict** | Kesimpulan peninjau: `BERSIH` · `BERSIH-DENGAN-CATATAN` · `TIDAK-BERSIH` |
| **Kartu Keputusan** | Ringkasan 7 baris untuk Lee + rekomendasi BOLEH/JANGAN MERGE |
| **SIAP-TEMPEL** | Berkas siap disalin Lee ke chat peninjau (sudah memuat prompt + paket) |
| **Uji mutasi** | Sengaja merusak kode → pemeriksa harus MERAH; dipulihkan → LOLOS (bukti gerbang tidak tumpul) |

---

## Bagian G — Kalau ada masalah

| Masalah | Yang Lee lakukan | Rujukan |
|---|---|---|
| Tablet/HP kerja hilang atau dicuri | Cabut perangkat dari aplikasi (Pengaturan → Perangkat) → ganti PIN pegawai terakhir → periksa aktivitas hari itu | `docs/teknis/BUKU_INSIDEN.md` §2 |
| HP admin/owner hilang (kunci kedua ikut hilang) | Lapor atasan (owner pusat / pemilik platform) → reset MFA → daftarkan device baru | `docs/teknis/BUKU_INSIDEN.md` §3 |
| Akun diduga dibobol | Nonaktifkan akun → cabut perangkat → ganti PIN/kata sandi → periksa jejak audit | `docs/teknis/BUKU_INSIDEN.md` §4 |
| Pegawai berhenti | Nonaktifkan akun → cabut perangkat → ganti PIN → periksa jejak 30 hari | `docs/teknis/BUKU_INSIDEN.md` §5 |
| Data pelanggan bocor | Hentikan kebocoran → catat → hubungi pemilik platform → lapor ≤ 3×24 jam | `docs/teknis/BUKU_INSIDEN.md` §6 |
| Internet kedai mati | Lanjut melayani; jangan kunci aplikasi sendiri; periksa antrean setelah internet kembali | `docs/teknis/BUKU_INSIDEN.md` §7 |
| Printer tidak keluar struk | Jangan tekan cetak berkali-kali; pakai jalur cadangan (tampilkan di layar) | `docs/teknis/BUKU_INSIDEN.md` §9 |
| CI merah (kiriman kode gagal) | Minta agent menjelaskan **sebabnya** + perbaikan + bukti hijau ulang | `docs/AGENT_OPERATING_GUIDE.md` §5 |
| Audit/review menemukan cacat berat | Minta agent memperbaiki K-1/K-2 dulu; jangan setujui lanjut/merge sebelum tertutup | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §10 · `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md` §2 |
| Peninjau gagal kalibrasi | Tidak masalah — itu justru penemuan; minta audit/review diulang (sesi/model lain) | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7 |
| Agent tidak bisa membuka sesi peninjau | Ingat: peninjau **wajib** sesi baru; pekerjaan berhenti di titik bersih sampai Lee sempat membukanya | Bagian D2 |
| Ruang kerja baru dinyalakan ulang & pekerjaan "hilang" | Minta agent memulihkan (aman, tidak menghapus apa pun) | Bagian E (`alat/pulihkan-git.sh`) |
| Agent mulai kacau / tidak fokus | Tempel prompt STOP/checkpoint (Bagian C2), lalu mulai sesi baru | `docs/AGENT_OPERATING_GUIDE.md` §8 |
| Merasa dipaksa/tergesa-gesa | Ingatkan: **kualitas di atas kecepatan**; minta berhenti di batas bersih | Bagian A5 butir 3 |

---

## Bagian H — Berkas penting, template, kebiasaan

### H1. Peta berkas penting

| Kalau Lee mencari… | Buka |
|---|---|
| **Cara melakukan apa pun + semua prompt + semua perintah** | **Buku ini** |
| Rekam permintaan Lee sepanjang proyek (supaya tidak ada yang terlewat) | `docs/teknis/REKAM_PESAN_PEMILIK.md` |
| Cara meminta audit, arti verdict, kalibrasi (ringkas) | `docs/PANDUAN_PEMILIK.md` |
| Aturan keamanan (akun, perangkat, PIN, data pelanggan) | `docs/KEAMANAN.md` |
| Cara Lee memicu audit (panduan peninjau) | `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` |
| Cara Lee memicu review PR | `docs/uji/PROMPT_REVIEW_PR_INDEPENDEN.md` |
| Langkah darurat saat masalah | `docs/teknis/BUKU_INSIDEN.md` |
| Posisi pekerjaan sekarang | `PROJECT_STATE.md`, `STATUS.md` |
| Daftar tugas & progres | `docs/ROADMAP.md` |
| Keputusan penting + alasannya | `docs/DECISIONS_LOG.md` |
| Hal yang sengaja ditunda | `docs/TERTANGGUH.md` |
| Protokol & alat audit | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`, `alat/audit-independen.py` |
| Protokol & alat review PR | `docs/uji/PROTOKOL_REVIEW_PR_INDEPENDEN.md`, `alat/review-pr.py` |
| Riwayat audit & ketajaman peninjau | `docs/uji/AUDIT_RIWAYAT.md`, `docs/uji/REVIEW_PR_RIWAYAT.md` |
| Pekerjaan lama yang harus diulang | `docs/uji/DAFTAR_PEKERJAAN_ULANG.md` |
| Rencana & keputusan desain (10 tema, gerakan, perilaku) | `docs/desain/RENCANA_DESAIN_UI.md`, `docs/SPESIFIKASI_UI.md`, `prototipe/` |
| Aturan kerja agent | `docs/AGENT_OPERATING_GUIDE.md`, `AGENT_SYSTEM.md` |
| **Lanjut di sesi/chat baru** | `docs/ops/SIAP-LANJUT.md` (handoff mesin, berubah tiap batch) · `PROMPT_SESI_BARU.md` (berkas prompt **statis**, kamu isi baris pertamanya) · `docs/ops/SESI_DITINGGALKAN.md` (sesi yang sengaja ditinggalkan) |
| Menyiapkan akun cloud (Supabase/Cloudflare) | `docs/ops/SIAP_AKUN_PEMILIK.md` |

### H2. Memakai sistem ini sebagai template (untuk aplikasi berikutnya)

### H1. Cara pakai sebagai template (copy folder ini jadi repo baru)

**Ini sudah siap sebagai template.** Kapanpun mau buat aplikasi baru, tinggal copy folder `sistem-building-aplikasi` ini jadi repo tersendiri — semua mekanisme, skill, dan prompt ikut.

**Yang di-copy = SELURUH isi folder ini, BUKAN hanya `AGENT_SYSTEM.md`.** Pedoman lama `PANDUAN_PEMAKAIAN.md` (v3) pernah menulis "yang masuk ke repo hanya `AGENT_SYSTEM.md`" — **itu sudah tidak berlaku** dan berkasnya kini berpenanda arsip. Alasannya: `AGENT_SYSTEM.md` merujuk `PROFIL_PENGGUNA.md` (LANGKAH 0 wajib), `skills/` (kewajiban pakai skill), `_sistem/templates/` (10 template Fondasi), `_sistem/validate_system.py` (audit hidup), `10_LOG_SESI.md`, dan `START_DI_SINI.md` — kalau hanya satu berkas yang ikut, semua rujukan itu putus dan sistem pincang.

**Cara copy paling aman (2 opsi):**

**Opsi A — via GitHub (direkomendasikan):**
1. Di GitHub, buat repo baru kosong (mis. `my-app-baru`) — jangan centang README.
2. Di komputer/lmarena: `git clone https://github.com/With-AI-Agent/Pembangun-Sistem.git` lalu `cp -r sistem/sistem-building-aplikasi/* my-app-baru/` (atau download ZIP folder `sistem-building-aplikasi` dari GitHub → extract ke `my-app-baru`).
3. `cd my-app-baru && git init && git add . && git commit -m "init dari template Building Aplikasi 26M" && git branch -M main && git remote add origin https://github.com/KAMU/my-app-baru.git && git push -u origin main`
4. Hubungkan lmarena agent ke repo `my-app-baru` → buka sesi baru → paste **Prompt Pembuka Universal** di atas → langsung jalan. Prompt di atas sudah portabel: `AGENT_SYSTEM.md di repo ini secara penuh (di folder sistem-building-aplikasi/ bila sistem ini ada di repo meta, atau di root bila sudah jadi repo standalone)` → jadi tidak perlu edit prompt.

**Opsi B — via lmarena langsung:**
- Di lmarena, buat repo baru, lalu `cp -r /home/user/Pembangun-Sistem/sistem/sistem-building-aplikasi/* /home/user/my-app-baru/` — push seperti di atas.

**Yang ikut ter-copy (TEMPLATE):** `AGENT_SYSTEM.md` (aturan kerja agent: 6 Tahap Fondasi + Coding + Checkpoint & Handoff + Tahap 0.5 + Mekanisme Hidup + Kewajiban Skill ADAPTIF), `PROFIL_PENGGUNA.md`, `SYSTEM_MANIFEST.md`, `STATUS.md`, `PANDUAN_PENGGUNA.md` + `PROMPT_ENTRI_UNIVERSAL.md` (identik), `START_DI_SINI.md`, `10_LOG_SESI.md`, `ACCEPTANCE_TESTS.md`, `_sistem/templates/` (**10 template**: DISCOVERY/PRD/TECH_SPEC/AGENT_OPERATING_GUIDE/ROADMAP/DECISIONS_LOG/PROJECT_STATE + STATUS/LOG_SESI/PROFIL_PENGGUNA), `docs/README.md`, `skills/` (**56 dirs, 26M lengkap** — semua skill inti Cloudflare/Supabase/Google/Vercel + 10 publik fresh HEAD via `npx` sudah di dalam, tidak perlu fetch ulang; 2 katalog (248 + 787 skill valid) tetap katalog 8K on-demand), `_salinan-meta/PLATFORM_LMARENA.md`, `skills/agent-skills/CATALOG.md` (248) + `skills/agent-skills-hub/CATALOG.md` (787 skill valid dari 797 direktori) — **katalog = maksimal, bukan kekurangan**. Agent baca katalog lalu `npx skills add <repo> --skill <nama>` kapanpun butuh (lihat `skills/README.md` § Update & Discoverability — 10 URL publik + `npx skills update`). Semua **self-contained 100%** — `check_selfcontained --semua` PASS, `validate_system` PASS di repo baru tanpa Input-Pengguna. Validasi ulang di repo baru: `python3 _sistem/validate_system.py` harus `PASS` (0 temuan).

**Jangan ikut di-copy (3 hal):**
1. **Input-Pengguna/** — 10 zip (53.813.128 bytes) yang hanya ada di repo meta induk sebagai **provenance audit**, bukan bagian template. Sudah diverifikasi tidak mengandung virus/malware (scan 2026-09-15 + ulang 2026-09-16), dan **10 skill publiknya sudah dipasang ulang fresh HEAD via `npx`** ke `skills/` — jadi repo baru tetap maksimal tanpa zip itu.
2. **.git** — riwayat repo meta (bila kamu memakai `git clone`, bukan download ZIP).
3. **`_Notes.md`** — catatan pribadi pemilik (tautan chat pribadi); tidak berguna di repo aplikasi. Karena `cp -r .../*` ikut membawanya, **hapus setelah copy**: `rm my-app-baru/_Notes.md`.

**Di repo baru, semua skill katalog tetap bisa dipakai:** agent baca `skills/agent-skills/CATALOG.md` (248) / `skills/agent-skills-hub/CATALOG.md` (787 skill valid dari 797 direktori) lalu `npx skills add <owner/repo> --skill <nama>` — **tidak akan bingung "skill tidak ada"** (dijamin di `AGENT_SYSTEM.md` § Kewajiban Penggunaan Skill + `skills/README.md` § Update & Discoverability). Skill niche tambahan: `npx skills find <keyword>` (atau pakai `skills/find-skills`). Katalog = on-demand, bukan kekurangan.


### H3. Kebiasaan yang perlu dijaga

### H4. Kebiasaan yang perlu dijaga

- **Checkpoint tiap tahap/task + commit & push** — jangan tunda.
- **Log sesi berkelanjutan** (`_log-sesi/`) — agent update setelah tiap pertukaran penting, header "Keadaan Sesi" selalu segar, `CLOSED` di akhir. Kalau sesi crash, sesi baru baca log `OPEN` itu — kalau tidak ada, backstop = `PROJECT_STATE.md` + `STATUS.md`.
- **PROJECT_STATE.md selalu di-update sebagai langkah TERAKHIR** setiap sesi — tanpa ini sesi baru buta.
- **Jangan lanjut kerja di sesi yang PR-nya sudah merge** — file baru akan terjebak tidak bisa di-push. Buka sesi baru.
- **DECISIONS_LOG wajib dibaca** sebelum ubah Area Berisiko Tinggi — jangan tebak dari kode.
- Kalau sesi panjang dan agent mulai ngawur: tempel prompt **"STOP dulu sebelum lanjut kerja. Aku mau kamu melakukan Checkpoint & Handoff..."** (lihat AGENT_SYSTEM.md §Checkpoint & Handoff).
- **ROADMAP harus sedetail mungkin** — jika di sesi Coding ada hal kecil yang ternyata belum ada di ROADMAP (favicon, empty state, `.env.example`), **STOP**, tambah task dulu dengan 7 atribut lengkap, baru lanjut (lihat Tahap 5 checklist kelengkapan).

---


---


---

## Log Keputusan

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-16 | Run klinik ke-2: penegasan "SELURUH folder yang di-copy, bukan hanya `AGENT_SYSTEM.md`" + koreksi angka basi + `_Notes.md` masuk daftar jangan-copy | Dua pedoman aktif saling bertentangan; angka tertinggal saat reinstall |
| 2026-09-15 | Buku pedoman dibuat pada run klinik pertama | Sistem belum punya pegangan pengguna |
| 2026-09-17 | Dinaikkan menjadi buku induk: bagian A–H + penjaga `alat/periksa-panduan.py` di CI | Permintaan Lee: satu berkas lengkap (manual book) |
| 2026-09-17 | **DItulis ulang menjadi v2 berbasis ALUR**: Bagian B = 12 alur (Apa ini · Kapan · Kalimat Lee · Langkah Lee · Yang agent lakukan · Bukti · Lama · Kalau macet); **Bagian C = prompt berlabel** siapa yang memakai; **Bagian E = tiap perintah dijelaskan fungsinya + cara pakai + arti bila GAGAL**; ditambah peta berkas baru (rekam pesan, protokol review PR) | Keluhan Lee: *"isi nya masih banyak kurang dan cacat… banyak hal berkaitan cara tidak kamu sertakan… kamu hanya nyediakan prompt tapi ga ngasih panduan nya… tabel perintah tapi ga dijelasin fungsi dan cara pakainya… ada beberapa prompt yang justru isi kata-katanya bukan ditujukan untuk agent, melainkan untuk pengguna"* |
| 2026-09-17 | Panggilan "Bapak" → **Lee** di seluruh berkas pengguna; aturan ini masuk `PROFIL_PENGGUNA.md` | Permintaan Lee: *"mulai sekarang agent ga boleh sebut aku bapak. Nama aku Lee."* |
| 2026-09-17 | **Cacat "kontrol mati" diperbaiki**: tombol Nyaman/Padat hanya menyasar kelas prototipe → kini mengubah token jarak & menyasar kelas aplikasi; penjaga baru `aplikasi/alat/periksa-kerapatan.py` (3 uji mutasi) + uji interaksi `aplikasi/src/layar/contoh/kerapatan.test.tsx`; daftar tema diberi keterangan jumlah agar 10 tema mudah ditemukan | Laporan Lee: *"tombol Nyaman dan Padat … waktu aku klik dan switch ga ada efek apa apa"* dan *"cuma liat ada 5 theme doang"* |
| 2026-09-17 | **Lembar kunci pemilik** — formulir `docs/ops/DAFTAR_KUNCI_PEMILIK.template.md` + berkas kerja terisi (bernama DAFTAR_KUNCI_PEMILIK.local.md, tidak ikut Git) + penjaga `alat/periksa-rahasia.py` | Permintaan Lee: tempat mengumpulkan hal yang harus disiapkan termasuk kunci; risiko sudah diperhitungkan Lee (data percobaan, rotasi sebelum rilis, repo privat) |
| 2026-09-17 | **Verifikasi menyeluruh atas seluruh permintaan Lee + penutupan 6 cacat ketertelusuran**: daftar temuan audit kini per temuan (dijaga `alat/periksa-temuan-audit.py`), rujukan dokumen pengikat dijaga `alat/periksa-rujukan.py` (rujukan mati ditemukan & diperbaiki; jumlahnya diukur oleh pemeriksa, bukan ditulis tangan), kerentanan dependency 0 (`npm audit` di CI), penjaga buku induk dapat `--uji-diri` + ambang alur = jumlah nyata, klaim bukti T0-01 & `alat/peta-ui.py` dikoreksi, akun pemilik masuk daftar tunggu | Permintaan Lee: *"Semua yang aku minta matangkan sebelumnya udh belum? Tolong pastikan dulu … pastikan itu bukan cuma disimpan, tapi juga dibaca"* |
| 2026-09-17 | **Buku Uji Pemilik dibuat** (`docs/uji/BUKU_UJI_PEMILIK.md`) + penjaga `alat/periksa-buku-uji.py` (3 uji mutasi) + masuk CI | Permintaan Lee: buku uji bertahap berisi langkah, harapan, dan tempat mengisi hasil — juga ditampilkan di chat |
| 2026-09-17 | **+2 permintaan Lee dijadwalkan**: bantuan kontekstual di setiap laman (`T1-42`) · Buku Uji Pemilik bertahap + gema di chat (`T1-43`); paket audit diperketat (`T1-44`) | Permintaan Lee 2026-09-17 (supaya pegawai tidak perlu mengingat sosialisasi; supaya hal yang harus Lee uji/lakukan tercatat sejak awal) |
| 2026-09-17 | **Keluhan pratinjau ketiga diperbaiki + kemampuan desain disimpan**: mode Padat kini memadatkan **tinggi** (bukan hanya kiri-kanan) dengan jarak mendatar & huruf tetap; panel tema bisa ditutup dengan **Esc (fokus pulang)/klik di luar/fokus keluar**; ujung daftar diberi **jejak pudar** yang mengikuti gulir; ilmunya disimpan di `skills/desain-antarmuka/SKILL.md` (wajib dibaca fase DESAIN) dan dijaga penjaga baru `aplikasi/alat/periksa-antarmuka.py` (10 uji-diri) | Laporan Lee: *"blok blok nya hanya berkurang panjang nya aja, tapi lebar (atas-bawah) nya ga ikut mengecil"* · *"pelajari ilmu desain … dan simpan hasil yang kamu pelajari itu untuk menjadi kemampuan. Dan ingat, jangan hanya disimpan, tapi juga harus digunakan"* · *"harus bisa ditutup dengan Esc / klik di luar"* · *"ujung nya itu kayak nabrak gitu"* |
| 2026-09-17 | **Jalur pulang laporan** (peninjau push laporan → agent menarik otomatis) + **aturan anti-teater**: ambang minimum = lantai bukan target, temuan di luar cakupan WAJIB dilaporkan (bagian 8), dilarang menyusun laporan agar lolos pemeriksa | Pertanyaan & temuan Lee: laporan tidak jelas bagaimana kembali ke sesi kerja; salah satu sesi peninjau berkata *"Saya baca dulu aturan pemeriksa laporan supaya laporannya memenuhi syarat"* |

<!-- Pemeliharaan 2026-09-21: pemeriksa roadmap menerima nol butir tertangguh terbuka; setiap butir terbuka wajib bertanda pada tugas, penanda selesai ditolak. Bukti: python3 alat/periksa-roadmap.py --uji-diri (ikut CI). Tugas/uji nyata tidak otomatis selesai ketika keputusan Lee dijawab. -->
