#!/usr/bin/env python3
"""
alat/uji-mutasi-0073.py — Penguji Mutasi Fail-Closed untuk 0073_pengaturan_meja.sql (T9-04).

Memastikan seluruh mitigasi risiko (meja nonaktif dilarang menerima pesanan baru),
pagar otorisasi peran, validasi keunikan nomor meja per cabang, larangan nonaktifkan
meja dengan pesanan aktif, larangan hapus meja ber-riwayat, dan audit trail
benar-benar teruji dan tidak bisa dilemahkan diam-diam.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

BERKAS_MIGRASI = Path("supabase/migrations/0073_pengaturan_meja.sql")
BERKAS_TES = "supabase/tes/pengaturan_meja.sql"

MUTASI = [
    (
        "M01: Hapus mitigasi T9-04: tolak pesanan baru di meja nonaktif",
        r"if not v_aktif_meja and \(tg_op = 'INSERT' or new\.meja_id is distinct from old\.meja_id\) then[\s\S]+?end if;",
        "-- [MUTASI M01 DILEMAHKAN: Pesanan di meja nonaktif dibiarkan]",
    ),
    (
        "M02: Hapus pagar otorisasi peran kelola meja",
        r"if v_peran not in \('owner_pusat', 'admin_cabang'\) and not public\.boleh\('atur_pengaturan'\) then[\s\S]+?end if;",
        "-- [MUTASI M02 DILEMAHKAN: Tanpa otorisasi peran simpan_meja]",
    ),
    (
        "M03: Hapus validasi keunikan nomor/nama meja di cabang",
        r"if exists \(\s+select 1 from public\.meja m\s+where m\.cabang_id = p_cabang_id[\s\S]+?\) then[\s\S]+?end if;",
        "-- [MUTASI M03 DILEMAHKAN: Nama kembar di cabang dibiarkan]",
    ),
    (
        "M04: Hapus pencegahan nonaktifkan meja dengan pesanan aktif",
        r"if v_pesanan_aktif > 0 then[\s\S]+?end if;",
        "-- [MUTASI M04 DILEMAHKAN: Meja terisi pesanan bisa dinonaktifkan]",
    ),
    (
        "M05: Hapus pencegahan hapus meja dengan riwayat pesanan di hapus_meja",
        r"if v_pesanan > 0 then[\s\S]+?end if;",
        "-- [MUTASI M05 DILEMAHKAN: Meja ber-riwayat pesanan bisa dihapus]",
    ),
    (
        "M06: Hapus pencatatan audit trail pada simpan_meja",
        r"insert into public\.catatan_audit \(\s+penyewa_id,\s+pelaku_id,\s+aksi,\s+entitas,\s+entitas_id,\s+nilai_lama,\s+nilai_baru\s+\) values \(\s+v_penyewa_id,\s+v_pengguna_id,\s+v_aksi,\s+'meja',\s+v_meja\.id,\s+v_nilai_lama,\s+v_nilai_baru\s+\);",
        "-- [MUTASI M06 DILEMAHKAN: Tanpa audit simpan_meja]",
    ),
    (
        "M07: Hapus validasi nama meja wajib diisi",
        r"if length\(v_nama_bersih\) < 1 or length\(v_nama_bersih\) > 50 then[\s\S]+?end if;",
        "-- [MUTASI M07 DILEMAHKAN: Nama meja kosong dibiarkan]",
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
    print("=== PENGUJIAN MUTASI 0073_pengaturan_meja.sql (T9-04) ===")
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
