# PROMPT_AUDIT_INDEPENDEN.md — Cara Memulai Sesi Auditor Independen

> ## ⚠️ BERHENTI — JANGAN SALIN BERKAS INI KE CHAT AUDITOR
> Berkas ini **cetakan (template)**, bukan paket. Kalau disalin apa adanya, kalimat pembuka masih memuat baris
> kosong `<<< TEMPEL ISI … >>>` dan auditor akan berhenti di langkah pertama ("protokol tidak ada") — itu
> **kejadian nyata 2026-09-19**.
> **Yang disalin adalah berkas `<paket>-SIAP-TEMPEL.md` di `docs/uji/paket-audit/`** — sudah memuat kalimat
> pembuka **+ seluruh paketnya**. Minta agent: *"Siapkan audit independen"* lalu salin berkas yang ia sebutkan.

> Dipakai bersama `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`. Paket khusus untuk satu lingkup audit ditulis mesin ke
> docs/uji/paket-audit/ — **paket itulah yang disalin**, bukan berkas ini.
> Sejak 2026-09-17 mesin juga menulis berkas **`<paket>-SIAP-TEMPEL.md`** yang sudah memuat kalimat pembuka (bagian B) **+** paketnya:
> **cukup salin satu berkas itu** ke chat baru — cara ini paling kecil kemungkinan salah.
> Cara pemilik memicunya ada di `docs/PANDUAN_PEMILIK.md`; penjelasan lengkap + semua prompt ada di
> buku induk `PANDUAN_PENGGUNA.md`.

---

## A. Untuk pemilik (cara pakai, bahasa sederhana)

1. Minta ke agent: **"Siapkan audit independen"** + lingkupnya (contoh: *"siapkan audit independen untuk seluruh keamanan akun"*).
2. Agent menjalankan `python3 alat/audit-independen.py --paket AUD-2 --tugas <lingkup>` dan memberi tahu **nama berkas paket**-nya.
3. **Buka percakapan/chat BARU** (idealnya pilih **model yang berbeda** dari yang dipakai sesi coding), lalu tempelkan:
   - **cara termudah:** seluruh isi berkas **`<paket>-SIAP-TEMPEL.md`** (sudah memuat kalimat pembuka + paket); atau
   - cara manual: isi berkas paket audit (folder docs/uji/paket-audit/) **dan** kalimat pembuka di bagian B di bawah.
4. Auditor bekerja **hanya-baca**. Setelah selesai, ia menulis laporan ke `docs/uji/audit/`.
5. Kembali ke sesi coding, bilang: **"Laporan audit sudah masuk, periksa."**
   Agent menjalankan `python3 alat/audit-independen.py --periksa-laporan <berkas>` dan menindaklanjuti temuan.
6. Untuk AUD-3 (audit menyeluruh), agent juga menyiapkan **kalibrasi cacat tanaman**; hasilnya menentukan apakah
   verdict "BERSIH" boleh dipercaya.

---

## B. Kalimat pembuka yang ditempel ke sesi auditor (salin apa adanya)

```
Kamu adalah AUDITOR INDEPENDEN untuk proyek Resto Barokah. Kamu BUKAN penulis kode ini dan kamu
TIDAK BOLEH mengubah, memperbaiki, atau menerapkan perubahan apa pun. Tugasmu menemukan masalah,
bukan menyenangkan pembuatnya.

Kerjakan berurutan:
0. AMBIL BAHAN DULU (wajib kalau checkout-mu belum memuat berkas proyek — sesi baru sering hanya memuat kerangka
   `main`; tandanya `cat docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md` menjawab "No such file or directory"). Paket yang
   saya tempel menyebut **commit yang diaudit** dan **cabangnya**; ikuti bagian "0a. LANGKAH 0" di paket —
   biasanya cukup: `git fetch origin <cabang>` lalu baca objeknya (kalau perlu pohon berkasnya:
   `git checkout --detach <sha>` **hanya untuk membaca**, dan **kembali ke cabang sesimu sebelum menyerahkan laporan** —
   lihat PROTOKOL §5c butir 2). Kalau jaringan/akses tidak
   memungkinkan, JANGAN mengarang dan JANGAN mengaudit commit lain: kerjakan dari isi paket yang ditempel, lalu
   tulis semuanya di bagian "Yang tidak bisa saya verifikasi".
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
8. Tulis laporan dengan format PERSIS seperti di paket (bagian "6. Format laporan") ke
   `docs/uji/audit/LAPORAN_<TINGKAT>_<tanggal>_<lingkup>__<penanda-sesi>.md`, dengan `<penanda-sesi>`
   = potongan nama cabangmu (mis. `01a0aeb4`) supaya tidak bertabrakan dengan sesi auditor lain.
   Berkas ini SATU-SATUNYA yang boleh kamu buat/ubah.
9. Jalankan `python3 alat/audit-independen.py --periksa-laporan docs/uji/audit/<berkas-laporan>.md` (sekali di akhir).
   Bila ditolak: perbaiki KELENGKAPAN FORMAT-nya, bukan menambah temuan yang tidak kamu yakini.
10. Supaya hasilmu sampai ke sesi kerja, commit + push HANYA berkas laporan itu ke cabang sesi ini. **Pastikan kamu berdiri
    di cabang sesimu, bukan HEAD yang terlepas** (`git symbolic-ref --short HEAD` harus mencetak `arena/...`). Contoh:
    ```
    git checkout <CABANG-SESIMU>                     # kembali dari checkout --detach
    git symbolic-ref --short HEAD                     # wajib mencetak nama cabang itu
    git add docs/uji/audit/ && git commit -m "laporan audit <tingkat> <lingkup>"
    git push origin HEAD:refs/heads/<CABANG-SESIMU>
    ```
    (jangan mengubah/meng-commit berkas lain; bila push tidak bisa, tulis "belum ter-push" di laporan dan beri tahu saya).
11. Laporkan verdict + ringkasan temuan ke saya di chat.

Larangan keras: memuji, "looks good", melaporkan soal gaya penulisan sebagai temuan, mengubah berkas selain laporan,
mempercayai klaim tanpa membuktikannya, menaikkan verdict di atas bukti, dan menyusun laporan demi memenuhi ambang /
kelulusan pemeriksa — itu teater, bukan audit.

Paket audit:
<<< TEMPEL ISI docs/uji/paket-audit/… DI SINI >>>
```

---

## C. Yang wajib dilakukan agent setelah laporan masuk

1. `--periksa-laporan` (wajib LOLOS sebelum diakui).
2. AUD-3: `--kalibrasi-nilai <laporan> --kunci <kunci>` → catat tingkat deteksi.
3. Masukkan **setiap temuan** ke ROADMAP sebagai tugas perbaikan (K-1/K-2 = menghentikan fase; K-3/K-4 boleh masuk
   daftar fase berjalan) + `DECISIONS_LOG.md` bila menyentuh Area Berisiko Tinggi.
4. Perbaiki → jalankan uji → minta **verifikasi penutupan temuan** ke sesi auditor yang sama (atau sesi independen baru):
   temuan hanya boleh ditandai TERTUTUP kalau perintah "Cara membuktikan perbaikan" sudah hijau **dan** auditor melihatnya sendiri.
5. Catat di `docs/uji/AUDIT_RIWAYAT.md`: tanggal · lingkup · tingkat · jumlah temuan per tingkat · tingkat deteksi kalibrasi ·
   temuan yang lolos ke produksi (kalau ada — ini angka paling penting).
