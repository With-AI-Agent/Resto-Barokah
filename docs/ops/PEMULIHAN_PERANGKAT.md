# Panduan Pemulihan Perangkat Darurat (Kunci Induk)

> **Tujuan:** Jika seluruh perangkat kasir/admin hilang, dicuri, atau rusak total, operasional resto tetap dapat dipulihkan oleh Pemilik (`owner_pusat`) tanpa membuka celah pintu belakang yang melemahkan keamanan.
> **Rujukan:** `docs/ROADMAP.md` T1-36 · `docs/TECH_SPEC.md` §9 ART-11 · `docs/KEAMANAN.md` §4b.

---

## 1. Prinsip Keamanan Kunci Induk

1. **Hanya `owner_pusat`**: Hanya pemilik resto terdaftar yang memiliki hak membuat kode darurat dan mengajukan pemulihan perangkat.
2. **Sekali Pakai & Tersimpan sebagai Hash**: Kode pemulihan darurat hanya dapat digunakan satu kali. Database hanya menyimpan hash satu arah (bcrypt), sehingga tidak dapat diintip dari database.
3. **Masa Tenggang 30 Menit**: Setiap pengajuan perangkat darurat harus melalui masa tenggang 30 menit sebelum perangkat diaktifkan. Hal ini memberi kesempatan bagi pengelola untuk membatalkan jika terjadi penyalahgunaan.
4. **Penyimpanan Dua Amplop Tersegel**:
   - **Salinan A**: Disimpan di kediaman pribadi pemilik.
   - **Salinan B**: Disimpan di brankas/arsip kantor di luar area kasir/layanan.
   - Dilarang keras menyimpan kode di catatan ponsel, foto, email, atau obrolan chat.
5. **Rotasi Wajib**: Kode wajib dibuat ulang setelah digunakan atau minimal 1 tahun sekali.

---

## 2. Tata Cara Pembuatan Kode Pemulihan

Pemilik (`owner_pusat`) menjalankan RPC:
```sql
select public.buat_kode_pemulihan('frasa-rahasia-darurat-minimal-20-karakter-acak');
```
- Sistem secara otomatis membatalkan kode pemulihan lama yang belum terpakai.
- Catat frasa rahasia ke dalam 2 lembar kertas fisik, masukkan ke dalam amplop tersegel bertanggal dan bertanda tangan.

---

## 3. Langkah Pemulihan Saat Kehilangan Perangkat

> **Siapa yang menjalankan (KEPUTUSAN LEE 2026-10-07, PMB1-F-083):** sampai
> layar darurat mandiri dibangun (dijadwalkan pra-pilot bersama klaster login),
> prosedur ini adalah prosedur **Tingkat 4 — pemilik platform mendampingi
> owner pusat**: owner menghubungi pemilik platform, membacakan kode pemulihan
> dari amplopnya, dan pemilik platform menjalankan langkah-langkah SQL di bawah
> (teruji: migrasi 0102 + 0105, suite `supabase/tes/pemulihan_aktivasi_darurat.sql`).
> Sebelumnya baris ini menjanjikan owner menjalankan sendiri (Tingkat 3);
> janji itu kini tercatat jujur di `docs/KEAMANAN.md` §4b.

Jika seluruh perangkat operasional tidak dapat diakses:

1. **Buka Amplop Tersegel**: Owner mengambil kode pemulihan fisik.
2. **TANPA perlu masuk aplikasi** — seluruh jalur ini dirancang untuk owner
   yang kehilangan SELURUH perangkat (tidak ada sesi `owner_pusat` yang bisa
   dipakai). Sejak migrasi 0102 (pengajuan) dan 0105 (aktivasi), kedua langkah
   di bawah bisa dijalankan tanpa sesi — dijalankan pemilik platform dari
   konsol SQL, didampingi owner.
3. **Ajukan Pemulihan Perangkat Darurat** (dari perangkat baru, tanpa sesi):
   ```sql
   select public.pulihkan_perangkat(
     'frasa-rahasia-darurat-minimal-20-karakter-acak',
     'Tablet-Kasir-Darurat-01',
     'kunci-perangkat-minimal-16-karakter',
     '<cabang-id>'
   );
   ```
   Catat baik-baik `kunci-perangkat` yang dipilih — kunci itu menjadi bukti
   kepemilikan pada langkah 5 (kode pemulihan hangus sekali pakai di sini).
4. **Masa Tenggang 30 Menit**:
   - Status pemulihan tercatat sebagai `menunggu`.
   - Perangkat darurat berstatus nonaktif selama masa tenggang.
   - Peringatan tercatat di `catatan_audit`.
5. **Aktivasi Setelah 30 Menit** (tanpa sesi, bukti = kunci perangkat):
   Setelah waktu 30 menit berlalu, jalankan:
   ```sql
   select public.selesaikan_pemulihan_darurat('kunci-perangkat-minimal-16-karakter');
   ```
   Perangkat darurat resmi aktif dan dapat langsung digunakan untuk
   operasional kasir/PIN staf. (Jalur lama `selesaikan_pemulihan` tetap ada
   bagi yang masih punya sesi, tetapi tidak lagi dibutuhkan.)
6. **Buat Kode Pemulihan Baru**: Segera buat kode pemulihan baru dan simpan kembali dalam 2 amplop tersegel.

---

## 4. Pembatalan Pemulihan yang Mencurigakan

Jika ada notifikasi/catatan pengajuan pemulihan yang tidak dikenali:
1. Segera batalkan permohonan sebelum masa tenggang 30 menit berakhir:
   ```sql
   select public.batalkan_pemulihan('<pemulihan-id>', 'Aktivitas mencurigakan');
   ```
2. Perangkat yang diajukan akan tetap terkunci nonaktif secara permanen.

> **KEPUTUSAN LEE 2026-10-07 (PMB1-F-238):** jika SELURUH perangkat hilang dan
> ada pengajuan pemulihan mencurigakan, jalan resminya = **eskalasi Tingkat 4**:
> owner menghubungi pemilik platform, dan pemilik platform membatalkan dari
> konsol (sesi `service_role`/`owner_pusat` yang sah, tercatat audit).
> `batalkan_pemulihan` sengaja TIDAK dibuka tanpa sesi — tanpa bukti
> kepemilikan yang bisa diverifikasi, jalur tanpa sesi justru membuka celah
> pembatalan oleh pihak asing. Jendela 30 menit dirancang supaya eskalasi ini
> hingga sempat berjalan sebelum perangkat diaktifkan.
