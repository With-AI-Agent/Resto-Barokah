#!/usr/bin/env python3
"""periksa-angka-bukti.py — penjaga ANGKA di klaim "Bukti" ROADMAP (temuan audit F-14).

Masalah yang dicegah: blok **Bukti** di `docs/ROADMAP.md` ditulis sekali pada tanggal
pengerjaan lalu tidak pernah disegarkan, sementara kode terus berjalan. Audit AUD-3
2026-09-18 menemukan tiga angka berbeda untuk hal yang sama ("17 uji komponen + 22 uji
lain" · "39 uji" · "51 uji hijau dalam 7 berkas") padahal nyatanya 76 uji dalam 10 berkas,
dan dua angka tabel ("16 tabel" · "23 tabel") padahal nyatanya 26 — tanpa satu pun
pemeriksa yang bisa MERAH.

Aturan yang ditegakkan (dan kenapa):
* Angka yang ditulis di klaim Bukti hanya boleh muncul bersama **perintah yang bisa
  diulang** (di dalam tanda kutip-balik) ATAU penanda jujur **"angka saat itu"**.
  Angka tanpa keduanya adalah klaim yang tidak bisa dibuktikan hari ini — persis jenis
  klaim yang dilarang protokol audit.

Jalankan: python3 alat/periksa-angka-bukti.py [--uji-diri]
"""
from __future__ import annotations

import pathlib
import re
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
ROADMAP = AKAR / "docs" / "ROADMAP.md"

# Perintah yang membuktikan angka: hasilnya bisa dijalankan ulang oleh siapa pun.
PERINTAH_BUKTI = (
    "npm test", "vitest", "pg_tables", "uji-sql", "--daftar", "count(*)",
    "npm ci", "periksa-",
)
POLA_ANGKA = re.compile(r"\b\d+\s+(uji|tabel)\b", re.IGNORECASE)
POLA_KLAIM = re.compile(r"\*\*Bukti", re.IGNORECASE)
PENANDA_JUJUR = "angka saat itu"


def periksa(akar: pathlib.Path) -> tuple[int, list[str]]:
    roadmap = akar / "docs" / "ROADMAP.md"
    if not roadmap.is_file():
        return 1, ["docs/ROADMAP.md tidak ada — tidak bisa diperiksa"]
    salah: list[str] = []
    for i, baris in enumerate(roadmap.read_text(encoding="utf-8").splitlines(), start=1):
        if not POLA_KLAIM.search(baris) or not POLA_ANGKA.search(baris):
            continue
        ada_perintah = any(p in baris for p in PERINTAH_BUKTI)
        jujur = PENANDA_JUJUR in baris.lower()
        if not (ada_perintah or jujur):
            salah.append(
                f"docs/ROADMAP.md:{i} memuat angka uji/tabel di klaim Bukti tanpa perintah "
                f"yang bisa diulang dan tanpa penanda \"{PENANDA_JUJUR}\" — "
                f"angka seperti ini akan basi tanpa ada yang bisa MERAH (F-14)"
            )
    return (1 if salah else 0), salah


def uji_diri() -> int:
    """Buktikan pemeriksa ini bisa MERAH, bukan sekadar mencetak OK."""
    import shutil
    import tempfile

    hasil: list[tuple[str, bool, str]] = []
    with tempfile.TemporaryDirectory(prefix="angka-bukti-") as tmp:
        salinan = pathlib.Path(tmp) / "repo"
        salinan.mkdir()
        (salinan / "docs").mkdir()
        shutil.copy2(ROADMAP, salinan / "docs" / "ROADMAP.md")
        kode, _ = periksa(salinan)
        hasil.append(("salinan utuh", kode == 0, f"kode {kode}"))

        # Mutasi 1: perintah dihapus dari satu klaim → harus GAGAL.
        teks = (salinan / "docs" / "ROADMAP.md").read_text(encoding="utf-8")
        baris = [b for b in teks.splitlines() if POLA_KLAIM.search(b) and POLA_ANGKA.search(b) and any(p in b for p in PERINTAH_BUKTI)]
        if baris:
            kena = baris[0]
            mutasi = teks.replace(kena, f"**Bukti 2026-09-18:** 76 uji hijau.", 1)
            (salinan / "docs" / "ROADMAP.md").write_text(mutasi, encoding="utf-8")
            kode, _ = periksa(salinan)
            hasil.append(("mutasi: perintah dihapus dari klaim angka", kode != 0,
                          "ditolak" if kode != 0 else "DILOLOSKAN (tumpul)"))
            (salinan / "docs" / "ROADMAP.md").write_text(teks, encoding="utf-8")
        else:
            hasil.append(("mutasi: perintah dihapus dari klaim angka", False,
                          "tidak ada klaim angka berperintah untuk dimutasi"))

        # Mutasi 2: penanda "angka saat itu" dihapus dari klaim yang hanya memakai penanda itu.
        baris_jujur = [b for b in teks.splitlines() if POLA_KLAIM.search(b) and POLA_ANGKA.search(b)
                       and PENANDA_JUJUR in b.lower() and not any(p in b for p in PERINTAH_BUKTI)]
        if baris_jujur:
            kena = baris_jujur[0]
            mutasi = teks.replace(kena, kena.replace(PENANDA_JUJUR, "akhir-akhir ini"), 1)
            (salinan / "docs" / "ROADMAP.md").write_text(mutasi, encoding="utf-8")
            kode, _ = periksa(salinan)
            hasil.append(("mutasi: penanda jujur dihapus", kode != 0,
                          "ditolak" if kode != 0 else "DILOLOSKAN (tumpul)"))
        else:
            hasil.append(("mutasi: penanda jujur dihapus", True,
                          "tidak ada klaim yang memakai penanda saja (aturan tetap berlaku)"))

    print("UJI-DIRI periksa-angka-bukti")
    gagal = 0
    for kasus, sesuai, ringkas in hasil:
        tanda = "OK " if sesuai else "X  "
        if not sesuai:
            gagal += 1
        print(f"  {tanda} {kasus} → {ringkas}")
    if gagal:
        print(f"\nHASIL: GAGAL — {gagal} kasus uji-diri tidak sesuai harapan (pemeriksa mungkin tumpul)")
        return 1
    print("\nHASIL: LOLOS — pemeriksa terbukti bisa MENOLAK angka tanpa bukti dan MENERIMA yang jujur.")
    return 0


def main() -> int:
    if "--uji-diri" in sys.argv:
        return uji_diri()
    kode, salah = periksa(AKAR)
    print("PERIKSA ANGKA BUKTI ROADMAP — setiap angka uji/tabel wajib punya perintah atau penanda jujur")
    for s in salah:
        print(f"  [X] {s}")
    print("-" * 70)
    if salah:
        print(f"HASIL: GAGAL — {len(salah)} klaim angka tanpa bukti (F-14)")
        return 1
    print("HASIL: LOLOS — semua angka di klaim Bukti bisa direproduksi atau ditandai jujur.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
