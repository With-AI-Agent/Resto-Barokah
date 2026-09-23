#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar migrasi 0038 (waktu_peladen):
  1. Fungsi dijadikan `security definer` (jam peladen tidak boleh berhak istimewa)
  2. Kunci `search_path` dilepas (pelajaran ACL/search_path 0023 & 0027)
  3. Hak execute `authenticated` dicabut (papan dapur kehilangan waktu peladen)

Setiap mutasi WAJIB membuat berkas uji 'waktu_peladen.sql' MERAH.

Verifikasi: python3 alat/uji-mutasi-0038.py            (3/3 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0038.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0038_waktu_peladen.sql")


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/waktu_peladen.sql"],
        cwd=REPO,
        capture_output=True,
        text=True
    )
    output = res.stdout + res.stderr
    lulus = "uji: 1 LULUS · 0 GAGAL" in output
    return lulus, output


def uji_mutasi():
    print("UJI MUTASI 0038 (waktu_peladen — jam peladen untuk papan dapur)")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()

    daftar_mutasi = [
        ("Fungsi dijadikan security definer",
         "security invoker",
         "security definer"),
        ("Kunci search_path dilepas",
         "set search_path = public, pg_temp",
         "-- mutasi: search_path tidak dikunci"),
        ("Hak execute authenticated dicabut",
         "grant execute on function public.waktu_peladen() to authenticated;",
         "-- mutasi: pegawai tidak lagi boleh memanggil"),
    ]

    try:
        lulus, out = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: Uji waktu_peladen.sql tidak lulus pada salinan utuh!")
            print(out)
            return 1
        print("  OK  kontrol: salinan utuh → uji waktu_peladen.sql hijau")

        for i, (nama, asal, ganti) in enumerate(daftar_mutasi, start=1):
            hasil = asli_migrasi.replace(asal, ganti)
            if hasil == asli_migrasi:
                print(f"  [X] Mutasi {i}: teks mutasi TIDAK MENEMPEL pada berkas — periksa jangkar!")
                return 1
            with open(MIGRASI, "w", encoding="utf-8") as f:
                f.write(hasil)
            lulus, out = jalankan_uji()
            if lulus:
                print(f"  [X] Mutasi {i}: {nama} LOLOS (Pagar tumpul!)")
                return 1
            print(f"  [OK] Mutasi {i}: {nama} TERBUKTI MERAH")

        print(f"\nHASIL: LOLOS — seluruh {len(daftar_mutasi)} mutasi wajib MERAH terbukti membuat uji merah.")
        return 0

    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli_migrasi)


def uji_diri():
    print("UJI DIRI penilai mutasi 0038")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()
    palsu = asli_migrasi.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli_migrasi:
        print("  [X] deteksi jangkar tidak menempel TIDAK bekerja")
        return 1
    lulus, _ = jalankan_uji()
    if not lulus:
        print("  [X] kontrol hijau tidak berfungsi")
        return 1
    print("  OK  kontrol positif hijau & deteksi jangkar tidak menempel bekerja.")
    return 0


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
