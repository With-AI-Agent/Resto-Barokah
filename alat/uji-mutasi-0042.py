#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar T5-07 di `0042_bahan_terbuang_jujur.sql`:
"penanda bahan terbuang ditentukan PELADEN dari tahap pembatalan, bukan dititipkan
perangkat kasir".

Kenapa perlu uji mutasi: kolom `bahan_terbuang` adalah SATU-SATUNYA penanda yang
memisahkan "pembatalan biasa" dari "kerugian bahan" di laporan. Kalau pagarnya
dilonggarkan diam-diam, kasir bisa membatalkan pesanan yang sudah dimasak lalu
menandainya "tidak ada bahan terbuang" — kerugiannya lenyap dari laporan pemilik
selamanya (tabelnya append-only).

Mutasi yang wajib membuat `supabase/tes/bahan_terbuang.sql` MERAH:
  1. Penanda kiriman klien diterima apa adanya (pagar dicabut total) — inilah
     keadaan SEBELUM 0042, dan inilah celah yang paling mahal
  2. Penanda selalu false — semua kerugian bahan hilang dari laporan
  3. Penanda selalu true — laporan kerugian dipompa oleh pembatalan pra-dapur
  4. Penolakan kiriman `true` pada pembatalan pra-dapur dilepas (hanya ditimpa
     diam-diam) — perangkat yang salah paham tidak pernah dikoreksi

Verifikasi: python3 alat/uji-mutasi-0042.py            (4/4 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0042.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0042_bahan_terbuang_jujur.sql")
# Tiga berkas: yang pertama membuktikan jalur T5-07, dua lainnya memastikan pagar
# pembatalan yang lama (nilai kerugian, sekali-batal, bukti PIN) tidak ikut jebol
# karena fungsi `picu_pembatalan_sah()` ditulis ulang utuh di 0042.
BERKAS_UJI = [
    "supabase/tes/bahan_terbuang.sql",
    "supabase/tes/persetujuan_void.sql",
    "supabase/tes/nilai_kerugian.sql",
]


def jalankan_uji():
    res = subprocess.run(
        ["node", "alat/uji-sql.mjs", *BERKAS_UJI],
        cwd=REPO,
        capture_output=True,
        text=True,
    )
    keluaran = res.stdout + res.stderr
    return f"uji: {len(BERKAS_UJI)} LULUS · 0 GAGAL" in keluaran, keluaran


DAFTAR_MUTASI = [
    (
        "penanda kiriman klien diterima apa adanya (keadaan sebelum 0042)",
        "  new.bahan_terbuang := v_terbuang;",
        "  new.bahan_terbuang := new.bahan_terbuang;",
    ),
    (
        "penanda selalu false — semua kerugian bahan hilang dari laporan",
        "  v_terbuang := (new.tahap = 'sesudah_dapur');",
        "  v_terbuang := false;",
    ),
    (
        "penanda selalu true — laporan kerugian dipompa pembatalan pra-dapur",
        "  v_terbuang := (new.tahap = 'sesudah_dapur');",
        "  v_terbuang := true;",
    ),
    (
        "penolakan kiriman bertentangan dilepas — perangkat salah tidak dikoreksi",
        "  if new.bahan_terbuang and not v_terbuang then",
        "  if false then",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0042 (T5-07 — bahan terbuang ditentukan peladen, bukan klien)")
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
            "pagar penanda bahan terbuang (T5-07) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0042")
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
