"""Reproduksi salah deteksi URL: memanggil parser proyek, tanpa mengubahnya."""
from pathlib import Path
import importlib.util
import sys
sys.dont_write_bytecode = True
akar = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(akar/'alat'))
spec = importlib.util.spec_from_file_location('penjaga_rujukan', akar/'alat/periksa-rujukan.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
url = 'https://www.postgresql.org/docs/current/plpgsql-control-structures.html#PLPGSQL-ERROR-TRAPPING'
for teks in [url, '[PostgreSQL §41.6.8](' + url + ')']:
    hasil = m.rujukan_dalam(teks)
    assert len(hasil) == 1
    assert hasil[0][1] == 'docs/current/plpgsql-control-structures.html'
    assert not (akar/hasil[0][1]).exists()
    print('URL eksternal salah dideteksi sebagai berkas repo:', hasil[0][1])
    try:
        assert hasil == [], 'Kontrak: URL eksternal bukan rujukan berkas lokal'
    except AssertionError:
        print('Kontrol negatif: assertion kontrak URL eksternal MERAH pada parser nyata')
    else:
        raise AssertionError('Reproduksi tidak lagi menangkap cacat')
# Pencarian benar-benar harus tetap menjaga jalur lokal; bukan seluruh parsing dimatikan.
assert m.rujukan_dalam('`docs/PRD.md`')[0][1] == 'docs/PRD.md'
assert (akar/'docs/PRD.md').is_file()
assert m.rujukan_dalam('`docs/contoh-hilang-f112.md`')[0][1] == 'docs/contoh-hilang-f112.md'
assert not (akar/'docs/contoh-hilang-f112.md').exists()
print('Kontrol jalur lokal sah/hilang dikenali; LOLOS reproduksi PMB1-F-149')
