#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar migrasi 0036 (T4-06, set_stok):
  1. Penjagaan alasan whitespace dilepas ('   ' dianggap alasan sah)
  2. Isolasi penyewa pada pencarian bahan dilepas (bahan resto lain bisa disentuh)
  3. Pemetaan jenis pergerakan dibalik (masuk ↔ keluar)

Setiap mutasi WAJIB membuat berkas uji 'set_stok.sql' MERAH.
(Catatan jujur: penjaga perubahan nol TIDAK dimutasi di sini — nol sudah
ditolak berlapis di pintu bawah catat_stok/pemicu buku besar, sehingga
melepas lapisan atas tidak mengubah perilaku; lapisan ganda disengaja.)

Verifikasi: python3 alat/uji-mutasi-0036.py            (3/3 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0036.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0036_stok.sql")


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/set_stok.sql"],
        cwd=REPO,
        capture_output=True,
        text=True
    )
    output = res.stdout + res.stderr
    lulus = "uji: 1 LULUS · 0 GAGAL" in output
    return lulus, output


def uji_mutasi():
    print("UJI MUTASI 0036 (set_stok — delta jujur berizin)")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()

    daftar_mutasi = [
        ("Penjagaan alasan whitespace dilepas",
         "  if p_alasan is null or length(btrim(p_alasan)) = 0 then",
         "  if p_alasan is null then   -- mutasi: alasan spasi dianggap sah"),
        ("Isolasi penyewa pada pencarian bahan dilepas",
         "     and b.penyewa_id = public.penyewa_saya();",
         "     ;   -- mutasi: bahan resto lain ikut terlihat"),
        ("Pemetaan jenis pergerakan dibalik",
         "  v_jenis := case when p_jumlah > 0 then 'masuk' else 'keluar' end;",
         "  v_jenis := case when p_jumlah > 0 then 'keluar' else 'masuk' end;   -- mutasi"),
    ]

    try:
        lulus, out = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: Uji set_stok.sql tidak lulus pada salinan utuh!")
            print(out)
            return 1
        print("  OK  kontrol: salinan utuh → uji set_stok.sql hijau")

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
    print("UJI DIRI penilai mutasi 0036")
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
