#!/usr/bin/env python3
"""periksa-fondasi-independen.py — pemeriksa fondasi yang ditulis ULANG dari nol.

Ditulis oleh sesi review independen (2026-09-16). SENGAJA **tidak** menyalin logika
`alat/periksa-roadmap.py` maupun `_sistem/validate_system.py`. Bedanya:

  * pemeriksa lama mencari kata di SELURUH teks ROADMAP (`if e not in teks`) →
    satu penyebutan di tabel ringkasan sudah cukup untuk "lolos".
    Pemeriksa ini menuntut **penyebutan di dalam blok tugas yang punya 7 atribut**,
    sehingga tabel ringkasan/checklist tidak bisa dipakai menutupi tugas yang hilang.
  * pemeriksa lama tidak memeriksa apakah `Ref: DOK §N` menunjuk bagian yang ADA.
    Pemeriksa ini mengurai judul bagian tiap dokumen lalu mencocokkannya.
  * pemeriksa lama tidak memeriksa arah sebaliknya (butir TERTANGGUH terbuka
    yang tidak dirujuk tugas mana pun) dan tidak mendeteksi rujukan ❓ ke butir
    yang sudah SELESAI (rujukan basi — tugas tetap dilewati padahal tidak perlu).
  * pemeriksa lama tidak memeriksa nomor tugas ganda / nomor fase yang bolong.
  * pemeriksa lama tidak mendeteksi atribut "pengisi kosong" (isi terlalu pendek,
    "TBD", "-", dll).

Jalankan:  python3 alat/periksa-fondasi-independen.py
Keluar 0 bila bersih, 1 bila ada temuan.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

AKAR = Path(__file__).resolve().parent.parent
D = AKAR / "docs"

ATRIBUT_WAJIB = ("Tujuan", "Ref", "File", "DoD", "Kompleksitas", "Risiko & mitigasi", "Verifikasi")
PENGISI_KOSONG = re.compile(r"^\s*(tbd|todo|-+|n/?a|belum diisi|\.\.\.)\s*$", re.I)
PANJANG_MIN = 6   # karakter isi atribut yang dianggap bermakna ("PRD M8" sah, "-"/"TBD" tidak)

temuan: list[str] = []
ringkas: list[str] = []


def baca(nama: str) -> str:
    p = D / nama
    return p.read_text(encoding="utf-8") if p.is_file() else ""


def urai_tugas(teks: str) -> list[dict]:
    """Pecah ROADMAP menjadi daftar tugas: id, judul, baris awal, atribut->nilai."""
    baris = teks.splitlines()
    kepala = [(n, m) for n, b in enumerate(baris, 1)
              if (m := re.match(r"^- \[( |x)\] (T\d+-\d+) — (.*)$", b))]
    hasil = []
    for idx, (n, m) in enumerate(kepala):
        akhir = kepala[idx + 1][0] - 1 if idx + 1 < len(kepala) else len(baris)
        isi = baris[n:akhir]
        # potong di batas blok supaya lambang tugas berikutnya tidak ikut terbaca
        for k, b in enumerate(isi):
            if b.startswith("## ") or b.strip() == "---":
                isi = isi[:k]
                break
        atr: dict[str, str] = {}
        kunci = None
        for b in isi:
            a = re.match(r"^\s*- \*\*([^:*]+):?\*\*:?\s*(.*)$", b)
            if a:
                kunci = a.group(1).strip().rstrip(":")
                atr[kunci] = a.group(2).strip()
            elif kunci and b.strip():
                atr[kunci] += " " + b.strip()
        hasil.append({"id": m.group(2), "judul": m.group(3), "baris": n,
                      "selesai": m.group(1) == "x", "atr": atr,
                      "teks": m.group(3) + "\n" + "\n".join(isi)})
    return hasil


def judul_bagian(teks: str) -> set[str]:
    return set(re.findall(r"^#{2,4}\s*([0-9]+(?:\.[0-9]+)?)[.)]?\s", teks, re.M))


# ---------------------------------------------------------------- 1. muat
roadmap = baca("ROADMAP.md")
if not roadmap:
    print("GAGAL: docs/ROADMAP.md tidak ada — tidak bisa memeriksa apa pun.")
    sys.exit(1)
spec = baca("TECH_SPEC.md")
prd = baca("PRD.md")
guide = baca("AGENT_OPERATING_GUIDE.md")
tertangguh = baca("TERTANGGUH.md")
keputusan = baca("DECISIONS_LOG.md")

tugas = urai_tugas(roadmap)
ringkas.append(f"tugas terbaca: {len(tugas)}")

# ---------------------------------------------------------------- 2. penomoran
per_fase: dict[int, list[int]] = {}
terlihat: dict[str, int] = {}
for t in tugas:
    if t["id"] in terlihat:
        temuan.append(f"ROADMAP.md:{t['baris']} nomor tugas GANDA {t['id']} "
                      f"(sudah ada di baris {terlihat[t['id']]})")
    terlihat[t["id"]] = t["baris"]
    f, n = t["id"][1:].split("-")
    per_fase.setdefault(int(f), []).append(int(n))
for f in sorted(per_fase):
    nomor = sorted(per_fase[f])
    if nomor != list(range(1, len(nomor) + 1)):
        temuan.append(f"Fase {f}: nomor tugas tidak berurutan 1..n → {nomor}")
fase_ada = sorted(per_fase)
bolong = [f for f in range(0, max(fase_ada) + 1) if f not in per_fase]
if bolong:
    temuan.append(f"Fase terlewat (tidak punya tugas sama sekali): {bolong}")
ringkas.append("fase: " + ", ".join(f"F{f}={len(per_fase[f])}" for f in fase_ada))

# ---------------------------------------------------------------- 3. 7 atribut + anti pengisi kosong
kurang = kosong = 0
for t in tugas:
    for a in ATRIBUT_WAJIB:
        nilai = next((v for k, v in t["atr"].items() if k.startswith(a[:8])), None)
        if nilai is None:
            temuan.append(f"ROADMAP.md:{t['baris']} {t['id']}: atribut **{a}** hilang")
            kurang += 1
        elif PENGISI_KOSONG.match(nilai) or len(nilai) < PANJANG_MIN:
            temuan.append(f"ROADMAP.md:{t['baris']} {t['id']}: atribut **{a}** hanya pengisi kosong → {nilai!r}")
            kosong += 1
ringkas.append(f"atribut hilang: {kurang} · pengisi kosong: {kosong}")

# ---------------------------------------------------------------- 4. risiko tinggi wajib DECISIONS_LOG
tanpa_log = 0
for t in tugas:
    if "⚠️" in t["teks"] and "DECISIONS_LOG" not in t["teks"]:
        temuan.append(f"ROADMAP.md:{t['baris']} {t['id']}: bertanda ⚠️ tanpa kewajiban DECISIONS_LOG")
        tanpa_log += 1
ringkas.append(f"tugas ⚠️: {sum(1 for t in tugas if '⚠️' in t['teks'])} (tanpa kewajiban log: {tanpa_log})")

# ---------------------------------------------------------------- 5. Ref menunjuk bagian nyata
DOK = {"TECH_SPEC": judul_bagian(spec), "PRD": judul_bagian(prd),
       "AGENT_OPERATING_GUIDE": judul_bagian(guide), "GUIDE": judul_bagian(guide)}
ref_mati = 0
for t in tugas:
    ref = next((v for k, v in t["atr"].items() if k.startswith("Ref")), "")
    if not ref:
        continue
    for dok, sec in re.findall(r"\b(TECH_SPEC|PRD|AGENT_OPERATING_GUIDE|GUIDE)\s*§\s*([0-9]+(?:\.[0-9]+)?)", ref):
        if DOK[dok] and sec not in DOK[dok]:
            temuan.append(f"ROADMAP.md:{t['baris']} {t['id']}: Ref menunjuk {dok} §{sec} yang TIDAK ADA")
            ref_mati += 1
ringkas.append(f"rujukan § mati: {ref_mati}")

# ---------------------------------------------------------------- 6. TERTANGGUH dua arah
terbuka = set(re.findall(r"\|\s*(T-\d{3})\s*\|[^\n]*\[ \] terbuka", tertangguh))
terbuka.discard("T-000")  # baris contoh format, bukan butir nyata
selesai_t = set(re.findall(r"\|\s*(T-\d{3})\s*\|\s*\d{4}-\d{2}-\d{2}\s*\|", tertangguh)) - terbuka
semua_t = terbuka | selesai_t
dirujuk: dict[str, list[str]] = {}
for t in tugas:
    for tid in re.findall(r"❓\s*(T-\d{3})", t["teks"]):
        dirujuk.setdefault(tid, []).append(t["id"])
for tid, pemakai in sorted(dirujuk.items()):
    if tid not in semua_t:
        temuan.append(f"ROADMAP: ❓ {tid} dirujuk oleh {', '.join(pemakai)} tetapi TIDAK ADA di docs/TERTANGGUH.md")
    elif tid in selesai_t:
        temuan.append(f"ROADMAP: ❓ {tid} masih menghalangi {', '.join(pemakai)} padahal butir itu SUDAH SELESAI "
                      f"di docs/TERTANGGUH.md — tanda ❓ basi, tugas akan dilewati tanpa alasan")
for tid in sorted(terbuka - set(dirujuk)):
    temuan.append(f"TERTANGGUH {tid} terbuka tetapi tidak ada satu pun tugas ROADMAP yang menandainya ❓ — "
                  f"tenggatnya tidak dijaga oleh apa pun")
ringkas.append(f"tertangguh terbuka: {len(terbuka)} · selesai: {len(selesai_t)} · dirujuk roadmap: {len(dirujuk)}")
if len(terbuka) > 12:
    temuan.append(f"docs/TERTANGGUH.md: {len(terbuka)} butir terbuka — melewati batas 12 (AGENT_OPERATING_GUIDE §13.6)")
for tid in sorted(terbuka):
    baris = next((b for b in tertangguh.splitlines() if re.search(rf"\|\s*{tid}\s*\|", b)), "")
    if len(baris.split("|")) < 8 or not baris.split("|")[6].strip():
        temuan.append(f"docs/TERTANGGUH.md {tid}: tenggat/alasan tidak terbaca di kolomnya")

# ---------------------------------------------------------------- 7. cakupan M1-M12 / entitas / ART di dalam BLOK tugas
def disebut_dalam_tugas(pola: str) -> list[str]:
    r = re.compile(pola)
    return [t["id"] for t in tugas if r.search(t["teks"])]

for i in range(1, 13):
    if not disebut_dalam_tugas(rf"\bM{i}\b"):
        temuan.append(f"Fitur wajib M{i} tidak disebut di dalam blok tugas mana pun (hanya di tabel ringkasan?)")
for i in range(1, 11):
    kena = disebut_dalam_tugas(rf"\bART-{i}\b")
    if not kena:
        temuan.append(f"Area Berisiko Tinggi ART-{i} tidak disebut di dalam blok tugas mana pun")
    elif not any("⚠️" in t["teks"] for t in tugas if t["id"] in kena):
        temuan.append(f"ART-{i} disebut di {kena} tetapi tidak satu pun bertanda ⚠️")

# entitas diambil LANGSUNG dari tabel TECH_SPEC §4 (bukan daftar tangan yang bisa basi)
entitas = sorted({m for m in re.findall(r"^\|\s*`([a-z_]+)`\s*\|", spec, re.M)})
tanpa_tugas = [e for e in entitas if not disebut_dalam_tugas(rf"\b{e}\b")]
if tanpa_tugas:
    temuan.append("Entitas basis data (TECH_SPEC §4) tanpa penyebutan di blok tugas mana pun: "
                  + ", ".join(tanpa_tugas))
ringkas.append(f"entitas TECH_SPEC §4 terbaca: {len(entitas)} · tanpa tugas: {len(tanpa_tugas)}")

# RPC diambil langsung dari TECH_SPEC §5
rpc = sorted({m for m in re.findall(r"`rpc/([a-z_]+)`", spec)})
id_tugas = {t["id"] for t in tugas}
peta = {}
for baris_peta in roadmap.splitlines():
    if baris_peta.startswith("|") and "T" in baris_peta and "`" in baris_peta:
        nama = re.findall(r"`([a-z_]+)`", baris_peta)
        tujuan = re.findall(r"\bT\d+-\d+\b", baris_peta)
        for n in nama:
            peta.setdefault(n, []).extend(tujuan)
rpc_tanpa = []
for r in rpc:
    if disebut_dalam_tugas(rf"\b{r}\b"):
        continue
    tujuan = [x for x in peta.get(r, []) if x in id_tugas]
    if not tujuan:
        rpc_tanpa.append(r)
if rpc_tanpa:
    temuan.append("RPC (TECH_SPEC §5) tanpa penyebutan di blok tugas mana pun: " + ", ".join(rpc_tanpa))
ringkas.append(f"RPC TECH_SPEC §5 terbaca: {len(rpc)} · tanpa tugas: {len(rpc_tanpa)}")

# ---------------------------------------------------------------- 8. klaim jumlah di ROADMAP harus cocok kenyataan
m = re.search(r"=\s*\*\*(\d+)\s*tugas\*\*", roadmap)
if m and int(m.group(1)) != len(tugas):
    temuan.append(f"ROADMAP mengklaim {m.group(1)} tugas, nyatanya {len(tugas)}")
for f, n in re.findall(r"F(\d+)\s+(\d+)\s*·", roadmap):
    if int(f) in per_fase and len(per_fase[int(f)]) != int(n):
        temuan.append(f"Klaim jumlah tugas F{f}={n} tidak cocok kenyataan {len(per_fase[int(f)])}")

# ---------------------------------------------------------------- 9. DECISIONS_LOG harus ada & berisi
if not keputusan.strip():
    temuan.append("docs/DECISIONS_LOG.md kosong/tidak ada padahal 118 tugas mewajibkannya")

# ---------------------------------------------------------------- keluaran
print("PERIKSA FONDASI INDEPENDEN — Resto Barokah")
for r in ringkas:
    print(f"  · {r}")
if temuan:
    print(f"\nTEMUAN ({len(temuan)}):")
    for t in temuan:
        print(f"  - {t}")
    sys.exit(1)
print("\nHASIL: BERSIH — tidak ada temuan dari pemeriksa independen.")
sys.exit(0)
