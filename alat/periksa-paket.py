#!/usr/bin/env python3
"""periksa-paket.py — penjaga INVARIAN paket audit & paket review PR.

Kenapa ada (dua temuan audit AUD-3 2026-09-18 yang tidak lolos apa pun):

* **F-11** — paket menuliskan commit yang diaudit, tetapi tidak ada satu pun pemeriksa
  yang memastikan commit itu benar-benar induk dari commit yang memuat berkas paket.
  Akibatnya, paket yang ter-commit di commit X bisa menyuruh auditor `git checkout`
  ke commit Y — auditor memeriksa pohon yang BERBEDA dari yang dimaksud, semuanya
  tetap hijau, dan verifikasi penutupan temuan membandingkan dua pohon berbeda.
* **F-12** — bagian "1. Artefak yang harus diperiksa (minimal)" memuat 267 dari 354
  jalur (75%) yang **tidak ada** di commit yang diaudit (jalur tugas yang belum
  dikerjakan). Auditor diarahkan mencari bukti yang tidak pernah ada, lalu bisa
  menyimpulkan "sudah ada" hanya dari NAMA berkas.

Dua aturan yang diperiksa di sini:

1. **Invariant commit:** SHA yang ditulis paket == induk langsung dari commit yang
   menambahkan/mengubah berkas paket itu di pohon HEAD. (Cara paket dibuat: tulis
   paket pada tip X → commit paket → commit itu berinduk X. Jadi invariannya selalu
   bisa dipenuhi; kalau tidak, berarti paket disegarkan setelah tip bergerak.)
2. **Artefak nyata:** setiap jalur di tabel bagian 1 harus ada di pohon commit yang
   diaudit (`git cat-file -e <sha>:<jalur>`).

Dipakai CI (lihat .github/workflows/ci.yml) dan bisa dijalankan manual:
  python3 alat/periksa-paket.py
  python3 alat/periksa-paket.py --uji-diri     # bukti pemeriksa ini bisa MENOLAK
                                              # (termasuk aturan berkas SIAP-TEMPEL: cacat nyata 2026-09-19)
"""
from __future__ import annotations

import fnmatch
import pathlib
import re
import subprocess
import sys

AKAR = pathlib.Path(__file__).resolve().parent.parent
FOLDER_PAKET = AKAR / "docs" / "uji" / "paket-audit"
FOLDER_REVIEW = AKAR / "docs" / "uji" / "review-pr"

# Paket yang dibuat SEBELUM perbaikan F-12 (2026-09-18). Aturan 2 dilewati untuk
# berkas ini (isinya memang memuat jalur masa depan) — tetapi ATURAN 1 tetap berlaku.
# Paket yang dibuat setelah tanggal itu tidak punya pengecualian apa pun.
# Paket audit yang dibuat SEBELUM perbaikan berkas siap-tempel (2026-09-19). Berkas ini
# sudah di-commit dan TIDAK boleh disunting (aturan F-11), jadi aturan baru tidak berlaku surut
# untuk mereka; yang diperiksa adalah paket-paket sesudahnya.
LEGACY_SIAP_TEMPEL_SEBELUM = {
    "AUD-2-2026-09-17-SIAP-TEMPEL.md",
    "AUD-3-2026-09-17-SIAP-TEMPEL.md",
    "AUD-3-2026-09-18-SIAP-TEMPEL.md",
    "AUD-3-2026-09-19-SIAP-TEMPEL.md",
}

LEGACY_TANPA_ATURAN_ARTEFAK = {
    "AUD-2-2026-09-17.md",
    "AUD-2-2026-09-17-SIAP-TEMPEL.md",
    "AUD-3-2026-09-17.md",
    "AUD-3-2026-09-17-SIAP-TEMPEL.md",
    "AUD-3-2026-09-18.md",
    "AUD-3-2026-09-18-SIAP-TEMPEL.md",
    "PKT-2026-09-17-pr-01-putaran5.md",
    "PKT-2026-09-17-pr-01-putaran5-SIAP-TEMPEL.md",
    "PKT-2026-09-17-pr-01-putaran6.md",
    "PKT-2026-09-17-pr-01-putaran6-SIAP-TEMPEL.md",
    "PKT-2026-09-17-pr-01-putaran8.md",
    "PKT-2026-09-17-pr-01-putaran8-SIAP-TEMPEL.md",
    "PKT-2026-09-17-pr-01-putaran10.md",
    "PKT-2026-09-17-pr-01-putaran10-SIAP-TEMPEL.md",
    "PKT-2026-09-17-pr-01-putaran11.md",
    "PKT-2026-09-17-pr-01-putaran11-SIAP-TEMPEL.md",
    "PKT-2026-09-18-pr-01-putaran13.md",
    "PKT-2026-09-18-pr-01-putaran13-SIAP-TEMPEL.md",
}


def jalankan(perintah: list[str]) -> tuple[int, str]:
    hasil = subprocess.run(perintah, cwd=AKAR, capture_output=True, text=True)
    return hasil.returncode, (hasil.stdout + hasil.stderr).strip()


# ---- Aturan 3 (ditambahkan 2026-09-19) ----------------------------------------
# Setiap paket review PR yang terbit SEJAK tanggal di bawah ini WAJIB punya barisnya
# di `docs/uji/REVIEW_PR_RIWAYAT.md`.
#
# Kenapa: paket putaran13, putaran14, dan putaran15 terbit tanpa satu pun baris di
# riwayat itu (ditemukan 2026-09-19 saat menyiapkan putaran verifikasi). Akibatnya
# riwayat tampak "berhenti di putaran11" padahal review sudah berjalan tiga putaran
# lagi — pembaca/peninjau berikutnya bisa menyimpulkan paket itu tidak pernah ada,
# dan itu bahan temuan palsu. Tidak ada pemeriksa yang bisa MERAH untuk kelas ini.
RIWAYAT_REVIEW = AKAR / "docs" / "uji" / "REVIEW_PR_RIWAYAT.md"
SEJAK_RIWAYAT_WAJIB = "2026-09-19"  # paket bertanggal >= ini wajib tercatat
# Aturan 5 (2026-09-20, audit H F-02): paket bertanggal >= ini WAJIB menuliskan status CI commit
# targetnya. Kenapa: paket AUD-3 2026-09-19 menargetkan commit `4830b5a` yang dua run CI-nya
# `cancelled`, padahal protokol sudah mewajibkan "commit ber-CI hijau" — janji tanpa penegak.
SEJAK_CI_WAJIB = "2026-09-20"
POLA_CI_PAKET = re.compile(r"^-\s*\*\*CI commit target:\*\*\s*(.+)$", re.MULTILINE)
POLA_IZIN_CI = re.compile(r"^-\s*\*\*Izin pemilik untuk commit non-hijau:\*\*\s*(.+)$", re.MULTILINE)
POLA_PAKET_REVIEW = re.compile(r"^PKT-(\d{4}-\d{2}-\d{2})-pr-01-putaran(\d+)(?:-SIAP-TEMPEL)?\.md$")

# Aturan 6 — LINGKUP DARI POHON (B F-16, 2026-09-21). Paket audit menyeluruh yang lahir
# sejak tanggal ini wajib: (a) jumlah per grup SAMA dengan total tertulis (dulu grup `_sistem`
# tertulis 16 padahal 15); (b) total tertulis SAMA dengan hitungan ulang dari pohon commit
# target (dulu dihitung dari meja kerja — 333 dari 334, `supabase/README.md` lolos); (c) tidak
# ada berkas pohon yang tak-tertutup grup/pengecualian; (d) penanda berkas paket sendiri ada;
# (e) baris "belum berggrup" nol. Angka PER GRUP sengaja tidak dibandingkan satu-satu
# (definisi grup boleh bertambah di masa depan — yang dijamin: total & cakupan).
SEJAK_LINGKUP_POHON = "2026-09-21"
POLA_TOTAL_LINGKUP = re.compile(r"^- \*\*Jumlah berkas dalam lingkup:\*\* (\d+)", re.MULTILINE)
POLA_PENANDA_PAKET = re.compile(r"^- \*\*Berkas paket ini:\*\*", re.MULTILINE)
POLA_BIDANG_LINGKUP = re.compile(r"^## 0\. LINGKUP BIDANG: (\w+)", re.MULTILINE)

_PENGELOMPOK = None


def _muat_pengelompok():
    """Muat pengelompok dari `alat/audit-independen.py` (dipakai Aturan 6).

    Validator memakai DEFINISI grup yang sama dengan pembuat paket (bukan salinan) —
    kalau definisi berubah, validator ikut tanpa perlu disunting terpisah. Anti-lingkarnya:
    jangkar pohon mentah di `periksa_lingkup_pohon` (grup + pengecualian harus pas
    menghabiskan daftar `ls-tree`) + uji-diri membuktikan Aturan 6 bisa MENOLAK.
    """
    global _PENGELOMPOK
    if _PENGELOMPOK is None:
        import importlib.util
        sys.path.insert(0, str(AKAR / "alat"))
        lokasi = AKAR / "alat" / "audit-independen.py"
        spes = importlib.util.spec_from_file_location("audit_independen_f16", lokasi)
        modul = importlib.util.module_from_spec(spes)
        spes.loader.exec_module(modul)
        _PENGELOMPOK = (modul.kelompokkan_berkas, modul.cocok_bidang,
                        modul.BIDANG_PREFIKS, modul.DIKECUALIKAN)
    return _PENGELOMPOK


def periksa_lingkup_pohon(jalur: str, isi: str, sha: str | None) -> tuple[list[str], list[str]]:
    """Aturan 6 (B F-16): tabel lingkup §0 paket audit harus cocok dengan pohon commit target."""
    masalah: list[str] = []
    catatan: list[str] = []
    m_total = POLA_TOTAL_LINGKUP.search(isi)
    if not m_total:
        return masalah, [f"{jalur}: tanpa tabel lingkup §0 — Aturan 6 dilewati (bukan paket menyeluruh)"]
    if not sha:
        return masalah, [f"{jalur}: tanpa SHA target — Aturan 6 dilewati"]
    total_tertulis = int(m_total.group(1))
    # (a) jumlah per grup == total tertulis (menangkap angka tulis-tangan kelas `_sistem` 16-vs-15).
    awal = isi.find("**Grup berkas yang wajib kamu sentuh")
    akhir = isi.find("**Dikecualikan dari lingkup")
    grup_tertulis: dict[str, int] = {}
    if awal != -1 and akhir != -1 and awal < akhir:
        for baris in isi[awal:akhir].splitlines():
            sel = [c.strip() for c in baris.strip().strip("|").split("|")]
            if len(sel) < 3 or not sel[2].isdigit():
                continue
            grup_tertulis[sel[0]] = int(sel[2])
    if not grup_tertulis:
        masalah.append(f"{jalur}: F-16 — tabel grup §0 tidak terbaca (total tertulis {total_tertulis} tanpa rincian)")
        return masalah, catatan
    jumlah_grup = sum(grup_tertulis.values())
    if jumlah_grup != total_tertulis:
        masalah.append(
            f"{jalur}: F-16 — jumlah per grup ({jumlah_grup}) TIDAK SAMA dengan total tertulis ({total_tertulis}). "
            "Satu angka grup meleset (kelas `_sistem` 16-vs-15) atau ditulis tangan.")
    # (e) baris "belum berggrup" harus nol.
    if grup_tertulis.get("belum berggrup", 0) > 0:
        masalah.append(
            f"{jalur}: F-16 — {grup_tertulis['belum berggrup']} berkas 'belum berggrup': "
            "paket menyembunyikan berkas tak-tertutup.")
    # (d) penanda berkas paket sendiri.
    if not POLA_PENANDA_PAKET.search(isi):
        masalah.append(
            f"{jalur}: F-16 — tanpa penanda '- **Berkas paket ini:** …': paket tidak menyatakan "
            "berkasnya sendiri di luar hitungan.")
    # (b)+(c) hitung ulang dari pohon commit target.
    try:
        kelompokkan, cocok_bidang, BIDANG_PREFIKS, DIKECUALIKAN = _muat_pengelompok()
    except Exception as e:  # noqa: BLE001 — penjaga yang tidak bisa memeriksa harus GAGAL bersuara
        masalah.append(f"{jalur}: F-16 — pengelompok tidak bisa dimuat ({type(e).__name__}: {e})")
        return masalah, catatan
    kode_cat, _ = jalankan(["git", "cat-file", "-e", f"{sha}^{{commit}}"])
    if kode_cat != 0:
        # SHA hilang sudah dilaporkan blok F-11 — Aturan 6 tidak menambah ribut.
        catatan.append(f"{jalur}: commit target tidak ada di repo ini — Aturan 6(b/c) dilewati")
        return masalah, catatan
    try:
        grup, _dikecualikan = kelompokkan(sha)
    except SystemExit as e:
        masalah.append(f"{jalur}: F-16 — pohon commit target {sha[:8]} tidak bisa dibaca ({e})")
        return masalah, catatan
    m_bidang = POLA_BIDANG_LINGKUP.search(isi)
    bidang = None
    if m_bidang:
        bidang = m_bidang.group(1).lower()
        if bidang not in BIDANG_PREFIKS:
            catatan.append(f"{jalur}: bidang '{bidang}' tak dikenal — Aturan 6(b/c) dilewati")
            return masalah, catatan
        hitung = {n: [b for b in v if cocok_bidang(b, bidang)] for n, v in grup.items()}
    else:
        hitung = grup
    total_pohon = sum(len(v) for v in hitung.values())
    if total_pohon != total_tertulis:
        masalah.append(
            f"{jalur}: F-16 — total tertulis ({total_tertulis}) TIDAK SAMA dengan hitungan pohon "
            f"commit {sha[:8]} ({total_pohon}). Lingkup diambil dari meja kerja, bukan pohon target.")
    tak_tertutup = sorted(hitung.get("belum berggrup", []))
    if tak_tertutup:
        masalah.append(
            f"{jalur}: F-16 — {len(tak_tertutup)} berkas pohon TIDAK TERTUTUP grup mana pun: "
            f"{', '.join(tak_tertutup[:5])}{' …' if len(tak_tertutup) > 5 else ''}")
        return masalah, catatan
    # Jangkar independen: daftar mentah pohon harus habis dibagi grup + pengecualian
    # (menangkap bug pengelompok yang MENGHILANGKAN berkas — validator & pembuat paket memakai
    # fungsi yang sama, jadi tanpa jangkar ini keduanya bisa sepakat salah).
    kode, keluar_ls = jalankan(["git", "ls-tree", "-r", "--name-only", sha])
    if kode == 0:
        mentah = [b for b in keluar_ls.splitlines() if b.strip()]
        if bidang:
            mentah = [b for b in mentah if cocok_bidang(b, bidang)]
        tertutup = sum(len(v) for v in hitung.values()) + sum(
            1 for b in mentah
            if any(b == nama.rstrip("/") or b.startswith(nama) for nama, _ in DIKECUALIKAN))
        if tertutup != len(mentah):
            masalah.append(
                f"{jalur}: F-16 — jangkar pohon gagal: {len(mentah)} berkas pohon, tetapi grup + "
                f"pengecualian hanya menutup {tertutup}.")
            return masalah, catatan
    catatan.append(f"{jalur}: F-16 — lingkup §0 cocok dengan pohon {sha[:8]} "
                   f"(total {total_tertulis}, tak-tertutup: [])")
    return masalah, catatan


def periksa_riwayat(daftar: list[str]) -> list[str]:
    """Pastikan paket review baru tercatat di `docs/uji/REVIEW_PR_RIWAYAT.md`."""
    pesan: list[str] = []
    teks = RIWAYAT_REVIEW.read_text(encoding="utf-8") if RIWAYAT_REVIEW.is_file() else ""
    sudah: set[str] = set()
    for jalur in daftar:
        cocok = POLA_PAKET_REVIEW.match(pathlib.Path(jalur).name)
        if not cocok:
            continue
        tanggal, putaran = cocok.group(1), cocok.group(2)
        if tanggal < SEJAK_RIWAYAT_WAJIB or putaran in sudah:
            continue
        sudah.add(putaran)
        if f"putaran{putaran}" not in teks:
            pesan.append(
                f"paket review putaran{putaran} ({jalur}) tidak punya baris di "
                f"docs/uji/REVIEW_PR_RIWAYAT.md — setiap paket review wajib tercatat "
                f"(commit, jalur risiko, status laporan) supaya riwayat tidak bolong"
            )
    return pesan


def paket_terlacak() -> tuple[list[str], list[str]]:
    """(berkas yang diperiksa, berkas yang dilewati beserta alasannya).

    LAPORAN_* di docs/uji/review-pr adalah laporan REVIEWER (bukan paket) — di dalamnya
    `Commit yang direview` menunjuk ujung rentang PR, bukan induk commit berkasnya, jadi
    invariannya berbeda dan sengaja tidak diperiksa di sini.
    """
    _, keluaran = jalankan(["git", "ls-files", "docs/uji/paket-audit", "docs/uji/review-pr"])
    diperiksa: list[str] = []
    dilewati: list[str] = []
    for b in keluaran.splitlines():
        if not b.endswith(".md"):
            continue
        if pathlib.Path(b).name.startswith("LAPORAN_"):
            dilewati.append(b)
        else:
            diperiksa.append(b)
    return diperiksa, dilewati


def isi_pada(ref: str, jalur: str) -> str | None:
    kode, keluaran = jalankan(["git", "show", f"{ref}:{jalur}"])
    return keluaran if kode == 0 else None


def sha_diklaim(isi: str) -> str | None:
    m = re.search(r"\*\*Commit yang (?:diaudit|direview):\*\*\s*`([0-9a-f]{40})`", isi)
    return m.group(1) if m else None


def induk_dari_commit_terakhir(ref: str, jalur: str) -> tuple[str | None, str | None]:
    """(commit yang MENAMBAH paket ≤ ref, induknya) — dipakai uji-diri & pesan lama."""
    return _induk_commit(ref, jalur, tambah_saja=True)


def _induk_commit(ref: str, jalur: str, tambah_saja: bool) -> tuple[str | None, str | None]:
    perintah = ["git", "log"]
    if tambah_saja:
        perintah += ["--diff-filter=A"]
    perintah += ["-1", "--format=%H", ref, "--", jalur]
    kode, commit = jalankan(perintah)
    if kode != 0 or not commit.strip():
        return None, None
    commit = commit.strip().splitlines()[0]
    _, induk = jalankan(["git", "log", "-1", "--format=%P", commit])
    return commit, (induk.strip().split()[0] if induk.strip() else None)


def paket_ditulis_sah(ref: str, jalur: str, sha: str) -> bool | None:
    """Apakah paket ini pernah DITULIS tepat sesudah commit `sha` (isinya pun menargetkan `sha`)?

    Kenapa cara ini (pelajaran 2026-09-19): berkas paket sah ditulis lebih dari sekali dalam
    riwayatnya — paket dibuat, lalu disegarkan untuk commit berikutnya, lalu kadang disunting
    SESUDAHNYA untuk hal lain (mis. catatan provenance saat bahan kalibrasi dikeluarkan dari repo).
    Aturan lama ("commit yang TERAKHIR mengubah paket harus berinduk target") jadi rapuh: satu
    suntingan sah membuat 22 paket lama dituduh melanggar F-11 (palsu, tertangkap sapuan lokal &
    CI). Aturan "hanya commit penambah" menolak 13 paket lama. Yang benar: **ada** commit dalam
    riwayat yang menulis paket ini tepat sesudah commit target, dan isi paket saat itu menargetkan
    commit yang sama dengan isi sekarang — jadi target tidak bisa dipalsukan belakangan.

    Mengembalikan None bila riwayat tidak bisa dibaca (mis. klon dangkal) — pemanggil melewatkan.
    """
    kode, kel = jalankan(["git", "log", "--format=%H %P", ref, "--", jalur])
    if kode != 0:
        return None
    for baris in kel.splitlines():
        bagian = baris.split()
        if len(bagian) < 2 or bagian[1] != sha:
            continue
        isi = isi_pada(bagian[0], jalur)
        if isi and sha_diklaim(isi) == sha:
            return True
    return False


def jalur_bagian_1(isi: str) -> list[str]:
    """Ambil jalur berkas dari tabel '## 1. Artefak yang harus diperiksa'."""
    m = re.search(r"^## 1\. Artefak yang harus diperiksa.*?$", isi, re.M)
    if not m:
        return []
    sisa = isi[m.end():]
    akhir = re.search(r"^## ", sisa, re.M)
    bagian = sisa[: akhir.start()] if akhir else sisa
    jalur: list[str] = []
    for baris in bagian.splitlines():
        if not baris.strip().startswith("|"):
            continue
        for tok in re.findall(r"`([^`]+)`", baris):
            tok = tok.strip()
            if "/" in tok and " " not in tok and not tok.startswith("git "):
                jalur.append(tok)
    return jalur


def periksa_paket(ref: str, jalur: str, isi: str | None = None,
                  abaikan_pengecualian: bool = False) -> tuple[list[str], list[str]]:
    """Kembalikan (masalah, catatan) untuk satu berkas paket pada `ref`."""
    masalah: list[str] = []
    catatan: list[str] = []
    isi = isi if isi is not None else isi_pada(ref, jalur)
    if isi is None:
        return [f"{jalur}: tidak bisa dibaca pada {ref}"], catatan

    sha = sha_diklaim(isi)
    if not sha:
        masalah.append(f"{jalur}: tidak menulis '**Commit yang diaudit/direview:** <sha 40 digit>'")
    else:
        _, induk_terakhir = _induk_commit(ref, jalur, tambah_saja=False)
        sah = paket_ditulis_sah(ref, jalur, sha)
        if sah is False:
            masalah.append(
                f"{jalur}: F-11 — tidak ada commit dalam riwayat yang menulis paket ini tepat sesudah "
                f"commit target {sha[:8]} (penulis terakhir berinduk "
                f"{induk_terakhir[:8] if induk_terakhir else '?'}). Auditor akan memeriksa pohon yang "
                "berbeda dari yang dimaksud."
            )
        kode, _ = jalankan(["git", "cat-file", "-e", f"{sha}^{{commit}}"])
        if kode != 0:
            masalah.append(f"{jalur}: commit {sha[:8]} yang ditulis paket TIDAK ADA di repo ini")

    nama = pathlib.Path(jalur).name
    # ATURAN BARU (2026-09-19, cacat nyata): berkas `<paket>-SIAP-TEMPEL.md` adalah SATU-SATUNYA
    # yang disalin Lee ke chat auditor. Dua cacat nyata pernah terjadi: (a) kalimat pembukanya
    # masih memuat baris kosong `<<< TEMPEL ISI … >>>` sehingga auditor berhenti di langkah 1;
    # (b) tidak ada petunjuk cara MENGAMBIL BAHAN, padahal sesi auditor baru bercabang dari `main`
    # yang hanya memuat kerangka — auditor lalu melaporkan "audit TERBLOKIR" (kejadian nyata
    # 2026-09-19, sesi `arena/01a0b9f2`). Karena itu berkas siap-tempel diperiksa mesin.
    if (nama.endswith("-SIAP-TEMPEL.md") and "/paket-audit/" in jalur
            and nama not in LEGACY_SIAP_TEMPEL_SEBELUM):
        if "<<<" in isi:
            masalah.append(
                f"{jalur}: masih memuat penanda kosong `<<< … >>>` — berkas siap-tempel harus utuh; "
                "auditor akan berhenti karena menyangka paketnya belum diisi"
            )
        if "SAMBUNGAN: PAKET AUDIT" not in isi:
            masalah.append(f"{jalur}: tidak memuat bagian 'SAMBUNGAN: PAKET AUDIT' (paketnya tidak ikut tersalin)")
        pembuka_st = isi.split("SAMBUNGAN: PAKET AUDIT")[0]
        if "git fetch origin" not in pembuka_st or "git checkout --detach" not in pembuka_st:
            masalah.append(
                f"{jalur}: bagian PEMBUKA tidak memuat cara MENGAMBIL BAHAN (perintah git fetch origin + "
                "git checkout --detach); sesi auditor baru bercabang dari main dan tanpa perintah itu "
                "ia berhenti di langkah 1 (protokol tidak ada) — kejadian nyata 2026-09-19"
            )
        if "protokol" in isi and "PROTOKOL_AUDIT_INDEPENDEN.md" not in isi:
            masalah.append(f"{jalur}: menyebut protokol tanpa menunjuk berkasnya")

    # ATURAN 5 — BUKTI CI PADA COMMIT TARGET (audit H F-02, 2026-09-20).
    # Paket yang lahir sejak tanggal ini wajib menyatakan status CI commit targetnya; status
    # "belum hijau" hanya boleh dipakai bila ada izin pemilik yang ditulis di paket (keputusan
    # pemilik tetap boleh mengecualikan, tetapi tidak boleh diam-diam).
    tanggal = re.search(r"(\d{4}-\d{2}-\d{2})", nama)
    if tanggal and tanggal.group(1) >= SEJAK_CI_WAJIB:
        m_ci = POLA_CI_PAKET.search(isi)
        if not m_ci:
            masalah.append(
                f"{jalur}: F-02 — tidak menulis status CI commit target. Paket yang menargetkan commit "
                "tanpa CI hijau membuat auditor memeriksa pohon yang tidak pernah lewat gerbang otomatis. "
                "Tambahkan baris '- **CI commit target:** success (run <id>) …' (dibuat otomatis oleh "
                "`alat/audit-independen.py --paket` / `alat/review-pr.py --siapkan`)."
            )
        else:
            nilai = m_ci.group(1).strip()
            if not re.search(r"\bsuccess\b", nilai, re.IGNORECASE) and "BELUM-HIJAU" not in nilai:
                masalah.append(f"{jalur}: F-02 — status CI tidak dikenali: '{nilai[:60]}' (harus memuat 'success')")
            if not re.search(r"\bsuccess\b", nilai, re.IGNORECASE) and not POLA_IZIN_CI.search(isi):
                masalah.append(
                    f"{jalur}: F-02 — paket menargetkan commit yang CI-nya BELUM hijau / tidak bisa diperiksa, "
                    "tanpa izin pemilik. Tulis '- **Izin pemilik untuk commit non-hijau:** <kalimat izin>' "
                    "atau pilih commit yang CI-nya sudah hijau."
                )
            elif not re.search(r"\bsuccess\b", nilai, re.IGNORECASE):
                catatan.append(f"{jalur}: menargetkan commit non-hijau DENGAN izin pemilik (dikecualikan sadar)")
            # Silang-periksa ke GitHub bila sha target ada & gh tersedia: klaim 'success' yang tidak
            # cocok dengan kenyataan adalah kelas cacat yang sama dengan angka bukti basi.
            # SHA yang diperiksa = SHA yang disebut DI BARIS CI (commit target menurut paket);
            # kalau baris itu tidak menyebut SHA, pakai SHA target paket.
            m_sha_baris = re.search(r"\b([0-9a-f]{40})\b", nilai)
            sha_dicek = m_sha_baris.group(1) if m_sha_baris else sha
            if m_sha_baris and sha_dicek != sha:
                masalah.append(
                    f"{jalur}: F-02 — SHA pada baris CI ({sha_dicek[:12]}…) berbeda dari "
                    f"commit target paket ({sha[:12]}…); bukti CI milik commit lain tidak boleh dipakai"
                )
            if sha_dicek == sha and "success" in nilai.lower():
                try:
                    sys.path.insert(0, str(AKAR / "alat"))
                    import ci_target  # noqa: PLC0415 — impor lokal supaya CI tanpa gh tetap jalan
                    st = ci_target.status_ci(sha_dicek, AKAR)
                    if st["bisa"] and not st["hijau"]:
                        masalah.append(
                            f"{jalur}: F-02 — paket mengklaim CI hijau, tetapi GitHub berkata sebaliknya "
                            f"({st['rincian']}) untuk commit {sha_dicek[:8]}"
                        )
                    elif not st["bisa"]:
                        catatan.append(f"{jalur}: status CI tidak bisa diverifikasi dari sini ({st['rincian']})")
                    else:
                        catatan.append(f"{jalur}: CI commit target terverifikasi ke GitHub ({st['rincian']})")
                except Exception as e:  # noqa: BLE001 — pemeriksaan tambahan tidak boleh mematikan penjaga
                    catatan.append(f"{jalur}: silang-periksa CI dilewati ({type(e).__name__})")

    # ATURAN 6 — LINGKUP DARI POHON (B F-16, 2026-09-21). Hanya paket audit di bawah
    # /paket-audit/ (paket review tidak punya tabel grup) yang lahir sejak tanggalnya.
    if tanggal and tanggal.group(1) >= SEJAK_LINGKUP_POHON and "/paket-audit/" in jalur:
        m6, c6 = periksa_lingkup_pohon(jalur, isi, sha)
        masalah += m6
        catatan += c6

    if nama in LEGACY_TANPA_ATURAN_ARTEFAK and not abaikan_pengecualian:
        catatan.append(f"{jalur}: aturan artefak dilewati (paket lama sebelum perbaikan F-12)")
        return masalah, catatan
    if nama.startswith("PKT-"):
        # Paket review PR: tidak punya daftar artefak minimum, cukup invarian commit.
        catatan.append(f"{jalur}: paket review — hanya invarian commit yang diperiksa")
        return masalah, catatan
    if not sha:
        return masalah, catatan
    jalur_1 = jalur_bagian_1(isi)
    if not jalur_1:
        masalah.append(f"{jalur}: bagian 1 (artefak minimum) tidak memuat satu pun jalur berkas")
        return masalah, catatan
    hilang = []
    daftar_pohon: list[str] | None = None  # dimuat malas hanya bila ada pola glob
    for j in sorted(set(jalur_1)):
        if any(c in j for c in "*?["):
            # Entri "pola" (audit I F-20): pola sah bila cocok >=1 berkas di commit target.
            # Cacat nyata 2026-09-20: pola diperiksa sebagai nama harfiah sehingga paket
            # sah ditolak ("berkas *.tsx TIDAK ADA") padahal polanya cocok 13 berkas.
            if daftar_pohon is None:
                _, keluar_ls = jalankan(["git", "ls-tree", "-r", "--name-only", sha])
                daftar_pohon = keluar_ls.splitlines()
            if not any(fnmatch.fnmatchcase(b, j) for b in daftar_pohon):
                hilang.append(j)
            continue
        kode, _ = jalankan(["git", "cat-file", "-e", f"{sha}:{j}"])
        if kode != 0:
            hilang.append(j)
    if hilang:
        masalah.append(
            f"{jalur}: F-12 — {len(hilang)} dari {len(set(jalur_1))} jalur di bagian 1 TIDAK ADA "
            f"di commit {sha[:8]}: {', '.join(hilang[:5])}{' …' if len(hilang) > 5 else ''}"
        )
    else:
        catatan.append(f"{jalur}: bagian 1 bersih ({len(set(jalur_1))} jalur, semuanya ada di {sha[:8]})")
    return masalah, catatan


def periksa(ref: str = "HEAD", berkas: list[str] | None = None) -> int:
    daftar, dilewati = (berkas, []) if berkas is not None else paket_terlacak()
    if not daftar:
        print("TIDAK ADA paket terlacak di docs/uji/paket-audit atau docs/uji/review-pr")
        return 0
    masalah: list[str] = []
    catatan: list[str] = []
    for jalur in daftar:
        m, c = periksa_paket(ref, jalur)
        masalah += m
        catatan += c
    masalah += periksa_riwayat(daftar)
    for c in catatan:
        print(f"  [catatan] {c}")
    if dilewati:
        print(f"  [catatan] {len(dilewati)} laporan reviewer dilewati (invariannya berbeda: menunjuk ujung rentang PR)")
    for m in masalah:
        print(f"  [X] {m}")
    print("-" * 70)
    print(f"PERIKSA PAKET — {len(daftar)} paket terlacak (ref {ref})")
    if masalah:
        print(f"HASIL: GAGAL — {len(masalah)} pelanggaran invarian paket (F-11/F-12 + riwayat)")
        return 1
    print("HASIL: LOLOS — setiap paket menunjuk induk commit-nya sendiri, artefaknya nyata, dan paket review baru tercatat di riwayat.")
    return 0


def uji_diri() -> int:
    """Buktikan pemeriksa ini bisa MENOLAK, memakai paket nyata dari riwayat repo.

    Kasus 1 (harus GAGAL): paket AUD-3 2026-09-18 pada commit `d1f11d7` — versi itu
    memuat 267 jalur yang tidak ada di commit yang diaudit (temuan audit F-12 nyata).
    Kasus 2 (harus LOLOS): pohon sekarang.
    """
    hasil: list[tuple[str, bool, str]] = []

    kode, _ = jalankan(["git", "cat-file", "-e", "d1f11d7f32bdb78b14b6ed4d935946c515c656df^{commit}"])
    if kode != 0:
        print("LEWAT: commit sejarah d1f11d7 tidak ada di repo ini (klon dangkal?)")
        return 0
    isi_lama = isi_pada("d1f11d7", "docs/uji/paket-audit/AUD-3-2026-09-18.md")
    if isi_lama is None:
        print("LEWAT: versi paket di d1f11d7 tidak bisa dibaca")
        return 0
    masalah, _ = periksa_paket("d1f11d7", "docs/uji/paket-audit/AUD-3-2026-09-18.md", isi=isi_lama,
                               abaikan_pengecualian=True)
    hasil.append(("paket lama d1f11d7 (267 jalur hantu) ditolak", bool(masalah),
                  masalah[0][:90] if masalah else "DILOLOSKAN (tumpul)"))

    # Mutasi ringan: ubah SHA di salinan paket sekarang → aturan 1 harus menolak.
    sekarang = paket_terlacak()[0]
    if sekarang:
        jalur = sekarang[0]
        isi = isi_pada("HEAD", jalur) or ""
        m_sha = sha_diklaim(isi)
        if m_sha:
            palsu = isi.replace(m_sha, "0" * 40, 1)
            masalah_palsu, _ = periksa_paket("HEAD", jalur, isi=palsu, abaikan_pengecualian=True)
            hasil.append(("mutasi: SHA di paket diganti SHA palsu", bool(masalah_palsu),
                          masalah_palsu[0][:90] if masalah_palsu else "DILOLOSKAN (tumpul)"))
            # Mutasi: jalur hantu ditambahkan ke bagian 1 → aturan 2 harus menolak.
            m = re.search(r"^## 1\. Artefak yang harus diperiksa.*?$", isi, re.M)
            if m:
                hantu = isi[: m.end()] + "\n\n| 999 | `supabase/tes/uji-hantu-yang-tidak-ada.sql` |\n" + isi[m.end():]
                masalah_hantu, _ = periksa_paket("HEAD", jalur, isi=hantu, abaikan_pengecualian=True)
                masalah_hantu = [x for x in masalah_hantu if "F-12" in x] or masalah_hantu
                hasil.append(("mutasi: jalur hantu ditambahkan ke bagian 1", bool(masalah_hantu),
                              masalah_hantu[0][:90] if masalah_hantu else "DILOLOSKAN (tumpul)"))
                # Mutasi: pola glob hantu (tidak cocok berkas apa pun di commit) → tetap ditolak.
                # Buktikan perluasan pola tidak membuat penjaga tumpul (2026-09-20).
                hantu_glob = isi[: m.end()] + "\n\n| 998 | `supabase/tes/hantu-tak-ada*.sql` |\n" + isi[m.end():]
                masalah_glob, _ = periksa_paket("HEAD", jalur, isi=hantu_glob, abaikan_pengecualian=True)
                masalah_glob = [x for x in masalah_glob if "F-12" in x] or masalah_glob
                hasil.append(("mutasi: pola glob hantu ditambahkan ke bagian 1", bool(masalah_glob),
                              masalah_glob[0][:90] if masalah_glob else "DILOLOSKAN (tumpul)"))

    # Aturan 4 (siap-tempel): buktikan bisa MENOLAK placeholder & petunjuk-ambil-bahan yang hilang.
    siap_tempel = [j for j in sekarang
                   if j.endswith("-SIAP-TEMPEL.md") and "/paket-audit/" in j
                   and pathlib.Path(j).name not in LEGACY_SIAP_TEMPEL_SEBELUM]
    if siap_tempel:
        jalur_st = siap_tempel[-1]
        isi_st = isi_pada("HEAD", jalur_st) or ""
        if "<<<" not in isi_st and "git fetch origin" in isi_st:
            m_ph = isi_st.replace("— paket lengkapnya ada di bagian", "<<< TEMPEL ISI docs/uji/paket-audit/… DI SINI >>>\n— paket lengkapnya ada di bagian", 1)
            masalah_ph, _ = periksa_paket("HEAD", jalur_st, isi=m_ph, abaikan_pengecualian=True)
            masalah_ph = [x for x in masalah_ph if "penanda kosong" in x] or masalah_ph
            hasil.append(("mutasi: penanda kosong <<< dimasukkan lagi ke berkas siap-tempel", bool(masalah_ph),
                          masalah_ph[0][:90] if masalah_ph else "DILOLOSKAN (tumpul)"))
            m_fetch = isi_st.replace("git fetch origin", "git ambil origin")
            masalah_fetch, _ = periksa_paket("HEAD", jalur_st, isi=m_fetch, abaikan_pengecualian=True)
            masalah_fetch = [x for x in masalah_fetch if "MENGAMBIL BAHAN" in x] or masalah_fetch
            hasil.append(("mutasi: petunjuk mengambil bahan dihapus dari berkas siap-tempel", bool(masalah_fetch),
                          masalah_fetch[0][:90] if masalah_fetch else "DILOLOSKAN (tumpul)"))
        else:
            print("LEWAT: berkas siap-tempel belum memuat penanda/ambil-bahan (cek urutan kerja)")

    masalah_pohon: list[str] = []
    for jalur in sekarang:
        m, _ = periksa_paket("HEAD", jalur)
        masalah_pohon += m
    hasil.append(("pohon sekarang diterima", not masalah_pohon,
                  "lolos" if not masalah_pohon else masalah_pohon[0][:90]))

    # Aturan 5 (F-02): paket bertanggal >= SEJAK_CI_WAJIB wajib menulis status CI commit target.
    isi_uji = isi_pada("HEAD", sekarang[0]) if sekarang else None
    if isi_uji:
        jalur_uji = "docs/uji/paket-audit/AUD-3-2099-01-01-uji-ci.md"
        # (a) tanpa baris CI sama sekali → harus DITOLAK
        tanpa_ci = re.sub(r"^-\s*\*\*CI commit target:\*\*.*$\n?", "", isi_uji, flags=re.MULTILINE)
        m_semua, _ = periksa_paket("HEAD", jalur_uji, isi=tanpa_ci, abaikan_pengecualian=True)
        # STRICT: harus ditolak DENGAN ALASAN F-02. Kalau pemeriksa menolak karena sebab lain
        # (mis. F-11 soal riwayat commit), itu bukan bukti aturan F-02 bekerja — pelajaran dari
        # temuan I F-04 (classifier yang menerima kegagalan apa pun sebagai "pagar bekerja").
        m_ci = [x for x in m_semua if "F-02" in x]
        hasil.append(("mutasi: paket baru tanpa bukti CI commit target (alasan harus F-02)", bool(m_ci),
                      m_ci[0][:90] if m_ci else f"TIDAK DITOLAK DENGAN ALASAN F-02 (alasan lain: {m_semua[0][:60] if m_semua else '-'})"))
        # (b) SHA pada baris CI berbeda dari SHA target paket → harus DITOLAK
        # sebelum API; status hijau commit lain bukan bukti target (B-F09).
        m_sha_target = sha_diklaim(isi_uji)
        if m_sha_target:
            sha_lain = "f" * 40
            klaim_sha_lain = (tanpa_ci
                              + f"\n- **CI commit target:** success (run 888888) — diperiksa mesin terhadap commit `{sha_lain}`\n")
            m_lain_semua, _ = periksa_paket("HEAD", jalur_uji, isi=klaim_sha_lain, abaikan_pengecualian=True)
            m_lain = [x for x in m_lain_semua if "SHA pada baris CI" in x]
            hasil.append(("mutasi: bukti CI menyebut SHA berbeda dari target (alasan harus F-02)", bool(m_lain),
                          m_lain[0][:90] if m_lain else "TIDAK DITOLAK (tumpul)"))
        # (c) klaim 'success' padahal commit target CI-nya TIDAK hijau → harus DITOLAK.
        #     SHA-nya dicari dinamis: ambil beberapa commit terakhir cabang ini, pilih yang
        #     status CI-nya benar-benar bukan success (mis. run yang ditimpa push berikutnya).
        sys.path.insert(0, str(AKAR / "alat"))
        try:
            import ci_target  # noqa: PLC0415
            kode_gh, keluaran_gh = jalankan(["git", "log", "--format=%H", "-n", "12"])
            sha_tidak_hijau = None
            for sha_kandidat in [s for s in keluaran_gh.split() if len(s) == 40]:
                st = ci_target.status_ci(sha_kandidat, AKAR)
                if st.get("bisa") and not st.get("hijau"):
                    sha_tidak_hijau = sha_kandidat
                    break
        except Exception:  # noqa: BLE001
            sha_tidak_hijau = None
        if sha_tidak_hijau and m_sha_target:
            # Jadikan SHA non-hijau itu sebagai TARGET paket juga; kalau hanya
            # mengganti baris CI, B-F09 memang yang bekerja lebih dulu.
            target_nonhijau = tanpa_ci.replace(m_sha_target, sha_tidak_hijau)
            klaim_palsu = (target_nonhijau
                           + f"\n- **CI commit target:** success (run 999999) — diperiksa mesin terhadap commit `{sha_tidak_hijau}`\n")
            m_palsu_semua, _ = periksa_paket("HEAD", jalur_uji, isi=klaim_palsu, abaikan_pengecualian=True)
            m_palsu = [x for x in m_palsu_semua if "F-02" in x and "sebaliknya" in x]
            hasil.append((f"mutasi: paket mengklaim CI hijau padahal tidak ({sha_tidak_hijau[:7]})",
                          bool(m_palsu),
                          m_palsu[0][:90] if m_palsu else "TIDAK DITOLAK DENGAN ALASAN F-02 (tumpul)"))
        else:
            print("LEWAT: tidak ada commit non-hijau yang bisa dipakai / gh tidak tersedia — "
                  "silang-periksa CI dilewati di uji-diri")

    # Aturan 6 (F-16): tabel lingkup §0 harus cocok dengan pohon commit target.
    # Basis = paket nyata BERTABEL lingkup-penuh + jalur-tanggal palsu 2099 (pola uji F-02):
    # nama palsu mengaktifkan gerbang tanggal tanpa menyentuh riwayat git.
    try:
        kelompokkan6, cocok6, BIDANG6, _ = _muat_pengelompok()
    except Exception as e:  # noqa: BLE001 — impor gagal = Aturan 6 mati, harus bersuara
        hasil.append(("Aturan 6: pengelompok termuat", False, f"{type(e).__name__}: {e}"))
        kelompokkan6 = None
    basis_6 = None
    ada_tabel_6 = False
    objek_tersedia_6 = False
    if kelompokkan6 is not None:
        for j in sekarang:
            if j.endswith("-SIAP-TEMPEL.md") or "/paket-audit/" not in j:
                continue
            kandidat = isi_pada("HEAD", j) or ""
            if "- **Jumlah berkas dalam lingkup:**" not in kandidat:
                continue
            ada_tabel_6 = True
            if "## 0. LINGKUP BIDANG:" in kandidat:
                continue  # varian bidang diuji terpisah dari basis penuh
            sha_k = sha_diklaim(kandidat)
            if not sha_k:
                continue
            try:
                grup_k, _ = kelompokkan6(sha_k)
            except (SystemExit, Exception):  # noqa: BLE001 — pohon target tak ada (klon dangkal?)
                continue
            objek_tersedia_6 = True
            awal_k = kandidat.find("**Grup berkas yang wajib kamu sentuh")
            akhir_k = kandidat.find("**Dikecualikan dari lingkup")
            if awal_k == -1 or akhir_k == -1:
                continue
            # tabel lama harus punya baris untuk setiap grup berisi-berkas hari ini
            tabel_k = kandidat[awal_k:akhir_k]
            if any(len(v) > 0 and f"| {n} |" not in tabel_k for n, v in grup_k.items()):
                continue
            basis_6 = (kandidat, sha_k, grup_k, awal_k, akhir_k)
            break
    if basis_6 is None:
        if kelompokkan6 is None:
            pass  # impor gagal sudah dicatat sebagai hasil GAGAL di atas
        elif not sekarang:
            print("LEWAT: tidak ada paket — uji Aturan 6 dilewati")
        elif not ada_tabel_6:
            print("LEWAT: tidak ada paket bertabel §0 — uji Aturan 6 dilewati")
        elif not objek_tersedia_6:
            print("LEWAT: pohon target tak terbaca (klon dangkal?) — uji Aturan 6 dilewati")
        else:
            # Paket bertabel ADA dan pohonnya TERBACA, tetapi formatnya tak cocok: ujinya yang
            # basi (bukan lingkungannya) — diam = menyembunyikan. Pernah kejadian nyata saat
            # Aturan 6 ditulis (penanda akhir salah — untung tertangkap sebelum commit).
            hasil.append(("Aturan 6: basis paket bertabel terbaca", False,
                          "format tabel §0 tak cocok — sesuaikan uji Aturan 6"))
    else:
        isi_6, sha_6, grup6, awal6, akhir6 = basis_6
        jalur_6 = "docs/uji/paket-audit/AUD-3-2099-01-01-uji-lingkup.md"
        kepala6, tabel6, ekor6 = isi_6[:awal6], isi_6[awal6:akhir6], isi_6[akhir6:]
        # m1: satu angka grup ditulis tangan (+1) → jumlah ≠ total → DITOLAK (alasan F-16).
        tabel_m1, n1 = re.subn(r"(\| [^|\n]+ \| [^|\n]* \| )(\d+)( \|)",
                               lambda m: f"{m.group(1)}{int(m.group(2)) + 1}{m.group(3)}",
                               tabel6, count=1)
        if n1 == 0:
            print("LEWAT: baris grup tak terbaca — mutasi m1 dilewati")
        else:
            m_m1, _ = periksa_paket("HEAD", jalur_6, isi=kepala6 + tabel_m1 + ekor6,
                                    abaikan_pengecualian=True)
            m_m1 = [x for x in m_m1 if "F-16" in x and "jumlah per grup" in x]
            hasil.append(("mutasi: satu angka grup ditulis tangan (alasan harus F-16/jumlah)", bool(m_m1),
                          m_m1[0][:90] if m_m1 else "TIDAK DITOLAK DENGAN ALASAN F-16 (tumpul)"))
        # kontrol+: bangun tabel VALID dari hitungan ulang pohon → TANPA alasan F-16.
        # (Bukti Aturan 6 bisa lolos — tanpa ini, penolakan m1/m2/m4 bisa berarti "selalu menolak".)
        tabel_valid = tabel6
        for nama_g, berkas_g in grup6.items():
            pola_baris = re.compile(r"(\| " + re.escape(nama_g) + r" \| [^|\n]* \| )(\d+)( \|)")
            tabel_valid = pola_baris.sub(
                lambda m: f"{m.group(1)}{len(berkas_g)}{m.group(3)}", tabel_valid, count=1)
        total_pohon6 = sum(len(v) for v in grup6.values())
        kepala_valid = re.sub(r"- \*\*Jumlah berkas dalam lingkup:\*\* \d+",
                              f"- **Jumlah berkas dalam lingkup:** {total_pohon6}", kepala6, count=1)
        if "- **Berkas paket ini:**" not in kepala_valid:
            kepala_valid = kepala_valid.replace(
                f"- **Jumlah berkas dalam lingkup:** {total_pohon6}",
                f"- **Jumlah berkas dalam lingkup:** {total_pohon6}\n"
                "- **Berkas paket ini:** `docs/uji/paket-audit/AUD-3-2099-01-01-uji-lingkup.md` "
                "dibuat SETELAH angka di atas dihitung — ia TIDAK masuk hitungan.", 1)
        isi_valid = kepala_valid + tabel_valid + ekor6
        m_valid, _ = periksa_paket("HEAD", jalur_6, isi=isi_valid, abaikan_pengecualian=True)
        m_f16_valid = [x for x in m_valid if "F-16" in x]
        hasil.append(("kontrol: tabel lingkup valid dari pohon DITERIMA Aturan 6 (tanpa alasan F-16)",
                      not m_f16_valid,
                      "diterima" if not m_f16_valid else m_f16_valid[0][:90]))
        # m2: total +7 & satu grup +7 (jumlah konsisten!) → hanya (b) yang boleh menolak.
        kepala_m2 = re.sub(r"(\*\*Jumlah berkas dalam lingkup:\*\* )(\d+)",
                            lambda m: f"{m.group(1)}{int(m.group(2)) + 7}", kepala_valid, count=1)
        tabel_m2, _ = re.subn(r"(\| [^|\n]+ \| [^|\n]* \| )(\d+)( \|)",
                              lambda m: f"{m.group(1)}{int(m.group(2)) + 7}{m.group(3)}",
                              tabel_valid, count=1)
        m_m2, _ = periksa_paket("HEAD", jalur_6, isi=kepala_m2 + tabel_m2 + ekor6,
                                abaikan_pengecualian=True)
        m_m2 = [x for x in m_m2 if "F-16" in x and "hitungan pohon" in x]
        hasil.append(("mutasi: total konsisten-tapi-beda-pohon +7 (alasan harus F-16/pohon)", bool(m_m2),
                      m_m2[0][:90] if m_m2 else "TIDAK DITOLAK DENGAN ALASAN F-16 (tumpul)"))
        # m3b: penanda berkas paket dihapus dari tabel valid → DITOLAK (alasan penanda).
        isi_m3b = re.sub(r"^- \*\*Berkas paket ini:\*\*.*$\n?", "", isi_valid, flags=re.MULTILINE)
        m_m3b, _ = periksa_paket("HEAD", jalur_6, isi=isi_m3b, abaikan_pengecualian=True)
        m_m3b = [x for x in m_m3b if "F-16" in x and "Berkas paket ini" in x]
        hasil.append(("mutasi: penanda berkas paket dihapus (alasan harus F-16/penanda)", bool(m_m3b),
                      m_m3b[0][:90] if m_m3b else "TIDAK DITOLAK DENGAN ALASAN F-16 (tumpul)"))
        # m4: baris "belum berggrup" berisi 3 (total disesuaikan +3 supaya hanya (e) yang bicara).
        if "| belum berggrup |" in tabel_valid:
            tabel_m4 = re.sub(r"(\| belum berggrup \| [^|\n]* \| )(\d+)( \|)",
                              lambda m: f"{m.group(1)}3{m.group(3)}", tabel_valid, count=1)
        else:
            tabel_m4 = tabel_valid + "| belum berggrup | disuntik uji | 3 |  |\n"
        kepala_m4 = re.sub(r"(\*\*Jumlah berkas dalam lingkup:\*\* )(\d+)",
                            lambda m: f"{m.group(1)}{int(m.group(2)) + 3}", kepala_valid, count=1)
        m_m4, _ = periksa_paket("HEAD", jalur_6, isi=kepala_m4 + tabel_m4 + ekor6,
                                abaikan_pengecualian=True)
        m_m4 = [x for x in m_m4 if "F-16" in x and "belum berggrup" in x]
        hasil.append(("mutasi: baris 'belum berggrup' berisi 3 (alasan harus F-16/grup)", bool(m_m4),
                      m_m4[0][:90] if m_m4 else "TIDAK DITOLAK DENGAN ALASAN F-16 (tumpul)"))
        # bidang: varian KEAMANAN dengan angka saring-bidang → DITERIMA (tanpa F-16).
        if "keamanan" in BIDANG6:
            grup_bid = {n: [b for b in v if cocok6(b, "keamanan")] for n, v in grup6.items()}
            tabel_bid = tabel_valid
            for nama_g, berkas_g in grup_bid.items():
                pola_baris = re.compile(r"(\| " + re.escape(nama_g) + r" \| [^|\n]* \| )(\d+)( \|)")
                tabel_bid = pola_baris.sub(
                    lambda m: f"{m.group(1)}{len(berkas_g)}{m.group(3)}", tabel_bid, count=1)
            total_bid = sum(len(v) for v in grup_bid.values())
            kepala_bid = re.sub(r"- \*\*Jumlah berkas dalam lingkup:\*\* \d+",
                                f"- **Jumlah berkas dalam lingkup:** {total_bid}", kepala_valid, count=1)
            isi_bid = re.sub(r"^## 0\. LINGKUP MENYELURUH.*$",
                             "## 0. LINGKUP BIDANG: KEAMANAN (uji)", kepala_bid + tabel_bid + ekor6,
                             count=1, flags=re.MULTILINE)
            m_bid, _ = periksa_paket("HEAD", jalur_6, isi=isi_bid, abaikan_pengecualian=True)
            m_f16_bid = [x for x in m_bid if "F-16" in x]
            hasil.append(("kontrol: varian bidang KEAMANAN valid DITERIMA Aturan 6", not m_f16_bid,
                          "diterima" if not m_f16_bid else m_f16_bid[0][:90]))
        # bidang tak dikenal → (b/c) dilewati TANPA alasan F-16 (menolak agresif = landmine bagi bidang baru).
        isi_asing = re.sub(r"^## 0\. LINGKUP MENYELURUH.*$",
                           "## 0. LINGKUP BIDANG: ZZZZTIDAKADA (uji)", isi_valid,
                           count=1, flags=re.MULTILINE)
        m_asing, _ = periksa_paket("HEAD", jalur_6, isi=isi_asing, abaikan_pengecualian=True)
        m_f16_asing = [x for x in m_asing if "F-16" in x]
        hasil.append(("kontrol: bidang tak dikenal tidak memicu F-16", not m_f16_asing,
                      "dilewati" if not m_f16_asing else m_f16_asing[0][:90]))

    # Aturan 3: paket review baru tanpa baris riwayat wajib DITOLAK; yang tercatat diterima.
    masalah_riwayat = periksa_riwayat(["docs/uji/review-pr/PKT-2026-09-19-pr-01-putaran99.md"])
    hasil.append(("mutasi: paket review baru tanpa baris riwayat ditolak", bool(masalah_riwayat),
                  masalah_riwayat[0][:90] if masalah_riwayat else "DILOLOSKAN (tumpul)"))
    kontrol_riwayat = periksa_riwayat(["docs/uji/review-pr/PKT-2026-09-19-pr-01-putaran16.md"])
    hasil.append(("kontrol: paket review yang TERCATAT di riwayat diterima", not kontrol_riwayat,
                  "diterima" if not kontrol_riwayat else kontrol_riwayat[0][:90]))

    print("UJI-DIRI periksa-paket")
    gagal = 0
    for kasus, sesuai, ringkas in hasil:
        tanda = "OK " if sesuai else "X  "
        if not sesuai:
            gagal += 1
        print(f"  {tanda} {kasus} → {ringkas}")
    if gagal:
        print(f"\nHASIL: GAGAL — {gagal} kasus uji-diri tidak sesuai harapan (pemeriksa mungkin tumpul)")
        return 1
    print("\nHASIL: LOLOS — pemeriksa terbukti bisa MENOLAK paket cacat dan MENERIMA yang utuh.")
    return 0


def main() -> int:
    if "--uji-diri" in sys.argv:
        return uji_diri()
    ref = "HEAD"
    berkas = None
    if "--ref" in sys.argv:
        ref = sys.argv[sys.argv.index("--ref") + 1]
    if "--berkas" in sys.argv:
        berkas = sys.argv[sys.argv.index("--berkas") + 1:]
    return periksa(ref, berkas)


if __name__ == "__main__":
    raise SystemExit(main())
