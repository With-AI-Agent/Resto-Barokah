#!/usr/bin/env python3
"""
UJI MUTASI 0063 — membuktikan ketajaman saringan anti-email palsu & normalisasi Gmail (T8-07 / ART-5, ART-10).

Mutasi yang WAJIB membuat `supabase/tes/anti_email_palsu.sql` MERAH:
  1. Normalisasi titik Gmail dicabut (titik tidak dihapus).
  2. Saringan email sekali-pakai dilonggarkan (selalu return false).
  3. Validasi persetujuan privasi UU PDP dicabut (bisa klaim tanpa persetujuan).
  4. Pagar 1 voucher per kampanye per identitas dicabut (klaim kedua diloloskan).

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0063.py
            python3 alat/uji-mutasi-0063.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0063_anti_email_palsu.sql")
BERKAS_UJI = ["supabase/tes/anti_email_palsu.sql"]


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
        "normalisasi titik Gmail dicabut",
        "v_lokal := replace(v_lokal, '.', '');",
        "-- v_lokal := replace(v_lokal, '.', '');",
    ),
    (
        "saringan email sekali-pakai dilonggarkan",
        "return v_domain in (",
        "return false and v_domain in (",
    ),
    (
        "validasi persetujuan privasi UU PDP dicabut pada RPC",
        "if coalesce(p_persetujuan_privasi, false) is not true then",
        "if false and coalesce(p_persetujuan_privasi, false) is not true then",
    ),
    (
        "pagar satu voucher per identitas per kampanye dicabut pada RPC",
        "if v_ada.kode is not null then",
        "if false and v_ada.kode is not null then",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0063 (T8-07 — Anti Email Palsu & Normalisasi Gmail)")
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
            "pagar anti email palsu (T8-07) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0063")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()
    palsu = asli.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli:
        print("Uji diri gagal: penggantian tak terduga berhasil!")
        return 1
    print("  OK  uji-diri: mutasi sintetis tak menempel")
    print("UJI DIRI 0063 SELESAI — LOLOS")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uji-diri":
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
