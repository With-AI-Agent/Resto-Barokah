#!/usr/bin/env python3
"""
UJI MUTASI 0046 — membuktikan ketajaman pagar T7-02 di `0046_tutup_shift.sql`:
"tutup kasir membandingkan uang seharusnya vs fisik, selisih wajib beralasan,
izin tutup_kas ditegakkan, dan shift ditutup tidak dapat ditutup ulang".

Mutasi yang wajib membuat `supabase/tes/tutup_shift.sql` MERAH:
  1. Validasi alasan selisih dicabut (selisih tanpa alasan diizinkan)
  2. Validasi uang fisik negatif dicabut
  3. Pagar izin tutup_kas dicabut (pelayan/dapur diizinkan)
  4. Pagar shift sudah ditutup dicabut (shift bisa ditutup ulang)
  5. Rumus uang seharusnya dirusak (modal awal dihilangkan dari hitungan)
  6. Pengecekan ketersediaan shift terbuka dicabut

Verifikasi: python3 alat/uji-mutasi-0046.py
            python3 alat/uji-mutasi-0046.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0046_tutup_shift.sql")
BERKAS_UJI = ["supabase/tes/tutup_shift.sql"]


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
        "validasi alasan selisih dicabut",
        "  if v_selisih <> 0 and v_alasan = '' then",
        "  if false and v_selisih <> 0 and v_alasan = '' then",
    ),
    (
        "validasi uang fisik negatif dicabut",
        "  if p_uang_fisik is null or p_uang_fisik < 0 then",
        "  if false then",
    ),
    (
        "pagar izin tutup_kas dicabut (pelayan & dapur diizinkan)",
        "  if not public.boleh('tutup_kas', v_shift.cabang_id) then",
        "  if false then",
    ),
    (
        "pagar shift sudah ditutup dicabut",
        "    if v_shift.status <> 'terbuka' then",
        "    if false and v_shift.status <> 'terbuka' then",
    ),
    (
        "rumus uang seharusnya dirusak (modal awal dihilangkan)",
        "  v_uang_seharusnya := v_shift.modal_awal + v_tunai_masuk - v_tunai_keluar;",
        "  v_uang_seharusnya := v_tunai_masuk - v_tunai_keluar;",
    ),
    (
        "pengecekan ketersediaan shift terbuka dicabut",
        "    if v_shift.id is null then\n      raise exception 'Tidak ada shift kas terbuka yang dapat ditutup.';",
        "    if false and v_shift.id is null then\n      raise exception 'Tidak ada shift kas terbuka yang dapat ditutup.';",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0046 (T7-02 — rekonsiliasi tutup shift kasir)")
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
            "pagar rekonsiliasi tutup shift (T7-02) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0046")
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
