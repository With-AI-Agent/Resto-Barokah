#!/usr/bin/env python3
"""
alat/uji-mutasi-0076.py — Uji Mutasi Fail-Closed untuk 0076_metode_bayar_tip.sql (T9-07)

Memastikan setiap lapis proteksi pada migrasi 0076 terbukti gagal-tertutup (fail-closed):
jika proteksi sengaja dirusak (mutasi), rangkaian pengujian SQL HARUS mendeteksinya (keluar kode != 0).
"""

import os
import re
import subprocess
import sys

BERKAS_MIGRASI = "supabase/migrations/0076_metode_bayar_tip.sql"

MUTASI = [
    (
        "M01: Hapus pemicu fail-closed cegah hapus metode dengan riwayat transaksi",
        r"raise exception 'Metode pembayaran \"%\" tidak dapat dihapus karena sudah memiliki riwayat transaksi pembayaran\. Silakan nonaktifkan metode ini\.', old\.nama;",
        "-- MUTASI M01 DILEPAS",
    ),
    (
        "M02: Hapus pemicu fail-closed minimal satu metode pembayaran aktif",
        r"raise exception 'Minimal harus ada satu metode pembayaran yang aktif di restoran\.';",
        "-- MUTASI M02 DILEPAS",
    ),
    (
        "M03: Hapus validasi nama metode pembayaran minimal 2 karakter",
        r"if v_nama_bersih is null or length\(v_nama_bersih\) < 2 then\s+raise exception 'Nama metode pembayaran minimal 2 karakter\.';\s+end if;",
        "-- MUTASI M03 DILEPAS",
    ),
    (
        "M04: Hapus validasi metode tunai tidak boleh mewajibkan referensi",
        r"if p_jenis = 'tunai' and p_butuh_referensi = true then\s+raise exception 'Metode pembayaran tunai tidak boleh mewajibkan nomor referensi\.';\s+end if;",
        "-- MUTASI M04 DILEPAS",
    ),
    (
        "M05: Hapus validasi metode non-tunai wajib referensi",
        r"if p_jenis = 'non_tunai' and p_butuh_referensi = false then\s+raise exception 'Metode pembayaran non-tunai wajib mengaktifkan nomor referensi\.';\s+end if;",
        "-- MUTASI M05 DILEPAS",
    ),
    (
        "M06: Hapus proteksi otorisasi peran pada simpan_metode_bayar",
        r"if v_peran <> 'owner_pusat' and not public\.boleh\('atur_pengaturan'\) then\s+if v_peran <> 'admin_cabang' then\s+raise exception 'Hanya owner pusat, pemegang izin atur_pengaturan, atau admin cabang yang dapat mengatur metode pembayaran\.';\s+end if;\s+end if;",
        "-- MUTASI M06 DILEPAS",
    ),
    (
        "M07: Hapus proteksi otorisasi peran pada simpan_aturan_tip",
        r"if v_peran <> 'owner_pusat' and not public\.boleh\('atur_pengaturan'\) then\s+raise exception 'Hanya owner pusat atau pemegang izin atur_pengaturan yang dapat mengubah aturan tip\.';\s+end if;",
        "-- MUTASI M07 DILEPAS",
    ),
    (
        "M08: Hapus penambahan tip sukarela pada hitung_total",
        r"v_total := v_total \+ coalesce\(v_pesanan\.tip, 0\);",
        "-- MUTASI M08 DILEPAS",
    ),
]

def main():
    print("=== PENGUJIAN MUTASI 0076_metode_bayar_tip.sql (T9-07) ===")

    if not os.path.exists(BERKAS_MIGRASI):
        print(f"GALAT: Berkas {BERKAS_MIGRASI} tidak ditemukan.")
        sys.exit(1)

    with open(BERKAS_MIGRASI, "r", encoding="utf-8") as f:
        isi_asli = f.read()

    # 1. Jalankan baseline asli
    print("[1/2] Memeriksa baseline asli (harus LULUS / kode keluar 0)...")
    res_base = subprocess.run(["node", "alat/uji-sql.mjs", "supabase/tes/metode_bayar_tip.sql"], capture_output=True, text=True)
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
            res_mutasi = subprocess.run(["node", "alat/uji-sql.mjs", "supabase/tes/metode_bayar_tip.sql"], capture_output=True, text=True)
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
