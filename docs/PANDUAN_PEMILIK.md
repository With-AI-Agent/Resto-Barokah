# PANDUAN PEMILIK — tiga hal besar yang bisa Lee perintahkan kapan saja

> **Buku induk (semua cara + semua prompt + semua perintah):** `PANDUAN_PENGGUNA.md`.
> Berkas ini = ringkasan cepat untuk tiga hal yang paling sering Lee pakai: **audit independen**, **review PR**, dan **menutup sesi aman**.
> Semua istilah di sini dijelaskan di buku induk Bagian F. Tempat lain: `docs/teknis/REKAM_PESAN_PEMILIK.md` (rekam permintaan Lee).

---


## Pindah ke chat/sesi baru — jawaban lengkap (pertanyaan yang paling sering)

Chat yang panjang memang jadi berat. Pindah ke chat baru **aman**: seluruh keadaan proyek
tersimpan di repo, bukan di ingatan agent. Ini jawaban jujurnya untuk tiga pertanyaan itu:

**1) Apakah aku perlu atur "base branch"? — TIDAK.**
Sama sekali tidak perlu. Cabang kerja dibuat otomatis oleh platform dan tidak bisa diganti;
istilah "base branch" hanya dipakai saat sebuah Pull Request dibuka — dan PR #1 sudah terbuka
sejak lama. Jadi kamu **tidak menyentuh apa pun soal branch**; cukup salin berkas siap-tempel.

**2) Apakah aku harus kirim prompt penutup di sesi lama dulu? — Disarankan, tapi TIDAK wajib.**
- Sesi lama **masih bisa diajak bicara** → tulis satu kalimat: `Siapkan pindah ke sesi baru.`
  Gunanya: agent merapikan pekerjaan yang belum tersimpan, menyegarkan berkas handoff,
  menjalankan pemeriksa sampai **LOLOS**, lalu menampilkan berkas untuk kamu salin.
- Sesi lama **sudah mati/mogok/berat** → boleh langsung pindah. Resep di berkas tempel akan
  menyusul semua pekerjaan yang sudah dikirim ke GitHub, dan agent baru diperintah **memeriksa
  keadaan repo lebih dulu** sebelum bekerja.
- Satu-satunya yang bisa tertinggal kalau langkah ini dilewati: pekerjaan yang saat itu
  **belum** di-commit/belum di-push ke GitHub. Itu sebabnya langkah penutup disarankan.

**2b) Kalau aku tidak mau melanjutkan sesi yang terakhir, tapi sesi LAIN? — Kamu yang menentukan.**
Caranya sekarang **cuma satu langkah**: tulis nama cabang sesi pilihanmu di **baris pertama**
berkas `PROMPT_SESI_BARU.md` (barisnya berbunyi `SESI YANG AKU LANJUT:`). Selesai — salin berkas itu
ke chat baru, dan agent baru wajib menyusul cabang yang kamu tulis di situ.
Butuh melihat pilihannya dulu? Tulis di sesi yang sedang aktif:
**`Tampilkan daftar sesi yang bisa dilanjutkan.`** Agent menampilkan daftar sesi (nama cabang,
tanggal, jarak dari `main`, catatan sesi lama), lalu kamu sebutkan pilihanmu — mis. *"lanjutkan
nomor 2"*. Ini berguna kalau ada sesi yang memang **ingin kamu tinggalkan** (salah arah / sudah
tidak dipakai): mesin tidak akan menebak sendiri.
**Sesi yang sengaja kamu tinggalkan** bisa dicatat permanen di `docs/ops/SESI_DITINGGALKAN.md`
(satu baris: cabang + tanggal + alasan). Sesudah dicatat, mesin **menolak** handoff/`--siapkan` yang
menunjuk ke sesi itu dan menandainya di daftar sesi — jadi tidak ada yang menyarankannya lagi
tanpa perintahmu (`--paksa` tetap ada bila kamu berubah pikiran).
Dua batasnya: sesi yang **belum pernah di-push** ke GitHub tidak bisa dilanjutkan (pekerjaannya
belum tersimpan), dan sesi **lama** biasanya punya alat versi lebih tua — agent wajib melapor.
Dan pakai **satu sesi aktif saja**: dua sesi bersamaan bisa mengerjakan hal yang sama dua kali.

**3) Berkas apa yang aku salin, dan apakah harus yang terbaru? — `PROMPT_SESI_BARU.md`, dan TIDAK perlu yang terbaru.**
Berkas itu **STATIS**: isinya tidak berubah dari batch ke batch, jadi kamu cukup menyimpannya
**sekali** lalu memakainya terus (ini permintaanmu 2026-09-18). Yang kamu lakukan hanya mengisi
**baris pertama** (`SESI YANG AKU LANJUT: <cabang>`) dan menyalin seluruh isinya ke chat baru.
Bila agent menyegarkan `PROMPT_SESI_BARU.md` (mis. blok Prompt Pembuka Universal berubah), salinan
lamamu tetap aman — resep di dalamnya menarik pekerjaan terbaru dari GitHub; hanya kalimat
aturannya yang mungkin sedikit tertinggal.

**Langkah ringkas**
1. (Disarankan) di chat lama: `Siapkan pindah ke sesi baru.` → agent menyegarkan handoff
   `docs/ops/SIAP-LANJUT.md` dan memastikan pemeriksa handoff LOLOS.
2. Tulis nama cabang sesi pilihanmu di **baris pertama** `PROMPT_SESI_BARU.md`, lalu buka
   **chat baru**, salin **SELURUH isi** berkas itu, kirim. Selesai — agent baru akan
   menyusul ke cabang itu, membaca `docs/ops/SIAP-LANJUT.md`, dan melaporkan KARTU
   SESI sebelum bekerja.
3. Bila sesi lama mati karena galat, tambahkan satu kalimat di chat baru:
   *"Sesi sebelumnya berhenti karena galat; periksa dulu keadaan repo (`git status`,
   `python3 alat/lanjut-sesi.py`) sebelum melanjutkan."*
4. **Jangan merge PR #1** — merge adalah keputusan Lee dan mengakhiri sesi cabang ini.

Kenapa ini tidak bisa "basi": `docs/ops/SIAP-LANJUT.md` wajib diperbarui di **commit terakhir
setiap batch**, dan pemeriksa mesin menolak bila ada pekerjaan belum di-commit, belum di-push,
handoff belum disegarkan, atau berkas siap-tempel tidak lagi memuat Prompt Pembuka apa adanya.

## 1. Tiga perintah utama

| Lee bilang | Yang terjadi | Bukti yang Lee terima |
|---|---|---|
| **"Siapkan audit menyeluruh"** (atau: *untuk keamanan akun / Fase 1 / seluruh sistem*) | Agent menyiapkan **paket audit** + berkas **SIAP-TEMPEL** di `docs/uji/paket-audit/`; bahan kalibrasi disiapkan untuk mengukur ketajaman peninjau | Laporan peninjau → agent memvalidasi, memperbaiki K-1/K-2 → ringkasan + verdict |
| **"Siapkan review PR"** | Agent menyiapkan **paket review PR** + berkas **SIAP-TEMPEL** di `docs/uji/review-pr/`, dan menyebut **jalur risiko** PR (🔴/🟡/🟢) | **Kartu Keputusan** 7 baris: verdict · jumlah K-1/K-2/K-3 · cakupan · kalibrasi · **BOLEH/JANGAN MERGE** |
| **"Tutup sesi ini dengan benar"** | Agent menyimpan semua (commit + push), memperbarui papan keadaan, menutup log sesi | Pernyataan **"sesi aman ditutup"** + commit terakhir + status PR |

---

## 2. Cara Lee menjalankan audit / review (langkah yang sama untuk keduanya)

1. Kirim kalimatnya di **sesi kerja** (sesi ini).
2. Agent menjawab: nama berkas **SIAP-TEMPEL** + perkiraan lama.
3. Lee **buka chat/percakapan BARU** (idealnya pilih **model berbeda** dari sesi kerja).
4. Lee **salin seluruh isi berkas SIAP-TEMPEL** ke chat baru itu — **satu berkas saja**, tidak perlu menambah apa pun.
5. Peninjau bekerja (hanya membaca) lalu menulis laporan.
6. Peninjau menyimpan laporannya sebagai **berkas** dan mengirimkannya (push) ke cabang sesinya — jadi laporan tidak hilang di chat.
7. Lee kembali ke sesi kerja dan bilang: **"Laporan audit sudah masuk, periksa."** / **"Laporan review sudah masuk, periksa."**
8. Agent **menarik laporan itu otomatis** dari GitHub (`--ambil-laporan`), memvalidasi dengan pemeriksa mesin, memperbaiki
   **K-1 (Kritis)** dan **K-2 (Tinggi)** lebih dulu, lalu melaporkan.
   *Kalau peninjau tidak bisa push:* Lee cukup **menempelkan isi laporan** di chat — agent membuatkan berkasnya.

**Kalau laporan tidak ketemu** saat agent menariknya: artinya peninjau belum push. Minta peninjau mengirim berkasnya
(perintahnya ada di akhir prompt peninjau), atau tempel laporannya di chat sesi kerja.

**Kenapa peninjau harus sesi baru:** penelitian menunjukkan model AI cenderung meloloskan pekerjaannya sendiri. Peninjau harus orang lain (sesi lain) dari yang mengerjakan. Kalau Lee tidak sempat membuka sesi baru, agent **tidak boleh** mengaku sudah diaudit — pekerjaan berhenti di titik bersih.

---

## 3. Arti istilah hasil (ringkas)

| Istilah | Arti untuk Lee |
|---|---|
| **K-1 Kritis** | Bisa membuat uang salah / data bocor / tidak bisa dipulihkan → wajib diperbaiki lebih dulu |
| **K-2 Tinggi** | Janji dokumen dilanggar / pengaman wajib hilang → wajib sebelum fase ditutup atau sebelum merge |
| **K-3 / K-4** | Sedang / catatan — dicatat, tidak menghambat |
| **Verdict** | `BERSIH` · `BERSIH-DENGAN-CATATAN` · `TIDAK-BERSIH` |
| **Jalur risiko PR** | 🔴 Merah (uang/keamanan/data/migrasi) · 🟡 Kuning (logika, alat, dokumen fondasi) · 🟢 Hijau (dokumen biasa) |
| **Kalibrasi** | Latihan dengan cacat sengaja: `Ditemukan: X dari Y`. Gagal kalibrasi → verdict "BERSIH" tidak dipercaya |
| **Lantai, bukan target** | Angka minimum di paket (mis. ≥12 serangan) adalah batas bawah, bukan target. Peninjau yang berhenti tepat di ambang atau menambah baris demi syarat ditandai mesin |
| **Temuan di luar cakupan** | Temuan yang tidak diminta tetap wajib dilaporkan (bagian 8 laporan) — temuan yang benar tidak boleh hilang hanya karena tidak diminta |
| **Gerbang `tahan_semua`** (pilihan Lee) | K-1 **dan** K-2 menahan fase **dan** menahan merge sampai ditutup |
| **Kartu Keputusan** | Ringkasan 7 baris untuk keputusan merge (dibuat mesin dari laporan peninjau) |

---

## 4. Kabar rutin yang Lee terima

- **Setiap batch:** laporan **5 baris** — apa yang berubah · artinya untuk Lee · bukti (uji/pemeriksa) · cacat jujur · berikutnya.
- **Setiap akhir fase:** audit independen (sesi & model berbeda) sebelum fase berikutnya.
- **Setiap PR:** review independen + Kartu Keputusan sebelum Lee diminta merge.
- **Buku tunggu** (`docs/TERTANGGUH.md`): hal yang sengaja ditunda + tenggatnya (batas 12 butir).
- **Laporan Harian** (setelah fitur jadi): 1 email/hari + daftar peringatan di aplikasi.

---

## 5. Kalau ada yang tidak beres

| Kejadian | Yang Lee lakukan |
|---|---|
| Peninjau gagal kalibrasi (banyak cacat sengaja terlewat) | Itu penemuan, bukan bencana: minta audit/review ulang (idealnya model lain) |
| Kartu Keputusan berkata `JANGAN MERGE DULU` | Jangan merge; agent menjelaskan apa yang kurang dengan bahasa sederhana |
| Ruang kerja baru dinyalakan ulang & kerja "hilang" | Minta agent memulihkan (`bash alat/pulihkan-git.sh`) — aman, tidak menghapus apa pun |
| Lee merasa penjelasan terlalu teknis | Bilang: **"Terlalu teknis, sederhanakan."** |
| Lee merasa dipaksa/tergesa-gesa | Ingatkan: **kualitas di atas kecepatan** — minta berhenti di batas bersih |

Rincian lengkap semua alur: `PANDUAN_PENGGUNA.md` **Bagian B**.
