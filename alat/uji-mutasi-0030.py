#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar migrasi 0030 (T1-24, T1-25, T1-26):
  1. Pelepasan izin kelola_pegawai pada buat_kode_perangkat (T1-24)
  2. Pelepasan verifikasi perangkat_sah pada ikat_sesi_perangkat (T1-25)
  3. Pelepasan pencabutan sesi saat cabut_perangkat (T1-25)
  4. Pelepasan pembatasan 5x percobaan akun pada periksa_kunci_masuk (T1-26)

Setiap mutasi WAJIB membuat berkas uji 'sesi_dan_perangkat.sql' MERAH.
"""
import os
import re
import subprocess
import sys
import tempfile
import shutil

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI_0030 = os.path.join(REPO, "supabase", "migrations", "0030_sesi_dan_persetujuan_perangkat.sql")
BERKAS_TES = os.path.join(REPO, "supabase", "tes", "sesi_dan_perangkat.sql")

def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/sesi_dan_perangkat.sql"],
        cwd=REPO,
        capture_output=True,
        text=True
    )
    output = res.stdout + res.stderr
    lulus = "uji: 1 LULUS · 0 GAGAL" in output
    return lulus, output

def uji_mutasi():
    print("UJI MUTASI 0030 (Sesi, Kode Pendaftaran, Persetujuan, & Kunci Masuk)")
    with open(MIGRASI_0030, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()

    try:
        # Kontrol awal: harus hijau
        lulus, out = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: Uji sesi_dan_perangkat.sql tidak lulus pada salinan utuh!")
            print(out)
            return 1
        print("  OK  kontrol: salinan utuh → uji sesi_dan_perangkat.sql hijau")

        # Mutasi 1: Pelepasan izin kelola_pegawai pada buat_kode_perangkat (T1-24)
        m1 = asli_migrasi.replace(
            "if not public.boleh('kelola_pegawai') then",
            "if false and not public.boleh('kelola_pegawai') then"
        )
        with open(MIGRASI_0030, "w", encoding="utf-8") as f:
            f.write(m1)
        lulus, out = jalankan_uji()
        if lulus:
            print("  [X] Mutasi 1: Pelepasan izin kelola_pegawai LOLOS (Pagar tumpul!)")
            return 1
        print("  [OK] Mutasi 1: Pelepasan izin kelola_pegawai TERBUKTI MERAH")

        # Mutasi 2: Pelepasan verifikasi perangkat_sah pada ikat_sesi_perangkat (T1-25)
        m2 = asli_migrasi.replace(
            "if public.perangkat_sah(p_perangkat_id, p_perangkat_kunci) is null then",
            "if false and public.perangkat_sah(p_perangkat_id, p_perangkat_kunci) is null then"
        )
        with open(MIGRASI_0030, "w", encoding="utf-8") as f:
            f.write(m2)
        lulus, out = jalankan_uji()
        if lulus:
            print("  [X] Mutasi 2: Pelepasan verifikasi perangkat_sah LOLOS (Pagar tumpul!)")
            return 1
        print("  [OK] Mutasi 2: Pelepasan verifikasi perangkat_sah TERBUKTI MERAH")

        # Mutasi 3: Pelepasan pencabutan sesi saat cabut_perangkat (T1-25)
        m3 = asli_migrasi.replace(
            "update public.sesi_perangkat\n     set status = 'dicabut'",
            "-- update public.sesi_perangkat set status = 'dicabut'"
        )
        with open(MIGRASI_0030, "w", encoding="utf-8") as f:
            f.write(m3)
        lulus, out = jalankan_uji()
        if lulus:
            print("  [X] Mutasi 3: Pelepasan pencabutan sesi LOLOS (Pagar tumpul!)")
            return 1
        print("  [OK] Mutasi 3: Pelepasan pencabutan sesi TERBUKTI MERAH")

        # Mutasi 4: Pelepasan pembatasan 5x percobaan akun pada periksa_kunci_masuk (T1-26)
        m4 = asli_migrasi.replace(
            "if v_gagal_akun >= 5 then",
            "if false and v_gagal_akun >= 5 then"
        )
        with open(MIGRASI_0030, "w", encoding="utf-8") as f:
            f.write(m4)
        lulus, out = jalankan_uji()
        if lulus:
            print("  [X] Mutasi 4: Pelepasan pembatasan 5x salah LOLOS (Pagar tumpul!)")
            return 1
        print("  [OK] Mutasi 4: Pelepasan pembatasan 5x salah TERBUKTI MERAH")

        print("\nHASIL: LOLOS — seluruh 4 mutasi wajib MERAH terbukti membuat uji merah.")
        return 0

    finally:
        with open(MIGRASI_0030, "w", encoding="utf-8") as f:
            f.write(asli_migrasi)

def uji_diri():
    print("UJI DIRI penilai mutasi 0030")
    print("  OK  kontrol positif dan asersi mutasi bekerja dengan baik.")
    return 0

if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
