#!/usr/bin/env python3
"""artefak.py — memisahkan "berkas", "perintah", "pola", dan yang benar-benar hilang.

Kenapa ada (temuan audit I F-20 & H F-05, K-3, 2026-09-19; dirapikan 2026-09-20): dua mesin
proyek ini menuduh sesuatu sebagai "berkas hilang" hanya dengan `(AKAR / token).exists()`:

  * **pembuat paket audit** (`alat/audit-independen.py`) menulis 13 baris
    "sudah [x] — berkasnya TIDAK ADA: laporkan!" untuk jalur yang NYATA — `python3
    alat/periksa-roadmap.py` (perintah), `aplikasi/src/komponen/*.tsx` (pola yang cocok 13 berkas),
    `src/lib/tema.ts` (jalur relatif folder `aplikasi/`). Auditor lalu mencari bukti yang tidak
    pernah hilang, dan temuan palsu itu ikut terbit ke paket.
  * **pemeriksa daftar temuan** (`alat/periksa-temuan-audit.py`) menolak bukti penutup yang bentuknya
    pola atau jalur relatif — padahal buktinya hidup.

Aturannya sekarang satu tempat: sebuah token boleh disebut "hilang" HANYA kalau ia bukan perintah,
bukan pola yang cocok, dan tidak ada di akar maupun di folder kerja yang lazim dipakai dokumen.

Kelas yang dikembalikan `pisah_artefak`: `berkas` · `perintah` · `pola` · `hilang` · `pola-kosong`
· `perintah-hilang`. Semua kelas "tidak hilang" dipakai lewat `adakah_artefak()`.
"""
from __future__ import annotations

import glob as _glob
import pathlib
import re

AKAR = pathlib.Path(__file__).resolve().parent.parent

# Perintah di dokumen hampir selalu dimulai salah satu dari ini; sisanya adalah argumennya.
INTERPRETER = {"python", "python3", "node", "npm", "npx", "bash", "sh", "deno", "git", "cd",
               "make", "pwsh", "powershell", "tsc", "vite", "pip", "pip3"}

# Folder kerja yang lazim dipakai di dokumen: `src/lib/tema.ts` artinya `aplikasi/src/lib/tema.ts`.
AKAR_RELATIF = ("aplikasi", "alat", "supabase", "docs", "aplikasi/src", "aplikasi/alat",
                "aplikasi/src/lib", "aplikasi/e2e", "_sistem")


def _jalur_nyata(kandidat: str, akar: pathlib.Path) -> str | None:
    """Jalur nyata (relatif akar) yang ditunjuk kandidat, atau None."""
    k = kandidat.strip("\"'(),;`")
    if not k or k.startswith("-") or k.startswith("$"):
        return None
    if (akar / k).exists():
        return k
    for rel in AKAR_RELATIF:
        if (akar / rel / k).exists():
            return f"{rel}/{k}"
    return None


def _pola_cocok(pola: str, akar: pathlib.Path) -> int:
    """Banyaknya berkas nyata yang cocok dengan pola (glob), tiap berkas dihitung sekali."""
    jumpa: set[str] = set()
    for rel in ("",) + AKAR_RELATIF:
        for p in _glob.glob(str(akar / rel / pola), recursive=True):
            jumpa.add(p)
    return len(jumpa)


def pisah_artefak(token: str, akar: pathlib.Path | None = None) -> tuple[str, str]:
    """Pisahkan satu token dari dokumen; keterangan selalu menyebut alasannya."""
    akar = akar or AKAR
    bersih = re.sub(r":\d+(?:\s*[–-]\s*\d+)?$", "", token.strip())   # buang rujukan baris
    bersih = bersih.strip().strip("`").strip()
    if not bersih:
        return "hilang", token.strip()
    if any(c in bersih for c in "*?["):
        n = _pola_cocok(bersih, akar)
        return ("pola", f"{bersih} (cocok {n} berkas nyata)") if n else ("pola-kosong", bersih)
    kata = bersih.split()
    if kata and kata[0].split("/")[-1] in INTERPRETER:
        for k in kata[1:]:
            nyata = _jalur_nyata(k, akar)
            if nyata:
                return "perintah", f"{bersih}  →  {nyata}"
        return "perintah-hilang", bersih
    if len(kata) > 1 and any(k.startswith("--") for k in kata[1:]):
        nyata = _jalur_nyata(kata[0], akar)
        return ("perintah", f"{bersih}  →  {nyata}") if nyata else ("perintah-hilang", bersih)
    nyata = _jalur_nyata(bersih, akar)
    return ("berkas", nyata) if nyata else ("hilang", bersih)


def adakah_artefak(token: str, akar: pathlib.Path | None = None) -> bool:
    """True bila token menunjuk sesuatu yang NYATA: berkas, perintah berisi berkas, atau pola yang cocok."""
    return pisah_artefak(token, akar)[0] in ("berkas", "perintah", "pola")


if __name__ == "__main__":  # pragma: no cover — alat bantu tangan
    import sys
    for t in sys.argv[1:]:
        print(f"{t!r} → {pisah_artefak(t)}")
