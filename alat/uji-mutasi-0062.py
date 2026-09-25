#!/usr/bin/env python3
"""
UJI MUTASI 0062 — membuktikan ketajaman RPC katalog_publik (T8-01 / ART-10, ART-1).

Mutasi yang WAJIB membuat `supabase/tes/katalog_publik.sql` MERAH:
  1. Pengecekan status aktif resto dihilangkan (resto nonaktif lolos)
  2. Penanda habis per cabang dihilangkan (menu habis tampil tersedia)
  3. Harga khusus cabang diabaikan (selalu memakai harga pusat)

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0062.py
            python3 alat/uji-mutasi-0062.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0062_katalog_publik.sql")
BERKAS_UJI = ["supabase/tes/katalog_publik.sql"]


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
        "pengecekan status aktif resto dihilangkan",
        "and p.status = 'aktif';",
        "and (true or p.status = 'aktif');",
    ),
    (
        "penanda habis per cabang diabaikan",
        "when v_cabang_id is not null then coalesce(mc.habis, false)",
        "when v_cabang_id is not null then false",
    ),
    (
        "harga khusus cabang diabaikan (selalu harga pusat)",
        "when v_cabang_id is not null and mc.harga is not null then mc.harga",
        "when v_cabang_id is not null and mc.harga is not null then m.harga",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0062 (T8-01 — RPC katalog_publik)")
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
            "pagar RPC katalog_publik (T8-01) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0062")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()
    palsu = asli.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli:
        print("Uji diri gagal: penggantian tak terduga berhasil!")
        return 1
    print("  OK  uji-diri: mutasi sintetis tak menempel")
    print("UJI DIRI 0062 SELESAI — LOLOS")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uji-diri":
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
