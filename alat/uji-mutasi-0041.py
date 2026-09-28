#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar T5-05 di `0041_diskon_pin_atasan.sql`:
"diskon di atas batas kasir boleh, TETAPI hanya dengan bukti PIN atasan yang sah,
dan hanya sampai batas atasan itu sendiri".

Pagar ini menaikkan hak seseorang, jadi justru di sinilah uji mutasi paling perlu:
kalau syaratnya dilonggarkan diam-diam, kasir bisa menyetujui diskonnya sendiri.

Mutasi yang wajib membuat `supabase/tes/diskon_pin_atasan.sql` MERAH:
  1. Bukti PIN tidak diperiksa — klaim `disetujui_oleh` saja cukup menaikkan batas
     (inilah celah terparah: kasir tinggal menulis nama atasannya)
  2. Kupon PIN tidak wajib terikat pesanan ini — PIN untuk pesanan lain bisa dipakai ulang
  3. Kupon yang SUDAH dipakai tetap diterima — satu PIN atasan jadi stempel tak terbatas
  4. Batas penyetuju tidak diperiksa — PIN atasan menjadi izin tanpa batas
  5. Izin penyetuju tidak diperiksa — orang tanpa hak beri_diskon jadi penyetuju sah
  6. Batas pengetik dilepas — kasir bisa memberi diskon besar tanpa atasan sama sekali

Verifikasi: python3 alat/uji-mutasi-0041.py            (6/6 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0041.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# Pagar picu_diskon_batas() dimutakhirkan di 0065 untuk mendukung voucher (T8-09).
# Definisi yang berlaku saat uji dijalankan adalah migrasi terakhir yang mendefinisikannya.
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0065_kasir_cek_pakai_voucher.sql")
# Dua berkas: yang pertama membuktikan jalur T5-05, yang kedua memastikan pagar
# lama (bukti persetujuan 0016) tidak ikut jebol saat batas dinaikkan.
BERKAS_UJI = ["supabase/tes/diskon_pin_atasan.sql", "supabase/tes/diskon_setuju.sql"]


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
        "bukti PIN tidak diperiksa — klaim disetujui_oleh saja menaikkan batas",
        "      if v_kupon is not null then",
        "      if true then",
    ),
    (
        "kupon PIN tidak wajib terikat pesanan ini",
        "         and pp.pesanan_id = new.pesanan_id\n         and pp.dipakai_pada is null",
        "         and pp.dipakai_pada is null",
    ),
    (
        "kupon yang sudah dipakai tetap diterima (sekali-pakai bocor)",
        "         and pp.dipakai_pada is null\n         and pp.waktu > now() - interval '5 minutes'",
        "         and pp.waktu > now() - interval '5 minutes'",
    ),
    (
        "batas penyetuju tidak diperiksa — PIN atasan jadi izin tanpa batas",
        "        select ie.boleh\n           and (ie.batas_nominal is null or new.nilai <= ie.batas_nominal)\n"
        "           and (ie.batas_persen  is null or v_persen  <= ie.batas_persen)\n          into v_boleh",
        "        select ie.boleh\n          into v_boleh",
    ),
    (
        "izin penyetuju tidak diperiksa — siapa pun bisa jadi penyetuju",
        "        select ie.boleh\n           and (ie.batas_nominal is null or new.nilai <= ie.batas_nominal)",
        "        select true\n           and (ie.batas_nominal is null or new.nilai <= ie.batas_nominal)",
    ),
    (
        "batas pengetik dilepas — kasir tidak butuh atasan sama sekali",
        "    v_boleh := public.boleh('beri_diskon', new.nilai, v_persen);",
        "    v_boleh := true;",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0041 (T5-05 — PIN atasan menaikkan batas diskon, sampai batas atasan)")
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
            "pagar persetujuan PIN atasan (T5-05) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0041")
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
