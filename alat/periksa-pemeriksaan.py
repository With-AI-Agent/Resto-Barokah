#!/usr/bin/env python3
"""periksa-pemeriksaan.py — penjaga mesin Pemeriksaan Mendalam Bertahap (PMB).

Kenapa ada: rancangan PMB (docs/uji/pemeriksaan/RANCANGAN_PEMERIKSAAN_BERTAHAP.md §7) menaruh seluruh ingatan
pemeriksaan di berkas — papan potongan, buku besar temuan, kartu, asumsi, matriks telusur — supaya giliran
mana pun (chat baru sekalipun) bisa melanjutkan. Berkas yang ditulis banyak sesi akan rusak diam-diam kalau tidak
ada mesin yang menolak: potongan "SELESAI" tanpa kartu, temuan yang lompat status, temuan yang hilang, artefak
yang tidak ada, ID dobel. Mesin ini menolak semua itu.

Yang diperiksa (folder docs/uji/pemeriksaan/PMB-1/):
 1. PAPAN.md      — ID unik & berpola; status sah; DIKLAIM/SELESAI/DIHAKIMI punya sesi+tanggal; SELESAI punya kartu K;
                    DIHAKIMI punya kartu H dan tidak menyisakan temuan BARU; kartu tidak yatim; kartu lengkap bagiannya.
                    Ulangan independen potongan yang sama disimpan sebagai kartu/K-<ID>.<n>.md (n = 2, 3, …).
 2. BUKU_BESAR_TEMUAN.md — ID PMB1-F-nnn berurutan tanpa lompatan; DUPLIKAT (Hakim) wajib menunjuk temuan induk yang lebih dulu; tingkat K-1..K-4; potongan ada di papan; artefak ADA
                    (atau `(luar repo)`); bukti & baseline terisi; status sah; syarat per status (Hakim, commit, verifikasi,
                    rujukan T-0xx untuk DITANGGUHKAN); terhadap commit sebelumnya: tidak ada temuan yang hilang dan
                    transisi status mengikuti siklus.
 3. ASUMSI.md     — ID PMB1-A-nnn berurutan; status sah; DIBANTAH wajib menunjuk temuan yang ada.
 4. MATRIKS_TELUSUR.md & REGRESI_WAJIB.md — blok OTOMATIS mutakhir (lewat alat/susun-matriks-telusur.py --periksa).

Mode:
    python3 alat/periksa-pemeriksaan.py              # pemeriksaan penuh (dipakai CI)
    python3 alat/periksa-pemeriksaan.py --gerbang 1  # gerbang tahap: semua potongan tahap itu DIHAKIMI, 0 K-1/K-2 terbuka,
                                                     # (tahap 1) tidak ada janji yatim di matriks; menulis RINGKASAN_TAHAP-1.md
    python3 alat/periksa-pemeriksaan.py --uji-diri   # salin repo, rusak, pastikan MERAH (standar proyek: pemeriksa yang
                                                     # tidak bisa merah dianggap belum terpasang)
"""
from __future__ import annotations

import importlib.util
import io
import contextlib
import pathlib
import re
import subprocess
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from artefak import adakah_artefak  # noqa: E402
from bantu_uji_diri import AKAR, jalankan_pemeriksa, laporkan, salin_pohon  # noqa: E402

PUTARAN = "docs/uji/pemeriksaan/PMB-1"
STATUS_POTONGAN = {"RENCANA", "BELUM", "DIKLAIM", "SELESAI", "DIHAKIMI"}
STATUS_TEMUAN = {"BARU", "TERVERIFIKASI", "PALSU", "PERLU-INFO", "DIPERBAIKI", "DITUTUP", "DITANGGUHKAN", "DUPLIKAT"}
TERBUKA = {"BARU", "TERVERIFIKASI", "PERLU-INFO", "DIPERBAIKI"}
TRANSISI = {
    "BARU": {"TERVERIFIKASI", "PALSU", "PERLU-INFO", "DITANGGUHKAN", "DUPLIKAT"},
    "PERLU-INFO": {"TERVERIFIKASI", "PALSU", "DITANGGUHKAN", "DUPLIKAT"},
    "DUPLIKAT": set(),                     # kembar dari temuan lain (ulangan independen) — dinilai lewat temuan induknya
    "TERVERIFIKASI": {"DIPERBAIKI", "DITANGGUHKAN"},
    "DIPERBAIKI": {"DITUTUP", "TERVERIFIKASI"},
    "DITUTUP": {"TERVERIFIKASI"},          # kambuh → dibuka lagi oleh Hakim
    "DITANGGUHKAN": {"TERVERIFIKASI"},     # Lee mencabut penangguhan
    "PALSU": set(),
}
STATUS_ASUMSI = {"TERBUKA", "DIBUKTIKAN", "DIBANTAH"}
RE_ID_POTONGAN = re.compile(r"^(?:[FXMDGLZ]-\d{2}|P-\d{1,2}[A-Z]?-\d{2})$")
RE_ID_TEMUAN = re.compile(r"^PMB1-F-(\d{3})$")
RE_ID_ASUMSI = re.compile(r"^PMB1-A-(\d{3})$")
RE_SHA = re.compile(r"\b[0-9a-f]{7,40}\b")
BAGIAN_K = ["## 1. Cakupan", "## 2. Klaim yang dicoba dibantah", "## 3. Serangan", "## 4. Temuan", "## 5. Asumsi",
            "## 6. Tidak bisa diverifikasi", "## 7. Regresi temuan lama", "## 8. Angka usaha"]
BAGIAN_H = ["## 1. Temuan yang dihakimi", "## 4. Angka usaha"]
KEPALA_K = ["**Potongan:**", "**Sesi:**", "**Tanggal:**", "**Commit basis:**"]
KEPALA_H = ["**Potongan:**", "**Sesi hakim:**", "**Independensi:**"]


def _sel(baris: str) -> list[str]:
    return [s.strip() for s in baris.strip().strip("|").split("|")]


def _baris_tabel(teks: str, awalan_re: re.Pattern) -> list[tuple[int, list[str]]]:
    hasil = []
    for n, b in enumerate(teks.splitlines(), 1):
        if b.startswith("|"):
            sel = _sel(b)
            if sel and awalan_re.match(sel[0]):
                hasil.append((n, sel))
    return hasil


def baca_papan(akar: pathlib.Path, errs: list[str]) -> dict[str, dict]:
    p = akar / PUTARAN / "PAPAN.md"
    if not p.is_file():
        errs.append("PAPAN.md tidak ada"); return {}
    potongan: dict[str, dict] = {}
    for n, sel in _baris_tabel(p.read_text(encoding="utf-8"), RE_ID_POTONGAN):
        if len(sel) != 9:
            errs.append(f"PAPAN baris {n}: kolom harus 9, ada {len(sel)}"); continue
        pid, tahap, nama, lingkup, lensa, ukuran, status, sesi, tanggal = sel
        if pid in potongan:
            errs.append(f"PAPAN baris {n}: ID {pid} dobel"); continue
        if not tahap.isdigit():
            errs.append(f"PAPAN {pid}: tahap '{tahap}' bukan angka")
        if status not in STATUS_POTONGAN:
            errs.append(f"PAPAN {pid}: status '{status}' tidak sah (pilihan: {', '.join(sorted(STATUS_POTONGAN))})")
        if status in {"DIKLAIM", "SELESAI", "DIHAKIMI"} and (sesi in {"", "—"} or tanggal in {"", "—"}):
            errs.append(f"PAPAN {pid}: status {status} wajib punya Sesi dan Tanggal")
        if status in {"SELESAI", "DIHAKIMI"} and not (akar / PUTARAN / "kartu" / f"K-{pid}.md").is_file():
            errs.append(f"PAPAN {pid}: status {status} tetapi kartu kartu/K-{pid}.md tidak ada")
        if status == "DIHAKIMI" and not (akar / PUTARAN / "kartu" / f"H-{pid}.md").is_file():
            errs.append(f"PAPAN {pid}: status DIHAKIMI tetapi kartu kartu/H-{pid}.md tidak ada")
        potongan[pid] = {"tahap": int(tahap) if tahap.isdigit() else -1, "status": status, "baris": n}
    if not potongan:
        errs.append("PAPAN.md tidak memuat satu pun baris potongan")
    return potongan


def periksa_kartu(akar: pathlib.Path, potongan: dict[str, dict], errs: list[str]) -> None:
    folder = akar / PUTARAN / "kartu"
    if not folder.is_dir():
        errs.append("folder kartu/ tidak ada"); return
    for k in sorted(folder.glob("*.md")):
        if k.name.startswith("TEMPLAT_"):
            continue
        # Ulangan independen potongan yang sama (rancangan §9: potongan boleh diulang pemeriksa lain) → K-<ID>.2.md, K-<ID>.3.md …
        m = re.match(r"^([KH])-(.+?)(?:\.(\d+))?\.md$", k.name)
        if not m:
            errs.append(f"kartu/{k.name}: nama harus K-<ID>.md, H-<ID>.md, atau K-<ID>.<n>.md untuk ulangan"); continue
        jenis, pid, _ulangan = m.groups()
        if pid not in potongan:
            errs.append(f"kartu/{k.name}: potongan {pid} tidak ada di PAPAN (kartu yatim)"); continue
        isi = k.read_text(encoding="utf-8")
        for bagian in (BAGIAN_K if jenis == "K" else BAGIAN_H):
            if bagian not in isi:
                errs.append(f"kartu/{k.name}: bagian '{bagian}' hilang")
        for kepala in (KEPALA_K if jenis == "K" else KEPALA_H):
            if kepala not in isi:
                errs.append(f"kartu/{k.name}: kepala '{kepala}' hilang")
        if "<ID>" in isi or "<YYYY-MM-DD>" in isi:
            errs.append(f"kartu/{k.name}: masih berisi tempat kosong templat (<ID>/<YYYY-MM-DD>)")


def _artefak_ada(sel_artefak: str, akar: pathlib.Path) -> bool:
    if sel_artefak.startswith("(luar repo)"):
        return len(sel_artefak) > len("(luar repo)") + 2
    m = re.search(r"`([^`]+)`", sel_artefak)
    token = (m.group(1) if m else sel_artefak.split()[0] if sel_artefak.split() else "")
    token = re.split(r"[:\s§#]", token, 1)[0]
    return bool(token) and adakah_artefak(token, akar)


def baca_buku_besar(akar: pathlib.Path, potongan: dict[str, dict], errs: list[str]) -> dict[str, dict]:
    p = akar / PUTARAN / "BUKU_BESAR_TEMUAN.md"
    if not p.is_file():
        errs.append("BUKU_BESAR_TEMUAN.md tidak ada"); return {}
    temuan: dict[str, dict] = {}
    tertangguh = (akar / "docs/TERTANGGUH.md").read_text(encoding="utf-8") if (akar / "docs/TERTANGGUH.md").is_file() else ""
    urut = 0
    for n, sel in _baris_tabel(p.read_text(encoding="utf-8"), RE_ID_TEMUAN):
        if len(sel) != 11:
            errs.append(f"BUKU BESAR baris {n}: kolom harus 11, ada {len(sel)}"); continue
        fid, tingkat, pot, artefak, baseline, mutu, bukti, status, hakim, perbaikan, tutup = sel
        urut += 1
        nomor = int(RE_ID_TEMUAN.match(fid).group(1))
        if nomor != urut:
            errs.append(f"BUKU BESAR {fid}: nomor harus berurutan tanpa lompatan (diharapkan PMB1-F-{urut:03d})")
        if fid in temuan:
            errs.append(f"BUKU BESAR baris {n}: ID {fid} dobel"); continue
        if tingkat not in {"K-1", "K-2", "K-3", "K-4"}:
            errs.append(f"BUKU BESAR {fid}: tingkat '{tingkat}' tidak sah")
        if pot not in potongan:
            errs.append(f"BUKU BESAR {fid}: potongan '{pot}' tidak ada di PAPAN")
        if not _artefak_ada(artefak, akar):
            errs.append(f"BUKU BESAR {fid}: artefak '{artefak[:60]}' tidak ada di repo (atau tulis `(luar repo) <apa>`)")
        if baseline in {"", "—"}:
            errs.append(f"BUKU BESAR {fid}: kolom 'Baseline yang dilanggar' kosong")
        if len(bukti) < 20 or "→" not in bukti:
            errs.append(f"BUKU BESAR {fid}: bukti harus 'perintah → hasil' (panjang ≥ 20, memuat '→')")
        if status not in STATUS_TEMUAN:
            errs.append(f"BUKU BESAR {fid}: status '{status}' tidak sah")
        if status in {"TERVERIFIKASI", "PALSU", "PERLU-INFO", "DITUTUP", "DUPLIKAT"} and hakim in {"", "—"}:
            errs.append(f"BUKU BESAR {fid}: status {status} wajib mengisi kolom Hakim (sesi + kartu H)")
        if status in {"DIPERBAIKI", "DITUTUP"} and not RE_SHA.search(perbaikan):
            errs.append(f"BUKU BESAR {fid}: status {status} wajib menyebut sha commit perbaikan")
        if status == "DITUTUP" and tutup in {"", "—"}:
            errs.append(f"BUKU BESAR {fid}: status DITUTUP wajib mengisi 'Verifikasi tutup'")
        if status == "DUPLIKAT":
            induk = [r for r in re.findall(r"PMB1-F-\d{3}", " ".join((hakim, tutup))) if r != fid]
            if not induk or induk[0] not in temuan:
                errs.append(f"BUKU BESAR {fid}: DUPLIKAT wajib menyebut ID temuan induk yang sudah ada (lebih dulu) di kolom Hakim/Verifikasi tutup")
        if status == "DITANGGUHKAN":
            m = re.search(r"\bT-0\d\d\b", " ".join((hakim, perbaikan, tutup, bukti)))
            if not m or m.group(0) not in tertangguh:
                errs.append(f"BUKU BESAR {fid}: DITANGGUHKAN wajib merujuk butir T-0xx yang ada di docs/TERTANGGUH.md (hanya Lee)")
        temuan[fid] = {"tingkat": tingkat, "potongan": pot, "status": status, "baris": n}
    for pid, info in potongan.items():
        if info["status"] == "DIHAKIMI" and any(t["potongan"] == pid and t["status"] == "BARU" for t in temuan.values()):
            errs.append(f"PAPAN {pid}: DIHAKIMI tetapi masih ada temuan BARU dari potongan ini")
    return temuan


def periksa_transisi(akar: pathlib.Path, temuan: dict[str, dict], errs: list[str]) -> None:
    """Bandingkan dengan versi tercommit sebelumnya: temuan tidak boleh hilang, transisi harus sah."""
    rel = f"{PUTARAN}/BUKU_BESAR_TEMUAN.md"
    try:
        sama = subprocess.run(["git", "diff", "--quiet", "HEAD", "--", rel], cwd=akar, capture_output=True).returncode == 0
        acuan = "HEAD~1" if sama else "HEAD"
        lama = subprocess.run(["git", "show", f"{acuan}:{rel}"], cwd=akar, capture_output=True, text=True)
    except (OSError, ValueError):
        return
    if lama.returncode != 0:
        return  # berkas belum ada di acuan (baru dibuat) → tidak ada riwayat untuk dibandingkan
    for _, sel in _baris_tabel(lama.stdout, RE_ID_TEMUAN):
        if len(sel) != 11:
            continue
        fid, status_lama = sel[0], sel[7]
        if fid not in temuan:
            errs.append(f"BUKU BESAR: temuan {fid} HILANG dibanding {acuan} — temuan tidak boleh dihapus, hanya berubah status")
            continue
        baru = temuan[fid]["status"]
        if baru != status_lama and baru not in TRANSISI.get(status_lama, set()):
            errs.append(f"BUKU BESAR {fid}: transisi {status_lama} → {baru} di luar siklus (lihat kepala berkas)")


def baca_asumsi(akar: pathlib.Path, temuan: dict[str, dict], errs: list[str]) -> None:
    p = akar / PUTARAN / "ASUMSI.md"
    if not p.is_file():
        errs.append("ASUMSI.md tidak ada"); return
    urut = 0
    for n, sel in _baris_tabel(p.read_text(encoding="utf-8"), RE_ID_ASUMSI):
        if len(sel) != 7:
            errs.append(f"ASUMSI baris {n}: kolom harus 7, ada {len(sel)}"); continue
        aid, _kalimat, _sumber, status, bukti, _dampak, _pot = sel
        urut += 1
        if int(RE_ID_ASUMSI.match(aid).group(1)) != urut:
            errs.append(f"ASUMSI {aid}: nomor harus berurutan (diharapkan PMB1-A-{urut:03d})")
        if status not in STATUS_ASUMSI:
            errs.append(f"ASUMSI {aid}: status '{status}' tidak sah")
        if status == "DIBANTAH":
            rujuk = re.findall(r"PMB1-F-\d{3}", " | ".join(sel))
            if not rujuk or any(r not in temuan for r in rujuk):
                errs.append(f"ASUMSI {aid}: DIBANTAH wajib menunjuk temuan PMB1-F-nnn yang ada di Buku Besar")
        if status != "TERBUKA" and len(bukti) < 15:
            errs.append(f"ASUMSI {aid}: status {status} wajib punya bukti/riset")


def periksa_matriks_mutakhir(akar: pathlib.Path, errs: list[str]) -> None:
    spec = importlib.util.spec_from_file_location("susun_matriks", akar / "alat" / "susun-matriks-telusur.py")
    if spec is None or spec.loader is None:
        errs.append("alat/susun-matriks-telusur.py tidak ada"); return
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    with contextlib.redirect_stdout(io.StringIO()):
        kode = mod.susun(akar, True)
    if kode != 0:
        errs.append("blok OTOMATIS MATRIKS_TELUSUR/REGRESI_WAJIB basi → jalankan python3 alat/susun-matriks-telusur.py")


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    potongan = baca_papan(akar, errs)
    periksa_kartu(akar, potongan, errs)
    temuan = baca_buku_besar(akar, potongan, errs)
    periksa_transisi(akar, temuan, errs)
    baca_asumsi(akar, temuan, errs)
    periksa_matriks_mutakhir(akar, errs)
    ringkas = {s: sum(1 for p in potongan.values() if p["status"] == s) for s in sorted(STATUS_POTONGAN)}
    print(f"PERIKSA PEMERIKSAAN — {len(potongan)} potongan {ringkas} · {len(temuan)} temuan "
          f"(terbuka K-1/K-2: {sum(1 for t in temuan.values() if t['status'] in TERBUKA and t['tingkat'] in {'K-1', 'K-2'})})")
    for e in errs:
        print(f"  [GAGAL] {e}")
    print(f"\nHASIL: {'GAGAL — ' + str(len(errs)) + ' masalah' if errs else 'LOLOS'}")
    return 1 if errs else 0


def _janji_di_bagian_b(teks_matriks: str) -> set[str]:
    b = teks_matriks.split("## B.", 1)[1].split("## C.", 1)[0] if "## B." in teks_matriks else ""
    ada: set[str] = set(re.findall(r"PRD M\d{1,2}|ART-\d{1,2}|TECH_SPEC §\d{1,2}b?|KEAMANAN §\d{1,2}b?", b))
    for awalan, a, z in re.findall(r"(ART-|TECH_SPEC §|KEAMANAN §)(\d{1,2}) … (?:ART-|§)(\d{1,2})", b):
        ada.update(f"{awalan}{i}" for i in range(int(a), int(z) + 1))
    return ada


def gerbang(akar: pathlib.Path, tahap: int) -> int:
    errs: list[str] = []
    if periksa(akar) != 0:
        print("\nGERBANG: GAGAL — pemeriksaan dasar belum LOLOS"); return 1
    potongan = baca_papan(akar, errs)
    temuan = baca_buku_besar(akar, potongan, errs)
    milik = {pid for pid, p in potongan.items() if p["tahap"] == tahap}
    belum = sorted(pid for pid in milik if potongan[pid]["status"] != "DIHAKIMI")
    if not milik:
        errs.append(f"tidak ada potongan bertahap {tahap} di PAPAN")
    if belum:
        errs.append(f"potongan tahap {tahap} belum DIHAKIMI: {', '.join(belum)}")
    terbuka = sorted(f for f, t in temuan.items() if t["potongan"] in milik and t["status"] in TERBUKA and t["tingkat"] in {"K-1", "K-2"})
    if terbuka:
        errs.append(f"temuan K-1/K-2 masih terbuka: {', '.join(terbuka)}")
    if tahap == 1:
        m = (akar / PUTARAN / "MATRIKS_TELUSUR.md").read_text(encoding="utf-8")
        semua = set(re.findall(r"^\| ((?:PRD M|ART-|TECH_SPEC §|KEAMANAN §)\d{1,2}b?) \|", m, re.M))
        yatim = sorted(semua - _janji_di_bagian_b(m))
        if yatim:
            errs.append(f"janji yatim (tanpa potongan pemeriksa di bagian B matriks): {', '.join(yatim)}")
    per_status = {s: sum(1 for t in temuan.values() if t["potongan"] in milik and t["status"] == s) for s in sorted(STATUS_TEMUAN)}
    per_k = {k: sum(1 for t in temuan.values() if t["potongan"] in milik and t["tingkat"] == k) for k in ("K-1", "K-2", "K-3", "K-4")}
    putusan = "LOLOS" if not errs else "GAGAL"
    isi = [f"# RINGKASAN TAHAP {tahap} — PMB-1 (dibuat mesin: `python3 alat/periksa-pemeriksaan.py --gerbang {tahap}`)", "",
           f"- **Putusan gerbang:** {putusan}", f"- Potongan tahap ini: {len(milik)} · belum DIHAKIMI: {len(belum)}",
           f"- Temuan per status: {per_status}", f"- Temuan per tingkat: {per_k}",
           f"- Temuan palsu ÷ total: {per_status.get('PALSU', 0)}/{sum(per_status.values()) or 1}",
           "- Kalibrasi (diisi Perencana setelah membuka kunci): ditemukan … dari … · temuan palsu … · per kelas …", ""]
    if errs:
        isi += ["## Penghalang", ""] + [f"- {e}" for e in errs] + [""]
    (akar / PUTARAN / f"RINGKASAN_TAHAP-{tahap}.md").write_text("\n".join(isi), encoding="utf-8")
    for e in errs:
        print(f"  [GERBANG] {e}")
    print(f"\nGERBANG TAHAP {tahap}: {putusan} — ringkasan ditulis ke {PUTARAN}/RINGKASAN_TAHAP-{tahap}.md")
    return 1 if errs else 0


def uji_diri() -> int:
    hasil: list[tuple[str, bool, str]] = []
    bb = pathlib.Path(PUTARAN) / "BUKU_BESAR_TEMUAN.md"
    papan = pathlib.Path(PUTARAN) / "PAPAN.md"

    def coba(nama: str, rusak, harus_merah: bool = True) -> None:
        with salin_pohon() as tmp:
            rusak(tmp)
            kode, keluaran = jalankan_pemeriksa(periksa, tmp)
            ok = (kode != 0) if harus_merah else (kode == 0)
            hasil.append((nama, ok, f"kode={kode}" + ("" if ok else "\n" + keluaran[-600:])))

    coba("salinan utuh diterima", lambda t: None, harus_merah=False)
    coba("potongan SELESAI tanpa kartu ditolak",
         lambda t: (t / papan).write_text((t / papan).read_text(encoding="utf-8").replace(
             "| F-02 | 1 |", "| F-02 | 1 |", 1).replace("| BELUM | — | — |\n| F-03", "| SELESAI | arena/x | 2026-09-28 |\n| F-03", 1), encoding="utf-8"))
    coba("status temuan tidak sah ditolak",
         lambda t: (t / bb).write_text((t / bb).read_text(encoding="utf-8").replace("| BARU | — | — | — |", "| SELESAI | — | — | — |", 1), encoding="utf-8"))
    coba("DITUTUP tanpa hakim/commit ditolak",
         lambda t: (t / bb).write_text((t / bb).read_text(encoding="utf-8").replace("| BARU | — | — | — |", "| DITUTUP | — | — | — |", 1), encoding="utf-8"))
    coba("artefak yang tidak ada ditolak",
         lambda t: (t / bb).write_text((t / bb).read_text(encoding="utf-8").replace(
             "`supabase/migrations/0086_data_awal_dan_autentikasi_perangkat.sql:286`", "`supabase/migrations/9999_tidak_ada.sql:1`", 1), encoding="utf-8"))
    coba("ID temuan melompat ditolak",
         lambda t: (t / bb).write_text((t / bb).read_text(encoding="utf-8").replace("| PMB1-F-001 |", "| PMB1-F-002 |", 1), encoding="utf-8"))
    coba("potongan temuan yang tidak ada di papan ditolak",
         lambda t: (t / bb).write_text((t / bb).read_text(encoding="utf-8").replace("| K-1 | F-10 |", "| K-1 | F-99 |", 1), encoding="utf-8"))
    coba("kartu yatim / tidak lengkap ditolak",
         lambda t: (t / PUTARAN / "kartu" / "K-F-01.md").write_text("# kartu kosong\n", encoding="utf-8"))
    coba("matriks basi ditolak",
         lambda t: (t / "docs/ROADMAP.md").write_text((t / "docs/ROADMAP.md").read_text(encoding="utf-8").replace("- [ ] T11-02 —", "- [x] T11-02 —", 1), encoding="utf-8"))
    coba("DUPLIKAT tanpa temuan induk ditolak",
         lambda t: (t / bb).write_text((t / bb).read_text(encoding="utf-8").replace("| BARU | — | — | — |", "| DUPLIKAT | arena/x H-F-01 | — | — |", 1), encoding="utf-8"))
    coba("asumsi DIBANTAH tanpa temuan ditolak",
         lambda t: (t / PUTARAN / "ASUMSI.md").write_text((t / PUTARAN / "ASUMSI.md").read_text(encoding="utf-8").replace("PMB1-F-001, 2026-09-28", "temuan menyusul", 1), encoding="utf-8"))
    return laporkan("periksa-pemeriksaan", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    if "--gerbang" in sys.argv:
        i = sys.argv.index("--gerbang")
        sys.exit(gerbang(AKAR, int(sys.argv[i + 1]) if i + 1 < len(sys.argv) else 1))
    sys.exit(periksa(AKAR))
