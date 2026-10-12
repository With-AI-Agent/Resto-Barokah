#!/usr/bin/env python3
"""Uji ulang pagar F-216/F-217 memakai fungsi nyata alat/pmb-integrasi.py.

Kasus negatif memakai diff historis pada pohon Perencana (af38951^1 -> af38951),
bukan checkout cabang giliran; kasus kontrol mensimulasikan append yang sah dan
pembukaan kembali tugas yang sah.
"""
from __future__ import annotations

import importlib.util
import pathlib
import subprocess
import sys
from unittest.mock import patch

ROOT = pathlib.Path(__file__).resolve().parents[5]
SPEC = importlib.util.spec_from_file_location("pmb_integrasi_yang_diuji", ROOT / "alat" / "pmb-integrasi.py")
if SPEC is None or SPEC.loader is None:
    raise SystemExit("tidak dapat memuat alat/pmb-integrasi.py")
MOD = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MOD
SPEC.loader.exec_module(MOD)


def run_git(*args: str) -> str:
    p = subprocess.run(["git", *args], cwd=ROOT, capture_output=True, text=True)
    if p.returncode:
        raise AssertionError(f"git {' '.join(args)} gagal: {p.stderr.strip()}")
    return p.stdout


def integrasi(base: str = "BASE", branch: str = "TIP"):
    obj = MOD.Integrasi.__new__(MOD.Integrasi)
    obj.base = base
    obj.cabang = branch
    obj.pelanggaran = []
    obj.catatan = []
    obj.izinkan_hapus_roadmap = False
    obj.pembangun = True
    return obj


def uji_bukti_sintetis(lama: bytes | None, baru: bytes | None) -> list[str]:
    obj = integrasi()
    path = MOD.PMB + "bukti/H-PROBE-uji.txt"

    def git_palsu(*args: str, cek: bool = True) -> str:
        if args[:2] == ("diff", "--name-only"):
            return path + "\n"
        raise AssertionError(f"perintah git tak terduga: {args}")

    def show_palsu(rev: str, actual_path: str) -> bytes | None:
        assert actual_path == path
        return {"BASE": lama, "TIP": baru}[rev]

    with patch.object(MOD, "git", side_effect=git_palsu), patch.object(MOD, "show_bytes", side_effect=show_palsu):
        obj.periksa_bukti_kekal()
    return obj.pelanggaran


def uji_roadmap(diff: str) -> list[str]:
    obj = integrasi()
    with patch.object(MOD, "git", return_value=diff):
        obj.periksa_roadmap_pembangun()
    return obj.pelanggaran


# F-216: uji fungsi nyata pada diff integrasi Perencana yang dahulu menimpa bukti.
base = run_git("rev-parse", "af38951^1").strip()
obj = integrasi(base, "af38951")
obj.periksa_bukti_kekal()
assert any("B-F-09-rantai.txt" in p and "DITIMPA" in p and "PMB1-F-216" in p for p in obj.pelanggaran), obj.pelanggaran
print("F-216 historical control: PASS — periksa_bukti_kekal menolak penimpaan B-F-09-rantai.txt pada af38951")

assert not uji_bukti_sintetis(b"lama\n", b"lama\nbaris tambahan\n")
print("F-216 positive control: PASS — append di ujung diterima")
assert not uji_bukti_sintetis(None, b"bukti baru\n")
print("F-216 positive control: PASS — berkas bukti baru diterima")
assert any("DITIMPA" in p for p in uji_bukti_sintetis(b"lama\n", b"isi pengganti\n"))
print("F-216 negative control: PASS — overwrite ditolak")
assert any("DIHAPUS" in p for p in uji_bukti_sintetis(b"lama\n", None))
print("F-216 negative control: PASS — delete ditolak")

# F-217: uji fungsi nyata pada diff integrasi Perencana yang dahulu membuang catatan Lee.
obj = integrasi(base, "af38951")
obj.periksa_roadmap_pembangun()
assert any("PMB1-F-217" in p and "JAMINAN MEREK LAIN" in p for p in obj.pelanggaran), obj.pelanggaran
print("F-217 historical control: PASS — periksa_roadmap_pembangun menolak paragraf JAMINAN MEREK LAIN yang hilang pada af38951")

allowed = """--- a/docs/ROADMAP.md
+++ b/docs/ROADMAP.md
@@ -1,4 +1,7 @@
-- [x] T3-01 — Katalog kasir
+- [ ] T3-01 — Katalog kasir
-- **Bukti:** ⏳ BUKTI-BELUM — klaim lama
-- **DoD:** klaim lama
-- **Verifikasi:** klaim lama
+  - **Dibuka kembali:** PMB1-F-130 (2026-09-30) — bukti wajib: tes
+  - **DoD:** data database nyata
+  - **Verifikasi:** tes dan ukuran nyata
"""
assert not uji_roadmap(allowed), uji_roadmap(allowed)
print("F-217 positive control: PASS — pola [x]→[ ] dengan baris B+/DoD/Verifikasi diterima")

added_checkbox = """--- a/docs/ROADMAP.md
+++ b/docs/ROADMAP.md
@@ -1,0 +1,1 @@
+- [x] T99-99 — centang tidak sah dari Pembangun
"""
assert any("MENCENTANG" in p and "K6" in p for p in uji_roadmap(added_checkbox))
print("F-217 negative control: PASS — Pembangun menambah [x] ditolak oleh K6")

restored = run_git("show", "3e01d5c:docs/ROADMAP.md")
assert "JAMINAN MEREK LAIN" in restored and "Data dikirim potong 20 byte" in restored
print("Perencana current correction: PASS — commit 3e01d5c memulihkan paragraf JAMINAN dan catatan 20 byte")
print("HASIL: LOLOS — seluruh kontrol F-216/F-217 sesuai dugaan")
