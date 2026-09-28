#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Uji aturan wajib desain Resto Barokah pada berkas css/tokens.css.

Dua bagian:
  A. KONTRAS WARNA (WCAG 2.1, 13 pasangan x 10 tema) — teks, teks redup, tulisan
     di tombol, label status (sukses/peringatan/bahaya/info), aksen.
  B. ATURAN DESAIN — kelengkapan token tiap tema, tangga jarak & ukuran huruf,
     ukuran sentuh minimal 44 px, cincin fokus, mode "kurangi gerak",
     bayangan berlapis, dan huruf yang benar-benar tersimpan di dalam aplikasi.

Token dibaca dari blok tema (var() diurai otomatis).

Cara pakai:  python3 prototipe/uji-kontras.py
Keluaran:    daftar periksa + ringkasan; kode keluar 1 bila ada yang GAGAL.
"""
import re, sys, os

BASE = os.path.dirname(os.path.abspath(__file__))
CSS_PATH = os.path.join(BASE, 'css', 'tokens.css')
css = open(CSS_PATH, encoding='utf-8').read()


def tanpa_komentar(teks):
    """Buang komentar CSS TANPA menghapus struktur baris.

    Kenapa perlu: pembaca deklarasi di bawah memecah isi blok per `;`. Kalau ada
    komentar di belakang sebuah nilai (mis. `--baris-isi:1.55;   /* tinggi baris */`),
    teks komentar itu menempel ke deklarasi BERIKUTNYA sehingga token itu tidak
    terbaca — cacat ini nyata (2026-09-17: `--t-1` dilaporkan "hilang" padahal ada,
    hanya karena ada komentar setelah nilai sebelumnya).
    """
    return re.sub(r'/\*.*?\*/', lambda m: '\n' * m.group(0).count('\n'), teks, flags=re.S)

# ============================ PEMBACA BERKAS CSS ===========================


def isi_blok(teks, pos):
    """Ambil isi {...} mulai dari posisi '{' (kurung seimbang)."""
    j, dalam = pos + 1, 1
    while j < len(teks) and dalam:
        if teks[j] == '{':
            dalam += 1
        elif teks[j] == '}':
            dalam -= 1
        j += 1
    return teks[pos + 1:j - 1]


def deklarasi(isi, token=True):
    """Pecah isi blok jadi {nama: nilai}; ';' di dalam tanda kutip/kurung diabaikan.

    token=True  -> hanya ambil token sendiri (--nama: nilai)
    token=False -> ambil properti CSS biasa (min-height: 44px)
    """
    hasil, buf, petik, kurung = {}, '', None, 0
    pola = r'^\s*(--[a-z0-9-]+)\s*:\s*(.+)$' if token else r'^\s*([-\w]+)\s*:\s*(.+)$'
    for ch in isi + ';':
        if petik:
            if ch == petik:
                petik = None
            buf += ch
            continue
        if ch in ('"', "'"):
            petik = ch
            buf += ch
            continue
        if ch == '(':
            kurung += 1
        elif ch == ')':
            kurung = max(0, kurung - 1)
        if ch == ';' and kurung == 0:
            m = re.match(pola, buf, re.S)
            if m:
                hasil[m.group(1)] = ' '.join(m.group(2).split())
            buf = ''
            continue
        buf += ch
    return hasil


css = tanpa_komentar(css)

# blok tema: hanya yang selektornya berdiri sendiri di awal baris
blok = {}
for m in re.finditer(r'\[data-theme="([a-z]+)"\]\s*\{', css):
    awal_baris = css.rfind('\n', 0, m.start()) + 1
    if css[awal_baris:m.start()].strip():
        continue  # selektornya menempel dengan selektor lain -> lewati
    blok.setdefault(m.group(1), {}).update(deklarasi(isi_blok(css, m.end() - 1)))

NAMA = {
    'terang': 'Terang Bersih', 'hangat': 'Hangat Kedai', 'gelap': 'Gelap Dapur', 'kontras': 'Kontras Tinggi',
    'bara': 'Bara Panggang', 'vintage': 'Vintage Klasik', 'alam': 'Alam Hijau',
    'tropis': 'Tropis Segar', 'pastel': 'Pastel Manis', 'etnik': 'Etnik Nusantara',
}
TEMA = [t for t in blok if t in NAMA]


def urai(nilai, t, dalam=0):
    """Urai var(--x) sampai dapat warna heksa."""
    nilai = (nilai or '').strip()
    m = re.match(r'^var\((--[a-z0-9-]+)\)$', nilai)
    if m and dalam < 8:
        return urai(t.get(m.group(1), '#000000'), t, dalam + 1)
    return nilai


def rgb(h):
    h = (h or '').strip().lstrip('#')
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


# ================================ BAGIAN A ================================

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

print("UJI ATURAN DESAIN RESTO BAROKAH")
print("Bagian A - kontras WCAG 2.1 (teks 4,5:1 / elemen 3:1)\n")

lolos = gagal = 0
for t in TEMA:
    nilai = blok[t]
    print(f"=== {NAMA[t]}  (data-theme=\"{t}\") ===")
    for label, fg, bg, minr in PASANGAN:
        a = rgb(urai(nilai.get(fg, '#000'), nilai))
        b = rgb(urai(nilai.get(bg, '#fff'), nilai))
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

# ================================ BAGIAN B ================================

print("Bagian B - aturan desain\n")
atur = []   # (berhasil, judul, keterangan)


def periksa(ok, judul, ket=''):
    atur.append((bool(ok), judul, ket))


# --- nilai global (bukan warna) ---
def blok_ber_selektor(selektor):
    """Ambil gabungan deklarasi dari blok yang selektornya tepat sama."""
    gab = {}
    for m in re.finditer(re.escape(selektor) + r'\s*\{', css):
        awal_baris = css.rfind('\n', 0, m.start()) + 1
        if css[awal_baris:m.start()].strip():
            continue
        gab.update(deklarasi(isi_blok(css, m.end() - 1), token=False))
    return gab


global_root = blok_ber_selektor(':root')

# 1. kelengkapan token warna & suasana di setiap tema
WAJIB = ['--bg', '--surface', '--surface-2', '--kaca', '--text', '--text-muted', '--border', '--border-kuat',
         '--accent', '--accent-hover', '--accent-contrast', '--accent-soft',
         '--success', '--success-soft', '--warn', '--warn-soft', '--danger', '--danger-soft', '--info', '--info-soft',
         '--glow', '--cincin', '--pola', '--sh-1', '--sh-2', '--sh-3', '--sh-4',
         '--font-display', '--font-body', '--radius', '--radius-sm', '--radius-lg']
for t in TEMA:
    kurang = [k for k in WAJIB if k not in blok[t]]
    periksa(not kurang, f'{NAMA[t]}: {len(WAJIB)} token wajib lengkap',
            'kurang: ' + ', '.join(kurang) if kurang else '')

# 2. tangga jarak (--s-1 .. --s-10)
s = [global_root.get('--s-%d' % i) for i in range(1, 11)]
periksa(all(s), 'Tangga jarak --s-1..--s-10 tersedia',
        'hilang: ' + ', '.join('--s-%d' % i for i, v in enumerate(s, 1) if not v) if not all(s) else '')
angka_s = [int(v.replace('px', '')) for v in s if v and v.endswith('px')]
periksa(len(angka_s) == 10 and angka_s == sorted(angka_s) and len(set(angka_s)) == 10,
        'Tangga jarak naik berurutan',
        '-> ' + ' < '.join(str(x) for x in angka_s) if angka_s else '')
periksa(all(x % 4 == 0 for x in angka_s), 'Tangga jarak kelipatan 4 px',
        'tidak kelipatan 4: ' + ', '.join(str(x) for x in angka_s if x % 4) if any(x % 4 for x in angka_s) else '')

# 3. tangga ukuran huruf (--t-1 .. --t-10)
t_skala = [global_root.get('--t-%d' % i) for i in range(1, 11)]
periksa(all(t_skala), 'Tangga huruf --t-1..--t-10 tersedia',
        'hilang: ' + ', '.join('--t-%d' % i for i, v in enumerate(t_skala, 1) if not v) if not all(t_skala) else '')
px = [int(v.replace('px', '')) for v in t_skala if v and v.endswith('px')]
periksa(len(px) >= 8 and px == sorted(px) and len(set(px)) == len(px), 'Tangga huruf naik berurutan',
        '-> ' + ' < '.join(str(x) for x in px) + ' (+ 2 ukuran judul besar)' if px else '')
periksa(global_root.get('--t-5') == '16px', 'Huruf isi minimal 16 px', '--t-5 = ' + str(global_root.get('--t-5')))

# 4. ukuran sentuh minimal 44 px
def min_height(selektor, kelas_atur='min-height'):
    return blok_ber_selektor(selektor).get(kelas_atur)


def ada_aturan(teks):
    return bool(re.search(teks, css))

SENTUH = [('.btn', 'min-height'), ('.input', 'min-height'), ('.tab', 'min-height'),
          ('.pay', 'min-height'), ('.btn-ikon', 'width'), ('.tombol-tambah', 'width'), ('.nav-bawah a', 'min-height')]
def selesai_var(nilai):
    """Selesaikan `var(--token)` berantai sampai jadi nilai mentah (mis. `48px`)."""
    for _ in range(8):
        m = re.fullmatch(r'var\(\s*(--[a-z0-9-]+)\s*\)', (nilai or '').strip())
        if not m:
            break
        nilai = (global_root.get(m.group(1)) or '').strip()
    return nilai


for sel, prop in SENTUH:
    v = min_height(sel, prop)
    nyata = selesai_var(v)
    n = int(nyata.replace('px', '')) if nyata and nyata.endswith('px') else 0
    periksa(n >= 44, f'Sentuh {sel} >= 44 px', f'{prop}: {v} -> {nyata}')

# tombol ramping: tampak kecil, tapi daerah sentuh diperluas lewat lapisan tak terlihat
periksa(ada_aturan(r'\.btn-sm\{[^}]*min-height:40px') and ada_aturan(r'\.btn-sm::after\{[^}]*inset:-6px'),
        'Tombol kecil tetap nyaman disentuh', '.btn-sm 40 px + daerah sentuh ~52 px')
periksa(ada_aturan(r'\.segmen button\{[^}]*position:relative') and ada_aturan(r'\.segmen button::after\{[^}]*inset:-4px'),
        'Tombol pemilih (segmen) tetap nyaman disentuh', '36 px + daerah sentuh 44 px')

# 5. cincin fokus & mode kurangi gerak
periksa(ada_aturan(r':where\(a,button,summary,input,select,textarea,\[tabindex\]\):focus-visible'),
        'Semua yang bisa ditekan punya cincin fokus', 'aturan :where(...):focus-visible ada')
periksa(css.count(':focus-visible') >= 4, 'Cincin fokus dipasang di banyak komponen',
        f'{css.count(":focus-visible")} tempat memakai --cincin')
periksa('prefers-reduced-motion' in css and 'transition-duration:.001ms' in css,
        'Mode "kurangi gerak" dihormati', 'blok prefers-reduced-motion ada')

# 6. bayangan berlapis (kedalaman) di setiap tema
#    - tema biasa: --sh-3 & --sh-4 harus bertingkat (>= 2 lapisan)
#    - tema "kontras": sengaja rata, bayangannya diganti garis tegas (bukan bayangan)
kurang_lapis = []
for t in TEMA:
    if t == 'kontras':
        datar = all(blok[t].get('--sh-%d' % i, '').startswith(('none', '0 0 0')) for i in range(1, 5))
        if not datar:
            kurang_lapis.append('kontras (harus rata/garis)')
        continue
    for i in (3, 4):
        v = blok[t].get('--sh-%d' % i, '')
        if v.count('rgba(') + v.count('var(') < 2:
            kurang_lapis.append(f'{t}/--sh-{i}')
periksa(not kurang_lapis, 'Bayangan bertingkat (kedalaman) di semua tema',
        'kurang: ' + ', '.join(kurang_lapis) if kurang_lapis else '18 dari 18 perlu; tema Kontras sengaja rata')

# 6b. bayangan di tema terang diberi warna (bukan hitam pekat) supaya terlihat mahal
TERANG = ['terang', 'hangat', 'vintage', 'alam', 'tropis', 'pastel', 'etnik']
hitam_pekat = [f'{t}/--sh-{i}' for t in TERANG for i in range(1, 5)
               if 'rgba(0,0,0' in blok[t].get('--sh-%d' % i, '')]
periksa(not hitam_pekat, 'Bayangan tema terang berwarna (tidak hitam pekat)',
        'hitam pekat: ' + ', '.join(hitam_pekat) if hitam_pekat else '7 tema terang memakai bayangan bernuansa')

# 7. cahaya (glow) & pola latar
tanpa = [t for t in TEMA if blok[t].get('--glow', 'none') == 'none']
periksa(not tanpa, 'Setiap tema punya cahaya (glow) sendiri', 'tanpa glow: ' + ', '.join(tanpa) if tanpa else '')
periksa(all('--pola' in blok[t] for t in TEMA), 'Setiap tema punya pola latar (boleh "none")')

# 8. tangga sudut (radius)
salah = [t for t in TEMA
         if not (blok[t].get('--radius-sm', '').endswith('px') and blok[t].get('--radius', '').endswith('px')
                 and blok[t].get('--radius-lg', '').endswith('px'))]
periksa(not salah, 'Setiap tema punya 3 tingkat sudut (kecil/sedang/besar)',
        'bermasalah: ' + ', '.join(salah) if salah else '')

# 9. huruf benar-benar tersimpan (offline)
face = {}
for m in re.finditer(r'@font-face\{([^}]*)\}', css):
    d = deklarasi(m.group(1), token=False)
    fam = (d.get('font-family') or '').strip().strip('"').strip("'")
    url = d.get('src') or ''
    berkas = re.findall(r"url\('([^']+)'\)", url)
    if fam:
        face.setdefault(fam, []).append(berkas[0] if berkas else '')

hilang_berkas = []
for fam, daftar in face.items():
    for f in daftar:
        # alamat di dalam CSS ('../aset/font/...') dihitung dari folder css/
        jalur = os.path.normpath(os.path.join(BASE, 'css', f))
        if not os.path.exists(jalur):
            hilang_berkas.append(f'{fam} -> {f}')
periksa(not hilang_berkas, f'Semua berkas huruf ada di dalam aplikasi ({len(face)} keluarga)',
        'hilang: ' + ', '.join(hilang_berkas) if hilang_berkas else '')

SISTEM = {'system-ui', 'sans-serif', 'serif', 'ui-monospace', 'monospace', '-apple-system'}
luar = []
for t in TEMA:
    for tok in ('--font-display', '--font-body'):
        v = blok[t].get(tok, '')
        m = re.match(r"^\s*'([^']+)'", v) or re.match(r'^\s*([A-Za-z-]+)', v)
        nama_huruf = m.group(1) if m else ''
        if nama_huruf and nama_huruf not in face and nama_huruf not in SISTEM:
            luar.append(f'{t}/{tok}={nama_huruf}')
periksa(not luar, 'Semua huruf tema tersedia tanpa internet',
        'mengandalkan luar: ' + ', '.join(luar) if luar else f'{len(face)} keluarga huruf tersimpan (woff2)')

# 10. satu berkas ukuran wajar (aplikasi ringan)
ukuran = sum(os.path.getsize(os.path.join(BASE, 'aset', 'font', f))
             for f in os.listdir(os.path.join(BASE, 'aset', 'font')) if f.endswith('.woff2'))
periksa(ukuran < 1_200_000, 'Berat huruf wajar (< 1,2 MB)', f'{ukuran / 1024:.0f} KB untuk {len(face)} keluarga')

for ok, judul, ket in atur:
    lolos += ok
    gagal += not ok
    print(f"  {'LOLOS' if ok else 'GAGAL':5s}  {judul}" + (f"  [{ket}]" if ket else ''))
    if not ok:
        print("         ^ PERIKSA: aturan ini belum terpenuhi")

print()
print(f"RINGKASAN: {lolos} lolos, {gagal} gagal  -  {len(TEMA)} tema, "
      f"{len(TEMA) * len(PASANGAN)} pemeriksaan warna, {len(atur)} pemeriksaan aturan desain")
sys.exit(1 if gagal else 0)
