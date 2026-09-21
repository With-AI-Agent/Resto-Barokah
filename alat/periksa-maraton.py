#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""periksa-maraton.py — penjaga papan tugas maraton kerja sama (AL-16).

Menolak papan yang bisa membuat kerja paralel jadi cacat:
  1. kolom wajib ada; status hanya dari himpunan sah; DITOLAK/DIBATALKAN wajib beralasan;
  2. tugas AKTIF (DIBERIKAN/SELESAI) wajib punya lingkup + pekerja, dan lingkup antar-tugas
     aktif TIDAK BOLEH bersinggungan (akar tabrakan multi-agent = kepemilikan tumpang tindih);
  3. nomor migrasi cadangan: 4 digit, unik antar-tugas, lebih besar dari migrasi tertinggi
     yang ada (pekerja tidak boleh berebut/menabrak nomor);
  4. lingkup tidak boleh menyentuh migrasi BEKU (nomor ≤ NOMOR_TERTINGGI_BEKU) atau berkas
     pemeriksa/pagar — itu wilayah tunggal integrator.

Dipakai: integrator saat menyiapkan gelombang & saat panen; CI (gerbang); `--uji-diri`
membuktikan pemeriksa ini bisa MENOLAK papan cacat dan MENERIMA papan sehat.
"""
from __future__ import annotations

import pathlib
import re
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
PAPAN = "docs/ops/PAPAN_TUGAS.md"
MIGRASI_DIR = "supabase/migrations"
STATUS_AKTIF = {"DIBERIKAN", "SELESAI"}
STATUS_SAHH = STATUS_AKTIF | {"DITERIMA"}
# NOMOR_TERTINGGI_BEKU dibaca dari periksa-migrasi-beku bila ada konstanta; fallback konservatif.
def nomor_tertinggi_beku(akar: pathlib.Path) -> int:
    src = (akar / "alat" / "periksa-migrasi-beku.py").read_text(encoding="utf-8")
    m = re.search(r"NOMOR_TERTINGGI_BEKU\s*=\s*(\d+)", src)
    return int(m.group(1)) if m else 16


def migrasi_tertinggi(akar: pathlib.Path) -> int:
    nomor = [int(p.name[:4]) for p in (akar / MIGRASI_DIR).glob("0*.sql") if p.name[:4].isdigit()]
    return max(nomor) if nomor else 0


def baca_baris_tugas(teks: str) -> list[list[str]]:
    baris = []
    for line in teks.splitlines():
        line = line.strip()
        if not (line.startswith("|") and line.count("|") >= 7):
            continue
        sel = [s.strip() for s in line.strip("|").split("|")]
        if len(sel) < 7 or sel[0] in ("Tugas", "") or set(sel[0]) <= {"-"}:
            continue
        baris.append(sel)
    return baris


def periksa_papan(teks: str, akar: pathlib.Path) -> list[str]:
    salah: list[str] = []
    if "| Tugas | Lingkup berkas eksklusif |" not in teks:
        salah.append("kolom wajib papan hilang (Tugas/Lingkup/…)")
        return salah
    beku = nomor_tertinggi_beku(akar)
    tertinggi = migrasi_tertinggi(akar)
    nomor_pakai: dict[str, str] = {}
    lingkup_aktif: list[tuple[str, str]] = []
    for sel in baca_baris_tugas(teks):
        tugas, lingkup, nomor, pekerja, status, dod, catatan = (sel + [""] * 7)[:7]
        nama_status = status.split("(")[0].strip().upper()
        if nama_status not in STATUS_SAHH and not (status.upper().startswith(("DITOLAK", "DIBATALKAN"))):
            salah.append(f"{tugas}: status tidak sah '{status}'")
            continue
        if status.upper().startswith(("DITOLAK", "DIBATALKAN")) and "(" not in status:
            salah.append(f"{tugas}: {nama_status} wajib menyebut alasan dalam kurung")
        if nama_status not in STATUS_AKTIF:
            continue
        if not lingkup or lingkup in ("—", "-"):
            salah.append(f"{tugas}: tugas aktif wajib punya lingkup berkas eksklusif")
        if not pekerja or pekerja in ("—", "-") or "arena/" not in pekerja:
            salah.append(f"{tugas}: tugas aktif wajib punya pekerja (cabang arena/…)")
        if not dod or dod in ("—", "-"):
            salah.append(f"{tugas}: tugas aktif wajib punya DoD & bukti")
        # nomor migrasi cadangan
        if nomor and nomor not in ("—", "-"):
            if not re.fullmatch(r"\d{4}", nomor):
                salah.append(f"{tugas}: nomor migrasi cadangan wajib 4 digit, dapat '{nomor}'")
            else:
                n = int(nomor)
                if n <= tertinggi:
                    salah.append(f"{tugas}: nomor cadangan {nomor} ≤ migrasi tertinggi yang ada ({tertinggi:04d})")
                if n <= beku:
                    salah.append(f"{tugas}: nomor cadangan {nomor} berada di zona beku (≤{beku})")
                if nomor in nomor_pakai:
                    salah.append(f"{tugas}: nomor cadangan {nomor} sudah dipakai {nomor_pakai[nomor]}")
                nomor_pakai[nomor] = tugas
        # lingkup terlarang + tabrakan
        for bagian in [x.strip() for x in lingkup.replace("·", ",").split(",") if x.strip()]:
            bagian = bagian.strip("` ")
            m = re.match(r"supabase/migrations/(0\d{3})_", bagian)
            if m and int(m.group(1)) <= beku:
                salah.append(f"{tugas}: lingkup menyentuh migrasi beku {bagian}")
            if bagian.startswith(("alat/", ".github/")):
                salah.append(f"{tugas}: lingkup menyentuh wilayah pemeriksa/pagar ({bagian}) — itu tugas integrator")
            for t2, l2 in lingkup_aktif:
                a, b = bagian.rstrip("*").rstrip("/"), l2.rstrip("*").rstrip("/")
                if a and b and (a.startswith(b) or b.startswith(a)):
                    salah.append(f"{tugas}: lingkup '{bagian}' bersinggungan dengan {t2} ('{l2}')")
            lingkup_aktif.append((tugas, bagian))
    return salah


def main() -> int:
    if "--uji-diri" in sys.argv:
        return uji_diri()
    teks = (AKAR / PAPAN).read_text(encoding="utf-8")
    salah = periksa_papan(teks, AKAR)
    for s in salah:
        print(f"  [X] {s}")
    if salah:
        print(f"HASIL: GAGAL — {len(salah)} cacat pada papan tugas maraton")
        return 1
    print("HASIL: LOLOS — papan tugas maraton sehat (lingkup eksklusif, nomor aman, status sah)")
    return 0


def uji_diri() -> int:
    sehat = """# PAPAN TUGAS MARATON
| Tugas | Lingkup berkas eksklusif | No. migrasi cadangan | Pekerja (cabang) | Status | DoD & bukti wajib | Catatan panen |
|---|---|---|---|---|---|---|
| T-01 | `supabase/tes/foo/**` | 0020 | `arena/aaa-pekerja-1` | DIBERIKAN | uji hijau + laporan | — |
| T-02 | `docs/**` | — | `arena/bbb-pekerja-2` | SELESAI | laporan + bukti | — |
| T-03 | `aplikasi/src/x/**` | — | `arena/ccc-pekerja-3` | DITERIMA | laporan | dipanen, baterai hijau |
| T-04 | `docs/lama/**` | — | `arena/ddd-pekerja-4` | DITOLAK (DoD tak terbukti) | laporan | kembali ke kolam |
"""
    tertinggi = migrasi_tertinggi(AKAR)
    kasus = [
        ("papan sehat diterima", sehat, False),
        ("mutasi: lingkup dua tugas aktif bersinggungan → ditolak",
         sehat.replace("`docs/lama/**`", "`docs/**`").replace("DITOLAK (DoD tak terbukti)", "DIBERIKAN"), True),
        ("mutasi: nomor migrasi cadangan ganda → ditolak",
         sehat.replace("| T-02 | `docs/**` | — |", "| T-02 | `docs/**` | 0020 |"), True),
        ("mutasi: nomor cadangan ≤ migrasi tertinggi → ditolak",
         sehat.replace("| 0020 |", f"| {tertinggi:04d} |"), True),
        ("mutasi: tugas aktif tanpa pekerja → ditolak",
         sehat.replace("`arena/bbb-pekerja-2`", "—"), True),
        ("mutasi: status di luar himpunan sah → ditolak",
         sehat.replace("SELESAI", "MANGKAT"), True),
        ("mutasi: DITOLAK tanpa alasan → ditolak",
         sehat.replace("DITOLAK (DoD tak terbukti)", "DITOLAK"), True),
        ("mutasi: lingkup menyentuh migrasi beku → ditolak",
         sehat.replace("`supabase/tes/foo/**`", "`supabase/migrations/0006_pin.sql`"), True),
        ("mutasi: lingkup menyentuh wilayah pagar → ditolak",
         sehat.replace("`docs/**`", "`alat/uji-sql.mjs`"), True),
    ]
    gagal = 0
    print("UJI-DIRI PERIKSA MARATON — semua kasus harus sesuai harapan")
    for nama, teks, harap_gagal in kasus:
        salah = periksa_papan(teks, AKAR)
        cocok = bool(salah) == harap_gagal
        gagal += 0 if cocok else 1
        print(f"  {'OK ' if cocok else ' X '} {nama}" + ("" if cocok else f" → salah={salah[:2]}"))
    if gagal:
        print(f"HASIL: GAGAL — {gagal} kasus tidak sesuai harapan (penjaga mungkin tumpul)")
        return 1
    print("HASIL: LOLOS — penjaga papan terbukti bisa MENOLAK papan cacat dan MENERIMA papan sehat")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
