#!/usr/bin/env python3
"""
UJI MUTASI 0047 — membuktikan ketajaman pagar T7-03 di `0047_kas_pergerakan.sql`:
"mencatat kas keluar/masuk/setoran dengan alasan wajib, izin kasir/admin,
kekal tidak bisa di-update/delete, dan masuk ke uang seharusnya saat tutup kas".

Mutasi yang wajib membuat `supabase/tes/kas_pergerakan.sql` MERAH:
  1. Validasi jumlah <= 0 dicabut
  2. Validasi alasan wajib dicabut
  3. Pemicu kekal (anti update/delete) dinonaktifkan
  4. Pagar shift tertutup dicabut (kas masuk/keluar di shift tertutup diizinkan)
  5. Pagar izin pergerakan kas dicabut (pelayan diizinkan)
  6. Integrasi dengan tutup_shift dirusak (kas keluar tidak mengurangi uang)

Verifikasi: python3 alat/uji-mutasi-0047.py
            python3 alat/uji-mutasi-0047.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0047_kas_pergerakan.sql")
BERKAS_UJI = ["supabase/tes/kas_pergerakan.sql"]


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
        "validasi jumlah <= 0 dicabut",
        "  if p_jumlah is null or p_jumlah <= 0 then",
        "  if false and p_jumlah <= 0 then",
    ),
    (
        "validasi alasan wajib dicabut",
        "  if p_alasan is null or btrim(p_alasan) = '' then",
        "  if false then",
    ),
    (
        "pemicu kekal anti-update/delete dinonaktifkan",
        "  raise exception 'Pergerakan kas adalah jejak keuangan kekal; tidak dapat diubah atau dihapus.';",
        "  return null;",
    ),
    (
        "pagar shift tertutup dicabut",
        "  if v_shift.status <> 'terbuka' and p_jenis <> 'koreksi' then",
        "  if false then",
    ),
    (
        "pagar izin pergerakan kas dicabut (pelayan diizinkan)",
        "  if not public.boleh('tutup_kas', v_shift.cabang_id) then",
        "  if false then",
    ),
    (
        "integrasi kas keluar di tutup_shift dirusak (pengeluaran tidak mengurangi uang)",
        "  v_tunai_keluar := v_kas_keluar;",
        "  v_tunai_keluar := 0;",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0047 (T7-03 — kas pergerakan masuk/keluar & setoran)")
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
            "pagar pergerakan kas (T7-03) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0047")
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
