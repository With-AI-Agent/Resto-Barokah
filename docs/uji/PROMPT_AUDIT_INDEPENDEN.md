# PROMPT_AUDIT_INDEPENDEN.md — Cara Memulai Sesi Auditor Independen

> Dipakai bersama `docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md`. Paket khusus untuk satu lingkup audit ditulis mesin ke
> docs/uji/paket-audit/ — **paket itulah yang disalin**, bukan berkas ini.
> Cara pemilik memicunya ada di `docs/PANDUAN_PEMILIK.md`; penjelasan lengkap + semua prompt ada di
> buku induk `PANDUAN_PENGGUNA.md`.

---

## A. Untuk pemilik (cara pakai, bahasa sederhana)

1. Minta ke agent: **"Siapkan audit independen"** + lingkupnya (contoh: *"siapkan audit independen untuk seluruh keamanan akun"*).
2. Agent menjalankan `python3 alat/audit-independen.py --paket AUD-2 --tugas <lingkup>` dan memberi tahu **nama berkas paket**-nya.
3. **Buka percakapan/chat BARU** (idealnya pilih **model yang berbeda** dari yang dipakai sesi coding), lalu tempelkan:
   - isi berkas paket audit (berkas paket di folder docs/uji/paket-audit/), **dan**
   - kalimat pembuka di bagian B di bawah.
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
