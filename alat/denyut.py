#!/usr/bin/env python3
"""
ALAT DENYUT HARIAN & PEMBERSIH DATA SEMENTARA (T10-08)
======================================================
Referensi:
  - TECH_SPEC §1 (pg_cron) & §10 (Batas Gratis Supabase 500 MB & Anti-Tidur)
  - PRD M12 (Kasus Tepi & Pembersihan Rutin)

Fungsi:
  1. Denyut Harian: memicu aktivitas ringan database agar proyek gratis tidak
     tertidur (inactivity pause 7 hari pada Supabase gratis).
  2. Pembersih Data Sementara: membersihkan data percobaan lama, kode kadaluwarsa,
     dan sesi usang dengan masa retensi tertentu (bawaan 30 hari).
  3. Mitigasi Keamanan: DAFTAR TABEL YANG BOLEH DIBERSIHKAN DITULIS EKSPLISIT.
     Tabel inti keuangan, pesanan, pembayaran, audit, dan stok DILARANG disentuh.

Cara Pakai:
  python3 alat/denyut.py --denyut
  python3 alat/denyut.py --bersihkan [--hari 30]
  python3 alat/denyut.py --semua
  python3 alat/denyut.py --log [--limit 20]
  python3 alat/denyut.py --simulasi-2-hari
  python3 alat/denyut.py --uji-diri
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
EKSEKUTOR_NODE = os.path.join(REPO, "alat", "eksekusi-denyut.mjs")

# -----------------------------------------------------------------------------
# DAFTAR TABEL EKSPLISIT (MITIGASI RISIKO DoD T10-08)
# -----------------------------------------------------------------------------
# Hanya tabel di daftar ini yang boleh dibersihkan oleh prosedur pembersih:
TABEL_SEMENTARA_DIIZINKAN = [
    "percobaan_pin",
    "percobaan_simpan_pin",
    "percobaan_masuk",
    "voucher_percobaan",
    "kode_pendaftaran_perangkat",
    "pemulihan_perangkat",
    "sesi_perangkat",
    "mode_dukungan",
    "log_jadwal",
]

# Tabel inti berikut DILARANG KERAS disentuh oleh pembersih data sementara:
TABEL_INTI_DILARANG = [
    "penyewa",
    "cabang",
    "pengguna",
    "pengaturan",
    "kategori_menu",
    "menu_item",
    "menu_varian",
    "menu_tambahan",
    "menu_cabang",
    "meja",
    "pesanan",
    "pesanan_item",
    "pembayaran",
    "diskon_transaksi",
    "pembatalan",
    "shift_kas",
    "kas_pergerakan",
    "koreksi_modal_shift",
    "stok_bahan",
    "stok_pergerakan",
    "pelanggan",
    "kampanye_voucher",
    "voucher",
    "catatan_audit",
    "perangkat",
    "kredensial_pin",
    "kredensial_perangkat",
    "kredensial_pemulihan",
]


def validasi_daftar_tabel() -> tuple[bool, str]:
    """Memverifikasi bahwa tabel sementara dan tabel inti tidak tumpang tindih."""
    irisan = set(TABEL_SEMENTARA_DIIZINKAN).intersection(set(TABEL_INTI_DILARANG))
    if irisan:
        return False, f"Konflik izin: tabel inti masuk daftar sementara: {irisan}"
    return True, "Daftar putih tabel sementara aman & terisolasi."


def jalankan_node(args: list[str]) -> tuple[int, dict | list | str]:
    """Menjalankan alat bantu node eksekusi-denyut.mjs."""
    perintah = ["node", EKSEKUTOR_NODE] + args
    res = subprocess.run(
        perintah,
        cwd=REPO,
        capture_output=True,
        text=True,
    )
    if res.returncode != 0:
        return res.returncode, res.stderr or res.stdout

    try:
        data = json.loads(res.stdout)
        return 0, data
    except Exception:
        return 0, res.stdout


def jalankan_denyut() -> int:
    print("Memulai denyut harian sistem...")
    rc, data = jalankan_node(["--denyut"])
    if rc != 0:
        print(f"[GAGAL] Denyut harian gagal: {data}")
        return 1

    print("  [OK] Denyut harian berhasil.")
    print(f"       Waktu        : {data.get('waktu')}")
    print(f"       Penyewa Aktif: {data.get('penyewa_aktif')}")
    print(f"       Cabang Aktif : {data.get('cabang_aktif')}")
    print(f"       Log ID       : {data.get('log_id')}")
    return 0


def jalankan_bersihkan(hari: int = 30) -> int:
    print(f"Memulai pembersihan data sementara (retensi: {hari} hari)...")
    if hari < 1 or hari > 365:
        print(f"[GAGAL] Hari retensi harus antara 1 s/d 365 hari (diberikan: {hari})")
        return 1

    rc, data = jalankan_node(["--bersihkan", str(hari)])
    if rc != 0:
        print(f"[GAGAL] Pembersihan data sementara gagal: {data}")
        return 1

    dibersihkan = data.get("dibersihkan", {})
    total = data.get("total_baris_dibersihkan", 0)
    print("  [OK] Pembersihan data sementara berhasil.")
    print(f"       Total baris dibersihkan: {total}")
    print(f"       Percobaan PIN lama     : {dibersihkan.get('percobaan_pin', 0)}")
    print(f"       Percobaan Masuk lama   : {dibersihkan.get('percobaan_masuk', 0)}")
    print(f"       Voucher Percobaan lama : {dibersihkan.get('voucher_percobaan', 0)}")
    print(f"       Kode Perangkat usang   : {dibersihkan.get('kode_pendaftaran_kadaluwarsa', 0)}")
    print(f"       Sesi usang             : {dibersihkan.get('sesi_diakhiri_kadaluwarsa', 0)}")
    print(f"       Mode Dukungan expired  : {dibersihkan.get('mode_dukungan_dinonaktifkan', 0)}")
    print(f"       Log ID                 : {data.get('log_id')}")
    return 0


def tampilkan_log(limit: int = 20) -> int:
    print(f"Mengambil riwayat log jadwal (maks: {limit})...")
    rc, data = jalankan_node(["--log", str(limit)])
    if rc != 0:
        print(f"[GAGAL] Ambil log jadwal gagal: {data}")
        return 1

    daftar = data.get("data", [])
    print(f"Ditemukan {len(daftar)} entri log:")
    print("-" * 75)
    print(f"{'Waktu':<25} | {'Jenis':<12} | {'Status':<8} | {'Pesan'}")
    print("-" * 75)
    for entri in daftar:
        waktu = entri.get("dimulai_pada", "")[:19].replace("T", " ")
        jenis = entri.get("jenis", "")
        status = "SUKSES" if entri.get("sukses") else "GAGAL"
        pesan = entri.get("pesan", "")
        print(f"{waktu:<25} | {jenis:<12} | {status:<8} | {pesan}")
    print("-" * 75)
    return 0


def jalankan_simulasi_2_hari() -> int:
    print("=" * 75)
    print("VERIFIKASI SIMULASI JADWAL 2 HARI (DoD T10-08)")
    print("=" * 75)
    rc, data = jalankan_node(["--simulasi-2-hari"])
    if rc != 0:
        print(f"[GAGAL] Simulasi 2 hari gagal: {data}")
        return 1

    h1 = data.get("hari_1", {})
    h2 = data.get("hari_2", {})
    logs = data.get("log_tercatat", [])

    print("\nHari ke-1:")
    print(f"  - Denyut pagi      : {'SUKSES' if h1.get('denyut', {}).get('berhasil') else 'GAGAL'}")
    print(f"  - Pembersihan malam: {'SUKSES' if h1.get('pembersihan', {}).get('berhasil') else 'GAGAL'} "
          f"({h1.get('pembersihan', {}).get('total_baris_dibersihkan', 0)} baris)")

    print("\nHari ke-2:")
    print(f"  - Denyut pagi      : {'SUKSES' if h2.get('denyut', {}).get('berhasil') else 'GAGAL'}")
    print(f"  - Pembersihan malam: {'SUKSES' if h2.get('pembersihan', {}).get('berhasil') else 'GAGAL'} "
          f"({h2.get('pembersihan', {}).get('total_baris_dibersihkan', 0)} baris)")

    print(f"\nVerifikasi Log Terjadwal ({len(logs)} tercatat):")
    for l in logs:
        print(f"  [{l.get('jenis').upper()}] {l.get('dimulai_pada')[:19]} — {l.get('pesan')}")

    if len(logs) >= 4:
        print("\nHASIL: LOLOS — Seluruh tugas terjadwal 2 hari terbukti berjalan & tercatat.")
        return 0
    else:
        print("\nHASIL: GAGAL — Log terjadwal kurang dari 4 eksekusi.")
        return 1


def uji_diri() -> int:
    print("Memulai Uji Diri: alat/denyut.py...")
    # 1. Validasi daftar tabel
    ok, pesan = validasi_daftar_tabel()
    if not ok:
        print(f"  [GAGAL] {pesan}")
        return 1
    print("  [OK] Validasi daftar tabel putih & daftar tabel terlarang lolos.")

    # 2. Uji coba pemicuan tidak sah / retensi salah
    if jalankan_bersihkan(0) == 0:
        print("  [GAGAL] Retensi 0 hari seharusnya ditolak.")
        return 1
    print("  [OK] Proteksi retensi minimum 1 hari terbukti menolak nilai 0.")

    # 3. Uji simulasi eksekutor
    rc, data = jalankan_node(["--denyut"])
    if rc != 0 or not isinstance(data, dict) or not data.get("berhasil"):
        print("  [GAGAL] Uji denyut lokal gagal.")
        return 1
    print("  [OK] Panggilan denyut harian lokal berhasil.")

    print("\nHASIL UJI DIRI: LOLOS")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Denyut Harian & Pembersih Data Sementara (T10-08)")
    parser.add_argument("--denyut", action="store_true", help="Jalankan denyut harian anti-tidur")
    parser.add_argument("--bersihkan", action="store_true", help="Jalankan pembersih data sementara")
    parser.add_argument("--hari", type=int, default=30, help="Hari retensi pembersihan (bawaan: 30)")
    parser.add_argument("--semua", action="store_true", help="Jalankan denyut dan pembersihan sekaligus")
    parser.add_argument("--log", action="store_true", help="Tampilkan riwayat log jadwal")
    parser.add_argument("--limit", type=int, default=20, help="Batas jumlah log yang diambil")
    parser.add_argument("--simulasi-2-hari", "--verifikasi", action="store_true", help="Simulasi & verifikasi log 2 hari")
    parser.add_argument("--uji-diri", action="store_true", help="Uji diri ketajaman skrip denyut.py")

    args = parser.parse_args()

    if args.uji_diri:
        return uji_diri()
    elif args.simulasi_2_hari:
        return jalankan_simulasi_2_hari()
    elif args.log:
        return tampilkan_log(args.limit)
    elif args.semua:
        r1 = jalankan_denyut()
        r2 = jalankan_bersihkan(args.hari)
        return 0 if (r1 == 0 and r2 == 0) else 1
    elif args.denyut:
        return jalankan_denyut()
    elif args.bersihkan:
        return jalankan_bersihkan(args.hari)
    else:
        # Default bila tanpa argumen: jalankan simulasi 2 hari
        return jalankan_simulasi_2_hari()


if __name__ == "__main__":
    sys.exit(main())
