"""Jalankan dari akar repo; tidak mengubah sumber, hanya salinan sementara milik uji-diri."""
import contextlib
import importlib.util
from pathlib import Path
spec = importlib.util.spec_from_file_location('penjaga', Path('alat/periksa-pemeriksaan.py').resolve())
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
print('KEADAAN KINI', flush=True)
a = m.uji_diri()
asli = m.salin_pohon
@contextlib.contextmanager
def tanpa_baru():
    with asli() as tmp:
        p = tmp / m.PUTARAN / 'BUKU_BESAR_TEMUAN.md'
        teks = p.read_text()
        hasil = []
        for baris in teks.splitlines():
            if baris.startswith('| PMB1-F-'):
                sel = [s.strip() for s in baris.strip('|').split('|')]
                if sel[7] == 'BARU':
                    sel[7] = 'PERLU-INFO'
                    sel[8] = 'arena/uji-sintetis H-F-03 (bukan putusan nyata)'
                    baris = '| ' + ' | '.join(sel) + ' |'
            hasil.append(baris)
        p.write_text('\n'.join(hasil)+'\n')
        assert '| BARU |' not in p.read_text()
        yield tmp
m.salin_pohon = tanpa_baru
print('KEADAAN SINTETIS TANPA BARU (semua salinan, bukan buku besar nyata)', flush=True)
b = m.uji_diri()
raise SystemExit(a or b)
