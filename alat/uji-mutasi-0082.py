#!/usr/bin/env python3
"""
alat/uji-mutasi-0082.py — Uji Mutasi Fail-Closed untuk 0082_denyut_harian_pembersih.sql (T10-08)

Memastikan seluruh proteksi keamanan tugas terjadwal denyut harian dan pembersih
data sementara terbukti gagal-tertutup (fail-closed): jika proteksi dirusak,
berkas uji SQL 'supabase/tes/denyut_pembersih.sql' HARUS mendeteksinya dan gagal.
"""

import os
import re
import subprocess
import sys

BERKAS_MIGRASI = "supabase/migrations/0082_denyut_harian_pembersih.sql"
BERKAS_TES = "supabase/tes/denyut_pembersih.sql"

MUTASI = [
    (
        "M01: Hapus pembatasan otorisasi pemilik_platform pada bersihkan_data_sementara",
        r"if v_peran_saya is null or v_peran_saya <> 'pemilik_platform' then\s+raise exception 'Hanya pemilik platform atau sistem yang dapat menjalankan pembersihan'",
        "if false and (v_peran_saya is null or v_peran_saya <> 'pemilik_platform') then\n      raise exception 'Hanya pemilik platform atau sistem yang dapat menjalankan pembersihan'",
    ),
    (
        "M02: Hapus pencatatan log hasil tugas jadwal pada denyut_harian",
        r"insert into public\.log_jadwal \(\s+jenis,\s+dimulai_pada,\s+selesai_pada,\s+sukses,\s+rincian,\s+pesan\s+\) values \(\s+'denyut'",
        "-- MUTASI M02: -- insert into public.log_jadwal",
    ),
    (
        "M03: Hapus validasi batas retensi minimum (retensi 0 hari lolos)",
        r"if p_hari_retensi is null or p_hari_retensi < 1 then\s+raise exception 'Hari retensi minimal 1 hari'",
        "if false and (p_hari_retensi is null or p_hari_retensi < 1) then\n    raise exception 'Hari retensi minimal 1 hari'",
    ),
    (
        "M04: Hapus filter batas waktu pembersihan PIN (menghapus data segar tak bersyarat)",
        r"delete from public\.percobaan_pin where waktu < v_batas;",
        "delete from public.percobaan_pin;",
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

    print("UJI MUTASI 0082 (denyut harian & pembersih data sementara — T10-08)")
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
    print("UJI DIRI penilai mutasi 0082")
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
