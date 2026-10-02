#!/usr/bin/env python3
"""Cek HAKIM H-F-03.5 (2026-10-02): adakah baris DIPERBAIKI di potongan G-04 (PROMPT_GILIRAN §5: cek sebelum selesai)?
Cara jalan (dari akar repo): python3 docs/uji/pemeriksaan/PMB-1/bukti/H-F-03.5-cek-g04.py
Hanya membaca BUKU_BESAR_TEMUAN.md (11 kolom per baris temuan)."""
import pathlib

AKAR = pathlib.Path(__file__).resolve().parents[5]
buku = (AKAR / "docs/uji/pemeriksaan/PMB-1/BUKU_BESAR_TEMUAN.md").read_text(encoding="utf-8")
baris_g04 = []
for baris in buku.splitlines():
    if not baris.startswith("| PMB1-F-"):
        continue
    sel = [x.strip() for x in baris.strip().strip("|").split("|")]
    if len(sel) == 11 and sel[2] == "G-04":
        baris_g04.append((sel[0], sel[1], sel[7]))
for fid, tingkat, status in baris_g04:
    print(f"{fid} {tingkat} {status}")
diperbaiki = [fid for fid, _t, status in baris_g04 if status == "DIPERBAIKI"]
print(f"G-04: {len(baris_g04)} baris; DIPERBAIKI = {len(diperbaiki)} {diperbaiki if diperbaiki else ''}".rstrip())
