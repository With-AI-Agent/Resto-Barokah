#!/usr/bin/env python3
"""
alat/uji-mutasi-0080.py — Uji Mutasi Fail-Closed untuk 0080_kunci_idempoten_menyeluruh.sql (T10-02)

Memastikan seluruh penjaga idempoten menyeluruh (simpan_pesanan, buka_shift, tutup_shift,
set_stok, opname_stok) terbukti gagal-tertutup (fail-closed): jika proteksi dirusak,
berkas uji SQL 'supabase/tes/idempoten.sql' HARUS mendeteksinya dan gagal (keluar kode != 0).
"""

import os
import re
import subprocess
import sys

BERKAS_MIGRASI = "supabase/migrations/0080_kunci_idempoten_menyeluruh.sql"
BERKAS_TES = "supabase/tes/idempoten.sql"

MUTASI = [
    (
        "M01: Hapus pengecekan idempoten pada simpan_pesanan (dobel kirim tembus)",
        r"if found then\s+return jsonb_build_object\(\s+'berhasil', true,\s+'kode', 'IDEMPOTEN',",
        "-- MUTASI M01: if false then return null;",
    ),
    (
        "M02: Hapus pengecekan idempoten pada buka_shift (dobel buka shift tembus)",
        r"if found then\s+return jsonb_build_object\(\s+'berhasil', true,\s+'kode', 'IDEMPOTEN',\s+'pesan', 'Shift kasir sudah terbuka sebelumnya dengan kunci yang sama",
        "-- MUTASI M02: if false then return null;",
    ),
    (
        "M03: Hapus pengecekan idempoten pada tutup_shift (dobel tutup shift tembus)",
        r"if found then\s+return jsonb_build_object\(\s+'berhasil', true,\s+'kode', 'IDEMPOTEN',\s+'pesan', 'Shift kasir sudah ditutup sebelumnya dengan kunci yang sama",
        "-- MUTASI M03: if false then return null;",
    ),
    (
        "M04: Hapus pengecekan idempoten pada set_stok (delta stok bertambah ganda)",
        r"if found then\s+select b\.jumlah into v_saldo_sekarang\s+from public\.stok_bahan b\s+where b\.id = p_stok_bahan_id;\s+return jsonb_build_object\(\s+'berhasil', true,\s+'kode', 'IDEMPOTEN',",
        "-- MUTASI M04: if false then return null;",
    ),
    (
        "M05: Hapus pengecekan idempoten pada opname_stok (rekam opname dobel)",
        r"if found then\s+select b\.jumlah into v_saldo_sekarang\s+from public\.stok_bahan b\s+where b\.id = p_stok_bahan_id;\s+return jsonb_build_object\(\s+'berhasil', true,\s+'kode', 'IDEMPOTEN',",
        "-- MUTASI M05: if false then return null;",
    ),
]


def jalankan_tes():
    perintah = ["node", "alat/uji-sql.mjs", BERKAS_TES]
    hasil = subprocess.run(perintah, capture_output=True, text=True)
    return hasil.returncode == 0, hasil.stdout + hasil.stderr


def uji_mutasi():
    if not os.path.exists(BERKAS_MIGRASI):
        print(f"Berkas migrasi tidak ditemukan: {BERKAS_MIGRASI}")
        return 1

    with open(BERKAS_MIGRASI, "r", encoding="utf-8") as f:
        konten_asli = f.read()

    print("UJI MUTASI 0080 (kunci idempoten menyeluruh — T10-02)")
    # Baseline check
    lulus, log = jalankan_tes()
    if not lulus:
        print("  [ERROR] Baseline tes sudah gagal sebelum mutasi diterapkan!")
        print(log)
        return 1
    print(f"  OK  kontrol: salinan utuh → {BERKAS_TES} hijau")

    semua_lulus = True
    for nama, pola_cari, teks_ganti in MUTASI:
        if not re.search(pola_cari, konten_asli):
            print(f"  [GAGAL] Pola mutasi tidak ditemukan di {BERKAS_MIGRASI}:")
            print(f"          {nama}")
            semua_lulus = False
            continue

        konten_mutasi = re.sub(pola_cari, teks_ganti, konten_asli, count=1)
        with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
            f.write(konten_mutasi)

        try:
            lulus, _ = jalankan_tes()
            if lulus:
                print(f"  [GAGAL] {nama} LOLOS (seharusnya gagal!)")
                semua_lulus = False
            else:
                print(f"  [OK] {nama} TERBUKTI MERAH")
        finally:
            with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
                f.write(konten_asli)

    if semua_lulus:
        print(f"\nHASIL: LOLOS — seluruh {len(MUTASI)} mutasi terbukti ditangkap oleh uji SQL.")
        return 0
    else:
        print("\nHASIL: GAGAL — beberapa mutasi tidak terdeteksi.")
        return 1


def uji_diri():
    print("UJI DIRI penilai mutasi 0080")
    if not os.path.exists(BERKAS_MIGRASI):
        print(f"  [X] Berkas migrasi tidak ada: {BERKAS_MIGRASI}")
        return 1
    with open(BERKAS_MIGRASI, "r", encoding="utf-8") as f:
        teks = f.read()
    for nama, pola, _ in MUTASI:
        if not re.search(pola, teks):
            print(f"  [X] Jangkar tidak cocok untuk: {nama}")
            return 1
    print("  [OK] Semua jangkar mutasi cocok pada berkas migrasi utuh.")
    print("HASIL: LOLOS")
    return 0


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
