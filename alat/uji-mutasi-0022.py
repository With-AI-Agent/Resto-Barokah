#!/usr/bin/env python3
"""T-025(a): mutasi hanya pada salinan sementara; merah setup BUKAN bukti.

Setiap mutasi harus memicu asersi BY-201/ketetapan nilai pada uji transaksi asli.
Kunci concurrency diuji terpisah dengan 2 koneksi di uji-konkuren-0022.py.
Mutasi progres sengaja memilih tepat SATU dari dua pagar yang mirip; jangan
mengubah kedua fungsi sekaligus karena hasil merah tidak diagnostik (B-F03).
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi

AKAR = Path(__file__).resolve().parent.parent
MIG = 'supabase/migrations/0022_beku_setelah_bayar.sql'
MIG_0025 = 'supabase/migrations/0025_isolasi_identitas_null.sql'
MIG_0026 = 'supabase/migrations/0026_kunci_lingkup_rincian.sql'
UJI = 'supabase/tes/beku_setelah_bayar.sql'
PROGRES = "and ((old.status = 'baru' and new.status = 'dimasak')"
LAPISAN_0024 = """
-- Harness 0022 mengisolasi pagar lama; pagar akhir 0024 punya harness sendiri.
drop trigger pesanan_beku_akhir_satu_pernyataan on public.pesanan;
drop trigger item_beku_akhir_satu_pernyataan on public.pesanan_item;
drop trigger diskon_beku_akhir_satu_pernyataan on public.diskon_transaksi;
drop trigger pembatalan_beku_akhir_satu_pernyataan on public.pembatalan;
"""
LAPISAN_0026 = """
-- Harness 0022 mengisolasi definisi lama; A-F04/0026 diuji oleh harness sendiri.
drop trigger rincian_kunci_global_sebelum on public.pesanan_item;
"""


def ganti_kemunculan(teks: str, lama: str, baru: str, nomor: int) -> str:
    """Ganti kemunculan 1-based dan pastikan hanya satu titik berubah."""
    posisi = [i for i in range(len(teks)) if teks.startswith(lama, i)]
    if len(posisi) < nomor:
        raise AssertionError(f'kemunculan ke-{nomor} tidak ada untuk {lama!r}')
    i = posisi[nomor - 1]
    hasil = teks[:i] + teks[i:].replace(lama, baru, 1)
    if hasil.count(baru) != teks.count(baru) + 1:
        raise AssertionError('mutasi tidak tepat satu kemunculan')
    return hasil


def main() -> int:
    asli = (AKAR / MIG).read_text(encoding='utf-8')
    # Kedua baris PROGRES berada di fungsi berbeda: BEFORE (rincian) dan AFTER
    # (hitung_total). Masing-masing mutasi hanya boleh menyentuh satu baris.
    before_only = ganti_kemunculan(asli, PROGRES, "and false and ((old.status = 'baru' and new.status = 'dimasak')", 1)
    after_only = ganti_kemunculan(asli, PROGRES, "and false and ((old.status = 'baru' and new.status = 'dimasak')", 2)
    mutasi = [
        ('penjaga item dimatikan', asli + '\ndrop trigger aaa_item_beku_setelah_bayar on public.pesanan_item;'),
        ('penjaga diskon dimatikan', asli + '\ndrop trigger aaa_diskon_beku_setelah_bayar on public.diskon_transaksi;'),
        ('pagar void dan pertahanan header dimatikan', asli + '\ndrop trigger aaa_pembatalan_beku_setelah_bayar on public.pembatalan;\ndrop trigger aaa_item_beku_setelah_bayar on public.pesanan_item;\ndrop trigger zzz_pesanan_beku_setelah_bayar on public.pesanan;'),
        ('penjaga header dimatikan', asli + '\ndrop trigger zzz_pesanan_beku_setelah_bayar on public.pesanan;'),
        ('parent lama dilupakan', asli.replace('v_lama := old.pesanan_id;', 'v_lama := null;')),
        ('parent tujuan + pertahanan header dilepas', asli.replace('v_baru := new.pesanan_id;', 'v_baru := null;') + '\ndrop trigger zzz_pesanan_beku_setelah_bayar on public.pesanan;'),
        ('bypass peladen ditambahkan', asli.replace('begin\n  if tg_op', 'begin\n  if auth.uid() is null then return case when tg_op = \'DELETE\' then old else new end; end if;\n  if tg_op', 1)),
        ('hanya lunas dianggap berbayar', asli.replace('where pb.pesanan_id = v_id)', "where pb.pesanan_id = v_id and (select status from public.pesanan where id=v_id)='lunas')")),
        ('progres pagar BEFORE dimatikan (tepat satu)', before_only),
        ('progres pagar AFTER dimatikan (tepat satu)', after_only),
    ]
    assert before_only.count('and false and') == 1
    assert after_only.count('and false and') == 1
    gagal = 0
    with tempfile.TemporaryDirectory(prefix='mutasi-0022-') as tmp:
        root = Path(tmp)
        for folder in ('supabase/migrations', 'supabase/tes', 'alat/sql'):
            shutil.copytree(AKAR / folder, root / folder)
        shutil.copy2(AKAR / 'alat/uji-sql.mjs', root / 'alat/uji-sql.mjs')
        (root / 'alat/node_modules').symlink_to(AKAR / 'alat/node_modules')

        asli_0025 = (root / MIG_0025).read_text(encoding='utf-8')
        asli_0026 = (root / MIG_0026).read_text(encoding='utf-8')

        def fungsi_rincian(teks: str) -> str:
            awal = teks.index('create function public.picu_rincian_beku_setelah_bayar()')
            akhir = teks.index('revoke all on function public.picu_rincian_beku_setelah_bayar()', awal)
            return teks[awal:akhir].replace(
                'create function public.picu_rincian_beku_setelah_bayar()',
                'create or replace function public.picu_rincian_beku_setelah_bayar()',
                1,
            )

        def run(teks: str) -> tuple[str, str]:
            # Jangan biarkan lapisan baru 0024/0026 menutupi mutasi yang
            # memang hendak mengkalibrasi pagar 0022. Harness masing-masing
            # menguji lapis baru sendiri.
            (root / MIG).write_text(teks, encoding='utf-8')
            (root / MIG_0025).write_text(
                asli_0025 if teks == asli else asli_0025 + '\n' + LAPISAN_0024,
                encoding='utf-8',
            )
            (root / MIG_0026).write_text(
                asli_0026 if teks == asli else asli_0026 + '\n' + LAPISAN_0026 + '\n' + fungsi_rincian(teks),
                encoding='utf-8',
            )
            r = subprocess.run(['node', 'alat/uji-sql.mjs', UJI], cwd=root,
                               capture_output=True, text=True, timeout=120)
            return klasifikasi(r.returncode, r.stdout + r.stderr)

        for nama, teks, harap in [('kontrol utuh', asli, HIJAU)] + [
            (n, t, MERAH_PAGAR) for n, t in mutasi
        ] + [('sintaks rusak bukan bukti', asli + '\nBUKAN SQL;', RUSAK),
             ('penutup pulih', asli, HIJAU)]:
            jenis, sebab = run(teks)
            ok = jenis == harap and (
                harap != MERAH_PAGAR or 'HARAPAN TIDAK TERPENUHI' in sebab
            ) and (nama in ('kontrol utuh', 'penutup pulih') or teks != asli)
            gagal += int(not ok)
            print(f"{'OK' if ok else 'GAGAL'} {nama}: {jenis} {sebab}")
    print(f'HASIL: {"LOLOS" if not gagal else "GAGAL"} — {len(mutasi)} mutasi terisolasi, kontrol+penutup, salinan rusak ditolak; {gagal} tidak sesuai.')
    return int(bool(gagal))


if __name__ == '__main__':
    raise SystemExit(main())
