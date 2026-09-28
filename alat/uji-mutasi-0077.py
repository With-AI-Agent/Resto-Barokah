#!/usr/bin/env python3
"""
alat/uji-mutasi-0077.py — Uji Mutasi Fail-Closed untuk 0077_kelola_pegawai_izin.sql (T9-08 / ART-2)

Memastikan setiap lapis proteksi pada migrasi 0077 terbukti gagal-tertutup (fail-closed):
jika proteksi sengaja dirusak (mutasi), rangkaian pengujian SQL HARUS mendeteksinya (keluar kode != 0).
"""

import os
import re
import subprocess
import sys

BERKAS_MIGRASI = "supabase/migrations/0077_kelola_pegawai_izin.sql"

MUTASI = [
    (
        "M01: Hapus pemicu fail-closed cegah hard-delete pegawai ber-riwayat",
        r"raise exception 'Pegawai \"%\" tidak dapat dihapus karena memiliki riwayat transaksi pesanan\. Silakan nonaktifkan akun pegawai ini\.', old\.nama;",
        "-- MUTASI M01 DILEPAS",
    ),
    (
        "M02: Hapus proteksi minimal satu owner pusat aktif di set_status_pengguna",
        r"raise exception 'Restoran minimal harus memiliki satu owner pusat yang aktif\.';",
        "-- MUTASI M02 DILEPAS",
    ),
    (
        "M03: Hapus perlindungan hierarki owner pusat saat simpan_pegawai (edit profil)",
        r"if v_target\.peran = 'owner_pusat' and v_peran_saya <> 'owner_pusat' then\s+raise exception 'Hanya sesama owner pusat yang dapat mengubah data profil owner pusat\.';\s+end if;",
        "-- MUTASI M03 DILEPAS",
    ),
    (
        "M04: Hapus perlindungan hierarki owner pusat saat set_izin",
        r"if v_target\.peran = 'owner_pusat' and v_peran_saya <> 'owner_pusat' then\s+raise exception 'Hanya sesama owner pusat yang dapat mengubah izin owner pusat\.';\s+end if;",
        "-- MUTASI M04 DILEPAS",
    ),
    (
        "M05: Hapus anti-privilege escalation saat set_izin kelola_pegawai",
        r"if p_kode_izin = 'kelola_pegawai' and p_boleh = true and v_peran_saya <> 'owner_pusat' then\s+raise exception 'Hanya owner pusat yang berhak memberikan izin kelola pegawai\.';\s+end if;",
        "-- MUTASI M05 DILEPAS",
    ),
    (
        "M06: Hapus validasi batas diskon nominal negatif",
        r"if p_batas_nominal is not null and p_batas_nominal < 0 then\s+raise exception 'Batas nominal diskon tidak boleh negatif\.';\s+end if;",
        "-- MUTASI M06 DILEPAS",
    ),
    (
        "M07: Hapus validasi batas diskon persen di atas 100",
        r"if p_batas_persen is not null and \(p_batas_persen < 0 or p_batas_persen > 100\) then\s+raise exception 'Batas persen diskon harus di antara 0 dan 100\.';\s+end if;",
        "-- MUTASI M07 DILEPAS",
    ),
    (
        "M08: Hapus penolakan PIN lemah saat tambah pegawai",
        r"v_lemah := public\.pin_lemah\(p_pin\);\s+if v_lemah is not null then\s+raise exception 'PIN ditolak: %\.',\s*v_lemah;\s+end if;",
        "-- MUTASI M08 DILEPAS",
    ),
    (
        "M09: Hapus perlindungan hierarki saat reset_pin_pegawai",
        r"if v_target\.peran = 'owner_pusat' and v_peran_saya <> 'owner_pusat' then\s+raise exception 'Hanya sesama owner pusat yang dapat mereset PIN owner pusat\.';\s+end if;",
        "-- MUTASI M09 DILEPAS",
    ),
    (
        "M10: Hapus otorisasi peran pada ambil_daftar_pegawai",
        r"if v_peran_saya <> 'owner_pusat' and not public\.boleh\('kelola_pegawai'\) then\s+raise exception 'Hanya owner pusat atau pemegang izin kelola_pegawai yang dapat melihat daftar pegawai\.';\s+end if;",
        "-- MUTASI M10 DILEPAS",
    ),
]

def main():
    print("=== PENGUJIAN MUTASI 0077_kelola_pegawai_izin.sql (T9-08) ===")

    if not os.path.exists(BERKAS_MIGRASI):
        print(f"GALAT: Berkas {BERKAS_MIGRASI} tidak ditemukan.")
        sys.exit(1)

    with open(BERKAS_MIGRASI, "r", encoding="utf-8") as f:
        isi_asli = f.read()

    env_ujisql = dict(os.environ)
    if "NODE_PATH" not in env_ujisql:
        env_ujisql["NODE_PATH"] = "alat/node_modules"

    # 1. Jalankan baseline asli
    print("[1/2] Memeriksa baseline asli (harus LULUS / kode keluar 0)...")
    res_base = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/kelola_pegawai_izin.sql"],
        capture_output=True,
        text=True,
        env=env_ujisql,
    )
    if res_base.returncode != 0:
        print("GALAT: Baseline asli gagal! Perbaiki kode sebelum menguji mutasi.")
        print(res_base.stdout)
        print(res_base.stderr)
        sys.exit(1)
    print("  -> Baseline BERSIH & LULUS.\n")

    # 2. Uji mutasi
    print(f"[2/2] Menguji {len(MUTASI)} mutasi fail-closed...")
    semua_lolos = True

    for i, (label, pola, pengganti) in enumerate(MUTASI, 1):
        if not re.search(pola, isi_asli):
            print(f"  ❌ PERINGATAN: Pola mutasi #{i} '{label}' tidak ditemukan dalam berkas migrasi!")
            semua_lolos = False
            continue

        isi_termutasi = re.sub(pola, pengganti, isi_asli, count=1)
        with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
            f.write(isi_termutasi)

        try:
            res_mutasi = subprocess.run(
                ["node", "alat/uji-sql.mjs", "supabase/tes/kelola_pegawai_izin.sql"],
                capture_output=True,
                text=True,
                env=env_ujisql,
            )
            if res_mutasi.returncode == 0:
                print(f"  ❌ LOLOS DINI (BAHAYA): Mutasi #{i} '{label}' TIDAK tertangkap! Uji tetap hijau saat kode dirusak.")
                semua_lolos = False
            else:
                print(f"  ✅ TERTANGKAP: Mutasi #{i} '{label}' terdeteksi merah.")
        finally:
            with open(BERKAS_MIGRASI, "w", encoding="utf-8") as f:
                f.write(isi_asli)

    if not semua_lolos:
        print("\nHASIL: Ada mutasi yang tidak tertangkap. Perketat berkas uji SQL!")
        sys.exit(1)

    print("\nHASIL: 100% mutasi tertangkap (fail-closed terbukti kuat).")

if __name__ == "__main__":
    main()
