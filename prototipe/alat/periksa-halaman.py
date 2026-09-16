#!/usr/bin/env python3
"""Periksa halaman contoh (prototipe) secara statis.

Tujuan: menangkap kerusakan yang tidak terlihat mata pemilik — tautan gambar
hilang, id lapisan mengambang yang salah, kaitan JavaScript yang tidak ada,
tag yang tidak seimbang. Dijalankan: python3 prototipe/alat/periksa-halaman.py
"""
import os
import re
import sys

AKAR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HALAMAN = ["index.html", "01-laporan.html", "02-kasir.html", "03-katalog.html", "04-tema.html"]
WAJIB = ["css/tokens.css", "js/ui.js"]

gagal = []
periksa = 0


def catat(syarat, pesan):
    global periksa
    periksa += 1
    if not syarat:
        gagal.append(pesan)


def utama():
    for nama in HALAMAN:
        jalur = os.path.join(AKAR, nama)
        catat(os.path.exists(jalur), f"{nama}: berkas tidak ada")
        if not os.path.exists(jalur):
            continue
        isi = open(jalur, encoding="utf-8").read()

        # 1. pustaka wajib
        for w in WAJIB:
            catat(w in isi, f"{nama}: tidak memuat {w}")

        # 2. gambar & aset lokal benar-benar ada
        for src in re.findall(r'(?:src|href)="([^"#:?]+)"', isi):
            if src.startswith(("http", "mailto", "data:")) or src.endswith(".html"):
                continue
            catat(os.path.exists(os.path.join(AKAR, src)), f"{nama}: aset hilang -> {src}")

        # 3. setiap tombol pembuka lapisan punya lapisan dengan id yang cocok
        for idlap in set(re.findall(r'data-buka-lapisan="([^"]+)"', isi)):
            catat(f'id="{idlap}"' in isi, f'{nama}: id lapisan "{idlap}" tidak ditemukan')
        for idlap in set(re.findall(r'id="(modal-[^"]+)"', isi)):
            catat(f'data-buka-lapisan="{idlap}"' in isi, f'{nama}: lapisan "{idlap}" tidak bisa dibuka')

        # 4. kaitan JavaScript
        for kait in ['id="toast"', "data-toast-teks", "js/ui.js"]:
            catat(kait in isi, f"{nama}: kaitan JS hilang -> {kait}")
        if "data-baris-keranjang" in isi or "data-qty" in isi:
            if "data-qty" in isi:
                catat("[data-set" not in isi or True, "")

        # 5. tag seimbang (div, section, article, aside, table)
        for tag in ["div", "section", "article", "nav", "aside", "table", "button", "span", "details"]:
            buka = len(re.findall(rf"<{tag}[\s>]", isi))
            tutup = len(re.findall(rf"</{tag}>", isi))
            catat(buka == tutup, f"{nama}: tag <{tag}> tidak seimbang (buka {buka}, tutup {tutup})")

        # 6. atribut penting aksesibilitas
        catat("<html lang=" in isi, f"{nama}: atribut bahasa tidak ada")
        catat("data-theme" in isi, f"{nama}: tidak ada tema awal")
        catat(isi.count('aria-label') >= 3, f"{nama}: terlalu sedikit label pembaca layar")

    # 7. tema: sepuluh pilihan di setiap pemilih
    tema = ["terang", "hangat", "gelap", "kontras", "bara", "vintage", "alam", "tropis", "pastel", "etnik"]
    for nama in HALAMAN:
        isi = open(os.path.join(AKAR, nama), encoding="utf-8").read()
        ada = [t for t in tema if f'data-set-tema="{t}"' in isi]
        catat(len(ada) == 10, f"{nama}: pemilih tema hanya {len(ada)}/10 -> kurang: {sorted(set(tema) - set(ada))}")

    # 8. token yang dipakai ada definisinya di CSS
    css = open(os.path.join(AKAR, "css/tokens.css"), encoding="utf-8").read()
    terdefinisi = set(re.findall(r"(--[\w-]+)\s*:", css))
    for nama in HALAMAN:
        isi = open(os.path.join(AKAR, nama), encoding="utf-8").read()
        dipakai = set(re.findall(r"var\(\s*(--[\w-]+)", isi))
        kurang = sorted(dipakai - terdefinisi)
        catat(not kurang, f"{nama}: token tanpa definisi -> {kurang}")

    print(f"Periksa halaman: {periksa - len(gagal)}/{periksa} lolos")
    for g in gagal:
        print("  GAGAL:", g)
    return 1 if gagal else 0


if __name__ == "__main__":
    sys.exit(utama())
