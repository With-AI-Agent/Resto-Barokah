# PANDUAN_PEMILIK.md — Cara Bapak Mengendalikan Proyek Ini

> **Buku induk (lengkap):** `PANDUAN_PENGGUNA.md` — semua mekanisme, semua prompt, glosarium, dan penanganan masalah. Berkas ini = pelengkap khusus AUDIT (cara memicu, arti verdict, kalibrasi).

> Ditulis untuk **pemilik**, bukan programmer. Semua istilah teknis dijelaskan di tempat.
> Bila panduan ini dan kenyataan berbeda, **kenyataan yang benar** — laporkan supaya panduan diperbaiki (aturan pemilik 2026-09-17).

---

## 1. Tiga hal yang bisa Bapak perintahkan kapan saja

| Bapak bilang | Yang terjadi | Bukti yang Bapak terima |
|---|---|---|
| **"Siapkan audit independen"** (+ lingkup: "seluruh sistem" / "keamanan akun" / "Fase 1") | Agent menyiapkan **paket audit**; Bapak membuka **chat baru dengan model berbeda**, menempel paket + kalimat pembuka (§3 di bawah) | Laporan audit + verdict + daftar temuan; agent memperbaiki temuan berat sebelum lanjut |
| **"Kerjakan ulang X"** | Agent mengulang pekerjaan yang Bapak sebut (mis. kode lama yang bertentangan dengan aturan baru) | Daftar pekerjaan ulang + bukti uji setelah selesai |
| **"Berhenti dulu"** | Agent berhenti di batas bersih: semua tersimpan di Git + laporan 5 baris | Tidak ada pekerjaan menggantung tanpa catatan |

---

## 2. Kabar rutin yang Bapak terima

- **Setiap batch pekerjaan:** laporan **5 baris** — apa yang berubah · artinya untuk Bapak · bukti (uji/pemeriksa) · cacat yang jujur dilaporkan · langkah berikutnya.
- **Setiap akhir fase:** **audit independen** (sesi & model berbeda) sebelum fase berikutnya boleh dimulai.
- **Buku tunggu** (`docs/TERTANGGUH.md`): hal-hal yang sengaja ditunda + tenggatnya. Batas 12 butir; kalau penuh, agent wajib berhenti dan minta keputusan Bapak.
- **Laporan Harian** (setelah fitur jadi): 1 email/hari + daftar peringatan di aplikasi (omzet, void, diskon, selisih kas, percobaan masuk gagal, perubahan perangkat).

---

## 3. Cara meminta audit independen (langkah demi langkah)

**Kenapa langkahnya begini:** pemeriksa harus **orang/sesi lain** dari yang mengerjakan. Model AI cenderung meloloskan pekerjaannya sendiri (terbukti dalam riset), jadi pemeriksa wajib sesi baru — dan bila bisa, **model berbeda**.

1. Di sesi kerja biasa, Bapak bilang: **"Siapkan audit independen untuk <lingkup>."**
2. Agent menjawab dengan: nama berkas paket (folder docs/uji/paket-audit/), tingkat audit (AUD-2 biasa / AUD-3 menyeluruh), dan lama perkiraan.
3. Bapak **buka chat baru**, pilih **model lain** bila tersedia.
4. Salin **isi berkas paket** + **kalimat pembuka** dari `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` ke chat baru itu.
5. Auditor bekerja (hanya membaca, tidak mengubah apa pun) dan menulis laporan.
6. Kembali ke sesi kerja, Bapak bilang: **"Laporan audit sudah masuk, periksa dan tindak lanjuti."**
7. Agent: memvalidasi laporan dengan mesin → memperbaiki temuan **K-1 (Kritis)** & **K-2 (Tinggi)** lebih dulu → melaporkan ke Bapak.

### 3b. Audit menyeluruh (AUD-3) — untuk keadaan sekarang, sebelum pekerjaan ulang

Bapak minta: **"Siapkan audit menyeluruh"** (tanpa lingkup — menyeluruh berarti **semua berkas proyek**, termasuk **berkas untuk pengguna**). Yang agent siapkan dalam batch yang sama:

1. Paket `python3 alat/audit-independen.py --paket AUD-3 --semua` → daftar **semua grup berkas** + jumlah berkasnya (contoh terakhir: ratusan berkas proyek; kumpulan skill pihak ketiga dikecualikan dengan alasan tertulis).
2. Salinan kalibrasi cacat tanaman (`--kalibrasi-siapkan`) supaya ketajaman auditor **terukur** — jangan pernah memakai AUD-3 tanpa kalibrasi.
3. Kalimat pembuka yang harus Bapak tempel (Bagian D1 buku induk / `docs/uji/PROMPT_AUDIT_INDEPENDEN.md` §B).

Laporan AUD-3 **ditolak mesin** bila tidak memuat: mode `menyeluruh`, ringkasan `Cakupan menyeluruh: X dari Y berkas`, satu baris bukti per grup berkas, sub-bagian `### 1a. Berkas untuk pengguna`, atau cakupan < 90%. Artinya: tidak ada jalan pintas "audit contoh".

**Gerbang yang Bapak pilih (2026-09-17): `tahan_semua`** — temuan **K-1 dan K-2** sama-sama **menahan fase** sampai diperbaiki & diverifikasi; K-3/K-4 masuk daftar perbaikan.

**Bila Bapak tidak mau repot membuka chat baru:** Bapak bisa minta agent melakukannya, tetapi hasilnya lebih lemah (sesi yang mengerjakan cenderung membela pekerjaannya sendiri). Agent **wajib jujur** menyebut kelemahan ini, bukan menyamarkan.

---

## 4. Cara membaca hasil audit (arti istilah)

| Istilah | Arti untuk Bapak |
|---|---|
| **K-1 Kritis** | Bisa membuat uang salah, data bocor, atau jejak hilang. **Wajib diperbaiki sebelum pekerjaan lain.** |
| **K-2 Tinggi** | Janji di dokumen dilanggar / pengaman wajib hilang. Wajib diperbaiki sebelum fase ditutup. |
| **K-3 Sedang** | Tidak konsisten, uji kurang, dokumen basi. Diperbaiki di fase berjalan. |
| **K-4 Catatan** | Kerapian; tidak menghambat. Boleh masuk daftar tunggu. |
| **BERSIH** | Tidak ada temuan K-1/K-2, semua temuan punya bukti, dan (untuk audit menyeluruh) auditor lulus **kalibrasi cacat tanaman**. |
| **BERSIH-DENGAN-CATATAN** | Tidak ada masalah berat; ada perbaikan kecil yang dicatat. |
| **TIDAK-BERSIH** | Ada masalah berat; pekerjaan **dihentikan** sampai diperbaiki. |
| **Terkalibrasi / Belum terkalibrasi** | Apakah auditor sudah terbukti bisa menemukan cacat yang sengaja ditanam. Kalau "belum", verdict BERSIH-nya **tidak boleh dipercaya** dan audit harus diulang. |
| **Gagal kalibrasi** | Bukan bencana: artinya mekanisme bekerja — ketidaktajaman terdeteksi **sebelum** merugikan Bapak. |

---

## 5. Kalibrasi cacat tanaman (kenapa ini penting, bahasa sederhana)

Sebelum auditor boleh bilang "semua aman", agent menanam **beberapa kesalahan yang sengaja dibuat** di salinan
kode (termasuk kesalahan yang tersembunyi), lalu auditor mencari tanpa tahu jawabannya. Kalau auditor menemukan
hampir semuanya → kemampuannya terbukti, verdict "BERSIH"-nya bermakna. Kalau banyak yang terlewat → laporan
ditandai **belum terkalibrasi** dan hasilnya tidak dipakai sebagai bukti.

**Jujur soal batas:** mustahil menjamin 100% tidak ada yang terlewat — penelitian inspeksi pun menunjukkan tim
profesional menemukan sekitar 58% cacat. Karena itu ada berlapis-lapis: uji otomatis (mesin) → auditor independen
→ kalibrasi → dan **uji terima oleh Bapak sendiri** di perangkat nyata. Yang kami lakukan adalah menaikkan angka
deteksi dan **mengukurnya**, bukan menjanjikan keajaiban.

---

## 6. Hal-hal yang tidak boleh ditunda (agent wajib berhenti & bertanya)

1. Keamanan, uang, atau data pelanggan yang belum jelas.
2. Muncul **biaya** (walau kecil).
3. Permintaan yang bertentangan dengan keputusan yang sudah dikunci.
4. Dua dokumen saling bertentangan.
5. Agent ingin **menyimpang** dari deskripsi/rancangan Bapak (walau niatnya memperbaiki) — aturan Bapak 2026-09-17: **tanya dulu, jelaskan bahasa sederhana, baru kerjakan, lalu dicatat**.

---

## 7. Riwayat dokumen ini

| Tanggal | Perubahan | Alasan |
|---|---|---|
| 2026-09-17 | Dibuat; bagian audit independen ditambahkan | Permintaan pemilik: *"Aku mau setelah mekanisme ini tertanam, di panduan pengguna dijelaskan cara ketika aku mau melakukan ini"* |
