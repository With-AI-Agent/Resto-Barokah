#!/usr/bin/env python3
"""Uji aturan wajib desain Resto Barokah pada berkas css/tokens.css.

Memeriksa rasio kontras (WCAG 2.1) untuk pasangan warna penting di SETIAP tema:
teks, teks redup, tulisan di tombol, dan label status (sukses/peringatan/bahaya/info).
Token dibaca lewat 3 lapis (primitif -> semantik) dan rujukan var() diurai otomatis.

Cara pakai:  python3 prototipe/uji-kontras.py
Keluaran:    daftar periksa + ringkasan; kode keluar 1 bila ada yang GAGAL.
"""
import re, sys, os

BASE = os.path.dirname(os.path.abspath(__file__))
css = open(os.path.join(BASE, 'css', 'tokens.css')).read()

# ---------- baca token per tema ----------
# Catatan: satu baris boleh memuat beberapa token -> ambil SEMUA yang ada di baris itu.
blok, tema = {}, None
for line in css.splitlines():
    m = re.match(r'^\s*(:root|\[data-theme="([a-z]+)"\])', line)
    if m:
        tema = m.group(2) or 'terang'
        blok.setdefault(tema, {})
        continue
    if tema:
        for nama, nilai in re.findall(r'(--[a-z0-9-]+):\s*([^;]+);', line):
            blok[tema][nama] = nilai.strip()

NAMA = {
    'terang': 'Terang Bersih', 'hangat': 'Hangat Kedai', 'gelap': 'Gelap Dapur', 'kontras': 'Kontras Tinggi',
    'bara': 'Bara Panggang', 'vintage': 'Vintage Klasik', 'alam': 'Alam Hijau',
    'tropis': 'Tropis Segar', 'pastel': 'Pastel Manis', 'etnik': 'Etnik Nusantara',
}


def urai(nilai, t, dalam=0):
    """Urai var(--x) sampai dapat warna heksa."""
    nilai = nilai.strip()
    m = re.match(r'^var\((--[a-z0-9-]+)\)$', nilai)
    if m and dalam < 8:
        return urai(t.get(m.group(1), '#000000'), t, dalam + 1)
    return nilai


def rgb(h):
    h = h.strip().lstrip('#')
    if not re.fullmatch(r'[0-9a-fA-F]{3}|[0-9a-fA-F]{6}', h):
        return None
    if len(h) == 3:
        h = ''.join(c * 2 for c in h)
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lum(c):
    f = lambda x: (x / 255) / 12.92 if x / 255 <= 0.03928 else (((x / 255) + 0.055) / 1.055) ** 2.4
    r, g, b = c
    return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b)


def rasio(a, b):
    la, lb = lum(a), lum(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


PASANGAN = [
    ('teks utama di latar',     '--text',            '--bg',           4.5),
    ('teks utama di kartu',     '--text',            '--surface',      4.5),
    ('teks redup di latar',     '--text-muted',      '--bg',           4.5),
    ('teks redup di kartu',     '--text-muted',      '--surface',      4.5),
    ('teks redup di kartu abu', '--text-muted',      '--surface-2',    4.5),
    ('tulisan di tombol',       '--accent-contrast', '--accent',       4.5),
    ('aksen di latar',          '--accent',          '--bg',           3.0),
    ('aksen di kartu',          '--accent',          '--surface',      3.0),
    ('aksen lembut',            '--accent',          '--accent-soft',  4.5),
    ('label sukses',            '--success',         '--success-soft', 4.5),
    ('label peringatan',        '--warn',            '--warn-soft',    4.5),
    ('label bahaya',            '--danger',          '--danger-soft',  4.5),
    ('label info',              '--info',            '--info-soft',    4.5),
]

lolos = gagal = 0
print("UJI KONTRAK DESAIN - kontras WCAG (minimum teks 4,5:1 / elemen 3:1)\n")
for t, nilai in blok.items():
    if t not in NAMA:
        continue
    print(f"=== {NAMA[t]}  (data-theme=\"{t}\") ===")
    for label, fg, bg, minr in PASANGAN:
        a, b = rgb(urai(nilai.get(fg, '#000'), nilai)), rgb(urai(nilai.get(bg, '#fff'), nilai))
        if not a or not b:
            print(f"  ?      {label:24s} token tidak terbaca")
            gagal += 1
            continue
        r = rasio(a, b)
        ok = r >= minr
        lolos += ok
        gagal += not ok
        print(f"  {'LOLOS' if ok else 'GAGAL':5s}  {label:24s} {r:5.2f}:1  (minimum {minr})")
    print()

jumlah = len([t for t in blok if t in NAMA])
print(f"RINGKASAN: {lolos} lolos, {gagal} gagal  -  {jumlah} tema diuji")
sys.exit(1 if gagal else 0)
