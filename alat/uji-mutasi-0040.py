#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar migrasi 0040 (urutan rantai audit):
  1. Pemeriksa rantai dikembalikan ke urutan jam (waktu asc, id asc)
  2. Pembangun rantai dikembalikan ke pencarian induk lewat jam
  3. Nomor urut kiriman klien dipercaya (bisa menyelip ke tengah rantai)
  4. Nomor urut tidak diterbitkan peladen (kolom NOT NULL yang menangkap)

Setiap mutasi WAJIB membuat berkas uji 'urutan_rantai_audit.sql' MERAH.

Verifikasi: python3 alat/uji-mutasi-0040.py            (4/4 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0040.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0040_urutan_rantai_audit.sql")


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/urutan_rantai_audit.sql"],
        cwd=REPO,
        capture_output=True,
        text=True
    )
    output = res.stdout + res.stderr
    lulus = "uji: 1 LULUS · 0 GAGAL" in output
    return lulus, output


def uji_mutasi():
    print("UJI MUTASI 0040 (urutan rantai audit — anti seri dalam satu transaksi)")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()

    daftar_mutasi = [
        ("Pemeriksa rantai dikembalikan ke urutan jam",
         "     order by urutan asc\n  loop",
         "     order by waktu asc, id asc\n  loop"),
        ("Pembangun rantai mencari induk lewat jam",
         "   order by urutan desc\n   limit 1",
         "   order by waktu desc, id desc\n   limit 1"),
        ("Nomor urut kiriman klien dipercaya",
         "  NEW.urutan := nextval(pg_get_serial_sequence('public.catatan_audit', 'urutan'));",
         "  -- mutasi: urutan kiriman perangkat dipakai apa adanya"),
        ("Nomor urut tidak diterbitkan peladen",
         "  NEW.urutan := nextval(pg_get_serial_sequence('public.catatan_audit', 'urutan'));",
         "  NEW.urutan := null;   -- mutasi: peladen tidak menerbitkan nomor urut"),
    ]

    try:
        lulus, out = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: Uji urutan_rantai_audit.sql tidak lulus pada salinan utuh!")
            print(out)
            return 1
        print("  OK  kontrol: salinan utuh → uji urutan_rantai_audit.sql hijau")

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
                print(out[-1500:])
                return 1
            print(f"  [OK] Mutasi {i}: {nama} TERBUKTI MERAH")

        print(f"\nHASIL: LOLOS — seluruh {len(daftar_mutasi)} mutasi wajib MERAH terbukti membuat uji merah.")
        return 0

    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli_migrasi)


def uji_diri():
    print("UJI DIRI penilai mutasi 0040")
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
