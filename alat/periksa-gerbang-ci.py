#!/usr/bin/env python3
"""Pemeriksa gerbang CI — memastikan langkah pengaman di GitHub Actions TIDAK hilang/melemah.

Kenapa ada: temuan palsu peninjau PR-01 (putaran11, 2026-09-17). Peninjau membaca diff
`ci.yml` dan menyimpulkan bahwa langkah "Uji SQL" memakai `node alat/uji-sql.mjs --daftar`
sehingga "tidak menjalankan 28 berkas uji". Kesimpulan itu SALAH — `--daftar` hanya
MENAMBAH cetakan daftar tabel, uji tetap dijalankan (dibuktikan dengan menyuntikkan uji
yang sengaja gagal → `uji: 27 LULUS · 1 GAGAL`, exit 1). Tetapi nama opsinya memang
menjebak, dan itu kelas cacat yang nyata: **gerbang CI yang tampak ada bisa disalahbaca
(atau diam-diam dilemahkan) tanpa ada yang menangkap.**

Dua perbaikan dari pelajaran itu:
  1. Langkah CI memakai perintah penuh (tanpa `--daftar`) dan namanya menyebut "penuh".
  2. Pemeriksa ini mengunci gerbang-gerbang wajib: kalau salah satunya hilang, diturunkan
     ambangnya, atau diberi `|| true`/`continue-on-error`, pemeriksa MERAH.

Jalankan:  python3 alat/periksa-gerbang-ci.py [--uji-diri]
"""

from __future__ import annotations

import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

AKAR = pathlib.Path(__file__).resolve().parents[1]
CI = AKAR / ".github" / "workflows" / "ci.yml"

# Gerbang wajib: (nama untuk pesan, pola yang HARUS ada di berkas CI)
# Catatan pola: setiap pola DIANKUR `$` (akhir baris) supaya cocok dengan langkah aslinya,
# bukan dengan baris uji-diri (`… --uji-diri`) — pelajaran dari uji-diri pertama pemeriksa ini:
# tanpa `$`, menghapus langkah asli tetap lolos karena baris `--uji-diri` ikut cocok.
GERBANG_WAJIB = [
    ("suite uji SQL penuh", r"node\s+alat/uji-sql\.mjs\s*$"),
    ("bukti mutasi pagar migrasi 0012", r"python3\s+alat/uji-mutasi-0012\.py\s*$"),
    ("kerentanan dependency (npm audit, 0 toleransi)", r"npm audit --audit-level=low\s*$"),
    ("validator sistem", r"python3\s+_sistem/validate_system\.py\s*$"),
    ("pemeriksa pohon bersih", r"python3\s+alat/periksa-bersih\.py\s*$"),
    ("pemeriksa temuan audit", r"python3\s+alat/periksa-temuan-audit\.py\s*$"),
    ("pemeriksa buku uji", r"python3\s+alat/periksa-buku-uji\.py\s*$"),
    ("pemeriksa rujukan dokumen", r"python3\s+alat/periksa-rujukan\.py\s*$"),
    ("pemeriksa gerbang CI", r"python3\s+alat/periksa-gerbang-ci\.py\s*$"),
]

# Pola pelemahan senyap yang dilarang
PELEMAHAN = [
    (r"continue-on-error:\s*true", "langkah diberi `continue-on-error: true` (gagal tidak memerahkan CI)"),
    (r"^\s*run:\s*.*\|\|\s*true", "perintah diberi `|| true` (gagal ditelan)"),
    (r"^\s*run:\s*exit\s+0", "perintah diganti `exit 0`"),
]


def periksa(akar: pathlib.Path) -> tuple[int, list[str]]:
    ci = akar / ".github" / "workflows" / "ci.yml"
    pesan: list[str] = []
    if not ci.is_file():
        return 1, [f"berkas CI tidak ada: {ci}"]
    teks = ci.read_text(encoding="utf-8")

    kurang: list[str] = []
    for nama, pola in GERBANG_WAJIB:
        if not re.search(pola, teks, re.M):
            kurang.append(nama)
    if kurang:
        pesan.append(
            "gerbang wajib tidak ditemukan di .github/workflows/ci.yml: " + ", ".join(kurang)
        )

    for pola, alasan in PELEMAHAN:
        for cocok in re.finditer(pola, teks, re.M):
            baris = teks[: cocok.start()].count("\n") + 1
            pesan.append(f"pelemahan gerbang di baris {baris}: {alasan}")

    for i, baris_ci in enumerate(teks.splitlines(), start=1):
        if baris_ci.lstrip().startswith("#"):
            continue  # komentar boleh menyebut --daftar (justru menjelaskan kenapa tidak dipakai)
        if "--daftar" in baris_ci and "uji-sql" in baris_ci:
            pesan.append(
                f"baris {i}: langkah CI memakai `--daftar`. Opsi itu TETAP menjalankan uji, tetapi "
                "namanya menjebak dan sudah pernah menyesatkan peninjau — pakai perintah penuh "
                "`node alat/uji-sql.mjs` supaya tidak ada yang bisa salah baca"
            )

    return (1 if pesan else 0), pesan


def _jalankan(skrip: pathlib.Path, cwd: pathlib.Path) -> tuple[int, str]:
    """Jalankan SALINAN pemeriksa di dalam pohon uji (bukan berkas asli) supaya
    mutasi benar-benar dinilai oleh salinan itu."""
    hasil = subprocess.run(
        [sys.executable, str(skrip)], capture_output=True, text=True, cwd=str(cwd)
    )
    return hasil.returncode, hasil.stdout + hasil.stderr


def uji_diri() -> int:
    """Buktikan pemeriksa ini bisa MENOLAK yang rusak dan MENERIMA yang utuh."""
    kasus: list[tuple[str, int]] = []
    akar_asli = AKAR
    with tempfile.TemporaryDirectory(prefix="gerbang-ci-") as tmp:
        tmp_p = pathlib.Path(tmp)
        (tmp_p / ".github" / "workflows").mkdir(parents=True)
        shutil.copy2(akar_asli / ".github" / "workflows" / "ci.yml", tmp_p / ".github" / "workflows" / "ci.yml")
        (tmp_p / "alat").mkdir(parents=True, exist_ok=True)
        shutil.copy2(akar_asli / "alat" / "periksa-gerbang-ci.py", tmp_p / "alat" / "periksa-gerbang-ci.py")

        skrip_uji = tmp_p / "alat" / "periksa-gerbang-ci.py"
        kode, keluar = _jalankan(skrip_uji, tmp_p)
        kasus.append(("salinan utuh → diterima", kode == 0))
        if kode != 0:
            print(keluar[:1200])

        def mutasi(nama: str, ubah) -> None:
            ci = tmp_p / ".github" / "workflows" / "ci.yml"
            asli = ci.read_text(encoding="utf-8")
            ci.write_text(ubah(asli), encoding="utf-8")
            kode_m, keluar_m = _jalankan(skrip_uji, tmp_p)
            kasus.append((f"mutasi: {nama} → ditolak", kode_m != 0))
            if kode_m == 0:
                print(f"  ! {nama} DILOLOSKAN\n{keluar_m[:600]}")
            ci.write_text(asli, encoding="utf-8")

        mutasi("suite SQL diberi `--daftar`", lambda t: t.replace("run: node alat/uji-sql.mjs", "run: node alat/uji-sql.mjs --daftar"))
        mutasi("langkah bukti mutasi dihapus", lambda t: re.sub(r"\n\s*- name: Bukti mutasi[\s\S]*?run: python3 alat/uji-mutasi-0012\.py", "", t, count=1))
        mutasi("npm audit diberi `|| true`", lambda t: t.replace("run: npm audit --audit-level=low", "run: npm audit --audit-level=low || true"))
        mutasi("ambang audit diturunkan", lambda t: t.replace("npm audit --audit-level=low", "npm audit --audit-level=critical"))
        mutasi("langkah pemeriksa pohon bersih dihapus", lambda t: t.replace("          python3 alat/periksa-bersih.py\n", "", 1))
        mutasi("langkah diberi continue-on-error", lambda t: t.replace("    runs-on: ubuntu-latest", "    runs-on: ubuntu-latest\n    continue-on-error: true", 1))

    print("\nUJI-DIRI PEMERIKSA GERBANG CI")
    for nama, lulus in kasus:
        print(f"  {'OK ' if lulus else 'X  '} {nama}")
    gagal = [n for n, l in kasus if not l]
    if gagal:
        print(f"\nHASIL: GAGAL — {len(gagal)} kasus uji-diri tidak sesuai harapan (pemeriksa mungkin tumpul)")
        return 1
    print("\nHASIL: LOLOS — pemeriksa terbukti bisa MENOLAK yang rusak dan MENERIMA yang utuh.")
    return 0


def main() -> int:
    if "--uji-diri" in sys.argv:
        return uji_diri()

    kode, pesan = periksa(AKAR)
    jumlah_gerbang = len(GERBANG_WAJIB)
    if kode != 0:
        print(f"PERIKSA GERBANG CI — GAGAL ({len(pesan)} temuan)")
        for p in pesan:
            print(f"  [X] {p}")
        print("\nHASIL: GAGAL — gerbang CI hilang/dilemahkan.")
        return 1
    print(f"PERIKSA GERBANG CI — {jumlah_gerbang} gerbang wajib ada, tanpa pelemahan, dan suite SQL dijalankan penuh.")
    print("\nHASIL: LOLOS — gerbang CI utuh (bukti bisa MENOLAK: jalankan dengan --uji-diri).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
