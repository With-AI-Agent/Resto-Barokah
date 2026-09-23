#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar diskon `picu_diskon_batas()`
(migrasi 0019_pesan_diskon_jujur.sql; cap kumulatif berasal dari 0014). Ini pagar
T5-04: "satu diskon per transaksi (bawaan) + opsi tumpuk DENGAN BATAS".

Mutasi yang wajib membuat `supabase/tes/diskon_tumpuk.sql` MERAH:
  1. Aturan "satu diskon per transaksi" dilepas (tumpuk selalu boleh)
  2. `tumpuk_diskon` dibaca terbalik (resto yang melarang justru mengizinkan)
  3. Cap PERSEN resto dihitung per baris, bukan kumulatif
     (inilah cacat asli PR-02: kasir memecah diskon jadi banyak baris kecil)
  4. Cap NOMINAL resto tidak pernah diperiksa
  5. Pagar "total diskon melebihi subtotal" dilepas (pesanan bisa minus)

Kalau salah satu mutasi TIDAK membuat uji merah, jaring pengamannya bocor dan
skrip ini GAGAL — lebih baik berisik daripada diam-diam tidak menguji apa pun.

Verifikasi: python3 alat/uji-mutasi-0019.py            (5/5 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0019.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# JEBAKAN "fungsi ditulis ulang" (lihat DECISIONS_LOG [Mutu gerbang/2026-09-23]):
# pagar-pagar ini hidup di `picu_diskon_batas()`, yang ditulis ULANG UTUH oleh
# `0041_diskon_pin_atasan.sql` (T5-05). Definisi yang benar-benar berlaku saat
# pemasangan adalah yang TERAKHIR, jadi memutasi salinan lama di 0019 tidak
# berpengaruh apa pun dan SEMUA mutasi terbaca "pagar tumpul" padahal pagarnya utuh.
# Setiap kali fungsi ini ditulis ulang lagi, konstanta di bawah WAJIB ikut pindah.
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0041_diskon_pin_atasan.sql")
BERKAS_UJI = "supabase/tes/diskon_tumpuk.sql"


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", BERKAS_UJI],
        cwd=REPO,
        capture_output=True,
        text=True,
    )
    keluaran = res.stdout + res.stderr
    return "uji: 1 LULUS · 0 GAGAL" in keluaran, keluaran


DAFTAR_MUTASI = [
    (
        "aturan satu diskon per transaksi dilepas",
        "      raise exception 'Resto ini hanya mengizinkan satu diskon per transaksi.';",
        "      null;   -- mutasi: diskon kedua dibiarkan lewat",
    ),
    (
        "tumpuk_diskon dibaca terbalik",
        "    if not coalesce(v_tumpuk, false) then",
        "    if coalesce(v_tumpuk, false) then",
    ),
    (
        "cap persen resto dihitung per baris, bukan kumulatif",
        "     and v_total::numeric * 100 > v_pesanan.subtotal::numeric * v_cap_persen then",
        "     and new.nilai::numeric * 100 > v_pesanan.subtotal::numeric * v_cap_persen then",
    ),
    (
        "cap nominal resto tidak pernah diperiksa",
        "  if v_cap_nominal is not null and v_total > v_cap_nominal then",
        "  if false then",
    ),
    (
        "pagar total diskon melebihi subtotal dilepas",
        "  if v_total > v_pesanan.subtotal then",
        "  if false then",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0019 (pagar diskon T5-04 — satu diskon, tumpuk berbatas, cap kumulatif)")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()

    try:
        lulus, keluaran = jalankan_uji()
        if not lulus:
            print(f"GAGAL KONTROL AWAL: {BERKAS_UJI} tidak lulus pada salinan utuh!")
            print(keluaran[-1500:])
            return 1
        print(f"  OK  kontrol: salinan utuh → {BERKAS_UJI} hijau")

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
            "pagar diskon T5-04 terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0019")
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
