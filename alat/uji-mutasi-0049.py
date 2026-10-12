#!/usr/bin/env python3
"""
UJI MUTASI 0049 — membuktikan ketajaman pagar T7-05 di `0049_pengingat_shift.sql`:
"pengingat shift belum ditutup, penanda & audit shift melewati tengah malam,
serta view laporan shift menggantung".

Mutasi yang wajib membuat `supabase/tes/pengingat_shift.sql` MERAH:
  1. Penanda shift melewati tengah malam dimatikan (selalu false)
  2. Pemicu tanggal berbeda pada shift_kas dinonaktifkan
  3. Catatan audit shift_melewati_tengah_malam ditiadakan
  4. View laporan_shift_menggantung tidak menyaring status shift terbuka
  5. View tingkat_peringatan melewati_tengah_malam dicabut
  6. View penanda melewati_tengah_malam dipalsukan selalu false

Verifikasi: python3 alat/uji-mutasi-0049.py
            python3 alat/uji-mutasi-0049.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0049_pengingat_shift.sql")
# JEBAKAN "fungsi ditulis ulang": penanda tengah malam di dalam `public.tutup_shift`
# (awalnya 0049, ditulis ulang 0084) kini berlaku lewat 0092_selisih_kas_negatif_tidak_
# didisembunyikan.sql (PMB1-F-046) — mutasi wajib menyasar definisi terakhir.
MIGRASI_TUTUP = os.path.join(REPO, "supabase", "migrations", "0092_selisih_kas_negatif_tidak_didisembunyikan.sql")
BERKAS_UJI = ["supabase/tes/pengingat_shift.sql"]


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
        "penanda shift melewati tengah malam dimatikan (selalu false)",
        "  if timezone('Asia/Jakarta', now())::date > timezone('Asia/Jakarta', v_shift.dibuka_pada)::date then\n    v_melewati_tengah_malam := true;\n  end if;",
        "  v_melewati_tengah_malam := false;",
        MIGRASI_TUTUP,
    ),
    (
        "pemicu tanggal berbeda pada shift_kas dinonaktifkan",
        "  if timezone('Asia/Jakarta', coalesce(new.ditutup_pada, now()))::date > timezone('Asia/Jakarta', new.dibuka_pada)::date then\n    new.melewati_tengah_malam := true;\n  end if;",
        "  null;",
        MIGRASI,
    ),
    (
        "catatan audit shift_melewati_tengah_malam ditiadakan",
        "  if v_melewati_tengah_malam then",
        "  if false and v_melewati_tengah_malam then",
        MIGRASI_TUTUP,
    ),
    (
        "view laporan_shift_menggantung tidak menyaring status shift terbuka",
        " where s.status = 'terbuka';",
        " where true;",
        MIGRASI,
    ),
    (
        "view tingkat_peringatan melewati_tengah_malam dicabut",
        "      when (s.melewati_tengah_malam or timezone('Asia/Jakarta', now())::date > timezone('Asia/Jakarta', s.dibuka_pada)::date) then 'melewati_tengah_malam'",
        "      when false then 'melewati_tengah_malam'",
        MIGRASI,
    ),
    (
        "view penanda melewati_tengah_malam dipalsukan selalu false",
        "    (s.melewati_tengah_malam or timezone('Asia/Jakarta', now())::date > timezone('Asia/Jakarta', s.dibuka_pada)::date) as melewati_tengah_malam,",
        "    false as melewati_tengah_malam,",
        MIGRASI,
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0049 (T7-05 — pengingat shift belum ditutup & penanda tengah malam)")
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
            nama = item[0]
            asal = item[1]
            ganti = item[2]
            target_berkas = item[3] if len(item) > 3 else MIGRASI
            asli = berkas_asli[target_berkas]

            hasil = asli.replace(asal, ganti)
            if hasil == asli:
                print(f"  [X] Mutasi {nomor}: teks mutasi TIDAK MENEMPEL pada berkas — periksa jangkar!")
                return 1
            with open(target_berkas, "w", encoding="utf-8") as f:
                f.write(hasil)
            lulus, keluaran = jalankan_uji()
            # Kembalikan segera sebelum mutasi berikutnya
            with open(target_berkas, "w", encoding="utf-8") as f:
                f.write(asli)

            if lulus:
                print(f"  [X] Mutasi {nomor}: {nama} LOLOS (pagar tumpul!)")
                print(keluaran[-1500:])
                return 1
            print(f"  [OK] Mutasi {nomor}: {nama} TERBUKTI MERAH")

        print(
            f"\nHASIL: LOLOS — semua {len(DAFTAR_MUTASI)} mutasi WAJIB MERAH benar-benar merah; "
            "pagar pengingat shift belum ditutup (T7-05) terbukti bekerja."
        )
        return 0
    finally:
        for b, konten in berkas_asli.items():
            with open(b, "w", encoding="utf-8") as f:
                f.write(konten)


def uji_diri():
    print("UJI DIRI penilai mutasi 0049")
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
