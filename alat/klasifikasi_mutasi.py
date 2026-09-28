#!/usr/bin/env python3
"""klasifikasi_mutasi.py — memisahkan "MERAH karena pagar bekerja" dari "MERAH karena salinan rusak".

Kenapa ada (temuan audit I F-04, K-3, 2026-09-20): harness mutasi dulu memakai
`lulus = (kode != 0)`. Artinya **kegagalan apa pun** dihitung sebagai bukti pagar bekerja —
termasuk `ERR_MODULE_NOT_FOUND`, `SyntaxError`, dan "migrasi tidak bisa diterapkan". Mutasi yang
merusak sintaks/setup akan dilaporkan "MERAH (benar)" walau tidak ada penjaga yang benar-benar diuji.
Harness yang begitu **tidak bisa membuktikan apa pun** tentang pagar; ia hanya membuktikan ada
sesuatu yang gagal.

Aturan klasifikasi (satu tempat, dipakai semua harness mutasi):

  * `HIJAU`        — runner keluar 0; seluruh berkas uji hijau.
  * `MERAH-PAGAR`  — runner benar-benar menjalankan berkas uji, ada berkas di bawah `supabase/tes/`
                     yang GAGAL, jumlahnya cocok dengan ringkasan, dan sebabnya adalah **asersi
                     pengaman** (`HARAPAN TIDAK TERPENUHI` / `SEBAB PENOLAKAN BUKAN YANG DIHARAPKAN`).
                     Hanya jenis ini yang boleh dihitung sebagai bukti pagar bekerja.
  * `RUSAK`        — kegagalan lingkungan/setup/sintaks, atau merah yang sebabnya BUKAN asersi
                     (mis. `function ... does not exist`, migrasi tak bisa diterapkan, runner mati
                     sebelum ringkasan, jumlah gagal tak cocok). **Bukan bukti** — wajib ditolak.

Tidak ada tebakan: setiap keputusan mengembalikan `jenis` + `sebab` supaya bisa dicetak apa adanya.
"""
from __future__ import annotations

import re

HIJAU = "HIJAU"
MERAH_PAGAR = "MERAH-PAGAR"
RUSAK = "RUSAK"

# Pesan yang HANYA keluar dari asersi `uji.harap/harap_gagal/harap_gagal_sebab` di `alat/uji-sql.mjs`.
TOKEN_ASERSI = (
    "HARAPAN TIDAK TERPENUHI",
    "SEBAB PENOLAKAN BUKAN YANG DIHARAPKAN",
)

# Jejak kegagalan yang membuat keluaran TIDAK bisa dipakai sebagai bukti (salinan/lingkungan rusak).
POLA_RUSAK = (
    "ERR_MODULE_NOT_FOUND",
    "Cannot find module",
    "SyntaxError",
    "tidak bisa diterapkan",      # migrasi gagal diterapkan
    "tidak bisa dibuat",          # data uji gagal dibuat
    "berkas tidak ada",           # berkas uji hilang
    "PGliteError",               # pustaka/runner PGlite gagal setelah mulai
)

POLA_RINGKASAN = re.compile(r"^uji: (\d+) LULUS · (\d+) GAGAL\s*$", re.MULTILINE)
POLA_GAGAL_UJI = re.compile(r"^\s+GAGAL (supabase/tes/\S+)")


def klasifikasi(kode: int, keluaran: str) -> tuple[str, str]:
    """Kembalikan `(jenis, sebab)`; `jenis` salah satu dari HIJAU / MERAH-PAGAR / RUSAK."""
    if kode == 0:
        return HIJAU, ""

    m = POLA_RINGKASAN.search(keluaran)
    if not m:
        return RUSAK, "runner berhenti sebelum menulis ringkasan (kegagalan lingkungan/sintaks?)"
    jumlah_gagal = int(m.group(2))

    jumpa = [p for p in POLA_RUSAK if p in keluaran]
    if jumpa:
        return RUSAK, "keluaran memuat jejak salinan rusak: " + ", ".join(jumpa)

    if jumlah_gagal == 0:
        return RUSAK, "kode keluar ≠ 0 tetapi ringkasan menyebut 0 GAGAL — keluaran tidak bisa dipercaya"

    baris = keluaran.splitlines()
    berkas_gagal: list[str] = []
    sebab_gagal: list[str] = []
    for i, b in enumerate(baris):
        mm = POLA_GAGAL_UJI.match(b)
        if mm:
            berkas_gagal.append(mm.group(1))
            sebab_gagal.append(baris[i + 1].strip() if i + 1 < len(baris) else "")
    if len(berkas_gagal) != jumlah_gagal:
        return RUSAK, (f"ringkasan bilang {jumlah_gagal} GAGAL, tetapi hanya {len(berkas_gagal)} "
                       f"kegagalan datang dari berkas uji `supabase/tes/` (sisanya di luar berkas uji)")

    # SEMUA kegagalan harus berasal dari asersi pengaman. Satu runner bisa memuat
    # beberapa berkas uji; `any()` di sini pernah membuat runtime error pada satu
    # berkas tertutup oleh asersi pada berkas lain (B-F01). Fail closed: campuran
    # runtime + asersi = RUSAK, bukan bukti pagar.
    non_asersi = [
        (berkas, sebab)
        for berkas, sebab in zip(berkas_gagal, sebab_gagal)
        if not any(token in sebab for token in TOKEN_ASERSI)
    ]
    if non_asersi:
        berkas, sebab = non_asersi[0]
        return RUSAK, (
            "setidaknya satu kegagalan bukan asersi pengaman — keluaran campuran/runner rusak: "
            f"{berkas} — {sebab[:160]}"
        )
    return MERAH_PAGAR, f"{berkas_gagal[-1]} — {sebab_gagal[-1][:160]}"
