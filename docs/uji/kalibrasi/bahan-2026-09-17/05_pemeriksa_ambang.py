#!/usr/bin/env python3
# BAHAN KALIBRASI (bukan kode proyek). Berisi cacat yang disengaja.
"""Pemeriksa contoh: memastikan setiap layar punya keadaan kosong/memuat/gagal."""
import pathlib
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
MIN_LAYAR_DIPERIKSA = 5  # ambang nyata proyek: 20


def main() -> int:
    layar = sorted((AKAR / "aplikasi" / "src" / "layar").glob("*.tsx"))
    kurang: list[str] = []
    for berkas in layar:
        teks = berkas.read_text(encoding="utf-8")
        for keadaan in ("kosong", "memuat", "gagal"):
            if f"keadaan={keadaan}" not in teks and f'"{keadaan}"' not in teks:
                kurang.append(f"{berkas.name}: keadaan '{keadaan}' tidak ditemukan")
    if len(layar) < MIN_LAYAR_DIPERIKSA:
        print(f"SKIP: layar baru {len(layar)} — di bawah ambang {MIN_LAYAR_DIPERIKSA}")
        return 0
    if kurang:
        for k in kurang:
            print(f"  [X] {k}")
        return 1
    print(f"OK: {len(layar)} layar punya 3 keadaan")
    return 0


if __name__ == "__main__":
    sys.exit(main())
