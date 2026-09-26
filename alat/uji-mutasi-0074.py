#!/usr/bin/env python3
"""
alat/uji-mutasi-0074.py — Penguji Mutasi Fail-Closed untuk 0074_pengaturan_menu.sql (T9-05).

Memastikan seluruh mitigasi risiko (menu yang pernah dipesan dilarang dihapus fisik),
pagar integritas kategori ber-menu, otorisasi peran kelola menu, validasi harga,
validasi nama unik, isolasi kategori penyewa, dan audit trail benar-benar
teruji dan tidak bisa dilemahkan diam-diam.
"""

import os
import re
import subprocess
import sys
from pathlib import Path

BERKAS_MIGRASI = Path("supabase/migrations/0074_pengaturan_menu.sql")
BERKAS_TES = "supabase/tes/pengaturan_menu.sql"

MUTASI = [
    (
        "M01: Hapus mitigasi T9-05: tolak hapus menu yang memiliki riwayat pesanan",
        r"if exists \(select 1 from public\.pesanan_item where menu_item_id = old\.id\) then[\s\S]+?end if;",
        "-- [MUTASI M01 DILEMAHKAN: Menu ber-riwayat pesanan bisa dihapus]",
    ),
    (
        "M02: Hapus pencegahan hapus kategori yang masih memiliki menu item",
        r"if exists \(select 1 from public\.menu_item where kategori_id = old\.id\) then[\s\S]+?end if;",
        "-- [MUTASI M02 DILEMAHKAN: Kategori ber-menu bisa dihapus]",
    ),
    (
        "M03: Hapus pagar otorisasi peran kelola menu pada simpan_menu",
        r"if coalesce\(public\.peran_saya\(\), ''\) not in \('owner_pusat', 'admin_cabang'\)\s+and not public\.boleh\('atur_pengaturan'\) then[\s\S]+?end if;",
        "-- [MUTASI M03 DILEMAHKAN: Tanpa otorisasi peran simpan_menu]",
    ),
    (
        "M04: Hapus validasi harga menu tidak boleh negatif",
        r"if p_harga is null or p_harga < 0 then[\s\S]+?end if;",
        "-- [MUTASI M04 DILEMAHKAN: Harga negatif dibiarkan]",
    ),
    (
        "M05: Hapus validasi nama menu wajib diisi",
        r"if p_nama is null or btrim\(p_nama\) = '' then[\s\S]+?end if;",
        "-- [MUTASI M05 DILEMAHKAN: Nama menu kosong dibiarkan]",
    ),
    (
        "M06: Hapus validasi keunikan nama menu di kategori yang sama",
        r"if exists \(\s+select 1 from public\.menu_item\s+where penyewa_id = v_penyewa\s+and kategori_id = p_kategori_id\s+and lower\(nama\) = lower\(btrim\(p_nama\)\)\s+\) then[\s\S]+?end if;",
        "-- [MUTASI M06 DILEMAHKAN: Nama menu kembar di kategori sama dibiarkan]",
    ),
    (
        "M07: Hapus pencatatan audit trail pada simpan_menu",
        r"insert into public\.catatan_audit \(penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_baru\)[\s\S]+?'simpan_menu'[\s\S]+?\);",
        "-- [MUTASI M07 DILEMAHKAN: Tanpa audit simpan_menu]",
    ),
    (
        "M08: Hapus validasi kategori menu milik penyewa yang sama",
        r"if not exists \(\s+select 1 from public\.kategori_menu\s+where id = p_kategori_id and penyewa_id = v_penyewa\s+\) then[\s\S]+?end if;",
        "-- [MUTASI M08 DILEMAHKAN: Kategori beda penyewa dibiarkan]",
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
    print("=== PENGUJIAN MUTASI 0074_pengaturan_menu.sql (T9-05) ===")
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
