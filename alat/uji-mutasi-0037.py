#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar migrasi 0037 (T4-07, opname_stok):
  1. Selisih dihitung terhadap nol (bukan saldo sistem) — selisih palsu
  2. Jejak opname ditulis sebagai 'koreksi' (jejak opname hilang)
  3. Penjaga jumlah fisik negatif dilepas

Setiap mutasi WAJIB membuat berkas uji 'opname_stok.sql' MERAH.

Verifikasi: python3 alat/uji-mutasi-0037.py            (3/3 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0037.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0037_opname.sql")


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/opname_stok.sql"],
        cwd=REPO,
        capture_output=True,
        text=True
    )
    output = res.stdout + res.stderr
    lulus = "uji: 1 LULUS · 0 GAGAL" in output
    return lulus, output


def uji_mutasi():
    print("UJI MUTASI 0037 (opname_stok — selisih terbuka, jejak kekal)")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()

    daftar_mutasi = [
        ("Selisih dihitung terhadap nol (bukan saldo sistem)",
         "  v_selisih := p_jumlah_fisik - v_bahan.jumlah;",
         "  v_selisih := p_jumlah_fisik;   -- mutasi: selisih palsu"),
        ("Jejak opname ditulis sebagai koreksi",
         "  v_saldo := public.catat_stok(p_stok_bahan_id, 'opname', v_selisih, p_alasan);",
         "  v_saldo := public.catat_stok(p_stok_bahan_id, 'koreksi', v_selisih, p_alasan);   -- mutasi"),
        ("Penjaga jumlah fisik negatif dilepas",
         "  if p_jumlah_fisik is null or p_jumlah_fisik < 0 then",
         "  if p_jumlah_fisik is null then   -- mutasi: negatif dianggap sah"),
    ]

    try:
        lulus, out = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: Uji opname_stok.sql tidak lulus pada salinan utuh!")
            print(out)
            return 1
        print("  OK  kontrol: salinan utuh → uji opname_stok.sql hijau")

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
    print("UJI DIRI penilai mutasi 0037")
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
