#!/usr/bin/env python3
"""T1-30 (bagian efektif): ACL/search_path fungsi istimewa + sapuan RLS.

Jalankan semua migrasi di DB sementara, lalu baca katalog PostgreSQL asli.
Tidak percaya regex CREATE pertama, komentar REVOKE, atau grant yang sudah
DITIMPA migrasi lebih baru. Ini pemeriksa skema efektif, bukan parser statis.
Sisa T1-30: analisis AST initplan SELECT pada setiap pemanggilan helper policy;
tidak diklaim di sini. Rahasia + npm audit tetap gerbang tersendiri yang wajib.

--uji-diri membuktikan setiap aturan bisa merah pada SALINAN, dan setup rusak
tidak dihitung sebagai bukti. Tidak menyentuh database Supabase atau sumber.
"""
from __future__ import annotations

import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi

AKAR = Path(__file__).resolve().parent.parent
TES = ['supabase/tes/keamanan_fungsi.sql', 'supabase/tes/rls_semua_tabel.sql']
MIG = 'supabase/migrations/0023_acl_fungsi_pemicu.sql'


def jalankan(akar: Path) -> subprocess.CompletedProcess:
    return subprocess.run(['node', 'alat/uji-sql.mjs', *TES], cwd=akar,
                          capture_output=True, text=True, timeout=120)


def uji_diri() -> int:
    mutasi = [
        ('path dilepas dari definisi terakhir',
         'alter function public.penyewa_saya() reset search_path;', 'T130-path', MERAH_PAGAR),
        ('path berisi schema tak dipercaya',
         "alter function public.penyewa_saya() set search_path to '$user',public,pg_temp;", 'T130-path', MERAH_PAGAR),
        ('EXECUTE PUBLIC dibuka ulang',
         'grant execute on function public.penyewa_saya() to public;', 'T130-public', MERAH_PAGAR),
        ('fungsi baru mewarisi ACL default PUBLIC',
         "create function public.uji_acl_bocor() returns int language sql security definer set search_path=public,pg_temp as $$ select 1 $$;", 'T130-public', MERAH_PAGAR),
        ('komentar REVOKE bukan pencabutan hak',
         'grant execute on function public.penyewa_saya() to public;\n-- revoke all on function public.penyewa_saya() from public;', 'T130-public', MERAH_PAGAR),
        ('trigger menjadi RPC authenticated',
         'grant execute on function public.picu_pembatalan_sah() to authenticated;', 'T130-trigger', MERAH_PAGAR),
        ('trigger menjadi RPC anon',
         'grant execute on function public.picu_pembayaran_jujur() to anon;', 'T130-trigger', MERAH_PAGAR),
        # Dua berkas gagal: satu error runtime di ACL, satu asersi RLS. Ini
        # sengaja membuktikan B-F01 sebagai RUSAK, bukan bukti campuran.
        ('RLS tabel dilepas',
         'alter table public.pesanan disable row level security;', '', MERAH_PAGAR),
        ('policy terakhir tabel dihapus',
         'drop policy penyewa_pilih on public.penyewa;', '', MERAH_PAGAR),
    ]
    gagal = 0
    garis = '-' * 70
    asersi = 'HARAPAN TIDAK TERPENUHI: T130: pagar wajib menolak'
    runtime = 'function public.fungsi_uji(uuid) does not exist'
    for nama, isi in (
        ('campuran runtime lalu asersi',
         f'  GAGAL supabase/tes/keamanan_fungsi.sql\n        {runtime}\n'
         f'  GAGAL supabase/tes/rls_semua_tabel.sql\n        {asersi}\n'
         f'{garis}\nuji: 0 LULUS · 2 GAGAL\nHASIL: GAGAL\n'),
        ('campuran asersi lalu runtime',
         f'  GAGAL supabase/tes/rls_semua_tabel.sql\n        {asersi}\n'
         f'  GAGAL supabase/tes/keamanan_fungsi.sql\n        {runtime}\n'
         f'{garis}\nuji: 0 LULUS · 2 GAGAL\nHASIL: GAGAL\n'),
    ):
        jenis, sebab = klasifikasi(1, isi)
        ok = jenis == RUSAK and 'bukan asersi' in sebab
        gagal += int(not ok)
        print(f"{'OK' if ok else 'GAGAL'} {nama}: {jenis} {sebab}")

    with tempfile.TemporaryDirectory(prefix='keamanan-sql-') as tmp:
        root = Path(tmp)
        for folder in ('supabase/migrations', 'supabase/tes', 'alat/sql'):
            shutil.copytree(AKAR / folder, root / folder)
        shutil.copy2(AKAR / 'alat/uji-sql.mjs', root / 'alat/uji-sql.mjs')
        (root / 'alat/node_modules').symlink_to(AKAR / 'alat/node_modules')
        asli = (root / MIG).read_text()
        kasus = [('kontrol utuh', '', HIJAU, '')]
        kasus += [(n, t, harap, token) for n, t, token, harap in mutasi]
        kasus += [('salinan SQL rusak bukan bukti', 'BUKAN SQL;', RUSAK, ''),
                  ('kontrol pulih', '', HIJAU, '')]
        for nama, tambahan, harap, token in kasus:
            (root / MIG).write_text(asli + '\n' + tambahan)
            r = jalankan(root)
            teks = r.stdout + r.stderr
            jenis, sebab = klasifikasi(r.returncode, teks)
            ok = jenis == harap and token in teks
            if harap == MERAH_PAGAR:
                ok = ok and 'HARAPAN TIDAK TERPENUHI' in sebab
            gagal += not ok
            print(f"{'OK' if ok else 'GAGAL'} {nama}: {jenis} {sebab}")
    print(f'HASIL: {"LOLOS" if not gagal else "GAGAL"} — {len(mutasi)} mutasi, kontrol awal/akhir, kalibrasi rusak; {gagal} tidak sesuai.')
    return int(bool(gagal))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--uji-diri', action='store_true')
    args = parser.parse_args()
    if args.uji_diri:
        return uji_diri()
    r = jalankan(AKAR)
    print(r.stdout, end='')
    print(r.stderr, end='')
    print('Lingkup: search_path + ACL efektif + trigger-only + sapuan RLS. '
          'Belum mengesahkan initplan SELECT pada policy (sisa T1-30).')
    return r.returncode


if __name__ == '__main__':
    raise SystemExit(main())
