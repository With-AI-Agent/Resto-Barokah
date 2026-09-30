#!/usr/bin/env python3
"""Uji-diri peta-ui (PMB1-F-096, kartu B-F-07) — pembungkus tipis `alat/peta-ui.py --uji-diri`.

Kenapa ada: penjaga Buku Besar (K4 Jaminan Tuntas) mengenali berkas bukti mesin
berpola `alat/uji-*.py`; alat aslinya bernama `peta-ui.py` sehingga bukti mutasinya
tidak terbaca penjaga. Pembungkus ini menjalankan mutasi yang sama persis (7 mutasi
fail-closed, termasuk Mutasi 7 Aturan 6b "nama fitur wajib cocok judul PRD").
"""
import importlib.util
import sys
from pathlib import Path

_spec = importlib.util.spec_from_file_location("peta_ui", Path(__file__).with_name("peta-ui.py"))
_modul = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_modul)

if __name__ == "__main__":
    sys.exit(_modul.uji_diri())
