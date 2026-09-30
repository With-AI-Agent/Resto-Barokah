#!/usr/bin/env python3
"""periksa-pemeriksaan.py — penjaga mesin Pemeriksaan Mendalam Bertahap (PMB).

Kenapa ada: rancangan PMB (docs/uji/pemeriksaan/RANCANGAN_PEMERIKSAAN_BERTAHAP.md §7) menaruh seluruh ingatan
pemeriksaan di berkas — papan potongan, buku besar temuan, kartu, asumsi, matriks telusur — supaya giliran
mana pun (chat baru sekalipun) bisa melanjutkan. Berkas yang ditulis banyak sesi akan rusak diam-diam kalau tidak
ada mesin yang menolak: potongan "SELESAI" tanpa kartu, temuan yang lompat status, temuan yang hilang, artefak
yang tidak ada, ID dobel. Mesin ini menolak semua itu.

Yang diperiksa (folder docs/uji/pemeriksaan/PMB-1/):
 1. PAPAN.md      — ID unik & berpola; status sah; DIKLAIM/SELESAI/DIHAKIMI punya sesi+tanggal; SELESAI punya kartu K;
                    DIHAKIMI punya kartu H dan tidak menyisakan temuan BARU; kartu tidak yatim; kartu lengkap bagiannya
                    (K = pemeriksa, H = hakim, B = pembangun — bagian wajib BAGIAN_K/H/B).
                    Ulangan independen potongan yang sama disimpan sebagai kartu/K-<ID>.<n>.md (n = 2, 3, …).
 2. BUKU_BESAR_TEMUAN.md — ID PMB1-F-nnn berurutan tanpa lompatan; nomor baris artefak tidak melebihi panjang berkas; status berputusan menyebut kartu H yang ada; DUPLIKAT (Hakim) wajib menunjuk temuan induk yang lebih dulu; tingkat K-1..K-4; potongan ada di papan; artefak ADA
                    (atau `(luar repo)`); bukti & baseline terisi; status sah; syarat per status (Hakim, commit, verifikasi,
                    rujukan T-0xx untuk DITANGGUHKAN); terhadap commit sebelumnya: tidak ada temuan yang hilang dan
                    transisi status mengikuti siklus.
 3. ASUMSI.md     — ID PMB1-A-nnn berurutan; status sah; DIBANTAH wajib menunjuk temuan yang ada.
 4. MATRIKS_TELUSUR.md & REGRESI_WAJIB.md — blok OTOMATIS mutakhir (lewat alat/susun-matriks-telusur.py --periksa).

Mode:
    python3 alat/periksa-pemeriksaan.py              # pemeriksaan penuh (dipakai CI)
    python3 alat/periksa-pemeriksaan.py --gerbang 1  # gerbang tahap: semua potongan tahap itu DIHAKIMI, 0 K-1/K-2 terbuka,
                                                     # (tahap 1) tidak ada janji yatim di matriks; menulis RINGKASAN_TAHAP-1.md
                                                     # (tahap 2) K5 sensus klaim: 0 centang ⏳ BUKTI-BELUM tersisa pada fase yang
                                                     # potongannya ada di tahap 2 + setiap [x] fase itu tercatat di bagian
                                                     # "Sensus klaim" kartu K potongan tersebut
    python3 alat/periksa-pemeriksaan.py --gerbang akhir  # K1 gerbang akhir sebelum pilot: semua potongan DIHAKIMI, 0 temuan
                                                     # terbuka SEMUA tingkat, DITANGGUHKAN hanya oleh Lee (+ tanggal tinjau),
                                                     # 0 tugas ROADMAP 'Dibuka kembali' yang masih [ ], 0 ⏳ BUKTI-BELUM

Kunci "Jaminan Tuntas" (keputusan Lee 2026-09-29, docs/uji/pemeriksaan/USULAN_JAMINAN_TUNTAS.md) yang dijaga di sini:
  K1 gerbang akhir (--gerbang akhir) · K2 DAFTAR_TUNGGU_LEE.md wajib mutakhir (alat/susun-daftar-tunggu-lee.py) ·
  K4 baris DIPERBAIKI/DITUTUP wajib menyebut berkas uji/penjaga yang ADA di repo (bukti mesin; `tanpa uji mesin: <alasan>`
  hanya untuk perbaikan dokumen yang commit-nya tidak menyentuh kode) · K5 sensus klaim pada --gerbang 2.
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
RE_KARTU_H = re.compile(r"\bH-[A-Z]-[0-9A-Z]{1,3}(?:-\d{2})?(?:\.\d+)?\b")  # H-F-07, H-F-07.2, H-P-10-00, H-P-1B-00
TERBUKA = {"BARU", "TERVERIFIKASI", "PERLU-INFO", "DIPERBAIKI"}
TRANSISI = {
    "BARU": {"TERVERIFIKASI", "PALSU", "PERLU-INFO", "DITANGGUHKAN", "DUPLIKAT"},
    "PERLU-INFO": {"TERVERIFIKASI", "PALSU", "DITANGGUHKAN", "DUPLIKAT"},
    "DUPLIKAT": set(),                     # kembar dari temuan lain (ulangan independen) — dinilai lewat temuan induknya
    "TERVERIFIKASI": {"DIPERBAIKI", "DITANGGUHKAN", "PERLU-INFO"},   # → PERLU-INFO hanya untuk sengketa hakim / bukti baru (alasan tertulis)
    "DIPERBAIKI": {"DITUTUP", "TERVERIFIKASI"},
    "DITUTUP": {"TERVERIFIKASI"},          # kambuh → dibuka lagi oleh Hakim
    "DITANGGUHKAN": {"TERVERIFIKASI"},     # Lee mencabut penangguhan
    "PALSU": {"PERLU-INFO"},                # dibuka kembali hanya karena sengketa hakim / bukti baru (alasan tertulis)
}
STATUS_ASUMSI = {"TERBUKA", "DIBUKTIKAN", "DIBANTAH"}
RE_ID_POTONGAN = re.compile(r"^(?:[FXMDGLZ]-\d{2}|P-\d{1,2}[A-Z]?-\d{2})$")
RE_ID_TEMUAN = re.compile(r"^PMB1-F-(\d{3})$")
RE_ID_ASUMSI = re.compile(r"^PMB1-A-(\d{3})$")
RE_SHA = re.compile(r"\b[0-9a-f]{7,40}\b")
# K4: baris yang sudah DITUTUP/DIPERBAIKI SEBELUM aturan bukti mesin berlaku (2026-09-29) — perbaikan naskah/kalibrasi Tahap 0–1
# yang memang tidak punya berkas uji. Daftar ini BEKU: ID baru tidak boleh ditambahkan (aturan berlaku penuh sesudahnya).
K4_SEBELUM_ATURAN = frozenset({"PMB1-F-092", "PMB1-F-192", "PMB1-F-193", "PMB1-F-194", "PMB1-F-195", "PMB1-F-197",
                               "PMB1-F-198", "PMB1-F-199", "PMB1-F-200", "PMB1-F-201", "PMB1-F-202"})
FRASA_TANPA_UJI = "tanpa uji mesin:"
AWALAN_KODE = ("aplikasi/src/", "supabase/", "alat/", "aplikasi/alat/", "_sistem/", ".github/workflows/")
_MODUL_ROADMAP = None


def _modul_roadmap(akar: pathlib.Path):
    """Muat alat/periksa-roadmap.py sekali (pembaca blok tugas, pola bukti mesin K3)."""
    global _MODUL_ROADMAP
    if _MODUL_ROADMAP is None:
        spec = importlib.util.spec_from_file_location("periksa_roadmap", akar / "alat" / "periksa-roadmap.py")
        if spec is None or spec.loader is None:
            raise RuntimeError("alat/periksa-roadmap.py tidak bisa dimuat")
        _MODUL_ROADMAP = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(_MODUL_ROADMAP)  # type: ignore[union-attr]
    return _MODUL_ROADMAP


def _commit_menyentuh_kode(akar: pathlib.Path, teks: str) -> bool | None:
    """True bila salah satu sha di teks mengubah berkas kode/skema/alat; None bila sha tidak bisa dibaca (riwayat tidak ada)."""
    hasil: bool | None = None
    for sha in RE_SHA.findall(teks):
        try:
            r = subprocess.run(["git", "show", "--name-only", "--format=", sha], cwd=akar, capture_output=True, text=True)
        except OSError:
            return None
        if r.returncode != 0:
            continue
        hasil = bool(hasil) or any(l.startswith(AWALAN_KODE) for l in r.stdout.splitlines() if l.strip())
    return hasil


def periksa_bukti_mesin_perbaikan(akar: pathlib.Path, fid: str, status: str, perbaikan: str, tutup: str, errs: list[str]) -> None:
    """K4 Jaminan Tuntas: DIPERBAIKI/DITUTUP wajib menyebut berkas uji/penjaga yang ADA di repo (bukan nama karangan —
    pelajaran PMB1-F-202 & kartu B-F-09.2). Pengecualian: `tanpa uji mesin: <alasan>` untuk perbaikan dokumen/naskah yang
    commit-nya tidak menyentuh kode; baris yang ditutup sebelum aturan (K4_SEBELUM_ATURAN)."""
    if status not in {"DIPERBAIKI", "DITUTUP"} or fid in K4_SEBELUM_ATURAN:
        return
    pr = _modul_roadmap(akar)
    if pr.jalur_bukti_mesin(f"{perbaikan} {tutup}", akar):
        return
    if FRASA_TANPA_UJI in perbaikan.lower():
        if _commit_menyentuh_kode(akar, perbaikan):
            errs.append(f"BUKU BESAR {fid}: '{FRASA_TANPA_UJI}' tidak boleh dipakai — commit perbaikannya menyentuh kode/skema/alat; "
                        f"sebutkan berkas uji/penjaga yang ADA di repo (K4)")
        return
    errs.append(f"BUKU BESAR {fid}: status {status} wajib menyebut ≥1 berkas uji/penjaga yang ADA di repo di kolom Perbaikan/Tutup "
                f"(mis. `aplikasi/src/lib/x.test.ts`, `supabase/tes/x.sql`, `alat/periksa-x.py`) — bukti mesin K4; untuk perbaikan "
                f"dokumen tulis `{FRASA_TANPA_UJI} <alasan>`")
BAGIAN_K = ["## 1. Cakupan", "## 2. Klaim yang dicoba dibantah", "## 3. Serangan", "## 4. Temuan", "## 5. Asumsi",
            "## 6. Tidak bisa diverifikasi", "## 7. Regresi temuan lama", "## 8. Angka usaha"]
BAGIAN_H = ["## 1. Temuan yang dihakimi", "## 4. Angka usaha"]
BAGIAN_B = ["## 1. Temuan yang dibangun", "## 2. Yang sengaja tidak disentuh", "## 3. Keputusan yang dibutuhkan Lee",
            "## 4. Rantai bukti", "## 5. Angka usaha"]          # kartu PEMBANGUN (PROMPT_GILIRAN §5 butir 7)
KEPALA_K = ["**Potongan:**", "**Sesi:**", "**Tanggal:**", "**Commit basis:**"]
KEPALA_H = ["**Potongan:**", "**Sesi hakim:**", "**Independensi:**"]
KEPALA_B = ["**Potongan:**", "**Sesi pembangun:**", "**Commit basis:**", "**Independensi:**"]
RE_TERPUSH = re.compile(r"\*\*Ter-push sampai:\*\*\s*`?[0-9a-f]{7,40}\b")   # kartu B: bukti hasil giliran ada di origin (arahan Lee 2026-09-30)


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
        m = re.match(r"^([KHB])-(.+?)(?:\.(\d+))?\.md$", k.name)
        if not m:
            errs.append(f"kartu/{k.name}: nama harus K-<ID>.md, H-<ID>.md, B-<ID>.md, atau K-<ID>.<n>.md untuk ulangan"); continue
        jenis, pid, _ulangan = m.groups()
        if pid not in potongan:
            errs.append(f"kartu/{k.name}: potongan {pid} tidak ada di PAPAN (kartu yatim)"); continue
        isi = k.read_text(encoding="utf-8")
        for bagian in {"K": BAGIAN_K, "H": BAGIAN_H, "B": BAGIAN_B}[jenis]:
            if bagian not in isi:
                errs.append(f"kartu/{k.name}: bagian '{bagian}' hilang")
        for kepala in {"K": KEPALA_K, "H": KEPALA_H, "B": KEPALA_B}[jenis]:
            if kepala not in isi:
                errs.append(f"kartu/{k.name}: kepala '{kepala}' hilang")
        if "<ID>" in isi or "<YYYY-MM-DD>" in isi:
            errs.append(f"kartu/{k.name}: masih berisi tempat kosong templat (<ID>/<YYYY-MM-DD>)")
        if jenis == "B" and not RE_TERPUSH.search(isi):
            errs.append(f"kartu/{k.name}: baris `- **Ter-push sampai:** `<sha>`` hilang — arahan Lee 2026-09-30: hasil giliran wajib masuk GitHub; "
                        "isi dari keluaran `python3 alat/periksa-push.py` (mesin integrasi mengisinya dari tip origin bila kartu lupa)")


def _artefak_ada(sel_artefak: str, akar: pathlib.Path) -> bool:
    if sel_artefak.startswith("(luar repo)"):
        return len(sel_artefak) > len("(luar repo)") + 2
    m = re.search(r"`([^`]+)`", sel_artefak)
    token = (m.group(1) if m else sel_artefak.split()[0] if sel_artefak.split() else "")
    token = re.split(r"[:\s§#]", token, 1)[0]
    return bool(token) and adakah_artefak(token, akar)


def _baris_artefak_di_luar_berkas(sel_artefak: str, akar: pathlib.Path) -> str | None:
    """`berkas:baris` / `berkas:12-15,40` → nomor baris yang melebihi panjang berkas (PMB1-F-094: rujukan baris tak terverifikasi).
    Isi baris tetap tugas Hakim; di sini hanya batas kasar yang murah."""
    m = re.search(r"`([^`\s]+?):(\d+(?:\s*[–-]\s*\d+)?(?:,\s*\d+(?:\s*[–-]\s*\d+)?)*)`", sel_artefak)
    if not m:
        return None
    berkas = akar / m.group(1)
    if not berkas.is_file():
        return None
    try:
        jumlah = sum(1 for _ in berkas.open("rb"))
    except OSError:
        return None
    nomor = [int(x) for x in re.findall(r"\d+", m.group(2))]
    lebih = [n for n in nomor if n > jumlah]
    return f"baris {lebih} melebihi panjang {m.group(1)} ({jumlah} baris)" if lebih else None


def baca_buku_besar(akar: pathlib.Path, potongan: dict[str, dict], errs: list[str]) -> dict[str, dict]:
    p = akar / PUTARAN / "BUKU_BESAR_TEMUAN.md"
    if not p.is_file():
        errs.append("BUKU_BESAR_TEMUAN.md tidak ada"); return {}
    temuan: dict[str, dict] = {}
    kartu_h = {q.name[:-3] for q in (akar / PUTARAN / "kartu").glob("H-*.md")}
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
        elif (salah := _baris_artefak_di_luar_berkas(artefak, akar)):
            errs.append(f"BUKU BESAR {fid}: artefak menunjuk {salah}")
        if baseline in {"", "—"}:
            errs.append(f"BUKU BESAR {fid}: kolom 'Baseline yang dilanggar' kosong")
        if len(bukti) < 20 or "→" not in bukti:
            errs.append(f"BUKU BESAR {fid}: bukti harus 'perintah → hasil' (panjang ≥ 20, memuat '→')")
        if status not in STATUS_TEMUAN:
            errs.append(f"BUKU BESAR {fid}: status '{status}' tidak sah")
        if status in {"TERVERIFIKASI", "PALSU", "PERLU-INFO", "DITUTUP", "DUPLIKAT"} and hakim in {"", "—"}:
            errs.append(f"BUKU BESAR {fid}: status {status} wajib mengisi kolom Hakim (sesi + kartu H)")
        if status in {"TERVERIFIKASI", "PALSU", "PERLU-INFO", "DITUTUP", "DUPLIKAT"} and hakim not in {"", "—"}:
            # PMB1-F-136: kolom Hakim yang terisi saja tidak cukup — kartu hakim yang disebut harus benar-benar ada di kartu/
            rujukan_h = set(RE_KARTU_H.findall(f"{hakim} {tutup}"))
            if not (rujukan_h & kartu_h):
                errs.append(f"BUKU BESAR {fid}: status {status} wajib menyebut kartu hakim yang ADA di kartu/ (H-<potongan>[.n].md) "
                            f"di kolom Hakim/Tutup — disebut: {sorted(rujukan_h) or 'tidak ada'}")
        if status in {"DIPERBAIKI", "DITUTUP"} and not RE_SHA.search(perbaikan):
            errs.append(f"BUKU BESAR {fid}: status {status} wajib menyebut sha commit perbaikan")
        periksa_bukti_mesin_perbaikan(akar, fid, status, perbaikan, tutup, errs)
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
        temuan[fid] = {"tingkat": tingkat, "potongan": pot, "status": status, "baris": n, "teks": f"{hakim} {perbaikan} {tutup}"}
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


def periksa_daftar_tunggu_mutakhir(akar: pathlib.Path, errs: list[str]) -> None:
    """K2: DAFTAR_TUNGGU_LEE.md harus persis hasil mesin — kalau basi, Lee membaca daftar yang salah."""
    spec = importlib.util.spec_from_file_location("susun_daftar_tunggu", akar / "alat" / "susun-daftar-tunggu-lee.py")
    if spec is None or spec.loader is None:
        errs.append("alat/susun-daftar-tunggu-lee.py tidak ada"); return
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)  # type: ignore[union-attr]
    with contextlib.redirect_stdout(io.StringIO()):
        kode = mod.susun(akar, True)
    if kode != 0:
        errs.append("DAFTAR_TUNGGU_LEE.md basi (K2) → jalankan python3 alat/susun-daftar-tunggu-lee.py lalu commit")


def periksa(akar: pathlib.Path) -> int:
    errs: list[str] = []
    potongan = baca_papan(akar, errs)
    periksa_kartu(akar, potongan, errs)
    temuan = baca_buku_besar(akar, potongan, errs)
    periksa_transisi(akar, temuan, errs)
    baca_asumsi(akar, temuan, errs)
    periksa_matriks_mutakhir(akar, errs)
    periksa_daftar_tunggu_mutakhir(akar, errs)
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


def _tugas_roadmap(akar: pathlib.Path) -> list[tuple[str, bool, str]]:
    """[(id, dicentang?, badan)] dari docs/ROADMAP.md (lewat pembaca periksa-roadmap.py)."""
    pr = _modul_roadmap(akar)
    rm = akar / "docs" / "ROADMAP.md"
    if not rm.is_file():
        return []
    hasil = []
    for tid, isi in pr.blok_tugas(rm.read_text(encoding="utf-8"), semua_status=True):
        kepala, _, badan = isi.partition("\n")
        hasil.append((tid, kepala.startswith("[x]"), badan))
    return hasil


def sensus_kurang(akar: pathlib.Path, potongan: dict[str, dict]) -> list[str]:
    """K5 (gerbang tahap 2): untuk setiap fase yang punya potongan P-<fase>-xx, (a) tidak boleh ada centang ⏳ BUKTI-BELUM
    tersisa pada tugas T<fase>-xx, (b) setiap tugas [x] fase itu wajib tercatat di bagian 'Sensus klaim' kartu K potongannya."""
    pr = _modul_roadmap(akar)
    fase_potongan: dict[str, list[str]] = {}
    for pid, p in potongan.items():
        m = re.match(r"^P-(\d+[A-Z]?)-\d{2}$", pid)
        if m and p["tahap"] == 2:
            fase_potongan.setdefault(m.group(1), []).append(pid)
    errs: list[str] = []
    for fase, pids in sorted(fase_potongan.items()):
        tercatat: set[str] = set()
        for pid in pids:
            for k in (akar / PUTARAN / "kartu").glob(f"K-{pid}*.md"):
                isi = k.read_text(encoding="utf-8")
                bagian = re.split(r"^##+ .*Sensus klaim.*$", isi, maxsplit=1, flags=re.M | re.I)
                if len(bagian) == 2:
                    tercatat.update(re.findall(rf"\bT{fase}-\d+\b", re.split(r"^## ", bagian[1], maxsplit=1, flags=re.M)[0]))
        belum_bukti, tak_tercatat = [], []
        for tid, centang, badan in _tugas_roadmap(akar):
            if not centang or tid.split("-")[0] != f"T{fase}":
                continue
            if any(pr.PENANDA_TRANSISI in l for l in badan.splitlines() if pr.RE_BARIS_BUKTI.match(l)):
                belum_bukti.append(tid)
            if tid not in tercatat:
                tak_tercatat.append(tid)
        if belum_bukti:
            errs.append(f"sensus klaim fase {fase}: masih ada centang ⏳ BUKTI-BELUM: {', '.join(belum_bukti)}")
        if tak_tercatat:
            errs.append(f"sensus klaim fase {fase}: tugas [x] tidak tercatat di bagian 'Sensus klaim' kartu K {'/'.join(pids)}: {', '.join(tak_tercatat)}")
    return errs


def gerbang(akar: pathlib.Path, tahap: int | str) -> int:
    errs: list[str] = []
    if periksa(akar) != 0:
        print("\nGERBANG: GAGAL — pemeriksaan dasar belum LOLOS"); return 1
    potongan = baca_papan(akar, errs)
    temuan = baca_buku_besar(akar, potongan, errs)
    akhir = tahap == "akhir"
    milik = set(potongan) if akhir else {pid for pid, p in potongan.items() if p["tahap"] == tahap}
    belum = sorted(pid for pid in milik if potongan[pid]["status"] != "DIHAKIMI")
    if not milik:
        errs.append(f"tidak ada potongan bertahap {tahap} di PAPAN")
    if belum:
        errs.append(f"potongan {'(semua tahap)' if akhir else 'tahap ' + str(tahap)} belum DIHAKIMI: {', '.join(belum)}")
    tingkat_dijaga = {"K-1", "K-2", "K-3", "K-4"} if akhir else {"K-1", "K-2"}
    terbuka = sorted(f for f, t in temuan.items() if t["potongan"] in milik and t["status"] in TERBUKA and t["tingkat"] in tingkat_dijaga)
    if terbuka:
        errs.append(f"temuan {'SEMUA tingkat' if akhir else 'K-1/K-2'} masih terbuka ({len(terbuka)}): {', '.join(terbuka[:40])}"
                    + (" …" if len(terbuka) > 40 else ""))
    if akhir:
        # K1: DITANGGUHKAN hanya oleh Lee, dengan tanggal tinjau; ROADMAP tanpa tugas 'Dibuka kembali' terbuka & tanpa ⏳ BUKTI-BELUM
        pr = _modul_roadmap(akar)
        for fid, t in temuan.items():
            if t["status"] == "DITANGGUHKAN":
                teks = t.get("teks", "")
                if "lee" not in teks.lower() or not re.search(r"tinjau\s*:?\s*\d{4}-\d{2}-\d{2}", teks, re.I):
                    errs.append(f"{fid} DITANGGUHKAN tanpa kata-kata Lee + 'tinjau YYYY-MM-DD' di kolom Perbaikan/Tutup — hanya Lee yang menangguhkan")
        dibuka, belum_bukti = [], []
        for tid, centang, badan in _tugas_roadmap(akar):
            if not centang and pr.RE_DIBUKA_KEMBALI.search(badan):
                dibuka.append(tid)
            if centang and any(pr.PENANDA_TRANSISI in l for l in badan.splitlines() if pr.RE_BARIS_BUKTI.match(l)):
                belum_bukti.append(tid)
        if dibuka:
            errs.append(f"tugas ROADMAP 'Dibuka kembali' masih [ ] ({len(dibuka)}): {', '.join(dibuka)}")
        if belum_bukti:
            errs.append(f"centang ROADMAP masih ⏳ BUKTI-BELUM ({len(belum_bukti)}) — sensus klaim belum tuntas")
    if tahap == 2:
        errs.extend(sensus_kurang(akar, potongan))
    if tahap == 1:
        m = (akar / PUTARAN / "MATRIKS_TELUSUR.md").read_text(encoding="utf-8")
        semua = set(re.findall(r"^\| ((?:PRD M|ART-|TECH_SPEC §|KEAMANAN §)\d{1,2}b?) \|", m, re.M))
        yatim = sorted(semua - _janji_di_bagian_b(m))
        if yatim:
            errs.append(f"janji yatim (tanpa potongan pemeriksa di bagian B matriks): {', '.join(yatim)}")
    per_status = {s: sum(1 for t in temuan.values() if t["potongan"] in milik and t["status"] == s) for s in sorted(STATUS_TEMUAN)}
    per_k = {k: sum(1 for t in temuan.values() if t["potongan"] in milik and t["tingkat"] == k) for k in ("K-1", "K-2", "K-3", "K-4")}
    putusan = "LOLOS" if not errs else "GAGAL"
    isi = [f"# RINGKASAN {'GERBANG AKHIR' if akhir else 'TAHAP ' + str(tahap)} — PMB-1 (dibuat mesin: `python3 alat/periksa-pemeriksaan.py --gerbang {tahap}`)", "",
           f"- **Putusan gerbang:** {putusan}", f"- Potongan tahap ini: {len(milik)} · belum DIHAKIMI: {len(belum)}",
           f"- Temuan per status: {per_status}", f"- Temuan per tingkat: {per_k}",
           f"- Temuan palsu ÷ total: {per_status.get('PALSU', 0)}/{sum(per_status.values()) or 1}",
           "- Kalibrasi (diisi Perencana setelah membuka kunci): ditemukan … dari … · temuan palsu … · per kelas …", ""]
    if errs:
        isi += ["## Penghalang", ""] + [f"- {e}" for e in errs] + [""]
    (akar / PUTARAN / f"RINGKASAN_TAHAP-{tahap}.md").write_text("\n".join(isi), encoding="utf-8")
    for e in errs:
        print(f"  [GERBANG] {e}")
    print(f"\nGERBANG {'AKHIR' if akhir else 'TAHAP ' + str(tahap)}: {putusan} — ringkasan ditulis ke {PUTARAN}/RINGKASAN_TAHAP-{tahap}.md")
    return 1 if errs else 0


def uji_diri() -> int:
    """Mutasi harus MERAH. Setiap kasus MEMBUAT cacatnya sendiri (baris/keadaan sintetis) — tidak bergantung pada isi
    papan/buku besar saat ini (PMB1-F-009: versi lama tumpul begitu tidak ada baris BARU / F-02 sudah bukan BELUM)."""
    hasil: list[tuple[str, bool, str]] = []
    bb = pathlib.Path(PUTARAN) / "BUKU_BESAR_TEMUAN.md"
    papan = pathlib.Path(PUTARAN) / "PAPAN.md"
    asumsi = pathlib.Path(PUTARAN) / "ASUMSI.md"

    def segarkan_daftar(t: pathlib.Path) -> None:
        """Kasus yang HARUS diterima menyegarkan DAFTAR_TUNGGU_LEE.md dulu (K2 menuntut daftar mutakhir) — jadi yang diuji
        adalah aturan lain, bukan kebasian daftar. Kasus MERAH sengaja tidak disegarkan."""
        spec = importlib.util.spec_from_file_location("susun_daftar_tunggu_ud", t / "alat" / "susun-daftar-tunggu-lee.py")
        mod = importlib.util.module_from_spec(spec); spec.loader.exec_module(mod)  # type: ignore[union-attr]
        with contextlib.redirect_stdout(io.StringIO()):
            mod.susun(t, False)

    def coba(nama: str, rusak, harus_merah: bool = True, fungsi=None) -> None:
        with salin_pohon() as tmp:
            try:
                rusak(tmp)
                if not harus_merah:
                    segarkan_daftar(tmp)
            except LookupError as e:          # mutasi tidak bisa dibuat → kasus gagal (bukan diam-diam lolos)
                hasil.append((nama, False, f"mutasi tidak terbentuk: {e}")); return
            kode, keluaran = jalankan_pemeriksa(fungsi or periksa, tmp)
            ok = (kode != 0) if harus_merah else (kode == 0)
            hasil.append((nama, ok, f"kode={kode}" + ("" if ok else "\n" + keluaran[-600:])))

    def id_berikut(teks: str, awalan: str) -> str:
        nomor = [int(m) for m in re.findall(rf"\| {awalan}(\d{{3}}) \|", teks)]
        return f"{awalan}{(max(nomor) if nomor else 0) + 1:03d}"

    def potongan_bukan_dihakimi(t: pathlib.Path) -> str:
        for m in re.finditer(r"^\| ((?:[FXMDGLZ]-\d{2}|P-\d+A?-\d{2})) \|(?:[^|\n]*\|){5} (\w+) \|", (t / papan).read_text(encoding="utf-8"), re.M):
            if m.group(2) != "DIHAKIMI":
                return m.group(1)
        raise LookupError("semua potongan sudah DIHAKIMI — tidak ada tempat untuk baris sintetis BARU")

    def tambah_temuan(t: pathlib.Path, status: str, hakim: str = "—", perbaikan: str = "—", tutup: str = "—",
                      artefak: str = "`docs/PRD.md:1`", pot: str | None = None) -> None:
        pot = pot or potongan_bukan_dihakimi(t)
        teks = (t / bb).read_text(encoding="utf-8").rstrip("\n")
        fid = id_berikut(teks, "PMB1-F-")
        baris = (f"| {fid} | K-4 | {pot} | {artefak} | uji-diri: baseline sintetis | keterpeliharaan | "
                 f"`echo uji-diri` → baris sintetis untuk menguji penjaga | {status} | {hakim} | {perbaikan} | {tutup} |")
        (t / bb).write_text(teks + "\n" + baris + "\n", encoding="utf-8")

    def ubah_sel_temuan(t: pathlib.Path, fid: str, indeks: int, nilai: str) -> None:
        teks = (t / bb).read_text(encoding="utf-8")
        for i, baris in enumerate(teks.splitlines()):
            if baris.startswith(f"| {fid} |"):
                sel = [s.strip() for s in baris.strip().strip("|").split("|")]
                sel[indeks] = nilai
                garis = teks.splitlines(); garis[i] = "| " + " | ".join(sel) + " |"
                (t / bb).write_text("\n".join(garis) + "\n", encoding="utf-8"); return
        raise LookupError(f"baris {fid} tidak ada")

    def potongan_belum_selesai(t: pathlib.Path) -> None:
        teks = (t / papan).read_text(encoding="utf-8")
        m = re.search(r"^(\| (?:[FXMDGLZ]-\d{2}|P-\d+A?-\d{2}) \|(?:[^|\n]*\|){5}) (?:BELUM|RENCANA) \| — \| — \|$", teks, re.M)
        if not m:
            raise LookupError("tidak ada potongan BELUM/RENCANA yang bisa dijadikan SELESAI tanpa kartu")
        (t / papan).write_text(teks.replace(m.group(0), f"{m.group(1)} SELESAI | arena/uji-diri | 2026-09-28 |", 1), encoding="utf-8")

    def roadmap_bergeser(t: pathlib.Path) -> None:
        blok = (t / PUTARAN / "MATRIKS_TELUSUR.md").read_text(encoding="utf-8")
        tugas = re.findall(r"\bT\d+-\d{2}\b", blok.split("<!-- OTOMATIS:MULAI -->", 1)[-1])
        rm = t / "docs/ROADMAP.md"; teks = rm.read_text(encoding="utf-8")
        for tid in tugas:
            m = re.search(rf"^- \[( |x)\] {re.escape(tid)} —", teks, re.M)
            if m:
                ganti = "- [x] " if m.group(1) == " " else "- [ ] "
                rm.write_text(teks[:m.start()] + ganti + teks[m.start() + 6:], encoding="utf-8"); return
        raise LookupError("tidak ada tugas ROADMAP yang muncul di matriks")

    def asumsi_dibantah_tanpa_temuan(t: pathlib.Path) -> None:
        teks = (t / asumsi).read_text(encoding="utf-8").rstrip("\n")
        aid = id_berikut(teks, "PMB1-A-")
        (t / asumsi).write_text(teks + f"\n| {aid} | uji-diri: asumsi sintetis | `docs/PRD.md:1` | DIBANTAH | "
                                "`echo uji-diri` → dibantah tanpa rujukan temuan | tidak ada | F-01 |\n", encoding="utf-8")

    def kartu_b(t: pathlib.Path, lengkap: bool, terpush: bool = True) -> None:
        isi = ("# KARTU PEMBANGUN — B-F-01\n- **Potongan:** F-01 · **Sesi pembangun:** arena/uji-diri · **Commit basis:** 0000000 · "
               "**Independensi:** bukan penemu, bukan hakim\n" + ("- **Ter-push sampai:** `0000000`\n" if terpush else ""))
        for bagian in BAGIAN_B if lengkap else BAGIAN_B[:2]:
            isi += f"\n{bagian}\n- (uji-diri)\n"
        (t / PUTARAN / "kartu" / "B-F-01.md").write_text(isi, encoding="utf-8")

    coba("salinan utuh diterima", lambda t: None, harus_merah=False)
    coba("kartu PEMBANGUN B-<ID>.md yang lengkap diterima", lambda t: kartu_b(t, True), harus_merah=False)
    coba("kartu PEMBANGUN tanpa bagian wajib ditolak", lambda t: kartu_b(t, False))
    coba("kartu PEMBANGUN tanpa baris Ter-push sampai ditolak (arahan Lee 2026-09-30)", lambda t: kartu_b(t, True, terpush=False))
    coba("baris sintetis yang sah diterima", lambda t: tambah_temuan(t, "BARU"), harus_merah=False)
    coba("potongan SELESAI tanpa kartu ditolak", potongan_belum_selesai)
    coba("status temuan tidak sah ditolak", lambda t: tambah_temuan(t, "SELESAI"))
    coba("DITUTUP tanpa hakim/commit ditolak", lambda t: tambah_temuan(t, "DITUTUP"))
    coba("artefak yang tidak ada ditolak", lambda t: tambah_temuan(t, "BARU", artefak="`supabase/migrations/9999_tidak_ada.sql:1`"))
    coba("artefak dengan nomor baris di luar berkas ditolak", lambda t: tambah_temuan(t, "BARU", artefak="`docs/PRD.md:99999`"))
    coba("TERVERIFIKASI dengan kartu hakim yang tidak ada ditolak (PMB1-F-136)",
         lambda t: tambah_temuan(t, "TERVERIFIKASI", hakim="arena/bukan-hakim H-TIDAK-ADA — bukan hakim sebenarnya"))
    coba("TERVERIFIKASI oleh pemeriksa sendiri (kartu K, bukan H) ditolak",
         lambda t: tambah_temuan(t, "TERVERIFIKASI", hakim="arena/uji K-F-01 §4 — direproduksi sendiri"))
    coba("ID temuan melompat ditolak", lambda t: ubah_sel_temuan(t, "PMB1-F-001", 0, "PMB1-F-000"))
    coba("potongan temuan yang tidak ada di papan ditolak", lambda t: tambah_temuan(t, "BARU", pot="F-99"))
    coba("temuan pertama dihapus ditolak (urutan ID putus)", lambda t: (t / bb).write_text(
        "\n".join(b for b in (t / bb).read_text(encoding="utf-8").splitlines() if not b.startswith("| PMB1-F-001 |")) + "\n", encoding="utf-8"))
    coba("kartu yatim / tidak lengkap ditolak",
         lambda t: (t / PUTARAN / "kartu" / "K-F-01.md").write_text("# kartu kosong\n", encoding="utf-8"))
    coba("matriks basi ditolak", roadmap_bergeser)
    coba("DUPLIKAT tanpa temuan induk ditolak", lambda t: tambah_temuan(t, "DUPLIKAT", hakim="arena/uji-diri H-F-01"))
    coba("asumsi DIBANTAH tanpa temuan ditolak", asumsi_dibantah_tanpa_temuan)

    # --- Jaminan Tuntas (keputusan Lee 2026-09-29): K2 daftar tunggu, K4 bukti mesin, K1 gerbang akhir, K5 sensus klaim
    coba("K2: DAFTAR_TUNGGU_LEE.md basi (buku besar berubah tanpa disusun ulang) ditolak",
         lambda t: ubah_sel_temuan(t, "PMB1-F-001", 9, "MENUNGGU KEPUTUSAN LEE: uji-diri daftar basi"))
    coba("K4: DIPERBAIKI tanpa berkas uji/penjaga ditolak",
         lambda t: tambah_temuan(t, "DIPERBAIKI", perbaikan="abcdef1 — diperbaiki, katanya sudah diuji"))
    coba("K4: DIPERBAIKI menyebut berkas uji karangan ditolak",
         lambda t: tambah_temuan(t, "DIPERBAIKI", perbaikan="abcdef1 — uji `aplikasi/src/lib/tidak-pernah-ada.test.ts` hijau"))
    coba("K4: DIPERBAIKI menyebut berkas uji yang ADA diterima",
         lambda t: tambah_temuan(t, "DIPERBAIKI", perbaikan="abcdef1 — uji `alat/periksa-roadmap.py` --uji-diri hijau"), harus_merah=False)
    coba("K4: DIPERBAIKI dokumen dengan 'tanpa uji mesin: <alasan>' diterima",
         lambda t: tambah_temuan(t, "DIPERBAIKI", perbaikan="abcdef1 — tanpa uji mesin: perbaikan kalimat naskah"), harus_merah=False)

    def gerbang_akhir(t: pathlib.Path) -> None:
        segarkan_daftar(t)
    coba("K1: gerbang akhir menolak selama masih ada temuan terbuka tingkat apa pun", gerbang_akhir, fungsi=lambda a: gerbang(a, "akhir"))

    def _sensus(t: pathlib.Path, lengkap: bool) -> list[str]:
        rm = t / "docs" / "ROADMAP.md"; teks = rm.read_text(encoding="utf-8")
        pr = _modul_roadmap(t)
        ids = [tid for tid, isi in pr.blok_tugas(teks, semua_status=True) if tid.startswith("T0-") and isi.startswith("[x]")]
        if lengkap:  # semua centang T0 diberi bukti nyata (ganti penanda transisi) → sensus tuntas
            baris = teks.splitlines(); dalam_t0 = False
            for i, b in enumerate(baris):
                m = re.match(r"^- \[[ x]\] (T\d+[A-Z]?-\d+) — ", b)
                if m:
                    dalam_t0 = m.group(1).startswith("T0-")
                elif dalam_t0 and pr.RE_BARIS_BUKTI.match(b) and pr.PENANDA_TRANSISI in b:
                    baris[i] = "  - **Bukti:** `alat/periksa-roadmap.py` (uji-diri sensus)"
            rm.write_text("\n".join(baris), encoding="utf-8")
        (t / PUTARAN / "kartu" / "K-P-0-01.md").write_text("# kartu sensus uji-diri\n\n## Sensus klaim\n\n" +
            "\n".join(f"| {tid} | bukti diperiksa |" for tid in (ids if lengkap else ids[:1])) + "\n\n## 4. Temuan\n", encoding="utf-8")
        return sensus_kurang(t, {"P-0-01": {"tahap": 2, "status": "DIHAKIMI", "baris": 0}})

    with salin_pohon() as tmp:
        err = _sensus(tmp, lengkap=False)
        hasil.append(("K5: sensus klaim tidak lengkap / masih ⏳ BUKTI-BELUM ditolak", bool(err), "; ".join(err)[:200]))
    with salin_pohon() as tmp:
        err = _sensus(tmp, lengkap=True)
        hasil.append(("K5: sensus klaim lengkap dengan bukti nyata diterima", not err, "; ".join(err)[:200] or "bersih"))
    return laporkan("periksa-pemeriksaan", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    if "--gerbang" in sys.argv:
        i = sys.argv.index("--gerbang")
        arg = sys.argv[i + 1] if i + 1 < len(sys.argv) else "1"
        sys.exit(gerbang(AKAR, "akhir" if arg == "akhir" else int(arg)))
    sys.exit(periksa(AKAR))
