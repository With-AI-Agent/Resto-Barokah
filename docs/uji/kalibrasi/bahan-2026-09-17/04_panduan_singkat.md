# Bahan kalibrasi (bukan kode proyek) — berisi cacat yang disengaja

## Cara menyalakan pratinjau aplikasi
1. Jalankan `bash aplikasi/pratinjau.sh` dari akar repo.
2. Buka `http://localhost:5173` di peramban.
3. Kalau layar putih, jalankan `python3 alat/periksa-struktur.py` lalu muat ulang.

## Kebijakan PIN
- PIN wajib 6 angka.
- Salah PIN **10 kali** berturut-turut → akun terkunci 15 menit.
- Kebijakan lengkap ada di `docs/PANDUAN_KEAMANAN.md` §4.

## Batas lebih bayar
- Kasir tidak boleh menerima pembayaran melebihi total pesanan; selisih lebih bayar ditolak sistem.
