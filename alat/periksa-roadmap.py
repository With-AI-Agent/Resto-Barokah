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


def periksa_tunggu(tugas: str, tunggu: str) -> list[str]:
    """Nol butir terbuka sah; setiap butir terbuka wajib punya penanda pada TUGAS.

    Jangan hitung contoh format T-000 atau riwayat di luar blok tugas sebagai penanda.
    Penanda ke butir selesai juga ditolak, supaya dua pemeriksa tidak bertentangan.
    """
    semua = set(re.findall(r"^\|\s*(T-\d{3})\s*\|", tunggu, re.M)) - {"T-000"}
    terbuka = set(re.findall(r"^\|\s*(T-\d{3})\s*\|[^\n]*\[ \] terbuka", tunggu, re.M)) - {"T-000"}
    tanda = set(re.findall(r"❓\s*(T-\d{3})", tugas))
    return ([f"RUJUKAN MATI: ❓ {t} tidak ada di docs/TERTANGGUH.md" for t in sorted(tanda - semua)]
            + [f"❓ {t} basi: butir sudah selesai" for t in sorted(tanda & (semua - terbuka))]
            + [f"{t} masih terbuka tetapi tidak ditandai ❓ pada tugas" for t in sorted(terbuka - tanda)])


POLA_HARAPAN_FILE = re.compile(
    r"\(rencana|belum ada|belum dibuat|akan dibuat|menyusul|dijadwalkan|pindah ke|menggantikan|"
    r"tidak dibuat|disatukan|dilebur|terbuka di|diimplementasikan|tidak di-commit|pengganti|"
    r"nama lama|nomor rencana|L F-|T\d+-\d+",
    re.I
)


def periksa_jalur_file(teks: str, akar: Path = ROOT) -> list[str]:
    """Pastikan setiap berkas yang dirujuk di `File:` untuk tugas `[x]` benar-benar ada di repo.

    Kecuali bila baris tersebut menandai bahwa berkas memang rencana, dipindah, disatukan,
    atau ditangguhkan (POLA_HARAPAN_FILE). Temuan audit L F-08.
    """
    gagal = []
    lines = teks.splitlines()
    cur_tid = None
    cur_checked = False
    cur_lines = []

    def _evaluasi():
        if cur_tid and cur_checked:
            for l in cur_lines:
                if not l.strip().startswith("- **File:**"):
                    continue
                tokens = re.findall(r"`([^`]+)`(?:\s*\(([^)]+)\))?", l)
                for tok, note in tokens:
                    tok = tok.strip()
                    if "/" not in tok or "*" in tok:
                        continue
                    if note and POLA_HARAPAN_FILE.search(note):
                        continue
                    if POLA_HARAPAN_FILE.search(l) and any(k in l for k in (tok.split("/")[-1], tok)):
                        continue
                    if not (akar / tok).exists():
                        gagal.append(f"{cur_tid}: berkas `{tok}` pada File: tidak ada di repo (tandai rencana bila memang belum ada)")

    for line in lines:
        m = re.match(r"^- \[([ x])\] (T\d+-\d+) — (.+)$", line)
        if m:
            _evaluasi()
            cur_tid = m.group(2)
            cur_checked = (m.group(1) == "x")
            cur_lines = [line]
        elif cur_tid:
            if line.startswith("## ") or line.strip() == "---":
                _evaluasi()
                cur_tid = None
                cur_lines = []
            else:
                cur_lines.append(line)
    _evaluasi()
    return gagal


def uji_diri() -> int:
    from bantu_uji_diri import laporkan
    buka = "| T-026 | 2026-09-21 | uji | [ ] terbuka |"
    tutup = "| T-025 | 2026-09-21 | selesai |"
    kasus = [
        ("kosong sah", "", "", False),
        ("semua selesai sah", "", tutup, False),
        ("terbuka bertanda sah", "❓ T-026", buka, False),
        ("terbuka tak bertanda ditolak", "", buka, True),
        ("ID palsu ditolak", "❓ T-999", buka, True),
        ("penanda basi ditolak", "❓ T-025", tutup, True),
        ("contoh format bukan butir nyata", "", "`| T-000 | contoh | [ ] terbuka |`", False),
        ("butir kedua tanpa penanda ditolak", "❓ T-026", buka + "\n| T-027 | x | [ ] terbuka |", True),
    ]
    hasil = []
    for nama, tugas, tunggu, ditolak in kasus:
        err = periksa_tunggu(tugas, tunggu)
        hasil.append((nama, bool(err) == ditolak, "; ".join(err) or "bersih"))
    # Bukti penanda di judul fase/riwayat tidak menggantikan penanda tugas.
    contoh = "## Fase ❓ T-026\n- [ ] T2-01 — tugas\n  - isi\n---\nriwayat ❓ T-026"
    err = periksa_tunggu("\n".join(isi for _, isi in blok_tugas(contoh)), buka)
    hasil.append(("penanda hanya di luar tugas ditolak", bool(err), str(err)))

    # Uji verifikasi rujukan File: tugas [x] (L F-08)
    teks_uji_file_ok = "- [x] T99-01 — tugas\n  - **File:** `alat/periksa-roadmap.py`\n"
    teks_uji_file_hilang = "- [x] T99-02 — tugas\n  - **File:** `alat/tidak-pernah-ada-12345.py`\n"
    teks_uji_file_rencana = "- [x] T99-03 — tugas\n  - **File:** `alat/tidak-pernah-ada-12345.py` (rencana)\n"
    teks_uji_file_belum = "- [ ] T99-04 — tugas belum selesai\n  - **File:** `alat/tidak-pernah-ada-12345.py`\n"

    hasil.append(("file [x] nyata sah", len(periksa_jalur_file(teks_uji_file_ok, ROOT)) == 0, ""))
    hasil.append(("file [x] hilang ditolak", len(periksa_jalur_file(teks_uji_file_hilang, ROOT)) == 1, ""))
    hasil.append(("file [x] hilang ditandai rencana sah", len(periksa_jalur_file(teks_uji_file_rencana, ROOT)) == 0, ""))
    hasil.append(("file [ ] belum selesai dilewati", len(periksa_jalur_file(teks_uji_file_belum, ROOT)) == 0, ""))

    return laporkan("periksa-roadmap", hasil)


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

    tunggu = TERTANGGUH.read_text(encoding="utf-8") if TERTANGGUH.is_file() else ""
    ids_tertangguh = set(re.findall(r"^\|\s*(T-\d{3})\s*\|", tunggu, re.M))
    tanda_tanya = set(re.findall(r"❓\s*(T-\d{3})", isi_tugas))
    gagal.extend(periksa_tunggu(isi_tugas, tunggu))
    if not TERTANGGUH.is_file():
        gagal.append("docs/TERTANGGUH.md tidak ada")

    kesalahan_file = periksa_jalur_file(teks, ROOT)
    if kesalahan_file:
        gagal.extend(kesalahan_file)

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
    sys.exit(uji_diri() if "--uji-diri" in sys.argv else main())
