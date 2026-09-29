#!/usr/bin/env python3
"""H-F-17 · verifikasi ulang PMB1-F-136 (status DIPERBAIKI, commit 3f56abb) oleh hakim ketiga.

Apa yang diuji (memanggil artefak yang diuji, bukan meniru logikanya):
  A. SALINAN RUSAK + PENJAGA LAMA (versi `3f56abb^`, sebelum perbaikan)  → harus LOLOS (cacat F-136 memang nyata)
  B. SALINAN RUSAK + PENJAGA SEKARANG (HEAD)                           → harus GAGAL (perbaikan bekerja)
  C. KONTROL NEGATIF: salinan utuh + PENJAGA SEKARANG                  → harus LOLOS (penjaga tidak menolak yang benar)
  D. KONTROL NEGATIF: baris berputusan yang menyebut kartu H yang ADA  → harus LOLOS (tidak menolak putusan sah)

Mutasi: satu baris Buku Besar yang statusnya `BARU` diubah jadi `TERVERIFIKASI` dengan kolom Hakim
`arena/bukan-hakim H-TIDAK-ADA — bukan hakim sebenarnya` (kartu H itu tidak ada di `kartu/`).

Jalankan:  python3 docs/uji/pemeriksaan/PMB-1/bukti/H-F-17-verifikasi-F-136.py
"""
from __future__ import annotations

import importlib.util
import io
import contextlib
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

AKAR = pathlib.Path(__file__).resolve().parents[5]          # root repo (docs/uji/pemeriksaan/PMB-1/bukti/ → 5 tingkat ke atas)
PUTARAN = "docs/uji/pemeriksaan/PMB-1"
BB = f"{PUTARAN}/BUKU_BESAR_TEMUAN.md"
COMMIT_PERBAIKAN = "3f56abb"
ABAIKAN = (".git", "node_modules", "dist", "build", "coverage", ".vite", "__pycache__", ".pytest_cache")


def salin() -> pathlib.Path:
    tujuan = pathlib.Path(tempfile.mkdtemp(prefix="h-f-17-")) / "repo"
    shutil.copytree(AKAR, tujuan, ignore=lambda _d, isi: {n for n in isi if n in ABAIKAN}, symlinks=True)
    subprocess.run(["git", "init", "-q"], cwd=tujuan, check=False, capture_output=True, timeout=60)
    return tujuan


def muat_penjaga(akar: pathlib.Path, nama_modul: str):
    """Muat alat/periksa-pemeriksaan.py dari salinan itu (bukan dari repo asli)."""
    for m in ("artefak", "bantu_uji_diri", "susun_matriks"):
        sys.modules.pop(m, None)
    sys.path.insert(0, str(akar / "alat"))
    spec = importlib.util.spec_from_file_location(nama_modul, akar / "alat" / "periksa-pemeriksaan.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)                             # type: ignore[unionion-attr]
    return mod


def jalankan(akar: pathlib.Path, nama_modul: str) -> tuple[int, str]:
    mod = muat_penjaga(akar, nama_modul)
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        kode = mod.periksa(akar)
    return kode, buf.getvalue()


def baris_berubah(teks: str, fid: str, status: str, hakim: str) -> str:
    for i, b in enumerate(teks.splitlines()):
        if b.startswith(f"| {fid} |"):
            sel = [s.strip() for s in b.strip().strip("|").split("|")]
            sel[7], sel[8] = status, hakim
            garis = teks.splitlines()
            garis[i] = "| " + " | ".join(sel) + " |"
            return "\n".join(garis) + "\n"
    raise SystemExit(f"baris {fid} tidak ditemukan")


def id_baru(akar: pathlib.Path) -> str:
    teks = (akar / BB).read_text(encoding="utf-8")
    for m in re.finditer(r"^\| (PMB1-F-\d{3}) \| K-\d \| \S+ \|", teks, re.M):
        sel = [s.strip() for s in next(b for b in teks.splitlines() if b.startswith(f"| {m.group(1)} |")).strip().strip("|").split("|")]
        if sel[7] == "BARU":
            return m.group(1)
    raise SystemExit("tidak ada baris BARU untuk dimutasi")


def utama() -> int:
    versi_lama = subprocess.run(["git", "show", f"{COMMIT_PERBAIKAN}^:alat/periksa-pemeriksaan.py"],
                                cwd=AKAR, capture_output=True, text=True, check=True).stdout
    tmp = salin()
    hasil: list[tuple[str, bool, str]] = []
    try:
        fid = id_baru(tmp)
        asli = (tmp / BB).read_text(encoding="utf-8")
        (tmp / "alat" / "periksa-pemeriksaan.py").write_text(versi_lama, encoding="utf-8")

        # A — cacat asli: penjaga LAMA diam saja
        (tmp / BB).write_text(baris_berubah(asli, fid, "TERVERIFIKASI",
                                            "arena/bukan-hakim H-TIDAK-ADA — bukan hakim sebenarnya"), encoding="utf-8")
        kode, keluar = jalankan(tmp, "penjaga_lama")
        hasil.append(("A. penjaga LAMA (3f56abb^) + baris TERVERIFIKASI kartu H palsu → harus LOLOS (cacat nyata)",
                      kode == 0, f"kode={kode} · {fid}"))

        # B — perbaikan: penjaga SEKARANG menolak
        shutil.copy2(AKAR / "alat" / "periksa-pemeriksaan.py", tmp / "alat" / "periksa-pemeriksaan.py")
        kode, keluar = jalankan(tmp, "penjaga_baru")
        pesan = [b for b in keluar.splitlines() if "kartu hakim yang ADA" in b]
        hasil.append(("B. penjaga SEKARANG (HEAD) + mutasi sama → harus GAGAL",
                      kode != 0 and bool(pesan), f"kode={kode} · {pesan[0].strip() if pesan else 'pesan penjaga tidak muncul'}"))

        # C — kontrol negatif: salinan utuh tetap diterima
        (tmp / BB).write_text(asli, encoding="utf-8")
        kode, keluar = jalankan(tmp, "penjaga_utuh")
        hasil.append(("C. KONTROL: salinan utuh + penjaga SEKARANG → harus LOLOS", kode == 0, f"kode={kode}"))

        # D — kontrol negatif: putusan sah yang menyebut kartu H yang ADA tidak ditolak
        (tmp / BB).write_text(baris_berubah(asli, fid, "TERVERIFIKASI",
                                            "arena/01a0eb76-resto-barokah H-F-17 — direproduksi hakim ketiga"), encoding="utf-8")
        kode, keluar = jalankan(tmp, "penjaga_sah")
        hasil.append(("D. KONTROL: TERVERIFIKASI menyebut kartu H yang ADA (H-F-17) → harus LOLOS",
                      kode == 0, f"kode={kode}" + ("" if kode == 0 else "\n" + keluar[-500:])))
    finally:
        shutil.rmtree(tmp.parent, ignore_errors=True)

    gagal = 0
    print("VERIFIKASI ULANG PMB1-F-136 (H-F-17 · arena/01a0eb76-resto-barokah)")
    for kasus, ok, ringkas in hasil:
        print(f"  {'OK ' if ok else 'X  '} {kasus} → {ringkas}")
        gagal += 0 if ok else 1
    print("\nHASIL: " + ("LOLOS — perbaikan 3f56abb terbukti menutup cacat F-136 (A merah-diam dulu, B menolak sekarang, C & D tidak menolak yang sah)"
                         if not gagal else f"GAGAL — {gagal} kasus tidak sesuai harapan"))
    return 1 if gagal else 0


if __name__ == "__main__":
    sys.exit(utama())
