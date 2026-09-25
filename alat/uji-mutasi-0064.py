#!/usr/bin/env python3
"""
UJI MUTASI 0064 — membuktikan ketajaman penerbitan kode voucher acak, validator, barcode, dan detail kartu (T8-08).

Mutasi yang WAJIB membuat `supabase/tes/voucher_terbit.sql` MERAH:
  1. Karakter ambigu diselipkan kembali ke himpunan karakter (memasukkan '0' dan '1').
  2. Validator format kode dilonggarkan sehingga kode kosong diloloskan.
  3. Generator kode acak diganti nilai konstan (memicu tabrakan keunikan 100 kode).
  4. Evaluasi otomatis status kedaluwarsa dicabut pada RPC ambil_kartu_voucher.
  5. Pengecekan kode kosong dicabut pada RPC ambil_kartu_voucher.

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0064.py
            python3 alat/uji-mutasi-0064.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0064_terbit_voucher_acak.sql")
BERKAS_UJI = ["supabase/tes/voucher_terbit.sql"]


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
        "karakter ambigu diselipkan ke pembuat kode acak",
        "v_chars text := '23456789ABCDEFGHJKMNPQRSTUVWXYZ';",
        "v_chars text := '0123456789ABCDEFGHJKMNPQRSTUVWXYZ';",
    ),
    (
        "validator format kode dilonggarkan untuk string kosong",
        "if p_kode is null or trim(p_kode) = '' then\n    return false;",
        "if p_kode is null or trim(p_kode) = '' then\n    return true;",
    ),
    (
        "generator kode acak menghasilkan nilai konstan deterministik",
        "return 'RB-' || v_part1 || '-' || v_part2;",
        "return 'RB-2345-6789';",
    ),
    (
        "evaluasi otomatis status kedaluwarsa dicabut",
        "if v_voucher.status = 'aktif' and v_sekarang > v_berlaku_sampai then",
        "if false and v_voucher.status = 'aktif' and v_sekarang > v_berlaku_sampai then",
    ),
    (
        "penolakan kode kosong dicabut pada ambil_kartu_voucher",
        "if v_kode = '' then",
        "if false and v_kode = '' then",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0064 (T8-08 — Terbitkan Kode Voucher Acak + Barcode)")
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
            "pagar kode voucher acak dan kartu voucher (T8-08) terbukti tajam."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0064")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()
    palsu = asli.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli:
        print("Uji diri gagal: penggantian tak terduga berhasil!")
        return 1
    print("  OK  uji-diri: mutasi sintetis tak menempel")
    print("UJI DIRI 0064 SELESAI — LOLOS")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uji-diri":
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
