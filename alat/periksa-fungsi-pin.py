#!/usr/bin/env python3
"""Penjaga Edge Function PIN (T1-06).

Mengapa ada: PIN adalah data paling sensitif di aplikasi ini, dan cara paling
umum PIN bocor bukan lewat serangan canggih — melainkan lewat log yang mencatat
permintaan, atau lewat kunci penuh (service_role) yang dipakai supaya "gampang".
Pemeriksa ini menolak kiriman kode bila salah satu dari itu muncul kembali.

Yang diperiksa pada `supabase/functions/verifikasi_pin/index.ts`:
  1. berbentuk fungsi Edge (Deno.serve) dan meneruskan ke RPC `verifikasi_pin`;
  2. hanya menerima POST (menolak metode lain);
  3. tidak memakai console.* sama sekali (PIN tidak mungkin masuk log);
  4. tidak menyebut service_role (RLS tidak boleh dilewati);
  5. memakai Authorization pemanggil + kunci publik;
  6. tidak memuat rahasia yang tertulis langsung (pola kunci JWT / kata sandi).

Jalankan: python3 alat/periksa-fungsi-pin.py
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

AKAR = Path(__file__).resolve().parent.parent
BERKAS = AKAR / "supabase" / "functions" / "verifikasi_pin" / "index.ts"

HASIL: list[tuple[str, bool, str]] = []


def periksa(nama: str, syarat: bool, catatan: str) -> None:
    HASIL.append((nama, bool(syarat), catatan))


def utama() -> int:
    if not BERKAS.exists():
        print(f"GAGAL: berkas tidak ada: {BERKAS.relative_to(AKAR)}")
        return 1

    isi = BERKAS.read_text(encoding="utf-8")
    baris_kode = "\n".join(
        b for b in isi.splitlines() if not b.strip().startswith(("//", "*", "/*"))
    )

    periksa("berkas ada & tidak kosong", len(isi.strip()) > 200, f"{len(isi)} huruf")
    periksa(
        "berbentuk Edge Function (Deno.serve)",
        "Deno.serve" in baris_kode,
        "memakai Deno.serve",
    )
    periksa(
        "meneruskan ke RPC verifikasi_pin",
        re.search(r"rpc/\$\{?RPC\}?|rpc/verifikasi_pin", baris_kode) is not None,
        "memanggil /rest/v1/rpc/verifikasi_pin",
    )
    periksa(
        "hanya menerima POST",
        "'POST'" in baris_kode and "405" in baris_kode,
        "metode selain POST dijawab 405",
    )
    periksa(
        "TIDAK memakai console.* (PIN tidak mungkin masuk log)",
        "console." not in baris_kode,
        "tidak ada console.* di seluruh berkas",
    )
    periksa(
        "TIDAK memakai service_role (RLS tidak dilewati)",
        "service_role" not in baris_kode and "SERVICE_ROLE" not in baris_kode,
        "memakai kunci publik + token pemanggil",
    )
    periksa(
        "memakai token pemanggil (Authorization)",
        "Authorization" in baris_kode,
        "header Authorization diteruskan apa adanya",
    )
    periksa(
        "memakai kunci publik dari lingkungan, bukan tertulis di berkas",
        "SUPABASE_ANON_KEY" in baris_kode
        and "Deno.env.get" in baris_kode
        and "eyJ" not in baris_kode,
        "kunci dibaca dari Deno.env",
    )
    periksa(
        "PIN tidak pernah disimpan/dikembalikan",
        "pin_hash" not in baris_kode and "setItem" not in baris_kode,
        "tidak menyentuh hash maupun penyimpanan peramban",
    )

    gagal = [h for h in HASIL if not h[1]]
    print(f"Pemeriksa Edge Function PIN — {BERKAS.relative_to(AKAR)}")
    for nama, lulus, catatan in HASIL:
        print(f"  {'LOLOS' if lulus else 'GAGAL'}  {nama}  [{catatan}]")
    print(f"\nRINGKASAN: {len(HASIL) - len(gagal)} lolos, {len(gagal)} gagal")
    return 1 if gagal else 0


if __name__ == "__main__":
    sys.exit(utama())
