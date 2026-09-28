#!/usr/bin/env python3
"""G3 A-F02: mutasi pagar identitas kosong.

Kontrol harus hijau. Jika helper kepercayaan dibuat selalu benar, regresi
lintas-tenant harus merah karena asersi akses, bukan karena runner rusak.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi

AKAR = Path(__file__).resolve().parent.parent
MIG = 'supabase/migrations/0025_isolasi_identitas_null.sql'
UJI = 'supabase/tes/isolasi_null_identitas.sql'
MUTASI_BYPASS = """
-- Mutasi: semua sesi dianggap jalur peladen. Ini hanya salinan uji.
create or replace function public.jalur_peladen_terverifikasi()
returns boolean language sql stable set search_path = public, pg_temp
as $$ select true $$;
"""


def main() -> int:
    asli = (AKAR / MIG).read_text(encoding='utf-8')
    kasus = [
        ('kontrol utuh', asli, HIJAU),
        ('helper identitas dibuka', asli + MUTASI_BYPASS, MERAH_PAGAR),
        ('SQL rusak bukan bukti', asli + '\nBUKAN SQL;', RUSAK),
        ('kontrol pulih', asli, HIJAU),
    ]
    gagal = 0
    with tempfile.TemporaryDirectory(prefix='mutasi-0025-') as tmp:
        root = Path(tmp)
        for folder in ('supabase/migrations', 'supabase/tes', 'alat/sql'):
            shutil.copytree(AKAR / folder, root / folder)
        shutil.copy2(AKAR / 'alat/uji-sql.mjs', root / 'alat/uji-sql.mjs')
        (root / 'alat/node_modules').symlink_to(AKAR / 'alat/node_modules')
        for nama, teks, harap in kasus:
            (root / MIG).write_text(teks, encoding='utf-8')
            hasil = subprocess.run(
                ['node', 'alat/uji-sql.mjs', UJI],
                cwd=root, capture_output=True, text=True, timeout=120,
            )
            jenis, sebab = klasifikasi(hasil.returncode, hasil.stdout + hasil.stderr)
            ok = jenis == harap and (
                harap != MERAH_PAGAR or 'HARAPAN TIDAK TERPENUHI' in sebab
            )
            gagal += int(not ok)
            print(f"{'OK' if ok else 'GAGAL'} {nama}: {jenis} {sebab}")
    print(
        f'HASIL: {"LOLOS" if not gagal else "GAGAL"} — '
        f'helper bypass, kontrol+pulih, salinan rusak ditolak; {gagal} tidak sesuai.'
    )
    return int(bool(gagal))


if __name__ == '__main__':
    raise SystemExit(main())
