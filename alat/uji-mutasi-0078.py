#!/usr/bin/env python3
"""
alat/uji-mutasi-0078.py — Uji Mutasi Fail-Closed untuk 0078_kelola_cabang.sql (T9-09 / ART-1 & ART-12)

Memastikan setiap lapis proteksi pada migrasi 0078 terbukti gagal-tertutup (fail-closed):
jika proteksi sengaja dirusak (mutasi), rangkaian pengujian SQL HARUS mendeteksinya (keluar kode != 0).
"""

import os
import re
import subprocess
import sys

BERKAS_MIGRASI = "supabase/migrations/0078_kelola_cabang.sql"

MUTASI = [
    (
        "M01: Hapus pemicu fail-closed cegah hard-delete cabang ber-riwayat pesanan",
        r"raise exception 'Cabang \"%\" tidak dapat dihapus karena memiliki riwayat transaksi pesanan\. Silakan nonaktifkan cabang ini\.', old\.nama;",
        "-- MUTASI M01 DILEPAS",
    ),
    (
        "M02: Hapus pemicu fail-closed tolak nonaktifkan satu-satunya cabang aktif (trigger)",
        r"if v_aktif_count = 0 then\s+raise exception 'Minimal harus ada satu cabang yang aktif di restoran\.';\s+end if;",
        "-- MUTASI M02 DILEPAS",
    ),
    (
        "M03: Hapus otorisasi owner_pusat pada tambah_cabang",
        r"if v_peran_saya <> 'owner_pusat' then\s+raise exception 'Hanya owner pusat yang dapat membuka cabang baru\.';\s+end if;",
        "-- MUTASI M03 DILEPAS",
    ),
    (
        "M04: Hapus validasi nama cabang kosong pada tambah_cabang",
        r"if length\(v_nama_bersih\) < 1 or length\(v_nama_bersih\) > 120 then\s+raise exception 'Nama cabang harus di antara 1 dan 120 karakter\.';\s+end if;",
        "-- MUTASI M04 DILEPAS",
    ),
    (
        "M05: Hapus validasi nama cabang duplikat pada tambah_cabang",
        r"if exists \(\s*select 1 from public\.cabang\s+where penyewa_id = v_penyewa\s+and lower\(nama\) = lower\(v_nama_bersih\)\s*\) then\s+raise exception 'Nama cabang \"%\" sudah digunakan di resto Anda\.', v_nama_bersih;\s+end if;",
        "-- MUTASI M05 DILEPAS",
    ),
    (
        "M06: Hapus validasi zona waktu resmi pada tambah_cabang",
        r"if p_zona_waktu not in \('Asia/Jakarta', 'Asia/Makassar', 'Asia/Jayapura'\) then\s+raise exception 'Zona waktu tidak valid[^']+';\s+end if;",
        "-- MUTASI M06 DILEPAS",
    ),
    (
        "M07: Hapus validasi lebar kertas printer default",
        r"if \(v_printer->>'lebar'\) is not null and \(v_printer->>'lebar'\)::int not in \(58, 80\) then\s+raise exception 'Lebar kertas printer hanya boleh 58 atau 80 mm\.';\s+end if;",
        "-- MUTASI M07 DILEPAS",
    ),
    (
        "M08: Hapus pembatasan admin_cabang hanya boleh mengedit cabangnya sendiri",
        r"if not exists \(\s*select 1 from public\.pengguna_cabang\s+where pengguna_id = auth\.uid\(\)\s+and cabang_id = p_id\s+and aktif = true\s*\) then\s+raise exception 'Admin cabang hanya dapat mengubah cabang tempatnya bertugas\.';\s+end if;",
        "-- MUTASI M08 DILEPAS",
    ),
    (
        "M09: Hapus otorisasi owner_pusat pada set_status_cabang",
        r"if v_peran_saya <> 'owner_pusat' then\s+raise exception 'Hanya owner pusat yang dapat mengubah status keaktifan cabang\.';\s+end if;",
        "-- MUTASI M09 DILEPAS",
    ),
    (
        "M10: Hapus validasi cabang resto pada set_akses_cabang",
        r"if v_target_cabang\.id is null then\s+raise exception 'Cabang tidak ditemukan atau bukan milik resto Anda\.';\s+end if;",
        "-- MUTASI M10 DILEPAS",
    ),
]

def main():
    print("=== PENGUJIAN MUTASI 0078_kelola_cabang.sql (T9-09) ===")
    if not os.path.exists(BERKAS_MIGRASI):
        print(f"ERROR: Berkas {BERKAS_MIGRASI} tidak ditemukan.")
        sys.exit(1)

    with open(BERKAS_MIGRASI, "r", encoding="utf-8") as f:
        konten_asli = f.read()

    tertangkap = 0
    lolos = 0
    rincian = []

    env = os.environ.copy()
    env["NODE_PATH"] = "alat/node_modules"

    for nama, pola, pengganti in MUTASI:
        if not re.search(pola, konten_asli):
            print(f"PERINGATAN: Pola untuk [{nama}] tidak ditemukan di berkas migrasi!")
            rincian.append((nama, "POLA TIDAK DITEMUKAN", False))
            continue

        konten_mutasi = re.sub(pola, pengganti, konten_asli, count=1)
        with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
            f.write(konten_mutasi)

        try:
            hasil = subprocess.run(
                ["node", "alat/uji-sql.mjs", "kelola_cabang"],
                capture_output=True,
                text=True,
                env=env,
                timeout=45,
            )
            # Jika uji GAGAL saat proteksi dimutasi, berarti mutasi BERHASIL TERTANGKAP (fail-closed aman)
            if hasil.returncode != 0:
                tertangkap += 1
                rincian.append((nama, "TERTANGKAP (uji gagal seperti yang diharapkan)", True))
                print(f"  [OK] {nama} -> TERTANGKAP MERAH")
            else:
                lolos += 1
                rincian.append((nama, "LOLOS (CELAH! Uji tetap hijau padahal proteksi dimatikan)", False))
                print(f"  [BAHAYA] {nama} -> LOLOS HIJAU (Uji tidak menguji lapis ini)")
        finally:
            with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
                f.write(konten_asli)

    print("\n--- HASIL AKHIR UJI MUTASI ---")
    print(f"Total Mutasi: {len(MUTASI)}")
    print(f"Tertangkap:   {tertangkap}")
    print(f"Lolos Celah:  {lolos}")

    if lolos > 0 or tertangkap < len(MUTASI):
        print("\nGAGAL: Ada proteksi yang belum diuji secara fail-closed!")
        sys.exit(1)
    else:
        print("\nSUKSES: 100% mutasi tertangkap fail-closed!")
        sys.exit(0)

if __name__ == "__main__":
    main()
