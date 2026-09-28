#!/usr/bin/env python3
"""Periksa halaman contoh (prototipe) secara statis.

Tujuan: menangkap kerusakan yang tidak terlihat mata pemilik — tautan gambar
hilang, id lapisan mengambang yang salah, kaitan JavaScript yang tidak ada,
tag yang tidak seimbang, token tanpa definisi.

Sejak ronde 3 versi "KERAJINAN", pemilih tema TIDAK lagi ditulis di HTML:
ia dibangun oleh `js/ui.js` ke dalam wadah `[data-pemilih-tema]`. Karena itu
pemeriksa ini menuntut: setiap halaman punya wadah itu, DAN `js/ui.js` benar
memuat 10 tema (jadi pemilih di halaman mana pun pasti berisi 10 pilihan).

Dijalankan: python3 prototipe/alat/periksa-halaman.py
"""
import os
import re
import sys

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HALAMAN = ["index.html", "01-laporan.html", "02-kasir.html", "03-katalog.html", "04-tema.html"]
WAJIB = ["css/tokens.css", "js/ui.js"]
TEMA = ["terang", "hangat", "gelap", "kontras", "bara", "vintage", "alam", "tropis", "pastel", "etnik"]

gagal = []
periksa = 0


def catat(syarat, pesan):
    global periksa
    periksa += 1
    if not syarat:
        gagal.append(pesan)


def baca(nama):
    with open(os.path.join(AKAR, nama), encoding="utf-8") as f:
        return f.read()


def utama():
    ui = baca("js/ui.js")
    css = baca("css/tokens.css")
    terdefinisi = set(re.findall(r"(--[\w-]+)\s*:", css))

    # --- 0. js/ui.js memuat 10 tema & pembangun pemilih ---
    for kode in TEMA:
        catat(re.search(r"\['%s'," % kode, ui) is not None,
              f"js/ui.js: tema '{kode}' tidak ada di daftar")
    catat("data-pemilih-tema" in ui, "js/ui.js: tidak membangun pemilih tema")
    catat("terbuka" in ui and "lapis" in ui, "js/ui.js: tidak menangani lapisan mengambang")

    for nama in HALAMAN:
        jalur = os.path.join(AKAR, nama)
        catat(os.path.exists(jalur), f"{nama}: berkas tidak ada")
        if not os.path.exists(jalur):
            continue
        isi = baca(nama)

        # 1. pustaka wajib
        for w in WAJIB:
            catat(w in isi, f"{nama}: tidak memuat {w}")

        # 2. gambar & aset lokal benar-benar ada
        for src in re.findall(r'(?:src|href)="([^"#:?]+)"', isi):
            if src.startswith(("http", "mailto", "data:")) or src.endswith(".html"):
                continue
            catat(os.path.exists(os.path.join(AKAR, src)), f"{nama}: aset hilang -> {src}")

        # 3. setiap tombol pembuka lapisan punya lapisan dengan id yang cocok
        for idlap in set(re.findall(r'data-buka-lapis(?:an)?="#?([^"]+)"', isi)):
            catat(f'id="{idlap.lstrip("#")}"' in isi, f'{nama}: id lapisan "{idlap}" tidak ditemukan')
        for idlap in set(re.findall(r'id="(lapis-[^"]+)"', isi)):
            # boleh dibuka lewat tombol di halaman, atau lewat kaitan di js/ui.js
            catat(f'data-buka-lapis="#{idlap}"' in isi or idlap in ui,
                  f'{nama}: lapisan "{idlap}" tidak bisa dibuka')

        # 4. kaitan JavaScript (v3: toast & pemilih dibangun oleh ui.js)
        catat("js/ui.js" in isi, f"{nama}: tidak memuat js/ui.js")
        catat("data-pemilih-tema" in isi, f"{nama}: tidak ada wadah pemilih tema [data-pemilih-tema]")
        if "data-aksi=" in isi:
            catat("toast" in ui, f"{nama}: memakai data-aksi tetapi ui.js tidak punya pesan (toast)")
        if "data-bayar" in isi:
            catat("data-buka-lapis" in ui or "lapis-bayar" in ui,
                  f"{nama}: tombol bayar tidak dihubungkan ke lapisan pembayaran")
        if "data-kas-fisik" in isi:
            catat("data-selisih" in ui, f"{nama}: hitungan selisih kas tidak ada di ui.js")

        # 5. tag seimbang
        for tag in ["div", "section", "article", "nav", "aside", "table", "button", "span", "details"]:
            buka = len(re.findall(rf"<{tag}[\s>]", isi))
            tutup = len(re.findall(rf"</{tag}>", isi))
            catat(buka == tutup, f"{nama}: tag <{tag}> tidak seimbang (buka {buka}, tutup {tutup})")

        # 6. atribut penting aksesibilitas
        catat("<html lang=" in isi, f"{nama}: atribut bahasa tidak ada")
        catat("data-theme" in isi, f"{nama}: tidak ada tema awal")
        catat(isi.count("aria-label") >= 3, f"{nama}: terlalu sedikit label pembaca layar")

        # 7. tema: 10 pilihan. Boleh ditulis di halaman (index & galeri) atau
        #    dibangun ui.js lewat wadah data-pemilih-tema.
        statis = [t for t in TEMA if f'data-set-tema="{t}"' in isi]
        if len(statis) < 10:
            catat("data-pemilih-tema" in isi and all(re.search(r"\['%s'," % t, ui) for t in TEMA),
                  f"{nama}: pemilih tema hanya {len(statis)}/10 dan wadah pemilih tidak lengkap")

        # 8. token yang dipakai ada definisinya
        dipakai = set(re.findall(r"var\(\s*(--[\w-]+)", isi))
        kurang = sorted(dipakai - terdefinisi)
        catat(not kurang, f"{nama}: token tanpa definisi -> {kurang}")

    print(f"Periksa halaman: {periksa - len(gagal)}/{periksa} lolos")
    for g in gagal:
        print("  GAGAL:", g)
    return 1 if gagal else 0


if __name__ == "__main__":
    sys.exit(utama())
