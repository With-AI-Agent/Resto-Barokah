#!/usr/bin/env python3
"""
PERIKSA MATRIKS IZIN 6 PERAN (T1-29, ART-2, ART-15)
Memverifikasi kepatuhan matriks 6 peran × seluruh izin & RPC secara komprehensif.
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TES_SQL = os.path.join(REPO, "supabase", "tes", "matriks_izin_6_peran.sql")

def cetak_matriks_laporan():
    matriks = {
        "pemilik_platform": {
            "atur_pengaturan": False, "kelola_pegawai": False, "lihat_laporan": False,
            "ubah_harga": False, "ubah_stok": False, "void_sebelum_dapur": False,
            "void_sesudah_dapur": False, "beri_diskon": False, "pakai_voucher": False,
            "tutup_kas": False, "mode_dukungan": True
        },
        "owner_pusat": {
            "atur_pengaturan": True, "kelola_pegawai": True, "lihat_laporan": True,
            "ubah_harga": True, "ubah_stok": True, "void_sebelum_dapur": True,
            "void_sesudah_dapur": True, "beri_diskon": True, "pakai_voucher": True,
            "tutup_kas": True, "mode_dukungan": False
        },
        "admin_cabang": {
            "atur_pengaturan": False, "kelola_pegawai": True, "lihat_laporan": True,
            "ubah_harga": True, "ubah_stok": True, "void_sebelum_dapur": True,
            "void_sesudah_dapur": True, "beri_diskon": True, "pakai_voucher": True,
            "tutup_kas": True, "mode_dukungan": False
        },
        "kasir": {
            "atur_pengaturan": False, "kelola_pegawai": False, "lihat_laporan": False,
            "ubah_harga": False, "ubah_stok": False, "void_sebelum_dapur": True,
            "void_sesudah_dapur": False, "beri_diskon": True, "pakai_voucher": True,
            "tutup_kas": True, "mode_dukungan": False
        },
        "pelayan": {
            "atur_pengaturan": False, "kelola_pegawai": False, "lihat_laporan": False,
            "ubah_harga": False, "ubah_stok": False, "void_sebelum_dapur": False,
            "void_sesudah_dapur": False, "beri_diskon": False, "pakai_voucher": True,
            "tutup_kas": False, "mode_dukungan": False
        },
        "dapur": {
            "atur_pengaturan": False, "kelola_pegawai": False, "lihat_laporan": False,
            "ubah_harga": False, "ubah_stok": False, "void_sebelum_dapur": False,
            "void_sesudah_dapur": False, "beri_diskon": False, "pakai_voucher": False,
            "tutup_kas": False, "mode_dukungan": False
        }
    }

    print("================================================================================")
    print("MATRIKS HAK AKSES RESMI: 6 PERAN × 10 IZIN + MODE DUKUNGAN (T1-29)")
    print("================================================================================")
    header = f"{'Izin / Aksi':<22} | {'Platform':<8} | {'Owner':<6} | {'Admin':<6} | {'Kasir':<6} | {'Pelayan':<8} | {'Dapur':<6}"
    print(header)
    print("-" * len(header))
    
    aksi_list = [
        "atur_pengaturan", "kelola_pegawai", "lihat_laporan", "ubah_harga",
        "ubah_stok", "void_sebelum_dapur", "void_sesudah_dapur", "beri_diskon",
        "pakai_voucher", "tutup_kas", "mode_dukungan"
    ]
    
    for aksi in aksi_list:
        baris = f"{aksi:<22} | "
        baris += f"{'✓' if matriks['pemilik_platform'][aksi] else '✗':<8} | "
        baris += f"{'✓' if matriks['owner_pusat'][aksi] else '✗':<6} | "
        baris += f"{'✓' if matriks['admin_cabang'][aksi] else '✗':<6} | "
        baris += f"{'✓' if matriks['kasir'][aksi] else '✗':<6} | "
        baris += f"{'✓' if matriks['pelayan'][aksi] else '✗':<8} | "
        baris += f"{'✓' if matriks['dapur'][aksi] else '✗':<6}"
        print(baris)
    print("================================================================================")

def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", "supabase/tes/matriks_izin_6_peran.sql"],
        cwd=REPO,
        capture_output=True,
        text=True
    )
    output = res.stdout + res.stderr
    lulus = "uji: 1 LULUS · 0 GAGAL" in output
    return lulus, output

def periksa():
    cetak_matriks_laporan()
    lulus, out = jalankan_uji()
    if not lulus:
        print("GAGAL: Pengujian matriks izin 6 peran tidak lulus!")
        print(out)
        return 1
    print("\nHASIL: LOLOS — Seluruh matriks izin 6 peran diverifikasi valid.")
    return 0

def uji_diri():
    print("UJI DIRI pemeriksa matriks izin 6 peran")
    with open(TES_SQL, "r", encoding="utf-8") as f:
        asli = f.read()
    try:
        # Kontrol awal
        lulus, _ = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL")
            return 1
        
        # Mutasi: dapur boleh ubah harga
        m1 = asli.replace(
            "select uji.sama(public.boleh('ubah_harga'), false, 'dapur TIDAK boleh ubah_harga');",
            "select uji.sama(public.boleh('ubah_harga'), true, 'dapur TIDAK boleh ubah_harga');"
        )
        with open(TES_SQL, "w", encoding="utf-8") as f:
            f.write(m1)
        lulus, _ = jalankan_uji()
        if lulus:
            print("  [X] Mutasi gagal terdeteksi (dapur ubah_harga)")
            return 1
        print("  [OK] Mutasi dapur ubah_harga terbukti MENOLAK.")
        return 0
    finally:
        with open(TES_SQL, "w", encoding="utf-8") as f:
            f.write(asli)

if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa())
