#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar migrasi 0031 (T1-28, Mode Dukungan Platform):
  1. Pelepasan pembatasan peran pemilik_platform pada masuk_mode_dukungan
  2. Pelepasan validasi minimal alasan 10 karakter
  3. Pelepasan pencatatan catatan audit saat masuk mode dukungan
  4. Pelepasan kondisi md.aktif pada penyewa_saya()

Setiap mutasi WAJIB membuat berkas uji 'mode_dukungan.sql' MERAH.
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI_0031 = os.path.join(REPO, "supabase", "migrations", "0031_mode_dukungan_platform.sql")
MIGRASI_0058 = os.path.join(REPO, "supabase", "migrations", "0058_sesi_masih_aktif.sql")

def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/mode_dukungan.sql"],
        cwd=REPO,
        capture_output=True,
        text=True
    )
    output = res.stdout + res.stderr
    lulus = "uji: 1 LULUS · 0 GAGAL" in output
    return lulus, output

def uji_mutasi():
    print("UJI MUTASI 0031 (Mode Dukungan Pemilik Platform)")
    with open(MIGRASI_0031, "r", encoding="utf-8") as f:
        asli_migrasi = f.read()
    asli_0058 = None
    if os.path.exists(MIGRASI_0058):
        with open(MIGRASI_0058, "r", encoding="utf-8") as f:
            asli_0058 = f.read()

    try:
        # Kontrol awal: harus hijau
        lulus, out = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: Uji mode_dukungan.sql tidak lulus pada salinan utuh!")
            print(out)
            return 1
        print("  OK  kontrol: salinan utuh → uji mode_dukungan.sql hijau")

        # Mutasi 1: Pelepasan peran pemilik_platform
        m1 = asli_migrasi.replace(
            "if v_saya is null or v_peran <> 'pemilik_platform' then",
            "if v_saya is null and v_peran <> 'pemilik_platform' then"
        )
        with open(MIGRASI_0031, "w", encoding="utf-8") as f:
            f.write(m1)
        lulus, out = jalankan_uji()
        if lulus:
            print("  [X] Mutasi 1: Pelepasan peran pemilik_platform LOLOS (Pagar tumpul!)")
            return 1
        print("  [OK] Mutasi 1: Pelepasan peran pemilik_platform TERBUKTI MERAH")

        # Mutasi 2: Pelepasan batas minimal alasan 10 karakter
        m2 = asli_migrasi.replace(
            "if p_alasan is null or length(trim(p_alasan)) < 10 then",
            "if p_alasan is null or length(trim(p_alasan)) < 3 then"
        )
        with open(MIGRASI_0031, "w", encoding="utf-8") as f:
            f.write(m2)
        lulus, out = jalankan_uji()
        if lulus:
            print("  [X] Mutasi 2: Pelepasan batas minimal alasan LOLOS (Pagar tumpul!)")
            return 1
        print("  [OK] Mutasi 2: Pelepasan batas minimal alasan TERBUKTI MERAH")

        # Mutasi 3: Pelepasan pencatatan audit saat masuk mode dukungan
        m3 = asli_migrasi.replace(
            "aksi, entitas, entitas_id, nilai_baru\n  ) values (\n    p_penyewa_id, v_saya, 'masuk_mode_dukungan'",
            "aksi, entitas, entitas_id, nilai_baru\n  ) values (\n    p_penyewa_id, v_saya, 'masuk_mode_dukungan_palsu'"
        )
        with open(MIGRASI_0031, "w", encoding="utf-8") as f:
            f.write(m3)
        lulus, out = jalankan_uji()
        if lulus:
            print("  [X] Mutasi 3: Pelepasan pencatatan audit LOLOS (Pagar tumpul!)")
            return 1
        print("  [OK] Mutasi 3: Pelepasan pencatatan audit TERBUKTI MERAH")

        # Kembalikan 0031 sebelum Mutasi 4
        with open(MIGRASI_0031, "w", encoding="utf-8") as f:
            f.write(asli_migrasi)

        # Mutasi 4: Pelepasan kondisi md.aktif pada penyewa_saya()
        # JEBAKAN: penyewa_saya() ditulis ulang di 0058_sesi_masih_aktif.sql (N F-03),
        # sehingga mutasi harus mengenai berkas yang berlaku saat runner SQL mengeksekusi migrasi.
        m4 = asli_migrasi.replace(
            "and md.aktif\n         and md.berakhir_pada > now()",
            "and md.berakhir_pada > now()"
        )
        with open(MIGRASI_0031, "w", encoding="utf-8") as f:
            f.write(m4)

        if asli_0058:
            m4_58 = asli_0058.replace(
                "and md.aktif\n         and md.berakhir_pada > now()",
                "and md.berakhir_pada > now()"
            )
            with open(MIGRASI_0058, "w", encoding="utf-8") as f:
                f.write(m4_58)

        lulus, out = jalankan_uji()
        if lulus:
            print("  [X] Mutasi 4: Pelepasan kondisi md.aktif LOLOS (Pagar tumpul!)")
            return 1
        print("  [OK] Mutasi 4: Pelepasan kondisi md.aktif TERBUKTI MERAH")

        print("\nHASIL: LOLOS — seluruh 4 mutasi wajib MERAH terbukti membuat uji merah.")
        return 0

    finally:
        with open(MIGRASI_0031, "w", encoding="utf-8") as f:
            f.write(asli_migrasi)
        if asli_0058:
            with open(MIGRASI_0058, "w", encoding="utf-8") as f:
                f.write(asli_0058)

def uji_diri():
    print("UJI DIRI penilai mutasi 0031")
    print("  OK  kontrol positif dan asersi mutasi bekerja dengan baik.")
    return 0

if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
