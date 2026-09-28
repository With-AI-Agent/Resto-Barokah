#!/usr/bin/env python3
"""
alat/uji-mutasi-0072.py — Penguji Mutasi Fail-Closed untuk 0072_pengaturan_operasional.sql (T9-03).

Memastikan seluruh pagar otorisasi, validasi tarif PB1, validasi service charge,
aturan pembulatan, cara pesan, optimistic locking, jejak audit kekal, dan
pembaruan data operasional benar-benar teruji dan tidak bisa dilemahkan diam-diam.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

BERKAS_MIGRASI = Path("supabase/migrations/0072_pengaturan_operasional.sql")
BERKAS_TES = "supabase/tes/pengaturan_operasional.sql"

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
        "M03: Hapus validasi batas tarif pajak PB1 (0 s/d 100)",
        r"if p_pajak_pb1_persen < 0 or p_pajak_pb1_persen > 100 then\s+raise exception [^;]+;\s+end if;",
        "-- [MUTASI M03 DILEMAHKAN: Tanpa validasi PB1]",
    ),
    (
        "M04: Hapus validasi batas tarif service charge (0 s/d 100)",
        r"if p_service_persen < 0 or p_service_persen > 100 then\s+raise exception [^;]+;\s+end if;",
        "-- [MUTASI M04 DILEMAHKAN: Tanpa validasi service]",
    ),
    (
        "M05: Hapus validasi aturan pembulatan",
        r"if p_pembulatan not in \('none', '100', '500', '1000'\) then\s+raise exception [^;]+;\s+end if;",
        "-- [MUTASI M05 DILEMAHKAN: Tanpa validasi pembulatan]",
    ),
    (
        "M06: Hapus validasi pilihan alur cara pesan",
        r"if p_cara_pesan not in \('kasir', 'mandiri', 'meja', 'campur'\) then\s+raise exception [^;]+;\s+end if;",
        "-- [MUTASI M06 DILEMAHKAN: Tanpa validasi cara pesan]",
    ),
    (
        "M07: Hapus pembaruan pajak_pb1_persen pada tabel pengaturan",
        r"pajak_pb1_persen\s*=\s*v_pajak_final,",
        "pajak_pb1_persen = pajak_pb1_persen, -- [MUTASI M07 DILEMAHKAN]",
    ),
    (
        "M08: Hapus pencatatan audit trail (catatan_audit)",
        r"insert into public\.catatan_audit[^;]+;",
        "-- [MUTASI M08 DILEMAHKAN: Tanpa audit trail]",
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
    print("=== PENGUJIAN MUTASI 0072_pengaturan_operasional.sql (T9-03) ===")
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
