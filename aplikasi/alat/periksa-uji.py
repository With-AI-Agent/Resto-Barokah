#!/usr/bin/env python3
"""Pemeriksa kerangka uji (Fase 0 T0-10) — penjaga aturan TDD.

Masalah yang dicegah: "uji hanya formalitas". Alat ini memastikan dua hal:

1. Kerangkanya siap: Vitest terpasang, ada skrip `npm test`, dan konfigurasinya
   mengenal berkas uji di `src/`.
2. **Setiap berkas logika wajib punya berkas ujinya sendiri.** Yang dianggap
   logika = berkas di `src/lib/` dan `src/hook/`. Jadi begitu kode uang, izin,
   atau aturan bisnis ditulis mulai Fase 1, ujinya tidak bisa "lupa dibuat" —
   pemeriksa ini akan menolak.

Jalankan: python3 aplikasi/alat/periksa-uji.py
"""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

AKAR_REPO = Path(__file__).resolve().parents[2]
APLIKASI = AKAR_REPO / "aplikasi"

ok: list[str] = []
info: list[str] = []
gagal: list[str] = []

AWALAN_UJI = (".test.", ".spec.")


def berkas_logika() -> list[Path]:
    hasil: list[Path] = []
    for folder in ("lib", "hook"):
        akar = APLIKASI / "src" / folder
        if not akar.is_dir():
            continue
        for berkas in sorted(akar.rglob("*")):
            if berkas.suffix not in {".ts", ".tsx"}:
                continue
            if any(tanda in berkas.name for tanda in AWALAN_UJI):
                continue
            if berkas.name.endswith(".d.ts"):
                continue
            hasil.append(berkas)
    return hasil


def punya_uji(berkas: Path) -> Path | None:
    for akhiran in (".test.ts", ".test.tsx", ".spec.ts", ".spec.tsx"):
        kandidat = berkas.with_name(berkas.stem + akhiran)
        if kandidat.exists():
            return kandidat
    return None


def uji_kerangka() -> None:
    pkg = APLIKASI / "package.json"
    if not pkg.exists():
        gagal.append("GAGAL: aplikasi/package.json tidak ada")
        return
    isi = json.loads(pkg.read_text(encoding="utf-8"))
    skrip = isi.get("scripts", {})
    dev = isi.get("devDependencies", {})

    if "test" in skrip and "vitest" in skrip["test"]:
        ok.append(f"OK: skrip uji ada (npm test → {skrip['test']})")
    else:
        gagal.append("GAGAL: skrip `npm test` belum memanggil vitest")

    for nama in ("vitest", "jsdom", "@testing-library/react"):
        if nama in dev:
            ok.append(f"OK: {nama} terpasang ({dev[nama]})")
        else:
            gagal.append(f"GAGAL: {nama} belum terpasang sebagai alat pengembangan")

    konfig = APLIKASI / "vitest.config.ts"
    if not konfig.exists():
        gagal.append("GAGAL: aplikasi/vitest.config.ts tidak ada")
        return
    isi_konfig = konfig.read_text(encoding="utf-8")
    if "src/**/*.test" in isi_konfig:
        ok.append("OK: konfigurasi uji mengenal berkas uji di src/")
    else:
        gagal.append("GAGAL: konfigurasi uji tidak menyertakan berkas uji src/**/*.test")


def uji_pasangan() -> None:
    daftar = berkas_logika()
    if not daftar:
        gagal.append("GAGAL: tidak ada berkas logika di src/lib atau src/hook (aneh)")
        return
    tanpa_uji = [b for b in daftar if punya_uji(b) is None]
    if tanpa_uji:
        for berkas in tanpa_uji:
            gagal.append(
                f"GAGAL: {berkas.relative_to(AKAR_REPO)} tidak punya berkas uji "
                f"({berkas.with_name(berkas.stem + '.test.ts')} wajib ada)"
            )
    else:
        ok.append(f"OK: {len(daftar)} berkas logika semuanya punya uji")

    # jumlah uji (perkiraan dari kata kunci) — berguna sebagai laporan
    jumlah = 0
    for berkas in sorted((APLIKASI / "src").rglob("*.test.*")):
        teks = berkas.read_text(encoding="utf-8")
        jumlah += len(re.findall(r"\bit\(|\btest\(", teks))
    info.append(f"INFO: {jumlah} uji terbaca di src/ (dijalankan oleh npm test)")


def main() -> int:
    uji_kerangka()
    uji_pasangan()
    for baris in ok + info + gagal:
        print(baris)
    print("-" * 60)
    print(f"kerangka uji: {len(ok)} OK · {len(info)} INFO · {len(gagal)} GAGAL")
    print("KEPUTUSAN:", "LOLOS" if not gagal else "GAGAL")
    return 1 if gagal else 0


if __name__ == "__main__":
    sys.exit(main())
