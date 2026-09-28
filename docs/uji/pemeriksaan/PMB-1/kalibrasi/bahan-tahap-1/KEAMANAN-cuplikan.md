# Cuplikan KEAMANAN — usulan revisi §6 & §7 (bahan kalibrasi; lihat README.md)

## 6. PIN

1. **6 digit**, **unik antar pegawai dalam satu resto**, dilarang pola lemah (111111, 123456, tanggal lahir, dsb.).
2. Disimpan hanya sebagai **hash bcrypt** (pgcrypto) dengan batas kolom yang menolak nilai bukan-hash (berlaku sejak T1-06).
3. **Tidak ada fungsi yang mengembalikan hash**, dan PIN tidak pernah masuk log (dijaga pemeriksa statis `alat/periksa-fungsi-pin.py`).
4. **Batas percobaan dua lapis:** 10×/15 menit per akun · 12×/15 menit per perangkat; percobaan yang ditolak karena terkunci tetap dihitung; semua percobaan tercatat di tabel yang NYATA hari ini — `percobaan_pin` (verifikasi) dan `percobaan_simpan_pin` (pemasangan PIN). Penyatuan ke tabel `percobaan_masuk` adalah RENCANA Fase 1B (ROADMAP T1-26), bukan keadaan sekarang.
5. **PIN benar belum cukup untuk aksi:** persetujuan tetap diperiksa lewat `boleh_untuk()` — PIN dapur tidak bisa menyetujui void hanya karena PIN-nya benar (aturan T1-06); sejak 0016 konsumen kupon (void & diskon) mengecek ULANG izin penyetuju saat kupon dipakai, dan aksi berkupon wajib menyebut pesanan.
6. Ganti PIN sendiri wajib PIN lama; mengganti PIN pegawai lain wajib `kelola_pegawai` + tercatat + (sejak Fase 1B) pemberitahuan. PIN warisan 4 angka (data lama) tidak bisa dipakai masuk, tetapi diterima sebagai PIN lama untuk naik kelas ke 6 angka (sejak 0016, temuan review PR-09).

## 7. Sesi

| Kendali | Nilai | Penegak |
|---|---|---|
| Umur token akses | 15 menit | Supabase (pengaturan, gratis) |
| Umur maksimum sesi | Staf 12 jam · admin/owner 30 hari · pemilik platform 30 hari | Database (`sesi_perangkat`) |
| Kunci otomatis saat menganggur | 15 / 15 / 15 / 30 / 60 menit (kasir/pelayan/dapur/admin/owner) — **hanya berlaku di luar jam aktif**; di dalam jam aktif perangkat tetap terkunci saat ditinggal sesuai batas peran | Aplikasi + aturan dokumen |
| Jam aktif per cabang (**keputusan pemilik 2026-09-17**) | Diatur owner di Pengaturan (mis. buka 09.00 – tutup 22.00, ditambah masa persiapan/pembersihan); di luar jam itu kunci otomatis **15 menit** | Pengaturan + aplikasi |
| Kunci = | sesi dihapus dari perangkat; buka lagi wajib PIN/kata sandi | Aplikasi |
| Batas percobaan masuk | 5×/15 menit per akun · 12×/15 menit per perangkat | Database |
| Pencabutan | per perangkat · per akun · semua perangkat | Database + RPC (seketika) |

**Catatan jujur paket gratis:** "time-box sesi", "inactivity timeout", "satu sesi per pengguna", dan pemeriksa kata sandi bocor (HaveIBeenPwned) adalah fitur **Pro**; karenanya kendali di atas dibuat sendiri. Kompensasi untuk kata sandi: minimum 12 karakter + pola umum dilarang + TOTP wajib.
