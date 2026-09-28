#!/usr/bin/env python3
"""
UJI MUTASI 0061 — membuktikan ketajaman RPC verifikasi_pin_perangkat untuk staf
(N F-01 audit AUD-3 2026-09-24).

Mutasi yang WAJIB membuat `supabase/tes/verifikasi_pin_perangkat.sql` MERAH:
  1. Validasi format PIN tepat 6 angka dihilangkan (PIN 4 angka lolos)
  2. Pengecekan status aktif perangkat dihilangkan (perangkat non-aktif lolos)
  3. Pengecekan kecocokan PIN hash dihilangkan/dibypass (PIN salah lolos)

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0061.py
            python3 alat/uji-mutasi-0061.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0061_verifikasi_pin_perangkat.sql")
BERKAS_UJI = ["supabase/tes/verifikasi_pin_perangkat.sql"]


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
        "validasi format PIN 6 angka dihilangkan",
        "if p_pin !~ '^\\d{6}$' then",
        "if false and p_pin !~ '^\\d{6}$' then",
    ),
    (
        "pengecekan status aktif perangkat dihilangkan",
        "if v_perangkat.id is null or not coalesce(v_perangkat.aktif, false) then",
        "if false and (v_perangkat.id is null or not coalesce(v_perangkat.aktif, false)) then",
    ),
    (
        "pengecekan hash PIN di-bypass",
        "v_berhasil := v_hash is not null and crypt(p_pin, v_hash) = v_hash;",
        "v_berhasil := true;",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0061 (N F-01 audit 2026-09-24 — RPC verifikasi_pin_perangkat)")
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
            "pagar RPC verifikasi_pin_perangkat (N F-01) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0061")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()
    palsu = asli.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli:
        print("Uji diri gagal: penggantian tak terduga berhasil!")
        return 1
    print("  OK  uji-diri: mutasi sintetis tak menempel")
    print("UJI DIRI 0061 SELESAI — LOLOS")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uji-diri":
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
