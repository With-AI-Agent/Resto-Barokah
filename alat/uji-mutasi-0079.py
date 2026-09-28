#!/usr/bin/env python3
"""
alat/uji-mutasi-0079.py — Uji Mutasi Fail-Closed untuk 0079_daftar_penyewa_m1.sql (T9-10 / PRD M1 / ART-1)

Memastikan setiap lapis proteksi pada migrasi 0079 terbukti gagal-tertutup (fail-closed):
jika proteksi sengaja dirusak (mutasi), rangkaian pengujian SQL HARUS mendeteksinya (keluar kode != 0).
"""

import os
import re
import subprocess
import sys

BERKAS_MIGRASI = "supabase/migrations/0079_daftar_penyewa_m1.sql"

MUTASI = [
    (
        "M01: Hapus pemicu fail-closed cegah hard-delete penyewa yang memiliki cabang",
        r"if exists \(select 1 from public\.cabang where penyewa_id = old\.id\) then\s+raise exception 'Penyewa \"%\" tidak dapat dihapus karena masih memiliki data cabang\. Silakan nonaktifkan status penyewa\.', old\.nama;\s+end if;",
        "-- MUTASI M01 DILEPAS",
    ),
    (
        "M02: Hapus otorisasi pemilik_platform pada buat_penyewa",
        r"if v_peran_saya is null or v_peran_saya <> 'pemilik_platform' then\s+raise exception 'Hanya pemilik_platform yang berhak mendaftarkan penyewa baru\.';\s+end if;",
        "-- MUTASI M02 DILEPAS",
    ),
    (
        "M03: Hapus validasi nama resto kosong pada buat_penyewa",
        r"if length\(v_nama_bersih\) < 1 or length\(v_nama_bersih\) > 120 then\s+raise exception 'Nama penyewa/resto wajib diisi \(1-120 karakter\)\.';\s+end if;",
        "-- MUTASI M03 DILEPAS",
    ),
    (
        "M04: Hapus validasi format regex slug pada buat_penyewa",
        r"if v_slug !~ '\^\[a-z0-9\]\[a-z0-9-\]\{1,30\}\$' then[\s\S]*?end if;",
        "-- MUTASI M04 DILEPAS",
    ),
    (
        "M05: Hapus validasi tolak duplikasi slug pada buat_penyewa",
        r"if exists \(select 1 from public\.penyewa where slug = v_slug\) then[\s\S]*?end if;",
        "-- MUTASI M05 DILEPAS",
    ),
    (
        "M06: Hapus validasi tolak PIN Owner lemah pada buat_penyewa",
        r"v_lemah := public\.pin_lemah\(p_owner_pin\);[\s\S]*?end if;",
        "-- MUTASI M06 DILEPAS",
    ),
    (
        "M07: Hapus validasi format email Owner pada buat_penyewa",
        r"if v_owner_email !~ .*?then[\s\S]*?end if;",
        "-- MUTASI M07 DILEPAS",
    ),
    (
        "M08: Hapus otorisasi pemilik_platform pada set_status_penyewa",
        r"if v_peran_saya is null or v_peran_saya <> 'pemilik_platform' then\s+raise exception 'Hanya pemilik_platform yang berhak mengubah status penyewa\.';\s+end if;",
        "-- MUTASI M08 DILEPAS",
    ),
    (
        "M09: Hapus validasi alasan wajib minimal 5 karakter saat nonaktifkan penyewa",
        r"if p_status = 'nonaktif' and \(v_alasan_bersih is null or length\(v_alasan_bersih\) < 5\) then\s+raise exception 'Alasan penonaktifan penyewa wajib diisi minimal 5 karakter\.';\s+end if;",
        "-- MUTASI M09 DILEPAS",
    ),
    (
        "M10: Hapus otorisasi pemilik_platform pada ambil_daftar_penyewa",
        r"if v_peran_saya is null or v_peran_saya <> 'pemilik_platform' then\s+raise exception 'Hanya pemilik_platform yang berhak melihat daftar penyewa\.';\s+end if;",
        "-- MUTASI M10 DILEPAS",
    ),
]


def jalankan_uji_sql() -> bool:
    """Menjalankan uji SQL lokal. Mengembalikan True jika lolos (exit 0), False jika gagal."""
    hasil = subprocess.run(
        ["node", "alat/uji-sql.mjs"],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return hasil.returncode == 0


def main():
    if not os.path.exists(BERKAS_MIGRASI):
        print(f"GALAT: Berkas {BERKAS_MIGRASI} tidak ditemukan.")
        sys.exit(1)

    with open(BERKAS_MIGRASI, "r", encoding="utf-8") as f:
        isi_asli = f.read()

    print(f"=== UJI MUTASI FAIL-CLOSED: {BERKAS_MIGRASI} ===")
    print(f"Baseline: Menjalankan uji SQL pada kode asli...")
    if not jalankan_uji_sql():
        print("GALAT: Rangkaian uji SQL gagal sebelum mutasi diterapkan! Perbaiki kode terlebih dahulu.")
        sys.exit(1)
    print("Baseline: LULUS (Semua uji hijau).\n")

    tertangkap = 0
    lolos_mutasi = []

    for idx, (label, pola, pengganti) in enumerate(MUTASI, 1):
        if not re.search(pola, isi_asli):
            print(f"[{idx:02d}/10] ⚠️  POLA TIDAK DITEMUKAN: {label}")
            continue

        isi_termutasi = re.sub(pola, pengganti, isi_asli, count=1)

        with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
            f.write(isi_termutasi)

        lulus = jalankan_uji_sql()

        with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
            f.write(isi_asli)

        if not lulus:
            print(f"[{idx:02d}/10] ✅ TERTANGKAP MERAH: {label}")
            tertangkap += 1
        else:
            print(f"[{idx:02d}/10] ❌ LOLOS HIJAU (CACAT): {label}")
            lolos_mutasi.append(label)

    print("\n=== RINGKASAN UJI MUTASI 0079 ===")
    print(f"Tertangkap Merah : {tertangkap}/{len(MUTASI)}")
    if lolos_mutasi:
        print(f"Lolos Hijau      : {len(lolos_mutasi)} (Pintu pengaman belum teruji)")
        for l in lolos_mutasi:
            print(f"  - {l}")
        sys.exit(1)
    else:
        print("SEMUA MUTASI BERHASIL TERTANGKAP FAIL-CLOSED (100% HIJAU-AMAN).")
        sys.exit(0)


if __name__ == "__main__":
    main()
