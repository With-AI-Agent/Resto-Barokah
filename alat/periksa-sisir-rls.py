#!/usr/bin/env python3
"""
ALAT PEMERIKSA SISIR RLS AKHIR SELURUH TABEL (T10-05 / ART-1)
=============================================================
Memverifikasi kepatuhan seluruh tabel pada skema PostgreSQL public
terhadap aturan arsitektur ART-1 (TECH_SPEC §9 ART-1 & PRD M12):
"100% tabel di skema public wajib mengaktifkan Row Level Security (RLS)
dan memiliki kebijakan (policy) resmi terdaftar. Nol tabel terbuka."

Memeriksa secara dinamis lewat katalog PostgreSQL asli:
  1. 100% tabel mengaktifkan relrowsecurity (0 tabel tanpa RLS).
  2. 100% tabel memiliki pg_policy terpasang (0 tabel tanpa policy).
  3. Seluruh tabel ber-penyewa_id terikat isolasi penyewa_saya() atau deny-all.
  4. Seluruh tabel tanpa penyewa_id memiliki rantai jangkar yang sah.
  5. Integritas fungsi perantara isolasi terjaga.
  6. Matriks isolasi multi-tenant & hak akses 6 peran teruji fail-closed:
     - pemilik_platform (default 0 data penyewa)
     - owner_pusat (terisolasi penuh ke restonya)
     - admin_cabang (terisolasi ke restonya)
     - kasir (terisolasi ke restonya, dilarang ubah pengaturan/hapus audit)
     - pelayan (terisolasi ke restonya)
     - dapur (terisolasi ke restonya)
     - kasir resto lain (terisolasi dari resto lawan)

Cara pakai:
  python3 alat/periksa-sisir-rls.py            # verifikasi penuh
  python3 alat/periksa-sisir-rls.py --uji-diri # uji ketajaman pagar
"""

from __future__ import annotations

import argparse
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

AKAR = Path(__file__).resolve().parent.parent
BERKAS_TES = "supabase/tes/sisir_rls_akhir.sql"


def migrasi_terakhir() -> str:
    mig_dir = AKAR / "supabase" / "migrations"
    migs = sorted([f.name for f in mig_dir.glob("*.sql")])
    return f"supabase/migrations/{migs[-1]}"


MIGRASI_AKHIR = migrasi_terakhir()


def jalankan_tes(akar: Path) -> subprocess.CompletedProcess:
    return subprocess.run(
        ["node", "alat/uji-sql.mjs", "--daftar", BERKAS_TES],
        cwd=akar,
        capture_output=True,
        text=True,
        timeout=120,
    )


def periksa_sisir(cetak: bool = True) -> int:
    if cetak:
        print("=" * 70)
        print("AUDIT PENYISIRAN RLS SELURUH TABEL (T10-05 / ART-1 / PRD M12)")
        print("=" * 70)

    r = jalankan_tes(AKAR)
    keluaran = r.stdout + r.stderr

    if r.returncode != 0:
        if cetak:
            print("  [GAGAL] Eksekusi tes SQL sisir_rls_akhir gagal:")
            print(keluaran)
        return 1

    # Pola entri tabel dari --daftar:
    #   cabang                 RLS=ya   policy= 3  penyewa_id=ya
    pola_tabel = re.compile(
        r"^\s{2}([a-z_0-9]+)\s+RLS=(ya|tidak)\s+policy=\s*(\d+)\s+penyewa_id=(ya|tidak)",
        re.MULTILINE,
    )
    cocok = pola_tabel.findall(keluaran)

    if not cocok:
        if cetak:
            print("  [GAGAL] Tidak dapat menemukan daftar tabel dari keluaran katalog.")
        return 1

    total_tabel = len(cocok)
    tabel_tanpa_rls = 0
    tabel_tanpa_policy = 0

    for nama, rls, pol, penyewa in cocok:
        pol_count = int(pol)
        if rls != "ya":
            tabel_tanpa_rls += 1
            if cetak:
                print(f"  [X] {nama:<25}: RLS TIDAK AKTIF")
        elif pol_count == 0:
            tabel_tanpa_policy += 1
            if cetak:
                print(f"  [X] {nama:<25}: 0 POLICY")
        else:
            if cetak:
                print(
                    f"  [OK] {nama:<25}: RLS=ya | Policy={pol_count:<2} | penyewa_id={penyewa}"
                )

    lulus_eksekusi = "LULUS supabase/tes/sisir_rls_akhir.sql" in keluaran
    lulus_akhir = "HASIL: LOLOS" in keluaran

    if cetak:
        print("-" * 70)
        print(f"Total tabel publik diperiksa : {total_tabel}")
        print(f"Tabel dengan RLS aktif       : {total_tabel - tabel_tanpa_rls}/{total_tabel}")
        print(f"Tabel tanpa RLS (terbuka)    : {tabel_tanpa_rls}")
        print(f"Tabel dengan policy terpasang: {total_tabel - tabel_tanpa_policy}/{total_tabel}")
        print(f"Tabel tanpa policy           : {tabel_tanpa_policy}")
        print(f"Eksekusi uji sisir SQL       : {'LULUS' if lulus_eksekusi else 'GAGAL'}")
        print("-" * 70)

    if (
        tabel_tanpa_rls == 0
        and tabel_tanpa_policy == 0
        and lulus_eksekusi
        and lulus_akhir
        and total_tabel >= 45
    ):
        if cetak:
            print("LAPORAN AKHIR: 0 TABEL TANPA POLICY — 0 TABEL TERBUKA")
            print("HASIL: LOLOS — Seluruh 45 tabel terisolasi 100% secara fail-closed.")
        return 0
    else:
        if cetak:
            print("HASIL: GAGAL — Ditemukan tabel tanpa RLS atau tanpa policy.")
        return 1


def uji_diri() -> int:
    print("=" * 70)
    print("UJI DIRI: periksa-sisir-rls.py (Ketajaman Deteksi RLS Bocor)")
    print("=" * 70)

    # 1. Kontrol awal: basis data sah wajib hijau
    rc = periksa_sisir(cetak=False)
    if rc != 0:
        print("  [GAGAL] Kontrol awal gagal.")
        return 1
    print("  [OK] Kontrol awal: LOLOS (0 tabel terbuka, 0 tanpa policy).")

    mutasi = [
        (
            "Tabel baru tanpa RLS (terbuka langsung)",
            "create table public.tabel_bocor_uji (id int);",
            "BELUM mengaktifkan RLS",
        ),
        (
            "Tabel baru dengan RLS tapi tanpa policy (terkunci buta)",
            "create table public.tabel_buta_uji (id int); alter table public.tabel_buta_uji enable row level security;",
            "tidak punya policy sama sekali",
        ),
        (
            "Tabel baru tanpa penyewa_id dan tidak terdaftar jangkar",
            "create table public.tabel_liar_uji (id int); alter table public.tabel_liar_uji enable row level security; create policy liar_pilih on public.tabel_liar_uji for select to authenticated using (true);",
            "tidak punya penyewa_id DAN tidak terdaftar rantainya",
        ),
        (
            "Tabel dengan penyewa_id tapi policy terbuka tanpa penyewa_saya()",
            "create table public.tabel_bocor_tenant (id int, penyewa_id uuid); alter table public.tabel_bocor_tenant enable row level security; create policy bocor_pilih on public.tabel_bocor_tenant for select to authenticated using (true);",
            "tidak menyaring penyewa_saya()",
        ),
    ]

    with tempfile.TemporaryDirectory(prefix="sisir-rls-") as tmp:
        root = Path(tmp)
        for folder in ("supabase/migrations", "supabase/tes", "alat/sql"):
            shutil.copytree(AKAR / folder, root / folder)
        shutil.copy2(AKAR / "alat/uji-sql.mjs", root / "alat/uji-sql.mjs")
        (root / "alat/node_modules").symlink_to(AKAR / "alat/node_modules")

        asli = (root / MIGRASI_AKHIR).read_text(encoding="utf-8")

        for nama, sql_tambahan, pola_error in mutasi:
            (root / MIGRASI_AKHIR).write_text(
                asli + "\n\n" + sql_tambahan, encoding="utf-8"
            )
            r = jalankan_tes(root)
            keluaran = r.stdout + r.stderr

            if r.returncode != 0 and pola_error in keluaran:
                print(f"  [OK] Mutasi tertangkap: {nama}")
            else:
                print(f"  [GAGAL] Mutasi TIDAK tertangkap: {nama}")
                print(f"          Keluaran: {keluaran[:300]}")
                return 1

    print("-" * 70)
    print("HASIL UJI DIRI: LOLOS — Semua mutasi kebocoran RLS tertangkap tegas.")
    print("-" * 70)
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--uji-diri",
        action="store_true",
        help="Jalankan pengujian mutasi untuk membuktikan ketajaman deteksi",
    )
    args = parser.parse_args()

    if args.uji_diri:
        return uji_diri()
    return periksa_sisir(cetak=True)


if __name__ == "__main__":
    sys.exit(main())
