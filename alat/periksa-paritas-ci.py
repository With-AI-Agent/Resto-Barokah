#!/usr/bin/env python3
"""Bandingkan perintah CI dengan pemeriksaan lokal.

B-F05: `ci.yml` dan `aplikasi/alat/periksa-semua.sh` sempat divergen. Pemeriksaan
lokal boleh menambah langkah, tetapi tidak boleh diam-diam kehilangan perintah CI;
perintah CI-only harus tetap tampak eksplisit di skrip lokal (mis. koneksi Supabase
bersyarat env). Ini pemeriksa teks konservatif, bukan pengganti eksekusi CI.
"""
from __future__ import annotations

import importlib.util
from pathlib import Path
import re
import sys

AKAR = Path(__file__).resolve().parent.parent
CI = AKAR / ".github" / "workflows" / "ci.yml"
LOKAL = AKAR / "aplikasi" / "alat" / "periksa-semua.sh"


def muat_ci() -> list[str]:
    spec = importlib.util.spec_from_file_location("periksa_gerbang_ci", AKAR / "alat" / "periksa-gerbang-ci.py")
    if spec is None or spec.loader is None:
        raise RuntimeError("periksa-gerbang-ci.py tidak bisa dimuat")
    modul = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modul)
    return modul.perintah_ci(CI.read_text(encoding="utf-8"))


def normalisasi(perintah: str) -> str:
    return perintah.replace('"', '').replace("'", '').strip()


def periksa(teks_ci: str, teks_lokal: str) -> list[str]:
    """Kembalikan perintah CI yang tidak tampak di pemeriksa lokal."""
    spec = importlib.util.spec_from_file_location("periksa_gerbang_ci_paritas", AKAR / "alat" / "periksa-gerbang-ci.py")
    if spec is None or spec.loader is None:
        return ["periksa-gerbang-ci.py tidak bisa dimuat"]
    modul = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(modul)
    perintah = modul.perintah_ci(teks_ci)
    hilang: list[str] = []
    for cmd in perintah:
        needle = normalisasi(cmd)
        # Tanda pipe heredoc bukan perintah tunggal; semua baris run sudah diurai
        # oleh perintah_ci. Cocokkan bentuk literal agar perubahan nama/argumen terlihat.
        if needle and needle not in normalisasi(teks_lokal):
            hilang.append(cmd)
    return hilang


def main() -> int:
    if not CI.is_file() or not LOKAL.is_file():
        print("HASIL: GAGAL — ci.yml atau pemeriksa lokal tidak ada")
        return 1
    hilang = periksa(CI.read_text(encoding="utf-8"), LOKAL.read_text(encoding="utf-8"))
    print(f"PERIKSA PARITAS CI — {len(muat_ci())} perintah CI dibandingkan dengan skrip lokal")
    if hilang:
        print("HASIL: GAGAL — perintah CI tidak tercermin di periksa-semua.sh:")
        for cmd in hilang:
            print(f"  [X] {cmd}")
        return 1
    print("HASIL: LOLOS — skrip lokal memuat semua perintah CI (boleh menambah pemeriksaan lokal).")
    return 0


def uji_diri() -> int:
    ci = CI.read_text(encoding="utf-8")
    lokal = LOKAL.read_text(encoding="utf-8")
    baseline = periksa(ci, lokal)
    hasil: list[tuple[str, bool, str]] = [
        ("skrip lokal utuh diterima", not baseline, ", ".join(baseline[:2]) or "lolos"),
    ]
    target = "python3 alat/uji-mutasi-0025.py"
    mutasi = lokal.replace(target, "# DIHAPUS UNTUK UJI PARITAS", 1)
    hilang = periksa(ci, mutasi)
    hasil.append(("mutasi satu perintah CI ditolak", target in hilang, ", ".join(hilang[:2]) or "DILOLOSKAN"))
    gagal = 0
    print("UJI-DIRI PARITAS CI")
    for nama, ok, catatan in hasil:
        gagal += int(not ok)
        print(f"  {'OK' if ok else 'GAGAL'} {nama}: {catatan}")
    print(f"HASIL UJI-DIRI: {'LOLOS' if not gagal else 'GAGAL'} — {len(hasil)} kasus, {gagal} tidak sesuai.")
    return int(bool(gagal))


if __name__ == "__main__":
    raise SystemExit(uji_diri() if "--uji-diri" in sys.argv else main())
