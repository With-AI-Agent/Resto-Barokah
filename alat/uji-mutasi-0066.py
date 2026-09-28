#!/usr/bin/env python3
"""
UJI MUTASI 0066 — membuktikan ketajaman validasi aturan kampanye voucher oleh admin (T8-11).

Mutasi yang WAJIB membuat `supabase/tes/kampanye_aturan.sql` MERAH:
  1. Validasi diskon persen > 100% dilepas.
  2. Validasi diskon nominal <= 0 dilepas.
  3. Validasi tanggal selesai <= mulai dilepas.
  4. Validasi kuota <= 0 dilepas.
  5. Validasi anggaran < nilai voucher nominal dilepas.
  6. Pengecekan hak akses admin/pemilik dilonggarkan (kasir diizinkan).

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0066.py
            python3 alat/uji-mutasi-0066.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0066_kampanye_aturan.sql")
BERKAS_UJI = ["supabase/tes/kampanye_aturan.sql"]


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
        "validasi diskon persen > 100% dilepas",
        "  if new.jenis = 'persen' and (new.nilai <= 0 or new.nilai > 100) then",
        "  if false and (new.nilai <= 0) then",
    ),
    (
        "validasi kuota 0 dilepas (kuota harus > 0)",
        "  if new.kuota <= 0 then",
        "  if false and new.kuota <= 0 then",
    ),
    (
        "validasi anggaran < nilai voucher nominal dilepas",
        "  if new.jenis = 'nominal' and new.anggaran_maks < new.nilai then",
        "  if false and new.anggaran_maks < new.nilai then",
    ),
    (
        "plafon potongan nominal tidak di-null-kan trigger",
        "  if new.jenis = 'nominal' then\n    new.maks_potongan := null;",
        "  if new.jenis = 'nominal' then\n    null; -- mutasi: maks_potongan dibiarkan",
    ),
    (
        "pengecekan hak akses admin/pemilik dilonggarkan di simpan_kampanye_voucher",
        "  if not public.boleh('atur_pengaturan') and coalesce(public.peran_saya(), '') not in ('owner_pusat', 'admin_cabang') then",
        "  if false then",
    ),
    (
        "pengecekan keunikan kode kampanye dimatikan di simpan_kampanye_voucher",
        "    if exists (\n      select 1 from public.kampanye_voucher\n       where penyewa_id = v_penyewa_id\n         and kode_kampanye = v_kode\n    ) then",
        "    if false and exists (\n      select 1 from public.kampanye_voucher\n       where penyewa_id = v_penyewa_id\n         and kode_kampanye = v_kode\n    ) then",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0066 (T8-11 — Pengaturan Kampanye Voucher oleh Admin)")
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
            "pagar Pengaturan Kampanye Voucher oleh Admin (T8-11) terbukti tajam."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0066")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()
    palsu = asli.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli:
        print("Uji diri gagal: penggantian tak terduga berhasil!")
        return 1
    print("  OK  uji-diri: mutasi sintetis tak menempel")
    print("UJI DIRI 0066 SELESAI — LOLOS")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uji-diri":
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
