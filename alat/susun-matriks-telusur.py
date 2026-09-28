#!/usr/bin/env python3
"""susun-matriks-telusur.py — menyusun bagian OTOMATIS Matriks Telusur & Regresi Wajib PMB.

Kenapa ada: rancangan PMB (docs/uji/pemeriksaan/RANCANGAN_PEMERIKSAAN_BERTAHAP.md §7, §13 butir 2 & 5)
mewajibkan **matriks ketelusuran** janji → tugas ROADMAP → berkas, dan daftar **regresi wajib**
(klaim `[x]` yang DoD/Verifikasinya menuntut pelaksanaan nyata). Menulisnya dengan tangan akan basi
dalam seminggu; mesin menyusunnya ulang dari sumbernya sehingga selalu bisa dibuktikan.

Sumber janji (baseline): PRD M1–M12, TECH_SPEC ART-1…15 & §1–§13, KEAMANAN §1–§15 (+§4b).
Sumber tautan: baris `**Ref:**`, `**File:**`, `**DoD:**`, `**Verifikasi:**` tiap tugas ROADMAP.

Cara pakai:
    python3 alat/susun-matriks-telusur.py            # tulis ulang blok OTOMATIS di kedua berkas
    python3 alat/susun-matriks-telusur.py --periksa  # GAGAL bila blok OTOMATIS basi (dipakai penjaga)
    python3 alat/susun-matriks-telusur.py --uji-diri # buktikan mode --periksa bisa MERAH

Blok OTOMATIS diapit penanda `<!-- OTOMATIS:MULAI -->` … `<!-- OTOMATIS:SELESAI -->`; isi di luar
penanda (penugasan potongan, hasil) ditulis manusia dan tidak disentuh alat ini.
"""
from __future__ import annotations

import pathlib
import re
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
PUTARAN = "docs/uji/pemeriksaan/PMB-1"
MATRIKS = f"{PUTARAN}/MATRIKS_TELUSUR.md"
REGRESI = f"{PUTARAN}/REGRESI_WAJIB.md"
MULAI, SELESAI = "<!-- OTOMATIS:MULAI -->", "<!-- OTOMATIS:SELESAI -->"

RE_TUGAS = re.compile(r"^- \[([ x])\] (T\d+[A-Z]?-\d+) — (.*)$")
RE_FASE = re.compile(r"^## Fase (\S+)")
RE_BIDANG = re.compile(r"^\s+- \*\*(Ref|File|DoD|Verifikasi):\*\*\s*(.*)$")
# Kata yang menandakan DoD/Verifikasi menuntut tangan pemilik / dunia nyata (bukan hanya kode).
RE_NYATA = re.compile(
    r"\b(pemilik|Lee|nyata|perangkat kedua|perangkat fisik|printer fisik|HP\b|tanda tangan|pelatihan|"
    r"disaksikan|dari HP|di luar jaringan|produksi nyata|dashboard)\b", re.I)


def baca_roadmap(akar: pathlib.Path) -> list[dict]:
    """Kembalikan daftar tugas ROADMAP beserta fase, baris, status, Ref/File/DoD/Verifikasi."""
    tugas: list[dict] = []
    fase = "?"
    aktif: dict | None = None
    for n, baris in enumerate((akar / "docs/ROADMAP.md").read_text(encoding="utf-8").splitlines(), 1):
        m = RE_FASE.match(baris)
        if m:
            fase = m.group(1)
            aktif = None
            continue
        m = RE_TUGAS.match(baris)
        if m:
            aktif = {"id": m.group(2), "selesai": m.group(1) == "x", "judul": m.group(3).strip(),
                     "fase": fase, "baris": n, "Ref": "", "File": "", "DoD": "", "Verifikasi": ""}
            tugas.append(aktif)
            continue
        if aktif is not None:
            m = RE_BIDANG.match(baris)
            if m and not aktif[m.group(1)]:
                aktif[m.group(1)] = m.group(2).strip()
    return tugas


def janji_dari_ref(ref: str) -> set[str]:
    """Ambil ID janji baseline dari satu baris Ref: `PRD M4`, `ART-7`, `KEAMANAN §6`, `TECH_SPEC §11`."""
    hasil: set[str] = set()
    for seg in re.split(r"[;·]", ref):
        for m in re.finditer(r"\bM(\d{1,2})\b", seg):
            if "PRD" in seg:
                hasil.add(f"PRD M{int(m.group(1))}")
        for m in re.finditer(r"\bART-(\d{1,2})\b", seg):
            hasil.add(f"ART-{int(m.group(1))}")
        dok = None
        if "KEAMANAN" in seg:
            dok = "KEAMANAN"
        elif "TECH_SPEC" in seg:
            dok = "TECH_SPEC"
        if dok:
            for m in re.finditer(r"§\s*(\d{1,2}b?)", seg):
                hasil.add(f"{dok} §{m.group(1)}")
    return hasil


def daftar_janji(akar: pathlib.Path) -> list[tuple[str, str]]:
    """(ID janji, judul singkat) — dibaca dari dokumen fondasi supaya tidak ada janji karangan."""
    janji: list[tuple[str, str]] = []
    prd = (akar / "docs/PRD.md").read_text(encoding="utf-8")
    for m in re.finditer(r"^### M(\d{1,2})\. (.+)$", prd, re.M):
        janji.append((f"PRD M{int(m.group(1))}", m.group(2).strip()))
    ts = (akar / "docs/TECH_SPEC.md").read_text(encoding="utf-8")
    art: dict[int, str] = {}
    for m in re.finditer(r"\bART-(\d{1,2})\b[^\n]{0,80}", ts):
        art.setdefault(int(m.group(1)), m.group(0)[:70].replace("|", "/"))
    for k in sorted(art):
        janji.append((f"ART-{k}", art[k]))
    for m in re.finditer(r"^## (\d{1,2})\. (.+)$", ts, re.M):
        janji.append((f"TECH_SPEC §{int(m.group(1))}", m.group(2).strip()))
    km = (akar / "docs/KEAMANAN.md").read_text(encoding="utf-8")
    for m in re.finditer(r"^## (\d{1,2}b?)\. (.+)$", km, re.M):
        janji.append((f"KEAMANAN §{m.group(1)}", m.group(2).strip()))
    return janji


def _pendek(teks: str, n: int = 90) -> str:
    teks = teks.replace("|", "/").replace("\n", " ")
    return teks if len(teks) <= n else teks[: n - 1] + "…"


def blok_matriks(akar: pathlib.Path) -> str:
    tugas = baca_roadmap(akar)
    peta: dict[str, list[dict]] = {}
    for t in tugas:
        for j in janji_dari_ref(t["Ref"]):
            peta.setdefault(j, []).append(t)
    baris = ["| Janji (baseline) | Judul | Tugas ROADMAP yang merujuk | Tuntas/total | Berkas implementasi (dari `File:`) |",
             "|---|---|---|---|---|"]
    yatim = 0
    for jid, judul in daftar_janji(akar):
        daftar = peta.get(jid, [])
        ids = ", ".join(t["id"] for t in daftar) or "⚠️ **tanpa tugas**"
        if not daftar:
            yatim += 1
        tuntas = sum(1 for t in daftar if t["selesai"])
        berkas: list[str] = []
        for t in daftar:
            for b in re.findall(r"`([^`]+)`", t["File"]):
                if b not in berkas:
                    berkas.append(b)
        teks_berkas = ", ".join(f"`{b}`" for b in berkas[:5]) + (f" +{len(berkas)-5}" if len(berkas) > 5 else "")
        baris.append(f"| {jid} | {_pendek(judul, 60)} | {ids} | {tuntas}/{len(daftar)} | {teks_berkas or '—'} |")
    kepala = (f"_Disusun mesin oleh `python3 alat/susun-matriks-telusur.py` dari `docs/ROADMAP.md` ({len(tugas)} tugas), "
              f"`docs/PRD.md`, `docs/TECH_SPEC.md`, `docs/KEAMANAN.md`. Janji tanpa tugas: **{yatim}** — "
              f"tiap baris ⚠️ wajib dijawab potongan fondasi (janji tidak dibangun? atau `Ref:` ROADMAP tidak lengkap?)._")
    return kepala + "\n\n" + "\n".join(baris) + "\n"


def potongan_roadmap(baris: int) -> str:
    """Potongan fondasi PMB-1 yang bertanggung jawab atas baris ROADMAP ini (lihat PAPAN F-08…F-10)."""
    if baris < 659:
        return "F-08"
    if baris < 1519:
        return "F-09"
    return "F-10"


def blok_regresi(akar: pathlib.Path) -> str:
    tugas = baca_roadmap(akar)
    baris = ["| Tugas | Fase | Baris ROADMAP | Kata pemicu di DoD/Verifikasi | Potongan penyisir |", "|---|---|---|---|---|"]
    n = 0
    for t in tugas:
        if not t["selesai"]:
            continue
        # urutan harus deterministik lintas proses (hash acak str): kunci (huruf kecil, asli)
        kata = sorted({m.group(0) for m in RE_NYATA.finditer(t["DoD"] + " " + t["Verifikasi"])}, key=lambda s: (s.lower(), s))
        if not kata:
            continue
        n += 1
        baris.append(f"| {t['id']} | {t['fase']} | {t['baris']} | {', '.join(kata)} | {potongan_roadmap(t['baris'])} |")
    kepala = (f"_Disusun mesin oleh `python3 alat/susun-matriks-telusur.py`: **{n}** tugas `[x]` yang DoD/Verifikasinya memuat "
              "kata pelaksanaan nyata (pemilik, perangkat, printer, HP, tanda tangan, pelatihan, …). Ini daftar untuk **disisir**, "
              "bukan vonis: potongan penyisir wajib menuntut bukti pelaksanaan tiap baris, atau mencatat temuan kelas "
              "\"klaim vs kenyataan\" (contoh nyata: T11-02/04/09/10/12, REKAM §31)._")
    return kepala + "\n\n" + "\n".join(baris) + "\n"


def ganti_blok(teks: str, isi: str) -> str:
    a, b = teks.find(MULAI), teks.find(SELESAI)
    if a < 0 or b < 0 or b < a:
        raise SystemExit("penanda OTOMATIS tidak lengkap")
    return teks[: a + len(MULAI)] + "\n" + isi + teks[b:]


def susun(akar: pathlib.Path, periksa_saja: bool) -> int:
    basi: list[str] = []
    for rel, pembuat in ((MATRIKS, blok_matriks), (REGRESI, blok_regresi)):
        p = akar / rel
        if not p.is_file():
            print(f"[GAGAL] {rel} tidak ada"); return 1
        lama = p.read_text(encoding="utf-8")
        baru = ganti_blok(lama, pembuat(akar))
        if baru != lama:
            if periksa_saja:
                basi.append(rel)
            else:
                p.write_text(baru, encoding="utf-8")
                print(f"ditulis ulang: {rel}")
        else:
            print(f"[OK] {rel} mutakhir")
    if basi:
        print("\nHASIL: GAGAL — blok OTOMATIS basi: " + ", ".join(basi) + " → jalankan `python3 alat/susun-matriks-telusur.py`")
        return 1
    print("\nHASIL: LOLOS" if periksa_saja else "\nSELESAI")
    return 0


def uji_diri() -> int:
    sys.path.insert(0, str(AKAR / "alat"))
    from bantu_uji_diri import jalankan_pemeriksa, laporkan, salin_pohon  # noqa: E402
    hasil: list[tuple[str, bool, str]] = []
    with salin_pohon() as tmp:
        kode, _ = jalankan_pemeriksa(lambda a: susun(a, True), tmp)
        hasil.append(("salinan utuh diterima", kode == 0, f"kode={kode}"))
        # Rusak: tandai satu tugas ROADMAP jadi [x] → daftar regresi/matriks berubah → --periksa harus MERAH.
        r = tmp / "docs/ROADMAP.md"
        teks = r.read_text(encoding="utf-8")
        teks2 = teks.replace("- [ ] T11-02 —", "- [x] T11-02 —", 1)
        assert teks2 != teks
        r.write_text(teks2, encoding="utf-8")
        kode, _ = jalankan_pemeriksa(lambda a: susun(a, True), tmp)
        hasil.append(("blok basi ditolak (ROADMAP berubah tanpa susun ulang)", kode != 0, f"kode={kode}"))
        r.write_text(teks, encoding="utf-8")
        # Rusak: hapus satu janji dari matriks → juga basi.
        m = tmp / MATRIKS
        isi = m.read_text(encoding="utf-8")
        m.write_text(isi.replace("| PRD M6 |", "| PRD M6x |", 1), encoding="utf-8")
        kode, _ = jalankan_pemeriksa(lambda a: susun(a, True), tmp)
        hasil.append(("matriks yang diubah tangan ditolak", kode != 0, f"kode={kode}"))
    return laporkan("susun-matriks-telusur", hasil)


if __name__ == "__main__":
    if "--uji-diri" in sys.argv:
        sys.exit(uji_diri())
    sys.exit(susun(AKAR, "--periksa" in sys.argv))
