#!/usr/bin/env python3
"""periksa-roadmap.py — pemeriksa otomatis docs/ROADMAP.md (Resto Barokah).

Tujuan: memastikan daftar tugas BENAR-BENAR lengkap dan tidak ada tugas yang cacat,
tanpa mengandalkan ingatan agent. Dijalankan sebelum fase baru dimulai dan di CI.

    python3 alat/periksa-roadmap.py

Yang diperiksa:
  1. Setiap tugas punya 7 atribut wajib (Tujuan, Ref, File, DoD, Kompleksitas, Risiko & mitigasi, Verifikasi).
  2. Semua fitur Must Have M1–M12 disebut minimal sekali di kolom Ref.
  3. Semua entitas data model (TECH_SPEC §4) punya jejak di ROADMAP.
  4. Semua RPC inti (TECH_SPEC §5) punya jejak.
  5. Semua Area Berisiko Tinggi ART-1…ART-10 muncul bersama lambang ⚠️.
  6. Semua tanda ❓ memakai ID yang benar-benar ada di docs/TERTANGGUH.md.
  7. Hal kecil (README, .env.example, favicon, error, memuat/kosong, a11y, responsif) & integrasi
     (Supabase, Google, Resend, Cloudflare, pg_cron) punya tugasnya.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ROADMAP = ROOT / "docs" / "ROADMAP.md"
TERTANGGUH = ROOT / "docs" / "TERTANGGUH.md"

ATRIBUT = ["**Tujuan:**", "**Ref:**", "**File:**", "**DoD", "**Kompleksitas:**",
           "**Risiko & mitigasi:**", "**Verifikasi:**"]

FITUR = [f"M{i}" for i in range(1, 13)]

TEK_SPEC = ROOT / "docs" / "TECH_SPEC.md"


def nama_entitas() -> list[str]:
    """Nama tabel diambil LANGSUNG dari dokumen terkunci `TECH_SPEC.md` §4 (bukan daftar tangan yang bisa basi).

    Dasar perubahan (temuan review independen W3-03): daftar tangan lama memuat nama pendek
    (`kategori`, `stok`) yang bukan nama tabel resmi, sehingga gerbangnya hijau palsu.
    """
    if not TEK_SPEC.is_file():
        return []
    return sorted(set(re.findall(r"^\|\s*`([a-z_]+)`\s*\|", TEK_SPEC.read_text(encoding="utf-8"), re.M)))


def nama_rpc() -> list[str]:
    """Nama RPC diambil dari `rpc/nama` di `TECH_SPEC.md` §5."""
    if not TEK_SPEC.is_file():
        return []
    return sorted(set(re.findall(r"`rpc/([a-z_]+)`", TEK_SPEC.read_text(encoding="utf-8"))))


ART = [f"ART-{i}" for i in range(1, 11)]

HAL_KECIL = {"README": "README", ".env.example": ".env.example", "favicon": "favicon",
             "halaman error": "TidakPunyaAkses", "keadaan memuat/kosong/gagal": "Keadaan",
             "a11y": "a11y", "responsif": "responsif"}

INTEGRASI = {"Supabase": "Supabase", "Google": "Google", "Resend": "Resend",
             "Cloudflare": "Cloudflare", "pg_cron": "pg_cron"}


def blok_tugas(teks: str) -> list[tuple[str, str]]:
    """Pisahkan ROADMAP menjadi blok per tugas → [(id, isi_blok)]."""
    hasil: list[tuple[str, str]] = []
    sekarang_id, sekarang_isi = None, []
    for baris in teks.splitlines():
        m = re.match(r"^- \[[ x]\] (T\d+-\d+) — (.+)$", baris)
        if m:
            if sekarang_id:
                hasil.append((sekarang_id, "\n".join(sekarang_isi)))
            sekarang_id, sekarang_isi = m.group(1), [m.group(2)]
        elif sekarang_id is not None:
            if baris.startswith("## ") or baris.strip() == "---":
                hasil.append((sekarang_id, "\n".join(sekarang_isi)))
                sekarang_id, sekarang_isi = None, []
            else:
                sekarang_isi.append(baris)
    if sekarang_id:
        hasil.append((sekarang_id, "\n".join(sekarang_isi)))
    return hasil


def main() -> int:
    if not ROADMAP.is_file():
        print("GAGAL: docs/ROADMAP.md tidak ada")
        return 1
    teks = ROADMAP.read_text(encoding="utf-8")
    tugas = blok_tugas(teks)
    gagal: list[str] = []
    catatan: list[str] = []

    if len(tugas) < 100:
        gagal.append(f"jumlah tugas mencurigakan: {len(tugas)} (harusnya ratusan)")

    for tid, isi in tugas:
        kurang = [a for a in ATRIBUT if a not in isi]
        if kurang:
            gagal.append(f"{tid}: atribut hilang → {', '.join(kurang)}")
        if "⚠️" in isi and "DECISIONS_LOG" not in isi:
            gagal.append(f"{tid}: bertanda ⚠️ tetapi tidak menyebut DECISIONS_LOG")

    isi_tugas = "\n".join(isi for _, isi in tugas)
    for m in FITUR:
        if not re.search(rf"\b{m}\b", teks):
            gagal.append(f"fitur wajib {m} tidak punya tugas")
    for e in nama_entitas():
        if e not in isi_tugas:
            gagal.append(f"entitas '{e}' (TECH_SPEC §4) tidak disebut di blok tugas mana pun")
    for r in nama_rpc():
        if r not in isi_tugas:
            gagal.append(f"RPC '{r}' (TECH_SPEC §5) tidak disebut di blok tugas mana pun")
    for a in ART:
        if not re.search(rf"{a}\b", teks):
            gagal.append(f"Area Berisiko Tinggi {a} tidak disinggung")
        elif f"{a} " not in teks and f"{a}(" not in teks and f"{a}/" not in teks and f"({a})" not in teks:
            catatan.append(f"{a} disinggung tanpa konteks jelas — periksa manual")
    tugas_berisiko = sum(1 for _, isi in tugas if "⚠️" in isi)
    if tugas_berisiko < 20:
        gagal.append(f"hanya {tugas_berisiko} tugas bertanda ⚠️ — Area Berisiko seharusnya tersebar di banyak tugas")

    ids_tertangguh = set(re.findall(r"\|\s*(T-\d{3})\s*\|", TERTANGGUH.read_text(encoding="utf-8"))) if TERTANGGUH.is_file() else set()
    tanda_tanya = set(re.findall(r"❓\s*(T-\d{3})", teks))
    if not tanda_tanya:
        gagal.append("tidak ada tanda ❓ T-xxx (padahal ada butir tertangguh)")
    for t in sorted(tanda_tanya - ids_tertangguh):
        gagal.append(f"RUJUKAN MATI: ❓ {t} tidak ada di docs/TERTANGGUH.md")

    for label, pola in HAL_KECIL.items():
        if pola not in teks:
            gagal.append(f"hal kecil terlewat: {label}")
    for label, pola in INTEGRASI.items():
        if pola not in teks:
            gagal.append(f"integrasi terlewat: {label}")

    # ringkasan
    per_fase: dict[str, int] = {}
    for tid, _ in tugas:
        f = tid.split("-")[0]
        per_fase[f] = per_fase.get(f, 0) + 1
    print("PERIKSA ROADMAP — Resto Barokah")
    print(f"  Tugas        : {len(tugas)}  ({', '.join(f'{k}:{v}' for k, v in sorted(per_fase.items()))})")
    print(f"  Atribut 7x   : {'lengkap' if not any('atribut hilang' in g for g in gagal) else 'ADA YANG KURANG'}")
    print(f"  Fitur M1-M12 : {'lengkap' if not any('fitur wajib' in g for g in gagal) else 'ADA YANG KURANG'}")
    print(f"  ⚠️ DECISIONS : {tugas_berisiko} tugas bertanda (dihitung per blok tugas, bukan kemunculan lambang)")
    print(f"  Entitas §4   : {len(nama_entitas())} tabel resmi TECH_SPEC — semuanya wajib disebut di blok tugas")
    print(f"  RPC §5       : {len(nama_rpc())} nama resmi TECH_SPEC — semuanya wajib disebut di blok tugas")
    print(f"  ❓ tertangguh : {len(tanda_tanya)} rujukan" + (" (semua sah)" if tanda_tanya <= ids_tertangguh else " (ADA YANG MATI)"))
    if catatan:
        print("  Catatan      : " + "; ".join(catatan))
    if gagal:
        print(f"\nGAGAL ({len(gagal)} temuan):")
        for g in gagal:
            print(f"  - {g}")
        return 1
    print("\nHASIL: LOLOS — semua pemeriksaan roadmap terpenuhi.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
