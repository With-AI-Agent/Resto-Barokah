#!/usr/bin/env python3
"""
alat/uji-mutasi-0084.py
Suite Uji Mutasi Fail-Closed untuk T10-12 (Cabut Akses Pegawai Berhenti & Serah Terima)

Membuktikan bahwa proteksi keamanan pada migrasi 0084 benar-benar aktif:
  Mutan 1: Melemahkan otorisasi (membiarkan non-owner/non-kelola_pegawai memanggil pegawai_berhenti)
  Mutan 2: Melewatkan pencabutan sesi perangkat di sesi_perangkat
  Mutan 3: Melewatkan penghapusan PIN di kredensial_pin
  Mutan 4: Melewatkan penandaan shift kasir terbuka (perlu_tutup_atasan)
"""

import sys
import subprocess
import tempfile
import shutil
from pathlib import Path

MIGRASI_ASLI = Path("supabase/migrations/0084_cabut_akses_pegawai_berhenti.sql")
TEST_FILE = "supabase/tes/cabut_akses.sql"

MUTASI_SCENARIOS = [
    {
        "nama": "Mutan 1: Bypass otorisasi kelola_pegawai",
        "cari": "if v_peran_saya <> 'owner_pusat' and not public.boleh('kelola_pegawai') then",
        "ganti": "if false and v_peran_saya <> 'owner_pusat' and not public.boleh('kelola_pegawai') then",
    },
    {
        "nama": "Mutan 2: Lewatkan pemutusan sesi perangkat",
        "cari": "update public.sesi_perangkat\n     set status = 'dicabut',",
        "ganti": "update public.sesi_perangkat\n     set status = 'aktif',",
    },
    {
        "nama": "Mutan 3: Lewatkan penghapusan PIN kredensial",
        "cari": "delete from public.kredensial_pin\n   where pengguna_id = p_pengguna_id;",
        "ganti": "-- mutan lewati hapus pin: delete from public.kredensial_pin where pengguna_id = p_pengguna_id;",
    },
    {
        "nama": "Mutan 4: Lewatkan penandaan perlu_tutup_atasan pada shift kas",
        "cari": "update public.shift_kas\n       set perlu_tutup_atasan = true,",
        "ganti": "update public.shift_kas\n       set perlu_tutup_atasan = false,",
    },
]

def main():
    print("=" * 70)
    print("UJI MUTASI FAIL-CLOSED: 0084_cabut_akses_pegawai_berhenti.sql (T10-12)")
    print("=" * 70)

    if not MIGRASI_ASLI.exists():
        print(f"Error: {MIGRASI_ASLI} tidak ditemukan!")
        sys.exit(1)

    konten_asli = MIGRASI_ASLI.read_text(encoding="utf-8")

    # Pastikan kode asli lolos tes
    print("[1/2] Verifikasi kode asli lolos pengujian...")
    cmd_baseline = ["node", "alat/uji-sql.mjs", TEST_FILE]
    res_baseline = subprocess.run(cmd_baseline, capture_output=True, text=True)
    if res_baseline.returncode != 0:
        print("FAIL: Kode asli tidak lolos uji baseline!")
        print(res_baseline.stdout)
        print(res_baseline.stderr)
        sys.exit(1)
    print("      Baseline OK: Pengujian lolos.")

    print("\n[2/2] Menguji ketahanan terhadap mutasi (Fail-Closed)...")
    mutan_terbunuh = 0

    for i, m in enumerate(MUTASI_SCENARIOS, 1):
        print(f"\n  Skenario {i}: {m['nama']}")
        if m["cari"] not in konten_asli:
            print(f"    ERROR: Target string mutasi tidak ditemukan di {MIGRASI_ASLI}!")
            sys.exit(1)

        konten_mutan = konten_asli.replace(m["cari"], m["ganti"], 1)
        MIGRASI_ASLI.write_text(konten_mutan, encoding="utf-8")

        try:
            res_mutan = subprocess.run(cmd_baseline, capture_output=True, text=True)
            if res_mutan.returncode != 0:
                print(f"    [TERBUNUH] Mutan berhasil dideteksi dan ditolak oleh suite uji.")
                mutan_terbunuh += 1
            else:
                print(f"    [LOLOS - BAHAYA!] Mutan tidak terdeteksi oleh pengujian!")
        finally:
            MIGRASI_ASLI.write_text(konten_asli, encoding="utf-8")

    print("\n" + "=" * 70)
    print(f"HASIL MUTASI: {mutan_terbunuh}/{len(MUTASI_SCENARIOS)} mutan berhasil terbunuh.")
    if mutan_terbunuh == len(MUTASI_SCENARIOS):
        print("STATUS: 100% FAIL-CLOSED TERBUKTI.")
        print("=" * 70)
        sys.exit(0)
    else:
        print("STATUS: GAGAL — Terdapat mutan yang lolos uji!")
        print("=" * 70)
        sys.exit(1)

if __name__ == "__main__":
    main()
