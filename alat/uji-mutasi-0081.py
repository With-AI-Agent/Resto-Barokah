#!/usr/bin/env python3
"""
alat/uji-mutasi-0081.py — Uji Mutasi Fail-Closed untuk 0081_akhiri_sesi_perangkat_hilang.sql (T10-06)

Memastikan seluruh penjaga keamanan pemutusan sesi dan penanganan perangkat hilang
terbukti gagal-tertutup (fail-closed): jika proteksi dirusak, berkas uji SQL
'supabase/tes/akhiri_sesi_perangkat_hilang.sql' HARUS mendeteksinya dan gagal (keluar kode != 0).
"""

import os
import re
import subprocess
import sys

BERKAS_MIGRASI = "supabase/migrations/0081_akhiri_sesi_perangkat_hilang.sql"
BERKAS_TES = "supabase/tes/akhiri_sesi_perangkat_hilang.sql"

MUTASI = [
    (
        "M01: Hapus filter isolasi penyewa/otorisasi pada daftar_sesi()",
        r"where sp\.penyewa_id = v_penyewa\s+and \(v_boleh or sp\.pengguna_id = v_saya\)",
        "where true",
    ),
    (
        "M02: Hapus pengecekan izin pada akhiri_sesi (staf bisa akhiri sesi staf lain)",
        r"if v_sesi\.pengguna_id <> v_uid and not public\.boleh\('kelola_pegawai'\) then",
        "if false and v_sesi.pengguna_id <> v_uid then",
    ),
    (
        "M03: Hapus pencatatan audit pada keluar_semua_perangkat",
        r"insert into public\.catatan_audit \(\s+penyewa_id,\s+pelaku_id,\s+aksi,\s+entitas,\s+entitas_id,\s+nilai_lama,\s+nilai_baru\s+\) values \(\s+v_penyewa,\s+v_saya,\s+'keluar_semua_perangkat'",
        "-- MUTASI M03: -- insert into public.catatan_audit",
    ),
    (
        "M04: Hapus pencabutan sesi seketika saat perangkat ditandai hilang",
        r"update public\.sesi_perangkat\s+set status = 'dicabut',\s+diperbarui_pada = now\(\)\s+where perangkat_id = p_perangkat_id\s+and status = 'aktif';",
        "-- MUTASI M04: tidak mencabut sesi aktif perangkat",
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

    print("UJI MUTASI 0081 (akhiri sesi & perangkat hilang — T10-06)")
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
    print("UJI DIRI penilai mutasi 0081")
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
