#!/usr/bin/env python3
"""periksa-fondasi-independen-2.py — pemeriksa fondasi putaran ke-3 (review independen 2026-09-19).

Ditulis dari nol dan SENGAJA memakai sudut pandang yang belum dipakai dua pemeriksa lama
(`alat/periksa-roadmap.py` dan `alat/periksa-fondasi-independen.py`). Keduanya dibiarkan utuh;
berkas ini adalah pemeriksa KETIGA, bukan pengganti. Perbedaan pokok:

  Pemeriksa lama bertanya "apakah kata X disebut?" — pemeriksa ini bertanya "apakah yang ditulis
  di ROADMAP COCOK dengan yang dijanjikan dokumen terkunci dan dengan isi repo nyata?":

  A. Kosakata status pesanan/item/meja/voucher di ROADMAP dibandingkan dengan enum yang tertulis
     di TECH_SPEC §4 (rantai `a → b → c` yang memakai kata status tak resmi = GAGAL).
  B. Setiap variabel lingkungan di tabel TECH_SPEC §6 harus disebut oleh minimal satu tugas
     (kalau tidak, tidak ada yang tahu siapa memasang kunci itu dan kapan).
  C. Setiap jalur `aplikasi/src/<folder>/` di baris File harus memakai folder yang ada di
     struktur resmi TECH_SPEC §3.
  D. Nomor migrasi `supabase/migrations/NNNN_*.sql` harus unik dan tidak melompat.
  E. Tugas yang baris Risiko-nya mewajibkan DECISIONS_LOG / menyebut ART-n harus memakai lambang
     ⚠️ DI JUDULNYA (arah kebalikan dari pemeriksa lama, yang hanya memeriksa ⚠️ → DECISIONS_LOG).
  F. Label "Area: … (ART-n)" di baris Risiko dicocokkan dengan judul ART-n di TECH_SPEC §9.
  G. Judul fase yang membawa tanda "⚠️ ART-n" harus punya minimal satu tugas ⚠️ ber-ART-n di fase itu.
  H. Baris checklist Tahap 5 ("M1 → T9-10 · M2 → T9-01…T9-07 …") diurai dan tiap tugas yang
     ditunjuk harus ADA dan benar-benar menyebut fitur itu di Ref-nya.
  I. Setiap fitur `### Mn.` di PRD, setiap tabel di TECH_SPEC §4, dan setiap `### ART-n.` di
     TECH_SPEC §9 dicari dari sisi DOKUMEN SUMBER (bukan daftar tangan) → harus punya tugas:
     tabel wajib punya tugas ber-File `supabase/migrations/`; ART wajib punya tugas ⚠️ di judul.
  J. 7 atribut: diperiksa per baris dengan pola label yang berbeda, ditambah deteksi
     "isi kembar" — nilai atribut yang identik di banyak tugas adalah pengisi templat.
  K. Rujukan bernomor di Ref: "Aturan Bisnis N" ≤ jumlah aturan di PRD §8; "risiko #N" ≤ jumlah baris
     tabel PRD §9; `Mn` ≤ 12; `Kn` ≤ 6; `ART-n` ≤ 10; berkas yang dirujuk (mis. prototipe/README.md) harus ada.
  L. Penomoran: setiap tugas harus berada di bawah judul "## Fase N" yang nomornya sama dengan
     awalan ID-nya (T4-xx di bawah Fase 3 = salah tempat); nomor ganda; fase bolong.
  M. TERTANGGUH: butir terbuka yang tenggatnya "Fn"/"Tn-xx" harus punya minimal satu tugas ❓ di fase ≤ n
     (kalau tidak, aturan "tenggat lewat = hard stop" tidak pernah bisa terpicu).
  N. Angka yang ditulis dokumen dibandingkan dengan kenyataan di disk: jumlah tugas di docs/README.md
     dan ROADMAP, jumlah folder & SKILL.md di skills/ yang diklaim AGENT_OPERATING_GUIDE §2.
  Q. Tugas ⚠️ yang sudah dicentang [x] wajib disebut (ID-nya) di DECISIONS_LOG — jejak keputusan, bukan sekadar "berkas ada".
  P. `PROJECT_STATE.md` wajib ada bila ROADMAP ada, dan nilai `STATUS:`-nya harus dikenal tabel AGENT_SYSTEM.md
     (`validate_system.py` tidak memeriksa berkas ini sama sekali).
  O. Ketergantungan maju: DoD/Verifikasi yang merujuk tugas di fase LEBIH LAMBAT = GAGAL; rujukan maju
     di baris Risiko hanya dicatat. Ditambah: DoD yang memakai konsep "shift terbuka" sebelum fase
     tempat RPC `buka_shift` dibangun (dibaca dari tabel Peta RPC) — kecuali blok tugas menyebut dari
     mana shift itu datang (kata "seed").

Pemakaian:
    python3 alat/periksa-fondasi-independen-2.py                 # periksa repo tempat skrip ini berada
    python3 alat/periksa-fondasi-independen-2.py --akar /jalur   # periksa pohon fondasi lain
    python3 alat/periksa-fondasi-independen-2.py --uji-diri      # bukti pemeriksa ini benar-benar menggigit

Keluar 0 bila tidak ada GAGAL (PERINGATAN boleh ada), 1 bila ada GAGAL atau dokumen tidak ditemukan.
Hanya pustaka standar Python.
"""
from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from pathlib import Path

ATRIBUT = ("Tujuan", "Ref", "File", "DoD", "Kompleksitas", "Risiko & mitigasi", "Verifikasi")
KATA_UMUM_ARAH = {  # token rantai `→` yang bukan status, supaya tidak salah tuduh
    "pesan", "kirim", "bayar", "cetak", "tutup", "buka", "void", "matikan", "nyalakan", "pulih",
    "ubah", "cek", "pakai", "simpan", "muat", "katalog", "kasir", "dapur", "laporan", "struk",
}
KATA_SALAH_STATUS = {"dibayar", "dibatalkan", "terkirim", "menunggu", "selesai", "dikirimkan", "terbayar"}
SINONIM_AREA = {  # kata Inggris/gaya lama di baris Risiko → kata di judul ART TECH_SPEC
    "role": "peran", "permission": "izin", "rls": "rls", "auth": "peran", "keuangan": "uang",
    "kalkulasi": "uang", "voucher": "voucher", "kas": "kas", "shift": "shift", "cetak": "cetak",
    "printer": "cetak", "offline": "offline", "antrean": "offline", "zona": "zona", "waktu": "zona",
    "privasi": "privasi", "pelanggan": "privasi", "state": "state", "pesanan": "pesanan",
    "isolasi": "isolasi", "penyewa": "penyewa", "pengaturan": "uang",
}


class Hasil:
    def __init__(self) -> None:
        self.gagal: list[str] = []
        self.peringatan: list[str] = []
        self.info: list[str] = []

    def g(self, pesan: str) -> None:
        self.gagal.append(pesan)

    def p(self, pesan: str) -> None:
        self.peringatan.append(pesan)

    def i(self, pesan: str) -> None:
        self.info.append(pesan)


# ----------------------------------------------------------------------------- pengurai

def urai_roadmap(teks: str) -> tuple[list[dict], list[tuple[int, int, str]]]:
    """Kembalikan (daftar tugas, daftar judul fase). Tiap tugas: id, fase_judul, judul, baris, atr, blok."""
    baris = teks.splitlines()
    fase_judul: list[tuple[int, int, str]] = []  # (nomor baris, nomor fase, teks judul)
    for n, b in enumerate(baris, 1):
        m = re.match(r"^## Fase (\d+)\s*[—-]\s*(.*)$", b)
        if m:
            fase_judul.append((n, int(m.group(1)), m.group(2)))
    tugas: list[dict] = []
    fase_aktif = None
    i = 0
    while i < len(baris):
        b = baris[i]
        mf = re.match(r"^## Fase (\d+)", b)
        if mf:
            fase_aktif = int(mf.group(1))
        elif b.startswith("## "):
            fase_aktif = None
        m = re.match(r"^- \[( |x)\] (T(\d+)-(\d+)) — (.*)$", b)
        if m:
            j = i + 1
            blok: list[str] = []
            while j < len(baris) and not re.match(r"^- \[( |x)\] T\d+-\d+ — ", baris[j]) \
                    and not baris[j].startswith("## ") and baris[j].strip() != "---":
                blok.append(baris[j])
                j += 1
            atr: dict[str, str] = {}
            for bb in blok:
                ma = re.match(r"^\s{2,}- \*\*(Tujuan|Ref|File|DoD|Kompleksitas|Risiko & mitigasi|Verifikasi|Catatan)"
                              r"[^*]*\*\*\s*:?\s*(.*)$", bb)
                if ma:
                    atr[ma.group(1)] = ma.group(2).strip()
            tugas.append({
                "id": m.group(2), "fase": int(m.group(3)), "nomor": int(m.group(4)),
                "fase_judul": fase_aktif, "judul": m.group(5).strip(), "baris": i + 1,
                "atr": atr, "blok": "\n".join(blok),
            })
            i = j
            continue
        i += 1
    return tugas, fase_judul


def enum_status_spec(spec: str) -> set[str]:
    """Kumpulkan kata status resmi dari TECH_SPEC §4/§9: pola `status` (a/b/c) dan rantai a → b → c."""
    kata: set[str] = set()
    for grup in re.findall(r"`status`\s*\(([a-z_/ ]+)\)", spec):
        kata.update(x.strip() for x in grup.split("/") if x.strip())
    for grup in re.findall(r"`status`:\s*((?:`[a-z_]+`\s*(?:→|/)\s*)+`[a-z_]+`)", spec):
        kata.update(re.findall(r"`([a-z_]+)`", grup))
    for grup in re.findall(r"`((?:[a-z_]+\s*→\s*)+[a-z_]+)`", spec):
        kata.update(x.strip() for x in grup.split("→"))
    kata.discard("status")
    return kata


def tabel_env_spec(spec: str) -> list[str]:
    bagian = re.search(r"^## 6\..*?(?=^## 7\.)", spec, re.S | re.M)
    if not bagian:
        return []
    return re.findall(r"^\|\s*`([A-Z][A-Z0-9_]+)`\s*\|", bagian.group(0), re.M)


def folder_src_spec(spec: str) -> set[str]:
    bagian = re.search(r"^## 3\..*?(?=^## 4\.)", spec, re.S | re.M)
    if not bagian:
        return set()
    hasil: set[str] = set()
    dalam_src = False
    for b in bagian.group(0).splitlines():
        if re.match(r"^\s{2}/src\b", b):
            dalam_src = True
            continue
        if dalam_src:
            if re.match(r"^/", b):
                dalam_src = False
                continue
            m = re.match(r"^\s{4}/([a-z-]+)", b)
            if m:
                hasil.add(m.group(1))
    return hasil


def judul_art_spec(spec: str) -> dict[int, str]:
    return {int(n): j.strip() for n, j in re.findall(r"^### ART-(\d+)\.\s*(.+)$", spec, re.M)}


def tabel_spec_entitas(spec: str) -> list[str]:
    bagian = re.search(r"^## 4\..*?(?=^## 5\.)", spec, re.S | re.M)
    if not bagian:
        return []
    return sorted({m for m in re.findall(r"^\|\s*`([a-z_]+)`\s*\|", bagian.group(0), re.M)})


def fitur_prd(prd: str) -> list[int]:
    return sorted({int(n) for n in re.findall(r"^### M(\d+)\.", prd, re.M)})


def jumlah_aturan_bisnis(prd: str) -> int:
    bagian = re.search(r"^## 8\..*?(?=^## 9\.)", prd, re.S | re.M)
    return len(re.findall(r"^\d+\.\s", bagian.group(0), re.M)) if bagian else 0


def jumlah_risiko_prd(prd: str) -> int:
    bagian = re.search(r"^## 9\..*?(?=^## 10\.)", prd, re.S | re.M)
    return len(re.findall(r"^\|\s*\d+\s*\|", bagian.group(0), re.M)) if bagian else 0


def peta_rpc(roadmap: str) -> dict[str, list[str]]:
    peta: dict[str, list[str]] = {}
    for b in roadmap.splitlines():
        if b.startswith("|") and "`" in b and re.search(r"\bT\d+-\d+\b", b):
            for nama in re.findall(r"`([a-z_]+)`", b):
                peta.setdefault(nama, []).extend(re.findall(r"\bT\d+-\d+\b", b))
    return peta


def rentang_tugas(teks: str) -> list[str]:
    """'T3-01…T3-16' → [T3-01, …, T3-16]; 'T1-05/T1-06' → keduanya."""
    hasil: list[str] = []
    for a, b in re.findall(r"(T\d+-\d+)\s*(?:…|\.\.\.|–)\s*(T\d+-\d+)", teks):
        fa, na = a[1:].split("-")
        fb, nb = b[1:].split("-")
        if fa == fb:
            hasil.extend(f"T{fa}-{n:02d}" for n in range(int(na), int(nb) + 1))
    sisa = re.sub(r"(T\d+-\d+)\s*(?:…|\.\.\.|–)\s*(T\d+-\d+)", " ", teks)
    hasil.extend(re.findall(r"\bT\d+-\d+\b", sisa))
    return hasil


# ----------------------------------------------------------------------------- pemeriksaan

def periksa(akar: Path, h: Hasil, teks_roadmap: str | None = None) -> None:
    d = akar / "docs"
    roadmap = teks_roadmap if teks_roadmap is not None else (d / "ROADMAP.md").read_text(encoding="utf-8")
    spec = (d / "TECH_SPEC.md").read_text(encoding="utf-8")
    prd = (d / "PRD.md").read_text(encoding="utf-8")
    tertangguh = (d / "TERTANGGUH.md").read_text(encoding="utf-8")
    guide = (d / "AGENT_OPERATING_GUIDE.md").read_text(encoding="utf-8")
    readme = (d / "README.md").read_text(encoding="utf-8") if (d / "README.md").is_file() else ""

    tugas, fase_judul = urai_roadmap(roadmap)
    if len(tugas) < 50:
        h.g(f"ROADMAP hanya terbaca {len(tugas)} tugas — format berubah atau berkas rusak")
        return
    id_ke_tugas = {t["id"]: t for t in tugas}
    h.i(f"tugas terbaca: {len(tugas)} · fase: {len(fase_judul)}")

    # L. penomoran & penempatan di bawah judul fase yang benar
    hitung = Counter(t["id"] for t in tugas)
    for tid, n in sorted(hitung.items()):
        if n > 1:
            h.g(f"nomor tugas ganda: {tid} muncul {n} kali")
    def norm_judul(j: str) -> str:
        return re.sub(r"<!--.*?-->|\s+", " ", j).strip().lower()
    judul_norm = Counter(norm_judul(t["judul"]) for t in tugas)
    for j, n in judul_norm.items():
        if n > 1:
            pemilik = ", ".join(t["id"] for t in tugas if norm_judul(t["judul"]) == j)
            h.g(f"judul tugas persis sama dipakai {n} tugas: '{j}' → {pemilik}")
    nomor_fase = [f for _, f, _ in fase_judul]
    if nomor_fase != list(range(nomor_fase[0], nomor_fase[0] + len(nomor_fase))):
        h.g(f"judul fase tidak berurutan/bolong: {nomor_fase}")
    for t in tugas:
        if t["fase_judul"] is None:
            h.g(f"ROADMAP.md:{t['baris']} {t['id']} berada di luar judul '## Fase N' mana pun")
        elif t["fase_judul"] != t["fase"]:
            h.g(f"ROADMAP.md:{t['baris']} {t['id']} tertulis di bawah judul Fase {t['fase_judul']} — salah tempat")
    per_fase: dict[int, list[int]] = {}
    for t in tugas:
        per_fase.setdefault(t["fase"], []).append(t["nomor"])
    for f, nn in sorted(per_fase.items()):
        if sorted(nn) != list(range(min(nn), min(nn) + len(nn))):
            h.g(f"Fase {f}: nomor tugas melompat/ganda → {sorted(nn)}")

    # J. 7 atribut per baris + isi kembar
    for t in tugas:
        for a in ATRIBUT:
            nilai = t["atr"].get(a)
            if nilai is None:
                h.g(f"ROADMAP.md:{t['baris']} {t['id']}: baris atribut **{a}** tidak ditemukan")
            elif a == "Ref":
                if not re.search(r"\b(PRD|TECH_SPEC|AGENT_OPERATING_GUIDE|GUIDE|DISCOVERY|prototipe|docs/)\b", nilai):
                    h.g(f"ROADMAP.md:{t['baris']} {t['id']}: atribut **Ref** tidak menunjuk dokumen fondasi mana pun → {nilai!r}")
            elif len(re.findall(r"[A-Za-z]{3,}", nilai)) < 2:
                h.g(f"ROADMAP.md:{t['baris']} {t['id']}: atribut **{a}** tidak berisi kalimat bermakna → {nilai!r}")
    for a in ("Tujuan", "DoD", "Verifikasi", "Risiko & mitigasi"):
        kembar = Counter(t["atr"].get(a, "").lower() for t in tugas)
        for nilai, n in kembar.items():
            if nilai and n >= 5:
                h.g(f"atribut **{a}** berisi kalimat yang persis sama di {n} tugas (pengisi templat): {nilai[:70]!r}")

    # A. kosakata status
    status_resmi = enum_status_spec(spec)
    if not status_resmi:
        h.p("TECH_SPEC §4 tidak memuat enum status yang bisa diurai — pemeriksaan kosakata status dilewati")
    else:
        h.i("kata status resmi (TECH_SPEC §4/§9): " + ", ".join(sorted(status_resmi)))
        for t in tugas:
            teks = " ".join(t["atr"].get(a, "") for a in ("DoD", "Verifikasi", "Tujuan"))
            for rantai in re.findall(r"((?:[a-z_]+\s*→\s*){1,}[a-z_]+)", teks):
                token = [x.strip() for x in rantai.split("→")]
                resmi = sum(1 for x in token if x in status_resmi)
                salah = [x for x in token if x not in status_resmi and x not in KATA_UMUM_ARAH]
                if salah and (resmi >= 2 or any(x in KATA_SALAH_STATUS for x in salah)):
                    h.g(f"ROADMAP.md:{t['baris']} {t['id']}: rantai status '{rantai}' memakai kata yang TIDAK ada di "
                        f"TECH_SPEC §4 → {salah} (resmi: draf/dikirim/dimasak/siap/lunas/batal; item: baru/dimasak/siap/batal)")
            for kata_salah in re.findall(r"status\s+[\"'`]?(dibayar|dibatalkan|terkirim|menunggu|selesai)\b", teks):
                h.p(f"ROADMAP.md:{t['baris']} {t['id']}: 'status {kata_salah}' — kata itu bukan status resmi TECH_SPEC §4")

    # B. variabel lingkungan §6
    env = tabel_env_spec(spec)
    if not env:
        h.p("TECH_SPEC §6 tidak memuat tabel variabel lingkungan yang bisa diurai")
    for v in env:
        pemakai = [t["id"] for t in tugas if v in t["blok"] or v in t["judul"]]
        if not pemakai:
            h.g(f"TECH_SPEC §6 variabel `{v}` tidak disebut oleh satu pun tugas ROADMAP — "
                f"tidak ada yang menetapkan siapa memasang kuncinya, di mana, dan kapan")
    h.i(f"variabel lingkungan §6 terbaca: {len(env)}")

    # C. folder src
    folder = folder_src_spec(spec)
    if folder:
        for t in tugas:
            for f in re.findall(r"aplikasi/src/([a-z-]+)/", t["atr"].get("File", "")):
                if f not in folder:
                    h.g(f"ROADMAP.md:{t['baris']} {t['id']}: File memakai folder aplikasi/src/{f}/ yang tidak ada di "
                        f"TECH_SPEC §3 (resmi: {', '.join(sorted(folder))})")
        for t in tugas:
            for jalur in re.findall(r"`(aplikasi/alat/[^`]+)`", t["atr"].get("File", "")):
                h.p(f"ROADMAP.md:{t['baris']} {t['id']}: File `{jalur}` — TECH_SPEC §3 hanya mengenal `/alat` di akar, "
                    f"bukan `aplikasi/alat/`")
    else:
        h.p("TECH_SPEC §3 tidak bisa diurai — pemeriksaan folder dilewati")

    # D. nomor migrasi
    migrasi: dict[str, list[str]] = {}
    for t in tugas:
        for n in re.findall(r"supabase/migrations/(\d{4})_", t["atr"].get("File", "")):
            migrasi.setdefault(n, []).append(t["id"])
    for n, ids in sorted(migrasi.items()):
        if len(ids) > 1:
            h.g(f"nomor migrasi {n} dipakai lebih dari satu tugas: {', '.join(ids)}")
    if migrasi:
        nomor = sorted(int(n) for n in migrasi)
        lompat = [n for n in range(nomor[0], nomor[-1]) if n not in set(nomor)]
        if lompat:
            h.p(f"nomor migrasi melompat (tidak dipakai tugas mana pun): {lompat}")
    h.i(f"nomor migrasi direncanakan: {len(migrasi)} (dari {min(migrasi) if migrasi else '-'} s/d {max(migrasi) if migrasi else '-'})")

    # E. kewajiban DECISIONS_LOG / ART di Risiko → ⚠️ wajib di judul
    for t in tugas:
        risiko = t["atr"].get("Risiko & mitigasi", "")
        wajib = "DECISIONS_LOG" in risiko or re.search(r"\bART-\d+\b", risiko)
        if wajib and "⚠️" not in t["judul"]:
            h.g(f"ROADMAP.md:{t['baris']} {t['id']}: baris Risiko mewajibkan DECISIONS_LOG/ART tetapi JUDUL tugas "
                f"tidak memakai ⚠️ — agent yang menyaring tugas dari judul akan melewatkan kewajibannya")

    # F. label Area (ART-n) cocok judul ART di TECH_SPEC
    art = judul_art_spec(spec)
    for t in tugas:
        risiko = t["atr"].get("Risiko & mitigasi", "")
        for area, n in re.findall(r"Area:\s*([^;(]+?)\s*\(ART-(\d+)", risiko):
            n = int(n)
            if n not in art:
                h.g(f"ROADMAP.md:{t['baris']} {t['id']}: Risiko menyebut ART-{n} yang tidak ada di TECH_SPEC §9")
                continue
            kata_area = {SINONIM_AREA.get(k, k) for k in re.findall(r"[a-z]+", area.lower())}
            kata_judul = set(re.findall(r"[a-z]+", art[n].lower()))
            if not (kata_area & kata_judul):
                h.p(f"ROADMAP.md:{t['baris']} {t['id']}: label 'Area: {area.strip()} (ART-{n})' tidak cocok dengan judul "
                    f"ART-{n} di TECH_SPEC §9 ('{art[n]}')")

    # G. tanda ART pada judul fase
    for nb, f, judul in fase_judul:
        for n in re.findall(r"ART-(\d+)", judul):
            ada = [t["id"] for t in tugas if t["fase"] == f and "⚠️" in t["judul"] and f"ART-{n}" in t["blok"]]
            if not ada:
                h.g(f"ROADMAP.md:{nb} judul Fase {f} membawa tanda ART-{n} tetapi tidak ada tugas ⚠️ ber-ART-{n} di fase itu")

    # H. checklist Tahap 5 pemetaan Mn → tugas
    m_check = re.search(r"Must Have\**\s*M1–M12 punya task:\**\s*(.+)$", roadmap, re.M)
    if not m_check:
        h.p("baris checklist 'Must Have M1–M12 punya task' tidak ditemukan — pemetaan tidak bisa diuji")
    else:
        for fitur, tujuan in re.findall(r"(M\d+)\s*→\s*([^·]+)", m_check.group(1)):
            longgar: list[str] = []
            for tid in rentang_tugas(tujuan):
                if tid not in id_ke_tugas:
                    h.g(f"checklist Tahap 5: {fitur} → {tid} tetapi tugas {tid} tidak ada")
                elif not re.search(rf"\b{fitur}\b", id_ke_tugas[tid]["atr"].get("Ref", "") + id_ke_tugas[tid]["judul"]):
                    longgar.append(tid)
            if longgar:
                h.p(f"checklist Tahap 5: {fitur} dipetakan ke {len(longgar)} tugas yang Ref/judulnya tidak menyebut {fitur} "
                    f"({', '.join(longgar[:6])}{'…' if len(longgar) > 6 else ''}) — pemetaan kelengkapan longgar, periksa manual")

    # I. sumber dokumen → tugas
    for n in fitur_prd(prd):
        if not any(re.search(rf"\bM{n}\b", t["atr"].get("Ref", "")) for t in tugas):
            h.g(f"PRD fitur M{n} tidak dirujuk di Ref tugas mana pun")
    entitas = tabel_spec_entitas(spec)
    for e in entitas:
        pembuat = [t["id"] for t in tugas if "supabase/migrations/" in t["atr"].get("File", "")
                   and re.search(rf"\b{e}\b", t["blok"] + " " + t["judul"])]
        if not pembuat:
            h.g(f"tabel `{e}` (TECH_SPEC §4) tidak disebut oleh tugas mana pun yang punya berkas migrasi")
    h.i(f"tabel TECH_SPEC §4 terbaca: {len(entitas)} · fitur PRD: {len(fitur_prd(prd))} · ART: {len(art)}")
    for n in art:
        if not any("⚠️" in t["judul"] and f"ART-{n}" in t["blok"] for t in tugas):
            h.g(f"ART-{n} ({art[n]}) tidak punya tugas ⚠️ yang menyebutnya")

    # K. rujukan bernomor & berkas
    n_aturan = jumlah_aturan_bisnis(prd)
    n_risiko = jumlah_risiko_prd(prd)
    for t in tugas:
        ref = t["atr"].get("Ref", "") + " " + t["atr"].get("Risiko & mitigasi", "")
        for n in re.findall(r"Aturan Bisnis\s+(\d+)", ref):
            if n_aturan and int(n) > n_aturan:
                h.g(f"ROADMAP.md:{t['baris']} {t['id']}: merujuk Aturan Bisnis {n}, PRD §8 hanya punya {n_aturan}")
        for n in re.findall(r"risiko\s*#(\d+)", ref):
            if n_risiko and int(n) > n_risiko:
                h.g(f"ROADMAP.md:{t['baris']} {t['id']}: merujuk risiko #{n}, PRD §9 hanya punya {n_risiko} baris")
        for n in re.findall(r"\bM(\d+)\b", ref):
            if int(n) > 12 or int(n) < 1:
                h.g(f"ROADMAP.md:{t['baris']} {t['id']}: merujuk M{n} (hanya M1–M12 yang ada)")
        for n in re.findall(r"\bK(\d)\b", ref):
            if int(n) > 6 or int(n) < 1:
                h.g(f"ROADMAP.md:{t['baris']} {t['id']}: merujuk K{n} (hanya K1–K6 yang ada)")
        for n in re.findall(r"\bART-(\d+)\b", ref):
            if int(n) not in art:
                h.g(f"ROADMAP.md:{t['baris']} {t['id']}: merujuk ART-{n} yang tidak ada")
        for jalur in re.findall(r"`((?:prototipe|docs|_sistem|alat)/[^`]+\.(?:md|py|css))`", t["atr"].get("Ref", "")):
            if not (akar / jalur).exists():
                h.g(f"ROADMAP.md:{t['baris']} {t['id']}: Ref menunjuk berkas `{jalur}` yang tidak ada di repo")

    # M. TERTANGGUH: tenggat ↔ fase tugas ❓
    terbuka: dict[str, str] = {}
    for b in tertangguh.splitlines():
        kol = [k.strip() for k in b.strip().strip("|").split("|")]
        if len(kol) >= 8 and re.match(r"T-\d{3}$", kol[0]) and "terbuka" in kol[7] and kol[0] != "T-000":
            terbuka[kol[0]] = kol[5]
    for tid, tenggat in sorted(terbuka.items()):
        m = re.search(r"\bF(\d+)\b", tenggat) or re.search(r"\bT(\d+)-\d+\b", tenggat)
        if not m:
            h.p(f"TERTANGGUH {tid}: tenggat '{tenggat}' tidak menyebut fase/tugas yang bisa dijaga otomatis")
            continue
        batas = int(m.group(1))
        penjaga = [t["id"] for t in tugas if f"❓ {tid}" in (t["judul"] + t["blok"]) or f"{tid}" in t["judul"]]
        if not penjaga:
            h.g(f"TERTANGGUH {tid} terbuka tetapi tidak ada tugas ❓ {tid}")
        elif min(id_ke_tugas[p]["fase"] for p in penjaga) > batas:
            h.g(f"TERTANGGUH {tid}: tenggat '{tenggat}' (≤ Fase {batas}) tetapi tugas ❓ pertama yang menjaganya "
                f"ada di Fase {min(id_ke_tugas[p]['fase'] for p in penjaga)} ({', '.join(penjaga)}) — "
                f"hard stop tenggat tidak akan pernah terpicu di fase {batas}")
    h.i(f"butir tertangguh terbuka: {len(terbuka)}")

    # N. angka dokumen vs kenyataan
    m = re.search(r"\*\*(\d+)\s*tugas\*\*", roadmap)
    if m and int(m.group(1)) != len(tugas):
        h.g(f"ROADMAP menulis {m.group(1)} tugas, nyatanya {len(tugas)}")
    for n in re.findall(r"(\d+)\s*tugas dalam\s*\d+\s*fase", readme):
        if int(n) != len(tugas):
            h.g(f"docs/README.md menulis '{n} tugas', nyatanya {len(tugas)} — angka basi")
    skills = akar / "skills"
    if skills.is_dir():
        n_dir = sum(1 for p in skills.iterdir() if p.is_dir())
        n_skill_md = sum(1 for _ in skills.rglob("SKILL.md"))
        for klaim_dir, klaim_md in re.findall(r"\((\d+) folder, (\d+) berkas SKILL\.md", guide):
            if int(klaim_dir) != n_dir or int(klaim_md) != n_skill_md:
                h.p(f"AGENT_OPERATING_GUIDE §2 menulis skills/ = {klaim_dir} folder & {klaim_md} SKILL.md; "
                    f"nyata {n_dir} folder & {n_skill_md} SKILL.md")
        h.i(f"skills/: {n_dir} folder · {n_skill_md} SKILL.md")

    # O. ketergantungan maju
    peta = peta_rpc(roadmap)
    fase_buka_shift = min((id_ke_tugas[x]["fase"] for x in peta.get("buka_shift", []) if x in id_ke_tugas), default=None)
    maju_risiko = 0
    for t in tugas:
        for a in ("DoD", "Verifikasi"):
            for lain in re.findall(r"\bT(\d+)-(\d+)\b", t["atr"].get(a, "")):
                if int(lain[0]) > t["fase"]:
                    h.g(f"ROADMAP.md:{t['baris']} {t['id']}: {a} bergantung pada T{lain[0]}-{lain[1]} yang baru dikerjakan "
                        f"di Fase {int(lain[0])} — tugas ini tidak bisa selesai di fasenya sendiri")
        for lain in re.findall(r"\bT(\d+)-(\d+)\b", t["atr"].get("Risiko & mitigasi", "")):
            if int(lain[0]) > t["fase"]:
                maju_risiko += 1
        if fase_buka_shift is not None and t["fase"] < fase_buka_shift and \
                re.search(r"shift (yang )?(terbuka|dibuka)", t["atr"].get("DoD", ""), re.I) and \
                not re.search(r"\bseed\b", t["blok"] + t["judul"], re.I):
            h.g(f"ROADMAP.md:{t['baris']} {t['id']}: DoD mensyaratkan 'shift terbuka' padahal RPC `buka_shift` baru dibangun "
                f"di Fase {fase_buka_shift} — tidak ada cara membuka shift saat tugas ini diuji (perlu seed/uji SQL yang disebut eksplisit)")
    h.i(f"rujukan maju di baris Risiko (mitigasi menunjuk tugas fase lebih lambat, hanya dicatat): {maju_risiko}")

    # Q. tugas ⚠️ yang sudah dicentang [x] wajib punya jejak di DECISIONS_LOG (AT-07 "DECISIONS_LOG dijaga")
    #    — diuji 2026-09-19: DECISIONS_LOG dikosongkan sampai 3 baris, tiga pemeriksa lama tetap hijau.
    keputusan = (d / "DECISIONS_LOG.md").read_text(encoding="utf-8") if (d / "DECISIONS_LOG.md").is_file() else ""
    selesai_berisiko = [t for t in tugas if re.match(r"- \[x\]", roadmap.splitlines()[t["baris"] - 1]) and "⚠️" in t["judul"]]
    id_di_log = set(rentang_tugas(keputusan))  # "T1-01…T1-04" di judul entri dihitung mencakup T1-02 & T1-03
    tanpa_jejak = [t["id"] for t in selesai_berisiko if t["id"] not in id_di_log]
    for tid in tanpa_jejak:
        h.g(f"{tid} bertanda ⚠️ dan sudah dicentang [x], tetapi docs/DECISIONS_LOG.md tidak menyebut {tid} sama sekali — "
            f"kewajiban \"DECISIONS_LOG diperbarui untuk tugas ⚠️\" tidak terbukti")
    h.i(f"tugas ⚠️ selesai: {len(selesai_berisiko)} · tanpa jejak di DECISIONS_LOG: {len(tanpa_jejak)}")

    # P. PROJECT_STATE.md: ada & STATUS-nya nilai yang dikenal AGENT_SYSTEM.md
    #    (validate_system.py tidak memeriksa berkas ini sama sekali — diuji 2026-09-19: dihapus pun tetap PASS)
    ps = akar / "PROJECT_STATE.md"
    agent_system = (akar / "AGENT_SYSTEM.md").read_text(encoding="utf-8") if (akar / "AGENT_SYSTEM.md").is_file() else ""
    if not ps.is_file():
        h.g("PROJECT_STATE.md tidak ada padahal docs/ROADMAP.md ada — sesi baru tidak tahu posisinya (validate_system.py tidak menangkap ini)")
    else:
        m = re.search(r"^STATUS:\s*([A-Z0-9_]+)", ps.read_text(encoding="utf-8"), re.M)
        dikenal = set(re.findall(r"`(CODING_[A-Z_]+|SIKLUS_[A-Z_]+|FONDASI_TAHAP_[0-9]_[A-Z_]+)`", agent_system))
        if not m:
            h.g("PROJECT_STATE.md: baris `STATUS: <nilai>` tidak terbaca")
        elif agent_system and m.group(1) not in dikenal and not re.match(r"FONDASI_TAHAP_[1-6]_[A-Z_]+$", m.group(1)):
            h.g(f"PROJECT_STATE.md: STATUS `{m.group(1)}` tidak ada di tabel status AGENT_SYSTEM.md "
                f"(dikenal: {', '.join(sorted(dikenal))}) — agent baru tidak punya prosedur untuk nilai ini")
        else:
            h.i(f"PROJECT_STATE.md STATUS: {m.group(1) if m else '?'}")


# ----------------------------------------------------------------------------- uji diri

def uji_diri(akar: Path) -> int:
    asli = (akar / "docs" / "ROADMAP.md").read_text(encoding="utf-8")

    def jalankan(teks: str) -> list[str]:
        h = Hasil()
        periksa(akar, h, teks_roadmap=teks)
        return h.gagal

    dasar = jalankan(asli)
    mutasi: list[tuple[str, str, str]] = []
    # 1. hilangkan ⚠️ dari judul tugas yang Risiko-nya wajib DECISIONS_LOG
    m = re.search(r"^(- \[ \] T\d+-\d+ — .*?) ⚠️\s*$", asli, re.M)
    if m:
        mutasi.append(("⚠️ dihapus dari judul", m.group(0), m.group(1)))
    # 2. nomor migrasi digandakan
    m = re.search(r"supabase/migrations/(\d{4})_", asli)
    if m:
        semua = re.findall(r"supabase/migrations/(\d{4})_", asli)
        lain = next(x for x in semua if x != m.group(1))
        mutasi.append(("nomor migrasi ganda", f"supabase/migrations/{lain}_", f"supabase/migrations/{m.group(1)}_"))
    # 3. kata status tak resmi
    mutasi.append(("status tak resmi", "draf → dikirim", "draf → terkirim"))
    # 4. tugas salah tempat: pindahkan judul fase
    m = re.search(r"^## Fase 1 —", asli, re.M)
    if m:
        mutasi.append(("tugas di bawah fase salah", "## Fase 1 —", "## Fase 2 —"))
    # 5. hapus penyebutan variabel lingkungan
    mutasi.append(("variabel §6 hilang", "VITE_SUPABASE_URL", "VITE_SUPABASE_ALAMAT"))
    # 6. klaim jumlah tugas salah
    m = re.search(r"\*\*(\d+)\s*tugas\*\*", asli)
    if m:
        mutasi.append(("klaim jumlah tugas salah", m.group(0), "**999 tugas**"))
    # 7. DoD bergantung tugas fase lebih lambat
    m = re.search(r"^(  - \*\*DoD:\*\* )(.*)$", asli, re.M)
    if m:
        mutasi.append(("DoD bergantung fase lebih lambat", m.group(0), m.group(1) + m.group(2) + " (memakai T11-07)"))

    gagal_uji = 0
    print("UJI DIRI periksa-fondasi-independen-2.py")
    print(f"  dasar: {len(dasar)} GAGAL pada ROADMAP asli")
    for nama, lama, baru in mutasi:
        if lama not in asli:
            print(f"  [LEWAT] {nama}: teks sasaran tidak ada di ROADMAP ini")
            continue
        hasil = jalankan(asli.replace(lama, baru))
        tambahan = [x for x in hasil if x not in dasar]
        if tambahan:
            print(f"  [TERTANGKAP] {nama} → +{len(tambahan)} temuan baru; contoh: {tambahan[0][:110]}")
        else:
            print(f"  [LOLOS TANPA TERTANGKAP] {nama} — pemeriksa TIDAK menggigit!")
            gagal_uji += 1
    print(f"HASIL UJI DIRI: {'LULUS' if gagal_uji == 0 else 'GAGAL'} ({len(mutasi) - gagal_uji}/{len(mutasi)} mutasi tertangkap)")
    return 1 if gagal_uji else 0


# ----------------------------------------------------------------------------- utama

def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--akar", default=str(Path(__file__).resolve().parent.parent),
                    help="akar pohon fondasi yang diperiksa (bawaan: repo tempat skrip ini)")
    ap.add_argument("--uji-diri", action="store_true", help="jalankan uji mutasi terhadap pemeriksa ini sendiri")
    arg = ap.parse_args()
    akar = Path(arg.akar).resolve()

    wajib = ["docs/ROADMAP.md", "docs/TECH_SPEC.md", "docs/PRD.md", "docs/TERTANGGUH.md", "docs/AGENT_OPERATING_GUIDE.md"]
    hilang = [w for w in wajib if not (akar / w).is_file()]
    print(f"PERIKSA FONDASI INDEPENDEN-2 — akar: {akar}")
    if hilang:
        print("GAGAL: dokumen fondasi tidak ditemukan → " + ", ".join(hilang))
        print("  (jalankan dari akar repo yang memuat fondasi, atau beri --akar /jalur/fondasi)")
        return 1
    if arg.uji_diri:
        return uji_diri(akar)

    h = Hasil()
    periksa(akar, h)
    for x in h.info:
        print(f"  · {x}")
    if h.peringatan:
        print(f"\nPERINGATAN ({len(h.peringatan)}) — tidak menggagalkan, tetapi wajib dibaca:")
        for x in h.peringatan:
            print(f"  ! {x}")
    if h.gagal:
        print(f"\nGAGAL ({len(h.gagal)}):")
        for x in h.gagal:
            print(f"  - {x}")
        print(f"\nHASIL: ADA {len(h.gagal)} TEMUAN GAGAL.")
        return 1
    print("\nHASIL: BERSIH — tidak ada temuan gagal dari pemeriksa independen-2.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
