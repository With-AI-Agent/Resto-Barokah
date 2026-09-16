#!/usr/bin/env python3
"""Uji aturan wajib desain Resto Barokah pada berkas css/tokens.css.

Memeriksa rasio kontras (WCAG) untuk pasangan warna penting di SETIAP tema:
teks, teks redup, tulisan di tombol, label status (sukses/peringatan/bahaya/info).

Cara pakai:  python3 prototipe/uji-kontras.py
Keluaran:    daftar periksa + ringkasan; kode keluar 1 bila ada yang GAGAL.
"""
import re, sys, os

BASE = os.path.dirname(os.path.abspath(__file__))
css = open(os.path.join(BASE, 'css', 'tokens.css')).read()

blok, tema = {}, None
for line in css.splitlines():
    m = re.match(r'^\s*(:root|\[data-theme="([a-z]+)"\])', line)
    if m:
        tema = m.group(2) or 'terang'
        blok.setdefault(tema, {})
        continue
    if tema:
        v = re.match(r'^\s*(--[a-z0-9-]+):\s*([^;]+);', line)
        if v:
            blok[tema][v.group(1)] = v.group(2).strip()

def rgb(h):
    h = h.strip().lstrip('#')
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
    ('teks utama',          '--text',            '--bg',           4.5),
    ('teks utama di kartu', '--text',            '--surface',      4.5),
    ('teks redup',          '--text-muted',      '--bg',           4.5),
    ('teks redup di kartu', '--text-muted',      '--surface',      4.5),
    ('tulisan di tombol',   '--accent-contrast', '--accent',       4.5),
    ('aksen di latar',      '--accent',          '--bg',           3.0),
    ('aksen di kartu',      '--accent',          '--surface',      3.0),
    ('label sukses',        '--success',         '--success-soft', 4.5),
    ('label peringatan',    '--warn',            '--warn-soft',    4.5),
    ('label bahaya',        '--danger',          '--danger-soft',  4.5),
    ('label info',          '--info',            '--info-soft',    4.5),
    ('aksen lembut',        '--accent',          '--accent-soft',  4.5),
    ('aksen di kartu abu',  '--accent',          '--surface-2',    3.0),
]

NAMA = {'terang': 'Terang Bersih', 'hangat': 'Hangat Kedai', 'gelap': 'Gelap Dapur', 'kontras': 'Kontras Tinggi'}
lolos = gagal = 0
for t, nilai in blok.items():
    print(f"\n=== {NAMA.get(t, t)} ===")
    for label, fg, bg, minr in PASANGAN:
        a, b = rgb(nilai[fg]), rgb(nilai[bg])
        r = rasio(a, b)
        ok = r >= minr
        lolos += ok
        gagal += not ok
        print(f"  {'LOLOS' if ok else 'GAGAL'}  {label:22s} {r:5.2f}:1  (minimum {minr})")

print(f"\nRingkasan: {lolos} lolos, {gagal} gagal")
sys.exit(1 if gagal else 0)
