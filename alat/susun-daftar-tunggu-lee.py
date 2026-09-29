#!/usr/bin/env python3
"""susun-daftar-tunggu-lee.py — kunci K2 "Jaminan Tuntas": SATU berkas berisi semua yang menunggu Lee.

Kenapa ada (keputusan Lee 2026-09-29, docs/uji/pemeriksaan/USULAN_JAMINAN_TUNTAS.md, REKAM §31 butir 20–21):
Lee khawatir di antara ratusan temuan ada yang terlupakan. Ingatan agent tidak boleh dipercaya untuk itu — mesin
yang menghitung. Alat ini membaca Buku Besar PMB-1, ROADMAP, TERTANGGUH.md, dan Buku Uji Pemilik, lalu menulis
`docs/uji/pemeriksaan/PMB-1/DAFTAR_TUNGGU_LEE.md` (deterministik: tanpa jam/sha, supaya bisa diperiksa CI).

    python3 alat/susun-daftar-tunggu-lee.py            # tulis ulang berkas
    python3 alat/susun-daftar-tunggu-lee.py --periksa  # CI: GAGAL bila berkas basi (harus dijalankan ulang)
    python3 alat/susun-daftar-tunggu-lee.py --uji-diri

Isi daftar (semua dihasilkan mesin, jangan diedit tangan):
  A. Temuan TERBUKA yang kolom Perbaikan-nya memuat penanda LEE: A1 `MENUNGGU KEPUTUSAN LEE:` / `BUTUH LEE` (masih
     menunggu Lee) · A2 `KEPUTUSAN LEE <tanggal> (…):` (sudah Lee putuskan, menunggu dieksekusi agent).
  B. Semua temuan K-1 yang masih terbuka (status BARU/TERVERIFIKASI/PERLU-INFO/DIPERBAIKI).
  C. Tugas ROADMAP bertanda `Dibuka kembali: PMB1-F-nnn` yang masih `[ ]` (fitur yang dulu diklaim selesai).
  D. Centang lama `⏳ BUKTI-BELUM` yang menunggu sensus klaim Tahap 2 (angka per fase + daftar ID).
  E. Butir tertangguh terbuka di docs/TERTANGGUH.md (hanya Lee yang boleh menutup).
  F. Baris Buku Uji Pemilik `U-nn` yang kolom Hasil-nya belum Lee isi.
Dipanggil otomatis oleh alat/pmb-integrasi.py sesudah setiap integrasi; kesegarannya dijaga alat/periksa-pemeriksaan.py
dan langkah CI `--periksa`.
"""
from __future__ import annotations

import importlib.util
import pathlib
import re
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
sys.path.insert(0, str(AKAR / "alat"))
PMB = "docs/uji/pemeriksaan/PMB-1"
LEDGER = f"{PMB}/BUKU_BESAR_TEMUAN.md"
KELUARAN = f"{PMB}/DAFTAR_TUNGGU_LEE.md"
ROADMAP = "docs/ROADMAP.md"
TERTANGGUH = "docs/TERTANGGUH.md"
BUKU_UJI = "docs/uji/BUKU_UJI_PEMILIK.md"
TERBUKA = ("BARU", "TERVERIFIKASI", "PERLU-INFO", "DIPERBAIKI")
RE_PENANDA_LEE = re.compile(r"(MENUNGGU KEPUTUSAN LEE|BUTUH LEE(?:/OPERATOR)?|KEPUTUSAN LEE[^:]*)\s*:?\s*(.*)", re.S)


def _modul(nama_berkas: str, nama: str):
    spec = importlib.util.spec_from_file_location(nama, AKAR / "alat" / nama_berkas)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"{nama_berkas} tidak bisa dimuat")
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)  # type: ignore[union-attr]
    return m


def _sel(baris: str) -> list[str]:
    return [s.strip() for s in baris.strip().strip("|").split("|")]


def _pendek(teks: str, n: int = 170) -> str:
    teks = re.sub(r"\s+", " ", teks).strip()
    return teks if len(teks) <= n else teks[: n - 1].rstrip() + "…"


def baca_temuan(akar: pathlib.Path) -> list[dict]:
    p = akar / LEDGER
    if not p.is_file():
        return []
    hasil = []
    for b in p.read_text(encoding="utf-8", errors="surrogateescape").splitlines():
        if not b.startswith("| PMB1-F-"):
            continue
        sel = _sel(b)
        if len(sel) < 11:
            continue
        hasil.append({"id": sel[0], "tingkat": sel[1], "potongan": sel[2], "artefak": sel[3], "status": sel[7],
                      "perbaikan": sel[9], "tutup": sel[10]})
    return hasil


def bagian_a(temuan: list[dict]) -> list[str]:
    tunggu, putus = [], []
    for t in temuan:
        if t["status"] not in TERBUKA:
            continue
        m = RE_PENANDA_LEE.search(t["perbaikan"])
        if not m:
            continue
        baris = f"| {t['id']} | {t['tingkat']} | {t['potongan']} | {t['status']} | **{m.group(1).strip()}:** {_pendek(m.group(2))} |"
        (putus if m.group(1).startswith("KEPUTUSAN LEE") else tunggu).append(baris)
    kepala = "| ID | Tingkat | Potongan | Status | Apa yang diminta dari Lee |"
    a = ["## A. Keputusan / tindakan yang ditunggu dari Lee (temuan terbuka berpenanda LEE)", "",
         "### A1. Masih MENUNGGU keputusan/tindakan Lee", "", kepala, "|---|---|---|---|---|"] + (tunggu or ["| — | — | — | — | (tidak ada) |"])
    a += ["", f"Jumlah A1: **{len(tunggu)}**", "",
          "### A2. Sudah DIPUTUSKAN Lee — menunggu dieksekusi agent (penanda `KEPUTUSAN LEE <tanggal>:`)", "",
          kepala.replace("Apa yang diminta dari Lee", "Keputusan Lee & yang harus dikerjakan"), "|---|---|---|---|---|"] + (putus or ["| — | — | — | — | (tidak ada) |"])
    return a + ["", f"Jumlah A2: **{len(putus)}**", ""]


def bagian_b(temuan: list[dict]) -> list[str]:
    baris = ["## B. Temuan K-1 (berat) yang masih terbuka — wajib 0 sebelum data asli/pilot", "",
             "| ID | Potongan | Status | Artefak |", "|---|---|---|---|"]
    k1 = [t for t in temuan if t["tingkat"] == "K-1" and t["status"] in TERBUKA]
    for t in k1:
        baris.append(f"| {t['id']} | {t['potongan']} | {t['status']} | {_pendek(t['artefak'], 90)} |")
    if not k1:
        baris.append("| — | — | — | (tidak ada) |")
    return baris + ["", f"Jumlah: **{len(k1)}**", ""]


def bagian_c_d(akar: pathlib.Path) -> tuple[list[str], list[str], int, int]:
    pr = _modul("periksa-roadmap.py", "periksa_roadmap")
    teks = (akar / ROADMAP).read_text(encoding="utf-8") if (akar / ROADMAP).is_file() else ""
    c = ["## C. Tugas ROADMAP yang DIBUKA KEMBALI (dulu diklaim selesai, ternyata belum) dan masih `[ ]`", "",
         "| Tugas | Judul | Temuan pembuka | Bukti yang wajib ada sebelum boleh dicentang lagi |", "|---|---|---|---|"]
    per_fase: dict[str, list[str]] = {}
    n_c = 0
    for tid, isi in pr.blok_tugas(teks, semua_status=True):
        kepala, _, badan = isi.partition("\n")
        centang = kepala.startswith("[x]")
        judul = kepala[4:].strip()
        m = pr.RE_DIBUKA_KEMBALI.search(badan)
        if m and not centang:
            n_c += 1
            baris_dk = next((l for l in badan.splitlines() if "**Dibuka kembali:**" in l), "")
            wajib = baris_dk.split("bukti wajib:", 1)[1].strip() if "bukti wajib:" in baris_dk else "(belum ditulis — cacat, lengkapi)"
            c.append(f"| {tid} | {_pendek(judul, 70)} | {m.group(1)} | {_pendek(wajib, 110)} |")
        if centang and any(pr.PENANDA_TRANSISI in l for l in badan.splitlines() if pr.RE_BARIS_BUKTI.match(l)):
            per_fase.setdefault(tid.split("-")[0], []).append(tid)
    if n_c == 0:
        c.append("| — | — | — | (tidak ada) |")
    c += ["", f"Jumlah: **{n_c}**", ""]
    total_d = sum(len(v) for v in per_fase.values())
    d = ["## D. Centang lama `⏳ BUKTI-BELUM` yang menunggu sensus klaim Tahap 2 PMB (belum berbukti menurut aturan K3)", "",
         "| Fase | Jumlah | ID tugas |", "|---|---|---|"]
    for fase in sorted(per_fase, key=lambda f: (len(f), f)):
        d.append(f"| {fase} | {len(per_fase[fase])} | {', '.join(per_fase[fase])} |")
    if total_d == 0:
        d.append("| — | 0 | (tidak ada — semua centang sudah berbukti) |")
    d += ["", f"Jumlah: **{total_d}** (daftar beku: `{PMB}/BUKTI_BELUM_BASELINE.txt`, hanya boleh menyusut)", ""]
    return c, d, n_c, total_d


def bagian_e(akar: pathlib.Path) -> tuple[list[str], int]:
    teks = (akar / TERTANGGUH).read_text(encoding="utf-8") if (akar / TERTANGGUH).is_file() else ""
    e = ["## E. Butir tertangguh yang masih terbuka (`docs/TERTANGGUH.md`) — hanya Lee yang boleh menutup", "",
         "| ID | Tanggal | Hal |", "|---|---|---|"]
    n = 0
    for b in teks.splitlines():
        if not re.match(r"^\|\s*T-\d{3}\s*\|", b) or "[ ] terbuka" not in b:
            continue
        sel = _sel(b)
        if sel[0] == "T-000":
            continue
        n += 1
        e.append(f"| {sel[0]} | {sel[1] if len(sel) > 1 else ''} | {_pendek(sel[2] if len(sel) > 2 else '', 110)} |")
    if n == 0:
        e.append("| — | — | (tidak ada) |")
    return e + ["", f"Jumlah: **{n}**", ""], n


def bagian_f(akar: pathlib.Path) -> tuple[list[str], int]:
    teks = (akar / BUKU_UJI).read_text(encoding="utf-8") if (akar / BUKU_UJI).is_file() else ""
    kosong = []
    for b in teks.splitlines():
        if not b.startswith("| U-"):
            continue
        sel = _sel(b)
        if len(sel) >= 5 and re.match(r"^U-\d{2,3}$", sel[0]) and not sel[4]:
            kosong.append(sel[0])
    f = ["## F. Baris Buku Uji Pemilik yang belum Lee isi hasilnya (`docs/uji/BUKU_UJI_PEMILIK.md`)", "",
         f"Belum diisi: **{len(kosong)}** → {', '.join(kosong) if kosong else '(semua sudah diisi)'}", "",
         "Cara mengisi: bilang di chat `Buku uji baris U-nn: OK` (atau `GAGAL — apa yang terjadi`); agent mencatatnya. "
         "Baris `U-nn` yang Lee isi `OK` menjadi bukti sah untuk centang `[x]` ROADMAP (aturan K3).", ""]
    return f, len(kosong)


def susun_teks(akar: pathlib.Path) -> str:
    temuan = baca_temuan(akar)
    a = bagian_a(temuan)
    b = bagian_b(temuan)
    c, d, n_c, n_d = bagian_c_d(akar)
    e, n_e = bagian_e(akar)
    f, n_f = bagian_f(akar)
    n_a1 = int(re.search(r"Jumlah A1: \*\*(\d+)\*\*", "\n".join(a)).group(1))
    n_a2 = int(re.search(r"Jumlah A2: \*\*(\d+)\*\*", "\n".join(a)).group(1))
    n_b = sum(1 for l in b if l.startswith("| PMB1-F-"))
    terbuka = {s: sum(1 for t in temuan if t["status"] == s) for s in TERBUKA}
    kepala = [
        "# DAFTAR TUNGGU LEE — semua yang menunggu keputusan/tindakan Lee (DIBUAT MESIN, jangan diedit tangan)",
        "",
        "> Dibuat oleh `python3 alat/susun-daftar-tunggu-lee.py` dari Buku Besar PMB-1, `docs/ROADMAP.md`, `docs/TERTANGGUH.md`, dan Buku Uji Pemilik.",
        "> Diperbarui otomatis pada setiap integrasi (`alat/pmb-integrasi.py`); CI GAGAL bila berkas ini basi (`--periksa`).",
        "> Kunci K2 \"Jaminan Tuntas\" (keputusan Lee 2026-09-29): Lee cukup membaca SATU berkas ini — tidak ada yang perlu diingat.",
        "",
        "## Ringkasan angka",
        "",
        "| Bagian | Isi | Jumlah |", "|---|---|---|",
        f"| A1 | Masih menunggu keputusan/tindakan Lee | {n_a1} |",
        f"| A2 | Sudah diputuskan Lee, menunggu dieksekusi agent | {n_a2} |",
        f"| B | Temuan K-1 terbuka | {n_b} |",
        f"| C | Tugas ROADMAP dibuka kembali, masih `[ ]` | {n_c} |",
        f"| D | Centang lama menunggu sensus klaim (⏳ BUKTI-BELUM) | {n_d} |",
        f"| E | Butir tertangguh terbuka | {n_e} |",
        f"| F | Baris Buku Uji belum diisi Lee | {n_f} |",
        "",
        "Temuan terbuka semua tingkat: " + " · ".join(f"{s} {n}" for s, n in terbuka.items()) +
        f" · **total {sum(terbuka.values())}** (gerbang akhir PMB menuntut 0, kecuali DITANGGUHKAN oleh Lee dengan tanggal tinjau).",
        "",
    ]
    return "\n".join(kepala + a + b + c + d + e + f).rstrip() + "\n"


def susun(akar: pathlib.Path, periksa_saja: bool) -> int:
    baru = susun_teks(akar)
    p = akar / KELUARAN
    lama = p.read_text(encoding="utf-8") if p.is_file() else None
    if lama == baru:
        print(f"[OK] {KELUARAN} mutakhir")
        print("\nHASIL: LOLOS" if periksa_saja else "\nSELESAI (tidak ada perubahan)")
        return 0
    if periksa_saja:
        print(f"[GAGAL] {KELUARAN} basi → jalankan `python3 alat/susun-daftar-tunggu-lee.py` lalu commit")
        print("\nHASIL: GAGAL")
        return 1
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(baru, encoding="utf-8")
    print(f"ditulis ulang: {KELUARAN}")
    print("\nSELESAI")
    return 0


def uji_diri() -> int:
    import shutil
    import tempfile
    from bantu_uji_diri import laporkan
    hasil: list[tuple[str, bool, str]] = []
    with tempfile.TemporaryDirectory() as tmp:
        t = pathlib.Path(tmp)
        for rel in (LEDGER, ROADMAP, TERTANGGUH, BUKU_UJI, f"{PMB}/BUKTI_BELUM_BASELINE.txt"):
            (t / rel).parent.mkdir(parents=True, exist_ok=True)
            shutil.copy(AKAR / rel, t / rel)
        # salinan alat yang dibutuhkan modul periksa-roadmap (jalur relatif ke ROOT-nya sendiri, bukan tmp) — cukup teks
        teks = susun_teks(t)
        hasil.append(("berkas dibuat dengan 6 bagian", all(f"## {h}." in teks for h in "ABCDEF"), "bagian lengkap"))
        hasil.append(("deterministik (dua kali susun sama)", teks == susun_teks(t), ""))
        # mutasi 1: tambah penanda MENUNGGU KEPUTUSAN LEE pada temuan terbuka → muncul di A
        led = (t / LEDGER).read_text(encoding="utf-8", errors="surrogateescape")
        baris = next(b for b in led.splitlines() if b.startswith("| PMB1-F-") and "| TERVERIFIKASI |" in b)
        sel = _sel(baris)
        sel[9] = "MENUNGGU KEPUTUSAN LEE: uji-diri penanda X9Z"
        (t / LEDGER).write_text(led.replace(baris, "| " + " | ".join(sel) + " |"), encoding="utf-8", errors="surrogateescape")
        teks2 = susun_teks(t)
        hasil.append(("penanda LEE pada temuan terbuka masuk bagian A", "uji-diri penanda X9Z" in teks2, ""))
        # mutasi 2: temuan yang sama DITUTUP → hilang dari A (hanya yang terbuka)
        sel[7] = "DITUTUP"
        (t / LEDGER).write_text(led.replace(baris, "| " + " | ".join(sel) + " |"), encoding="utf-8", errors="surrogateescape")
        hasil.append(("penanda LEE pada temuan DITUTUP tidak dihitung", "uji-diri penanda X9Z" not in susun_teks(t), ""))
        (t / LEDGER).write_text(led, encoding="utf-8", errors="surrogateescape")
        # mutasi 3: tugas Dibuka kembali [ ] di ROADMAP → muncul di C
        rm = (t / ROADMAP).read_text(encoding="utf-8")
        rm2 = rm + ("\n- [ ] T99-77 — tugas uji-diri dibuka kembali\n  - **Dibuka kembali:** PMB1-F-999 (2026-09-30) — bukti wajib: `supabase/tes/x.sql`\n"
                    "  - **Tujuan:** a\n  - **Ref:** a\n  - **File:** a\n  - **DoD:** a\n  - **Kompleksitas:** a\n  - **Risiko & mitigasi:** a\n  - **Verifikasi:** a\n")
        (t / ROADMAP).write_text(rm2, encoding="utf-8")
        teks3 = susun_teks(t)
        hasil.append(("tugas Dibuka kembali yang masih [ ] masuk bagian C", "| T99-77 |" in teks3 and "PMB1-F-999" in teks3, ""))
        # mutasi 4: tugas yang sama dicentang → keluar dari C
        (t / ROADMAP).write_text(rm2.replace("- [ ] T99-77", "- [x] T99-77"), encoding="utf-8")
        hasil.append(("tugas Dibuka kembali yang sudah [x] tidak masuk C", "| T99-77 |" not in susun_teks(t), ""))
        (t / ROADMAP).write_text(rm, encoding="utf-8")
        # mutasi 5: Lee mengisi satu baris Buku Uji OK → bagian F berkurang
        bu = (t / BUKU_UJI).read_text(encoding="utf-8")
        baris_u = next(b for b in bu.splitlines() if b.startswith("| U-"))
        sel_u = _sel(baris_u)
        sebelum = susun_teks(t)
        sel_u[4] = "OK"
        (t / BUKU_UJI).write_text(bu.replace(baris_u, "| " + " | ".join(sel_u) + " |"), encoding="utf-8")
        sesudah = susun_teks(t)
        n_seb = int(re.search(r"Belum diisi: \*\*(\d+)\*\*", sebelum).group(1))
        n_ses = int(re.search(r"Belum diisi: \*\*(\d+)\*\*", sesudah).group(1))
        hasil.append(("baris Buku Uji yang Lee isi OK keluar dari bagian F", n_ses == n_seb - 1, f"{n_seb}→{n_ses}"))
        # periksa: berkas basi harus GAGAL, mutakhir harus LOLOS
        (t / KELUARAN).write_text("basi\n", encoding="utf-8")
        import contextlib
        import io
        with contextlib.redirect_stdout(io.StringIO()):
            kode_basi = susun(t, True)
            susun(t, False)
            kode_segar = susun(t, True)
        hasil.append(("--periksa menolak berkas basi", kode_basi == 1, str(kode_basi)))
        hasil.append(("--periksa menerima berkas mutakhir", kode_segar == 0, str(kode_segar)))
    return laporkan("susun-daftar-tunggu-lee", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(susun(AKAR, "--periksa" in sys.argv))
