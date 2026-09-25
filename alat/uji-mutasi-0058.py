#!/usr/bin/env python3
"""
UJI MUTASI 0058 — membuktikan ketajaman pagar keaktifan sesi, umur maksimum,
dan pencabutan perangkat (N F-03 audit AUD-3 2026-09-24).

Mutasi yang WAJIB membuat `supabase/tes/sesi_kedaluwarsa.sql` MERAH:
  1. sesi_masih_aktif selalu mengembalikan true (pagar dilewati)
  2. Pemeriksaan berakhir_pada > now() dihilangkan (umur sesi tidak ditegakkan)
  3. Pemeriksaan p.aktif = true dihilangkan (perangkat dicabut tetap dilayani)
  4. Panggilan sesi_masih_aktif() pada penyewa_saya() dicabut

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0058.py
            python3 alat/uji-mutasi-0058.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0058_sesi_masih_aktif.sql")
BERKAS_UJI = ["supabase/tes/sesi_kedaluwarsa.sql"]


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
        "sesi_masih_aktif selalu true",
        "v_uid := auth.uid();",
        "return true; -- MUTASI: selalu true\n  v_uid := auth.uid();",
    ),
    (
        "pemeriksaan umur sesi (berakhir_pada > now()) dihilangkan",
        "and sp.berakhir_pada > now()",
        "-- MUTASI: umur sesi diabaikan\n         -- and sp.berakhir_pada > now()",
    ),
    (
        "pemeriksaan status perangkat aktif dihilangkan",
        "and p.aktif = true",
        "-- MUTASI: status perangkat diabaikan\n         -- and p.aktif = true",
    ),
    (
        "sesi_masih_aktif pada penyewa_saya dicabut",
        "and public.sesi_masih_aktif()",
        "-- MUTASI: tidak memeriksa sesi_masih_aktif\n     -- and public.sesi_masih_aktif()",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0058 (N F-03 audit 2026-09-24 — keaktifan sesi & pencabutan perangkat)")
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
            "pagar keaktifan sesi & pencabutan perangkat (N F-03) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0058")
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
