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
