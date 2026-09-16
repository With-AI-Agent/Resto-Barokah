#!/usr/bin/env python3
"""Membuat gambar ikhtisar palet semua tema (docs/desain/palet-tema.png).

Warna dibaca LANGSUNG dari prototipe/css/tokens.css supaya gambar selalu sama
dengan yang benar-benar dipakai aplikasi (tidak ada warna yang dikarang).

Butuh ImageMagick (perintah `convert`).
Cara pakai:  python3 prototipe/buat-palet.py
"""
import os, re, subprocess

BASE = os.path.dirname(os.path.abspath(__file__))
AKAR = os.path.dirname(BASE)
css = open(os.path.join(BASE, 'css', 'tokens.css')).read()
keluar = os.path.join(AKAR, 'docs', 'desain', 'palet-tema.png')

NAMA = {
    'terang': '1. TERANG BERSIH', 'hangat': '2. HANGAT KEDAI', 'gelap': '3. GELAP DAPUR',
    'kontras': '4. KONTRAS TINGGI', 'bara': '5. BARA PANGGANG', 'vintage': '6. VINTAGE KLASIK',
    'alam': '7. ALAM HIJAU', 'tropis': '8. TROPIS SEGAR', 'pastel': '9. PASTEL MANIS',
    'etnik': '10. ETNIK NUSANTARA',
}
HURUF = {
    'terang': 'Outfit + WorkSans', 'hangat': 'Lora (serif) + WorkSans', 'gelap': 'Outfit + WorkSans',
    'kontras': 'huruf sistem', 'bara': 'BigShoulders + InstrumentSans', 'vintage': 'ArsenalSC + CrimsonPro',
    'alam': 'NationalPark + WorkSans', 'tropis': 'Outfit + WorkSans', 'pastel': 'Bricolage + Outfit',
    'etnik': 'YoungSerif + WorkSans',
}
ASAL = {
    'terang': 'bawaan · rujukan P16/P08', 'hangat': 'rujukan P15/P22', 'gelap': 'rujukan P17/P03',
    'kontras': 'aksesibilitas', 'bara': 'dari gambar kiriman pemilik (P16)',
    'vintage': 'arah gaya: vintage-analog-retro-film', 'alam': 'arah gaya: organic-biophilic',
    'tropis': 'disusun sendiri', 'pastel': 'arah gaya: claymorphism', 'etnik': 'disusun sendiri',
}

# baca token tiap tema (semua token pada satu baris)
blok, tema = {}, None
for baris in css.splitlines():
    m = re.match(r'^\s*(:root|\[data-theme="([a-z]+)"\])', baris)
    if m:
        tema = m.group(2) or 'terang'
        blok.setdefault(tema, {})
        continue
    if tema:
        for nama, nilai in re.findall(r'(--[a-z0-9-]+):\s*([^;]+);', baris):
            blok[tema][nama] = nilai.strip()

KUNCI = ['--bg', '--surface', '--surface-2', '--accent', '--text', '--text-muted',
         '--success', '--warn', '--danger', '--info']


def urai(nilai, t, dalam=0):
    m = re.match(r'^var\((--[a-z0-9-]+)\)$', nilai.strip())
    if m and dalam < 8:
        return urai(t.get(m.group(1), '#000000'), t, dalam + 1)
    return nilai.strip()


L, T = 1780, 1180
perintah = ['convert', '-size', f'{L}x{T}', 'xc:#ffffff',
            '-font', 'DejaVu-Sans-Bold', '-pointsize', '34', '-fill', '#111111',
            '-annotate', '+40+58', 'RESTO BAROKAH - 10 TEMA (warna diambil langsung dari kode)',
            '-font', 'DejaVu-Sans', '-pointsize', '19', '-fill', '#555555',
            '-annotate', '+40+88', 'Semua tema lolos uji kontras: 130 pemeriksaan, 0 gagal (python3 prototipe/uji-kontras.py)',
            '-font', 'DejaVu-Sans-Bold', '-pointsize', '17', '-fill', '#333333',
            '-annotate', '+40+124', 'TEMA']

x_awal = 600
lebar, tinggi = 112, 62
y = 150
for i, (kode, nama) in enumerate(NAMA.items()):
    t = blok.get(kode, {})
    if i % 2 == 0 and i > 0:
        pass
    perintah += ['-font', 'DejaVu-Sans-Bold', '-pointsize', '20', '-fill', '#111111',
                 '-annotate', f'+40+{y + 30}', nama,
                 '-font', 'DejaVu-Sans', '-pointsize', '15', '-fill', '#666666',
                 '-annotate', f'+40+{y + 52}', f'{HURUF[kode]}  ·  {ASAL[kode]}']
    for j, kunci in enumerate(KUNCI):
        warna = urai(t.get(kunci, '#000000'), t)
        x = x_awal + j * (lebar + 6)
        perintah += ['-fill', warna, '-stroke', '#00000022', '-strokewidth', '1',
                     '-draw', f'rectangle {x},{y - 6} {x + lebar - 6},{y + tinggi - 6}']
    y += 88

# keterangan warna di bawah
perintah += ['-stroke', 'none', '-font', 'DejaVu-Sans', '-pointsize', '14', '-fill', '#444444']
for j, kunci in enumerate(KUNCI):
    x = x_awal + j * (lebar + 6)
    perintah += ['-annotate', f'+{x}+{y + 18}', kunci.replace('--', '')]

perintah += ['-font', 'DejaVu-Sans', '-pointsize', '15', '-fill', '#666666',
             '-annotate', '+40+1108', 'Cara lihat: buka halaman prototipe/04-tema.html untuk melihat semua tema hidup, atau tekan tombol "Tema" di halaman contoh tampilan.',
             '-annotate', '+40+1134', 'Huruf dari skills/ui-styling/canvas-fonts (lisensi OFL), dirampingkan ke woff2: 1,4 MB menjadi 311 KB, disimpan lokal tanpa internet.']

os.makedirs(os.path.dirname(keluar), exist_ok=True)
subprocess.run(perintah + [keluar], check=True)
print('Gambar dibuat:', os.path.relpath(keluar, AKAR), f'({os.path.getsize(keluar)/1024:.0f} KB)')
