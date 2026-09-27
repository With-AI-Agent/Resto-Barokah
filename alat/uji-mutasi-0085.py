#!/usr/bin/env python3
"""
alat/uji-mutasi-0085.py
Suite Uji Mutasi Fail-Closed untuk T10-13 (Ringkasan Peringatan Harian ke Owner)

Membuktikan bahwa proteksi keamanan pada migrasi 0085 benar-benar aktif:
  Mutan 1: Bypass otorisasi izin lihat_laporan pada RPC ambil_ringkasan_harian
  Mutan 2: Melemahkan isolasi RLS multi-tenant pada tabel ringkasan_harian
  Mutan 3: Bypass validasi rantai audit kriptografis (ART-13)
  Mutan 4: Pelanggaran privasi ART-14 (menyisipkan email pelanggan ke rincian peringatan)
"""

import sys
import subprocess
from pathlib import Path

MIGRASI_ASLI = Path("supabase/migrations/0085_ringkasan_harian.sql")
TEST_FILE = "supabase/tes/ringkasan.sql"

MUTASI_SCENARIOS = [
    {
        "nama": "Mutan 1: Bypass otorisasi izin lihat_laporan pada ambil_ringkasan_harian",
        "cari": "if not public.boleh('lihat_laporan') and not public.boleh('atur_pengaturan') then\n    raise exception 'Tidak berwenang melihat laporan peringatan.'",
        "ganti": "if false and not public.boleh('lihat_laporan') and not public.boleh('atur_pengaturan') then\n    raise exception 'Tidak berwenang melihat laporan peringatan.'",
    },
    {
        "nama": "Mutan 2: Melemahkan isolasi RLS multi-tenant ringkasan_harian_pilih",
        "cari": "    penyewa_id = (select public.penyewa_saya())",
        "ganti": "    penyewa_id is not null",
    },
    {
        "nama": "Mutan 3: Melemahkan verifikasi rantai audit kriptografis (ART-13)",
        "cari": "from public.verifikasi_rantai_audit(v_penyewa_id) vra",
        "ganti": "from (select false as valid, 'Rantai audit putus sengaja diuji' as pesan) vra",
    },
    {
        "nama": "Mutan 4: Pelanggaran privasi ART-14 menyisipkan data pribadi ke rincian",
        "cari": "      'pegawai', coalesce(u.nama, 'Sistem'),",
        "ganti": "      'pegawai', coalesce(u.nama, 'Sistem') || ' kontak pelanggan: rahasia@gmail.com 0812345',",
    },
]

def main():
    print("=" * 70)
    print("UJI MUTASI FAIL-CLOSED: 0085_ringkasan_harian.sql (T10-13)")
    print("=" * 70)

    if not MIGRASI_ASLI.exists():
        print(f"Error: {MIGRASI_ASLI} tidak ditemukan!")
        sys.exit(1)

    konten_asli = MIGRASI_ASLI.read_text(encoding="utf-8")

    # Pastikan kode asli lolos tes
    print("[1/2] Verifikasi kode asli lolos pengujian baseline...")
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
