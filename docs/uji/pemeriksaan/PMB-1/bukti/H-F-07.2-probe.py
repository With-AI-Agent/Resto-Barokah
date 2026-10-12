#!/usr/bin/env python3
"""Reproduksi hakim F-07 ulangan; hanya membaca proyek, mutasi di salinan sementara.
Jalankan dari akar repo: python3 docs/uji/pemeriksaan/PMB-1/bukti/H-F-07.2-probe.py
Tidak mengakses Supabase/produksi. Hasil HIJAU di kasus cacat berarti cacat masih hidup.
"""
import importlib.util
from pathlib import Path
import shutil
import sys
import tempfile

AKAR = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(AKAR / 'alat'))

def muat(nama, berkas):
    spec = importlib.util.spec_from_file_location(nama, AKAR / berkas)
    modul = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modul)
    return modul

peta = muat('peta_ui_hakim_ulang', 'alat/peta-ui.py')
pmb = muat('pmb_hakim_ulang', 'alat/periksa-pemeriksaan.py')
print('Basis sumber:', AKAR)
print('Kontrol proyek asli:', peta.periksa(AKAR))
assert peta.periksa(AKAR)[0]

with tempfile.TemporaryDirectory(prefix='h-f-07-ulang-') as tmp:
    akar = Path(tmp)
    for rel in ('aplikasi/src/lib/layar.ts', 'aplikasi/src/lib/aksi.ts', 'docs/PETA_UI.md', 'docs/PRD.md'):
        tujuan = akar / rel
        tujuan.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(AKAR / rel, tujuan)
    shutil.copytree(AKAR / 'supabase/migrations', akar / 'supabase/migrations')
    # Sertakan seluruh kode layar agar kontrol bukan contoh yang menghilangkan aturan 7.
    shutil.copytree(AKAR / 'aplikasi/src/layar', akar / 'aplikasi/src/layar')
    assert peta.periksa(akar)[0]
    (akar / 'docs/PRD.md').unlink()
    hasil = peta.periksa(akar)
    print('PMB1-F-096 PRD dihapus dari salinan:', hasil)
    assert hasil == (True, []), 'Perilaku berubah: sekarang penjaga membaca PRD'
    shutil.copy2(AKAR / 'docs/PRD.md', akar / 'docs/PRD.md')

    aksi = akar / 'aplikasi/src/lib/aksi.ts'
    asli = aksi.read_text()
    layar = peta.ekstrak_objek_ts(akar / 'aplikasi/src/lib/layar.ts', 'DAFTAR_LAYAR')
    def sinkronkan():
        entri = peta.ekstrak_objek_ts(aksi, 'REGISTRI_AKSI')
        (akar / 'docs/PETA_UI.md').write_text(peta.generate_markdown(layar, entri))
        return entri
    entri = sinkronkan()
    print('PMB1-F-097 voucher.klaim_diskon:', entri['voucher.klaim_diskon'])
    assert entri['voucher.klaim_diskon']['rpc'] == 'hitung_total'
    for id_aksi in ('dapur.mulai_masak', 'dapur.selesai_masak', 'dapur.tandai_habis'):
        print('PMB1-F-098:', id_aksi, entri[id_aksi]['jenis'], entri[id_aksi]['rpc'])
        assert entri[id_aksi]['jenis'] == 'tulis' and entri[id_aksi]['rpc'] is None
    for id_aksi in ('pengaturan.simpan_tema', 'pengaturan.simpan_menu', 'pengaturan.simpan_kategori'):
        print('PMB1-F-099:', id_aksi, entri[id_aksi]['peran'], entri[id_aksi]['rpc'])
        assert 'admin_cabang' in entri[id_aksi]['peran']

    # Kontrol negatif: fungsi sungguhan memeriksa RPC tak dikenal; bukan stub yang selalu hijau.
    assert "rpc: 'hitung_total'" in asli
    aksi.write_text(asli.replace("rpc: 'hitung_total'", "rpc: 'rpc_tidak_ada_hakim_ulang'", 1))
    sinkronkan()
    hasil = peta.periksa(akar)
    print('Kontrol negatif RPC tidak ada (harus ditolak):', hasil)
    assert not hasil[0] and any('[Aturan 1 - RPC]' in x for x in hasil[1])
    # Bandingkan hilangnya RPC tulis dengan RPC palsu, PETA tetap disinkronkan pada kedua kasus.
    aksi.write_text(asli.replace("rpc: 'hitung_total'", 'rpc: null', 1))
    sinkronkan()
    hasil = peta.periksa(akar)
    print('PMB1-F-098 RPC tulis dibuat null:', hasil)
    assert hasil == (True, [])

for rujukan, ditolak in [('`docs/KEAMANAN.md:53-54`', False), ('`docs/KEAMANAN.md:99999`', True)]:
    hasil = pmb._baris_artefak_di_luar_berkas(rujukan, AKAR)
    print('PMB1-F-094 penjaga batas baris:', rujukan, hasil)
    assert bool(hasil) == ditolak
print('SELESAI: semua hasil sesuai asersi; sumber proyek tidak diubah.')
