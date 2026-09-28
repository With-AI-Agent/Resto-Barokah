#!/usr/bin/env python3
"""
alat/uji-mutasi-0083.py — Uji Mutasi Fail-Closed untuk 0083_versi_pengaturan_bersamaan.sql (T10-11)

Memastikan seluruh proteksi kunci konkurensi optimistik (optimistic locking)
pada simpan_menu, simpan_kategori_menu, simpan_meja, dan catat_konflik_pengaturan
terbukti gagal-tertutup (fail-closed): jika proteksi dirusak, berkas uji SQL
'supabase/tes/pengaturan_bersamaan.sql' HARUS mendeteksinya dan gagal.
"""

import os
import re
import subprocess
import sys

BERKAS_MIGRASI = "supabase/migrations/0083_versi_pengaturan_bersamaan.sql"
BERKAS_TES = "supabase/tes/pengaturan_bersamaan.sql"

MUTASI = [
    (
        "M01: Hapus pengecekan versi usang pada simpan_menu",
        r"if p_versi_lama is not null and v_diubah_pada_lama is not null then\s+if v_diubah_pada_lama <> p_versi_lama then\s+raise exception 'Data menu sudah diubah oleh pengguna lain\. Silakan muat ulang halaman\.'",
        "if false then raise exception 'Data menu sudah diubah oleh pengguna lain. Silakan muat ulang halaman.'",
    ),
    (
        "M02: Hapus pengecekan versi usang pada simpan_kategori_menu",
        r"if p_versi_lama is not null and v_diubah_pada_lama is not null then\s+if v_diubah_pada_lama <> p_versi_lama then\s+raise exception 'Data kategori menu sudah diubah oleh pengguna lain\. Silakan muat ulang halaman\.'",
        "if false then raise exception 'Data kategori menu sudah diubah oleh pengguna lain. Silakan muat ulang halaman.'",
    ),
    (
        "M03: Hapus pengecekan versi usang pada simpan_meja",
        r"if p_versi_lama is not null and v_meja\.diubah_pada is not null then\s+if v_meja\.diubah_pada <> p_versi_lama then\s+raise exception 'Data meja sudah diubah oleh pengguna lain\. Silakan muat ulang halaman\.'",
        "if false then raise exception 'Data meja sudah diubah oleh pengguna lain. Silakan muat ulang halaman.'",
    ),
    (
        "M04: Hapus pencatatan jejak audit pada catat_konflik_pengaturan",
        r"insert into public\.catatan_audit \(\s+penyewa_id, pelaku_id, aksi, entitas, entitas_id, nilai_lama, nilai_baru\s+\) values \(",
        "-- MUTASI M04: -- insert into public.catatan_audit (",
    ),
]


def jalankan_tes() -> bool:
    hasil = subprocess.run(
        ["node", "alat/uji-sql.mjs", BERKAS_TES],
        capture_output=True,
        text=True,
    )
    return hasil.returncode == 0


def main():
    print("======================================================================")
    print("UJI MUTASI FAIL-CLOSED: 0083_versi_pengaturan_bersamaan.sql (T10-11)")
    print("======================================================================")

    if not os.path.exists(BERKAS_MIGRASI):
        print(f"GALAT: Berkas migrasi {BERKAS_MIGRASI} tidak ditemukan.")
        sys.exit(1)

    with open(BERKAS_MIGRASI, "r", encoding="utf-8") as f:
        isi_asli = f.read()

    # Pastikan baseline lulus sebelum mutasi
    print("1. Menjalankan baseline tanpa mutasi...")
    if not jalankan_tes():
        print("GALAT: Baseline gagal sebelum mutasi diterapkan!")
        sys.exit(1)
    print("   Baseline: LOLOS (100% hijau)\n")

    semua_lulus = True

    try:
        for idx, (label, pola, pengganti) in enumerate(MUTASI, 1):
            print(f"Kasus Mutasi #{idx}: {label}")
            if not re.search(pola, isi_asli):
                print(f"   [GAGAL] Pola mutasi tidak cocok pada berkas {BERKAS_MIGRASI}!")
                semua_lulus = False
                continue

            isi_mutasi = re.sub(pola, pengganti, isi_asli, count=1)
            with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
                f.write(isi_mutasi)

            lulus_mutasi = jalankan_tes()
            if lulus_mutasi:
                print("   [MUTAN LOLOS / BAHAYA] Pengujian tetap lolos padahal proteksi dimatikan!")
                semua_lulus = False
            else:
                print("   [MUTAN MATI / BERHASIL] Pengujian mendeteksi kerusakan proteksi (merah).")

    finally:
        # Kembalikan berkas ke bentuk asli
        with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
            f.write(isi_asli)
        print("\nBerkas migrasi dikembalikan ke kondisi asli.")

    if semua_lulus:
        print("\nHASIL AKHIR: 4/4 MUTAN MATI — SELURUH PROTEKSI KONKURENSI FAIL-CLOSED LULUS SEMPURNA.")
        sys.exit(0)
    else:
        print("\nHASIL AKHIR: ADA MUTAN YANG LOLOS — PERBAIKI PENGUJIAN!")
        sys.exit(1)


if __name__ == "__main__":
    main()
