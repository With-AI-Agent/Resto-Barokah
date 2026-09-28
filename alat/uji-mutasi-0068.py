#!/usr/bin/env python3
"""
UJI MUTASI 0068 — membuktikan ketajaman laporan klaim voucher dan deteksi anomali (T8-13).

Mutasi yang WAJIB membuat `supabase/tes/laporan_voucher.sql` MERAH:
  1. Izin `lihat_laporan` dilepas pada `laporan_voucher` (kasir tanpa izin bisa membaca laporan).
  2. Izin `lihat_laporan` dilepas pada `deteksi_anomali_voucher` (pelayan bisa melihat anomali).
  3. Validasi batas maksimal rentang tanggal (90 hari) dilepas.
  4. Validasi urutan rentang tanggal (akhir < mulai) dilepas.
  5. Deteksi anomali klaim berlebih (>3) dimatikan.
  6. Deteksi anomali brute force percobaan gagal dimatikan.
  7. Deteksi anomali pemakaian kilat (<2 menit) dimatikan.

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0068.py
            python3 alat/uji-mutasi-0068.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0068_laporan_voucher.sql")
BERKAS_UJI = ["supabase/tes/laporan_voucher.sql"]


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", *BERKAS_UJI],
        cwd=REPO,
        capture_output=True,
        text=True,
    )
    keluaran = res.stdout + res.stderr
    return (
        f"uji: {len(BERKAS_UJI)} LULUS · 0 GAGAL" in keluaran,
        keluaran,
    )


DAFTAR_MUTASI = [
    (
        "Izin lihat_laporan dilepas pada laporan_voucher",
        "  if not public.boleh('lihat_laporan') then\n    raise exception 'Anda tidak berwenang melihat laporan voucher.';\n  end if;",
        "  if false and not public.boleh('lihat_laporan') then\n    raise exception 'Anda tidak berwenang melihat laporan voucher.';\n  end if;",
    ),
    (
        "Izin lihat_laporan dilepas pada deteksi_anomali_voucher",
        "  if not public.boleh('lihat_laporan') then\n    raise exception 'Anda tidak berwenang melihat deteksi anomali voucher.';\n  end if;",
        "  if false and not public.boleh('lihat_laporan') then\n    raise exception 'Anda tidak berwenang melihat deteksi anomali voucher.';\n  end if;",
    ),
    (
        "Validasi batas 90 hari rentang tanggal dilepas",
        "  if (v_tanggal_akhir - v_tanggal_mulai) > 90 then\n    raise exception 'Rentang tanggal laporan voucher maksimal 90 hari.';\n  end if;",
        "  if false and (v_tanggal_akhir - v_tanggal_mulai) > 90 then\n    raise exception 'Rentang tanggal laporan voucher maksimal 90 hari.';\n  end if;",
    ),
    (
        "Validasi urutan rentang tanggal dilepas",
        "  if v_tanggal_akhir < v_tanggal_mulai then\n    raise exception 'Tanggal akhir tidak boleh lebih awal dari tanggal mulai.';\n  end if;",
        "  if false and v_tanggal_akhir < v_tanggal_mulai then\n    raise exception 'Tanggal akhir tidak boleh lebih awal dari tanggal mulai.';\n  end if;",
    ),
    (
        "Deteksi anomali klaim berlebih (>3) dimatikan",
        "    having count(v.id) > coalesce(p_ambang_klaim, 3)",
        "    having false and count(v.id) > coalesce(p_ambang_klaim, 3)",
    ),
    (
        "Deteksi anomali brute force percobaan gagal dimatikan",
        "    having count(*) >= 5",
        "    having false and count(*) >= 5",
    ),
    (
        "Deteksi anomali pemakaian kilat (<2 menit) dimatikan",
        "    and extract(epoch from (v.terpakai_pada - v.dibuat_pada)) between 0 and 120",
        "    and false and extract(epoch from (v.terpakai_pada - v.dibuat_pada)) between 0 and 120",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0068 (T8-13 — Laporan Klaim Voucher & Deteksi Anomali)")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()

    try:
        lulus, keluaran = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: uji tidak hijau pada salinan utuh!")
            print(keluaran[-1500:])
            return 1
        print("  OK  kontrol: salinan utuh → " + " + ".join(BERKAS_UJI) + " hijau")

        for nomor, (nama, asal, ganti) in enumerate(DAFTAR_MUTASI, start=1):
            hasil = asli.replace(asal, ganti)
            if hasil == asli:
                print(f"  [X] Mutasi {nomor}: teks mutasi TIDAK MENEMPEL pada berkas — periksa jangkar!")
                return 1
            with open(MIGRASI, "w", encoding="utf-8") as f:
                f.write(hasil)
            lulus, keluaran = jalankan_uji()
            if lulus:
                print(f"  [X] Mutasi {nomor}: {nama} LOLOS (pagar tumpul!)")
                print(keluaran[-1500:])
                return 1
            print(f"  [OK] Mutasi {nomor}: {nama} TERBUKTI MERAH")

        print(
            f"\nHASIL: LOLOS — semua {len(DAFTAR_MUTASI)} mutasi WAJIB MERAH benar-benar merah; "
            "pagar Laporan Klaim Voucher & Deteksi Anomali (T8-13) terbukti tajam."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0068")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()
    palsu = asli.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli:
        print("Uji diri gagal: penggantian tak terduga berhasil!")
        return 1
    print("  OK  uji-diri: mutasi sintetis tak menempel")
    print("UJI DIRI 0068 SELESAI — LOLOS")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uji-diri":
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
