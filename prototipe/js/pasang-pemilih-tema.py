#!/usr/bin/env python3
"""Menyisipkan pemilih 10 tema ke semua halaman contoh tampilan.

Dipakai sekali (2026-09-16) untuk menyamakan tombol ganti tema di index.html,
01-laporan.html, 02-kasir.html, dan 03-katalog.html.

Jalankan dari mana saja:  python3 prototipe/js/pasang-pemilih-tema.py
"""
import os, re

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

TEMA = [
    ('terang',  'Terang Bersih',  'Bersih & terang — bawaan'),
    ('hangat',  'Hangat Kedai',   'Krem & coklat, ramah'),
    ('gelap',   'Gelap Dapur',    'Gelap, untuk layar dapur'),
    ('kontras', 'Kontras Tinggi', 'Hitam-putih, garis tebal'),
    ('bara',    'Bara Panggang',  'Hitam + emas (dari gambar kirimanmu)'),
    ('vintage', 'Vintage Klasik', 'Kertas tua, serif, garis ganda'),
    ('alam',    'Alam Hijau',     'Hijau daun, membulat lembut'),
    ('tropis',  'Tropis Segar',   'Teal laut, ceria'),
    ('pastel',  'Pastel Manis',   'Pastel lembut, tebal (clay)'),
    ('etnik',   'Etnik Nusantara','Ivory, terakota, motif batik'),
]

tombol = []
for kode, nama, ket in TEMA:
    tombol.append(
        f'        <button type="button" data-set-tema="{kode}">'
        f'<span class="sw-3" data-theme="{kode}" aria-hidden="true">'
        f'<i style="background:var(--bg)"></i><i style="background:var(--accent)"></i><i style="background:var(--text)"></i>'
        f'</span><span><strong>{nama}</strong><small>{ket}</small></span></button>'
    )

PEMILIH = (
    '<details class="picker">\n'
    '  <summary class="btn btn-sm"><i class="swatch" data-swatch-tema></i> Tema: <span data-nama-tema>Terang Bersih</span></summary>\n'
    '  <div class="picker-panel" aria-label="Pilih tema">\n'
    + '\n'.join(tombol) + '\n'
    '    <a class="picker-all" href="04-tema.html">Lihat 10 tema berdampingan &rarr;</a>\n'
    '  </div>\n'
    '</details>'
)

for berkas in ['index.html', '01-laporan.html', '02-kasir.html', '03-katalog.html']:
    jalur = os.path.join(BASE, berkas)
    html = open(jalur).read()
    baru, n = re.subn(r'<nav class="theme-switch".*?</nav>', PEMILIH, html, flags=re.S)
    if n == 0:
        print(f'  ! {berkas}: tombol tema tidak ditemukan')
        continue
    # tambahkan tautan ke galeri tema di bar contoh
    if '04-tema.html' not in baru.split('demo-bar')[1].split('</div>')[0]:
        baru = baru.replace('<a href="03-katalog.html">katalog</a>',
                            '<a href="03-katalog.html">katalog</a> · <a href="04-tema.html">10 tema</a>', 1)
        baru = baru.replace('<a href="02-kasir.html">kasir</a>',
                            '<a href="02-kasir.html">kasir</a> · <a href="04-tema.html">10 tema</a>', 1)
    open(jalur, 'w').write(baru)
    print(f'  OK {berkas}: pemilih tema dipasang ({len(TEMA)} pilihan)')

print('Selesai.')
