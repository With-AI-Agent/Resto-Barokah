#!/usr/bin/env python3
"""
UJI MUTASI — membuktikan ketajaman pagar T5-12 di `0043_laporan_pembatalan.sql`:
"daftar pembatalan hanya boleh DIBACA pemegang izin `lihat_laporan`".

Kenapa perlu uji mutasi: pagar ini berupa satu baris `and public.boleh('lihat_laporan')`
di dalam policy. Baris sependek itu gampang hilang saat policy ditulis ulang di
migrasi berikutnya — dan kalau hilang, tidak ada yang meledak. Uji biasa tetap
hijau, layar tetap normal, dan celahnya baru ketahuan kalau ada yang iseng
memeriksa. Satu-satunya cara memastikan pagarnya benar-benar bekerja adalah
mencabutnya dengan sengaja dan memastikan uji berubah MERAH.

Yang dilindungi: daftar pembatalan memperlihatkan pegawai mana yang paling sering
membatalkan dan berapa kerugian yang ia timbulkan — data ketenagakerjaan yang
sensitif. Sebelum 0043, SIAPA PUN yang masuk bisa membacanya, termasuk pelayan
dan dapur yang izin `lihat_laporan`-nya tegas-tegas `false`.

Mutasi yang wajib membuat `supabase/tes/laporan_pembatalan.sql` MERAH:
  1. Syarat izin dicabut dari policy — persis keadaan SEBELUM 0043 (celahnya)
  2. Syarat izin diganti `true` — bentuk lain dari pencabutan yang terlihat lebih
     "tidak sengaja" saat membaca diff sekilas
  3. `security_invoker` dimatikan pada view — pagar RLS-nya utuh, tetapi view
     berjalan sebagai pemiliknya sehingga menjadi PINTU BELAKANG yang melewati
     policy. Ini jebakan klasik view di Postgres dan justru yang paling mudah
     terlewat saat meninjau kode.
  4. Izin yang diperiksa diganti dengan izin lain yang dimiliki semua peran
     (`void_sebelum_dapur`) — pagar "terlihat ada" tetapi tidak menyaring siapa pun

Verifikasi: python3 alat/uji-mutasi-0043.py            (4/4 mutasi wajib MERAH)
            python3 alat/uji-mutasi-0043.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0043_laporan_pembatalan.sql")
BERKAS_UJI = ["supabase/tes/laporan_pembatalan.sql"]


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
        "syarat izin dicabut dari policy (keadaan sebelum 0043 — celahnya)",
        "    and (select public.boleh('lihat_laporan'))\n",
        "",
    ),
    (
        "syarat izin diganti true — pagar ada di mata, tidak ada di kenyataan",
        "    and (select public.boleh('lihat_laporan'))",
        "    and true",
    ),
    (
        "security_invoker dimatikan — view jadi pintu belakang yang melewati RLS",
        "with (security_invoker = true) as",
        "with (security_invoker = false) as",
    ),
    (
        "izin yang diperiksa diganti izin yang dimiliki semua peran",
        "public.boleh('lihat_laporan')",
        "public.boleh('void_sebelum_dapur')",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0043 (T5-12 — daftar pembatalan hanya untuk pemegang lihat_laporan)")
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
            "pagar baca laporan pembatalan (T5-12) terbukti bekerja."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0043")
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
