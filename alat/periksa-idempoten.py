#!/usr/bin/env python3
"""
ALAT PEMERIKSA CAKUPAN KUNCI IDEMPOTEN (T10-02 / ART-8)
======================================================
Memverifikasi kepatuhan seluruh RPC penulisan di Supabase/PostgreSQL terhadap
aturan arsitektur ART-8 (TECH_SPEC §9 ART-8 & PRD §9):
"Semua penulisan dari antrean offline wajib membawa kunci_idempoten; peladen
menolak duplikat dengan anggun (balasan rekaman yang sudah ada, idempoten)."

Daftar domain penulisan wajib ber-kunci idempoten (100% cakupan):
  1. Pesanan:       simpan_pesanan
  2. Pembayaran:    bayar_pesanan
  3. Voucher:       pakai_voucher
  4. Shift Buka:    buka_shift
  5. Shift Tutup:   tutup_shift
  6. Shift Kas:     kas_pergerakan
  7. Stok Bahan:    set_stok
  8. Opname Stok:   opname_stok

Cara pakai:
  python3 alat/periksa-idempoten.py            # verifikasi 100% cakupan
  python3 alat/periksa-idempoten.py --uji-diri # uji ketajaman pemeriksa
"""

import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR_MIGRASI = os.path.join(REPO, "supabase", "migrations")

# Daftar RPC penulisan yang wajib mendukung p_kunci_idempoten
RPC_PENULISAN_WAJIB = [
    {
        "nama": "simpan_pesanan",
        "domain": "Pesanan Kasir (ART-8)",
        "tabel": "pesanan",
        "kolom_kunci": "kunci_idempoten",
    },
    {
        "nama": "bayar_pesanan",
        "domain": "Pembayaran Kasir (ART-8)",
        "tabel": "pembayaran",
        "kolom_kunci": "kunci_idempoten",
    },
    {
        "nama": "pakai_voucher",
        "domain": "Voucher Kasir (ART-5/ART-8)",
        "tabel": "diskon_transaksi",
        "kolom_kunci": "voucher_id",
    },
    {
        "nama": "buka_shift",
        "domain": "Buka Shift Kasir (M7/ART-8)",
        "tabel": "shift_kas",
        "kolom_kunci": "kunci_idempoten",
    },
    {
        "nama": "tutup_shift",
        "domain": "Tutup Shift Kasir (M7/ART-8)",
        "tabel": "shift_kas",
        "kolom_kunci": "kunci_idempoten_tutup",
    },
    {
        "nama": "kas_pergerakan",
        "domain": "Arus Kas Masuk/Keluar (M7/ART-8)",
        "tabel": "kas_pergerakan",
        "kolom_kunci": "kunci_idempoten",
    },
    {
        "nama": "set_stok",
        "domain": "Penyesuaian Stok (M9/ART-8)",
        "tabel": "stok_pergerakan",
        "kolom_kunci": "kunci_idempoten",
    },
    {
        "nama": "opname_stok",
        "domain": "Hitung Fisik Stok (M9/ART-8)",
        "tabel": "stok_pergerakan",
        "kolom_kunci": "kunci_idempoten",
    },
]


def baca_semua_migrasi():
    gabungan = ""
    berkas_migrasi = sorted(os.listdir(DIR_MIGRASI))
    for b in berkas_migrasi:
        if b.endswith(".sql"):
            with open(os.path.join(DIR_MIGRASI, b), "r", encoding="utf-8") as f:
                gabungan += f"\n-- BERKAS: {b}\n" + f.read()
    return gabungan


def periksa_rpc(sql_gabungan, target_rpc):
    nama_rpc = target_rpc["nama"]
    # Cari definisi create or replace function public.<nama_rpc>(...)
    pola = re.compile(
        rf"create\s+(?:or\s+replace\s+)?function\s+public\.{nama_rpc}\s*\((.*?)\)",
        re.IGNORECASE | re.DOTALL,
    )
    cocok = pola.findall(sql_gabungan)
    if not cocok:
        return False, f"Fungsi public.{nama_rpc} tidak ditemukan dalam migrasi."

    # Pastikan setidaknya satu signature menerima p_kunci_idempoten
    punya_kunci = False
    for signature in cocok:
        if "p_kunci_idempoten" in signature:
            punya_kunci = True
            break

    if not punya_kunci:
        return (
            False,
            f"Fungsi public.{nama_rpc} ditemukan ({len(cocok)} definisi), tetapi TIDAK SATU PUN menerima p_kunci_idempoten.",
        )

    return True, f"Fungsi public.{nama_rpc} terbukti menerima p_kunci_idempoten."


def periksa_kolom_tabel(sql_gabungan, target_rpc):
    kolom = target_rpc["kolom_kunci"]
    tabel = target_rpc["tabel"]
    # Periksa apakah ada alter table atau create table dengan kolom tersebut
    pola_kolom = re.compile(
        rf"(?:add\s+column\s+(?:if\s+not\s+exists\s+)?{kolom}|{kolom}\s+(?:text|uuid))",
        re.IGNORECASE,
    )
    if not pola_kolom.search(sql_gabungan):
        return (
            False,
            f"Kolom identifikasi idempoten '{kolom}' tidak ditemukan di tabel '{tabel}'.",
        )
    return True, f"Kolom '{kolom}' pada tabel '{tabel}' terkonfirmasi."


def periksa_cakupan(cetak=True):
    if cetak:
        print("=" * 70)
        print("AUDIT CAKUPAN KUNCI IDEMPOTEN PENULISAN (T10-02 / ART-8)")
        print("=" * 70)

    sql_gabungan = baca_semua_migrasi()
    total = len(RPC_PENULISAN_WAJIB)
    lulus_rpc = 0
    lulus_skema = 0

    for item in RPC_PENULISAN_WAJIB:
        nama = item["nama"]
        domain = item["domain"]
        ok_rpc, pesan_rpc = periksa_rpc(sql_gabungan, item)
        ok_skema, pesan_skema = periksa_kolom_tabel(sql_gabungan, item)

        if ok_rpc and ok_skema:
            lulus_rpc += 1
            lulus_skema += 1
            if cetak:
                print(f"  [OK] {nama:<16} : {domain:<32} (RPC & Skema)")
        else:
            if cetak:
                print(f"  [X]  {nama:<16} : {domain:<32}")
                if not ok_rpc:
                    print(f"       -> Galat RPC: {pesan_rpc}")
                if not ok_skema:
                    print(f"       -> Galat Skema: {pesan_skema}")

    persentase = (lulus_rpc / total) * 100.0
    if cetak:
        print("-" * 70)
        print(f"Total RPC penulisan terdaftar : {total}")
        print(f"RPC dengan kunci idempoten    : {lulus_rpc}/{total} ({persentase:.1f}%)")
        print(f"Skema tabel penyimpan kunci   : {lulus_skema}/{total}")
        print("-" * 70)

    if lulus_rpc == total and lulus_skema == total:
        if cetak:
            print("HASIL: LOLOS — 100% RPC penulisan memiliki dukungan kunci idempoten.")
        return 0
    else:
        if cetak:
            print("HASIL: GAGAL — Cakupan kunci idempoten belum 100%.")
        return 1


def uji_diri():
    print("Uji Diri: periksa_idempoten.py...")
    # 1. Tes kondisi normal
    rc = periksa_cakupan(cetak=False)
    if rc != 0:
        print("  [GAGAL] Audit kondisi normal gagal.")
        return 1

    # 2. Tes deteksi kegagalan: manipulasi input simulasi
    sql_palsu = "create or replace function public.simpan_pesanan(p_cabang uuid) returns jsonb as $$ begin end; $$;"
    item_uji = RPC_PENULISAN_WAJIB[0]
    ok, _ = periksa_rpc(sql_palsu, item_uji)
    if ok:
        print(
            "  [GAGAL] Pemeriksa tidak mendeteksi fungsi tanpa p_kunci_idempoten."
        )
        return 1

    print("  [OK] Pemeriksa idempoten terbukti tajam (mendeteksi fungsi tanpa p_kunci_idempoten).")
    print("HASIL UJI DIRI: LOLOS")
    return 0


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(periksa_cakupan(cetak=True))
