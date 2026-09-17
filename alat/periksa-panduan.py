#!/usr/bin/env python3
"""periksa-panduan.py — penjaga BUKU PEDOMAN INDUK (PANDUAN_PENGGUNA.md).

Kenapa ada: permintaan pemilik 2026-09-17 — buku pedoman pengguna harus benar-benar
INDUK dan LENGKAP (semua mekanisme + semua prompt), dan tidak boleh basi. Pemeriksa
ini dijalankan di CI, jadi buku tidak bisa pelan-pelan kehilangan isi atau menunjuk
berkas yang tidak ada.

Yang diperiksa:
 1. Semua bagian A–H ada.
 2. Topik wajib ada (audit + kalibrasi, keamanan, darurat, privasi, biaya, glosarium,
    prompt pembuka + penutup, review & merge, template).
 3. Tabel mekanisme memuat >= 10 baris (C1..Cn) dan tiap mekanisme punya berkas rujukan.
 4. Blok Prompt Pembuka identik dengan PROMPT_ENTRI_UNIVERSAL.md.
 5. Blok Prompt Auditor identik dengan blok kanonik di docs/uji/PROMPT_AUDIT_INDEPENDEN.md.
 6. Semua rujukan berkas ber-backtick benar-benar ada (kecuali ditandai "(rencana)").
 7. Berkas untuk pengguna benar-benar ada & menunjuk balik ke buku induk.
 8. Panjang minimum (penjaga anti-penyusutan).
"""
from __future__ import annotations

import pathlib
import re
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
BUKU = AKAR / "PANDUAN_PENGGUNA.md"
MIN_BARIS = 350
TOPIK_WAJIB = {
    "prompt pembuka": r"Prompt Pembuka Universal",
    "prompt penutup": r"Prompt Penutup Sesi",
    "audit indep.": r"AUD-3|audit independen",
    "kalibrasi cacat": r"[Kk]alibrasi",
    "istilah audit": r"K-1",
    "keamanan": r"KEAMANAN\.md",
    "darurat/insiden": r"BUKU_INSIDEN\.md",
    "privasi/PDP": r"PDP",
    "biaya": r"[Bb]iaya",
    "review & merge": r"review & merge|Review & Merge",
    "template": r"(?i)sebagai template",
    "titik masuk sesi baru": r"PROMPT_ENTRI_UNIVERSAL",
}
BERKAS_PENGGUNA_WAJIB = [
    "docs/PANDUAN_PEMILIK.md",
    "docs/uji/PROMPT_AUDIT_INDEPENDEN.md",
    "docs/uji/PROTOKOL_AUDIT_INDEPENDEN.md",
    "docs/teknis/BUKU_INSIDEN.md",
    "docs/ops/SIAP_AKUN_PEMILIK.md",
    "docs/KEAMANAN.md",
    "PROMPT_ENTRI_UNIVERSAL.md",
    "PROFIL_PENGGUNA.md",
    "10_LOG_SESI.md",
    "ACCEPTANCE_TESTS.md",
]


def blok_pertama(teks: str) -> str:
    m = re.search(r"```\n(.*?)\n```", teks, re.DOTALL)
    return m.group(1).strip() if m else ""


def cari_blok_kanonik(teks: str) -> str:
    """Ambil blok prompt auditor dari bagian B berkas kanonik."""
    bagian = teks.split("## B.")[-1]
    return blok_pertama(bagian)


def main() -> int:
    errs: list[str] = []
    catatan: list[str] = []
    if not BUKU.is_file():
        print("GAGAL: PANDUAN_PENGGUNA.md tidak ada"); return 1
    teks = BUKU.read_text(encoding="utf-8")
    baris = teks.splitlines()

    if len(baris) < MIN_BARIS:
        errs.append(f"buku terlalu pendek: {len(baris)} baris (minimum {MIN_BARIS}) — buku induk tidak boleh menyusut")

    for huruf in "ABCDEFGH":
        if not re.search(rf"^## Bagian {huruf}\b", teks, re.MULTILINE):
            errs.append(f"bagian {huruf} hilang (buku induk wajib punya bagian A–H)")

    for nama, pola in TOPIK_WAJIB.items():
        if not re.search(pola, teks):
            errs.append(f"topik wajib hilang: {nama} (pola {pola!r}) — tambahkan ke buku")

    baris_mekanisme = [b for b in baris if re.match(r"\|\s*C\d+\s*\|", b)]
    if len(baris_mekanisme) < 10:
        errs.append(f"tabel mekanisme hanya {len(baris_mekanisme)} baris (minimum 10 mekanisme terdaftar)")
    for b in baris_mekanisme:
        kolom = [k.strip() for k in b.strip("|").split("|")]
        if len(kolom) < 5 or not re.search(r"`|—\s*$", kolom[2]):
            errs.append(f"baris mekanisme tanpa rujukan berkas: {b.strip()[:70]}")

    # 4. blok prompt pembuka harus identik
    pe = AKAR / "PROMPT_ENTRI_UNIVERSAL.md"
    if pe.is_file():
        kanonik = blok_pertama(pe.read_text(encoding="utf-8"))
        if not kanonik:
            errs.append("PROMPT_ENTRI_UNIVERSAL.md tidak punya blok prompt bertanda ```")
        elif kanonik not in teks:
            errs.append("blok Prompt Pembuka di buku induk TIDAK identik dengan PROMPT_ENTRI_UNIVERSAL.md — jangan menyalin manual, ambil dari sumbernya")
    else:
        errs.append("PROMPT_ENTRI_UNIVERSAL.md tidak ada")

    # 5. blok prompt auditor harus identik
    pa = AKAR / "docs" / "uji" / "PROMPT_AUDIT_INDEPENDEN.md"
    if pa.is_file():
        kanonik_audit = cari_blok_kanonik(pa.read_text(encoding="utf-8"))
        if not kanonik_audit:
            errs.append("PROMPT_AUDIT_INDEPENDEN.md bagian B: blok prompt auditor tidak ditemukan")
        elif kanonik_audit not in teks:
            errs.append("blok Prompt Auditor di buku induk TIDAK identik dengan docs/uji/PROMPT_AUDIT_INDEPENDEN.md bagian B")
    else:
        errs.append("docs/uji/PROMPT_AUDIT_INDEPENDEN.md tidak ada")

    # 6. rujukan berkas ber-backtick harus ada
    # rentang baris blok kanonik yang disematkan apa adanya (dari berkas lain) —
    # rujukan di dalamnya dilaporkan sebagai catatan, bukan kegagalan: teks itu milik sumbernya.
    rentang_kanonik: list[tuple[int, int]] = []
    for sumber in (pe, pa):
        if not sumber.is_file():
            continue
        isi = sumber.read_text(encoding="utf-8")
        blok_kanonik = blok_pertama(isi) if sumber is pe else cari_blok_kanonik(isi)
        if not blok_kanonik:
            continue
        awal = teks.find(blok_kanonik)
        if awal >= 0:
            n_awal = teks[:awal].count("\n") + 1
            rentang_kanonik.append((n_awal, n_awal + blok_kanonik.count("\n")))

    def di_dalam_kanonik(no_baris: int) -> bool:
        return any(a <= no_baris <= b for a, b in rentang_kanonik)

    kandidat: set[str] = set()
    for m in re.finditer(r"`([^`\n]+)`", teks):
        t = m.group(1).strip()
        if t.startswith(("http", "python3 ", "node ", "bash ", "cd ", "git ", "gh ", "npx ")):
            continue
        if t.startswith("<") or " " in t or "<" in t or "…" in t or "*" in t:
            continue
        if not (("/" in t) or re.search(r"\.(md|py|sh|mjs|ts|tsx|sql|json|yml|html)$", t)):
            continue
        kandidat.add(t.rstrip("/") if t.endswith("/") and not (AKAR / t).is_dir() else t)
    lewat = 0
    for t in sorted(kandidat):
        if t in {"main", "arena/...", "docs/..."}:
            continue
        jalur = AKAR / t
        if jalur.exists():
            continue
        # baris yang menyebut berkas ini (+ nomor barisnya)
        pola_baris = [(i, b) for i, b in enumerate(baris, 1) if f"`{t}`" in b or f"`{t.rstrip('/')}/`" in b]
        if pola_baris and all(di_dalam_kanonik(i) for i, _ in pola_baris):
            catatan.append(f"rujukan di dalam blok kanonik yang disematkan (milik sumber lain): {t}")
            lewat += 1
            continue
        if any(re.search(r"\(rencana\)|belum ada|belum jadi|akan ditulis|observasi", b) for _, b in pola_baris):
            catatan.append(f"rujukan berkas yang belum ada (ditandai rencana): {t}")
            lewat += 1
            continue
        errs.append(f"rujukan berkas tidak ada: `{t}` — perbaiki rujukan atau tandai (rencana)")

    # 7. berkas untuk pengguna wajib ada + menunjuk balik
    for rel in BERKAS_PENGGUNA_WAJIB:
        if not (AKAR / rel).is_file():
            errs.append(f"berkas untuk pengguna hilang: {rel}")
    pm = AKAR / "docs" / "PANDUAN_PEMILIK.md"
    if pm.is_file() and "PANDUAN_PENGGUNA.md" not in pm.read_text(encoding="utf-8"):
        errs.append("docs/PANDUAN_PEMILIK.md tidak menunjuk balik ke buku induk PANDUAN_PENGGUNA.md — pengguna bisa tersesat")
    pp = AKAR / "docs" / "uji" / "PROMPT_AUDIT_INDEPENDEN.md"
    if pp.is_file() and "PANDUAN_PENGGUNA" not in pp.read_text(encoding="utf-8"):
        errs.append("docs/uji/PROMPT_AUDIT_INDEPENDEN.md tidak menunjuk ke buku induk")

    print(f"PERIKSA BUKU PEDOMAN INDUK — {len(baris)} baris · {len(baris_mekanisme)} mekanisme · {len(kandidat)} rujukan berkas")
    for c in catatan:
        print(f"  [catatan] {c}")
    if errs:
        print(f"\nHASIL: GAGAL — {len(errs)} temuan")
        for e in errs:
            print(f"  [X] {e}")
        return 1
    print("\nHASIL: LOLOS — buku induk lengkap, rujukan hidup, prompt identik dengan sumbernya.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
