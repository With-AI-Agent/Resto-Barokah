#!/usr/bin/env python3
"""
alat/uji-mutasi-0075.py — Uji Mutasi Fail-Closed untuk 0075_menu_cabang.sql (T9-06)

Memastikan setiap lapis proteksi pada migrasi 0075 terbukti gagal-tertutup (fail-closed):
jika proteksi sengaja dirusak (mutasi), rangkaian pengujian SQL HARUS mendeteksinya (keluar kode != 0).
"""

import os
import re
import subprocess
import sys

BERKAS_MIGRASI = "supabase/migrations/0075_menu_cabang.sql"

MUTASI = [
    (
        "M01: Hapus validasi harga menu cabang tidak boleh negatif",
        r"if p_harga is not null and p_harga < 0 then\s+raise exception 'Harga khusus cabang tidak boleh negatif\.';\s+end if;",
        "-- MUTASI M01 DILEPAS",
    ),
    (
        "M02: Hapus proteksi cabang milik resto yang sama pada simpan_menu_cabang",
        r"if not v_cabang_ada then\s+raise exception 'Cabang tidak ditemukan atau bukan milik resto Anda\.';\s+end if;",
        "-- MUTASI M02 DILEPAS",
    ),
    (
        "M03: Hapus proteksi menu milik resto yang sama pada simpan_menu_cabang",
        r"if not v_menu_ada then\s+raise exception 'Menu tidak ditemukan atau bukan milik resto Anda\.';\s+end if;",
        "-- MUTASI M03 DILEPAS",
    ),
    (
        "M04: Hapus pagar otorisasi peran kelola menu cabang pada simpan_menu_cabang",
        r"raise exception 'Hanya owner pusat, pemegang izin atur_pengaturan, atau admin cabang yang dapat mengatur menu cabang\.';",
        "-- MUTASI M04 DILEPAS",
    ),
    (
        "M05: Hapus pemeriksaan mc.aktif pada harga_berlaku",
        r"and coalesce\(mc\.aktif, true\)",
        "-- MUTASI M05 DILEPAS",
    ),
    (
        "M06: Hapus pencatatan audit trail pada simpan_menu_cabang",
        r"insert into public\.catatan_audit\s*\([^)]+\)\s*values\s*\([^;]+;",
        "-- MUTASI M06 DILEPAS",
    ),
    (
        "M07: Hapus penolakan salin cabang ke dirinya sendiri pada salin_harga_cabang",
        r"if p_cabang_asal_id = p_cabang_tujuan_id then\s+raise exception 'Cabang asal dan cabang tujuan tidak boleh sama\.';\s+end if;",
        "-- MUTASI M07 DILEPAS",
    ),
]

def main():
    print("=== PENGUJIAN MUTASI 0075_menu_cabang.sql (T9-06) ===")

    if not os.path.exists(BERKAS_MIGRASI):
        print(f"GALAT: Berkas {BERKAS_MIGRASI} tidak ditemukan.")
        sys.exit(1)

    with open(BERKAS_MIGRASI, "r", encoding="utf-8") as f:
        isi_asli = f.read()

    # 1. Jalankan baseline asli
    print("[1/2] Memeriksa baseline asli (harus LULUS / kode keluar 0)...")
    res_base = subprocess.run(["node", "alat/uji-sql.mjs"], capture_output=True, text=True)
    if res_base.returncode != 0:
        print("GALAT: Baseline asli gagal! Perbaiki kode sebelum menguji mutasi.")
        print(res_base.stdout)
        print(res_base.stderr)
        sys.exit(1)
    print("  -> Baseline BERSIH & LULUS.\n")

    # 2. Uji mutasi
    print(f"[2/2] Menguji {len(MUTASI)} mutasi fail-closed...")
    semua_lolos = True

    for i, (label, pola, pengganti) in enumerate(MUTASI, 1):
        if not re.search(pola, isi_asli):
            print(f"  ❌ PERINGATAN: Pola mutasi #{i} '{label}' tidak ditemukan dalam berkas migrasi!")
            semua_lolos = False
            continue

        isi_termutasi = re.sub(pola, pengganti, isi_asli, count=1)
        with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
            f.write(isi_termutasi)

        try:
            res_mutasi = subprocess.run(["node", "alat/uji-sql.mjs"], capture_output=True, text=True)
            if res_mutasi.returncode == 0:
                print(f"  ❌ LOLOS DINI (BAHAYA): Mutasi #{i} '{label}' TIDAK tertangkap! Uji tetap hijau saat kode dirusak.")
                semua_lolos = False
            else:
                print(f"  ✅ TERTANGKAP: Mutasi #{i} '{label}' terdeteksi merah.")
        finally:
            with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
                f.write(isi_asli)

    if not semua_lolos:
        print("\nHASIL: Ada mutasi yang tidak tertangkap. Perketat berkas uji SQL!")
        sys.exit(1)

    print("\nHASIL: 100% mutasi tertangkap (fail-closed terbukti kuat).")

if __name__ == "__main__":
    main()
