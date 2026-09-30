#!/usr/bin/env python3
"""
UJI MUTASI 0067 — membuktikan ketajaman pengaman anti-kecurangan voucher 10 lapis (T8-12).

Mutasi yang WAJIB membuat `supabase/tes/pengaman_voucher.sql` MERAH:
  1. Lapis 1: Kuota klaim per identitas pelanggan dilepas (dobel klaim diperbolehkan).
  2. Lapis 2: Batas penukaran voucher per cabang per hari dilepas (kuota harian cabang diabaikan).
  3. Lapis 5: Batas anggaran maksimal kampanye dilepas (anggaran bisa dilampaui).
  4. Lapis 8: Pagar rate limiting perangkat/IP dilepas (brute force tidak diblokir).
  5. Lapis 9: Penolakan email sekali-pakai dilepas (tempmail diizinkan mendaftar).
  6. Pengawasan: Hak akses admin_cabang/owner_pusat pada log audit dilepas (kasir diizinkan mengintip log).

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0067.py
            python3 alat/uji-mutasi-0067.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0067_pengaman_voucher.sql")
# JEBAKAN "fungsi ditulis ulang": RPC `daftar_voucher` yang dua mutasi sundul
# ditulis ulang di 0089_voucher_wajib_identitas_terverifikasi.sql (PMB1-F-031). Mutasi
# harus menempel pada berkas BERLAKU, kalau tidak pagarnya-butak (mutasi "LOLOS").
MIGRASI_VOUCHER = os.path.join(REPO, "supabase", "migrations", "0089_voucher_wajib_identitas_terverifikasi.sql")
BERKAS_UJI = ["supabase/tes/pengaman_voucher.sql"]


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
        "Lapis 1: kuota klaim per pelanggan dilepas",
        "  if v_jumlah_voucher_pelanggan >= coalesce(v_kmp.kuota_per_pelanggan, 1) then",
        "  if false and v_jumlah_voucher_pelanggan >= coalesce(v_kmp.kuota_per_pelanggan, 1) then",
        MIGRASI_VOUCHER,
    ),
    (
        "Lapis 2: batas penukaran per cabang per hari dilepas",
        "    if v_pemakaian_hari_ini >= v_kampanye.kuota_harian_cabang then",
        "    if false and v_pemakaian_hari_ini >= v_kampanye.kuota_harian_cabang then",
        MIGRASI,
    ),
    (
        "Lapis 5: batas anggaran maksimal kampanye dilepas",
        "    if v_total_anggaran_terpakai + v_potongan > v_kampanye.anggaran_maks then",
        "    if false and v_total_anggaran_terpakai + v_potongan > v_kampanye.anggaran_maks then",
        MIGRASI,
    ),
    (
        "Lapis 8: rate limiting perangkat penyerang dilepas",
        "  if v_penyewa_id is not null and public.apakah_perangkat_terblokir(v_penyewa_id, p_perangkat, p_ip) then",
        "  if false and v_penyewa_id is not null then",
        MIGRASI,  # jangkar ini milik cek_voucher/pakai_voucher, bukan daftar_voucher
    ),
    (
        "Lapis 9: penolakan email sekali pakai dilepas",
        "    if public.apakah_email_sekali_pakai(p_email) then",
        "    if false and public.apakah_email_sekali_pakai(p_email) then",
        MIGRASI_VOUCHER,
    ),
    (
        "Pengawasan: hak akses log percobaan dilonggarkan ke kasir",
        "  if v_penyewa is null or v_peran not in ('owner_pusat', 'admin_cabang') then",
        "  if false then",
        MIGRASI,
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0067 (T8-12 — Pengaman Anti-Kecurangan Voucher 10 Lapis)")
    berkas_asli = {}
    for item in DAFTAR_MUTASI:
        b = item[3] if len(item) > 3 else MIGRASI
        if b not in berkas_asli:
            with open(b, "r", encoding="utf-8") as f:
                berkas_asli[b] = f.read()

    try:
        lulus, keluaran = jalankan_uji()
        if not lulus:
            print("GAGAL KONTROL AWAL: uji tidak hijau pada salinan utuh!")
            print(keluaran[-1500:])
            return 1
        print("  OK  kontrol: salinan utuh → " + " + ".join(BERKAS_UJI) + " hijau")

        for nomor, item in enumerate(DAFTAR_MUTASI, start=1):
            nama, asal, ganti = item[0], item[1], item[2]
            target = item[3] if len(item) > 3 else MIGRASI
            asli = berkas_asli[target]
            hasil = asli.replace(asal, ganti)
            if hasil == asli:
                print(f"  [X] Mutasi {nomor}: teks mutasi TIDAK MENEMPEL pada {os.path.basename(target)} — periksa jangkar!")
                return 1
            with open(target, "w", encoding="utf-8") as f:
                f.write(hasil)
            lulus, keluaran = jalankan_uji()
            with open(target, "w", encoding="utf-8") as f:
                f.write(asli)
            if lulus:
                print(f"  [X] Mutasi {nomor}: {nama} LOLOS (pagar tumpul!)")
                print(keluaran[-1500:])
                return 1
            print(f"  [OK] Mutasi {nomor}: {nama} TERBUKTI MERAH")

        print(
            f"\nHASIL: LOLOS — semua {len(DAFTAR_MUTASI)} mutasi WAJIB MERAH benar-benar merah; "
            "pagar Pengaman Anti-Kecurangan Voucher 10 Lapis (T8-12) terbukti tajam."
        )
        return 0
    finally:
        for b, konten in berkas_asli.items():
            with open(b, "w", encoding="utf-8") as f:
                f.write(konten)


def uji_diri():
    print("UJI DIRI penilai mutasi 0067")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()
    palsu = asli.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli:
        print("Uji diri gagal: penggantian tak terduga berhasil!")
        return 1
    print("  OK  uji-diri: mutasi sintetis tak menempel")
    print("UJI DIRI 0067 SELESAI — LOLOS")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uji-diri":
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
