#!/usr/bin/env python3
"""bantu_uji_diri.py — alat bantu untuk pemeriksa yang punya mode `--uji-diri`.

Kenapa ada: standar proyek (PROTOKOL_AUDIT_INDEPENDEN §8) — **pemeriksa yang tidak bisa
MERAH dianggap belum terpasang**. Cara membuktikannya: salin pohon repo ke folder
sementara, rusak satu hal di salinan itu, lalu pastikan pemeriksa MENOLAK salinan yang
rusak dan MENERIMA salinan yang utuh. Berkas ini menyediakan penyalinnya supaya tiap
pemeriksa tidak menulis ulang logika salin yang sama.

Cara pakai dari pemeriksa lain:

    from bantu_uji_diri import salin_pohon, jalankan_pemeriksa
    with salin_pohon() as tmp:
        kode, keluaran = jalankan_pemeriksa(periksa, tmp)   # periksa = callable(akar) -> int
"""
from __future__ import annotations

import contextlib
import io
import pathlib
import shutil
import subprocess
import tempfile

AKAR = pathlib.Path(__file__).resolve().parent.parent

# Tidak perlu disalin: terlalu besar atau memang bukan sumber kebenaran.
# Catatan: `skills/` dan `prototipe/` TIDAK diabaikan — dokumen pengikat merujuk isinya,
# jadi salinan uji harus punya berkas itu supaya "salinan utuh" benar-benar utuh.
ABAIKAN = (
    ".git", "node_modules", "dist", "build", "coverage",
    ".vite", "__pycache__", ".pytest_cache", "alat/node_modules",
)


def _abaikan(_dir: str, isi: list[str]) -> set[str]:
    return {n for n in isi if n in ABAIKAN}


@contextlib.contextmanager
def salin_pohon():
    """Salin repo (tanpa folder besar) ke folder sementara, beri jalan sebagai context."""
    tujuan = pathlib.Path(tempfile.mkdtemp(prefix="uji-diri-"))
    try:
        shutil.copytree(AKAR, tujuan / "repo", ignore=_abaikan, symlinks=True)
        # Salinan diberi repo Git KOSONG. Sebabnya: `.git` sengaja tidak ikut disalin,
        # padahal ada pemeriksa yang membuktikan `.gitignore` benar-benar bekerja lewat
        # `git check-ignore`. Tanpa langkah ini, salinan utuh selalu GAGAL 2 kali
        # (`.env` "tidak diabaikan", `.env.example` "diabaikan") — GAGAL PALSU yang
        # membuat uji-diri pemeriksa itu mustahil hijau (catatan lama: periksa-komponen-env).
        # `git init` cukup untuk `git check-ignore`; riwayat commit tidak dibutuhkan.
        with contextlib.suppress(Exception):
            subprocess.run(["git", "init", "-q"], cwd=tujuan / "repo", check=False,
                           capture_output=True, timeout=30)
        yield tujuan / "repo"
    finally:
        shutil.rmtree(tujuan, ignore_errors=True)


def jalankan_pemeriksa(pemeriksa, akar: pathlib.Path) -> tuple[int, str]:
    """Jalankan pemeriksa(akar) -> kode, sambil menangkap keluarannya."""
    buf = io.StringIO()
    with contextlib.redirect_stdout(buf):
        kode = pemeriksa(akar)
    return kode, buf.getvalue()


def laporkan(nama: str, hasil: list[tuple[str, bool, str]]) -> int:
    """Cetak ringkasan uji-diri. hasil = [(nama kasus, sesuai harapan?, kode:keluaran)]."""
    print(f"UJI-DIRI {nama}")
    gagal = 0
    for kasus, sesuai, ringkas in hasil:
        tanda = "OK " if sesuai else "X  "
        if not sesuai:
            gagal += 1
        print(f"  {tanda} {kasus} → {ringkas}")
    if gagal:
        print(f"\nHASIL: GAGAL — {gagal} kasus uji-diri tidak sesuai harapan (pemeriksa mungkin tumpul)")
        return 1
    print("\nHASIL: LOLOS — pemeriksa terbukti bisa MENOLAK yang rusak dan MENERIMA yang utuh.")
    return 0
