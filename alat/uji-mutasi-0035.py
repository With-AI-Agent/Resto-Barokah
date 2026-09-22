#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar migrasi 0035 (T4-05, Menu Habis):
  1. Jejak pelaku pada riwayat dihapus (siapa menandai hilang)
  2. Pintu tandai_habis tanpa pemeriksaan izin (kasir bisa menandai/mencabut)
  3. Penjaga hanya-tambah riwayat dilepas (riwayat bisa ditulis ulang)

Setiap mutasi WAJIB membuat berkas uji 'menu_habis_sumber.sql' MERAH.

Verifikasi: python3 alat/uji-mutasi-0035.py            (3/3 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0035.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0035_menu_habis_sumber.sql")


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/menu_habis_sumber.sql"],
        cwd=REPO,
        capture_output=True,
        text=True
    )
    output = res.stdout + res.stderr
    lulus = "uji: 1 LULUS · 0 GAGAL" in output
    return lulus, output


def uji_mutasi():
    print("UJI MUTASI 0035 (Menu Habis — sumber kebenaran + jejak hanya-tambah)")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()

    daftar_mutasi = [
        ("Jejak pelaku pada riwayat dihapus",
         "values (v_penyewa, new.menu_item_id, new.cabang_id, new.habis, auth.uid());",
         "values (v_penyewa, new.menu_item_id, new.cabang_id, new.habis, null);   -- mutasi: siapa hilang"),
        ("Pintu tandai_habis tanpa pemeriksaan izin",
         "  if not public.boleh('ubah_stok') then\n"
         "    raise exception 'Anda tidak berizin mengubah stok.';\n"
         "  end if;",
         "  -- mutasi: siapa pun boleh menandai/mencabut;"),
        ("Penjaga hanya-tambah riwayat dilepas",
         "  raise exception 'Riwayat penanda habis hanya-tambah — tidak boleh diubah atau dihapus.';",
         "  return old;   -- mutasi: riwayat boleh ditulis ulang"),
    ]

    try:
        lulus, out = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: Uji menu_habis_sumber.sql tidak lulus pada salinan utuh!")
            print(out)
            return 1
        print("  OK  kontrol: salinan utuh → uji menu_habis_sumber.sql hijau")

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
    print("UJI DIRI penilai mutasi 0035")
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
