---
agent_instruction: IGNORE for execution — USER GUIDE ONLY
user_guide_only: true
purpose: BUKU PEDOMAN INDUK (manual book) pemilik — satu tempat untuk SEMUA hal yang perlu pengguna pahami: cara memakai sistem, semua mekanisme yang berjalan, semua prompt yang dibutuhkan, glosarium, penanganan masalah, dan peta berkas. Panduan per-mekanisme boleh ada sendiri-sendiri, tetapi buku ini WAJIB lengkap dan menunjuk ke semuanya. Dijaga oleh `alat/periksa-panduan.py` (ikut CI) supaya tidak bisa basi. Agent hanya membaca berkas ini bila diminta eksplisit atau via prompt entri.
---

# Buku Pedoman Pengguna — Resto Barokah & Sistem Pembangunnya

**Buku ini untuk Bapak (pemilik, non-teknis).** Kalau Bapak mau tahu *"bagaimana cara melakukan X?"*, *"mekanisme apa saja yang jalan?"*, *"prompt apa yang harus saya tempel?"* — jawabannya ada di buku ini. Kalau jawabannya belum ada di sini, itu **cacat buku** dan agent wajib menambahkannya (pemeriksa `alat/periksa-panduan.py` menahan CI sampai ditambahkan).

> **Aturan pemakaian buku ini:** bagian **A** = peta singkat · **B** = prompt & kalimat siap pakai (paling sering dipakai) · **C** = semua mekanisme · **D** = prompt kanonik lengkap · **E** = istilah awam · **F** = kalau ada masalah · **G** = peta berkas · **H** = memakai sistem ini sebagai template.

---

## Daftar Isi

| Bagian | Isi | Untuk apa |
|---|---|---|
| **A** | Peta cepat: apa yang dibangun · apa yang sudah/belum jadi · bukti yang selalu diminta · siapa memegang apa | Orientasi 5 menit |
| **B** | Prompt pembuka & penutup · kalimat untuk setiap situasi · review & merge PR · perintah mesin · aturan yang mengikat agent | Kerja harian |
| **C** | Semua mekanisme: fondasi · maraton & buku tunggu · keamanan akun/perangkat · kelengkapan layar-tombol · audit independen · uji otomatis/CI · kedaruratan · privasi · biaya · laporan harian | Tahu sistem bekerja bagaimana |
| **D** | Semua prompt kanonik (audit independen, kerja ulang, checkpoint) | Menyalin tanpa salah |
| **E** | Istilah awam (termasuk istilah audit: K-1…K-4, terkalibrasi) | Tidak bingung istilah |
| **F** | Kalau ada masalah (perangkat hilang, akun dibobol, data bocor, internet mati, CI merah, audit gagal, agent ngawur) | Saat panik, buka ini |
| **G** | Peta berkas penting: mana dibaca untuk apa | Mencari cepat |
| **H** | Memakai sistem ini sebagai template untuk aplikasi berikutnya | Kalau mulai proyek baru |

---

## Bagian A — Peta cepat

### A1. Apa yang sedang dibangun (dua lapis)

1. **Lapis sistem (mesin kerja):** cara agent bekerja — fondasi dokumen, roadmap, aturan maraton, audit independen. Berkasnya ada di akar repo dan dalam `docs/`.
2. **Lapis aplikasi (produk):** aplikasi kasir/resto "Resto Barokah" untuk Kedai Oasis — kode di `aplikasi/`, database di `supabase/`, alat uji di `alat/`.

Bapak tidak perlu menyentuh kode. Bapak **memutuskan**, agent **mengerjakan + membuktikan**.

### A2. Peta kejujuran: apa yang sudah jadi & apa yang belum

| Sudah jadi & teruji | Belum jadi (jangan dipakai dulu) |
|---|---|
| Fondasi dokumen (Discovery, PRD, Tech Spec, aturan kerja agent, Roadmap) — **dikunci** | Layar aplikasi untuk dipakai kedai (baru kerangka; layar fitur menyusul) |
| Database: penyewa, cabang, pengguna, izin, pengaturan, katalog, stok, meja, pesanan, pembayaran — diuji otomatis di PostgreSQL nyata (PGlite) | Perangkat terdaftar & login staf (Fase 1B), kontrak UI (Fase 1C) |
| Alat pemeriksa otomatis + CI (uji SQL, uji unit, pemeriksa dokumen, kontrak UI nanti) | Akun cloud (Supabase/Cloudflare) — menunggu Bapak (T0-00/T0-08), region **Singapore** sudah diputuskan |
| Mekanisme audit independen (protokol, alat, kalibrasi cacat) | Pekerjaan ulang artefak lama (T1-37) — daftarnya sudah ada & terukur |

> Buku ini **tidak** menjanjikan "sudah selesai". Status sebenarnya selalu bisa dilihat di `PROJECT_STATE.md` dan `docs/ROADMAP.md`.

### A3. Bukti yang selalu Bapak terima (agar tidak perlu percaya kata)

| Klaim | Bukti yang wajib ada |
|---|---|
| "Uji lulus" | keluaran perintah uji (mis. uji SQL & uji unit) + jumlah lulus/gagal |
| "Gerbang bisa menangkap cacat" | uji mutasi: sengaja dirusak → gerbang MERAH, dipulihkan → LOLOS |
| "Dokumen tidak basi" | pemeriksa otomatis di CI (termasuk buku ini) |
| "Audit independen bersih" | laporan auditor yang **lolos kontrak mesin** + hasil **kalibrasi cacat tanaman** |
| "Sudah diperbaiki" | perintah "cara membuktikan perbaikan" dari temuan dijalankan ulang dan hijau |

### A4. Siapa memegang apa (agar tidak ada pintu rahasia)

| Hal | Pemegang |
|---|---|
| Keputusan bisnis (harga, jam buka, fitur, biaya) | **Bapak** |
| Akun & kunci layanan (Supabase, Cloudflare, email) | **Bapak** (agent hanya memandu; kunci rahasia tidak ditulis di kode) |
| Kode, database, uji, dokumen | Agent |
| Audit independen | **Sesi & model berbeda** dari yang mengerjakan |
| Kode pemulihan perangkat (darurat) | **Bapak** (amplop tersegel, `docs/KEAMANAN.md` §4b) |
| Uji terima terakhir sebelum pilot | **Bapak** di perangkat nyata |

---

## Bagian B — Prompt & kalimat siap pakai

### B1. Prompt Pembuka Universal (gunakan SETIAP sesi baru)

Salin blok di bawah ke chat pertama — dalam keadaan apa pun (fondasi, coding, audit, lanjut). Isinya sama dengan berkas `PROMPT_ENTRI_UNIVERSAL.md` (dijaga pemeriksa supaya identik).

```
Cek dulu apakah ada file PROJECT_STATE.md di root repo ini.

Kalau TIDAK ADA (repo kosong/baru): ini proyek baru. Baca AGENT_SYSTEM.md di repo ini secara penuh (di folder sistem-building-aplikasi/ bila sistem ini ada di repo meta, atau di root bila sudah jadi repo standalone), lalu mulai dari TAHAP 1 (Discovery) sesuai AGENT_SYSTEM.md.

Kalau ADA: baca isinya, lihat nilai STATUS-nya, lalu ikuti instruksi yang sesuai di AGENT_SYSTEM.md untuk STATUS tersebut (FONDASI_TAHAP_2_PRD s/d CODING_AKTIF / SIKLUS_BARU).

Setelah kamu tahu posisi kita:

0. JALANKAN BOOTSTRAP SESI: python3 alat/mulai-sesi.py — script ini mencetak KARTU SESI: posisi proyek, keadaan branch/PR, log sesi terbaru, DAFTAR SKILL yang wajib kamu baca untuk fase sekarang, dan berkas fondasi yang wajib dibaca. Kalau script tidak ada/gagal, pakai tabel fase-ke-skill di docs/AGENT_OPERATING_GUIDE.md bagian 2.
1. BACA sungguhan setiap berkas SKILL.md yang tercantum di KARTU SESI (beserta referensi yang ditunjuknya bila relevan) — jangan hanya menyebutnya. Semua skill sudah tersimpan lokal di skills/ (tidak perlu internet, tidak perlu npx). Kalau ada skill yang dibutuhkan fase ini tapi tidak ada di repo, LAPORKAN — jangan dilewati diam-diam.
2. Baca SYSTEM_MANIFEST.md dan STATUS.md (identitas, tahap, pekerjaan belum tersimpan) + PROJECT_STATE.md (posisi sekarang).
3. Verifikasi branch/working tree. Ingat fakta platform: branch arena/... dibuat otomatis dan tidak bisa diganti; base branch dipilih di awal sesi (rekomendasi: main); setiap sesi bisa memakai MODEL AI YANG BERBEDA; setelah PR di-merge atau di-close, akses sesi itu hilang. Laporkan branch aktif, jarak commit terhadap main, commit terakhir, dan working tree bersih/kotor. **Kalau pekerjaan sesi sebelumnya belum di-merge dan kamu perlu melihatnya, pilih base branch = cabang arena sesi itu (mis. arena/01a0a8a2-resto-barokah) saat membuat sesi baru — jangan merge PR hanya supaya bisa melihat pekerjaan.**
3b. Kalau ruang kerja baru dinyalakan ulang: (a) pustaka aplikasi bisa hilang → `bash aplikasi/alat/pratinjau.sh` memasang & menyalakan pratinjau; (b) salinan Git lokal bisa mundur ke `main` → `bash alat/pulihkan-git.sh` untuk memeriksa dan `bash alat/pulihkan-git.sh --perbaiki` bila memang tertinggal (tanpa `--hard`/`--force`). JANGAN menulis ulang berkas dari ingatan — ambil dari GitHub.
4. Cek dan laporkan semua PR (gh pr list --state all) — PR menggantung dari sesi lama bisa membuatmu bekerja dari dasar yang ketinggalan.
5. Cari file LOG_SESI_*.md terbaru di _log-sesi/. Kalau keadaannya OPEN, BACA header Keadaan Sesi + kronologi terakhir, lalu LAPORKAN keadaan sesi sebelumnya SEBELUM bertanya tujuan — jangan minta aku menjelaskan ulang konteks yang sudah tercatat di sana.
6. Baca docs/TERTANGGUH.md (buku tunggu) — KARTU SESI sudah mencetak daftar butir terbukanya. Setiap butir berarti ada hal yang SENGAJA ditunda; kamu WAJIB melaporkan jumlah & ID-nya, dan TIDAK BOLEH menutupnya tanpa jawaban pemilik (kecuali bisa dibuktikan dari dokumen yang sudah dikunci — tulis alasannya).
7. Laporkan posisi + KARTU SESI yang sudah terisi (termasuk: "Skill terpasang: N berkas dari M skill", fondasi yang dibaca, posisi sekarang, rencana sesi ini, yang dibutuhkan dariku) — SEBELUM mulai bekerja.
8. Berdasarkan jawabanku tentang tujuan sesi, baca sendiri file yang relevan (docs/*, PROJECT_STATE.md, docs/ROADMAP.md, docs/DECISIONS_LOG.md) — TANPA perlu aku tempel manual.
9. Jangan menulis/mengeksekusi apa pun sebelum tujuan sesi dikonfirmasi.

MODE MARATON (aturan kerja yang disetujui pemilik): bekerjalah terus-menerus dalam batch — satu perintah "lanjut" dariku = kerjakan sebanyak mungkin tugas berikutnya yang TIDAK tertangguh, tanpa bertanya. Hal yang bisa ditunda JANGAN dijadikan pertanyaan: tunda, catat di docs/TERTANGGUH.md (isi: kenapa boleh ditunda, nilai sementara, tenggat fase, siapa yang menjawab), lalu lanjut bekerja. Kamu HANYA boleh berhenti untuk bertanya pada Stop Conditions: (1) keamanan/uang/data pelanggan belum jelas, (2) muncul biaya apa pun, (3) dokumen fondasi bertentangan, (4) mau mengubah keputusan yang sudah dikunci/di DECISIONS_LOG, (5) tindakan merusak/tak bisa dibatalkan (hapus data, force push, deploy publik), (6) butir tertangguh sudah lebih dari 12 atau tenggatnya lewat. Setiap akhir batch: commit + push + perbarui ROADMAP/PROJECT_STATE/STATUS/LOG_SESI + tawarkan jawaban untuk semua butir tertangguh (aku cukup bilang "setuju semua").

Sebagai langkah TERAKHIR nanti sebelum sesi ini berakhir (baik karena tahap/task selesai, atau karena aku minta checkpoint): WAJIB perbarui PROJECT_STATE.md + STATUS.md + tutup LOG_SESI (CLOSED), COMMIT & PUSH semua pekerjaan (tanpa push, pekerjaan bisa hilang dan sesi berikutnya tidak bisa melanjutkan), lalu laporkan bahwa sesi aman ditutup.
```

### B2. Prompt Penutup Sesi (gunakan di akhir sesi)

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


### B3. Kalimat untuk berbagai situasi

**Kalimat siap salin (tambahan 2026-09-17):**

**Situasi: Mau mulai aplikasi baru (ide masih mentah)
```
Aku mau bikin aplikasi baru. Ide mentahnya: "[tulis ide kamu di sini, se-mentah apa pun]".
Pakai Prompt Pembuka di atas, mulai Tahap 1 Discovery — gali dulu sebelum tulis dokumen.
```

**Situasi: Lanjutkan Fondasi (sudah ada /docs sebagian)
```
Lanjutkan Fondasi. Cek PROJECT_STATE.md dulu — kita di tahap berapa? Lanjut diskusi tahap itu sampai aku bilang "cukup, tulis draftnya".
```

**Situasi: Lanjutkan Coding (Fondasi sudah beres)
```
Lanjutkan Coding. Baca PROJECT_STATE.md, docs/ROADMAP.md (mana yang [x] dan [ ]), dan docs/DECISIONS_LOG.md dulu — baru eksekusi task berikutnya sesuai TECH_SPEC & AGENT_GUIDE.
```

**Situasi: Audit / cek konsistensi sebelum lanjut
```
Tolong audit dulu sebelum lanjut. Cek konsistensi /docs (Tahap 6 Cross-Check) — apakah ada yang tidak sinkron antara PRD, TECH_SPEC, dan ROADMAP? Laporkan temuan + saran perbaikan.
```

**Situasi: Mau bikin siklus baru (v1, v2 setelah MVP jadi)
```
Aku mau mulai siklus baru v1. Versi yang sudah jalan: [MVP/v1]. Konteks tambahan:
- Yang sudah bagus: [...]
- Yang bermasalah: [...]
- Feedback nyata: [...]
- Ide fitur baru: [...]
Ikuti Tahap 0.5 di AGENT_SYSTEM.md.
```

---


**Situasi: Mau audit / pemeriksaan independen (Bapak paling sering butuh ini)**
```
Siapkan audit independen dulu. Lingkupnya: <seluruh sistem / keamanan akun / Fase 1 / bebas>.
Setelah paketnya siap, tunjukkan nama berkas **SIAP-TEMPEL**-nya (satu berkas yang sudah memuat kalimat pembuka +
paket, di folder docs/uji/paket-audit/) dan beri tahu aku lokasi bahan kalibrasinya. Jangan kerjakan pekerjaan lain
sebelum laporan audit masuk.
```

**Situasi: Sudah menjalankan audit di chat baru, ingin ditindaklanjuti**
```
Laporan audit sudah masuk. Periksa dengan alat kontrak, lalu: (1) tunjukkan verdict + daftar temuan per tingkat,
(2) perbaiki semua K-1 dan K-2 lebih dulu, (3) catat temuan lain sebagai tugas, (4) laporkan sebelum lanjut kerja lain.
```

**Situasi: Mau pekerjaan lama diulang karena aturan berubah**
```
Audit dampaknya dulu: keputusan <X> berubah — daftar pekerjaan lama yang jadi bertentangan dan harus diulang.
Tulis di dokumen daftar kerja ulang, tambahkan tugasnya ke ROADMAP, lalu kerjakan berurutan dengan bukti.
```

**Situasi: Mau berhenti di batas bersih**
```
STOP dulu sebelum lanjut kerja. Lakukan Checkpoint & Handoff: simpan semua ke Git (commit + push),
perbarui PROJECT_STATE + STATUS + buku tunggu + log sesi, lalu laporkan kondisi akhir dan hal yang belum selesai.
```

**Situasi: Mau tahu posisi sekarang tanpa membaca berkas**
```
Jelaskan posisi proyek sekarang dalam bahasa sederhana: sudah sampai mana, apa yang sedang dikerjakan,
apa yang menunggu keputusanku, dan apa 3 langkah berikutnya. Tanpa istilah teknis.
```

**Situasi: Merasa ada yang aneh / tidak yakin pekerjaan benar**
```
Aku merasa ada yang tidak beres pada <hal>. Jangan membela pekerjaan sebelumnya — buktikan ulang dari nol:
jalankan perintah buktinya, tunjukkan keluaran nyatanya, dan katakan jujur kalau ternyata memang cacat.
```

**Situasi: Mau menambah/menutup hal yang ditunda**
```
Tunjukkan daftar butir tertangguh (buku tunggu) beserta tenggatnya, dan usulkan jawaban untuk masing-masing.
Aku akan bilang "setuju semua" atau memilih.
```

### B4. Cara review & merge perubahan

### B5. Cara review & merge perubahan

1. Agent kerja di branch → commit + push → buka PR (tanpa auto-merge).
2. Kamu buka PR di GitHub, lihat file yang berubah (tab Files changed). **Periksa arahnya: `compare` = cabang sesi (arena/...), `base` = main — jangan terbalik.**
3. Kalau oke → **Merge pull request** (tombol hijau). Kalau belum → tulis komentar di PR, agent perbaiki di sesi baru. **Sebelum menekan merge, pastikan tidak ada sesi lain yang masih bekerja** (mis. sesi reviewer); merge = sesi itu kehilangan akses.
4. **Setelah merge, sesi itu tidak bisa push lagi** — ini batasan platform lmarena, bukan aturan kita. Kerja lanjutan = buka sesi baru dari `main`.

---


### B6. Perintah mesin yang boleh Bapak minta agent jalankan

| Bapak minta | Perintah | Fungsinya |
|---|---|---|
| "Siapkan audit" | `python3 alat/audit-independen.py --paket AUD-2 --tugas T1-01..T1-10` | Menyiapkan paket audit terarah |
| "Siapkan audit menyeluruh" | `python3 alat/audit-independen.py --paket AUD-3 --semua` | Paket audit **seluruh berkas proyek** + berkas **SIAP-TEMPEL** (pemilik cukup menyalin satu berkas) |
| "Siapkan kalibrasi" | `python3 alat/audit-independen.py --kalibrasi-siapkan` | Menanam cacat uji ketajaman auditor |
| "Periksa laporan audit" | `python3 alat/audit-independen.py --periksa-laporan <berkas>` | Menolak laporan malas/tanpa bukti |
| "Nilai kalibrasi" | `python3 alat/audit-independen.py --kalibrasi-nilai <laporan> --kunci <kunci>` | Mengukur ketajaman auditor |
| "Uji buku pedoman" | `python3 alat/periksa-panduan.py` | Memastikan buku ini lengkap & tidak basi |
| "Uji semuanya" | `node alat/uji-sql.mjs` + `cd aplikasi && npm test` + pemeriksa Python | Menjalankan seluruh ujian |
| "Nyalakan pratinjau" | `bash aplikasi/alat/pratinjau.sh` | Menyalakan aplikasi untuk dilihat |
| "Pulihkan ruang kerja" | `bash alat/pulihkan-git.sh` | Kalau salinan Git lokal tertinggal |

### B7. Aturan yang mengikat agent ke Bapak (bukan imbauan)

1. **Delegasi penuh:** kalau Bapak menyerahkan pilihan, agent memilih yang terbaik + menulis alasannya di `docs/DECISIONS_LOG.md`.
2. **Mode maraton:** satu perintah "lanjut" = satu batch pekerjaan; hal yang bisa ditunda **dicatat** di `docs/TERTANGGUH.md` (maksimal 12 butir terbuka) dan pekerjaan tetap jalan.
3. **Kualitas di atas kecepatan:** kalau batch tidak bisa dikerjakan dengan bukti yang bisa dipertanggungjawabkan, agent **berhenti** di batas bersih, bukan mengerjakan setengah.
4. **Penyimpangan wajib ditanya dulu** (aturan Bapak 2026-09-17): agent dilarang menyimpang dari deskripsi/rancangan Bapak tanpa bertanya, menjelaskan dalam bahasa sederhana, dan mencatatnya.
5. **Stop Conditions:** keamanan/uang/data pelanggan belum jelas · muncul biaya · dokumen saling bertentangan · mau mengubah keputusan yang sudah dikunci · tindakan merusak/tak bisa dibatalkan · butir tertangguh lebih dari 12 · menemukan cacat pada pekerjaan yang diklaim selesai.
6. **Gerbang audit:** temuan **K-1/K-2 menahan fase** sampai diperbaiki dan diverifikasi; laporan audit wajib lolos kontrak mesin; verdict "BERSIH" tidak sah bila auditor gagal kalibrasi.
7. **PR tidak di-merge oleh agent** — merge adalah keputusan Bapak (gerbang serah terima).

---

## Bagian C — Semua mekanisme yang berjalan

| # | Mekanisme | Berkas rujukan | Siapa yang menjaga | Bukti yang bisa Bapak lihat |
|---|---|---|---|---|
| C1 | **Fondasi 6 dokumen** (Discovery → PRD → Tech Spec → aturan agent → Roadmap → cross-check) | `docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/ROADMAP.md`, `docs/AGENT_OPERATING_GUIDE.md` | Agent | `python3 alat/periksa-roadmap.py` LOLOS |
| C2 | **Maraton & buku tunggu** (hal yang ditunda + tenggat, maksimal 12) | `docs/TERTANGGUH.md` | Agent (isi) · Bapak (menutup) | Daftar terbuka + tanda `❓` pada tugas ROADMAP |
| C3 | **Keamanan akun, perangkat, sesi** (PIN di perangkat terdaftar · TOTP wajib untuk peran berkuasa · pencabutan seketika · jalur pemulihan perangkat hilang) | `docs/KEAMANAN.md` | Agent | Uji SQL perangkat/sesi/percobaan + `docs/KEAMANAN.md` §14 |
| C4 | **Kelengkapan layar & tombol** (registri aksi, kontrak layar, 7 keadaan, tombol wajib diuji) | `docs/SPESIFIKASI_UI.md` | Agent | Pemeriksa peta UI (Fase 1C) + uji komponen |
| C5 | **Audit & pemeriksaan independen** (AUD-0…AUD-3, kalibrasi cacat tanaman, gerbang K-1/K-2) | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` | Sesi auditor independen | Laporan yang lolos `--periksa-laporan` + angka kalibrasi |
| C6 | **Uji otomatis & CI** (uji SQL nyata, uji unit, pemeriksa dokumen, pemeriksa buku ini) | `.github/workflows/ci.yml`, `alat/uji-sql.mjs` | Mesin (setiap kiriman kode) | Riwayat CI hijau/merah per kiriman |
| C7 | **Kedaruratan** (perangkat hilang, akun dibobol, pegawai berhenti, data bocor 3×24 jam, internet mati, printer, cadangan) | `docs/teknis/BUKU_INSIDEN.md` | Bapak + admin cabang | Langkah bernomor + log insiden |
| C8 | **Data pelanggan & UU PDP** (persetujuan, minimalisasi, anonimisasi, pemberitahuan kebocoran) | `docs/KEAMANAN.md` §11 | Agent (teknis) · Bapak (kebijakan) | Uji SQL persetujuan/anonimisasi (T8-15) |
| C9 | **Biaya nol** (batas layanan gratis, kapan naik kelas) | `docs/TECH_SPEC.md` §10 | Agent (jaga) · Bapak (keputusan bila berbiaya) | Catatan batas + peringatan sebelum mendekati |
| C10 | **Laporan harian & notifikasi** (omzet, void, diskon, selisih kas, percobaan masuk gagal, perubahan perangkat) | `supabase/functions/ringkasan_harian/index.ts` (rencana) | Mesin + agent | Email + layar Peringatan (Fase 10) |

### C5 lebih rinci: audit independen (paling sering Bapak pakai)

1. **Empat tingkat:** AUD-0 audit dampak (keputusan berubah) · AUD-1 periksa batch oleh mesin (otomatis di CI) · AUD-2 review independen (akhir fase / perubahan berisiko) · AUD-3 audit **menyeluruh** (semua berkas + semua lensa + kalibrasi; sebelum pilot & kapan pun Bapak minta).
2. **Siapa auditor:** **sesi baru**, kalau bisa **model berbeda**, dan **hanya-baca** (tidak boleh memperbaiki).
3. **Enam lensa:** Ancaman & Akses · Uang & Jejak · Kesepakatan Dokumen · Mutu Uji · Lapangan/UI · Privasi & Kepatuhan.
4. **Kalibrasi cacat tanaman:** agent menanam cacat sengaja (termasuk yang tersembunyi) di salinan kode; auditor mencari tanpa tahu jawabannya. Kalau banyak yang terlewat → laporan ditandai **belum terkalibrasi** dan verdict "BERSIH"-nya tidak dipakai.
5. **Kontrak laporan:** temuan wajib punya bukti perintah + skenario gagal; "BERSIH" tidak sah kalau ada temuan K-1/K-2; AUD-3 wajib menyebut jumlah berkas yang diperiksa.
6. **Cara Bapak memicunya:** kalimat bebas, mis. *"Siapkan audit independen"* atau *"Audit independen sekarang"* → agent menyiapkan paket + salinan kalibrasi → Bapak menempelkannya di chat baru (pakai kalimat di Bagian D).

---

## Bagian D — Semua prompt kanonik

### D1. Prompt auditor independen (untuk chat baru)

Salin **seluruh blok** di bawah. Untuk satu lingkup tertentu, agent menulis versi terisi-otomatis di berkas paket (`docs/uji/paket-audit/`), dan blok ini diambil apa adanya dari `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` (dijaga pemeriksa supaya identik).

```
Kamu adalah AUDITOR INDEPENDEN untuk proyek Resto Barokah. Kamu BUKAN penulis kode ini dan kamu
TIDAK BOLEH mengubah, memperbaiki, atau menerapkan perubahan apa pun. Tugasmu menemukan masalah,
bukan menyenangkan pembuatnya.

Kerjakan berurutan:
1. Baca `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` (aturan main), lalu paket audit yang saya tempel di bawah.
2. Muat skill yang disebut paket: `skills/security-review/SKILL.md`, `skills/verification-before-completion/SKILL.md`,
   `skills/systematic-debugging/SKILL.md`, `skills/verification-loop/SKILL.md`, `skills/test-driven-development/SKILL.md`,
   `skills/prd-taskmaster/SKILL.md`, `skills/supabase/SKILL.md`, `skills/supabase-postgres-best-practices/SKILL.md`,
   dan `skills/ui-ux-pro-max/SKILL.md` bila menyentuh tampilan. Bila butuh skill lain, gunakan `skills/find-skills`
   atau `skills/agent-skills-hub`.
3. Kerjakan SEMUA lensa yang diminta paket. Untuk tiap lensa tulis: apa yang kamu periksa, perintah yang kamu jalankan,
   dan HASIL NYATA (tempel keluaran penting, bukan ringkasan keyakinan).
4. Bantah klaim pembangun di paket — jangan mempercayainya. Kalau perintah bukti tidak bisa dijalankan
   (mis. pustaka belum dipasang), tulis di bagian "Yang tidak bisa saya verifikasi", jangan menebak.
5. Setiap calon temuan: uji ulang di kode sekarang (buka berkas, telusuri pemanggil, jalankan perintah). Tidak bisa
   dibuktikan → tandai DUGAAN. Bisa dibuktikan → TERVERIFIKASI + sertakan perintahnya.
6. Kamu boleh (dan dianjurkan) mencari referensi internet untuk perilaku Supabase/PostgreSQL/OWASP; cantumkan tautannya.
7. Tulis laporan dengan format PERSIS seperti di paket (bagian "6. Format laporan") ke
   `docs/uji/audit/LAPORAN_<TINGKAT>_<tanggal>_<lingkup>.md`.
8. Jalankan `python3 alat/audit-independen.py --periksa-laporan docs/uji/audit/<berkas-laporan>.md` sampai LOLOS,
   lalu laporkan verdict + ringkasan temuan ke saya.

Larangan keras: memuji, "looks good", melaporkan soal gaya penulisan sebagai temuan, mengubah berkas,
mempercayai klaim tanpa membuktikannya, dan menaikkan verdict di atas bukti yang kamu punya.

Paket audit:
<<< TEMPEL ISI docs/uji/paket-audit/… DI SINI >>>
```

### D2. Prompt audit untuk kasus khusus

- **Audit menyeluruh (semua berkas):** tambahkan di akhir blok D1: *"Mode cakupan: menyeluruh. Periksa SEMUA grup berkas yang disebut paket, termasuk berkas untuk pengguna, dan tulis 'Cakupan menyeluruh: X dari Y berkas'."*
- **Audit ulang setelah perbaikan:** *"Audit ulang hanya pada temuan yang sudah diklaim diperbaiki: jalankan perintah 'cara membuktikan perbaikan' tiap temuan dan nyatakan TERTUTUP hanya bila hijau."*
- **Audit kalau Bapak mencurigai satu hal:** *"Audit terarah pada <hal>. Fokus lensa <L1/L2/…>. Tetap wajib bukti perintah."*

### D3. Prompt pemilik untuk pekerjaan yang dikerjakan agent

| Situasi | Kalimat |
|---|---|
| Lanjut kerja | **"Lanjut."** |
| Berhenti (kualitas dulu) | **"Berhenti dulu, aku mau batch bersih."** |
| Minta penjelasan | **"Jelaskan dengan bahasa sederhana: apa yang baru berubah, dan apa risikonya buat aku."** |
| Setuju semua usulan | **"Setuju semua."** |
| Satu hal ditolak | **"Selain <hal>, setuju semua."** |

---

## Bagian E — Istilah yang perlu kamu tahu (versi awam)

### E1. Istilah dasar sistem

- **Repo** — folder besar di GitHub tempat semua dokumen + kode aplikasimu tersimpan. "Markas" kerja.
- **Branch** — "salinan kerja" repo. Tiap sesi agent otomatis dapat branch sendiri (`arena/...`), supaya kerja yang belum selesai tidak mengacaukan versi utama.
- **`main`** — versi utama yang dianggap bersih & siap dipakai. Hasil kerja baru masuk sini setelah Bapak **merge**.
- **Commit** — "menyimpan" perubahan di branch.
- **Push** — mengirim commit ke GitHub (baru benar-benar aman; kalau sesi berhenti sebelum push, kerja bisa hilang).
- **PR (Pull Request)** — "usulan" memindahkan hasil branch ke `main`.
- **Merge** — Bapak menyetujui PR; hasil kerja resmi jadi. **Jangan merge selagi ada sesi lain yang masih bekerja di cabang itu** — sesi itu kehilangan akses.
- **CI** — mesin pemeriksa otomatis di GitHub: setiap kiriman kode diuji; kalau ada yang gagal, kiriman itu belum boleh dianggap selesai.
- **PROJECT_STATE.md** — penunjuk "kita di tahap apa"; dibaca otomatis agent tiap sesi baru.
- **DECISIONS_LOG.md** — catatan keputusan penting beserta alasannya; wajib dibaca sebelum mengubah hal berisiko.
- **Fondasi vs Coding** — Fondasi = dokumen perencanaan; Coding = mengubah rencana menjadi kode.

**Analogi:** `main` itu naskah asli; agent memakai fotokopian (branch), corat-coret di situ, lalu "mengusulkan" (PR) untuk ditempel ke naskah asli (merge).

### E2. Istilah audit (dipakai di Bagian C & F)

| Istilah | Arti singkat |
|---|---|
| **AUD-0** | Audit dampak: memeriksa pekerjaan lama yang jadi bertentangan karena keputusan berubah |
| **AUD-1** | Periksa otomatis mesin (CI) pada setiap batch |
| **AUD-2** | Review independen oleh sesi/model berbeda (akhir fase/perubahan berisiko) |
| **AUD-3** | Audit menyeluruh: semua berkas + enam lensa + kalibrasi (sebelum pilot) |
| **K-1 Kritis** | Uang salah / data bocor / tidak bisa dipulihkan → wajib diperbaiki lebih dulu |
| **K-2 Tinggi** | Janji dokumen dilanggar / pengaman wajib hilang → wajib sebelum fase ditutup |
| **K-3 Sedang** | Tidak konsisten, uji kurang, dokumen basi |
| **K-4 Catatan** | Kerapian, tidak menghambat |
| **TERVERIFIKASI / DUGAAN** | Temuan yang sudah dibuktikan ulang / masih dugaan (tidak dihitung berat) |
| **Terkalibrasi** | Auditor terbukti menemukan cacat sengaja; verdict BERSIH-nya boleh dipercaya |
| **Lensa** | Sudut pandang pemeriksaan (keamanan, uang, dokumen, mutu uji, lapangan, privasi) |
| **Cacat tanaman** | Kesalahan yang sengaja dimasukkan ke salinan kode untuk menguji ketajaman auditor |

---

## Bagian F — Kalau ada masalah

| Masalah | Yang Bapak lakukan | Rujukan |
|---|---|---|
| Tablet/HP kerja hilang atau dicuri | Cabut perangkat dari aplikasi (Pengaturan → Perangkat) → ganti PIN pegawai terakhir → periksa aktivitas hari itu | `docs/teknis/BUKU_INSIDEN.md` §2 |
| HP admin/owner hilang (kunci kedua ikut hilang) | Lapor atasan (owner pusat / pemilik platform) → reset MFA → daftarkan device baru | `docs/teknis/BUKU_INSIDEN.md` §3 |
| Akun diduga dibobol | Nonaktifkan akun → cabut perangkat → ganti PIN/kata sandi → periksa jejak audit | `docs/teknis/BUKU_INSIDEN.md` §4 |
| Pegawai berhenti | Nonaktifkan akun → cabut perangkat → ganti PIN → periksa jejak 30 hari | `docs/teknis/BUKU_INSIDEN.md` §5 |
| Data pelanggan bocor | Hentikan kebocoran → catat → hubungi pemilik platform → lapor ≤ 3×24 jam | `docs/teknis/BUKU_INSIDEN.md` §6 |
| Internet kedai mati | Lanjut melayani; jangan kunci aplikasi sendiri; periksa antrean setelah internet kembali | `docs/teknis/BUKU_INSIDEN.md` §7 |
| Printer tidak keluar struk | Jangan tekan cetak berkali-kali; pakai jalur cadangan (tampilkan di layar) | `docs/teknis/BUKU_INSIDEN.md` §9 |
| CI merah (kiriman kode gagal) | Minta agent menjelaskan **sebabnya** + perbaikan + bukti hijau ulang | `docs/AGENT_OPERATING_GUIDE.md` §5 |
| Audit menemukan cacat berat | Minta agent memperbaiki K-1/K-2 dulu; jangan setujui lanjut fase sebelum tertutup | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §10 |
| Auditor gagal kalibrasi | Tidak masalah — itu justru penemuan; minta audit diulang (sesi/model lain) atau ganti pendekatan | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` §7 |
| Agent mulai kacau / tidak fokus | Tempel prompt **STOP/checkpoint** (Bagian B3), lalu mulai sesi baru | `docs/AGENT_OPERATING_GUIDE.md` §8 |
| Bapak merasa dipaksa/tergesa-gesa | Ingatkan: **kualitas di atas kecepatan**; minta agent berhenti di batas bersih | Bagian B7 butir 3 |

---

## Bagian G — Peta berkas penting

| Kalau Bapak mencari… | Buka |
|---|---|
| Cara memakai sistem & semua prompt | **Buku ini** |
| Cara meminta audit, arti verdict | `docs/PANDUAN_PEMILIK.md` |
| Aturan keamanan (akun, perangkat, PIN, data pelanggan) | `docs/KEAMANAN.md` |
| Langkah darurat saat masalah | `docs/teknis/BUKU_INSIDEN.md` |
| Posisi pekerjaan sekarang | `PROJECT_STATE.md`, `STATUS.md` |
| Daftar tugas & progres | `docs/ROADMAP.md` |
| Keputusan penting + alasannya | `docs/DECISIONS_LOG.md` |
| Hal yang sengaja ditunda | `docs/TERTANGGUH.md` |
| Protokol & alat audit | `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`, `alat/audit-independen.py` |
| Riwayat audit & ketajaman auditor | `docs/uji/AUDIT_RIWAYAT.md` |
| Pekerjaan lama yang harus diulang | `docs/uji/DAFTAR_PEKERJAAN_ULANG.md` |
| Rencana & keputusan desain | `docs/desain/RENCANA_DESAIN_UI.md`, `prototipe/` |
| Aturan kerja agent | `docs/AGENT_OPERATING_GUIDE.md`, `AGENT_SYSTEM.md` |
| Menyiapkan akun cloud (Supabase/Cloudflare) | `docs/ops/SIAP_AKUN_PEMILIK.md` |

---

## Bagian H — Memakai sistem ini sebagai template & kebiasaan yang dijaga

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


### H2. Profil Pengguna — 4 pertanyaan awal (jadi prinsip permanen)

Di **sesi pertama** repo baru, agent akan **Wajib** baca `PROFIL_PENGGUNA.md` dulu (sebelum PROJECT_STATE). Kalau masih kosong, dia akan tanya 4 hal ini — jawab dengan jujur, supaya semua sesi selanjutnya langsung menyesuaikan otakmu:

1. **Bahasa:** mau pakai Indonesia / English / campur?
2. **Gaya:** mau santai-singkat / formal-rinci / step-by-step tanpa jargon?
3. **Latar belakang:** seberapa paham coding/database/DevOps? (tidak sama sekali / sedikit / lumayan / expert)
4. **Preferensi opsi:** mau langsung direkomendasikan yang terbaik + alasan singkat, atau mau dijelaskan trade-off dulu?

Jawabanmu disimpan di `PROFIL_PENGGUNA.md` dan jadi **prinsip permanen** — kapanpun buka sesi terbaru, agent langsung pakai gaya itu tanpa kamu ulang. Mau ganti? Bilang saja "ganti gaya jadi ...", agent update file-nya.

> **Aku jujur:** ide kamu ini **sangat penting dan benar**. Tanpa ini, agent akan kaku pakai bahasa Indonesia teknis untuk semua orang — padahal ada pengguna yang tidak paham Inggris, ada yang expert yang mau to-the-point. Dengan PROFIL, sistem jadi benar-benar menyesuaikan. Ini sudah aku jadikan `LANGKAH 0` wajib di `AGENT_SYSTEM.md` (sebelum cek PROJECT_STATE).


### H3. Mekanisme hidup — kapan pun bisa audit / sempurnakan / lanjutkan

Sistem ini **hidup**, bukan sekali jadi:

**A. Hidupnya Sistem Building itu sendiri:** kapan saja bilang *"audit sistem ini"*, *"sempurnakan sistem ini"*, *"tambah skill ..."*, agent akan jalankan audit (`validate_system` + `validate_repo` + `check_selfcontained` + FI 72), laporkan Critical/Minor, buka branch `sistem-audit-...`, PR tanpa auto-merge. Lihat `AGENT_SYSTEM.md` § *MEKANISME HIDUP — SISTEM & APLIKASI*.

**B. Hidupnya Aplikasi yang kamu bangun:** bahkan setelah rilis MVP/v1, kapan saja bilang *"audit aplikasi ini"*, *"perbaiki bug ..."*, *"buat v2"*, *"apakah ada yang tercecer di ROADMAP?"*, agent akan:
- audit via **Tahap 6 Cross-Check**,
- atau tambah task baru di `docs/ROADMAP.md` (dengan 7 atribut lengkap) dan eksekusi via Prosedur Coding,
- atau jalankan **Tahap 0.5 Siklus Baru** (arsipkan ROADMAP lama → tulis ROADMAP baru, `PROJECT_STATE=SIKLUS_BARU`).

> **Jujur:** kamu benar — tanpa mekanisme hidup, sistem akan mati setelah rilis. Sekarang sudah tertanam eksplisit di `AGENT_SYSTEM.md` § *MEKANISME HIDUP* (bisa dipicu dengan bahasa natural, sesuai PROFIL). Kamu bisa **audit kapanpun**, tidak perlu tunggu "sempurna".


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

## Log Keputusan

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-16 | Run klinik ke-2 (rawat inap, kit v0.2.0): penegasan "SELURUH folder yang di-copy, bukan hanya `AGENT_SYSTEM.md`" + koreksi angka basi + `_Notes.md` masuk daftar jangan-copy | Pemilik menemukan `PANDUAN_PEMAKAIAN.md` (v3, arsip) yang menyebut hanya `AGENT_SYSTEM.md` masuk repo baru → dua pedoman aktif saling bertentangan; angka-angka tertinggal sejak reinstall npx |
| 2026-09-15 | Pegangan dibuat pada run klinik pertama (kit v0.2.0) | Sistem belum punya pegangan pengguna; pegangan baru mengikuti template meta 2-berkas identik, portabel untuk repo standalone |
| 2026-09-17 | **Dinaikkan menjadi BUKU PEDOMAN INDUK (manual book)**: bagian A–H, memuat semua mekanisme, semua prompt kanonik (termasuk prompt auditor independen), glosarium istilah audit, penanganan masalah, dan peta berkas; dijaga `alat/periksa-panduan.py` di CI | Permintaan pemilik: *"satu file untuk pengguna yang betul-betul isinya lengkap… harus betul-betul jadi induk dan lengkap… semacam manual book… termasuk mekanisme audit dan pemeriksaan, dan juga ada semua prompt yang dibutuhkan"* |
