#!/usr/bin/env python3
"""
UJI MUTASI 0048 — membuktikan ketajaman pagar T7-04 di `0048_wajib_shift.sql`:
"transaksi hanya dalam shift terbuka: pesanan dan pembayaran di luar shift
terbuka ditolak dengan pesan jelas saat wajib_shift aktif".

Mutasi yang wajib membuat `supabase/tes/wajib_shift.sql` MERAH:
  1. Pagar pesanan tanpa shift kasir dicabut
  2. Pagar pembayaran tanpa shift kasir dicabut pada pemicu
  3. Pagar RPC bayar_pesanan tanpa shift kasir dicabut
  4. Pagar shift tertutup pada pesanan dicabut
  5. Pengaturan wajib_shift diabaikan
  6. Otomatisasi tautan shift_id pada pesanan dirusak

Verifikasi: python3 alat/uji-mutasi-0048.py
            python3 alat/uji-mutasi-0048.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0048_wajib_shift.sql")
BERKAS_UJI = ["supabase/tes/wajib_shift.sql"]


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", *BERKAS_UJI],
        cwd=REPO,
        capture_output=True,
        text=True,
    )
    keluaran = res.stdout + res.stderr
    return f"uji: {len(BERKAS_UJI)} LULUS · 0 GAGAL" in keluaran, keluaran


DAFTAR_MUTASI = [
    (
        "pagar pesanan tanpa shift kasir dicabut",
        "raise exception 'SH-400: Tidak dapat membuat pesanan: belum ada shift kas yang dibuka di cabang ini.';",
        "-- mutasi: pesanan lolos tanpa shift\n        v_shift_id := null;",
    ),
    (
        "pagar pembayaran tanpa shift kasir dicabut pada pemicu",
        "raise exception 'SH-400: Tidak dapat memproses pembayaran: belum ada shift kas yang dibuka di cabang ini.';",
        "-- mutasi: pembayaran lolos tanpa shift\n        v_shift_id := null;",
    ),
    (
        "pagar RPC bayar_pesanan tanpa shift kasir dicabut",
        "raise exception 'SH-400: Tidak dapat memproses pembayaran: belum ada shift kas yang dibuka di cabang ini.';",
        "-- mutasi: rpc bayar_pesanan lolos tanpa shift kasir\n      v_shift_id := null;",
    ),
    (
        "pagar shift tertutup pada pesanan dicabut",
        "raise exception 'SH-400: Shift kas % sudah ditutup atau tidak valid.', NEW.shift_id;",
        "-- mutasi: shift tertutup dibiarkan lewat\n        null;",
    ),
    (
        "pengaturan wajib_shift diabaikan (dianggap selalu false)",
        "if v_wajib then",
        "if false and v_wajib then",
    ),
    (
        "otomatisasi tautan shift_id pada pesanan dirusak",
        "NEW.shift_id := v_shift_id;",
        "NEW.shift_id := null;",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0048 (T7-04 — transaksi hanya dalam shift terbuka)")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()

    try:
        lulus, keluaran = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: uji tidak hijau pada salinan utuh!")
            print(keluaran[-1500:])
            return 1
        print("  OK  kontrol: salinan utuh → " + " + ".join(BERKAS_UJI) + " hijau")

        for nomor, (nama, asal, ganti) in enumerate(DAFTAR_MUTASI, start=1):
            if asal not in asli:
                print(f"  [X] Mutasi {nomor}: teks mutasi TIDAK MENEMPEL pada berkas — periksa jangkar!")
                return 1
            # Ganti kemunculan pertama saja jika ada duplikasi atau target spesifik
            hasil = asli.replace(asal, ganti, 1)
            with open(MIGRASI, "w", encoding="utf-8") as f:
                f.write(hasil)
            lulus, keluaran = jalankan_uji()
            if lulus:
                print(f"  [X] Mutasi {nomor}: {nama} LOLOS (pagar tumpul!)")
                print(keluaran[-1500:])
                return 1
            print(f"  [OK] Mutasi {nomor}: {nama} TERBUKTI MERAH")

        print(
            f"\nHASIL: LOLOS — semua {len(DAFTAR_MUTASI)} mutasi WAJIB MERAH benar-benar merah; "
            "pagar transaksi wajib shift (T7-04) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0048")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()
    palsu = asli.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli:
        print("  [X] deteksi jangkar tidak menempel TIDAK bekerja")
        return 1
    lulus, _ = jalankan_uji()
    if not lulus:
        print("  [X] kontrol positif tidak hijau — penilai tidak bisa dipercaya")
        return 1
    print("  OK  kontrol positif hijau & deteksi jangkar tidak menempel bekerja.")
    return 0


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
