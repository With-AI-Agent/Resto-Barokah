#!/usr/bin/env python3
"""
alat/uji-mutasi-0070.py — Penguji Mutasi Fail-Closed untuk 0070_identitas_resto.sql (T9-01).

Memastikan seluruh penjaga keamanan, optimistic concurrency locking, jejak audit,
dan penyajian identitas ke katalog publik benar-benar teruji dan tidak bisa dilemahkan diam-diam.
"""

import os
import re
import subprocess
import sys
import tempfile
from pathlib import Path

BERKAS_MIGRASI = Path("supabase/migrations/0070_identitas_resto.sql")
BERKAS_TES = "supabase/tes/pengaturan_identitas.sql"

MUTASI = [
    (
        "M01: Hapus pagar otorisasi peran (owner_pusat / atur_pengaturan)",
        r"if v_peran <> 'owner_pusat' and not public\.boleh\('atur_pengaturan'\) then\s+raise exception [^;]+;\s+end if;",
        "-- [MUTASI M01 DILEMAHKAN: Tanpa cek izin atur_pengaturan]",
    ),
    (
        "M02: Hapus penjaga kunci konkurensi optimistik (p_versi_lama)",
        r"if v_pengaturan\.versi_pengaturan <> p_versi_lama then\s+raise exception [^;]+;\s+end if;",
        "-- [MUTASI M02 DILEMAHKAN: Tanpa optimistic locking]",
    ),
    (
        "M03: Hapus pembaruan nama resto di tabel penyewa",
        r"update public\.penyewa\s+set nama = v_nama_bersih\s+where id = v_penyewa_id;",
        "-- [MUTASI M03 DILEMAHKAN: Tidak simpan nama ke penyewa]",
    ),
    (
        "M04: Hapus pembaruan tagline dan logo di tabel pengaturan",
        r"tagline\s*=\s*coalesce\(p_tagline,\s*tagline\),",
        "tagline = tagline, -- [MUTASI M04 DILEMAHKAN]",
    ),
    (
        "M05: Hapus pencatatan audit trail (catatan_audit)",
        r"insert into public\.catatan_audit[^;]+;",
        "-- [MUTASI M05 DILEMAHKAN: Tanpa audit trail]",
    ),
    (
        "M06: Hapus validasi nama resto kosong",
        r"if length\(v_nama_bersih\) < 1 or length\(v_nama_bersih\) > 120 then\s+raise exception [^;]+;\s+end if;",
        "-- [MUTASI M06 DILEMAHKAN: Tanpa validasi panjang nama resto]",
    ),
    (
        "M07: Hapus tagline dari kembalian katalog_publik",
        r"'tagline',\s*v_penyewa\.tagline,",
        "'tagline', '', -- [MUTASI M07 DILEMAHKAN]",
    ),
]


def jalankan_tes(env_tambahan=None) -> tuple[int, str]:
    env = os.environ.copy()
    if env_tambahan:
        env.update(env_tambahan)
    p = subprocess.run(
        ["node", "alat/uji-sql.mjs", BERKAS_TES],
        capture_output=True,
        text=True,
        env=env,
    )
    return p.returncode, p.stdout + "\n" + p.stderr


def main():
    print("=== PENGUJIAN MUTASI 0070_identitas_resto.sql (T9-01) ===")
    if not BERKAS_MIGRASI.exists():
        print(f"GALAT: {BERKAS_MIGRASI} tidak ditemukan.")
        sys.exit(1)

    isi_asli = BERKAS_MIGRASI.read_text(encoding="utf-8")

    # 1. Pastikan baseline hijau
    print("[1/2] Memeriksa baseline asli (harus LULUS / kode keluar 0)...")
    kode_base, log_base = jalankan_tes()
    if kode_base != 0:
        print("GALAT: Baseline gagal sebelum mutasi!")
        print(log_base)
        sys.exit(1)
    print("  -> Baseline BERSIH & LULUS.\n")

    # 2. Uji mutasi
    print(f"[2/2] Menguji {len(MUTASI)} mutasi fail-closed...")
    semua_lolos = True

    for i, (label, pola, pengganti) in enumerate(MUTASI, 1):
        if not re.search(pola, isi_asli):
            print(f"  [!] Pola mutasi #{i} '{label}' tidak cocok dengan isi berkas migrasi.")
            semua_lolos = False
            continue

        isi_termutasi = re.sub(pola, pengganti, isi_asli, count=1)
        BERKAS_MIGRASI.write_text(isi_termutasi, encoding="utf-8")

        try:
            kode, log = jalankan_tes()
            # Bila termutasi, tes HARUS gagal (kode != 0)
            if kode == 0:
                print(f"  ❌ GAGAL: Mutasi #{i} '{label}' lolos diam-diam (tidak tertangkap tes)!")
                semua_lolos = False
            else:
                print(f"  ✅ TERTANGKAP: Mutasi #{i} '{label}' terdeteksi merah.")
        finally:
            BERKAS_MIGRASI.write_text(isi_asli, encoding="utf-8")

    if not semua_lolos:
        print("\nHASIL: Sebagian mutasi tidak tertangkap! Perketat berkas uji.")
        sys.exit(1)

    print("\nHASIL: 100% mutasi tertangkap (fail-closed terbukti kuat).")


if __name__ == "__main__":
    main()
