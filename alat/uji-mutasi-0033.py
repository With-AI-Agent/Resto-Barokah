#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar migrasi 0033 (T4-02, Tujuan Item Dapur/Bar):
  1. Penulisan salinan tujuan dari kategori dihapus (spoof perangkat dibiarkan)
  2. Pembekuan salinan dihapus (tujuan item bisa ditulis ulang)

Setiap mutasi WAJIB membuat berkas uji 'tujuan_item.sql' MERAH.
(Catatan jujur: penolakan menu hantu TIDAK dimutasi di sini — pintu itu milik penjaga
menu 0012 dengan pesan kanoniknya sendiri, dan sudah beruji di supabase/tes/pesanan.sql.)

Verifikasi: python3 alat/uji-mutasi-0033.py            (2/2 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0033.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI_0033 = os.path.join(REPO, "supabase", "migrations", "0033_tujuan_item.sql")


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/tujuan_item.sql"],
        cwd=REPO,
        capture_output=True,
        text=True
    )
    output = res.stdout + res.stderr
    lulus = "uji: 1 LULUS · 0 GAGAL" in output
    return lulus, output


def uji_mutasi():
    print("UJI MUTASI 0033 (Tujuan Item Dapur/Bar — salinan kekal)")
    with open(MIGRASI_0033, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()

    daftar_mutasi = [
        ("Penulisan salinan tujuan dari kategori dihapus",
         "    new.tujuan := coalesce(v_tujuan, 'dapur');",
         "    new.tujuan := coalesce(new.tujuan, 'dapur');   -- mutasi: spoof perangkat dibiarkan"),
        ("Pembekuan salinan tujuan dihapus",
         "  if new.tujuan is distinct from old.tujuan then\n"
         "    raise exception 'Tujuan item adalah salinan dari kategori saat pesanan dibuat — tidak boleh diubah (% → %).', old.tujuan, new.tujuan;\n"
         "  end if;",
         "  -- mutasi: salinan boleh ditulis ulang;"),
    ]

    try:
        lulus, out = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: Uji tujuan_item.sql tidak lulus pada salinan utuh!")
            print(out)
            return 1
        print("  OK  kontrol: salinan utuh → uji tujuan_item.sql hijau")

        for i, (nama, asal, ganti) in enumerate(daftar_mutasi, start=1):
            hasil = asli_migrasi.replace(asal, ganti)
            if hasil == asli_migrasi:
                print(f"  [X] Mutasi {i}: teks mutasi TIDAK MENEMPEL pada berkas — periksa jangkar!")
                return 1
            with open(MIGRASI_0033, "w", encoding="utf-8") as f:
                f.write(hasil)
            lulus, out = jalankan_uji()
            if lulus:
                print(f"  [X] Mutasi {i}: {nama} LOLOS (Pagar tumpul!)")
                return 1
            print(f"  [OK] Mutasi {i}: {nama} TERBUKTI MERAH")

        print(f"\nHASIL: LOLOS — seluruh {len(daftar_mutasi)} mutasi wajib MERAH terbukti membuat uji merah.")
        return 0

    finally:
        with open(MIGRASI_0033, "w", encoding="utf-8") as f:
            f.write(asli_migrasi)


def uji_diri():
    print("UJI DIRI penilai mutasi 0033")
    with open(MIGRASI_0033, "r", encoding="utf-8") as f:
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
