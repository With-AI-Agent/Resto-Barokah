#!/usr/bin/env python3
"""
UJI MUTASI 0056 — membuktikan ketajaman pagar `public.cabang_aktif_saya()`
(N F-04 audit AUD-3 2026-09-24): helper deterministik per sesi, dan
berhenti mengembalikan cabang saat tidak ada akses.

Mutasi yang WAJIB membuat `supabase/tes/cabang_aktif_saya.sql` MERAH:
  1. Body diganti `select null::uuid` — pagar lenyap.
  2. Order by dibalik (desc) — cabang akhir jadi "aktif".

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0056.py
            python3 alat/uji-mutasi-0056.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0056_cabang_aktif_saya.sql")
BERKAS_UJI = ["supabase/tes/cabang_aktif_saya.sql"]


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", *BERKAS_UJI],
        cwd=REPO,
        capture_output=True,
        text=True,
    )
    keluaran = res.stdout + res.stderr
    return (
        f"uji: {len(BERKAS_UJI)} LULUS · 0 GAGAL" in keluaran,
        keluaran,
    )


DAFTAR_MUTASI = [
    (
        "body diganti null::uuid — pagar lenyap",
        "  select c.id\n    from public.cabang c",
        "  select null::uuid -- MUTASI: pagar dilepas",
    ),
    (
        "order by dibalik desc — cabang akhir jadi aktif",
        "order by c.dibuat_pada asc, c.id asc",
        "order by c.dibuat_pada desc, c.id desc",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0056 (N F-04 audit 2026-09-24 — pagar cabang_aktif_saya)")
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
            hasil = asli.replace(asal, ganti)
            if hasil == asli:
                print(f"  [X] Mutasi {nomor}: teks mutasi TIDAK MENEMPEL pada berkas — periksa jangkar!")
                return 1
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
            "pagar cabang_aktif_saya (N F-04) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0056")
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
