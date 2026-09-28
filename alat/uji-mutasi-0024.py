#!/usr/bin/env python3
"""G3 A-F03: mutasi pagar akhir satu-pernyataan.

Suite regresi harus hijau pada migrasi utuh, merah karena BY-201 ketika lapisan
akhir dilepas, dan RUSAK ketika salinan SQL sengaja dibuat tidak valid. Merah
setup/runtime tidak pernah dihitung sebagai bukti pagar.
"""
from pathlib import Path
import shutil
import subprocess
import tempfile

from klasifikasi_mutasi import HIJAU, MERAH_PAGAR, RUSAK, klasifikasi

AKAR = Path(__file__).resolve().parent.parent
MIG = 'supabase/migrations/0024_beku_satu_pernyataan.sql'
UJI = 'supabase/tes/beku_satu_pernyataan.sql'
TRIGGER = [
    'pesanan_beku_akhir_satu_pernyataan',
    'item_beku_akhir_satu_pernyataan',
    'diskon_beku_akhir_satu_pernyataan',
    'pembatalan_beku_akhir_satu_pernyataan',
]


def main() -> int:
    asli = (AKAR / MIG).read_text(encoding='utf-8')
    hapus_semua = '\n'.join(
        f'drop trigger {nama} on public.{tabel};'
        for nama, tabel in zip(TRIGGER, ('pesanan', 'pesanan_item', 'diskon_transaksi', 'pembatalan'))
    )
    mutasi = [
        ('pagar header dilepas', asli + '\ndrop trigger pesanan_beku_akhir_satu_pernyataan on public.pesanan;'),
        ('pagar item dilepas', asli + '\ndrop trigger item_beku_akhir_satu_pernyataan on public.pesanan_item;'),
        ('seluruh pagar akhir dilepas', asli + '\n' + hapus_semua),
    ]
    gagal = 0
    with tempfile.TemporaryDirectory(prefix='mutasi-0024-') as tmp:
        root = Path(tmp)
        for folder in ('supabase/migrations', 'supabase/tes', 'alat/sql'):
            shutil.copytree(AKAR / folder, root / folder)
        shutil.copy2(AKAR / 'alat/uji-sql.mjs', root / 'alat/uji-sql.mjs')
        (root / 'alat/node_modules').symlink_to(AKAR / 'alat/node_modules')

        def run(teks: str) -> tuple[str, str]:
            (root / MIG).write_text(teks, encoding='utf-8')
            hasil = subprocess.run(
                ['node', 'alat/uji-sql.mjs', UJI],
                cwd=root, capture_output=True, text=True, timeout=120,
            )
            return klasifikasi(hasil.returncode, hasil.stdout + hasil.stderr)

        kasus = [('kontrol utuh', asli, HIJAU)]
        kasus += [(nama, teks, MERAH_PAGAR) for nama, teks in mutasi]
        kasus += [('SQL rusak bukan bukti', asli + '\nBUKAN SQL;', RUSAK),
                  ('kontrol pulih', asli, HIJAU)]
        for nama, teks, harap in kasus:
            jenis, sebab = run(teks)
            ok = jenis == harap and (
                harap != MERAH_PAGAR or 'HARAPAN TIDAK TERPENUHI' in sebab
            )
            gagal += int(not ok)
            print(f"{'OK' if ok else 'GAGAL'} {nama}: {jenis} {sebab}")
    print(
        f'HASIL: {"LOLOS" if not gagal else "GAGAL"} — '
        f'{len(mutasi)} mutasi, kontrol+pulih, salinan rusak ditolak; {gagal} tidak sesuai.'
    )
    return int(bool(gagal))


if __name__ == '__main__':
    raise SystemExit(main())
