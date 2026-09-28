#!/usr/bin/env python3
"""
UJI MUTASI 0059 — membuktikan ketajaman pagar isolasi penyewa dan pencabutan anon
pada percobaan_masuk (N F-05 audit AUD-3 2026-09-24).

Mutasi yang WAJIB membuat `supabase/tes/percobaan_masuk_tenant.sql` MERAH:
  1. Hak execute catat_percobaan_masuk diberikan kembali ke anon
  2. Pemeriksaan akses lintas penyewa (v_penyewa <> p_penyewa_id) dihilangkan
  3. Pemeriksaan izin kelola_pegawai pada periksa_kunci_masuk dihilangkan

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0059.py
            python3 alat/uji-mutasi-0059.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0059_catat_percobaan_masuk_tenant.sql")
BERKAS_UJI = ["supabase/tes/percobaan_masuk_tenant.sql"]


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
        "hak catat_percobaan_masuk diberikan kembali ke anon",
        "revoke execute on function public.catat_percobaan_masuk(uuid, uuid, uuid, boolean, text) from anon;",
        "grant execute on function public.catat_percobaan_masuk(uuid, uuid, uuid, boolean, text) to anon;",
    ),
    (
        "pemeriksaan lintas penyewa dihilangkan",
        "if v_penyewa is null or v_penyewa <> p_penyewa_id then",
        "if false and (v_penyewa is null or v_penyewa <> p_penyewa_id) then",
    ),
    (
        "pemeriksaan izin kelola_pegawai pada periksa_kunci_masuk dihilangkan",
        "and not (public.sepenyewa(p_pengguna_id) and public.boleh('kelola_pegawai'))",
        "and false -- MUTASI: izin diabaikan",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0059 (N F-05 audit 2026-09-24 — isolasi tenant & larangan anon percobaan_masuk)")
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
            "pagar isolasi tenant & larangan anon (N F-05) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0059")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()
    palsu = asli.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli:
        print("  [X] deteksi jangkar tidak menempel TIDAK bekerja")
        return 1
    lulus, _ = jalankan_uji()
    if not lulus:
        print("  [X] kontrol positif tidak hijau — penilai tidak bisa dipercaya")
        return 1
    print("  OK  kontrol positif hijau & deteksi jangkar tidak menempel bekerja.")
    return 0


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
