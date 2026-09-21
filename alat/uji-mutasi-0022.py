#!/usr/bin/env python3
"""T-025(a): mutasi hanya pada salinan sementara; merah setup BUKAN bukti.

Setiap mutasi harus memicu asersi BY-201/ketetapan nilai pada uji transaksi asli.
Kunci concurrency diuji terpisah dengan 2 koneksi di uji-konkuren-0022.py.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi

AKAR = Path(__file__).resolve().parent.parent
MIG = 'supabase/migrations/0022_beku_setelah_bayar.sql'
UJI = 'supabase/tes/beku_setelah_bayar.sql'


def main() -> int:
    asli = (AKAR / MIG).read_text()
    mutasi = [
        ('penjaga item dimatikan', asli + '\ndrop trigger aaa_item_beku_setelah_bayar on public.pesanan_item;'),
        ('penjaga diskon dimatikan', asli + '\ndrop trigger aaa_diskon_beku_setelah_bayar on public.diskon_transaksi;'),
        ('pagar void dan pertahanan header dimatikan', asli + '\ndrop trigger aaa_pembatalan_beku_setelah_bayar on public.pembatalan;\ndrop trigger aaa_item_beku_setelah_bayar on public.pesanan_item;\ndrop trigger zzz_pesanan_beku_setelah_bayar on public.pesanan;'),
        ('penjaga header dimatikan', asli + '\ndrop trigger zzz_pesanan_beku_setelah_bayar on public.pesanan;'),
        ('parent lama dilupakan', asli.replace('v_lama := old.pesanan_id;', 'v_lama := null;')),
        ('parent tujuan + pertahanan header dilepas', asli.replace('v_baru := new.pesanan_id;', 'v_baru := null;') + '\ndrop trigger zzz_pesanan_beku_setelah_bayar on public.pesanan;'),
        ('bypass peladen ditambahkan', asli.replace('begin\n  if tg_op', 'begin\n  if auth.uid() is null then return case when tg_op = \'DELETE\' then old else new end; end if;\n  if tg_op', 1)),
        ('hanya lunas dianggap berbayar', asli.replace('where pb.pesanan_id = v_id)', "where pb.pesanan_id = v_id and (select status from public.pesanan where id=v_id)='lunas')")),
        ('progres masak menghitung ulang tarif baru', asli.replace("and ((old.status = 'baru' and new.status = 'dimasak')", "and false and ((old.status = 'baru' and new.status = 'dimasak')")),
    ]
    gagal = 0
    with tempfile.TemporaryDirectory(prefix='mutasi-0022-') as tmp:
        root = Path(tmp)
        for folder in ('supabase/migrations', 'supabase/tes', 'alat/sql'):
            shutil.copytree(AKAR / folder, root / folder)
        shutil.copy2(AKAR / 'alat/uji-sql.mjs', root / 'alat/uji-sql.mjs')
        (root / 'alat/node_modules').symlink_to(AKAR / 'alat/node_modules')

        def run(teks: str) -> tuple[str, str]:
            (root / MIG).write_text(teks)
            r = subprocess.run(['node', 'alat/uji-sql.mjs', UJI], cwd=root,
                               capture_output=True, text=True, timeout=120)
            return klasifikasi(r.returncode, r.stdout + r.stderr)

        for nama, teks, harap in [('kontrol utuh', asli, HIJAU)] + [
            (n, t, MERAH_PAGAR) for n, t in mutasi
        ] + [('sintaks rusak bukan bukti', asli + '\nBUKAN SQL;', RUSAK),
             ('penutup pulih', asli, HIJAU)]:
            jenis, sebab = run(teks)
            ok = jenis == harap and (harap != MERAH_PAGAR or 'HARAPAN TIDAK TERPENUHI' in sebab) and (nama in ('kontrol utuh', 'penutup pulih') or teks != asli)
            gagal += not ok
            print(f"{'OK' if ok else 'GAGAL'} {nama}: {jenis} {sebab}")
    print(f'HASIL: {"LOLOS" if not gagal else "GAGAL"} — {len(mutasi)} mutasi, kontrol+penutup, kalibrasi salinan rusak; {gagal} tidak sesuai.')
    return int(bool(gagal))


if __name__ == '__main__':
    raise SystemExit(main())
