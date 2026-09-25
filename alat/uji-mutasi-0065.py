#!/usr/bin/env python3
"""
UJI MUTASI 0065 — membuktikan ketajaman pagar layar kasir: Cek (baca saja) & Pakai (atomik + PIN) Voucher (T8-09).

Mutasi yang WAJIB membuat `supabase/tes/kasir_voucher.sql` MERAH:
  1. PIN kasir tidak divalidasi (PIN salah diloloskan).
  2. Status voucher tidak diubah ke 'terpakai' (voucher tidak dikonsumsi / rentan dobel klaim).
  3. Cek voucher mengubah status voucher (merusak jaminan baca-saja).
  4. Pengecekan larangan tumpuk diskon dimatikan (multi-diskon lolos).
  5. Plafon batas maksimal potongan diabaikan pada kalkulasi diskon cek_voucher.

Kontrol positif: salinan utuh hijau.

Verifikasi: python3 alat/uji-mutasi-0065.py
            python3 alat/uji-mutasi-0065.py --uji-diri
"""
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MIGRASI = os.path.join(REPO, "supabase", "migrations", "0065_kasir_cek_pakai_voucher.sql")
BERKAS_UJI = ["supabase/tes/kasir_voucher.sql"]


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
        "PIN kasir tidak divalidasi (PIN salah diloloskan)",
        "if p_pin_kasir is null or p_pin_kasir = '' or crypt(p_pin_kasir, v_kasir.pin_hash) is distinct from v_kasir.pin_hash then",
        "if false and (p_pin_kasir is null or p_pin_kasir = '') then",
    ),
    (
        "status voucher tidak diubah ke terpakai (voucher tidak terkonsumsi)",
        "update public.voucher\n     set status = 'terpakai',",
        "update public.voucher\n     set status = 'aktif',",
    ),
    (
        "cek voucher mengubah status voucher (merusak jaminan baca-saja)",
        "insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, kasir_id, cabang_id, waktu)\n  values (v_voucher.penyewa_id, v_kode, 'cek_sah', auth.uid(), p_cabang_id, now());",
        "update public.voucher set status = 'terpakai' where id = v_voucher.id;\n  insert into public.voucher_percobaan (penyewa_id, kode_dicoba, hasil, kasir_id, cabang_id, waktu)\n  values (v_voucher.penyewa_id, v_kode, 'cek_sah', auth.uid(), p_cabang_id, now());",
    ),
    (
        "pengecekan larangan tumpuk diskon dimatikan",
        "if not coalesce(v_tumpuk, false) and exists (\n    select 1 from public.diskon_transaksi where pesanan_id = p_pesanan_id\n  ) then",
        "if false and exists (\n    select 1 from public.diskon_transaksi where pesanan_id = p_pesanan_id\n  ) then",
    ),
    (
        "plafon batas maksimal potongan diabaikan pada kalkulasi estimasi",
        "if v_kampanye.maks_potongan is not null and v_estimasi_potongan > v_kampanye.maks_potongan then\n        v_estimasi_potongan := v_kampanye.maks_potongan;\n      end if;",
        "if false and v_kampanye.maks_potongan is not null then\n        v_estimasi_potongan := v_kampanye.maks_potongan;\n      end if;",
    ),
]


def uji_mutasi():
    print("UJI MUTASI 0065 (T8-09 — Layar Kasir: Cek & Pakai Voucher)")
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
            "pagar Cek (baca saja) & Pakai (atomik + PIN) Voucher (T8-09) terbukti tajam."
        )
        return 0
    finally:
        with open(MIGRASI, "w", encoding="utf-8") as f:
            f.write(asli)


def uji_diri():
    print("UJI DIRI penilai mutasi 0065")
    with open(MIGRASI, "r", encoding="utf-8") as f:
        asli = f.read()
    palsu = asli.replace("jangkar-yang-tidak-akan-ada-xyz", "rusak")
    if palsu != asli:
        print("Uji diri gagal: penggantian tak terduga berhasil!")
        return 1
    print("  OK  uji-diri: mutasi sintetis tak menempel")
    print("UJI DIRI 0065 SELESAI — LOLOS")
    return 0


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--uji-diri":
        sys.exit(uji_diri())
    sys.exit(uji_mutasi())
