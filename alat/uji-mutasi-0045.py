#!/usr/bin/env python3
"""
UJI MUTASI 0045 — membuktikan ketajaman pagar T7-01 di `0045_buka_shift.sql`:
"buka kasir menuntut modal awal, satu shift terbuka per kasir per cabang,
identitas & waktu tercatat, dan baris terkunci dari modifikasi langsung".

Mutasi yang wajib membuat `supabase/tes/buka_shift.sql` MERAH:
  1. Validasi modal_awal null dicabut
  2. Validasi modal_awal negatif dicabut
  3. Pagar peran kasir/admin dicabut (sehingga pelayan/dapur lolos)
  4. Pagar satu shift terbuka dicabut (sehingga kasir bisa buka shift dobel)
  5. Pemicu larangan DELETE dicabut (sehingga baris shift bisa dihapus)
  6. Pemicu larangan ubah modal_awal langsung dicabut

Verifikasi: python3 alat/uji-mutasi-0045.py
            python3 alat/uji-mutasi-0045.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0045_buka_shift.sql")
BERKAS_UJI = ["supabase/tes/buka_shift.sql"]


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", *BERKAS_UJI],
        cwd=REPO,
        capture_output=True,
        text=True,
    )
    keluaran = res.stdout + res.stderr
    return f"uji: {len(BERKAS_UJI)} LULUS · 0 GAGAL" in keluaran, keluaran


DAFTAR_MUTASI = [
    (
        "validasi modal_awal null dicabut",
        "  if p_modal_awal is null then",
        "  if false and p_modal_awal is null then",
    ),
    (
        "validasi modal_awal negatif dicabut",
        "  if p_modal_awal < 0 then",
        "  if false and p_modal_awal < 0 then",
    ),
    (
        "pagar peran dicabut (pelayan & dapur diizinkan)",
        "  if public.peran_saya() not in ('owner_pusat', 'admin_cabang', 'kasir') then",
        "  if false then",
    ),
    (
        "pagar satu shift terbuka dicabut (bisa buka shift dobel)",
        "  if v_shift_aktif_id is not null then",
        "  if false and v_shift_aktif_id is not null then",
    ),
    (
        "pemicu larangan DELETE dicabut",
        "  if TG_OP = 'DELETE' then",
        "  if false and TG_OP = 'DELETE' then",
    ),
    (
        "pemicu larangan ubah modal_awal langsung dicabut",
        "    if NEW.modal_awal <> OLD.modal_awal then",
        "    if false and NEW.modal_awal <> OLD.modal_awal then",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0045 (T7-01 — integritas buka shift kasir)")
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
            "pagar integritas buka shift (T7-01) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0045")
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
